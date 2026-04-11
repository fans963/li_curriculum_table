use std::sync::{Arc, OnceLock};
pub use crate::crawler::model::{TimetableRecord, CourseRow, TimeSlot};
pub use crate::crawler::SessionManager;
use crate::ocr::DdddOcr;
use crate::crawler::services::timetable::TimetableService;
use tokio::sync::Mutex;

static SHARED_SESSION_MANAGER: OnceLock<Arc<SessionManager>> = OnceLock::new();

pub async fn init_ocr_engine(_model_bytes: Vec<u8>) -> anyhow::Result<()> {
    let ocr = Arc::new(Mutex::new(DdddOcr::new()));
    let manager = SessionManager::new(ocr).await;
    let arc_manager = Arc::new(manager);
    
    let _ = SHARED_SESSION_MANAGER.set(arc_manager);
    Ok(())
}

pub async fn fetch_timetable_data(username: String, password: String) -> anyhow::Result<TimetableRecord> {
    let manager = get_authorized_session(Some(username.clone()), Some(password.clone())).await?;
    let service = TimetableService::new(manager);
    let record = service.fetch_timetable(&username, &password, 5).await?;
    Ok(record)
}

pub async fn get_shared_session_manager() -> anyhow::Result<Arc<SessionManager>> {
    SHARED_SESSION_MANAGER.get()
        .cloned()
        .ok_or_else(|| anyhow::anyhow!("Session manager not initialized"))
}

/// Internal helper for session-authorized API calls.
/// Exposed to other modules in the api crate but not to Flutter.
pub(crate) async fn get_authorized_session(
    username: Option<String>,
    password: Option<String>,
) -> anyhow::Result<Arc<SessionManager>> {
    let session = get_shared_session_manager().await?;
    if let (Some(u), Some(p)) = (username, password) {
        let _ = session.login_if_needed(&u, &p, 3).await;
    }
    Ok(session)
}

pub fn update_proxy_config(port: u16) {
    crate::crawler::core::session::set_proxy_port(port);
}

pub async fn run_proxy_server(port: u16) {
    #[cfg(not(target_arch = "wasm32"))]
    {
        let _ = crate::crawler::core::proxy_server::start_proxy_server(port).await;
    }
    #[cfg(target_arch = "wasm32")]
    {
        let _ = port;
    }
}
