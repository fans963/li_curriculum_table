use crate::crawler::core::SessionManager;
use crate::crawler::error::CrawlerResult;
use crate::crawler::model::GradeRecord;
use crate::crawler::parser::parse_grades;
use reqwest::Method;
use std::sync::Arc;

pub struct GradeService {
    session: Arc<SessionManager>,
}

impl GradeService {
    pub fn new(session: Arc<SessionManager>) -> Self {
        Self { session }
    }

    pub async fn fetch_grades(
        &self,
        username: &str,
        password: &str,
        max_attempts: u32,
    ) -> CrawlerResult<GradeRecord> {
        // 1. Ensure logged in
        self.session
            .login_if_needed(username, password, max_attempts)
            .await?;

        // 2. Fetch grades HTML
        let portal_url = self.session.config.get_portal_url();
        let target_url = format!(
            "{}/njlgdx/kscj/cjcx_list",
            portal_url.replace(":8080", ":9080")
        );
        let query_url = format!(
            "{}/njlgdx/kscj/cjcx_query?Ves632DSdyV=NEW_XSD_XJCJ",
            portal_url.replace(":8080", ":9080")
        );

        // POST body as seen in .har
        let body = "kksj=&kcxz=&kcmc=&xsfs=max".to_string().into_bytes();

        log::info!("GradeService: Fetching grades from {}", target_url);
        let html = self
            .session
            .fetch_text(&target_url, Method::POST, Some(body), Some(&query_url))
            .await?;

        if html.len() < 500 {
            log::warn!("GradeService: Received short HTML response (len={}): {}", html.len(), html);
        }

        // 3. Parse
        let record = parse_grades(&html)?;
        Ok(record)
    }
}
