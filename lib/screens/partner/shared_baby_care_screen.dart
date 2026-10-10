import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/partner_service.dart';

/// ═══════════════════════════════════════════════════════════════════
///  العناية بالطفل — مشتركة بين الزوجين بتزامن لحظي حقيقي
///
///  المصدر: couples/{id}/baby_logs/{yyyy-MM-dd}
///  الطرفان يقرآن ويكتبان على نفس الوثيقة عبر `FieldValue.increment`،
///  فلا تضيع تسجيلة إن سجّل الاثنان في نفس اللحظة (عكس set المباشر).
/// ═══════════════════════════════════════════════════════════════════
class SharedBabyCareScreen extends StatefulWidget {
  final String coupleId;

  /// لتخصيص صياغة التنبيه المرسل للطرف الآخر
  final bool isMother;

  const SharedBabyCareScreen({
    super.key,
    required this.coupleId,
    required this.isMother,
  });

  @override
  State<SharedBabyCareScreen> createState() => _SharedBabyCareScreenState();
}

const _pink = Color(0xFFE0195B);
const _lav = Color(0xFF9B6FE1);
const _teal = Color(0xFF00897B);
const _ink = Color(0xFF1F1A20);
const _ink3 = Color(0xFF9B8F95);
const _bg = Color(0xFFF7FAFC);

class _SharedBabyCareScreenState extends State<SharedBabyCareScreen> {
  static const _metrics = [
    ('feeding', 'رضعة', '🍼', _pink),
    ('sleep', 'ساعة نوم', '😴', _lav),
    ('diaper', 'حفاض', '👶', _teal),
  ];

  static const _dayNames = ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];

  int _selected = 0;
  bool _busy = false;

  String get _key => _metrics[_selected].$1;
  Color get _color => _metrics[_selected].$4;

  List<DateTime> get _days {
    final t = DateTime.now();
    return List.generate(7, (i) => DateTime(t.year, t.month, t.day - (6 - i)));
  }

  Future<void> _bump(int delta) async {
    if (_busy) return;
    setState(() => _busy = true);
    final m = _metrics[_selected];
    await PartnerService.bumpBabyLog(_key, by: delta);
    if (delta > 0) {
      final who = widget.isMother ? 'زوجتك' : 'زوجك';
      await PartnerService.notify(
        type: 'baby_log',
        title: 'سجّل $who ${m.$2}',
        body: 'تم تسجيل ${m.$2} جديدة اليوم ${m.$3}',
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: _ink,
          title: const Text('العناية بالطفل',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: PartnerService.coupleBabyLogs(widget.coupleId)
              .orderBy(FieldPath.documentId, descending: true)
              .limit(14)
              .snapshots(),
          builder: (context, snap) {
            final byDate = <String, Map<String, dynamic>>{};
            for (final d in snap.data?.docs ?? []) {
              byDate[d.id] = d.data();
            }

            final values = _days
                .map((d) =>
                    (byDate[PartnerService.dateKey(d)]?[_key] as num?)?.toInt() ??
                    0)
                .toList();
            final todayV = values.last;
            final yesterdayV = values[values.length - 2];
            final maxV = values.reduce((a, b) => a > b ? a : b);
            final total = values.fold<int>(0, (a, b) => a + b);
            final lastBy =
                byDate[PartnerService.dateKey(DateTime.now())]?['updatedBy'];

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                _syncBanner(lastBy as String?),
                const SizedBox(height: 14),
                _picker(),
                const SizedBox(height: 18),
                _counter(todayV, todayV - yesterdayV),
                const SizedBox(height: 18),
                _chart(values, maxV),
                const SizedBox(height: 16),
                _summary(todayV, total, values.length),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _syncBanner(String? lastBy) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final byOther = lastBy != null && lastBy != me;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (byOther ? _teal : _ink3).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(byOther ? Icons.sync : Icons.sync_alt,
            size: 18, color: byOther ? _teal : _ink3),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            byOther
                ? 'آخر تسجيل اليوم من ${widget.isMother ? "زوجك" : "زوجتك"} — يظهر عندكما فوراً'
                : 'كل ما تُسجّله يظهر عند ${widget.isMother ? "زوجك" : "زوجتك"} فوراً',
            style: TextStyle(
                fontSize: 12, height: 1.5, color: byOther ? _teal : _ink3),
          ),
        ),
      ]),
    );
  }

  Widget _picker() => Row(
        children: List.generate(_metrics.length, (i) {
          final on = i == _selected;
          final m = _metrics[i];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(left: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: on ? m.$4.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: on ? m.$4.withOpacity(0.45) : const Color(0xFFE6EDF2)),
                ),
                child: Column(children: [
                  Text(m.$3, style: const TextStyle(fontSize: 19)),
                  const SizedBox(height: 4),
                  Text(m.$2,
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: on ? m.$4 : _ink3)),
                ]),
              ),
            ),
          );
        }),
      );

  Widget _counter(int today, int diff) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE6EDF2)),
        ),
        child: Column(children: [
          const Text('اليوم',
              style: TextStyle(fontSize: 12.5, color: _ink3)),
          const SizedBox(height: 8),
          Text('$today',
              style: TextStyle(
                  fontSize: 46, fontWeight: FontWeight.w900, color: _color)),
          if (diff != 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (diff > 0 ? _teal : _pink).withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${diff > 0 ? "↑" : "↓"} ${diff.abs()} عن أمس',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: diff > 0 ? _teal : _pink),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _roundBtn(Icons.remove, _ink3, today > 0 ? () => _bump(-1) : null),
            const SizedBox(width: 30),
            _roundBtn(Icons.add, _color, () => _bump(1), big: true),
          ]),
        ]),
      );

  Widget _roundBtn(IconData i, Color c, VoidCallback? onTap, {bool big = false}) =>
      InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Opacity(
          opacity: onTap == null ? 0.35 : 1,
          child: Container(
            width: big ? 68 : 52,
            height: big ? 68 : 52,
            decoration: BoxDecoration(
              color: big ? c : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: c.withOpacity(big ? 1 : 0.35), width: 2),
            ),
            child: Icon(i,
                color: big ? Colors.white : c, size: big ? 32 : 24),
          ),
        ),
      );

  Widget _chart(List<int> values, int maxV) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE6EDF2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('آخر 7 أيام',
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = values[i];
                final h = maxV == 0 ? 0.0 : (v / maxV) * 66.0;
                final isToday = i == 6;
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(v == 0 ? '' : '$v',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isToday ? _color : _ink3)),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: h < 4 && v > 0 ? 4 : h,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: _color.withOpacity(isToday ? 1 : 0.28),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_dayNames[_days[i].weekday - 1],
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w500,
                              color: isToday ? _ink : _ink3)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ]),
      );

  Widget _summary(int today, int total, int days) => Row(children: [
        _stat('اليوم', '$today'),
        _div(),
        _stat('المتوسّط', (total / days).toStringAsFixed(1)),
        _div(),
        _stat('الإجمالي', '$total'),
      ]);

  Widget _div() => Container(width: 1, height: 28, color: const Color(0xFFE6EDF2));

  Widget _stat(String label, String value) => Expanded(
        child: Column(children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _ink3)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: _color)),
        ]),
      );
}
