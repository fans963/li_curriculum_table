pub mod core;
pub mod services;
pub mod error;
pub mod model;
pub mod parser;

pub use core::SessionManager;
pub use services::timetable::TimetableService;
pub use services::classroom::ClassroomService;
pub use error::{CrawlerError, CrawlerResult};
pub use model::{CrawlerConfig, TimetableRecord, Building, ClassroomAvailability, ProxySession};

// Deprecated - for backward compatibility during migration
pub use services::timetable::TimetableService as TimetableCrawler;
