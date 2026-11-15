// Web-only: تحديث URL بدون إعادة تحميل الصفحة (soft URL change).
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void setWebPath(String path) {
  try {
    html.window.history.pushState(null, '', path);
  } catch (_) {}
}

void resetWebPath() {
  try {
    html.window.history.pushState(null, '', '/');
  } catch (_) {}
}

/// يُرجع مسار URL الحالي (مثل "/shop" أو "/pregnancy") — لدعم deep linking.
String? getInitialPath() {
  try {
    return html.window.location.pathname;
  } catch (_) {
    return null;
  }
}

/// الانتقال إلى صفحة أخرى في الموقع (يستبدل الصفحة الحالية في السجلّ).
void webRedirect(String url) {
  try {
    html.window.location.replace(url);
  } catch (_) {}
}

/// قراءة قيمة من localStorage (أو sessionStorage إن session = true).
String? webStorageGet(String key, {bool session = false}) {
  try {
    return (session ? html.window.sessionStorage : html.window.localStorage)[key];
  } catch (_) {
    return null;
  }
}

/// كتابة قيمة (null = حذف) في localStorage أو sessionStorage.
void webStorageSet(String key, String? value, {bool session = false}) {
  try {
    final s = session ? html.window.sessionStorage : html.window.localStorage;
    if (value == null) {
      s.remove(key);
    } else {
      s[key] = value;
    }
  } catch (_) {}
}
