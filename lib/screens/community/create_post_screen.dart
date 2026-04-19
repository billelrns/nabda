import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String _selectedCategory = 'general';
  bool _isAnonymous = false;

  final List<String> categories = ['cycle', 'pregnancy', 'baby', 'general'];
  final Map<String, String> categoryLabels = {
    'cycle': 'الدورة الشهرية',
    'pregnancy': 'الحمل',
    'baby': 'الطفل',
    'general': 'عام',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء منشور جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'العنوان',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'أضيفي عنواناً جذاباً',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'المحتوى',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'شاركي تجربتك أو سؤالك...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'الفئة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(categoryLabels[category]!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 25),
            CheckboxListTile(
              value: _isAnonymous,
              onChanged: (value) {
                setState(() => _isAnonymous = value ?? false);
              },
              title: const Text('نشر المنشور بشكل مجهول'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نشر المنشور بنجاح')),
                );
                context.go('/community');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('نشر المنشور'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}






