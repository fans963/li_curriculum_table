use crate::api::crawler::get_authorized_session;
use crate::crawler::services::GradeService;
use crate::crawler::model::Grade;
use anyhow::Result;

pub async fn get_grades(username: String, password: String) -> Result<Vec<Grade>> {
    let session = get_authorized_session(Some(username.clone()), Some(password.clone())).await?;
    let service = GradeService::new(session);

    let record = service.fetch_grades(&username, &password, 3).await
        .map_err(|e| anyhow::anyhow!("Failed to fetch grades: {}", e))?;
        
    Ok(record.grades)
}
