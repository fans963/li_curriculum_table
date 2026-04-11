use thiserror::Error;

#[derive(Error, Debug)]
pub enum CrawlerError {
    #[error("Network error: {0}")]
    Network(#[from] reqwest::Error),

    #[error("OCR error: {0}")]
    Ocr(String),

    #[error("Parsing error: {0}")]
    Parse(String),

    #[error("Login failed after {0} attempts. Please check your credentials.")]
    LoginFailed(u32),

    #[error("Invalid credentials: Username or password incorrect")]
    InvalidCredentials,

    #[error("Session expired or invalid")]
    SessionExpired,

    #[error("The system is under maintenance or temporarily unavailable")]
    Maintenance,

    #[error("Unknown error: {0}")]
    Unknown(String),
}

pub type CrawlerResult<T> = Result<T, CrawlerError>;
