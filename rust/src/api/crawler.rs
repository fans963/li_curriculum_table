use crate::crawler::SessionManager;
pub use crate::crawler::model::{CourseRow, TimeSlot, TimetableRecord};
use crate::crawler::services::timetable::TimetableService;
pub use std::sync::Arc;
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

pub async fn fetch_timetable_with_session() -> anyhow::Result<TimetableRecord> {
    let session = get_shared_session_manager().await?;
    if !session.check_session_public().await {
        anyhow::bail!("QR session expired; please scan again");
    }
    let service = TimetableService::new(session);
    Ok(service.fetch_timetable("", "", 1).await?)
}

pub struct QrLoginStart {
    pub image_png: Vec<u8>,
    pub already_authenticated: bool,
}

pub async fn start_qr_login() -> anyhow::Result<QrLoginStart> {
    let session = get_shared_session_manager().await?;
    let image = session.start_qr_login().await?;
    Ok(QrLoginStart {
        already_authenticated: image.is_none(),
        image_png: image.unwrap_or_default(),
    })
}

pub async fn poll_qr_login() -> anyhow::Result<String> {
    let session = get_shared_session_manager().await?;
    Ok(session.poll_qr_login().await?)
}

pub async fn cancel_qr_login() -> anyhow::Result<()> {
    let session = get_shared_session_manager().await?;
    session.cancel_qr_login().await;
    Ok(())
}

/// Restore cookies from a JSON blob previously produced by
/// [`persist_cookies_bytes`]. Used at startup to rehydrate the jar
/// from `flutter_secure_storage`. Must be called *before* the first
/// `get_shared_session_manager()` call so the SessionManager picks up
/// the preload on construction.
pub fn set_initial_cookies_json(json: String) -> anyhow::Result<usize> {
    let bytes = json.into_bytes();
    let preview = bytes.len();
    crate::crawler::core::session::set_cookie_preload_json(bytes);
    // We can't report the final count until SessionManager::new runs;
    // the return value is the byte size of the preload, which is at
    // least informative. Dart mostly ignores this number.
    Ok(preview)
}

/// Snapshot the current cookie jar as JSON bytes. Returned to Dart
/// so it can persist the jar through `flutter_secure_storage`. The
/// `Vec` may be empty if the jar is empty.
pub async fn persist_cookies_bytes() -> anyhow::Result<Vec<u8>> {
    let session = get_shared_session_manager().await?;
    session.persist_cookies_bytes()
}

/// Explicitly flush the in-memory cookie jar to disk. Returns the
/// number of cookies persisted. Called automatically after QR /
/// password login; this is mainly for the logout flow to wipe the
/// on-disk copy.
pub async fn persist_cookies() -> anyhow::Result<usize> {
    let session = get_shared_session_manager().await?;
    session.persist_cookies()
}

/// Clear all persisted cookies both in-memory and on disk. The next
/// request after this will trigger a fresh login.
pub async fn clear_persisted_cookies() -> anyhow::Result<()> {
    let session = get_shared_session_manager().await?;
    session.clear_persisted_cookies()
}

/// Whether any cookies for the CAS host are currently loaded. Cheap
/// probe used by Dart at startup to decide whether to show the login
/// dialog vs. attempt silent re-login.
pub async fn has_cas_cookies() -> anyhow::Result<bool> {
    let session = get_shared_session_manager().await?;
    Ok(session.has_cas_cookies())
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
