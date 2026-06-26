use std::sync::OnceLock;
use std::time::Duration;

// Re-export reqwest types so frb_generated.rs can find them via `use crate::api::http::*`
pub use reqwest::{Client, ClientBuilder};

const BROWSER_UA: &str = "Mozilla/5.0 (X11; Linux x86_64; rv:151.0) Gecko/20100101 Firefox/151.0";

/// Build a [`reqwest::Client`] with browser-like headers, keep-alive, and a
/// generous timeout for the slow campus OPAC server.
pub fn build_client() -> reqwest::Client {
    static CLIENT: OnceLock<reqwest::Client> = OnceLock::new();
    CLIENT
        .get_or_init(|| {
            client_builder()
                .build()
                .expect("Failed to build reqwest client")
        })
        .clone()
}

pub fn client_builder() -> reqwest::ClientBuilder {
    let mut headers = reqwest::header::HeaderMap::new();
    headers.insert(
        reqwest::header::ACCEPT,
        reqwest::header::HeaderValue::from_static(
            "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ),
    );
    headers.insert(
        reqwest::header::ACCEPT_LANGUAGE,
        reqwest::header::HeaderValue::from_static("zh-CN,zh;q=0.9,en;q=0.8"),
    );

    let builder = reqwest::Client::builder()
        .user_agent(BROWSER_UA)
        .default_headers(headers)
        .tcp_keepalive(Duration::from_secs(30));

    #[cfg(not(target_arch = "wasm32"))]
    let builder = builder.timeout(Duration::from_secs(30));

    builder
}
