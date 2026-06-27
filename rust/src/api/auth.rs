pub use crate::crawler::SessionManager;
use std::sync::Arc;

pub async fn get_authorized_session(
    username: Option<String>,
    password: Option<String>,
) -> anyhow::Result<Arc<SessionManager>> {
    crate::api::crawler::get_authorized_session(username, password).await
}
