use crate::api::crawler::get_shared_session_manager;
use crate::crawler::services::GradeService;

pub async fn get_grades(username: String, password: String) -> Vec<crate::crawler::model::Grade> {
    let session = match get_shared_session_manager().await {
        Ok(s) => s,
        Err(e) => {
            log::error!("API: get_grades failed to get session: {}", e);
            return vec![];
        }
    };
    let service = GradeService::new(session);

    match service.fetch_grades(&username, &password, 3).await {
        Ok(record) => record.grades,
        Err(e) => {
            log::error!("API: get_grades failed: {}", e);
            vec![]
        }
    }
}
