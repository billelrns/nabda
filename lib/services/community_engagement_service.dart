import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_post_model.dart';

/// Service to manage automated community engagement for Nabda app.
/// Uses "فريق نبضة" official account to post content, welcome new users,
/// and promote products naturally within the community.
class CommunityEngagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final _random = Random();

  // ─── Official Account Constants ───
  static const String teamUserId = 'nabda_team_official';
  static const String teamName = 'فريق نبضة';
  static const String teamBadge = 'official'; // badge type

  // ─── Badge System ───
  static const Map<String, Map<String, dynamic>> badgeDefinitions = {
    'official': {'label': 'حساب رسمي', 'icon': 'verified', 'color': 0xFF00897B},
    'active': {'label': 'مساهمة نشطة', 'icon': 'local_fire_department', 'color': 0xFFFF9800},
    'expert': {'label': 'خبيرة', 'icon': 'workspace_premium', 'color': 0xFF9C27B0},
    'helpful': {'label': 'مفيدة', 'icon': 'favorite', 'color': 0xFFE91E63},
    'new_mom': {'label': 'أم جديدة', 'icon': 'child_care', 'color': 0xFF2196F3},
    'top_contributor': {'label': 'أفضل مساهمة', 'icon': 'emoji_events', 'color': 0xFFFFB300},
  };

  // ─── Points Thresholds for Badges ───
  static const Map<String, int> badgeThresholds = {
    'active': 20,       // 20+ points
    'helpful': 50,      // 50+ points
    'expert': 100,      // 100+ points
    'top_contributor': 200, // 200+ points
  };

  // ════════════════════════════════════════════════
  //  DAILY QUESTION / DISCUSSION TOPICS
  // ════════════════════════════════════════════════

  static const List<Map<String, String>> _dailyTopics = [
    // ── الحمل ──
    {'title': 'سؤال اليوم: ما أكثر شيء فاجأك في الحمل؟', 'content': 'كل حمل فيه مفاجآت! شاركينا أكثر شيء ما كنتِ تتوقعينه خلال حملك، سواء كان إيجابي أو سلبي. تجربتك ممكن تفيد أم أخرى تمر بنفس المرحلة 💕', 'category': 'pregnancy'},
    {'title': 'كيف تتعاملين مع غثيان الصباح؟', 'content': 'الغثيان من أصعب أعراض الحمل خاصة في الأشهر الأولى. شاركينا الطرق اللي ساعدتك في التخفيف منه! هل جربتِ الزنجبيل؟ البسكويت المالح؟ أو نصائح أخرى؟', 'category': 'pregnancy'},
    {'title': 'ما هي أجمل لحظة في متابعة حملك؟', 'content': 'أول نبض قلب، أول حركة، أول سونار... كل لحظة في الحمل مميزة. ما هي اللحظة اللي ما تنسينها أبداً؟ شاركينا لحظتك الخاصة ❤️', 'category': 'pregnancy'},
    {'title': 'نصائح للحامل في الشهر الأول', 'content': 'للأمهات اللي بدأن رحلة الحمل للتو: ما هي أهم النصائح اللي تقدمينها من تجربتك؟ الفيتامينات، التغذية، الراحة... شاركينا خبرتك!', 'category': 'pregnancy'},
    {'title': 'كيف تختارين اسم مولودك؟', 'content': 'اختيار اسم المولود من أمتع وأصعب القرارات! كيف اخترتِ الاسم؟ هل بحثتِ عن المعنى أولاً؟ هل اتفقتِ مع زوجك بسهولة أم كان فيه نقاش؟ 😄', 'category': 'pregnancy'},
    {'title': 'تجهيزات حقيبة المستشفى: ما الأساسي؟', 'content': 'للأمهات اللي على وشك الولادة: ما هي الأغراض الأساسية في حقيبة المستشفى؟ وما الأشياء اللي تمنيتِ لو أخذتِها معك؟', 'category': 'pregnancy'},

    // ── الدورة ──
    {'title': 'كيف تتعاملين مع آلام الدورة الشهرية؟', 'content': 'كل وحدة عندها طريقتها الخاصة في التعامل مع آلام الدورة. شاركينا الطرق الطبيعية أو النصائح اللي تساعدك في هذه الأيام الصعبة 🌸', 'category': 'cycle'},
    {'title': 'هل تتابعين دورتك الشهرية بانتظام؟', 'content': 'متابعة الدورة الشهرية مهمة جداً لصحة المرأة. هل تستخدمين تطبيق نبضة لتتبع دورتك؟ ما الفوائد اللي لاحظتِها من المتابعة المنتظمة؟', 'category': 'cycle'},
    {'title': 'أطعمة تساعد في تخفيف أعراض الدورة', 'content': 'التغذية السليمة تلعب دور كبير في تخفيف أعراض الدورة. ما هي الأطعمة اللي تنصحين بها؟ وما الأطعمة اللي يُفضل تجنبها خلال هذه الفترة؟', 'category': 'cycle'},
    {'title': 'الرياضة أثناء الدورة: نعم أم لا؟', 'content': 'بعض النساء يفضلن الراحة التامة وبعضهن يجدن أن الرياضة الخفيفة تساعد. ما رأيك؟ هل تمارسين الرياضة خلال الدورة؟ وما التمارين المناسبة؟', 'category': 'cycle'},

    // ── الطفل ──
    {'title': 'أول كلمة لطفلك: ما كانت؟ 👶', 'content': 'لحظة ما ينطق طفلك أول كلمة من أحلى اللحظات! ما كانت أول كلمة لطفلك؟ ماما؟ بابا؟ أم كلمة غريبة ومضحكة؟ شاركينا! 😍', 'category': 'baby'},
    {'title': 'نصائح للأمهات الجدد في الشهر الأول', 'content': 'الشهر الأول مع المولود الجديد تحدي كبير! ما هي أهم النصائح اللي تقدمينها لأم تعيش هذه التجربة لأول مرة؟ النوم، الرضاعة، التعامل مع البكاء...', 'category': 'baby'},
    {'title': 'كيف تنظمين نوم طفلك؟', 'content': 'تنظيم نوم الطفل من أكبر التحديات! في أي عمر بدأتِ تنظيم النوم؟ وما الروتين اللي استخدمتِه؟ شاركينا تجربتك لمساعدة الأمهات الأخريات 🌙', 'category': 'baby'},
    {'title': 'ما أفضل ألعاب تعليمية لطفلك حسب عمره؟', 'content': 'اللعب مهم جداً لنمو الطفل! ما الألعاب التعليمية اللي أحبها طفلك وفادته؟ شاركينا حسب الفئة العمرية 🧸', 'category': 'baby'},
    {'title': 'تجربتك مع إدخال الطعام الصلب', 'content': 'متى بدأتِ إدخال الطعام الصلب لطفلك؟ ما أول طعام جربتِه؟ وكيف كان رد فعله؟ نصائحك للأمهات اللي على وشك البدء! 🥕🍌', 'category': 'baby'},

    // ── عام ──
    {'title': 'كيف توازنين بين العمل والأمومة؟', 'content': 'التوازن بين العمل والأمومة تحدي يومي. كيف تنظمين وقتك؟ هل عندك نصائح عملية تشاركينها مع المجتمع؟ 💪', 'category': 'general'},
    {'title': 'ما الكتاب أو المصدر اللي ساعدك أكثر كأم؟', 'content': 'سواء كتاب عن تربية الأطفال، حساب على السوشال ميديا، أو حتى نصيحة من جدتك! ما المصدر اللي أفادك أكثر في رحلة الأمومة؟ 📚', 'category': 'general'},
    {'title': 'لحظة أمومة لا تُنسى', 'content': 'كل أم عندها لحظات خاصة لا تُنسى مع أطفالها. شاركينا لحظة أمومة جميلة أو مضحكة أو مؤثرة عاشيتِها مؤخراً ❤️', 'category': 'general'},
    {'title': 'ما أكثر شيء تتمنين لو عرفتِه قبل الأمومة؟', 'content': 'لو تقدرين ترجعين بالزمن وتنصحين نفسك قبل ما تصيرين أم، ما النصيحة اللي كنتِ تقولينها؟ شاركينا حكمتك! 💫', 'category': 'general'},
  ];

  // ════════════════════════════════════════════════
  //  HEALTH TIPS
  // ════════════════════════════════════════════════

  static const List<Map<String, String>> _healthTips = [
    {'title': 'نصيحة اليوم: شرب الماء أثناء الحمل 💧', 'content': 'شرب 8-10 أكواب ماء يومياً أثناء الحمل يساعد في تقليل التورم، منع الإمساك، والحفاظ على صحة السائل الأمنيوسي. حاولي تشربين ماء بانتظام طوال اليوم!\n\nهل تشربين كمية كافية من الماء؟ شاركينا نصائحك للحفاظ على الترطيب 💕', 'category': 'pregnancy'},
    {'title': 'نصيحة صحية: أهمية حمض الفوليك', 'content': 'حمض الفوليك ضروري جداً خاصة في الأشهر الثلاثة الأولى من الحمل. يساعد في حماية الجنين من تشوهات الأنبوب العصبي. تأكدي من أخذ المكملات اللي وصفها لك الطبيب!\n\nهل بدأتِ تأخذين حمض الفوليك قبل الحمل أم بعده؟', 'category': 'pregnancy'},
    {'title': 'نصيحة: تمارين كيجل بعد الولادة', 'content': 'تمارين كيجل تساعد في تقوية عضلات الحوض بعد الولادة. ابدأي بها بالتدريج بعد استشارة طبيبتك. 10 تكرارات 3 مرات يومياً كافية للبداية!\n\nهل جربتِ تمارين كيجل؟ ما الفرق اللي لاحظتِه؟', 'category': 'general'},
    {'title': 'نصيحة: الرضاعة الطبيعية في الأسبوع الأول', 'content': 'الأيام الأولى من الرضاعة قد تكون صعبة، لكن لا تستسلمي! اللبأ (الحليب الأول) غني جداً بالمناعة لطفلك حتى لو كان بكمية قليلة.\n\nشاركينا تجربتك مع الرضاعة الطبيعية وأي نصائح للأمهات الجدد 🤱', 'category': 'baby'},
    {'title': 'نصيحة: النوم على الجانب الأيسر أثناء الحمل', 'content': 'النوم على الجانب الأيسر خاصة في الثلث الأخير من الحمل يحسن الدورة الدموية ويوصل المغذيات أفضل للجنين. استخدمي وسادة الحمل لراحة أكثر!\n\nهل تجدين صعوبة في النوم أثناء الحمل؟ 🌙', 'category': 'pregnancy'},
    {'title': 'نصيحة: علامات التسنين عند الطفل', 'content': 'سيلان اللعاب المفرط، العض على الأشياء، والتهيج قد تكون علامات بداية التسنين. عادة يبدأ بين 4-7 أشهر. العضاضة المبردة تساعد كثيراً!\n\nفي أي عمر بدأ التسنين عند طفلك؟ 🦷', 'category': 'baby'},
  ];

  // ════════════════════════════════════════════════
  //  WELCOME COMMENTS
  // ════════════════════════════════════════════════

  static const List<String> _welcomeComments = [
    'أهلاً وسهلاً بك في مجتمع نبضة! 💕 سعيدات بانضمامك لنا',
    'مرحباً بك! شكراً لمشاركتك معنا، نحب نسمع تجاربك دائماً ❤️',
    'يا هلا! منوّرة مجتمع نبضة 🌸 نتمنى تكون تجربتك معنا مفيدة وممتعة',
    'أهلين! أول منشور ومبروك عليك! نحن هنا دايماً لدعمك 💕',
    'مرحبا بالعضوة الجديدة! نبضة أحلى بوجودك معنا ❤️',
  ];

  // ════════════════════════════════════════════════
  //  PRODUCT PROMOTION TEMPLATES
  // ════════════════════════════════════════════════

  static const List<Map<String, String>> _productPromotions = [
    {'title': 'منتجات مفيدة للأمهات الجدد ✨', 'content': 'جمعنا لكم مجموعة من المنتجات اللي بتسهل عليكم كأمهات! تصفحي قسم المتجر في التطبيق واكتشفي منتجات الحمل والطفل بأسعار مناسبة 🛍️\n\nهل جربتِ أي منتج من متجر نبضة؟ شاركينا رأيك!', 'category': 'general'},
    {'title': 'جديد في المتجر: منتجات العناية بالحامل 🤰', 'content': 'أضفنا منتجات جديدة مخصصة للحوامل! كريمات تشققات البطن، وسائد الحمل، وملابس مريحة. اكتشفيها في قسم المتجر 💜\n\nما أكثر منتج تحتاجينه أثناء الحمل؟', 'category': 'pregnancy'},
    {'title': 'أساسيات المولود الجديد: قائمة مفيدة 👶', 'content': 'جهزنا لكم قائمة بأساسيات المولود الجديد اللي ممكن تلاقينها في متجر نبضة. من الحفاضات للملابس لمستلزمات الرضاعة!\n\nما أول شيء اشتريتِه لمولودك؟ 🎀', 'category': 'baby'},
  ];

  // ════════════════════════════════════════════════
  //  PUBLIC API
  // ════════════════════════════════════════════════

  /// Post today's discussion topic (called from admin panel or scheduled)
  Future<String> postDailyTopic({String? specificCategory}) async {
    final topics = specificCategory != null
        ? _dailyTopics.where((t) => t['category'] == specificCategory).toList()
        : _dailyTopics;

    if (topics.isEmpty) return '';

    // Pick a topic not recently posted
    final recentPosts = await _getRecentTeamPosts(limit: 10);
    final recentTitles = recentPosts.map((p) => p['title']).toSet();

    final available = topics.where((t) => !recentTitles.contains(t['title'])).toList();
    final topic = available.isNotEmpty
        ? available[_random.nextInt(available.length)]
        : topics[_random.nextInt(topics.length)];

    return await _publishPost(
      title: topic['title']!,
      content: topic['content']!,
      category: topic['category']!,
      postType: 'daily_topic',
    );
  }

  /// Post a health tip
  Future<String> postHealthTip({String? specificCategory}) async {
    final tips = specificCategory != null
        ? _healthTips.where((t) => t['category'] == specificCategory).toList()
        : _healthTips;

    if (tips.isEmpty) return '';

    final recentPosts = await _getRecentTeamPosts(limit: 10);
    final recentTitles = recentPosts.map((p) => p['title']).toSet();

    final available = tips.where((t) => !recentTitles.contains(t['title'])).toList();
    final tip = available.isNotEmpty
        ? available[_random.nextInt(available.length)]
        : tips[_random.nextInt(tips.length)];

    return await _publishPost(
      title: tip['title']!,
      content: tip['content']!,
      category: tip['category']!,
      postType: 'health_tip',
    );
  }

  /// Post a product promotion
  Future<String> postProductPromotion() async {
    final promo = _productPromotions[_random.nextInt(_productPromotions.length)];
    return await _publishPost(
      title: promo['title']!,
      content: promo['content']!,
      category: promo['category']!,
      postType: 'product_promo',
    );
  }

  /// Post a custom message from admin as "فريق نبضة"
  Future<String> postCustomMessage({
    required String title,
    required String content,
    required String category,
    String postType = 'custom',
  }) async {
    return await _publishPost(
      title: title,
      content: content,
      category: category,
      postType: postType,
    );
  }

  /// Add welcome comment to a new user's first post
  Future<void> addWelcomeComment(String postId) async {
    final comment = _welcomeComments[_random.nextInt(_welcomeComments.length)];
    final commentData = {
      'userId': teamUserId,
      'author': teamName,
      'text': comment,
      'createdAt': Timestamp.now(),
      'isTeam': true,
    };
    await _firestore.collection('community_posts').doc(postId).update({
      'comments': FieldValue.arrayUnion([commentData]),
    });
  }

  /// Check and auto-welcome new members' first posts
  Future<int> autoWelcomeNewPosts() async {
    // Get posts from last 24 hours that don't have a team welcome
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final recentPosts = await _firestore
        .collection('community_posts')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .get();

    int welcomed = 0;
    for (final doc in recentPosts.docs) {
      final data = doc.data();
      final userId = data['userId'] as String? ?? '';
      if (userId == teamUserId) continue; // Skip team posts

      // Check if this is the user's first post
      final userPostCount = await _firestore
          .collection('community_posts')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      if ((userPostCount.count ?? 0) <= 1) {
        // Check if team already commented
        final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
        final hasTeamComment = comments.any((c) => c['userId'] == teamUserId);
        if (!hasTeamComment) {
          await addWelcomeComment(doc.id);
          welcomed++;
        }
      }
    }
    return welcomed;
  }

  /// Update user badges based on their points
  Future<void> updateUserBadges(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final points = data['communityPoints'] as int? ?? 0;
    final currentBadges = List<String>.from(data['badges'] ?? []);

    final newBadges = <String>[];
    for (final entry in badgeThresholds.entries) {
      if (points >= entry.value && !currentBadges.contains(entry.key)) {
        newBadges.add(entry.key);
      }
    }

    if (newBadges.isNotEmpty) {
      await _firestore.collection('users').doc(userId).set({
        'badges': FieldValue.arrayUnion(newBadges),
      }, SetOptions(merge: true));
    }
  }

  /// Get all available daily topics (for admin UI)
  List<Map<String, String>> getAllDailyTopics() => _dailyTopics;

  /// Get all health tips (for admin UI)
  List<Map<String, String>> getAllHealthTips() => _healthTips;

  /// Get all product promotions (for admin UI)
  List<Map<String, String>> getAllProductPromotions() => _productPromotions;

  /// Get recent team posts for the stats
  Future<Map<String, int>> getTeamStats() async {
    final posts = await _firestore
        .collection('community_posts')
        .where('userId', isEqualTo: teamUserId)
        .get();

    int totalLikes = 0;
    int totalComments = 0;
    for (final doc in posts.docs) {
      final data = doc.data();
      totalLikes += (data['likes'] as int? ?? 0);
      totalComments += (data['comments'] as List? ?? []).length;
    }

    return {
      'totalPosts': posts.docs.length,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
    };
  }

  // ════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ════════════════════════════════════════════════

  Future<String> _publishPost({
    required String title,
    required String content,
    required String category,
    required String postType,
  }) async {
    final newId = _firestore.collection('community_posts').doc().id;
    final post = {
      'id': newId,
      'userId': teamUserId,
      'title': title,
      'content': content,
      'author': teamName,
      'category': category,
      'imageUrl': null,
      'likes': 0,
      'likedBy': <String>[],
      'comments': <Map<String, dynamic>>[],
      'isAnonymous': false,
      'isTeamPost': true,
      'postType': postType, // daily_topic, health_tip, product_promo, custom
      'createdAt': Timestamp.now(),
      'updatedAt': null,
    };
    await _firestore.collection('community_posts').doc(newId).set(post);
    return newId;
  }

  Future<List<Map<String, dynamic>>> _getRecentTeamPosts({int limit = 10}) async {
    final snap = await _firestore
        .collection('community_posts')
        .where('userId', isEqualTo: teamUserId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }
}
