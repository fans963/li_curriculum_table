use anyhow::Result;
use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
struct GitHubRelease {
    tag_name: Option<String>,
    html_url: Option<String>,
    body: Option<String>,
    published_at: Option<String>,
}

#[derive(Debug, Clone)]
pub struct UpdateData {
    pub latest_version: String,
    pub release_url: String,
    pub release_notes: String,
    pub published_at: String,
}

pub async fn check_for_update() -> Result<UpdateData> {
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()?;

    let response = client
        .get("https://api.github.com/repos/fans963/--table/releases/latest")
        .header("Accept", "application/vnd.github.v3+json")
        .header("User-Agent", "li-curriculum-table")
        .send()
        .await?;

    let status = response.status();
    if !status.is_success() {
        return Err(anyhow::anyhow!(
            "GitHub API returned status {}",
            status.as_u16()
        ));
    }

    let data: GitHubRelease = response.json().await?;

    let tag = data.tag_name.unwrap_or_default();
    let latest_version = tag.trim_start_matches('v').to_string();
    let release_url = data.html_url.unwrap_or_default();
    let release_notes = data.body.unwrap_or_default();
    let published_at = data.published_at.unwrap_or_default();

    Ok(UpdateData {
        latest_version,
        release_url,
        release_notes,
        published_at,
    })
}
