// أداة جلب بسيطة مع محاولات إعادة و User-Agent متصفح حقيقي
// (Node 18+ فيه fetch مدمج)

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
  '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36';

async function getText(url, { retries = 3, timeout = 20000 } = {}) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const ctrl = new AbortController();
      const t = setTimeout(() => ctrl.abort(), timeout);
      const res = await fetch(url, {
        signal: ctrl.signal,
        headers: {
          'User-Agent': UA,
          'Accept': 'text/html,application/json,application/xml,*/*',
          'Accept-Language': 'ar,fr;q=0.8,en;q=0.6',
        },
      });
      clearTimeout(t);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.text();
    } catch (e) {
      if (attempt === retries) throw e;
      await new Promise((r) => setTimeout(r, 800 * attempt));
    }
  }
}

async function getJson(url, opts) {
  const txt = await getText(url, opts);
  return JSON.parse(txt);
}

module.exports = { getText, getJson };
