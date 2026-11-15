// المستخدمات — نفس لوحة التطبيق (_UsersManagementScreen): users_directory فقط (لا بيانات صحية)
// بحث، تصفية بالدور/الحظر، ملف المستخدمة، آخر المنشورات، حظر/إلغاء حظر، تغيير الدور (المالك فقط)
import { S, db, esc, num, ago, fmtDate, toast, confirmBox, openDrawer, closeDrawer, mountTable, downloadCSV, log, FV, can } from './core.js';

const ROLE = { owner: ['أدمن', 'pink'], supervisor: ['مشرفة', 'teal'], employee: ['موظفة', 'amber'], agent: ['موظفة تأكيد', 'amber'] };
const STAGE = { pregnant: '🤰 حامل', baby: '👶 أم', planning: '🌱 تخطّط للحمل', cycle: '🌸 متابعة الدورة' };
let rows = []; let table = null; let unsub = null; let q = ''; let f = 'all';

const roleTag = (r) => ROLE[r] ? `<span class="tag ${ROLE[r][1]}">${ROLE[r][0]}</span>` : '';
const av = (u, s = 34) => u.photoUrl
  ? `<img src="${esc(u.photoUrl)}" alt="" style="width:${s}px;height:${s}px;border-radius:50%;object-fit:cover;flex:0 0 ${s}px">`
  : `<span class="ad-me-av" style="width:${s}px;height:${s}px;flex:0 0 ${s}px;font-size:${Math.round(s / 2.4)}px">${esc((u.name || u.email || '?').charAt(0).toUpperCase())}</span>`;

function filtered() {
  return rows.filter((u) => {
    if (q && !(`${u.name || ''} ${u.email || ''} ${u.username || ''}`.toLowerCase().includes(q))) return false;
    if (f === 'banned') return u.isBanned === true;
    if (f === 'staff') return ['owner', 'supervisor', 'employee', 'agent'].includes(u.role);
    if (f === 'new') return (Date.now() - (u.createdAt?.toDate?.()?.getTime() || 0)) < 7 * 86400000;
    if (f === 'active') return (u.postsCount || 0) > 0;
    return true;
  });
}

export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>المستخدمات</h1><p>حسابات التطبيق والموقع — من الدليل العام (users_directory) دون أي بيانات صحية</p></div>
      <div class="ad-actions"><button class="btn" id="us-csv">⬇️ تصدير CSV</button></div></div>
      <div class="grid g-4" id="us-kpi" style="margin-bottom:14px"></div>
      <div class="toolbar"><input class="input" id="us-q" placeholder="🔍 بحث بالاسم أو البريد…" style="max-width:320px">
        <div class="chips" id="us-f">${[['all', 'الكل'], ['new', '🆕 جديدات (7 أيام)'], ['active', '💬 ناشطات في المجتمع'], ['staff', '🧑‍💼 الطاقم'], ['banned', '⛔ محظورات']].map(([k, l]) => `<button class="chip ${f === k ? 'active' : ''}" data-f="${k}">${l}</button>`).join('')}</div></div>
      <div class="card" id="us-tbl"><div class="skel" style="height:260px"></div></div>`;
    const draw = () => {
      const list = filtered();
      if (!table) {
        table = mountTable(document.getElementById('us-tbl'), {
          rows: list, pageSize: 30, sortKey: 'createdAt', emptyIcon: '👥', empty: 'لا توجد مستخدمات',
          onRow: (u) => openUser(u.id),
          columns: [
            { key: 'name', label: 'المستخدمة', render: (u) => `<div style="display:flex;gap:10px;align-items:center">${av(u)}<div style="min-width:0"><b>${esc(u.name || 'بدون اسم')}</b> ${roleTag(u.role)} ${u.isBanned ? '<span class="tag red">محظورة</span>' : ''}<div style="font-size:11.5px;color:var(--ink-3)" dir="ltr">${esc(u.email || '')}</div></div></div>`, sort: (u) => (u.name || '').toLowerCase() },
            { key: 'lifeStage', label: 'المرحلة', render: (u) => esc(STAGE[u.lifeStage] || '—') },
            { key: 'postsCount', label: 'منشورات', render: (u) => num(u.postsCount || 0), sort: (u) => u.postsCount || 0 },
            { key: 'likesReceived', label: 'إعجابات', render: (u) => num(u.likesReceived || 0), sort: (u) => u.likesReceived || 0 },
            { key: 'createdAt', label: 'الانضمام', render: (u) => ago(u.createdAt), sort: (u) => u.createdAt?.toMillis?.() || 0 },
            { key: 'lastLoginAt', label: 'آخر دخول', render: (u) => ago(u.lastLoginAt || u.lastSeen), sort: (u) => (u.lastLoginAt || u.lastSeen)?.toMillis?.() || 0 },
          ],
        });
      } else table.setRows(list, true);
      const dayAgo = Date.now() - 7 * 86400000;
      const k = (ic, bg, l, v, s = '') => `<div class="card kpi"><div class="kpi-top"><span>${l}</span><span class="kpi-ic" style="background:${bg}">${ic}</span></div><div class="kpi-val num">${v}</div><div class="kpi-sub"><span>${s}</span></div></div>`;
      document.getElementById('us-kpi').innerHTML =
        k('👥', 'var(--pink-soft)', 'إجمالي المستخدمات', num(rows.length), rows.length >= 2000 ? 'آخر 2000 حساب' : '') +
        k('🆕', 'var(--teal-soft)', 'جديدات هذا الأسبوع', num(rows.filter((u) => (u.createdAt?.toMillis?.() || 0) > dayAgo).length)) +
        k('💬', 'var(--amber-soft)', 'ناشطات في المجتمع', num(rows.filter((u) => (u.postsCount || 0) > 0).length)) +
        k('⛔', 'var(--red-soft)', 'محظورات', num(rows.filter((u) => u.isBanned).length));
    };
    table = null;
    el.querySelector('#us-q').oninput = (e) => { q = e.target.value.trim().toLowerCase(); draw(); };
    el.querySelectorAll('#us-f .chip').forEach((c) => c.onclick = () => { f = c.dataset.f; el.querySelectorAll('#us-f .chip').forEach((x) => x.classList.toggle('active', x === c)); draw(); });
    el.querySelector('#us-csv').onclick = () => downloadCSV(`nabda-users-${Date.now()}.csv`, filtered().map((u) => ({ uid: u.id, name: u.name || '', email: u.email || '', role: u.role || 'user', banned: u.isBanned ? 'yes' : '', posts: u.postsCount || 0, joined: fmtDate(u.createdAt, false) })));
    unsub = db.collection('users_directory').orderBy('createdAt', 'desc').limit(2000).onSnapshot((s) => {
      rows = s.docs.map((d) => ({ id: d.id, ...d.data() }));
      draw();
    }, (e) => { document.getElementById('us-tbl').innerHTML = `<div class="alert red">تعذّر التحميل: ${esc(e.code || e.message)}</div>`; });
    return () => { unsub && unsub(); table = null; };
  },
};

async function openUser(uid) {
  const u = rows.find((x) => x.id === uid); if (!u) return;
  const canBan = can('users.ban'); const canRole = S.role === 'owner';
  openDrawer({ title: u.name || 'مستخدمة', body: `
    <div style="text-align:center;margin-bottom:16px"><div style="display:flex;justify-content:center">${av(u, 76)}</div>
      <h3 style="margin:10px 0 2px">${esc(u.name || 'بدون اسم')}</h3><div style="color:var(--ink-3);font-size:13px" dir="ltr">${esc(u.email || '')}</div>
      <div style="margin-top:8px;display:flex;gap:6px;justify-content:center;flex-wrap:wrap">${roleTag(u.role) || '<span class="tag">مستخدمة</span>'}${u.isBanned ? '<span class="tag red">⛔ محظورة</span>' : ''}${STAGE[u.lifeStage] ? `<span class="tag">${STAGE[u.lifeStage]}</span>` : ''}</div></div>
    <div class="card" style="margin-bottom:12px"><div class="card-b"><dl class="kv">
      <dt>المنشورات</dt><dd>${num(u.postsCount || 0)}</dd><dt>إعجابات مستلمة</dt><dd>${num(u.likesReceived || 0)}</dd><dt>التعليقات</dt><dd>${num(u.commentsCount || 0)}</dd>
      <dt>الانضمام</dt><dd>${fmtDate(u.createdAt)}</dd><dt>آخر دخول</dt><dd>${fmtDate(u.lastLoginAt || u.lastSeen)}</dd>
      ${u.cohortKey ? `<dt>نادي الولادة</dt><dd>${esc(u.cohortKey)}</dd>` : ''}${u.isBanned && u.bannedReason ? `<dt>سبب الحظر</dt><dd>${esc(u.bannedReason)}</dd>` : ''}
      <dt>UID</dt><dd dir="ltr" style="font-size:11.5px;font-weight:600">${esc(u.id)}</dd></dl></div></div>
    <div class="card"><div class="card-h"><h3>آخر المنشورات</h3></div><div class="card-b" id="us-posts"><div class="skel" style="height:80px"></div></div></div>
    <p style="font-size:11.5px;color:var(--ink-3);margin-top:10px">🔒 بيانات الدورة والحمل والطفل لا تظهر هنا (خصوصية صحية).</p>`,
  foot: `${canBan ? `<button class="btn ${u.isBanned ? 'btn-teal' : 'btn-danger'}" id="us-ban">${u.isBanned ? '🔓 إلغاء الحظر' : '⛔ حظر المستخدمة'}</button>` : ''}
    ${canRole && u.id !== S.user.uid ? '<button class="btn" id="us-role">🧑‍💼 تغيير الدور</button>' : ''}<button class="btn" data-close-drawer>إغلاق</button>` });
  db.collection('community_posts').where('userId', '==', uid).orderBy('createdAt', 'desc').limit(5).get().then((s) => {
    const box = document.getElementById('us-posts'); if (!box) return;
    box.innerHTML = s.empty ? '<div class="empty" style="padding:12px">لا توجد منشورات</div>' : s.docs.map((d) => { const p = d.data(); return `<div class="list-row" style="display:block"><div style="font-size:13.5px;line-height:1.7">${esc(String(p.title ? p.title + ' — ' : '') + String(p.content || '').slice(0, 180))}</div><div style="font-size:11.5px;color:var(--ink-3);margin-top:4px">❤️ ${num((p.likes || []).length || p.likesCount || 0)} · 💬 ${num((p.comments || []).length || 0)} · ${ago(p.createdAt)}${p.cohortKey ? ' · 🤱 نادي' : ''}</div></div>`; }).join('');
  }).catch(() => { const box = document.getElementById('us-posts'); if (box) box.innerHTML = '<div class="empty" style="padding:12px">تعذّر تحميل المنشورات</div>'; });

  document.getElementById('us-ban')?.addEventListener('click', async () => {
    const ban = !u.isBanned;
    if (!(await confirmBox(ban ? `حظر ${u.name || 'هذه المستخدمة'}؟ لن تستطيع النشر أو التعليق.` : 'إلغاء حظر هذه المستخدمة؟', { danger: ban, ok: ban ? 'حظر' : 'إلغاء الحظر' }))) return;
    const ts = FV().serverTimestamp();
    const data = ban ? { isBanned: true, bannedAt: ts, bannedReason: 'قرار الإدارة', updatedAt: ts } : { isBanned: false, updatedAt: ts };
    try {
      await Promise.all([db.collection('users').doc(uid).update(data), db.collection('users_directory').doc(uid).set(data, { merge: true })]);
      log(ban ? 'user.ban' : 'user.unban', uid); toast(ban ? 'حُظرت المستخدمة' : 'أُلغي الحظر', 'success'); closeDrawer();
    } catch (e) { toast('تعذّر (مالك/مشرفة فقط): ' + (e.code || ''), 'error'); }
  });
  document.getElementById('us-role')?.addEventListener('click', () => changeRole(u));
}

/** نفس منطق التطبيق: staff/ مصدر الحقيقة، ثم role في users + users_directory */
function changeRole(u) {
  const opts = [['user', 'مستخدمة عادية'], ['agent', 'موظفة تأكيد (الطلبات فقط)'], ['employee', 'موظفة'], ['supervisor', 'مشرفة'], ['owner', 'أدمن (مالك)']];
  const cur = u.role || 'user';
  openDrawer({ title: 'تغيير الدور — ' + (u.name || ''), body: `<div class="form"><p style="color:var(--ink-3);font-size:13px">الدور الحالي: <b>${esc((opts.find((o) => o[0] === cur) || [0, cur])[1])}</b></p>
    ${opts.map(([k, l]) => `<label class="check" style="display:flex;margin:6px 0"><input type="radio" name="us-r" value="${k}" ${cur === k ? 'checked' : ''}> ${l}</label>`).join('')}
    <div class="alert amber" style="margin-top:10px">أي دور غير «مستخدمة» يمنحها الدخول إلى لوحة التحكم في الموقع والتطبيق.</div></div>`,
  foot: '<button class="btn btn-primary" id="us-r-save">حفظ</button><button class="btn" data-close-drawer>إلغاء</button>' });
  document.getElementById('us-r-save').onclick = async () => {
    const role = document.querySelector('input[name="us-r"]:checked').value;
    if (role === cur) return closeDrawer();
    try {
      if (role !== 'user') await db.collection('staff').doc(u.id).set({ email: u.email || '', name: u.name || '', role, isActive: true, createdAt: FV().serverTimestamp(), createdBy: S.user.uid }, { merge: true });
      else await db.collection('staff').doc(u.id).delete();
      const ts = FV().serverTimestamp();
      await Promise.all([
        db.collection('users').doc(u.id).update({ role, updatedAt: ts }).catch(() => {}),
        db.collection('users_directory').doc(u.id).set({ role, updatedAt: ts }, { merge: true }),
      ]);
      log('user.role', u.id, { role }); toast('تم تغيير الدور ✓', 'success'); closeDrawer();
    } catch (e) { toast('تعذّر (المالك فقط): ' + (e.code || ''), 'error'); }
  };
}
