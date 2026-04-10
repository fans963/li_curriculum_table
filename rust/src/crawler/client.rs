use crate::api::ocr::DdddOcr;
use crate::crawler::error::{CrawlerError, CrawlerResult};
use crate::crawler::model::{CrawlerConfig, TimetableRecord};
use crate::crawler::parser::parse_and_process_timetable;
use encoding_rs::GBK;
use image::load_from_memory;
use reqwest::{Client, Method};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Serialize, Deserialize, Clone, Default)]
pub struct ProxySession {
    pub jsession8080: String,
    pub jsession9080: String,
}

pub struct TimetableCrawler {
    client: Client,
    config: CrawlerConfig,
    ocr: Arc<crate::api::ocr::DdddOcr>,
    #[cfg(target_arch = "wasm32")]
    session: std::sync::Arc<std::sync::Mutex<ProxySession>>,
}

const PROXY_URL: &str = "https://www.fans963blog.asia/";

impl TimetableCrawler {
    pub fn new(ocr: Arc<DdddOcr>) -> Self {
        let mut builder = Client::builder();

        #[cfg(not(target_arch = "wasm32"))]
        {
            builder = builder
                .cookie_store(true)
                .redirect(reqwest::redirect::Policy::limited(10));
        }
        #[cfg(target_arch = "wasm32")]
        {
            // On Wasm, .cookie_store is not available on builder.
            // We use .fetch_credentials_include() on individual requests instead.
            // Redirects are followed by default by the browser.
        }

        let client = builder.build().unwrap();

        Self {
            client,
            config: CrawlerConfig::default(),
            ocr,
            #[cfg(target_arch = "wasm32")]
            session: std::sync::Arc::new(std::sync::Mutex::new(ProxySession::default())),
        }
    }

    pub async fn login_and_fetch(
        &self,
        username: &str,
        password: &str,
        max_attempts: u32,
    ) -> CrawlerResult<TimetableRecord> {
        for _attempt in 1..=max_attempts {
            // 1. Start session & Get captcha
            let captcha_bytes = self.get_captcha().await?;
            let img = load_from_memory(&captcha_bytes)
                .map_err(|e| CrawlerError::Ocr(format!("Failed to load image: {}", e)))?;

            let verify_code = self
                .ocr
                .classification(img)
                .map_err(|e| CrawlerError::Ocr(format!("OCR failed: {}", e)))?;

            let verify_code = verify_code.trim();
            log::info!("Crawler: OCR Result: {}", verify_code);
            
            #[cfg(target_arch = "wasm32")]
            {
                use base64::Engine;
                let b64 = base64::engine::general_purpose::STANDARD.encode(&captcha_bytes);
                log::info!("Crawler DEBUG: Captcha Base64: data:image/png;base64,{}", b64);
            }

            if !self.is_valid_verify_code(verify_code) {
                continue;
            }

            // 2. Submit login
            let html = self.submit_login(username, password, verify_code).await?;
            log::info!("Crawler: submit_login returned HTML ({} chars)", html.len());
            
            // Debug: show first 200 chars of decoded HTML
            let preview: String = html.chars().take(200).collect();
            log::info!("Crawler: HTML preview: {}", preview.replace('\n', " ").replace('\r', ""));
            
            // Check for key markers
            log::info!("Crawler: Contains '理论课表': {}", html.contains("理论课表"));
            log::info!("Crawler: Contains 'dataList': {}", html.contains("dataList"));
            log::info!("Crawler: Contains 'kbtable': {}", html.contains("kbtable"));
            
            let record = parse_and_process_timetable(&html)?;
            log::info!("Crawler: Parser returned {} rows, {} headers, login_likely_success={}", 
                record.rows.len(), record.headers.len(), record.login_likely_success);
            
            // Log slot counts per row
            for (i, row) in record.rows.iter().enumerate() {
                log::info!("Crawler: Row[{}] '{}' has {} slots", i, row.course_name, row.slots.len());
            }

            if record.login_likely_success {
                return Ok(record);
            }
            log::info!("Crawler: login_likely_success=false, retrying...");
        }

        Err(CrawlerError::LoginFailed(max_attempts))
    }

    async fn get_captcha(&self) -> CrawlerResult<Vec<u8>> {
        #[cfg(target_arch = "wasm32")]
        {
            let api_url = format!("{}api/session/start", PROXY_URL);
            log::info!("Crawler WASM: Calling Session Start: {}", api_url);
            
            let payload = serde_json::json!({
                "loginBaseUrl": self.config.get_portal_url()
            });

            let resp = self.client.post(api_url).json(&payload).send().await?;
            let json: serde_json::Value = resp.json().await?;
            
            let captcha_b64 = json["captchaBase64"].as_str().unwrap_or("");
            let session_json = serde_json::from_value::<ProxySession>(json["session"].clone())
                .unwrap_or_default();
            
            *self.session.lock().unwrap() = session_json;
            
            use base64::Engine;
            let bytes = base64::engine::general_purpose::STANDARD.decode(captcha_b64)
                .map_err(|e| CrawlerError::Ocr(format!("Base64 decode failed: {}", e)))?;
            Ok(bytes)
        }
        #[cfg(not(target_arch = "wasm32"))]
        {
            let portal_url = self.config.get_portal_url();
            let init_url = format!("{}/Logon.do?method=logonurl", portal_url);
            // Init session
            let _ = self.fetch_raw(&init_url, Method::GET, None, None).await?;

            // Get captcha
            let captcha_url = format!("{}/verifycode.servlet", portal_url);
            let resp = self.fetch_raw(&captcha_url, Method::GET, None, None).await?;
            Ok(resp)
        }
    }

    async fn fetch_raw(
        &self,
        url: &str,
        method: Method,
        body: Option<Vec<u8>>,
        referer: Option<&str>,
    ) -> CrawlerResult<Vec<u8>> {
        let wrapped_url = self.wrap_url(url);
        log::info!("Crawler Request: {} {}", method, wrapped_url);
        if let Some(ref_url) = referer {
            log::info!("Crawler Referer: {}", ref_url);
        }
        
        if let Some(ref b) = body {
            log::info!("Crawler Request Body Size: {} bytes", b.len());
        }

        // Basic Headers for Chrome simulation
        let mut headers = reqwest::header::HeaderMap::new();
        let ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36";
        headers.insert("User-Agent", ua.parse().unwrap());
        headers.insert("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7".parse().unwrap());
        headers.insert("Accept-Language", "zh-CN,zh;q=0.9,en;q=0.8".parse().unwrap());
        headers.insert("Cache-Control", "max-age=0".parse().unwrap());
        headers.insert("Upgrade-Insecure-Requests", "1".parse().unwrap());
        
        if let Some(ref_url) = referer {
            headers.insert("Referer", ref_url.parse().unwrap());
            headers.insert("X-Alt-Referer", ref_url.parse().unwrap());
        }
        
        let mut req_builder = self.client.request(method.clone(), wrapped_url)
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
            req_builder = req_builder.fetch_credentials_include();
        }

        let resp = req_builder.send().await?;
        let status = resp.status();
        let bytes = resp.bytes().await?.to_vec();
        log::info!("Crawler Response: {} ({} bytes)", status, bytes.len());
        Ok(bytes)
    }

    async fn fetch_text(
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

        let preview = if text.len() > 200 {
            format!("{}...", &text[..200])
        } else {
            text.clone()
        };
        log::info!("Crawler Text Response Preview: {}", preview.replace('\n', " ").replace('\r', " "));
        
        Ok(text)
    }

    async fn submit_login(
        &self,
        username: &str,
        password: &str,
        verify_code: &str,
    ) -> CrawlerResult<String> {
        log::info!("Crawler: Attempting login for user {}", username);
        
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
                "targetUrl": self.config.get_target_url()
            });

            log::info!("Crawler WASM: Calling Session Submit: {}", api_url);
            let resp = self.client.post(api_url)
                .json(&payload)
                .send()
                .await?;
            
            let resp_status = resp.status();
            log::info!("Crawler WASM: Submit response status: {}", resp_status);
            
            let json: serde_json::Value = resp.json().await?;
            
            // Log the response structure
            let status_code = json["statusCode"].as_i64().unwrap_or(-1);
            let has_html = json["html"].is_string();
            let html_b64_len = json["html"].as_str().map(|s| s.len()).unwrap_or(0);
            log::info!("Crawler WASM: Response statusCode={}, has_html={}, html_b64_len={}", 
                status_code, has_html, html_b64_len);
            
            // Log network logs from proxy
            if let Some(logs) = json["networkLogs"].as_array() {
                for l in logs {
                    log::info!("Crawler WASM proxy: {}", l.as_str().unwrap_or(""));
                }
            }
            
            let html_b64 = json["html"].as_str().unwrap_or("");
            
            if html_b64.is_empty() {
                log::info!("Crawler WASM: WARNING - html field is empty!");
                return Err(CrawlerError::Parse("Proxy returned empty HTML".to_string()));
            }
            
            use base64::Engine;
            let bytes = base64::engine::general_purpose::STANDARD.decode(html_b64)
                .map_err(|e| CrawlerError::Ocr(format!("HTML Base64 decode failed: {}", e)))?;
            
            log::info!("Crawler WASM: Base64 decoded to {} raw bytes", bytes.len());
            
            // Try UTF-8 first; if invalid, fall back to GBK decoding
            let text = if let Ok(s) = String::from_utf8(bytes.clone()) {
                log::info!("Crawler WASM: Decoded as UTF-8 ({} chars)", s.len());
                s
            } else {
                log::info!("Crawler WASM: UTF-8 failed, falling back to GBK");
                let (decoded, _, _) = encoding_rs::GBK.decode(&bytes);
                log::info!("Crawler WASM: GBK decoded to {} chars", decoded.len());
                decoded.into_owned()
            };
            Ok(text)
        }
        #[cfg(not(target_arch = "wasm32"))]
        {
            let portal_url = self.config.get_portal_url();
            let logon_url = format!("{}/Logon.do?method=logon", portal_url);
            let init_url = format!("{}/Logon.do?method=logonurl", portal_url);

            log::info!("Crawler: Submitting login directly (Native)");

            // Submit login form with proper URL encoding
            let body = url::form_urlencoded::Serializer::new(String::new())
                .append_pair("USERNAME", username)
                .append_pair("PASSWORD", password)
                .append_pair("useDogCode", "")
                .append_pair("RANDOMCODE", verify_code)
                .append_pair("encoded", "")
                .finish()
                .into_bytes();

            let _ = self.fetch_raw(&logon_url, Method::POST, Some(body), Some(&init_url)).await?;

            // After successful login, fetch the target table
            log::info!("Crawler: Login request sent. Now fetching timetable...");
            let target_url = self.config.get_target_url();
            let html = self.fetch_text(&target_url, Method::GET, None, Some(&init_url)).await?;
            log::info!("Crawler: Timetable HTML received ({} chars)", html.len());
            Ok(html)
        }
    }

    fn is_valid_verify_code(&self, code: &str) -> bool {
        code.len() == 4 && code.chars().all(|c| c.is_alphanumeric())
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
