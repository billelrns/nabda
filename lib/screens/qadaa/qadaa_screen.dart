import 'package:flutter/material.dart';
import '../../models/qadaa_model.dart';
import '../../services/qadaa_service.dart';

/// شاشة متابعة أيام القضاء لشهر رمضان المبارك
class QadaaScreen extends StatefulWidget {
  final int? initialYear;

  const QadaaScreen({Key? key, this.initialYear}) : super(key: key);

  @override
  State<QadaaScreen> createState() => _QadaaScreenState();
}

class _QadaaScreenState extends State<QadaaScreen> {
  final QadaaService _service = QadaaService.instance;
  late int _selectedYear;
  final Set<int> _collapsedYears = {};

  static const Color _tealColor = Color(0xFF2CB5C4);
  static const Color _purpleColor = Color(0xFF7E57C2);
  static const Color _purpleDeep = Color(0xFF5E35B1);
  static const Color _inkColor = Color(0xFF1B1320);
  static const Color _mutedColor = Color(0xFF6B6470);

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? QadaaService.defaultYearInfo.year;
    _service.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openCalendarPicker({int? targetYear}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RamadanCalendarPickerSheet(
        initialYear: targetYear ?? _selectedYear,
        onSaved: (year, selectedDays) async {
          await _service.saveMissedDays(year, selectedDays);
          if (mounted) {
            setState(() {
              _selectedYear = year;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  selectedDays.isEmpty
                      ? 'تم حذف أيام القضاء لسنة $year'
                      : 'تم حفظ ${selectedDays.length} يوم قضاء لسنة $year بنجاح ✨',
                ),
                backgroundColor: _tealColor,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final activeYears = _service.activeYears;
        final bool hasData = activeYears.isNotEmpty;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.close, size: 18, color: Colors.black87),
                  ),
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: const Text(
                'أيام القضاء',
                style: TextStyle(
                  color: _inkColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Almarai',
                ),
              ),
            ),
            body: SafeArea(
              child: hasData ? _buildTrackingView(activeYears) : _buildEmptyStateView(),
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 1. الشاشة الترحيبية / الفارغة (مطابقة للصورة 5)
  // ════════════════════════════════════════════════════════════════
  Widget _buildEmptyStateView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // العناوين الترحيبية
                  const Text(
                    'أيام القضاء لشهر رمضان المبارك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _purpleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'خاصية تساعدك على حفظ و متابعة أيام القضاء',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // الرسم التوضيحي الأنيق لشهر رمضان
                  _buildRamadanIllustration(),

                  const SizedBox(height: 30),

                  // النص التوضيحي
                  const Text(
                    'تشمل أيام القضاء الحيض والحمل والرضاعة و النفاس\nوغيرها من الأسباب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _inkColor,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),
                  const SizedBox(height: 20),

                  // الزر السفلي "+ إضافة أيام القضاء"
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _openCalendarPicker(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tealColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'إضافة أيام القضاء',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.add_circle, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // رسم توضيحي لرمضان وتقويم الأيام
  Widget _buildRamadanIllustration() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6FC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _purpleColor.withOpacity(0.12), width: 1),
      ),
      child: Column(
        children: [
          // رأس التقويم التوضيحي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.nightlight_round, color: Color(0xFFFFB300), size: 20),
                  SizedBox(width: 6),
                  Text('🌙', style: TextStyle(fontSize: 18)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: _purpleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'رمضان المبارك',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _purpleDeep,
                  ),
                ),
              ),
              const Text('🏮', style: TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 16),

          // شبكة مصغرة تمثل تقويم رمضان
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    Text('س', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('ح', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('ن', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('ث', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('ر', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('خ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('ج', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(21, (i) {
                    final day = i + 1;
                    final isHighlighted = day >= 13 && day <= 18;
                    return Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isHighlighted
                            ? _purpleColor
                            : const Color(0xFFF0F0F0),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isHighlighted ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 2. شاشة المتابعة وقائمة الأيام (مطابقة للصورة 1 و 2)
  // ════════════════════════════════════════════════════════════════
  Widget _buildTrackingView(List<QadaaYearData> activeYears) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            itemCount: activeYears.length,
            itemBuilder: (context, index) {
              final yearData = activeYears[index];
              final isCollapsed = _collapsedYears.contains(yearData.year);

              return _buildYearCard(yearData, isCollapsed);
            },
          ),
        ),

        // الزر السفلي الثابت "تعديل أيام القضاء"
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _openCalendarPicker(targetYear: _selectedYear),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tealColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'تعديل أيام القضاء',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // بطاقة تتبع السنة
  Widget _buildYearCard(QadaaYearData yearData, bool isCollapsed) {
    final missedDays = yearData.missedDays;
    final completedDays = yearData.completedDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة (السنة وسهم الطي)
          InkWell(
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedYears.remove(yearData.year);
                } else {
                  _collapsedYears.add(yearData.year);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        yearData.titleAr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _purpleColor,
                        ),
                      ),
                      Icon(
                        isCollapsed
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: _purpleColor,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // نص التقدم: "1/2 يوم تم قضائهم"
                  Text(
                    '${yearData.totalCompleted}/${yearData.totalMissed} يوم تم قضائهم',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _inkColor,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // شريط التقدم البنفسجي
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: yearData.progressPercent,
                      minHeight: 5.5,
                      backgroundColor: const Color(0xFFE8E4EC),
                      valueColor: const AlwaysStoppedAnimation<Color>(_purpleColor),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // قائمة الأيام مع Checkbox (إذا كانت البطاقة مفتوحة)
          if (!isCollapsed) ...[
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                children: List.generate(missedDays.length, (index) {
                  final dayNum = missedDays[index];
                  final isDone = completedDays.contains(dayNum);
                  final ordinalName = _getArabicOrdinalName(index + 1);

                  return InkWell(
                    onTap: () {
                      _service.toggleDayCompleted(yearData.year, dayNum);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ordinalName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDone ? Colors.grey.shade400 : _inkColor,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ),
                          // Checkbox المخصص المطابق للصور
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDone ? _tealColor : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDone ? _tealColor : _tealColor.withOpacity(0.7),
                                width: 1.8,
                              ),
                            ),
                            child: isDone
                                ? const Center(
                                    child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // رسالة إتمام القضاء إن اكتملت كل الأيام
            if (yearData.isAllCompleted)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF81C784), width: 0.8),
                ),
                child: const Row(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'هنيئاً لكِ إتمام قضاء جميع الأيام المفطرة لهذا العام، تقبل الله منكِ صالح الأعمال 🤍',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _getArabicOrdinalName(int index) {
    const ordinals = [
      'اليوم الأول',
      'اليوم الثاني',
      'اليوم الثالث',
      'اليوم الرابع',
      'اليوم الخامس',
      'اليوم السادس',
      'اليوم السابع',
      'اليوم الثامن',
      'اليوم التاسع',
      'اليوم العاشر',
      'اليوم الحادي عشر',
      'اليوم الثاني عشر',
      'اليوم الثالث عشر',
      'اليوم الرابع عشر',
      'اليوم الخامس عشر',
      'اليوم السادس عشر',
      'اليوم السابع عشر',
      'اليوم الثامن عشر',
      'اليوم التاسع عشر',
      'اليوم العشرون',
      'اليوم الحادي والعشرون',
      'اليوم الثاني والعشرون',
      'اليوم الثالث والعشرون',
      'اليوم الرابع والعشرون',
      'اليوم الخامس والعشرون',
      'اليوم السادس والعشرون',
      'اليوم السابع والعشرون',
      'اليوم الثامن والعشرون',
      'اليوم التاسع والعشرون',
      'اليوم الثلاثون',
    ];
    if (index >= 1 && index <= ordinals.length) {
      return ordinals[index - 1];
    }
    return 'اليوم $index';
  }
}

// ════════════════════════════════════════════════════════════════
// 3. نافذة اختيار أيام القضاء من تقويم رمضان (مطابقة للصورة 3 و 4)
// ════════════════════════════════════════════════════════════════
class _RamadanCalendarPickerSheet extends StatefulWidget {
  final int initialYear;
  final Function(int year, List<int> selectedDays) onSaved;

  const _RamadanCalendarPickerSheet({
    Key? key,
    required this.initialYear,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<_RamadanCalendarPickerSheet> createState() =>
      _RamadanCalendarPickerSheetState();
}

class _RamadanCalendarPickerSheetState
    extends State<_RamadanCalendarPickerSheet> {
  late int _currentYear;
  late Set<int> _selectedDays;

  static const Color _tealColor = Color(0xFF2CB5C4);
  static const Color _purpleColor = Color(0xFF7E57C2);
  static const Color _inkColor = Color(0xFF1B1320);

  @override
  void initState() {
    super.initState();
    _currentYear = widget.initialYear;
    _selectedDays = Set<int>.from(
      QadaaService.instance.getYearData(_currentYear)?.missedDays ?? [],
    );
  }

  void _switchYear(int newYear) {
    setState(() {
      _currentYear = newYear;
      _selectedDays = Set<int>.from(
        QadaaService.instance.getYearData(_currentYear)?.missedDays ?? [],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final yearInfo = QadaaService.getYearInfo(_currentYear);
    final offset = yearInfo.arabicWeekdayOffset;
    final totalDays = yearInfo.totalRamadanDays;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط السحب العلوي
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // رأس النافذة: زر الإغلاق + اختيار السنة
            Row(
              children: [
                IconButton(
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.close, size: 18, color: Colors.black87),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: PopupMenuButton<int>(
                      initialValue: _currentYear,
                      onSelected: _switchYear,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (ctx) => QadaaService.supportedRamadanYears.map((y) {
                        return PopupMenuItem<int>(
                          value: y.year,
                          child: Text(
                            y.titleAr,
                            style: TextStyle(
                              fontWeight: y.year == _currentYear
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: y.year == _currentYear ? _purpleColor : _inkColor,
                            ),
                          ),
                        );
                      }).toList(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            yearInfo.titleAr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _inkColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_left, size: 22, color: _inkColor),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // لموازنة زر الإغلاق
              ],
            ),

            const SizedBox(height: 18),

            // شريط أسماء أيام الأسبوع (السبت إلى الجمعة)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('السبت', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text('الأحد', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text('الاثنين', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text('الثلاثاء', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text('الأربعاء', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text('الخميس', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text('الجمعه', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),

            const SizedBox(height: 14),

            // شبكة أيام رمضان (1 إلى 30) مطابقة للصور
            _buildCalendarGrid(offset, totalDays),

            const SizedBox(height: 20),

            // النص الإرشادي
            const Text(
              'قومي بالضغط على اليوم الذي تريدين إضافته لأيام القضاء',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSaved(_currentYear, _selectedDays.toList());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tealColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'حفظ أيام القضاء',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(int offset, int totalDays) {
    // عدد الخلايا الكلي في الشبكة (الإزاحة + الأيام)
    final totalCells = offset + totalDays;
    final totalRows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(totalRows, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNumber = cellIndex - offset + 1;

              if (dayNumber < 1 || dayNumber > totalDays) {
                return const SizedBox(width: 38, height: 38);
              }

              final isSelected = _selectedDays.contains(dayNumber);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(dayNumber);
                    } else {
                      _selectedDays.add(dayNumber);
                    }
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // دائرة اليوم
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFEFEFEF),
                        border: Border.all(
                          color: isSelected
                              ? _purpleColor
                              : Colors.black.withOpacity(0.06),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? _purpleColor : _inkColor,
                          ),
                        ),
                      ),
                    ),

                    // علامة الصح البنفسجية عند التحديد (أسفل الدائرة)
                    if (isSelected)
                      Positioned(
                        bottom: -4,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _purpleColor,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
