use crate::api::http;
use anyhow::Result;
use flutter_rust_bridge::frb;
use futures_util::StreamExt;
use serde::Deserialize;
use tokio::io::AsyncWriteExt;

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

pub struct DownloadProgress {
    pub received: u64,
    pub total: u64,
    pub done: bool,
    pub saved_path: String,
    pub error: String,
}

pub async fn check_for_update() -> Result<UpdateData> {
    let client = http::build_client();

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

/// Download a file from [url] to a temporary path, streaming progress via [sink].
/// Returns the final saved file path on success.
pub async fn download_update(
    url: String,
    save_path: String,
    sink: flutter_rust_bridge::StreamSink<DownloadProgress>,
) -> Result<()> {
    let client = http::build_client();

    let response = match client.get(&url).send().await {
        Ok(r) => r,
        Err(e) => {
            let _ = sink.add(DownloadProgress {
                received: 0,
                total: 0,
                done: true,
                saved_path: String::new(),
                error: format!("请求失败: {}", e),
            });
            return Ok(());
        }
    };

    if !response.status().is_success() {
        let _ = sink.add(DownloadProgress {
            received: 0,
            total: 0,
            done: true,
            saved_path: String::new(),
            error: format!("服务器返回错误: {}", response.status().as_u16()),
        });
        return Ok(());
    }

    let total = response.content_length().unwrap_or(0);
    let mut stream = response.bytes_stream();
    let mut file = tokio::fs::File::create(&save_path).await?;
    let mut received: u64 = 0;

    while let Some(chunk) = stream.next().await {
        let chunk = match chunk {
            Ok(c) => c,
            Err(e) => {
                let _ = sink.add(DownloadProgress {
                    received,
                    total,
                    done: true,
                    saved_path: String::new(),
                    error: format!("下载中断: {}", e),
                });
                return Ok(());
            }
        };

        file.write_all(&chunk).await?;
        received += chunk.len() as u64;

        let _ = sink.add(DownloadProgress {
            received,
            total,
            done: false,
            saved_path: String::new(),
            error: String::new(),
        });
    }

    file.flush().await?;

    let _ = sink.add(DownloadProgress {
        received,
        total,
        done: true,
        saved_path: save_path.clone(),
        error: String::new(),
    });

    Ok(())
}
