pub mod client;
pub mod error;
pub mod model;
pub mod parser;

pub use client::TimetableCrawler;
pub use error::{CrawlerError, CrawlerResult};
pub use model::{CrawlerConfig, TimetableRecord};
