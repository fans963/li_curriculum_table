pub mod core;
pub mod error;
pub mod model;
pub mod parser;
pub mod services;

pub use core::SessionManager;
pub use error::{CrawlerError, CrawlerResult};
pub use model::{Building, ClassroomAvailability, CrawlerConfig, TimetableRecord};
pub use services::classroom::ClassroomService;
pub use services::timetable::TimetableService;

// Deprecated - for backward compatibility during migration
pub use services::timetable::TimetableService as TimetableCrawler;
