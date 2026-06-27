use crate::api::http;
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

/// Build a client for binary file downloads — no auto decompression,
/// since APK/IPA are already compressed and reqwest would fail trying
/// to gunzip them.
#[cfg(any(target_os = "android", target_os = "ios"))]
fn build_download_client() -> reqwest::Client {
    reqwest::Client::builder()
        .user_agent("li-curriculum-table")
        .no_gzip()
        .no_brotli()
        .no_zstd()
        .connect_timeout(std::time::Duration::from_secs(10))
        .build()
        .expect("Failed to build download client")
}

/// Try to start a download from one of the candidate URLs.
/// Returns Ok(response) on success, Err on connection/HTTP failure.
#[cfg(any(target_os = "android", target_os = "ios"))]
async fn try_download(
    client: &reqwest::Client,
    url: &str,
) -> Result<reqwest::Response, String> {
    let resp = client
        .get(url)
        .timeout(std::time::Duration::from_secs(15))
        .send()
        .await
        .map_err(|e| format!("{}", e))?;

    if !resp.status().is_success() {
        return Err(format!("HTTP {}", resp.status().as_u16()));
    }

    Ok(resp)
}

/// Download a file from [url] to [save_path], streaming progress via [sink].
/// Tries the original URL first, then each mirror prefix in [mirror_prefixes].
/// Mirror prefixes are prepended to [url], e.g. "https://ghfast.top/" + url.
/// Only available on mobile platforms (Android/iOS).
#[cfg(any(target_os = "android", target_os = "ios"))]
pub async fn download_update(
    url: String,
    save_path: String,
    mirror_prefixes: Vec<String>,
    sink: crate::frb_generated::StreamSink<DownloadProgress>,
) -> Result<()> {
    use futures_util::StreamExt;
    use tokio::io::AsyncWriteExt;

    let client = build_download_client();

    // Build candidate URLs: original first, then mirrors
    let mut candidates: Vec<String> = Vec::with_capacity(1 + mirror_prefixes.len());
    candidates.push(url.clone());
    for prefix in &mirror_prefixes {
        candidates.push(format!("{}{}", prefix, url));
    }

    // Try each candidate until one succeeds
    let mut last_error = String::new();
    let mut response: Option<reqwest::Response> = None;

    for candidate in &candidates {
        match try_download(&client, candidate).await {
            Ok(resp) => {
                response = Some(resp);
                break;
            }
            Err(e) => {
                last_error = e;
                // Notify the UI which mirror failed so it can display status
                let _ = sink.add(DownloadProgress {
                    received: 0,
                    total: 0,
                    done: false,
                    saved_path: String::new(),
                    error: format!("尝试 {} 失败: {}", candidate, last_error),
                });
                continue;
            }
        }
    }

    let response = match response {
        Some(r) => r,
        None => {
            let _ = sink.add(DownloadProgress {
                received: 0,
                total: 0,
                done: true,
                saved_path: String::new(),
                error: format!("所有下载源均失败，最后错误: {}", last_error),
            });
            return Ok(());
        }
    };

    let total = response.content_length().unwrap_or(0);
    let mut stream = response.bytes_stream();
    let mut file = match tokio::fs::File::create(&save_path).await {
        Ok(f) => f,
        Err(e) => {
            let _ = sink.add(DownloadProgress {
                received: 0,
                total,
                done: true,
                saved_path: String::new(),
                error: format!("创建文件失败: {}", e),
            });
            return Ok(());
        }
    };
    let mut received: u64 = 0;

    while let Some(chunk_result) = stream.next().await {
        let chunk = match chunk_result {
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

        if let Err(e) = file.write_all(&chunk).await {
            let _ = sink.add(DownloadProgress {
                received,
                total,
                done: true,
                saved_path: String::new(),
                error: format!("写入文件失败: {}", e),
            });
            return Ok(());
        }
        received += chunk.len() as u64;

        let _ = sink.add(DownloadProgress {
            received,
            total,
            done: false,
            saved_path: String::new(),
            error: String::new(),
        });
    }

    let _ = file.flush().await;

    let _ = sink.add(DownloadProgress {
        received,
        total,
        done: true,
        saved_path: save_path,
        error: String::new(),
    });

    Ok(())
}

/// Stub for desktop/web platforms — download is not supported in-app.
#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub async fn download_update(
    _url: String,
    _save_path: String,
    _mirror_prefixes: Vec<String>,
    sink: crate::frb_generated::StreamSink<DownloadProgress>,
) -> Result<()> {
    let _ = sink.add(DownloadProgress {
        received: 0,
        total: 0,
        done: true,
        saved_path: String::new(),
        error: "当前平台不支持应用内下载，请前往 GitHub 下载".to_string(),
    });
    Ok(())
}
