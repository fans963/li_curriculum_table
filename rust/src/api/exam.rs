use crate::api::crawler::get_authorized_session;
use crate::crawler::model::Exam;
use crate::crawler::services::ExamService;
use anyhow::Result;

pub async fn get_exams(username: String, password: String) -> Result<Vec<Exam>> {
    let session = get_authorized_session(Some(username.clone()), Some(password.clone())).await?;
    let service = ExamService::new(session);

    let record = service
        .fetch_exams(&username, &password, 3)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to fetch exams: {}", e))?;

    Ok(record.exams)
}
