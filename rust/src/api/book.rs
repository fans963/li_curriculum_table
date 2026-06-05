use scraper::{Html, Selector};

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

pub async fn search_books(title: String) -> anyhow::Result<Vec<BookInfo>> {
    let clean_title = title.trim();
    if clean_title.is_empty() {
        return Ok(Vec::new());
    }

    let client = reqwest::Client::builder()
        .user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        .timeout(std::time::Duration::from_secs(10))
        .build()?;

    let encoded_title: String = url::form_urlencoded::byte_serialize(clean_title.as_bytes()).collect();
    let target_url = format!(
        "http://202.119.83.14:8080/uopac/opac/openlink.php?title={}&doctype=ALL&showmode=list",
        encoded_title
    );
    
    let response = client.get(&target_url)
        .send()
        .await?;

    let html_content = response.text().await?;
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
                    
                    // strip starting index like '1. ' or '2. '
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
                    let detail_url = if relative_href.starts_with("http") {
                        relative_href
                    } else {
                        format!("http://202.119.83.14:8080/uopac/opac/{}", relative_href)
                    };

                    let doc_type = h3_el.select(&span_selector).next()
                        .map(|s| s.text().collect::<Vec<_>>().join("").trim().to_string())
                        .unwrap_or_else(|| "未知类型".to_string());

                    // The call number is typically the last text node inside h3
                    let mut call_no = String::new();
                    for node in h3_el.children() {
                        if let Some(text_node) = node.value().as_text() {
                            let text = text_node.trim();
                            if !text.is_empty() {
                                call_no = text.to_string();
                            }
                        }
                    }

                    // Remove leading spaces/dashes if any
                    let call_no = call_no.trim_start_matches(|c| c == ' ' || c == '-' || c == '/' || c == ':').trim().to_string();

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

    Ok(books)
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

    let client = reqwest::Client::builder()
        .user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        .timeout(std::time::Duration::from_secs(10))
        .build()?;

    let response = client.get(&detail_url)
        .send()
        .await?;

    let html_content = response.text().await?;
    let document = Html::parse_document(&html_content);
    
    let mut isbn = "无".to_string();
    let mut price = "无".to_string();
    let mut pages = "无".to_string();

    let dl_selector = Selector::parse("dl.booklist").unwrap();
    let dt_selector = Selector::parse("dt").unwrap();
    let dd_selector = Selector::parse("dd").unwrap();

    for dl in document.select(&dl_selector) {
        if let (Some(dt), Some(dd)) = (dl.select(&dt_selector).next(), dl.select(&dd_selector).next()) {
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
        // skip header row
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
