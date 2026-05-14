import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'weight_tracker_screen.dart';

// ─── Theme ───
const Color _bg = Color(0xFFFFF5F7);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);

// ─── Firestore Helper ───
DocumentReference get _userDoc {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

// ═══════════════════════════════════════════════
//  MAIN TRACKERS SCREEN
// ═══════════════════════════════════════════════
class HealthTrackersScreen extends StatelessWidget {
  const HealthTrackersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('العدادات الصحية', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_teal, _teal.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monitor_heart, size: 40, color: Colors.white),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تتبعي صحتك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('سجّلي قياساتك اليومية لمتابعة صحتك وصحة جنينك', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tracker cards grid
            _TrackerCard(
              title: 'الوزن',
              subtitle: 'تتبعي زيادة وزنك أسبوعيًا',
              emoji: '⚖️',
              color: const Color(0xFF5C6BC0),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightTrackerScreen())),
            ),
            const SizedBox(height: 12),
            _TrackerCard(
              title: 'ضغط الدم',
              subtitle: 'سجّلي قراءات الضغط',
              emoji: '🩺',
              color: const Color(0xFFEF5350),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _BloodPressureScreen())),
            ),
            const SizedBox(height: 12),
            _TrackerCard(
              title: 'عدّاد الانقباضات',
              subtitle: 'حساب توقيت ومدة الانقباضات',
              emoji: '⏱️',
              color: const Color(0xFFFF7043),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ContractionTimerScreen())),
            ),
            const SizedBox(height: 12),
            _TrackerCard(
              title: 'حركات الجنين',
              subtitle: 'عدّي ركلات طفلك يوميًا',
              emoji: '👶',
              color: const Color(0xFFAB47BC),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _KickCounterScreen())),
            ),
            const SizedBox(height: 12),
            _TrackerCard(
              title: 'نمو البطن',
              subtitle: 'قياس محيط البطن',
              emoji: '🤰',
              color: const Color(0xFF26A69A),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _BellyGrowthScreen())),
            ),
            const SizedBox(height: 12),
            _TrackerCard(
              title: 'ساعات النوم',
              subtitle: 'تتبعي نومك وجودته',
              emoji: '😴',
              color: const Color(0xFF42A5F5),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _SleepTrackerScreen())),
            ),
            const SizedBox(height: 12),
            _TrackerCard(
              title: 'شرب الماء',
              subtitle: 'تأكدي من شربك 8 أكواب يوميًا',
              emoji: '💧',
              color: const Color(0xFF29B6F6),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _WaterTrackerScreen())),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─── Tracker Card Widget ───
class _TrackerCard extends StatelessWidget {
  final String title, subtitle, emoji;
  final Color color;
  final VoidCallback onTap;
  const _TrackerCard({required this.title, required this.subtitle, required this.emoji, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: _text2)),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios, size: 16, color: _text2),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  1. WEIGHT TRACKER — moved to weight_tracker_screen.dart
// ═══════════════════════════════════════════════

// ═══════════════════════════════════════════════
//  2. BLOOD PRESSURE TRACKER
// ═══════════════════════════════════════════════
class _BloodPressureScreen extends StatefulWidget {
  const _BloodPressureScreen({Key? key}) : super(key: key);
  @override
  State<_BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<_BloodPressureScreen> {
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _pulseController = TextEditingController();

  Future<void> _addReading() async {
    final sys = int.tryParse(_sysController.text);
    final dia = int.tryParse(_diaController.text);
    if (sys == null || dia == null) return;
    final pulse = int.tryParse(_pulseController.text);
    await _userDoc.collection('bp_tracker').add({
      'systolic': sys, 'diastolic': dia, 'pulse': pulse,
      'date': FieldValue.serverTimestamp(),
    });
    _sysController.clear(); _diaController.clear(); _pulseController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('تم تسجيل قراءة الضغط'), backgroundColor: _teal, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  String _bpStatus(int sys, int dia) {
    if (sys < 90 || dia < 60) return '🔵 منخفض';
    if (sys <= 120 && dia <= 80) return '🟢 طبيعي';
    if (sys <= 140 || dia <= 90) return '🟡 مرتفع قليلاً';
    return '🔴 مرتفع - استشيري الطبيبة';
  }

  Color _bpColor(int sys, int dia) {
    if (sys < 90 || dia < 60) return Colors.blue;
    if (sys <= 120 && dia <= 80) return Colors.green;
    if (sys <= 140 || dia <= 90) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() { _sysController.dispose(); _diaController.dispose(); _pulseController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('🩺 ضغط الدم', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _inputField(_sysController, 'الانقباضي', 'SYS')),
                      const SizedBox(width: 8),
                      const Text('/', style: TextStyle(fontSize: 24, color: _text2)),
                      const SizedBox(width: 8),
                      Expanded(child: _inputField(_diaController, 'الانبساطي', 'DIA')),
                      const SizedBox(width: 8),
                      Expanded(child: _inputField(_pulseController, 'النبض', '♡')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addReading,
                      style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('تسجيل القراءة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _userDoc.collection('bp_tracker').orderBy('date', descending: true).limit(30).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Center(child: Text('لا توجد قراءات بعد', style: TextStyle(color: _text2)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snap.data!.docs.length,
                    itemBuilder: (_, i) {
                      final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                      final sys = d['systolic'] as int? ?? 0;
                      final dia = d['diastolic'] as int? ?? 0;
                      final pulse = d['pulse'] as int?;
                      final ts = d['date'] as Timestamp?;
                      final dateStr = ts != null ? '${ts.toDate().day}/${ts.toDate().month} - ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}' : '---';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(color: _bpColor(sys, dia).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text('$sys\n$dia', textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _bpColor(sys, dia)))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_bpStatus(sys, dia), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _text1)),
                                Text(dateStr, style: TextStyle(fontSize: 11, color: _text2)),
                              ],
                            )),
                            if (pulse != null) Text('♡ $pulse', style: TextStyle(color: _pink, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController c, String label, String hint) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint, labelText: label,
        filled: true, fillColor: _bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  3. CONTRACTION TIMER
// ═══════════════════════════════════════════════
class _ContractionTimerScreen extends StatefulWidget {
  const _ContractionTimerScreen({Key? key}) : super(key: key);
  @override
  State<_ContractionTimerScreen> createState() => _ContractionTimerScreenState();
}

class _ContractionTimerScreenState extends State<_ContractionTimerScreen> {
  bool _isActive = false;
  Timer? _timer;
  int _seconds = 0;
  final List<Map<String, dynamic>> _contractions = [];

  void _toggleContraction() {
    if (_isActive) {
      // End contraction
      _timer?.cancel();
      _contractions.insert(0, {
        'duration': _seconds,
        'time': DateTime.now(),
        'interval': _contractions.isNotEmpty
          ? DateTime.now().difference(_contractions.first['time'] as DateTime).inSeconds
          : 0,
      });
      // Save to Firestore
      _userDoc.collection('contractions').add({
        'duration': _seconds,
        'date': FieldValue.serverTimestamp(),
      });
      setState(() { _isActive = false; _seconds = 0; });
    } else {
      // Start contraction
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
      setState(() => _isActive = true);
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('⏱️ عدّاد الانقباضات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        ),
        body: Column(
          children: [
            const SizedBox(height: 30),
            // Timer display
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isActive ? _pink.withOpacity(0.1) : _teal.withOpacity(0.1),
                border: Border.all(color: _isActive ? _pink : _teal, width: 4),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_formatTime(_seconds),
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: _isActive ? _pink : _teal)),
                    Text(_isActive ? 'انقباض جارٍ...' : 'جاهزة',
                      style: TextStyle(fontSize: 14, color: _isActive ? _pink : _text2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Start/Stop button
            SizedBox(
              width: 200, height: 56,
              child: ElevatedButton.icon(
                onPressed: _toggleContraction,
                icon: Icon(_isActive ? Icons.stop : Icons.play_arrow),
                label: Text(_isActive ? 'إيقاف' : 'بداية الانقباض', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isActive ? _pink : _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_contractions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statCard('المدة المتوسطة', '${(_contractions.map((c) => c['duration'] as int).reduce((a,b) => a+b) / _contractions.length).round()} ث'),
                    if (_contractions.length > 1)
                      _statCard('الفاصل المتوسط', '${(_contractions.where((c) => c['interval'] > 0).map((c) => c['interval'] as int).reduce((a,b) => a+b) / (_contractions.length - 1) / 60).toStringAsFixed(1)} د'),
                    _statCard('العدد', '${_contractions.length}'),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            // Contraction list
            Expanded(
              child: _contractions.isEmpty
                ? Center(child: Text('اضغطي "بداية الانقباض" عند بدء كل انقباض', style: TextStyle(color: _text2, fontSize: 13)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _contractions.length,
                    itemBuilder: (_, i) {
                      final c = _contractions[i];
                      final dur = c['duration'] as int;
                      final time = c['time'] as DateTime;
                      final interval = c['interval'] as int;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Text('${_contractions.length - i}', style: TextStyle(fontWeight: FontWeight.bold, color: _teal, fontSize: 16)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('المدة: ${_formatTime(dur)}', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
                                Text('${time.hour}:${time.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 11, color: _text2)),
                              ],
                            )),
                            if (interval > 0)
                              Text('فاصل: ${(interval / 60).toStringAsFixed(1)} د', style: TextStyle(fontSize: 12, color: _text2)),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _teal)),
          Text(label, style: TextStyle(fontSize: 10, color: _text2)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  4. KICK COUNTER
// ═══════════════════════════════════════════════
class _KickCounterScreen extends StatefulWidget {
  const _KickCounterScreen({Key? key}) : super(key: key);
  @override
  State<_KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends State<_KickCounterScreen> {
  int _kicks = 0;
  DateTime? _sessionStart;
  Timer? _timer;
  int _elapsed = 0;

  void _startSession() {
    _sessionStart = DateTime.now();
    _kicks = 0;
    _elapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
    setState(() {});
  }

  void _addKick() {
    setState(() => _kicks++);
    if (_kicks >= 10) {
      _timer?.cancel();
      // Save completed session
      _userDoc.collection('kick_counter').add({
        'kicks': _kicks,
        'duration': _elapsed,
        'date': FieldValue.serverTimestamp(),
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('ممتاز! 🎉', textAlign: TextAlign.center),
          content: Text('سجّلتِ 10 حركات في ${(_elapsed / 60).toStringAsFixed(1)} دقيقة.\nالطبيعي أن تشعري بـ 10 حركات خلال ساعتين.',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); setState(() { _sessionStart = null; }); },
              child: const Text('حسنًا')),
          ],
        ),
      );
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('👶 حركات الجنين', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: _sessionStart == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👶', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 20),
                  const Text('عدّاد حركات الجنين', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _text1)),
                  const SizedBox(height: 8),
                  Text('اضغطي على الشاشة كلما شعرتِ بركلة', style: TextStyle(color: _text2, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('الهدف: 10 حركات خلال ساعتين', style: TextStyle(color: _text2, fontSize: 12)),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _startSession,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('ابدئي الجلسة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${(_elapsed ~/ 60).toString().padLeft(2,'0')}:${(_elapsed % 60).toString().padLeft(2,'0')}',
                    style: TextStyle(fontSize: 20, color: _text2)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _addKick,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [_pink.withOpacity(0.8), const Color(0xFFAB47BC)]),
                        boxShadow: [BoxShadow(color: _pink.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$_kicks', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text('ركلة', style: TextStyle(fontSize: 16, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('اضغطي عند كل ركلة', style: TextStyle(color: _text2)),
                  const SizedBox(height: 8),
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _kicks / 10,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(_kicks >= 10 ? Colors.green : _pink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('$_kicks / 10', style: TextStyle(color: _text2, fontSize: 13)),
                ],
              ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  5. BELLY GROWTH TRACKER
// ═══════════════════════════════════════════════
class _BellyGrowthScreen extends StatefulWidget {
  const _BellyGrowthScreen({Key? key}) : super(key: key);
  @override
  State<_BellyGrowthScreen> createState() => _BellyGrowthScreenState();
}

class _BellyGrowthScreenState extends State<_BellyGrowthScreen> {
  final _measureController = TextEditingController();

  Future<void> _addMeasure() async {
    final cm = double.tryParse(_measureController.text);
    if (cm == null || cm < 20 || cm > 150) return;
    await _userDoc.collection('belly_growth').add({
      'cm': cm, 'date': FieldValue.serverTimestamp(),
    });
    _measureController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('تم تسجيل القياس'), backgroundColor: _teal, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  @override
  void dispose() { _measureController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('🤰 نمو البطن', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
              child: Column(
                children: [
                  const Text('قياس محيط البطن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _measureController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'المحيط بالسنتيمتر', suffixText: 'سم',
                            filled: true, fillColor: _bg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _addMeasure,
                        style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                        child: const Text('تسجيل', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _userDoc.collection('belly_growth').orderBy('date', descending: true).limit(20).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Center(child: Text('لا توجد قياسات بعد', style: TextStyle(color: _text2)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snap.data!.docs.length,
                    itemBuilder: (_, i) {
                      final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                      final cm = d['cm'];
                      final ts = d['date'] as Timestamp?;
                      final dateStr = ts != null ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}' : '---';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14)),
                        child: Row(
                          children: [
                            const Text('🤰', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$cm سم', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
                                Text(dateStr, style: TextStyle(fontSize: 11, color: _text2)),
                              ],
                            )),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  6. SLEEP TRACKER
// ═══════════════════════════════════════════════
class _SleepTrackerScreen extends StatefulWidget {
  const _SleepTrackerScreen({Key? key}) : super(key: key);
  @override
  State<_SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<_SleepTrackerScreen> {
  double _hours = 7;
  int _quality = 3; // 1-5

  Future<void> _saveSleep() async {
    await _userDoc.collection('sleep_tracker').add({
      'hours': _hours, 'quality': _quality, 'date': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('تم تسجيل النوم'), backgroundColor: _teal, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qualityEmojis = ['😫', '😞', '😐', '🙂', '😴'];
    final qualityLabels = ['سيء جداً', 'سيء', 'متوسط', 'جيد', 'ممتاز'];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('😴 تتبع النوم', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
              child: Column(
                children: [
                  Text('${_hours.toStringAsFixed(1)} ساعة', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _teal)),
                  const SizedBox(height: 8),
                  Slider(
                    value: _hours, min: 1, max: 14, divisions: 26,
                    activeColor: _teal,
                    label: '${_hours.toStringAsFixed(1)} ساعة',
                    onChanged: (v) => setState(() => _hours = v),
                  ),
                  Text('المثالي للحامل: 7-9 ساعات', style: TextStyle(fontSize: 11, color: _text2)),
                  const SizedBox(height: 16),
                  const Text('جودة النوم', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _text1)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => GestureDetector(
                      onTap: () => setState(() => _quality = i + 1),
                      child: Column(
                        children: [
                          Text(qualityEmojis[i], style: TextStyle(fontSize: _quality == i + 1 ? 34 : 24)),
                          Text(qualityLabels[i], style: TextStyle(fontSize: 9, color: _quality == i + 1 ? _teal : _text2,
                            fontWeight: _quality == i + 1 ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    )),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSleep,
                      style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _userDoc.collection('sleep_tracker').orderBy('date', descending: true).limit(14).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Center(child: Text('لا توجد تسجيلات بعد', style: TextStyle(color: _text2)));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: snap.data!.docs.length,
                    itemBuilder: (_, i) {
                      final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                      final h = d['hours'] ?? 0;
                      final q = d['quality'] ?? 3;
                      final ts = d['date'] as Timestamp?;
                      final dateStr = ts != null ? '${ts.toDate().day}/${ts.toDate().month}' : '---';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Text(qualityEmojis[(q as int) - 1], style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$h ساعة', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1)),
                                Text(dateStr, style: TextStyle(fontSize: 11, color: _text2)),
                              ],
                            )),
                            Text(qualityLabels[q - 1], style: TextStyle(fontSize: 12, color: _text2)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  7. WATER INTAKE TRACKER
// ═══════════════════════════════════════════════
class _WaterTrackerScreen extends StatefulWidget {
  const _WaterTrackerScreen({Key? key}) : super(key: key);
  @override
  State<_WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<_WaterTrackerScreen> {
  int _glasses = 0;
  static const int _goal = 8;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final today = DateTime.now();
    final key = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    final doc = await _userDoc.collection('water_tracker').doc(key).get();
    if (doc.exists) {
      setState(() => _glasses = (doc.data() as Map<String, dynamic>)['glasses'] ?? 0);
    }
  }

  Future<void> _addGlass() async {
    setState(() => _glasses++);
    final today = DateTime.now();
    final key = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    await _userDoc.collection('water_tracker').doc(key).set({
      'glasses': _glasses, 'date': FieldValue.serverTimestamp(),
    });
    if (_glasses == _goal && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('ممتاز! حققتِ هدفك اليومي! 🎉'), backgroundColor: _teal, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  Future<void> _removeGlass() async {
    if (_glasses <= 0) return;
    setState(() => _glasses--);
    final today = DateTime.now();
    final key = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
    await _userDoc.collection('water_tracker').doc(key).set({
      'glasses': _glasses, 'date': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_glasses / _goal).clamp(0.0, 1.0);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('💧 شرب الماء', style: TextStyle(fontWeight: FontWeight.bold, color: _text1)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Water glass visual
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 180, height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.05),
                      border: Border.all(color: Colors.blue.withOpacity(0.2), width: 3),
                    ),
                  ),
                  Container(
                    width: 160, height: 160,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          width: 160,
                          height: 160 * percent,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.blue.withOpacity(0.3), Colors.blue.withOpacity(0.6)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text('$_glasses', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _glasses >= _goal ? _teal : _text1)),
                      Text('من $_goal أكواب', style: TextStyle(fontSize: 14, color: _text2)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // + / - buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleButton(Icons.remove, _removeGlass, Colors.red.shade300),
                  const SizedBox(width: 30),
                  GestureDetector(
                    onTap: _addGlass,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF29B6F6), Color(0xFF0288D1)]),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, spreadRadius: 3)],
                      ),
                      child: const Center(child: Text('💧', style: TextStyle(fontSize: 36))),
                    ),
                  ),
                  const SizedBox(width: 30),
                  _circleButton(Icons.add, _addGlass, _teal),
                ],
              ),
              const SizedBox(height: 16),
              Text(_glasses >= _goal ? 'أحسنتِ! حققتِ الهدف! 🎉' : 'تحتاجين ${_goal - _glasses} أكواب أخرى',
                style: TextStyle(fontSize: 14, color: _glasses >= _goal ? _teal : _text2)),
              const SizedBox(height: 8),
              Text('الحامل تحتاج 8-10 أكواب يوميًا', style: TextStyle(fontSize: 11, color: _text2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.3))),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
