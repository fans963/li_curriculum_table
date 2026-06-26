use crate::api::http;
use regex_lite::Regex;
use scraper::{Html, Selector};

/// Advanced search parameters mirroring the OPAC search_more.php form.
#[derive(Debug, Clone, Default)]
pub struct BookSearchParams {
    /// Search field: "title", "author", "publisher", "isbn", "keyword", "callno", "series"
    pub search_type: String,
    /// The search query text
    pub query: String,
    /// Document type filter (default "ALL")
    pub doctype: String,
    /// Language code filter (default "ALL")
    pub lang_code: String,
    /// Results per page: 20, 30, 50, 100 (default 20)
    pub displaypg: u32,
    /// Sort field (default "CATA_DATE")
    pub sort: String,
    /// Sort order: "asc" or "desc" (default "DESC")
    pub orderby: String,
    /// Campus filter: "ALL", "00"=南京, "06"=江阴 (default "ALL")
    pub dept: String,
    /// Show mode: "list" or "table" (default "list")
    pub showmode: String,
    /// Page number (1-based, default 1)
    pub page: u32,
}

impl BookSearchParams {
    pub fn new(query: String) -> Self {
        Self {
            search_type: "title".to_string(),
            query,
            doctype: "ALL".to_string(),
            lang_code: "ALL".to_string(),
            displaypg: 20,
            sort: "CATA_DATE".to_string(),
            orderby: "DESC".to_string(),
            dept: "ALL".to_string(),
            showmode: "list".to_string(),
            page: 1,
        }
    }

    /// Build the search URL from parameters.
    pub fn build_url(&self) -> String {
        let encoded: String =
            url::form_urlencoded::byte_serialize(self.query.as_bytes()).collect();
        let mut url = format!(
            "http://202.119.83.14:8080/uopac/opac/openlink.php?strSearchType={}&historyCount=1&strText={}&doctype={}&lang_code={}&displaypg={}&sort={}&orderby={}&dept={}&showmode={}&match_flag=forward&with_ebook=on",
            self.search_type,
            encoded,
            self.doctype,
            self.lang_code,
            self.displaypg,
            self.sort,
            self.orderby,
            self.dept,
            self.showmode,
        );
        if self.page > 1 {
            url.push_str(&format!("&page={}", self.page));
        }
        url
    }
}

#[derive(Debug, Clone)]
pub struct BookInfo {
    pub title: String,
    pub author: String,
    pub publisher: String,
    pub call_no: String,
    pub doc_type: String,
    pub holdings_summary: String,
    pub detail_url: String,
}

#[derive(Debug, Clone)]
pub struct BookLocation {
    pub location: String,
    pub status: String,
}

/// Result of a book search including total count for pagination.
#[derive(Debug, Clone)]
pub struct BookSearchResult {
    pub books: Vec<BookInfo>,
    pub total_count: u32,
}

pub async fn search_books(title: String) -> anyhow::Result<BookSearchResult> {
    if title.trim().is_empty() {
        return Ok(BookSearchResult { books: Vec::new(), total_count: 0 });
    }
    let encoded: String = url::form_urlencoded::byte_serialize(title.as_bytes()).collect();
    let url = format!(
        "http://202.119.83.14:8080/uopac/opac/openlink.php?strSearchType=title&historyCount=1&strText={}&doctype=ALL&displaypg=20&showmode=list&with_ebook=on",
        encoded
    );
    search_and_parse(&url).await
}

/// Advanced search with full parameters.
pub async fn search_books_advanced(params: BookSearchParams) -> anyhow::Result<BookSearchResult> {
    if params.query.trim().is_empty() {
        return Ok(BookSearchResult { books: Vec::new(), total_count: 0 });
    }
    search_and_parse(&params.build_url()).await
}

/// Core search: build URL, fetch, parse.
async fn search_and_parse(target_url: &str) -> anyhow::Result<BookSearchResult> {
    let client = http::build_client();

    println!("BookCrawler: [Request] {}", target_url);

    let response = client.get(target_url).send().await?;

    let status = response.status();
    println!("BookCrawler: [Response] status: {}, url: {}", status, response.url());

    let html_content = response.text().await?;
    println!("BookCrawler: [Data] received {} bytes", html_content.len());



    let document = Html::parse_document(&html_content);

    let book_list_selector = Selector::parse("ol#search_book_list").unwrap();
    let item_selector = Selector::parse("li.book_list_info").unwrap();

    let mut books = Vec::new();

    if let Some(book_list_el) = document.select(&book_list_selector).next() {
        for item in book_list_el.select(&item_selector) {
            let h3_selector = Selector::parse("h3").unwrap();
            let a_selector = Selector::parse("a").unwrap();
            let span_selector = Selector::parse("span").unwrap();
            let p_selector = Selector::parse("p").unwrap();

            if let Some(h3_el) = item.select(&h3_selector).next() {
                if let Some(a_el) = h3_el.select(&a_selector).next() {
                    let title_full = a_el.text().collect::<Vec<_>>().join("").trim().to_string();

                    let title = if let Some(dot_idx) = title_full.find('.') {
                        if dot_idx < 4 {
                            title_full[dot_idx + 1..].trim().to_string()
                        } else {
                            title_full.clone()
                        }
                    } else {
                        title_full.clone()
                    };

                    let relative_href = a_el.value().attr("href").unwrap_or("").to_string();
                    let detail_url = resolve_detail_url(&relative_href);

                    let doc_type = h3_el
                        .select(&span_selector)
                        .next()
                        .map(|s| s.text().collect::<Vec<_>>().join("").trim().to_string())
                        .unwrap_or_else(|| "未知类型".to_string());

                    let mut call_no = String::new();
                    for node in h3_el.children() {
                        if let Some(text_node) = node.value().as_text() {
                            let text = text_node.trim();
                            if !text.is_empty() {
                                call_no = text.to_string();
                            }
                        }
                    }
                    let call_no = call_no
                        .trim_start_matches([' ', '-', '/', ':'])
                        .trim()
                        .to_string();

                    let mut holdings_summary = "未知".to_string();
                    let mut author = "未知作者".to_string();
                    let mut publisher = "未知出版信息".to_string();

                    if let Some(p_el) = item.select(&p_selector).next() {
                        let mut all_texts = Vec::new();
                        for text_el in p_el.text() {
                            let trimmed = text_el.trim();
                            if !trimmed.is_empty() {
                                all_texts.push(trimmed.to_string());
                            }
                        }
                        if all_texts.len() >= 2 {
                            holdings_summary = all_texts[..2].join(" ");
                        }
                        if all_texts.len() > 2 {
                            author = all_texts[2].clone();
                        }
                        if all_texts.len() > 3 {
                            publisher = all_texts[3].clone();
                        }
                    }

                    books.push(BookInfo {
                        title,
                        author,
                        publisher,
                        call_no,
                        doc_type,
                        holdings_summary,
                        detail_url,
                    });
                }
            }
        }
    }

    let total_count = parse_total_count(&html_content);

    Ok(BookSearchResult { books, total_count })
}

/// Parse total result count from the page by stripping HTML tags first,
/// then matching "检索到 N 条".
fn parse_total_count(html: &str) -> u32 {
    // Strip HTML tags: replace <...> with nothing
    let re_tag = Regex::new(r"<[^>]*>").ok();
    let plain = if let Some(re) = &re_tag {
        re.replace_all(html, "")
    } else {
        return 0;
    };
    // Collapse whitespace
    let plain = plain.replace(char::is_whitespace, " ");
    let re = Regex::new(r"检索到\s*(\d+)\s*条").ok();
    if let Some(re) = &re {
        if let Some(caps) = re.captures(&plain) {
            if let Some(m) = caps.get(1) {
                return m.as_str().parse::<u32>().unwrap_or(0);
            }
        }
    }
    // Fallback: "count=N" in URLs
    let re2 = Regex::new(r"[&?]count=(\d+)").ok();
    if let Some(re) = &re2 {
        if let Some(caps) = re.captures(html) {
            if let Some(m) = caps.get(1) {
                return m.as_str().parse::<u32>().unwrap_or(0);
            }
        }
    }
    0
}

/// Resolve a relative or absolute detail URL.
fn resolve_detail_url(href: &str) -> String {
    if href.starts_with("http") {
        href.to_string()
    } else {
        format!(
            "http://202.119.83.14:8080/uopac/opac/{}",
            href.trim_start_matches("./")
        )
    }
}

#[derive(Debug, Clone)]
pub struct BookDetail {
    pub isbn: String,
    pub price: String,
    pub pages: String,
    pub locations: Vec<BookLocation>,
}

pub async fn fetch_book_locations(detail_url: String) -> anyhow::Result<BookDetail> {
    if detail_url.is_empty() {
        return Ok(BookDetail {
            isbn: "无".to_string(),
            price: "无".to_string(),
            pages: "无".to_string(),
            locations: Vec::new(),
        });
    }

    let client = http::build_client();

    println!("BookCrawler: [Request] detail: {}", detail_url);

    let response = client.get(&detail_url)
        .send()
        .await?;

    println!("BookCrawler: [Response] detail status: {}, url: {}", response.status(), response.url());
    let html_content = response.text().await?;
    println!("BookCrawler: [Data] detail received {} bytes", html_content.len());
    let document = Html::parse_document(&html_content);
    
    let mut isbn = "无".to_string();
    let mut price = "无".to_string();
    let mut pages = "无".to_string();

    // New format (2026): generic dl/dt/dd pairs, not dl.booklist
    let dl_selector = Selector::parse("dl").unwrap();
    let dt_selector = Selector::parse("dt").unwrap();
    let dd_selector = Selector::parse("dd").unwrap();

    for dl in document.select(&dl_selector) {
        for (dt, dd) in dl.select(&dt_selector).zip(dl.select(&dd_selector)) {
            let dt_text = dt.text().collect::<Vec<_>>().join("").trim().to_string();
            let dd_text = dd.text().collect::<Vec<_>>().join("").trim().to_string();

            if dt_text.contains("ISBN及定价") {
                let parts: Vec<&str> = dd_text.split('/').collect();
                if !parts.is_empty() {
                    isbn = parts[0].trim().to_string();
                }
                if parts.len() > 1 {
                    price = parts[1].trim().to_string();
                }
            } else if dt_text.contains("载体形态项") {
                if let Some(idx) = dd_text.find('页') {
                    pages = dd_text[..idx + '页'.len_utf8()].trim().to_string();
                } else if let Some(idx) = dd_text.find(" p.") {
                    pages = dd_text[..idx + 3].trim().to_string();
                } else if let Some(idx) = dd_text.find("p.") {
                    pages = dd_text[..idx + 2].trim().to_string();
                } else {
                    pages = dd_text.clone();
                }
            }
        }
    }

    let table_selector = Selector::parse("table#item").unwrap();
    let tr_selector = Selector::parse("tr").unwrap();
    let td_selector = Selector::parse("td").unwrap();

    let mut locations = Vec::new();

    if let Some(table_el) = document.select(&table_selector).next() {
        let mut rows = table_el.select(&tr_selector);
        let _ = rows.next();
        
        for row in rows {
            let tds: Vec<_> = row.select(&td_selector).collect();
            if tds.len() >= 5 {
                let loc = tds[3].text().collect::<Vec<_>>().join("").trim().to_string();
                let status = tds[4].text().collect::<Vec<_>>().join("").trim().to_string();
                locations.push(BookLocation {
                    location: loc,
                    status,
                });
            }
        }
    }

    Ok(BookDetail {
        isbn,
        price,
        pages,
        locations,
    })
}

/// Try to find a cover URL by ISBN, falling back to title search.
/// Sources: Open Library → Dangdang → Douban → Google Books
pub async fn fetch_cover_url(isbn: String, title: String) -> anyhow::Result<Option<String>> {
    let clean_isbn = isbn.trim().to_string();
    let clean_title = title.trim().to_string();

    let client = http::build_client();

    // ── Open Library ──
    if let Some(url) = ol_cover_by_isbn(&client, &clean_isbn).await {
        eprintln!("[Cover] Open Library OK: {}", url);
        return Ok(Some(url));
    }
    if !clean_title.is_empty() {
        if let Some(url) = ol_cover_by_title(&client, &clean_title).await {
            eprintln!("[Cover] Open Library (title) OK: {}", url);
            return Ok(Some(url));
        }
    }

    // ── Dangdang ──
    if let Some(url) = fetch_dangdang_cover(&client, &clean_isbn).await {
        eprintln!("[Cover] Dangdang OK: {}", url);
        return Ok(Some(url));
    }

    // ── Douban ──
    if let Some(url) = fetch_douban_cover(&client, &clean_isbn).await {
        eprintln!("[Cover] Douban OK: {}", url);
        return Ok(Some(url));
    }

    // ── Google Books ──
    if let Some(url) = google_books_cover(&client, &clean_isbn, &clean_title).await {
        eprintln!("[Cover] Google Books OK: {}", url);
        return Ok(Some(url));
    }

    eprintln!("[Cover] No cover found for ISBN={} title={}", clean_isbn, clean_title);
    Ok(None)
}

/// Open Library: direct ISBN cover URL (fastest, no API call).
async fn ol_cover_by_isbn(client: &reqwest::Client, isbn: &str) -> Option<String> {
    if isbn.is_empty() {
        return None;
    }
    // Try search API first — returns cover_i which is more reliable
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
    // Fallback: direct ISBN cover URL
    let direct_url = format!(
        "https://covers.openlibrary.org/b/isbn/{}-M.jpg?default=false",
        isbn
    );
    check_image_url(client, &direct_url).await
}

/// Open Library: search by title (q=) to find cover_i.
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

/// Extract cover_i from an Open Library search.json response.
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
        .first()?
        ["cover_i"]
        .as_u64()
        .map(|id| id.to_string())
}

/// Google Books: search by ISBN first, then by title.
async fn google_books_cover(client: &reqwest::Client, isbn: &str, title: &str) -> Option<String> {
    let ua = "CurriculumTableApp (contact@example.org)";

    // By ISBN
    if !isbn.is_empty() {
        let url = format!(
            "https://www.googleapis.com/books/v1/volumes?q=isbn:{}",
            isbn
        );
        if let Some(cover) = gb_extract_thumbnail(client, &url, ua).await {
            return Some(cover);
        }
    }

    // By title
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

/// Fetch Google Books API and extract the thumbnail URL.
async fn gb_extract_thumbnail(client: &reqwest::Client, url: &str, ua: &str) -> Option<String> {
    let resp = client.get(url).header("User-Agent", ua).send().await.ok()?;
    if resp.status() != reqwest::StatusCode::OK {
        return None;
    }
    let body: serde_json::Value = resp.json().await.ok()?;
    let thumbnail = body["items"]
        .as_array()?
        .first()?
        ["volumeInfo"]["imageLinks"]["thumbnail"]
        .as_str()?;
    Some(thumbnail.replace("http://", "https://"))
}

/// Check if a URL returns a valid image (200 status, Content-Type image/*, size > 1KB).
async fn check_image_url(client: &reqwest::Client, url: &str) -> Option<String> {
    match client
        .head(url)
        .header("User-Agent", "CurriculumTableApp (contact@example.org)")
        .send()
        .await
    {
        Ok(resp) => {
            let status = resp.status();
            if !status.is_success() {
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
                    eprintln!("[Cover] Too small ({}B), skipping: {}", bytes, url);
                    return None;
                }
            }
            Some(url.to_string())
        }
        Err(_) => None,
    }
}

/// Search Dangdang by ISBN, scrape product page for cover image URL.
async fn fetch_dangdang_cover(client: &reqwest::Client, isbn: &str) -> Option<String> {
    if isbn.is_empty() {
        return None;
    }
    let encoded: String = url::form_urlencoded::byte_serialize(isbn.as_bytes()).collect();
    let search_url = format!(
        "http://search.dangdang.com/?key={}&act=input",
        encoded
    );

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
    let cover_url = re.captures(&html)?.get(1)?.as_str();
    let cover_url = format!("https:{}", cover_url);

    check_image_url(client, &cover_url).await
}

/// Search Douban by ISBN, extract cover image URL.
/// Douban images require Referer header; validates with GET + Referer.
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
    let re = Regex::new(r#"(//img\d+\.doubanio\.com/view/subject/[a-z]+/public/s\d+\.(?:jpg|webp))"#).ok()?;
    let cover_path = re.captures(&html)?.get(1)?.as_str();
    let cover_url = format!("https:{}", cover_path);

    // Validate with GET + Referer (Douban blocks HEAD and requests without Referer)
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
