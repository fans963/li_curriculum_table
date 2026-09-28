use crate::crawler::error::{CrawlerError, CrawlerResult};
use aes::cipher::{BlockCipherEncrypt, KeyInit};
use aes::Aes128;
use base64::{engine::general_purpose::STANDARD, Engine};
use scraper::{Html, Selector};
use url::Url;

const RANDOM_CHARS: &[u8] = b"ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678";

pub(super) struct LoginForm {
    pub action: Url,
    pub salt: String,
    pub event_id: String,
    pub cllt: String,
    pub dllt: String,
    pub lt: String,
    pub execution: String,
}

impl LoginForm {
    pub fn parse(html: &str, page_url: &Url) -> CrawlerResult<Self> {
        let document = Html::parse_document(html);
        let form_selector = Selector::parse("form").unwrap();
        let input_selector = Selector::parse("input").unwrap();
        let form = document
            .select(&form_selector)
            .find(|form| {
                form.select(&input_selector)
                    .any(|input| input.value().attr("name") == Some("passwordText"))
            })
            .ok_or_else(|| CrawlerError::Parse("CAS username/password form missing".into()))?;

        let raw_action = form.value().attr("action").unwrap_or("");
        let mut action = page_url
            .join(raw_action)
            .map_err(|e| CrawlerError::Parse(format!("Invalid CAS form action: {e}")))?;

        // Preserve ?service=... query if missing on the form action. On the real CAS page,
        // <form action="/authserver/login"> omits query parameters, and login.js dynamically
        // appends ?service=... from the page URL or the inline `var service = [...]` script variable.
        if action.query().is_none() {
            if let Some(query) = page_url.query() {
                action.set_query(Some(query));
            } else if let Some(service) = extract_service_from_html(html) {
                action.query_pairs_mut().append_pair("service", &service);
            }
        }

        let field = |name: &str| -> CrawlerResult<String> {
            form.select(&input_selector)
                .find(|input| input.value().attr("name") == Some(name))
                .map(|input| input.value().attr("value").unwrap_or("").to_string())
                .ok_or_else(|| CrawlerError::Parse(format!("CAS form field {name} missing")))
        };
        let salt = form
            .select(&input_selector)
            .find(|input| input.value().attr("id") == Some("pwdEncryptSalt"))
            .and_then(|input| input.value().attr("value"))
            .ok_or_else(|| CrawlerError::Parse("CAS password salt missing".into()))?
            .to_string();
        if salt.len() != 16 {
            return Err(CrawlerError::Parse(
                "Unexpected CAS password salt length".into(),
            ));
        }

        Ok(Self {
            action,
            salt,
            event_id: field("_eventId")?,
            cllt: field("cllt")?,
            dllt: field("dllt")?,
            lt: field("lt")?,
            execution: field("execution")?,
        })
    }

    pub fn payload(&self, username: &str, encrypted_password: String) -> Vec<(String, String)> {
        [
            ("username", username.to_string()),
            ("password", encrypted_password),
            ("captcha", String::new()),
            ("_eventId", self.event_id.clone()),
            ("cllt", self.cllt.clone()),
            ("dllt", self.dllt.clone()),
            ("lt", self.lt.clone()),
            ("execution", self.execution.clone()),
        ]
        .into_iter()
        .map(|(key, value)| (key.to_string(), value))
        .collect()
    }
}

fn random_string(len: usize) -> CrawlerResult<String> {
    let mut bytes = vec![0u8; len];
    getrandom::fill(&mut bytes)
        .map_err(|_| CrawlerError::Unknown("Secure random generator unavailable".into()))?;
    Ok(bytes
        .into_iter()
        .map(|byte| RANDOM_CHARS[(byte as usize) % RANDOM_CHARS.len()] as char)
        .collect())
}

fn extract_service_from_html(html: &str) -> Option<String> {
    if let Some(idx) = html.find("var service") {
        let snippet = &html[idx..html.len().min(idx + 300)];
        if let Some(start) = snippet.find('"') {
            let rest = &snippet[start + 1..];
            if let Some(end) = rest.find('"') {
                let s = &rest[..end];
                if s.contains("http") || s.contains("indexsso") {
                    return Some(s.replace(r"\/", "/"));
                }
            }
        }
        if let Some(start) = snippet.find('\'') {
            let rest = &snippet[start + 1..];
            if let Some(end) = rest.find('\'') {
                let s = &rest[..end];
                if s.contains("http") || s.contains("indexsso") {
                    return Some(s.replace(r"\/", "/"));
                }
            }
        }
    }
    None
}

/// Matches getAesString() in the current authserver encrypt.js.
fn encrypt_with_prefix_and_iv(
    password: &str,
    salt: &str,
    prefix: &str,
    iv: &str,
) -> CrawlerResult<String> {
    if salt.len() != 16 || iv.len() != 16 || prefix.len() != 64 {
        return Err(CrawlerError::Parse("Invalid CAS AES input length".into()));
    }
    let cipher = Aes128::new_from_slice(salt.as_bytes())
        .map_err(|_| CrawlerError::Parse("Invalid CAS AES key".into()))?;
    let mut plaintext = prefix.as_bytes().to_vec();
    plaintext.extend_from_slice(password.as_bytes());
    let padding = 16 - plaintext.len() % 16;
    plaintext.extend(std::iter::repeat_n(padding as u8, padding));

    let mut previous = [0u8; 16];
    previous.copy_from_slice(iv.as_bytes());
    #[allow(clippy::chunks_exact_to_as_chunks)]
    for chunk in plaintext.chunks_exact_mut(16) {
        for (byte, prev) in chunk.iter_mut().zip(previous) {
            *byte ^= prev;
        }
        cipher.encrypt_block(chunk.try_into().unwrap());
        previous.copy_from_slice(chunk);
    }
    Ok(STANDARD.encode(plaintext))
}

pub(super) fn encrypt_password(password: &str, salt: &str) -> CrawlerResult<String> {
    let prefix = random_string(64)?;
    let iv = random_string(16)?;
    encrypt_with_prefix_and_iv(password, salt, &prefix, &iv)
}

#[cfg(test)]
mod tests {
    use super::*;

    const FORM: &str = r#"<form method="post" action="/authserver/login?service=http%3A%2F%2Fbkjw.njust.edu.cn%2Fnjlgdx%2Findexsso.jsp&amp;x=1">
        <input name="username"><input name="passwordText">
        <input id="pwdEncryptSalt" value="1234567890abcdef">
        <input name="_eventId" value="submit"><input name="cllt" value="userNameLogin">
        <input name="dllt" value="generalLogin"><input name="lt" value="">
        <input name="execution" value="e7s2"></form>"#;

    #[test]
    fn parses_current_form_and_preserves_service_and_execution() {
        let page = Url::parse("https://ids.njust.edu.cn/authserver/login").unwrap();
        let form = LoginForm::parse(FORM, &page).unwrap();
        assert_eq!(form.action.host_str(), Some("ids.njust.edu.cn"));
        assert!(form.action.as_str().contains("service=http%3A%2F%2F"));
        assert!(form.action.as_str().contains("&x=1"));
        assert_eq!(form.execution, "e7s2");
        let fields = form.payload("test-user", "encrypted".into());
        assert_eq!(fields[0], ("username".into(), "test-user".into()));
        assert_eq!(fields[1], ("password".into(), "encrypted".into()));
        assert_eq!(fields[7], ("execution".into(), "e7s2".into()));
    }

    #[test]
    fn rejects_missing_dynamic_fields() {
        let page = Url::parse("https://ids.njust.edu.cn/authserver/login").unwrap();
        assert!(LoginForm::parse(&FORM.replace("pwdEncryptSalt", "oldSalt"), &page).is_err());
        assert!(
            LoginForm::parse(&FORM.replace("name=\"execution\"", "name=\"old\""), &page).is_err()
        );
    }

    #[test]
    fn aes_matches_live_page_known_vector() {
        let encrypted = encrypt_with_prefix_and_iv(
            "sample-password",
            "1234567890abcdef",
            &"A".repeat(64),
            "fedcba0987654321",
        )
        .unwrap();
        assert_eq!(encrypted, "YuM9Bx6zd11PT+H5Zzdv18h1C937IJnOwY/F5K9tvmrlKxhjeFGuzt0CE1fWxUzyDcbyY8Lm3i80NWQiHRQo0bbgDqMN0zYfObt1Wptwots=");
    }

    #[test]
    fn random_encryption_produces_distinct_ciphertexts() {
        let first = encrypt_password("sample-password", "1234567890abcdef").unwrap();
        let second = encrypt_password("sample-password", "1234567890abcdef").unwrap();
        assert_ne!(first, second);
    }
}
