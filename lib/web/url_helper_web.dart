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
