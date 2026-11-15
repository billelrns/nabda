// Stub لغير الويب — لا يفعل شيئًا.
void setWebPath(String path) {}
void resetWebPath() {}
String? getInitialPath() => null;

/// الانتقال إلى رابط آخر في الموقع (الويب فقط).
void webRedirect(String url) {}

/// قراءة/كتابة localStorage أو sessionStorage (الويب فقط).
String? webStorageGet(String key, {bool session = false}) => null;
void webStorageSet(String key, String? value, {bool session = false}) {}
