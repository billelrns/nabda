import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/baby_names_database.dart';
import '../baby_names/baby_names_screen.dart' show BabyName;

/// ═══════════════════════════════════════════════════════════════════
///  اختيار الاسم بالتوافق بين الزوجين
///
///  كلٌّ يمرّر الأسماء بإعجاب أو تخطٍّ **دون أن يرى اختيار الآخر**،
///  وعند إعجاب الاثنين بنفس الاسم يظهر «تطابق 💗».
///  (نمط BumpSync — أقوى ميزة تعاونية في التطبيقات المنافسة،
///   وغير موجودة في أي تطبيق عربي.)
///
///  المسار: couples/{id}/names/{اسم}
///  الوثيقة: { name, gender, meaning, motherLike, partnerLike }
/// ═══════════════════════════════════════════════════════════════════
class NameMatchScreen extends StatefulWidget {
  final String coupleId;

  /// `true` إن كانت الزوجة هي المستخدِمة، `false` للزوج.
  final bool isMother;

  const NameMatchScreen({
    super.key,
    required this.coupleId,
    required this.isMother,
  });

  @override
  State<NameMatchScreen> createState() => _NameMatchScreenState();
}

const _pink = Color(0xFFE0195B);
const _teal = Color(0xFF00897B);
const _ink = Color(0xFF1F1A20);
const _ink3 = Color(0xFF9B8F95);
const _bg = Color(0xFFFFF8FB);

class _NameMatchScreenState extends State<NameMatchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  String _gender = 'female';
  List<BabyName> _deck = [];
  int _i = 0;
  bool _loading = true;

  /// الأسماء التي حكم عليها هذا المستخدم مسبقاً (لا تُعاد)
  final Set<String> _judged = {};

  String get _myField => widget.isMother ? 'motherLike' : 'partnerLike';
  // لا حاجة لحقل الطرف الآخر: استعلام التطابق يُثبّت `motherLike` في
  // الخادم ثم يُرشّح `partnerLike` محلياً، وهو صحيح للدورين معاً.

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('couples')
      .doc(widget.coupleId)
      .collection('names');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
    _loadDeck();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadDeck() async {
    setState(() => _loading = true);
    try {
      final snap = await _col.get();
      _judged
        ..clear()
        ..addAll(snap.docs
            .where((d) => d.data()[_myField] != null)
            .map((d) => d.id));
    } catch (_) {/* نكمل بما لدينا */}

    final pool = babyNamesDatabase
        .where((n) => n.gender == _gender && !_judged.contains(n.name))
        .toList()
      ..sort((a, b) => a.popularityRank.compareTo(b.popularityRank));

    if (!mounted) return;
    setState(() {
      _deck = pool.take(120).toList();
      _i = 0;
      _loading = false;
    });
  }

  Future<void> _judge(BabyName n, bool like) async {
    setState(() => _i++);
    _judged.add(n.name);
    try {
      await _col.doc(n.name).set({
        'name': n.name,
        'gender': n.gender,
        'meaning': n.meaning,
        'isIslamic': n.isIslamic,
        _myField: like,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذّر الحفظ — تحقّق من الاتصال'),
            behavior: SnackBarBehavior.floating));
      }
    }
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
          title: const Text('اسم طفلنا',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          bottom: TabBar(
            controller: _tab,
            labelColor: _pink,
            unselectedLabelColor: _ink3,
            indicatorColor: _pink,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            tabs: const [
              Tab(text: 'اختر'),
              Tab(text: '💗 المتّفق عليها'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [_pickTab(), _matchesTab()],
        ),
      ),
    );
  }

  // ── تبويب الاختيار ───────────────────────────────────────────
  Widget _pickTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Column(children: [
      const SizedBox(height: 14),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'female', label: Text('بنت'), icon: Text('👧')),
          ButtonSegment(value: 'male', label: Text('ولد'), icon: Text('👦')),
        ],
        selected: {_gender},
        onSelectionChanged: (s) {
          _gender = s.first;
          _loadDeck();
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: _pink.withOpacity(0.12),
          selectedForegroundColor: _pink,
        ),
      ),
      Expanded(
        child: _i >= _deck.length
            ? _deckDone()
            : Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                child: _card(_deck[_i]),
              ),
      ),
      if (_i < _deck.length) _buttons(_deck[_i]),
      const SizedBox(height: 22),
    ]);
  }

  Widget _card(BabyName n) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Spacer(),
          Text(n.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.w900, color: _ink)),
          if (n.isIslamic) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('قرآني',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _teal)),
            ),
          ],
          const SizedBox(height: 20),
          Text(n.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, height: 1.9, color: _ink3)),
          const Spacer(),
          Text('${_i + 1} / ${_deck.length}',
              style: const TextStyle(fontSize: 11.5, color: _ink3)),
        ]),
      );

  Widget _buttons(BabyName n) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circleBtn(Icons.close, const Color(0xFF9E9E9E), () => _judge(n, false)),
          const SizedBox(width: 44),
          _circleBtn(Icons.favorite, _pink, () => _judge(n, true)),
        ],
      );

  Widget _circleBtn(IconData icon, Color c, VoidCallback onTap) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: c.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                  color: c.withOpacity(0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Icon(icon, color: c, size: 28),
        ),
      );

  Widget _deckDone() => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('✅', style: TextStyle(fontSize: 46)),
            const SizedBox(height: 16),
            const Text('أنهيت كل الأسماء المعروضة',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 8),
            const Text('افتح تبويب «المتّفق عليها» لترى ما اتفقتما عليه.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _ink3, height: 1.7)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                _judged.clear();
                _loadDeck();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('ابدأ من جديد'),
            ),
          ]),
        ),
      );

  // ── تبويب المتّفق عليها ──────────────────────────────────────
  Widget _matchesTab() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.where('motherLike', isEqualTo: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final docs = (snap.data?.docs ?? [])
              .where((d) => d.data()['partnerLike'] == true)
              .toList();

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Text('💭', style: TextStyle(fontSize: 46)),
                  SizedBox(height: 16),
                  Text('لا يوجد تطابق بعد',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  SizedBox(height: 8),
                  Text(
                    'عندما يُعجب كلاكما بنفس الاسم سيظهر هنا تلقائياً.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: _ink3, height: 1.7),
                  ),
                ]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final d = docs[i].data();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _pink.withOpacity(0.22)),
                ),
                child: Row(children: [
                  const Text('💗', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['name'] as String? ?? '',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: _ink)),
                          const SizedBox(height: 4),
                          Text(d['meaning'] as String? ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: _ink3, height: 1.5)),
                        ]),
                  ),
                ]),
              );
            },
          );
        },
      );
}
