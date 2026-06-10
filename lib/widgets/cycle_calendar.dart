import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// تقويم الدورة التفاعلي: يعرض أيام الحيض 🩸/الخصوبة 🌱/الإباضة 🥚 (متوقّعة)،
/// ويسمح بتسجيل الحيض الفعلي واضطرابات الدورة ⚠️ وكل الفئات الطبية الهامة في cycle_logs.
class CycleCalendarCard extends StatefulWidget {
  const CycleCalendarCard({Key? key}) : super(key: key);
  @override
  State<CycleCalendarCard> createState() => _CycleCalendarCardState();
}

class _CycleCalendarCardState extends State<CycleCalendarCard> {
  late DateTime _month;
  static const _arMonths = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
      'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
  static const _week = ['سبت','أحد','إثن','ثلا','أرب','خمي','جمع'];

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month, 1);
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DocumentReference get _userDoc => FirebaseFirestore.instance
      .collection('users').doc(FirebaseAuth.instance.currentUser!.uid);
  CollectionReference get _logs => _userDoc.collection('cycle_logs');

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: _userDoc.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        final ts = d['lastPeriodStart'];
        final lp = ts is Timestamp ? ts.toDate() : null;
        final cycleLen = (d['cycleLength'] as num?)?.toInt() ?? 28;
        final luteal = (d['lutealPhase'] as num?)?.toInt() ?? 14;
        final periodLen = ((d['cycleProfile'] as Map?)?['periodLength'] as num?)?.toInt() ?? 5;
        final mStart = DateTime(_month.year, _month.month, 1);
        final mEnd = DateTime(_month.year, _month.month + 1, 0);
        return StreamBuilder<QuerySnapshot>(
          stream: _logs
              .where('date', isGreaterThanOrEqualTo: _key(mStart))
              .where('date', isLessThanOrEqualTo: _key(mEnd))
              .snapshots(),
          builder: (context, ls) {
            final logs = <String, Map<String, dynamic>>{};
            if (ls.hasData) {
              for (final doc in ls.data!.docs) {
                final m = doc.data() as Map<String, dynamic>;
                if (m['date'] is String) logs[m['date'] as String] = m;
              }
            }
            return Directionality(
              textDirection: TextDirection.rtl,
              child: _card(lp, cycleLen, luteal, periodLen, logs),
            );
          },
        );
      },
    );
  }

  String _predict(DateTime day, DateTime? lp, int cycleLen, int luteal, int periodLen) {
    if (lp == null) return 'none';
    final d0 = DateTime(day.year, day.month, day.day);
    final lp0 = DateTime(lp.year, lp.month, lp.day);
    int pos = d0.difference(lp0).inDays % cycleLen;
    if (pos < 0) pos += cycleLen;
    final ov = cycleLen - luteal;
    if (pos == ov) return 'ovulation';
    if (pos < periodLen) return 'period';
    if (pos >= ov - 5 && pos <= ov + 1) return 'fertile';
    return 'normal';
  }

  Widget _card(DateTime? lp, int cycleLen, int luteal, int periodLen,
      Map<String, Map<String, dynamic>> logs) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstCol = (_month.weekday + 1) % 7;
    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    final cells = <Widget>[];
    for (int i = 0; i < firstCol; i++) cells.add(const SizedBox());
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final log = logs[_key(date)];
      cells.add(_cell(day, _predict(date, lp, cycleLen, luteal, periodLen),
          log, date == today0, () => _editDay(date, log)));
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_right, color: Color(0xFFE53B7E)),
            onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1))),
          Text('${_arMonths[_month.month - 1]} ${_month.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B1320))),
          IconButton(icon: const Icon(Icons.chevron_left, color: Color(0xFFE53B7E)),
            onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1))),
        ]),
        Row(children: _week.map((w) => Expanded(child: Center(child: Text(w,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8E8295)))))).toList()),
        const SizedBox(height: 6),
        GridView.count(crossAxisCount: 7, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), childAspectRatio: 0.85, children: cells),
        const SizedBox(height: 8),
        const Text('اضغطي على أي يوم لتسجيل الحيض أو تفاصيل الدورة 📝',
          style: TextStyle(fontSize: 11, color: Color(0xFF8E8295))),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 6, children: const [
          _Legend(emoji: '🩸', label: 'حيض', color: Color(0xFFFF5A8A)),
          _Legend(emoji: '🌱', label: 'خصوبة', color: Color(0xFF66BB6A)),
          _Legend(emoji: '🥚', label: 'إباضة', color: Color(0xFF9C27B0)),
          _Legend(emoji: '⚠️', label: 'اضطراب', color: Color(0xFFFF9800)),
        ]),
      ]),
    );
  }

  Widget _cell(int day, String predicted, Map<String, dynamic>? log, bool isToday, VoidCallback onTap) {
    final actualPeriod = log?['isPeriod'] == true;
    final irr = log?['irregularity'];
    final irregular = irr != null && irr != '' && irr != 'none';
    final hasNote = log != null && (
      (log['note']?.toString().isNotEmpty ?? false) ||
      (log['flow'] != null && log['flow'] != '') ||
      (log['mood'] != null && log['mood'] != '') ||
      (log['bloodColor'] != null && log['bloodColor'] != '') ||
      (log['cramps'] != null && log['cramps'] != '') ||
      (log['mucus'] != null && log['mucus'] != '') ||
      (log['pregnancyTest'] != null && log['pregnancyTest'] != '' && log['pregnancyTest'] != 'none') ||
      (log['bbt'] != null) || (log['weight'] != null) ||
      ((log['symptoms'] as List?)?.isNotEmpty ?? false));
    Color? bg;
    String emoji = '';
    if (actualPeriod) { bg = const Color(0xFFFF5A8A); emoji = '🩸'; }
    else if (predicted == 'ovulation') { bg = const Color(0xFF9C27B0); emoji = '🥚'; }
    else if (predicted == 'fertile') { bg = const Color(0xFF66BB6A); emoji = '🌱'; }
    else if (predicted == 'period') { bg = const Color(0xFFFF5A8A); }
    final borderColor = isToday
        ? const Color(0xFF15B8A6)
        : (irregular ? const Color(0xFFFF9800) : Colors.transparent);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg == null ? null : bg.withValues(alpha: actualPeriod ? 0.32 : 0.15),
          shape: BoxShape.circle,
          border: (isToday || irregular) ? Border.all(color: borderColor, width: 2) : null,
        ),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$day', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
            color: bg ?? const Color(0xFF4A3F4F))),
          if (irregular) const Text('⚠️', style: TextStyle(fontSize: 8))
          else if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 8))
          else if (hasNote) Container(width: 5, height: 5,
            decoration: const BoxDecoration(color: Color(0xFF15B8A6), shape: BoxShape.circle)),
        ])),
      ),
    );
  }

  void _editDay(DateTime date, Map<String, dynamic>? existing) {
    bool isPeriod = existing?['isPeriod'] == true;
    String flow = (existing?['flow'] as String?) ?? '';
    String color = (existing?['bloodColor'] as String?) ?? '';
    String cramps = (existing?['cramps'] as String?) ?? '';
    String mucus = (existing?['mucus'] as String?) ?? '';
    String mood = (existing?['mood'] as String?) ?? '';
    String sex = (existing?['sex'] as String?) ?? '';
    String preg = (existing?['pregnancyTest'] as String?) ?? '';
    String irr = (existing?['irregularity'] as String?) ?? 'none';
    final Set<String> symptoms =
        ((existing?['symptoms'] as List?)?.map((e) => e.toString()).toSet()) ?? <String>{};
    final noteC = TextEditingController(text: (existing?['note'] as String?) ?? '');
    final bbtC = TextEditingController(text: existing?['bbt'] != null ? '${existing!['bbt']}' : '');
    final weightC = TextEditingController(text: existing?['weight'] != null ? '${existing!['weight']}' : '');

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        Widget single(String emoji, String label, String cur, String key, void Function(String) set) =>
            _eChip(emoji, label, cur == key, () => setS(() => set(key)));
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(left: 18, right: 18, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Text('${date.day} ${_arMonths[date.month - 1]} ${date.year}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B1320)))),
              const SizedBox(height: 6),
              SwitchListTile(contentPadding: EdgeInsets.zero, activeColor: const Color(0xFFFF5A8A),
                title: const Text('تسجيل الحيض 🩸', style: TextStyle(fontWeight: FontWeight.w700)),
                value: isPeriod, onChanged: (v) => setS(() => isPeriod = v)),

              if (isPeriod) ...[
                _secLabel('شدّة النزيف'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  single('💧', 'خفيف', flow, 'light', (k) => flow = k),
                  single('🩸', 'متوسط', flow, 'medium', (k) => flow = k),
                  single('🔴', 'غزير', flow, 'heavy', (k) => flow = k),
                ]),
                _secLabel('لون الدم'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  single('🌸', 'وردي فاتح', color, 'light', (k) => color = k),
                  single('❤️', 'أحمر فاتح', color, 'bright', (k) => color = k),
                  single('🍷', 'أحمر داكن', color, 'dark', (k) => color = k),
                  single('🟤', 'بنّي', color, 'brown', (k) => color = k),
                  single('⚫', 'أسود', color, 'black', (k) => color = k),
                ]),
                _secLabel('التقلّصات'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  single('🙂', 'لا ألم', cramps, 'none', (k) => cramps = k),
                  single('🙁', 'خفيفة', cramps, 'mild', (k) => cramps = k),
                  single('😣', 'شديدة', cramps, 'severe', (k) => cramps = k),
                  single('😖', 'قوية', cramps, 'intense', (k) => cramps = k),
                  single('😩', 'مُعجِزة', cramps, 'debilitating', (k) => cramps = k),
                ]),
              ],

              _secLabel('مخاط عنق الرحم'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                single('🌵', 'جاف', mucus, 'dry', (k) => mucus = k),
                single('💧', 'كريمي', mucus, 'creamy', (k) => mucus = k),
                single('🥚', 'مطّاطي', mucus, 'eggwhite', (k) => mucus = k),
                single('☁️', 'متكتّل', mucus, 'clumpy', (k) => mucus = k),
                single('🫧', 'رغوي', mucus, 'foamy', (k) => mucus = k),
                single('💛', 'مصفرّ', mucus, 'yellow', (k) => mucus = k),
                single('🩸', 'دموي', mucus, 'bloody', (k) => mucus = k),
              ]),

              _secLabel('المزاج'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                single('😌', 'هادئة', mood, 'calm', (k) => mood = k),
                single('😊', 'سعيدة', mood, 'happy', (k) => mood = k),
                single('🤩', 'متحمّسة', mood, 'excited', (k) => mood = k),
                single('😢', 'حزينة', mood, 'sad', (k) => mood = k),
                single('😠', 'غاضبة', mood, 'angry', (k) => mood = k),
              ]),

              _secLabel('الأعراض'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in const [
                  ['🎈', 'انتفاخ', 'bloating'], ['🤕', 'صداع', 'headache'],
                  ['💢', 'ألم الثدي', 'breast'], ['🪨', 'ألم الظهر', 'back'],
                  ['😴', 'إرهاق', 'fatigue'], ['🌙', 'أرق', 'insomnia'],
                  ['🤢', 'غثيان', 'nausea'], ['🔴', 'حبّ الشباب', 'acne'],
                  ['🍫', 'اشتهاء طعام', 'cravings'], ['🎭', 'تقلّب مزاج', 'moodswing'],
                ])
                  _eChip(s[0], s[1], symptoms.contains(s[2]),
                    () => setS(() => symptoms.contains(s[2]) ? symptoms.remove(s[2]) : symptoms.add(s[2]))),
              ]),

              _secLabel('العلاقة الزوجية'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                single('🚫', 'لا', sex, 'none', (k) => sex = k),
                single('❤️', 'بلا حماية', sex, 'unprotected', (k) => sex = k),
                single('🛡️', 'واقٍ', sex, 'condom', (k) => sex = k),
                single('💊', 'حبوب منع', sex, 'pills', (k) => sex = k),
                single('🔵', 'وسيلة أخرى', sex, 'other', (k) => sex = k),
              ]),

              _secLabel('اختبار الحمل'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                single('⬜', 'لم يُجرَ', preg, 'none', (k) => preg = k),
                single('➖', 'سلبي', preg, 'negative', (k) => preg = k),
                single('〰️', 'خط باهت', preg, 'faint', (k) => preg = k),
                single('➕', 'إيجابي', preg, 'positive', (k) => preg = k),
              ]),

              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(controller: bbtC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'حرارة الجسم °م', isDense: true,
                    filled: true, fillColor: const Color(0xFFFFF1F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: weightC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'الوزن كغ', isDense: true,
                    filled: true, fillColor: const Color(0xFFFFF1F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))),
              ]),

              _secLabel('اضطراب'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                single('✅', 'لا شيء', irr, 'none', (k) => irr = k),
                single('⏰', 'تأخّر', irr, 'late', (k) => irr = k),
                single('⚡', 'تبكير', irr, 'early', (k) => irr = k),
                single('🩸', 'نزيف غزير', irr, 'heavy_bleed', (k) => irr = k),
                single('💧', 'تنقيط', irr, 'spotting', (k) => irr = k),
                single('😖', 'ألم شديد', irr, 'pain', (k) => irr = k),
                single('🚷', 'غياب الدورة', irr, 'missed', (k) => irr = k),
              ]),

              const SizedBox(height: 12),
              TextField(controller: noteC, maxLines: 2,
                decoration: InputDecoration(hintText: 'ملاحظة (اختياري) 📝', filled: true, fillColor: const Color(0xFFFFF1F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53B7E), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  final bbt = double.tryParse(bbtC.text.trim());
                  final weight = double.tryParse(weightC.text.trim());
                  await _logs.doc(_key(date)).set({
                    'date': _key(date), 'isPeriod': isPeriod, 'flow': flow,
                    'bloodColor': color, 'cramps': cramps, 'mucus': mucus, 'mood': mood,
                    'sex': sex, 'pregnancyTest': preg, 'irregularity': irr,
                    'symptoms': symptoms.toList(), 'note': noteC.text.trim(),
                    if (bbt != null) 'bbt': bbt,
                    if (weight != null) 'weight': weight,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))),
              const SizedBox(height: 8),
              Center(child: TextButton(
                onPressed: () async {
                  await _userDoc.set({'lastPeriodStart': Timestamp.fromDate(DateTime(date.year, date.month, date.day))}, SetOptions(merge: true));
                  await _logs.doc(_key(date)).set({'date': _key(date), 'isPeriod': true, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('🔄 تعيين كبداية دورة جديدة', style: TextStyle(color: Color(0xFFE53B7E), fontWeight: FontWeight.w700)))),
            ])),
          ),
        );
      }),
    );
  }

  Widget _secLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4A3F4F))),
  );

  Widget _eChip(String emoji, String label, bool sel, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: sel ? const Color(0xFFE53B7E) : const Color(0xFFFFF1F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? const Color(0xFFE53B7E) : const Color(0xFFF0E6EE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
            color: sel ? Colors.white : const Color(0xFF4A3F4F))),
        ],
      ),
    ),
  );

  Widget _chip(String label, bool sel, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: sel ? const Color(0xFFE53B7E) : const Color(0xFFFFF1F6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? const Color(0xFFE53B7E) : const Color(0xFFF0E6EE)),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: sel ? Colors.white : const Color(0xFF4A3F4F))),
    ),
  );
}

class _Legend extends StatelessWidget {
  final String emoji, label;
  final Color color;
  const _Legend({required this.emoji, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(emoji, style: const TextStyle(fontSize: 12)),
    const SizedBox(width: 4),
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color.withValues(alpha: 0.6), shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4A3F4F))),
  ]);
}
