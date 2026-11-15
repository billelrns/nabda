// ═══════════════════════════════════════════════════════════════════
//  مساحات الإعلانات — Google AdSense
//  الاستعمال: ضعي adSlot('articleMid') في HTML ثم استدعي mountAds() بعد الإدراج.
//  عند التفعيل أضيفي إلى CSP في firebase.json:
//    script-src: https://pagead2.googlesyndication.com https://*.googlesyndication.com https://*.google.com https://*.gstatic.com https://*.doubleclick.net https://*.adtrafficquality.google
//    frame-src:  https://*.googlesyndication.com https://*.doubleclick.net https://*.google.com
//    connect-src / img-src: نفس النطاقات (img-src يسمح بـ https: أصلاً)
// ═══════════════════════════════════════════════════════════════════
import { ADS } from './site-config.js';

const SIZES = {
  articleTop: { h: 120, label: 'إعلان' },
  articleMid: { h: 280, label: 'إعلان' },
  articleEnd: { h: 280, label: 'إعلان' },
  sidebar: { h: 250, label: 'إعلان' },
  sidebarSticky: { h: 600, label: 'إعلان' },
  listing: { h: 260, label: 'إعلان' },
};

/** HTML لمساحة إعلان (تبقى فارغة/مخفية إن كانت الإعلانات معطّلة بلا عناصر نائبة) */
export function adSlot(kind) {
  const sz = SIZES[kind] || { h: 250, label: 'إعلان' };
  if (!ADS.client && !ADS.showPlaceholders) return '';
  return `<aside class="nb-ad nb-ad-${kind}" data-ad="${kind}" style="min-height:${sz.h}px" aria-label="مساحة إعلانية"><span class="nb-ad-label">${sz.label}</span></aside>`;
}

let scriptLoaded = false;
/** تفعيل الوحدات الموجودة في الصفحة (لا يفعل شيئاً قبل ضبط ADS.client) */
export function mountAds(root = document) {
  if (!ADS.client) return;
  if (!scriptLoaded) {
    scriptLoaded = true;
    const s = document.createElement('script');
    s.async = true; s.crossOrigin = 'anonymous';
    s.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${encodeURIComponent(ADS.client)}`;
    document.head.appendChild(s);
  }
  root.querySelectorAll('.nb-ad[data-ad]:not([data-filled])').forEach((el) => {
    const slot = ADS.slots[el.dataset.ad];
    el.dataset.filled = '1';
    if (!slot) return;
    el.classList.add('live');
    el.innerHTML = `<span class="nb-ad-label">إعلان</span><ins class="adsbygoogle" style="display:block" data-ad-client="${ADS.client}" data-ad-slot="${slot}" data-ad-format="auto" data-full-width-responsive="true"></ins>`;
    try { (window.adsbygoogle = window.adsbygoogle || []).push({}); } catch (_) {}
  });
}
