import 'package:flutter/material.dart';

class PostCard extends StatefulWidget {
  final String title;
  final String content;
  final String author;
  final String category;
  final int initialLikes;
  final int commentCount;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const PostCard({
    Key? key,
    required this.title,
    required this.content,
    required this.author,
    required this.category,
    this.initialLikes = 0,
    this.commentCount = 0,
    this.onLike,
    this.onComment,
    this.onShare,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _likes;
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _likes = widget.initialLikes;
    _isLiked = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]\!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(widget.author[0]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.author,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Chip(
                      label: Text(widget.category),
                      labelStyle: const TextStyle(fontSize: 11),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLiked = \!_isLiked;
                    _likes = _isLiked ? _likes + 1 : _likes - 1;
                  });
                  widget.onLike?.call();
                },
                child: Row(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: _isLiked ? const Color(0xFFE91E63) : null,
                    ),
                    const SizedBox(width: 5),
                    Text('$_likes'),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onComment,
                child: Row(
                  children: [
                    const Icon(Icons.comment_outlined, size: 16),
                    const SizedBox(width: 5),
                    Text('${widget.commentCount}'),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onShare,
                child: const Icon(Icons.share_outlined, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
