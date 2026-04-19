import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';

class CycleDashboard extends StatefulWidget {
  const CycleDashboard({Key? key}) : super(key: key);

  @override
  State<CycleDashboard> createState() => _CycleDashboardState();
}

class _CycleDashboardState extends State<CycleDashboard> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقويم الدورة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المتوسط الحالي للدورة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '28 يومًا',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFFE91E63),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'التنبؤات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildPredictionCard(
              title: 'بداية الفترة',
              date: 'في 12 يومًا',
              icon: Icons.calendar_today,
              color: const Color(0xFFE91E63),
            ),
            const SizedBox(height: 10),
            _buildPredictionCard(
              title: 'فترة الإباضة',
              date: 'في 20 يومًا',
              icon: Icons.favorite,
              color: const Color(0xFF00897B),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => context.go('/symptom-logger'),
              icon: const Icon(Icons.note_add),
              label: const Text('تسجيل الملاحظات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard({
    required String title,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






