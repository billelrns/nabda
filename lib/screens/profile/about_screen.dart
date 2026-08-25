import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../onboarding_screen.dart' show PrivacyPolicyPage, TermsOfServicePage;

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: const Text('عن التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Logo & App Name
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo_nabda_foreground.png',
                    width: 65,
                    height: 65,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.favorite,
                      color: Color(0xFFE91E63),
                      size: 45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'نبضة',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'صحة المرأة العربية ورعاية الأمومة',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'الإصدار 1.0.0',
                  style: TextStyle(fontSize: 12, color: Color(0xFF00897B), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Description Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(
                        'نبضة هو رفيقتكِ الموثوقة والشاملة في جميع مراحل رحلتكِ الصحية والأسرية: من التخطيط للحمل، مروراً بمتابعة أسابيع وتطورات الجنين بدقة، وحتى رعاية وتربية طفلكِ والاهتمام بصحتكِ وجمالكِ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _featureBadge(Icons.menu_book, '300+ مقال طبي'),
                          _featureBadge(Icons.pregnant_woman, 'متابعة أسبوعية'),
                          _featureBadge(Icons.psychology, 'مساعد ذكي'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Official Links Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 1,
                child: Column(
                  children: [
                    _linkTile(
                      icon: Icons.email_outlined,
                      color: const Color(0xFF00897B),
                      title: 'تواصلي مع فريق العمل',
                      subtitle: 'matbakhwalid@gmail.com',
                      onTap: () => _openUrl('mailto:matbakhwalid@gmail.com'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _linkTile(
                      icon: Icons.language,
                      color: Colors.blue.shade600,
                      title: 'الموقع الإلكتروني الرسمي',
                      subtitle: 'nabda.online',
                      onTap: () => _openUrl('https://nabda.online'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _linkTile(
                      icon: Icons.privacy_tip_outlined,
                      color: Colors.purple.shade600,
                      title: 'سياسة الخصوصية',
                      subtitle: 'حماية بياناتكِ وخصوصيتكِ أولويتنا',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _linkTile(
                      icon: Icons.description_outlined,
                      color: Colors.orange.shade700,
                      title: 'الشروط والأحكام',
                      subtitle: 'شروط استخدام تطبيق نبضة',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'صُنع بحب 💖 لجميع الأمهات والنساء في الوطن العربي',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00897B), size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _linkTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
