// الطاقم والصلاحيات (المالك فقط): إضافة بالـ UID، تغيير الدور، تفعيل/تعطيل، إزالة
import { S, db, esc, ago, toast, confirmBox, openModal, closeModal, log, FV, ROLE_LABEL } from './core.js';

const ROLES = [['owner', 'المالك — كل الصلاحيات'], ['supervisor', 'مشرفة — المتجر والمحتوى والإشراف'], ['employee', 'موظفة — الطلبات والمنتجات والمحتوى'], ['agent', 'موظفة تأكيد — الطلبات فقط']];
let unsub = null;
export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>الطاقم والصلاحيات</h1><p>الوصول إلى اللوحة محصور بحسابات staff النشطة</p></div><div class="ad-actions"><button class="btn btn-primary" id="sf-add">+ إضافة عضو</button></div></div>
      <div class="alert teal" style="margin-bottom:14px">💡 لإضافة عضو: تسجّل الدخول مرّة في الموقع أو التطبيق، ثم تفتح <b>/admin</b> فتظهر لها رسالة فيها الـ UID — انسخيه هنا.</div>
      <div class="grid g-3" id="sf-list"><div class="skel" style="height:140px"></div></div>`;
    el.querySelector('#sf-add').onclick = () => edit(null);
    unsub = db.collection('staff').onSnapshot((s) => {
      const rows = s.docs.map((d) => ({ id: d.id, ...d.data() }));
      document.getElementById('sf-list').innerHTML = rows.map((m) => `
        <div class="card"><div class="card-b" style="display:grid;gap:10px">
          <div style="display:flex;gap:12px;align-items:center"><div class="ad-me-av" style="width:44px;height:44px;font-size:18px;${m.isActive ? '' : 'filter:grayscale(1)'}">${esc((m.name || m.email || '?').charAt(0))}</div>
            <div style="flex:1;min-width:0"><b>${esc(m.name || '—')}</b> ${m.id === S.user.uid ? '<span class="tag pink">أنتِ</span>' : ''}<div style="font-size:12px;color:var(--ink-3);overflow:hidden;text-overflow:ellipsis" dir="ltr">${esc(m.email || m.id)}</div></div></div>
          <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap"><span class="tag ${m.role === 'owner' ? 'pink' : 'teal'}">${esc(ROLE_LABEL[m.role] || m.role)}</span>${m.isActive ? '<span class="tag teal">نشط</span>' : '<span class="tag red">معطّل</span>'}<span style="font-size:11.5px;color:var(--ink-3);margin-right:auto">${m.createdAt ? 'أُضيف ' + ago(m.createdAt) : ''}</span></div>
          ${m.id !== S.user.uid ? `<div style="display:flex;gap:6px"><button class="btn btn-sm" data-ed="${esc(m.id)}">✏️ تعديل</button><button class="btn btn-sm" data-tg="${esc(m.id)}">${m.isActive ? '⏸ تعطيل' : '▶ تفعيل'}</button><button class="btn btn-sm btn-danger" data-rm="${esc(m.id)}">إزالة</button></div>` : ''}
        </div></div>`).join('');
      const box = document.getElementById('sf-list');
      box.querySelectorAll('[data-ed]').forEach((b) => b.onclick = () => edit(rows.find((r) => r.id === b.dataset.ed)));
      box.querySelectorAll('[data-tg]').forEach((b) => b.onclick = async () => { const m = rows.find((r) => r.id === b.dataset.tg); try { await db.collection('staff').doc(m.id).update({ isActive: !m.isActive }); log('staff.toggle', m.id, { active: !m.isActive }); } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); } });
      box.querySelectorAll('[data-rm]').forEach((b) => b.onclick = async () => { const m = rows.find((r) => r.id === b.dataset.rm); if (!(await confirmBox(`إزالة ${m.name || m.email} من الطاقم نهائياً؟`, { danger: true, ok: 'إزالة' }))) return; try { await db.collection('staff').doc(m.id).delete(); log('staff.remove', m.id); toast('أُزيلت', 'success'); } catch (e) { toast('تعذّر: ' + (e.code || ''), 'error'); } });
    }, (e) => { document.getElementById('sf-list').innerHTML = `<div class="alert red">${esc(e.code || e.message)}</div>`; });
    return () => unsub && unsub();
  },
};

function edit(m) {
  openModal({ title: m ? 'تعديل عضو' : 'إضافة عضو للطاقم', body: `<div class="form">
    <div class="field"><label>UID (من Firebase Auth) *</label><input class="input" id="sf-uid" dir="ltr" value="${esc(m?.id || '')}" ${m ? 'disabled' : ''}></div>
    <div class="f-row"><div class="field"><label>الاسم</label><input class="input" id="sf-name" value="${esc(m?.name || '')}"></div><div class="field"><label>البريد</label><input class="input" id="sf-email" dir="ltr" value="${esc(m?.email || '')}"></div></div>
    <div class="field"><label>الدور</label>${ROLES.map(([k, l]) => `<label class="check" style="display:flex;margin:4px 0"><input type="radio" name="sf-role" value="${k}" ${(m?.role || 'employee') === k ? 'checked' : ''}> ${l}</label>`).join('')}</div></div>`,
    foot: '<button class="btn btn-primary" id="sf-save">حفظ</button><button class="btn" data-close-modal>إلغاء</button>' });
  document.getElementById('sf-save').onclick = async () => {
    const uid = document.getElementById('sf-uid').value.trim();
    if (!/^[A-Za-z0-9]{20,40}$/.test(uid)) return toast('UID غير صالح', 'error');
    const role = document.querySelector('input[name="sf-role"]:checked').value;
    const data = { name: document.getElementById('sf-name').value.trim(), email: document.getElementById('sf-email').value.trim(), role, isActive: m ? m.isActive : true };
    if (!m) { data.createdAt = FV().serverTimestamp(); data.createdBy = S.user.uid; }
    try { await db.collection('staff').doc(uid).set(data, { merge: true }); log(m ? 'staff.update' : 'staff.add', uid, { role }); toast('حُفظ', 'success'); closeModal(); }
    catch (e) { toast('تعذّر (المالك فقط): ' + (e.code || ''), 'error'); }
  };
}
