import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

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

class DueDateCountdownScreen extends StatefulWidget {
  const DueDateCountdownScreen({Key? key}) : super(key: key);
  @override
  State<DueDateCountdownScreen> createState() => _DueDateCountdownScreenState();
}

class _DueDateCountdownScreenState extends State<DueDateCountdownScreen> {
  DateTime? _dueDate;
  DateTime? _lmpDate;
  bool _loaded = false;

  final _motivationalMessages = [
    'كل يوم يقربك أكثر من لقاء طفلك',
    'أنتِ قوية وستجتازين هذه الرحلة بنجاح',
    'طفلك ينمو ويكبر بداخلك كل لحظة',
    'استمتعي بكل لحظة — هذه فترة مميزة',
    'جسمك يصنع معجزة كل يوم',
    'أنتِ أم رائعة حتى قبل أن يولد طفلك',
    'كل ركلة هي رسالة حب من طفلك',
    'قريبًا ستحملينه بين يديك',
    'أنتِ تقومين بعمل مذهل — فخورون بك',
    'طفلك محظوظ لأنك أمه',
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
      final dueDateStr = data['dueDate'] as String?;
      final lmpStr = data['lastPeriodDate'] as String?;
      final week = (data['pregnancyWeek'] as num?)?.toInt() ??
          (data['weight_tracker_profile']?['current_week'] as num?)?.toInt() ?? 0;

      DateTime? due = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
      DateTime? lmp = lmpStr != null ? DateTime.tryParse(lmpStr) : null;

      if (due == null && lmp != null) due = lmp.add(const Duration(days: 280));
      if (due == null && week > 0) {
        lmp = DateTime.now().subtract(Duration(days: week * 7));
        due = lmp.add(const Duration(days: 280));
      }

      setState(() { _dueDate = due; _lmpDate = lmp; _loaded = true; });
    } catch (_) {
      setState(() { _loaded = true; });
    }
  }

  int get _currentWeek {
    if (_lmpDate == null) return 0;
    return DateTime.now().difference(_lmpDate!).inDays ~/ 7;
  }

  int get _daysRemaining => _dueDate != null ? max(0, _dueDate!.difference(DateTime.now()).inDays) : 0;
  int get _weeksRemaining => _daysRemaining ~/ 7;
  int get _extraDays => _daysRemaining % 7;
  int get _daysPassed => _lmpDate != null ? DateTime.now().difference(_lmpDate!).inDays : 0;
  double get _progress => (_daysPassed / 280).clamp(0.0, 1.0);
  int get _trimester => _currentWeek <= 13 ? 1 : _currentWeek <= 26 ? 2 : 3;

  String get _todayMessage {
    final idx = DateTime.now().day % _motivationalMessages.length;
    return _motivationalMessages[idx];
  }

  String get _babySize {
    if (_currentWeek < 8) return 'حبة فاصوليا 🫘';
    if (_currentWeek < 12) return 'ليمونة 🍋';
    if (_currentWeek < 16) return 'برتقالة 🍊';
    if (_currentWeek < 20) return 'موزة 🍌';
    if (_currentWeek < 24) return 'ذرة 🌽';
    if (_currentWeek < 28) return 'باذنجان 🍆';
    if (_currentWeek < 32) return 'جوز هند 🥥';
    if (_currentWeek < 36) return 'أناناس 🍍';
    if (_currentWeek < 40) return 'بطيخة 🍉';
    return 'يقطينة 🎃';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('العد التنازلي', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: true,
        ),
        body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _dueDate == null
            ? _buildNoDueDate()
            : _buildCountdown(),
      ),
    );
  }

  Widget _buildNoDueDate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⏳', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text('لم يتم تحديد موعد الولادة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text1)),
            const SizedBox(height: 10),
            Text('يرجى إدخال تاريخ آخر دورة من صفحة تقويم الحمل', style: TextStyle(fontSize: 14, color: _text2), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Main countdown circle
        Center(
          child: SizedBox(
            width: 260, height: 260,
            child: CustomPaint(
              painter: _CountdownCirclePainter(progress: _progress, trimester: _trimester),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$_daysRemaining', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: _pink)),
                    const Text('يوم متبقي', style: TextStyle(fontSize: 16, color: _text2)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('$_weeksRemaining أسبوع و $_extraDays أيام', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _teal)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Motivational message
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_pink.withOpacity(0.08), _pink.withOpacity(0.03)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _pink.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Text('💝', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(child: Text(_todayMessage, style: const TextStyle(fontSize: 15, color: _text1, height: 1.5))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Info cards row
        Row(
          children: [
            _infoCard('الأسبوع', '$_currentWeek', 'من 40', _teal),
            const SizedBox(width: 12),
            _infoCard('الثلث', '$_trimester', ['', 'الأول', 'الثاني', 'الثالث'][_trimester], Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _infoCard('حجم الجنين', _babySize.split(' ').last, _babySize.split(' ').first, Colors.purple),
            const SizedBox(width: 12),
            _infoCard('التقدم', '${(_progress * 100).toInt()}%', 'مكتمل', _pink),
          ],
        ),
        const SizedBox(height: 16),

        // Due date info
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(
            children: [
              _detailRow(Icons.calendar_today, 'موعد الولادة المتوقع', '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
              const Divider(height: 20),
              if (_lmpDate != null) ...[
                _detailRow(Icons.history, 'تاريخ آخر دورة', '${_lmpDate!.day}/${_lmpDate!.month}/${_lmpDate!.year}'),
                const Divider(height: 20),
              ],
              _detailRow(Icons.timer, 'أيام مرت', '$_daysPassed يوم'),
              const Divider(height: 20),
              _detailRow(Icons.baby_changing_station, 'الأيام المتبقية', '$_daysRemaining يوم'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Weekly progress bar
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('مراحل الحمل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
              const SizedBox(height: 16),
              _trimesterBar('الثلث الأول', 1, 13, Colors.blue),
              const SizedBox(height: 10),
              _trimesterBar('الثلث الثاني', 14, 26, Colors.orange),
              const SizedBox(height: 10),
              _trimesterBar('الثلث الثالث', 27, 40, _pink),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _infoCard(String label, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 12, color: _text2)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _text1)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _teal, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: _text2))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _text1)),
      ],
    );
  }

  Widget _trimesterBar(String label, int startWeek, int endWeek, Color color) {
    final totalWeeks = endWeek - startWeek + 1;
    final passedInTrimester = (_currentWeek - startWeek + 1).clamp(0, totalWeeks);
    final progress = passedInTrimester / totalWeeks;
    final isCurrent = _currentWeek >= startWeek && _currentWeek <= endWeek;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCurrent ? color : _text2)),
            const Spacer(),
            Text('أسبوع $startWeek-$endWeek', style: TextStyle(fontSize: 11, color: _text2)),
            if (isCurrent) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                child: const Text('الآن', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.toDouble(),
            minHeight: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _CountdownCirclePainter extends CustomPainter {
  final double progress;
  final int trimester;
  _CountdownCirclePainter({required this.progress, required this.trimester});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background circle
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);

    // Progress arc
    final colors = [Colors.blue, Colors.orange, const Color(0xFFE91E63)];
    final color = colors[(trimester - 1).clamp(0, 2)];
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Trimester markers
    for (int i = 0; i < 3; i++) {
      final angle = -pi / 2 + (2 * pi * (i + 1) / 3);
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(dx, dy), 5, Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
