import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SymptomLogger extends StatefulWidget {
  const SymptomLogger({Key? key}) : super(key: key);

  @override
  State<SymptomLogger> createState() => _SymptomLoggerState();
}

class _SymptomLoggerState extends State<SymptomLogger> {
  String _selectedMood = 'normal';
  String _selectedFlow = 'normal';
  List<String> _selectedSymptoms = [];
  late TextEditingController _notesController;

  final List<String> symptoms = [
    'صداع',
    'آلام في البطن',
    'آلام في الظهر',
    'إرهاق',
    'قلق',
    'تقلب المزاج',
    'انتفاخ',
    'حب شباب',
  ];

  final Map<String, String> moods = {
    'very_bad': '😢',
    'bad': '😟',
    'normal': '😊',
    'good': '😄',
    'very_good': '😍',
  };

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الأعراض'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'كيف تشعرين اليوم؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: moods.entries.map((entry) {
                  final isSelected = _selectedMood == entry.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMood = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFFE91E63).withOpacity(0.2)
                              : Colors.grey[100],
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE91E63)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'غزارة الفترة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildFlowButton('light', 'خفيفة'),
                const SizedBox(width: 10),
                _buildFlowButton('normal', 'عادية'),
                const SizedBox(width: 10),
                _buildFlowButton('heavy', 'غزيرة'),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'الأعراض',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: symptoms.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: const Color(0xFFE91E63).withOpacity(0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text(
              'ملاحظات إضافية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'أضيفي أي ملاحظات إضافية...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل الأعراض بنجاح')),
                );
                context.go('/home');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowButton(String value, String label) {
    final isSelected = _selectedFlow == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFlow = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE91E63)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
