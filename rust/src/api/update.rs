use crate::api::http;
use anyhow::Result;
use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
struct GiteeRelease {
    tag_name: Option<String>,
    name: Option<String>,
    body: Option<String>,
    created_at: Option<String>,
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

const GITEE_OWNER: &str = "fans963";
const GITEE_REPO: &str = "li_curriculum_table";
const VERCEL_MANIFEST: &str = "https://li-table.vercel.app/manifest.json";

#[derive(Debug, Clone, Deserialize)]
struct VercelManifest {
    version: Option<String>,
    published: Option<String>,
}

pub async fn check_for_update() -> Result<UpdateData> {
    let client = http::build_client();

    // Try Vercel manifest first (fastest, no rate limit)
    if let Ok(vercel) = check_vercel_manifest(&client).await {
        return Ok(vercel);
    }

    // Fall back to Gitee API
    check_gitee_api(&client).await
}

async fn check_vercel_manifest(client: &reqwest::Client) -> Result<UpdateData> {
    let response = client
        .get(VERCEL_MANIFEST)
        .header("User-Agent", "li-curriculum-table")
        .send()
        .await?;

    let status = response.status();
    if !status.is_success() {
        return Err(anyhow::anyhow!("Vercel manifest returned {}", status.as_u16()));
    }

    let data: VercelManifest = response.json().await?;
    let version = data.version.unwrap_or_default();
    if version.is_empty() {
        return Err(anyhow::anyhow!("Empty version in Vercel manifest"));
    }

    Ok(UpdateData {
        latest_version: version.clone(),
        release_url: format!("https://li-table.vercel.app/releases/v{}", version),
        release_notes: String::new(),
        published_at: data.published.unwrap_or_default(),
    })
}

async fn check_gitee_api(client: &reqwest::Client) -> Result<UpdateData> {
    let response = client
        .get(format!(
            "https://gitee.com/api/v5/repos/{}/{}/releases/latest",
            GITEE_OWNER, GITEE_REPO
        ))
        .header("User-Agent", "li-curriculum-table")
        .send()
        .await?;

    let status = response.status();
    if !status.is_success() {
        return Err(anyhow::anyhow!(
            "Gitee API returned status {}",
            status.as_u16()
        ));
    }

    let data: GiteeRelease = response.json().await?;

    let tag = data.tag_name.unwrap_or_default();
    let latest_version = tag.trim_start_matches('v').to_string();
    let release_url = format!(
        "https://gitee.com/{}/{}/releases/tag/{}",
        GITEE_OWNER, GITEE_REPO, tag
    );
    let release_notes = data.body.unwrap_or_default();
    let published_at = data.created_at.unwrap_or_default();

    Ok(UpdateData {
        latest_version,
        release_url,
        release_notes,
        published_at,
    })
}

/// Extract version from a release download URL path.
/// e.g. ".../download/v2.0.0/app.apk" → Some("2.0.0")
fn extract_version_from_url(url: &str) -> Option<String> {
    let segments: Vec<&str> = url.split('/').collect();
    for (i, seg) in segments.iter().enumerate() {
        if *seg == "download" && i + 1 < segments.len() {
            let v = segments[i + 1];
            return Some(v.trim_start_matches('v').to_string());
        }
    }
    None
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
    use reqwest::header::{HeaderValue, ACCEPT_ENCODING};
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

    // Build Gitee download URL from the original GitHub URL.
    // e.g. "...releases/download/v2.0.0/app.apk" → gitee.com/.../download/v2.0.0/app.apk
    let filename = url.rsplit('/').next().unwrap_or("");
    let version = extract_version_from_url(&url).unwrap_or_default();

    // Priority: Vercel CDN first (fastest globally), then Gitee, then mirrors, then GitHub
    let mut candidates: Vec<String> = Vec::new();
    if !filename.is_empty() && !version.is_empty() {
        candidates.push(format!(
            "https://li-table.vercel.app/releases/v{}/{}",
            version, filename
        ));
        candidates.push(format!(
            "https://gitee.com/{}/{}/releases/download/v{}/{}",
            GITEE_OWNER, GITEE_REPO, version, filename
        ));
    }
    candidates.extend(
        mirror_prefixes
            .iter()
            .map(|p| format!("{}{}", p, url))
    );
    candidates.push(url);

    let _ = sink.add(DownloadProgress {
        received: 0,
        total: 0,
        done: false,
        saved_path: String::new(),
        error: "正在连接...".to_string(),
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
            received: 0,
            total: 0,
            done: true,
            saved_path: String::new(),
            error: "所有下载源均不可达".to_string(),
        });
        return Ok(());
    };

    // ── Phase 2: stream from the winning response ─────────────────────────
    let total = response.content_length().unwrap_or(0);

    if let Some(parent) = Path::new(&save_path).parent() {
        if let Err(e) = tokio::fs::create_dir_all(parent).await {
            let _ = sink.add(DownloadProgress {
                received: 0,
                total,
                done: true,
                saved_path: String::new(),
                error: format!("创建目录失败: {}", e),
            });
            return Ok(());
        }
    }

    match do_stream(response, &save_path, total, &sink).await {
        Ok(received) => {
            let _ = sink.add(DownloadProgress {
                received,
                total,
                done: true,
                saved_path: save_path,
                error: String::new(),
            });
            return Ok(());
        }
        Err(e) => {
            let _ = sink.add(DownloadProgress {
                received: 0,
                total,
                done: false,
                saved_path: String::new(),
                error: format!("{}，尝试回退...", e),
            });
        }
    }

    // ── Phase 3: sequential fallback on remaining candidates ──────────────
    for (idx, candidate) in candidates.iter().enumerate() {
        if idx == winner_idx {
            continue;
        }

        let mut req = client.get(candidate);
        req = req.header(ACCEPT_ENCODING, HeaderValue::from_static("identity"));
        let resp = match tokio::time::timeout(Duration::from_secs(8), req.send()).await {
            Ok(Ok(r)) if r.status().is_success() => r,
            _ => continue,
        };

        let _ = sink.add(DownloadProgress {
            received: 0,
            total: 0,
            done: false,
            saved_path: String::new(),
            error: format!("正在回退到源 {} / {}...", idx + 1, candidates.len()),
        });

        match do_stream(resp, &save_path, total, &sink).await {
            Ok(received) => {
                let _ = sink.add(DownloadProgress {
                    received,
                    total,
                    done: true,
                    saved_path: save_path,
                    error: String::new(),
                });
                return Ok(());
            }
            Err(e) => {
                let _ = sink.add(DownloadProgress {
                    received: 0,
                    total,
                    done: false,
                    saved_path: String::new(),
                    error: format!("{}，尝试下一个源...", e),
                });
            }
        }
    }

    let _ = sink.add(DownloadProgress {
        received: 0,
        total: 0,
        done: true,
        saved_path: String::new(),
        error: "所有下载源均失败".to_string(),
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
        writer
            .write_all(&chunk)
            .await
            .map_err(|e| format!("写入失败: {}", e))?;
        received += chunk.len() as u64;

        let _ = sink.add(DownloadProgress {
            received,
            total,
            done: false,
            saved_path: String::new(),
            error: String::new(),
        });
    }

    writer
        .flush()
        .await
        .map_err(|e| format!("刷新文件失败: {}", e))?;
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
        received: 0,
        total: 0,
        done: true,
        saved_path: String::new(),
        error: "Web 端不支持应用内下载".to_string(),
    });
    Ok(())
}
