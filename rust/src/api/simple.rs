#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();

    // Logging is now bridged to Dart via flutter_rust_bridge v2.13+.
    // No platform-specific logger backends needed.
    log::set_max_level(log::LevelFilter::Info);
    log::info!("Rust: Logger initialized.");
}
