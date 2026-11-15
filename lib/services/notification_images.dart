import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// ═══════════════════════════════════════════════════════════════════
///  صور الإشعارات — تحويل صورة (رابط أو من أصول التطبيق) إلى صورة كبيرة
///  تظهر داخل الإشعار نفسه (BigPictureStyle على أندرويد).
///
///  لماذا ملف مُخزَّن لا بايتات مباشرة؟
///  الإشعارات المجدولة تُحفظ داخل SharedPreferences حتى موعدها؛ ولو
///  حملت الصورة بايتاتٍ لتضخّم ذلك الملف بميغابايتات يُحمَّل كاملاً عند كل
///  إقلاع. أمّا مسار الملف فبضعة أحرف فقط.
///
///  لماذا التصغير؟
///  أندرويد يفكّ الصورة كاملة في الذاكرة لعرضها. صورة منتج بدقّة 3000px
///  تستهلك عشرات الميغابايتات وقد يرفض النظام عرض الإشعار كلّه.
/// ═══════════════════════════════════════════════════════════════════
class NotificationImages {
  NotificationImages._();

  // بطاقة عريضة 2:1 بدقّة عالية — نفس نسبة الصورة الكبيرة في إشعارات أندرويد،
  // فلا يقصّ النظام أعلى المنتج وأسفله وتبقى الصورة واضحة.
  static const int _cardW = 1200;
  static const int _cardH = 600;
  static const int _maxDownloadBytes = 6 * 1024 * 1024;
  static const Duration _maxAge = Duration(days: 10);

  static Directory? _dir;

  static Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/notif_images');
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d;
    _cleanupOld(d); // بلا انتظار
    return d;
  }

  /// يحذف الصور الأقدم من 10 أيام حتى لا يكبر المجلد بلا حدّ
  static Future<void> _cleanupOld(Directory d) async {
    try {
      final now = DateTime.now();
      await for (final f in d.list()) {
        if (f is File && now.difference(await f.lastModified()) > _maxAge) {
          await f.delete();
        }
      }
    } catch (_) {/* أفضل-جهد */}
  }

  /// يُحضّر الصورة ويُعيد مسار الملف المصغّر، أو `null` عند أي فشل.
  /// [source] رابط https أو مسار أصل يبدأ بـ `assets/`.
  /// لا يرمي استثناءً أبداً — الإشعار يُعرض بلا صورة في أسوأ الأحوال.
  static Future<String?> prepare(String? source) async {
    if (source == null) return null;
    final src = source.trim();
    if (src.isEmpty) return null;
    final isAsset = src.startsWith('assets/');
    final isUrl = src.startsWith('https://') || src.startsWith('http://');
    if (!isAsset && !isUrl) return null;

    try {
      final dir = await _cacheDir();
      // اسم ثابت لكل مصدر → الصورة نفسها لا تُنزَّل مرّتين
      // n2_ : صيغة البطاقة الجديدة (لا نُعيد استعمال الصور القديمة المقصوصة)
      final file = File('${dir.path}/n2_${_stableHash(src)}.png');
      if (await file.exists() && await file.length() > 0) return file.path;

      final Uint8List raw;
      if (isAsset) {
        raw = (await rootBundle.load(src)).buffer.asUint8List();
      } else {
        final res = await http
            .get(Uri.parse(src))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
        if (res.bodyBytes.length > _maxDownloadBytes) return null;
        raw = res.bodyBytes;
      }

      final png = await _downscale(raw);
      if (png == null) return null;
      await file.writeAsBytes(png, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('NotificationImages.prepare failed for $src: $e');
      return null;
    }
  }

  /// يضع الصورة كاملةً داخل بطاقة 1200×600 بخلفية وردية فاتحة.
  /// • صورة عريضة أصلاً (≥ 1.8:1): تُصغَّر لتملأ البطاقة كما هي.
  /// • صورة مربّعة/طولية (صور المنتجات غالباً): تُعرض كاملة بارتفاع البطاقة
  ///   في الوسط، بدل أن يقصّ أندرويد نصفها فيظهر المنتج مبتوراً.
  static Future<Uint8List?> _downscale(Uint8List bytes) async {
    try {
      // قراءة الأبعاد الأصلية أولاً لاختيار حجم الفكّ المناسب
      final probe = await ui.instantiateImageCodec(bytes);
      final pf = await probe.getNextFrame();
      final ow = pf.image.width, oh = pf.image.height;
      pf.image.dispose();
      probe.dispose();
      if (ow <= 0 || oh <= 0) return null;
      final wide = ow / oh >= 1.8;

      // فكّ بالحجم النهائي تقريباً (أسرع وأقلّ ذاكرة، وبجودة عالية)
      final codec = wide
          ? await ui.instantiateImageCodec(bytes, targetWidth: ow > _cardW ? _cardW : null)
          : await ui.instantiateImageCodec(bytes, targetHeight: oh > _cardH ? _cardH : null);
      final frame = await codec.getNextFrame();
      final img = frame.image;

      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec);
      final full = ui.Rect.fromLTWH(0, 0, _cardW.toDouble(), _cardH.toDouble());
      // خلفية وردية فاتحة بتدرّج خفيف (ألوان نبضة)
      canvas.drawRect(
        full,
        ui.Paint()
          ..shader = ui.Gradient.linear(
            ui.Offset.zero,
            ui.Offset(_cardW.toDouble(), _cardH.toDouble()),
            const [ui.Color(0xFFFFF5F8), ui.Color(0xFFFCE4EC)],
          ),
      );
      // احتواء الصورة كاملةً داخل البطاقة (contain) في الوسط
      final scale = [_cardW / img.width, _cardH / img.height].reduce((a, b) => a < b ? a : b);
      final dw = img.width * scale, dh = img.height * scale;
      final dst = ui.Rect.fromLTWH((_cardW - dw) / 2, (_cardH - dh) / 2, dw, dh);
      canvas.drawImageRect(
        img,
        ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final card = await rec.endRecording().toImage(_cardW, _cardH);
      final data = await card.toByteData(format: ui.ImageByteFormat.png);
      card.dispose();
      img.dispose();
      codec.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// FNV-1a — ثابت بين الجلسات (عكس String.hashCode غير المضمون)
  static String _stableHash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16);
  }

  /// يبني نمط الصورة الكبيرة جاهزاً للإشعار، أو `null` إن تعذّرت الصورة.
  static Future<BigPictureStyleInformation?> bigPicture(
    String? source, {
    String? title,
    String? body,
  }) async {
    final path = await prepare(source);
    if (path == null) return null;
    final bmp = FilePathAndroidBitmap(path);
    return BigPictureStyleInformation(
      bmp,
      // الصورة المصغّرة الجانبية (والإشعار مطويّ) = الصورة الأصلية لا البطاقة،
      // حتى يظهر المنتج واضحاً بدل شريط وردي بنصفه
      largeIcon: await _thumbFor(source) ?? bmp,
      // عند التوسيع تظهر الصورة كبيرة فلا داعي لتكرارها صغيرةً
      hideExpandedLargeIcon: true,
      contentTitle: title,
      summaryText: body,
    );
  }

  /// صورة مربّعة 256px للأيقونة الجانبية (الإشعار مطويّ)
  static Future<AndroidBitmap<Object>?> _thumbFor(String? source) async {
    try {
      if (source == null) return null;
      final src = source.trim();
      final dir = await _cacheDir();
      final file = File('${dir.path}/t_${_stableHash(src)}.png');
      if (await file.exists() && await file.length() > 0) return FilePathAndroidBitmap(file.path);
      final Uint8List raw;
      if (src.startsWith('assets/')) {
        raw = (await rootBundle.load(src)).buffer.asUint8List();
      } else {
        final res = await http.get(Uri.parse(src)).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200 || res.bodyBytes.isEmpty || res.bodyBytes.length > _maxDownloadBytes) return null;
        raw = res.bodyBytes;
      }
      final codec = await ui.instantiateImageCodec(raw, targetWidth: 256);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (data == null) return null;
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return FilePathAndroidBitmap(file.path);
    } catch (_) {
      return null;
    }
  }

  /// صورة مصغّرة جانبية فقط (حين يكون الإشعار مطويّاً)
  static Future<AndroidBitmap<Object>?> thumbnail(String? source) async {
    final path = await prepare(source);
    return path == null ? null : FilePathAndroidBitmap(path);
  }

  /// أوّل صورة صالحة لمنتج من وثيقة Firestore — نفس ترتيب صفحة المنتج
  static String? productImage(Map<String, dynamic> p) {
    final cover = (p['coverImage'] ?? '').toString();
    if (cover.startsWith('http')) return cover;
    final urls = p['imageUrls'];
    if (urls is List) {
      for (final u in urls) {
        final s = u.toString();
        if (s.startsWith('http')) return s;
      }
    }
    final single = (p['imageUrl'] ?? '').toString();
    return single.startsWith('http') ? single : null;
  }
}
