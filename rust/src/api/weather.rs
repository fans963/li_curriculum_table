use crate::api::http;
use anyhow::Result;
use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
struct OpenMeteoResponse {
    current_weather: Option<CurrentWeather>,
}

#[derive(Debug, Clone, Deserialize)]
struct CurrentWeather {
    temperature: f64,
    weathercode: i32,
    is_day: i32,
    windspeed: Option<f64>,
}

#[derive(Debug, Clone)]
pub struct WeatherData {
    pub temperature: f64,
    pub weather_code: i32,
    pub is_day: bool,
    pub wind_speed: Option<f64>,
}

pub async fn fetch_weather(latitude: f64, longitude: f64) -> Result<WeatherData> {
    log::info!("fetch_weather: lat={}, lon={}", latitude, longitude);

    let client = http::build_client();

    let url = format!(
        "https://api.open-meteo.com/v1/forecast?latitude={}&longitude={}&current_weather=true&timezone=auto",
        latitude, longitude,
    );

    log::info!("fetch_weather: requesting {}", url);

    let response = client.get(&url).send().await.map_err(|e| {
        log::error!("fetch_weather: request failed: {}", e);
        anyhow::anyhow!("Weather request failed: {}", e)
    })?;

    log::info!("fetch_weather: status={}", response.status());

    let body = response.text().await.map_err(|e| {
        log::error!("fetch_weather: failed to read body: {}", e);
        anyhow::anyhow!("Failed to read weather response: {}", e)
    })?;

    log::info!("fetch_weather: body len={}", body.len());

    let data: OpenMeteoResponse = serde_json::from_str(&body).map_err(|e| {
        log::error!("fetch_weather: parse failed: {} (body: {})", e, &body[..body.len().min(200)]);
        anyhow::anyhow!("Failed to parse weather response: {}", e)
    })?;

    let current = data
        .current_weather
        .ok_or_else(|| anyhow::anyhow!("No current_weather in response"))?;

    log::info!(
        "fetch_weather: done, temp={}, code={}, is_day={}",
        current.temperature, current.weathercode, current.is_day
    );

    Ok(WeatherData {
        temperature: current.temperature,
        weather_code: current.weathercode,
        is_day: current.is_day == 1,
        wind_speed: current.windspeed,
    })
}
