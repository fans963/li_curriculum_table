use crate::api::ocr::DdddOcr;
use crate::crawler::{TimetableCrawler, TimetableRecord};
use anyhow::Result;
use std::sync::Arc;
use tokio::sync::OnceCell;

static OCR_ENGINE: OnceCell<Arc<DdddOcr>> = OnceCell::const_new();

async fn get_ocr_engine() -> Result<Arc<DdddOcr>> {
    let engine = OCR_ENGINE.get_or_try_init(|| async {
        DdddOcr::new().map(Arc::new).map_err(|e| anyhow::anyhow!("Failed to init OCR: {}", e))
    }).await?;
    Ok(engine.clone())
}

#[flutter_rust_bridge::frb(sync)]
pub fn init_crawler() -> Result<()> {
    // This can be used to pre-warm the OCR engine
    Ok(())
}

pub async fn fetch_timetable_data(username: String, password: String) -> Result<TimetableRecord> {
    let ocr = get_ocr_engine().await?;
    let crawler = TimetableCrawler::new(ocr);
    
    let record = crawler.login_and_fetch(&username, &password, 5).await
        .map_err(|e| anyhow::anyhow!("Crawler failed: {}", e))?;
    
    Ok(record)
}
