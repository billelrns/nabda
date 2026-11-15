// الإعدادات: واتساب المتجر، اسم المتجر، سياسات التوصيل والإرجاع (تظهر في صفحة المنتج)، شريط إعلان
import { db, esc, toast, log, FV } from './core.js';

let cache = null;
export async function getStoreSettingsCached() {
  if (cache) return cache;
  try { const d = await db.collection('site_config').doc('settings').get(); cache = d.exists ? d.data() : {}; } catch (_) { cache = {}; }
  return cache;
}

export default {
  render(el) {
    el.innerHTML = `<div class="ad-page-head"><div><h1>الإعدادات</h1><p>إعدادات المتجر العامة (site_config/settings)</p></div><div class="ad-actions"><button class="btn btn-primary" id="se-save">💾 حفظ</button></div></div>
      <div class="grid g-2"><div class="card"><div class="card-h"><h3>🏪 المتجر</h3></div><div class="card-b form">
        <div class="field"><label>اسم المتجر (يظهر في الملصقات والفواتير)</label><input class="input" id="se-name"></div>
        <div class="field"><label>رقم واتساب المتجر</label><input class="input" id="se-wa" dir="ltr" placeholder="2135XXXXXXXX"><span class="hint">بالصيغة الدولية بلا + (مثال 213550123456). عند تركه فارغاً تختفي أزرار واتساب من الموقع.</span></div>
        <div class="field"><label>شريط إعلان أعلى المتجر (اختياري)</label><input class="input" id="se-banner" placeholder="🚚 توصيل مجاني فوق 8000 دج"></div>
      </div></div>
      <div class="card"><div class="card-h"><h3>📜 السياسات</h3></div><div class="card-b form">
        <div class="field"><label>سياسة التوصيل</label><textarea class="textarea" id="se-ship" rows="4"></textarea></div>
        <div class="field"><label>سياسة الإرجاع والاستبدال</label><textarea class="textarea" id="se-ret" rows="4"></textarea></div>
        <span class="hint">تظهر في تبويب «التوصيل والإرجاع» بكل صفحة منتج.</span>
      </div></div></div>`;
    const $ = (i) => document.getElementById(i);
    cache = null;
    getStoreSettingsCached().then((s) => { $('se-name').value = s.storeName || 'متجر نبضة'; $('se-wa').value = s.whatsapp || ''; $('se-banner').value = s.shopBanner || ''; $('se-ship').value = s.shippingPolicy || ''; $('se-ret').value = s.returnPolicy || ''; });
    $('se-save').onclick = async () => {
      const wa = $('se-wa').value.replace(/\D/g, '');
      if (wa && !/^213[567]\d{8}$/.test(wa)) return toast('رقم واتساب: 213 ثم 9 أرقام تبدأ بـ 5 أو 6 أو 7', 'error');
      const data = { storeName: $('se-name').value.trim(), whatsapp: wa, shopBanner: $('se-banner').value.trim(), shippingPolicy: $('se-ship').value.trim(), returnPolicy: $('se-ret').value.trim(), updatedAt: FV().serverTimestamp() };
      try { await db.collection('site_config').doc('settings').set(data, { merge: true }); cache = data; log('settings.update', ''); toast('حُفظت الإعدادات ✓', 'success'); }
      catch (e) { toast('تعذّر (صلاحية المشرفة): ' + (e.code || ''), 'error'); }
    };
  },
};
