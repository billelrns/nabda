# توليد أيقونة التطبيق تلقائياً — flutter_launcher_icons

## الخطوات

### 1. أضيفي الحزمة إلى pubspec.yaml

في نهاية `pubspec.yaml` أضيفي:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/logo_nabda_square.png"
  min_sdk_android: 21
  adaptive_icon_background: "#E91E63"
  adaptive_icon_foreground: "assets/images/logo_nabda_foreground.png"
  web:
    generate: true
    image_path: "assets/images/logo_nabda_square.png"
    background_color: "#E91E63"
    theme_color: "#00897B"
  windows:
    generate: true
    image_path: "assets/images/logo_nabda_square.png"
    icon_size: 48
```

### 2. حضّري الصور

تحتاجين 2 صورة:

| الصورة | الوصف | المقاس |
|---|---|---|
| `logo_nabda_square.png` | الشعار كامل مع الخلفية | 1024×1024 |
| `logo_nabda_foreground.png` | الشعار فقط (للـ adaptive icon على Android 8+) | 1024×1024 مع padding 20% |

ضعيها في: `C:\nabda_app\assets\images\`

**نصيحة:** استعملي Canva أو Figma لتحضير النسختين. تأكّدي:
- خلفية شفافة على الـforeground
- الشعار في المنتصف بحجم 60% من الصورة (لا يقترب من الحواف)

### 3. شغّلي التوليد

```cmd
cd C:\nabda_app
flutter pub get
flutter pub run flutter_launcher_icons
```

سيتم توليد كل المقاسات تلقائياً:
- Android: `android/app/src/main/res/mipmap-*` (كل الكثافات)
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Web: `web/icons/`
- Windows: `windows/runner/resources/app_icon.ico`

### 4. اختبري

```cmd
flutter clean
flutter build apk --release
flutter install
```

افتحي التطبيق على الهاتف — الأيقونة الجديدة يجب أن تظهر في الشاشة الرئيسية.

### 5. أيقونة عالية الدقّة لـ Play Store

للرفع على Play Console، تحتاجين **512×512 PNG** منفصلة. استعملي `logo_nabda_square.png` مباشرة (بعد resize لـ 512×512).

**احفظيها كـ:** `store_assets/icon_512.png`

---

## بدائل إذا لم تنجح flutter_launcher_icons

### يدوياً عبر Android Studio

1. افتحي Android Studio → File → Open → `C:\nabda_app\android`
2. Right-click على `res` → New → Image Asset
3. Icon Type: **Launcher Icons (Adaptive and Legacy)**
4. Foreground: اختاري `logo_nabda_foreground.png`
5. Background Layer: اختاري لون `#E91E63` أو صورة
6. Next → Finish

هذا يُولّد كل المقاسات تلقائياً.

### يدوياً عبر موقع

استعملي: https://icon.kitchen — يُولّد كل ما تحتاجين مجاناً بسحب صورة واحدة.

---

## أخطاء شائعة

**Error: image_path not found** → تحقّقي من مسار الصورة في pubspec.yaml
**Error: PNG needs alpha channel** → صورك يجب أن تكون PNG بشفافية (لا JPG)
**Icon looks pixelated** → الصورة الأصلية أصغر من 1024×1024. استعملي حجماً أكبر.
**Adaptive icon يظهر مقصوصاً** → الشعار قريب جداً من الحواف. زيدي padding.
