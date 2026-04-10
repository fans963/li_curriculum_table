use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimeSlot {
    pub weekday: u32,
    #[serde(rename = "startSection")]
    pub start_section: u32,
    #[serde(rename = "endSection")]
    pub end_section: u32,
    #[serde(rename = "startWeek")]
    pub start_week: u32,
    #[serde(rename = "endWeek")]
    pub end_week: u32,
    #[serde(rename = "weekText")]
    pub week_text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CourseRow {
    #[serde(rename = "courseId")]
    pub course_id: String,
    pub order: String,
    #[serde(rename = "courseName")]
    pub course_name: String,
    pub teacher: String,
    #[serde(rename = "timeText")]
    pub time_text: String,
    pub credit: String,
    pub location: String,
    #[serde(rename = "courseType")]
    pub course_type: String,
    pub stage: String,
    pub slots: Vec<TimeSlot>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimetableRecord {
    pub headers: Vec<String>,
    pub rows: Vec<CourseRow>,
    pub login_likely_success: bool,
}

pub struct KbtableWeekHint {
    pub course_name: String,
    pub weekday: u32,
    pub start_section: u32,
    pub end_section: u32,
    pub week_text: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrawlerConfig {
    pub login_url: String,
    pub target_url: String,
}

impl CrawlerConfig {
    pub fn get_portal_url(&self) -> String {
        const DEFAULT_PORTAL_URL: &str = "http://202.119.81.112:8080";
        DEFAULT_PORTAL_URL.to_string()
    }

    pub fn get_base_url(&self) -> String {
        "http://202.119.81.112:9080/njlgdx".to_string()
    }

    pub fn get_target_url(&self) -> String {
        format!("{}/xskb/xskb_list.do?Ves632DSdyV=NEW_XSD_PYGL", self.get_base_url())
    }
}

impl Default for CrawlerConfig {
    fn default() -> Self {
        Self {
            login_url: "".to_string(), 
            target_url: "".to_string(),
        }
    }
}
