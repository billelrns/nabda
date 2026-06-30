import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_screen.dart';

// ─── Theme ───
const Color _bg = Color(0xFFFAF5F5);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);
const Color _gold = Color(0xFFFFB300);

// ═══════════════════════════════════════════════
//  LEADERBOARD SCREEN
// ═══════════════════════════════════════════════
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'points';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          _buildHeader(),
          _buildPodium(),
          _buildSortBar(),
          _buildTabs(),
          Expanded(child: _buildRankingList()),
          _buildCurrentUserBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_pink.withOpacity(0.08), _bg],
        ),
      ),
      child: Column(children: [
        const Text('شكراً', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _text1)),
        const SizedBox(height: 4),
        Text('للأمهات اللواتي يساعدن المجتمع بانتظام',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _text2)),
      ]),
    );
  }

  Widget _buildPodium() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users_directory')
        .orderBy('communityPoints', descending: true).limit(3).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: _teal)));
        }
        final docs = snap.data!.docs;
        final top3 = <Map<String, dynamic>>[];
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          top3.add(data);
        }
        while (top3.length < 3) top3.add({'name': '—', 'communityPoints': 0});

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(children: [
            const Text('👑', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _podiumAvatar(top3[1], 2, 44),
                const SizedBox(width: 12),
                _podiumAvatar(top3[0], 1, 56),
                const SizedBox(width: 12),
                _podiumAvatar(top3[2], 3, 40),
              ],
            ),
          ]),
        );
      },
    );
  }

  Widget _podiumAvatar(Map<String, dynamic> user, int rank, double size) {
    final name = user['name'] ?? '—';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = {1: _gold, 2: const Color(0xFFB0BEC5), 3: const Color(0xFFCD7F32)};
    final borderColor = colors[rank] ?? _teal;

    return GestureDetector(
      onTap: () {
        if (user['id'] != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: user['id'])));
        }
      },
      child: Column(children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: rank == 1 ? 3.5 : 2.5),
            boxShadow: rank == 1 ? [BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 12)] : null,
          ),
          child: CircleAvatar(
            radius: size / 2 - 3,
            backgroundColor: borderColor.withOpacity(0.1),
            backgroundImage: user['photoUrl'] != null && (user['photoUrl'] as String).isNotEmpty
              ? NetworkImage(user['photoUrl']) : null,
            child: user['photoUrl'] == null || (user['photoUrl'] as String).isEmpty
              ? Text(initial, style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.bold, color: borderColor))
              : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(fontSize: rank == 1 ? 12 : 10, fontWeight: FontWeight.bold, color: _text1),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(children: [
        Expanded(child: Text('الترتيب', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _text1))),
        GestureDetector(
          onTap: _showSortOptions,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _pink.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.tune, size: 16, color: _pink),
              const SizedBox(width: 4),
              Text(_sortLabel(), style: TextStyle(fontSize: 12, color: _pink, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ]),
    );
  }

  String _sortLabel() {
    switch (_sortBy) {
      case 'posts': return 'المنشورات';
      case 'likes': return 'الإعجابات';
      case 'comments': return 'التعليقات';
      default: return 'النقاط';
    }
  }

  void _showSortOptions() {
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
            const SizedBox(height: 16),
            const Text('Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text1)),
            const SizedBox(height: 6),
            Text('لوحة الترتيب تكرّم الأمهات اللواتي يساعدن المجتمع أكثر',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _text2)),
            const SizedBox(height: 20),
            _sortOption(Icons.edit_note, 'بمنشوراتهن', 'posts', const Color(0xFF66BB6A)),
            _sortOption(Icons.favorite, 'بإعجاباتهن', 'likes', _pink),
            _sortOption(Icons.chat_bubble_outline, 'بتعليقاتهن', 'comments', const Color(0xFF42A5F5)),
            _sortOption(Icons.stars, 'بالنقاط الإجمالية', 'points', _gold),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }

  Widget _sortOption(IconData icon, String label, String value, Color color) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: _text1)),
      trailing: isSelected ? Icon(Icons.check_circle, color: _teal, size: 22) : null,
      onTap: () { setState(() => _sortBy = value); Navigator.pop(context); },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? _teal.withOpacity(0.05) : null,
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        indicatorColor: _text1, indicatorWeight: 2.5,
        labelColor: _text1, unselectedLabelColor: _text2,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [Tab(text: 'الكل'), Tab(text: 'الجدد')],
      ),
    );
  }

  Widget _buildRankingList() {
    return TabBarView(
      controller: _tabController,
      children: [_rankList(newOnly: false), _rankList(newOnly: true)],
    );
  }

  String _firestoreField() {
    switch (_sortBy) {
      case 'posts': return 'postCount';
      case 'likes': return 'receivedLikes';
      case 'comments': return 'commentCount';
      default: return 'communityPoints';
    }
  }

  Widget _rankList({required bool newOnly}) {
    // القراءة من الدليل العامّ الآمن (users محجوب بقواعد الخصوصية).
    final Query query = FirebaseFirestore.instance.collection('users_directory')
      .orderBy(_firestoreField(), descending: true).limit(50);
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _teal));
        }
        var docs = snap.data?.docs ?? [];
        // فلترة «الجدد» محليّاً (آخر 30 يوماً) لتفادي فهرس مركّب.
        if (newOnly) {
          final cut = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
          docs = docs.where((d) {
            final c = (d.data() as Map<String, dynamic>)['createdAt'];
            return c is Timestamp && c.compareTo(cut) > 0;
          }).toList();
        }
        if (docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.emoji_events_outlined, size: 60, color: _text2.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('لا توجد بيانات بعد', style: TextStyle(color: _text2)),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            final rank = i + 1;
            final name = d['name'] ?? 'مستخدمة';
            final points = d[_firestoreField()] ?? 0;
            final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            final rankColor = rank == 1 ? _gold : rank == 2 ? const Color(0xFFB0BEC5) : rank == 3 ? const Color(0xFFCD7F32) : _text2;

            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: doc.id))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _card, borderRadius: BorderRadius.circular(16),
                  border: rank <= 3 ? Border.all(color: rankColor.withOpacity(0.3)) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                ),
                child: Row(children: [
                  SizedBox(width: 32, child: Text('#$rank',
                    style: TextStyle(fontSize: rank <= 3 ? 18 : 14, fontWeight: FontWeight.bold, color: rankColor))),
                  CircleAvatar(
                    radius: 22, backgroundColor: _teal.withOpacity(0.1),
                    backgroundImage: d['photoUrl'] != null && (d['photoUrl'] as String).isNotEmpty
                      ? NetworkImage(d['photoUrl']) : null,
                    child: d['photoUrl'] == null || (d['photoUrl'] as String).isEmpty
                      ? Text(initial, style: TextStyle(fontWeight: FontWeight.bold, color: _teal, fontSize: 16)) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _text1),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(_formatPoints(points), style: TextStyle(fontSize: 12, color: _text2)),
                  ])),
                  FollowButton(targetUserId: doc.id),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  String _formatPoints(dynamic points) {
    final n = points is int ? points : (points is double ? points.toInt() : 0);
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _buildCurrentUserBar() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
        final d = snap.data!.data() as Map<String, dynamic>;
        final name = d['name'] ?? 'أنتِ';
        final points = d['communityPoints'] ?? 0;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_pink.withOpacity(0.85), _pink]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(top: false, child: Row(children: [
            CircleAvatar(
              radius: 18, backgroundColor: Colors.white.withOpacity(0.3),
              backgroundImage: d['avatarUrl'] != null && (d['avatarUrl'] as String).isNotEmpty
                ? NetworkImage(d['avatarUrl']) : null,
              child: d['avatarUrl'] == null || (d['avatarUrl'] as String).isEmpty
                ? Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)) : null,
            ),
            const SizedBox(width: 10),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const Spacer(),
            Text(_formatPoints(points), style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showSortOptions,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
              ),
            ),
          ])),
        );
      },
    );
  }
}

// ─── Follow Button Widget (public for reuse) ───
class FollowButton extends StatelessWidget {
  final String targetUserId;
  const FollowButton({Key? key, required this.targetUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == targetUserId) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid)
        .collection('following').doc(targetUserId).snapshots(),
      builder: (context, snap) {
        final isFollowing = snap.hasData && snap.data!.exists;
        return GestureDetector(
          onTap: () async {
            final ref = FirebaseFirestore.instance.collection('users').doc(uid).collection('following').doc(targetUserId);
            final targetRef = FirebaseFirestore.instance.collection('users').doc(targetUserId).collection('followers').doc(uid);
            // كتابة مستند الطرف الآخر قد تُرفض بقواعد الخصوصية — نجعلها غير قاتلة
            // حتى تبقى متابعتي (الجهة الخاصّة بي) فعّالة دون كسر.
            if (isFollowing) {
              await ref.delete();
              try { await targetRef.delete(); } catch (_) {}
              try { await FirebaseFirestore.instance.collection('users').doc(uid).update({'followingCount': FieldValue.increment(-1)}); } catch (_) {}
              try { await FirebaseFirestore.instance.collection('users').doc(targetUserId).update({'followersCount': FieldValue.increment(-1)}); } catch (_) {}
            } else {
              await ref.set({'followedAt': FieldValue.serverTimestamp()});
              try { await targetRef.set({'followedAt': FieldValue.serverTimestamp()}); } catch (_) {}
              try { await FirebaseFirestore.instance.collection('users').doc(uid).update({'followingCount': FieldValue.increment(1)}); } catch (_) {}
              try { await FirebaseFirestore.instance.collection('users').doc(targetUserId).update({'followersCount': FieldValue.increment(1)}); } catch (_) {}
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: isFollowing ? Colors.grey.shade200 : _pink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFollowing ? 'متابَعة ✓' : 'متابعة',
              style: TextStyle(color: isFollowing ? _text2 : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
