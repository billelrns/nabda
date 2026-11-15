// Headless test runner: node run.mjs '<json list of {path,user,w,h,name,actions}>'
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import chromium from '@sparticuz/chromium';
import puppeteer from 'puppeteer-core';

const WEB = '/sessions/sleepy-tender-clarke/mnt/nabda_app/web';
const OUT = '/sessions/sleepy-tender-clarke/mnt/outputs/harness/shots';
const MOCK = fs.readFileSync('/sessions/sleepy-tender-clarke/mnt/outputs/harness/mock-firebase.js', 'utf8');
fs.mkdirSync(OUT, { recursive: true });
const fj = JSON.parse(fs.readFileSync('/sessions/sleepy-tender-clarke/mnt/nabda_app/firebase.json', 'utf8'));
const rewrites = fj.hosting.rewrites || [];
const redirects = fj.hosting.redirects || [];
function globToRe(g) {
  return new RegExp('^' + g.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*\*/g, '§').replace(/\*/g, '[^/]*').replace(/§/g, '.*').replace(/:(\w+)/g, '([^/]+)') + '$');
}
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg', '.webp': 'image/webp', '.svg': 'image/svg+xml', '.xml': 'application/xml', '.txt': 'text/plain' };
const server = http.createServer((req, res) => {
  let p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  for (const r of redirects) { if (globToRe(r.source).test(p)) { const m = p.match(globToRe(r.source)); let d = r.destination; if (m && m[1]) d = d.replace(/:\w+/, m[1]); res.writeHead(301, { Location: d }); return res.end(); } }
  let file = path.join(WEB, p);
  if (p === '/') file = path.join(WEB, 'home.html');
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    if (fs.existsSync(file + '.html')) file = file + '.html';
    else {
      const rw = rewrites.find((r) => globToRe(r.source).test(p));
      if (rw) file = path.join(WEB, rw.destination || (rw.function ? '/product.html' : '/404.html'));
      else { res.writeHead(404, { 'Content-Type': 'text/html; charset=utf-8' }); return res.end(fs.readFileSync(path.join(WEB, '404.html'))); }
    }
  }
  res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(8765, r));

const jobs = JSON.parse(process.argv[2].startsWith('[') ? process.argv[2] : fs.readFileSync(process.argv[2],'utf8'));
const browser = await puppeteer.launch({ args: [...chromium.args, '--lang=ar'], executablePath: await chromium.executablePath(), headless: true });
const report = [];
for (const j of jobs) { try { await Promise.race([runJob(j), new Promise((_,rej)=>setTimeout(()=>rej(new Error('JOB TIMEOUT')),50000))]); } catch(e){ report.push({name:j.name,url:j.path,errs:['FATAL '+e.message]}); } }
async function runJob(j) {
  const page = await browser.newPage();
  await page.setViewport({ width: j.w || 1366, height: j.h || 768 });
  const errs = [];
  page.on('pageerror', (e) => errs.push('PAGEERROR ' + e.message.slice(0, 300)));
  page.on('console', (m) => { if (m.type() === 'error' || m.type() === 'warning') errs.push(m.type().toUpperCase() + ' ' + m.text().slice(0, 300)); });
  page.on('requestfailed', (r) => { if (r.url().includes('127.0.0.1')) errs.push('REQFAIL ' + r.url()); });
  page.on('response', (r) => { if (r.url().includes('127.0.0.1') && r.status() >= 400) errs.push('HTTP' + r.status() + ' ' + r.url().replace('http://127.0.0.1:8765', '')); });
  await page.setRequestInterception(true);
  page.on('request', (r) => {
    const u = r.url();
    if (u.includes('127.0.0.1')) return r.continue();
    if (u.includes('firebase-app-compat')) return r.respond({ status: 200, contentType: 'text/javascript', body: MOCK });
    if (u.includes('gstatic.com/firebasejs')) return r.respond({ status: 200, contentType: 'text/javascript', body: '/*mock*/' });
    if (/\.(png|jpe?g|webp|gif)(\?|$)/i.test(u)) return r.respond({ status: 200, contentType: 'image/png', body: fs.readFileSync(WEB + '/favicon.png') });
    return r.abort();
  });
  await page.evaluateOnNewDocument((user) => { if (user) localStorage.setItem('mock_user', user); else localStorage.removeItem('mock_user'); }, j.user || null);
  const t0=Date.now();
  try {
    await page.goto('http://127.0.0.1:8765' + j.path, { waitUntil: 'load', timeout: 15000 });
  } catch (e) { errs.push('GOTO ' + e.message.slice(0, 200)); }
  errs.push('T_GOTO '+(Date.now()-t0));
  await new Promise((r) => setTimeout(r, j.wait || 1200));
  if (j.actions) {
    for (const a of j.actions) {
      try {
        if (a.click) { await page.click(a.click); }
        if (a.type) { await page.type(a.type[0], a.type[1]); }
        if (a.select) { await page.select(a.select[0], a.select[1]); }
        if (a.eval) { const v = await page.evaluate(a.eval); if (v !== undefined) errs.push('EVAL ' + JSON.stringify(v).slice(0, 1500)); }
        if (a.scroll) { await page.evaluate((y) => window.scrollTo(0, y), a.scroll); }
        await new Promise((r) => setTimeout(r, a.wait || 600));
      } catch (e) { errs.push('ACTION ' + JSON.stringify(a).slice(0, 80) + ' ' + e.message.slice(0, 150)); }
    }
  }
  errs.push('T_ACT '+(Date.now()-t0));
  const name = j.name || j.path.replace(/[^a-z0-9]+/gi, '_');
  await page.screenshot({ path: `${OUT}/${name}.jpg`, type: 'jpeg', quality: 60, fullPage: !!j.full });
  const rec = { name, url: page.url().replace('http://127.0.0.1:8765', ''), errs: [...new Set(errs)].filter(e=>!e.includes('ERR_FAILED')) };
  report.push(rec); console.log(`== ${rec.name}  (${rec.url})`); rec.errs.slice(0,25).forEach(e=>console.log('   '+e));
  await page.close();
}
await browser.close();
server.close();
printReport();
function printReport(){
for (const r of report) { if (r.errs[0]?.startsWith('FATAL')) console.log('== '+r.name+' '+r.errs[0]); }
}
