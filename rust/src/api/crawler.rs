pub use crate::crawler::model::{CourseRow, TimeSlot, TimetableRecord};
use crate::crawler::services::timetable::TimetableService;
pub use crate::crawler::SessionManager;
use std::sync::Arc;
use tokio::sync::OnceCell;

static SHARED_SESSION_MANAGER: OnceCell<Arc<SessionManager>> = OnceCell::const_new();

pub async fn get_shared_session_manager() -> anyhow::Result<Arc<SessionManager>> {
    let session = SHARED_SESSION_MANAGER
        .get_or_init(|| async {
            Arc::new(SessionManager::new().await)
        })
        .await;
    Ok(session.clone())
}

pub async fn fetch_timetable_data(
    username: String,
    password: String,
) -> anyhow::Result<TimetableRecord> {
    let manager = get_authorized_session(Some(username.clone()), Some(password.clone())).await?;
    let service = TimetableService::new(manager);
    let record = service.fetch_timetable(&username, &password, 5).await?;
    Ok(record)
}

/// Internal helper for session-authorized API calls.
/// Exposed to other modules in the api crate but not to Flutter.
pub(crate) async fn get_authorized_session(
    username: Option<String>,
    password: Option<String>,
) -> anyhow::Result<Arc<SessionManager>> {
    let session = get_shared_session_manager().await?;
    if let (Some(u), Some(p)) = (username, password) {
        session.login_if_needed(&u, &p, 3).await?;
    }
    Ok(session)
}

/// Inject cookies from an external browser (WebView) login session into the
/// Rust HTTP client's cookie jar. Each cookie entry is a pair of
/// `(origin_url, cookie_string)` where:
/// - `origin_url` is like `https://bkjw.njust.edu.cn/njlgdx/framework/main.jsp`
/// - `cookie_string` is like `JSESSIONID=ABC123; Path=/njlgdx`
///
/// After injecting, this function verifies the session is valid by checking
/// the academic homepage. Returns Ok(()) on success, Err on failure.
pub async fn inject_session_cookies(
    cookies: Vec<CookieEntry>,
) -> anyhow::Result<()> {
    let session = get_shared_session_manager().await?;
    let pairs: Vec<(String, String)> = cookies
        .into_iter()
        .map(|c| (c.url, c.cookie))
        .collect();
    session.login_with_cookies(pairs).await?;
    Ok(())
}

/// A cookie entry for FFI transport between Flutter and Rust.
pub struct CookieEntry {
    pub url: String,
    pub cookie: String,
}

/// Check whether the current session is still valid (has authenticated cookies).
pub async fn check_session_valid() -> anyhow::Result<bool> {
    let session = get_shared_session_manager().await?;
    Ok(session.check_session_public().await)
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

