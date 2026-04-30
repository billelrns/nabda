import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/pregnancy_week_articles.dart';

class PregnancyWeeksScreen extends StatelessWidget {
  final int? currentWeek;
  final int? daysLeft;
  final double? percent;
  const PregnancyWeeksScreen({Key? key, this.currentWeek, this.daysLeft, this.percent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentWeek != null && currentWeek! >= 1) {
      final week = currentWeek!.clamp(1, 40);
      final article = pregnancyWeekArticles.firstWhere((a) => a.week == week, orElse: () => pregnancyWeekArticles.last);
      return WeekDetailScreen(article: article, currentWeek: currentWeek, daysLeft: daysLeft, percent: percent);
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(title: const Text('دليل الحمل أسبوعياً', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF9C27B0), foregroundColor: Colors.white, elevation: 0, centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(3, (ti) {
            final name = ['الثلث الأول', 'الثلث الثاني', 'الثلث الثالث'][ti];
            final weeks = [
              pregnancyWeekArticles.where((a) => a.week <= 12).toList(),
              pregnancyWeekArticles.where((a) => a.week > 12 && a.week <= 27).toList(),
              pregnancyWeekArticles.where((a) => a.week > 27).toList(),
            ][ti];
            final color = [const Color(0xFF4CAF50), const Color(0xFF2196F3), const Color(0xFF9C27B0)][ti];
            final range = ['1 - 12', '13 - 27', '28 - 40'][ti];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Icon([Icons.spa, Icons.child_friendly, Icons.favorite][ti], color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('الأسبوع $range', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                  ])),
                ])),
              ...weeks.map((a) => Card(margin: const EdgeInsets.only(bottom: 10), elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: InkWell(borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WeekDetailScreen(article: a))),
                  child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                      child: CustomPaint(painter: RealisticFetusIllustration(week: a.week, isSmall: true))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('الأسبوع ${a.week}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${a.babySizeAr} (${a.babyLength})', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ])),
                    Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey.shade400),
                  ]))))),
              const SizedBox(height: 16),
            ]);
          }),
        ),
      ),
    );
  }
}

class WeekDetailScreen extends StatefulWidget {
  final PregnancyWeekArticle article;
  final int? currentWeek;
  final int? daysLeft;
  final double? percent;
  const WeekDetailScreen({Key? key, required this.article, this.currentWeek, this.daysLeft, this.percent}) : super(key: key);
  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  Uint8List? _echoImage;
  bool _loadingEcho = true;
  int _kickCount = 0;

  @override
  void initState() { super.initState(); _loadSavedEcho(); }

  Future<void> _loadSavedEcho() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loadingEcho = false); return; }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .collection('echo_images').doc('week_${widget.article.week}').get();
      if (doc.exists && doc.data()?['imageBase64'] != null) {
        setState(() { _echoImage = base64Decode(doc.data()!['imageBase64']); _loadingEcho = false; });
      } else { setState(() => _loadingEcho = false); }
    } catch (_) { setState(() => _loadingEcho = false); }
  }

  Future<void> _pickEchoImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 72, maxWidth: 1024);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 500 * 1024) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الصورة كبيرة جداً'))); return; }
    setState(() => _echoImage = bytes);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .collection('echo_images').doc('week_${widget.article.week}').set({
        'imageBase64': base64Encode(bytes), 'week': widget.article.week, 'updatedAt': FieldValue.serverTimestamp()});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('تم حفظ صورة الإيكو بنجاح'), backgroundColor: Colors.green.shade600));
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final color = a.week <= 12 ? const Color(0xFF4CAF50) : a.week <= 27 ? const Color(0xFF2196F3) : const Color(0xFF9C27B0);
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(slivers: [
        SliverAppBar(expandedHeight: 300, pinned: true, backgroundColor: color, foregroundColor: Colors.white,
          automaticallyImplyLeading: widget.currentWeek == null,
          actions: [
            IconButton(icon: const Icon(Icons.list_alt), tooltip: 'جميع الأسابيع',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PregnancyWeeksScreen()))),
            IconButton(icon: const Icon(Icons.date_range), tooltip: 'تغيير تاريخ الحمل',
              onPressed: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now().subtract(const Duration(days: 140)),
                  firstDate: DateTime.now().subtract(const Duration(days: 280)), lastDate: DateTime.now());
                if (date != null) { final user = FirebaseAuth.instance.currentUser;
                  if (user != null) await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'pregnancyStartDate': Timestamp.fromDate(date)}, SetOptions(merge: true));
                }
              }),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text('الأسبوع ${a.week}', style: const TextStyle(fontWeight: FontWeight.bold)),
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [const Color(0xFF1A1A2E), color.withOpacity(0.9), color])),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [const Color(0xFFE8B4B8).withOpacity(0.15), Colors.transparent])),
                  child: CustomPaint(painter: RealisticFetusIllustration(week: a.week))),
                const SizedBox(height: 8),
                Text(a.getTrimesterAr(), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                Text('حجم الجنين: ${a.babySizeAr}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ])))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          if (widget.currentWeek != null) ...[_buildProgress(color), const SizedBox(height: 12)],
          _card(Icons.straighten, 'حجم الجنين', color, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _sz('مثل', a.babySizeAr, Icons.circle), _sz('الطول', a.babyLength, Icons.height), _sz('الوزن', a.babyWeight, Icons.monitor_weight_outlined)])),
          const SizedBox(height: 12),
          _buildEcho(color), const SizedBox(height: 12),
          _card(Icons.child_care, 'تطور الجنين', const Color(0xFF4CAF50), child: Text(a.fetalDevAr, style: const TextStyle(fontSize: 14, height: 1.8))),
          const SizedBox(height: 12),
          _card(Icons.favorite, 'أعراض الأم', const Color(0xFFE91E63), child: Text(a.symptomsAr, style: const TextStyle(fontSize: 14, height: 1.8))),
          const SizedBox(height: 12),
          _card(Icons.restaurant, 'نصائح التغذية', const Color(0xFFFF9800), child: Text(a.nutritionAr, style: const TextStyle(fontSize: 14, height: 1.8))),
          const SizedBox(height: 12),
          _card(Icons.lightbulb_outline, 'نصائح عامة', const Color(0xFF2196F3), child: Text(a.tipsAr, style: const TextStyle(fontSize: 14, height: 1.8))),
          const SizedBox(height: 12),
          if (widget.currentWeek != null) ...[_buildChecklist(color), const SizedBox(height: 12), _buildKicks(color), const SizedBox(height: 12)],
          Row(children: [
            if (a.week > 1) Expanded(child: OutlinedButton.icon(
              onPressed: () { final p = pregnancyWeekArticles.firstWhere((x) => x.week == a.week - 1);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WeekDetailScreen(article: p, currentWeek: widget.currentWeek, daysLeft: widget.daysLeft, percent: widget.percent))); },
              icon: const Icon(Icons.arrow_forward), label: Text('الأسبوع ${a.week - 1}'),
              style: OutlinedButton.styleFrom(foregroundColor: color, padding: const EdgeInsets.symmetric(vertical: 12)))),
            if (a.week > 1 && a.week < 40) const SizedBox(width: 12),
            if (a.week < 40) Expanded(child: ElevatedButton.icon(
              onPressed: () { final n = pregnancyWeekArticles.firstWhere((x) => x.week == a.week + 1);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WeekDetailScreen(article: n, currentWeek: widget.currentWeek, daysLeft: widget.daysLeft, percent: widget.percent))); },
              icon: const Icon(Icons.arrow_back), label: Text('الأسبوع ${a.week + 1}'),
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)))),
          ]),
          const SizedBox(height: 30),
        ]))),
      ])));
  }

  Widget _buildProgress(Color c) {
    final w = widget.currentWeek ?? widget.article.week;
    final d = widget.daysLeft ?? max(0, (40 * 7) - (w * 7));
    final p = widget.percent ?? (w / 40).clamp(0.0, 1.0);
    return Container(width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [c, c.withOpacity(0.7)]), borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: [
        Text('الأسبوع $w', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6), Text('$d يوم متبقي', style: const TextStyle(fontSize: 15, color: Colors.white70)),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: p, backgroundColor: Colors.white30, color: Colors.white, minHeight: 10)),
        const SizedBox(height: 8), Text('${(p * 100).toInt()}% مكتمل', style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]));
  }

  Widget _buildChecklist(Color c) {
    final user = FirebaseAuth.instance.currentUser; if (user == null) return const SizedBox.shrink();
    final mk = DateTime.now().toIso8601String().substring(0, 7);
    final items = [['تناول فيتامينات ما قبل الولادة','vitamins'],['شرب كمية كافية من الماء','water'],['حجز موعد فحص السكر','glucose'],['ممارسة تمارين التنفس','breathing'],['المشي 30 دقيقة','walking']];
    return _card(Icons.checklist, 'قائمة المهام الأسبوعية', c, child: Column(children: items.map((i) {
      final did = '${mk}_${i[1]}';
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('weekly_checklist').doc(did).snapshots(),
        builder: (ctx, snap) {
          bool done = snap.hasData && snap.data!.exists && ((snap.data!.data() as Map<String, dynamic>?)?['done'] ?? false);
          return InkWell(onTap: () => FirebaseFirestore.instance.collection('users').doc(user.uid).collection('weekly_checklist').doc(did).set(
            {'text': i[0], 'done': !done, 'key': i[1], 'updatedAt': FieldValue.serverTimestamp()}),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
              Icon(done ? Icons.check_circle : Icons.circle_outlined, color: done ? Colors.green : Colors.grey, size: 26),
              const SizedBox(width: 10),
              Expanded(child: Text(i[0], style: TextStyle(fontSize: 14, decoration: done ? TextDecoration.lineThrough : null, color: done ? Colors.grey : Colors.black87))),
            ])));
        });
    }).toList()));
  }

  Widget _buildKicks(Color c) {
    return _card(Icons.touch_app, 'عداد حركات الجنين', c, child: Column(children: [
      Text('$_kickCount', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: c)),
      const Text('حركة', style: TextStyle(color: Colors.grey)), const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ElevatedButton.icon(onPressed: () => setState(() => _kickCount++), icon: const Icon(Icons.touch_app), label: const Text('ركلة!'),
          style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white)),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) { final dk = DateTime.now().toIso8601String().substring(0, 10);
            await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('kick_logs').doc(dk).set(
              {'count': _kickCount, 'date': dk, 'updatedAt': FieldValue.serverTimestamp()});
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ $_kickCount حركة'), backgroundColor: c));
          } setState(() => _kickCount = 0);
        }, child: const Text('حفظ وإعادة')),
      ])]));
  }

  Widget _buildEcho(Color c) {
    return Card(elevation: 1.5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF7B1FA2).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.camera_alt, color: Color(0xFF7B1FA2), size: 20)),
          const SizedBox(width: 10),
          const Text('صورة الإيكو / السونار 3D', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2))),
        ]),
        const SizedBox(height: 12),
        if (_loadingEcho) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_echoImage != null) Stack(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_echoImage!, width: double.infinity, height: 220, fit: BoxFit.cover)),
          Positioned(top: 8, left: 8, child: GestureDetector(onTap: _pickEchoImage, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit, color: Colors.white, size: 14), SizedBox(width: 4), Text('تغيير', style: TextStyle(color: Colors.white, fontSize: 12))])))),
        ])
        else GestureDetector(onTap: _pickEchoImage, child: Container(width: double.infinity, height: 150,
          decoration: BoxDecoration(color: const Color(0xFF7B1FA2).withOpacity(0.05), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7B1FA2).withOpacity(0.3), width: 2)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_a_photo, size: 40, color: const Color(0xFF7B1FA2).withOpacity(0.5)),
            const SizedBox(height: 10),
            Text('أضيفي صورة الإيكو أو السونار 3D', style: TextStyle(color: const Color(0xFF7B1FA2).withOpacity(0.7), fontWeight: FontWeight.bold)),
          ]))),
      ])));
  }

  Widget _card(IconData icon, String title, Color c, {required Widget child}) {
    return Card(elevation: 1.5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: c, size: 20)),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c)),
        ]),
        const SizedBox(height: 12), child,
      ])));
  }

  Widget _sz(String l, String v, IconData i) {
    return Column(children: [Icon(i, size: 24, color: Colors.grey.shade500), const SizedBox(height: 6),
      Text(l, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)), const SizedBox(height: 2),
      Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center)]);
  }
}

class RealisticFetusIllustration extends CustomPainter {
  final int week;
  final bool isSmall;
  final bool isOnDark;
  RealisticFetusIllustration({required this.week, this.isSmall = false, this.isOnDark = false});

  static const Color _skinBase = Color(0xFFE8A090);
  static const Color _skinLight = Color(0xFFF2C4B6);
  static const Color _skinDark = Color(0xFFC47A6C);


  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy) * 0.85;
    // Background glow
    if (!isSmall) {
      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(Offset(cx, cy), r * 1.3,
            [const Color(0xFFE8B4B8).withOpacity(0.08), Colors.transparent],
            [0.0, 1.0]);
      canvas.drawCircle(Offset(cx, cy), r * 1.3, glowPaint);
    }
    canvas.save();
    canvas.translate(cx, cy);
    if (week <= 4) {
      _drawEarly(canvas, r);
    } else if (week <= 8) {
      _drawEmbryo(canvas, r);
    } else if (week <= 14) {
      _drawEarlyFetus(canvas, r, _skinLight);
    } else if (week <= 26) {
      _drawMidFetus(canvas, r, _skinLight);
    } else {
      _drawLateFetus(canvas, r, _skinLight);
    }
    canvas.restore();
  }

  void _drawEarly(Canvas canvas, double r) {
    // Cell cluster / blastocyst
    final rng = Random(42);
    for (int i = 0; i < 12; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * r * 0.35;
      final cr = r * (0.1 + rng.nextDouble() * 0.12);
      final p = Paint()
        ..shader = ui.Gradient.radial(
            Offset(cos(angle) * dist - cr * 0.2, sin(angle) * dist - cr * 0.2),
            cr,
            [_skinLight.withOpacity(0.9), _skinBase.withOpacity(0.7)],
            [0.0, 1.0]);
      canvas.drawCircle(Offset(cos(angle) * dist, sin(angle) * dist), cr, p);
    }
    // Outer membrane
    final memb = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _skinDark.withOpacity(0.3);
    canvas.drawCircle(Offset.zero, r * 0.55, memb);
  }

  void _drawEmbryo(Canvas canvas, double r) {
    // C-shaped embryo
    final bodyPath = Path();
    final s = r * 0.6;
    bodyPath.moveTo(0, -s * 0.8);
    bodyPath.cubicTo(s * 0.7, -s * 0.6, s * 0.7, s * 0.3, s * 0.2, s * 0.7);
    bodyPath.cubicTo(s * 0.1, s * 0.8, -s * 0.1, s * 0.8, -s * 0.15, s * 0.6);
    bodyPath.cubicTo(-s * 0.3, s * 0.2, -s * 0.4, -s * 0.3, 0, -s * 0.8);
    bodyPath.close();

    final bodyPaint = Paint()
      ..shader = ui.Gradient.radial(
          Offset(s * 0.1, -s * 0.1), s,
          [_skinLight, _skinBase, _skinDark],
          [0.0, 0.6, 1.0]);
    canvas.drawPath(bodyPath, bodyPaint);

    // Head bump
    final headPaint = Paint()
      ..shader = ui.Gradient.radial(
          Offset(-s * 0.05, -s * 0.7), s * 0.4,
          [_skinLight, _skinBase],
          [0.0, 1.0]);
    canvas.drawCircle(Offset(s * 0.05, -s * 0.65), s * 0.3, headPaint);

    // Eye dot
    final eye = Paint()..color = const Color(0xFF3A2520).withOpacity(0.6);
    canvas.drawCircle(Offset(s * 0.15, -s * 0.7), s * 0.04, eye);
  }

  void _drawEarlyFetus(Canvas canvas, double r, Color light) {
    final s = r * 0.7;
    // Head
    _head(canvas, Offset(0, -s * 0.4), s * 0.35, light);
    // Body
    final bodyPath = Path();
    bodyPath.moveTo(-s * 0.2, -s * 0.1);
    bodyPath.cubicTo(-s * 0.35, s * 0.3, -s * 0.15, s * 0.7, s * 0.05, s * 0.6);
    bodyPath.cubicTo(s * 0.25, s * 0.5, s * 0.35, s * 0.1, s * 0.2, -s * 0.1);
    bodyPath.close();
    final bp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, s * 0.2), s * 0.7,
          [light, _skinBase, _skinDark],
          [0.0, 0.5, 1.0]);
    canvas.drawPath(bodyPath, bp);
    // Limb buds
    final limb = Paint()..color = _skinBase.withOpacity(0.8);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-s * 0.35, s * 0.15), width: s * 0.12, height: s * 0.3), const Radius.circular(6)), limb);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(s * 0.3, s * 0.15), width: s * 0.12, height: s * 0.3), const Radius.circular(6)), limb);
    // Eye
    canvas.drawCircle(Offset(s * 0.08, -s * 0.45), s * 0.035, Paint()..color = const Color(0xFF3A2520).withOpacity(0.7));
    // Cord
    _cord(canvas, Offset(s * 0.05, s * 0.55), s);
  }

  void _drawMidFetus(Canvas canvas, double r, Color light) {
    final s = r * 0.8;
    canvas.save();
    canvas.rotate(-0.3);
    // Head
    _head(canvas, Offset(s * 0.05, -s * 0.45), s * 0.32, light);
    // Body - curled position
    final body = Path();
    body.moveTo(-s * 0.15, -s * 0.15);
    body.cubicTo(-s * 0.3, s * 0.15, -s * 0.25, s * 0.55, 0, s * 0.5);
    body.cubicTo(s * 0.2, s * 0.45, s * 0.3, s * 0.1, s * 0.15, -s * 0.15);
    body.close();
    final bp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, s * 0.1), s * 0.6,
          [light, _skinBase, _skinDark],
          [0.0, 0.5, 1.0]);
    canvas.drawPath(body, bp);
    // Arms
    final armP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(-s * 0.3, 0), Offset(-s * 0.5, s * 0.2),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-s * 0.2, s * 0.0), Offset(-s * 0.35, s * 0.25), armP);
    // Hand
    canvas.drawCircle(Offset(-s * 0.36, s * 0.26), s * 0.05, Paint()..color = _skinBase);
    // Legs curled
    final legP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(0, s * 0.4), Offset(-s * 0.15, s * 0.65),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leg = Path();
    leg.moveTo(-s * 0.05, s * 0.45);
    leg.cubicTo(-s * 0.2, s * 0.6, -s * 0.3, s * 0.5, -s * 0.25, s * 0.35);
    canvas.drawPath(leg, legP);
    // Foot
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.25, s * 0.34), width: s * 0.1, height: s * 0.06),
        Paint()..color = _skinBase);
    // Eye
    canvas.drawCircle(Offset(s * 0.15, -s * 0.5), s * 0.03, Paint()..color = const Color(0xFF3A2520).withOpacity(0.8));
    // Ear
    canvas.drawArc(Rect.fromCenter(center: Offset(-s * 0.08, -s * 0.42), width: s * 0.1, height: s * 0.12),
        0.5, 2.5, false, Paint()..color = _skinDark.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Nose
    canvas.drawCircle(Offset(s * 0.2, -s * 0.43), s * 0.025, Paint()..color = _skinDark.withOpacity(0.5));
    // Cord
    _cord(canvas, Offset(s * 0.05, s * 0.5), s);
    canvas.restore();
  }

  void _drawLateFetus(Canvas canvas, double r, Color light) {
    final s = r * 0.85;
    canvas.save();
    canvas.rotate(-0.25);
    // Head - larger
    _head(canvas, Offset(s * 0.05, -s * 0.42), s * 0.35, light);
    // Body - fully curled
    final body = Path();
    body.moveTo(-s * 0.18, -s * 0.1);
    body.cubicTo(-s * 0.35, s * 0.2, -s * 0.3, s * 0.55, 0, s * 0.52);
    body.cubicTo(s * 0.25, s * 0.48, s * 0.35, s * 0.15, s * 0.18, -s * 0.1);
    body.close();
    final bp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, s * 0.15), s * 0.6,
          [light, _skinBase, _skinDark],
          [0.0, 0.45, 1.0]);
    canvas.drawPath(body, bp);
    // Belly highlight
    final bellyGlow = Paint()
      ..shader = ui.Gradient.radial(
          Offset(s * 0.05, s * 0.2), s * 0.2,
          [light.withOpacity(0.5), Colors.transparent],
          [0.0, 1.0]);
    canvas.drawCircle(Offset(s * 0.05, s * 0.2), s * 0.2, bellyGlow);
    // Arms crossed
    final armP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(-s * 0.2, s * 0.05), Offset(s * 0.1, s * 0.15),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arm1 = Path();
    arm1.moveTo(-s * 0.2, s * 0.05);
    arm1.cubicTo(-s * 0.15, s * 0.15, -s * 0.05, s * 0.18, s * 0.05, s * 0.1);
    canvas.drawPath(arm1, armP);
    // Hand near face
    canvas.drawCircle(Offset(s * 0.06, s * 0.09), s * 0.05, Paint()..color = _skinBase);
    // Fingers hint
    for (int i = 0; i < 4; i++) {
      final fa = -0.4 + i * 0.25;
      canvas.drawLine(
          Offset(s * 0.06 + cos(fa) * s * 0.05, s * 0.09 + sin(fa) * s * 0.05),
          Offset(s * 0.06 + cos(fa) * s * 0.08, s * 0.09 + sin(fa) * s * 0.08),
          Paint()..color = _skinDark.withOpacity(0.3)..strokeWidth = 1.0..strokeCap = StrokeCap.round);
    }
    // Legs tucked
    final legP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(-s * 0.05, s * 0.45), Offset(-s * 0.25, s * 0.2),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leg1 = Path();
    leg1.moveTo(-s * 0.05, s * 0.48);
    leg1.cubicTo(-s * 0.2, s * 0.55, -s * 0.35, s * 0.45, -s * 0.3, s * 0.3);
    canvas.drawPath(leg1, legP);
    final leg2 = Path();
    leg2.moveTo(s * 0.1, s * 0.48);
    leg2.cubicTo(-s * 0.05, s * 0.6, -s * 0.2, s * 0.55, -s * 0.2, s * 0.4);
    canvas.drawPath(leg2, legP);
    // Feet
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.3, s * 0.29), width: s * 0.11, height: s * 0.07),
        Paint()..color = _skinBase);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.2, s * 0.39), width: s * 0.11, height: s * 0.07),
        Paint()..color = _skinBase);
    // Face details
    // Eyes closed (sleeping)
    final eyeP = Paint()..color = const Color(0xFF3A2520).withOpacity(0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(s * 0.14, -s * 0.47), width: s * 0.08, height: s * 0.04), 0, pi, false, eyeP);
    // Nose
    final nosePath = Path();
    nosePath.moveTo(s * 0.2, -s * 0.44);
    nosePath.cubicTo(s * 0.24, -s * 0.42, s * 0.24, -s * 0.38, s * 0.2, -s * 0.37);
    canvas.drawPath(nosePath, Paint()..color = _skinDark.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    // Mouth
    canvas.drawArc(Rect.fromCenter(center: Offset(s * 0.16, -s * 0.33), width: s * 0.08, height: s * 0.04),
        0.2, 2.2, false, Paint()..color = const Color(0xFFBF7E7E).withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    // Ear
    final earPath = Path();
    earPath.moveTo(-s * 0.05, -s * 0.42);
    earPath.cubicTo(-s * 0.12, -s * 0.48, -s * 0.14, -s * 0.38, -s * 0.08, -s * 0.35);
    canvas.drawPath(earPath, Paint()..color = _skinDark.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.8);
    // Hair wisps (for late weeks)
    if (week >= 32) {
      final hairP = Paint()..color = const Color(0xFF5D4037).withOpacity(0.3)..strokeWidth = 1.0..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final a = -1.8 + i * 0.3;
        canvas.drawLine(
            Offset(s * 0.05 + cos(a) * s * 0.33, -s * 0.42 + sin(a) * s * 0.33),
            Offset(s * 0.05 + cos(a) * s * 0.4, -s * 0.42 + sin(a) * s * 0.4),
            hairP);
      }
    }
    // Cord
    _cord(canvas, Offset(s * 0.05, s * 0.52), s);
    canvas.restore();
  }

  void _head(Canvas canvas, Offset center, double radius, Color light) {
    final hp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(center.dx - radius * 0.15, center.dy - radius * 0.15), radius,
          [light, _skinBase, _skinDark],
          [0.0, 0.6, 1.0]);
    canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 2.15), hp);
    // Highlight
    final hl = Paint()
      ..shader = ui.Gradient.radial(
          Offset(center.dx - radius * 0.2, center.dy - radius * 0.3), radius * 0.5,
          [light.withOpacity(0.6), Colors.transparent],
          [0.0, 1.0]);
    canvas.drawCircle(Offset(center.dx - radius * 0.15, center.dy - radius * 0.2), radius * 0.5, hl);
  }

  void _cord(Canvas canvas, Offset start, double s) {
    final cordPath = Path();
    cordPath.moveTo(start.dx, start.dy);
    cordPath.cubicTo(start.dx + s * 0.15, start.dy + s * 0.15, start.dx - s * 0.1, start.dy + s * 0.3,
        start.dx + s * 0.2, start.dy + s * 0.35);
    final cordPaint = Paint()
      ..shader = ui.Gradient.linear(
          start, Offset(start.dx + s * 0.2, start.dy + s * 0.35),
          [_skinDark.withOpacity(0.6), const Color(0xFF8B6F6F).withOpacity(0.3)],
          [0.0, 1.0])
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(cordPath, cordPaint);
  }

  @override
  bool shouldRepaint(covariant RealisticFetusIllustration old) => old.week != week;
}
                                                   