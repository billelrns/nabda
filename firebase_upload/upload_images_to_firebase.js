// ============================================================
// نبضة — رفع صور المقالات + البانر إلى Firebase Storage
// تشغيل:  node upload_images_to_firebase.js
// يتطلب Node 18+ (fetch مدمج). بدون أي مكتبات خارجية.
// ============================================================
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// ---------- الإعدادات ----------
const API_KEY = 'AIzaSyDyFmGvaOMAzb2XXOFR_RO_lSn7UYyBd6M';
const BUCKET = 'nabda-app-ca864.firebasestorage.app';
const ADMIN_EMAIL = 'billel@nabda.com';

// المجلدات المحلية التي سترفع (المصدر → المسار داخل Storage)
const LOCAL_DIRS = [
  { src: 'C:\\nabda_app\\assets\\images\\article_pics', dest: 'article_pics' },
  { src: 'C:\\nabda_app\\assets\\images\\articles',     dest: 'article_categories' },
];

// بانرات المتجر المولدة على Higgsfield (تُحمَّل ثم تُرفع إلى banners/)
const REMOTE_FILES = [
  { url: 'https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260727_121537_7abcceff-0640-4e4a-8a04-5a9d5546636e.png', dest: 'banners/shop_banner_3d.png' },
  { url: 'https://d8j0ntlcm91z4.cloudfront.net/user_3DngLJtHaOKYTwAJGppvUUZgNwb/hf_20260727_121540_0a934f36-9124-479f-a1f4-c13b7e586ddc.png', dest: 'banners/shop_banner_photo.png' },
];
// --------------------------------

function ask(q, hide) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(res => {
    if (hide) {
      process.stdout.write(q);
      const onData = c => {
        c = c + '';
        if (c === '\n' || c === '\r' || c === '\u0004') {
          process.stdin.removeListener('data', onData);
          process.stdin.setRawMode(false);
          process.stdout.write('\n');
          rl.close(); res(pw);
        } else if (c === '\u0003') { process.exit(1); }
        else if (c === '\u0008' || c === '\u007f') { pw = pw.slice(0, -1); }
        else { pw += c; }
      };
      let pw = '';
      process.stdin.setRawMode(true);
      process.stdin.on('data', onData);
    } else rl.question(q, a => { rl.close(); res(a.trim()); });
  });
}

async function signIn(email, password) {
  const r = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const j = await r.json();
  if (!r.ok) throw new Error('فشل تسجيل الدخول: ' + (j.error?.message || r.status));
  return j.idToken;
}

async function listExisting(prefix, token) {
  const names = new Set();
  let pageToken = '';
  do {
    const u = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o?prefix=${encodeURIComponent(prefix + '/')}&maxResults=1000${pageToken ? '&pageToken=' + pageToken : ''}`;
    const r = await fetch(u, { headers: { Authorization: 'Firebase ' + token } });
    if (!r.ok) break;
    const j = await r.json();
    (j.items || []).forEach(it => names.add(it.name));
    pageToken = j.nextPageToken || '';
  } while (pageToken);
  return names;
}

function contentType(f) {
  const e = path.extname(f).toLowerCase();
  return e === '.png' ? 'image/png' : e === '.webp' ? 'image/webp' : 'image/jpeg';
}

async function uploadBytes(objectName, bytes, ctype, token) {
  const r = await fetch(`https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o?name=${encodeURIComponent(objectName)}`, {
    method: 'POST', headers: { Authorization: 'Firebase ' + token, 'Content-Type': ctype }, body: bytes,
  });
  const j = await r.json();
  if (!r.ok) throw new Error(`فشل رفع ${objectName}: ` + (j.error?.message || r.status));
  const tok = (j.downloadTokens || '').split(',')[0];
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(objectName)}?alt=media${tok ? '&token=' + tok : ''}`;
}

(async () => {
  console.log('=== نبضة: رفع الصور إلى Firebase Storage ===');
  const email = (await ask(`البريد الإداري [${ADMIN_EMAIL}]: `)) || ADMIN_EMAIL;
  const pass = await ask('كلمة المرور: ', true);
  console.log('تسجيل الدخول...');
  const token = await signIn(email, pass);
  console.log('✓ تم تسجيل الدخول\n');

  const map = {};
  let up = 0, skip = 0, fail = 0;

  // 1) المجلدات المحلية
  for (const d of LOCAL_DIRS) {
    if (!fs.existsSync(d.src)) { console.log(`⚠ مجلد غير موجود، تخطي: ${d.src}`); continue; }
    const existing = await listExisting(d.dest, token);
    const files = fs.readdirSync(d.src).filter(f => /\.(png|jpe?g|webp)$/i.test(f));
    console.log(`▶ ${d.src} → ${d.dest}/  (${files.length} ملف، ${existing.size} موجود مسبقاً)`);
    for (const f of files) {
      const obj = `${d.dest}/${f}`;
      if (existing.has(obj)) { skip++; map[obj] = `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(obj)}?alt=media`; continue; }
      try {
        map[obj] = await uploadBytes(obj, fs.readFileSync(path.join(d.src, f)), contentType(f), token);
        up++; if (up % 20 === 0) console.log(`  ...${up} مرفوع`);
      } catch (e) { fail++; console.log('  ✗ ' + e.message); }
    }
  }

  // 2) البانرات من Higgsfield
  const existingBanners = await listExisting('banners', token);
  for (const rf of REMOTE_FILES) {
    if (existingBanners.has(rf.dest)) { skip++; continue; }
    try {
      console.log(`▶ تحميل بانر: ${rf.dest}`);
      const r = await fetch(rf.url);
      if (!r.ok) throw new Error('HTTP ' + r.status);
      const bytes = Buffer.from(await r.arrayBuffer());
      // حفظ نسخة محلية أيضاً
      const localDir = path.join(__dirname, 'banners');
      fs.mkdirSync(localDir, { recursive: true });
      fs.writeFileSync(path.join(localDir, path.basename(rf.dest)), bytes);
      map[rf.dest] = await uploadBytes(rf.dest, bytes, 'image/png', token);
      up++;
    } catch (e) { fail++; console.log('  ✗ ' + rf.dest + ': ' + e.message); }
  }

  fs.writeFileSync(path.join(__dirname, 'urls_map.json'), JSON.stringify(map, null, 2), 'utf8');
  console.log(`\n=== النتيجة: ${up} مرفوع | ${skip} متخطى (موجود) | ${fail} فشل ===`);
  console.log('خريطة الروابط: firebase_upload/urls_map.json');
})().catch(e => { console.error('خطأ: ' + e.message); process.exit(1); });
