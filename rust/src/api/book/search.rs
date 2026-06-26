use crate::api::http;
use regex_lite::Regex;
use scraper::{Html, Selector};

use super::models::{BookDetail, BookInfo, BookLocation, BookSearchParams, BookSearchResult};

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

pub async fn search_books_advanced(params: BookSearchParams) -> anyhow::Result<BookSearchResult> {
    if params.query.trim().is_empty() {
        return Ok(BookSearchResult { books: Vec::new(), total_count: 0 });
    }
    search_and_parse(&params.build_url()).await
}

async fn search_and_parse(target_url: &str) -> anyhow::Result<BookSearchResult> {
    let client = http::build_client();
    let response = client.get(target_url).send().await?;
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
                    let title = if let Some(dot_idx) = title_full.find('.') {
                        if dot_idx < 4 { title_full[dot_idx + 1..].trim().to_string() } else { title_full.clone() }
                    } else {
                        title_full.clone()
                    };

                    let relative_href = a_el.value().attr("href").unwrap_or("").to_string();
                    let detail_url = resolve_detail_url(&relative_href);

                    let doc_type = h3_el.select(&span_selector).next()
                        .map(|s| s.text().collect::<Vec<_>>().join("").trim().to_string())
                        .unwrap_or_else(|| "未知类型".to_string());

                    let mut call_no = String::new();
                    for node in h3_el.children() {
                        if let Some(text_node) = node.value().as_text() {
                            let text = text_node.trim();
                            if !text.is_empty() { call_no = text.to_string(); }
                        }
                    }
                    let call_no = call_no.trim_start_matches([' ', '-', '/', ':']).trim().to_string();

                    let mut holdings_summary = "未知".to_string();
                    let mut author = "未知作者".to_string();
                    let mut publisher = "未知出版信息".to_string();

                    if let Some(p_el) = item.select(&p_selector).next() {
                        let mut all_texts = Vec::new();
                        for text_el in p_el.text() {
                            let trimmed = text_el.trim();
                            if !trimmed.is_empty() { all_texts.push(trimmed.to_string()); }
                        }
                        if all_texts.len() >= 2 { holdings_summary = all_texts[..2].join(" "); }
                        if all_texts.len() > 2 { author = all_texts[2].clone(); }
                        if all_texts.len() > 3 { publisher = all_texts[3].clone(); }
                    }

                    books.push(BookInfo { title, author, publisher, call_no, doc_type, holdings_summary, detail_url });
                }
            }
        }
    }

    let total_count = parse_total_count(&html_content);
    Ok(BookSearchResult { books, total_count })
}

fn parse_total_count(html: &str) -> u32 {
    let re_tag = Regex::new(r"<[^>]*>").ok();
    let plain = match &re_tag {
        Some(re) => re.replace_all(html, ""),
        None => return 0,
    };
    let plain = plain.replace(char::is_whitespace, " ");
    let re = Regex::new(r"检索到\s*(\d+)\s*条").ok();
    if let Some(re) = &re {
        if let Some(caps) = re.captures(&plain) {
            if let Some(m) = caps.get(1) {
                return m.as_str().parse::<u32>().unwrap_or(0);
            }
        }
    }
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

fn resolve_detail_url(href: &str) -> String {
    if href.starts_with("http") {
        href.to_string()
    } else {
        format!("http://202.119.83.14:8080/uopac/opac/{}", href.trim_start_matches("./"))
    }
}

pub async fn fetch_book_locations(detail_url: String) -> anyhow::Result<BookDetail> {
    if detail_url.is_empty() {
        return Ok(BookDetail { isbn: "无".into(), price: "无".into(), pages: "无".into(), locations: Vec::new() });
    }

    let client = http::build_client();
    let response = client.get(&detail_url).send().await?;
    let html_content = response.text().await?;
    let document = Html::parse_document(&html_content);

    let mut isbn = "无".to_string();
    let mut price = "无".to_string();
    let mut pages = "无".to_string();

    let dl_selector = Selector::parse("dl").unwrap();
    let dt_selector = Selector::parse("dt").unwrap();
    let dd_selector = Selector::parse("dd").unwrap();

    for dl in document.select(&dl_selector) {
        for (dt, dd) in dl.select(&dt_selector).zip(dl.select(&dd_selector)) {
            let dt_text = dt.text().collect::<Vec<_>>().join("").trim().to_string();
            let dd_text = dd.text().collect::<Vec<_>>().join("").trim().to_string();

            if dt_text.contains("ISBN及定价") {
                let parts: Vec<&str> = dd_text.split('/').collect();
                if !parts.is_empty() { isbn = parts[0].trim().to_string(); }
                if parts.len() > 1 { price = parts[1].trim().to_string(); }
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
                locations.push(BookLocation { location: loc, status });
            }
        }
    }

    Ok(BookDetail { isbn, price, pages, locations })
}
