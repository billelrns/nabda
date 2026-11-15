// الأسواق والدول: تفعيل السعودية، إعداداتها (واتساب، لافتة، سياسات بلهجتها)، شحن المناطق، تغطية التسعير
// site_config/markets = { SA: { enabled, whatsapp, shopBanner, shippingPolicy, returnPolicy, comingSoonText } }
// site_config/shipping_SA = { _default: { home }, "<المنطقة>": { home, enabled } }
import { S, db, esc, num, toast, log, FV, loadProducts, pAvail, marketOf, MK } from './core.js';

const SA_REGIONS = ['الرياض', 'مكة المكرمة', 'المدينة المنورة', 'القصيم', 'الشرقية', 'عسير', 'تبوك', 'حائل', 'الحدود الشمالية', 'جازان', 'نجران', 'الباحة', 'الجوف'];

export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>الأسواق والدول</h1><p>كل دولة سوق مستقل بعملته ومنتجاته وشحنه ولهجته — لا تُخلط الأسعار أبداً</p></div>
      <div class="ad-actions"><a class="btn" href="/sa/shop" target="_blank" rel="noopener">🇸🇦 معاينة متجر السعودية ↗</a><button class="btn btn-primary" id="mk-save">💾 حفظ</button></div></div>
      <div class="grid g-4" id="mk-kpi" style="margin-bottom:14px"><div class="skel" style="height:110px;grid-column:1/-1"></div></div>
      <div class="grid g-2">
        <div class="card"><div class="card-h"><h3>🇸🇦 السعودية</h3><label class="check" style="font-weight:900"><span class="switch"><input type="checkbox" id="mk-sa-on"><span></span></span> المتجر مفتوح للسعودية</label></div>
          <div class="card-b form">
            <div class="alert amber" id="mk-sa-state"></div>
            <div class="field"><label>سعر الصرف المرجعي (دج لكل ريال)</label><input class="input num" type="number" min="1" id="mk-sa-rate" placeholder="40"><span class="hint">يُستعمل فقط لاقتراح أسعار عند «نسخ / تحويل» المنتجات — لا يُحوَّل أي سعر تلقائياً للزبونات.</span></div>
            <div class="field"><label>رقم واتساب لطلبات السعودية</label><input class="input" id="mk-sa-wa" dir="ltr" placeholder="9665XXXXXXXX"><span class="hint">بالصيغة الدولية بلا +. فارغ = أزرار واتساب مخفية في متجر السعودية.</span></div>
            <div class="field"><label>لافتة أعلى المتجر (بلهجة خليجية)</label><input class="input" id="mk-sa-banner" placeholder="🚚 توصيل مجاني فوق 300 ريال"></div>
            <div class="field"><label>سياسة التوصيل</label><textarea class="textarea" id="mk-sa-ship" rows="3" placeholder="نوصّل لكل مناطق المملكة خلال 3–7 أيام عمل…"></textarea></div>
            <div class="field"><label>سياسة الإرجاع</label><textarea class="textarea" id="mk-sa-ret" rows="3"></textarea></div>
            <div class="field"><label>نص «قريباً» (يظهر ما دام المتجر مغلقاً للسعودية)</label><textarea class="textarea" id="mk-sa-soon" rows="2"></textarea></div>
          </div></div>
        <div class="card"><div class="card-h"><h3>🚚 شحن السعودية (ر.س)</h3></div><div class="card-b form">
          <div class="field"><label>السعر الافتراضي لكل المناطق</label><input class="input num" type="number" min="0" step="0.5" id="mk-sa-def" placeholder="30"></div>
          <div style="font-size:12.5px;color:var(--ink-3);margin-bottom:6px">سعر خاص لمنطقة (فارغ = الافتراضي)، أو أوقفي التوصيل إليها:</div>
          <div id="mk-sa-regions"></div>
        </div></div>
      </div>`;
    const $ = (i) => document.getElementById(i);
    Promise.all([db.collection('site_config').doc('markets').get(), db.collection('site_config').doc('shipping_SA').get(), loadProducts()]).then(([m, sh, prods]) => {
      const sa = (m.exists && m.data().SA) || {};
      const rates = sh.exists ? sh.data() : {};
      $('mk-sa-on').checked = sa.enabled === true;
      $('mk-sa-rate').value = sa.rateDZD || '';
      $('mk-sa-wa').value = sa.whatsapp || ''; $('mk-sa-banner').value = sa.shopBanner || '';
      $('mk-sa-ship').value = sa.shippingPolicy || ''; $('mk-sa-ret').value = sa.returnPolicy || ''; $('mk-sa-soon').value = sa.comingSoonText || '';
      $('mk-sa-def').value = rates._default?.home ?? '';
      $('mk-sa-regions').innerHTML = SA_REGIONS.map((r) => `<div class="list-row"><span style="flex:1;font-weight:800">${esc(r)}</span><input class="input num" type="number" min="0" step="0.5" data-r="${esc(r)}" value="${rates[r]?.home ?? ''}" placeholder="افتراضي" style="width:110px"><label class="switch" title="التوصيل متاح"><input type="checkbox" data-re="${esc(r)}" ${rates[r]?.enabled === false ? '' : 'checked'}><span></span></label></div>`).join('');
      const priced = prods.filter((p) => pAvail(p, 'SA')).length;
      const dz = prods.filter((p) => pAvail(p, 'DZ')).length;
      const saOrders = (S.allOrders || []).filter((o) => marketOf(o) === 'SA');
      const k = (ic, bg, l, v, s = '') => `<div class="card kpi"><div class="kpi-top"><span>${l}</span><span class="kpi-ic" style="background:${bg}">${ic}</span></div><div class="kpi-val num">${v}</div><div class="kpi-sub"><span>${s}</span></div></div>`;
      $('mk-kpi').innerHTML = k('🇩🇿', 'var(--teal-soft)', 'منتجات الجزائر', num(dz)) + k('🇸🇦', 'var(--pink-soft)', 'منتجات مسعّرة للسعودية', num(priced), `من ${num(prods.length)} — <a href="#products">سعّري من عمود 🇸🇦</a>`)
        + k('📦', 'var(--amber-soft)', 'طلبات السعودية', num(saOrders.length), saOrders.length ? `${num(saOrders.filter((o) => !o.status || o.status === 'pending').length)} جديدة` : '') + k(sa.enabled ? '🟢' : '⚪', sa.enabled ? 'var(--green-soft)' : 'var(--gray-soft)', 'حالة متجر السعودية', sa.enabled ? 'مفتوح' : 'مغلق', sa.enabled ? 'يرى الزوّار المنتجات بالريال' : 'يرى الزوّار صفحة «قريباً»');
      const state = () => { $('mk-sa-state').innerHTML = $('mk-sa-on').checked ? (priced ? `✅ عند الحفظ يفتح المتجر للسعودية بـ ${num(priced)} منتج مسعّر بالريال.` : '⚠️ لا يوجد أي منتج مسعّر بالريال بعد — سيظهر المتجر فارغاً. سعّري المنتجات أولاً (المنتجات ← عمود 🇸🇦 أو «تسعير السعودية» الجماعي).') : '⏸ المتجر مغلق للسعودية: الزائرات من السعودية يرين صفحة «قريباً» مع الموسوعة والمجتمع، ولا تظهر لهنّ أسعار الدينار أبداً.'; };
      $('mk-sa-on').onchange = state; state();
    }).catch((e) => toast('تعذّر التحميل: ' + (e.code || e.message), 'error'));

    $('mk-save').onclick = async () => {
      const wa = $('mk-sa-wa').value.replace(/\D/g, '');
      if (wa && !/^9665\d{8}$/.test(wa)) return toast('رقم واتساب السعودية: 9665XXXXXXXX', 'error');
      const SA = { enabled: $('mk-sa-on').checked, whatsapp: wa, shopBanner: $('mk-sa-banner').value.trim(), shippingPolicy: $('mk-sa-ship').value.trim(), returnPolicy: $('mk-sa-ret').value.trim(), comingSoonText: $('mk-sa-soon').value.trim(), rateDZD: Number($('mk-sa-rate').value) || 40, updatedAt: FV().serverTimestamp() };
      const rates = { _default: { home: Number($('mk-sa-def').value) || 0 } };
      document.querySelectorAll('[data-r]').forEach((i) => { const r = i.dataset.r; const on = document.querySelector(`[data-re="${CSS.escape(r)}"]`).checked; const v = i.value.trim(); if (v !== '' || !on) rates[r] = { ...(v !== '' ? { home: Number(v) || 0 } : {}), enabled: on }; });
      if (!rates._default.home) delete rates._default;
      try {
        await Promise.all([db.collection('site_config').doc('markets').set({ SA }, { merge: true }), db.collection('site_config').doc('shipping_SA').set(rates)]);
        log('markets.update', 'SA', { enabled: SA.enabled }); toast(`حُفظ ✓ — متجر السعودية ${SA.enabled ? 'مفتوح' : 'مغلق'}`, 'success');
      } catch (e) { toast('تعذّر (مالك/مشرفة): ' + (e.code || ''), 'error'); }
    };
  },
};
