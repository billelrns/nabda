// المحتوى: مقالات ديناميكية (dynamic_articles — تظهر في التطبيق) + مقالات متخصّصة (specialized_articles)
import { db, esc, ago, mountTable, openModal, closeModal, toast, confirmBox, log, FV, uploadImage } from './core.js';

const SECTIONS = { home: 'الرئيسية', cycle: 'الدورة', pregnancy: 'الحمل', baby: 'الطفل', news: 'أخبار' };
// كلمات تستوجب مراجعة (لا نصائح علاجية ولا ادّعاء صفة طبية)
const RISKY = ['دواء', 'جرعة', 'علاج', 'مضاد حيوي', 'د.', 'دكتور', 'طبيب', 'فريق طبي', 'مكمل', 'فيتامين'];
let tab = 'dynamic'; let table = null; let unsub = null;

export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>المحتوى</h1><p>مقالات تظهر داخل التطبيق والموقع — المؤلّف دائماً «فريق تحرير نبضة»</p></div>
      <div class="ad-actions"><button class="btn btn-primary" id="ct-new">+ مقال جديد</button></div></div>
      <div class="tabs" id="ct-tabs"><button data-t="dynamic" class="${tab === 'dynamic' ? 'active' : ''}">📰 المقالات الديناميكية</button><button data-t="specialized" class="${tab === 'specialized' ? 'active' : ''}">📚 المقالات المتخصّصة</button></div>
      <div class="alert amber" style="margin-bottom:14px">⚠️ سياسة نبضة: لا وصف أدوية أو جرعات أو تشخيص، ولا نسبة أي محتوى لطبيب أو «فريق طبي». الموسوعة (آلاف المقالات) تُدار من ملفات البيانات في المستودع.</div>
      <div class="card" id="ct-tbl"></div>`;
    el.querySelectorAll('#ct-tabs button').forEach((b) => b.onclick = () => { tab = b.dataset.t; el.querySelectorAll('#ct-tabs button').forEach((x) => x.classList.toggle('active', x === b)); load(); });
    el.querySelector('#ct-new').onclick = () => edit(null);
    load();
    return () => unsub && unsub();
  },
};

function load() {
  if (unsub) unsub();
  table = null;
  document.getElementById('ct-tbl').innerHTML = '<div class="card-b"><div class="skel" style="height:200px"></div></div>';
  const col = tab === 'dynamic' ? 'dynamic_articles' : 'specialized_articles';
  unsub = db.collection(col).onSnapshot((snap) => {
    const rows = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    if (tab === 'specialized') rows.sort((a, b) => String(a.topic).localeCompare(String(b.topic)) || (a.order || 0) - (b.order || 0));
    const cols = tab === 'dynamic' ? [
      { key: 'title', label: 'العنوان', render: (r) => `<div class="cell-prod">${r.image ? `<img src="${esc(r.image)}" alt="">` : ''}<div><div class="cell-strong">${esc(r.title)}</div><div class="muted">${esc(r.category || '')}</div></div></div>` },
      { key: 'section', label: 'القسم', render: (r) => `<span class="tag">${esc(SECTIONS[r.section] || r.section || '—')}</span>` },
      { key: 'createdAt', label: 'أُضيف', sort: (r) => r.createdAt?.seconds || 0, render: (r) => `<span class="muted">${ago(r.createdAt)}</span>` },
    ] : [
      { key: 'title', label: 'العنوان', render: (r) => `<div class="cell-strong">${esc(r.title)}</div>` },
      { key: 'topic', label: 'الموضوع', render: (r) => `<span class="tag">${esc(r.topic || '')}</span>` },
      { key: 'order', label: 'الترتيب' },
    ];
    if (table) return table.setRows(rows, true);
    table = mountTable(document.getElementById('ct-tbl'), { rows, columns: cols, pageSize: 25, onRow: (r) => edit(r), empty: 'لا مقالات', emptyIcon: '📰' });
  }, (e) => { document.getElementById('ct-tbl').innerHTML = `<div class="alert red">تعذّر: ${esc(e.code || e.message)}</div>`; });
}

function edit(r) {
  const dyn = tab === 'dynamic';
  const a = r || {};
  openModal({
    title: r ? 'تعديل مقال' : 'مقال جديد', wide: true,
    body: `<div class="form">
      <div class="field"><label>العنوان *</label><input class="input" id="ce-title" maxlength="160" value="${esc(a.title || '')}"></div>
      ${dyn ? `<div class="f-row"><div class="field"><label>القسم</label><select class="select" id="ce-section">${Object.entries(SECTIONS).map(([k, l]) => `<option value="${k}" ${a.section === k ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
        <div class="field"><label>التصنيف</label><input class="input" id="ce-cat" value="${esc(a.category || '')}"></div></div>`
      : `<div class="f-row"><div class="field"><label>الموضوع (topic)</label><input class="input" id="ce-topic" dir="ltr" value="${esc(a.topic || '')}"></div><div class="field"><label>الترتيب</label><input class="input" type="number" id="ce-order" value="${a.order ?? 0}"></div></div>`}
      <div class="field"><label>النص *</label><textarea class="textarea" id="ce-body" rows="14">${esc(dyn ? a.content || '' : a.body || '')}</textarea><span class="hint" id="ce-risk"></span></div>
      <div class="field"><label>الصورة</label><div style="display:flex;gap:8px;align-items:center"><input class="input" id="ce-img" dir="ltr" value="${esc(a.image || '')}" style="flex:1" placeholder="https://…"><button class="btn" type="button" id="ce-up">📷 رفع</button><input type="file" id="ce-file" accept="image/*" class="hidden"></div></div>
      <div class="hint">المؤلّف: فريق تحرير نبضة (ثابت).</div></div>`,
    foot: `<button class="btn btn-primary" id="ce-save">💾 حفظ</button><button class="btn" data-close-modal>إلغاء</button>${r ? '<button class="btn btn-danger" id="ce-del" style="margin-right:auto">🗑️ حذف</button>' : ''}`,
  });
  const $ = (i) => document.getElementById(i);
  const risk = () => { const t = $('ce-body').value + ' ' + $('ce-title').value; const hits = RISKY.filter((w) => t.includes(w)); $('ce-risk').innerHTML = hits.length ? `<span style="color:#B45309">⚠️ راجعي هذه الكلمات قبل النشر: ${hits.map(esc).join('، ')}</span>` : ''; };
  $('ce-body').oninput = risk; risk();
  $('ce-up').onclick = () => $('ce-file').click();
  $('ce-file').onchange = async (e) => { const f = e.target.files[0]; if (!f) return; $('ce-up').textContent = '⏳'; try { $('ce-img').value = await uploadImage(f, dyn ? 'articles' : 'specialized'); } catch (er) { toast('فشل الرفع: ' + (er.code || ''), 'error'); } $('ce-up').textContent = '📷 رفع'; };
  $('ce-save').onclick = async () => {
    const title = $('ce-title').value.trim(); const text = $('ce-body').value.trim();
    if (!title || !text) return toast('العنوان والنص مطلوبان', 'error');
    const col = dyn ? 'dynamic_articles' : 'specialized_articles';
    const data = dyn
      ? { title, content: text, image: $('ce-img').value.trim(), category: $('ce-cat').value.trim(), section: $('ce-section').value, author: 'فريق تحرير نبضة' }
      : { title, body: text, image: $('ce-img').value.trim(), topic: $('ce-topic').value.trim(), order: Number($('ce-order').value) || 0, updatedAt: FV().serverTimestamp() };
    try {
      if (r) await db.collection(col).doc(r.id).set(data, { merge: true });
      else await db.collection(col).add({ ...data, createdAt: FV().serverTimestamp() });
      log('content.' + (r ? 'update' : 'create'), title); toast('حُفظ المقال', 'success'); closeModal();
    } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); }
  };
  $('ce-del')?.addEventListener('click', async () => {
    closeModal();
    if (!(await confirmBox(`حذف «${a.title}»؟`, { danger: true, ok: 'حذف' }))) return;
    try { await db.collection(dyn ? 'dynamic_articles' : 'specialized_articles').doc(r.id).delete(); log('content.delete', a.title); toast('حُذف', 'success'); } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); }
  });
}
