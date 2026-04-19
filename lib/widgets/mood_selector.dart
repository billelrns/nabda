import 'package:flutter/material.dart';

class MoodSelector extends StatefulWidget {
  final Function(String) onMoodSelected;
  final String? initialMood;

  const MoodSelector({
    Key? key,
    required this.onMoodSelected,
    this.initialMood,
  }) : super(key: key);

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  late String _selectedMood;

  final Map<String, String> moods = {
    'very_bad': '😢',
    'bad': '😟',
    'normal': '😊',
    'good': '😄',
    'very_good': '😍',
  };

  final Map<String, String> moodLabels = {
    'very_bad': 'سيء جداً',
    'bad': 'سيء',
    'normal': 'عادي',
    'good': 'جيد',
    'very_good': 'ممتاز',
  };

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood ?? 'normal';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: moods.entries.map((entry) {
          final isSelected = _selectedMood == entry.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedMood = entry.key);
                widget.onMoodSelected(entry.key);
              },
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFFE91E63).withOpacity(0.2)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE91E63)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    moodLabels[entry.key]!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}






