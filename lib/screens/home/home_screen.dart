import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نبضة'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildCycleTab(),
          _buildCommunityTab(),
          _buildAIChatTab(),
          _buildDoctorsTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'الدورة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'المجتمع',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'الدعم الذكي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'الأطباء',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }

  Widget _buildCycleTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'دورتك الحالية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اليوم 5 من الدورة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'الفترة المتوقعة للانتهاء: 5 أيام',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'السجل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () => context.go('/cycle'),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('عرض التقويم الكامل'),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () => context.go('/symptom-logger'),
                  icon: const Icon(Icons.add),
                  label: const Text('تسجيل الأعراض'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () => context.go('/create-post'),
            icon: const Icon(Icons.add),
            label: const Text('إنشاء منشور'),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.group,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                const Text('لا توجد منشورات بعد'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/community'),
                  child: const Text('عرض المزيد'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIChatTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text('محادث ذكية'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/ai-chat'),
            child: const Text('ابدأ محادثة'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medical_services,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text('الأطباء المتاحون'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/doctors'),
            child: const Text('عرض الأطباء'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text('ملفك الشخصي'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/profile'),
            child: const Text('عرض الملف الشخصي'),
          ),
        ],
      ),
    );
  }
}
