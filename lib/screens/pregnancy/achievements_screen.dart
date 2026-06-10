import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

const Color _bg = Color(0xFFFFF5F7);
const Color _card = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _text1 = Color(0xFF2D2D3A);
const Color _text2 = Color(0xFF6B7280);
const Color _gold = Color(0xFFFFD700);

DocumentReference get _userDoc {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _arrowController;
  Map<String, bool> _unlocked = {};
  int _streak = 0;
  int _totalPoints = 0;
  bool _loaded = false;

  final _achievements = <_AchievementCategory>[
    _AchievementCategory('الحمل', Icons.pregnant_woman, const Color(0xFFE91E63), [
      _Achievement('first_week', 'الأسبوع الأول', 'سجلي أول أسبوع حمل', '🌱', 10),
      _Achievement('trimester_1', 'الثلث الأول', 'أكملي الثلث الأول (13 أسبوع)', '🌸', 50),
      _Achievement('trimester_2', 'الثلث الثاني', 'أكملي الثلث الثاني (26 أسبوع)', '🌺', 75),
      _Achievement('trimester_3', 'الثلث الثالث', 'ادخلي الثلث الثالث', '🌻', 100),
      _Achievement('due_date', 'يوم الولادة', 'وصلتِ ليوم الولادة المتوقع!', '👶', 200),
      _Achievement('baby_size_fan', 'خبيرة الأحجام', 'تصفحي جميع أحجام الجنين', '🍉', 30),
    ]),
    _AchievementCategory('الصحة', Icons.favorite, const Color(0xFF00897B), [
      _Achievement('first_weight', 'أول وزن', 'سجلي وزنك لأول مرة', '⚖️', 10),
      _Achievement('weight_5', 'متابعة منتظمة', 'سجلي وزنك 5 مرات', '📊', 25),
      _Achievement('weight_20', 'خبيرة المتابعة', 'سجلي وزنك 20 مرة', '🏆', 75),
      _Achievement('vitamins_day', 'فيتامينات اليوم', 'سجلي جميع فيتاميناتك في يوم واحد', '💊', 15),
      _Achievement('vitamins_week', 'أسبوع صحي', 'سجلي فيتاميناتك لمدة أسبوع متواصل', '🌟', 50),
      _Achievement('exercise_first', 'أول تمرين', 'أكملي أول تمرين', '🏃‍♀️', 10),
    ]),
    _AchievementCategory('التنظيم', Icons.checklist, const Color(0xFFFF7043), [
      _Achievement('bag_10', 'بداية التحضير', 'حضري 10 عناصر من حقيبة الولادة', '🧳', 20),
      _Achievement('bag_complete', 'حقيبة مكتملة', 'أكملي تحضير حقيبة الولادة', '✅', 100),
      _Achievement('journal_first', 'أول يومية', 'اكتبي أول إدخال في يوميات الحمل', '📝', 10),
      _Achievement('journal_10', 'كاتبة نشيطة', 'اكتبي 10 إدخالات في اليوميات', '✍️', 40),
      _Achievement('journal_30', 'مذكرات ذهبية', 'اكتبي 30 إدخال في اليوميات', '📖', 100),
      _Achievement('calendar_check', 'موعد محجوز', 'أضيفي أول موعد في تقويم الحمل', '📅', 10),
    ]),
    _AchievementCategory('الاستمرارية', Icons.local_fire_department, const Color(0xFFFF9800), [
      _Achievement('streak_3', '3 أيام متواصلة', 'استخدمي التطبيق 3 أيام متتالية', '🔥', 15),
      _Achievement('streak_7', 'أسبوع كامل', 'استخدمي التطبيق 7 أيام متتالية', '💪', 35),
      _Achievement('streak_14', 'أسبوعان متواصلان', 'استخدمي التطبيق 14 يوم متتالي', '⭐', 70),
      _Achievement('streak_30', 'شهر كامل', 'استخدمي التطبيق 30 يوم متتالي', '🏅', 150),
      _Achievement('streak_60', 'بطلة الاستمرارية', 'استخدمي التطبيق 60 يوم متتالي', '👑', 300),
      _Achievement('first_login', 'أهلاً بك', 'سجلي الدخول لأول مرة', '👋', 5),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _achievements.length, vsync: this);
    _arrowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() { _tabController.dispose(); _arrowController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    try {
      final doc = await _userDoc.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final achievements = data['achievements'] as Map<String, dynamic>? ?? {};
      final streak = (data['login_streak'] as num?)?.toInt() ?? 0;

      final unlockedMap = <String, bool>{};
      int points = 0;

      for (final cat in _achievements) {
        for (final a in cat.items) {
          final isUnlocked = achievements[a.id] == true;
          unlockedMap[a.id] = isUnlocked;
          if (isUnlocked) points += a.points;
        }
      }

      // Auto-check some achievements based on data
      await _autoCheckAchievements(data, unlockedMap);

      // Recalculate points after auto-check
      points = 0;
      for (final cat in _achievements) {
        for (final a in cat.items) {
          if (unlockedMap[a.id] == true) points += a.points;
        }
      }

      setState(() {
        _unlocked = unlockedMap;
        _streak = streak;
        _totalPoints = points;
        _loaded = true;
      });
    } catch (_) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _autoCheckAchievements(Map<String, dynamic> data, Map<String, bool> unlocked) async {
    final newUnlocks = <String, bool>{};

    // First login
    if (unlocked['first_login'] != true) {
      newUnlocks['first_login'] = true;
      unlocked['first_login'] = true;
    }

    // Pregnancy week achievements
    final week = (data['pregnancyWeek'] as num?)?.toInt() ??
        (data['weight_tracker_profile']?['current_week'] as num?)?.toInt() ?? 0;
    if (week >= 1 && unlocked['first_week'] != true) { newUnlocks['first_week'] = true; unlocked['first_week'] = true; }
    if (week >= 13 && unlocked['trimester_1'] != true) { newUnlocks['trimester_1'] = true; unlocked['trimester_1'] = true; }
    if (week >= 26 && unlocked['trimester_2'] != true) { newUnlocks['trimester_2'] = true; unlocked['trimester_2'] = true; }
    if (week >= 27 && unlocked['trimester_3'] != true) { newUnlocks['trimester_3'] = true; unlocked['trimester_3'] = true; }
    if (week >= 40 && unlocked['due_date'] != true) { newUnlocks['due_date'] = true; unlocked['due_date'] = true; }

    // Hospital bag
    final bag = data['hospital_bag'] as Map<String, dynamic>? ?? {};
    final bagChecked = bag.values.where((v) => v == true).length;
    if (bagChecked >= 10 && unlocked['bag_10'] != true) { newUnlocks['bag_10'] = true; unlocked['bag_10'] = true; }
    if (bagChecked >= 45 && unlocked['bag_complete'] != true) { newUnlocks['bag_complete'] = true; unlocked['bag_complete'] = true; }

    // Weight tracking
    try {
      final weightSnap = await _userDoc.collection('weight_tracker').get();
      final wCount = weightSnap.docs.length;
      if (wCount >= 1 && unlocked['first_weight'] != true) { newUnlocks['first_weight'] = true; unlocked['first_weight'] = true; }
      if (wCount >= 5 && unlocked['weight_5'] != true) { newUnlocks['weight_5'] = true; unlocked['weight_5'] = true; }
      if (wCount >= 20 && unlocked['weight_20'] != true) { newUnlocks['weight_20'] = true; unlocked['weight_20'] = true; }
    } catch (_) {}

    // Journal
    try {
      final journalSnap = await _userDoc.collection('pregnancy_journal').get();
      final jCount = journalSnap.docs.length;
      if (jCount >= 1 && unlocked['journal_first'] != true) { newUnlocks['journal_first'] = true; unlocked['journal_first'] = true; }
      if (jCount >= 10 && unlocked['journal_10'] != true) { newUnlocks['journal_10'] = true; unlocked['journal_10'] = true; }
      if (jCount >= 30 && unlocked['journal_30'] != true) { newUnlocks['journal_30'] = true; unlocked['journal_30'] = true; }
    } catch (_) {}

    // Streak
    final streak = (data['login_streak'] as num?)?.toInt() ?? 0;
    if (streak >= 3 && unlocked['streak_3'] != true) { newUnlocks['streak_3'] = true; unlocked['streak_3'] = true; }
    if (streak >= 7 && unlocked['streak_7'] != true) { newUnlocks['streak_7'] = true; unlocked['streak_7'] = true; }
    if (streak >= 14 && unlocked['streak_14'] != true) { newUnlocks['streak_14'] = true; unlocked['streak_14'] = true; }
    if (streak >= 30 && unlocked['streak_30'] != true) { newUnlocks['streak_30'] = true; unlocked['streak_30'] = true; }
    if (streak >= 60 && unlocked['streak_60'] != true) { newUnlocks['streak_60'] = true; unlocked['streak_60'] = true; }

    // Save new unlocks
    if (newUnlocks.isNotEmpty) {
      await _userDoc.set({
        'achievements': newUnlocks,
      }, SetOptions(merge: true));
    }
  }

  int get _totalAchievements => _achievements.fold(0, (s, c) => s + c.items.length);
  int get _unlockedCount => _unlocked.values.where((v) => v).length;
  int get _maxPoints => _achievements.fold(0, (s, c) => s + c.items.fold(0, (ss, a) => ss + a.points));

  String get _level {
    if (_totalPoints >= 1000) return 'ملكة نبضة 👑';
    if (_totalPoints >= 600) return 'خبيرة 🌟';
    if (_totalPoints >= 300) return 'متقدمة 💎';
    if (_totalPoints >= 100) return 'نشيطة 🔥';
    if (_totalPoints >= 30) return 'مبتدئة 🌱';
    return 'جديدة 👋';
  }

  int get _nextLevelPoints {
    if (_totalPoints >= 1000) return 1000;
    if (_totalPoints >= 600) return 1000;
    if (_totalPoints >= 300) return 600;
    if (_totalPoints >= 100) return 300;
    if (_totalPoints >= 30) return 100;
    return 30;
  }

  int get _currentLevelBase {
    if (_totalPoints >= 1000) return 1000;
    if (_totalPoints >= 600) return 600;
    if (_totalPoints >= 300) return 300;
    if (_totalPoints >= 100) return 100;
    if (_totalPoints >= 30) return 30;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('الإنجازات والشارات', style: TextStyle(fontWeight: FontWeight.bold, color: _text1, fontSize: 20)),
          backgroundColor: _card, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent, centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: _teal,
            unselectedLabelColor: _text2,
            indicatorColor: _teal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: _achievements.map((c) => Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(c.icon, size: 18),
                const SizedBox(width: 6),
                Text(c.title),
              ]),
            )).toList(),
          ),
        ),
        body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : Column(
              children: [
                // Stats header
                _buildStatsHeader(),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(_achievements.length, (i) => _buildCategoryList(i)),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  int get _levelIndex {
    if (_totalPoints >= 1000) return 5;
    if (_totalPoints >= 600) return 4;
    if (_totalPoints >= 300) return 3;
    if (_totalPoints >= 100) return 2;
    if (_totalPoints >= 30) return 1;
    return 0;
  }

  Widget _buildStatsHeader() {
    final levels = [
      {'name': 'جديدة', 'emoji': '👋', 'points': 0},
      {'name': 'مبتدئة', 'emoji': '🌱', 'points': 30},
      {'name': 'نشيطة', 'emoji': '🔥', 'points': 100},
      {'name': 'متقدمة', 'emoji': '💎', 'points': 300},
      {'name': 'خبيرة', 'emoji': '🌟', 'points': 600},
      {'name': 'ملكة نبضة', 'emoji': '👑', 'points': 1000},
    ];
    final currentIdx = _levelIndex;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // Current level info
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_gold, _gold.withOpacity(0.7)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _gold.withOpacity(0.4), blurRadius: 12)],
                ),
                child: Center(child: Text(levels[currentIdx]['emoji'] as String, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_level, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('$_totalPoints نقطة  •  $_unlockedCount / $_totalAchievements إنجاز', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    if (_totalPoints < 1000) ...[
                      const SizedBox(height: 4),
                      Text('${_nextLevelPoints - _totalPoints} نقطة للمستوى التالي', style: TextStyle(fontSize: 11, color: _gold.withOpacity(0.8))),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Level path with animated arrow
          SizedBox(
            height: 85,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final stepWidth = totalWidth / (levels.length - 1);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background track
                    Positioned(top: 18, left: 0, right: 0,
                      child: Container(height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(2)))),
                    // Gold progress track
                    Positioned(top: 18, left: 0,
                      child: Container(
                        height: 4,
                        width: (stepWidth * currentIdx).clamp(0.0, totalWidth),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFC107)]), borderRadius: BorderRadius.circular(2)),
                      )),
                    // Level dots
                    ...List.generate(levels.length, (i) {
                      final x = i * stepWidth;
                      final isReached = i <= currentIdx;
                      final isCurrent = i == currentIdx;
                      return Positioned(
                        left: x - (isCurrent ? 15 : 12),
                        top: isCurrent ? 4 : 7,
                        child: Column(
                          children: [
                            Container(
                              width: isCurrent ? 30 : 24, height: isCurrent ? 30 : 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isReached ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFC107)]) : null,
                                color: isReached ? null : Colors.white.withOpacity(0.15),
                                border: isCurrent ? Border.all(color: Colors.white, width: 2.5) : null,
                                boxShadow: isCurrent ? [BoxShadow(color: _gold.withOpacity(0.5), blurRadius: 10)] : null,
                              ),
                              child: Center(child: Text(levels[i]['emoji'] as String, style: TextStyle(fontSize: isCurrent ? 14 : 10))),
                            ),
                            const SizedBox(height: 4),
                            Text(levels[i]['name'] as String,
                              style: TextStyle(fontSize: isCurrent ? 9 : 7, color: isReached ? _gold : Colors.white30, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      );
                    }),
                    // Animated bouncing arrow
                    AnimatedBuilder(
                      animation: _arrowController,
                      builder: (context, _) {
                        final bounce = _arrowController.value * 6;
                        return Positioned(
                          left: (currentIdx * stepWidth) - 8,
                          top: -14 - bounce,
                          child: Text('▼', style: TextStyle(fontSize: 14, color: _gold, shadows: [Shadow(color: _gold.withOpacity(0.6), blurRadius: 6)])),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Stats row
          Row(
            children: [
              _statItem('🔥', '$_streak', 'أيام متتالية'),
              _divider(),
              _statItem('⭐', '$_totalPoints', 'نقطة'),
              _divider(),
              _statItem('🏆', '$_unlockedCount', 'إنجاز'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 45, color: Colors.white.withOpacity(0.15));

  Widget _buildCategoryList(int catIndex) {
    final cat = _achievements[catIndex];
    final catUnlocked = cat.items.where((a) => _unlocked[a.id] == true).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        // Category header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: cat.color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(cat.icon, color: cat.color, size: 20),
              const SizedBox(width: 8),
              Text('$catUnlocked / ${cat.items.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cat.color)),
              const Spacer(),
              if (catUnlocked == cat.items.length)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(6)),
                  child: const Text('مكتمل!', style: TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        // Achievement cards
        ...cat.items.map((a) {
          final isUnlocked = _unlocked[a.id] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked ? _card : _card.withOpacity(0.7),
              borderRadius: BorderRadius.circular(18),
              border: isUnlocked ? Border.all(color: _gold.withOpacity(0.4), width: 1.5) : null,
              boxShadow: isUnlocked ? [BoxShadow(color: _gold.withOpacity(0.1), blurRadius: 8)] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
            ),
            child: Row(
              children: [
                // Golden Badge
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: isUnlocked ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFC107), Color(0xFFFFECB3)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                    color: isUnlocked ? null : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: isUnlocked ? Border.all(color: const Color(0xFFFFD700).withOpacity(0.6), width: 1.5) : null,
                    boxShadow: isUnlocked ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
                  ),
                  child: Center(
                    child: isUnlocked
                      ? Text(a.emoji, style: const TextStyle(fontSize: 28))
                      : Icon(Icons.lock_rounded, color: Colors.grey.shade400, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: isUnlocked ? _text1 : _text2,
                      )),
                      const SizedBox(height: 3),
                      Text(a.description, style: TextStyle(fontSize: 12, color: _text2)),
                    ],
                  ),
                ),
                // Points
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isUnlocked ? _gold.withOpacity(0.15) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${a.points}',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.amber.shade800 : _text2,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _AchievementCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<_Achievement> items;
  const _AchievementCategory(this.title, this.icon, this.color, this.items);
}

class _Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int points;
  const _Achievement(this.id, this.name, this.description, this.emoji, this.points);
}
