use crate::api::http;
use anyhow::Result;
use bytes::Bytes;
use crate::frb_generated::StreamSink;
use serde::Deserialize;
use std::path::Path;
use tokio::sync::mpsc;
use tokio::time::{Duration, Instant};
use tokio::fs::File as TokioFile;
use tokio::io::{AsyncWriteExt, BufWriter, AsyncSeekExt};
use std::sync::atomic::{AtomicI64, Ordering};
use std::sync::Arc;

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

#[derive(Debug, Clone)]
pub struct DownloadProgress {
    pub received: i32,
    pub total: i32,
    pub done: bool,
    pub saved_path: String,
    pub error: String,
}

struct RaceResult {
    url: String,
    response: reqwest::Response,
    first_chunks: Vec<Bytes>,
    elapsed_ms: u128,
}

pub async fn check_for_update() -> Result<UpdateData> {
    let client = http::build_client();

    let response = client
        .get("https://api.github.com/repos/fans963/li_curriculum_table/releases/latest")
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

pub async fn download_update(
    url: String,
    save_path: String,
    proxy: Option<String>,
    sink: StreamSink<DownloadProgress>,
) -> Result<()> {
    log::info!("OTA: download_update called. URL: {}, Proxy: {:?}", url, proxy);

    // Gitee primary mirror candidate
    let gitee_url = url.replace("github.com", "gitee.com");

    let mirror_prefixes = vec![
        "https://gh-proxy.com/",
        "https://ghproxy.net/",
        "https://ghfast.top/",
    ];

    // Build the list of mirror candidates to race.
    // CRITICAL:
    // 1. We place Gitee at the front of the list as the primary download source.
    // 2. We exclude the direct github.com URL from the parallel race because github.com
    //    has a fast handshake (1-2s) but is severely throttled (10-30KB/s) in China.
    let mut mirror_candidates = vec![gitee_url];
    for p in mirror_prefixes {
        mirror_candidates.push(format!("{}{}", p, url));
    }

    let _ = sink.add(DownloadProgress {
        received: 0,
        total: 0,
        done: false,
        saved_path: "".to_string(),
        error: "正在连接...".to_string(),
    });

    // Build a dedicated downloader client with a generous connect timeout (10s),
    // tcp keepalive, but NO overall request timeout.
    let mut builder = reqwest::Client::builder()
        .user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        .connect_timeout(Duration::from_secs(10))
        .tcp_keepalive(Duration::from_secs(30));

    // Configure system proxy if provided
    if let Some(ref p_str) = proxy {
        if !p_str.trim().is_empty() && p_str != "DIRECT" {
            let parts: Vec<&str> = p_str.split(';').collect();
            if let Some(first_proxy) = parts.first() {
                let cleaned = first_proxy.replace("PROXY", "").trim().to_string();
                if !cleaned.is_empty() {
                    let proxy_url = if cleaned.starts_with("http://") || cleaned.starts_with("https://") {
                        cleaned
                    } else {
                        format!("http://{}", cleaned)
                    };
                    if let Ok(reqwest_proxy) = reqwest::Proxy::all(&proxy_url) {
                        log::info!("OTA: Configuring download client with system proxy: {}", proxy_url);
                        builder = builder.proxy(reqwest_proxy);
                    }
                }
            }
        }
    }

    let downloader_client = builder.build()?;

    // Phase 1: Race mirror candidates in parallel
    let (tx, mut rx) = mpsc::channel(mirror_candidates.len());

    for u in mirror_candidates.clone() {
        let tx = tx.clone();
        let client = downloader_client.clone();
        tokio::spawn(async move {
            let start = Instant::now();
            let run = async {
                let mut resp = client.get(&u)
                    .send()
                    .await?;
                if !resp.status().is_success() {
                    return Err(anyhow::anyhow!("Status not success: {}", resp.status()));
                }

                let mut first_chunks = Vec::new();
                let mut bytes_read = 0;
                const TARGET_SIZE: usize = 64 * 1024; // 64KB

                while bytes_read < TARGET_SIZE {
                    match tokio::time::timeout(Duration::from_secs(8), resp.chunk()).await {
                        Ok(Ok(Some(chunk))) => {
                            bytes_read += chunk.len();
                            first_chunks.push(chunk);
                        }
                        Ok(Ok(None)) => break,
                        Ok(Err(e)) => return Err(anyhow::anyhow!("Chunk read error: {}", e)),
                        Err(_) => return Err(anyhow::anyhow!("Chunk read timeout")),
                    }
                }

                Ok(RaceResult {
                    url: u.clone(),
                    response: resp,
                    first_chunks,
                    elapsed_ms: start.elapsed().as_millis(),
                })
            };

            match tokio::time::timeout(Duration::from_secs(8), run).await {
                Ok(Ok(res)) => {
                    log::info!("OTA Race: {} -> Connected & Read 64KB in {}ms", res.url, res.elapsed_ms);
                    let _ = tx.send(Some(res)).await;
                }
                Ok(Err(e)) => {
                    log::warn!("OTA Race Error: {} -> {}", u, e);
                    let _ = tx.send(None).await;
                }
                Err(_) => {
                    log::warn!("OTA Race Timeout: {}", u);
                    let _ = tx.send(None).await;
                }
            }
        });
    }

    // Wait for the winner
    let mut winner: Option<RaceResult> = None;
    let mut failures = 0;
    let total_candidates = mirror_candidates.len();

    let race_start = Instant::now();
    while failures < total_candidates && race_start.elapsed().as_secs() < 12 {
        tokio::select! {
            res = rx.recv() => {
                match res {
                    Some(Some(race_res)) => {
                        winner = Some(race_res);
                        break;
                    }
                    _ => {
                        failures += 1;
                    }
                }
            }
            _ = tokio::time::sleep(Duration::from_millis(50)) => {}
        }
    }

    if winner.is_none() {
        return download_fallback(mirror_candidates, &url, &save_path, sink, downloader_client).await;
    }

    let mut race_winner = winner.unwrap();
    log::info!("OTA CONNECT WINNER: {} (selected after {}ms)", race_winner.url, race_winner.elapsed_ms);

    let total = race_winner.response.content_length().unwrap_or(0);
    
    // Check if the mirror server explicitly supports range requests.
    // Default to FALSE if missing (e.g. Gitee redirector) to ensure safety.
    let accepts_ranges = race_winner.response.headers()
        .get(reqwest::header::ACCEPT_RANGES)
        .map(|v| v == "bytes")
        .unwrap_or(false);

    let num_threads = 4;
    if total > 5 * 1024 * 1024 && accepts_ranges {
        log::info!("OTA: Starting parallel multi-threaded download (4 threads) for speed acceleration...");
        
        let path = Path::new(&save_path);
        if let Some(parent) = path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }
        
        // Pre-create the file and pre-allocate its length
        let file = TokioFile::create(path).await?;
        file.set_len(total).await?;
        drop(file);

        let received_counter = Arc::new(AtomicI64::new(0));
        let mut tasks = Vec::new();
        let chunk_size = (total + num_threads - 1) / num_threads;

        let download_sw = Instant::now();
        let mut last_speed_print = Instant::now();
        let mut last_ui_print = Instant::now();

        for i in 0..num_threads {
            let start = i * chunk_size;
            let end = std::cmp::min((i + 1) * chunk_size - 1, total - 1);
            
            let client = downloader_client.clone();
            let url = race_winner.url.clone();
            let path_str = save_path.clone();
            let received_counter = received_counter.clone();

            let task = tokio::spawn(async move {
                let run_chunk = async {
                    let mut resp = client.get(&url)
                        .header("Range", format!("bytes={}-{}", start, end))
                        .send()
                        .await?;
                    
                    // CRITICAL: If the server ignored the Range header and returned 200 OK
                    // instead of 206 Partial Content, we must abort and fall back to single-threaded download.
                    if resp.status() != reqwest::StatusCode::PARTIAL_CONTENT {
                        return Err(anyhow::anyhow!(
                            "Server does not support range requests (status: {})",
                            resp.status()
                        ));
                    }
                    
                    let mut chunk_file = TokioFile::options()
                        .write(true)
                        .open(&path_str)
                        .await?;
                    chunk_file.seek(std::io::SeekFrom::Start(start)).await?;
                    
                    let mut buf_file = BufWriter::with_capacity(64 * 1024, chunk_file);
                    
                    while let Some(chunk) = resp.chunk().await? {
                        buf_file.write_all(&chunk).await?;
                        received_counter.fetch_add(chunk.len() as i64, Ordering::SeqCst);
                    }
                    buf_file.flush().await?;
                    buf_file.into_inner().sync_all().await?;
                    Ok(())
                };
                
                run_chunk.await
            });
            tasks.push(task);
        }

        // Monitor progress
        let mut all_done = false;
        while !all_done {
            tokio::time::sleep(Duration::from_millis(100)).await;
            let current_received = received_counter.load(Ordering::SeqCst) as i32;
            
            let now = Instant::now();
            if now.duration_since(last_speed_print).as_secs() >= 1 {
                let elapsed_secs = download_sw.elapsed().as_secs_f64();
                let speed = if elapsed_secs > 0.0 { current_received as f64 / elapsed_secs } else { 0.0 };
                let pct = format!("{:.1}%", (current_received as f64 * 100.0 / total as f64));
                log::info!("OTA Download Progress (Rust Parallel): {} / {} bytes ({}), Speed: {}", current_received, total, pct, fmt_speed(speed));
                last_speed_print = now;
            }

            if now.duration_since(last_ui_print).as_millis() >= 300 {
                let _ = sink.add(DownloadProgress {
                    received: current_received,
                    total: total as i32,
                    done: false,
                    saved_path: "".to_string(),
                    error: "".to_string(),
                });
                last_ui_print = now;
            }
            
            all_done = true;
            for t in &tasks {
                if !t.is_finished() {
                    all_done = false;
                    break;
                }
            }
        }

        // Catch errors and trigger single-threaded fallback if any chunk task fails
        let mut parallel_failed = false;
        for t in tasks {
            match t.await {
                Ok(Ok(_)) => {}
                Ok(Err(e)) => {
                    log::warn!("Parallel chunk download failed: {}. Falling back to single-thread...", e);
                    parallel_failed = true;
                }
                Err(e) => {
                    log::warn!("Parallel task join failed: {}. Falling back to single-thread...", e);
                    parallel_failed = true;
                }
            }
        }

        if parallel_failed {
            // Delete the corrupted/pre-allocated file and run fallback download
            let _ = tokio::fs::remove_file(&save_path).await;
            log::info!("OTA: Restarting download in single-threaded fallback mode...");
            return download_fallback(vec![race_winner.url.clone()], &url, &save_path, sink, downloader_client).await;
        }
        
        let final_received = received_counter.load(Ordering::SeqCst) as i32;
        let elapsed_secs = download_sw.elapsed().as_secs_f64();
        let speed = if elapsed_secs > 0.0 { final_received as f64 / elapsed_secs } else { 0.0 };
        log::info!("OTA Download Completed (Rust Parallel): Total {} bytes, Avg Speed: {}, Time: {}ms", final_received, fmt_speed(speed), download_sw.elapsed().as_millis());

        let _ = sink.add(DownloadProgress {
            received: final_received,
            total: total as i32,
            done: true,
            saved_path: save_path.clone(),
            error: "".to_string(),
        });
    } else {
        log::info!("OTA: Server does not support range requests. Using single-threaded streaming download...");
        // Phase 2: Stream remaining data from the winner in single thread
        let mut received = 0i32;

        let path = Path::new(&save_path);
        if let Some(parent) = path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }
        
        let raw_file = TokioFile::create(path).await?;
        let mut file = BufWriter::with_capacity(128 * 1024, raw_file);

        // Write the pre-read chunks
        for chunk in &race_winner.first_chunks {
            file.write_all(chunk).await?;
            received += chunk.len() as i32;
        }

        let _ = sink.add(DownloadProgress {
            received,
            total: if total > 0 { total as i32 } else { 0 },
            done: false,
            saved_path: "".to_string(),
            error: "".to_string(),
        });

        let download_sw = Instant::now();
        let mut last_speed_print = Instant::now();
        let mut last_ui_print = Instant::now();

        while let Some(chunk) = race_winner.response.chunk().await? {
            file.write_all(&chunk).await?;
            received += chunk.len() as i32;

            let now = Instant::now();

            if now.duration_since(last_speed_print).as_secs() >= 1 {
                let elapsed_secs = download_sw.elapsed().as_secs_f64();
                let speed = if elapsed_secs > 0.0 { received as f64 / elapsed_secs } else { 0.0 };
                let pct = if total > 0 {
                    format!("{:.1}%", (received as f64 * 100.0 / total as f64))
                } else {
                    "unknown".to_string()
                };
                log::info!("OTA Download Progress (Rust): {} / {} bytes ({}), Speed: {}", received, total, pct, fmt_speed(speed));
                last_speed_print = now;
            }

            if now.duration_since(last_ui_print).as_millis() >= 300 {
                let _ = sink.add(DownloadProgress {
                    received,
                    total: if total > 0 { total as i32 } else { 0 },
                    done: false,
                    saved_path: "".to_string(),
                    error: "".to_string(),
                });
                last_ui_print = now;
            }
        }

        file.flush().await?;
        file.get_mut().sync_all().await?;
        let elapsed_secs = download_sw.elapsed().as_secs_f64();
        let speed = if elapsed_secs > 0.0 { received as f64 / elapsed_secs } else { 0.0 };
        log::info!("OTA Download Completed (Rust): Total {} bytes, Avg Speed: {}, Time: {}ms", received, fmt_speed(speed), download_sw.elapsed().as_millis());

        let _ = sink.add(DownloadProgress {
            received,
            total: if total > 0 { total as i32 } else { 0 },
            done: true,
            saved_path: save_path.clone(),
            error: "".to_string(),
        });
    }

    Ok(())
}

async fn download_fallback(
    mirror_candidates: Vec<String>,
    direct_url: &str,
    save_path: &str,
    sink: StreamSink<DownloadProgress>,
    client: reqwest::Client,
) -> Result<()> {
    log::warn!("OTA: stream error or race failed, trying fallbacks sequentially...");
    
    let mut fallback_candidates = mirror_candidates;
    fallback_candidates.push(direct_url.to_string());

    let mut last_error = String::new();

    for candidate in fallback_candidates {
        log::info!("OTA Fallback: trying {}...", candidate);
        let _ = sink.add(DownloadProgress {
            received: 0,
            total: 0,
            done: false,
            saved_path: "".to_string(),
            error: format!("正在回退到 {}...", candidate),
        });

        let run_fallback = async {
            let mut resp = client.get(&candidate)
                .send()
                .await?;
            if !resp.status().is_success() {
                return Err(anyhow::anyhow!("Status: {}", resp.status()));
            }

            let total = resp.content_length().unwrap_or(0) as i32;
            let mut r = 0i32;
            let path = Path::new(save_path);
            let raw_file = TokioFile::create(path).await?;
            let mut file = BufWriter::with_capacity(128 * 1024, raw_file);
            let mut last_ui = Instant::now();

            while let Some(chunk) = resp.chunk().await? {
                file.write_all(&chunk).await?;
                r += chunk.len() as i32;

                let now = Instant::now();
                if now.duration_since(last_ui).as_millis() >= 300 {
                    let _ = sink.add(DownloadProgress {
                        received: r,
                        total: if total > 0 { total } else { 0 },
                        done: false,
                        saved_path: "".to_string(),
                        error: "".to_string(),
                    });
                    last_ui = now;
                }
            }

            file.flush().await?;
            file.get_mut().sync_all().await?;
            Ok::<i32, anyhow::Error>(r)
        };

        match tokio::time::timeout(Duration::from_secs(600), run_fallback).await {
            Ok(Ok(r)) => {
                let _ = sink.add(DownloadProgress {
                    received: r,
                    total: r,
                    done: true,
                    saved_path: save_path.to_string(),
                    error: "".to_string(),
                });
                return Ok(());
            }
            Ok(Err(e)) => {
                last_error.push_str(&format!("\n{}: {}", candidate, e));
            }
            Err(_) => {
                last_error.push_str(&format!("\n{}: Timeout", candidate));
            }
        }
    }

    let _ = sink.add(DownloadProgress {
        received: 0,
        total: 0,
        done: true,
        saved_path: "".to_string(),
        error: format!("所有下载源均失败: {}", last_error),
    });

    Err(anyhow::anyhow!("All candidates failed: {}", last_error))
}

fn fmt_speed(bytes_per_sec: f64) -> String {
    if bytes_per_sec < 1024.0 {
        format!("{:.1} B/s", bytes_per_sec)
    } else if bytes_per_sec < 1024.0 * 1024.0 {
        format!("{:.1} KB/s", bytes_per_sec / 1024.0)
    } else {
        format!("{:.1} MB/s", bytes_per_sec / (1024.0 * 1024.0))
    }
}
