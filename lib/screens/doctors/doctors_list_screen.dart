import 'package:flutter/material.dart';

class DoctorsListScreen extends StatelessWidget {
  const DoctorsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأطباء'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'ابحثي عن طبيب...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDoctorCard(
              name: 'د. نور الدين',
              specialty: 'طبيب النساء والتوليد',
              rating: 4.8,
              reviewCount: 124,
              image: '👩‍⚕️',
            ),
            const SizedBox(height: 15),
            _buildDoctorCard(
              name: 'د. فاطمة محمود',
              specialty: 'طب الأطفال',
              rating: 4.7,
              reviewCount: 98,
              image: '👩‍⚕️',
            ),
            const SizedBox(height: 15),
            _buildDoctorCard(
              name: 'د. سارة علي',
              specialty: 'طب الأسرة',
              rating: 4.9,
              reviewCount: 156,
              image: '👩‍⚕️',
            ),
            const SizedBox(height: 15),
            _buildDoctorCard(
              name: 'د. أحمد حسن',
              specialty: 'الطب النفسي',
              rating: 4.6,
              reviewCount: 87,
              image: '👨‍⚕️',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required double rating,
    required int reviewCount,
    required String image,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(image, style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      specialty,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 5),
              Text(
                '$rating',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 5),
              Text(
                '($reviewCount تقييم)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('عرض المزيد'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('حجز موعد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}






