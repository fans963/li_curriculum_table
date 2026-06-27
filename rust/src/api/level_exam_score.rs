use crate::api::crawler::get_authorized_session;
use crate::crawler::model::LevelExamScore;
use crate::crawler::services::LevelExamScoreService;
use anyhow::Result;

pub async fn get_level_exam_scores(
    username: String,
    password: String,
) -> Result<Vec<LevelExamScore>> {
    let session = get_authorized_session(Some(username.clone()), Some(password.clone())).await?;
    let service = LevelExamScoreService::new(session);

    let record = service
        .fetch_level_exam_scores(&username, &password, 3)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to fetch level exam scores: {}", e))?;

    Ok(record.scores)
}
