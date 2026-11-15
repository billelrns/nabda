// إشراف المجتمع: البلاغات (reports) بنفس مخطّط لوحة التطبيق (_ReportsManagementScreen)
// targetType: community_post | comment | ai_response | direct_chat — status: pending | action_taken | dismissed
// (نقبل أيضاً القيم القديمة post / resolved)
import { db, esc, ago, fmtDate, toast, confirmBox, log, FV } from './core.js';

let unsub = null; let filter = 'pending'; let type = 'all';
const TYPES = { community_post: ['منشور مجتمع', 'teal'], post: ['منشور مجتمع', 'teal'], comment: ['تعليق', ''], ai_response: ['إجابة المساعد', 'pink'], direct_chat: ['محادثة خاصة', 'amber'] };
const REASONS = { spam: 'إزعاج/إعلان', harassment: 'تحرّش أو إساءة', inappropriate: 'محتوى غير لائق', misinformation: 'معلومات مضلّلة', medical: 'نصيحة طبية خطيرة', other: 'أخرى' };
const isPost = (r) => ['community_post', 'post'].includes(r.targetType || (r.postId ? 'post' : ''));
const isDone = (s) => ['action_taken', 'resolved', 'dismissed'].includes(s);
const stLabel = (s) => s === 'dismissed' ? ['تم التجاهل', 'cancelled'] : isDone(s) ? ['تم اتخاذ إجراء', 'delivered'] : ['قيد المراجعة', 'pending'];

export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>إشراف المجتمع والبلاغات</h1><p>بلاغات المنشورات والتعليقات وإجابات المساعد والمحادثات — نفس قائمة التطبيق</p></div></div>
      <div class="grid g-4" id="md-kpi" style="margin-bottom:14px"></div>
      <div class="toolbar"><div class="chips" id="md-chips">${[['pending', '⏳ قيد المراجعة'], ['done', '✅ تمّت المعالجة'], ['all', 'الكل']].map(([k, l]) => `<button class="chip ${filter === k ? 'active' : ''}" data-f="${k}">${l}</button>`).join('')}</div>
        <select class="input" id="md-type" style="max-width:200px"><option value="all">كل الأنواع</option>${Object.entries({ community_post: 'منشورات', comment: 'تعليقات', ai_response: 'إجابات المساعد', direct_chat: 'محادثات خاصة' }).map(([k, l]) => `<option value="${k}" ${type === k ? 'selected' : ''}>${l}</option>`).join('')}</select></div>
      <div id="md-list"><div class="skel" style="height:200px"></div></div>`;
    let rows = [];
    const draw = () => {
      const list = rows.filter((r) => {
        const s = r.status || 'pending';
        if (filter === 'pending' && isDone(s)) return false;
        if (filter === 'done' && !isDone(s)) return false;
        if (type !== 'all') { const t = r.targetType || (r.postId ? 'post' : ''); if (type === 'community_post' ? !isPost(r) : t !== type) return false; }
        return true;
      });
      const k = (ic, bg, l, v) => `<div class="card kpi"><div class="kpi-top"><span>${l}</span><span class="kpi-ic" style="background:${bg}">${ic}</span></div><div class="kpi-val num">${v}</div></div>`;
      const kp = document.getElementById('md-kpi'); if (kp) kp.innerHTML = k('⏳', 'var(--amber-soft)', 'قيد المراجعة', rows.filter((r) => !isDone(r.status || 'pending')).length)
        + k('📝', 'var(--teal-soft)', 'على المنشورات', rows.filter(isPost).length) + k('🤖', 'var(--pink-soft)', 'على المساعد', rows.filter((r) => r.targetType === 'ai_response').length) + k('✅', 'var(--green-soft)', 'تمّت معالجتها', rows.filter((r) => isDone(r.status)).length);
      const box = document.getElementById('md-list'); if (!box) return;
      box.innerHTML = list.length ? list.map((r) => {
        const [tl, tc] = TYPES[r.targetType || (r.postId ? 'post' : '')] || [r.targetType || 'بلاغ', ''];
        const [sl, sc] = stLabel(r.status || 'pending');
        const pending = !isDone(r.status || 'pending');
        return `<div class="card" style="margin-bottom:12px" data-r="${esc(r.id)}"><div class="card-h"><div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap"><span class="tag ${tc}">${esc(tl)}</span><b>${esc(REASONS[r.reason] || r.reason || 'غير محدد')}</b><span style="font-size:12px;color:var(--ink-3)">${ago(r.createdAt)} · ${fmtDate(r.createdAt)}</span></div>
          <span class="pill s-${sc}">${sl}</span></div>
          <div class="card-b">${r.note ? `<div style="margin-bottom:8px">📝 ملاحظة المبلِّغة: ${esc(r.note)}</div>` : ''}
            <div class="md-target" data-t="${esc(r.targetId || r.postId || '')}" data-post="${isPost(r) ? 1 : ''}" style="background:var(--surface-2);border-radius:12px;padding:12px;font-size:13.5px;color:var(--ink-2);white-space:pre-line">${r.content ? esc(String(r.content).slice(0, 800)) : (isPost(r) ? 'جاري تحميل المنشور…' : `المعرّف: ${esc(r.targetId || '—')}`)}</div>
            ${r.targetUserId ? `<div style="font-size:11px;color:var(--ink-3);margin-top:6px" dir="ltr">target user: ${esc(r.targetUserId)}</div>` : ''}
            ${r.action ? `<div style="font-size:12px;color:var(--ink-3);margin-top:6px">الإجراء: ${esc(r.action)}</div>` : ''}
            <div style="display:flex;gap:8px;margin-top:12px;flex-wrap:wrap">
              ${pending && isPost(r) ? '<button class="btn btn-sm btn-danger" data-act="delete">🗑️ حذف المنشور</button>' : ''}
              ${pending ? '<button class="btn btn-sm" data-act="ban">⛔ حظر صاحبة المحتوى</button><button class="btn btn-sm" data-act="dismiss">🚫 تجاهل</button>' : ''}
              <button class="btn btn-sm btn-ghost" data-act="remove" style="margin-right:auto">حذف السجل</button></div></div></div>`;
      }).join('') : '<div class="card"><div class="empty"><div class="em">🛡️</div>لا توجد بلاغات هنا</div></div>';
      box.querySelectorAll('.md-target[data-post="1"]').forEach(async (t) => {
        const r = rows.find((x) => x.id === t.closest('[data-r]').dataset.r);
        if (!t.dataset.t) return;
        try { const d = await db.collection('community_posts').doc(t.dataset.t).get();
          if (d.exists) { t.dataset.uid = d.data().userId || ''; if (!r?.content) t.innerHTML = `<b>${esc(d.data().author || '')}</b>${d.data().title ? ' — ' + esc(d.data().title) : ''}<div style="margin-top:6px">${esc(String(d.data().content || '').slice(0, 800))}</div>`; }
          else if (!r?.content) t.innerHTML = '<i>المنشور محذوف</i>';
        } catch (_) {}
      });
      box.querySelectorAll('[data-act]').forEach((b) => b.onclick = () => { const card = b.closest('[data-r]'); act(rows.find((x) => x.id === card.dataset.r), b.dataset.act, card.querySelector('.md-target').dataset.uid); });
    };
    el.querySelectorAll('#md-chips .chip').forEach((c) => c.onclick = () => { filter = c.dataset.f; el.querySelectorAll('#md-chips .chip').forEach((x) => x.classList.toggle('active', x === c)); draw(); });
    el.querySelector('#md-type').onchange = (e) => { type = e.target.value; draw(); };
    unsub = db.collection('reports').orderBy('createdAt', 'desc').limit(300).onSnapshot((s) => { rows = s.docs.map((d) => ({ id: d.id, ...d.data() })); draw(); },
      (e) => { document.getElementById('md-list').innerHTML = `<div class="alert red">تعذّر (صلاحية المالك/المشرفة): ${esc(e.code || e.message)}</div>`; });
    return () => unsub && unsub();
  },
};

async function act(r, kind, authorUid) {
  if (!r) return;
  const ref = db.collection('reports').doc(r.id);
  const target = r.targetId || r.postId;
  try {
    if (kind === 'dismiss') { await ref.update({ status: 'dismissed', resolvedAt: FV().serverTimestamp() }); toast('تم تجاهل البلاغ'); log('report.dismiss', r.id); return; }
    if (kind === 'remove') { if (!(await confirmBox('حذف سجل البلاغ؟', { danger: true, ok: 'حذف' }))) return; await ref.delete(); log('report.remove', r.id); return; }
    if (kind === 'delete') {
      if (!(await confirmBox('حذف المنشور المبلَّغ عنه نهائياً؟', { danger: true, ok: 'حذف' }))) return;
      if (target) await db.collection('community_posts').doc(target).delete();
      await ref.update({ status: 'action_taken', action: 'deleted_content', resolvedAt: FV().serverTimestamp() });
      toast('حُذف المنشور وأُغلق البلاغ', 'success'); log('report.delete', target); return;
    }
    if (kind === 'ban') {
      const uid = r.targetUserId || authorUid;
      if (!uid) return toast('تعذّر تحديد صاحبة المحتوى', 'error');
      if (!(await confirmBox('حظر صاحبة هذا المحتوى من المجتمع؟', { danger: true, ok: 'حظر' }))) return;
      const ts = FV().serverTimestamp();
      const data = { isBanned: true, bannedAt: ts, bannedReason: REASONS[r.reason] || r.reason || 'بلاغ', updatedAt: ts };
      await db.collection('users').doc(uid).update(data);
      await db.collection('users_directory').doc(uid).set(data, { merge: true }).catch(() => {});
      await ref.update({ status: 'action_taken', action: 'banned_user', resolvedAt: FV().serverTimestamp() });
      toast('حُظرت المستخدمة', 'success'); log('user.ban', uid);
    }
  } catch (e) { toast('تعذّر: ' + (e.code || e.message), 'error'); }
}
