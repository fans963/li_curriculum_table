use crate::api::http;
use crate::crawler::core::cas::{encrypt_password, LoginForm};
use crate::crawler::error::{CrawlerError, CrawlerResult};
use crate::crawler::model::CrawlerConfig;
use encoding_rs::GBK;
#[cfg(not(target_arch = "wasm32"))]
use reqwest::cookie::Jar;
use reqwest::{Client, Method};
use std::sync::atomic::{AtomicU16, Ordering};
#[cfg(not(target_arch = "wasm32"))]
use std::sync::Arc;
use tokio::sync::Mutex;
use url::Url;

static PROXY_PORT: AtomicU16 = AtomicU16::new(9999);

pub fn set_proxy_port(port: u16) {
    PROXY_PORT.store(port, Ordering::SeqCst);
}

pub fn get_proxy_port() -> u16 {
    PROXY_PORT.load(Ordering::SeqCst)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NetworkingStrategy {
    Direct,
    LocalProxy,
    LocalNativeProxy, // Web version uses Native app as local gateway
}

pub struct SessionManager {
    pub client: Client,
    #[cfg(not(target_arch = "wasm32"))]
    pub jar: Arc<Jar>,
    pub config: CrawlerConfig,
    pub login_lock: Mutex<()>,
    pub strategy: NetworkingStrategy,
}

impl SessionManager {
    pub async fn new() -> Self {
        #[cfg(target_arch = "wasm32")]
        let mut strategy: NetworkingStrategy = NetworkingStrategy::LocalNativeProxy;
        #[cfg(not(target_arch = "wasm32"))]
        let strategy: NetworkingStrategy;

        #[cfg(not(target_arch = "wasm32"))]
        let jar = Arc::new(Jar::default());
        let builder = http::client_builder();

        #[cfg(target_arch = "wasm32")]
        {
            let port = get_proxy_port();
            let local_discovery_url = format!("http://localhost:{}/status", port);
            log::info!(
                "Web: Probing for local native proxy at {}...",
                local_discovery_url
            );

            let probe_client = http::build_client();
            if let Ok(resp) = probe_client.get(local_discovery_url).send().await {
                if resp.status().is_success() {
                    log::info!(
                        "Web: Local native proxy discovered! Switching to hyper-speed mode."
                    );
                    strategy = NetworkingStrategy::LocalNativeProxy;
                }
            }
        }

        #[cfg(not(target_arch = "wasm32"))]
        let builder = {
            let b = builder
                .cookie_provider(Arc::clone(&jar))
                .redirect(reqwest::redirect::Policy::limited(16));

            strategy = NetworkingStrategy::Direct;
            log::info!("[V8] Native mode: Using Direct connection.");
            b
        };

        let client = builder.build().unwrap_or_default();
        log::info!(
            "Crawler: SessionManager initialized. Strategy: {:?}, Port: {}",
            strategy,
            get_proxy_port()
        );

        Self {
            client,
            #[cfg(not(target_arch = "wasm32"))]
            jar,
            config: CrawlerConfig::default(),
            login_lock: Mutex::new(()),
            strategy,
        }
    }

    /// Inject cookies obtained from an external browser (WebView) into the
    /// reqwest cookie jar. Each entry is a `(url, cookie_header)` pair where
    /// `url` is the origin the cookie belongs to (e.g. `https://bkjw.njust.edu.cn`)
    /// and `cookie_header` is a `Set-Cookie`-style string such as
    /// `JSESSIONID=ABC123; Path=/njlgdx`.
    pub fn inject_cookies(&self, cookies: &[(String, String)]) {
        #[cfg(not(target_arch = "wasm32"))]
        for (raw_url, cookie_str) in cookies {
            if let Ok(url) = Url::parse(raw_url) {
                self.jar.add_cookie_str(cookie_str, &url);
                log::info!(
                    "Crawler: Injected cookie for {:?} {}",
                    url.host_str(),
                    url.path()
                );
            } else {
                log::warn!("Crawler: Skipping invalid cookie URL");
            }
        }
        #[cfg(target_arch = "wasm32")]
        let _ = cookies;
    }

    pub async fn login_if_needed(
        &self,
        username: &str,
        password: &str,
        _max_attempts: u32,
    ) -> CrawlerResult<()> {
        if self.check_session().await {
            return Ok(());
        }

        let _lock = self.login_lock.lock().await;

        if self.check_session().await {
            return Ok(());
        }

        // The CAS entry point creates the right service URL and keeps it on the
        // login form. Do not build or cache a ticket or an execution value.
        let entry_url = format!("{}/indexsso.jsp", self.config.get_base_url());
        let (final_url, login_page) = self.fetch_text_with_url(&entry_url, Method::GET, None, None).await?;
        if is_authenticated_page(&login_page) {
            return Ok(());
        }

        let form = LoginForm::parse(&login_page, &final_url)?;

        let cas_host = self.config.get_cas_host();
        let cas_host_owned = if cas_host.contains("://") {
            cas_host.to_string()
        } else {
            format!("https://{cas_host}")
        };
        let expected_host = Url::parse(&cas_host_owned)
            .ok()
            .and_then(|u| u.host_str().map(|s| s.to_string()))
            .unwrap_or_else(|| "ids.njust.edu.cn".to_string());

        if form.action.host_str() != Some(&expected_host) {
            return Err(CrawlerError::Parse(
                "Untrusted CAS login form action".into(),
            ));
        }

        // The login page initializes a browser fingerprint cookie and checks
        // whether this account needs a captcha before submitting the form.
        let mut fingerprint = [0u8; 16];
        getrandom::fill(&mut fingerprint)
            .map_err(|_| CrawlerError::Unknown("Secure random generator unavailable".into()))?;
        let fingerprint: String = fingerprint
            .iter()
            .map(|byte| format!("{byte:02X}"))
            .collect();
        let cas_base = format!("{}://{}", form.action.scheme(), form.action.authority().trim_end_matches('/'));
        let bfp_url = format!("{cas_base}/authserver/bfp/info?bfp={fingerprint}");
        self.fetch_text(&bfp_url, Method::GET, None, Some(form.action.as_str()))
            .await?;
        let captcha_url = Url::parse_with_params(
            &format!("{cas_base}/authserver/checkNeedCaptcha.htl"),
            [("username", username)],
        )
        .map_err(|e| CrawlerError::Parse(format!("Invalid captcha check URL: {e}")))?;
        let captcha_status = self
            .fetch_text(
                captcha_url.as_str(),
                Method::GET,
                None,
                Some(form.action.as_str()),
            )
            .await?;
        let captcha: serde_json::Value = serde_json::from_str(&captcha_status)
            .map_err(|_| CrawlerError::Parse("Invalid CAS captcha response".into()))?;
        if captcha.get("isNeed").and_then(serde_json::Value::as_bool) != Some(false) {
            return Err(CrawlerError::AuthenticationChallenge);
        }

        let encrypted = encrypt_password(password, &form.salt)?;
        let body = url::form_urlencoded::Serializer::new(String::new())
            .extend_pairs(form.payload(username, encrypted))
            .finish()
            .into_bytes();
        let response = self
            .fetch_text(
                form.action.as_str(),
                Method::POST,
                Some(body),
                Some(form.action.as_str()),
            )
            .await?;

        if is_authenticated_page(&response) || self.check_session().await {
            return Ok(());
        }
        if response.contains("用户名或密码错误")
            || response.contains("密码错误")
            || response.contains("账号不存在")
            || response.contains("Invalid username or password")
        {
            return Err(CrawlerError::InvalidCredentials);
        }
        if response.contains("验证码错误")
            || response.contains("请输入验证码")
            || response.contains("verification code is required")
            || response.contains("图形动态码")
            || response.contains("动态码")
        {
            return Err(CrawlerError::AuthenticationChallenge);
        }
        if response.contains("系统维护") || response.contains("maintenance") {
            return Err(CrawlerError::Maintenance);
        }
        Err(CrawlerError::AuthenticationRejected)
    }

    /// Inject cookies from an external browser session and verify that the
    /// resulting session is valid. This is the primary login path when the
    /// school CAS rejects independent HTTP clients.
    pub async fn login_with_cookies(
        &self,
        cookies: Vec<(String, String)>,
    ) -> CrawlerResult<()> {
        if self.check_session().await {
            return Ok(());
        }

        let _lock = self.login_lock.lock().await;

        if self.check_session().await {
            return Ok(());
        }

        self.inject_cookies(&cookies);

        if self.check_session().await {
            Ok(())
        } else {
            Err(CrawlerError::SessionExpired)
        }
    }

    /// Public wrapper for check_session, exposed for the API layer.
    pub async fn check_session_public(&self) -> bool {
        self.check_session().await
    }

    async fn check_session(&self) -> bool {
        let url = format!("{}/framework/main.jsp", self.config.get_base_url());
        match self.fetch_text(&url, Method::GET, None, None).await {
            Ok(html) => {
                let success = is_authenticated_page(&html);
                if !success {
                    log::debug!(
                        "Crawler: Session check failed (invalid keywords). HTML length: {}",
                        html.len()
                    );
                }
                success
            }
            Err(e) => {
                log::warn!("Crawler: Session check error: {}", e);
                false
            }
        }
    }

    pub async fn fetch_raw(
        &self,
        url: &str,
        method: Method,
        body: Option<Vec<u8>>,
        referer: Option<&str>,
    ) -> CrawlerResult<Vec<u8>> {
        let (_, bytes) = self.fetch_raw_with_url(url, method, body, referer).await?;
        Ok(bytes)
    }

    pub async fn fetch_raw_with_url(
        &self,
        url: &str,
        method: Method,
        body: Option<Vec<u8>>,
        referer: Option<&str>,
    ) -> CrawlerResult<(Url, Vec<u8>)> {
        let wrapped_url = self.wrap_url(url);
        log::debug!("Crawler: [Request] {}", safe_request_label(&method, url));

        let mut headers = reqwest::header::HeaderMap::new();
        let ua = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36";
        headers.insert("User-Agent", ua.parse().unwrap());
        headers.insert("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7".parse().unwrap());
        headers.insert("Accept-Language", "en-US,en;q=0.9".parse().unwrap());

        if let Some(ref_url) = referer {
            headers.insert("Referer", ref_url.parse().unwrap());
        }
        if method == Method::POST && url.contains("/authserver/login") {
            if let Ok(parsed) = url::Url::parse(url) {
                if let Some(host) = parsed.host_str() {
                    let scheme = parsed.scheme();
                    let origin = if let Some(port) = parsed.port() {
                        format!("{scheme}://{host}:{port}")
                    } else {
                        format!("{scheme}://{host}")
                    };
                    headers.insert(
                        "Origin",
                        origin.parse().unwrap(),
                    );
                }
            }
            headers.insert("Upgrade-Insecure-Requests", "1".parse().unwrap());
        }

        let mut req_builder = self
            .client
            .request(method.clone(), wrapped_url)
            .headers(headers);

        if let Some(ref b) = body {
            req_builder = req_builder.body(b.clone());
            if method == Method::POST {
                req_builder = req_builder.header(
                    reqwest::header::CONTENT_TYPE,
                    "application/x-www-form-urlencoded",
                );
            }
        }

        if self.strategy == NetworkingStrategy::LocalNativeProxy {
            #[cfg(target_arch = "wasm32")]
            {
                if let Some(ref_val) = referer {
                    req_builder = req_builder.header("X-Proxy-Referer", ref_val);
                }

                req_builder = req_builder.fetch_credentials_include();
            }
        }

        let resp = req_builder.send().await?;
        let status = resp.status();
        let final_url = resp.url().clone();
        log::debug!(
            "Crawler: [Response] status: {}, host: {:?}, path: {}",
            status,
            final_url.host_str(),
            final_url.path()
        );

        let bytes = resp.bytes().await?.to_vec();
        log::debug!("Crawler: [Data] received {} bytes", bytes.len());
        Ok((final_url, bytes))
    }

    pub async fn fetch_text(
        &self,
        url: &str,
        method: Method,
        body: Option<Vec<u8>>,
        referer: Option<&str>,
    ) -> CrawlerResult<String> {
        let (_, text) = self.fetch_text_with_url(url, method, body, referer).await?;
        Ok(text)
    }

    pub async fn fetch_text_with_url(
        &self,
        url: &str,
        method: Method,
        body: Option<Vec<u8>>,
        referer: Option<&str>,
    ) -> CrawlerResult<(Url, String)> {
        let (final_url, bytes) = self.fetch_raw_with_url(url, method, body, referer).await?;
        let text = if let Ok(s) = String::from_utf8(bytes.clone()) {
            s
        } else {
            let (decoded, _, _) = GBK.decode(&bytes);
            decoded.into_owned()
        };
        Ok((final_url, text))
    }

    fn wrap_url(&self, url: &str) -> String {
        match self.strategy {
            NetworkingStrategy::LocalNativeProxy => {
                let port = get_proxy_port();
                let encoded: String =
                    url::form_urlencoded::byte_serialize(url.as_bytes()).collect();
                format!("http://localhost:{}/proxy?url={}", port, encoded)
            }
            _ => url.to_string(),
        }
    }
}

fn is_authenticated_page(html: &str) -> bool {
    if html.contains("请先登录系统")
        || html.contains("登录个人中心")
        || html.contains("pwdFromId")
        || html.contains("/authserver/login")
        || html.contains("/xk/Verifyservlet")
        || html.contains("统一身份认证")
        || html.contains("pwdEncryptSalt")
        || html.contains("RANDOMCODE")
    {
        return false;
    }
    html.contains("学生个人中心")
        || html.contains("理论课表")
        || html.contains("xs_main.jsp")
        || (html.contains("个人中心") && !html.contains("登录"))
}

fn safe_request_label(method: &Method, raw_url: &str) -> String {
    match Url::parse(raw_url) {
        Ok(url) => format!("{} {:?} {}", method, url.host_str(), url.path()),
        Err(_) => method.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn session_marker_does_not_accept_cas_login_page() {
        assert!(!is_authenticated_page(
            "<title>Unified identity authentication platform</title><form id=\"pwdFromId\"></form>"
        ));
        assert!(!is_authenticated_page(
            "<div class=\"dl\"><div class=\"dlti\">登录个人中心</div><font color=\"red\">请先登录系统</font></div>"
        ));
        assert!(is_authenticated_page(
            "<title>学生个人中心</title><a href=\"/njlgdx/xskb/xskb_list.do\">课表</a>"
        ));
    }

    #[test]
    fn request_log_does_not_include_ticket_or_account() {
        let label = safe_request_label(
            &Method::GET,
            "https://bkjw.njust.edu.cn/njlgdx/indexsso.jsp?ticket=secret&username=student",
        );
        assert_eq!(
            label,
            "GET Some(\"bkjw.njust.edu.cn\") /njlgdx/indexsso.jsp"
        );
    }

    // This test binds a local TCP listener and runs the full login
    // flow against a mock CAS server. It requires network permissions
    // (binding to 127.0.0.1:0), so it is not run by `cargo test`; invoke
    // it explicitly with `cargo test --lib ... -- --include-ignored`.
    #[cfg(not(target_arch = "wasm32"))]
    #[tokio::test]
    #[ignore]
    async fn mock_cas_login_flow_reaches_academic_home() {
        // Spawn a tiny HTTP server that mimics the school's authserver +
        // academic system redirects. Proves the Rust implementation walks
        // the correct redirect chain and recognises the academic homepage
        // without depending on the school accepting independent clients.
        let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
        let port = listener.local_addr().unwrap().port();
        let _server = std::thread::spawn(move || run_mock_cas(listener, port));
        let base_url = format!("http://127.0.0.1:{port}/njlgdx");

        let mut session = SessionManager::new().await;
        session.config.login_url = base_url.clone();
        session.config.target_url = format!("{base_url}/xskb/xskb_list.do");
        session.config.academic_base = base_url.clone();
        session.config.cas_host = format!("http://127.0.0.1:{port}");

        session
            .login_if_needed("923104780617", "Fanenbo20051127", 1)
            .await
            .unwrap();
        assert!(session.check_session().await);
    }

    // Run explicitly with NJUST_TEST_USER and NJUST_TEST_PASSWORD. This is a
    // live smoke test, not part of the offline unit-test suite.
    #[tokio::test]
    #[ignore]
    async fn live_cas_login_reaches_academic_home() {
        let username = std::env::var("NJUST_TEST_USER").expect("NJUST_TEST_USER missing");
        let password = std::env::var("NJUST_TEST_PASSWORD").expect("NJUST_TEST_PASSWORD missing");
        let session = SessionManager::new().await;
        session
            .login_if_needed(&username, &password, 1)
            .await
            .unwrap();
        assert!(session.check_session().await);
    }

    #[tokio::test]
    #[ignore]
    async fn live_fetch_services_with_cas_login() {
        let username = std::env::var("NJUST_TEST_USER").expect("NJUST_TEST_USER missing");
        let password = std::env::var("NJUST_TEST_PASSWORD").expect("NJUST_TEST_PASSWORD missing");
        let session = Arc::new(SessionManager::new().await);

        let timetable_service = crate::crawler::services::timetable::TimetableService::new(Arc::clone(&session));
        let timetable = timetable_service
            .fetch_timetable(&username, &password, 1)
            .await
            .expect("fetch timetable");
        assert!(timetable.login_likely_success);
        println!("Fetched {} timetable rows", timetable.rows.len());

        let grade_service = crate::crawler::services::grade::GradeService::new(Arc::clone(&session));
        let grades = grade_service
            .fetch_grades(&username, &password, 1)
            .await
            .expect("fetch grades");
        println!("Fetched {} grades", grades.grades.len());

        let exam_service = crate::crawler::services::exam::ExamService::new(Arc::clone(&session));
        let exams = exam_service
            .fetch_exams(&username, &password, 1)
            .await
            .expect("fetch exams");
        println!("Fetched {} exams", exams.exams.len());

        let level_service = crate::crawler::services::level_exam_score::LevelExamScoreService::new(Arc::clone(&session));
        let level_scores = level_service
            .fetch_level_exam_scores(&username, &password, 1)
            .await
            .expect("fetch level exam scores");
        println!("Fetched {} level exam scores", level_scores.scores.len());

        let classroom_service = crate::crawler::services::classroom::ClassroomService::new(Arc::clone(&session));
        let campus_data = classroom_service
            .get_campuses()
            .await
            .expect("get campuses");
        println!("Fetched {} campuses, current term: {}", campus_data.campuses.len(), campus_data.current_term);
    }

    // Verify the cookie-injection login path works.
    // Run with: NJUST_SESSION_ID=<JSESSIONID from browser> cargo test --lib \
    //     crawler::core::session::tests::live_cookie_injection_reaches_academic_home -- --ignored
    #[tokio::test]
    #[ignore]
    async fn live_cookie_injection_reaches_academic_home() {
        let jsessionid =
            std::env::var("NJUST_SESSION_ID").expect("NJUST_SESSION_ID missing");
        let session = SessionManager::new().await;

        let cookies = vec![(
            "https://bkjw.njust.edu.cn/njlgdx/framework/main.jsp".to_string(),
            format!("JSESSIONID={}; Path=/njlgdx", jsessionid),
        )];
        session.login_with_cookies(cookies).await.unwrap();
        assert!(session.check_session().await);
    }

    fn run_mock_cas(listener: std::net::TcpListener, port: u16) {
    use std::io::{Read, Write};
    let login_html = "\
<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>Mock CAS</title></head>\n\
<body>\n\
<form id=\"pwdFromId\" method=\"post\" action=\"/authserver/login\">\n\
    <input name=\"username\" id=\"username\">\n\
    <input name=\"passwordText\" id=\"password\" type=\"password\">\n\
    <input name=\"password\" id=\"saltPassword\" type=\"hidden\" value=\"\">\n\
    <input name=\"captcha\" id=\"captcha\">\n\
    <input name=\"rememberMe\" id=\"rememberMe\" type=\"checkbox\">\n\
    <input name=\"_eventId\" id=\"_eventId\" type=\"hidden\" value=\"submit\">\n\
    <input name=\"cllt\" id=\"cllt\" type=\"hidden\" value=\"userNameLogin\">\n\
    <input name=\"dllt\" id=\"dllt\" type=\"hidden\" value=\"generalLogin\">\n\
    <input name=\"lt\" id=\"lt\" type=\"hidden\" value=\"\">\n\
    <input id=\"pwdEncryptSalt\" type=\"hidden\" value=\"MOCKSALT12345678\">\n\
    <input name=\"execution\" id=\"execution\" type=\"hidden\" value=\"e3s3\">\n\
</form></body></html>";
    let student_center = "\
<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>学生个人中心</title></head>\n\
<body><a href=\"/njlgdx/xskb/xskb_list.do\">我的课表</a>\
<a href=\"/njlgdx/framework/main.jsp\">首页</a></body></html>";
    for stream in listener.incoming() {
        let mut stream = match stream {
            Ok(s) => s,
            Err(_) => continue,
        };
        let _ = stream.set_read_timeout(Some(std::time::Duration::from_secs(10)));
        let _ = stream.set_write_timeout(Some(std::time::Duration::from_secs(10)));
        let mut buf = vec![0u8; 16384];
        let mut total = 0;
        let mut header_end = None;
        while total < buf.len() {
            match stream.read(&mut buf[total..]) {
                Ok(0) => break,
                Ok(n) => {
                    total += n;
                    if let Some(p) = buf[..total].windows(4).position(|w| w == b"\r\n\r\n") {
                        header_end = Some(p + 4);
                        break;
                    }
                }
                Err(_) => break,
            }
        }
        let req = String::from_utf8_lossy(&buf[..total]).into_owned();
        let header_end = header_end.unwrap_or(total);
        let _body = &buf[header_end..total];
        let (method, path_with_query) = req
            .split_once(' ')
            .map(|(m, rest)| (m, rest.split_once(' ').map_or(rest, |(p, _)| p)))
            .unwrap_or(("GET", "/"));
        // Strip absolute-form prefix that reqwest uses after a redirect
        // (e.g. "GET http://host/njlgdx/indexsso.jsp HTTP/1.1").
        let path_with_query = if let Some(rest) = path_with_query.strip_prefix("http://") {
            rest.split_once('/')
                .map(|(_, p)| format!("/{p}"))
                .unwrap_or_else(|| rest.to_string())
        } else if let Some(rest) = path_with_query.strip_prefix("https://") {
            rest.split_once('/')
                .map(|(_, p)| format!("/{p}"))
                .unwrap_or_else(|| rest.to_string())
        } else {
            path_with_query.to_string()
        };
        let path = path_with_query.split('?').next().unwrap_or("/");

        let mut extra_headers = String::new();
        let response = match (method, path) {
            ("GET", "/njlgdx/indexsso.jsp") => {
                if path_with_query.contains("ticket=") {
                    redirect(
                        format!("http://127.0.0.1:{port}/njlgdx/xk/LoginToXk"),
                        &["MOD_AUTH_CAS=mockmodcas; Path=/"],
                    )
                } else {
                    redirect(
                        format!(
                            "http://127.0.0.1:{port}/authserver/login?service=http%3A%2F%2F127.0.0.1%3A{port}%2Fnjlgdx%2Findexsso.jsp"
                        ),
                        &[],
                    )
                }
            }
            ("GET", "/authserver/login") => {
                extra_headers.push_str(
                    "Set-Cookie: route=mockroute; Path=/authserver\r\n\
                     Set-Cookie: JSESSIONID=MOCKJSESSION; Path=/authserver; HttpOnly\r\n",
                );
                text_response(200, login_html, &extra_headers)
            }
            ("GET", "/authserver/tenant/info") => text_response(200, "{\"mobileFlay\":false}", ""),
            ("GET", "/authserver/qrCode/getToken") => text_response(200, "QR-mocktoken", ""),
            ("GET", "/authserver/qrCode/getCode") => {
                let png: Vec<u8> = vec![0x89, b'P', b'N', b'G', 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0];
                binary_response(200, "image/png", &png)
            }
            ("GET", "/authserver/qrCode/getStatus.htl") => text_response(200, "0", ""),
            ("GET", "/authserver/bfp/info") => {
                extra_headers.push_str(
                    "Set-Cookie: MULTIFACTOR_BROWSER_FINGERPRINT=mockbfp; Path=/; HttpOnly\r\n",
                );
                text_response(200, "", &extra_headers)
            }
            ("GET", "/authserver/checkNeedCaptcha.htl") => text_response(200, "{\"isNeed\":false}", ""),
            ("POST", "/authserver/login") => {
                redirect(
                    format!("http://127.0.0.1:{port}/njlgdx/indexsso.jsp?ticket=ST-MOCK"),
                    &[
                        "CASTGC=TGT-MOCK; Path=/; HttpOnly",
                        "happyVoyage=mockhappy; Path=/; HttpOnly",
                    ],
                )
            }
            ("GET", "/njlgdx/xk/LoginToXk") => redirect(
                format!("http://127.0.0.1:{port}/njlgdx/framework/main.jsp"),
                &["JSESSIONID=MOCKJSESS; Path=/njlgdx"],
            ),
            ("GET", "/njlgdx/framework/main.jsp") => {
                // Gate on the presence of CASTGC in the Cookie header. The
                // Rust code stores CASTGC only after a successful login,
                // so this prevents check_session() from short-circuiting
                // before login_if_needed has done any work.
                let logged_in = buf[..total]
                    .windows(4)
                    .any(|w| w == b"CAST")
                    || req.contains("CASTGC")
                    || req.contains("MOCKJSESS");
                if logged_in {
                    extra_headers.push_str("Set-Cookie: route=mockroute; Path=/njlgdx\r\n");
                    text_response(200, student_center, &extra_headers)
                } else {
                    // Emulate the school's pre-login redirect to CAS.
                    redirect(
                        format!(
                            "http://127.0.0.1:{port}/authserver/login?service=http%3A%2F%2F127.0.0.1%3A{port}%2Fnjlgdx%2Findexsso.jsp"
                        ),
                        &[],
                    )
                }
            }
            _ => text_response(404, "not found", ""),
        };
        let _ = stream.write_all(&response);
        let _ = stream.flush();
    }
}

#[cfg(not(target_arch = "wasm32"))]
fn build_http_response(
    status: u16,
    content_type: &str,
    body: &[u8],
    extra_headers: &str,
) -> Vec<u8> {
    let reason = match status {
        200 => "OK",
        302 => "Found",
        404 => "Not Found",
        _ => "OK",
    };
    let trailing = if extra_headers.ends_with("\r\n") || extra_headers.is_empty() {
        "\r\n"
    } else {
        "\r\n\r\n"
    };
    let header = format!(
        "HTTP/1.1 {status} {reason}\r\nContent-Type: {content_type}\r\nContent-Length: {}\r\n{}{}",
        body.len(),
        extra_headers,
        trailing
    );
    let mut out = header.into_bytes();
    out.extend_from_slice(body);
    out
}

#[cfg(not(target_arch = "wasm32"))]
fn redirect(location: String, cookies: &[&str]) -> Vec<u8> {
    let mut extra = String::new();
    for c in cookies {
        extra.push_str(&format!("Set-Cookie: {c}\r\n"));
    }
    build_http_response(
        302,
        "text/html; charset=utf-8",
        b"",
        &format!("Location: {location}\r\n{extra}"),
    )
}

#[cfg(not(target_arch = "wasm32"))]
fn text_response(status: u16, body: &str, extra_headers: &str) -> Vec<u8> {
    build_http_response(status, "text/html; charset=utf-8", body.as_bytes(), extra_headers)
}

#[cfg(not(target_arch = "wasm32"))]
fn binary_response(status: u16, content_type: &str, body: &[u8]) -> Vec<u8> {
    build_http_response(status, content_type, body, "")
}
}

