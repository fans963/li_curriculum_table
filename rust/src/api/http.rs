use std::sync::OnceLock;
use std::time::Duration;

// Re-export reqwest types so frb_generated.rs can find them via `use crate::api::http::*`
pub use reqwest::{Client, ClientBuilder};

/// Build a [`reqwest::Client`] with a 15 s timeout (native) or default (WASM).
/// The client is built once and reused across calls.
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

/// Return a [`reqwest::ClientBuilder`].
/// - Native: 15 s timeout, TLS via reqwest's `rustls` feature
/// - WASM: no timeout (browser handles it), no TLS config
pub fn client_builder() -> reqwest::ClientBuilder {
    let builder = reqwest::Client::builder();

    // timeout is not available on WASM
    #[cfg(not(target_arch = "wasm32"))]
    let builder = builder.timeout(Duration::from_secs(15));

    builder
}
