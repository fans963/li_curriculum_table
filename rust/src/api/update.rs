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

/// Build a client for binary file downloads.
/// Explicitly requests identity encoding to prevent proxies from applying
/// Content-Encoding: gzip which would corrupt the binary stream.
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

/// Try to initiate a download. Returns Ok(response) on success.
#[cfg(any(target_os = "android", target_os = "ios"))]
async fn try_connect(
    client: &reqwest::Client,
    url: &str,
) -> Result<reqwest::Response, String> {
    let resp = client
        .get(url)
        // Tell the proxy: do NOT compress the response body
        .header(reqwest::header::ACCEPT_ENCODING, "identity")
        .timeout(std::time::Duration::from_secs(15))
        .send()
        .await
        .map_err(|e| format!("{}", e))?;

    if !resp.status().is_success() {
        return Err(format!("HTTP {}", resp.status().as_u16()));
    }

    Ok(resp)
}

/// Download a file with mirror fallback.
///
/// Tries the original URL first, then each mirror prefix. If a stream error
/// occurs mid-download, it resets and retries the next candidate from scratch.
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

    let mut last_error = String::new();

    for (idx, candidate) in candidates.iter().enumerate() {
        // Notify UI which source we're trying
        let _ = sink.add(DownloadProgress {
            received: 0,
            total: 0,
            done: false,
            saved_path: String::new(),
            error: if idx == 0 {
                "正在连接 GitHub...".to_string()
            } else {
                format!("正在尝试镜像 {}...", idx)
            },
        });

        let response = match try_connect(&client, candidate).await {
            Ok(r) => r,
            Err(e) => {
                last_error = format!("{}: {}", candidate, e);
                continue;
            }
        };

        let total = response.content_length().unwrap_or(0);
        let mut stream = response.bytes_stream();

        // Truncate (or create) the file for this attempt
        let mut file = match tokio::fs::File::create(&save_path).await {
            Ok(f) => f,
            Err(e) => {
                last_error = format!("创建文件失败: {}", e);
                continue;
            }
        };

        let mut received: u64 = 0;
        let mut stream_err = false;

        while let Some(chunk_result) = stream.next().await {
            match chunk_result {
                Ok(chunk) => {
                    if let Err(e) = file.write_all(&chunk).await {
                        last_error = format!("写入失败: {}", e);
                        stream_err = true;
                        break;
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
                Err(e) => {
                    last_error = format!("{}: 流错误 {}", candidate, e);
                    stream_err = true;
                    break;
                }
            }
        }

        if stream_err {
            // Try next mirror
            let _ = sink.add(DownloadProgress {
                received,
                total,
                done: false,
                saved_path: String::new(),
                error: format!("{}，尝试下一个源...", last_error),
            });
            continue;
        }

        let _ = file.flush().await;

        // Success
        let _ = sink.add(DownloadProgress {
            received,
            total,
            done: true,
            saved_path: save_path,
            error: String::new(),
        });
        return Ok(());
    }

    // All candidates failed
    let _ = sink.add(DownloadProgress {
        received: 0,
        total: 0,
        done: true,
        saved_path: String::new(),
        error: format!("所有下载源均失败: {}", last_error),
    });
    Ok(())
}

/// Stub for desktop/web platforms.
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
