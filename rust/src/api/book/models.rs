/// Advanced search parameters mirroring the OPAC search_more.php form.
#[derive(Debug, Clone, Default)]
pub struct BookSearchParams {
    pub search_type: String,
    pub query: String,
    pub doctype: String,
    pub lang_code: String,
    pub displaypg: u32,
    pub sort: String,
    pub orderby: String,
    pub dept: String,
    pub showmode: String,
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

    pub fn build_url(&self) -> String {
        let encoded: String =
            url::form_urlencoded::byte_serialize(self.query.as_bytes()).collect();
        let mut url = format!(
            "http://202.119.83.14:8080/uopac/opac/openlink.php?strSearchType={}&historyCount=1&strText={}&doctype={}&lang_code={}&displaypg={}&sort={}&orderby={}&dept={}&showmode={}&match_flag=forward&with_ebook=on",
            self.search_type, encoded, self.doctype, self.lang_code,
            self.displaypg, self.sort, self.orderby, self.dept, self.showmode,
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

#[derive(Debug, Clone)]
pub struct BookSearchResult {
    pub books: Vec<BookInfo>,
    pub total_count: u32,
}

#[derive(Debug, Clone)]
pub struct BookDetail {
    pub isbn: String,
    pub price: String,
    pub pages: String,
    pub locations: Vec<BookLocation>,
}
