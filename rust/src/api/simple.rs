#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Keep FRB's panic backtrace setup without installing its platform logger.
    // rust_logger installs the single logger that both prints to the console
    // and forwards records to Dart/AppLogger.
    flutter_rust_bridge::setup_backtrace();
    crate::api::rust_logger::install_rust_log_bridge();
    log::info!("Rust: Logger initialized.");
}
