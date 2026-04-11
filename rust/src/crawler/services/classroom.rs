use crate::crawler::core::SessionManager;
use crate::crawler::error::CrawlerResult;
use crate::crawler::model::{Building, Campus, CampusPageData, ClassroomAvailability, ClassroomSchedule};
use crate::crawler::parser::parse_campuses;
use reqwest::Method;
use std::sync::Arc;

pub struct ClassroomService {
    session: Arc<SessionManager>,
}

impl ClassroomService {
    pub fn new(session: Arc<SessionManager>) -> Self {
        Self { session }
    }

    pub async fn get_campuses(&self) -> CrawlerResult<CampusPageData> {
        let url = format!("{}/kbcx/kbxx_classroom", self.session.config.get_base_url());
        let html = self.session.fetch_text(&url, Method::GET, None, None).await?;
        parse_campuses(&html)
    }

    pub async fn get_buildings(&self, campus_id: &str) -> CrawlerResult<Vec<Building>> {
        let url = format!("{}/kbcx/getJxlByAjax", self.session.config.get_base_url());
        let body = format!("xqid={}", campus_id).into_bytes();
        let json_text = self.session.fetch_text(&url, Method::POST, Some(body), None).await?;
        
        // Response format is like: [{"dm":"1","dmmc":"Ⅰ教学楼"}, ...]
        let raw_buildings: Vec<serde_json::Value> = serde_json::from_str(&json_text)
            .map_err(|e| crate::crawler::error::CrawlerError::Parse(e.to_string()))?;
        
        let buildings = raw_buildings.into_iter().filter_map(|b| {
            let id = b.get("dm")?.as_str()?.to_string();
            let name = b.get("dmmc")?.as_str()?.to_string();
            Some(Building { id, name })
        }).collect();

        Ok(buildings)
    }

    pub async fn get_building_schedule(
        &self,
        campus_id: &str,
        building_id: &str,
        term: &str,
    ) -> CrawlerResult<Vec<ClassroomSchedule>> {
        let url = format!("{}/kbcx/kbxx_classroom_ifr", self.session.config.get_base_url());
        
        let body = url::form_urlencoded::Serializer::new(String::new())
            .append_pair("xnxqh", term)
            .append_pair("skyx", "")
            .append_pair("xqid", campus_id)
            .append_pair("jzwid", building_id)
            .append_pair("zc1", "1")
            .append_pair("zc2", "30")
            .append_pair("xq", "1")
            .append_pair("xq2", "7")
            .append_pair("jc1", "1")
            .append_pair("jc2", "12")
            .finish()
            .into_bytes();

        let html = self.session.fetch_text(&url, Method::POST, Some(body), None).await?;
        crate::crawler::parser::parse_building_schedule(&html)
    }

    pub async fn get_classroom_availability(
        &self,
        campus_id: &str,
        building_id: &str,
        week: u32,
        weekday: u32,
        term: &str,
    ) -> CrawlerResult<Vec<ClassroomAvailability>> {
        let schedules = self.get_building_schedule(campus_id, building_id, term).await?;

        
        let mut final_list = Vec::new();
        for schedule in schedules {
            let mut availability = vec![true; 5];
            for occupied in schedule.occupied_slots {
                if occupied.weekday == weekday && week >= occupied.start_week && week <= occupied.end_week {
                    if occupied.slot_index < 5 {
                        availability[occupied.slot_index as usize] = false;
                    }
                }
            }
            final_list.push(ClassroomAvailability {
                classroom_name: schedule.classroom_name,
                availability,
            });
        }

        // Sort by name for consistency
        final_list.sort_by(|a, b| a.classroom_name.cmp(&b.classroom_name));

        Ok(final_list)
    }
}
