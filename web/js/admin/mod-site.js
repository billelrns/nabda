// واجهة الموقع: شرائح سلايدر الصفحة الرئيسية (site_config/home) مع معاينة وترتيب ورفع صور
import { db, esc, toast, confirmBox, log, FV, uploadImage } from './core.js';

const DEFAULTS = [
  { img: '/landing-assets/slide-pregnancy.webp', tag: '✨ تطبيق صحة المرأة بالعربية', title: 'رحلتُكِ إلى الأمومة تبدأ من هنا', desc: 'تابعي حملكِ أسبوعاً بأسبوع مع نصائح مخصّصة وعدّ تنازلي للولادة.', cta: 'ابدئي رحلتكِ', link: '/pregnancy' },
  { img: '/landing-assets/slide-cycle.webp', tag: '📅 تتبع الدورة الشهرية', title: 'افهمي جسمكِ بشكل أعمق', desc: 'تقويم ذكي يتوقّع دورتكِ وأيام الخصوبة.', cta: 'تتبّعي دورتكِ', link: '/cycle' },
  { img: '/landing-assets/slide-baby.webp', tag: '👶 رعاية الطفل', title: 'رافقي نموّ طفلكِ يوماً بيوم', desc: 'مراحل النمو الشهرية، نصائح الرضاعة والنوم.', cta: 'اكتشفي المزيد', link: '/baby' },
  { img: '/landing-assets/slide-store.webp', tag: '🛍️ متجر نبضة', title: 'كل ما يحتاجه طفلكِ في مكان واحد', desc: 'منتجات مختارة مع التوصيل والدفع عند الاستلام.', cta: 'تسوّقي الآن', link: '/shop' },
];
let slides = [];

export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>واجهة الموقع</h1><p>شرائح السلايدر في الصفحة الرئيسية لـ nabda.online</p></div>
      <div class="ad-actions"><a class="btn" href="/" target="_blank" rel="noopener">↗ معاينة الموقع</a><button class="btn" id="st-add">+ شريحة</button><button class="btn btn-primary" id="st-save">💾 نشر التغييرات</button></div></div>
      <div id="st-list" class="grid"><div class="skel" style="height:200px"></div></div>`;
    db.collection('site_config').doc('home').get().then((d) => {
      slides = d.exists && Array.isArray(d.data().slides) && d.data().slides.length ? d.data().slides : JSON.parse(JSON.stringify(DEFAULTS));
      draw();
    }).catch((e) => { document.getElementById('st-list').innerHTML = `<div class="alert red">${esc(e.code || e.message)}</div>`; });
    el.querySelector('#st-add').onclick = () => { slides.push({ img: '', tag: '', title: 'عنوان جديد', desc: '', cta: 'اكتشفي', link: '/' }); draw(); };
    el.querySelector('#st-save').onclick = save;
  },
};

function draw() {
  const box = document.getElementById('st-list');
  box.innerHTML = slides.map((s, i) => `
    <div class="card"><div class="card-h"><h3>الشريحة ${i + 1}</h3><div class="ad-actions">
      <button class="btn btn-sm" data-mv="${i}" data-d="-1" ${i === 0 ? 'disabled' : ''}>▲</button><button class="btn btn-sm" data-mv="${i}" data-d="1" ${i === slides.length - 1 ? 'disabled' : ''}>▼</button>
      <label class="check" style="font-size:12.5px"><input type="checkbox" data-f="hidden" data-i="${i}" ${s.hidden ? 'checked' : ''}> مخفية</label>
      <button class="btn btn-sm btn-danger" data-rm="${i}">حذف</button></div></div>
      <div class="card-b" style="display:grid;grid-template-columns:320px minmax(0,1fr);gap:18px" class="st-g">
        <div><div style="position:relative;border-radius:14px;overflow:hidden;aspect-ratio:16/9;background:#FFF0F5 center/cover no-repeat;background-image:url('${esc(s.img)}')">
          <div style="position:absolute;inset:0;background:linear-gradient(270deg,rgba(255,255,255,.92) 0%,rgba(255,255,255,.4) 55%,transparent 100%);padding:14px;display:flex;flex-direction:column;justify-content:center;gap:4px">
            <span style="font-size:10px;font-weight:800;color:#E91E63">${esc(s.tag)}</span><b style="font-size:15px;color:#1D1720">${esc(s.title)}</b><span style="font-size:10.5px;color:#4B4450">${esc(s.desc)}</span>
            <span style="align-self:flex-start;margin-top:4px;background:#F43F7E;color:#fff;border-radius:999px;padding:3px 10px;font-size:10px;font-weight:800">${esc(s.cta)}</span></div></div>
          <button class="btn btn-sm" style="margin-top:8px;width:100%;justify-content:center" data-up="${i}">📷 تغيير الصورة</button></div>
        <div class="form">
          <div class="f-row"><div class="field"><label>الشارة</label><input class="input" data-f="tag" data-i="${i}" value="${esc(s.tag)}"></div><div class="field"><label>العنوان</label><input class="input" data-f="title" data-i="${i}" value="${esc(s.title)}"></div></div>
          <div class="field"><label>الوصف</label><input class="input" data-f="desc" data-i="${i}" value="${esc(s.desc)}"></div>
          <div class="f-row"><div class="field"><label>نص الزر</label><input class="input" data-f="cta" data-i="${i}" value="${esc(s.cta)}"></div><div class="field"><label>الرابط</label><input class="input" dir="ltr" data-f="link" data-i="${i}" value="${esc(s.link)}" placeholder="/shop"></div></div>
          <div class="field"><label>رابط الصورة</label><input class="input" dir="ltr" data-f="img" data-i="${i}" value="${esc(s.img)}"></div>
        </div></div></div>`).join('') + '<input type="file" id="st-file" accept="image/*" class="hidden"><style>@media(max-width:900px){.card-b[style*="320px"]{grid-template-columns:1fr!important}}</style>';
  box.querySelectorAll('[data-f]').forEach((inp) => {
    inp.onchange = () => { const s = slides[+inp.dataset.i]; s[inp.dataset.f] = inp.type === 'checkbox' ? inp.checked : inp.value.trim(); draw(); };
  });
  box.querySelectorAll('[data-mv]').forEach((b) => b.onclick = () => { const i = +b.dataset.mv; const j = i + Number(b.dataset.d); [slides[i], slides[j]] = [slides[j], slides[i]]; draw(); });
  box.querySelectorAll('[data-rm]').forEach((b) => b.onclick = async () => { if (await confirmBox('حذف هذه الشريحة؟', { danger: true })) { slides.splice(+b.dataset.rm, 1); draw(); } });
  let target = null;
  box.querySelectorAll('[data-up]').forEach((b) => b.onclick = () => { target = +b.dataset.up; document.getElementById('st-file').click(); });
  document.getElementById('st-file').onchange = async (e) => {
    const f = e.target.files[0]; if (!f || target === null) return;
    toast('جاري رفع الصورة…');
    try { slides[target].img = await uploadImage(f, 'ads'); draw(); toast('رُفعت — لا تنسي «نشر التغييرات»', 'success'); } catch (er) { toast('فشل الرفع: ' + (er.code || ''), 'error'); }
  };
}

async function save() {
  const bad = slides.find((s) => !s.title || !s.img);
  if (bad) return toast('كل شريحة تحتاج عنواناً وصورة', 'error');
  try {
    // الرئيسية تعرض الشرائح غير المخفية فقط
    await db.collection('site_config').doc('home').set({ slides: slides.filter((s) => !s.hidden), allSlides: slides, updatedAt: FV().serverTimestamp() }, { merge: true });
    log('site.slides', `${slides.length} شرائح`);
    toast('نُشرت الشرائح على الموقع ✓', 'success');
  } catch (e) { toast('تعذّر النشر (صلاحية المشرفة): ' + (e.code || ''), 'error'); }
}
