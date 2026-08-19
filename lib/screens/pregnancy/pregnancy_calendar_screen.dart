import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../models/pregnancy_week_articles.dart' show pregnancyMonthArForWeek;
import '../../services/pregnancy_dates_service.dart';
import '../../widgets/due_date_card.dart';

// ─── Theme ───
const Color _bg = Color(0xFFFFF5F7);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);
const Color _indigo = Color(0xFF5C6BC0);

DocumentReference get _userDoc {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

// ═══════════════════════════════════════════════
//  PREGNANCY CALENDAR SCREEN
// ═══════════════════════════════════════════════
class PregnancyCalendarScreen extends StatefulWidget {
  const PregnancyCalendarScreen({Key? key}) : super(key: key);
  @override
  State<PregnancyCalendarScreen> createState() => _PregnancyCalendarScreenState();
}

class _PregnancyCalendarScreenState extends State<PregnancyCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  DateTime? _dueDate;
  DateTime? _lmpDate; // Last menstrual period
  int _currentWeek = 0;
  bool _loaded = false;

  List<_CalendarEvent> _customEvents = [];
  bool _loadingEvents = false;

  @override
  void initState() {
    super.initState();
    _loadPregnancyData();
    _loadCustomEvents();
  }

  Future<void> _loadPregnancyData() async {
    try {
      final doc = await _userDoc.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};

      // ── مصدر موحّد لتواريخ الحمل (نفس ما تستعمله بقية الشاشات) ──
      final pd = PregnancyDates.fromUserData(data);

      setState(() {
        _dueDate = pd.effectiveDueDate;
        _lmpDate = pd.effectiveStart;
        _currentWeek = pd.week;
        _loaded = true;
      });
    } catch (_) {
      setState(() { _loaded = true; });
    }
  }

  Future<void> _loadCustomEvents() async {
    setState(() { _loadingEvents = true; });
    try {
      final snap = await _userDoc.collection('pregnancy_calendar').orderBy('date').get();
      setState(() {
        _customEvents = snap.docs.map((d) {
          final data = d.data();
          final ts = data['date'] as Timestamp?;
          return _CalendarEvent(
            id: d.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            date: ts?.toDate() ?? DateTime.now(),
            type: _EventType.values.firstWhere(
              (t) => t.name == (data['type'] ?? 'custom'),
              orElse: () => _EventType.custom,
            ),
            isCompleted: data['completed'] ?? false,
          );
        }).toList();
        _loadingEvents = false;
      });
    } catch (_) {
      setState(() { _loadingEvents = false; });
    }
  }

  // Get pregnancy week for a specific date
  int _weekForDate(DateTime date) {
    if (_lmpDate == null) return 0;
    final diff = date.difference(_lmpDate!).inDays;
    return (diff / 7).floor().clamp(0, 42);
  }

  // Get trimester for a week
  int _trimesterForWeek(int week) {
    if (week <= 13) return 1;
    if (week <= 26) return 2;
    return 3;
  }

  // Get all events for a date (built-in + custom)
  List<_CalendarEvent> _eventsForDate(DateTime date) {
    final events = <_CalendarEvent>[];
    final week = _weekForDate(date);

    // Check if this date matches any medical milestone
    if (_lmpDate != null) {
      for (final milestone in _medicalMilestones) {
        final milestoneDate = _lmpDate!.add(Duration(days: milestone.week * 7));
        if (_isSameDay(milestoneDate, date)) {
          events.add(_CalendarEvent(
            id: 'milestone_${milestone.week}',
            title: milestone.title,
            description: milestone.description,
            date: milestoneDate,
            type: milestone.type,
            isCompleted: false,
          ));
        }
      }
    }

    // Custom events
    events.addAll(_customEvents.where((e) => _isSameDay(e.date, date)));
    return events;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  Future<void> _addCustomEvent(String title, String desc, DateTime date, _EventType type) async {
    await _userDoc.collection('pregnancy_calendar').add({
      'title': title,
      'description': desc,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'completed': false,
    });
    await _loadCustomEvents();
  }

  Future<void> _toggleEventComplete(String id, bool completed) async {
    await _userDoc.collection('pregnancy_calendar').doc(id).update({'completed': !completed});
    await _loadCustomEvents();
  }

  Future<void> _deleteEvent(String id) async {
    await _userDoc.collection('pregnancy_calendar').doc(id).delete();
    await _loadCustomEvents();
  }

  void _showAddEventDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var selectedDate = _selectedDate;
    var selectedType = _EventType.custom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Text('إضافة موعد جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text1)),
                  const SizedBox(height: 20),
                  // Type selector
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _eventTypeChip('فحص طبي', _EventType.medical, Icons.medical_services, selectedType, (t) => setBS(() => selectedType = t)),
                      _eventTypeChip('تطعيم', _EventType.vaccine, Icons.vaccines, selectedType, (t) => setBS(() => selectedType = t)),
                      _eventTypeChip('سونار', _EventType.ultrasound, Icons.monitor, selectedType, (t) => setBS(() => selectedType = t)),
                      _eventTypeChip('تحليل', _EventType.labTest, Icons.science, selectedType, (t) => setBS(() => selectedType = t)),
                      _eventTypeChip('آخر', _EventType.custom, Icons.event, selectedType, (t) => setBS(() => selectedType = t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'عنوان الموعد',
                      hintText: 'مثال: فحص السكري',
                      filled: true, fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      filled: true, fillColor: _bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date picker button
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 300)),
                        lastDate: DateTime.now().add(const Duration(days: 300)),
                        builder: (context, child) => Localizations.override(context: context, locale: const Locale('en'), child: child!),
                      );
                      if (picked != null) setBS(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: _teal, size: 20),
                          const SizedBox(width: 10),
                          Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(fontSize: 15, color: _text1)),
                          const Spacer(),
                          Text('تغيير', style: TextStyle(fontSize: 13, color: _teal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isNotEmpty) {
                          Navigator.pop(ctx);
                          _addCustomEvent(titleCtrl.text.trim(), descCtrl.text.trim(), selectedDate, selectedType);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('حفظ الموعد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventTypeChip(String label, _EventType type, IconData icon, _EventType selected, Function(_EventType) onTap) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _teal.withOpacity(0.15) : _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _teal : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? _teal : _text2),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? _teal : _text2)),
          ],
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
          title: const Text('تقويم الحمل', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddEventDialog,
          backgroundColor: _pink,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة موعد', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: !_loaded
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : _dueDate == null
                ? _buildSetupPrompt()
                : _buildCalendarBody(),
      ),
    );
  }

  Widget _buildSetupPrompt() {
    final dueDateCtrl = TextEditingController();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(color: _teal.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.calendar_month, size: 56, color: _teal),
            ),
            const SizedBox(height: 24),
            const Text('تقويم الحمل', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _text1)),
            const SizedBox(height: 10),
            Text('أدخلي تاريخ آخر دورة أو تاريخ الولادة المتوقع لعرض التقويم',
              style: TextStyle(fontSize: 14, color: _text2, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 90)),
                    firstDate: DateTime.now().subtract(const Duration(days: 300)),
                    lastDate: DateTime.now(),
                    helpText: 'اختاري تاريخ آخر دورة شهرية',
                    builder: (context, child) => Localizations.override(context: context, locale: const Locale('en'), child: child!),
                  );
                  if (picked != null) {
                    await PregnancyDates.saveLmp(picked);
                    await _loadPregnancyData();
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('تحديد تاريخ آخر دورة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarBody() {
    final daysRemaining = _dueDate!.difference(DateTime.now()).inDays;
    final selectedEvents = _eventsForDate(_selectedDate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        // Pregnancy info header
        _buildPregnancyHeader(daysRemaining),
        const SizedBox(height: 12),
        // تاريخ الولادة المتوقّع — قابل للتعديل مع سؤال المصدر
        DueDateCard(color: _teal, onChanged: _loadPregnancyData),
        const SizedBox(height: 16),
        // Calendar widget
        _buildCalendarWidget(),
        const SizedBox(height: 16),
        // Events for selected date
        _buildSelectedDateEvents(selectedEvents),
        const SizedBox(height: 16),
        // Upcoming events
        _buildUpcomingEvents(),
        const SizedBox(height: 16),
        // Trimester milestones
        _buildTrimesterTimeline(),
      ],
    );
  }

  Widget _buildPregnancyHeader(int daysRemaining) {
    final trimester = _trimesterForWeek(_currentWeek);
    final progress = (_currentWeek / 40).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_teal, _teal.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الأسبوع $_currentWeek', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${pregnancyMonthArForWeek(_currentWeek)} · الثلث ${'الأول الثاني الثالث'.split(' ')[trimester - 1]}',
                      style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    Text('${daysRemaining > 0 ? daysRemaining : 0}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('يوم متبقي', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الولادة المتوقعة: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Saturday = 6 in Dart (weekday 1=Mon..7=Sun). For Arabic calendar starting Saturday:
    final startWeekday = (firstDay.weekday + 1) % 7; // 0=Sat, 1=Sun, ... 6=Fri

    final monthNames = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final dayNames = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_right, color: _teal),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                }),
              ),
              GestureDetector(
                onTap: () => setState(() { _focusedMonth = DateTime.now(); _selectedDate = DateTime.now(); }),
                child: Text('${monthNames[month - 1]} $year',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _text1)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, color: _teal),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Day names header
          Row(
            children: dayNames.map((d) => Expanded(
              child: Center(child: Text(d, style: TextStyle(fontSize: 12, color: _text2, fontWeight: FontWeight.bold))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          ...List.generate(6, (row) {
            return Row(
              children: List.generate(7, (col) {
                final dayIndex = row * 7 + col - startWeekday + 1;
                if (dayIndex < 1 || dayIndex > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }
                final date = DateTime(year, month, dayIndex);
                final isSelected = _isSameDay(date, _selectedDate);
                final today = _isToday(date);
                final events = _eventsForDate(date);
                final hasEvents = events.isNotEmpty;
                final isDueDate = _dueDate != null && _isSameDay(date, _dueDate!);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _selectedDate = date; }),
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected ? _teal : isDueDate ? _pink.withOpacity(0.15) : today ? _teal.withOpacity(0.08) : null,
                        borderRadius: BorderRadius.circular(10),
                        border: today && !isSelected ? Border.all(color: _teal, width: 1.5) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$dayIndex',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || today ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : isDueDate ? _pink : _text1,
                            )),
                          if (hasEvents)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: events.take(3).map((e) => Container(
                                width: 5, height: 5,
                                margin: const EdgeInsets.only(top: 2, left: 1, right: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : _eventColor(e.type),
                                  shape: BoxShape.circle,
                                ),
                              )).toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
          const SizedBox(height: 8),
          // Legend
          Wrap(
            spacing: 12, runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _calendarLegend(_teal, 'اليوم'),
              _calendarLegend(_pink, 'موعد الولادة'),
              _calendarLegend(Colors.blue, 'فحص طبي'),
              _calendarLegend(Colors.orange, 'تطعيم'),
              _calendarLegend(Colors.purple, 'سونار'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: _text2)),
      ],
    );
  }

  Widget _buildSelectedDateEvents(List<_CalendarEvent> events) {
    final week = _weekForDate(_selectedDate);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note, color: _teal, size: 20),
              const SizedBox(width: 8),
              Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
              const Spacer(),
              if (week > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('الأسبوع $week · ${pregnancyMonthArForWeek(week)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _indigo)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_available, size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('لا توجد مواعيد في هذا اليوم', style: TextStyle(fontSize: 13, color: _text2)),
                  ],
                ),
              ),
            )
          else
            ...events.map((e) => _eventCard(e)),
        ],
      ),
    );
  }

  Widget _eventCard(_CalendarEvent event) {
    final color = _eventColor(event.type);
    final isCustom = !event.id.startsWith('milestone_');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border(right: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(_eventIcon(event.type), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _text1,
                  decoration: event.isCompleted ? TextDecoration.lineThrough : null)),
                if (event.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(event.description, style: TextStyle(fontSize: 12, color: _text2, height: 1.4)),
                  ),
                const SizedBox(height: 6),
                Text(_eventTypeName(event.type), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isCustom) ...[
            IconButton(
              icon: Icon(event.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 22),
              onPressed: () => _toggleEventComplete(event.id, event.isCompleted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
              onPressed: () => _deleteEvent(event.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    // Get all future events (next 8 weeks)
    final now = DateTime.now();
    final upcoming = <_CalendarEvent>[];

    for (int d = 0; d < 56; d++) {
      final date = now.add(Duration(days: d));
      final events = _eventsForDate(date);
      upcoming.addAll(events);
    }

    if (upcoming.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upcoming, color: _pink, size: 20),
              const SizedBox(width: 8),
              const Text('المواعيد القادمة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
              const Spacer(),
              Text('${upcoming.length} موعد', style: TextStyle(fontSize: 12, color: _text2)),
            ],
          ),
          const SizedBox(height: 12),
          ...upcoming.take(6).map((e) {
            final color = _eventColor(e.type);
            final daysUntil = e.date.difference(now).inDays;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_eventIcon(e.type), color: color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _text1), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${e.date.day}/${e.date.month} — الأسبوع ${_weekForDate(e.date)}',
                          style: TextStyle(fontSize: 11, color: _text2)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: daysUntil <= 7 ? Colors.red.withOpacity(0.1) : _teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      daysUntil == 0 ? 'اليوم' : daysUntil == 1 ? 'غدًا' : 'بعد $daysUntil يوم',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: daysUntil <= 7 ? Colors.red : _teal),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrimesterTimeline() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('جدول الفحوصات الطبية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _text1)),
          const SizedBox(height: 6),
          Text('الفحوصات الأساسية خلال فترة الحمل', style: TextStyle(fontSize: 12, color: _text2)),
          const SizedBox(height: 16),
          ..._medicalMilestones.map((m) {
            final isPast = _currentWeek > m.week;
            final isCurrent = _currentWeek == m.week;
            final color = _eventColor(m.type);
            return Container(
              margin: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline line
                  SizedBox(
                    width: 30,
                    child: Column(
                      children: [
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: isPast ? _teal : isCurrent ? _pink : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: isPast ? const Icon(Icons.check, color: Colors.white, size: 10) : null,
                        ),
                        Container(width: 2, height: 40, color: Colors.grey[200]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrent ? _pink.withOpacity(0.06) : _bg,
                        borderRadius: BorderRadius.circular(12),
                        border: isCurrent ? Border.all(color: _pink.withOpacity(0.3)) : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(m.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                      color: isPast ? _text2 : _text1,
                                      decoration: isPast ? TextDecoration.lineThrough : null)),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(4)),
                                        child: const Text('الآن', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(m.description, style: TextStyle(fontSize: 11, color: _text2), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text('أ${m.week}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Helpers ───
  Color _eventColor(_EventType type) {
    switch (type) {
      case _EventType.medical: return Colors.blue;
      case _EventType.vaccine: return Colors.orange;
      case _EventType.ultrasound: return Colors.purple;
      case _EventType.labTest: return Colors.cyan;
      case _EventType.milestone: return _teal;
      case _EventType.custom: return _indigo;
    }
  }

  IconData _eventIcon(_EventType type) {
    switch (type) {
      case _EventType.medical: return Icons.medical_services;
      case _EventType.vaccine: return Icons.vaccines;
      case _EventType.ultrasound: return Icons.monitor;
      case _EventType.labTest: return Icons.science;
      case _EventType.milestone: return Icons.star;
      case _EventType.custom: return Icons.event;
    }
  }

  String _eventTypeName(_EventType type) {
    switch (type) {
      case _EventType.medical: return 'فحص طبي';
      case _EventType.vaccine: return 'تطعيم';
      case _EventType.ultrasound: return 'سونار / أشعة';
      case _EventType.labTest: return 'تحليل مخبري';
      case _EventType.milestone: return 'مرحلة مهمة';
      case _EventType.custom: return 'موعد شخصي';
    }
  }
}

// ─── Models ───
enum _EventType { medical, vaccine, ultrasound, labTest, milestone, custom }

class _CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final _EventType type;
  final bool isCompleted;
  const _CalendarEvent({required this.id, required this.title, required this.description, required this.date, required this.type, required this.isCompleted});
}

class _MedicalMilestone {
  final int week;
  final String title;
  final String description;
  final _EventType type;
  const _MedicalMilestone(this.week, this.title, this.description, this.type);
}

// ─── Medical Milestones Data ───
const List<_MedicalMilestone> _medicalMilestones = [
  _MedicalMilestone(6, 'أول سونار', 'تأكيد الحمل وسماع نبض الجنين', _EventType.ultrasound),
  _MedicalMilestone(8, 'تحاليل الثلث الأول', 'فحص دم شامل، فصيلة الدم، Rh، سكر صائم، بول', _EventType.labTest),
  _MedicalMilestone(10, 'فحص طبي روتيني', 'قياس الضغط، الوزن، متابعة الأعراض', _EventType.medical),
  _MedicalMilestone(12, 'سونار الشفافية القفوية', 'فحص NT لتقييم خطر التشوهات الكروموسومية + تحليل PAPP-A', _EventType.ultrasound),
  _MedicalMilestone(14, 'بداية الثلث الثاني', 'فحص روتيني — عادة تقل أعراض الغثيان', _EventType.medical),
  _MedicalMilestone(16, 'تحاليل الثلث الثاني', 'تحليل AFP / الفحص الرباعي لتشوهات الأنبوب العصبي', _EventType.labTest),
  _MedicalMilestone(20, 'سونار التشريحي المفصل', 'فحص أعضاء الجنين بالتفصيل + تحديد الجنس', _EventType.ultrasound),
  _MedicalMilestone(24, 'فحص سكري الحمل', 'اختبار تحمل الجلوكوز (OGTT) — شرب محلول سكري', _EventType.labTest),
  _MedicalMilestone(26, 'تحاليل + فحص روتيني', 'فحص دم، حديد، هيموغلوبين، ضغط', _EventType.labTest),
  _MedicalMilestone(28, 'حقنة Anti-D (إن لزم)', 'للأمهات بفصيلة Rh سالب — تطعيم وقائي', _EventType.vaccine),
  _MedicalMilestone(30, 'فحص الثلث الثالث', 'متابعة نمو الجنين، وضعيته، السائل الأمنيوسي', _EventType.medical),
  _MedicalMilestone(32, 'سونار النمو', 'تقييم حجم الجنين ونموه + كمية الماء', _EventType.ultrasound),
  _MedicalMilestone(34, 'فحص GBS', 'مسحة المكورات العقدية مجموعة B', _EventType.labTest),
  _MedicalMilestone(36, 'فحص أسبوعي', 'بدء الفحوصات الأسبوعية — وضعية الجنين، عنق الرحم', _EventType.medical),
  _MedicalMilestone(37, 'تطعيم السعال الديكي', 'لقاح Tdap لحماية الطفل في أسابيعه الأولى', _EventType.vaccine),
  _MedicalMilestone(38, 'فحص + تخطيط NST', 'تخطيط قلب الجنين Non-Stress Test', _EventType.medical),
  _MedicalMilestone(39, 'فحص ما قبل الولادة', 'تقييم جاهزية الولادة — عنق الرحم، وضعية الرأس', _EventType.medical),
  _MedicalMilestone(40, 'موعد الولادة المتوقع', 'اليوم المنتظر! مناقشة خطة الولادة مع الطبيب', _EventType.milestone),
];
