import 'package:flutter/material.dart';

class KickCounterScreen extends StatefulWidget {
  const KickCounterScreen({Key? key}) : super(key: key);

  @override
  State<KickCounterScreen> createState() => _KickCounterScreenState();
}

class _KickCounterScreenState extends State<KickCounterScreen> {
  int _kickCount = 0;
  DateTime? _startTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عداد الركلات'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'عد ركلات طفلك',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE91E63).withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  '$_kickCount',
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_startTime != null)
              Text(
                'الوقت المنقضي: ${DateTime.now().difference(_startTime!).inMinutes} دقيقة',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _kickCount++;
                  _startTime ??= DateTime.now();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'سجل ركلة',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _kickCount = 0;
                  _startTime = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
              child: const Text('إعادة تعيين'),
            ),
          ],
        ),
      ),
    );
  }
}






