use thiserror::Error;

#[derive(Error, Debug)]
pub enum CrawlerError {
    #[error("Network error: {0}")]
    Network(#[from] reqwest::Error),

    #[error("OCR error: {0}")]
    Ocr(String),

    #[error("Parsing error: {0}")]
    Parse(String),

    #[error("Login failed after {0} attempts")]
    LoginFailed(u32),

    #[error("Unknown error: {0}")]
    Unknown(String),
}

pub type CrawlerResult<T> = Result<T, CrawlerError>;
