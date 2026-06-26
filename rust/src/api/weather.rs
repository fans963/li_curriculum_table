use crate::api::http;
use anyhow::Result;
use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
struct OpenMeteoResponse {
    daily: Option<DailyWeather>,
    error: Option<bool>,
    reason: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
struct DailyWeather {
    weather_code: Option<Vec<i32>>,
    temperature_2m_max: Option<Vec<f64>>,
    temperature_2m_min: Option<Vec<f64>>,
}

#[derive(Debug, Clone)]
pub struct WeatherData {
    pub min_temperature: f64,
    pub max_temperature: f64,
    pub weather_code: i32,
    pub is_day: bool,
    pub wind_speed: Option<f64>,
}

pub async fn fetch_weather(latitude: f64, longitude: f64) -> Result<WeatherData> {
    let client = http::build_client();

    let url = format!(
        "https://api.open-meteo.com/v1/forecast?latitude={}&longitude={}&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1",
        latitude, longitude,
    );

    let response = client.get(&url).send().await?;
    let body = response.text().await?;
    let data: OpenMeteoResponse = serde_json::from_str(&body)?;

    if data.error == Some(true) {
        let reason = data.reason.unwrap_or_else(|| "Unknown error".to_string());
        anyhow::bail!("Weather API error: {}", reason);
    }

    let daily = data
        .daily
        .ok_or_else(|| anyhow::anyhow!("No daily weather data in response"))?;

    let weather_code = daily.weather_code.and_then(|v| v.first().cloned()).unwrap_or(0);
    let max_temp = daily.temperature_2m_max.and_then(|v| v.first().cloned()).unwrap_or(0.0);
    let min_temp = daily.temperature_2m_min.and_then(|v| v.first().cloned()).unwrap_or(0.0);

    Ok(WeatherData {
        min_temperature: min_temp,
        max_temperature: max_temp,
        weather_code,
        is_day: true, // We don't have is_day for daily, assume day
        wind_speed: None,
    })
}
