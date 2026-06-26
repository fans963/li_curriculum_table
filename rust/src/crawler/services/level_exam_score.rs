use crate::crawler::core::SessionManager;
use crate::crawler::error::CrawlerResult;
use crate::crawler::model::LevelExamScoreRecord;
use crate::crawler::parser::parse_level_exam_scores;
use reqwest::Method;
use std::sync::Arc;

pub struct LevelExamScoreService {
    session: Arc<SessionManager>,
}

impl LevelExamScoreService {
    pub fn new(session: Arc<SessionManager>) -> Self {
        Self { session }
    }

    pub async fn fetch_level_exam_scores(
        &self,
        username: &str,
        password: &str,
        max_attempts: u32,
    ) -> CrawlerResult<LevelExamScoreRecord> {
        self.session
            .login_if_needed(username, password, max_attempts)
            .await?;

        let portal_url = self.session.config.get_portal_url();
        let base_url = portal_url.replace(":8080", ":9080");

        // Level exam scores page is a direct GET — no term selection needed
        let target_url = format!("{base_url}/njlgdx/kscj/djkscj_list");
        log::info!("LevelExamScoreService: GET {}", target_url);

        let html = self
            .session
            .fetch_text(&target_url, Method::GET, None, None)
            .await?;

        log::info!(
            "LevelExamScoreService: Received HTML, length={}",
            html.len()
        );

        if html.len() < 500 {
            log::warn!(
                "LevelExamScoreService: Short HTML response (len={}): {}",
                html.len(),
                html
            );
        }

        let record = parse_level_exam_scores(&html)?;
        log::info!(
            "LevelExamScoreService: Parsed {} scores",
            record.scores.len()
        );

        Ok(record)
    }
}
