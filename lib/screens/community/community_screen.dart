import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_post_screen.dart';
import '../messaging/chat_list_screen.dart';
import 'post_detail_screen.dart';
import 'leaderboard_screen.dart';
import 'user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/cohort_service.dart';
import '../../services/pregnancy_dates_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/community_engagement_service.dart';
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
  int _mainTab = 0; // 0 = المنشورات, 1 = الترتيب

  @override
  void initState() {
    super.initState();
    _syncProfile(); // مزامنة كسولة: فوج شهر الولادة + بيانات الملفّ العامّ في users_directory
  }

  /// يقرأ مستند المستخدِمة مرّة واحدة، ثمّ:
  /// 1) يزامن فوج شهر الولادة (idempotent).
  /// 2) يعكس بيانات العرض العامّة (نقاط/شارات/عدّادات/صورة) إلى users_directory
  ///    حتى تستطيع العضوات الأخريات رؤية ملفّها وترتيبها (مستند users محجوب بالخصوصية).
  Future<void> _syncProfile() async {
    final uid = _currentUserId;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists) return;
      final d = snap.data()!;

      // (1) الفوج — من تواريخ الحمل الموحّدة
      final pd = PregnancyDates.fromUserData(d);
      final key = CohortService().deriveCohortKey(
        status: d['lifeStage'] as String? ?? '',
        pregnancyStartDate: pd.effectiveStart,
        dueDate: pd.effectiveDueDate,
        babyBirthDate: d['babyBirthDate'] is Timestamp ? (d['babyBirthDate'] as Timestamp).toDate() : null,
      );
      await CohortService().syncUserCohort(uid, key);

      // (2) مرآة الملفّ العامّ
      final points = (d['communityPoints'] is int) ? d['communityPoints'] as int : 0;
      final existing = (d['badges'] is List) ? List<String>.from(d['badges']) : <String>[];
      final badges = <String>{...existing, ..._badgesForPoints(points)}.toList();
      await FirebaseFirestore.instance.collection('users_directory').doc(uid).set({
        'name': d['name'] ?? '',
        'photoUrl': d['photoUrl'] ?? d['avatarUrl'] ?? '',
        'bio': d['bio'] ?? '',
        'communityPoints': points,
        'postCount': d['postCount'] ?? 0,
        'receivedLikes': d['receivedLikes'] ?? 0,
        'commentCount': d['commentCount'] ?? 0,
        'followersCount': d['followersCount'] ?? 0,
        'followingCount': d['followingCount'] ?? 0,
        'badges': badges,
        'cohortKey': key,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {/* صامت — لا يعطّل فتح المجتمع */}
  }

  /// الشارات المستحقّة حسب النقاط (مطابقة لعتبات CommunityEngagementService).
  static List<String> _badgesForPoints(int p) {
    final b = <String>[];
    if (p >= 20) b.add('active');
    if (p >= 50) b.add('helpful');
    if (p >= 100) b.add('expert');
    if (p >= 200) b.add('top_contributor');
    return b;
  }

  /// يفتح ملفّ صاحبة المنشور (إلا منشورات الفريق أو المجهولة).
  void _openProfile(CommunityPostModel post) {
    if (post.userId == CommunityEngagementService.teamUserId || post.isAnonymous || post.userId.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => UserProfileScreen(userId: post.userId)));
  }

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
      backgroundColor: const Color(0xFFFFF8FB),
      appBar: AppBar(
        title: const Text(
          'مجتمع نبضة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const ChatListScreen())),
            tooltip: 'الرسائل الخاصة',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                _mainTabButton('المنشورات', Icons.forum_outlined, 0),
                _mainTabButton('ناديي', Icons.groups_outlined, 1),
                _mainTabButton('الترتيب', Icons.emoji_events_outlined, 2),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _mainTab == 0 || _mainTab == 1
        ? FloatingActionButton.extended(
            onPressed: () async {
              String? cohortKey;
              if (_mainTab == 1 && _currentUserId != null) {
                final userSnap = await FirebaseFirestore.instance.collection('users').doc(_currentUserId!).get();
                cohortKey = userSnap.data()?['cohortKey'] as String?;
              }
              if (mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePostScreen(cohortKey: cohortKey)));
              }
            },
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('منشور جديد', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        : null,
      body: _mainTab == 0
        ? Column(
            children: [
              _buildCategoryFilter(),
              Expanded(child: _buildPostFeed()),
            ],
          )
        : _mainTab == 1
            ? _buildCohortFeed()
            : const LeaderboardScreen(),
    );
  }

  Widget _mainTabButton(String label, IconData icon, int index) {
    final isSelected = _mainTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mainTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
              color: isSelected ? const Color(0xFF00897B) : Colors.transparent,
              width: 2.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF00897B) : const Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF2D2D3A) : const Color(0xFF6B7280))),
            ],
          ),
        ),
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
    final isTeamPost = post.userId == CommunityEngagementService.teamUserId;
    final displayName = isTeamPost
        ? CommunityEngagementService.teamName
        : (post.isAnonymous ? 'مجهولة' : post.author);
    final avatarText = isTeamPost
        ? 'ن'
        : (post.isAnonymous ? 'م' : (post.author.isNotEmpty ? post.author[0] : '؟'));

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isTeamPost ? 2.5 : 1.5,
      shadowColor: isTeamPost ? const Color(0xFF00897B).withOpacity(0.3) : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isTeamPost
            ? const BorderSide(color: Color(0xFF00897B), width: 1.2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              Row(
                children: [
                  isTeamPost
                    ? Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                          ),
                          boxShadow: [BoxShadow(color: const Color(0xFF00897B).withOpacity(0.3), blurRadius: 6)],
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                      )
                    : CircleAvatar(
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
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _openProfile(post),
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isTeamPost ? const Color(0xFF00897B) : null,
                                ),
                              ),
                            ),
                            if (isTeamPost) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 16, color: Color(0xFF00897B)),
                            ],
                          ],
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
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id))),
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
      Navigator.pushReplacementNamed(context, '/login');
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

  Widget _buildCohortFeed() {
    if (_currentUserId == null) {
      return const Center(child: Text('يرجى تسجيل الدخول لعرض النادي الخاص بك'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(_currentUserId).snapshots(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)));
        }
        final userData = userSnap.data?.data();
        final cohortKey = userData?['cohortKey'] as String?;

        if (cohortKey == null || cohortKey.isEmpty) {
          return _buildNoCohortState();
        }

        // رسالة الترحيب تظهر مرّة واحدة فقط عند أول دخول
        _maybeShowClubIntro(cohortKey);

        // النادي المعروض: نادي المستخدمة، أو الذي اختارت تصفّحه
        final viewKey = _browsingCohortKey ?? cohortKey;

        return Column(
          children: [
            _buildCohortHeaderCard(viewKey, myKey: cohortKey),
            Expanded(child: _buildCohortPostList(viewKey)),
          ],
        );
      },
    );
  }

  Widget _buildNoCohortState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_outlined, size: 64, color: Color(0xFFE91E63)),
            ),
            const SizedBox(height: 20),
            const Text(
              'نادي الولادة الخاص بكِ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A)),
            ),
            const SizedBox(height: 12),
            Text(
              'أندية أشهر الولادة مخصصة لربط الحوامل والأمهات اللواتي يمررن بنفس مرحلتكِ لمشاركة التجارب والنصائح اليومية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'تفضلي بتحديد تاريخ بداية حملكِ أو تاريخ ولادة طفلكِ في حسابكِ للانضمام التلقائي للنادي الخاص بكِ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('حدّثي تاريخ بداية الحمل أو تاريخ الولادة من تبويب «حسابي» للانضمام التلقائي'),
                    backgroundColor: Color(0xFF00897B),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('تحديث بيانات الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── تصفّح الأندية الأخرى + رسالة الترحيب لأول مرّة ──────────────
  String? _browsingCohortKey;
  bool _introChecked = false;

  Future<void> _maybeShowClubIntro(String cohortKey) async {
    if (_introChecked) return;
    _introChecked = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('club_intro_seen') == true) return;
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE8EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.groups_rounded, color: Color(0xFFE91E63), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('نادي الولادة الخاص بكِ',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أندية أشهر الولادة مخصصة لربط الحوامل والأمهات اللواتي يمررن بنفس مرحلتكِ لمشاركة التجارب والنصائح اليومية.',
                  style: TextStyle(height: 1.6, fontSize: 13.5, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF00897B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'انضممتِ تلقائياً إلى «${CohortService.labelForKey(cohortKey)}» حسب تاريخ ولادتكِ المتوقّع.',
                          style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF00695C), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'يمكنكِ أيضاً تصفّح أندية الأشهر الأخرى للاطّلاع على منشوراتها من زر «تصفّح الأندية».',
                  style: TextStyle(height: 1.6, fontSize: 12.5, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('فهمت، لنبدأ'),
              ),
            ],
          ),
        ),
      );
      await prefs.setBool('club_intro_seen', true);
    } catch (_) {}
  }

  Future<void> _openClubPicker(String myKey) async {
    final keys = CohortService.nearbyKeys(myKey, span: 6);
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('تصفّح الأندية',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('اطّلعي على منشورات أندية الأشهر الأخرى',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: keys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final k = keys[i];
                    final isMine = k == myKey;
                    final isCurrent = k == (_browsingCohortKey ?? myKey);
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, k),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF00897B).withOpacity(0.09)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? const Color(0xFF00897B).withOpacity(0.35)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.groups_rounded,
                                size: 19,
                                color: isCurrent ? const Color(0xFF00897B) : Colors.grey.shade500),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                CohortService.labelForKey(k),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                  color: const Color(0xFF2D2D3A),
                                ),
                              ),
                            ),
                            if (isMine)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE91E63).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('ناديكِ',
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFE91E63))),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _browsingCohortKey = picked == myKey ? null : picked);
    }
  }

  Widget _buildCohortHeaderCard(String cohortKey, {required String myKey}) {
    final isVisiting = cohortKey != myKey;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('cohort_members_count').doc(cohortKey).snapshots(),
      builder: (context, countSnap) {
        final count = countSnap.data?.data()?['memberCount'] ?? 1;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00897B), Color(0xFF00695C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00897B).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatCohortName(cohortKey),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isVisiting
                              ? '$count عضوة · أنتِ تتصفّحين هذا النادي'
                              : '$count عضوة في ناديكِ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // زر تصفّح الأندية
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openClubPicker(myKey),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 17),
                          SizedBox(width: 5),
                          Text('الأندية',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isVisiting) ...[
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _browsingCohortKey = null),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text('العودة إلى ناديكِ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCohortPostList(String cohortKey) {
    return StreamBuilder<List<CommunityPostModel>>(
      stream: _firestoreService.getPosts(cohortKey: cohortKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ في تحميل منشورات النادي'));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('لا توجد منشورات في النادي بعد', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('شاركي سؤالاً أو تجربة لتكوني أول من ينشط في النادي!', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(posts[index]),
        );
      },
    );
  }

  String _formatCohortName(String key) {
    // اسم موحّد: «مواليد جانفي 2027»
    return CohortService.labelForKey(key);
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
