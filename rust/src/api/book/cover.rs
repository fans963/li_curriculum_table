use crate::api::http;
use regex_lite::Regex;

pub async fn fetch_cover_url(isbn: String, title: String) -> anyhow::Result<Option<String>> {
    let clean_isbn = isbn.trim().to_string();
    let clean_title = title.trim().to_string();
    let client = http::build_client();

    // Fire all independent cover sources concurrently
    let (ol_isbn, ol_title, dangdang, douban, google) = tokio::join!(
        ol_cover_by_isbn(&client, &clean_isbn),
        ol_cover_by_title(&client, &clean_title),
        fetch_dangdang_cover(&client, &clean_isbn),
        fetch_douban_cover(&client, &clean_isbn),
        google_books_cover(&client, &clean_isbn, &clean_title),
    );

    // Return the first successful result (priority order)
    for result in [ol_isbn, ol_title, dangdang, douban, google] {
        if let Some(url) = result {
            return Ok(Some(url));
        }
    }

    Ok(None)
}

async fn ol_cover_by_isbn(client: &reqwest::Client, isbn: &str) -> Option<String> {
    if isbn.is_empty() {
        return None;
    }
    let encoded: String = url::form_urlencoded::byte_serialize(isbn.as_bytes()).collect();
    let api_url = format!(
        "https://openlibrary.org/search.json?isbn={}&limit=1&fields=cover_i",
        encoded
    );
    if let Some(cover_id) = ol_fetch_cover_id(client, &api_url).await {
        let url = format!("https://covers.openlibrary.org/b/id/{}-L.jpg", cover_id);
        if check_image_url(client, &url).await.is_some() {
            return Some(url);
        }
    }
    let direct_url = format!(
        "https://covers.openlibrary.org/b/isbn/{}-M.jpg?default=false",
        isbn
    );
    check_image_url(client, &direct_url).await
}

async fn ol_cover_by_title(client: &reqwest::Client, title: &str) -> Option<String> {
    if title.is_empty() {
        return None;
    }
    let encoded: String = url::form_urlencoded::byte_serialize(title.as_bytes()).collect();
    let api_url = format!(
        "https://openlibrary.org/search.json?q={}&limit=1&fields=cover_i",
        encoded
    );
    if let Some(cover_id) = ol_fetch_cover_id(client, &api_url).await {
        let url = format!("https://covers.openlibrary.org/b/id/{}-L.jpg", cover_id);
        return check_image_url(client, &url).await;
    }
    None
}

async fn ol_fetch_cover_id(client: &reqwest::Client, url: &str) -> Option<String> {
    let resp = client
        .get(url)
        .header("User-Agent", "CurriculumTableApp (contact@example.org)")
        .send()
        .await
        .ok()?;
    if resp.status() != reqwest::StatusCode::OK {
        return None;
    }
    let body: serde_json::Value = resp.json().await.ok()?;
    body["docs"]
        .as_array()?
        .first()?["cover_i"]
        .as_u64()
        .map(|id| id.to_string())
}

async fn google_books_cover(
    client: &reqwest::Client,
    isbn: &str,
    title: &str,
) -> Option<String> {
    let ua = "CurriculumTableApp (contact@example.org)";
    if !isbn.is_empty() {
        let url = format!(
            "https://www.googleapis.com/books/v1/volumes?q=isbn:{}",
            isbn
        );
        if let Some(cover) = gb_extract_thumbnail(client, &url, ua).await {
            return Some(cover);
        }
    }
    if !title.is_empty() {
        let encoded: String = url::form_urlencoded::byte_serialize(title.as_bytes()).collect();
        let url = format!(
            "https://www.googleapis.com/books/v1/volumes?q=intitle:{}&maxResults=1",
            encoded
        );
        if let Some(cover) = gb_extract_thumbnail(client, &url, ua).await {
            return Some(cover);
        }
    }
    None
}

async fn gb_extract_thumbnail(
    client: &reqwest::Client,
    url: &str,
    ua: &str,
) -> Option<String> {
    let resp = client.get(url).header("User-Agent", ua).send().await.ok()?;
    if resp.status() != reqwest::StatusCode::OK {
        return None;
    }
    let body: serde_json::Value = resp.json().await.ok()?;
    let thumbnail = body["items"]
        .as_array()?
        .first()?["volumeInfo"]["imageLinks"]["thumbnail"]
        .as_str()?;
    Some(thumbnail.replace("http://", "https://"))
}

async fn check_image_url(client: &reqwest::Client, url: &str) -> Option<String> {
    match client
        .head(url)
        .header("User-Agent", "CurriculumTableApp (contact@example.org)")
        .send()
        .await
    {
        Ok(resp) => {
            if !resp.status().is_success() {
                return None;
            }
            let is_image = resp
                .headers()
                .get("content-type")
                .and_then(|v| v.to_str().ok())
                .map(|ct| ct.starts_with("image/"))
                .unwrap_or(true);
            if !is_image {
                return None;
            }
            let size = resp
                .headers()
                .get("content-length")
                .and_then(|v| v.to_str().ok())
                .and_then(|v| v.parse::<u64>().ok());
            if let Some(bytes) = size {
                if bytes < 1024 {
                    return None;
                }
            }
            Some(url.to_string())
        }
        Err(_) => None,
    }
}

async fn fetch_dangdang_cover(client: &reqwest::Client, isbn: &str) -> Option<String> {
    if isbn.is_empty() {
        return None;
    }
    let encoded: String = url::form_urlencoded::byte_serialize(isbn.as_bytes()).collect();
    let search_url = format!("http://search.dangdang.com/?key={}&act=input", encoded);
    let resp = client
        .get(&search_url)
        .header("User-Agent", "Mozilla/5.0")
        .send()
        .await
        .ok()?;
    let html = resp.text().await.ok()?;
    let product_id = Regex::new(r"product\.dangdang\.com/(\d+)")
        .ok()?
        .captures(&html)?
        .get(1)?
        .as_str()
        .to_string();
    let product_url = format!("http://product.dangdang.com/{}.html", product_id);
    let resp = client
        .get(&product_url)
        .header("User-Agent", "Mozilla/5.0")
        .send()
        .await
        .ok()?;
    let html = resp.text().await.ok()?;
    let re = Regex::new(&format!(
        r#"(//[a-zA-Z0-9]+\.ddimg\.cn/[^"']*/{}-1_w_[^"']+)"#,
        regex_lite::escape(&product_id)
    ))
    .ok()?;
    let cover_url = format!("https:{}", re.captures(&html)?.get(1)?.as_str());
    check_image_url(client, &cover_url).await
}

async fn fetch_douban_cover(client: &reqwest::Client, isbn: &str) -> Option<String> {
    if isbn.is_empty() {
        return None;
    }
    let encoded: String = url::form_urlencoded::byte_serialize(isbn.as_bytes()).collect();
    let search_url = format!(
        "https://search.douban.com/book/subject_search?search_text={}",
        encoded
    );
    let resp = client
        .get(&search_url)
        .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
        .header("Referer", "https://book.douban.com/")
        .send()
        .await
        .ok()?;
    let html = resp.text().await.ok()?;
    let re = Regex::new(
        r#"(//img\d+\.doubanio\.com/view/subject/[a-z]+/public/s\d+\.(?:jpg|webp))"#,
    )
    .ok()?;
    let cover_url = format!("https:{}", re.captures(&html)?.get(1)?.as_str());
    let resp = client
        .get(&cover_url)
        .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
        .header("Referer", "https://book.douban.com/")
        .send()
        .await
        .ok()?;
    if resp.status().is_success() {
        let is_image = resp
            .headers()
            .get("content-type")
            .and_then(|v| v.to_str().ok())
            .map(|ct| ct.starts_with("image/"))
            .unwrap_or(false);
        if is_image {
            return Some(cover_url);
        }
    }
    None
}
