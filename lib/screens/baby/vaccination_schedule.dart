import 'package:flutter/material.dart';

class VaccinationSchedule extends StatelessWidget {
  const VaccinationSchedule({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول التطعيمات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'التطعيمات المقررة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildVaccinationCard(
              age: 'عند الولادة',
              vaccines: ['BCG', 'شلل الأطفال'],
              status: 'مكتمل',
              isCompleted: true,
            ),
            const SizedBox(height: 15),
            _buildVaccinationCard(
              age: '6 أسابيع',
              vaccines: ['خماسي', 'الالتهاب الكبدي B', 'شلل الأطفال'],
              status: 'مكتمل',
              isCompleted: true,
            ),
            const SizedBox(height: 15),
            _buildVaccinationCard(
              age: '3 أشهر',
              vaccines: ['خماسي', 'شلل الأطفال', 'الدوران'],
              status: 'قريب جداً',
              isCompleted: false,
            ),
            const SizedBox(height: 15),
            _buildVaccinationCard(
              age: '6 أشهر',
              vaccines: ['خماسي', 'شلل الأطفال'],
              status: 'قادم',
              isCompleted: false,
            ),
            const SizedBox(height: 15),
            _buildVaccinationCard(
              age: '9 أشهر',
              vaccines: ['الحصبة والنكاف والحصبة الألمانية'],
              status: 'قادم',
              isCompleted: false,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملاحظات مهمة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'تأكدي من حضور جميع مواعيد التطعيمات في الوقت المحدد لضمان الحماية الكاملة لطفلك.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccinationCard({
    required String age,
    required List<String> vaccines,
    required String status,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF43A047).withOpacity(0.1)
            : Colors.amber.withOpacity(0.1),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF43A047).withOpacity(0.3)
              : Colors.amber.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF43A047)
                      : Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.schedule,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      age,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vaccines.map((vaccine) {
              return Chip(
                label: Text(vaccine),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}






