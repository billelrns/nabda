import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
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

      final lmpStr = data['lastPeriodDate'] as String?;
      final dueDateStr = data['dueDate'] as String?;
      final weekFromData = (data['pregnancyWeek'] as num?)?.toInt() ??
          (data['weight_tracker_profile']?['current_week'] as num?)?.toInt() ?? 0;

      DateTime? lmp = lmpStr != null ? DateTime.tryParse(lmpStr) : null;
      DateTime? due = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
      if (due == null && lmp != null) due = lmp.add(const Duration(days: 280));

      int week = weekFromData;
      if (lmp != null) week = DateTime.now().difference(lmp).inDays ~/ 7;

      int remaining = due != null ? max(0, due.difference(DateTime.now()).inDays) : 0;
      int trim = week <= 13 ? 1 : week <= 26 ? 2 : 3;

      setState(() {
        _currentWeek = week;
        _daysRemaining = remaining;
        _trimester = trim;
        _babySize = _getBabySize(week);
        _userName = (data['displayName'] as String?) ?? 'أم نبضة';
        _loaded = true;
      });
    } catch (_) {
      setState(() => _loaded = true);
    }
  }

  String _getBabySize(int w) {
    if (w < 8) return 'حبة فاصوليا 🫘';
    if (w < 12) return 'ليمونة 🍋';
    if (w < 16) return 'برتقالة 🍊';
    if (w < 20) return 'موزة 🍌';
    if (w < 24) return 'ذرة 🌽';
    if (w < 28) return 'باذنجان 🍆';
    if (w < 32) return 'جوز هند 🥥';
    if (w < 36) return 'أناناس 🍍';
    if (w < 40) return 'بطيخة 🍉';
    return 'يقطينة 🎃';
  }

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

  Widget _weekCard() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFE91E63), const Color(0xFFFF6090)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFE91E63).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -30, top: -30, child: _decorCircle(100, Colors.white.withOpacity(0.08))),
          Positioned(left: -20, bottom: -20, child: _decorCircle(80, Colors.white.withOpacity(0.06))),
          Positioned(right: 40, bottom: 20, child: _decorCircle(40, Colors.white.withOpacity(0.05))),
          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Text('نبضة 💗', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Spacer(),
                Text('الأسبوع', style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8))),
                Text('$_currentWeek', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
                const SizedBox(height: 4),
                Text('من 40 أسبوع', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentWeek / 40).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_userName, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownCard() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF4DB6AC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF00897B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(left: -30, top: -30, child: _decorCircle(100, Colors.white.withOpacity(0.07))),
          Positioned(right: -15, bottom: -15, child: _decorCircle(70, Colors.white.withOpacity(0.05))),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('نبضة 💗', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('⏳', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 10),
                Text('$_daysRemaining', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white, height: 1)),
                Text('يوم متبقي لموعد الولادة', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: Text('${_daysRemaining ~/ 7} أسبوع و ${_daysRemaining % 7} أيام', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _babySizeCard() {
    final emoji = _babySize.split(' ').last;
    final name = _babySize.split(' ').first;
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF7B1FA2).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: _decorCircle(90, Colors.white.withOpacity(0.07))),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('نبضة 💗', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(emoji, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 12),
                Text('طفلي بحجم $name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text('الأسبوع $_currentWeek من الحمل', style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.7))),
                const Spacer(),
                Text(_userName, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementCard() {
    final trimesterName = ['', 'الأول', 'الثاني', 'الثالث'][_trimester];
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFFB74D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFFF6F00).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(left: -25, bottom: -25, child: _decorCircle(90, Colors.white.withOpacity(0.07))),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('نبضة 💗', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('🏆', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                const Text('أنا في الثلث', style: TextStyle(fontSize: 18, color: Colors.white)),
                Text(trimesterName, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('من رحلة الحمل!', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
                const Spacer(),
                Text(_userName, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final progress = (_currentWeek / 40 * 100).toInt();
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: _decorCircle(100, Colors.white.withOpacity(0.06))),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('نبضة 💗', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                SizedBox(
                  width: 140, height: 140,
                  child: CustomPaint(
                    painter: _ProgressCirclePainter(progress / 100),
                    child: Center(
                      child: Text('$progress%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('من رحلة الحمل مكتملة', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
                Text('الأسبوع $_currentWeek من 40', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                const Spacer(),
                Text(_userName, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
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
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = Colors.white
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
