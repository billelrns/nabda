import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PregnancyDashboard extends StatelessWidget {
  const PregnancyDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رحلة الحمل'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE91E63),
                    const Color(0xFF00897B),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأسبوع 20',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'من الحمل',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'تاريخ الاستحقاق: 15 أكتوبر 2024',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'نمو الطفل',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildBabySizeCard(),
            const SizedBox(height: 30),
            const Text(
              'المواعيد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildAppointmentCard(
              date: '25 مايو',
              type: 'فحص الدم',
              doctor: 'د. نور الدين',
            ),
            const SizedBox(height: 10),
            _buildAppointmentCard(
              date: '30 مايو',
              type: 'سونار',
              doctor: 'د. فاطمة',
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => context.go('/kick-counter'),
              icon: const Icon(Icons.touch_app),
              label: const Text('عد ركلات الطفل'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBabySizeCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حجم الجنين',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'حوالي حجم الجزرة',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            'الوزن: حوالي 300 غرام',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 5),
          Text(
            'الطول: حوالي 25 سم',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String date,
    required String type,
    required String doctor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]\!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF00897B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today, color: Color(0xFF00897B)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  '$date - $doctor',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
