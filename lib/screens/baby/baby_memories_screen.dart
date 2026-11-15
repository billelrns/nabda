import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/baby_memories_service.dart';
import '../../utils/voice.dart';

/// ═══════════════════════════════════════════════════════════════════
///  دفتر ذكريات الطفل — الواجهة
///  • BabyMemoriesSection : قسم داخل صفحة الطفل (المعالم + آخر الذكريات)
///  • BabyMemoriesScreen  : السجلّ الزمني الكامل
///  • showMemoryEditor    : إضافة / تعديل / حذف ذكرى
/// ═══════════════════════════════════════════════════════════════════

const _pink = Color(0xFFFF4F93);
const _pinkDeep = Color(0xFFE53B7E);
const _pink50 = Color(0xFFFFF1F6);
const _teal = Color(0xFF15B8A6);
const _gold = Color(0xFFE8B04B);
const _ink = Color(0xFF1B1320);
const _ink2 = Color(0xFF4A3F4F);
const _ink3 = Color(0xFF8E8295);
const _line = Color(0xFFF0E6EE);
const _cream = Color(0xFFFFF8FA);

// ══════════════════════════════════════════════════════════════════
//  القسم داخل صفحة الطفل
// ══════════════════════════════════════════════════════════════════
class BabyMemoriesSection extends StatefulWidget {
  final DocumentReference babyRef;
  final String babyId;
  final String babyName;
  final DateTime? birthDate;

  const BabyMemoriesSection({
    super.key,
    required this.babyRef,
    required this.babyId,
    required this.babyName,
    this.birthDate,
  });

  @override
  State<BabyMemoriesSection> createState() => _BabyMemoriesSectionState();
}

class _BabyMemoriesSectionState extends State<BabyMemoriesSection> {
  // صفحة الطفل تُعاد بناؤها كثيراً (عدّة StreamBuilder متداخلة)؛ لو أنشأنا
  // البثّ في build لأُعيد الاشتراك في كل مرّة ورمش القسم. نحتفظ به هنا.
  late Stream<List<BabyMemory>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = BabyMemoriesService.watch(widget.babyRef);
  }

  @override
  void didUpdateWidget(covariant BabyMemoriesSection old) {
    super.didUpdateWidget(old);
    if (old.babyId != widget.babyId) {
      _stream = BabyMemoriesService.watch(widget.babyRef);
    }
  }

  void _openEditor({MilestoneType? preset, BabyMemory? existing}) => showMemoryEditor(
        context,
        babyRef: widget.babyRef,
        babyId: widget.babyId,
        babyName: widget.babyName,
        birthDate: widget.birthDate,
        preset: preset,
        existing: existing,
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BabyMemory>>(
      stream: _stream,
      builder: (context, snap) {
        final memories = snap.data ?? const <BabyMemory>[];
        // أوّل مرّة لكل معلم = الأقدم تاريخاً
        final firstOf = <String, BabyMemory>{};
        for (final m in memories.reversed) {
          if (!m.isCustom) firstOf.putIfAbsent(m.type, () => m);
        }
        final done = firstOf.length;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── شريط المعالم ──
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: kMilestones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final t = kMilestones[i];
                final m = firstOf[t.id];
                return _MilestoneChip(
                  type: t,
                  memory: m,
                  onTap: () => m != null ? _openEditor(existing: m) : _openEditor(preset: t),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              done == 0
                  ? V.t('اضغطي على أيّ لحظة لتسجيلها بتاريخها وصورتها 📸')
                  : '$done من ${kMilestones.length} لحظات مسجّلة',
              style: const TextStyle(fontSize: 11.5, color: _ink3),
            ),
          ),

          // ── آخر الذكريات ──
          if (memories.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _line),
                ),
                child: Column(children: [
                  for (var i = 0; i < memories.length && i < 3; i++)
                    _TimelineTile(
                      memory: memories[i],
                      birthDate: widget.birthDate,
                      isLast: i == (memories.length < 3 ? memories.length - 1 : 2),
                      compact: true,
                      onTap: () => _openEditor(existing: memories[i]),
                    ),
                ]),
              ),
            ),
          ],

          // ── الأزرار ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [
              Expanded(
                child: _pillButton(
                  icon: Icons.add_rounded,
                  label: 'ذكرى جديدة',
                  filled: true,
                  onTap: () => _openEditor(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pillButton(
                  icon: Icons.auto_stories_outlined,
                  label: memories.isEmpty ? 'السجلّ' : 'السجلّ كاملاً (${memories.length})',
                  filled: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BabyMemoriesScreen(
                        babyRef: widget.babyRef,
                        babyId: widget.babyId,
                        babyName: widget.babyName,
                        birthDate: widget.birthDate,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) =>
      Material(
        color: filled ? _pink : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: filled ? null : Border.all(color: _pink.withOpacity(0.35)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: filled ? Colors.white : _pinkDeep),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: filled ? Colors.white : _pinkDeep)),
              ),
            ]),
          ),
        ),
      );
}

class _MilestoneChip extends StatelessWidget {
  final MilestoneType type;
  final BabyMemory? memory;
  final VoidCallback onTap;
  const _MilestoneChip({required this.type, required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = memory != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(
          color: done ? Colors.white : _cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? _teal.withOpacity(0.45) : _line,
            width: done ? 1.5 : 1,
          ),
          boxShadow: done
              ? [BoxShadow(color: _teal.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? _teal.withOpacity(0.10) : Colors.white,
                image: (done && memory!.photoUrl != null)
                    ? DecorationImage(image: NetworkImage(memory!.photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: (done && memory!.photoUrl != null)
                  ? null
                  : Center(
                      child: Opacity(
                        opacity: done ? 1 : 0.55,
                        child: Text(type.emoji, style: const TextStyle(fontSize: 21)),
                      ),
                    ),
            ),
            Positioned(
              bottom: -2,
              left: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _teal : _pink,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(done ? Icons.check : Icons.add, size: 11, color: Colors.white),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(type.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: done ? _ink : _ink2)),
          const SizedBox(height: 3),
          Text(
            done ? _shortDate(memory!.date) : V.verb('سجّلي'),
            style: TextStyle(fontSize: 10, color: done ? _teal : _ink3, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }

  static String _shortDate(DateTime d) {
    final full = BabyMemoriesService.formatDate(d);
    final parts = full.split(' ');
    return parts.length >= 2 ? '${parts[0]} ${parts[1]}' : full;
  }
}

// ══════════════════════════════════════════════════════════════════
//  عنصر في الخطّ الزمني
// ══════════════════════════════════════════════════════════════════
class _TimelineTile extends StatelessWidget {
  final BabyMemory memory;
  final DateTime? birthDate;
  final bool isLast;
  final bool compact;
  final VoidCallback onTap;

  const _TimelineTile({
    required this.memory,
    required this.birthDate,
    required this.isLast,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final age = BabyMemoriesService.ageAt(birthDate, memory.date);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── الخطّ والنقطة ──
          SizedBox(
            width: 34,
            child: Column(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pink50,
                  border: Border.all(color: _pink.withOpacity(0.35), width: 1.5),
                ),
                child: Center(child: Text(memory.emoji, style: const TextStyle(fontSize: 16))),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: _line),
                ),
            ]),
          ),
          const SizedBox(width: 12),
          // ── المحتوى ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(memory.title,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 3),
                Text(
                  [BabyMemoriesService.formatDate(memory.date), if (age.isNotEmpty) age].join(' • '),
                  style: const TextStyle(fontSize: 11.5, color: _ink3),
                ),
                if (memory.note.isNotEmpty && !compact) ...[
                  const SizedBox(height: 6),
                  Text(memory.note, style: const TextStyle(fontSize: 13, height: 1.7, color: _ink2)),
                ],
                if (memory.photoUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      memory.photoUrl!,
                      height: compact ? 90 : 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  السجلّ الزمني الكامل
// ══════════════════════════════════════════════════════════════════
class BabyMemoriesScreen extends StatelessWidget {
  final DocumentReference babyRef;
  final String babyId;
  final String babyName;
  final DateTime? birthDate;

  const BabyMemoriesScreen({
    super.key,
    required this.babyRef,
    required this.babyId,
    required this.babyName,
    this.birthDate,
  });

  @override
  Widget build(BuildContext context) {
    void edit({BabyMemory? m}) => showMemoryEditor(
          context,
          babyRef: babyRef,
          babyId: babyId,
          babyName: babyName,
          birthDate: birthDate,
          existing: m,
        );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          elevation: 0,
          foregroundColor: _ink,
          title: Text(
            babyName.trim().isEmpty ? 'سجلّ الذكريات' : 'ذكريات ${babyName.trim()}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _pink,
          foregroundColor: Colors.white,
          onPressed: () => edit(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('ذكرى جديدة', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: StreamBuilder<List<BabyMemory>>(
          stream: BabyMemoriesService.watch(babyRef),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            }
            final list = snap.data ?? const <BabyMemory>[];
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('📖', style: TextStyle(fontSize: 52)),
                    const SizedBox(height: 16),
                    const Text('الدفتر فارغ بعد',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
                    const SizedBox(height: 8),
                    Text(
                      V.t('سجّلي أول ابتسامة، أول سنّ، أول خطوة…\nبتاريخها وصورتها، لتبقى معكِ للأبد.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, height: 1.8, color: _ink3),
                    ),
                  ]),
                ),
              );
            }

            // تجميع حسب السنة لعناوين فاصلة
            final children = <Widget>[];
            int? year;
            for (var i = 0; i < list.length; i++) {
              final m = list[i];
              if (m.date.year != year) {
                year = m.date.year;
                children.add(Padding(
                  padding: EdgeInsets.fromLTRB(4, i == 0 ? 4 : 18, 4, 12),
                  child: Text('$year',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _gold)),
                ));
              }
              children.add(_TimelineTile(
                memory: m,
                birthDate: birthDate,
                isLast: i == list.length - 1 || list[i + 1].date.year != m.date.year,
                onTap: () => edit(m: m),
              ));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: children,
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  نافذة الإضافة / التعديل
// ══════════════════════════════════════════════════════════════════
Future<void> showMemoryEditor(
  BuildContext context, {
  required DocumentReference babyRef,
  required String babyId,
  required String babyName,
  DateTime? birthDate,
  MilestoneType? preset,
  BabyMemory? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _MemoryEditor(
      babyRef: babyRef,
      babyId: babyId,
      babyName: babyName,
      birthDate: birthDate,
      preset: preset,
      existing: existing,
    ),
  );
}

class _MemoryEditor extends StatefulWidget {
  final DocumentReference babyRef;
  final String babyId;
  final String babyName;
  final DateTime? birthDate;
  final MilestoneType? preset;
  final BabyMemory? existing;

  const _MemoryEditor({
    required this.babyRef,
    required this.babyId,
    required this.babyName,
    required this.birthDate,
    this.preset,
    this.existing,
  });

  @override
  State<_MemoryEditor> createState() => _MemoryEditorState();
}

class _MemoryEditorState extends State<_MemoryEditor> {
  late MilestoneType _type;
  late DateTime _date;
  late final TextEditingController _title;
  late final TextEditingController _note;
  Uint8List? _newPhoto;
  bool _removePhoto = false;
  bool _busy = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e != null ? milestoneById(e.type) : (widget.preset ?? kCustomMemory);
    _date = e?.date ?? DateTime.now();
    _title = TextEditingController(text: e?.isCustom == true ? e!.title : '');
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = widget.birthDate ?? now.subtract(const Duration(days: 365 * 6));
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(first) ? first : (_date.isAfter(now) ? now : _date),
      firstDate: first,
      lastDate: now,
      helpText: 'تاريخ الذكرى',
      // نفس نمط كل منتقيات التاريخ في التطبيق (main.dart)
      builder: (context, child) => Localizations.override(
          context: context, locale: const Locale('en'), child: child!),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickPhoto(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 80);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newPhoto = bytes;
        _removePhoto = false;
      });
    } catch (_) {
      _snack('تعذّر فتح الصور');
    }
  }

  void _photoMenu() {
    showModalBottomSheet(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _pink),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(c);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _pink),
              title: const Text('من المعرض'),
              onTap: () {
                Navigator.pop(c);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('إزالة الصورة'),
                onTap: () {
                  Navigator.pop(c);
                  setState(() {
                    _newPhoto = null;
                    _removePhoto = true;
                  });
                },
              ),
          ]),
        ),
      ),
    );
  }

  bool get _hasPhoto =>
      _newPhoto != null || (!_removePhoto && widget.existing?.photoUrl != null);

  Future<void> _save() async {
    if (_type.id == 'custom' && _title.text.trim().isEmpty) {
      _snack('اكتبي عنواناً للذكرى');
      return;
    }
    setState(() => _busy = true);
    final err = await BabyMemoriesService.save(
      babyRef: widget.babyRef,
      babyId: widget.babyId,
      type: _type,
      title: _type.id == 'custom' ? _title.text : _type.title,
      date: _date,
      note: _note.text,
      existingId: widget.existing?.id,
      existing: widget.existing,
      photoBytes: _newPhoto,
      removePhoto: _removePhoto,
      babyName: widget.babyName,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      _snack(err);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('حذف الذكرى؟', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text('ستُحذف الذكرى وصورتها نهائياً، ولا يمكن استرجاعها.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('تراجع')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await BabyMemoriesService.delete(widget.babyRef, widget.existing!);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('تعذّر الحذف — تحقّقي من الاتصال');
      }
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final age = BabyMemoriesService.ageAt(widget.birthDate, _date);
    // الاختيار من القائمة متاح عند الإنشاء الحرّ فقط (لا عند التعديل ولا مع معلم محدّد)
    final chooseType = !_editing && widget.preset == null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text(_type.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _editing ? 'تعديل الذكرى' : (_type.id == 'custom' ? 'ذكرى جديدة' : _type.title),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _ink),
                  ),
                ),
                if (_editing)
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ]),

              if (chooseType) ...[
                const SizedBox(height: 14),
                const Text('ما اللحظة؟',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink2)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in [...kMilestones, kCustomMemory])
                    ChoiceChip(
                      label: Text('${t.emoji} ${t.title}'),
                      selected: _type.id == t.id,
                      selectedColor: _pink50,
                      side: BorderSide(color: _type.id == t.id ? _pink : _line),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _type.id == t.id ? _pinkDeep : _ink2,
                      ),
                      onSelected: (_) => setState(() => _type = t),
                    ),
                ]),
              ],

              if (_type.id == 'custom') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: _title,
                  maxLength: 60,
                  decoration: _input('عنوان الذكرى', 'مثلاً: أول مرّة نادى «ماما»'),
                ),
              ],

              const SizedBox(height: 10),
              // ── التاريخ ──
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _line),
                  ),
                  child: Row(children: [
                    const Icon(Icons.event_rounded, color: _pink, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(BabyMemoriesService.formatDate(_date),
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
                        if (age.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(age, style: const TextStyle(fontSize: 11.5, color: _teal, fontWeight: FontWeight.w700)),
                        ],
                      ]),
                    ),
                    const Text('تغيير', style: TextStyle(fontSize: 12, color: _pinkDeep, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),

              const SizedBox(height: 12),
              // ── الصورة ──
              GestureDetector(
                onTap: _photoMenu,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: _hasPhoto ? 200 : 96,
                    decoration: BoxDecoration(
                      color: _pink50,
                      border: Border.all(color: _pink.withOpacity(0.25)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: _hasPhoto
                        ? Stack(fit: StackFit.expand, children: [
                            _newPhoto != null
                                ? Image.memory(_newPhoto!, fit: BoxFit.cover)
                                : Image.network(widget.existing!.photoUrl!, fit: BoxFit.cover),
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('تغيير الصورة',
                                    style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ])
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.add_a_photo_outlined, color: _pinkDeep),
                            const SizedBox(width: 10),
                            Text(V.t('أضيفي صورة لهذه اللحظة (اختياري)'),
                                style: const TextStyle(fontSize: 13, color: _pinkDeep, fontWeight: FontWeight.w700)),
                          ]),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLines: 3,
                maxLength: 500,
                decoration: _input('ملاحظة (اختيارية)', 'ماذا حدث؟ من كان حاضراً؟ كيف شعرتِ؟'),
              ),

              const SizedBox(height: 6),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _pink,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_editing ? 'حفظ التعديلات' : 'حفظ الذكرى 💗',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: V.t(hint),
        hintStyle: const TextStyle(fontSize: 12, color: _ink3),
        filled: true,
        fillColor: _cream,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _pink, width: 1.5)),
      );
}
