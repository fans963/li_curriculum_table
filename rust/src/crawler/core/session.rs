use crate::api::ocr::DdddOcr;
use crate::crawler::error::{CrawlerError, CrawlerResult};
use crate::crawler::model::CrawlerConfig;
#[cfg(target_arch = "wasm32")]
use crate::crawler::model::ProxySession;
#[cfg(target_arch = "wasm32")]
use base64::Engine;
use encoding_rs::GBK;
use image::load_from_memory;
use reqwest::{Client, Method};
use std::sync::Arc;
use tokio::sync::Mutex;

#[cfg(target_arch = "wasm32")]
const PROXY_URL: &str = "https://www.fans963blog.asia/";

pub struct SessionManager {
    pub client: Client,
    pub config: CrawlerConfig,
    pub ocr: Arc<DdddOcr>,
    pub login_lock: Mutex<()>,
    #[cfg(target_arch = "wasm32")]
    pub session: Arc<std::sync::Mutex<ProxySession>>,
}

impl SessionManager {
    pub fn new(ocr: Arc<DdddOcr>) -> Self {
        let mut builder = Client::builder();

        #[cfg(not(target_arch = "wasm32"))]
        {
            builder = builder
                .cookie_store(true)
                .redirect(reqwest::redirect::Policy::limited(10));
        }

        let client = builder.build().unwrap();

        Self {
            client,
            config: CrawlerConfig::default(),
            ocr,
            login_lock: Mutex::new(()),
            #[cfg(target_arch = "wasm32")]
            session: Arc::new(std::sync::Mutex::new(ProxySession::default())),
        }
    }

    pub async fn login_if_needed(
        &self,
        username: &str,
        password: &str,
        max_attempts: u32,
    ) -> CrawlerResult<()> {
        // Quick check without lock
        if self.check_session().await {
            return Ok(());
        }

        // Acquire lock to ensure only one login attempt happens at a time
        let _lock = self.login_lock.lock().await;

        // Double check after acquiring lock (another task might have finished login)
        if self.check_session().await {
            return Ok(());
        }

        for attempt in 1..=max_attempts {
            println!("Crawler: Shared Login attempt {}/{}", attempt, max_attempts);
            let captcha_bytes = self.get_captcha().await?;
            
            let img = load_from_memory(&captcha_bytes)
                .map_err(|e| CrawlerError::Ocr(format!("Failed to load image: {}", e)))?;

            let verify_code = self
                .ocr
                .classification(img)
                .map_err(|e| CrawlerError::Ocr(format!("OCR failed: {}", e)))?;

            let verify_code = verify_code.trim();
            println!("Crawler: Shared OCR result: '{}'", verify_code);
            
            if verify_code.len() != 4 || !verify_code.chars().all(|c| c.is_alphanumeric()) {
                println!("Crawler: Invalid verification code format, retrying...");
                continue;
            }

            println!("Crawler: Submitting shared login credentials...");
            let html = self.submit_login(username, password, verify_code).await?;

            if html.contains("个人中心") || html.contains("理论课表") || html.contains("main.jsp")
            {
                println!("Crawler: Shared Login successful!");
                return Ok(());
            }
            println!("Crawler: Shared Login failed (HTML check), retrying...");
        }

        Err(CrawlerError::LoginFailed(max_attempts))
    }

    async fn check_session(&self) -> bool {
        let url = format!("{}/main.jsp", self.config.get_portal_url());
        match self.fetch_text(&url, Method::GET, None, None).await {
            Ok(html) => {
                let success = html.contains("个人中心") || html.contains("理论课表") || html.contains("logout");
                if !success {
                    log::debug!("Crawler: Session check failed (invalid keywords). HTML length: {}", html.len());
                }
                success
            }
            Err(e) => {
                println!("Crawler: Session check error: {}", e);
                false
            }
        }
    }

    pub async fn fetch_raw(
        &self,
        url: &str,
        method: Method,
        body: Option<Vec<u8>>,
        referer: Option<&str>,
    ) -> CrawlerResult<Vec<u8>> {
        let wrapped_url = self.wrap_url(url);

        let mut headers = reqwest::header::HeaderMap::new();
        let ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36";
        headers.insert("User-Agent", ua.parse().unwrap());
        headers.insert("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7".parse().unwrap());
        headers.insert(
            "Accept-Language",
            "zh-CN,zh;q=0.9,en;q=0.8".parse().unwrap(),
        );

        if let Some(ref_url) = referer {
            headers.insert("Referer", ref_url.parse().unwrap());
            headers.insert("X-Alt-Referer", ref_url.parse().unwrap());
        }

        let mut req_builder = self
            .client
            .request(method.clone(), wrapped_url)
            .headers(headers);

        if let Some(ref b) = body {
            req_builder = req_builder.body(b.clone());
            if method == Method::POST {
                req_builder = req_builder.header(
                    reqwest::header::CONTENT_TYPE,
                    "application/x-www-form-urlencoded",
                );
            }
        }

        #[cfg(target_arch = "wasm32")]
        {
            // Bypassing browser 'Forbidden Header' restrictions for 'Cookie' and 'Referer'
            // by using custom X-Proxy-* headers which the proxy then maps to standard headers.
            let session = self.session.lock().unwrap();

            let is_9080 = url.contains(":9080");
            let cookie_val = if is_9080 {
                if !session.jsession9080.is_empty() {
                    Some(&session.jsession9080)
                } else {
                    Some(&session.jsession8080)
                }
            } else {
                Some(&session.jsession8080)
            };

            if let Some(val) = cookie_val {
                if !val.is_empty() {
                    req_builder =
                        req_builder.header("X-Proxy-Cookie", format!("JSESSIONID={}", val));
                }
            }

            if let Some(ref_val) = referer {
                req_builder = req_builder.header("X-Proxy-Referer", ref_val);
            }

            req_builder = req_builder.fetch_credentials_include();
        }

        let resp = req_builder.send().await?;

        #[cfg(target_arch = "wasm32")]
        {
            // Extract server-side logs from custom header if present
            if let Some(logs_b64) = resp.headers().get("X-Proxy-Logs") {
                if let Ok(logs_str) = logs_b64.to_str() {
                    let decoded: Result<Vec<u8>, _> =
                        base64::engine::general_purpose::STANDARD.decode(logs_str);
                    if let Ok(decoded_bytes) = decoded {
                        if let Ok(logs_json) = serde_json::from_slice::<Vec<String>>(&decoded_bytes)
                        {
                            for log_line in logs_json {
                                log::info!("[SERVER] {}", log_line);
                            }
                        }
                    }
                }
            }
        }

        let bytes = resp.bytes().await?.to_vec();
        Ok(bytes)
    }

    pub async fn fetch_text(
        &self,
        url: &str,
        method: Method,
        body: Option<Vec<u8>>,
        referer: Option<&str>,
    ) -> CrawlerResult<String> {
        let bytes = self.fetch_raw(url, method, body, referer).await?;
        let text = if let Ok(s) = String::from_utf8(bytes.clone()) {
            s
        } else {
            let (decoded, _, _) = GBK.decode(&bytes);
            decoded.into_owned()
        };
        Ok(text)
    }

    async fn get_captcha(&self) -> CrawlerResult<Vec<u8>> {
        #[cfg(target_arch = "wasm32")]
        {
            let api_url = format!("{}api/session/start", PROXY_URL);
            let payload = serde_json::json!({
                "loginBaseUrl": self.config.get_portal_url()
            });

            let resp = self.client.post(api_url).json(&payload).send().await?;
            let json: serde_json::Value = resp.json().await?;

            let captcha_b64 = json["captchaBase64"].as_str().unwrap_or("");
            let session_json =
                serde_json::from_value::<ProxySession>(json["session"].clone()).unwrap_or_default();

            *self.session.lock().unwrap() = session_json;

            use base64::Engine;
            let bytes = base64::engine::general_purpose::STANDARD
                .decode(captcha_b64)
                .map_err(|e| CrawlerError::Ocr(format!("Base64 decode failed: {}", e)))?;
            Ok(bytes)
        }
        #[cfg(not(target_arch = "wasm32"))]
        {
            let portal_url = self.config.get_portal_url();
            let init_url = format!("{}/Logon.do?method=logonurl", portal_url);
            let _ = self.fetch_raw(&init_url, Method::GET, None, None).await?;

            let captcha_url = format!("{}/verifycode.servlet", portal_url);
            let resp = self
                .fetch_raw(&captcha_url, Method::GET, None, None)
                .await?;
            Ok(resp)
        }
    }

    async fn submit_login(
        &self,
        username: &str,
        password: &str,
        verify_code: &str,
    ) -> CrawlerResult<String> {
        #[cfg(target_arch = "wasm32")]
        {
            let api_url = format!("{}api/session/submit", PROXY_URL);
            let session = self.session.lock().unwrap().clone();

            let payload = serde_json::json!({
                "username": username,
                "password": password,
                "verifyCode": verify_code,
                "session": session,
                "loginBaseUrl": self.config.get_portal_url(),
                "targetUrl": self.config.get_portal_url() + "/main.jsp"
            });

            let resp = self.client.post(api_url).json(&payload).send().await?;
            let json: serde_json::Value = resp.json().await?;

            // Log server-side diagnostics
            if let Some(logs) = json["networkLogs"].as_array() {
                for log_line in logs {
                    log::info!("[PROXY] {}", log_line.as_str().unwrap_or(""));
                }
            }
            if let Some(status) = json["statusCode"].as_i64() {
                log::info!("[PROXY] target statusCode={}", status);
            }
            if let Some(sess) = json.get("session") {
                log::info!("[PROXY] session={}", sess);
            }

            // Update local session from proxy response
            if let Ok(new_session) = serde_json::from_value::<crate::crawler::model::ProxySession>(
                json["session"].clone(),
            ) {
                *self.session.lock().unwrap() = new_session;
            }

            let html_b64 = json["html"].as_str().unwrap_or("");

            if html_b64.is_empty() {
                log::warn!("[PROXY] html field is empty — login likely failed (wrong captcha or credentials)");
                return Err(CrawlerError::Parse("Proxy returned empty HTML".to_string()));
            }

            use base64::Engine;
            let bytes = base64::engine::general_purpose::STANDARD
                .decode(html_b64)
                .map_err(|e| CrawlerError::Ocr(format!("HTML Base64 decode failed: {}", e)))?;

            let text = if let Ok(s) = String::from_utf8(bytes.clone()) {
                s
            } else {
                let (decoded, _, _) = GBK.decode(&bytes);
                decoded.into_owned()
            };
            log::info!(
                "[PROXY] decoded html length={}, snippet={}",
                text.len(),
                &text[..text.len().min(200)]
            );
            Ok(text)
        }
        #[cfg(not(target_arch = "wasm32"))]
        {
            let portal_url = self.config.get_portal_url();
            let logon_url = format!("{}/Logon.do?method=logon", portal_url);
            let init_url = format!("{}/Logon.do?method=logonurl", portal_url);

            let body = url::form_urlencoded::Serializer::new(String::new())
                .append_pair("USERNAME", username)
                .append_pair("PASSWORD", password)
                .append_pair("useDogCode", "")
                .append_pair("RANDOMCODE", verify_code)
                .append_pair("encoded", "")
                .finish()
                .into_bytes();

            let resp = self
                .fetch_text(&logon_url, Method::POST, Some(body), Some(&init_url))
                .await?;
            Ok(resp)
        }
    }

    fn wrap_url(&self, url: &str) -> String {
        #[cfg(target_arch = "wasm32")]
        {
            let encoded: String = url::form_urlencoded::byte_serialize(url.as_bytes()).collect();
            format!("{}?url={}", PROXY_URL, encoded)
        }
        #[cfg(not(target_arch = "wasm32"))]
        {
            url.to_string()
        }
    }
}
