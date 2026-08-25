import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _titleC = TextEditingController();
  final _msgC = TextEditingController();

  String? _purpose = 'الدعم الفني';
  String? _problem = 'مشكلة تقنية';
  Uint8List? _screenshotBytes;
  String? _screenshotName;
  bool _sending = false;

  final _purposes = ['الدعم الفني', 'اقتراح', 'شكوى', 'استفسار', 'آخر'];
  final _problems = [
    'مشكلة في تسجيل الدخول',
    'مشكلة في المحتوى',
    'مشكلة في الإشعارات',
    'مشكلة في المتجر أو الطلبات',
    'مشكلة تقنية',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  Future<void> _prefillUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailC.text = user.email ?? '';
      _nameC.text = user.displayName ?? '';
      if (_nameC.text.isEmpty) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists && mounted) {
            final data = doc.data();
            setState(() {
              _nameC.text = data?['displayName'] ?? data?['name'] ?? '';
            });
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _titleC.dispose();
    _msgC.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _screenshotBytes = bytes;
        _screenshotName = img.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameC.text.trim().isEmpty ||
        _emailC.text.trim().isEmpty ||
        _titleC.text.trim().isEmpty ||
        _msgC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة (*)')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      String? imageUrl;
      if (_screenshotBytes != null) {
        final storageRef = FirebaseStorage.instance
            .ref('support_attachments/${DateTime.now().millisecondsSinceEpoch}_${_screenshotName ?? "screen.jpg"}');
        final uploadTask = await storageRef.putData(
          _screenshotBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('support_requests').add({
        'userId': uid,
        'name': _nameC.text.trim(),
        'email': _emailC.text.trim(),
        'purpose': _purpose,
        'problem': _problem,
        'title': _titleC.text.trim(),
        'message': _msgC.text.trim(),
        'screenshot': imageUrl,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم إرسال رسالتكِ بنجاح، سيتواصل معكِ فريق الدعم قريباً'),
            backgroundColor: Color(0xFF00897B),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الإرسال: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        appBar: AppBar(
          title: const Text('الدعم الفني', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.headset_mic, size: 36, color: Color(0xFF00897B)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'نحن هنا لمساعدتكِ والإجابة على استفساراتكِ وملاحظاتكِ دائماً.',
                        style: TextStyle(color: Colors.teal.shade900, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _field(_nameC, 'الاسم *', Icons.person_outline),
              const SizedBox(height: 12),
              _field(_emailC, 'البريد الإلكتروني *', Icons.email_outlined, TextInputType.emailAddress),
              const SizedBox(height: 12),
              _dropdown('الغرض من التواصل *', _purpose, _purposes, (v) => setState(() => _purpose = v)),
              const SizedBox(height: 12),
              _dropdown('نوع المشكلة', _problem, _problems, (v) => setState(() => _problem = v)),
              const SizedBox(height: 12),
              _field(_titleC, 'عنوان الرسالة *', Icons.title),
              const SizedBox(height: 12),
              _field(_msgC, 'اكتبي رسالتكِ هنا بالتفصيل *', Icons.message_outlined, TextInputType.multiline, 4),
              const SizedBox(height: 18),
              const Text(
                'إرفاق صورة أو لقطة شاشة (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00897B).withOpacity(0.5), width: 1.5),
                    color: Colors.white,
                  ),
                  child: _screenshotBytes != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(_screenshotBytes!, fit: BoxFit.cover, width: double.infinity),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                  onPressed: () => setState(() => _screenshotBytes = null),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: Color(0xFF00897B)),
                            SizedBox(height: 6),
                            Text('اضغطي هنا لرفع صورة أو لقطة شاشة', style: TextStyle(color: Color(0xFF00897B), fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _sending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('إرسال الطلب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, [TextInputType? type, int lines = 1]) {
    return TextField(
      controller: c,
      keyboardType: type,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00897B), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }
}
