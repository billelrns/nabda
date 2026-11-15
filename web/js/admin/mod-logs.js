// سجلّ النشاط (المالك): من فعل ماذا ومتى
import { db, esc, fmtDate, mountTable, downloadCSV } from './core.js';

const LABELS = {
  'order.status': 'تغيير حالة طلب', 'order.edit': 'تعديل طلب', 'phone.block': 'حظر رقم', 'phone.unblock': 'رفع حظر رقم',
  'product.create': 'إضافة منتج', 'product.update': 'تعديل منتج', 'product.delete': 'حذف منتج', 'product.price': 'تعديل سعر', 'product.stock': 'تعديل مخزون',
  'product.active': 'إظهار/إخفاء منتج', 'product.duplicate': 'نسخ منتج', 'product.import': 'استيراد منتجات', 'shipping.update': 'تحديث أسعار الشحن', 'site.slides': 'تحديث شرائح الرئيسية',
  'settings.update': 'تحديث الإعدادات', 'staff.add': 'إضافة عضو', 'staff.update': 'تعديل عضو', 'staff.remove': 'إزالة عضو', 'staff.toggle': 'تفعيل/تعطيل عضو',
  'report.delete': 'حذف محتوى مبلَّغ', 'report.dismiss': 'تجاهل بلاغ', 'user.ban': 'حظر مستخدمة', 'content.create': 'إضافة مقال', 'content.update': 'تعديل مقال', 'content.delete': 'حذف مقال', 'waitlist.notified': 'إعلام قائمة انتظار',
};
const label = (a) => LABELS[a] || (a.startsWith('product.bulk') ? 'تعديل جماعي للمنتجات' : a);

export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>سجلّ النشاط</h1><p>آخر 500 عملية في لوحة التحكم (لا يمكن تعديله أو حذفه)</p></div><div class="ad-actions"><button class="btn" id="lg-csv">⬇️ تصدير</button></div></div>
      <div class="toolbar"><input class="input" id="lg-q" placeholder="🔍 عضو، عملية، هدف…" style="flex:1"></div><div class="card" id="lg-tbl"><div class="card-b"><div class="skel" style="height:200px"></div></div></div>`;
    let rows = []; let table = null;
    db.collection('admin_logs').orderBy('at', 'desc').limit(500).get().then((s) => {
      rows = s.docs.map((d) => ({ id: d.id, ...d.data() }));
      table = mountTable(document.getElementById('lg-tbl'), { rows, pageSize: 40, sortKey: 'at', empty: 'لا نشاط بعد', emptyIcon: '📜', columns: [
        { key: 'at', label: 'الوقت', sort: (r) => r.at?.seconds || 0, render: (r) => `<span class="muted">${fmtDate(r.at)}</span>` },
        { key: 'name', label: 'العضو', render: (r) => `<b>${esc(r.name || r.uid)}</b> <span class="tag">${esc(r.role || '')}</span>` },
        { key: 'action', label: 'العملية', render: (r) => esc(label(r.action)) },
        { key: 'target', label: 'الهدف', render: (r) => `<span class="muted" style="word-break:break-all">${esc(String(r.target || '').slice(0, 80))}</span>` },
      ] });
    }).catch((e) => { document.getElementById('lg-tbl').innerHTML = `<div class="alert red">تعذّر (المالك فقط): ${esc(e.code || e.message)}</div>`; });
    el.querySelector('#lg-q').oninput = (e) => { const q = e.target.value.trim().toLowerCase(); table?.setRows(rows.filter((r) => `${r.name} ${label(r.action)} ${r.target}`.toLowerCase().includes(q))); };
    el.querySelector('#lg-csv').onclick = () => downloadCSV('nabda-admin-logs.csv', rows.map((r) => ({ الوقت: fmtDate(r.at), العضو: r.name, الدور: r.role, العملية: label(r.action), الهدف: r.target, التفاصيل: r.details || '' })));
  },
};
