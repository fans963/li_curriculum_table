#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize

    flutter_rust_bridge::setup_default_user_utils();
    
    #[cfg(target_arch = "wasm32")]
    {
        let _ = console_log::init_with_level(log::Level::Info);
    }
    
    // Silence verbose logs (like tract TRACE) on Web.
    // This is safe even if log isn't the primary backend.
    log::set_max_level(log::LevelFilter::Info);
    log::info!("Rust: Logger initialized for Web.");
}