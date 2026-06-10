import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشات التعريف الترحيبية (أول تشغيل) — 3 شرائح بطابع فاخر.
/// تنتهي بـ «ابدئي رحلتك» ثم تستدعي onDone للانتقال للخطوة التالية.
class IntroScreen extends StatefulWidget {
  /// يُستدعى بعد إنهاء شرائح التعريف (RootGate يقرّر الوجهة).
  final VoidCallback? onDone;
  const IntroScreen({Key? key, this.onDone}) : super(key: key);
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

const _bg = Color(0xFFFCF7F7);
const _rose = Color(0xFFF64D8A);
const _blush = Color(0xFFFAD7E5);
const _peach = Color(0xFFF8B8A5);
const _lav = Color(0xFFCBB8FF);
const _green = Color(0xFF8BCF7B);
const _ink = Color(0xFF3A2A2A);
const _muted = Color(0xFF9A8A8A);

class _IntroScreenState extends State<IntroScreen> {
  final _pc = PageController();
  int _i = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
    if (!mounted) return;
    widget.onDone?.call();
  }

  void _next() {
    if (_i < 2) {
      _pc.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  @override
  void dispose() { _pc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(children: [
            // تخطّي
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: _i < 2 ? TextButton(onPressed: _finish, child: const Text('تخطّي', style: TextStyle(color: _muted, fontWeight: FontWeight.w700))) : const SizedBox(height: 36),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (v) => setState(() => _i = v),
                children: [_slideWelcome(), _slideFeatures(), _slidePrivacy()],
              ),
            ),
            // النقاط
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (k) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: k == _i ? 22 : 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: k == _i ? _rose : _blush, borderRadius: BorderRadius.circular(4)),
            ))),
            const SizedBox(height: 18),
            // الزر
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: GestureDetector(
                onTap: _next,
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_rose, _peach]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _rose.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Center(child: Text(_i < 2 ? 'التالي' : '✨  ابدئي رحلتك',
                    style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── الشعار (يستخدم الصورة إن وُجدت، وإلا رسم احتياطي) ──
  Widget _logo(double size) => Image.asset(
    'assets/images/logo_nabda.png', width: size, height: size, fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [_blush, _peach])),
      child: const Center(child: Icon(Icons.favorite, color: _rose, size: 64)),
    ),
  );

  Widget _slideWelcome() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _logo(160),
      const SizedBox(height: 8),
      const Text('نبضة', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: _rose)),
      const SizedBox(height: 6),
      const Text('كل نبضة حبٍّ، تهمّنا', style: TextStyle(fontSize: 15, color: _muted)),
      const SizedBox(height: 26),
      const Text('مرحباً بكِ في عالم نبضة 🌸', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _ink), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      const Text('دليلكِ الشخصي لصحة المرأة والأمومة — من الدورة والخصوبة إلى الحمل ورعاية طفلكِ، في مكان واحد أنيق وآمن.',
        style: TextStyle(fontSize: 14.5, color: _muted, height: 1.8), textAlign: TextAlign.center),
    ]),
  );

  Widget _slideFeatures() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('دليلكِ في كل مرحلة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
      const SizedBox(height: 8),
      const Text('مهما كانت رحلتكِ، نبضة معكِ خطوة بخطوة', style: TextStyle(fontSize: 14, color: _muted), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: _feat('🌙', 'تتبّع الدورة', 'فهم جسمكِ يوماً بيوم', _lav)),
        const SizedBox(width: 12),
        Expanded(child: _feat('🌱', 'الخصوبة', 'نصائح لزيادة فرص الحمل', _green)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _feat('🤰', 'متابعة الحمل', 'دعم مخصّص لكل أسبوع', _rose)),
        const SizedBox(width: 12),
        Expanded(child: _feat('👶', 'رعاية المولود', 'نمو، رضاعة، تطعيمات', _peach)),
      ]),
    ]),
  );

  Widget _feat(String emoji, String t, String s, Color c) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 5))],
    ),
    child: Column(children: [
      Container(width: 54, height: 54, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.18)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26)))),
      const SizedBox(height: 10),
      Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
      const SizedBox(height: 4),
      Text(s, style: const TextStyle(fontSize: 11.5, color: _muted, height: 1.5), textAlign: TextAlign.center),
    ]),
  );

  Widget _slidePrivacy() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 120, height: 120,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [_blush, _peach.withOpacity(0.5)])),
        child: const Center(child: Icon(Icons.lock_rounded, size: 58, color: _rose))),
      const SizedBox(height: 24),
      const Text('خصوصيتكِ محمية وآمنة 🔒', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _ink), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      const Text('أمانكِ أساس خدمتنا — بياناتكِ محفوظة بأمان وتحت تحكّمكِ الكامل.',
        style: TextStyle(fontSize: 14.5, color: _muted, height: 1.8), textAlign: TextAlign.center),
      const SizedBox(height: 22),
      _privacyRow(Icons.verified_user_rounded, 'تحكّم كامل ببياناتكِ'),
      _privacyRow(Icons.visibility_off_rounded, 'لا مشاركة مع أطراف ثالثة'),
      _privacyRow(Icons.lock_outline_rounded, 'حماية وتشفير للبيانات'),
    ]),
  );

  Widget _privacyRow(IconData ic, String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: _rose.withOpacity(0.12)),
        child: Icon(ic, color: _rose, size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Text(t, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink))),
      const Icon(Icons.check_circle, color: _green, size: 20),
    ]),
  );
}
