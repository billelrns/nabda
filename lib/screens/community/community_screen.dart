import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/community_post_model.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedCategory = 'all';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'مجتمع نبضة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-post'),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('منشور جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildPostFeed()),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categoryLabels.entries.map((entry) {
            final isSelected = _selectedCategory == entry.key;
            final color = entry.key == 'all'
                ? const Color(0xFF00897B)
                : (_categoryColors[entry.key] ?? const Color(0xFF00897B));
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = entry.key),
                selectedColor: color,
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPostFeed() {
    final category = _selectedCategory == 'all' ? null : _selectedCategory;
    return StreamBuilder<List<CommunityPostModel>>(
      stream: _firestoreService.getPosts(category: category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00897B)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 12),
                Text(
                  'حدث خطأ في تحميل المنشورات',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) return _buildEmptyState();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(posts[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد منشورات بعد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'كوني أول من يشارك في المجتمع!',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPostModel post) {
    final isLiked = _currentUserId != null && post.likedBy.contains(_currentUserId);
    final categoryColor = _categoryColors[post.category] ?? const Color(0xFF00897B);
    final categoryLabel = _categoryLabels[post.category] ?? post.category;
    final displayName = post.isAnonymous ? 'مجهولة' : post.author;
    final avatarText = post.isAnonymous ? 'م' : (post.author.isNotEmpty ? post.author[0] : '؟');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/post/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: categoryColor.withOpacity(0.12),
                    child: Text(
                      avatarText,
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      categoryLabel,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              // Content preview
              if (post.content.isNotEmpty)
                Text(
                  post.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              // Image thumbnail
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildPostImage(post.imageUrl!, height: 180),
                ),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 10),
              // Actions
              Row(
                children: [
                  _buildActionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likes}',
                    color: isLiked ? Colors.red.shade400 : Colors.grey.shade500,
                    onTap: () => _toggleLike(post),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.comments.length}',
                    color: Colors.grey.shade500,
                    onTap: () => context.push('/post/${post.id}'),
                  ),
                  const Spacer(),
                  if (post.comments.isNotEmpty)
                    Text(
                      'اقرأ المزيد ›',
                      style: TextStyle(
                        color: const Color(0xFF00897B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildPostImage(String data, {double height = 180}) {
    try {
      final Uint8List bytes = base64Decode(data);
      return Image.memory(
        bytes,
        height: height,
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
}
