import express from 'express';
import * as http from "node:http";
import * as https from "node:https";

const app = express();
app.use(express.json());
app.use(express.raw({ type: '*/*', limit: '1mb' }));

// Global CORS Middleware
app.use((req, res, next) => {
    const origin = req.headers.origin || '*';
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', req.headers['access-control-request-headers'] || '*');
    res.setHeader('Access-Control-Expose-Headers', 'X-Proxy-Logs, Content-Type, Set-Cookie');
    
    if (req.method === 'OPTIONS') {
        return res.status(204).end();
    }
    next();
});

// --- Constants and Sharding Logic ---
const DEFAULT_LOGIN_BASE_URL = "http://202.119.81.112:8080";
const DEFAULT_TARGET_URL = "http://202.119.81.112:9080/njlgdx/xskb/xskb_list.do?Ves632DSdyV=NEW_XSD_PYGL";
const ALLOWED_UPSTREAM_HOSTS = ["202.119.81.112", "202.119.81.113", "api1.fans963blog.asia", "api2.fans963blog.asia"];

// --- Logic Helpers ---

function updateSessionFromSetCookie(session, targetUrl, setCookieList) {
  if (!setCookieList || setCookieList.length === 0) return;
  const jsession = extractJsessionId(setCookieList);
  if (!jsession) return;

  const port = getEffectivePort(targetUrl);
  if (port === "8080" || port === "80" || port === "443") {
    session.jsession8080 = jsession;
  } else if (port === "9080") {
    session.jsession9080 = jsession;
  }
}

function extractJsessionId(setCookieList) {
  for (const item of setCookieList) {
    const m = String(item).match(/(?:^|\s|;)JSESSIONID=([^;,\s]+)/i);
    if (m && m[1]) return m[1].trim();
  }
  return "";
}

function getEffectivePort(targetUrl) {
  return targetUrl.port || (targetUrl.protocol === "https:" ? "443" : "80");
}

function buildSessionCookieHeader(session, targetUrl) {
  const port = getEffectivePort(targetUrl);
  const cookie =
    port === "9080"
      ? (session.jsession9080 || session.jsession8080)
      : (port === "8080" || port === "80" || port === "443")
        ? session.jsession8080
        : "";
  return cookie ? `JSESSIONID=${cookie}` : "";
}

function normalizeRoutedUrl(url) {
  // Vercel reaches raw IPs directly, no need for mandatory sharding
  return url;
}

function normalizeUrlWithDefaultPort(rawUrl, defaultPort) {
  const parsed = new URL(String(rawUrl || ""));
  if (!parsed.port) parsed.port = defaultPort;
  return parsed;
}

async function upstreamRequest(url, { method = "GET", session, referer = "", isCaptcha = false, contentType = "", body = null } = {}) {
  const headers = {
    "Accept": "*/*",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36",
    "Accept-Encoding": "identity",
  };

  const cookieStr = buildSessionCookieHeader(session, url);
  if (cookieStr) headers["Cookie"] = cookieStr;
  if (referer) headers["Referer"] = referer;
  if (contentType) headers["Content-Type"] = contentType;
  if (isCaptcha) {
    headers["Accept"] = "image/avif,image/webp,image/apng,image/*,*/*;q=0.8";
    headers["Cache-Control"] = "no-cache";
  }

  const response = await fetch(url.toString(), {
    method,
    headers,
    body: body || undefined,
    redirect: "manual",
  });

  const arrayBuffer = await response.arrayBuffer();
  const bytes = new Uint8Array(arrayBuffer);

  return {
    statusCode: response.status,
    bytes,
    location: response.headers.get("Location") || "",
    contentType: response.headers.get("Content-Type") || "",
    setCookieList: response.headers.getSetCookie ? response.headers.getSetCookie() : (response.headers.get("set-cookie") ? [response.headers.get("set-cookie")] : []),
  };
}

async function upstreamRequestWithRedirects(initialUrl, requestOptions = {}, maxRedirects = 5) {
  let currentUrl = initialUrl;
  let redirects = 0;
  let response = await upstreamRequest(currentUrl, requestOptions);
  updateSessionFromSetCookie(requestOptions.session, currentUrl, response.setCookieList);

  while ([301, 302, 303, 307, 308].includes(response.statusCode) && redirects < maxRedirects) {
    const location = response.location;
    if (!location) break;

    const nextUrl = normalizeRoutedUrl(new URL(location, currentUrl));
    response = await upstreamRequest(nextUrl, { ...requestOptions, method: "GET", body: null, contentType: "" });
    updateSessionFromSetCookie(requestOptions.session, nextUrl, response.setCookieList);
    currentUrl = nextUrl;
    redirects += 1;
  }
  return { response, finalUrl: currentUrl, redirects };
}

function decodeBody(bytes, contentType = "") {
  return new TextDecoder("utf-8").decode(bytes); // Simple decode, Rust handles GBK better
}

// --- Endpoints ---

app.post('/api/session/start', async (req, res) => {
  const body = req.body;
  const loginBase = normalizeUrlWithDefaultPort(body?.loginBaseUrl || DEFAULT_LOGIN_BASE_URL, "8080");
  const session = { jsession8080: "", jsession9080: "" };
  const logs = [];

  try {
    const homeUrl = new URL("/", loginBase);
    const homeResult = await upstreamRequestWithRedirects(homeUrl, { method: "GET", session, referer: `${loginBase.origin}/` });
    logs.push(`[START] GET / status=${homeResult.response.statusCode} url=${homeResult.finalUrl.toString()}`);

    const captchaUrl = new URL(`/verifycode.servlet?t=${Date.now()}`, loginBase);
    const captchaResult = await upstreamRequestWithRedirects(captchaUrl, { method: "GET", session, referer: `${loginBase.origin}/`, isCaptcha: true });
    
    res.json({
      session,
      captchaBase64: Buffer.from(captchaResult.response.bytes).toString('base64'),
      captchaContentType: captchaResult.response.contentType,
      networkLogs: logs
    });
  } catch (e) {
    res.status(502).json({ error: "start_failed", details: String(e), networkLogs: logs });
  }
});

app.post('/api/session/submit', async (req, res) => {
  const { username, password, verifyCode, session, loginBaseUrl, targetUrl } = req.body;
  const loginBase = normalizeUrlWithDefaultPort(loginBaseUrl || DEFAULT_LOGIN_BASE_URL, "8080");
  const target = normalizeUrlWithDefaultPort(targetUrl || DEFAULT_TARGET_URL, "9080");
  const currentSession = session || { jsession8080: "", jsession9080: "" };
  const logs = [];

  try {
    const logonUrl = new URL("/Logon.do?method=logon", loginBase);
    const form = new URLSearchParams({ USERNAME: username, PASSWORD: password, useDogCode: "", RANDOMCODE: verifyCode }).toString();
    logs.push(`[DEBUG] logonUrl=${logonUrl.toString()}`);
    logs.push(`[DEBUG] session_before_login: 8080=${currentSession.jsession8080} 9080=${currentSession.jsession9080}`);

    let postRes = await upstreamRequest(logonUrl, {
      method: "POST",
      session: currentSession,
      referer: `${loginBase.origin}/`,
      contentType: "application/x-www-form-urlencoded",
      body: form
    });
    logs.push(`[SUBMIT] POST status=${postRes.statusCode} location=${postRes.location || 'none'} set-cookie=${JSON.stringify(postRes.setCookieList)}`);
    updateSessionFromSetCookie(currentSession, logonUrl, postRes.setCookieList);
    logs.push(`[DEBUG] session_after_post: 8080=${currentSession.jsession8080} 9080=${currentSession.jsession9080}`);

    // Check the POST response body for error messages (e.g., wrong captcha)
    const postBody = decodeBody(postRes.bytes, postRes.contentType);
    if (postBody && postBody.length < 2000 && postBody.length > 0) {
      logs.push(`[SUBMIT] POST body(${postBody.length}): ${postBody.substring(0, 300)}`);
    }

    let currentUrl = logonUrl;
    let redirects = 0;
    while ([301, 302, 303, 307, 308].includes(postRes.statusCode) && redirects < 5) {
      const location = postRes.location;
      if (!location) break;
      const nextUrl = normalizeRoutedUrl(new URL(location, currentUrl));
      const nextPort = getEffectivePort(nextUrl);
      logs.push(`[REDIRECT] ${redirects+1}: ${nextUrl.toString()} (port=${nextPort})`);
      postRes = await upstreamRequest(nextUrl, { method: "GET", session: currentSession, referer: `${loginBase.origin}/` });
      logs.push(`[REDIRECT] ${redirects+1} result: status=${postRes.statusCode} set-cookie=${JSON.stringify(postRes.setCookieList)}`);
      updateSessionFromSetCookie(currentSession, nextUrl, postRes.setCookieList);
      logs.push(`[DEBUG] session_after_redirect_${redirects+1}: 8080=${currentSession.jsession8080} 9080=${currentSession.jsession9080}`);
      currentUrl = nextUrl;
      redirects += 1;
    }

    // After following redirects, check if the final page is already the success page.
    // The login redirect chain ends on 9080/njlgdx/framework/main.jsp which shows "学生个人中心".
    // Fetching 8080/main.jsp separately ALWAYS fails because the 8080 session is invalidated after login.
    const redirectBody = decodeBody(postRes.bytes, postRes.contentType);
    logs.push(`[AFTER_LOGIN] final status=${postRes.statusCode} url=${currentUrl.toString()} bodyLen=${redirectBody?.length || 0}`);
    if (redirectBody) {
      logs.push(`[AFTER_LOGIN] snippet: ${redirectBody.substring(0, 300)}`);
    }

    // If the redirect chain already landed on a success page, return it directly.
    // Otherwise, try fetching the target URL.
    const isLoginSuccess = redirectBody && (redirectBody.includes("个人中心") || redirectBody.includes("理论课表"));
    
    if (isLoginSuccess) {
      logs.push(`[RESULT] Login success detected from redirect chain, returning redirect page directly`);
      res.json({
        html: Buffer.from(postRes.bytes).toString('base64'),
        networkLogs: logs,
        session: currentSession,
        statusCode: postRes.statusCode
      });
    } else {
      // Fallback: try the target URL (for non-redirect login flows)
      const targetFetchUrl = target;
      logs.push(`[TARGET] fetching ${targetFetchUrl.toString()} cookie8080=${currentSession.jsession8080} cookie9080=${currentSession.jsession9080}`);
      const targetRes = await upstreamRequest(targetFetchUrl, { method: "GET", session: currentSession, referer: currentUrl.toString() });
      const targetBody = decodeBody(targetRes.bytes, targetRes.contentType);
      logs.push(`[TARGET] status=${targetRes.statusCode} bodyLen=${targetBody?.length || 0} snippet=${(targetBody || '').substring(0, 200)}`);
      res.json({
        html: Buffer.from(targetRes.bytes).toString('base64'),
        networkLogs: logs,
        session: currentSession,
        statusCode: targetRes.statusCode
      });
    }
  } catch (e) {
    logs.push(`[ERROR] ${e.message}`);
    res.status(502).json({ error: "submit_failed", details: String(e), networkLogs: logs });
  }
});

// --- Legacy Universal Proxy ---
app.all('/', async (req, res) => {
    const logs = [];
    const urlMatch = req.url.match(/(?<=[?&])url=(?<url>.*)$/);
    if (!urlMatch) return res.status(400).send("query parameter 'url' is required");
    const targetReqUrl = new URL(decodeURIComponent(urlMatch.groups.url));

    const method = req.method;
    const headers = {
        ...req.headers,
        host: targetReqUrl.host,
        origin: targetReqUrl.origin,
        // Browser sets 'referer' to localhost, we allow manual override via X-Proxy-Referer
        referer: req.headers['x-proxy-referer'] || req.headers['x-alt-referer'] || req.headers.referer || targetReqUrl.origin
    };

    // If browser blocks 'Cookie' header, we can use 'X-Proxy-Cookie' as a bypass
    if (req.headers['x-proxy-cookie']) {
        headers['cookie'] = req.headers['x-proxy-cookie'];
    }

    logs.push(`[PROXY] ${method} ${targetReqUrl.toString()}`);
    logs.push(`[PROXY] cookie=${headers['cookie'] || 'none'} x-proxy-cookie=${req.headers['x-proxy-cookie'] || 'none'}`);

    try {
        const response = await fetch(targetReqUrl.toString(), {
            method,
            headers,
            body: (method !== 'GET' && method !== 'HEAD') ? req.body : undefined,
            redirect: 'follow'
        });

        logs.push(`[UPSTREAM] status=${response.status}`);
        if (response.headers.get('location')) {
            logs.push(`[REDIRECT] -> ${response.headers.get('location')}`);
        }

        res.status(response.status);

        // Filter headers: Node's fetch automatically decompresses the body
        const skipHeaders = ['content-encoding', 'content-length', 'transfer-encoding'];
        response.headers.forEach((v, k) => {
            if (!skipHeaders.includes(k.toLowerCase())) {
                res.setHeader(k, v);
            }
        });

        // Attach logs to the response header
        res.setHeader('X-Proxy-Logs', Buffer.from(JSON.stringify(logs)).toString('base64'));

        const body = await response.arrayBuffer();
        res.send(Buffer.from(body));
    } catch (err) {
        logs.push(`[ERROR] ${err.message}`);
        res.setHeader('X-Proxy-Logs', Buffer.from(JSON.stringify(logs)).toString('base64'));
        res.status(502).send(err.message);
    }
});


export default app;