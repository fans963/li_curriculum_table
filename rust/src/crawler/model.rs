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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Campus {
    pub id: String,
    pub name: String,
}

/// Bundled response from the classroom page: campuses + server-selected current term.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CampusPageData {
    pub campuses: Vec<Campus>,
    pub current_term: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Grade {
    pub term: String,
    #[serde(rename = "courseCode")]
    pub course_code: String,
    #[serde(rename = "courseName")]
    pub course_name: String,
    pub score: String,
    #[serde(rename = "scoreMark")]
    pub score_mark: String,
    pub credits: f64,
    #[serde(rename = "totalHours")]
    pub total_hours: u32,
    #[serde(rename = "assessmentMethod")]
    pub assessment_method: String,
    #[serde(rename = "courseAttribute")]
    pub course_attribute: String,
    #[serde(rename = "courseNature")]
    pub course_nature: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GradeRecord {
    pub grades: Vec<Grade>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Building {
    pub id: String,
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClassroomAvailability {
    pub classroom_name: String,
    pub availability: Vec<bool>, // true = free, false = occupied
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OccupiedSlot {
    pub start_week: u32,
    pub end_week: u32,
    pub weekday: u32,
    pub slot_index: u32, // 0-4
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClassroomSchedule {
    pub classroom_name: String,
    pub occupied_slots: Vec<OccupiedSlot>,
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
        format!(
            "{}/xskb/xskb_list.do?Ves632DSdyV=NEW_XSD_PYGL",
            self.get_base_url()
        )
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
