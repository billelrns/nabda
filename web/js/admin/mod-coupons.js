// الكوبونات والعروض — نفس مخطّط التطبيق (coupons: code, discount, type percentage|fixed, maxUses, usedCount, isActive)
import { db, esc, num, ago, toast, confirmBox, openModal, closeModal, log, FV, TS } from './core.js';

let unsub = null;
export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>الكوبونات والعروض</h1><p>أكواد الخصم المشتركة بين التطبيق والموقع</p></div>
      <div class="ad-actions"><button class="btn btn-primary" id="cp-new">+ كوبون جديد</button></div></div>
      <div class="grid g-3" id="cp-list"><div class="skel" style="height:130px"></div></div>`;
    el.querySelector('#cp-new').onclick = () => edit(null);
    unsub = db.collection('coupons').orderBy('createdAt', 'desc').onSnapshot((s) => {
      const rows = s.docs.map((d) => ({ id: d.id, ...d.data() }));
      const box = document.getElementById('cp-list'); if (!box) return;
      box.innerHTML = rows.length ? rows.map((c) => {
        const used = Number(c.usedCount || 0); const max = Number(c.maxUses || 100); const pct = Math.min(100, Math.round(used / Math.max(1, max) * 100));
        const expired = c.expiresAt && c.expiresAt.toDate && c.expiresAt.toDate() < new Date();
        return `<div class="card" style="${c.isActive && !expired ? '' : 'opacity:.6'}"><div class="card-b" style="display:grid;gap:10px">
          <div style="display:flex;align-items:center;gap:10px"><span style="font:900 18px/1 monospace;letter-spacing:1px;background:var(--pink-soft);color:var(--pink);padding:8px 12px;border-radius:10px;border:1.5px dashed var(--pink)">${esc(c.code)}</span>
            <label class="switch" style="margin-right:auto" title="تفعيل"><input type="checkbox" data-tg="${esc(c.id)}" ${c.isActive ? 'checked' : ''}><span></span></label></div>
          <div style="font-weight:900;font-size:17px">${c.type === 'percentage' ? `${num(c.discount)}% خصم` : `${num(c.discount)} دج خصم ثابت`}</div>
          <div><div class="bar-track"><div class="bar-fill" style="width:${pct}%"></div></div><div style="font-size:12px;color:var(--ink-3);margin-top:4px">استُعمل ${num(used)} / ${num(max)}${expired ? ' · <b style="color:var(--red)">منتهي</b>' : c.expiresAt ? ' · ينتهي ' + ago(c.expiresAt) : ''}</div></div>
          <div style="display:flex;gap:6px"><button class="btn btn-sm" data-cp="${esc(c.code)}">📋 نسخ</button><button class="btn btn-sm" data-ed="${esc(c.id)}">✏️ تعديل</button><button class="btn btn-sm btn-danger" data-rm="${esc(c.id)}">حذف</button></div>
        </div></div>`;
      }).join('') : '<div class="card" style="grid-column:1/-1"><div class="empty"><div class="em">🎟️</div>لا توجد كوبونات بعد</div></div>';
      box.querySelectorAll('[data-tg]').forEach((i) => i.onchange = async () => { try { await db.collection('coupons').doc(i.dataset.tg).update({ isActive: i.checked }); log('coupon.toggle', i.dataset.tg, { active: i.checked }); } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); } });
      box.querySelectorAll('[data-cp]').forEach((b) => b.onclick = () => { navigator.clipboard?.writeText(b.dataset.cp); toast('نُسخ الكود'); });
      box.querySelectorAll('[data-ed]').forEach((b) => b.onclick = () => edit(rows.find((r) => r.id === b.dataset.ed)));
      box.querySelectorAll('[data-rm]').forEach((b) => b.onclick = async () => { if (!(await confirmBox('حذف هذا الكوبون؟', { danger: true, ok: 'حذف' }))) return; try { await db.collection('coupons').doc(b.dataset.rm).delete(); log('coupon.delete', b.dataset.rm); toast('حُذف', 'success'); } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); } });
    }, (e) => { document.getElementById('cp-list').innerHTML = `<div class="alert red">${esc(e.code || e.message)}</div>`; });
    return () => unsub && unsub();
  },
};

function edit(c) {
  const exp = c?.expiresAt?.toDate ? c.expiresAt.toDate().toISOString().slice(0, 10) : '';
  openModal({ title: c ? 'تعديل الكوبون' : 'كوبون جديد', body: `<div class="form">
    <div class="field"><label>كود الكوبون *</label><input class="input" id="cp-code" dir="ltr" style="text-transform:uppercase;font-weight:900;letter-spacing:1px" value="${esc(c?.code || '')}" placeholder="NABDA10"></div>
    <div class="f-row"><div class="field"><label>القيمة *</label><input class="input" id="cp-val" type="number" min="1" value="${esc(c?.discount ?? '')}"></div>
      <div class="field"><label>النوع</label><select class="input" id="cp-type"><option value="percentage" ${c?.type !== 'fixed' ? 'selected' : ''}>نسبة %</option><option value="fixed" ${c?.type === 'fixed' ? 'selected' : ''}>مبلغ ثابت (دج)</option></select></div></div>
    <div class="f-row"><div class="field"><label>الحد الأقصى للاستخدام</label><input class="input" id="cp-max" type="number" min="1" value="${esc(c?.maxUses ?? 100)}"></div>
      <div class="field"><label>تاريخ الانتهاء (اختياري)</label><input class="input" id="cp-exp" type="date" value="${exp}"></div></div></div>`,
  foot: '<button class="btn btn-primary" id="cp-save">حفظ</button><button class="btn" data-close-modal>إلغاء</button>' });
  document.getElementById('cp-save').onclick = async () => {
    const code = document.getElementById('cp-code').value.trim().toUpperCase().replace(/\s+/g, '');
    const discount = Number(document.getElementById('cp-val').value);
    const type = document.getElementById('cp-type').value;
    if (!/^[A-Z0-9_-]{3,24}$/.test(code)) return toast('الكود: 3–24 حرفاً لاتينياً أو رقماً', 'error');
    if (!(discount > 0) || (type === 'percentage' && discount > 90)) return toast('قيمة الخصم غير صالحة (النسبة ≤ 90%)', 'error');
    const e = document.getElementById('cp-exp').value;
    const data = { code, discount, type, maxUses: Math.max(1, parseInt(document.getElementById('cp-max').value, 10) || 100), expiresAt: e ? TS().fromDate(new Date(e + 'T23:59:59')) : null };
    try {
      if (c) await db.collection('coupons').doc(c.id).update(data);
      else {
        const dup = await db.collection('coupons').where('code', '==', code).limit(1).get();
        if (!dup.empty) return toast('هذا الكود موجود مسبقاً', 'error');
        await db.collection('coupons').add({ ...data, usedCount: 0, isActive: true, createdAt: FV().serverTimestamp() });
      }
      log(c ? 'coupon.update' : 'coupon.create', code); toast('حُفظ الكوبون ✓', 'success'); closeModal();
    } catch (ex) { toast('تعذّر (مالك/مشرفة): ' + (ex.code || ''), 'error'); }
  };
}
