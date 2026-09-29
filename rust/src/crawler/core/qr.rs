use crate::crawler::error::{CrawlerError, CrawlerResult};
use scraper::{Html, Selector};
use url::Url;

#[derive(Clone)]
pub(super) struct QrLoginAttempt {
    pub uuid: String,
    pub page_url: Url,
    pub form: QrLoginForm,
}

#[derive(Clone)]
pub(super) struct QrLoginForm {
    action: Url,
    fields: Vec<(String, String)>,
}

impl QrLoginForm {
    pub fn parse(html: &str, page_url: &Url) -> CrawlerResult<Self> {
        let document = Html::parse_document(html);
        let form_selector = Selector::parse("form#qrLoginForm").unwrap();
        let input_selector = Selector::parse("input").unwrap();
        let form = document
            .select(&form_selector)
            .next()
            .ok_or_else(|| CrawlerError::Parse("CAS QR login form missing".into()))?;
        let mut fields: Vec<(String, String)> = form
            .select(&input_selector)
            .filter_map(|input| {
                input.value().attr("name").map(|name| {
                    (
                        name.to_string(),
                        input.value().attr("value").unwrap_or("").to_string(),
                    )
                })
            })
            .collect();

        for required in ["uuid", "execution", "cllt", "dllt", "_eventId", "rmShown"] {
            if !fields.iter().any(|(name, _)| name == required) {
                return Err(CrawlerError::Parse(format!(
                    "CAS QR form field {required} missing"
                )));
            }
        }
        fields.retain(|(name, _)| name != "uuid");

        let service = page_url
            .query_pairs()
            .find(|(key, _)| key == "service")
            .map(|(_, value)| value.into_owned())
            .ok_or_else(|| CrawlerError::Parse("CAS service URL missing".into()))?;
        let mut action = page_url
            .join("/authserver/login")
            .map_err(|e| CrawlerError::Parse(format!("Invalid CAS QR action: {e}")))?;
        action
            .query_pairs_mut()
            .append_pair("display", "qrLogin")
            .append_pair("service", &service);
        Ok(Self { action, fields })
    }

    pub fn action(&self) -> &Url {
        &self.action
    }

    pub fn payload(&self, uuid: &str) -> Vec<u8> {
        let mut fields = self.fields.clone();
        fields.push(("uuid".into(), uuid.into()));
        url::form_urlencoded::Serializer::new(String::new())
            .extend_pairs(fields)
            .finish()
            .into_bytes()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn qr_form_keeps_academic_service_and_dynamic_fields() {
        let html = r#"<form id="qrLoginForm" method="post" action="/authserver/login">
            <input name="lt" value=""><input name="uuid" value="">
            <input name="cllt" value="qrLogin"><input name="dllt" value="generalLogin">
            <input name="execution" value="e4s1"><input name="_eventId" value="submit">
            <input name="rmShown" value="1"></form>"#;
        let page = Url::parse("https://ids.njust.edu.cn/authserver/login?service=http%3A%2F%2Fbkjw.njust.edu.cn%2Fnjlgdx%2Findexsso.jsp").unwrap();
        let form = QrLoginForm::parse(html, &page).unwrap();
        assert_eq!(form.action().host_str(), Some("ids.njust.edu.cn"));
        assert_eq!(
            form.action()
                .query_pairs()
                .filter(|(key, _)| key == "service")
                .count(),
            1
        );
        let body = String::from_utf8(form.payload("QR-test")).unwrap();
        assert!(body.contains("uuid=QR-test"));
        assert!(body.contains("execution=e4s1"));
        assert!(body.contains("cllt=qrLogin"));
    }
}
