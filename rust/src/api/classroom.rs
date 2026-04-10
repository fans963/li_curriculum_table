use crate::crawler::core::SessionManager;
use crate::crawler::services::classroom::ClassroomService;
use crate::crawler::model::{Building, Campus, ClassroomAvailability, ClassroomSchedule};
use crate::api::crawler::get_ocr_engine;
use anyhow::Result;
use std::sync::Arc;

pub async fn get_campuses(
    username: Option<String>,
    password: Option<String>,
) -> Result<Vec<Campus>> {
    let ocr = get_ocr_engine().await?;
    let session = Arc::new(SessionManager::new(ocr));
    
    if let (Some(u), Some(p)) = (username, password) {
        let _ = session.login_if_needed(&u, &p, 3).await;
    }

    let service = ClassroomService::new(session);
    let campuses = service.get_campuses().await
        .map_err(|e| anyhow::anyhow!("Failed to fetch campuses: {}", e))?;
    
    Ok(campuses)
}

pub async fn get_buildings(
    campus_id: String,
    username: Option<String>,
    password: Option<String>,
) -> Result<Vec<Building>> {
    let ocr = get_ocr_engine().await?;
    let session = Arc::new(SessionManager::new(ocr));
    
    if let (Some(u), Some(p)) = (username, password) {
        let _ = session.login_if_needed(&u, &p, 3).await;
    }

    let service = ClassroomService::new(session);
    let buildings = service.get_buildings(&campus_id).await
        .map_err(|e| anyhow::anyhow!("Failed to fetch buildings: {}", e))?;
    
    Ok(buildings)
}

pub async fn get_classroom_availability(
    campus_id: String,
    building_id: String,
    week: u32,
    weekday: u32,
    term: String,
    username: Option<String>,
    password: Option<String>,
) -> Result<Vec<ClassroomAvailability>> {
    let ocr = get_ocr_engine().await?;
    let session = Arc::new(SessionManager::new(ocr));
    
    if let (Some(u), Some(p)) = (username, password) {
        let _ = session.login_if_needed(&u, &p, 3).await;
    }
 
    let service = ClassroomService::new(session);
    let availability = service.get_classroom_availability(&campus_id, &building_id, week, weekday, &term).await
        .map_err(|e| anyhow::anyhow!("Failed to fetch classroom availability: {}", e))?;
    
    Ok(availability)
}

pub async fn get_building_schedule(
    campus_id: String,
    building_id: String,
    term: String,
    username: Option<String>,
    password: Option<String>,
) -> Result<Vec<ClassroomSchedule>> {
    let ocr = get_ocr_engine().await?;
    let session = Arc::new(SessionManager::new(ocr));
    
    if let (Some(u), Some(p)) = (username, password) {
        let _ = session.login_if_needed(&u, &p, 3).await;
    }
 
    let service = ClassroomService::new(session);
    let schedules = service.get_building_schedule(&campus_id, &building_id, &term).await
        .map_err(|e| anyhow::anyhow!("Failed to fetch building schedule: {}", e))?;
    
    Ok(schedules)
}

