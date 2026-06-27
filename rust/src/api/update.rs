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

// ═══════════════════════════════════════════════════════════════════════════
// Download — native/mobile only
// ═══════════════════════════════════════════════════════════════════════════

#[cfg(not(target_arch = "wasm32"))]
pub async fn download_update(
    url: String,
    save_path: String,
    mirror_prefixes: Vec<String>,
    sink: crate::frb_generated::StreamSink<DownloadProgress>,
) -> Result<()> {
    use futures_util::StreamExt;
    use reqwest::header::{ACCEPT_ENCODING, HeaderValue};
    use std::path::Path;
    use tokio::io::{AsyncWriteExt, BufWriter};
    use tokio::time::Duration;

    let client = reqwest::Client::builder()
        .user_agent("li-curriculum-table")
        .no_gzip()
        .no_brotli()
        .no_zstd()
        .connect_timeout(Duration::from_secs(8))
        .build()
        .expect("Failed to build download client");

    // Candidates: mirrors first, original GitHub URL last
    let mut candidates: Vec<String> = mirror_prefixes.iter().map(|p| format!("{}{}", p, url)).collect();
    candidates.push(url);

    let _ = sink.add(DownloadProgress {
        received: 0, total: 0, done: false,
        saved_path: String::new(), error: "正在连接...".to_string(),
    });

    // ── Phase 1: race all candidates in parallel ──────────────────────────
    let mut winner: Option<(usize, reqwest::Response)> = None;
    {
        let mut handles = Vec::with_capacity(candidates.len());
        for (idx, u) in candidates.iter().enumerate() {
            let c = client.clone();
            let u = u.clone();
            handles.push(tokio::spawn(async move {
                let mut req = c.get(&u);
                req = req.header(ACCEPT_ENCODING, HeaderValue::from_static("identity"));
                match tokio::time::timeout(Duration::from_secs(8), req.send()).await {
                    Ok(Ok(resp)) if resp.status().is_success() => Some((idx, resp)),
                    _ => None,
                }
            }));
        }
        for handle in handles {
            if let Ok(Some(result)) = handle.await {
                winner = Some(result);
                break;
            }
        }
    }

    let Some((winner_idx, response)) = winner else {
        let _ = sink.add(DownloadProgress {
            received: 0, total: 0, done: true,
            saved_path: String::new(), error: "所有下载源均不可达".to_string(),
        });
        return Ok(());
    };

    // ── Phase 2: stream from the winning response ─────────────────────────
    let total = response.content_length().unwrap_or(0);

    if let Some(parent) = Path::new(&save_path).parent() {
        if let Err(e) = tokio::fs::create_dir_all(parent).await {
            let _ = sink.add(DownloadProgress {
                received: 0, total, done: true,
                saved_path: String::new(), error: format!("创建目录失败: {}", e),
            });
            return Ok(());
        }
    }

    match do_stream(response, &save_path, total, &sink).await {
        Ok(received) => {
            let _ = sink.add(DownloadProgress {
                received, total, done: true,
                saved_path: save_path, error: String::new(),
            });
            return Ok(());
        }
        Err(e) => {
            let _ = sink.add(DownloadProgress {
                received: 0, total, done: false,
                saved_path: String::new(), error: format!("{}，尝试回退...", e),
            });
        }
    }

    // ── Phase 3: sequential fallback on remaining candidates ──────────────
    for (idx, candidate) in candidates.iter().enumerate() {
        if idx == winner_idx { continue; }

        let mut req = client.get(candidate);
        req = req.header(ACCEPT_ENCODING, HeaderValue::from_static("identity"));
        let resp = match tokio::time::timeout(Duration::from_secs(8), req.send()).await {
            Ok(Ok(r)) if r.status().is_success() => r,
            _ => continue,
        };

        let _ = sink.add(DownloadProgress {
            received: 0, total: 0, done: false,
            saved_path: String::new(),
            error: format!("正在回退到源 {} / {}...", idx + 1, candidates.len()),
        });

        match do_stream(resp, &save_path, total, &sink).await {
            Ok(received) => {
                let _ = sink.add(DownloadProgress {
                    received, total, done: true,
                    saved_path: save_path, error: String::new(),
                });
                return Ok(());
            }
            Err(e) => {
                let _ = sink.add(DownloadProgress {
                    received: 0, total, done: false,
                    saved_path: String::new(), error: format!("{}，尝试下一个源...", e),
                });
            }
        }
    }

    let _ = sink.add(DownloadProgress {
        received: 0, total: 0, done: true,
        saved_path: String::new(), error: "所有下载源均失败".to_string(),
    });
    Ok(())
}

/// Stream a response body to disk, yielding progress via [sink].
#[cfg(not(target_arch = "wasm32"))]
async fn do_stream(
    response: reqwest::Response,
    save_path: &str,
    total: u64,
    sink: &crate::frb_generated::StreamSink<DownloadProgress>,
) -> Result<u64, String> {
    use futures_util::StreamExt;
    use tokio::io::{AsyncWriteExt, BufWriter};

    let file = tokio::fs::File::create(save_path)
        .await
        .map_err(|e| format!("创建文件失败: {}", e))?;
    let mut writer = BufWriter::new(file);
    let mut stream = response.bytes_stream();
    let mut received: u64 = 0;

    while let Some(chunk_result) = stream.next().await {
        let chunk = chunk_result.map_err(|e| format!("流错误: {}", e))?;
        writer.write_all(&chunk).await.map_err(|e| format!("写入失败: {}", e))?;
        received += chunk.len() as u64;

        let _ = sink.add(DownloadProgress {
            received, total, done: false,
            saved_path: String::new(), error: String::new(),
        });
    }

    writer.flush().await.map_err(|e| format!("刷新文件失败: {}", e))?;
    Ok(received)
}

// ── Web stub ─────────────────────────────────────────────────────────────

#[cfg(target_arch = "wasm32")]
pub async fn download_update(
    _url: String,
    _save_path: String,
    _mirror_prefixes: Vec<String>,
    sink: crate::frb_generated::StreamSink<DownloadProgress>,
) -> Result<()> {
    let _ = sink.add(DownloadProgress {
        received: 0, total: 0, done: true,
        saved_path: String::new(), error: "Web 端不支持应用内下载".to_string(),
    });
    Ok(())
}
