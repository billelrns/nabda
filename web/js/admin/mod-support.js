// دعم واتساب وطلبات الاستعادة — نفس _WhatsAppSupportScreen: app_config/contact.whatsappNumber + password_reset_requests
import { db, esc, ago, fmtDate, toast, confirmBox, log, FV } from './core.js';

let unsub = null; let filter = 'pending';
export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>دعم واتساب وطلبات الاستعادة</h1><p>رقم دعم التطبيق + طلبات إعادة تعيين كلمة المرور الواردة من شاشة «نسيت كلمة المرور»</p></div></div>
      <div class="grid g-21">
        <div class="card"><div class="card-h"><h3>🔑 طلبات إعادة تعيين كلمة المرور</h3>
          <div class="chips" id="sp-f">${[['pending', '⏳ جديدة'], ['resolved', '✅ تمّت'], ['all', 'الكل']].map(([k, l]) => `<button class="chip ${filter === k ? 'active' : ''}" data-f="${k}">${l}</button>`).join('')}</div></div>
          <div class="card-b" id="sp-list"><div class="skel" style="height:160px"></div></div></div>
        <div class="card" style="align-self:start"><div class="card-h"><h3>💬 رقم واتساب الدعم (التطبيق)</h3></div><div class="card-b form">
          <div class="field"><label>الرقم بصيغة دولية بلا + ولا 00</label><input class="input" id="sp-wa" dir="ltr" placeholder="213555123456"></div>
          <button class="btn btn-primary" id="sp-save" style="background:#25D366;border-color:#25D366">💾 حفظ رقم الدعم</button>
          <span class="hint">يظهر في التطبيق لمن نسيت كلمة المرور. رقم واتساب <b>المتجر</b> في الموقع يُضبط من «الإعدادات».</span>
        </div></div>
      </div>`;
    db.collection('app_config').doc('contact').get().then((d) => { const i = document.getElementById('sp-wa'); if (i) i.value = (d.exists && d.data().whatsappNumber) || ''; }).catch(() => {});
    el.querySelector('#sp-save').onclick = async () => {
      const n = document.getElementById('sp-wa').value.replace(/[^\d]/g, '');
      if (n.length < 9) return toast('أدخلي رقماً صحيحاً (مثال 213555123456)', 'error');
      try { await db.collection('app_config').doc('contact').set({ whatsappNumber: n, updatedAt: FV().serverTimestamp() }, { merge: true }); log('support.whatsapp', n); toast('حُفظ رقم الدعم ✓', 'success'); }
      catch (e) { toast('تعذّر (مالك/مشرفة): ' + (e.code || ''), 'error'); }
    };
    let rows = [];
    const draw = () => {
      const box = document.getElementById('sp-list'); if (!box) return;
      const list = rows.filter((r) => filter === 'all' || (filter === 'resolved' ? r.status === 'resolved' : r.status !== 'resolved'));
      box.innerHTML = list.length ? list.map((r) => {
        const done = r.status === 'resolved';
        const phone = String(r.phone || '').replace(/[^\d]/g, '');
        const msg = encodeURIComponent(`مرحباً، بخصوص طلب إعادة تعيين كلمة المرور لحسابك في نبضة (${r.identifier || ''}).`);
        return `<div class="list-row"><span class="kpi-ic" style="background:${done ? 'var(--green-soft)' : 'var(--amber-soft)'}">${done ? '✓' : '🔒'}</span>
          <div style="flex:1;min-width:0"><b>${esc(r.displayName || r.identifier || '—')}</b><div style="font-size:12px;color:var(--ink-3)" dir="ltr">${esc(r.identifier || '')}${phone ? ' · ' + esc(phone) : ''}</div><div style="font-size:11.5px;color:var(--ink-3)">${ago(r.requestedAt)} · ${fmtDate(r.requestedAt)}</div></div>
          <div style="display:flex;gap:6px">${phone ? `<a class="btn btn-sm" style="background:#25D366;color:#fff;border-color:#25D366" target="_blank" rel="noopener" href="https://wa.me/${phone}?text=${msg}">واتساب</a>` : ''}
            ${done ? '' : `<button class="btn btn-sm btn-teal" data-ok="${esc(r.id)}">✓ تمّ</button>`}<button class="btn btn-sm btn-ghost" data-rm="${esc(r.id)}" title="حذف">🗑️</button></div></div>`;
      }).join('') : '<div class="empty"><div class="em">🔑</div>لا توجد طلبات</div>';
      box.querySelectorAll('[data-ok]').forEach((b) => b.onclick = async () => { try { await db.collection('password_reset_requests').doc(b.dataset.ok).update({ status: 'resolved', resolvedAt: FV().serverTimestamp() }); log('support.resolve', b.dataset.ok); } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); } });
      box.querySelectorAll('[data-rm]').forEach((b) => b.onclick = async () => { if (!(await confirmBox('حذف هذا الطلب؟', { danger: true, ok: 'حذف' }))) return; try { await db.collection('password_reset_requests').doc(b.dataset.rm).delete(); log('support.delete', b.dataset.rm); } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); } });
    };
    el.querySelectorAll('#sp-f .chip').forEach((c) => c.onclick = () => { filter = c.dataset.f; el.querySelectorAll('#sp-f .chip').forEach((x) => x.classList.toggle('active', x === c)); draw(); });
    unsub = db.collection('password_reset_requests').orderBy('requestedAt', 'desc').limit(150).onSnapshot((s) => { rows = s.docs.map((d) => ({ id: d.id, ...d.data() })); draw(); },
      (e) => { document.getElementById('sp-list').innerHTML = `<div class="alert red">تعذّر (مالك/مشرفة): ${esc(e.code || e.message)}</div>`; });
    return () => unsub && unsub();
  },
};
