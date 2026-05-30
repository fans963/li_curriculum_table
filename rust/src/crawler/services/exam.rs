use crate::crawler::core::SessionManager;
use crate::crawler::error::CrawlerResult;
use crate::crawler::model::ExamRecord;
use crate::crawler::parser::{parse_exam_query_term, parse_exams};
use reqwest::Method;
use std::sync::Arc;

pub struct ExamService {
    session: Arc<SessionManager>,
}

impl ExamService {
    pub fn new(session: Arc<SessionManager>) -> Self {
        Self { session }
    }

    pub async fn fetch_exams(
        &self,
        username: &str,
        password: &str,
        max_attempts: u32,
    ) -> CrawlerResult<ExamRecord> {
        // 1. Ensure logged in
        self.session
            .login_if_needed(username, password, max_attempts)
            .await?;

        let portal_url = self.session.config.get_portal_url();
        let base_url = portal_url.replace(":8080", ":9080");

        // 2. Fetch the exam query page to get the current term
        let query_url = format!(
            "{}/njlgdx/xsks/xsksap_query?Ves632DSdyV=NEW_XSD_KSBM",
            base_url
        );
        log::info!("ExamService: GET query page {}", query_url);
        let query_html = self
            .session
            .fetch_text(&query_url, Method::GET, None, None)
            .await?;
        log::info!("ExamService: Query page HTML length={}", query_html.len());

        let term = parse_exam_query_term(&query_html)
            .unwrap_or_else(|| {
                log::warn!("ExamService: Could not extract term, using empty string");
                String::new()
            });
        log::info!("ExamService: Using term='{}'", term);

        // 3. POST to exam list with the term
        let target_url = format!("{}/njlgdx/xsks/xsksap_list", base_url);
        let body = url::form_urlencoded::Serializer::new(String::new())
            .append_pair("xnxqid", &term)
            .finish()
            .into_bytes();

        log::info!("ExamService: POST {} with xnxqid={}", target_url, term);
        let html = self
            .session
            .fetch_text(&target_url, Method::POST, Some(body), Some(&query_url))
            .await?;

        log::info!("ExamService: Received HTML, length={}", html.len());

        // Debug: write HTML to temp file
        let _ = std::fs::write("/tmp/exam_response.html", &html);

        if html.len() < 500 {
            log::warn!(
                "ExamService: Received short HTML response (len={}): {}",
                html.len(),
                html
            );
        }

        if html.contains("logon") || html.contains("Logon") || html.contains("登录") {
            log::warn!("ExamService: Response looks like a login page, session may have expired");
        }

        // 4. Parse
        let record = parse_exams(&html)?;
        log::info!("ExamService: Parsed {} exams", record.exams.len());
        for (i, exam) in record.exams.iter().enumerate() {
            log::info!(
                "ExamService: Exam[{}] {} - {} - {} - {}",
                i, exam.course_name, exam.exam_time, exam.location, exam.seat_number
            );
        }

        Ok(record)
    }
}
