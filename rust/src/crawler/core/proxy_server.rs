use crate::api::crawler::get_shared_session_manager;
use crate::crawler::model::CrawlerConfig;
use reqwest::Method;
use std::net::SocketAddr;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use url::Url;

pub async fn start_proxy_server(port: u16) -> anyhow::Result<()> {
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = TcpListener::bind(addr).await?;
    log::info!("[V9] Proxy Server listening on {}", addr);

    loop {
        let (stream, peer_addr) = listener.accept().await?;
        log::debug!("[V9] Accepted connection from {}", peer_addr);
        
        tokio::spawn(async move {
            if let Err(e) = handle_connection(stream).await {
                log::error!("[V9] Connection error: {}", e);
            }
        });
    }
}

async fn handle_connection(mut stream: TcpStream) -> anyhow::Result<()> {
    let mut buffer = Vec::new();
    let mut temp_buf = [0; 4096];
    
    // 1. Read headers until \r\n\r\n
    let mut body_start = 0;
    loop {
        let n = stream.read(&mut temp_buf).await?;
        if n == 0 { break; }
        buffer.extend_from_slice(&temp_buf[..n]);
        
        let s = String::from_utf8_lossy(&buffer);
        if let Some(pos) = s.find("\r\n\r\n") {
            body_start = pos + 4;
            break;
        }
        if buffer.len() > 16384 { break; } // Safety limit for headers
    }

    if buffer.is_empty() { return Ok(()); }

    let request_head = String::from_utf8_lossy(&buffer[..body_start.min(buffer.len())]);
    let mut lines = request_head.lines();
    let first_line = lines.next().unwrap_or("");
    let parts: Vec<&str> = first_line.split_whitespace().collect();

    if parts.len() < 2 { return Ok(()); }
    let method_str = parts[0];
    let path = parts[1];
    
    // Extract relevant headers (Content-Length, Referer, Origin)
    let mut content_length = 0;
    let mut x_referer = None;
    let mut origin = None;
    
    for line in lines {
        let line_lower = line.to_lowercase();
        if line_lower.starts_with("content-length:") {
            content_length = line[15..].trim().parse::<usize>().unwrap_or(0);
        } else if line_lower.starts_with("x-alt-referer:") {
            x_referer = Some(line[14..].trim().to_string());
        } else if line_lower.starts_with("x-proxy-referer:") {
            x_referer = Some(line[16..].trim().to_string());
        } else if line_lower.starts_with("origin:") {
            origin = Some(line[7..].trim().to_string());
        }
    }

    let origin_str = origin.as_deref().unwrap_or("*");

    // Parse Method
    let method = match method_str {
        "POST" => Method::POST,
        "OPTIONS" => {
            send_cors_options(&mut stream, origin_str).await?;
            return Ok(());
        },
        _ => Method::GET,
    };

    // 2. Read full body if needed
    let mut body = Vec::new();
    if body_start < buffer.len() {
        body.extend_from_slice(&buffer[body_start..]);
    }
    
    while body.len() < content_length {
        let n = stream.read(&mut temp_buf).await?;
        if n == 0 { break; }
        body.extend_from_slice(&temp_buf[..n]);
    }
    if body.len() > content_length && content_length > 0 {
        body.truncate(content_length);
    }

    let body_opt = if body.is_empty() { None } else { Some(body) };

    // Simple routing
    if path == "/" || path == "/status" {
        send_response(&mut stream, 200, "OK", "Proxy is running", origin_str).await?;
    } else if path.starts_with("/proxy?") {
        handle_proxy_request(&mut stream, path, method, body_opt, x_referer.as_deref(), origin_str).await?;
    } else {
        send_response(&mut stream, 404, "Not Found", "Not Found", origin_str).await?;
    }

    Ok(())
}

async fn handle_proxy_request(
    stream: &mut TcpStream, 
    path: &str, 
    method: Method,
    body: Option<Vec<u8>>,
    referer: Option<&str>,
    origin: &str,
) -> anyhow::Result<()> {
    // Basic query param parsing: /proxy?url=...
    let url_param = path.split("url=").nth(1).unwrap_or("");
    let target_url = url::form_urlencoded::parse(url_param.as_bytes())
        .map(|(k, v)| if k == "" { v.into_owned() } else { k.into_owned() })
        .next()
        .unwrap_or_default();

    if target_url.is_empty() {
        send_response(stream, 400, "Bad Request", "Missing url parameter", origin).await?;
        return Ok(());
    }

    // Security: Only allow school domain
    let config = CrawlerConfig::default();
    let portal_host = Url::parse(&config.get_portal_url())?.host_str().unwrap_or("").to_string();
    
    if !target_url.contains(&portal_host) && !target_url.contains(":9080") {
        send_response(stream, 403, "Forbidden", "Target host not allowed", origin).await?;
        return Ok(());
    }

    log::info!("[V9] Forwarding {:?} request to: {}", method, target_url);

    let session = get_shared_session_manager().await?;
    
    // Forward the request with full parameters
    match session.fetch_raw(&target_url, method, body, referer).await {
        Ok(bytes) => {
            // Determine content type
            let content_type = if target_url.contains("verifycode") {
                "image/jpeg"
            } else if target_url.contains(".json") {
                "application/json"
            } else {
                "text/html; charset=utf-8"
            };
            send_binary_response(stream, 200, "OK", &bytes, content_type, origin).await?;
        }
        Err(e) => {
            let error_msg = format!("Upstream error: {}", e);
            log::error!("[V9] Proxy upstream error for {}: {}", target_url, e);
            send_binary_response(stream, 500, "Internal Server Error", error_msg.as_bytes(), "text/plain", origin).await?;
        }
    }

    Ok(())
}

async fn send_cors_options(stream: &mut TcpStream, origin: &str) -> anyhow::Result<()> {
    let response = format!(
        "HTTP/1.1 204 No Content\r\n\
         Access-Control-Allow-Origin: {}\r\n\
         Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n\
         Access-Control-Allow-Headers: Content-Type, Accept, X-Proxy-Cookie, X-Proxy-Referer, x-alt-referer, x-alt-cookie, X-Requested-With\r\n\
         Access-Control-Allow-Credentials: true\r\n\
         Access-Control-Max-Age: 86400\r\n\
         Connection: close\r\n\r\n",
        origin
    );
    stream.write_all(response.as_bytes()).await?;
    Ok(())
}

async fn send_binary_response(
    stream: &mut TcpStream, 
    status: u16, 
    status_text: &str, 
    body: &[u8], 
    content_type: &str,
    origin: &str,
) -> anyhow::Result<()> {
    let header = format!(
        "HTTP/1.1 {} {}\r\n\
         Content-Type: {}\r\n\
         Content-Length: {}\r\n\
         Access-Control-Allow-Origin: {}\r\n\
         Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n\
         Access-Control-Allow-Headers: *\r\n\
         Access-Control-Allow-Credentials: true\r\n\
         Connection: close\r\n\r\n",
        status, status_text, content_type, body.len(), origin
    );
    stream.write_all(header.as_bytes()).await?;
    stream.write_all(body).await?;
    Ok(())
}

async fn send_response(stream: &mut TcpStream, status: u16, status_text: &str, body: &str, origin: &str) -> anyhow::Result<()> {
    send_binary_response(stream, status, status_text, body.as_bytes(), "text/html; charset=utf-8", origin).await
}
