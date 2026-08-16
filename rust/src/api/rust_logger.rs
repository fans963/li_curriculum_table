use std::sync::{Mutex, OnceLock};

use log::{LevelFilter, Log, Metadata, Record};

/// A single Rust log record forwarded to Dart.
pub struct RustLogEntry {
    pub level: String,
    pub module: String,
    pub message: String,
}

struct DartLogBridge {
    sink: Mutex<Option<crate::frb_generated::StreamSink<RustLogEntry>>>,
}

impl Log for DartLogBridge {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= log::Level::Info
    }

    fn log(&self, record: &Record) {
        let module = record
            .target()
            .rsplit("::")
            .next()
            .unwrap_or(record.target());
        let message = format!("{}", record.args());

        if let Ok(sink) = self.sink.lock() {
            if let Some(sink) = sink.as_ref() {
                let _ = sink.add(RustLogEntry {
                    level: record.level().to_string(),
                    module: module.to_string(),
                    message,
                });
            }
        }
    }

    fn flush(&self) {}
}

static LOG_BRIDGE: OnceLock<DartLogBridge> = OnceLock::new();

fn logger() -> &'static DartLogBridge {
    LOG_BRIDGE.get_or_init(|| DartLogBridge {
        sink: Mutex::new(None),
    })
}

pub(crate) fn install_rust_log_bridge() {
    let _ = log::set_logger(logger());
    log::set_max_level(LevelFilter::Info);
}

/// Attaches a Dart-side stream to the Rust `log` crate.
///
/// This function intentionally owns a `StreamSink<RustLogEntry>` argument,
/// which makes flutter_rust_bridge expose it as a `Stream<RustLogEntry>` in
/// Dart. Records logged after this call are both printed to the console and
/// sent to Dart, where `AppLogger` persists them alongside Flutter logs.
pub fn init_rust_log_stream(sink: crate::frb_generated::StreamSink<RustLogEntry>) {
    let logger = logger();
    if let Ok(mut slot) = logger.sink.lock() {
        *slot = Some(sink);
    }

    log::info!("Rust log stream attached to Flutter AppLogger.");
}
