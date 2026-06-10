import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// تقويم الدورة التفاعلي: يعرض أيام الحيض 🩸/الخصوبة 🌱/الإباضة 🥚 (متوقّعة)،
/// ويسمح بتسجيل الحيض الفعلي واضطرابات الدورة ⚠️ لكل يوم في cycle_logs.
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
        const Text('اضغطي على أي يوم لتسجيل الحيض أو اضطراب 📝',
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
    final hasNote = log != null &&
        ((log['note']?.toString().isNotEmpty ?? false) ||
         (log['flow'] != null && log['flow'] != '') ||
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
    String flow = (existing?['flow'] as String?) ?? 'medium';
    String irr = (existing?['irregularity'] as String?) ?? 'none';
    final noteC = TextEditingController(text: (existing?['note'] as String?) ?? '');
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Text('${date.day} ${_arMonths[date.month - 1]} ${date.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1B1320)))),
            const SizedBox(height: 10),
            SwitchListTile(contentPadding: EdgeInsets.zero, activeColor: const Color(0xFFFF5A8A),
              title: const Text('تسجيل الحيض في هذا اليوم 🩸', style: TextStyle(fontWeight: FontWeight.w700)),
              value: isPeriod, onChanged: (v) => setS(() => isPeriod = v)),
            if (isPeriod) ...[
              const Padding(padding: EdgeInsets.only(top: 2, bottom: 6),
                child: Text('شدّة النزيف', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4A3F4F)))),
              Wrap(spacing: 8, children: [
                _chip('خفيف', flow == 'light', () => setS(() => flow = 'light')),
                _chip('متوسط', flow == 'medium', () => setS(() => flow = 'medium')),
                _chip('غزير', flow == 'heavy', () => setS(() => flow = 'heavy')),
              ]),
            ],
            const Padding(padding: EdgeInsets.only(top: 14, bottom: 6),
              child: Text('اضطراب أو ملاحظة', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4A3F4F)))),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('لا شيء', irr == 'none', () => setS(() => irr = 'none')),
              _chip('تأخّر', irr == 'late', () => setS(() => irr = 'late')),
              _chip('تبكير', irr == 'early', () => setS(() => irr = 'early')),
              _chip('نزيف غزير', irr == 'heavy_bleed', () => setS(() => irr = 'heavy_bleed')),
              _chip('تنقيط', irr == 'spotting', () => setS(() => irr = 'spotting')),
              _chip('ألم شديد', irr == 'pain', () => setS(() => irr = 'pain')),
              _chip('غياب الدورة', irr == 'missed', () => setS(() => irr = 'missed')),
            ]),
            const SizedBox(height: 12),
            TextField(controller: noteC, maxLines: 2,
              decoration: InputDecoration(hintText: 'ملاحظة (اختياري)', filled: true, fillColor: const Color(0xFFFFF1F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53B7E), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: () async {
                await _logs.doc(_key(date)).set({
                  'date': _key(date), 'isPeriod': isPeriod,
                  'flow': isPeriod ? flow : FieldValue.delete(),
                  'irregularity': irr, 'note': noteC.text.trim(),
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
      )),
    );
  }

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
