use crate::crawler::core::SessionManager;
use crate::crawler::error::CrawlerResult;
use crate::crawler::model::TimetableRecord;
use crate::crawler::parser::parse_and_process_timetable;
use reqwest::Method;
use std::sync::Arc;

pub struct TimetableService {
    session: Arc<SessionManager>,
}

impl TimetableService {
    pub fn new(session: Arc<SessionManager>) -> Self {
        Self { session }
    }

    pub async fn fetch_timetable(
        &self,
        username: &str,
        password: &str,
        max_attempts: u32,
    ) -> CrawlerResult<TimetableRecord> {
        // 1. Ensure logged in
        self.session.login_if_needed(username, password, max_attempts).await?;

        // 2. Fetch timetable HTML
        let target_url = self.session.config.get_target_url();
        let portal_url = self.session.config.get_portal_url();
        let init_url = format!("{}/Logon.do?method=logonurl", portal_url);
        
        log::info!("TimetableService: Fetching target HTML from {}", target_url);
        let html = self.session.fetch_text(&target_url, Method::GET, None, Some(&init_url)).await?;
        
        // 3. Parse
        let record = parse_and_process_timetable(&html)?;
        Ok(record)
    }
}
