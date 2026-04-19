import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المجتمع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/create-post'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('الكل', 'all'),
                  const SizedBox(width: 10),
                  _buildCategoryChip('الدورة', 'cycle'),
                  const SizedBox(width: 10),
                  _buildCategoryChip('الحمل', 'pregnancy'),
                  const SizedBox(width: 10),
                  _buildCategoryChip('الطفل', 'baby'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [
                _buildPostCard(
                  title: 'نصائح للتعامل مع آلام الدورة',
                  author: 'أم عمر',
                  category: 'cycle',
                  likes: 45,
                  comments: 12,
                  content: 'هناك عدة طرق فعالة للتخفيف من آلام الدورة الشهرية...',
                ),
                const SizedBox(height: 15),
                _buildPostCard(
                  title: 'تجربتي مع الحمل الأول',
                  author: 'أم محمد',
                  category: 'pregnancy',
                  likes: 67,
                  comments: 23,
                  content: 'أود أن أشارك تجربتي والدروس المستفادة منها...',
                ),
                const SizedBox(height: 15),
                _buildPostCard(
                  title: 'روتين الاستحمام اليومي للرضع',
                  author: 'أم سارة',
                  category: 'baby',
                  likes: 89,
                  comments: 34,
                  content: 'الاستحمام اليومي مهم جداً لصحة الطفل...',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = value);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: const Color(0xFFE91E63),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildPostCard({
    required String title,
    required String author,
    required String category,
    required int likes,
    required int comments,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(author[0]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Chip(
                      label: Text(category),
                      labelStyle: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_border, size: 16),
                  const SizedBox(width: 5),
                  Text('$likes'),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.comment_outlined, size: 16),
                  const SizedBox(width: 5),
                  Text('$comments'),
                ],
              ),
              const Icon(Icons.share_outlined, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}






