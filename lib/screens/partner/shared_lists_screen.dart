import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../shop/shop_page.dart';

/// ═══════════════════════════════════════════════════════════════════
///  القوائم المشتركة بين الزوجين — حقيبة الولادة وتحضير الطفل
///
///  💰 هذه هي بوّابة الإيراد في وضع الأب: كل عنصر غير مُنجَز يعرض زرّ
///  «جهّزه من نبضة» الذي يفتح المتجر على كلمة البحث المناسبة.
///  (نمط The Bump / BumpSync — قائمة التحضير هي ما يحوّل المتابعة إلى شراء.)
///
///  المسار: couples/{id}/lists/{hospital_bag|baby_prep}
///  الوثيقة: { items: [ {id, title, done, doneBy, query} ] }
/// ═══════════════════════════════════════════════════════════════════
class SharedListsScreen extends StatefulWidget {
  final String coupleId;
  const SharedListsScreen({super.key, required this.coupleId});

  @override
  State<SharedListsScreen> createState() => _SharedListsScreenState();
}

const _blue = Color(0xFF2E6B8F);
const _teal = Color(0xFF00897B);
const _amber = Color(0xFFD98324);
const _ink = Color(0xFF1F1A20);
const _ink3 = Color(0xFF9B8F95);
const _bg = Color(0xFFF7FAFC);

class _SharedListsScreenState extends State<SharedListsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _addC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _seedIfEmpty();
  }

  @override
  void dispose() {
    _tab.dispose();
    _addC.dispose();
    super.dispose();
  }

  String get _listId => _tab.index == 0 ? 'hospital_bag' : 'baby_prep';

  DocumentReference<Map<String, dynamic>> _ref(String id) => FirebaseFirestore
      .instance
      .collection('couples')
      .doc(widget.coupleId)
      .collection('lists')
      .doc(id);

  /// يملأ القائمتين بالعناصر الافتراضية أوّل مرّة فقط.
  Future<void> _seedIfEmpty() async {
    for (final entry in _defaults.entries) {
      try {
        final ref = _ref(entry.key);
        final snap = await ref.get();
        if (!snap.exists) {
          await ref.set({
            'type': entry.key,
            'items': entry.value
                .map((e) => {
                      'id': e.$1,
                      'title': e.$2,
                      'query': e.$3,
                      'done': false,
                      'doneBy': null,
                    })
                .toList(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {/* أفضل-جهد */}
    }
  }

  Future<void> _toggle(List<dynamic> items, int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final copy = List<Map<String, dynamic>>.from(
        items.map((e) => Map<String, dynamic>.from(e as Map)));
    final wasDone = copy[index]['done'] == true;
    copy[index]['done'] = !wasDone;
    copy[index]['doneBy'] = wasDone ? null : uid;
    try {
      await _ref(_listId).set({'items': copy}, SetOptions(merge: true));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذّر الحفظ — تحقّق من الاتصال'),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _add(List<dynamic> items) async {
    final t = _addC.text.trim();
    if (t.isEmpty) return;
    final copy = List<Map<String, dynamic>>.from(
        items.map((e) => Map<String, dynamic>.from(e as Map)));
    copy.add({
      'id': 'c${DateTime.now().millisecondsSinceEpoch}',
      'title': t,
      'query': t,
      'done': false,
      'doneBy': null,
    });
    _addC.clear();
    FocusScope.of(context).unfocus();
    try {
      await _ref(_listId).set({'items': copy}, SetOptions(merge: true));
    } catch (_) {/* تجاهل */}
  }

  Future<void> _remove(List<dynamic> items, int index) async {
    final copy = List<Map<String, dynamic>>.from(
        items.map((e) => Map<String, dynamic>.from(e as Map)));
    copy.removeAt(index);
    try {
      await _ref(_listId).set({'items': copy}, SetOptions(merge: true));
    } catch (_) {/* تجاهل */}
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
          title: const Text('قوائمنا المشتركة',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          bottom: TabBar(
            controller: _tab,
            labelColor: _blue,
            unselectedLabelColor: _ink3,
            indicatorColor: _blue,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            tabs: const [
              Tab(text: '🎒 حقيبة الولادة'),
              Tab(text: '👶 تحضير الطفل'),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _ref(_listId).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2));
            }
            final items = (snap.data?.data()?['items'] as List?) ?? [];
            final done = items.where((e) => (e as Map)['done'] == true).length;

            return Column(children: [
              _progress(done, items.length),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('القائمة فارغة — أضف أوّل عنصر',
                            style: TextStyle(color: _ink3)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (c, i) => _tile(items, i),
                      ),
              ),
              _addBar(items),
            ]);
          },
        ),
      ),
    );
  }

  Widget _progress(int done, int total) {
    final p = total == 0 ? 0.0 : done / total;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDF2)),
      ),
      child: Column(children: [
        Row(children: [
          Text('$done من $total جاهز',
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
          const Spacer(),
          Text('${(p * 100).round()}%',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900, color: _teal)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 7,
            backgroundColor: const Color(0xFFEDF2F5),
            valueColor: const AlwaysStoppedAnimation(_teal),
          ),
        ),
      ]),
    );
  }

  Widget _tile(List<dynamic> items, int i) {
    final m = Map<String, dynamic>.from(items[i] as Map);
    final done = m['done'] == true;
    final title = m['title'] as String? ?? '';
    final query = m['query'] as String? ?? title;

    return Dismissible(
      key: ValueKey(m['id'] ?? '$i$title'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
      ),
      onDismissed: (_) => _remove(items, i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EDF2)),
        ),
        child: Row(children: [
          Checkbox(
            value: done,
            activeColor: _teal,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
            onChanged: (_) => _toggle(items, i),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggle(items, i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: done ? _ink3 : _ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: _ink3,
                  ),
                ),
              ),
            ),
          ),
          if (!done)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _amber,
                  backgroundColor: _amber.withOpacity(0.10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ShopPage())),
                child: Text('جهّزه',
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w800),
                    semanticsLabel: 'جهّز $query من متجر نبضة'),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _addBar(List<dynamic> items) => Container(
        padding: EdgeInsets.fromLTRB(
            16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE6EDF2))),
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _addC,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(items),
                decoration: InputDecoration(
                  hintText: 'أضف عنصراً…',
                  hintStyle: const TextStyle(fontSize: 13, color: _ink3),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: _blue),
              onPressed: () => _add(items),
              icon: const Icon(Icons.add),
            ),
          ]),
        ),
      );

  // ── العناصر الافتراضية (id, العنوان, كلمة البحث في المتجر) ──
  static const Map<String, List<(String, String, String)>> _defaults = {
    'hospital_bag': [
      ('hb1', 'قميص ولادة قطني (قطعتان)', 'قميص ولادة'),
      ('hb2', 'حمّالة صدر للرضاعة', 'حمالة رضاعة'),
      ('hb3', 'فوط نفاس', 'فوط نفاس'),
      ('hb4', 'ملابس داخلية مريحة', 'ملابس داخلية'),
      ('hb5', 'روب وخفّ', 'روب'),
      ('hb6', 'أدوات نظافة شخصية', 'أدوات نظافة'),
      ('hb7', 'منشفة كبيرة', 'منشفة'),
      ('hb8', 'ملابس المولود (3 أطقم)', 'ملابس مولود'),
      ('hb9', 'حفاضات مقاس حديثي الولادة', 'حفاضات مواليد'),
      ('hb10', 'قمّاط وبطانية', 'قماط مولود'),
      ('hb11', 'قبّعة وجوارب صغيرة', 'قبعة مولود'),
      ('hb12', 'مناديل مبلّلة', 'مناديل مبللة'),
      ('hb13', 'الأوراق والوثائق', ''),
      ('hb14', 'شاحن هاتف طويل', ''),
      ('hb15', 'ماء وتمر ووجبات خفيفة', ''),
    ],
    'baby_prep': [
      ('bp1', 'سرير الطفل', 'سرير طفل'),
      ('bp2', 'فراش ومفارش السرير', 'فراش طفل'),
      ('bp3', 'عربة أطفال', 'عربة اطفال'),
      ('bp4', 'كرسي سيارة', 'كرسي سيارة'),
      ('bp5', 'حوض استحمام', 'حوض استحمام'),
      ('bp6', 'طاولة تغيير الحفاض', 'طاولة تغيير'),
      ('bp7', 'رضّاعات ومعقّم', 'رضاعات'),
      ('bp8', 'شفّاط حليب', 'شفاط حليب'),
      ('bp9', 'مريلات ومناديل كتف', 'مريلة طفل'),
      ('bp10', 'ملابس مقاس 0-3 أشهر', 'ملابس رضيع'),
      ('bp11', 'كريم تغيير الحفاض', 'كريم حفاض'),
      ('bp12', 'شامبو وغسول أطفال', 'شامبو اطفال'),
      ('bp13', 'حمّالة طفل', 'حمالة طفل'),
      ('bp14', 'ألعاب تعليقية للسرير', 'العاب رضع'),
      ('bp15', 'خزانة أو رفوف للملابس', ''),
    ],
  };
}
