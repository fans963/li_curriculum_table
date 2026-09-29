use std::fs;
use std::path::{Path, PathBuf};
use std::sync::RwLock;

use anyhow::{Context, Result};
use cookie_crate::Cookie as RawCookie;
use reqwest::cookie::CookieStore;
use reqwest::header::HeaderValue;
use serde::{Deserialize, Serialize};
use url::Url;

/// One cookie as serialized JSON. We don't try to round-trip every flag of
/// RFC 6265 — only the fields the campus CAS cookies actually use
/// (name, value, domain, path, secure, http_only, expiry).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CookieRecord {
    pub name: String,
    pub value: String,
    pub domain: String,
    pub path: String,
    #[serde(default)]
    pub secure: bool,
    #[serde(default)]
    pub http_only: bool,
    /// Unix timestamp in seconds. `None` = session cookie.
    #[serde(default)]
    pub expires_unix: Option<i64>,
}

#[derive(Debug, Default, Serialize, Deserialize)]
struct PersistedFile {
    #[serde(default)]
    cookies: Vec<CookieRecord>,
}

/// A `CookieStore` impl backed by an in-memory `Vec<CookieRecord>` that is
/// mirrored to a JSON file on every mutation.
///
/// On the way out (matching a `cookies(url)` request) we filter by domain
/// suffix (per RFC 6265 §5.1.3) and by path prefix (per §5.1.4), and we
/// drop expired cookies lazily so a stale on-disk file still works after
/// truncation of the timestamps.
pub struct PersistedCookieStore {
    inner: RwLock<Vec<CookieRecord>>,
    path: Option<PathBuf>,
}

impl PersistedCookieStore {
    /// Construct an empty in-memory store with no disk backing. Used when
    /// no storage dir has been configured yet (e.g. before Dart calls
    /// `set_cookie_storage_dir`).
    pub fn empty() -> Self {
        Self {
            inner: RwLock::new(Vec::new()),
            path: None,
        }
    }

    /// Load existing cookies from `path`. Missing file → empty store with
    /// `path` remembered (so the first `set_cookies` writes the file out).
    /// Corrupt file → log + start empty (we never block login on a bad
    /// cookie file).
    pub fn load_or_new(path: PathBuf) -> Self {
        let cookies = match fs::read(&path) {
            Ok(bytes) => match serde_json::from_slice::<PersistedFile>(&bytes) {
                Ok(file) => file.cookies,
                Err(e) => {
                    log::warn!(
                        "CookieStore: ignoring corrupt cookie file ({}): {}",
                        path.display(),
                        e
                    );
                    Vec::new()
                }
            },
            Err(_) => Vec::new(),
        };
        Self {
            inner: RwLock::new(cookies),
            path: Some(path),
        }
    }

    /// Serialize the current cookie jar to JSON bytes. The Dart side
    /// calls this to snapshot cookies into `flutter_secure_storage`.
    pub fn to_json_bytes(&self) -> Result<Vec<u8>> {
        let snapshot = {
            let guard = self
                .inner
                .read()
                .map_err(|_| anyhow::anyhow!("cookie store poisoned"))?;
            PersistedFile {
                cookies: guard.clone(),
            }
        };
        Ok(serde_json::to_vec_pretty(&snapshot)?)
    }

    /// Replace the in-memory jar with records parsed from a JSON blob
    /// previously produced by `to_json_bytes`. Existing cookies are
    /// discarded — callers usually invoke this only at startup.
    pub fn load_from_json(&self, bytes: &[u8]) -> Result<usize> {
        let file: PersistedFile = serde_json::from_slice(bytes)
            .context("parse cookie JSON")?;
        let count = file.cookies.len();
        let mut guard = self
            .inner
            .write()
            .map_err(|_| anyhow::anyhow!("cookie store poisoned"))?;
        *guard = file.cookies;
        Ok(count)
    }

    /// Persist current state to disk. No-op if no storage path is
    /// configured.
    pub fn save_to_disk(&self) -> Result<()> {
        let Some(path) = self.path.as_ref() else {
            return Ok(());
        };
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .with_context(|| format!("create cookie dir {}", parent.display()))?;
        }
        let snapshot = {
            let guard = self
                .inner
                .read()
                .map_err(|_| anyhow::anyhow!("cookie store poisoned"))?;
            PersistedFile {
                cookies: guard.clone(),
            }
        };
        let json = serde_json::to_vec_pretty(&snapshot)?;
        let tmp = path.with_extension("json.tmp");
        fs::write(&tmp, &json)
            .with_context(|| format!("write tmp cookie file {}", tmp.display()))?;
        // Atomic-ish rename so a crash mid-write doesn't leave a half-written file.
        fs::rename(&tmp, path)
            .with_context(|| format!("rename cookie file {}", path.display()))?;
        Ok(())
    }

    /// Wipe both the in-memory jar and the on-disk file.
    pub fn clear(&self) -> Result<()> {
        {
            let mut guard = self
                .inner
                .write()
                .map_err(|_| anyhow::anyhow!("cookie store poisoned"))?;
            guard.clear();
        }
        if let Some(path) = self.path.as_ref() {
            if path.exists() {
                fs::remove_file(path).ok();
            }
        }
        Ok(())
    }

    /// How many cookies we currently hold (for logging).
    pub fn len(&self) -> usize {
        self.inner.read().map(|g| g.len()).unwrap_or(0)
    }

    /// Inject a raw `Set-Cookie`-style string for a given URL.
    /// Mirrors `reqwest::cookie::Jar::add_cookie_str` so existing callers
    /// (e.g. `inject_cookies`) can stay agnostic to the underlying store.
    pub fn add_cookie_str(&self, cookie_str: &str, url: &Url) {
        let host = url.host_str().unwrap_or("").to_string();
        let path_prefix = url.path();
        let parsed = match RawCookie::parse(cookie_str) {
            Ok(c) => c.into_owned(),
            Err(_) => return,
        };
        let domain = parsed
            .domain()
            .map(|d| d.trim_start_matches('.').to_string())
            .unwrap_or_else(|| host.clone());
        let path = parsed
            .path()
            .map(|p| p.to_string())
            .unwrap_or_else(|| path_prefix.to_string());
        let expires_unix = parsed.expires_datetime().and_then(|dt| {
            let ts = dt.unix_timestamp();
            if ts > 0 { Some(ts) } else { None }
        });
        self.upsert(CookieRecord {
            name: parsed.name().to_string(),
            value: parsed.value().to_string(),
            domain,
            path,
            secure: parsed.secure().unwrap_or(false),
            http_only: parsed.http_only().unwrap_or(false),
            expires_unix,
        });
        if let Err(e) = self.save_to_disk() {
            log::warn!(
                "CookieStore: failed to persist after add_cookie_str for {}: {}",
                host,
                e
            );
        }
    }

    /// Whether the jar holds any cookie that would be sent to `host`.
    pub fn has_cookies_for(&self, host: &str) -> bool {
        let Ok(guard) = self.inner.read() else {
            return false;
        };
        guard.iter().any(|c| domain_matches(&c.domain, host))
    }

    /// Drop expired entries (in place). Cheap when the jar is small.
    fn prune_expired(cookies: &mut Vec<CookieRecord>) {
        let now = current_unix();
        cookies.retain(|c| match c.expires_unix {
            None => true,
            Some(exp) => exp > now,
        });
    }

    /// Upsert a single cookie record (matched by domain + path + name).
    fn upsert(&self, record: CookieRecord) {
        let mut guard = match self.inner.write() {
            Ok(g) => g,
            Err(_) => return,
        };
        if let Some(slot) = guard.iter_mut().find(|c| {
            c.name == record.name && c.domain == record.domain && c.path == record.path
        }) {
            *slot = record;
        } else {
            guard.push(record);
        }
        Self::prune_expired(&mut guard);
    }
}

impl CookieStore for PersistedCookieStore {
    fn set_cookies(
        &self,
        cookie_headers: &mut dyn Iterator<Item = &HeaderValue>,
        url: &Url,
    ) {
        let host = url.host_str().unwrap_or("").to_string();
        let path_prefix = url.path();

        let mut changed = false;
        for header in cookie_headers {
            // HeaderValue may not be valid UTF-8; parse via cookie_crate which
            // tolerates raw bytes (RFC 6265 cookies are ASCII).
            let raw = match header.to_str() {
                Ok(s) => s.to_string(),
                Err(_) => match std::str::from_utf8(header.as_bytes()) {
                    Ok(s) => s.to_string(),
                    Err(_) => continue,
                },
            };
            let parsed = match RawCookie::parse(raw) {
                Ok(c) => c.into_owned(),
                Err(_) => continue,
            };

            // Domain precedence: explicit Domain attribute > request host.
            let domain = parsed
                .domain()
                .map(|d| d.trim_start_matches('.').to_string())
                .unwrap_or_else(|| host.clone());
            // Path precedence: explicit Path attribute > request path prefix.
            let path = parsed
                .path()
                .map(|p| p.to_string())
                .unwrap_or_else(|| path_prefix.to_string());
            let expires_unix = parsed.expires_datetime().and_then(|dt| {
                let ts = dt.unix_timestamp();
                if ts > 0 { Some(ts) } else { None }
            });

            let record = CookieRecord {
                name: parsed.name().to_string(),
                value: parsed.value().to_string(),
                domain,
                path,
                secure: parsed.secure().unwrap_or(false),
                http_only: parsed.http_only().unwrap_or(false),
                expires_unix,
            };
            self.upsert(record);
            changed = true;
        }

        if changed {
            if let Err(e) = self.save_to_disk() {
                log::warn!(
                    "CookieStore: failed to persist cookies for {}: {}",
                    host,
                    e
                );
            }
        }
    }

    fn cookies(&self, url: &Url) -> Option<HeaderValue> {
        let host = url.host_str()?;
        let req_path = url.path();

        let guard = self.inner.read().ok()?;
        // Filter and format
        let mut pairs: Vec<String> = Vec::new();
        let mut touched = false;
        for cookie in guard.iter() {
            if !domain_matches(&cookie.domain, host) {
                continue;
            }
            if !path_matches(&cookie.path, req_path) {
                continue;
            }
            // Skip expired
            if let Some(exp) = cookie.expires_unix {
                if exp <= current_unix() {
                    touched = true;
                    continue;
                }
            }
            // Skip secure-only cookies for http://
            if cookie.secure && url.scheme() != "https" {
                continue;
            }
            pairs.push(format!("{}={}", cookie.name, cookie.value));
        }
        drop(guard);

        if touched {
            // Cleanup outside the read lock.
            if let Ok(mut g) = self.inner.write() {
                Self::prune_expired(&mut g);
            }
        }

        if pairs.is_empty() {
            return None;
        }
        let header = pairs.join("; ");
        HeaderValue::from_str(&header).ok()
    }
}

/// RFC 6265 §5.1.3 domain matching: the request host equals the cookie
/// domain, or the cookie domain is a suffix of the request host.
fn domain_matches(cookie_domain: &str, request_host: &str) -> bool {
    let cookie_domain = cookie_domain.trim_start_matches('.');
    let request_host = request_host.trim_start_matches('.');
    if cookie_domain.is_empty() || request_host.is_empty() {
        return false;
    }
    if request_host == cookie_domain {
        return true;
    }
    request_host.ends_with(&format!(".{cookie_domain}"))
}

/// RFC 6265 §5.1.4 path matching: cookie path is `/` or a prefix of the
/// request path (with `/` boundary check).
fn path_matches(cookie_path: &str, request_path: &str) -> bool {
    if cookie_path == "/" || cookie_path.is_empty() {
        return true;
    }
    if request_path.starts_with(cookie_path) {
        return true;
    }
    // §5.1.4: cookie path of "/foo" matches request path "/foo/" but not "/foobar"
    if request_path.starts_with(cookie_path)
        && cookie_path.ends_with('/')
        && request_path.len() > cookie_path.len()
    {
        return true;
    }
    // Trailing slash edge case: "/foo" matches both "/foo" and "/foo/...". 
    let normalized = cookie_path.trim_end_matches('/');
    if !normalized.is_empty() && request_path.starts_with(normalized) {
        let next = request_path.as_bytes().get(normalized.len());
        if matches!(next, Some(b'/') | None) {
            return true;
        }
    }
    false
}

fn current_unix() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

/// Sanity helper used at startup — log how many cookies we restored.
pub fn debug_summary(path: &Path) {
    if let Ok(bytes) = fs::read(path) { if let Ok(f) = serde_json::from_slice::<PersistedFile>(&bytes) { log::info!(
        "CookieStore: loaded {} cookies from {}",
        f.cookies.len(),
        path.display()
    ) } }
}
