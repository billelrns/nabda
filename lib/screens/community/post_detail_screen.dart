import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/community_post_model.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  static const Map<String, String> _categoryLabels = {
    'all': 'الكل',
    'pregnancy': 'الحمل',
    'baby': 'الطفل',
    'cycle': 'الدورة',
    'general': 'عام',
  };

  static const Map<String, Color> _categoryColors = {
    'cycle': Color(0xFFE91E63),
    'pregnancy': Color(0xFF9C27B0),
    'baby': Color(0xFF2196F3),
    'general': Color(0xFF00897B),
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(CommunityPostModel post) async {
    final uid = _currentUserId;
    if (uid == null) {
      context.go('/login');
      return;
    }
    try {
      await _firestoreService.toggleLike(post.id, uid);
    } catch (_) {}
  }

  Future<void> _submitComment(CommunityPostModel post) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      context.go('/login');
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      final userModel = await _authService.getCurrentUser(currentUser.uid);
      final authorName = userModel?.name ?? 'مستخدمة';

      final comment = {
        'userId': currentUser.uid,
        'author': authorName,
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestoreService.addComment(post.id, comment);
      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء إرسال التعليق')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Widget _buildPostImage(String data) {
    try {
      final Uint8List bytes = base64Decode(data);
      return Image.memory(
        bytes,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return 'منذ ${diff.inDays ~/ 7} أسبوع';
  }

  DateTime _parseCommentDate(dynamic val) {
    if (val == null) return DateTime.now();
    try {
      return DateTime.parse(val.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'تفاصيل المنشور',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF00897B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: StreamBuilder<CommunityPostModel?>(
          stream: _firestoreService.getPost(widget.postId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00897B)),
              );
            }
            final post = snapshot.data;
            if (post == null) {
              return const Center(
                child: Text('لم يتم العثور على المنشور'),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPostBody(post),
                      const SizedBox(height: 16),
                      _buildCommentsSection(post),
                    ],
                  ),
                ),
                _buildCommentInput(post),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostBody(CommunityPostModel post) {
    final isLiked = _currentUserId != null && post.likedBy.contains(_currentUserId);
    final categoryColor = _categoryColors[post.category] ?? const Color(0xFF00897B);
    final categoryLabel = _categoryLabels[post.category] ?? post.category;
    final displayName = post.isAnonymous ? 'مجهولة' : post.author;
    final avatarText = post.isAnonymous ? 'م' : (post.author.isNotEmpty ? post.author[0] : '؟');

    return Card(
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: categoryColor.withOpacity(0.12),
                      child: Text(
                        avatarText,
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _timeAgo(post.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        categoryLabel,
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                // Full content
                Text(
                  post.content,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          // Image (if present)
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: _buildPostImage(post.imageUrl!),
            ),
          if (post.imageUrl == null || post.imageUrl!.isEmpty)
            const SizedBox(height: 4),
          // Divider + actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likes} إعجاب',
                  color: isLiked ? Colors.red.shade400 : Colors.grey.shade600,
                  onTap: () => _toggleLike(post),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.comments.length} تعليق',
                  color: Colors.grey.shade600,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(CommunityPostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 4),
          child: Text(
            'التعليقات (${post.comments.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        if (post.comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  'لا توجد تعليقات بعد\nكوني أول من تعلّق!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...post.comments.map((comment) => _buildCommentCard(comment)),
      ],
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment) {
    final author = comment['author'] ?? 'مستخدمة';
    final text = comment['text'] ?? '';
    final createdAt = _parseCommentDate(comment['createdAt']);
    final avatarText = author.isNotEmpty ? author[0] : '؟';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF00897B).withOpacity(0.12),
            child: Text(
              avatarText,
              style: const TextStyle(
                color: Color(0xFF00897B),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(CommunityPostModel post) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      padding: EdgeInsets.only(
        right: 16,
        left: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'اكتبي تعليقك...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isSubmittingComment
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00897B)),
                  ),
                )
              : InkWell(
                  onTap: () => _submitComment(post),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00897B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
        ],
      ),
    );
  }
}
