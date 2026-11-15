// ═══════════════════════════════════════════════════════════════════
//  تحويل فوري للمستخدمة المسجّلة إلى التطبيق (/app/) — يُحمَّل في <head>
//  قبل رسم الصفحة حتى لا تظهر واجهة الموقع لحظةً قبل التحويل.
//  • nb_auth (localStorage) يضبطه shell.js والتطبيق عند كل تغيّر في الدخول.
//  • ?site=1 → تصفّح الموقع خلال هذه الجلسة دون تحويل (من زر «تصفّح الموقع»).
//  • ?app=1  → إلغاء وضع الموقع.
//  الزائرات غير المسجّلات: لا شيء يتغيّر. الحاسوب: لا شيء يتغيّر (الهاتف فقط).
// ═══════════════════════════════════════════════════════════════════
(function () {
  try {
    var q = new URLSearchParams(location.search);
    if (q.get('site') === '1') sessionStorage.setItem('nb_site', '1');
    if (q.get('app') === '1') sessionStorage.removeItem('nb_site');
    if (sessionStorage.getItem('nb_site') === '1') return;
    var mobile = (window.matchMedia('(max-width: 820px)').matches || /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent));
    if (!mobile) return;
    var p = location.pathname.replace(/\/+$/, '') || '/';
    var appPaths = ['/', '/index.html', '/home.html', '/pregnancy', '/baby', '/cycle', '/fertility', '/community'];
    if (appPaths.indexOf(p) === -1) return;
    if (localStorage.getItem('nb_auth') === '1') {
      document.documentElement.style.visibility = 'hidden';
      location.replace('/app/');
    }
  } catch (e) { /* لا شيء — تبقى الصفحة كما هي */ }
})();
