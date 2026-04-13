use crate::ocr::DdddOcr;
use crate::crawler::error::{CrawlerError, CrawlerResult};
use crate::crawler::model::CrawlerConfig;
use encoding_rs::GBK;
use reqwest::{Client, Method};
use std::sync::atomic::{AtomicU16, Ordering};
use std::sync::Arc;
use tokio::sync::Mutex;

static PROXY_PORT: AtomicU16 = AtomicU16::new(9999);

pub fn set_proxy_port(port: u16) {
    PROXY_PORT.store(port, Ordering::SeqCst);
}

pub fn get_proxy_port() -> u16 {
    PROXY_PORT.load(Ordering::SeqCst)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NetworkingStrategy {
    Direct,
    LocalProxy,
    LocalNativeProxy, // Web version uses Native app as local gateway
}

pub struct SessionManager {
    pub client: Client,
    pub config: CrawlerConfig,
    pub ocr: Arc<Mutex<DdddOcr>>,
    pub login_lock: Mutex<()>,
    pub strategy: NetworkingStrategy,
}

impl SessionManager {
    pub async fn new(ocr: Arc<Mutex<DdddOcr>>) -> Self {
        #[cfg(target_arch = "wasm32")]
        let mut strategy: NetworkingStrategy = NetworkingStrategy::LocalNativeProxy;
        #[cfg(not(target_arch = "wasm32"))]
        let strategy: NetworkingStrategy;

        let builder = Client::builder();

        #[cfg(target_arch = "wasm32")]
        {
            let port = get_proxy_port();
            let local_discovery_url = format!("http://localhost:{}/status", port);
            log::info!("Web: Probing for local native proxy at {}...", local_discovery_url);
            
            let probe_client = reqwest::Client::builder().build().unwrap_or_default();
            if let Ok(resp) = probe_client.get(local_discovery_url).send().await {
                if resp.status().is_success() {
                    log::info!("Web: Local native proxy discovered! Switching to hyper-speed mode.");
                    strategy = NetworkingStrategy::LocalNativeProxy;
                }
            }
        }

        #[cfg(not(target_arch = "wasm32"))]
        let builder = {
            let b = builder
                .cookie_store(true)
                .redirect(reqwest::redirect::Policy::limited(10));
            
            strategy = NetworkingStrategy::Direct;
            log::info!("[V8] Native mode: Using Direct connection.");
            b
        };

        let client = builder.build().unwrap_or_default();
        println!("Crawler: SessionManager initialized. Strategy: {:?}, Port: {}", strategy, get_proxy_port());

        Self {
            client,
            config: CrawlerConfig::default(),
            ocr,
            login_lock: Mutex::new(()),
            strategy,
        }
    }

    pub async fn login_if_needed(
        &self,
        username: &str,
        password: &str,
        max_attempts: u32,
    ) -> CrawlerResult<()> {
        if self.check_session().await {
            return Ok(());
        }

        let _lock = self.login_lock.lock().await;

        if self.check_session().await {
            return Ok(());
        }

        for attempt in 1..=max_attempts {
            println!("Crawler: Shared Login attempt {}/{}", attempt, max_attempts);
            let captcha_bytes = self.get_captcha().await?;
            
            let verify_code = {
                let ocr_guard = self.ocr.lock().await;
                ocr_guard.recognize(&captcha_bytes)
            };

            let verify_code = verify_code.trim();
            println!("Crawler: Shared OCR result: '{}'", verify_code);
            
            if verify_code.len() != 4 || !verify_code.chars().all(|c| c.is_alphanumeric()) {
                println!("Crawler: Invalid verification code format, retrying...");
                continue;
            }

            println!("Crawler: Submitting shared login credentials...");
            let html = self.submit_login(username, password, verify_code).await?;

            if html.contains("个人中心") || html.contains("理论课表") || html.contains("main.jsp") || html.contains("logout")
            {
                println!("Crawler: Shared Login successful!");
                return Ok(());
            }

            if html.contains("用户名或密码错误") || html.contains("密码错误") || html.contains("账号不存在") {
                return Err(CrawlerError::InvalidCredentials);
            }

            if html.contains("验证码错误") {
                println!("Crawler: Verification code error, retrying (attempt {}/{})...", attempt, max_attempts);
                continue;
            }

            if html.contains("系统维护") || html.contains("maintenance") {
                return Err(CrawlerError::Maintenance);
            }

            println!("Crawler: Shared Login failed (unknown reason, HTML check), retrying...");
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
        println!("Crawler: [Request] {} -> {}", url, wrapped_url);

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

        if self.strategy == NetworkingStrategy::LocalNativeProxy {
            #[cfg(target_arch = "wasm32")]
            {

                if let Some(ref_val) = referer {
                    req_builder = req_builder.header("X-Proxy-Referer", ref_val);
                }

                req_builder = req_builder.fetch_credentials_include();
            }
        }

        let resp = req_builder.send().await?;
        let status = resp.status();
        println!("Crawler: [Response] status: {}, url: {}", status, resp.url());


        let bytes = resp.bytes().await?.to_vec();
        println!("Crawler: [Data] received {} bytes", bytes.len());
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
        let portal_url = self.config.get_portal_url();
        let init_url = format!("{}/Logon.do?method=logonurl", portal_url);
        let _ = self.fetch_raw(&init_url, Method::GET, None, None).await?;

        let captcha_url = format!("{}/verifycode.servlet", portal_url);
        let resp = self
            .fetch_raw(&captcha_url, Method::GET, None, None)
            .await?;
        println!("Crawler: Captcha fetched, length: {}", resp.len());
        Ok(resp)
    }

    async fn submit_login(
        &self,
        username: &str,
        password: &str,
        verify_code: &str,
    ) -> CrawlerResult<String> {
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

    fn wrap_url(&self, url: &str) -> String {
        match self.strategy {
            NetworkingStrategy::LocalNativeProxy => {
                let port = get_proxy_port();
                let encoded: String = url::form_urlencoded::byte_serialize(url.as_bytes()).collect();
                format!("http://localhost:{}/proxy?url={}", port, encoded)
            }
            _ => url.to_string(),
        }
    }
}
