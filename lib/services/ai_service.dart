import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIService {
  final String apiKey;
  final String baseUrl = 'https://api.openai.com/v1';

  AIService({this.apiKey = 'YOUR_API_KEY'});

  // ── جلب سياق المستخدمة من Firestore ──────────────────────────────

  Future<String> _buildUserContext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return '';

    final db = FirebaseFirestore.instance;
    final List<String> context = [];

    try {
      // بيانات المستخدمة الأساسية
      final userDoc = await db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final name = data['name'] ?? '';
        final mode = data['mode'] ?? 'cycle'; // cycle, pregnancy, baby
        if (name.isNotEmpty) context.add('اسم المستخدمة: $name');
        context.add('وضع التطبيق: ${_modeAr(mode)}');
      }

      // بيانات الحمل
      final pregnancyQ = await db.collection('pregnancies')
          .where('userId', isEqualTo: uid).limit(1).get();
      if (pregnancyQ.docs.isNotEmpty) {
        final p = pregnancyQ.docs.first.data();
        final dueDate = p['dueDate'];
        if (dueDate != null) {
          final due = dueDate is Timestamp ? dueDate.toDate() : DateTime.tryParse(dueDate.toString());
          if (due != null) {
            final weeksLeft = due.difference(DateTime.now()).inDays ~/ 7;
            final weekOfPregnancy = 40 - weeksLeft;
            if (weekOfPregnancy > 0 && weekOfPregnancy <= 42) {
              context.add('الأسبوع الحالي من الحمل: $weekOfPregnancy');
              context.add('موعد الولادة المتوقع: ${due.day}/${due.month}/${due.year}');
            }
          }
        }
      }

      // بيانات الدورة الشهرية
      final cycleQ = await db.collection('cycles')
          .where('userId', isEqualTo: uid)
          .orderBy('startDate', descending: true)
          .limit(1).get();
      if (cycleQ.docs.isNotEmpty) {
        final c = cycleQ.docs.first.data();
        final start = c['startDate'];
        if (start != null) {
          final startDate = start is Timestamp ? start.toDate() : DateTime.tryParse(start.toString());
          if (startDate != null) {
            final dayOfCycle = DateTime.now().difference(startDate).inDays + 1;
            final cycleLength = c['cycleLength'] ?? 28;
            context.add('اليوم $dayOfCycle من الدورة (دورة مدتها $cycleLength يوماً)');
          }
        }
      }

      // بيانات الطفل
      final babyQ = await db.collection('babies')
          .where('userId', isEqualTo: uid).limit(1).get();
      if (babyQ.docs.isNotEmpty) {
        final b = babyQ.docs.first.data();
        final birth = b['birthDate'];
        if (birth != null) {
          final birthDate = birth is Timestamp ? birth.toDate() : DateTime.tryParse(birth.toString());
          if (birthDate != null) {
            final ageMonths = DateTime.now().difference(birthDate).inDays ~/ 30;
            context.add('عمر الطفل: $ageMonths شهراً');
          }
        }
        if (b['name'] != null) context.add('اسم الطفل: ${b['name']}');
      }

      // الأدوية الحالية
      final medsQ = await db.collection('medications')
          .where('userId', isEqualTo: uid)
          .where('isActive', isEqualTo: true).get();
      if (medsQ.docs.isNotEmpty) {
        final medNames = medsQ.docs.map((d) => d.data()['name'] ?? '').where((n) => n.isNotEmpty).join('، ');
        context.add('الأدوية الحالية: $medNames');
      }

    } catch (_) {}

    return context.isEmpty ? '' : '\n\nمعلومات عن المستخدمة:\n${context.join('\n')}';
  }

  String _modeAr(String mode) {
    switch (mode) {
      case 'pregnancy': return 'متابعة الحمل';
      case 'baby': return 'رعاية الطفل';
      default: return 'متابعة الدورة الشهرية';
    }
  }

  // ── المحادثة مع AI ────────────────────────────────────────────────

  Future<String> chat(
    String message, {
    List<Map<String, String>> history = const [],
    List<String> tags = const [],
  }) async {
    try {
      final userContext = await _buildUserContext();

      final systemPrompt = '''أنتِ "نبضة"، مساعدة صحية متخصصة لدعم صحة المرأة العربية.
تقدمين معلومات دقيقة وآمنة حول الدورة الشهرية والحمل وصحة الأطفال والصحة العامة للمرأة.
أسلوبك دافئ ومتفهم، وتتحدثين بالعربية الفصحى المبسطة.
تذكّري دائماً بالرجوع للطبيب في الحالات الطبية الجدية.
لا تقدمي تشخيصات طبية قاطعة.${userContext}''';

      // بناء تاريخ المحادثة
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
        ...history.take(10), // آخر 10 رسائل فقط لتجنب تجاوز الـ token limit
        {'role': 'user', 'content': message},
      ];

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 600,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] ?? 'لم أستطع الرد على سؤالك';
      } else {
        throw Exception('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في معالجة الطلب: $e');
    }
  }

  Future<List<String>> getRecommendations(String topic) async {
    try {
      final userContext = await _buildUserContext();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'قدّمي نصائح طبية موثوقة بصيغة قائمة مرقمة باللغة العربية.$userContext',
            },
            {
              'role': 'user',
              'content': 'اعطيني نصائح حول: $topic',
            }
          ],
          'temperature': 0.5,
          'max_tokens': 400,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] ?? '';
        return content.split('\n').where((line) => line.trim().isNotEmpty).toList();
      } else {
        throw Exception('خطأ في جلب التوصيات');
      }
    } catch (e) {
      throw Exception('خطأ في معالجة الطلب: $e');
    }
  }
}
