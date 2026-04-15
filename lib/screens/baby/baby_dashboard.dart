import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BabyDashboard extends StatelessWidget {
  const BabyDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات الطفل'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.child_care, size: 50),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'محمد',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'عمر: 6 أشهر',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'المقاييس',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildMeasurementCard('الوزن', '7.5 كغ', Icons.scale),
            const SizedBox(height: 10),
            _buildMeasurementCard('الطول', '67 سم', Icons.height),
            const SizedBox(height: 10),
            _buildMeasurementCard('محيط الرأس', '42 سم', Icons.circle_outlined),
            const SizedBox(height: 30),
            const Text(
              'الحدود الرئيسية',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            _buildMilestoneCard('الابتسامة', '6 أسابيع', Icons.emoji_emotions),
            const SizedBox(height: 10),
            _buildMilestoneCard('الجلوس', '4-6 أشهر', Icons.chair),
            const SizedBox(height: 10),
            _buildMilestoneCard('الحبو', '6-10 أشهر', Icons.directions_walk),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => context.go('/vaccinations'),
              icon: const Icon(Icons.vaccines),
              label: const Text('جدول التطعيمات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]\!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00897B), size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(String milestone, String age, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63).withOpacity(0.05),
        border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  age,
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
