import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leaderboard_screen.dart';
import 'post_detail_screen.dart';
import '../messaging/chat_room_screen.dart';
import '../../services/messaging_service.dart';

// ─── Theme ───
const Color _bg = Color(0xFFFAF5F5);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);

// ═══════════════════════════════════════════════
//  USER PROFILE SCREEN
// ═══════════════════════════════════════════════
class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _activityTab = 'posts'; // posts, photos

  bool get _isOwnProfile => FirebaseAuth.instance.currentUser?.uid == widget.userId;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: _card,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users_directory').doc(widget.userId).snapshots(),
            builder: (_, snap) {
              if (!snap.hasData || !snap.data!.exists) return const Text('...');
              final d = snap.data!.data() as Map<String, dynamic>;
              return Text('@${d['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 16));
            },
          ),
          actions: [
            if (!_isOwnProfile)
              IconButton(
                icon: const Icon(Icons.more_vert, size: 22),
                onPressed: () => _showOptionsSheet(),
              ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users_directory').doc(widget.userId).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _teal));
            }
            if (!snap.hasData || !snap.data!.exists) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.person_off_outlined, size: 60, color: _text2.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text('المستخدمة غير موجودة', style: TextStyle(color: _text2)),
              ]));
            }
            final d = snap.data!.data() as Map<String, dynamic>;
            return ListView(
              children: [
                _buildProfileHeader(d),
                _buildBio(d),
                _buildMemberSince(d),
                _buildStats(d),
                _buildBadgesAndRank(d),
                const SizedBox(height: 16),
                _buildActivityTabs(),
                _buildActivityContent(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> d) {
    final name = d['name'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final followersCount = d['followersCount'] ?? 0;
    final followingCount = d['followingCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: _card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 42,
            backgroundColor: _teal.withOpacity(0.1),
            backgroundImage: d['photoUrl'] != null && (d['photoUrl'] as String).isNotEmpty
              ? NetworkImage(d['photoUrl']) : null,
            child: d['photoUrl'] == null || (d['photoUrl'] as String).isEmpty
              ? Text(initial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _teal))
              : null,
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _counterCol('$followersCount', 'متابِعات'),
                _counterCol('$followingCount', 'متابَعات'),
              ],
            ),
            const SizedBox(height: 12),
            // Buttons
            if (!_isOwnProfile)
              Row(children: [
                Expanded(child: FollowButton(targetUserId: widget.userId)),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final myUid = FirebaseAuth.instance.currentUser?.uid;
                      if (myUid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يجب تسجيل الدخول أولاً'), backgroundColor: _teal),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(color: _teal),
                        ),
                      );

                      try {
                        final chatId = await MessagingService().getOrCreateChat(myUid, widget.userId);
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(chatId: chatId)));
                        }
                      } catch (_) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('حدث خطأ أثناء فتح المحادثة'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: _text2.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(child: Text('رسالة', style: TextStyle(color: _text2, fontSize: 12, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ]),
          ])),
        ],
      ),
    );
  }

  Widget _counterCol(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text1)),
      Text(label, style: TextStyle(fontSize: 11, color: _text2)),
    ]);
  }

  Widget _buildBio(Map<String, dynamic> d) {
    final name = d['name'] ?? '';
    final bio = d['bio'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      color: _card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _text1)),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(bio, style: TextStyle(fontSize: 13, color: _text2, height: 1.5), maxLines: 4, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }

  Widget _buildMemberSince(Map<String, dynamic> d) {
    DateTime? createdAt;
    if (d['createdAt'] is Timestamp) {
      createdAt = (d['createdAt'] as Timestamp).toDate();
    }
    final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      color: _card,
      child: Row(children: [
        Icon(Icons.group_outlined, size: 18, color: _text2),
        const SizedBox(width: 6),
        Text(
          createdAt != null
            ? 'عضوة منذ ${months[createdAt.month - 1]} ${createdAt.year}'
            : 'عضوة في المجتمع',
          style: TextStyle(fontSize: 12, color: _text2),
        ),
      ]),
    );
  }

  Widget _buildStats(Map<String, dynamic> d) {
    final points = d['communityPoints'] ?? 0;
    final posts = d['postCount'] ?? 0;
    final likes = d['receivedLikes'] ?? 0;
    final comments = d['commentCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.stars, '$points', 'نقاط', const Color(0xFFFFB300)),
          _statItem(Icons.edit_note, '$posts', 'منشورات', const Color(0xFF66BB6A)),
          _statItem(Icons.favorite, '$likes', 'إعجابات', _pink),
          _statItem(Icons.chat_bubble_outline, '$comments', 'تعليقات', const Color(0xFF42A5F5)),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: _text2)),
    ]);
  }

  // ─── الشارات والترتيب العام ───
  static const Map<String, (String, IconData, Color)> _badgeMeta = {
    'official': ('حساب رسمي', Icons.verified, _teal),
    'active': ('مساهمة نشطة', Icons.local_fire_department, Color(0xFFFF9800)),
    'helpful': ('مفيدة', Icons.favorite, _pink),
    'expert': ('خبيرة', Icons.workspace_premium, Color(0xFF9C27B0)),
    'new_mom': ('أم جديدة', Icons.child_care, Color(0xFF2196F3)),
    'top_contributor': ('أفضل مساهمة', Icons.emoji_events, Color(0xFFFFB300)),
  };

  /// ترتيب العضوة العام = عدد من يفوقها نقاطاً + 1 (عبر عدّاد تجميعي).
  Future<int> _computeRank(int points) async {
    try {
      final agg = await FirebaseFirestore.instance
          .collection('users_directory')
          .where('communityPoints', isGreaterThan: points)
          .count()
          .get();
      return (agg.count ?? 0) + 1;
    } catch (_) {
      return 0;
    }
  }

  Widget _buildBadgesAndRank(Map<String, dynamic> d) {
    final badges = (d['badges'] is List) ? List<String>.from(d['badges']) : <String>[];
    final points = (d['communityPoints'] is int) ? d['communityPoints'] as int : 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // الترتيب العام
        Row(children: [
          const Icon(Icons.emoji_events, color: Color(0xFFFFB300), size: 20),
          const SizedBox(width: 8),
          const Text('الترتيب العام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _text1)),
          const Spacer(),
          FutureBuilder<int>(
            future: _computeRank(points),
            builder: (_, s) {
              if (!s.hasData) return const Text('…', style: TextStyle(color: _text2));
              final r = s.data!;
              return Text(r > 0 ? '#$r' : '—',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _teal));
            },
          ),
        ]),
        const Divider(height: 22),
        const Text('الشارات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _text1)),
        const SizedBox(height: 10),
        if (badges.isEmpty)
          Text('لا شارات بعد — تُكتسَب بالمشاركة وكسب النقاط 💪',
              style: TextStyle(fontSize: 12, color: _text2))
        else
          Wrap(spacing: 8, runSpacing: 8, children: badges.map(_badgeChip).toList()),
      ]),
    );
  }

  Widget _badgeChip(String key) {
    final m = _badgeMeta[key];
    if (m == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: m.$3.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(m.$2, size: 16, color: m.$3),
        const SizedBox(width: 6),
        Text(m.$1, style: TextStyle(color: m.$3, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  Widget _buildActivityTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        _tabChip('المنشورات', 'posts', _pink),
        const SizedBox(width: 8),
        _tabChip('الصور', 'photos', const Color(0xFF42A5F5)),
      ]),
    );
  }

  Widget _tabChip(String label, String value, Color color) {
    final isSelected = _activityTab == value;
    return GestureDetector(
      onTap: () => setState(() => _activityTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color.withOpacity(0.3) : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? color : _text2)),
      ),
    );
  }

  Widget _buildActivityContent() {
    if (_activityTab == 'photos') return _buildPhotosGrid();
    return _buildPostsList();
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('community_posts')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true).limit(20).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Column(children: [
              Icon(Icons.article_outlined, size: 48, color: _text2.withOpacity(0.3)),
              const SizedBox(height: 8),
              Text('لا توجد منشورات بعد', style: TextStyle(color: _text2)),
            ])),
          );
        }
        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _buildPostCard(doc.id, d);
          }).toList(),
        );
      },
    );
  }

  Widget _buildPostCard(String postId, Map<String, dynamic> d) {
    final content = d['content'] ?? d['title'] ?? '';
    final likes = d['likes'] ?? 0;
    final comments = (d['comments'] as List?)?.length ?? 0;
    final tags = <String>[];
    if (d['category'] != null) tags.add(d['category']);
    final createdAt = d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : DateTime.now();

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Author row
          Row(children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users_directory').doc(widget.userId).snapshots(),
              builder: (_, s) {
                final userData = s.data?.data() as Map<String, dynamic>? ?? {};
                final name = userData['name'] ?? '';
                return Row(children: [
                  CircleAvatar(
                    radius: 16, backgroundColor: _teal.withOpacity(0.1),
                    backgroundImage: userData['photoUrl'] != null && (userData['photoUrl'] as String).isNotEmpty
                      ? NetworkImage(userData['photoUrl']) : null,
                    child: userData['photoUrl'] == null || (userData['photoUrl'] as String).isEmpty
                      ? Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _teal))
                      : null,
                  ),
                  const SizedBox(width: 8),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _text1)),
                ]);
              },
            ),
            const Spacer(),
            Text(_timeAgo(createdAt), style: TextStyle(fontSize: 11, color: _text2)),
            if (!_isOwnProfile) ...[
              const SizedBox(width: 4),
              Icon(Icons.more_horiz, size: 18, color: _text2),
            ],
          ]),
          const SizedBox(height: 10),
          // Content
          Text(content, style: const TextStyle(fontSize: 14, color: _text1, height: 1.6),
            maxLines: 5, overflow: TextOverflow.ellipsis),
          // Tags
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Text(t, style: TextStyle(fontSize: 11, color: _text2)),
            )).toList()),
          ],
          const SizedBox(height: 10),
          // Likes & comments count
          Row(children: [
            Icon(Icons.favorite, size: 16, color: _pink),
            const SizedBox(width: 4),
            Text('$likes', style: TextStyle(fontSize: 12, color: _text2)),
            const Spacer(),
            Text('$comments تعليقات', style: TextStyle(fontSize: 12, color: _text2)),
          ]),
          Divider(height: 20, color: Colors.grey.shade200),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionBtn(Icons.favorite_border, 'أعجبني'),
              _actionBtn(Icons.chat_bubble_outline, 'تعليق'),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 18, color: _text2),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: _text2)),
    ]);
  }

  Widget _buildPhotosGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('community_posts')
        .where('userId', isEqualTo: widget.userId)
        .where('imageUrl', isNull: false)
        .orderBy('createdAt', descending: true).limit(20).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Column(children: [
              Icon(Icons.photo_library_outlined, size: 48, color: _text2.withOpacity(0.3)),
              const SizedBox(height: 8),
              Text('لا توجد صور بعد', style: TextStyle(color: _text2)),
            ])),
          );
        }
        final docs = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty;
        }).toList();
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text('لا توجد صور', style: TextStyle(color: _text2))),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(d['imageUrl'], fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200,
                    child: Icon(Icons.broken_image, color: _text2.withOpacity(0.3)))),
              );
            },
          ),
        );
      },
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('🙈', style: TextStyle(fontSize: 24)),
              title: Text('حظر هذه العضوة', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await FirebaseFirestore.instance.collection('users').doc(uid)
                    .collection('blocked').doc(widget.userId).set({'blockedAt': FieldValue.serverTimestamp()});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حظر العضوة'), backgroundColor: _teal));
                    Navigator.pop(context);
                  }
                }
              },
            ),
            ListTile(
              leading: const Text('📢', style: TextStyle(fontSize: 24)),
              title: Text('الإبلاغ عن هذه العضوة', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await FirebaseFirestore.instance.collection('reports').add({
                    'reportedUserId': widget.userId,
                    'reportedBy': uid,
                    'type': 'user',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال البلاغ. شكراً لمساعدتنا!'), backgroundColor: _teal));
                  }
                }
              },
            ),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return '${diff.inMinutes}د';
    if (diff.inHours < 24) return '${diff.inHours}س';
    if (diff.inDays < 7) return '${diff.inDays}ي';
    return '${diff.inDays ~/ 7}أ';
  }
}
