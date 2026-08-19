import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../services/pregnancy_dates_service.dart';
import '../../utils/fetus_size.dart';
import '../../widgets/nabda_ui.dart' show WombFloatingFetus;
// Note: For actual sharing, add share_plus package. For now we show sharable cards.

const Color _bg = Color(0xFFFFF5F7);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);

DocumentReference get _userDoc {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

class ShareProgressScreen extends StatefulWidget {
  const ShareProgressScreen({Key? key}) : super(key: key);
  @override
  State<ShareProgressScreen> createState() => _ShareProgressScreenState();
}

class _ShareProgressScreenState extends State<ShareProgressScreen> {
  int _currentWeek = 0;
  int _daysRemaining = 0;
  int _trimester = 1;
  String _babySize = '';
  String _userName = '';
  bool _loaded = false;
  int _selectedTemplate = 0;

  final _templates = <_ShareTemplate>[
    _ShareTemplate('بطاقة الأسبوع', [Color(0xFFE91E63), Color(0xFFFF6090)], Icons.calendar_today),
    _ShareTemplate('بطاقة العد التنازلي', [Color(0xFF00897B), Color(0xFF4DB6AC)], Icons.timer),
    _ShareTemplate('بطاقة حجم الجنين', [Color(0xFF7B1FA2), Color(0xFFBA68C8)], Icons.child_friendly),
    _ShareTemplate('بطاقة الإنجاز', [Color(0xFFFF6F00), Color(0xFFFFB74D)], Icons.emoji_events),
    _ShareTemplate('بطاقة التقدم', [Color(0xFF1565C0), Color(0xFF42A5F5)], Icons.trending_up),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final doc = await _userDoc.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};

      // ── المصدر الموحّد لتواريخ الحمل (نفس الرئيسية وصفحة الحمل) ──
      final pd = PregnancyDates.fromUserData(data);
      final week = pd.week;
      final remaining = max(0, pd.daysLeft);

      setState(() {
        _currentWeek = week;
        _daysRemaining = remaining;
        _trimester = pd.trimester;
        _babySize = week > 0 ? FetusSize.labeled(week) : '';
        _userName = (data['name'] as String?)?.trim().isNotEmpty == true
            ? data['name'] as String
            : ((data['displayName'] as String?)?.trim().isNotEmpty == true
                ? data['displayName'] as String
                : 'أم نبضة');
        _loaded = true;
      });
    } catch (_) {
      setState(() => _loaded = true);
    }
  }

  /// مسار صورة الجنين للأسبوع الحالي
  String get _fetusAsset =>
      'assets/images/fetus_hd/week_${_currentWeek.clamp(4, 41)}.png';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('شاركي تقدمك', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: true,
        ),
        body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Template selector
                const Text('اختاري نوع البطاقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _templates.length,
                    itemBuilder: (ctx, i) {
                      final t = _templates[i];
                      final selected = i == _selectedTemplate;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTemplate = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 110,
                          margin: EdgeInsets.only(left: i < _templates.length - 1 ? 10 : 0),
                          decoration: BoxDecoration(
                            gradient: selected ? LinearGradient(colors: t.colors) : null,
                            color: selected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: selected ? null : Border.all(color: Colors.grey.shade200),
                            boxShadow: selected ? [BoxShadow(color: t.colors[0].withOpacity(0.3), blurRadius: 8)] : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(t.icon, color: selected ? Colors.white : _text2, size: 24),
                              const SizedBox(height: 6),
                              Text(t.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? Colors.white : _text2), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Preview card
                const Text('معاينة البطاقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
                const SizedBox(height: 12),
                _buildPreviewCard(),
                const SizedBox(height: 24),

                // Share buttons
                const Text('شاركي عبر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _shareButton('واتساب', Icons.chat, const Color(0xFF25D366)),
                    const SizedBox(width: 12),
                    _shareButton('انستغرام', Icons.camera_alt, const Color(0xFFE1306C)),
                    const SizedBox(width: 12),
                    _shareButton('فيسبوك', Icons.facebook, const Color(0xFF1877F2)),
                    const SizedBox(width: 12),
                    _shareButton('نسخ', Icons.copy, Colors.grey.shade600),
                  ],
                ),
                const SizedBox(height: 16),
                // Big share button
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _showShareDialog(),
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    label: const Text('مشاركة البطاقة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _templates[_selectedTemplate].colors[0],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    switch (_selectedTemplate) {
      case 0: return _weekCard();
      case 1: return _countdownCard();
      case 2: return _babySizeCard();
      case 3: return _achievementCard();
      case 4: return _progressCard();
      default: return _weekCard();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  بطاقات المشاركة — خلفيات نبضة المائية (وردي ناعم)
  // ═══════════════════════════════════════════════════════════════
  static const _ink = Color(0xFF4A2233);      // نص أساسي داكن
  static const _inkSoft = Color(0xFF8C6577);  // نص ثانوي
  static const _gold = Color(0xFFB08B4F);     // لمسة ذهبية

  /// إطار موحّد: صورة الخلفية + شعار نبضة + توقيع الأم
  /// [art] يوضع في المنطقة العلوية (داخل الحلقة/الإكليل في الخلفية)
  /// [child] النصوص في النصف السفلي حيث الخلفية نظيفة
  Widget _cardShell({
    required String asset,
    required Color fallback,
    required Widget child,
    Widget? art,
    double artSize = 150,
  }) {
    return Container(
      height: 430,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: fallback.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFDF0F3), fallback.withOpacity(0.18)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // شعار نبضة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withOpacity(0.35), width: 0.8),
                  ),
                  child: const Text('نبضة 💗',
                      style: TextStyle(color: _ink, fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                // ── العنصر البصري داخل الحلقة العلوية للخلفية ──
                SizedBox(
                  height: artSize,
                  child: Center(child: art ?? const SizedBox.shrink()),
                ),
                // ── النصوص في النصف السفلي النظيف ──
                Expanded(child: Center(child: child)),
                Text(_userName.isEmpty ? 'أم نبضة' : _userName,
                    style: const TextStyle(fontSize: 12.5, color: _inkSoft, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// الجنين داخل الرحم — دائرة صغيرة أنيقة
  Widget _fetusArt(double size) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _gold.withOpacity(0.55), width: 2),
          boxShadow: [
            BoxShadow(color: _gold.withOpacity(0.20), blurRadius: 14, spreadRadius: 1),
          ],
        ),
        child: ClipOval(
          child: WombFloatingFetus(fetusAsset: _fetusAsset, size: size),
        ),
      );

  Widget _weekCard() {
    return _cardShell(
      asset: 'assets/images/share_cards/card_week.png',
      fallback: const Color(0xFFE0195B),
      artSize: 156,
      art: _fetusArt(150),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('الأسبوع', style: TextStyle(fontSize: 16, color: _inkSoft, fontWeight: FontWeight.w600)),
          Text('$_currentWeek',
              style: const TextStyle(fontSize: 62, fontWeight: FontWeight.w900, color: _ink, height: 1.02)),
          const Text('من 40 أسبوعاً', style: TextStyle(fontSize: 13.5, color: _inkSoft)),
          const SizedBox(height: 12),
          SizedBox(
            width: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_currentWeek / 40).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: Colors.white.withOpacity(0.6),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE0195B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownCard() {
    return _cardShell(
      asset: 'assets/images/share_cards/card_countdown.png',
      fallback: const Color(0xFF00897B),
      artSize: 150,
      art: _fetusArt(144),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_daysRemaining',
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: _ink, height: 1.02)),
          const Text('يوم متبقٍ لموعد الولادة',
              style: TextStyle(fontSize: 14.5, color: _inkSoft, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.68),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withOpacity(0.3), width: 0.8),
            ),
            child: Text('${_daysRemaining ~/ 7} أسبوعاً و ${_daysRemaining % 7} أيام',
                style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _babySizeCard() {
    final emoji = _currentWeek > 0 ? FetusSize.emoji(_currentWeek) : '🌱';
    final name = _currentWeek > 0 ? FetusSize.name(_currentWeek) : '';
    return _cardShell(
      asset: 'assets/images/share_cards/card_size.png',
      fallback: const Color(0xFFF57C00),
      artSize: 156,
      // الفاكهة داخل الهالة، والجنين بجانبها بحجم أصغر
      art: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(child: WombFloatingFetus(fetusAsset: _fetusAsset, size: 96)),
          const SizedBox(width: 10),
          Text(emoji, style: const TextStyle(fontSize: 72)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('طفلي بحجم $name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 4),
          Text('الأسبوع $_currentWeek من الحمل',
              style: const TextStyle(fontSize: 13.5, color: _inkSoft)),
        ],
      ),
    );
  }

  Widget _achievementCard() {
    final trimesterName = ['', 'الأول', 'الثاني', 'الثالث'][_trimester];
    return _cardShell(
      asset: 'assets/images/share_cards/card_achievement.png',
      fallback: const Color(0xFFB08B4F),
      artSize: 150,
      art: _fetusArt(128),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('أنا في الثلث', style: TextStyle(fontSize: 16, color: _inkSoft, fontWeight: FontWeight.w600)),
          Text(trimesterName,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _ink, height: 1.12)),
          Text('الأسبوع $_currentWeek من رحلة الحمل',
              style: const TextStyle(fontSize: 13.5, color: _inkSoft)),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final progress = (_currentWeek / 40 * 100).toInt();
    return _cardShell(
      asset: 'assets/images/share_cards/card_progress.png',
      fallback: const Color(0xFF7E57C2),
      artSize: 150,
      art: SizedBox(
        width: 146,
        height: 146,
        child: CustomPaint(
          painter: _ProgressCirclePainter(progress / 100),
          child: Center(
            child: ClipOval(
              child: WombFloatingFetus(fetusAsset: _fetusAsset, size: 108),
            ),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$progress%',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: _ink, height: 1.05)),
          const Text('من رحلة الحمل مكتملة',
              style: TextStyle(fontSize: 15, color: _ink, fontWeight: FontWeight.w800)),
          Text('الأسبوع $_currentWeek من 40',
              style: const TextStyle(fontSize: 13, color: _inkSoft)),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _shareButton(String label, IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showShareDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareDialog() {
    // Build share text
    final texts = [
      'أنا في الأسبوع $_currentWeek من الحمل! 🤰 طفلي بحجم $_babySize — $_daysRemaining يوم متبقي! تطبيق نبضة 💗',
      '$_daysRemaining يوم يفصلني عن لقاء طفلي! ⏳ الأسبوع $_currentWeek من 40 — تطبيق نبضة 💗',
      'طفلي الآن بحجم $_babySize! 🤩 الأسبوع $_currentWeek من الحمل — تطبيق نبضة 💗',
      'أنا في الثلث ${['', 'الأول', 'الثاني', 'الثالث'][_trimester]} من الحمل! 🏆 — تطبيق نبضة 💗',
      'أكملت ${(_currentWeek / 40 * 100).toInt()}% من رحلة الحمل! 📈 الأسبوع $_currentWeek — تطبيق نبضة 💗',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('نص المشاركة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text1)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16)),
              child: Text(texts[_selectedTemplate], style: const TextStyle(fontSize: 15, color: _text1, height: 1.6), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم نسخ النص! يمكنك لصقه في أي تطبيق 📋'),
                      backgroundColor: _teal,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text('نسخ النص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('💡 قريباً: مشاركة مباشرة مع الصورة', style: TextStyle(fontSize: 12, color: _text2)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _ProgressCirclePainter extends CustomPainter {
  final double progress;
  _ProgressCirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = const Color(0xFFE0195B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ShareTemplate {
  final String name;
  final List<Color> colors;
  final IconData icon;
  const _ShareTemplate(this.name, this.colors, this.icon);
}
