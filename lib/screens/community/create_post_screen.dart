import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/community_post_model.dart';

const int _maxImageBytes = 500 * 1024; // 500 KB

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isAnonymous = false;
  bool _isLoading = false;
  Uint8List? _imageBytes;

  static const Map<String, String> _categoryLabels = {
    'general': 'عام',
    'pregnancy': 'الحمل',
    'baby': 'رعاية الطفل',
    'cycle': 'الدورة الشهرية',
  };

  static const Map<String, IconData> _categoryIcons = {
    'general': Icons.chat_bubble_outline_rounded,
    'pregnancy': Icons.pregnant_woman_outlined,
    'baby': Icons.child_care_outlined,
    'cycle': Icons.calendar_month_outlined,
  };

  static const Map<String, Color> _categoryColors = {
    'general': Color(0xFF00897B),
    'pregnancy': Color(0xFF9C27B0),
    'baby': Color(0xFF2196F3),
    'cycle': Color(0xFFE91E63),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1024,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (bytes.length > _maxImageBytes) {
      if (mounted) {
        _showSnackbar(
          'الصورة أكبر من 500KB بعد الضغط. اختاري صورة أصغر.',
        );
      }
      return;
    }

    setState(() => _imageBytes = bytes);
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showSnackbar('الرجاء إضافة عنوان للمنشور');
      return;
    }
    if (content.isEmpty && _imageBytes == null) {
      _showSnackbar('الرجاء كتابة محتوى أو إضافة صورة');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      context.go('/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userModel = await _authService.getCurrentUser(currentUser.uid);
      final authorName = userModel?.name ?? 'مستخدمة';
      final newId =
          FirebaseFirestore.instance.collection('community_posts').doc().id;

      final String? imageBase64 =
          _imageBytes != null ? base64Encode(_imageBytes!) : null;

      final post = CommunityPostModel(
        id: newId,
        userId: currentUser.uid,
        title: title,
        content: content,
        author: authorName,
        category: _selectedCategory,
        imageUrl: imageBase64,
        isAnonymous: _isAnonymous,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addPost(post);

      if (mounted) {
        _showSnackbar('تم نشر المنشور بنجاح ✓', success: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnackbar('حدث خطأ أثناء النشر، حاولي مرة أخرى');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF00897B) : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'منشور جديد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: ElevatedButton(
                      onPressed: _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00897B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'نشر',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: _titleController,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'عنوان المنشور...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Content field
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: _contentController,
                  maxLines: 6,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'شاركي تجربتك أو سؤالك مع مجتمع نبضة...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildImageSection(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(right: 4, bottom: 10),
                child: Text(
                  'اختاري الفئة',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.8,
                children: _categoryLabels.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  final color = _categoryColors[entry.key]!;
                  return InkWell(
                    onTap: () =>
                        setState(() => _selectedCategory = entry.key),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : color.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : color.withOpacity(0.25),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _categoryIcons[entry.key],
                            color: isSelected ? Colors.white : color,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: SwitchListTile(
                  title: const Text(
                    'نشر بشكل مجهول',
                    textAlign: TextAlign.right,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'لن يظهر اسمك مع المنشور',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                  value: _isAnonymous,
                  onChanged: (val) =>
                      setState(() => _isAnonymous = val),
                  activeColor: const Color(0xFF00897B),
                  secondary: Icon(
                    _isAnonymous
                        ? Icons.visibility_off
                        : Icons.visibility_outlined,
                    color: const Color(0xFF00897B),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_imageBytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              _imageBytes!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () => setState(() => _imageBytes = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'تغيير',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Size indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(_imageBytes!.length / 1024).toStringAsFixed(0)} KB',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _pickImage,
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 22),
        label: const Text(
          'أضف صورة',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00897B),
          side: const BorderSide(color: Color(0xFF00897B), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
