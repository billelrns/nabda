import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

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

class PregnancyJournalScreen extends StatefulWidget {
  const PregnancyJournalScreen({Key? key}) : super(key: key);
  @override
  State<PregnancyJournalScreen> createState() => _PregnancyJournalScreenState();
}

class _PregnancyJournalScreenState extends State<PregnancyJournalScreen> {
  List<_JournalEntry> _entries = [];
  bool _loading = true;
  int _currentWeek = 0;

  final _moods = [
    ('😊', 'سعيدة'),
    ('😴', 'متعبة'),
    ('🤢', 'غثيان'),
    ('😰', 'قلقة'),
    ('🥰', 'متحمسة'),
    ('😢', 'حزينة'),
    ('😤', 'منزعجة'),
    ('🤗', 'مرتاحة'),
  ];

  final _symptoms = [
    'غثيان', 'صداع', 'ألم الظهر', 'تورم القدمين', 'أرق', 'حرقة المعدة',
    'تقلصات', 'دوخة', 'تعب شديد', 'حركة الجنين', 'ضيق تنفس', 'تقلبات مزاجية',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userDoc = await _userDoc.get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      _currentWeek = (userData['pregnancyWeek'] as num?)?.toInt() ??
          (userData['weight_tracker_profile']?['current_week'] as num?)?.toInt() ?? 0;

      final snap = await _userDoc.collection('pregnancy_journal')
          .orderBy('date', descending: true).get();
      setState(() {
        _entries = snap.docs.map((d) {
          final data = d.data();
          final ts = data['date'] as Timestamp?;
          return _JournalEntry(
            id: d.id,
            date: ts?.toDate() ?? DateTime.now(),
            mood: data['mood'] ?? '',
            moodEmoji: data['moodEmoji'] ?? '😊',
            note: data['note'] ?? '',
            symptoms: List<String>.from(data['symptoms'] ?? []),
            week: (data['week'] as num?)?.toInt() ?? 0,
            photoBase64: data['photo'] as String?,
          );
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _addEntry(String mood, String moodEmoji, String note, List<String> symptoms) async {
    await _userDoc.collection('pregnancy_journal').add({
      'date': FieldValue.serverTimestamp(),
      'mood': mood,
      'moodEmoji': moodEmoji,
      'note': note,
      'symptoms': symptoms,
      'week': _currentWeek,
    });
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('تم حفظ يومياتك'), backgroundColor: _teal,
          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );
    }
  }

  Future<void> _deleteEntry(String id) async {
    await _userDoc.collection('pregnancy_journal').doc(id).delete();
    await _loadData();
  }

  void _showAddEntrySheet() {
    String selectedMood = 'سعيدة';
    String selectedEmoji = '😊';
    final noteCtrl = TextEditingController();
    final selectedSymptoms = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text('كيف حالك اليوم؟', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _text1)),
                Text('الأسبوع $_currentWeek', style: TextStyle(fontSize: 14, color: _text2)),
                const SizedBox(height: 20),
                // Mood selector
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _moods.map((m) {
                    final isSelected = m.$2 == selectedMood;
                    return GestureDetector(
                      onTap: () => setBS(() { selectedMood = m.$2; selectedEmoji = m.$1; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? _pink.withOpacity(0.12) : _bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? _pink : Colors.transparent, width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(m.$1, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(m.$2, style: TextStyle(fontSize: 12, color: isSelected ? _pink : _text2, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                // Symptoms
                Align(alignment: Alignment.centerRight, child: Text('الأعراض', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _text1))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _symptoms.map((s) {
                    final isSelected = selectedSymptoms.contains(s);
                    return GestureDetector(
                      onTap: () => setBS(() { isSelected ? selectedSymptoms.remove(s) : selectedSymptoms.add(s); }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? _teal.withOpacity(0.12) : _bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? _teal : Colors.transparent),
                        ),
                        child: Text(s, style: TextStyle(fontSize: 13, color: isSelected ? _teal : _text2, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                // Note
                Expanded(
                  child: TextField(
                    controller: noteCtrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'اكتبي ملاحظاتك وأفكارك اليوم...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true, fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _addEntry(selectedMood, selectedEmoji, noteCtrl.text.trim(), selectedSymptoms.toList());
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('حفظ اليوميات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('يوميات الحمل', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddEntrySheet,
          backgroundColor: _pink, foregroundColor: Colors.white,
          icon: const Icon(Icons.edit),
          label: const Text('كتابة يومية', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _entries.isEmpty
            ? _buildEmptyState()
            : _buildJournalList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(color: _pink.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.auto_stories, size: 56, color: _pink),
            ),
            const SizedBox(height: 24),
            const Text('يومياتك فارغة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _text1)),
            const SizedBox(height: 10),
            Text('سجّلي مشاعرك وأعراضك وذكرياتك اليومية\nلتحتفظي بها كذكرى جميلة',
              style: TextStyle(fontSize: 14, color: _text2, height: 1.6), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalList() {
    // Group by week
    final grouped = <int, List<_JournalEntry>>{};
    for (final e in _entries) {
      grouped.putIfAbsent(e.week, () => []).add(e);
    }
    final weeks = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        // Mood summary
        if (_entries.length >= 3) _buildMoodSummary(),
        if (_entries.length >= 3) const SizedBox(height: 16),
        // Entries
        ...weeks.expand((week) => [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text('الأسبوع $week', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _teal)),
          ),
          ...grouped[week]!.map((e) => _buildEntryCard(e)),
        ]),
      ],
    );
  }

  Widget _buildMoodSummary() {
    final moodCount = <String, int>{};
    for (final e in _entries) {
      moodCount[e.moodEmoji] = (moodCount[e.moodEmoji] ?? 0) + 1;
    }
    final sorted = moodCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملخص مشاعرك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: sorted.take(5).map((e) => Column(
              children: [
                Text(e.key, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text('${e.value}x', style: TextStyle(fontSize: 12, color: _text2, fontWeight: FontWeight.bold)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(_JournalEntry entry) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.delete, color: Colors.red[400]),
      ),
      onDismissed: (_) => _deleteEntry(entry.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: date + mood
            Row(
              children: [
                Text(entry.moodEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.mood, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
                      Text('${entry.date.day}/${entry.date.month}/${entry.date.year} — ${entry.date.hour}:${entry.date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: _text2)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('أ${entry.week}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _teal)),
                ),
              ],
            ),
            // Note
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(entry.note, style: const TextStyle(fontSize: 14, color: _text1, height: 1.6)),
            ],
            // Symptoms
            if (entry.symptoms.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: entry.symptoms.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(s, style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JournalEntry {
  final String id;
  final DateTime date;
  final String mood, moodEmoji, note;
  final List<String> symptoms;
  final int week;
  final String? photoBase64;
  const _JournalEntry({required this.id, required this.date, required this.mood, required this.moodEmoji,
    required this.note, required this.symptoms, required this.week, this.photoBase64});
}
