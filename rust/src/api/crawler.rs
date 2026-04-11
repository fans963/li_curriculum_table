use crate::api::ocr::DdddOcr;
use crate::crawler::core::SessionManager;
use crate::crawler::model::TimetableRecord;
use crate::crawler::services::timetable::TimetableService;
use anyhow::{Context, Result};
use std::sync::Arc;
use tokio::sync::OnceCell;

static OCR_ENGINE: OnceCell<Arc<DdddOcr>> = OnceCell::const_new();
static SESSION_MANAGER: OnceCell<Arc<SessionManager>> = OnceCell::const_new();

#[flutter_rust_bridge::frb(ignore)]
pub(crate) async fn get_ocr_engine() -> Result<Arc<DdddOcr>> {
    OCR_ENGINE
        .get()
        .cloned()
        .context("OCR engine not initialized. Please call init_ocr_engine first.")
}

#[flutter_rust_bridge::frb(ignore)]
pub(crate) async fn get_shared_session_manager() -> Result<Arc<SessionManager>> {
    if let Some(s) = SESSION_MANAGER.get() {
        return Ok(s.clone());
    }
    let ocr = get_ocr_engine().await?;
    let session = Arc::new(SessionManager::new(ocr));
    let _ = SESSION_MANAGER.set(session.clone());
    Ok(session)
}

pub async fn init_ocr_engine(model_bytes: Vec<u8>) -> Result<()> {
    if OCR_ENGINE.get().is_some() {
        println!("Crawler-API: OCR engine already initialized, skipping.");
        return Ok(());
    }

    println!(
        "Crawler-API: Initializing OCR engine with {} bytes...",
        model_bytes.len()
    );
    let ocr = DdddOcr::new(model_bytes)?;
    let _ = OCR_ENGINE.set(Arc::new(ocr));
    Ok(())
}

pub async fn fetch_timetable_data(username: String, password: String) -> Result<TimetableRecord> {
    println!("Crawler-API: Starting fetch task for {}...", username);
    let session = get_shared_session_manager().await?;
    let service = TimetableService::new(session);

    let record = service
        .fetch_timetable(&username, &password, 5)
        .await
        .map_err(|e| anyhow::anyhow!("Crawler failed: {}", e))?;

    println!(
        "Crawler-API: Task completed (Login likely success: {})",
        record.login_likely_success
    );
    Ok(record)
}
