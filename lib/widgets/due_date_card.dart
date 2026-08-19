import 'package:flutter/material.dart';

import '../services/pregnancy_dates_service.dart';

/// بطاقة «تاريخ الولادة المتوقّع» — تعرض التاريخ ومصدره وتتيح التعديل
class DueDateCard extends StatefulWidget {
  final Color color;
  final VoidCallback? onChanged;
  final bool compact;

  const DueDateCard({
    Key? key,
    this.color = const Color(0xFFE0195B),
    this.onChanged,
    this.compact = false,
  }) : super(key: key);

  @override
  State<DueDateCard> createState() => _DueDateCardState();
}

class _DueDateCardState extends State<DueDateCard> {
  PregnancyDates _d = const PregnancyDates();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await PregnancyDates.load();
    if (mounted) setState(() { _d = d; _loading = false; });
  }

  static const _months = [
    '', 'جانفي', 'فيفري', 'مارس', 'أفريل', 'ماي', 'جوان',
    'جويلية', 'أوت', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  String _fmt(DateTime d) => '${d.day} ${_months[d.month]} ${d.year}';

  Future<void> _edit() async {
    final now = DateTime.now();
    final initial = _d.effectiveDueDate ?? now.add(const Duration(days: 200));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 300)),
      helpText: 'تاريخ الولادة المتوقّع',
      cancelText: 'إلغاء',
      confirmText: 'التالي',
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: widget.color),
          ),
          child: child!,
        ),
      ),
    );
    if (picked == null || !mounted) return;

    final source = await _askSource();
    if (source == null || !mounted) return;

    await PregnancyDates.saveDueDate(picked, source);
    await _load();
    widget.onChanged?.call();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تحديث تاريخ الولادة وكل الشاشات'),
          backgroundColor: widget.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _askSource() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'ما مصدر هذا التاريخ؟',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1A20)),
              ),
              const SizedBox(height: 6),
              Text(
                'يساعدنا على دقّة المتابعة والتذكيرات',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ...PregnancyDates.sources.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, e.key),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: widget.color.withOpacity(0.18)),
                        ),
                        child: Row(
                          children: [
                            Icon(_iconFor(e.key), size: 20, color: widget.color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF1F1A20)),
                              ),
                            ),
                            Icon(Icons.arrow_back_ios, size: 13, color: widget.color),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'doctor':
        return Icons.medical_services_outlined;
      case 'ultrasound':
        return Icons.monitor_heart_outlined;
      case 'lmp':
        return Icons.event_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final due = _d.effectiveDueDate;
    final left = _d.daysLeft;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _edit,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(widget.compact ? 14 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.color.withOpacity(0.18)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.child_friendly_outlined, color: widget.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'تاريخ الولادة المتوقّع',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        due == null ? 'لم يُحدَّد بعد — اضغطي للإضافة' : _fmt(due),
                        style: TextStyle(
                          fontSize: due == null ? 13.5 : 16.5,
                          fontWeight: FontWeight.w800,
                          color: due == null ? Colors.grey.shade600 : const Color(0xFF1F1A20),
                        ),
                      ),
                      if (due != null) ...[
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _chip(
                              left >= 0 ? 'باقي $left يوماً' : 'مرّ ${-left} يوماً على الموعد',
                              widget.color,
                            ),
                            if (_d.sourceLabel.isNotEmpty)
                              _chip('المصدر: ${_d.sourceLabel}', const Color(0xFF00897B)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 13, color: widget.color),
                      const SizedBox(width: 4),
                      Text(
                        'تعديل',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: widget.color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c),
        ),
      );
}
