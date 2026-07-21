import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// Baby Names Screen — نسخة مبسّطة قابلة للتوسّع لاحقًا
// ══════════════════════════════════════════════════════════════

class BabyName {
  final String name;
  final String gender;
  final String meaning;
  final int popularityRank;
  final List<String> countries;
  final bool isIslamic;
  const BabyName(this.name, this.gender, this.meaning, this.popularityRank, this.countries, {this.isIslamic = false});
}

class BabyNamesScreen extends StatelessWidget {
  const BabyNamesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: const Text('أسماء المواليد', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFC2185B),
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: const Text('👶', style: TextStyle(fontSize: 56)),
                ),
                const SizedBox(height: 22),
                const Text(
                  'قسم أسماء المواليد',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F1A20)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'قيد التطوير — قريبًا مجموعة كبيرة من أسماء البنات والأولاد من الجزائر والمغرب العربي والخليج والشام ومصر بأصولها ومعانيها.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF8F8795), height: 1.8),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFF8D7E5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFF43F7E)),
                      SizedBox(width: 8),
                      Text('قريبًا', style: TextStyle(color: Color(0xFFF43F7E), fontWeight: FontWeight.w800)),
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
}
