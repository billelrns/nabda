import 'package:http/http.dart' as http;
import 'dart:convert';

class AIService {
  final String apiKey;
  final String baseUrl = 'https://api.openai.com/v1';

  AIService({this.apiKey = 'YOUR_API_KEY'});

  Future<String> chat(String message, {List<String> tags = const []}) async {
    try {
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
              'content':
                  'أنت مساعد صحي متخصص لدعم صحة المرأة. توفر معلومات دقيقة وآمنة حول الدورة الشهرية والحمل وصحة الأطفال.'
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'لم أستطع الرد على سؤالك';
      } else {
        throw Exception('خطأ في الاتصال مع الخادم: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في معالجة الطلب: $e');
    }
  }

  Future<List<String>> getRecommendations(String topic) async {
    try {
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
              'content': 'قدم نصائح طبية موثوقة بصيغة قائمة مرقمة'
            },
            {
              'role': 'user',
              'content': 'اعطني نصائح حول: $topic',
            }
          ],
          'temperature': 0.5,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] ?? '';
        return content.split('\n').where((line) => line.isNotEmpty).toList();
      } else {
        throw Exception('خطأ في جلب التوصيات');
      }
    } catch (e) {
      throw Exception('خطأ في معالجة الطلب: $e');
    }
  }
}






