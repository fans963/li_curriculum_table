use crate::api::ocr::DdddOcr;
use crate::crawler::error::{CrawlerError, CrawlerResult};
use crate::crawler::model::{CrawlerConfig, TimetableRecord};
use crate::crawler::parser::parse_and_process_timetable;
use image::load_from_memory;
use reqwest::header::REFERER;
use reqwest::Client;
use std::collections::HashMap;
use std::sync::Arc;

pub struct TimetableCrawler {
    client: Client,
    config: CrawlerConfig,
    ocr: Arc<DdddOcr>,
}

impl TimetableCrawler {
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
            
            let verify_code = self.ocr.classification(img)
                .map_err(|e| CrawlerError::Ocr(format!("OCR failed: {}", e)))?;
            
            let verify_code = verify_code.trim();

            if !self.is_valid_verify_code(verify_code) {
                continue;
            }

            // 2. Submit login
            let html = self.submit_login(username, password, verify_code).await?;
            let record = parse_and_process_timetable(&html)?;

            if record.login_likely_success {
                return Ok(record);
            }
        }

        Err(CrawlerError::LoginFailed(max_attempts))
    }

    async fn get_captcha(&self) -> CrawlerResult<Vec<u8>> {
        // Init session
        self.client.get(&self.config.login_url).send().await?;

        // Get captcha
        let captcha_url = format!("{}/verifycode.servlet", self.config.login_url);
        let resp = self.client.get(captcha_url).send().await?;
        let bytes = resp.bytes().await?.to_vec();
        Ok(bytes)
    }

    async fn submit_login(
        &self,
        username: &str,
        password: &str,
        verify_code: &str,
    ) -> CrawlerResult<String> {
        let logon_url = format!("{}/Logon.do?method=logon", self.config.login_url);
        
        let mut params = HashMap::new();
        params.insert("USERNAME", username);
        params.insert("PASSWORD", password);
        params.insert("useDogCode", "");
        params.insert("RANDOMCODE", verify_code);

        // Submit login form. Redirects are handled automatically by the client.
        let _resp = self.client
            .post(&logon_url)
            .form(&params)
            .header(REFERER, &logon_url)
            .send()
            .await?;

        // After successful login (or redirects), fetch the target table
        let target_resp = self.client.get(&self.config.target_url).send().await?;
        let html = target_resp.text().await?;
        Ok(html)
    }

    fn is_valid_verify_code(&self, code: &str) -> bool {
        code.len() == 4 && code.chars().all(|c| c.is_alphanumeric())
    }
}
