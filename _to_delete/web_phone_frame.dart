// ═══════════════════════════════════════════════════════════════════
//  إطار الهاتف على الحاسوب (Flutter Web تحت /app/)
//  • شاشة عريضة (≥ 600px): التطبيق يظهر داخل إطار هاتف في وسط الصفحة،
//    بنفس تصميم وتفاصيل تطبيق الموبايل تماماً (MediaQuery بعرض الهاتف،
//    فكل الشاشات تختار تخطيط الهاتف تلقائياً).
//  • شاشة هاتف (< 600px): التطبيق بملء الشاشة كما هو، بلا أي إطار.
// ═══════════════════════════════════════════════════════════════════
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'url_helper.dart';

class WebPhoneFrame extends StatelessWidget {
  final Widget child;
  const WebPhoneFrame({Key? key, required this.child}) : super(key: key);

  static const double _breakpoint = 600;
  static const double _phoneWidth = 420; // عرض الإطار الخارجي
  static const double _bezel = 10; // سُمك حافة الهاتف
  static const Color _pink = Color(0xFFE91E63);
  static const Color _deep = Color(0xFFC2185B);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    if (screen.width < _breakpoint) return child;

    // ارتفاع الهاتف: يملأ الشاشة مع هامش، بحدّ أقصى 920px
    final double frameH = screen.height < 640
        ? screen.height
        : math.min(screen.height - 40, 920.0);
    final double innerW = _phoneWidth - _bezel * 2;
    final double innerH = frameH - _bezel * 2;
    final bool showSide = screen.width >= 1000;

    final phone = Container(
      width: _phoneWidth,
      height: frameH,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1A1D),
        borderRadius: BorderRadius.circular(46),
        boxShadow: const [
          BoxShadow(color: Color(0x40C2185B), blurRadius: 48, offset: Offset(0, 20)),
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(_bezel),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: MediaQuery(
          // كل الشاشات داخل الإطار ترى «هاتفاً» بعرض innerW
          data: mq.copyWith(
            size: Size(innerW, innerH),
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
          ),
          child: SizedBox(width: innerW, height: innerH, child: child),
        ),
      ),
    );

    return Material(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFFFF5F8), Color(0xFFFCE4EC), Color(0xFFFFF8FB)],
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSide) const _SidePanel(),
              if (showSide) const SizedBox(width: 72),
              phone,
            ],
          ),
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const pink = WebPhoneFrame._pink;
    const deep = WebPhoneFrame._deep;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.favorite_rounded, color: pink, size: 38),
              SizedBox(width: 10),
              Text('نبضة',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: deep)),
            ]),
            const SizedBox(height: 14),
            const Text('رفيقتكِ في كل مرحلة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF3D2A33))),
            const SizedBox(height: 10),
            const Text(
              'تستعملين الآن تطبيق نبضة من المتصفّح. حسابكِ وبياناتكِ هي نفسها على الهاتف والموقع.',
              style: TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF6B5560)),
            ),
            const SizedBox(height: 22),
            Wrap(spacing: 10, runSpacing: 10, children: [
              OutlinedButton.icon(
                onPressed: () => webRedirect('/?site=1'),
                icon: const Icon(Icons.public, size: 18),
                label: const Text('تصفّح الموقع'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: deep,
                  side: const BorderSide(color: pink),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => webRedirect('/articles?site=1'),
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text('المقالات'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: deep,
                  side: const BorderSide(color: pink),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ]),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF8BBD0)),
              ),
              child: const Text(
                '📲 على هاتفكِ: افتحي nabda.online وسجّلي الدخول، ثم «إضافة إلى الشاشة الرئيسية» ليعمل كتطبيق.',
                style: TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFF6B5560)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
