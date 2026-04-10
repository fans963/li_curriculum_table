use crate::api::ocr::DdddOcr;
use crate::crawler::{TimetableCrawler, TimetableRecord};
use anyhow::Result;
use std::sync::Arc;
use tokio::sync::OnceCell;

static OCR_ENGINE: OnceCell<Arc<DdddOcr>> = OnceCell::const_new();

async fn get_ocr_engine() -> Result<Arc<DdddOcr>> {
    OCR_ENGINE.get()
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("OCR engine not initialized. Please call init_ocr_engine first."))
}

#[flutter_rust_bridge::frb(sync)]
pub fn init_ocr_engine(model_bytes: Vec<u8>) -> Result<()> {
    println!("Crawler-API: Initializing OCR engine with {} bytes...", model_bytes.len());
    let ocr = DdddOcr::new(model_bytes)?;
    OCR_ENGINE.set(Arc::new(ocr))
        .map_err(|_| anyhow::anyhow!("OCR engine already initialized"))?;
    Ok(())
}

pub async fn fetch_timetable_data(username: String, password: String) -> Result<TimetableRecord> {
    println!("Crawler-API: Starting fetch task for {}...", username);
    let ocr = get_ocr_engine().await?;
    let crawler = TimetableCrawler::new(ocr);
    
    let record = crawler.login_and_fetch(&username, &password, 5).await
        .map_err(|e| anyhow::anyhow!("Crawler failed: {}", e))?;
    
    println!("Crawler-API: Task completed (Login likely success: {})", record.login_likely_success);
    Ok(record)
}
