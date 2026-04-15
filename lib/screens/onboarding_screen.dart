import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  String _selectedMode = 'cycle';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() => _currentPage = page);
        },
        children: [
          _buildWelcomePage(),
          _buildModePage(),
          _buildFinalPage(),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Container(
      color: const Color(0xFF00897B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite, size: 80, color: Colors.white),
          const SizedBox(height: 30),
          const Text(
            'أهلاً بك في نبضة',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'تطبيق شامل لصحة المرأة يساعدك على متابعة دورتك الشهرية والحمل وصحة طفلك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              child: Text('التالي'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePage() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ما هو اهتمامك الرئيسي؟',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          _buildModeCard(
            icon: Icons.calendar_today,
            title: 'تتبع الدورة',
            description: 'تابعي دورتك الشهرية والأعراض',
            value: 'cycle',
          ),
          const SizedBox(height: 20),
          _buildModeCard(
            icon: Icons.pregnant_woman,
            title: 'الحمل',
            description: 'متابعة فترة الحمل والنمو',
            value: 'pregnancy',
          ),
          const SizedBox(height: 20),
          _buildModeCard(
            icon: Icons.child_care,
            title: 'صحة الطفل',
            description: 'متابعة نمو وصحة طفلك',
            value: 'baby',
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              child: Text('التالي'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String description,
    required String value,
  }) {
    final isSelected = _selectedMode == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE91E63).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFE91E63) : Colors.grey[300]\!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF00897B)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalPage() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Color(0xFF00897B)),
          const SizedBox(height: 30),
          const Text(
            'جاهزة للبدء\!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'أنتِ على بُعد خطوات قليلة من متابعة صحتك بكل سهولة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              child: Text('تسجيل الدخول'),
            ),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () {
              context.go('/register');
            },
            child: const Text(
              'إنشاء حساب جديد',
              style: TextStyle(color: Color(0xFF00897B)),
            ),
          ),
        ],
      ),
    );
  }
}
