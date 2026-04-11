use crate::api::crawler::get_ocr_engine;
use crate::crawler::core::SessionManager;
use crate::crawler::services::GradeService;
use std::sync::Arc;

pub async fn get_grades(username: String, password: String) -> Vec<crate::crawler::model::Grade> {
    let ocr = match get_ocr_engine().await {
        Ok(engine) => engine,
        Err(e) => {
            log::error!("API: get_grades failed to get OCR: {}", e);
            return vec![];
        }
    };
    let session = Arc::new(SessionManager::new(ocr));
    let service = GradeService::new(session);

    match service.fetch_grades(&username, &password, 3).await {
        Ok(record) => record.grades,
        Err(e) => {
            log::error!("API: get_grades failed: {}", e);
            vec![]
        }
    }
}
