use crate::api::crawler::get_shared_session_manager;
use crate::crawler::model::{Building, CampusPageData, ClassroomAvailability, ClassroomSchedule};
use crate::crawler::services::classroom::ClassroomService;
use anyhow::Result;

pub async fn get_campuses(
    username: Option<String>,
    password: Option<String>,
) -> Result<CampusPageData> {
    let session = get_shared_session_manager().await?;

    if let (Some(u), Some(p)) = (username, password) {
        let _ = session.login_if_needed(&u, &p, 3).await;
    }

    let service = ClassroomService::new(session);
    let data = service
        .get_campuses()
        .await
        .map_err(|e| anyhow::anyhow!("Failed to fetch campuses: {}", e))?;

    Ok(data)
}

pub async fn get_buildings(
    campus_id: String,
    username: Option<String>,
    password: Option<String>,
) -> Result<Vec<Building>> {
    let session = get_shared_session_manager().await?;

    if let (Some(u), Some(p)) = (username, password) {
        let _ = session.login_if_needed(&u, &p, 3).await;
    }

    let service = ClassroomService::new(session);
    let buildings = service
        .get_buildings(&campus_id)
        .await
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
    let session = get_shared_session_manager().await?;

    if let (Some(u), Some(p)) = (username, password) {
        let _ = session.login_if_needed(&u, &p, 3).await;
    }

    let service = ClassroomService::new(session);
    let availability = service
        .get_classroom_availability(&campus_id, &building_id, week, weekday, &term)
        .await
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
    let session = get_shared_session_manager().await?;

    if let (Some(u), Some(p)) = (username, password) {
        let _ = session.login_if_needed(&u, &p, 3).await;
    }

    let service = ClassroomService::new(session);
    let schedules = service
        .get_building_schedule(&campus_id, &building_id, &term)
        .await
        .map_err(|e| anyhow::anyhow!("Failed to fetch building schedule: {}", e))?;

    Ok(schedules)
}
