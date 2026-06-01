import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'firebase_options.dart';
import 'screens/community/community_screen.dart';
import 'screens/pregnancy/pregnancy_weeks_screen.dart';
import 'screens/shop/shop_page.dart';
import 'services/country_currency_service.dart';
import 'services/notification_service.dart';
import 'services/admin_service.dart';
import 'services/dynamic_content_service.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'config/theme.dart';
import 'screens/onboarding_screen.dart' show PrivacyPolicyPage, TermsOfServicePage;
import 'screens/baby_names/baby_names_screen.dart';
import 'screens/trackers/weight_tracker_screen.dart';
import 'screens/trackers/health_trackers_screen.dart';
import 'screens/pregnancy/pregnancy_calendar_screen.dart';
import 'screens/pregnancy/pregnancy_journal_screen.dart';
import 'screens/pregnancy/fetus_size_screen.dart';
import 'screens/pregnancy/hospital_bag_screen.dart';
import 'screens/pregnancy/due_date_countdown_screen.dart';
import 'screens/pregnancy/nutrition_screen.dart';
import 'screens/pregnancy/exercises_screen.dart';
import 'screens/pregnancy/achievements_screen.dart';
import 'screens/pregnancy/share_progress_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// ==================== LOCALE MANAGEMENT ====================
class LocaleNotifier extends ChangeNotifier {
  Locale _locale = Locale('ar', 'SA');
  Locale get locale => _locale;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_language') ?? 'ar';
    _locale = _codeToLocale(code);
    notifyListeners();
  }

  Future<void> setLocale(String langCode) async {
    _locale = _codeToLocale(langCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    notifyListeners();
  }

  Locale _codeToLocale(String code) {
    switch (code) {
      case 'fr': return Locale('fr', 'FR');
      case 'en': return Locale('en', 'US');
      default: return Locale('ar', 'SA');
    }
  }
}

final localeNotifier = LocaleNotifier();

// ==================== TRANSLATIONS ====================
class AppLocalizations {
  static String get currentLang => localeNotifier.locale.languageCode;

  static const Map<String, Map<String, String>> _t = {
    'app_name': {'ar': 'نبضة', 'fr': 'Nabda', 'en': 'Nabda'},
    'womens_health': {'ar': 'صحة المرأة العربية', 'fr': 'Santé féminine', 'en': 'Women\'s Health'},
    'home': {'ar': 'الرئيسية', 'fr': 'Accueil', 'en': 'Home'},
    'cycle': {'ar': 'الدورة', 'fr': 'Cycle', 'en': 'Cycle'},
    'pregnancy': {'ar': 'الحمل', 'fr': 'Grossesse', 'en': 'Pregnancy'},
    'baby': {'ar': 'الطفل', 'fr': 'Bébé', 'en': 'Baby'},
    'profile': {'ar': 'حسابي', 'fr': 'Profil', 'en': 'Profile'},
    'shop': {'ar': 'المتجر', 'fr': 'Boutique', 'en': 'Shop'},
    'hello': {'ar': 'مرحباً', 'fr': 'Bonjour', 'en': 'Hello'},
    'how_are_you': {'ar': 'كيف حالك اليوم؟', 'fr': 'Comment allez-vous aujourd\'hui?', 'en': 'How are you today?'},
    'cycle_tracking': {'ar': 'متابعة\nالدورة', 'fr': 'Suivi\ndu cycle', 'en': 'Cycle\nTracking'},
    'pregnancy_tracking': {'ar': 'متابعة\nالحمل', 'fr': 'Suivi\ngrossesse', 'en': 'Pregnancy\nTracking'},
    'baby_care': {'ar': 'رعاية\nالطفل', 'fr': 'Soins\nbébé', 'en': 'Baby\nCare'},
    'ai_assistant': {'ar': 'المساعد\nالذكي', 'fr': 'Assistant\nIA', 'en': 'AI\nAssistant'},
    'community': {'ar': 'المجتمع\nالنسائي', 'fr': 'Communauté\nféminine', 'en': 'Women\'s\nCommunity'},
    'reminders': {'ar': 'التذكيرات', 'fr': 'Rappels', 'en': 'Reminders'},
    'quick_tips': {'ar': 'نصائح سريعة', 'fr': 'Conseils rapides', 'en': 'Quick Tips'},
    'tip_water': {'ar': 'اشربي 8 أكواب ماء يومياً للحفاظ على رطوبة جسمك', 'fr': 'Buvez 8 verres d\'eau par jour pour rester hydratée', 'en': 'Drink 8 glasses of water daily to stay hydrated'},
    'tip_sleep': {'ar': 'احصلي على 7 ساعات نوم على الأقل كل ليلة', 'fr': 'Dormez au moins 7 heures chaque nuit', 'en': 'Get at least 7 hours of sleep each night'},
    'tip_walk': {'ar': 'امشي 30 دقيقة يومياً لصحة أفضل', 'fr': 'Marchez 30 minutes par jour pour une meilleure santé', 'en': 'Walk 30 minutes daily for better health'},
    'login': {'ar': 'تسجيل الدخول', 'fr': 'Connexion', 'en': 'Login'},
    'register': {'ar': 'إنشاء حساب', 'fr': 'Créer un compte', 'en': 'Register'},
    'email': {'ar': 'البريد الإلكتروني', 'fr': 'E-mail', 'en': 'Email'},
    'password': {'ar': 'كلمة المرور', 'fr': 'Mot de passe', 'en': 'Password'},
    'full_name': {'ar': 'الاسم الكامل', 'fr': 'Nom complet', 'en': 'Full Name'},
    'have_account': {'ar': 'لديك حساب؟ سجّلي الدخول', 'fr': 'Déjà un compte? Connectez-vous', 'en': 'Have an account? Login'},
    'no_account': {'ar': 'ليس لديك حساب؟ سجّلي الآن', 'fr': 'Pas de compte? Inscrivez-vous', 'en': 'No account? Register now'},
    'logout': {'ar': 'تسجيل الخروج', 'fr': 'Déconnexion', 'en': 'Logout'},
    'edit_name': {'ar': 'تعديل الاسم', 'fr': 'Modifier le nom', 'en': 'Edit Name'},
    'reset_data': {'ar': 'إعادة تعيين البيانات', 'fr': 'Réinitialiser les données', 'en': 'Reset Data'},
    'notifications': {'ar': 'الإشعارات', 'fr': 'Notifications', 'en': 'Notifications'},
    'privacy': {'ar': 'الخصوصية', 'fr': 'Confidentialité', 'en': 'Privacy'},
    'help': {'ar': 'المساعدة', 'fr': 'Aide', 'en': 'Help'},
    'language': {'ar': 'اللغة', 'fr': 'Langue', 'en': 'Language'},
    'save': {'ar': 'حفظ', 'fr': 'Enregistrer', 'en': 'Save'},
    'cancel': {'ar': 'إلغاء', 'fr': 'Annuler', 'en': 'Cancel'},
    'delete': {'ar': 'حذف', 'fr': 'Supprimer', 'en': 'Delete'},
    'confirm': {'ar': 'تأكيد', 'fr': 'Confirmer', 'en': 'Confirm'},
    'community_title': {'ar': 'المجتمع النسائي', 'fr': 'Communauté féminine', 'en': 'Women\'s Community'},
    'write_post': {'ar': 'شاركي تجربتك...', 'fr': 'Partagez votre expérience...', 'en': 'Share your experience...'},
    'post': {'ar': 'نشر', 'fr': 'Publier', 'en': 'Post'},
    'anonymous': {'ar': 'مجهولة', 'fr': 'Anonyme', 'en': 'Anonymous'},
    'post_as_anonymous': {'ar': 'نشر بشكل مجهول', 'fr': 'Publier anonymement', 'en': 'Post anonymously'},
    'new_post': {'ar': 'منشور جديد', 'fr': 'Nouveau post', 'en': 'New Post'},
    'no_posts': {'ar': 'لا توجد منشورات بعد.\nكوني أول من يشارك!', 'fr': 'Pas encore de posts.\nSoyez la première à partager!', 'en': 'No posts yet.\nBe the first to share!'},
    'post_hint': {'ar': 'اكتبي ما تريدين مشاركته مع المجتمع...', 'fr': 'Écrivez ce que vous souhaitez partager...', 'en': 'Write what you want to share with the community...'},
    'category': {'ar': 'القسم', 'fr': 'Catégorie', 'en': 'Category'},
    'cat_general': {'ar': 'عام', 'fr': 'Général', 'en': 'General'},
    'cat_cycle': {'ar': 'الدورة الشهرية', 'fr': 'Cycle menstruel', 'en': 'Menstrual Cycle'},
    'cat_pregnancy': {'ar': 'الحمل', 'fr': 'Grossesse', 'en': 'Pregnancy'},
    'cat_baby': {'ar': 'رعاية الطفل', 'fr': 'Soins bébé', 'en': 'Baby Care'},
    'cat_nutrition': {'ar': 'التغذية', 'fr': 'Nutrition', 'en': 'Nutrition'},
    'cat_mental': {'ar': 'الصحة النفسية', 'fr': 'Santé mentale', 'en': 'Mental Health'},
    'all': {'ar': 'الكل', 'fr': 'Tout', 'en': 'All'},
    'period_phase': {'ar': 'فترة الدورة', 'fr': 'Période menstruelle', 'en': 'Period Phase'},
    'fertile_phase': {'ar': 'فترة الخصوبة', 'fr': 'Période fertile', 'en': 'Fertile Phase'},
    'regular_phase': {'ar': 'فترة عادية', 'fr': 'Période normale', 'en': 'Regular Phase'},
    'day_of': {'ar': 'اليوم', 'fr': 'Jour', 'en': 'Day'},
    'of_days': {'ar': 'من', 'fr': 'de', 'en': 'of'},
    'reminders_subtitle': {'ar': 'الدورة • الماء • الدواء • التطعيم', 'fr': 'Cycle • Eau • Médicament • Vaccin', 'en': 'Cycle • Water • Medicine • Vaccine'},
    'posted': {'ar': 'نُشر', 'fr': 'Publié', 'en': 'Posted'},
    'just_now': {'ar': 'الآن', 'fr': 'À l\'instant', 'en': 'Just now'},
    'minutes_ago': {'ar': 'دقائق', 'fr': 'minutes', 'en': 'minutes ago'},
    'hours_ago': {'ar': 'ساعات', 'fr': 'heures', 'en': 'hours ago'},
    'days_ago': {'ar': 'أيام', 'fr': 'jours', 'en': 'days ago'},
  };

  static String t(String key) {
    return _t[key]?[currentLang] ?? _t[key]?['ar'] ?? key;
  }

  static bool get isRtl => currentLang == 'ar';
  static TextDirection get textDir => isRtl ? TextDirection.rtl : TextDirection.ltr;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ تهيئة المنطقة الزمنية للإشعارات المجدولة (الجزائر UTC+1)
  try {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Algiers'));
  } catch (_) {}

  // ✅ الإصلاح الحقيقي لخطأ ca9 على الويب: تعطيل التخزين المحلي (IndexedDB)
  // الذي يسبب "FIRESTORE INTERNAL ASSERTION FAILED: Unexpected state"
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (_) {}

  // تجاهل أخطاء Firestore الداخلية (ca9) على الويب
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains('FIRESTORE') && msg.contains('ASSERTION')) return;
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    if (msg.contains('FIRESTORE') && msg.contains('ASSERTION')) return true;
    return false;
  };

  // Register FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notifications (FCM + Local)
  try {
    await NotificationService().initialize();
  } catch (_) {
    // Fallback: basic local notifications init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    try {
      await flutterLocalNotificationsPlugin.initialize(initSettings);
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  // طلب أذونات إشعارات الأدوية وإنشاء القناة
  await NotifService.ensureMedSetup();

  await localeNotifier.loadSavedLocale();
  CountryCurrencyService().initialize();
  runApp(NabdaApp());
}

// ==================== APP ROOT ====================
class NabdaApp extends StatefulWidget {
  @override
  State<NabdaApp> createState() => _NabdaAppState();
}

class _NabdaAppState extends State<NabdaApp> {
  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppLocalizations.t('app_name'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('ar', 'SA'), Locale('fr', 'FR'), Locale('en', 'US')],
      locale: localeNotifier.locale,
      home: AuthGate(),
    );
  }
}

// ==================== AUTH GATE ====================
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snap.hasData) {
          // جدولة إشعارات التطبيق (مرة واحدة لكل جلسة)
          AppNotifs.scheduleAll();
          return MainNav();
        }
        return LoginPage();
      },
    );
  }
}

// ==================== FIRESTORE HELPER ====================
class DB {
  static String get uid => FirebaseAuth.instance.currentUser!.uid;
  static DocumentReference get userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);
  static CollectionReference get cycleLogs =>
      userDoc.collection('cycle_logs');
  static CollectionReference get babyLogs =>
      userDoc.collection('baby_logs');
  static CollectionReference get babies =>
      userDoc.collection('babies');
  static CollectionReference babyLogsFor(String babyId) =>
      userDoc.collection('babies').doc(babyId).collection('logs');
  static CollectionReference get communityPosts =>
      FirebaseFirestore.instance.collection('community_posts');

  static String dateKey([DateTime? d]) {
    final dt = d ?? DateTime.now();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

// ==================== NOTIFICATION SERVICE ====================
class NotifService {
  static const _waterChannel = 'water_channel';
  static const _cycleChannel = 'cycle_channel';
  static const _vaccineChannel = 'vaccine_channel';
  static const _medChannel = 'med_channel';

  static Future<void> showNow(int id, String title, String body, String channel) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel, channel,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    try {
      await flutterLocalNotificationsPlugin.show(id, title, body, details);
    } catch (_) {}
  }

  static Future<void> scheduleWaterReminders(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminder', enabled);
    // Cancel existing
    for (int i = 100; i < 120; i++) {
      await flutterLocalNotificationsPlugin.cancel(i);
    }
    if (!enabled) return;
    // Schedule every 2 hours from 8am to 10pm
    final now = DateTime.now();
    for (int h = 8; h <= 22; h += 2) {
      var scheduled = DateTime(now.year, now.month, now.day, h, 0);
      if (scheduled.isBefore(now)) scheduled = scheduled.add(Duration(days: 1));
      final delay = scheduled.difference(now);
      final id = 100 + (h ~/ 2);
      Future.delayed(delay, () {
        showNow(id, '\u{1F4A7} \u062A\u0630\u0643\u064A\u0631 \u0634\u0631\u0628 \u0627\u0644\u0645\u0627\u0621', '\u062D\u0627\u0646 \u0648\u0642\u062A \u0634\u0631\u0628 \u0643\u0648\u0628 \u0645\u0627\u0621! \u062D\u0627\u0641\u0638\u064A \u0639\u0644\u0649 \u062A\u0631\u0637\u064A\u0628 \u062C\u0633\u0645\u0643.', _waterChannel);
      });
    }
  }

  static Future<void> scheduleCycleReminder(DateTime nextPeriod) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('cycle_reminder') ?? true;
    await flutterLocalNotificationsPlugin.cancel(200);
    await flutterLocalNotificationsPlugin.cancel(201);
    if (!enabled) return;
    // Remind 2 days before
    final remind = nextPeriod.subtract(Duration(days: 2));
    final now = DateTime.now();
    if (remind.isAfter(now)) {
      Future.delayed(remind.difference(now), () {
        showNow(200, '\u{1F4C5} \u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062F\u0648\u0631\u0629', '\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0642\u0627\u062F\u0645\u0629 \u0628\u0639\u062F \u064A\u0648\u0645\u064A\u0646. \u062C\u0647\u0651\u0632\u064A \u0646\u0641\u0633\u0643!', _cycleChannel);
      });
    }
    // Remind on the day
    if (nextPeriod.isAfter(now)) {
      Future.delayed(nextPeriod.difference(now), () {
        showNow(201, '\u{1F4C5} \u0645\u0648\u0639\u062F \u0627\u0644\u062F\u0648\u0631\u0629', '\u0627\u0644\u064A\u0648\u0645 \u0627\u0644\u0645\u0648\u0639\u062F \u0627\u0644\u0645\u062A\u0648\u0642\u0639 \u0644\u0644\u062F\u0648\u0631\u0629. \u0627\u0639\u062A\u0646\u064A \u0628\u0646\u0641\u0633\u0643!', _cycleChannel);
      });
    }
  }

  static Future<void> scheduleMedReminder(bool enabled, String medName, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('med_reminder', enabled);
    await flutterLocalNotificationsPlugin.cancel(300);
    if (!enabled) return;
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(Duration(days: 1));
    Future.delayed(scheduled.difference(now), () {
      showNow(300, '\u{1F48A} \u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062F\u0648\u0627\u0621', '\u062D\u0627\u0646 \u0645\u0648\u0639\u062F \u062A\u0646\u0627\u0648\u0644 $medName', _medChannel);
    });
  }

  // ─── إشعار دواء يومي حقيقي (يعمل حتى لو كان التطبيق مغلقاً) ───
  static int medNotifId(String medId) => medId.hashCode & 0x7fffffff;

  /// طلب أذونات الإشعارات والإنذار الدقيق + إنشاء قناة الأدوية.
  static Future<void> ensureMedSetup() async {
    try {
      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      await android?.createNotificationChannel(const AndroidNotificationChannel(
        _medChannel, 'تذكيرات الأدوية',
        description: 'إشعارات مواعيد الأدوية',
        importance: Importance.max,
        playSound: true,
      ));
    } catch (_) {}
  }

  /// إشعار نظام فوري (للتأكيد أن الإشعارات تعمل).
  static Future<void> showInstant(String title, String body) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        999, title, body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _medChannel, _medChannel,
            channelDescription: 'تذكيرات الأدوية',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {}
  }

  static tz.TZDateTime _nextDaily(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  // معرّف فريد لكل وقت تذكير ضمن نفس الدواء
  static int medSlotId(String medId, int i) => ('$medId#$i').hashCode & 0x7fffffff;

  static const int _maxTimesPerMed = 10;

  /// يجدول إشعاراً يومياً متكرراً لوقت واحد (id محدّد).
  static Future<void> _scheduleOne(
      int id, String medName, String patientName, int hour, int minute) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '\u{1F48A} حان وقت الدواء',
        'دواء "$medName" لـ $patientName',
        _nextDaily(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _medChannel, _medChannel,
            channelDescription: 'تذكيرات الأدوية',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // يتكرر يومياً في نفس الوقت
      );
    } catch (_) {}
  }

  /// يجدول إشعاراً منفصلاً لكل وقت من أوقات الدواء.
  /// times: قائمة [ساعة, دقيقة].
  static Future<void> scheduleMedTimes({
    required String medId,
    required String medName,
    required String patientName,
    required List<List<int>> times,
  }) async {
    await cancelMedReminder(medId); // امسح القديمة أولاً
    for (int i = 0; i < times.length && i < _maxTimesPerMed; i++) {
      await _scheduleOne(
          medSlotId(medId, i), medName, patientName, times[i][0], times[i][1]);
    }
  }

  /// توافق خلفي: وقت واحد فقط.
  static Future<void> scheduleMedDaily({
    required String medId,
    required String medName,
    required String patientName,
    required int hour,
    required int minute,
  }) async {
    await scheduleMedTimes(
      medId: medId,
      medName: medName,
      patientName: patientName,
      times: [
        [hour, minute]
      ],
    );
  }

  static Future<void> cancelMedReminder(String medId) async {
    // ألغِ كل الأوقات الممكنة + المعرّف القديم
    for (int i = 0; i < _maxTimesPerMed; i++) {
      try {
        await flutterLocalNotificationsPlugin.cancel(medSlotId(medId, i));
      } catch (_) {}
    }
    try {
      await flutterLocalNotificationsPlugin.cancel(medNotifId(medId));
    } catch (_) {}
  }

  /// معلومة المنطقة الزمنية (للتشخيص): الاسم + الإزاحة بالساعات.
  static String tzInfo() {
    try {
      final now = tz.TZDateTime.now(tz.local);
      return '${tz.local.name} ${now.timeZoneOffset.inHours}h';
    } catch (e) {
      return 'tz?';
    }
  }

  /// عدد التذكيرات المجدولة فعلياً (للتشخيص).
  static Future<int> pendingCount() async {
    try {
      final pending = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pending.length;
    } catch (_) {
      return -1;
    }
  }

  static Future<void> scheduleVaccineReminder(String vaccineName, DateTime date) async {
    final remind = date.subtract(Duration(days: 1));
    final now = DateTime.now();
    if (remind.isAfter(now)) {
      Future.delayed(remind.difference(now), () {
        showNow(400, '\u{1F489} \u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062A\u0637\u0639\u064A\u0645', '\u063A\u062F\u0627\u064B \u0645\u0648\u0639\u062F \u062A\u0637\u0639\u064A\u0645: $vaccineName', _vaccineChannel);
      });
    }
  }
}

// ==================== APP-WIDE NOTIFICATIONS ====================
// \u0625\u0634\u0639\u0627\u0631\u0627\u062A \u0627\u0644\u062A\u0637\u0628\u064A\u0642 \u0627\u0644\u0645\u062C\u062F\u0648\u0644\u0629: \u0634\u0631\u0628 \u0627\u0644\u0645\u0627\u0621\u060C \u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u062D\u0645\u0644/\u0627\u0644\u062F\u0648\u0631\u0629\u060C \u0646\u0635\u0627\u0626\u062D \u064A\u0648\u0645\u064A\u0629\u060C \u0639\u0631\u0648\u0636 \u0627\u0644\u0645\u062A\u062C\u0631.
// \u062A\u064F\u062C\u062F\u0648\u0644 \u0645\u0631\u0643\u0632\u064A\u0627\u064B \u0639\u0646\u062F \u0641\u062A\u062D \u0627\u0644\u062A\u0637\u0628\u064A\u0642 (AuthGate) \u0648\u062A\u064F\u0639\u0627\u062F \u062C\u062F\u0648\u0644\u062A\u0647\u0627 \u0643\u0644 \u062C\u0644\u0633\u0629.
class AppNotifs {
  static const _waterCh = 'water_channel';
  static const _tipsCh = 'tips_channel';
  static const _pregCh = 'pregnancy_channel';
  static const _prodCh = 'products_channel';

  // \u0646\u0637\u0627\u0642\u0627\u062A \u0627\u0644\u0645\u0639\u0631\u0651\u0641\u0627\u062A (\u0644\u0627 \u062A\u062A\u0639\u0627\u0631\u0636 \u0645\u0639 \u062A\u0630\u0643\u064A\u0631\u0627\u062A \u0627\u0644\u0623\u062F\u0648\u064A\u0629 \u0627\u0644\u062A\u064A \u062A\u0633\u062A\u062E\u062F\u0645 hash \u0643\u0628\u064A\u0631)
  static const _waterBase = 1000; // 1000-1019
  static const _tipsBase = 1100;  // 1100-1129
  static const _pregBase = 1200;  // 1200-1219
  static const _prodBase = 1300;  // 1300-1329

  static bool _done = false;

  // \u0645\u0641\u0627\u062A\u064A\u062D \u0627\u0644\u062A\u0634\u063A\u064A\u0644/\u0627\u0644\u0625\u064A\u0642\u0627\u0641 (\u064A\u062A\u062D\u0643\u0645 \u0628\u0647\u0627 \u0627\u0644\u0623\u062F\u0645\u0646 \u0639\u0628\u0631 \u0625\u0639\u062F\u0627\u062F\u0627\u062A \u0639\u0627\u0645\u0629 \u0641\u064A Firestore)
  static Map<String, dynamic> _flags = {};

  static const List<String> _tips = [
    '\u0627\u0634\u0631\u0628\u064A 8 \u0623\u0643\u0648\u0627\u0628 \u0645\u0627\u0621 \u064A\u0648\u0645\u064A\u0627\u064B \u0644\u0644\u062D\u0641\u0627\u0638 \u0639\u0644\u0649 \u0646\u0634\u0627\u0637\u0643 \u0648\u0635\u062D\u0629 \u0628\u0634\u0631\u062A\u0643 \uD83D\uDCA7',
    '\u062A\u0646\u0627\u0648\u0644\u064A \u0648\u062C\u0628\u0629 \u0641\u0637\u0648\u0631 \u063A\u0646\u064A\u0629 \u0628\u0627\u0644\u062D\u062F\u064A\u062F \u0648\u0627\u0644\u0628\u0631\u0648\u062A\u064A\u0646 \u0644\u0637\u0627\u0642\u0629 \u062A\u062F\u0648\u0645 \u0637\u0648\u0627\u0644 \u0627\u0644\u064A\u0648\u0645 \uD83C\uDF73',
    '\u0627\u0644\u0645\u0634\u064A 30 \u062F\u0642\u064A\u0642\u0629 \u064A\u0648\u0645\u064A\u0627\u064B \u064A\u062D\u0633\u0651\u0646 \u0627\u0644\u0645\u0632\u0627\u062C \u0648\u064A\u0646\u0638\u0651\u0645 \u0627\u0644\u0646\u0648\u0645 \uD83D\uDEB6\u200D\u2640\uFE0F',
    '\u0627\u062D\u0631\u0635\u064A \u0639\u0644\u0649 \u062D\u0645\u0636 \u0627\u0644\u0641\u0648\u0644\u064A\u0643 \u0625\u0646 \u0643\u0646\u062A\u0650 \u062D\u0627\u0645\u0644\u0627\u064B \u0623\u0648 \u062A\u062E\u0637\u0637\u064A\u0646 \u0644\u0644\u062D\u0645\u0644 \uD83C\uDF3F',
    '\u0627\u0644\u0646\u0648\u0645 \u0627\u0644\u0643\u0627\u0641\u064A (7-8 \u0633\u0627\u0639\u0627\u062A) \u0623\u0633\u0627\u0633 \u0644\u0635\u062D\u062A\u0643 \u0627\u0644\u0647\u0631\u0645\u0648\u0646\u064A\u0629 \uD83D\uDE34',
    '\u0642\u0644\u0651\u0644\u064A \u0627\u0644\u0643\u0627\u0641\u064A\u064A\u0646 \u0628\u0639\u062F \u0627\u0644\u0638\u0647\u0631 \u0644\u0646\u0648\u0645 \u0623\u0639\u0645\u0642 \u0648\u0623\u0647\u062F\u0623 \u2615',
    '\u0623\u0636\u064A\u0641\u064A \u0627\u0644\u062E\u0636\u0627\u0631 \u0627\u0644\u0648\u0631\u0642\u064A\u0629 \u0644\u0648\u062C\u0628\u0627\u062A\u0643 \u0644\u062A\u0639\u0632\u064A\u0632 \u0627\u0644\u062D\u062F\u064A\u062F \u0648\u0627\u0644\u0643\u0627\u0644\u0633\u064A\u0648\u0645 \uD83E\uDD6C',
    '\u062E\u0635\u0651\u0635\u064A \u062F\u0642\u0627\u0626\u0642 \u0644\u0644\u062A\u0646\u0641\u0633 \u0627\u0644\u0639\u0645\u064A\u0642 \u0644\u062A\u0642\u0644\u064A\u0644 \u0627\u0644\u062A\u0648\u062A\u0631 \uD83E\uDDD8\u200D\u2640\uFE0F',
    '\u062A\u0627\u0628\u0639\u064A \u0648\u0632\u0646\u0643 \u0648\u0636\u063A\u0637\u0643 \u0628\u0627\u0646\u062A\u0638\u0627\u0645 \u0641\u064A \u0642\u0633\u0645 \u0627\u0644\u0642\u064A\u0627\u0633\u0627\u062A \u0627\u0644\u0635\u062D\u064A\u0629 \uD83D\uDCCA',
    '\u062A\u0646\u0627\u0648\u0644\u064A \u0627\u0644\u0623\u0648\u0645\u064A\u063A\u0627 3 (\u0627\u0644\u0633\u0645\u0643\u060C \u0627\u0644\u062C\u0648\u0632) \u0644\u0635\u062D\u0629 \u0627\u0644\u0642\u0644\u0628 \u0648\u0627\u0644\u062F\u0645\u0627\u063A \uD83D\uDC1F',
    '\u062A\u0639\u0631\u0651\u0636\u064A \u0644\u0623\u0634\u0639\u0629 \u0627\u0644\u0634\u0645\u0633 \u0635\u0628\u0627\u062D\u0627\u064B \u0644\u0641\u064A\u062A\u0627\u0645\u064A\u0646 D \uD83C\uDF1E',
    '\u0644\u0627 \u062A\u0647\u0645\u0644\u064A \u0641\u062D\u0648\u0635\u0627\u062A\u0643 \u0627\u0644\u062F\u0648\u0631\u064A\u0629 \u0648\u0645\u0648\u0627\u0639\u064A\u062F \u0627\u0644\u0637\u0628\u064A\u0628 \uD83E\uDE7A',
    '\u0627\u0634\u0631\u0628\u064A \u0643\u0648\u0628 \u0645\u0627\u0621 \u0642\u0628\u0644 \u0643\u0644 \u0648\u062C\u0628\u0629 \u0644\u0644\u0647\u0636\u0645 \u0648\u0627\u0644\u0634\u0628\u0639 \uD83E\uDD5B',
    '\u062E\u0630\u064A \u0642\u0633\u0637\u0627\u064B \u0645\u0646 \u0627\u0644\u0631\u0627\u062D\u0629 \u0639\u0646\u062F \u0627\u0644\u0634\u0639\u0648\u0631 \u0628\u0627\u0644\u062A\u0639\u0628 \u2014 \u062C\u0633\u0645\u0643 \u064A\u0633\u062A\u062D\u0642 \u0627\u0644\u0639\u0646\u0627\u064A\u0629 \uD83D\uDC97',
  ];

  static NotificationDetails _d(String ch, String name) => NotificationDetails(
        android: AndroidNotificationDetails(ch, name,
            importance: Importance.high, priority: Priority.high, icon: '@mipmap/ic_launcher'),
      );

  static tz.TZDateTime _todayAt(int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (!d.isAfter(now)) d = d.add(const Duration(days: 1));
    return d;
  }

  static tz.TZDateTime _inDaysAt(int days, int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    final b = now.add(Duration(days: days));
    return tz.TZDateTime(tz.local, b.year, b.month, b.day, h, m);
  }

  static bool _on(String key) => _flags[key] != false; // \u0627\u0641\u062A\u0631\u0627\u0636\u064A\u0627\u064B \u0645\u0641\u0639\u0651\u0644

  static Future<void> _zonedDaily(
      int id, String ch, String name, String title, String body, int h, int m) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id, title, body, _todayAt(h, m), _d(ch, name),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> _zonedOnce(
      int id, String ch, String name, String title, String body, tz.TZDateTime when) async {
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id, title, body, when, _d(ch, name),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  static Future<void> _cancelRange(int start, int end) async {
    for (int i = start; i <= end; i++) {
      try {
        await flutterLocalNotificationsPlugin.cancel(i);
      } catch (_) {}
    }
  }

  static Future<void> _ensureChannels() async {
    try {
      final a = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      const chs = [
        [_waterCh, '\u062A\u0630\u0643\u064A\u0631 \u0634\u0631\u0628 \u0627\u0644\u0645\u0627\u0621'],
        [_tipsCh, '\u0646\u0635\u0627\u0626\u062D \u064A\u0648\u0645\u064A\u0629'],
        [_pregCh, '\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062D\u0645\u0644 \u0648\u0627\u0644\u062F\u0648\u0631\u0629'],
        [_prodCh, '\u0639\u0631\u0648\u0636 \u0648\u0645\u0646\u062A\u062C\u0627\u062A \u0646\u0628\u0636\u0629'],
      ];
      for (final c in chs) {
        await a?.createNotificationChannel(
          AndroidNotificationChannel(c[0], c[1], importance: Importance.high),
        );
      }
    } catch (_) {}
  }

  /// \u0646\u0642\u0637\u0629 \u0627\u0644\u062F\u062E\u0648\u0644: \u062A\u064F\u0633\u062A\u062F\u0639\u0649 \u0645\u0631\u0629 \u0648\u0627\u062D\u062F\u0629 \u0639\u0646\u062F \u0641\u062A\u062D \u0627\u0644\u062A\u0637\u0628\u064A\u0642 \u0628\u0639\u062F \u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644.
  static Future<void> scheduleAll() async {
    if (_done) return;
    _done = true;
    try {
      await _ensureChannels();
      await _loadFlags();
      if (_on('water')) await _scheduleWater(); else await _cancelRange(_waterBase, _waterBase + 19);
      if (_on('tips')) await _scheduleTips(); else await _cancelRange(_tipsBase, _tipsBase + 29);
      if (_on('pregnancy')) await _schedulePregnancyAndCycle(); else await _cancelRange(_pregBase, _pregBase + 19);
      if (_on('products')) await _scheduleProducts(); else await _cancelRange(_prodBase, _prodBase + 29);
    } catch (_) {}
  }

  // \u0625\u0639\u062F\u0627\u062F\u0627\u062A \u0639\u0627\u0645\u0629 \u064A\u062A\u062D\u0643\u0645 \u0628\u0647\u0627 \u0627\u0644\u0623\u062F\u0645\u0646: app_config/notifications { water, tips, pregnancy, products: bool }
  static Future<void> _loadFlags() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config').doc('notifications').get();
      _flags = doc.data() ?? {};
    } catch (_) {
      _flags = {};
    }
  }

  static Future<void> _scheduleWater() async {
    await _cancelRange(_waterBase, _waterBase + 19);
    // \u0645\u0631\u062A\u064A\u0646 \u064A\u0648\u0645\u064A\u0627\u064B \u0641\u0642\u0637: \u0635\u0628\u0627\u062D\u0627\u064B 10:00 \u0648\u0645\u0633\u0627\u0621\u064B 18:00
    const hours = [10, 18];
    for (int i = 0; i < hours.length; i++) {
      await _zonedDaily(_waterBase + i, _waterCh, '\u062A\u0630\u0643\u064A\u0631 \u0634\u0631\u0628 \u0627\u0644\u0645\u0627\u0621',
          '\uD83D\uDCA7 \u0648\u0642\u062A \u0634\u0631\u0628 \u0627\u0644\u0645\u0627\u0621', '\u062D\u0627\u0646 \u0648\u0642\u062A \u0634\u0631\u0628 \u0643\u0648\u0628 \u0645\u0627\u0621 \u2014 \u062D\u0627\u0641\u0638\u064A \u0639\u0644\u0649 \u062A\u0631\u0637\u064A\u0628 \u062C\u0633\u0645\u0643!', hours[i], 0);
    }
  }

  static Future<void> _scheduleTips() async {
    await _cancelRange(_tipsBase, _tipsBase + 29);
    // 4 \u0646\u0635\u0627\u0626\u062D \u0641\u0642\u0637\u060C \u0643\u0644 \u064A\u0648\u0645\u064A\u0646 \u062A\u0642\u0631\u064A\u0628\u0627\u064B\u060C \u0627\u0644\u0633\u0627\u0639\u0629 7\u0645\u060C \u062A\u062A\u062F\u0648\u0651\u0631 \u0645\u0646 \u0627\u0644\u0642\u0627\u0626\u0645\u0629
    final dayOffset = DateTime.now().day; // \u062A\u062F\u0648\u064A\u0631 \u062D\u0633\u0628 \u0627\u0644\u064A\u0648\u0645
    for (int i = 0; i < 4; i++) {
      final tip = _tips[(dayOffset + i) % _tips.length];
      await _zonedOnce(_tipsBase + i, _tipsCh, '\u0646\u0635\u0627\u0626\u062D \u064A\u0648\u0645\u064A\u0629',
          '\uD83D\uDCA1 \u0646\u0635\u064A\u062D\u0629 \u0627\u0644\u064A\u0648\u0645', tip, _inDaysAt(i * 2, 19, 0));
    }
  }

  static Future<void> _schedulePregnancyAndCycle() async {
    await _cancelRange(_pregBase, _pregBase + 19);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return;

      final pregTs = data['pregnancyStart'];
      if (pregTs is Timestamp) {
        // \u0648\u0636\u0639 \u0627\u0644\u062D\u0645\u0644: \u062A\u0630\u0643\u064A\u0631 \u0623\u0633\u0628\u0648\u0639\u064A \u0644\u0644\u0623\u0633\u0627\u0628\u064A\u0639 \u0627\u0644\u0623\u0631\u0628\u0639\u0629 \u0627\u0644\u0642\u0627\u062F\u0645\u0629
        final start = pregTs.toDate();
        final week = (DateTime.now().difference(start).inDays / 7).floor().clamp(1, 42);
        int id = _pregBase;
        for (int w = 0; w < 4; w++) {
          final cw = (week + w).clamp(1, 42);
          await _zonedOnce(id++, _pregCh, '\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062D\u0645\u0644',
              '\uD83E\uDD30 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 $cw \u0645\u0646 \u0627\u0644\u062D\u0645\u0644',
              '\u0623\u0646\u062A\u0650 \u0641\u064A \u0627\u0644\u0623\u0633\u0628\u0648\u0639 $cw \uD83D\uDC95 \u0627\u0637\u0651\u0644\u0639\u064A \u0639\u0644\u0649 \u062A\u0637\u0648\u0651\u0631 \u0637\u0641\u0644\u0643 \u0648\u0646\u0635\u0627\u0626\u062D \u0647\u0630\u0627 \u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0641\u064A \u062A\u0637\u0628\u064A\u0642 \u0646\u0628\u0636\u0629.',
              _inDaysAt(w * 7, 10, 0));
        }
        return;
      }

      final lpTs = data['lastPeriodStart'];
      if (lpTs is Timestamp) {
        // \u0648\u0636\u0639 \u0627\u0644\u062F\u0648\u0631\u0629: \u062A\u0630\u0643\u064A\u0631 \u0642\u0628\u0644 \u0627\u0644\u0645\u0648\u0639\u062F + \u064A\u0648\u0645\u0647
        final start = lpTs.toDate();
        final len = (data['cycleLength'] as num?)?.toInt() ?? 28;
        final next = start.add(Duration(days: len));
        final now = DateTime.now();
        if (next.isAfter(now) && next.difference(now).inDays <= 45) {
          final r2 = next.subtract(const Duration(days: 2));
          await _zonedOnce(_pregBase, _pregCh, '\u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062F\u0648\u0631\u0629',
              '\uD83D\uDCC5 \u062F\u0648\u0631\u062A\u0643 \u062A\u0642\u062A\u0631\u0628', '\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0645\u062A\u0648\u0642\u0651\u0639\u0629 \u0628\u0639\u062F \u064A\u0648\u0645\u064A\u0646 \uD83C\uDF38 \u062C\u0647\u0651\u0632\u064A \u0646\u0641\u0633\u0643.',
              tz.TZDateTime(tz.local, r2.year, r2.month, r2.day, 10, 0));
          await _zonedOnce(_pregBase + 1, _pregCh, '\u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062F\u0648\u0631\u0629',
              '\uD83D\uDCC5 \u0645\u0648\u0639\u062F \u0627\u0644\u062F\u0648\u0631\u0629', '\u0627\u0644\u064A\u0648\u0645 \u0627\u0644\u0645\u0648\u0639\u062F \u0627\u0644\u0645\u062A\u0648\u0642\u0651\u0639 \u0644\u062F\u0648\u0631\u062A\u0643 \uD83D\uDC97 \u0627\u0639\u062A\u0646\u064A \u0628\u0646\u0641\u0633\u0643.',
              tz.TZDateTime(tz.local, next.year, next.month, next.day, 10, 0));
        }
      }
    } catch (_) {}
  }

  static Future<void> _scheduleProducts() async {
    await _cancelRange(_prodBase, _prodBase + 29);
    // \u062C\u0644\u0628 \u0645\u0646\u062A\u062C\u0627\u062A \u0645\u0646 Firestore
    final products = <Map<String, String>>[];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      for (final d in snap.docs) {
        final m = d.data();
        final name = (m['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        products.add({
          'name': name,
          'price': (m['price'] ?? '').toString().trim(),
          'emoji': (m['emoji'] ?? '\uD83D\uDECD\uFE0F').toString(),
        });
      }
    } catch (_) {}

    // \u0645\u0631\u062A\u064A\u0646 \u064A\u0648\u0645\u064A\u0627\u064B (11:00 \u0648 19:00) \u0644\u0644\u0623\u064A\u0627\u0645 \u0627\u0644\u062B\u0644\u0627\u062B\u0629 \u0627\u0644\u0642\u0627\u062F\u0645\u0629
    const times = [11, 19];
    int id = _prodBase;
    for (int day = 0; day < 3; day++) {
      for (int t = 0; t < times.length; t++) {
        final slot = day * times.length + t;
        String title, body;
        if (products.isNotEmpty) {
          final p = products[slot % products.length];
          final price = p['price']!.isNotEmpty ? ' \u0628\u0633\u0639\u0631 ${p['price']}' : '';
          title = '${p['emoji']} \u0639\u0631\u0636 \u0627\u0644\u064A\u0648\u0645 \u0645\u0646 \u0645\u062A\u062C\u0631 \u0646\u0628\u0636\u0629';
          body = '${p['name']}$price \uD83D\uDED2 \u062A\u0633\u0648\u0651\u0642\u064A \u0627\u0644\u0622\u0646 \u0645\u0646 \u0645\u062A\u062C\u0631 \u0646\u0628\u0636\u0629!';
        } else {
          title = '\uD83D\uDECD\uFE0F \u0645\u062A\u062C\u0631 \u0646\u0628\u0636\u0629';
          body = '\u0627\u0643\u062A\u0634\u0641\u064A \u0645\u0646\u062A\u062C\u0627\u062A \u0645\u062E\u062A\u0627\u0631\u0629 \u0644\u0644\u0623\u0645 \u0648\u0627\u0644\u0637\u0641\u0644 \u0641\u064A \u0645\u062A\u062C\u0631 \u0646\u0628\u0636\u0629 \uD83D\uDC95';
        }
        await _zonedOnce(id++, _prodCh, '\u0639\u0631\u0648\u0636 \u0648\u0645\u0646\u062A\u062C\u0627\u062A \u0646\u0628\u0636\u0629', title, body,
            _inDaysAt(day, times[t], 0));
      }
    }
  }
}

// ==================== REMINDERS PAGE ====================
class RemindersPage extends StatefulWidget {
  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool _waterReminder = false;
  bool _cycleReminder = true;
  bool _medReminder = false;
  bool _vaccineReminder = true;
  String _medName = '';
  TimeOfDay _medTime = TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterReminder = prefs.getBool('water_reminder') ?? false;
      _cycleReminder = prefs.getBool('cycle_reminder') ?? true;
      _medReminder = prefs.getBool('med_reminder') ?? false;
      _vaccineReminder = prefs.getBool('vaccine_reminder') ?? true;
      _medName = prefs.getString('med_name') ?? '';
      _medTime = TimeOfDay(
        hour: prefs.getInt('med_hour') ?? 8,
        minute: prefs.getInt('med_minute') ?? 0,
      );
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cycle_reminder', _cycleReminder);
    await prefs.setBool('vaccine_reminder', _vaccineReminder);
    await prefs.setString('med_name', _medName);
    await prefs.setInt('med_hour', _medTime.hour);
    await prefs.setInt('med_minute', _medTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(centerTitle: true,
          title: Text('\u0627\u0644\u062A\u0630\u0643\u064A\u0631\u0627\u062A'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.teal.shade700, Colors.teal.shade400]),
            ),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Water Reminder
            _buildReminderCard(
              icon: Icons.water_drop,
              color: Colors.blue,
              title: '\u062A\u0630\u0643\u064A\u0631 \u0634\u0631\u0628 \u0627\u0644\u0645\u0627\u0621',
              subtitle: '\u0643\u0644 \u0633\u0627\u0639\u062A\u064A\u0646 \u0645\u0646 8 \u0635\u0628\u0627\u062D\u0627\u064B \u0625\u0644\u0649 10 \u0645\u0633\u0627\u0621\u064B',
              value: _waterReminder,
              onChanged: (v) async {
                setState(() => _waterReminder = v);
                await NotifService.scheduleWaterReminders(v);
                if (v && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('\u062A\u0645 \u062A\u0641\u0639\u064A\u0644 \u062A\u0630\u0643\u064A\u0631 \u0634\u0631\u0628 \u0627\u0644\u0645\u0627\u0621'), backgroundColor: Colors.blue));
                }
              },
            ),
            SizedBox(height: 12),
            // Cycle Reminder
            _buildReminderCard(
              icon: Icons.calendar_month,
              color: Colors.pink,
              title: '\u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0634\u0647\u0631\u064A\u0629',
              subtitle: '\u0642\u0628\u0644 \u064A\u0648\u0645\u064A\u0646 \u0645\u0646 \u0627\u0644\u0645\u0648\u0639\u062F \u0627\u0644\u0645\u062A\u0648\u0642\u0639',
              value: _cycleReminder,
              onChanged: (v) async {
                setState(() => _cycleReminder = v);
                await _savePrefs();
                if (v && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('\u062A\u0645 \u062A\u0641\u0639\u064A\u0644 \u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062F\u0648\u0631\u0629'), backgroundColor: Colors.pink));
                }
              },
            ),
            SizedBox(height: 12),
            // Vaccine Reminder
            _buildReminderCard(
              icon: Icons.vaccines,
              color: Colors.orange,
              title: '\u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A',
              subtitle: '\u0642\u0628\u0644 \u064A\u0648\u0645 \u0645\u0646 \u0645\u0648\u0639\u062F \u0627\u0644\u062A\u0637\u0639\u064A\u0645',
              value: _vaccineReminder,
              onChanged: (v) async {
                setState(() => _vaccineReminder = v);
                await _savePrefs();
                if (v && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('\u062A\u0645 \u062A\u0641\u0639\u064A\u0644 \u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A'), backgroundColor: Colors.orange));
                }
              },
            ),
            SizedBox(height: 12),
            // Medicine Reminder
            _buildReminderCard(
              icon: Icons.medication,
              color: Colors.green,
              title: '\u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062F\u0648\u0627\u0621',
              subtitle: _medReminder && _medName.isNotEmpty
                  ? '$_medName - ${_medTime.format(context)}'
                  : '\u062D\u062F\u062F\u064A \u0627\u0633\u0645 \u0627\u0644\u062F\u0648\u0627\u0621 \u0648\u0627\u0644\u0648\u0642\u062A',
              value: _medReminder,
              onChanged: (v) async {
                if (v) {
                  await _showMedDialog();
                } else {
                  setState(() => _medReminder = false);
                  await NotifService.scheduleMedReminder(false, '', 0, 0);
                }
              },
            ),
            SizedBox(height: 24),
            // Test notification button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.notifications_active),
                label: Text('\u0627\u062E\u062A\u0628\u0627\u0631 \u0627\u0644\u062A\u0646\u0628\u064A\u0647\u0627\u062A'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  NotifService.showNow(999, '\u0646\u0628\u0636\u0629', '\u0627\u0644\u062A\u0646\u0628\u064A\u0647\u0627\u062A \u062A\u0639\u0645\u0644 \u0628\u0646\u062C\u0627\u062D! \u{1F49C}', 'test');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('\u062A\u0645 \u0625\u0631\u0633\u0627\u0644 \u062A\u0646\u0628\u064A\u0647 \u062A\u062C\u0631\u064A\u0628\u064A'), backgroundColor: Colors.teal));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ),
    );
  }

  Future<void> _showMedDialog() async {
    final nameController = TextEditingController(text: _medName);
    TimeOfDay selectedTime = _medTime;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text('\u062A\u0630\u0643\u064A\u0631 \u0627\u0644\u062F\u0648\u0627\u0621'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '\u0627\u0633\u0645 \u0627\u0644\u062F\u0648\u0627\u0621',
                  prefixIcon: Icon(Icons.medication),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (t != null) setDialogState(() => selectedTime = t);
                },
                child: Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.access_time, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('\u0627\u0644\u0648\u0642\u062A: ${selectedTime.format(ctx)}', style: TextStyle(fontSize: 16)),
                  ]),
                ),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('\u0625\u0644\u063A\u0627\u0621')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: Text('\u062D\u0641\u0638'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true && nameController.text.isNotEmpty) {
      setState(() {
        _medReminder = true;
        _medName = nameController.text;
        _medTime = selectedTime;
      });
      await _savePrefs();
      await NotifService.scheduleMedReminder(true, _medName, _medTime.hour, _medTime.minute);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u062A\u0645 \u062A\u0641\u0639\u064A\u0644 \u062A\u0630\u0643\u064A\u0631 $_medName'), backgroundColor: Colors.green));
      }
    }
  }
}

// ==================== LOGIN PAGE ====================
class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final confirmPassC = TextEditingController();
  final nameC = TextEditingController();
  bool loading = false;
  String msg = '';
  bool isRegister = false;
  bool obscurePass = true;
  bool obscureConfirm = true;
  bool acceptTerms = false;
  int passwordStrength = 0;

  late AnimationController _bgController;
  late AnimationController _formController;
  late Animation<double> _logoScale;
  late Animation<Offset> _titleSlide;
  late Animation<double> _formFade;
  late Animation<Offset> _field1Slide;
  late Animation<Offset> _field2Slide;
  late Animation<Offset> _field3Slide;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    passC.addListener(_calcStrength);

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _formController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.0, 0.3, curve: Curves.elasticOut)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.15, 0.4, curve: Curves.easeOutCubic)));
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.25, 0.5, curve: Curves.easeIn)));
    _field1Slide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.3, 0.55, curve: Curves.easeOutCubic)));
    _field2Slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.4, 0.65, curve: Curves.easeOutCubic)));
    _field3Slide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.45, 0.7, curve: Curves.easeOutCubic)));
    _buttonScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.6, 0.85, curve: Curves.elasticOut)));

    _formController.forward();
  }

  void _calcStrength() {
    final p = passC.text;
    int s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s++;
    setState(() => passwordStrength = s.clamp(0, 5));
  }

  @override
  void dispose() {
    emailC.dispose(); passC.dispose(); confirmPassC.dispose(); nameC.dispose();
    _bgController.dispose(); _formController.dispose();
    super.dispose();
  }

  void _restartAnimation() {
    _formController.reset();
    _formController.forward();
  }

  void doAuth() async {
    if (emailC.text.isEmpty || passC.text.isEmpty) {
      setState(() { msg = '\u064A\u0631\u062C\u0649 \u0645\u0644\u0621 \u062C\u0645\u064A\u0639 \u0627\u0644\u062D\u0642\u0648\u0644'; });
      return;
    }
    if (isRegister && passC.text != confirmPassC.text) {
      setState(() { msg = '\u0643\u0644\u0645\u062A\u0627 \u0627\u0644\u0645\u0631\u0648\u0631 \u063A\u064A\u0631 \u0645\u062A\u0637\u0627\u0628\u0642\u062A\u064A\u0646'; });
      return;
    }
    if (isRegister && !acceptTerms) {
      setState(() { msg = '\u064A\u0631\u062C\u0649 \u0627\u0644\u0645\u0648\u0627\u0641\u0642\u0629 \u0639\u0644\u0649 \u0627\u0644\u0634\u0631\u0648\u0637 \u0648\u0627\u0644\u0623\u062D\u0643\u0627\u0645'; });
      return;
    }
    setState(() { loading = true; msg = ''; });
    try {
      if (isRegister) {
        var cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailC.text.trim(), password: passC.text);
        if (nameC.text.isNotEmpty) await cred.user?.updateDisplayName(nameC.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': nameC.text.trim(),
          'email': emailC.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'cycleLength': 28,
          'lastPeriodStart': null,
          'pregnancyStartDate': null,
          'babyName': '',
          'babyBirthDate': null,
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailC.text.trim(), password: passC.text);
      }
    } catch (e) {
      String error = e.toString().split(']').last.trim();
      if (error.contains('user-not-found')) error = '\u0644\u0627 \u064A\u0648\u062C\u062F \u062D\u0633\u0627\u0628 \u0628\u0647\u0630\u0627 \u0627\u0644\u0628\u0631\u064A\u062F';
      else if (error.contains('wrong-password') || error.contains('invalid-credential')) error = '\u0627\u0644\u0628\u0631\u064A\u062F \u0623\u0648 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u063A\u064A\u0631 \u0635\u062D\u064A\u062D\u0629';
      else if (error.contains('email-already-in-use')) error = '\u0647\u0630\u0627 \u0627\u0644\u0628\u0631\u064A\u062F \u0645\u0633\u062A\u062E\u062F\u0645 \u0628\u0627\u0644\u0641\u0639\u0644';
      else if (error.contains('weak-password')) error = '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0636\u0639\u064A\u0641\u0629 \u062C\u062F\u0627\u064B';
      else error = '\u062D\u062F\u062B \u062E\u0637\u0623 \u063A\u064A\u0631 \u0645\u062A\u0648\u0642\u0639';
      setState(() { msg = error; });
    }
    if (mounted) setState(() { loading = false; });
  }

  void _showForgotPassword() {
    final resetC = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('\u0627\u0633\u062A\u0639\u0627\u062F\u0629 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('\u0623\u062F\u062E\u0644\u064A \u0628\u0631\u064A\u062F\u0643 \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A \u0644\u0625\u0631\u0633\u0627\u0644 \u0631\u0627\u0628\u0637 \u0627\u0644\u0627\u0633\u062A\u0639\u0627\u062F\u0629', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(controller: resetC, keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: '\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A', prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFFE91E63)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2)))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: () async {
                if (resetC.text.trim().isEmpty) return;
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: resetC.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('\u062A\u0645 \u0625\u0631\u0633\u0627\u0644 \u0631\u0627\u0628\u0637 \u0627\u0644\u0627\u0633\u062A\u0639\u0627\u062F\u0629 \u0625\u0644\u0649 \u0628\u0631\u064A\u062F\u0643'), backgroundColor: const Color(0xFF00897B), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('\u062E\u0637\u0623: $e'))); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('\u0625\u0631\u0633\u0627\u0644 \u0631\u0627\u0628\u0637 \u0627\u0644\u0627\u0633\u062A\u0639\u0627\u062F\u0629', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) => CustomPaint(
                painter: _AuthBgPainter(_bgController.value, isRegister),
                size: Size.infinite,
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    SizedBox(height: isRegister ? 30 : 50),
                    // Logo with bounce
                    ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 95, height: 95,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isRegister ? [const Color(0xFF00897B), const Color(0xFF4DB6AC)] : [const Color(0xFFE91E63), const Color(0xFFFF6090)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: (isRegister ? const Color(0xFF00897B) : const Color(0xFFE91E63)).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Icon(isRegister ? Icons.person_add_rounded : Icons.favorite_rounded, color: Colors.white, size: 46),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Title with slide
                    SlideTransition(
                      position: _titleSlide,
                      child: Column(children: [
                        Text(isRegister ? '\u0627\u0646\u0636\u0645\u064A \u0625\u0644\u064A\u0646\u0627' : '\u0645\u0631\u062D\u0628\u0627\u064B \u0628\u0639\u0648\u062F\u062A\u0643',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
                        const SizedBox(height: 6),
                        Text(isRegister ? '\u0623\u0646\u0634\u0626\u064A \u062D\u0633\u0627\u0628\u0643 \u0648\u0627\u0633\u062A\u0645\u062A\u0639\u064A \u0628\u062E\u062F\u0645\u0627\u062A\u0646\u0627' : '\u0633\u062C\u0644\u064A \u0627\u0644\u062F\u062E\u0648\u0644 \u0644\u0645\u062A\u0627\u0628\u0639\u0629 \u0635\u062D\u062A\u0643',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                      ]),
                    ),
                    const SizedBox(height: 30),
                    // Form card with fade
                    FadeTransition(
                      opacity: _formFade,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10))],
                        ),
                        child: Column(children: [
                          // Name field (register only)
                          if (isRegister) ...[
                            SlideTransition(position: _field1Slide, child: _styledField(nameC, '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644', '\u0641\u0627\u0637\u0645\u0629', Icons.person_rounded)),
                            const SizedBox(height: 14),
                          ],
                          // Email
                          SlideTransition(position: isRegister ? _field2Slide : _field1Slide,
                            child: _styledField(emailC, '\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A', 'example@gmail.com', Icons.email_rounded, keyboardType: TextInputType.emailAddress, isLtr: true)),
                          const SizedBox(height: 14),
                          // Password
                          SlideTransition(position: isRegister ? _field3Slide : _field2Slide,
                            child: _styledField(passC, '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631', '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022', Icons.lock_rounded, isPassword: true, obscure: obscurePass,
                              onToggle: () => setState(() => obscurePass = !obscurePass))),
                          // Password strength (register)
                          if (isRegister && passC.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildPasswordStrength(),
                          ],
                          // Confirm password (register)
                          if (isRegister) ...[
                            const SizedBox(height: 14),
                            _styledField(confirmPassC, '\u062A\u0623\u0643\u064A\u062F \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631', '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022', Icons.lock_outline_rounded, isPassword: true, obscure: obscureConfirm,
                              onToggle: () => setState(() => obscureConfirm = !obscureConfirm)),
                          ],
                          // Forgot password (login only)
                          if (!isRegister) ...[
                            const SizedBox(height: 6),
                            Align(alignment: Alignment.centerLeft,
                              child: TextButton(onPressed: _showForgotPassword,
                                child: Text('\u0647\u0644 \u0646\u0633\u064A\u062A\u0650 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631\u061F', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)))),
                          ],
                          // Terms checkbox (register)
                          if (isRegister) ...[
                            const SizedBox(height: 12),
                            _buildTermsCheckbox(),
                          ],
                          const SizedBox(height: 18),
                          // Error message
                          if (msg.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12),
                            child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Row(children: [Icon(Icons.error_outline, color: Colors.red.shade400, size: 20), const SizedBox(width: 8), Expanded(child: Text(msg, style: TextStyle(color: Colors.red.shade700, fontSize: 13)))]))),
                          // Button with scale
                          ScaleTransition(
                            scale: _buttonScale,
                            child: SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
                              onPressed: (loading || (isRegister && !acceptTerms)) ? null : doAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isRegister ? const Color(0xFF00897B) : const Color(0xFFE91E63),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                elevation: 8,
                                shadowColor: (isRegister ? const Color(0xFF00897B) : const Color(0xFFE91E63)).withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                              child: loading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                : Text(isRegister ? '\u0625\u0646\u0634\u0627\u0621 \u062D\u0633\u0627\u0628' : '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))))),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Divider
                    FadeTransition(opacity: _formFade, child: Row(children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('\u0623\u0648', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ])),
                    const SizedBox(height: 16),
                    // Toggle
                    FadeTransition(opacity: _formFade, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(isRegister ? '\u0644\u062F\u064A\u0643 \u062D\u0633\u0627\u0628 \u0628\u0627\u0644\u0641\u0639\u0644\u061F ' : '\u0644\u064A\u0633 \u0644\u062F\u064A\u0643 \u062D\u0633\u0627\u0628\u061F ', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      GestureDetector(
                        onTap: () { setState(() { isRegister = !isRegister; msg = ''; }); _restartAnimation(); },
                        child: Text(isRegister ? '\u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u062E\u0648\u0644' : '\u0625\u0646\u0634\u0627\u0621 \u062D\u0633\u0627\u0628',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isRegister ? const Color(0xFF00897B) : const Color(0xFFE91E63), fontSize: 14))),
                    ])),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styledField(TextEditingController ctrl, String label, String hint, IconData icon, {
    TextInputType? keyboardType, bool isPassword = false, bool obscure = false,
    VoidCallback? onToggle, bool isLtr = false,
  }) {
    final accentColor = isRegister ? const Color(0xFF00897B) : const Color(0xFFE91E63);
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: ctrl, keyboardType: keyboardType,
        obscureText: isPassword ? obscure : false,
        textDirection: isLtr ? TextDirection.ltr : null,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accentColor, size: 20)),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade400),
            onPressed: onToggle) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final labels = ['', '\u0636\u0639\u064A\u0641\u0629 \u062C\u062F\u0627\u064B', '\u0636\u0639\u064A\u0641\u0629', '\u0645\u062A\u0648\u0633\u0637\u0629', '\u062C\u064A\u062F\u0629', '\u0642\u0648\u064A\u0629'];
    final colors = [Colors.grey, Colors.red, Colors.orange, Colors.amber, Colors.lightGreen, Colors.green];
    return Row(children: [
      ...List.generate(5, (i) => Expanded(child: Container(height: 4, margin: EdgeInsets.only(left: i < 4 ? 3 : 0),
        decoration: BoxDecoration(color: i < passwordStrength ? colors[passwordStrength] : Colors.grey.shade200, borderRadius: BorderRadius.circular(2))))),
      const SizedBox(width: 8),
      Text(passwordStrength > 0 ? labels[passwordStrength] : '', style: TextStyle(fontSize: 11, color: colors[passwordStrength])),
    ]);
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => acceptTerms = !acceptTerms),
      child: Row(children: [
        AnimatedContainer(duration: const Duration(milliseconds: 300), width: 24, height: 24,
          decoration: BoxDecoration(
            color: acceptTerms ? const Color(0xFF00897B) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: acceptTerms ? const Color(0xFF00897B) : Colors.grey.shade400, width: 2)),
          child: acceptTerms ? const Icon(Icons.check, color: Colors.white, size: 16) : null),
        const SizedBox(width: 10),
        Expanded(child: Wrap(children: [
          Text('\u0623\u0648\u0627\u0641\u0642 \u0639\u0644\u0649 ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServicePage())),
            child: Text('\u0627\u0644\u0634\u0631\u0648\u0637', style: TextStyle(fontSize: 13, color: isRegister ? const Color(0xFF00897B) : const Color(0xFFE91E63), fontWeight: FontWeight.bold, decoration: TextDecoration.underline))),
          Text(' \u0648', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
            child: Text('\u0627\u0644\u062E\u0635\u0648\u0635\u064A\u0629', style: TextStyle(fontSize: 13, color: isRegister ? const Color(0xFF00897B) : const Color(0xFFE91E63), fontWeight: FontWeight.bold, decoration: TextDecoration.underline))),
        ])),
      ]),
    );
  }
}

// Animated background painter for Auth pages
class _AuthBgPainter extends CustomPainter {
  final double animValue;
  final bool isRegister;
  _AuthBgPainter(this.animValue, this.isRegister);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final mainColor = isRegister ? const Color(0xFF00897B) : const Color(0xFFE91E63);
    final bgTop = isRegister ? const Color(0xFFE0F2F1) : const Color(0xFFFFF0F3);
    final bgMid = isRegister ? const Color(0xFFF5FAFA) : const Color(0xFFFFF5F7);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [bgTop, bgMid, Colors.white], stops: const [0.0, 0.4, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Floating circles
    final positions = [
      [0.1, 0.12, 75.0], [0.88, 0.08, 55.0], [0.75, 0.85, 90.0], [0.12, 0.78, 45.0], [0.5, 0.03, 35.0],
    ];
    for (int i = 0; i < positions.length; i++) {
      final px = positions[i][0], py = positions[i][1], pr = positions[i][2];
      final dx = w * px + sin(animValue * 2 * 3.14159 + i * 1.5) * 18;
      final dy = h * py + cos(animValue * 2 * 3.14159 + i * 1.5) * 12;
      canvas.drawCircle(Offset(dx, dy), pr, Paint()..color = mainColor.withOpacity(0.06));
    }

    // Wave
    final wavePath = Path()..moveTo(0, h * 0.88);
    for (double x = 0; x <= w; x += 1) {
      wavePath.lineTo(x, h * 0.88 + sin((x / w * 4 * 3.14159) + animValue * 2 * 3.14159) * 12);
    }
    wavePath.lineTo(w, h); wavePath.lineTo(0, h); wavePath.close();
    canvas.drawPath(wavePath, Paint()..color = mainColor.withOpacity(0.03));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==================== MAIN NAVIGATION ====================
class MainNav extends StatefulWidget {
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [HomePage(onCardTap: goToTab), CyclePage(), PregnancyPage(), BabyPage(), ShopPage()];
  }

  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLocalizations.textDir,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(index: _index, children: _pages),
            // Profile circle button at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: DB.userDoc.snapshots(),
                  builder: (context, snap) {
                    final photoUrl = (snap.data?.data() as Map<String, dynamic>?)?['photoUrl'] as String?;
                    return Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFF7E57C2)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0x4DE91E63), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: photoUrl != null
                              ? ClipOval(
                                  child: photoUrl.startsWith('data:')
                                      ? Image.memory(base64Decode(photoUrl.split(',').last), width: 36, height: 36, fit: BoxFit.cover)
                                      : Image.network(photoUrl, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFF00897B), size: 20)),
                                )
                              : const Icon(Icons.person, color: Color(0xFF00897B), size: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.only(left: 14, right: 14, bottom: 16),
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B1320).withOpacity(0.10),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final isActive = _index == i;
              final icons = [
                Icons.home_outlined,
                Icons.calendar_month_outlined,
                Icons.pregnant_woman,
                Icons.child_care_outlined,
                Icons.store_outlined,
              ];
              final activeIcons = [
                Icons.home,
                Icons.calendar_month,
                Icons.pregnant_woman,
                Icons.child_care,
                Icons.store,
              ];
              final labels = [
                AppLocalizations.t('home'),
                AppLocalizations.t('cycle'),
                AppLocalizations.t('pregnancy'),
                AppLocalizations.t('baby'),
                AppLocalizations.t('shop'),
              ];
              return GestureDetector(
                onTap: () => setState(() => _index = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: isActive
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF6BA3),
                              Color(0xFFFF4F93),
                              Color(0xFFE53B7E),
                            ],
                          )
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF4F93).withOpacity(0.40),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? activeIcons[i] : icons[i],
                        color: isActive ? Colors.white : const Color(0xFF8E8295),
                        size: 22,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Text(
                          labels[i],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ==================== HOME PAGE (Claude Design Premium) ====================
class HomePage extends StatefulWidget {
  final Function(int)? onCardTap;
  const HomePage({this.onCardTap});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ── Design Tokens ──
  static const _pink = Color(0xFFFF4F93);
  static const _pinkSoft = Color(0xFFFFC8DC);
  static const _pink50 = Color(0xFFFFF1F6);
  static const _lavender = Color(0xFFEADCF8);
  static const _lavender2 = Color(0xFFC7A8EB);
  static const _teal = Color(0xFF15B8A6);
  static const _tealDeep = Color(0xFF0F8B8D);
  static const _teal50 = Color(0xFFE7F7F5);
  static const _cream = Color(0xFFFFF8FA);
  static const _peach = Color(0xFFFFB38A);
  static const _peach50 = Color(0xFFFFF1E8);
  static const _sky = Color(0xFFDDEEFF);
  static const _gold = Color(0xFFFFD79A);
  static const _goldDeep = Color(0xFFC9A84C);
  static const _ink = Color(0xFF1B1320);
  static const _ink2 = Color(0xFF4A3F4F);
  static const _ink3 = Color(0xFF8E8295);
  static const _line = Color(0xFFF0E6EE);

  String _userName = '';
  int _pregnancyWeek = 0;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    int week = 0;
    if (data['pregnancyStart'] != null) {
      try {
        final start = (data['pregnancyStart'] as Timestamp).toDate();
        week = (DateTime.now().difference(start).inDays / 7).floor().clamp(1, 42);
      } catch (_) {}
    }
    if (mounted) setState(() {
      _userName = data['name'] as String? ?? user.displayName ?? '';
      _pregnancyWeek = week;
      _userData = data;
    });
  }

  int _calcCycleDay(Map<String, dynamic> data) {
    if (data['lastPeriodStart'] == null) return 1;
    try {
      Timestamp ts = data['lastPeriodStart'];
      int diff = DateTime.now().difference(ts.toDate()).inDays + 1;
      int len = (data['cycleLength'] as int?) ?? 28;
      return ((diff - 1) % len) + 1;
    } catch (_) { return 1; }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppLocalizations.textDir,
      child: Container(
        color: _cream,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_cream, Colors.white, _cream],
            ),
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: DB.userDoc.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.exists) {
                _userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                if (_userData['name'] != null) _userName = _userData['name'] as String;
                if (_userData['pregnancyStart'] != null) {
                  try {
                    final start = (_userData['pregnancyStart'] as Timestamp).toDate();
                    _pregnancyWeek = (DateTime.now().difference(start).inDays / 7).floor().clamp(1, 42);
                  } catch (_) {}
                }
              }
              return CustomScrollView(
                slivers: [
                  // ── Floating Top Bar as SliverAppBar ──
                  SliverAppBar(
                    floating: true, snap: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 68,
                    flexibleSpace: Container(
                      margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.85), width: 0.5),
                        boxShadow: [
                          BoxShadow(color: _ink.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
                          BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          // Bell icon
                          _topBarIconBtn(
                            icon: Icons.notifications_outlined,
                            color: _pink,
                            showDot: true,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RemindersPage())),
                          ),
                          // Logo center
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const RadialGradient(
                                      center: Alignment(-0.4, -0.5),
                                      colors: [Color(0xFFFF8DB7), _pink, Color(0xFFD63A78)],
                                      stops: [0, 0.55, 1],
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: _pink.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
                                    ],
                                  ),
                                  child: const Center(child: Icon(Icons.favorite, color: Colors.white, size: 16)),
                                ),
                                const SizedBox(width: 8),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [_pink, _lavender2],
                                  ).createShader(bounds),
                                  child: const Text('نبضة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                                ),
                              ],
                            ),
                          ),
                          // Avatar
                          GestureDetector(
                            onTap: () => widget.onCardTap?.call(4),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [_pink, _lavender2, _teal, _peach, _pink],
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(colors: [Color(0xFFFFD9E5), Color(0xFFFFB1CD)]),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    _userName.isNotEmpty ? _userName[0] : 'س',
                                    style: const TextStyle(color: Color(0xFFB6195F), fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ════════════ HERO SECTION ════════════
                        _buildHero(),

                        // ════════════ PREGNANCY TRACKER ════════════
                        if (_pregnancyWeek > 0) _buildTracker(),

                        // ════════════ QUICK ACCESS GRID ════════════
                        _buildSection(
                          eyebrow: 'متابعتي اليومية',
                          title: 'أرقامكِ في لمحة',
                          child: _buildQuickGrid(),
                        ),

                        // ════════════ AI ASSISTANT CARD ════════════
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: _buildAICard(),
                        ),

                        // ════════════ DAILY TIPS (horizontal scroll) ════════════
                        _buildSection(
                          eyebrow: 'نصائح اليوم',
                          title: 'عادات صغيرة، أثر كبير',
                          onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HealthTrackersScreen())),
                          child: const SizedBox.shrink(),
                        ),
                        _buildTipsRow(),

                        // ════════════ EXPLORE GRID ════════════
                        _buildSection(
                          eyebrow: 'استكشفي',
                          title: 'مستكشف نبضة',
                          onViewAll: () {},
                          child: _buildExploreGrid(),
                        ),

                        // ════════════ CHIP ROW ════════════
                        _buildSection(
                          eyebrow: 'المزيد من الأدوات',
                          title: 'كل ما تحتاجينه',
                          child: const SizedBox.shrink(),
                        ),
                        _buildChipRow(),

                        // ════════════ SHOP BANNER ════════════
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: _buildShopBanner(),
                        ),

                        // ════════════ ARTICLES ════════════
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _HomeArticlesSection(),
                        ),

                        
                        // ════════════ LATEST NEWS ════════════
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _NewsSection(accentColor: Color(0xFFE91E63), sectionTitle: 'آخر الأخبار'),
                        ),

const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────── Top bar icon button ───────────
  Widget _topBarIconBtn({required IconData icon, required Color color, bool showDot = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.6)],
              ),
              border: Border.all(color: _pink.withOpacity(0.1), width: 0.5),
              boxShadow: [
                BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          if (showDot)
            Positioned(
              top: 9, right: 9,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _pink,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: _pink.withOpacity(0.6), blurRadius: 8)],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────── HERO ───────────
  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.fromLTRB(0, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3EE), Color(0xFFFFD2E3), Color(0xFFF8C6E0)],
        ),
        boxShadow: [
          BoxShadow(color: _pink.withOpacity(0.16), blurRadius: 40, offset: const Offset(0, 20)),
          BoxShadow(color: _pink.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          // Image side
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://images.unsplash.com/photo-1556760544-74068565f05c?w=600&q=85',
              width: 130, height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 130, height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(colors: [Color(0xFFFFD9E5), Color(0xFFFFB1CD)]),
                ),
                child: const Icon(Icons.pregnant_woman, size: 60, color: Color(0xFFB6195F)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Text side
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Eyebrow pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome, size: 11, color: Color(0xFFB6195F)),
                    const SizedBox(width: 6),
                    Text(
                      'صباح الخير${_userName.isNotEmpty ? "، $_userName" : ""}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB6195F)),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                const Text(
                  'كل يوم خطوة نحو\nحملٍ صحي وسعيد ✨',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF5A0F33), height: 1.3, letterSpacing: -0.4),
                ),
                const SizedBox(height: 6),
                Text(
                  'تذكّري أن صحتكِ النفسية لا تقل أهمية عن الجسدية.',
                  style: TextStyle(fontSize: 12, color: const Color(0xFF5A0F33).withOpacity(0.78), fontWeight: FontWeight.w500, height: 1.65),
                ),
                const SizedBox(height: 8),
                // Mini pills
                Row(children: [
                  _heroPill(_pregnancyWeek > 0
                      ? (_pregnancyWeek <= 13 ? 'الثلث الأول' : _pregnancyWeek <= 26 ? 'الثلث الثاني' : 'الثلث الثالث')
                      : 'ابدئي رحلتكِ'),
                  const SizedBox(width: 6),
                  _heroPill('مزاج هادئ'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF7A1F4F))),
    );
  }

  // ─────────── PREGNANCY TRACKER ───────────
  Widget _buildTracker() {
    final week = _pregnancyWeek;
    const total = 40;
    final pct = (week / total).clamp(0.0, 1.0);
    final remaining = total - week;

    // Fetus size data
    final fetusSizes = {
      4: '🫐 توت', 8: '🫒 زيتونة', 12: '🍋 ليمونة', 16: '🍎 تفاحة', 20: '🍌 موزة',
      24: '🌽 ذرة', 26: '🥦 قرنبيط', 28: '🍆 باذنجانة', 30: '🥥 جوز هند', 32: '🍈 شمام',
      34: '🍍 أناناس', 36: '🥬 خس', 38: '🍉 بطيخة', 40: '🎃 يقطينة',
    };
    String fetusSize = '🫘 بذرة';
    for (final entry in fetusSizes.entries) {
      if (week >= entry.key) fetusSize = entry.value;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withOpacity(0.75),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 0.5),
        boxShadow: [
          BoxShadow(color: _ink.withOpacity(0.08), blurRadius: 48, offset: const Offset(0, 24)),
          BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Row: Ring + Info
          Row(
            children: [
              // Ring progress
              SizedBox(
                width: 130, height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(130, 130),
                      painter: _TrackerRingPainter(pct),
                    ),
                    // Baby emoji center
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 3600),
                      builder: (_, v, child) {
                        final yOffset = 3 * (0.5 - (0.5 * (1 + (2 * 3.14159 * v).remainder(6.28) < 3.14159 ? (2 * 3.14159 * v).remainder(3.14159) / 3.14159 : 1 - ((2 * 3.14159 * v).remainder(3.14159) / 3.14159)))).abs();
                        return Transform.translate(
                          offset: Offset(0, -yOffset),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            center: Alignment(-0.3, -0.4),
                            colors: [Color(0xFFFFE6EF), Color(0xFFFFC0D6), Color(0xFFFF8DB7)],
                            stops: [0, 0.6, 1],
                          ),
                          boxShadow: [
                            BoxShadow(color: _pink.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Center(child: Text('👶', style: TextStyle(fontSize: 34))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              // Info text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(colors: [_pink.withOpacity(0.12), _lavender2.withOpacity(0.18)]),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: _pink,
                            boxShadow: [BoxShadow(color: _pink.withOpacity(0.6), blurRadius: 6)],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('الأسبوع $week من $total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _pink)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink, fontFamily: 'Almarai', height: 1.1),
                        children: [
                          const TextSpan(text: 'أنتِ في الأسبوع '),
                          TextSpan(text: '$week', style: const TextStyle(color: _pink)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('باقي $remaining أسبوع للقاء صغيركِ 💕', style: const TextStyle(fontSize: 12.5, color: _ink2, fontWeight: FontWeight.w500, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Metric strip
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _pink.withOpacity(0.1),
            ),
            padding: const EdgeInsets.all(1),
            child: Row(
              children: [
                _metricCell(fetusSize, 'حجم الجنين', true, false),
                _metricCell('${(week * 1.3).toStringAsFixed(0)} سم', 'الطول', false, false),
                _metricCell('${(week * 28).toStringAsFixed(0)} غ', 'الوزن', false, true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // CTA button
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PregnancyWeeksScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [Color(0xFFFF6BA3), _pink, Color(0xFFE53B7E)]),
                boxShadow: [
                  BoxShadow(color: _pink.withOpacity(0.22), blurRadius: 28, offset: const Offset(0, 12)),
                  BoxShadow(color: _pink.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('استكشفي تطوّر هذا الأسبوع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCell(String value, String label, bool isFirst, bool isLast) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.horizontal(
            right: isFirst ? const Radius.circular(14) : Radius.zero,
            left: isLast ? const Radius.circular(14) : Radius.zero,
          ),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _ink), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10.5, color: _ink3, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─────────── SECTION HEADER ───────────
  Widget _buildSection({required String eyebrow, required String title, required Widget child, VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _pink50, borderRadius: BorderRadius.circular(8)),
                    child: Text(eyebrow, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _pink, letterSpacing: 0.3)),
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.3)),
                ]),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('عرض الكل', style: TextStyle(color: _pink, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_back_ios, color: _pink, size: 10),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ─────────── QUICK ACCESS GRID ───────────
  Widget _buildQuickGrid() {
    final cards = [
      _QAData(Icons.pregnant_woman, 'متابعة الحمل', 'الأسبوع $_pregnancyWeek', '✓ محدّث اليوم',
        [const Color(0xFFFF6BA3), _pink], () => widget.onCardTap?.call(2)),
      _QAData(Icons.water_drop, 'متابعة الدورة', 'آخر دورة قبل 28 يوم', 'إعدادي ملفّكِ',
        [_lavender2, const Color(0xFF9B6FE1)], () => widget.onCardTap?.call(1)),
      _QAData(Icons.monitor_weight, 'تتبّع الوزن', '68.4 كغ', '+ 2.1 كغ هذا الشهر',
        [_teal, _tealDeep], () => Navigator.push(context, MaterialPageRoute(builder: (_) => WeightTrackerScreen()))),
      _QAData(Icons.timer, 'العدّ التنازلي', '${(40 - _pregnancyWeek) * 7} يوم للولادة', '',
        [_peach, const Color(0xFFFF8852)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => DueDateCountdownScreen()))),
    ];

    return Column(
      children: [
        Row(children: [
          Expanded(child: _buildQACard(cards[0])),
          const SizedBox(width: 10),
          Expanded(child: _buildQACard(cards[1])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _buildQACard(cards[2])),
          const SizedBox(width: 10),
          Expanded(child: _buildQACard(cards[3])),
        ]),
      ],
    );
  }

  Widget _buildQACard(_QAData d) {
    return GestureDetector(
      onTap: d.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 108),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.9), width: 0.5),
          boxShadow: [
            BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: d.gradColors),
              ),
              child: Icon(d.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(d.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 2),
            Text(d.subtitle, style: const TextStyle(fontSize: 11.5, color: _ink3, fontWeight: FontWeight.w500)),
            if (d.meta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(d.meta, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _tealDeep)),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────── AI ASSISTANT CARD ───────────
  Widget _buildAICard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIChatPage())),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A2238), Color(0xFF2D2851), Color(0xFF3E2A56)],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF2D2851).withOpacity(0.32), blurRadius: 38, offset: const Offset(0, 18)),
            BoxShadow(color: const Color(0xFF2D2851).withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // AI Orb
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.06),
              duration: const Duration(milliseconds: 3000),
              builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.5),
                    colors: [Colors.white, Color(0xFFC6F5EE), _teal, _tealDeep],
                    stops: [0, 0.25, 0.6, 1],
                  ),
                  boxShadow: [
                    BoxShadow(color: _teal.withOpacity(0.15), spreadRadius: 6),
                    BoxShadow(color: _teal.withOpacity(0.45), blurRadius: 24),
                  ],
                ),
                child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 28)),
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('مساعدة ذكية', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF4DDFCB))),
                  ),
                  const SizedBox(height: 6),
                  const Text('اسألي مساعد نبضة الذكي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text('إجابات فورية مخصّصة لأسبوع حملكِ ✨', style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.72), height: 1.5)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.5),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('ابدئي محادثة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────── DAILY TIPS ROW ───────────
  Widget _buildTipsRow() {
    final tips = [
      _TipData('💧', 'اشربي 8 أكواب ماء يوميًا', 'لتحسين الدورة الدموية', [_sky, const Color(0xFFB8DCFF)], 0.5, '4 / 8'),
      _TipData('🚶‍♀️', 'امشي 30 دقيقة يوميًا', 'مشي خفيف بعد العشاء', [_teal50, const Color(0xFFB8EBE3)], 0.7, '21 د'),
      _TipData('🌙', 'احصلي على نوم كافٍ', 'النوم على الجانب الأيسر', [_lavender, const Color(0xFFD4BFEA)], 0.88, '7 س 30 د'),
      _TipData('🥗', 'وجبة غنية بالحديد', 'سبانخ • عدس • كبد', [_peach50, const Color(0xFFFFD9C2)], 0.33, '1 / 3'),
    ];

    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final t = tips[i];
          return Container(
            width: 220,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 0.5),
              boxShadow: [
                BoxShadow(color: _ink.withOpacity(0.06), blurRadius: 28, offset: const Offset(0, 12)),
                BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(colors: t.bgColors),
                  ),
                  child: Center(child: Text(t.emoji, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(height: 10),
                Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _ink, height: 1.4), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(t.subtitle, style: const TextStyle(fontSize: 12, color: _ink3, fontWeight: FontWeight.w500, height: 1.5), maxLines: 1),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(999)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: t.progress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(colors: [_teal, _tealDeep]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(t.count, style: const TextStyle(fontSize: 11, color: _ink2, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────── EXPLORE GRID ───────────
  Widget _buildExploreGrid() {
    final items = [
      _QAData(Icons.restaurant_menu, 'التغذية', 'وصفات للثلث الثاني', '',
        [_teal, _tealDeep], () => Navigator.push(context, MaterialPageRoute(builder: (_) => NutritionScreen()))),
      _QAData(Icons.favorite, 'التمارين', 'يوغا • مشي • كيغل', '',
        [const Color(0xFFFF6BA3), const Color(0xFFE53B7E)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExercisesScreen()))),
      _QAData(Icons.calendar_month, 'تقويم الحمل', '40 أسبوع كاملاً', '',
        [_lavender2, const Color(0xFF9B6FE1)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => PregnancyCalendarScreen()))),
      _QAData(Icons.card_travel, 'حقيبة الولادة', '12 من 24 مكتمل', '',
        [_peach, const Color(0xFFFF8852)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => HospitalBagScreen()))),
      _QAData(Icons.auto_stories, 'يوميات الحمل', 'آخر مذكّرة قبل يومين', '',
        [_teal, _tealDeep], () => Navigator.push(context, MaterialPageRoute(builder: (_) => PregnancyJournalScreen()))),
      _QAData(Icons.emoji_events, 'الإنجازات', '7 شارات', '',
        [_gold, _goldDeep], () => Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsScreen()))),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2) ...[
          Row(children: [
            Expanded(child: _buildQACard(items[i])),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < items.length ? _buildQACard(items[i + 1]) : const SizedBox()),
          ]),
          if (i + 2 < items.length) const SizedBox(height: 10),
        ],
      ],
    );
  }

  // ─────────── CHIP ROW ───────────
  Widget _buildChipRow() {
    final chips = [
      _ChipData('🤖', 'المساعد الذكي', _lavender, () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIChatPage()))),
      _ChipData('👶', 'رعاية الطفل', const Color(0xFFFFD9E5), () => widget.onCardTap?.call(3)),
      _ChipData('👥', 'مجتمع الأمهات', _sky, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityScreen()))),
      _ChipData('💚', 'العادات الصحية', _teal50, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HealthTrackersScreen()))),
      _ChipData('📖', 'مراحل الحمل', _peach50, () => Navigator.push(context, MaterialPageRoute(builder: (_) => PregnancyWeeksScreen()))),
      _ChipData('🍼', 'أسماء المواليد', const Color(0xFFFFF8E0), () => Navigator.push(context, MaterialPageRoute(builder: (_) => BabyNamesScreen()))),
      _ChipData('↗️', 'شاركي تقدّمكِ', const Color(0xFFFFD9E5), () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShareProgressScreen()))),
      _ChipData('📏', 'حجم الجنين', _lavender, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FetusSizeScreen()))),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = chips[i];
          return GestureDetector(
            onTap: c.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line, width: 0.5),
                boxShadow: [
                  BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
                  BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(color: c.bgColor, borderRadius: BorderRadius.circular(9)),
                    child: Center(child: Text(c.emoji, style: const TextStyle(fontSize: 14))),
                  ),
                  const SizedBox(width: 8),
                  Text(c.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _ink)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────── SHOP BANNER ───────────
  Widget _buildShopBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_lavender2, _pink],
        ),
        boxShadow: [
          BoxShadow(color: _lavender2.withOpacity(0.4), blurRadius: 36, offset: const Offset(0, 18)),
          BoxShadow(color: _pink.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('عرض الأسبوع', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                ),
                const SizedBox(height: 10),
                const Text('خصومات على منتجات\nالأم والطفل', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3, letterSpacing: -0.4)),
                const SizedBox(height: 6),
                Text('تشكيلة مختارة بعناية • شحن مجاني', style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.92), height: 1.5)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => widget.onCardTap?.call(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [BoxShadow(color: const Color(0xFF783050).withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('تسوّقي الآن', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _pink)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_back_ios, color: _pink, size: 12),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Products stack
          SizedBox(
            width: 100, height: 130,
            child: Stack(
              children: [
                Positioned(
                  top: 0, right: 20,
                  child: _shopImg('https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=300&q=80', 70, -8),
                ),
                Positioned(
                  bottom: 0, left: 0,
                  child: _shopImg('https://images.unsplash.com/photo-1515488825947-c69b40e07b9b?w=300&q=80', 62, 6),
                ),
                Positioned(
                  top: 20, left: 0,
                  child: _shopImg('https://images.unsplash.com/photo-1607000975327-deea3f6f04dd?w=300&q=80', 54, -3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopImg(String url, double size, double rotation) {
    return Transform.rotate(
      angle: rotation * 3.14159 / 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size, height: size,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.shopping_bag, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Data classes for HomePage ──
class _QAData {
  final IconData icon;
  final String title, subtitle, meta;
  final List<Color> gradColors;
  final VoidCallback? onTap;
  _QAData(this.icon, this.title, this.subtitle, this.meta, this.gradColors, this.onTap);
}

class _TipData {
  final String emoji, title, subtitle, count;
  final List<Color> bgColors;
  final double progress;
  _TipData(this.emoji, this.title, this.subtitle, this.bgColors, this.progress, this.count);
}

class _ChipData {
  final String emoji, label;
  final Color bgColor;
  final VoidCallback? onTap;
  _ChipData(this.emoji, this.label, this.bgColor, this.onTap);
}

// ── Tracker Ring Painter ──
class _TrackerRingPainter extends CustomPainter {
  final double progress;
  _TrackerRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 9.0;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFFF4F93).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6BA3), Color(0xFFFF4F93), Color(0xFFC7A8EB)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      2 * 3.14159 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TrackerRingPainter old) => old.progress != progress;
}

// ==================== CYCLE PAGE (Claude Design Premium) ====================
class CyclePage extends StatefulWidget {
  @override
  State<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends State<CyclePage> {
  static const _pink = Color(0xFFFF4F93);
  static const _pinkHot = Color(0xFFE53B7E);
  static const _pink50 = Color(0xFFFFF1F6);
  static const _lavender2 = Color(0xFFC7A8EB);
  static const _teal = Color(0xFF15B8A6);
  static const _tealDeep = Color(0xFF0F8B8D);
  static const _teal50 = Color(0xFFE7F7F5);
  static const _cream = Color(0xFFFFF8FA);
  static const _peach = Color(0xFFFFB38A);
  static const _ink = Color(0xFF1B1320);
  static const _ink2 = Color(0xFF4A3F4F);
  static const _ink3 = Color(0xFF8E8295);
  static const _line = Color(0xFFF0E6EE);

  String mood = '';
  Set<String> symptoms = {};

  @override
  void initState() {
    super.initState();
    _loadTodayLog();
  }

  Future<void> _loadTodayLog() async {
    try {
      var doc = await DB.cycleLogs.doc(DB.dateKey()).get();
      if (doc.exists) {
        var d = doc.data() as Map<String, dynamic>;
        setState(() {
          mood = d['mood'] ?? '';
          symptoms = Set<String>.from(d['symptoms'] ?? []);
        });
      }
    } catch (_) {}
  }

  Future<void> _saveTodayLog() async {
    await DB.cycleLogs.doc(DB.dateKey()).set({
      'date': DB.dateKey(),
      'mood': mood,
      'symptoms': symptoms.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('\u062A\u0645 \u062D\u0641\u0638 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u064A\u0648\u0645 \u2713'), backgroundColor: _teal));
  }

  Future<void> _startPeriod() async {
    await DB.userDoc.set({'lastPeriodStart': Timestamp.now()}, SetOptions(merge: true));
    await DB.cycleLogs.doc(DB.dateKey()).set({
      'date': DB.dateKey(), 'isPeriod': true, 'mood': mood,
      'symptoms': symptoms.toList(), 'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('\u062A\u0645 \u062A\u0633\u062C\u064A\u0644 \u0628\u062F\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629'), backgroundColor: _pink));
  }

  Future<void> _endPeriod() async {
    await DB.cycleLogs.doc(DB.dateKey()).set({
      'date': DB.dateKey(), 'isPeriod': false, 'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('\u062A\u0645 \u062A\u0633\u062C\u064A\u0644 \u0646\u0647\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629'), backgroundColor: Colors.grey.shade600));
  }

  String _phaseName(int day, int len) {
    if (day <= 5) return '\u0645\u0631\u062D\u0644\u0629 \u0627\u0644\u062D\u064A\u0636';
    if (day <= (len * 0.46).round()) return '\u0627\u0644\u0645\u0631\u062D\u0644\u0629 \u0627\u0644\u062C\u0631\u064A\u0628\u064A\u0629';
    if (day <= (len * 0.57).round()) return '\u0645\u0631\u062D\u0644\u0629 \u0627\u0644\u062A\u0628\u0648\u064A\u0636';
    return '\u0627\u0644\u0645\u0631\u062D\u0644\u0629 \u0627\u0644\u0623\u0635\u0641\u0631\u064A\u0629';
  }

  Color _phaseColor(int day, int len) {
    if (day <= 5) return _pink;
    if (day <= (len * 0.46).round()) return _lavender2;
    if (day <= (len * 0.57).round()) return _teal;
    return _peach;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: _cream,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_cream, Colors.white, _cream],
            ),
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: DB.userDoc.snapshots(),
            builder: (context, snapshot) {
              int cycleLength = 28, cycleDay = 1;
              if (snapshot.hasData && snapshot.data!.exists) {
                var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                cycleLength = (data['cycleLength'] as int?) ?? 28;
                if (data['lastPeriodStart'] != null) {
                  try {
                    Timestamp ts = data['lastPeriodStart'];
                    int diff = DateTime.now().difference(ts.toDate()).inDays + 1;
                    cycleDay = ((diff - 1) % cycleLength) + 1;
                  } catch (_) {}
                }
              }

              final phase = _phaseName(cycleDay, cycleLength);
              final phaseClr = _phaseColor(cycleDay, cycleLength);
              final ovDay = (cycleLength * 0.5).round();
              final fertileStart = (cycleLength * 0.36).round();
              final fertileEnd = (cycleLength * 0.57).round();
              final nextPeriod = cycleLength - cycleDay;

              return CustomScrollView(
                slivers: [
                  // \u2500\u2500 Top Bar \u2500\u2500
                  SliverAppBar(
                    floating: true, snap: true,
                    backgroundColor: Colors.transparent, elevation: 0,
                    toolbarHeight: 68,
                    flexibleSpace: Container(
                      margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withOpacity(0.85), width: 0.5),
                        boxShadow: [
                          BoxShadow(color: _ink.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () => Navigator.maybePop(context),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withOpacity(0.8),
                              ),
                              child: const Icon(Icons.arrow_forward_ios, size: 18, color: _ink),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062F\u0648\u0631\u0629', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: _pink, boxShadow: [BoxShadow(color: _pink.withOpacity(0.6), blurRadius: 6)])),
                                  const SizedBox(width: 5),
                                  Text('\u0627\u0644\u064A\u0648\u0645 \u2022 ${_arabicDate()}', style: const TextStyle(fontSize: 10.5, color: _ink3, fontWeight: FontWeight.w600)),
                                ]),
                              ],
                            ),
                          ),
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withOpacity(0.8),
                            ),
                            child: const Icon(Icons.calendar_month, size: 18, color: _pink),
                          ),
                          const SizedBox(width: 14),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 HERO CYCLE CARD \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            color: Colors.white.withOpacity(0.75),
                            border: Border.all(color: Colors.white.withOpacity(0.9), width: 0.5),
                            boxShadow: [
                              BoxShadow(color: _ink.withOpacity(0.08), blurRadius: 48, offset: const Offset(0, 24)),
                              BoxShadow(color: _pink.withOpacity(0.1), blurRadius: 60, offset: const Offset(0, 30)),
                            ],
                          ),
                          child: Column(children: [
                            // Eyebrow + title
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: LinearGradient(colors: [_pink.withOpacity(0.12), _lavender2.withOpacity(0.18)]),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.auto_awesome, size: 11, color: _pinkHot),
                                const SizedBox(width: 6),
                                Text(cycleDay >= fertileStart && cycleDay <= fertileEnd ? '\u0630\u0631\u0648\u0629 \u0627\u0644\u062E\u0635\u0648\u0628\u0629 \u0627\u0644\u064A\u0648\u0645' : phase,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _pinkHot)),
                              ]),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              cycleDay >= fertileStart && cycleDay <= fertileEnd
                                ? '\u0623\u0639\u0644\u0649 \u0627\u062D\u062A\u0645\u0627\u0644\u064A\u0629 \u0644\u0644\u062D\u0645\u0644 \u2728'
                                : cycleDay <= 5 ? '\u0627\u0639\u062A\u0646\u064A \u0628\u0646\u0641\u0633\u0643\u0650 \u0641\u064A \u0647\u0630\u0647 \u0627\u0644\u0623\u064A\u0627\u0645 \uD83D\uDC95' : '\u062F\u0648\u0631\u062A\u0643\u0650 \u062A\u0633\u064A\u0631 \u0628\u0634\u0643\u0644 \u0637\u0628\u064A\u0639\u064A \u2728',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink),
                            ),
                            const SizedBox(height: 4),
                            Text('\u062C\u0633\u0645\u0643\u0650 \u0641\u064A $phase \u2014 ${nextPeriod > 0 ? "\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0642\u0627\u062F\u0645\u0629 \u0628\u0639\u062F $nextPeriod \u064A\u0648\u0645" : "\u0628\u062F\u0627\u064A\u0629 \u062F\u0648\u0631\u0629 \u062C\u062F\u064A\u062F\u0629"}',
                              style: const TextStyle(fontSize: 12.5, color: _ink2, fontWeight: FontWeight.w500), textAlign: TextAlign.center),

                            const SizedBox(height: 18),

                            // \u2500\u2500 Cycle Ring \u2500\u2500
                            SizedBox(
                              width: 240, height: 240,
                              child: Stack(alignment: Alignment.center, children: [
                                CustomPaint(
                                  size: const Size(240, 240),
                                  painter: _CycleRingPainter(cycleDay, cycleLength),
                                ),
                                Column(mainAxisSize: MainAxisSize.min, children: [
                                  const Text('\u064A\u0648\u0645', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ink3)),
                                  ShaderMask(
                                    shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFFF6BA3), _pink, _lavender2]).createShader(b),
                                    child: Text('$cycleDay', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                                  ),
                                  Text('\u0645\u0646 $cycleLength', style: const TextStyle(fontSize: 12.5, color: _ink2, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      gradient: LinearGradient(colors: [phaseClr.withOpacity(0.16), _lavender2.withOpacity(0.18)]),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: phaseClr, boxShadow: [BoxShadow(color: phaseClr.withOpacity(0.6), blurRadius: 8)])),
                                      const SizedBox(width: 6),
                                      Text(phase, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: phaseClr)),
                                    ]),
                                  ),
                                ]),
                              ]),
                            ),

                            const SizedBox(height: 10),

                            // \u2500\u2500 Phase Legend \u2500\u2500
                            Row(children: [
                              _legendItem('\u0627\u0644\u062D\u064A\u0636', '1\u20135', _pink, cycleDay <= 5),
                              const SizedBox(width: 8),
                              _legendItem('\u0627\u0644\u062C\u0631\u064A\u0628\u064A\u0629', '6\u2013${(cycleLength * 0.46).round()}', _lavender2, cycleDay > 5 && cycleDay <= (cycleLength * 0.46).round()),
                              const SizedBox(width: 8),
                              _legendItem('\u0627\u0644\u062A\u0628\u0648\u064A\u0636', '${fertileStart}\u2013${fertileEnd}', _teal, cycleDay >= fertileStart && cycleDay <= fertileEnd),
                              const SizedBox(width: 8),
                              _legendItem('\u0627\u0644\u0623\u0635\u0641\u0631\u064A\u0629', '${fertileEnd + 1}\u2013$cycleLength', _peach, cycleDay > fertileEnd),
                            ]),

                            const SizedBox(height: 18),

                            // \u2500\u2500 Quick Stats \u2500\u2500
                            Row(children: [
                              _quickStat('$cycleLength', '\u0637\u0648\u0644 \u0627\u0644\u062F\u0648\u0631\u0629'),
                              const SizedBox(width: 12),
                              _quickStat('5 \u0623\u064A\u0627\u0645', '\u0645\u062F\u0629 \u0627\u0644\u062D\u064A\u0636'),
                              const SizedBox(width: 12),
                              _quickStat('\u0628\u0639\u062F $nextPeriod \u064A\u0648\u0645', '\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u062A\u0627\u0644\u064A\u0629'),
                            ]),

                            const SizedBox(height: 18),

                            // \u2500\u2500 Action Buttons \u2500\u2500
                            Row(children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _startPeriod,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(colors: [Color(0xFFFF6BA3), _pink, _pinkHot]),
                                      boxShadow: [BoxShadow(color: _pink.withOpacity(0.22), blurRadius: 28, offset: const Offset(0, 12))],
                                    ),
                                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                      SizedBox(width: 6),
                                      Text('\u0628\u062F\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                    ]),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _endPeriod,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: Colors.white,
                                      border: Border.all(color: _line),
                                      boxShadow: [BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                    ),
                                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(Icons.stop_rounded, color: _ink3, size: 18),
                                      SizedBox(width: 6),
                                      Text('\u0646\u0647\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629', style: TextStyle(color: _ink2, fontWeight: FontWeight.w700, fontSize: 13)),
                                    ]),
                                  ),
                                ),
                              ),
                            ]),
                          ]),
                        ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 MOOD SECTION \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        _sectionHeader('\u0645\u0632\u0627\u062C\u064A \u0627\u0644\u064A\u0648\u0645', '\u0643\u064A\u0641 \u062A\u0634\u0639\u0631\u064A\u0646\u061F'),
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _moodChip('\uD83D\uDE0A', '\u0633\u0639\u064A\u062F\u0629'), _moodChip('\uD83D\uDE0C', '\u0647\u0627\u062F\u0626\u0629'), _moodChip('\u2728', '\u0645\u0646\u062A\u0639\u0634\u0629'),
                              _moodChip('\uD83D\uDE34', '\u0645\u062A\u0639\u0628\u0629'), _moodChip('\uD83E\uDD7A', '\u062D\u0633\u0651\u0627\u0633\u0629'), _moodChip('\uD83D\uDE23', '\u0645\u062A\u0648\u062A\u0631\u0629'),
                              _moodChip('\uD83D\uDE14', '\u062D\u0632\u064A\u0646\u0629'), _moodChip('\uD83D\uDE24', '\u063A\u0627\u0636\u0628\u0629'),
                            ],
                          ),
                        ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 SYMPTOMS SECTION \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        _sectionHeader('\u0633\u062C\u0651\u0644\u064A \u0623\u0639\u0631\u0627\u0636\u0643\u0650', '\u0623\u0639\u0631\u0627\u0636 \u0627\u0644\u064A\u0648\u0645'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(spacing: 8, runSpacing: 8, children: [
                            _symptomPill('\uD83C\uDF38', '\u062A\u0642\u0644\u0635\u0627\u062A', 'cramps', null),
                            _symptomPill('\uD83E\uDD15', '\u0635\u062F\u0627\u0639', 'head', 'lav'),
                            _symptomPill('\uD83D\uDCA8', '\u0627\u0646\u062A\u0641\u0627\u062E', 'bloat', 'peach'),
                            _symptomPill('\uD83D\uDE34', '\u062A\u0639\u0628', 'fatigue', 'lav'),
                            _symptomPill('\uD83D\uDC97', '\u0623\u0644\u0645 \u0641\u064A \u0627\u0644\u0635\u062F\u0631', 'breast', null),
                            _symptomPill('\u2728', '\u062D\u0628\u0651 \u0634\u0628\u0627\u0628', 'acne', 'peach'),
                            _symptomPill('\uD83C\uDF6B', '\u0634\u0647\u064A\u0651\u0629 \u0639\u0627\u0644\u064A\u0629', 'craving', 'teal'),
                            _symptomPill('\uD83E\uDD22', '\u063A\u062B\u064A\u0627\u0646', 'nausea', 'teal'),
                            _symptomPill('\uD83C\uDF00', '\u0622\u0644\u0627\u0645 \u0638\u0647\u0631', 'back', null),
                            _symptomPill('\uD83C\uDFAD', '\u062A\u0642\u0644\u0651\u0628\u0627\u062A \u0645\u0632\u0627\u062C', 'mood_s', 'lav'),
                            _symptomPill('\uD83D\uDCA7', '\u062A\u062F\u0641\u0651\u0642 \u062E\u0641\u064A\u0641', 'flow', 'peach'),
                            _symptomPill('\uD83C\uDF19', '\u0646\u0648\u0645 \u0645\u062A\u0642\u0637\u0651\u0639', 'sleep', 'teal'),
                          ]),
                        ),

                        // \u2500\u2500 Save Button \u2500\u2500
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                          child: GestureDetector(
                            onTap: _saveTodayLog,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(colors: [_teal, _tealDeep]),
                                boxShadow: [BoxShadow(color: _teal.withOpacity(0.22), blurRadius: 28, offset: const Offset(0, 12))],
                              ),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.save_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('\u062D\u0641\u0638 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u064A\u0648\u0645', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                              ]),
                            ),
                          ),
                        ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 AI INSIGHTS \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        _sectionHeader('\u0631\u0624\u0649 \u0646\u0628\u0636\u0629 \u0627\u0644\u0630\u0643\u064A\u0629', '\u062A\u062D\u0644\u064A\u0644 \u062F\u0648\u0631\u062A\u0643\u0650'),
                        SizedBox(
                          height: 200,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _insightCard('\u0630\u0631\u0648\u0629 \u0627\u0644\u062E\u0635\u0648\u0628\u0629', '\u0628\u0646\u0627\u0621\u064B \u0639\u0644\u0649 \u062F\u0648\u0631\u062A\u0643\u0650\u060C \u0627\u0644\u064A\u0648\u0645 $ovDay \u0647\u0648 \u0630\u0631\u0648\u0629 \u0627\u062D\u062A\u0645\u0627\u0644 \u0627\u0644\u0625\u062E\u0635\u0627\u0628.',
                                '86\u066A \u0627\u062D\u062A\u0645\u0627\u0644', [_teal, _tealDeep, const Color(0xFF0A5F60)]),
                              const SizedBox(width: 12),
                              _insightCard('\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0642\u0627\u062F\u0645\u0629', '\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0642\u0627\u062F\u0645\u0629 \u0628\u0639\u062F $nextPeriod \u064A\u0648\u0645 \u0628\u0646\u0627\u0621\u064B \u0639\u0644\u0649 \u0622\u062E\u0631 3 \u0623\u0634\u0647\u0631.',
                                '$nextPeriod \u064A\u0648\u0645 \u0645\u062A\u0628\u0642\u064A\u0629', [const Color(0xFFFF6BA3), _pink, _lavender2]),
                              const SizedBox(width: 12),
                              _insightCard('\u062F\u0648\u0631\u062A\u0643\u0650 \u0645\u0646\u062A\u0638\u0645\u0629 \uD83D\uDC9A', '\u0637\u0648\u0644 \u062F\u0648\u0631\u062A\u0643\u0650 \u062B\u0627\u0628\u062A \u0636\u0645\u0646 ${cycleLength - 1}\u2013${cycleLength + 1} \u064A\u0648\u0645.',
                                '\u0627\u0646\u062A\u0638\u0627\u0645 \u0645\u0645\u062A\u0627\u0632', [const Color(0xFF1A2238), const Color(0xFF2D2851), const Color(0xFF3E2A56)]),
                            ],
                          ),
                        ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 CYCLE LENGTH SETTING \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withOpacity(0.9), width: 0.5),
                              boxShadow: [BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(colors: [_pink.withOpacity(0.12), _lavender2.withOpacity(0.18)]),
                                ),
                                child: const Icon(Icons.settings, size: 20, color: _pink),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(child: Text('\u0637\u0648\u0644 \u0627\u0644\u062F\u0648\u0631\u0629', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink))),
                              IconButton(icon: const Icon(Icons.remove_circle_outline, color: _pink), onPressed: () async {
                                if (cycleLength > 20) await DB.userDoc.set({'cycleLength': cycleLength - 1}, SetOptions(merge: true));
                              }),
                              Text('$cycleLength \u064A\u0648\u0645', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                              IconButton(icon: const Icon(Icons.add_circle_outline, color: _pink), onPressed: () async {
                                if (cycleLength < 45) await DB.userDoc.set({'cycleLength': cycleLength + 1}, SetOptions(merge: true));
                              }),
                            ]),
                          ),
                        ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 ARTICLES \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _CycleArticlesSection(),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _arabicDate() {
    final now = DateTime.now();
    final days = ['\u0627\u0644\u0623\u062D\u062F', '\u0627\u0644\u0625\u062B\u0646\u064A\u0646', '\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621', '\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621', '\u0627\u0644\u062E\u0645\u064A\u0633', '\u0627\u0644\u062C\u0645\u0639\u0629', '\u0627\u0644\u0633\u0628\u062A'];
    final months = ['\u064A\u0646\u0627\u064A\u0631', '\u0641\u0628\u0631\u0627\u064A\u0631', '\u0645\u0627\u0631\u0633', '\u0623\u0628\u0631\u064A\u0644', '\u0645\u0627\u064A\u0648', '\u064A\u0648\u0646\u064A\u0648', '\u064A\u0648\u0644\u064A\u0648', '\u0623\u063A\u0633\u0637\u0633', '\u0633\u0628\u062A\u0645\u0628\u0631', '\u0623\u0643\u062A\u0648\u0628\u0631', '\u0646\u0648\u0641\u0645\u0628\u0631', '\u062F\u064A\u0633\u0645\u0628\u0631'];
    return '${days[now.weekday % 7]} ${now.day} ${months[now.month - 1]}';
  }

  Widget _legendItem(String label, String days, Color clr, bool active) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active ? Colors.white : Colors.white.withOpacity(0.55),
          border: Border.all(color: active ? clr.withOpacity(0.3) : Colors.white.withOpacity(0.9), width: 0.5),
          boxShadow: active ? [BoxShadow(color: clr.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Column(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: clr)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _ink2)),
          Text(days, style: const TextStyle(fontSize: 10, color: _ink3, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _quickStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.85), width: 0.5),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _ink), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: _ink3, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String eyebrow, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _pink50, borderRadius: BorderRadius.circular(8)),
          child: Text(eyebrow, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _pink)),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
      ]),
    );
  }

  Widget _moodChip(String emoji, String label) {
    final sel = mood == label;
    return GestureDetector(
      onTap: () => setState(() => mood = label),
      child: Container(
        width: 78, margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: sel ? null : Colors.white,
          gradient: sel ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_pink50, Color(0xFFFFD6E7)]) : null,
          border: Border.all(color: sel ? _pink : _line, width: sel ? 1.5 : 0.5),
          boxShadow: sel ? [BoxShadow(color: _pink.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10))] : [BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 4)],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: sel ? Colors.white : _cream),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _ink)),
        ]),
      ),
    );
  }

  Widget _symptomPill(String emoji, String label, String id, String? variant) {
    final isOn = symptoms.contains(id);
    List<Color> gradColors;
    if (!isOn) {
      gradColors = [];
    } else if (variant == 'teal') {
      gradColors = [const Color(0xFF36D2C0), _teal, _tealDeep];
    } else if (variant == 'lav') {
      gradColors = [_lavender2, const Color(0xFF9B6FE1), const Color(0xFF7A4FC9)];
    } else if (variant == 'peach') {
      gradColors = [const Color(0xFFFFCEB2), _peach, const Color(0xFFFF8852)];
    } else {
      gradColors = [const Color(0xFFFF6BA3), _pink, _pinkHot];
    }

    return GestureDetector(
      onTap: () => setState(() {
        symptoms.contains(id) ? symptoms.remove(id) : symptoms.add(id);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: isOn ? null : Colors.white,
          gradient: isOn ? LinearGradient(colors: gradColors) : null,
          border: Border.all(color: isOn ? Colors.transparent : _line),
          boxShadow: isOn
            ? [BoxShadow(color: gradColors.first.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 10))]
            : [BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 4)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: isOn ? Colors.white.withOpacity(0.22) : const Color(0xFFFBF1ED)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 13))),
          ),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: isOn ? FontWeight.w700 : FontWeight.w600, color: isOn ? Colors.white : _ink2)),
        ]),
      ),
    );
  }

  Widget _insightCard(String title, String desc, String prob, List<Color> colors) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            ),
            padding: const EdgeInsets.all(24),
            child: Directionality(textDirection: TextDirection.rtl, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 12),
              Text(desc, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.8)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text(prob, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
              const SizedBox(height: 16),
              Center(child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              )),
            ])),
          ),
        );
      },
      child: Container(
      width: 270, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [const BoxShadow(color: Colors.white, blurRadius: 6)])),
            const SizedBox(width: 6),
            const Text('\u062A\u0648\u0642\u0651\u0639 \u0630\u0643\u064A', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(desc, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.82), height: 1.55)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.18), width: 0.5))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(prob, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('\u0627\u0644\u0645\u0632\u064A\u062F', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(width: 4),
                Icon(Icons.arrow_back_ios, size: 10, color: Colors.white),
              ]),
            ),
          ]),
        ),
      ]),
    ));
  }
}

// \u2500\u2500 Cycle Ring Painter \u2500\u2500
class _CycleRingPainter extends CustomPainter {
  final int day, total;
  _CycleRingPainter(this.day, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final R = size.width / 2 - 14;
    const pi = 3.14159265;

    // Phase arcs
    final phases = [
      [1, 5, const Color(0xFFFF4F93)],
      [6, (total * 0.46).round(), const Color(0xFFC7A8EB)],
      [(total * 0.36).round(), (total * 0.57).round(), const Color(0xFF15B8A6)],
      [(total * 0.57).round() + 1, total, const Color(0xFFFFB38A)],
    ];

    // Outer faint track
    canvas.drawCircle(Offset(cx, cy), R, Paint()..color = const Color(0x0F1B1320)..style = PaintingStyle.stroke..strokeWidth = 2);

    for (final p in phases) {
      final from = (p[0] as int), to = (p[1] as int);
      final color = p[2] as Color;
      final startAngle = ((from - 1) / total) * 2 * pi - pi / 2;
      final sweepAngle = ((to - from + 1) / total) * 2 * pi;
      final inPhase = day >= from && day <= to;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: R),
        startAngle + 0.02, sweepAngle - 0.04, false,
        Paint()..color = color.withOpacity(inPhase ? 1 : 0.35)..style = PaintingStyle.stroke..strokeWidth = 9..strokeCap = StrokeCap.round,
      );
    }

    // Day dots
    for (int d = 1; d <= total; d++) {
      final angle = ((d - 0.5) / total) * 2 * pi - pi / 2;
      final x = cx + R * cos(angle), y = cy + R * sin(angle);
      if (d == day) {
        canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(x, y), 6, Paint()..color = const Color(0xFFFF4F93)..style = PaintingStyle.stroke..strokeWidth = 2.5);
        // Indicator line
        final xo = cx + (R + 14) * cos(angle), yo = cy + (R + 14) * sin(angle);
        final xi = cx + (R + 4) * cos(angle), yi = cy + (R + 4) * sin(angle);
        canvas.drawLine(Offset(xi, yi), Offset(xo, yo), Paint()..color = const Color(0xFFFF4F93)..strokeWidth = 2.5..strokeCap = StrokeCap.round);
      } else {
        canvas.drawCircle(Offset(x, y), 2.4, Paint()..color = const Color(0x2E1B1320));
      }
    }
  }

  @override
  bool shouldRepaint(_CycleRingPainter old) => old.day != day || old.total != total;
}

// ==================== PREGNANCY PAGE (FIRESTORE) ====================
class PregnancyPage extends StatefulWidget {
  @override
  State<PregnancyPage> createState() => _PregnancyPageState();
}

class _PregnancyPageState extends State<PregnancyPage> {
  int kickCount = 0;
  bool counting = false;
  Map<String, bool> checklist = {};

  Future<void> _setPregnancyStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 7 * 20)),
      firstDate: DateTime.now().subtract(Duration(days: 280)),
      lastDate: DateTime.now(),
      helpText: '\u0627\u062E\u062A\u0627\u0631\u064A \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629',
      builder: (context, child) => Localizations.override(context: context, locale: const Locale('en'), child: child!),
    );
    if (date != null) {
      await DB.userDoc.set({'pregnancyStartDate': Timestamp.fromDate(date)}, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: DB.userDoc.snapshots(),
      builder: (context, snapshot) {
        // Show loading indicator while waiting for Firestore data
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Container(
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50, height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00897B)),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('\u062C\u0627\u0631\u064A \u062A\u062D\u0645\u064A\u0644 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u062D\u0645\u0644...',
                    style: TextStyle(fontSize: 16, color: Color(0xFF4A3F4F))),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Column(children: [
            Container(
              color: Color(0xFF00897B),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(child: Center(child: Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062D\u0645\u0644', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
                IconButton(icon: Icon(Icons.date_range, color: Colors.white), onPressed: _setPregnancyStart, tooltip: '\u062A\u062D\u062F\u064A\u062F \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629'),
              ]),
            ),
            Expanded(child: _noPregnancy()),
          ]);
        }
        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        if (data['pregnancyStartDate'] == null) {
          return Column(children: [
            Container(
              color: Color(0xFF00897B),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(child: Center(child: Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062D\u0645\u0644', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)))),
                IconButton(icon: Icon(Icons.date_range, color: Colors.white), onPressed: _setPregnancyStart, tooltip: '\u062A\u062D\u062F\u064A\u062F \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629'),
              ]),
            ),
            Expanded(child: _noPregnancy()),
          ]);
        }

        Timestamp ts = data['pregnancyStartDate'];
        int daysSinceLastPeriod = DateTime.now().difference(ts.toDate()).inDays;
        int week = (daysSinceLastPeriod / 7).floor();
        if (week < 1) week = 1;
        if (week > 42) week = 42;
        int daysLeft = (40 * 7) - daysSinceLastPeriod;
        if (daysLeft < 0) daysLeft = 0;
        double percent = (week / 40).clamp(0.0, 1.0);
        return PregnancyWeeksScreen(currentWeek: week, daysLeft: daysLeft, percent: percent);
      },
    );
  }

  Widget _noPregnancy() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF4F93).withOpacity(0.15), Color(0xFF00897B).withOpacity(0.15)],
              ),
            ),
            child: Icon(Icons.pregnant_woman, size: 60, color: Color(0xFFFF4F93)),
          ),
          const SizedBox(height: 24),
          Text('\u0644\u0645 \u064A\u062A\u0645 \u062A\u062D\u062F\u064A\u062F \u062A\u0627\u0631\u064A\u062E \u0627\u0644\u062D\u0645\u0644',
            style: TextStyle(fontSize: 18, color: Color(0xFF4A3F4F), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('\u062D\u062F\u062F\u064A \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629 \u0644\u0645\u062A\u0627\u0628\u0639\u0629 \u062D\u0645\u0644\u0643 \u0623\u0633\u0628\u0648\u0639\u0627\u064B \u0628\u0623\u0633\u0628\u0648\u0639',
            style: TextStyle(fontSize: 14, color: Color(0xFF8E8295)), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF15B8A6)]),
              boxShadow: [BoxShadow(color: Color(0xFF00897B).withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: ElevatedButton.icon(
              onPressed: _setPregnancyStart,
              icon: Icon(Icons.date_range),
              label: Text('\u062D\u062F\u062F\u064A \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

}

// ==================== BABY PAGE (FIRESTORE) ====================
class BabyPage extends StatefulWidget {
  @override
  State<BabyPage> createState() => _BabyPageState();
}

class _BabyPageState extends State<BabyPage> {
  // \u2500\u2500 Premium Design Tokens \u2500\u2500
  static const _pink = Color(0xFFFF4F93);
  static const _pinkHot = Color(0xFFE53B7E);
  static const _pink50 = Color(0xFFFFF1F6);
  static const _lavender = Color(0xFFEADCF8);
  static const _lavender2 = Color(0xFFC7A8EB);
  static const _teal = Color(0xFF15B8A6);
  static const _tealDeep = Color(0xFF0F8B8D);
  static const _teal50 = Color(0xFFE7F7F5);
  static const _cream = Color(0xFFFFF8FA);
  static const _peach = Color(0xFFFFB38A);
  static const _sky = Color(0xFFDDEEFF);
  static const _gold = Color(0xFFFFD79A);
  static const _ink = Color(0xFF1B1320);
  static const _ink2 = Color(0xFF4A3F4F);
  static const _ink3 = Color(0xFF8E8295);
  static const _line = Color(0xFFF0E6EE);

  String? _selectedBabyId;

  // ── Data Methods (multi-baby) ──
  Future<void> _addBaby() async {
    final nameC = TextEditingController();
    DateTime? pickedDate;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setDState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            title: Text('\u0625\u0636\u0627\u0641\u0629 \u0637\u0641\u0644 \u062C\u062F\u064A\u062F', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameC,
                decoration: InputDecoration(
                  labelText: '\u0627\u0633\u0645 \u0627\u0644\u0637\u0641\u0644',
                  prefixIcon: const Icon(Icons.child_care, color: _pink),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _pink, width: 2)),
                )),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(context: ctx2,
                    initialDate: DateTime.now().subtract(const Duration(days: 90)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(), helpText: '\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0645\u064A\u0644\u0627\u062F',
                    builder: (context, child) => Localizations.override(context: context, locale: const Locale('en'), child: child!));
                  if (date != null) setDState(() => pickedDate = date);
                },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
                    color: pickedDate != null ? _teal50 : _pink50,
                    border: Border.all(color: pickedDate != null ? _teal : _pink.withOpacity(0.3))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.calendar_month, color: pickedDate != null ? _teal : _pink, size: 18),
                    const SizedBox(width: 8),
                    Text(pickedDate != null ? '${pickedDate!.year}/${pickedDate!.month}/${pickedDate!.day}' : '\u0627\u062E\u062A\u0627\u0631\u064A \u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0645\u064A\u0644\u0627\u062F',
                      style: TextStyle(color: pickedDate != null ? _teal : _pink, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              ),
              if (pickedDate != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () { if (nameC.text.trim().isNotEmpty) Navigator.pop(ctx, {'name': nameC.text.trim(), 'birthDate': pickedDate}); },
                  child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(colors: [Color(0xFFFF6BA3), _pink, _pinkHot]),
                      boxShadow: [BoxShadow(color: _pink.withOpacity(0.22), blurRadius: 28, offset: const Offset(0, 12))]),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8),
                      Text('\u062D\u0641\u0638', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ])),
                ),
              ],
            ]),
          ),
        ));
      },
    );
    if (result != null && result['birthDate'] != null) {
      final doc = await DB.babies.add({
        'name': result['name'], 'birthDate': Timestamp.fromDate(result['birthDate']),
        'weight': 0.0, 'height': 0.0, 'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
      await DB.userDoc.set({'babyName': result['name'], 'babyBirthDate': Timestamp.fromDate(result['birthDate']),
        'selectedBabyId': doc.id}, SetOptions(merge: true));
      if (mounted) setState(() => _selectedBabyId = doc.id);
    }
  }

  Future<void> _setBabyInfo() async => _addBaby();

  Future<void> _addLog(String type, [String? babyId]) async {
    final id = babyId ?? _selectedBabyId;
    final col = id != null ? DB.babyLogsFor(id) : DB.babyLogs;
    final doc = col.doc(DB.dateKey());
    final snap = await doc.get();
    Map<String, dynamic> data = {};
    if (snap.exists) data = snap.data() as Map<String, dynamic>? ?? {};
    int current = (data[type] as int?) ?? 0;
    data[type] = current + 1;
    data['date'] = DB.dateKey();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data, SetOptions(merge: true));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('\u062A\u0645 \u062A\u0633\u062C\u064A\u0644 $type \u2713'), backgroundColor: _teal, duration: const Duration(seconds: 1)));
  }

  Future<void> _updateGrowth(String field, double value, [String? babyId]) async {
    final id = babyId ?? _selectedBabyId;
    if (id != null) {
      await DB.babies.doc(id).set({field: value, '${field}_date': DB.dateKey()}, SetOptions(merge: true));
    }
    await DB.userDoc.set({'baby_$field': value, 'baby_${field}_date': DB.dateKey()}, SetOptions(merge: true));
  }

  String _arabicDate() {
    final now = DateTime.now();
    final days = ['\u0627\u0644\u0623\u062D\u062F', '\u0627\u0644\u0625\u062B\u0646\u064A\u0646', '\u0627\u0644\u062B\u0644\u0627\u062B\u0627\u0621', '\u0627\u0644\u0623\u0631\u0628\u0639\u0627\u0621', '\u0627\u0644\u062E\u0645\u064A\u0633', '\u0627\u0644\u062C\u0645\u0639\u0629', '\u0627\u0644\u0633\u0628\u062A'];
    final months = ['\u064A\u0646\u0627\u064A\u0631', '\u0641\u0628\u0631\u0627\u064A\u0631', '\u0645\u0627\u0631\u0633', '\u0623\u0628\u0631\u064A\u0644', '\u0645\u0627\u064A\u0648', '\u064A\u0648\u0646\u064A\u0648', '\u064A\u0648\u0644\u064A\u0648', '\u0623\u063A\u0633\u0637\u0633', '\u0633\u0628\u062A\u0645\u0628\u0631', '\u0623\u0643\u062A\u0648\u0628\u0631', '\u0646\u0648\u0641\u0645\u0628\u0631', '\u062F\u064A\u0633\u0645\u0628\u0631'];
    return '${days[now.weekday % 7]} ${now.day} ${months[now.month - 1]}';
  }

  String _milestoneForAge(int days) {
    if (days < 30) return '\u0627\u0644\u0634\u0647\u0631 \u0627\u0644\u0623\u0648\u0644 \u2014 \u0627\u0644\u0627\u0628\u062A\u0633\u0627\u0645\u0629 \u0627\u0644\u0623\u0648\u0644\u0649 \u0642\u0631\u064A\u0628\u0629';
    if (days < 90) return '\u0628\u062F\u0627\u064A\u0629 \u0627\u0644\u062A\u0641\u0627\u0639\u0644 \u0627\u0644\u0627\u062C\u062A\u0645\u0627\u0639\u064A \u0648\u0627\u0644\u0645\u0646\u0627\u063A\u0627\u0629';
    if (days < 180) return '\u064A\u0628\u062F\u0623 \u0628\u0627\u0644\u0625\u0645\u0633\u0627\u0643 \u0648\u0627\u0644\u062A\u0642\u0644\u0651\u0628';
    if (days < 270) return '\u0645\u0631\u062D\u0644\u0629 \u0627\u0644\u062C\u0644\u0648\u0633 \u0648\u0627\u0644\u0637\u0639\u0627\u0645 \u0627\u0644\u0635\u0644\u0628';
    if (days < 365) return '\u0645\u0631\u062D\u0644\u0629 \u0627\u0644\u0632\u062D\u0641 \u0648\u0627\u0644\u0648\u0642\u0648\u0641';
    return '\u0645\u0631\u062D\u0644\u0629 \u0627\u0644\u0645\u0634\u064A \u0648\u0627\u0644\u0643\u0644\u0627\u0645';
  }

  String _emojiForAge(int days) {
    if (days < 30) return '\uD83D\uDC76';
    if (days < 90) return '\uD83D\uDE0A';
    if (days < 180) return '\u270B';
    if (days < 270) return '\uD83C\uDF7D\uFE0F';
    if (days < 365) return '\uD83D\uDEB6';
    return '\uD83D\uDCAC';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: _cream,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_cream, Colors.white, _cream],
            ),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: DB.babies.snapshots(),
            builder: (context, babiesSnap) {
              // Show loading while stream hasn't loaded yet
              if (babiesSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4F93)));
              }
              if (babiesSnap.hasError) {
                return Center(child: Text('خطأ: ${babiesSnap.error}', style: const TextStyle(color: Colors.red)));
              }
              final babyDocs = babiesSnap.hasData
                  ? (List<QueryDocumentSnapshot>.from(babiesSnap.data!.docs)
                    ..sort((a, b) {
                      final aDate = (a.data() as Map)['createdAt'];
                      final bDate = (b.data() as Map)['createdAt'];
                      if (aDate == null) return 1;
                      if (bDate == null) return -1;
                      return (aDate as Timestamp).compareTo(bDate as Timestamp);
                    }))
                  : <QueryDocumentSnapshot>[];
              
              return StreamBuilder<DocumentSnapshot>(
              stream: DB.userDoc.snapshots(),
              builder: (context, userSnap) {
              Map<String, dynamic> userData = {};
              if (userSnap.hasData && userSnap.data!.exists) {
                userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
              }
              
              // Determine selected baby
              if (_selectedBabyId == null && userData['selectedBabyId'] != null) {
                _selectedBabyId = userData['selectedBabyId'];
              }
              
              // Get baby data from subcollection or fallback to user doc
              String babyName = '';
              int ageDays = 0;
              String ageText = '';
              double weight = 0;
              double babyHeight = 0;
              String? activeBabyId = _selectedBabyId;
              
              if (babyDocs.isNotEmpty) {
                // Find selected baby or use first
                QueryDocumentSnapshot? selectedDoc;
                for (final d in babyDocs) {
                  if (d.id == activeBabyId) { selectedDoc = d; break; }
                }
                selectedDoc ??= babyDocs.first;
                activeBabyId = selectedDoc.id;
                if (_selectedBabyId != activeBabyId) _selectedBabyId = activeBabyId;
                
                final bd = selectedDoc.data() as Map<String, dynamic>;
                babyName = bd['name'] ?? '';
                weight = (bd['weight'] as num?)?.toDouble() ?? (userData['baby_weight'] as num?)?.toDouble() ?? 0;
                babyHeight = (bd['height'] as num?)?.toDouble() ?? (userData['baby_height'] as num?)?.toDouble() ?? 0;
                if (bd['birthDate'] != null) {
                  try {
                    Timestamp ts = bd['birthDate'];
                    ageDays = DateTime.now().difference(ts.toDate()).inDays;
                    if (ageDays < 30) ageText = '$ageDays \u064A\u0648\u0645';
                    else if (ageDays < 365) ageText = '${(ageDays / 30).floor()} \u0623\u0634\u0647\u0631';
                    else ageText = '${(ageDays / 365).floor()} \u0633\u0646\u0629 \u0648 ${((ageDays % 365) / 30).floor()} \u0623\u0634\u0647\u0631';
                  } catch (_) {}
                }
              } else {
                // Fallback to old single-baby data
                babyName = userData['babyName'] ?? '';
                weight = (userData['baby_weight'] as num?)?.toDouble() ?? 0;
                babyHeight = (userData['baby_height'] as num?)?.toDouble() ?? 0;
                if (userData['babyBirthDate'] != null) {
                  try {
                    Timestamp ts = userData['babyBirthDate'];
                    ageDays = DateTime.now().difference(ts.toDate()).inDays;
                    if (ageDays < 30) ageText = '$ageDays \u064A\u0648\u0645';
                    else if (ageDays < 365) ageText = '${(ageDays / 30).floor()} \u0623\u0634\u0647\u0631';
                    else ageText = '${(ageDays / 365).floor()} \u0633\u0646\u0629 \u0648 ${((ageDays % 365) / 30).floor()} \u0623\u0634\u0647\u0631';
                  } catch (_) {}
                }
              }

              if (babyName.isEmpty && userData['babyBirthDate'] == null && babyDocs.isEmpty) {
                return _buildEmptyState();
              }

              final logStream = activeBabyId != null
                ? DB.babyLogsFor(activeBabyId).doc(DB.dateKey()).snapshots()
                : DB.babyLogs.doc(DB.dateKey()).snapshots();

              return StreamBuilder<DocumentSnapshot>(
                stream: logStream,
                builder: (context, logSnap) {
                  Map<String, dynamic> log = {};
                  if (logSnap.hasData && logSnap.data!.exists) {
                    log = logSnap.data!.data() as Map<String, dynamic>? ?? {};
                  }
                  int feeding = (log['feeding'] as int?) ?? 0;
                  int sleep = (log['sleep'] as int?) ?? 0;
                  int diaper = (log['diaper'] as int?) ?? 0;

                  return CustomScrollView(
                    slivers: [
                      // \u2500\u2500 Top Bar \u2500\u2500
                      SliverAppBar(
                        floating: true, snap: true,
                        backgroundColor: Colors.transparent, elevation: 0,
                        toolbarHeight: 68,
                        flexibleSpace: Container(
                          margin: const EdgeInsets.only(top: 8, left: 12, right: 12),
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withOpacity(0.85), width: 0.5),
                            boxShadow: [BoxShadow(color: _ink.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
                          ),
                          child: Row(children: [
                            const SizedBox(width: 14),
                            GestureDetector(
                              onTap: () => Navigator.maybePop(context),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withOpacity(0.8)),
                                child: const Icon(Icons.arrow_forward_ios, size: 18, color: _ink),
                              ),
                            ),
                            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Text('\u0631\u0639\u0627\u064A\u0629 \u0627\u0644\u0637\u0641\u0644', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: _teal, boxShadow: [BoxShadow(color: _teal.withOpacity(0.6), blurRadius: 6)])),
                                const SizedBox(width: 5),
                                Text('\u0627\u0644\u064A\u0648\u0645 \u2022 ${_arabicDate()}', style: const TextStyle(fontSize: 10.5, color: _ink3, fontWeight: FontWeight.w600)),
                              ]),
                            ])),
                            GestureDetector(
                              onTap: _setBabyInfo,
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withOpacity(0.8)),
                                child: const Icon(Icons.edit_outlined, size: 18, color: _pink),
                              ),
                            ),
                            const SizedBox(width: 14),
                          ]),
                        ),
                      ),

                      SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 8),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 BABY SELECTOR \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        if (babyDocs.isNotEmpty)
                          Container(
                            height: 52,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                ...babyDocs.map((doc) {
                                  final bd = doc.data() as Map<String, dynamic>;
                                  final isSelected = doc.id == activeBabyId;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _selectedBabyId = doc.id);
                                        DB.userDoc.update({'selectedBabyId': doc.id});
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: isSelected ? _pink : Colors.white.withOpacity(0.7),
                                          border: Border.all(
                                            color: isSelected ? _pink : _ink.withOpacity(0.1),
                                            width: isSelected ? 1.5 : 0.5,
                                          ),
                                          boxShadow: isSelected
                                            ? [BoxShadow(color: _pink.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                                            : [],
                                        ),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          Text(
                                            bd['name'] ?? '\u0637\u0641\u0644',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected ? Colors.white : _ink,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.check_circle, size: 16, color: Colors.white),
                                          ],
                                        ]),
                                      ),
                                    ),
                                  );
                                }),
                                // Add baby button
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: GestureDetector(
                                    onTap: _addBaby,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _teal.withOpacity(0.4), width: 1.5, style: BorderStyle.solid),
                                        color: _teal.withOpacity(0.06),
                                      ),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                                        Icon(Icons.add_circle_outline, size: 18, color: _teal),
                                        SizedBox(width: 6),
                                        Text('\u0625\u0636\u0627\u0641\u0629 \u0637\u0641\u0644', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _teal)),
                                      ]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 HERO BABY CARD \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            color: Colors.white.withOpacity(0.75),
                            border: Border.all(color: Colors.white.withOpacity(0.9), width: 0.5),
                            boxShadow: [
                              BoxShadow(color: _ink.withOpacity(0.08), blurRadius: 48, offset: const Offset(0, 24)),
                              BoxShadow(color: _lavender2.withOpacity(0.12), blurRadius: 60, offset: const Offset(0, 30)),
                            ],
                          ),
                          child: Column(children: [
                            // Baby avatar orb
                            Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(colors: [Color(0xFFFFE6EF), Color(0xFFFFC0D6), Color(0xFFFF8DB7)]),
                                boxShadow: [BoxShadow(color: _pink.withOpacity(0.25), blurRadius: 32, offset: const Offset(0, 12))],
                              ),
                              child: Center(child: Text(_emojiForAge(ageDays), style: const TextStyle(fontSize: 48))),
                            ),
                            const SizedBox(height: 14),
                            // Name
                            Text(babyName.isEmpty ? '\u0637\u0641\u0644\u064A' : babyName,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _ink)),
                            if (ageText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(colors: [_lavender2.withOpacity(0.18), _pink.withOpacity(0.12)]),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.cake_outlined, size: 14, color: _pinkHot),
                                  const SizedBox(width: 6),
                                  Text('\u0627\u0644\u0639\u0645\u0631: $ageText', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _pinkHot)),
                                ]),
                              ),
                            ],
                            const SizedBox(height: 10),
                            // Milestone
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: _teal50,
                                border: Border.all(color: _teal.withOpacity(0.2)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.auto_awesome, size: 14, color: _teal),
                                const SizedBox(width: 6),
                                Flexible(child: Text(_milestoneForAge(ageDays), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _tealDeep))),
                              ]),
                            ),

                            const SizedBox(height: 20),

                            // \u2500\u2500 Growth Stats \u2500\u2500
                            Row(children: [
                              _growthCard('\u0627\u0644\u0648\u0632\u0646', weight > 0 ? '${weight.toStringAsFixed(1)}' : '--', '\u0643\u063A',
                                Icons.monitor_weight_outlined, const [Color(0xFFFFB38A), Color(0xFFFF8852)], () => _showGrowthInput('\u0627\u0644\u0648\u0632\u0646 (\u0643\u063A)', 'weight')),
                              const SizedBox(width: 12),
                              _growthCard('\u0627\u0644\u0637\u0648\u0644', babyHeight > 0 ? '${babyHeight.toStringAsFixed(0)}' : '--', '\u0633\u0645',
                                Icons.height, const [_teal, _tealDeep], () => _showGrowthInput('\u0627\u0644\u0637\u0648\u0644 (\u0633\u0645)', 'height')),
                            ]),
                          ]),
                        ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 DAILY LOG SECTION \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        _sectionHeader('\u0627\u0644\u0633\u062C\u0644 \u0627\u0644\u064A\u0648\u0645\u064A', '\u062A\u062A\u0628\u0639\u064A \u0646\u0634\u0627\u0637 \u0637\u0641\u0644\u0643\u0650'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(children: [
                            _logCard('\uD83C\uDF7C', '\u0627\u0644\u0631\u0636\u0627\u0639\u0629', '$feeding \u0645\u0631\u0629',
                              [const Color(0xFFFF6BA3), _pink], () => _addLog('feeding')),
                            const SizedBox(width: 10),
                            _logCard('\uD83D\uDE34', '\u0627\u0644\u0646\u0648\u0645', '$sleep \u0633\u0627\u0639\u0629',
                              [_lavender2, const Color(0xFF9B6FE1)], () => _addLog('sleep')),
                            const SizedBox(width: 10),
                            _logCard('\uD83D\uDC76', '\u0627\u0644\u062D\u0641\u0627\u0636', '$diaper \u062A\u063A\u064A\u064A\u0631',
                              [_teal, _tealDeep], () => _addLog('diaper')),
                          ]),
                        ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 VACCINES SECTION \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        _sectionHeader('\u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A', '\u0633\u062C\u0644 \u0627\u0644\u0644\u0642\u0627\u062D\u0627\u062A'),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(children: [
                            _vaccineItem('\u0644\u0642\u0627\u062D \u0627\u0644\u062A\u0647\u0627\u0628 \u0627\u0644\u0643\u0628\u062F \u0628', 'hepb', '\u0639\u0646\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629', activeBabyId),
                            _vaccineItem('\u0644\u0642\u0627\u062D BCG', 'bcg', '\u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0623\u0648\u0644', activeBabyId),
                            _vaccineItem('\u0627\u0644\u0644\u0642\u0627\u062D \u0627\u0644\u062B\u0644\u0627\u062B\u064A', 'dtap', '\u0634\u0647\u0631\u064A\u0646', activeBabyId),
                            _vaccineItem('\u0644\u0642\u0627\u062D \u0634\u0644\u0644 \u0627\u0644\u0623\u0637\u0641\u0627\u0644', 'polio', '\u0634\u0647\u0631\u064A\u0646', activeBabyId),
                            _vaccineItem('\u0644\u0642\u0627\u062D \u0627\u0644\u062D\u0635\u0628\u0629', 'mmr', '9 \u0623\u0634\u0647\u0631', activeBabyId),
                          ]),
                        ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 AI INSIGHTS \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        _sectionHeader('\u0631\u0624\u0649 \u0646\u0628\u0636\u0629 \u0627\u0644\u0630\u0643\u064A\u0629', '\u0646\u0635\u0627\u0626\u062D \u0644\u0639\u0645\u0631 \u0637\u0641\u0644\u0643\u0650'),
                        SizedBox(
                          height: 180,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _insightCard('النوم الصحي', 'يحتاج طفلكِ إلى 14-17 ساعة نوم يوميًا في هذا العمر.',
                                '🌙 نصيحة النوم', [const Color(0xFF1A2238), const Color(0xFF2D2851), const Color(0xFF3E2A56)],
                                'دليل شامل للنوم الصحي للطفل:\n\nالنوم الصحي هو أحد أهم عوامل نمو طفلك السليم. خلال النوم العميق يفرز الجسم هرمون النمو ويقوي الجهاز المناعي ويعالج الدماغ كل المعلومات والمهارات التي تعلمها الطفل أثناء اليقظة. لذلك فان جودة النوم لا تقل أهمية عن مدته.\n\nقواعد النوم الآمن الأساسية:\n\n• ضعي طفلك على ظهره دائما عند النوم. هذه القاعدة الذهبية تقلل خطر متلازمة الموت المفاجئ للرضع بنسبة كبيرة وينصح بها جميع أطباء الأطفال\n• استخدمي فرشة مسطحة وصلبة مغطاة بملاءة مشدودة. تجنبي الفرشات اللينة والوسائد والألعاب المحشوة والبطانيات السميكة في السرير\n• حافظي على درجة حرارة الغرفة بين 20-22 درجة مئوية. ألبسي الطفل طبقة واحدة أكثر مما ترتدينه واستخدمي كيس نوم بدل البطانيات\n• ضعي سرير الطفل في غرفتك خلال الأشهر الستة الأولى لكن ليس في سريرك. القرب يسهل الرضاعة الليلية\n\nبناء روتين نوم ناجح:\n\n• ابدئي روتين النوم في نفس الوقت كل ليلة حوالي الساعة 7 أو 8 مساء. الثبات هو المفتاح\n• حمام دافئ لمدة 10 دقائق يرسل اشارة للجسم أن وقت الاسترخاء قد حان\n• تدليك لطيف بزيت الأطفال يهدئ الجهاز العصبي ويعمق الترابط بينكما\n• الرضاعة الأخيرة في جو هادئ بأضواء خافتة ثم قصة قصيرة أو تهويدة\n• ضعي الطفل نعسانا لكن لم ينم بعد ليتعلم تهدئة نفسه والنوم باستقلالية\n• الضوضاء البيضاء كصوت المروحة تساعد كثيرا في تهدئة الرضيع وتذكره بأصوات الرحم\n\nساعات النوم حسب العمر:\n\n• حديث الولادة 0-3 أشهر: 14-17 ساعة موزعة على فترات قصيرة 2-4 ساعات لأن معدته صغيرة\n• 4-6 أشهر: 12-15 ساعة مع بدء النوم الليلي لفترات أطول 5-6 ساعات و2-3 قيلولات نهارية\n• 7-12 شهر: 12-14 ساعة مع نوم ليلي 8-10 ساعات وقيلولتين نهاريتين\n• 1-3 سنوات: 11-14 ساعة مع قيلولة واحدة نهارية\n\nنصائح اضافية مهمة:\n\n• تجنبي الشاشات قبل النوم بساعة على الأقل لأن الضوء الأزرق يثبط انتاج هرمون الميلاتونين المسؤول عن النوم\n• راقبي علامات النعاس: فرك العينين والتثاؤب والعصبية. لا تنتظري حتى يصبح متعبا جدا\n• اذا استيقظ ليلا انتظري دقيقة أو دقيقتين قبل التدخل فقد يعود للنوم بنفسه\n• القيلولات النهارية مهمة ولا تحرمي الطفل منها فالعكس هو الصحيح الطفل المرتاح ينام أفضل\n\nتذكري أن كل طفل مختلف وأن أنماط النوم تتغير مع كل مرحلة نمو. الصبر والثبات على الروتين هما مفتاح النجاح.'),
                              const SizedBox(width: 12),
                              _insightCard('التغذية', 'الرضاعة الطبيعية هي الأفضل خلال ال6 أشهر الأولى.',
                                '🍼 تغذية مثالية', [_teal, _tealDeep, const Color(0xFF0A5F60)],
                                'دليل شامل لتغذية الطفل من الولادة حتى السنة الثانية:\n\nتغذية طفلك بشكل صحيح هي أحد أهم القرارات التي تؤثر على صحته ونموه مدى الحياة. حليب الأم هو الغذاء المثالي الذي صممته الطبيعة خصيصا لاحتياجات الرضيع المتغيرة وتركيبته تتغير تلقائيا حسب عمر الطفل.\n\nمراحل التغذية حسب العمر:\n\n• من الولادة حتى 6 أشهر: رضاعة طبيعية حصرية. لا يحتاج الطفل أي طعام أو ماء اضافي. أرضعي 8-12 مرة يوميا أي كل 2-3 ساعات. حليب الأم يحتوي على كل العناصر الغذائية والأجسام المضادة التي يحتاجها\n• عند 6 أشهر: ابدئي بادخال الأطعمة الصلبة تدريجيا مع الاستمرار بالرضاعة. علامات الجاهزية: يستطيع الجلوس بمساعدة ويبدي اهتماما بطعامك ويفتح فمه عند تقديم الملعقة\n• 6-8 أشهر: ابدئي بالحبوب المدعمة بالحديد والخضروات المهروسة كالكوسا والبطاطا الحلوة والجزر ثم الفواكه كالموز والتفاح المسلوق. قدمي طعاما واحدا جديدا كل 3-5 أيام لمراقبة الحساسية\n• 8-10 أشهر: زيدي القوام من المهروس الناعم الى الخشن. أضيفي البروتين كالدجاج المفروم والعدس والبيض المسلوق وأطعمة الأصابع\n• 10-12 شهر: يمكن أن يأكل معظم طعام العائلة مقطعا بشكل مناسب. 3 وجبات رئيسية و2 خفيفة مع استمرار الرضاعة\n\nأطعمة يجب تجنبها:\n\n• العسل قبل عمر السنة بسبب خطر بكتيريا البوتولينوم\n• الملح والسكر المضاف لأن الكلى غير ناضجة\n• المكسرات الكاملة لخطر الاختناق حتى عمر 5 سنوات لكن يمكن اعطاؤها مطحونة\n• الحليب البقري كشراب رئيسي قبل عمر السنة\n\nعلامات الجوع المبكرة: وضع اليد في الفم والبحث عن الثدي والتملل. البكاء علامة متأخرة.\nعلامات الشبع: ابعاد الرأس واغلاق الفم وفقدان الاهتمام بالطعام. احترمي شهية طفلك ولا تجبريه.\n\nنصائح ذهبية: كلي مع طفلك فهو يتعلم بالمشاهدة. قدمي الطعام المرفوض عدة مرات فقد يحتاج 10-15 محاولة. اجعلي وقت الطعام ممتعا بدون ضغط.'),
                              const SizedBox(width: 12),
                              _insightCard('النمو الحركي', 'شجّعي طفلكِ على وقت البطن (tummy time) يوميًا.',
                                '💪 نشاط يومي', [const Color(0xFFFF6BA3), _pink, _lavender2],
                                'دليل شامل لمراحل النمو الحركي للطفل وكيفية تحفيزه:\n\nالنمو الحركي رحلة مذهلة تبدأ من حركات عشوائية بسيطة وتتطور تدريجيا حتى المشي والجري. كل طفل يتطور بسرعته الخاصة لكن هناك مراحل عامة يمر بها معظم الأطفال. فهم هذه المراحل يساعدك على تقديم الدعم المناسب.\n\nالمراحل الرئيسية حسب العمر:\n\n• شهر 1-2: يرفع رأسه قليلا على بطنه ويحرك أطرافه بحركات عشوائية ويبدأ بمتابعة الأشياء بعينيه\n• شهر 3-4: يرفع رأسه بثبات ويبدأ بالتقلب من البطن للظهر ويمسك الأشياء ويحاول الوصول اليها\n• شهر 5-6: يجلس بمساعدة ويتقلب في الاتجاهين وينقل الأشياء من يد لأخرى ويبدأ بالتحميل على يديه\n• شهر 7-8: يجلس بدون مساعدة ويبدأ بالزحف ويستخدم الابهام والسبابة لالتقاط الأشياء الصغيرة\n• شهر 9-10: يقف بمساعدة ويتنقل ممسكا بالأثاث ويصفق ويلوح ويزحف بسرعة\n• شهر 11-12: يقف لوحده ويخطو خطواته الأولى. بعض الأطفال يتأخرون حتى 15-18 شهرا وهذا طبيعي\n\nوقت البطن Tummy Time - من أهم الأنشطة:\n\n• ابدئي من اليوم الأول بعد الولادة بدقيقتين أو ثلاث عدة مرات يوميا\n• زيدي تدريجيا حتى 20-30 دقيقة موزعة على اليوم\n• ضعي ألعابا ملونة أمامه لتشجيعه على رفع رأسه\n• استلقي أمامه وتحدثي معه فوجهك أفضل محفز\n\nنصائح ذهبية لتحفيز النمو الحركي:\n\n• وفري مساحة آمنة للاستكشاف بتأمين المنزل بأغطية المقابس وأقفال الأدراج\n• الأرض أفضل مكان لتطوير المهارات الحركية. لا تبالغي في المشاية أو الكرسي الهزاز\n• قدمي ألعابا متنوعة مناسبة لعمره كالخشخيشة والمكعبات والكرات\n• شجعيه ولا تجبريه. اذا لم يكن مستعدا لمرحلة لا تضغطي عليه\n• امسكي بيديه للمشي لكن تجنبي المشاية التقليدية لأنها قد تؤخر المشي الطبيعي\n• تحدثي معه أثناء اللعب وصفي ما يفعله فهذا يحفز النمو اللغوي أيضا\n\nمتى تستشيرين الطبيب:\n• اذا لم يرفع رأسه بعد 4 أشهر\n• اذا لم يجلس بعد 9 أشهر\n• اذا لم يمشي بعد 18 شهرا\n• اذا فقد مهارة كان يتقنها سابقا\n\nتذكري: لا تقارني طفلك بالآخرين. كل طفل فريد ويتطور بطريقته في الوقت المناسب له.'),
                            ],
                          ),
                        ),

                        // \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550 ARTICLES \u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _BabyArticlesSection(ageDays: ageDays),
                        ),

                        // ════════════ LATEST NEWS ════════════
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _NewsSection(accentColor: Color(0xFFE91E63), sectionTitle: 'آخر أخبار الطفل'),
                        ),
                        const SizedBox(height: 30),
                      ])),
                    ],
                  );
                },
              );
            },
          );
            },
          ),
        ),
      ),
    );
  }

  // \u2500\u2500 Empty State \u2500\u2500
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_pink.withOpacity(0.15), _lavender.withOpacity(0.1)]),
            ),
            child: const Center(child: Text('\uD83D\uDC76', style: TextStyle(fontSize: 56))),
          ),
          const SizedBox(height: 20),
          const Text('\u0644\u0645 \u064A\u062A\u0645 \u0625\u0636\u0627\u0641\u0629 \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('\u0623\u0636\u064A\u0641\u064A \u0627\u0633\u0645 \u0648\u062A\u0627\u0631\u064A\u062E \u0645\u064A\u0644\u0627\u062F \u0637\u0641\u0644\u0643\u0650 \u0644\u0628\u062F\u0621 \u0627\u0644\u0645\u062A\u0627\u0628\u0639\u0629',
            style: TextStyle(fontSize: 13, color: _ink3), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _setBabyInfo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(colors: [Color(0xFFFF6BA3), _pink, _pinkHot]),
                boxShadow: [BoxShadow(color: _pink.withOpacity(0.3), blurRadius: 28, offset: const Offset(0, 12))],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('\u0623\u0636\u064A\u0641\u064A \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // \u2500\u2500 Section Header \u2500\u2500
  Widget _sectionHeader(String eyebrow, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _lavender.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
          child: Text(eyebrow, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _lavender2)),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
      ]),
    );
  }

  // \u2500\u2500 Growth Card \u2500\u2500
  Widget _growthCard(String title, String value, String unit, IconData icon, List<Color> colors, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withOpacity(0.65),
            border: Border.all(color: Colors.white.withOpacity(0.85), width: 0.5),
            boxShadow: [BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: [colors.first.withOpacity(0.15), colors.last.withOpacity(0.1)]),
              ),
              child: Icon(icon, color: colors.first, size: 22),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colors.first)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.first.withOpacity(0.7))),
            ]),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: _ink3, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: colors.first.withOpacity(0.08)),
              child: Text('\u062A\u062D\u062F\u064A\u062B', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: colors.first)),
            ),
          ]),
        ),
      ),
    );
  }

  // \u2500\u2500 Log Card \u2500\u2500
  Widget _logCard(String emoji, String title, String value, List<Color> colors, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            border: Border.all(color: _line),
            boxShadow: [BoxShadow(color: _ink.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [colors.first.withOpacity(0.12), colors.last.withOpacity(0.08)]),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 11, color: colors.first, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: colors),
                boxShadow: [BoxShadow(color: colors.first.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            ),
          ]),
        ),
      ),
    );
  }

  // \u2500\u2500 Vaccine Item \u2500\u2500
  CollectionReference _vaccinesCol([String? babyId]) {
    final id = babyId ?? _selectedBabyId;
    if (id != null) return DB.babies.doc(id).collection('vaccines');
    return DB.userDoc.collection('vaccines');
  }

  Widget _vaccineItem(String name, String key, String timing, [String? babyId]) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _vaccinesCol(babyId).doc(key).snapshots(),
      builder: (context, snap) {
        bool done = false;
        if (snap.hasData && snap.data!.exists) {
          done = (snap.data!.data() as Map<String, dynamic>?)?['done'] ?? false;
        }
        return GestureDetector(
          onTap: () {
            _vaccinesCol(babyId).doc(key).set({
              'name': name, 'done': !done, 'updatedAt': FieldValue.serverTimestamp()
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: done ? _teal50 : Colors.white,
              border: Border.all(color: done ? _teal.withOpacity(0.3) : _line, width: done ? 1.5 : 0.5),
              boxShadow: done
                ? [BoxShadow(color: _teal.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
                : [BoxShadow(color: _ink.withOpacity(0.03), blurRadius: 4)],
            ),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: done
                    ? const LinearGradient(colors: [_teal, _tealDeep])
                    : LinearGradient(colors: [_peach.withOpacity(0.2), _gold.withOpacity(0.15)]),
                ),
                child: Icon(done ? Icons.check_rounded : Icons.schedule_rounded, color: done ? Colors.white : _peach, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
                Text(timing, style: const TextStyle(fontSize: 11, color: _ink3, fontWeight: FontWeight.w500)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: done ? _teal.withOpacity(0.1) : _peach.withOpacity(0.1),
                ),
                child: Text(done ? '\u0645\u0643\u062A\u0645\u0644 \u2713' : '\u0642\u0627\u062F\u0645',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: done ? _teal : _peach)),
              ),
            ]),
          ),
        );
      },
    );
  }

  // \u2500\u2500 Insight Card \u2500\u2500
  Widget _insightCard(String title, String desc, String prob, List<Color> colors, [String? detailText]) {
    return GestureDetector(
      onTap: () => _showInsightDetail(title, detailText ?? desc, colors),
      child: Container(
      width: 260, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.white, blurRadius: 6)])),
            const SizedBox(width: 6),
            const Text('\u0646\u0635\u064A\u062D\u0629 \u0630\u0643\u064A\u0629', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(desc, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.82), height: 1.55)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.18), width: 0.5))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(prob, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('\u0627\u0644\u0645\u0632\u064A\u062F', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(width: 4),
                Icon(Icons.arrow_back_ios, size: 10, color: Colors.white),
              ]),
            ),
          ]),
        ),
      ]),
    ),
    );
  }

  // \u2500\u2500 Insight Detail Bottom Sheet \u2500\u2500
  void _showInsightDetail(String title, String content, List<Color> colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: _line),
            ),
            // Header with gradient
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white.withOpacity(0.2)),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Text('\u0646\u0635\u064a\u062d\u0629 \u0630\u0643\u064a\u0629 \u0645\u0646 \u0646\u0628\u0636\u0629', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
                ])),
              ]),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(content, style: const TextStyle(fontSize: 14, color: _ink2, height: 1.8, fontWeight: FontWeight.w500)),
              ),
            ),
            // Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: _cream,
                    border: Border.all(color: _line),
                  ),
                  child: const Center(child: Text('\u0625\u063a\u0644\u0627\u0642', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink2))),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // \u2500\u2500 Growth Input Dialog \u2500\u2500
  void _showGrowthInput(String label, String field) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _teal, width: 2)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('\u0625\u0644\u063A\u0627\u0621', style: TextStyle(color: _ink3))),
            GestureDetector(
              onTap: () {
                double? val = double.tryParse(controller.text);
                if (val != null) { _updateGrowth(field, val); Navigator.pop(ctx); }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: const LinearGradient(colors: [_teal, _tealDeep])),
                child: const Text('\u062D\u0641\u0638', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== FIRESTORE ARTICLES SECTION (shared) ====================
class _FirestoreArticlesSection extends StatelessWidget {
  final String type; // 'cycle' or 'baby'
  final Color color;
  const _FirestoreArticlesSection({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('articles')
        .where('type', isEqualTo: type)
        .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return SizedBox.shrink();
        // Group by category
        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (final doc in snap.data!.docs) {
          final d = doc.data() as Map<String, dynamic>;
          final cat = (d['category'] ?? '') as String;
          grouped.putIfAbsent(cat, () => []).add(doc);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.map((entry) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.auto_stories, color: color, size: 22),
                SizedBox(width: 8),
                Text(entry.key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.withOpacity(0.85))),
              ]),
              SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: entry.value.length,
                  itemBuilder: (_, i) {
                    final d = entry.value[i].data() as Map<String, dynamic>;
                    final title = d['title'] ?? '';
                    final content = d['content'] ?? '';
                    final imageUrl = d['imageUrl'] as String? ?? '';
                    final contentImages = (d['contentImages'] as List<dynamic>?)?.cast<String>() ?? [];
                    return _firestoreArticleCard(context, title, content, imageUrl, contentImages, color);
                  },
                ),
              ),
              SizedBox(height: 20),
            ]);
          }).toList(),
        );
      },
    );
  }

  // === Smart fallback images from Unsplash ===
  static final Map<String, String> _articleImageMap = {
    // Pregnancy
    'حمل': 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=600&q=80',
    'حامل': 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=600&q=80',
    'جنين': 'https://images.unsplash.com/photo-1584582397869-3e903bfe9985?w=600&q=80',
    'ولادة': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=600&q=80',
    'مخاض': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=600&q=80',
    // Baby & Child
    'طفل': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=600&q=80',
    'رضيع': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=600&q=80',
    'رضاعة': 'https://images.unsplash.com/photo-1584582397869-3e903bfe9985?w=600&q=80',
    'نوم': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=600&q=80',
    'تطعيم': 'https://images.unsplash.com/photo-1632053002928-1919605ee6f7?w=600&q=80',
    'لقاح': 'https://images.unsplash.com/photo-1632053002928-1919605ee6f7?w=600&q=80',
    // Nutrition
    'تغذية': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&q=80',
    'غذاء': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&q=80',
    'فيتامين': 'https://images.unsplash.com/photo-1505576399279-0d754c0fdc67?w=600&q=80',
    'حديد': 'https://images.unsplash.com/photo-1505576399279-0d754c0fdc67?w=600&q=80',
    'كالسيوم': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=600&q=80',
    'فوليك': 'https://images.unsplash.com/photo-1505576399279-0d754c0fdc67?w=600&q=80',
    // Cycle & Period
    'دورة': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&q=80',
    'حيض': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&q=80',
    'تبويض': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&q=80',
    'خصوبة': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&q=80',
    // Exercise & Wellness
    'رياضة': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&q=80',
    'تمارين': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&q=80',
    'يوغا': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600&q=80',
    'استرخاء': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=600&q=80',
    'نفسية': 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=600&q=80',
    'اكتئاب': 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=600&q=80',
    // Medical
    'طبيب': 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=600&q=80',
    'فحص': 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=600&q=80',
    'سونار': 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=600&q=80',
    'أشعة': 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=600&q=80',
    // Skin & Beauty
    'بشرة': 'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=600&q=80',
    'جلد': 'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=600&q=80',
    'شعر': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80',
    // Weight
    'وزن': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&q=80',
    // General health
    'صحة': 'https://images.unsplash.com/photo-1505576399279-0d754c0fdc67?w=600&q=80',
    'علاج': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600&q=80',
    'ألم': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600&q=80',
    'غثيان': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=600&q=80',
  };

  static String _getSmartImage(String title) {
    for (final entry in _articleImageMap.entries) {
      if (title.contains(entry.key)) return entry.value;
    }
    // Default fallback
    return 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=600&q=80';
  }

  Widget _firestoreArticleCard(BuildContext context, String title, String content, String imageUrl, List<String> contentImages, Color cardColor) {
    final resolvedImage = imageUrl.isNotEmpty ? imageUrl : _getSmartImage(title);
    final hasImage = resolvedImage.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => _ArticleDetailPage(title: title, body: content, color: cardColor, imageUrl: resolvedImage, contentImages: contentImages, section: type))),
      child: Container(
        width: 260,
        margin: EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: cardColor.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 3))],
          border: Border.all(color: cardColor.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image header
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(resolvedImage, height: 100, width: 260, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 100, color: cardColor.withOpacity(0.08),
                  child: Center(child: Icon(Icons.image, color: cardColor.withOpacity(0.3), size: 36)))),
            )
          else
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cardColor.withOpacity(0.15), cardColor.withOpacity(0.05)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(child: Icon(Icons.article_outlined, color: cardColor.withOpacity(0.4), size: 42)),
            ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F1A20)),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 6),
                Expanded(child: Text(content, style: TextStyle(fontSize: 12, color: Color(0xFF4A434B), height: 1.4),
                  maxLines: 3, overflow: TextOverflow.ellipsis)),
                Align(alignment: Alignment.centerLeft,
                  child: Text('اقرأي المزيد ←', style: TextStyle(color: cardColor, fontSize: 11, fontWeight: FontWeight.bold))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CycleArticlesSection extends StatelessWidget {
  static const _cycleArticles = <String, List<Map<String, String>>>{
    'صحة الدورة الشهرية': [
      {'title': 'فهم دورتك الشهرية', 'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&q=80',
       'content': 'الدورة الشهرية هي عملية طبيعية يمر بها جسم المرأة كل شهر تقريباً وتتراوح مدتها بين واحد وعشرين يوماً وخمسة وثلاثين يوماً بمتوسط ثمانية وعشرين يوماً. تبدأ الدورة من أول يوم للحيض وتنتهي قبل اليوم الأول للحيض التالي. خلال هذه الفترة يمر جسمك بأربع مراحل رئيسية تتحكم فيها الهرمونات بدقة متناهية.\n\nالمرحلة الأولى هي مرحلة الحيض التي تستمر من ثلاثة إلى سبعة أيام يتخلص فيها الرحم من بطانته عبر نزيف مهبلي. المرحلة الثانية هي المرحلة الجريبية التي يرتفع فيها هرمون الإستروجين مما يحفز نمو بويضة ناضجة. ثم تأتي مرحلة التبويض في منتصف الدورة حين تنطلق البويضة من المبيض. المرحلة الأخيرة هي المرحلة الأصفرية التي يفرز فيها البروجسترون لتهيئة بطانة الرحم. تتبعي دورتك بانتظام وسجلي الأعراض لفهم نمطك الشخصي.'},
      {'title': 'تخفيف آلام الدورة', 'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=600&q=80',
       'content': 'آلام الدورة الشهرية من أكثر الشكاوى شيوعاً بين النساء وتتراوح من تقلصات خفيفة إلى آلام شديدة. تحدث بسبب انقباضات الرحم وإفراز البروستاغلاندين.\n\nلتخفيف الألم طبيعياً جربي الكمادات الدافئة على أسفل البطن ومارسي رياضة خفيفة كالمشي أو اليوغا. تناولي أطعمة غنية بالمغنيسيوم كالموز والشوكولاتة الداكنة. اشربي شاي الزنجبيل أو البابونج وتجنبي الكافيين والملح الزائد. استشيري طبيبتك إذا استمر الألم شديداً كل شهر.'},
      {'title': 'متلازمة ما قبل الحيض PMS', 'image': 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=600&q=80',
       'content': 'متلازمة ما قبل الحيض مجموعة من الأعراض الجسدية والنفسية التي تظهر قبل الدورة بأسبوع إلى عشرة أيام وتختفي مع بدء الحيض. تصيب أكثر من سبعين بالمئة من النساء بدرجات متفاوتة وتشمل الأعراض الانتفاخ والصداع وتورم الثديين وتغيرات المزاج والتهيج والرغبة الشديدة في تناول السكريات.\n\nلتخفيف الأعراض مارسي الرياضة بانتظام وتناولي وجبات صغيرة متكررة غنية بالألياف والبروتين. قللي الملح لتقليل الانتفاخ واحصلي على نوم كافٍ. مكملات الكالسيوم والمغنيسيوم وفيتامين B6 قد تساعد بعد استشارة الطبيبة. إذا كانت الأعراض شديدة وتؤثر على حياتك اليومية فقد تكون متلازمة ما قبل الحيض الشديدة PMDD وتحتاج متابعة طبية.'},
      {'title': 'الدورة غير المنتظمة: الأسباب والعلاج', 'image': 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=600&q=80',
       'content': 'الدورة غير المنتظمة تعني تغيراً ملحوظاً في مدة الدورة أو كمية النزيف أو غياب الدورة لأكثر من ثلاثة أشهر. الأسباب شائعة وتشمل الضغط النفسي والتغيرات المفاجئة في الوزن والإفراط في التمارين الرياضية واضطرابات الغدة الدرقية ومتلازمة تكيس المبايض.\n\nللتعامل مع عدم الانتظام حافظي على وزن صحي ومارسي الرياضة باعتدال وقللي التوتر عبر تقنيات الاسترخاء. تتبعي دورتك لعدة أشهر وسجلي التفاصيل لمشاركتها مع طبيبتك. راجعي الطبيبة إذا غابت الدورة أكثر من ثلاثة أشهر أو كان النزيف غزيراً جداً أو استمر أكثر من سبعة أيام أو ظهرت أعراض إضافية كنمو الشعر الزائد أو حب الشباب الشديد.'},
      {'title': 'الدورة الشهرية والنظافة الشخصية', 'image': 'https://images.unsplash.com/photo-1585435557343-3b092031a831?w=600&q=80',
       'content': 'العناية بالنظافة الشخصية أثناء الدورة ضرورية لصحتك وراحتك. غيّري الفوطة الصحية كل ثلاث إلى أربع ساعات حتى لو لم تمتلئ لمنع نمو البكتيريا. اغسلي المنطقة الحساسة بالماء الفاتر فقط أو بغسول خفيف مخصص وتجنبي الصابون المعطر والدش المهبلي.\n\nارتدي ملابس داخلية قطنية مريحة وتجنبي الملابس الضيقة. إذا كنت تستخدمين السدادات القطنية غيّريها كل أربع إلى ست ساعات ولا تنسيها أبداً لتجنب متلازمة الصدمة السامة. كأس الحيض بديل آمن وصديق للبيئة يمكن استخدامه حتى اثنتي عشرة ساعة. احتفظي دائماً بحقيبة صغيرة فيها مستلزمات الدورة في حقيبتك.'},
      {'title': 'الرياضة أثناء الدورة الشهرية', 'image': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&q=80',
       'content': 'كثير من النساء يتجنبن الرياضة أثناء الدورة لكن الحقيقة أن التمارين الخفيفة والمعتدلة مفيدة جداً وتساعد على تخفيف الأعراض. الحركة تحسن الدورة الدموية وتفرز هرمونات الإندورفين التي تحسن المزاج وتقلل الألم.\n\nفي أيام النزيف الأولى اختاري تمارين خفيفة كالمشي واليوغا اللطيفة والسباحة والإطالة. مع تقدم الدورة يمكنك زيادة الشدة تدريجياً. تمارين القوة الخفيفة مع أوزان مناسبة ممتازة في المرحلة الجريبية بعد انتهاء الحيض حيث يكون الإستروجين في ارتفاع. استمعي لجسمك وخففي التمارين إذا شعرت بإرهاق شديد. اشربي ماءً كافياً وارتدي ملابس رياضية مريحة.'},
    ],
    'التبويض والخصوبة': [
      {'title': 'حساب أيام التبويض', 'image': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&q=80',
       'content': 'التبويض هو المرحلة التي تنطلق فيها البويضة الناضجة من أحد المبيضين. يحدث عادة في منتصف الدورة حوالي اليوم الرابع عشر في دورة مدتها ثمانية وعشرون يوماً.\n\nلتحديد يوم التبويض استخدمي عدة طرق: قياس درجة حرارة الجسم الأساسية كل صباح ومراقبة إفرازات عنق الرحم التي تصبح شفافة ومطاطة قبل التبويض واستخدام اختبارات التبويض المنزلية. تتراوح فترة الخصوبة بين خمسة أيام قبل التبويض ويوم بعده. الجمع بين عدة طرق يعطي أدق النتائج.'},
      {'title': 'علامات التبويض الطبيعية', 'image': 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=600&q=80',
       'content': 'يمكنك التعرف على فترة التبويض من خلال عدة علامات يرسلها جسمك. أبرزها تغير الإفرازات المهبلية التي تصبح شفافة وزلقة ومطاطة تشبه بياض البيض وارتفاع طفيف في درجة حرارة الجسم الأساسية وألم خفيف في جانب واحد من أسفل البطن يُعرف بألم الإباضة.\n\nعلامات أخرى تشمل زيادة الرغبة الجنسية وحساسية الثديين وانتفاخ خفيف وتحسن المزاج والطاقة بسبب ارتفاع الإستروجين. بعض النساء يلاحظن تحسناً في البشرة وزيادة في حاسة الشم. سجلي هذه العلامات يومياً لعدة أشهر وستتمكنين من التنبؤ بموعد التبويض بدقة أكبر.'},
      {'title': 'نصائح لتعزيز الخصوبة طبيعياً', 'image': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&q=80',
       'content': 'لتعزيز فرص الحمل بشكل طبيعي ابدئي بالحفاظ على وزن صحي لأن النحافة الشديدة والسمنة تؤثران على التبويض. تناولي غذاءً متوازناً غنياً بحمض الفوليك والحديد والزنك وأوميغا ثلاثة. أكثري من الخضروات والفواكه والبروتينات والحبوب الكاملة.\n\nمارسي الرياضة باعتدال وتجنبي الإفراط لأنه يؤثر على الهرمونات. قللي التوتر بتقنيات الاسترخاء والنوم الكافي. تجنبي التدخين والكحول والكافيين الزائد. ابدئي بتناول حمض الفوليك قبل الحمل بثلاثة أشهر. تتبعي دورتك ومارسي العلاقة الزوجية بانتظام خلال فترة الخصوبة. استشيري طبيبتك إذا لم يحدث حمل بعد سنة من المحاولة.'},
      {'title': 'متلازمة تكيس المبايض', 'image': 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=600&q=80',
       'content': 'متلازمة تكيس المبايض من أشهر الاضطرابات الهرمونية التي تصيب النساء في سن الإنجاب وتؤثر على واحدة من كل عشر نساء تقريباً. تتميز بارتفاع هرمونات الذكورة وعدم انتظام الدورة ووجود أكياس صغيرة على المبايض في الموجات فوق الصوتية.\n\nالأعراض تشمل عدم انتظام الدورة أو غيابها ونمو شعر زائد في الوجه والجسم وحب شباب شديد وصعوبة في فقدان الوزن وتساقط الشعر. العلاج يعتمد على تغيير نمط الحياة أولاً من خلال خسارة الوزن الزائد والرياضة المنتظمة والغذاء الصحي المنخفض السكريات المكررة. الأدوية تشمل حبوب منع الحمل لتنظيم الدورة وأدوية تحسين حساسية الأنسولين. استشيري أخصائية لوضع خطة علاج مناسبة.'},
    ],
    'التغذية والدورة الشهرية': [
      {'title': 'أطعمة تخفف أعراض الدورة', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80',
       'content': 'ما تأكلينه يؤثر مباشرة على شدة أعراض الدورة الشهرية. الأطعمة الغنية بالحديد كالسبانخ والعدس واللحوم الحمراء تعوض الحديد المفقود مع النزيف وتمنع الإرهاق والدوخة.\n\nالموز والشوكولاتة الداكنة والمكسرات غنية بالمغنيسيوم الذي يرخي العضلات ويقلل التقلصات. سمك السلمون وبذور الكتان والجوز توفر أوميغا ثلاثة المضادة للالتهاب. الأناناس يحتوي على إنزيم البروميلين الذي يخفف الالتهاب. اشربي ماءً كافياً وشاي الأعشاب كالبابونج والزنجبيل وتجنبي الأطعمة المالحة والمقلية والمشروبات الغازية والكافيين الزائد.'},
      {'title': 'المكملات الغذائية المفيدة للدورة', 'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=600&q=80',
       'content': 'بعض المكملات الغذائية أثبتت فعاليتها في تخفيف أعراض الدورة الشهرية. المغنيسيوم من أهمها لأنه يقلل التقلصات والصداع واحتباس السوائل بجرعة ثلاثمئة إلى أربعمئة ملليغرام يومياً.\n\nالكالسيوم بجرعة ألف ملليغرام يومياً يخفف أعراض متلازمة ما قبل الحيض. فيتامين B6 يساعد على تحسين المزاج وتقليل الانتفاخ. حمض أوميغا ثلاثة الدهني يقلل شدة التقلصات. الحديد ضروري للنساء ذوات النزيف الغزير لتجنب فقر الدم. فيتامين D يدعم صحة العظام والمزاج. استشيري طبيبتك قبل تناول أي مكمل لتحديد الجرعة المناسبة وتجنب التفاعلات.'},
      {'title': 'الترطيب وأهمية الماء أثناء الدورة', 'image': 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=600&q=80',
       'content': 'شرب الماء الكافي أثناء الدورة الشهرية أمر بالغ الأهمية رغم أنه قد يبدو غير بديهي خاصة عند الشعور بالانتفاخ. الجفاف يزيد من حدة الصداع والإرهاق والتقلصات ويمكن أن يفاقم احتباس السوائل.\n\nاهدفي لشرب ثمانية إلى عشرة أكواب يومياً وزيدي الكمية إذا كان النزيف غزيراً. أضيفي شرائح الليمون أو الخيار أو النعناع لتحسين الطعم. المشروبات الدافئة كشاي الأعشاب والماء الدافئ بالعسل مهدئة ومفيدة. قللي المشروبات المحتوية على الكافيين لأنها مدرة للبول وتزيد الجفاف. الأطعمة الغنية بالماء كالبطيخ والخيار والبرتقال تساهم أيضاً في الترطيب.'},
    ],
    'الصحة النفسية والدورة': [
      {'title': 'تقلبات المزاج أثناء الدورة', 'image': 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=600&q=80',
       'content': 'تقلبات المزاج المرتبطة بالدورة الشهرية ناتجة عن تغيرات هرمونية طبيعية وتؤثر على أكثر من ثمانين بالمئة من النساء. انخفاض الإستروجين والبروجسترون قبل الحيض يؤثر على مستويات السيروتونين في الدماغ مما يسبب القلق والحزن والتهيج.\n\nللتعامل مع تقلبات المزاج مارسي الرياضة بانتظام فهي ترفع الإندورفين وتحسن المزاج. احصلي على نوم كافٍ من سبع إلى تسع ساعات. مارسي التأمل والتنفس العميق. تجنبي القرارات الكبيرة في الأيام الصعبة. تحدثي عن مشاعرك مع شخص تثقين به. سجلي مزاجك يومياً لتفهمي نمطك الشهري وتتعاملي مع التغيرات بشكل أفضل.'},
      {'title': 'النوم والراحة أثناء الدورة', 'image': 'https://images.unsplash.com/photo-1531353826977-0941b4779a1c?w=600&q=80',
       'content': 'كثير من النساء يعانين من اضطرابات النوم قبل وأثناء الدورة الشهرية. انخفاض البروجسترون الذي له تأثير مهدئ يجعل النوم أصعب وقد تستيقظين أكثر أثناء الليل وتشعرين بإرهاق رغم ساعات النوم الكافية.\n\nلتحسين النوم حافظي على روتين ثابت للنوم والاستيقاظ حتى في عطلة نهاية الأسبوع. اجعلي غرفة النوم مظلمة وباردة وهادئة. تجنبي الشاشات قبل النوم بساعة واستبدليها بالقراءة أو التأمل. خذي حماماً دافئاً قبل النوم واشربي شاي البابونج المهدئ. إذا كان الألم يوقظك استخدمي كمادة دافئة وتناولي مسكناً قبل النوم بعد استشارة الطبيبة. نامي على جانبك مع وسادة بين ركبتيك لتخفيف ضغط البطن.'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final color = Colors.pink;
    return StreamBuilder<QuerySnapshot>(
      stream: DynamicContentService.getArticles(section: 'cycle'),
      builder: (context, dynamicSnap) {
        final dynamicArticles = (dynamicSnap.data?.docs ?? [])
            .map((doc) => DynamicContentService.docToArticle(doc))
            .toList();

        // Merge dynamic articles into categories (dynamic first)
        final merged = <String, List<Map<String, String>>>{};
        // Add dynamic articles first, grouped by category
        for (final art in dynamicArticles) {
          merged.putIfAbsent(art['category']!, () => []).add(art);
        }
        // Then add static articles
        for (final entry in _cycleArticles.entries) {
          merged.putIfAbsent(entry.key, () => []);
          merged[entry.key]!.addAll(entry.value);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: merged.entries.map((entry) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.auto_stories, color: color, size: 22),
                SizedBox(width: 8),
                Text(entry.key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.withOpacity(0.85))),
              ]),
              SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: entry.value.length,
                  itemBuilder: (_, i) {
                    final d = entry.value[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ArticleDetailPage(title: d['title']!, body: d['content']!, color: color, imageUrl: d['image']!, section: 'cycle'))),
                      child: Container(
                        width: 200, margin: EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white, boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 3))]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(d['image']!, height: 110, width: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 110, color: color.withOpacity(0.1), child: Icon(Icons.article, color: color, size: 40)))),
                          Padding(padding: EdgeInsets.all(10), child: Text(d['title']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
            ]);
          }).toList(),
        );
      },
    );
  }
}

class _BabyArticlesSection extends StatelessWidget {
  final int ageDays;
  const _BabyArticlesSection({this.ageDays = 0});

  String get _ageLabel {
    if (ageDays < 30) return 'حديث الولادة';
    if (ageDays < 180) return '${(ageDays / 30).floor()} أشهر';
    if (ageDays < 365) return '${(ageDays / 30).floor()} أشهر';
    return '${(ageDays / 365).floor()} سنة';
  }

  // Each article has ageMin/ageMax in days. Category 'صحة الطفل العامة' is shown for ALL ages.
  static const _babyArticles = <String, List<Map<String, String>>>{
    'حديث الولادة (0-3 أشهر)': [
      {
        'title': 'العناية بالحبل السري للمولود',
        'image': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=600&q=80',
        'ageMin': '0', 'ageMax': '90',
        'content': 'يُعد الحبل السري من أهم الأمور التي تحتاج عناية خاصة في الأيام الأولى بعد الولادة. بعد قطع الحبل السري يبقى جزء صغير متصل ببطن المولود يُعرف بجذع الحبل السري وهو يجف ويسقط تلقائياً خلال أسبوع إلى ثلاثة أسابيع من الولادة. خلال هذه الفترة من الضروري الحفاظ على المنطقة نظيفة وجافة لمنع أي عدوى بكتيرية قد تصيب المولود.\n\nتوصي منظمة الصحة العالمية بالعناية الجافة لجذع الحبل السري أي تركه مكشوفاً للهواء قدر الإمكان دون وضع أي مواد عليه مثل الكحول أو البودرة أو المراهم إلا إذا أوصى الطبيب بخلاف ذلك. اطوي حافة الحفاض للأسفل بحيث لا تغطي الجذع وألبسي المولود ملابس فضفاضة من القطن تسمح بتهوية المنطقة. إذا اتسخ الجذع بالبول أو البراز نظفيه بقطعة قطن مبللة بالماء الفاتر ثم جففيه جيداً بالتربيت اللطيف.\n\nعلامات العدوى التي يجب الانتباه لها تشمل احمرار الجلد حول قاعدة الجذع وتورم المنطقة وخروج إفرازات صفراء أو خضراء ذات رائحة كريهة ونزيف مستمر وارتفاع حرارة المولود. إذا لاحظتِ أياً من هذه العلامات توجهي للطبيب فوراً لأن التهاب الحبل السري حالة تستدعي العلاج السريع بالمضادات الحيوية. بعد سقوط الجذع قد تلاحظين كمية صغيرة من الدم أو إفرازات صفراء وهذا طبيعي ويشفى خلال أيام قليلة. استمري بالحفاظ على نظافة منطقة السرة حتى تلتئم تماماً ولا تحاولي سحب الجذع أو إزالته قبل أن يسقط بشكل طبيعي مهما بدا متدلياً.',
      },
      {
        'title': 'أساسيات الرضاعة الطبيعية لحديثي الولادة',
        'image': 'https://images.unsplash.com/photo-1609220136736-443140cffec6?w=600&q=80',
        'ageMin': '0', 'ageMax': '90',
        'content': 'الرضاعة الطبيعية هي الغذاء المثالي والأكمل لحديثي الولادة وتوصي بها منظمة الصحة العالمية بشكل حصري خلال الأشهر الستة الأولى. يحتوي حليب الأم على مزيج فريد من البروتينات والدهون والفيتامينات والأجسام المضادة التي تحمي المولود من العدوى والأمراض وتعزز نمو دماغه وجهازه الهضمي بشكل سليم.\n\nفي الساعات الأولى بعد الولادة يُنتج الثدي اللبأ وهو سائل ذهبي سميك غني بالأجسام المضادة والبروتينات المناعية. كمية اللبأ صغيرة لكنها تكفي معدة المولود الصغيرة التي لا تتسع لأكثر من خمسة إلى سبعة ملليلترات في اليوم الأول. لا تقلقي من قلة الكمية فهذا طبيعي تماماً وجسمك يعرف ما يحتاجه طفلك.\n\nيحتاج المولود للرضاعة كل ساعتين إلى ثلاث ساعات أي من ثماني إلى اثنتي عشرة رضعة في اليوم. علامات الجوع تشمل تحريك الرأس يميناً ويساراً ومص اليد أو الأصابع وفتح الفم عند لمس الخد. البكاء هو علامة جوع متأخرة لذا حاولي إرضاع طفلك قبل وصوله لمرحلة البكاء الشديد. تأكدي من أن طفلك يمسك بالثدي بشكل صحيح بحيث يغطي فمه الحلمة ومعظم الهالة وذقنه يلامس الثدي وشفته السفلى مقلوبة للخارج. الإمساك الصحيح هو مفتاح الرضاعة الناجحة ويمنع تشقق الحلمات ويضمن حصول الطفل على كمية كافية من الحليب.\n\nأول أسبوعين هما الأصعب في رحلة الرضاعة فتحلي بالصبر واطلبي المساعدة من استشارية رضاعة إذا واجهتِ صعوبة. تأكدي من أن طفلك يبلل ست حفاضات على الأقل يومياً بعد اليوم الرابع ويكتسب الوزن بشكل طبيعي فهذه أفضل علامات كفاية الحليب.',
      },
      {
        'title': 'نوم المولود: أنماط وتوجيهات آمنة',
        'image': 'https://images.unsplash.com/photo-1519689373023-dd07c7988603?w=600&q=80',
        'ageMin': '0', 'ageMax': '90',
        'content': 'ينام المولود الجديد ما بين ستة عشر وسبع عشرة ساعة يومياً لكنه لا ينام فترات طويلة متواصلة بل يستيقظ كل ساعتين إلى ثلاث ساعات للرضاعة. هذا النمط طبيعي تماماً ومرتبط بصغر حجم معدته واحتياجه المستمر للغذاء. لا يميز المولود بين الليل والنهار في الأسابيع الأولى وتبدأ ساعته البيولوجية بالتنظم تدريجياً بعد الشهر الثاني.\n\nالنوم الآمن أمر بالغ الأهمية لحماية المولود من متلازمة الموت المفاجئ للرضع. ضعي طفلك دائماً على ظهره للنوم على سطح مستوٍ وثابت بدون وسائد أو بطانيات سميكة أو ألعاب محشوة في سريره. استخدمي مرتبة صلبة تناسب حجم السرير تماماً بحيث لا توجد فراغات بين المرتبة وجوانب السرير. يمكنك لف المولود بقماطة خفيفة من القطن مع ترك مساحة كافية لحركة الوركين.\n\nدرجة حرارة الغرفة المثالية للنوم تتراوح بين عشرين واثنتين وعشرين درجة مئوية. تحققي من حرارة طفلك بلمس صدره أو رقبته فإذا كان دافئاً ومريحاً فالملابس مناسبة. تجنبي تغطيته بطبقات كثيرة لأن ارتفاع الحرارة يزيد خطر متلازمة الموت المفاجئ. ألبسيه بدلة نوم قطنية مناسبة للطقس وهذا كافٍ في معظم الأحيان.\n\nلمساعدة طفلك على التمييز بين الليل والنهار أبقي الأضواء والأصوات طبيعية نهاراً وأطفئي الأنوار وتحدثي بهدوء ليلاً. يمكنك وضع سرير الطفل في غرفتك خلال الأشهر الستة الأولى لتسهيل الرضاعة الليلية ومراقبته لكن تجنبي مشاركة سريرك معه لأسباب تتعلق بالسلامة.',
      },
      {
        'title': 'اليرقان عند حديثي الولادة',
        'image': 'https://images.unsplash.com/photo-1504151932400-72d4384f04b3?w=600&q=80',
        'ageMin': '0', 'ageMax': '90',
        'content': 'اليرقان أو الصفراء هو حالة شائعة جداً تصيب أكثر من ستين بالمئة من المواليد الأصحاء وتظهر عادة في اليوم الثاني أو الثالث بعد الولادة. يحدث اليرقان بسبب ارتفاع مستوى مادة البيليروبين في الدم وهي مادة صفراء تنتج من تكسر خلايا الدم الحمراء الزائدة. كبد المولود الجديد لا يكون ناضجاً بالكامل بعد لذا يستغرق وقتاً في معالجة البيليروبين والتخلص منه.\n\nتظهر أعراض اليرقان باصفرار الجلد وبياض العينين ويبدأ عادة من الوجه وينتشر تدريجياً إلى الصدر والبطن والأطراف. لفحص الصفراء في المنزل اضغطي برفق على جبين طفلك أو أنفه في مكان مضاء جيداً فإذا ظهر الجلد أصفر عند رفع إصبعك فقد يكون مستوى البيليروبين مرتفعاً. اليرقان الفسيولوجي الطبيعي يظهر بعد أربع وعشرين ساعة من الولادة ويبلغ ذروته في اليوم الثالث إلى الخامس ويختفي تلقائياً خلال أسبوع إلى أسبوعين.\n\nالرضاعة المتكررة هي أفضل علاج لليرقان الخفيف لأنها تساعد على طرد البيليروبين عبر البراز. أرضعي طفلك من ثماني إلى اثنتي عشرة مرة يومياً ولا تتوقفي عن الرضاعة. تعريض المولود لأشعة الشمس غير المباشرة لفترات قصيرة من عشر إلى خمس عشرة دقيقة يومياً يساعد أيضاً في تكسير البيليروبين لكن تجنبي أشعة الشمس المباشرة القوية.\n\nراجعي الطبيب فوراً إذا ظهر اليرقان خلال أول أربع وعشرين ساعة من الولادة أو إذا كان شديداً ومنتشراً في الأطراف أو رافقه خمول شديد ورفض الرضاعة أو بكاء حاد بنبرة عالية غير معتادة. في الحالات الشديدة يحتاج المولود للعلاج بالضوء في المستشفى وهو إجراء آمن وفعال يستخدم ضوءاً أزرق خاصاً يساعد جسم المولود على تكسير البيليروبين.',
      },
      {
        'title': 'المغص عند الرضع: الأسباب والتهدئة',
        'image': 'https://images.unsplash.com/photo-1492725764893-90b379c2b6e7?w=600&q=80',
        'ageMin': '0', 'ageMax': '90',
        'content': 'المغص من أكثر المشكلات شيوعاً عند الرضع في الأشهر الثلاثة الأولى ويصيب ما يقارب عشرين إلى خمسة وعشرين بالمئة من المواليد. يتميز بنوبات بكاء شديد ومستمر لأكثر من ثلاث ساعات يومياً لأكثر من ثلاثة أيام في الأسبوع ولمدة تزيد عن ثلاثة أسابيع عند رضيع سليم ويتغذى جيداً. يبدأ المغص عادة في الأسبوع الثاني أو الثالث ويبلغ ذروته في الأسبوع السادس ثم يتحسن تدريجياً ويختفي غالباً بحلول الشهر الثالث أو الرابع.\n\nالسبب الدقيق للمغص غير معروف تماماً لكن النظريات تشمل عدم نضج الجهاز الهضمي وابتلاع الهواء أثناء الرضاعة وحساسية بعض الأطعمة في حليب الأم والتحفيز الزائد للجهاز العصبي. نوبات المغص تحدث غالباً في المساء وتبدأ فجأة حيث يشد الرضيع ساقيه نحو بطنه ويقبض يديه ويحمر وجهه من شدة البكاء.\n\nلتهدئة الرضيع المصاب بالمغص جربي عدة تقنيات منها حمل الطفل على بطنه على ساعدك أو على ركبتيك مع تدليك ظهره بلطف. الحركة الإيقاعية مثل الهز اللطيف أو المشي به أو وضعه في كرسي هزاز تساعد كثيراً. الأصوات الرتيبة مثل صوت المكنسة أو المجفف أو تطبيقات الضوضاء البيضاء تهدئ الجهاز العصبي. تدليك بطن الرضيع بحركات دائرية لطيفة في اتجاه عقارب الساعة يساعد على تخفيف الغازات.\n\nإذا كنتِ ترضعين طبيعياً جربي تقليل منتجات الألبان والكافيين والبصل والبروكلي من غذائك لأسبوعين لمراقبة التحسن. تأكدي من تجشؤ الطفل بعد كل رضعة لإخراج الهواء المبتلع. استشيري الطبيب إذا رافق البكاء قيء شديد أو إسهال مدمم أو حمى أو رفض تام للرضاعة لاستبعاد أسباب أخرى. تذكري أن المغص مرحلة مؤقتة وستمر وأن طفلك سليم ولا يعاني من ألم دائم.',
      },
      {
        'title': 'الحمام الأول والعناية اليومية بالمولود',
        'image': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=600&q=80',
        'ageMin': '0', 'ageMax': '90',
        'content': 'الحمام الأول للمولود تجربة مميزة تتطلب تحضيراً جيداً ومعرفة بالخطوات الصحيحة لضمان سلامة الطفل وراحته. يُنصح بتأخير الحمام الأول الكامل حتى سقوط جذع الحبل السري والاكتفاء قبل ذلك بالتنظيف بالإسفنجة. جهزي كل ما تحتاجينه قبل البدء وتشمل القائمة حوض استحمام صغير وماء فاتر بدرجة حرارة سبعة وثلاثين درجة ومنشفة ناعمة وغسول لطيف خالٍ من العطور وحفاض نظيف وملابس.\n\nاختبري حرارة الماء بمرفقك أو بميزان حرارة مخصص قبل وضع الطفل فيه. لا تضعي أكثر من خمسة إلى ثمانية سنتيمترات من الماء في الحوض. أمسكي المولود بيد واحدة تدعم رأسه ورقبته وباليد الأخرى نظفي جسمه بلطف. ابدئي بالوجه بقطعة قماش مبللة بالماء فقط ثم الرأس ثم الجسم من الأعلى للأسفل واتركي منطقة الحفاض للآخر.\n\nلا تحتاجين لاستحمام المولود يومياً فمرتين إلى ثلاث مرات أسبوعياً كافية تماماً. الاستحمام المفرط يزيل الزيوت الطبيعية التي تحمي بشرته الرقيقة ويسبب الجفاف والتهيج. في الأيام التي لا يستحم فيها نظفي وجهه ويديه ومنطقة الحفاض بقطعة قماش مبللة فقط.\n\nالعناية اليومية تشمل أيضاً تنظيف ثنيات الرقبة وخلف الأذنين حيث يتجمع الحليب والعرق وتقليم الأظافر عندما تطول باستخدام مقص أظافر مخصص للأطفال ويفضل ذلك أثناء نوم الطفل. نظفي أنف المولود بقطرات ملحية عند الاحتقان ونظفي عينيه بقطن مبلل بالماء المعقم من الداخل للخارج. رطبي بشرته بكريم لطيف خاصة في الطقس الجاف واختاري ملابس قطنية ناعمة تناسب حرارة الجو.',
      },
    ],
    'الرضيع (3-6 أشهر)': [
      {
        'title': 'التسنين: الأعراض والتخفيف',
        'image': 'https://images.unsplash.com/photo-1519340241574-2cec6aef0c01?w=600&q=80',
        'ageMin': '90', 'ageMax': '180',
        'content': 'يبدأ التسنين عادة بين الشهر الرابع والسابع وقد يتأخر عند بعض الأطفال حتى الشهر الثاني عشر وكل هذا يعتبر طبيعياً. أول الأسنان ظهوراً عادة هي القواطع السفلية الأمامية تليها العلوية ثم الأضراس الأولى والأنياب وأخيراً الأضراس الثانية. يكتمل طقم الأسنان اللبنية وعددها عشرون سناً بحلول عمر السنتين ونصف إلى الثلاث سنوات تقريباً.\n\nأعراض التسنين تختلف من طفل لآخر لكن الشائع منها يشمل زيادة سيلان اللعاب ورغبة شديدة في العض والمضغ على كل شيء وتورم واحمرار اللثة في مكان ظهور السن وتهيج وبكاء أكثر من المعتاد واضطراب في النوم ورفض جزئي للطعام. بعض الأطفال يصابون بارتفاع طفيف في الحرارة لكن الحمى الشديدة ليست من أعراض التسنين وتستدعي مراجعة الطبيب.\n\nلتخفيف ألم التسنين قدمي لطفلك حلقة تسنين مبردة في الثلاجة وليس المجمد فالبرودة تخدر اللثة وتقلل الالتهاب. يمكنك أيضاً تدليك لثة الطفل بإصبع نظيف بحركات دائرية لطيفة. قطعة قماش نظيفة مبللة ومبردة يمكن للطفل مضغها. الأطعمة الباردة مثل الزبادي المبرد أو قطع الفواكه المجمدة في شبكة التغذية الآمنة مناسبة للأطفال فوق ستة أشهر.\n\nيمكن استخدام جل مسكن للثة مخصص للأطفال بكمية صغيرة على اللثة بعد استشارة الطبيب وتجنبي المنتجات التي تحتوي على البنزوكايين للأطفال أقل من سنتين. إذا كان الألم شديداً يمكنك إعطاء الباراسيتامول أو الإيبوبروفين المخصص للأطفال فوق ستة أشهر حسب الجرعة المناسبة لوزن الطفل. ابدئي بتنظيف أسنان طفلك فور ظهورها بفرشاة أسنان ناعمة مخصصة للرضع وكمية ضئيلة من معجون أسنان بالفلورايد بحجم حبة الأرز.',
      },
      {
        'title': 'مقدمة الأطعمة الصلبة في الشهر السادس',
        'image': 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=600&q=80',
        'ageMin': '90', 'ageMax': '180',
        'content': 'عند بلوغ الرضيع ستة أشهر يصبح جسمه مستعداً لتلقي أطعمة تكميلية بجانب حليب الأم أو الحليب الصناعي. علامات الاستعداد تشمل قدرة الطفل على الجلوس بدعم والتحكم في رأسه وإبداء اهتمام بالطعام عند رؤية الآخرين يأكلون وفقدان منعكس دفع اللسان. إذا لم تظهر هذه العلامات بعد فانتظري أسبوعاً أو اثنين وحاولي مجدداً.\n\nابدئي بتقديم طعام واحد مهروس بقوام ناعم جداً مثل الأرز المسلوق المهروس جيداً أو البطاطا الحلوة المسلوقة والمهروسة أو الكوسا أو الجزر المسلوق. قدمي ملعقة أو اثنتين فقط في البداية ولا تتوقعي أن يأكل الطفل كمية كبيرة فهو يتعلم مهارة جديدة وهي البلع من الملعقة بدلاً من الرضاعة. استخدمي ملعقة ناعمة مخصصة للرضع وضعي كمية صغيرة على طرفها.\n\nالقاعدة الذهبية هي تقديم طعام جديد واحد كل ثلاثة إلى خمسة أيام لمراقبة أي ردود فعل تحسسية. سجلي كل طعام جديد تقدمينه والتاريخ لتتبع أي حساسية. الأطعمة الأولى الموصى بها تشمل الحبوب المدعمة بالحديد والخضروات المسلوقة المهروسة كالجزر والبطاطا والكوسا والبازلاء والفواكه المهروسة كالموز والتفاح والكمثرى والأفوكادو.\n\nلا تضيفي ملحاً أو سكراً أو عسلاً للطعام وتجنبي حليب البقر كامل كشراب رئيسي قبل عمر السنة. حافظي على الرضاعة كمصدر رئيسي للتغذية فالأطعمة الصلبة في هذه المرحلة مكملة وليست بديلة. اجعلي وقت الطعام تجربة ممتعة واسمحي للطفل بلمس الطعام واستكشافه بيديه فهذا يطور مهاراته الحركية الدقيقة ويعزز علاقته الإيجابية بالطعام.',
      },
      {
        'title': 'تطور المهارات الحركية من 3 إلى 6 أشهر',
        'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=600&q=80',
        'ageMin': '90', 'ageMax': '180',
        'content': 'الفترة بين الشهر الثالث والسادس مليئة بالتطورات الحركية المثيرة حيث يتحول الرضيع من كائن يعتمد كلياً على الآخرين إلى طفل يبدأ باستكشاف العالم من حوله بنشاط وفضول متزايد. في الشهر الثالث يرفع الطفل رأسه وصدره بثبات أثناء الاستلقاء على بطنه ويبدأ بالتقلب من بطنه لظهره ويمد يديه نحو الأشياء التي تثير اهتمامه.\n\nبحلول الشهر الرابع يتحكم الطفل بشكل أفضل في رأسه ويمسك الأشياء بقبضة كاملة ويحملها لفمه لاستكشافها. يبدأ بالتقلب في الاتجاهين ويضحك بصوت عالٍ ويصدر أصوات مناغاة متنوعة. في الشهر الخامس يجلس بمساعدة ويتمايل قليلاً ويبدأ بنقل الأشياء من يد لأخرى ويظهر اهتماماً بالمرآة ويتعرف على الوجوه المألوفة.\n\nوقت البطن أو ما يُعرف بتمرين الاستلقاء على البطن ضروري جداً لتقوية عضلات الرقبة والظهر والكتفين وتحضير الطفل للمراحل التالية من الحركة مثل الحبو والجلوس المستقل. ابدئي بثلاث إلى خمس دقائق عدة مرات يومياً وزيدي تدريجياً. ضعي ألعاباً ملونة أمامه لتشجيعه على رفع رأسه والمد نحوها. استلقي أمامه وتحدثي معه لجعل التجربة ممتعة.\n\nلتعزيز التطور الحركي وفري ألعاباً آمنة بأحجام مختلفة يمكنه الإمساك بها وهزها واستكشافها. الخشخيشات والألعاب الملونة ذات الأصوات مناسبة جداً لهذه المرحلة. ضعيه على بطانية على الأرض ليتدرب على التقلب والمد بحرية. لا تتركيه في كرسي الأطفال أو المشاية لفترات طويلة لأن الحركة الحرة على الأرض أفضل لتطوره الحركي. تحدثي مع طبيب الأطفال إذا لم يرفع رأسه بحلول الشهر الرابع أو لم يمسك الأشياء بحلول الشهر الخامس.',
      },
      {
        'title': 'تنظيم نوم الرضيع من 3 إلى 6 أشهر',
        'image': 'https://images.unsplash.com/photo-1566004100631-35d015d6a491?w=600&q=80',
        'ageMin': '90', 'ageMax': '180',
        'content': 'بين الشهر الثالث والسادس يبدأ نمط نوم الرضيع بالتنظم تدريجياً وتصبح فترات النوم الليلية أطول. ينام الرضيع في هذه المرحلة ما بين أربع عشرة وست عشرة ساعة يومياً موزعة بين النوم الليلي وقيلولتين إلى ثلاث قيلولات نهارية. كثير من الأطفال يستطيعون النوم لفترة متواصلة من خمس إلى ست ساعات ليلاً بحلول الشهر الرابع.\n\nإنشاء روتين ثابت قبل النوم من أهم الخطوات لتنظيم نوم الرضيع. يمكن أن يشمل الروتين حماماً دافئاً يليه تدليك لطيف ثم ارتداء ملابس النوم والرضاعة وأخيراً أغنية هادئة أو قراءة قصة قصيرة. كرري هذا الروتين كل ليلة في نفس التوقيت تقريباً ليربط الطفل هذه الأنشطة بوقت النوم. ابدئي الروتين قبل ظهور علامات التعب الشديد كفرك العينين والتثاؤب والبكاء.\n\nحاولي وضع الطفل في سريره وهو نعسان لكنه لا يزال مستيقظاً ليتعلم الاستغراق في النوم بمفرده. هذه المهارة مهمة جداً لأنها تساعده على العودة للنوم وحده عندما يستيقظ في الليل وهو أمر طبيعي يحدث عدة مرات حتى عند البالغين. إذا بكى الطفل عند وضعه في السرير ربتي عليه بلطف وتحدثي بصوت هادئ دون حمله فوراً.\n\nالقيلولات النهارية مهمة لمنع الإرهاق الزائد الذي يجعل النوم الليلي أصعب لا أسهل. راقبي علامات التعب وضعي الطفل للقيلولة قبل أن يصبح متعباً جداً. القيلولة المثالية تتراوح بين ثلاثين دقيقة وساعتين. تجنبي القيلولة المتأخرة قريباً من وقت النوم الليلي. تحلي بالصبر فتنظيم النوم عملية تدريجية وقد تمر بفترات تراجع مرتبطة بطفرات النمو أو التسنين.',
      },
      {
        'title': 'أهمية وقت البطن لتقوية الرضيع',
        'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=600&q=80',
        'ageMin': '90', 'ageMax': '180',
        'content': 'وقت البطن أو ما يُسمى بالإنجليزية تمي تايم هو تمرين بسيط لكنه بالغ الأهمية لتطور الرضيع الحركي والبصري. يتضمن وضع الرضيع على بطنه لفترات قصيرة عدة مرات يومياً أثناء استيقاظه وتحت إشرافك الدائم. يساعد هذا التمرين على تقوية عضلات الرقبة والكتفين والظهر والذراعين وهي العضلات الأساسية التي يحتاجها الطفل لرفع رأسه والتقلب والجلوس والحبو لاحقاً.\n\nابدئي وقت البطن منذ الأسابيع الأولى بوضع الطفل على صدرك وأنت مستلقية بزاوية وهو ينظر لوجهك. هذا يمنحه التحفيز البصري ويشجعه على رفع رأسه. مع مرور الأسابيع انتقلي لوضعه على بطانية ناعمة على الأرض. ابدئي بدقيقتين إلى ثلاث دقائق في كل مرة وزيدي تدريجياً حتى يصل إلى عشرين دقيقة أو أكثر مقسمة على عدة جلسات يومياً.\n\nكثير من الأطفال لا يحبون وقت البطن في البداية ويبكون. لجعل التجربة ممتعة استلقي على مستوى نظره وتحدثي معه وغنّي له. ضعي ألعاباً ملونة ومرآة آمنة أمامه لجذب انتباهه وتشجيعه على رفع رأسه والمد نحوها. يمكنك وضع منشفة ملفوفة تحت صدره لمنحه بعض الدعم في البداية. غيري الألعاب والأنشطة لتبقي الأمر مثيراً ومتجدداً.\n\nبالإضافة لتقوية العضلات يساعد وقت البطن على تطوير التنسيق بين العينين واليدين ومنع تسطح مؤخرة الرأس الذي يحدث من الاستلقاء المستمر على الظهر. يحفز أيضاً التطور الحسي لأن الطفل يختبر سطحاً وزاوية مختلفة للعالم. اجعلي وقت البطن جزءاً من الروتين اليومي بعد تغيير الحفاض أو بعد الاستيقاظ من القيلولة ولا تمارسيه بعد الرضاعة مباشرة لتجنب الارتجاع.',
      },
    ],
    'الرضيع المتقدم (6-9 أشهر)': [
      {
        'title': 'الحبو والزحف: تشجيع الحركة الأولى',
        'image': 'https://images.unsplash.com/photo-1587616211892-f743fcca64f9?w=600&q=80',
        'ageMin': '180', 'ageMax': '270',
        'content': 'يبدأ معظم الأطفال بالحبو بين الشهر السابع والعاشر وهو إنجاز حركي كبير يفتح أمام الطفل عالماً جديداً من الاستكشاف والاستقلالية. بعض الأطفال يحبون بالطريقة التقليدية على يديهم وركبهم وآخرون يزحفون على بطنهم أو يتحركون بطريقة الدب على يديهم وأقدامهم وبعضهم يتنقل جالساً بدفع مؤخرتهم وكل هذه الأساليب طبيعية ومقبولة.\n\nلتشجيع طفلك على الحبو وفري له مساحة آمنة على الأرض واتركيه يستكشف بحرية. ضعي ألعابه المفضلة على بعد قليل منه ليحاول الوصول إليها. اجعلي وقت اللعب على الأرض جزءاً كبيراً من يومه وقللي من وقت الكرسي والمشاية لأن الحركة الحرة على الأرض هي أفضل طريقة لتطوير المهارات الحركية الكبرى.\n\nبعض الأطفال يتخطون مرحلة الحبو تماماً وينتقلون مباشرة للوقوف والمشي وهذا طبيعي ولا يدعو للقلق. ما يهم هو أن الطفل يتحرك ويستكشف بيئته بأي طريقة تناسبه. المهم ملاحظة الرغبة في الحركة والاستكشاف وليس الطريقة المحددة.\n\nبمجرد أن يبدأ طفلك بالحبو ستحتاجين لمراجعة سلامة المنزل بعناية أكبر. تأكدي من تغطية المقابس الكهربائية وتثبيت الأثاث الثقيل على الجدران وإزالة الأشياء الصغيرة التي يمكن ابتلاعها ووضع بوابات أمان على الدرج وتأمين خزائن المطبخ والحمام. أبقي أبواب الحمام والمطبخ مغلقة وراقبي طفلك المتحرك باستمرار لأن فضوله لا حدود له.',
      },
      {
        'title': 'تنويع الأطعمة الصلبة من 6 إلى 9 أشهر',
        'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80',
        'ageMin': '180', 'ageMax': '270',
        'content': 'بعد تقديم الأطعمة الأولى المهروسة بنجاح حان الوقت لتنويع غذاء طفلك وتقديم قوامات ونكهات جديدة. في هذه المرحلة يمكن الانتقال تدريجياً من الأطعمة المهروسة الناعمة إلى الأطعمة المهروسة بشكل خشن ثم المقطعة قطعاً صغيرة ناعمة. هذا التدرج مهم لتطوير مهارة المضغ وتقوية عضلات الفك واللسان.\n\nالبروتينات ضرورية في هذه المرحلة لنمو الطفل وتطوره. قدمي الدجاج المسلوق المهروس واللحم البقري المفروم المطبوخ جيداً والسمك الأبيض المنزوع العظم والعدس المسلوق والفاصوليا والحمص المهروس. البيض المسلوق جيداً مصدر ممتاز للبروتين والحديد ويمكن تقديمه مهروساً أو مقطعاً شرائح رفيعة. ابدئي بصفار البيض ثم أضيفي البياض تدريجياً.\n\nالزبادي الكامل الدسم مصدر رائع للكالسيوم والبروتين ويحبه معظم الأطفال. قدميه وحده أو مخلوطاً بالفواكه المهروسة. يمكنك أيضاً تقديم الجبن الناعم كالجبنة البيضاء والريكوتا. أضيفي القليل من زيت الزيتون أو الزبدة للأطعمة لزيادة السعرات الحرارية والدهون الصحية الضرورية لنمو دماغ الطفل.\n\nمن المهم تقديم أطعمة غنية بالحديد يومياً لأن مخزون الحديد الذي ولد به الطفل يبدأ بالنفاد في هذه المرحلة. اللحوم الحمراء والعدس والسبانخ والحبوب المدعمة بالحديد مصادر جيدة. قدمي مصادر فيتامين سي مثل الفراولة والبرتقال والطماطم مع الأطعمة الغنية بالحديد لتحسين امتصاصه. قدمي الماء بكوب مفتوح أو كوب بمقبضين مع الوجبات. تجنبي العصائر والعسل والملح والسكر والمكسرات الكاملة وحليب البقر كشراب رئيسي قبل عمر السنة.',
      },
      {
        'title': 'قلق الانفصال عند الرضيع',
        'image': 'https://images.unsplash.com/photo-1476703993599-0035a21b17a9?w=600&q=80',
        'ageMin': '180', 'ageMax': '270',
        'content': 'قلق الانفصال مرحلة طبيعية في نمو الطفل تبدأ عادة بين الشهر السادس والثامن وتبلغ ذروتها بين الشهر العاشر والثامن عشر. يبكي الطفل ويتشبث بأمه عندما تحاول المغادرة حتى لو كان مع أشخاص مألوفين كالأب أو الجدة. هذا السلوك يدل على نضج معرفي مهم فالطفل أصبح يفهم أن أمه موجودة حتى عندما لا يراها وهو مفهوم يسمى ديمومة الأشياء.\n\nقلق الانفصال قد يكون مرهقاً لك لكنه علامة صحية على ارتباط آمن بينك وبين طفلك. لا تشعري بالذنب عند المغادرة ولا تتسللي خارج الغرفة دون وداع لأن هذا يزيد قلق الطفل ويجعله يراقبك باستمرار خوفاً من اختفائك المفاجئ. بدلاً من ذلك ودعي طفلك بابتسامة وعبارة قصيرة وواثقة مثل ماما ستعود حالاً ثم غادري دون تردد.\n\nلتسهيل الفترة الانتقالية مارسي لعبة الغميضة البسيطة مع طفلك بإخفاء وجهك خلف يديك ثم كشفه لأنها تعلمه أنك تختفين ثم تعودين. ابدئي بغيابات قصيرة جداً وزيديها تدريجياً. اتركي معه غرضاً يحمل رائحتك كوشاح أو قميص. دعي مقدم الرعاية البديل يصل قبل مغادرتك بوقت كافٍ ليندمج الطفل في نشاط ممتع قبل أن تذهبي.\n\nكوني متسقة في ردود أفعالك وعودي دائماً عندما تقولين إنك ستعودين لبناء ثقة الطفل. لا تطيلي وقت الوداع ولا تعودي عندما يبكي لأن ذلك يعلمه أن البكاء يمنع رحيلك. معظم الأطفال يهدأون خلال دقائق من مغادرتك. قلق الانفصال يتحسن تدريجياً مع نضج الطفل وبناء ثقته بأنك ستعودين دائماً.',
      },
      {
        'title': 'تأمين المنزل للطفل المتحرك',
        'image': 'https://images.unsplash.com/photo-1484665737444-7bf29b2fcc42?w=600&q=80',
        'ageMin': '180', 'ageMax': '270',
        'content': 'عندما يبدأ طفلك بالحركة والزحف يتحول المنزل بأكمله إلى ساحة استكشاف ويصبح تأمين البيئة المنزلية ضرورة ملحة لحمايته من المخاطر. الأطفال في هذه المرحلة فضوليون بطبيعتهم ويضعون كل شيء في أفواههم ويحاولون الوصول لكل مكان وسحب أي شيء يمكنهم الإمساك به.\n\nابدئي بالنزول لمستوى طفلك حرفياً وانزلي على ركبتيك وزحفي في أرجاء المنزل لترى المخاطر من منظوره. ستلاحظين أشياء كثيرة لم تنتبهي لها من قبل مثل كابلات كهربائية مكشوفة وزوايا حادة في الأثاث وأشياء صغيرة على الأرض يمكن ابتلاعها وأدراج مفتوحة.\n\nخطوات التأمين الأساسية تشمل تركيب أغطية على جميع المقابس الكهربائية وتثبيت بوابات أمان على الدرج في الأعلى والأسفل وتركيب أقفال أمان على خزائن المطبخ والحمام خاصة التي تحتوي على مواد تنظيف وأدوية. ضعي واقيات زوايا مطاطية على الأثاث الحاد وثبتي الأثاث الطويل والثقيل كالرفوف والتلفزيون على الجدران لمنع سقوطه على الطفل.\n\nفي المطبخ أبعدي مقابض القدور نحو الداخل واستخدمي الشعلات الخلفية وأبعدي السكاكين والأدوات الحادة عن الحواف. في الحمام لا تتركي الطفل وحده أبداً قرب الماء ولو لثانية واحدة واستخدمي بساط مانع للانزلاق في حوض الاستحمام. أبعدي النباتات المنزلية السامة وعلقيها عالياً وأبقي أبواب الشرفات والنوافذ مؤمنة. احتفظي بأرقام الطوارئ والطبيب في مكان واضح وتعلمي أساسيات الإسعاف الأولي للأطفال.',
      },
      {
        'title': 'تطور التواصل واللغة من 6 إلى 9 أشهر',
        'image': 'https://images.unsplash.com/photo-1491013516836-7db643ee125a?w=600&q=80',
        'ageMin': '180', 'ageMax': '270',
        'content': 'الفترة بين الشهر السادس والتاسع تشهد قفزة ملحوظة في قدرات الطفل التواصلية واللغوية. يبدأ الطفل بإصدار مقاطع صوتية متكررة مثل بابابا وماماما وداداد وهي ليست كلمات بعد لكنها تمرين على الأصوات التي ستتحول لاحقاً لكلمات حقيقية. يفهم الطفل معنى كلمة لا ويستجيب لاسمه ويلتفت عندما يُنادى ويتعرف على أسماء الأشخاص والأشياء المألوفة.\n\nلتعزيز التطور اللغوي تحدثي مع طفلك كثيراً طوال اليوم وصفي له ما تفعلينه خطوة بخطوة. مثلاً عند تغيير الحفاض قولي الآن سنغير الحفاض أولاً نمسح ثم نضع الكريم ثم الحفاض الجديد. هذا الوصف المستمر يبني مخزوناً هائلاً من المفردات في ذاكرة الطفل حتى لو لم يستطع استخدامها بعد.\n\nالقراءة للطفل من أهم الأنشطة التي تعزز التطور اللغوي والمعرفي. اختاري كتباً من الورق السميك بصور واضحة وبسيطة وألوان زاهية. اقرئي بصوت واضح ومعبر وأشيري للصور وسمي الأشياء. لا يحتاج الطفل لفهم القصة كاملة بل يستفيد من سماع إيقاع اللغة والتعرف على الكلمات.\n\nاستجيبي لمحاولات طفلك للتواصل بحماس وتشجيع. عندما يشير لشيء قولي اسم الشيء. عندما يصدر أصواتاً كرريها ووسعيها. مثلاً إذا قال بابا قولي نعم بابا. بابا هنا. هذا يشجعه على الاستمرار في المحاولة والتجريب. الأغاني والأناشيد المصحوبة بحركات مثل لعبة هذا أبو مساعد ممتازة لتطوير اللغة والتنسيق الحركي معاً.',
      },
    ],
    'ما قبل المشي (9-12 شهر)': [
      {
        'title': 'الخطوات الأولى: تشجيع المشي بأمان',
        'image': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=600&q=80',
        'ageMin': '270', 'ageMax': '365',
        'content': 'يبدأ معظم الأطفال بالمشي المستقل بين الشهر التاسع والخامس عشر والمدى الطبيعي واسع جداً. قبل المشي المستقل يمر الطفل بعدة مراحل تحضيرية تشمل الوقوف مستنداً على الأثاث ثم المشي الجانبي ممسكاً بالأريكة أو الطاولة ثم الوقوف لحظات قصيرة دون دعم وأخيراً خطوات مترددة بين نقطتين. كل خطوة من هذه الخطوات تقوي عضلاته وتوازنه وثقته بنفسه.\n\nلتشجيع طفلك على المشي وفري له بيئة آمنة للممارسة. ضعي أثاثاً ثابتاً يمكنه الاستناد عليه على مسافات قصيرة من بعضه ليتنقل بينها. قفي أمامه على بعد خطوة أو اثنتين وافتحي ذراعيك ليمشي نحوك. احتفي بكل محاولة حتى لو سقط لأن التشجيع يبني ثقته. الوقوع جزء طبيعي من تعلم المشي فلا تبالغي في ردة فعلك عندما يسقط.\n\nالمشي حافياً في المنزل هو الأفضل لتطوير عضلات القدم والتوازن الطبيعي. القدم الحافية تسمح للطفل بالإحساس بالسطح وتعديل توازنه بشكل أفضل من القدم المحشورة في حذاء. عند الحاجة لحذاء خارج المنزل اختاري حذاء ناعماً ومرناً بنعل رقيق لا يعيق حركة القدم الطبيعية.\n\nتجنبي المشاية التقليدية لأنها لا تساعد فعلياً على تعلم المشي بل تؤخره وتزيد خطر الحوادث كالسقوط من الدرج والوصول لأشياء خطرة. البديل الآمن هو عربة الدفع الثابتة التي يمسك بها الطفل ويدفعها أمامه لأنها تعزز التوازن وتعلمه المشي بنمط حركي صحيح. تحلي بالصبر ولا تقارني طفلك بأقرانه فكل طفل يمشي في الوقت المناسب له.',
      },
      {
        'title': 'الكلمات الأولى وتطور اللغة',
        'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=600&q=80',
        'ageMin': '270', 'ageMax': '365',
        'content': 'بحلول الشهر التاسع إلى الثاني عشر يبدأ معظم الأطفال بنطق كلماتهم الأولى الحقيقية. الكلمة الأولى تكون عادة ماما أو بابا أو كلمة بسيطة مرتبطة بشيء يحبه الطفل. في هذه المرحلة يفهم الطفل كلمات أكثر بكثير مما ينطق وقد يفهم من عشر إلى خمسين كلمة بينما ينطق كلمتين إلى خمس كلمات فقط.\n\nالطفل في هذا العمر يستخدم أيضاً التواصل غير اللفظي بمهارة متزايدة. يشير بإصبعه لما يريد ويهز رأسه رفضاً ويلوح باي باي ويصفق عندما يكون سعيداً ويرفع يديه ليُحمل. كل هذه الإيماءات مهمة جداً للتواصل وتسبق عادة الانفجار اللغوي الذي يحدث بعد عمر السنة.\n\nلتعزيز اللغة عند طفلك تحدثي معه بجمل قصيرة وواضحة واستخدمي الكلمات الحقيقية بدلاً من الكلمات المحرفة. مثلاً قولي ماء بدلاً من مامو وحليب بدلاً من لبلوب. عندما يشير لشيء سميه له وكرري الاسم عدة مرات في سياقات مختلفة. اقرئي له يومياً وأشيري للصور وسمي الحيوانات والأشياء واسأليه أين الكلب وانتظري ليشير إليه.\n\nالأغاني والأناشيد البسيطة المتكررة ممتازة لتطوير اللغة لأنها تجمع بين الإيقاع والتكرار والحركة. غنّي مع طفلك كل يوم ولا يهم جمال صوتك. التلفزيون والشاشات ليست بديلاً عن التفاعل البشري المباشر فالطفل يتعلم اللغة من خلال التفاعل الحقيقي وليس من المشاهدة. إذا لم ينطق طفلك أي كلمة بحلول عمر السنة أو لم يستجب لاسمه أو لم يشر بإصبعه فاستشيري طبيب الأطفال للتقييم.',
      },
      {
        'title': 'الفطام التدريجي ووجبات الطفل',
        'image': 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=600&q=80',
        'ageMin': '270', 'ageMax': '365',
        'content': 'مع اقتراب الطفل من عمر السنة يصبح الطعام الصلب جزءاً أساسياً من تغذيته ويمكنك البدء بتقليل عدد الرضعات تدريجياً إذا رغبتِ في الفطام. الفطام التدريجي أفضل من المفاجئ لأنه يعطي جسمك وقتاً لتقليل إنتاج الحليب ويمنح طفلك وقتاً للتكيف عاطفياً مع التغيير. ابدئي بإلغاء رضعة واحدة كل أسبوع أو اثنين واستبدليها بوجبة صلبة أو كوب حليب.\n\nفي هذه المرحلة يمكن للطفل تناول معظم أطعمة العائلة بشرط تقطيعها لقطع صغيرة مناسبة وتجنب الأطعمة التي قد تسبب الاختناق. يحتاج الطفل لثلاث وجبات رئيسية ووجبة أو وجبتين خفيفتين يومياً. كل وجبة يجب أن تحتوي على مزيج من النشويات والبروتين والخضروات والدهون الصحية.\n\nأفكار لوجبات مناسبة تشمل الأرز المسلوق مع الدجاج المفروم والخضار المطبوخة والمعكرونة الصغيرة مع صلصة الطماطم واللحم المفروم والبيض المخفوق مع الخبز المحمص وشرائح الأفوكادو والشوربة بالخضار والبقوليات والبطاطا المهروسة مع السمك المشوي المفتت. قدمي الفواكه الطازجة المقطعة والزبادي كوجبات خفيفة.\n\nبعد عمر السنة يمكنك تقديم حليب البقر الكامل الدسم كشراب لكن لا تتجاوزي أربعمئة وخمسين ملليلتراً يومياً لأن الإفراط يقلل شهية الطفل للطعام الصلب ويسبب فقر الدم. يمكنك أيضاً تقديم العسل بعد عمر السنة. استمري بتجنب المكسرات الكاملة والحلوى الصلبة والعنب الكامل وأي طعام دائري أو لزج قد يسبب الاختناق. شجعي طفلك على الأكل بنفسه باستخدام يديه وملعقة صغيرة فهذا يطور استقلاليته ومهاراته الحركية الدقيقة.',
      },
      {
        'title': 'وضع الحدود والانضباط اللطيف للطفل',
        'image': 'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4?w=600&q=80',
        'ageMin': '270', 'ageMax': '365',
        'content': 'مع اقتراب الطفل من عمر السنة يبدأ باختبار الحدود واستكشاف ردود أفعال والديه عندما يفعل أشياء غير مسموحة. هذا سلوك طبيعي وصحي يدل على نمو معرفي واستقلالية متزايدة لكنه يتطلب من الوالدين البدء بوضع حدود واضحة ومتسقة بطريقة لطيفة وحازمة في الوقت ذاته.\n\nفي هذا العمر لا يفهم الطفل مفهوم الخطأ والصواب بشكل كامل وقدرته على التحكم بدوافعه محدودة جداً. لذا فإن العقاب البدني كالضرب أو الصراخ غير فعال وضار ويزيد العناد ويؤثر سلباً على نموه النفسي والعاطفي. بدلاً من ذلك استخدمي أسلوب إعادة التوجيه أي عندما يفعل شيئاً غير مسموح حوّلي انتباهه لنشاط آخر مقبول.\n\nعندما يلمس شيئاً خطيراً أو غير مسموح قولي لا بصوت هادئ وحازم مع تعبير وجه جاد ثم أبعديه عن المكان وقدمي له بديلاً. مثلاً إذا حاول لمس الفرن قولي لا الفرن حار يؤلم ثم خذيه بعيداً وأعطيه لعبة يلعب بها. كرري هذا عشرات المرات بصبر لأن الطفل يحتاج تكراراً كثيراً ليستوعب القواعد.\n\nامدحي السلوك الإيجابي بحماس وشجعي طفلك عندما يفعل شيئاً جيداً مثل أحسنت لقد وضعت اللعبة في مكانها. التعزيز الإيجابي أكثر فعالية بكثير من التركيز على السلوك السلبي. ثبتي القواعد المنزلية البسيطة وكوني متسقة أنتِ ووالده لأن التناقض بين الوالدين يربك الطفل. تذكري أن الانضباط يعني التعليم وليس العقاب وأن طفلك في رحلة طويلة من التعلم تحتاج منك الصبر والحب والتوجيه المستمر.',
      },
    ],
    'الطفل الصغير (12-24 شهر)': [
      {
        'title': 'تطور المشي والحركة بعد السنة الأولى',
        'image': 'https://images.unsplash.com/photo-1574169208507-84376144848b?w=600&q=80',
        'ageMin': '365', 'ageMax': '730',
        'content': 'بعد الخطوات الأولى يتطور مشي الطفل بسرعة مذهلة خلال السنة الثانية من عمره. في البداية يمشي بخطوات واسعة ومترددة وذراعيه مرفوعتان للتوازن ثم تصبح خطواته أكثر ثباتاً وتقارباً وتنخفض ذراعاه تدريجياً. بحلول الشهر الثامن عشر يستطيع معظم الأطفال المشي بثقة والانحناء لالتقاط الأشياء والمشي للخلف وصعود الدرج بمساعدة.\n\nبين الشهر الثامن عشر والرابع والعشرين يبدأ الطفل بالركض والقفز بقدمين معاً وركل الكرة والصعود على الأثاث المنخفض والنزول من الدرج. هذا التطور السريع يحتاج لمساحة آمنة للممارسة واللعب الحر. خصصي وقتاً يومياً للعب في الهواء الطلق حيث يمكن للطفل الركض والتسلق والاستكشاف بحرية.\n\nلتعزيز التطور الحركي الكبير وفري ألعاباً تشجع الحركة مثل كرات بأحجام مختلفة ودراجة ثلاثية أو حصان هزاز وأنفاق للزحف وسلالم صغيرة آمنة للتسلق. اللعب بالرمل والماء يطور المهارات الحركية الدقيقة والتنسيق بين اليد والعين. ألعاب التركيب والمكعبات تقوي الأصابع وتعلم التخطيط والتفكير المنطقي.\n\nالمهارات الحركية الدقيقة تتطور أيضاً بشكل ملحوظ في هذه المرحلة. يتعلم الطفل استخدام الملعقة والكوب بنفسه والرسم بالأقلام الغليظة وتقليب صفحات الكتب وتركيب المكعبات فوق بعضها ووضع الأشكال في فتحاتها المناسبة. شجعي الاستقلالية في الأكل وارتداء الملابس حتى لو كان بطيئاً وفوضوياً لأن الممارسة هي الطريقة الوحيدة للتعلم والإتقان.',
      },
      {
        'title': 'انفجار اللغة: تطور الكلام بعد السنة',
        'image': 'https://images.unsplash.com/photo-1485546246426-74dc88dec4d9?w=600&q=80',
        'ageMin': '365', 'ageMax': '730',
        'content': 'السنة الثانية من عمر الطفل تشهد ما يُعرف بالانفجار اللغوي حيث تتضاعف مفرداته بسرعة مذهلة. عند عمر السنة ينطق الطفل من كلمتين إلى خمس كلمات وبحلول الشهر الثامن عشر يمتلك من خمسين إلى مئة كلمة وعند السنتين قد يصل مخزونه إلى مئتين إلى ثلاثمئة كلمة ويبدأ بتكوين جمل من كلمتين مثل ماما شيلي وبابا بيت وأبغى ماء.\n\nالتطور اللغوي في هذه المرحلة يشمل أيضاً فهم التعليمات البسيطة مثل هات الكرة وضع الكتاب على الطاولة. يبدأ الطفل بتسمية أجزاء الجسم والألوان والأرقام والأشكال ويسأل أسئلة بسيطة مثل إيش هذا ووين بابا. كل هذه مؤشرات صحية على تطور لغوي سليم.\n\nلتعزيز اللغة في هذه المرحلة الحرجة استمري في التحدث مع طفلك طوال اليوم بجمل كاملة وواضحة. عندما يقول كلمة واحدة وسعيها لجملة مثلاً إذا قال جوس قولي تريد عصير برتقال. هذا يسمى التوسيع ويساعد الطفل على تعلم بنية الجمل. اقرئي القصص المصورة يومياً واسألي أسئلة عن الصور ماذا يفعل الولد وأين ذهبت القطة.\n\nقللي من وقت الشاشات لأن الدراسات تظهر أن التفاعل البشري المباشر أفضل بكثير لتطوير اللغة من أي محتوى تلفزيوني مهما كان تعليمياً. وفري فرصاً للتفاعل مع أطفال آخرين لأن اللعب الاجتماعي يحفز التواصل اللغوي. إذا لم يقل طفلك خمسين كلمة على الأقل بحلول الشهر الثامن عشر أو لم يكون جملاً من كلمتين بحلول السنتين فاستشيري أخصائي نطق وتخاطب للتقييم المبكر.',
      },
      {
        'title': 'نوبات الغضب والتعامل مع مشاعر الطفل',
        'image': 'https://images.unsplash.com/photo-1509909756405-be0199881695?w=600&q=80',
        'ageMin': '365', 'ageMax': '730',
        'content': 'نوبات الغضب أو التانترم من أكثر التحديات شيوعاً في السنة الثانية والثالثة من عمر الطفل وتصيب جميع الأطفال تقريباً بدرجات متفاوتة. يصرخ الطفل ويبكي ويرمي نفسه على الأرض وأحياناً يضرب أو يعض أو يرمي الأشياء. هذا السلوك طبيعي تماماً وناتج عن عدم نضج الجزء المسؤول عن تنظيم المشاعر في دماغ الطفل وعجزه عن التعبير عن مشاعره بالكلمات.\n\nالمحفزات الشائعة لنوبات الغضب تشمل التعب والجوع والإحباط من عدم القدرة على فعل شيء ورفض طلب يريده الطفل وتغيير الروتين المعتاد والتحفيز الزائد. فهم المحفزات يساعدك على الوقاية من كثير من النوبات. تأكدي من أن طفلك يحصل على نوم كافٍ ووجبات منتظمة وروتين يومي مستقر.\n\nعند حدوث النوبة أولاً تأكدي من أن الطفل في مكان آمن. ثم ابقي هادئة ولا تصرخي أو تعاقبي لأن ذلك يزيد حدة النوبة. اجلسي بجانبه بهدوء وقولي أفهم أنك غاضب ثم انتظري حتى يهدأ. بعض الأطفال يحتاجون لعناق ثابت وآخرون يفضلون مساحة شخصية فتعلمي ما يناسب طفلك.\n\nبعد أن يهدأ تحدثي معه بلغة بسيطة عن مشاعره وسميها له مثلاً كنت غاضباً لأنك أردت الحلوى وماما قالت لا. هذا يعلمه تسمية مشاعره وهي خطوة أساسية في الذكاء العاطفي. علميه بدائل مقبولة للتعبير عن غضبه كأن يقول أنا زعلان بدلاً من الضرب. تذكري أن نوبات الغضب مرحلة مؤقتة تقل تدريجياً مع تطور قدرته على التعبير اللغوي والتحكم في مشاعره.',
      },
      {
        'title': 'الاستعداد للتدريب على الحمام',
        'image': 'https://images.unsplash.com/photo-1544776193-352d25ca82cd?w=600&q=80',
        'ageMin': '365', 'ageMax': '730',
        'content': 'التدريب على استخدام الحمام من المراحل المهمة في نمو الطفل الصغير ويبدأ معظم الأطفال بإبداء علامات الاستعداد بين الشهر الثامن عشر والثلاثين. لا يوجد عمر محدد مثالي لبدء التدريب فالأهم هو انتظار ظهور علامات الاستعداد الجسدي والنفسي والمعرفي لدى الطفل. البدء قبل الاستعداد يطيل العملية ويسبب إحباطاً للطرفين.\n\nعلامات الاستعداد الجسدي تشمل قدرة الطفل على المشي بثبات والجلوس على النونية بتوازن والبقاء جافاً لمدة ساعتين متواصلتين مما يدل على نضج المثانة والقدرة على خلع ملابسه السفلية بمساعدة بسيطة. العلامات المعرفية تشمل فهم التعليمات البسيطة والقدرة على التعبير عن الحاجة للحمام بكلمة أو إشارة.\n\nعلامات الاستعداد النفسي مهمة جداً وتشمل إبداء اهتمام بالحمام أو النونية وعدم الراحة من الحفاض المتسخ والرغبة في التقليد والاستقلالية. إذا كان طفلك يمر بتغيير كبير كولادة أخ جديد أو انتقال لمنزل جديد فمن الأفضل تأجيل التدريب حتى يستقر.\n\nللتحضير اشتري نونية مناسبة وضعيها في الحمام واسمحي للطفل بالجلوس عليها بملابسه أولاً ليألفها. اقرئي له كتباً مصورة عن استخدام الحمام. راقبي أوقات حاجته المنتظمة واقترحي عليه الجلوس على النونية بعد الوجبات وعند الاستيقاظ. لا تضغطي عليه ولا توبخيه عند الحوادث وكافئيه بالمدح والتشجيع عند النجاح. التدريب عملية تستغرق أسابيع إلى أشهر وتحتاج صبراً كبيراً وتوقعات واقعية. التبول الليلي يتأخر عادة في التحكم ومعظم الأطفال لا يكونون جافين ليلاً قبل عمر ثلاث إلى خمس سنوات.',
      },
      {
        'title': 'المهارات الاجتماعية واللعب مع الآخرين',
        'image': 'https://images.unsplash.com/photo-1587654780040-0afaa78b0443?w=600&q=80',
        'ageMin': '365', 'ageMax': '730',
        'content': 'في السنة الثانية من عمره يبدأ الطفل بالاهتمام بالأطفال الآخرين لكن مهاراته الاجتماعية لا تزال في بداياتها. في البداية يلعب بجانب الأطفال الآخرين لكن ليس معهم وهو ما يُسمى اللعب الموازي. يراقب ما يفعلونه ويقلدهم أحياناً لكنه لا يتشارك الألعاب أو يتعاون معهم بعد. هذا طبيعي تماماً في هذا العمر.\n\nمفهوم المشاركة صعب على الطفل في هذه المرحلة لأنه لا يزال يتعلم أن الأشياء موجودة حتى لو أعطاها لغيره وأنه سيستعيدها. لا تجبريه على مشاركة ألعابه فوراً بل علميه تدريجياً عبر المناوبة في اللعب مثلاً دورك ثم دوره. خصصي بعض الألعاب التي لا يحتاج لمشاركتها وقدمي ألعاباً أخرى يمكن التشارك فيها.\n\nلتطوير المهارات الاجتماعية وفري فرصاً منتظمة للتفاعل مع أطفال في نفس عمره سواء في الحديقة أو مجموعات اللعب أو زيارات الأقارب. كوني حاضرة لتوجيه التفاعلات وحل النزاعات بهدوء. علمي طفلك كيف يعبر عن مشاعره بالكلمات بدلاً من الضرب أو العض مثلاً قل لا أريد بدلاً من أن تضرب.\n\nاللعب التخيلي يبدأ في هذه المرحلة ويشمل إطعام الدمى وتحضير طعام وهمي في المطبخ الصغير والتحدث في هاتف لعبة وارتداء ملابس تنكرية. شجعي هذا النوع من اللعب لأنه يطور الإبداع والتعاطف وفهم مشاعر الآخرين ومهارات حل المشكلات. شاركي طفلك في اللعب التخيلي وانخرطي في عالمه واتبعي قيادته فهذا يقوي علاقتكما ويعزز ثقته بنفسه.',
      },
    ],
    'صحة الطفل العامة': [
      {
        'title': 'الحمى عند الرضع: متى تقلقين',
        'image': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=600&q=80',
        'ageMin': '0', 'ageMax': '730',
        'content': 'الحمى هي استجابة طبيعية من جهاز المناعة لمكافحة العدوى وهي ليست مرضاً بحد ذاتها بل عرض يدل على أن الجسم يقاوم شيئاً ما. تُعتبر درجة حرارة ثمانية وثلاثين درجة مئوية أو أكثر حمى عند الرضيع عند قياسها من تحت الإبط. استخدمي ميزان حرارة رقمي دقيق وقيسي الحرارة من تحت الإبط لمدة ثلاث دقائق أو من الأذن باستخدام ميزان أذن مخصص وتجنبي الموازين الزئبقية القديمة.\n\nللعناية بالرضيع المحموم ألبسيه ملابس قطنية خفيفة ولا تكثري من التغطية حتى لو شعر بالبرد. قدمي السوائل بكثرة سواء حليب الأم أو الماء للأطفال فوق ستة أشهر لمنع الجفاف. استخدمي كمادات فاترة وليست باردة على الجبهة والرقبة واليدين. يمكنك إعطاء الباراسيتامول المخصص للرضع حسب وزن الطفل وعمره بعد استشارة الطبيب ولا تعطي الإيبوبروفين للأطفال أقل من ستة أشهر.\n\nاتصلي بالطبيب فوراً إذا كان عمر الطفل أقل من ثلاثة أشهر وحرارته مرتفعة أو إذا استمرت الحمى أكثر من ثلاثة أيام أو تجاوزت أربعين درجة أو رافقتها أعراض مقلقة كالطفح الجلدي أو صعوبة التنفس أو الخمول الشديد أو القيء المستمر أو رفض الرضاعة أو بكاء غير معتاد أو انتفاخ اليافوخ.\n\nفي حالات نادرة قد تسبب الحمى العالية تشنجات حرارية وهي مخيفة لكنها غالباً غير خطيرة. حافظي على هدوئك وضعي الطفل على جنبه على سطح آمن ولا تضعي شيئاً في فمه واتصلي بالإسعاف. سجلي أوقات الحمى ودرجاتها والأعراض المصاحبة لمساعدة الطبيب في التشخيص.',
      },
      {
        'title': 'جدول التطعيمات الأساسية للطفل',
        'image': 'https://images.unsplash.com/photo-1578307985320-34b61a66c195?w=600&q=80',
        'ageMin': '0', 'ageMax': '730',
        'content': 'التطعيمات أو اللقاحات من أهم الإنجازات الطبية في تاريخ البشرية وهي الطريقة الأكثر فعالية لحماية طفلك من أمراض خطيرة ومهددة للحياة. تعمل اللقاحات بتعريض الجهاز المناعي لنسخة ضعيفة أو غير نشطة من الفيروس أو البكتيريا لتدريبه على التعرف عليها ومحاربتها مستقبلاً دون أن يمرض الطفل.\n\nيبدأ جدول التطعيمات منذ الولادة بلقاح الالتهاب الكبدي بي ثم لقاح السل. في الشهر الثاني يأخذ الطفل مجموعة لقاحات مهمة تشمل الخماسي الذي يحمي من الدفتيريا والتيتانوس والسعال الديكي والإنفلونزا النزلية والالتهاب الكبدي بي ولقاح شلل الأطفال الفموي ولقاح المكورات الرئوية ولقاح الروتا. تتكرر هذه الجرعات في الشهر الرابع والسادس لضمان مناعة كاملة.\n\nفي الشهر التاسع يأخذ الطفل لقاح الحصبة الأول وفي عمر السنة يأخذ لقاح الحصبة والنكاف والحصبة الألمانية المشترك ولقاح الجدري المائي ولقاح الالتهاب الكبدي أ. في عمر السنة والنصف يأخذ جرعات تنشيطية من اللقاحات السابقة. التزمي بمواعيد التطعيمات ولا تؤخريها إلا لأسباب طبية يحددها الطبيب.\n\nالآثار الجانبية الشائعة للتطعيمات تشمل ألم واحمرار وتورم مكان الحقنة وارتفاع طفيف في الحرارة وانزعاج مؤقت. هذه الأعراض طبيعية وتختفي خلال يوم أو يومين. ضعي كمادة باردة على مكان الحقنة وأعطي مسكناً حسب توصية الطبيب إذا لزم الأمر. الآثار الجانبية الخطيرة نادرة جداً وفوائد التطعيم تفوق بمراحل أي مخاطر محتملة. احتفظي بدفتر التطعيمات واصطحبيه في كل زيارة للطبيب.',
      },
      {
        'title': 'العناية ببشرة الطفل الحساسة',
        'image': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=600&q=80',
        'ageMin': '0', 'ageMax': '730',
        'content': 'بشرة الرضيع رقيقة وحساسة للغاية وأرق بعشرين إلى ثلاثين بالمئة من بشرة البالغين مما يجعلها أكثر عرضة للجفاف والتهيج والعدوى. تحتاج هذه البشرة الناعمة إلى عناية خاصة ولطيفة باستخدام منتجات مخصصة للأطفال خالية من العطور والمواد الكيميائية القاسية والأصباغ والكحول.\n\nالحمام يجب أن يكون لطيفاً ومرتين إلى ثلاث مرات أسبوعياً فقط في الأشهر الأولى لأن الاستحمام اليومي يزيل الزيوت الطبيعية ويسبب الجفاف. استخدمي ماء فاتر بدرجة حرارة سبعة وثلاثين درجة تقريباً وغسول خفيف بدون صابون. لا تتركي الطفل في الماء أكثر من عشر دقائق وجففي بشرته بلطف بالتربيت وليس الفرك.\n\nرطبي بشرة طفلك بعد كل حمام بكريم أو لوشن مرطب لطيف خاصة في فصل الشتاء عندما يكون الهواء جافاً. الإكزيما شائعة عند الرضع وتظهر كبقع حمراء متقشرة ومثيرة للحكة على الوجه والمرفقين والركبتين. استخدمي مرطباً كثيفاً عدة مرات يومياً واستشيري طبيب الأطفال لوصف كريم مناسب إذا لزم الأمر.\n\nتجنبي تعريض بشرة الطفل لأشعة الشمس المباشرة في الأشهر الستة الأولى واستخدمي ملابس قطنية فاتحة اللون تغطي الجسم وقبعة واسعة الحواف. بعد ستة أشهر يمكنك استخدام واقي شمس معدني مخصص للأطفال. اختاري حفاضات ناعمة وغيريها فور اتساخها لمنع التسلخات واستخدمي كريم حاجز يحتوي على أكسيد الزنك. اغسلي ملابس الطفل بمنظف خاص خالٍ من العطور واشطفيها جيداً.',
      },
      {
        'title': 'الأمراض الشائعة عند الأطفال وعلاجها',
        'image': 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=600&q=80',
        'ageMin': '0', 'ageMax': '730',
        'content': 'يتعرض الأطفال الصغار للعديد من الأمراض الشائعة خاصة في السنتين الأوليين أثناء بناء جهازهم المناعي. من الطبيعي أن يصاب الطفل بست إلى عشر نزلات برد سنوياً وهذا لا يعني ضعف مناعته بل يعني أن جهازه المناعي يتعلم ويتقوى مع كل إصابة.\n\nالزكام أو نزلة البرد أكثر الأمراض شيوعاً وتشمل أعراضه سيلان الأنف والعطس والسعال الخفيف وارتفاع طفيف في الحرارة. العلاج منزلي يشمل الراحة وكثرة السوائل وقطرات الماء والملح للأنف المسدود. لا تعطي أدوية البرد والسعال للأطفال أقل من ست سنوات لأنها غير فعالة وقد تكون خطيرة.\n\nالتهاب الأذن الوسطى شائع أيضاً ويسبب ألماً شديداً وبكاء متواصلاً وسحب الأذن وحمى. يحتاج عادة لمضاد حيوي يصفه الطبيب. التهاب المعدة والأمعاء يسبب إسهالاً وقيئاً وأهم ما في الأمر منع الجفاف بتقديم محلول الإرواء الفموي بكميات صغيرة ومتكررة واستمرار الرضاعة.\n\nالطفح الجلدي شائع عند الأطفال وله أسباب كثيرة منها الإكزيما وطفح الحرارة وطفح الحفاض والعدوى الفيروسية. معظمها غير خطير ويزول بالعلاج البسيط لكن استشيري الطبيب إذا كان الطفح مصحوباً بحمى أو منتشراً بسرعة أو مؤلماً. التهاب الحلق وخاصة العقدي يحتاج تشخيص الطبيب وعلاج بالمضاد الحيوي. لا تعطي أي مضاد حيوي دون وصفة طبية ولا تتوقفي عنه قبل إكمال الجرعة المحددة حتى لو تحسن الطفل.',
      },
      {
        'title': 'سلامة الطفل والإسعافات الأولية المنزلية',
        'image': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&q=80',
        'ageMin': '0', 'ageMax': '730',
        'content': 'الحوادث المنزلية من أكثر أسباب إصابات الأطفال وكثير منها يمكن الوقاية منه بالتخطيط المسبق ومعرفة أساسيات الإسعافات الأولية. جهزي حقيبة إسعافات أولية في المنزل تحتوي على ميزان حرارة رقمي ومطهر خفيف وضمادات لاصقة بأحجام مختلفة وشاش معقم ومقص طبي وملاقط وكمادات باردة وباراسيتامول مخصص للأطفال ومحلول إرواء فموي.\n\nالاختناق من أخطر الحوادث عند الأطفال. تعلمي مناورة هيمليك المخصصة للرضع وهي وضع الرضيع وجهه للأسفل على ساعدك مع دعم رأسه وتوجيه خمس ضربات خفيفة بين لوحي الكتف ثم قلبه وأعطي خمس ضغطات على الصدر. للأطفال فوق السنة استخدمي ضغطات البطن. أبعدي الأشياء الصغيرة والمكسرات والعنب الكامل والعملات المعدنية والبطاريات الصغيرة عن متناول الطفل.\n\nالحروق تحتاج تبريد المنطقة فوراً بالماء الجاري الفاتر لعشر دقائق على الأقل ثم تغطيتها بشاش نظيف. لا تضعي ثلجاً أو معجون أسنان أو زبدة على الحرق. توجهي للمستشفى إذا كان الحرق أكبر من حجم كف الطفل أو في الوجه أو اليدين أو المناطق الحساسة.\n\nالسقوط شائع جداً عند الأطفال المتحركين. إذا سقط طفلك على رأسه راقبيه بعناية لأربع وعشرين ساعة وتوجهي للطوارئ فوراً إذا فقد الوعي أو تقيأ أكثر من مرتين أو أصبح نعساناً بشكل غير طبيعي أو ظهر تورم كبير. احتفظي برقم الطوارئ ومركز السموم في مكان واضح وعلمي أي شخص يرعى طفلك أساسيات الإسعافات الأولية.',
      },
    ],
  };

  /// Returns filtered articles: age-matched categories + general health (always shown).
  Map<String, List<Map<String, String>>> _filteredArticles() {
    final result = <String, List<Map<String, String>>>{};
    for (final entry in _babyArticles.entries) {
      // Always show 'صحة الطفل العامة' regardless of age
      if (entry.key == 'صحة الطفل العامة') {
        result[entry.key] = entry.value;
        continue;
      }
      if (ageDays <= 0) {
        // If no age, show all categories
        result[entry.key] = entry.value;
        continue;
      }
      // Filter articles where ageDays falls within [ageMin, ageMax]
      final matched = entry.value.where((article) {
        final ageMin = int.tryParse(article['ageMin'] ?? '0') ?? 0;
        final ageMax = int.tryParse(article['ageMax'] ?? '730') ?? 730;
        return ageDays >= ageMin && ageDays <= ageMax;
      }).toList();
      if (matched.isNotEmpty) {
        result[entry.key] = matched;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFE91E63);
    final staticArticles = _filteredArticles();
    return StreamBuilder<QuerySnapshot>(
      stream: DynamicContentService.getArticles(section: 'baby'),
      builder: (context, dynamicSnap) {
        final dynamicArticles = (dynamicSnap.data?.docs ?? [])
            .map((doc) => DynamicContentService.docToArticle(doc))
            .toList();

        // Merge dynamic articles into categories (dynamic first)
        final merged = <String, List<Map<String, String>>>{};
        // Dynamic articles first — they show in a special category or their own
        if (dynamicArticles.isNotEmpty) {
          for (final art in dynamicArticles) {
            final cat = art['category'] ?? 'مقالات جديدة';
            merged.putIfAbsent(cat, () => []).add(art);
          }
        }
        // Then add static filtered articles
        for (final entry in staticArticles.entries) {
          merged.putIfAbsent(entry.key, () => []);
          merged[entry.key]!.addAll(entry.value);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Age-specific header
            if (ageDays > 0) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [color.withOpacity(0.08), const Color(0xFF00897B).withOpacity(0.06)]),
                ),
                child: Row(children: [
                  const Icon(Icons.child_care, color: Color(0xFFE91E63), size: 20),
                  const SizedBox(width: 8),
                  Text('مقالات مناسبة لعمر $_ageLabel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                ]),
              ),
            ],
            ...merged.entries.map((entry) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.auto_stories, color: color, size: 22),
                SizedBox(width: 8),
                Text(entry.key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.withOpacity(0.85))),
              ]),
              SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: entry.value.length,
                  itemBuilder: (_, i) {
                    final d = entry.value[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ArticleDetailPage(title: d['title']!, body: d['content']!, color: color, imageUrl: d['image']!, section: 'baby'))),
                      child: Container(
                        width: 200, margin: EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white, boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 3))]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(d['image']!, height: 110, width: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 110, color: color.withOpacity(0.1), child: Icon(Icons.article, color: color, size: 40)))),
                          Padding(padding: EdgeInsets.all(10), child: Text(d['title']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
            ]);
          }),
          ],
        );
      },
    );
  }
}



class _HomeArticlesSection extends StatelessWidget {
  static const _articles = <Map<String, String>>[
    {'title': 'الأطعمة المفيدة للحامل', 'category': 'تغذية وجمال', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
     'content': 'تعتبر التغذية السليمة من أهم الركائز التي تضمن صحة الأم والجنين طوال فترة الحمل. يحتاج جسم المرأة الحامل إلى عناصر غذائية متنوعة تشمل البروتينات والفيتامينات والمعادن الأساسية مثل الحديد والكالسيوم وحمض الفوليك. احرصي على تناول الخضروات الورقية الداكنة كالسبانخ والبروكلي والفواكه الطازجة كالبرتقال والموز والتفاح والحبوب الكاملة والبقوليات يومياً. تجنبي الأطعمة المصنعة والمشروبات الغازية واستبدليها بالعصائر الطبيعية والماء.  الحديد من أهم المعادن خلال الحمل لأنه يساعد في تكوين الهيموغلوبين الذي ينقل الأكسجين إلى الجنين. تجدينه في اللحوم الحمراء والعدس والفاصوليا والسبانخ. يُفضل تناول مصادر الحديد مع فيتامين سي لتحسين امتصاصه كأن تضيفي عصير الليمون إلى طبق العدس. الكالسيوم ضروري لبناء عظام الجنين وأسنانه ويتوفر في الحليب والزبادي والجبن والسمسم واللوز.  حمض الفوليك يحمي الجنين من تشوهات الأنبوب العصبي ويوجد في الخضروات الورقية والبقوليات والحمضيات. يوصي الأطباء بتناول مكمل حمض الفوليك قبل الحمل وخلال الثلث الأول على الأقل. أحماض أوميغا 3 تساعد في نمو دماغ الجنين وتتوفر في الأسماك الدهنية كالسلمون والسردين وبذور الكتان والجوز.  تجنبي الأسماك العالية بالزئبق كسمك أبو سيف والماكريل الكبير. ابتعدي عن الأجبان الطرية غير المبسترة واللحوم النيئة والبيض غير المطبوخ جيداً. قللي من الكافيين إلى أقل من مائتي ملليغرام يومياً أي ما يعادل فنجان قهوة واحد. نظمي وجباتك على خمس إلى ست وجبات صغيرة بدل ثلاث كبيرة لتجنب الغثيان والحموضة. استشيري أخصائية تغذية لوضع خطة غذائية مناسبة لاحتياجاتك الخاصة وتأكدي من تناول المكملات التي يصفها طبيبك بانتظام.'},
    {'title': 'المشي أثناء الحمل', 'category': 'رياضة ولياقة', 'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
     'content': 'يُعد المشي من أفضل التمارين وأكثرها أماناً خلال فترة الحمل لأنه لا يتطلب معدات خاصة ويمكن ممارسته في أي وقت ومكان. فهو يساعد على تحسين الدورة الدموية وتقوية عضلات الحوض والساقين وتخفيف آلام الظهر والتورم. ابدئي بالمشي لمدة عشر دقائق يومياً ثم زيدي تدريجياً حتى ثلاثين دقيقة. اختاري أحذية مريحة وأماكن مسطحة وآمنة وتجنبي الحرارة الشديدة.  يساعد المشي المنتظم على تنظيم الوزن خلال الحمل ويقلل من خطر الإصابة بسكري الحمل وارتفاع ضغط الدم. كما يحسن المزاج ويقلل التوتر والقلق بفضل إفراز هرمونات السعادة الطبيعية كالإندورفين. أظهرت الدراسات أن الحوامل اللواتي يمارسن المشي بانتظام يتعافين أسرع بعد الولادة ويعانين أقل من اكتئاب ما بعد الولادة.  في الثلث الأول يمكنك المشي بوتيرة طبيعية مع الحرص على الترطيب الكافي. في الثلث الثاني قد تشعرين بمزيد من الطاقة فاستغلي ذلك لزيادة مدة المشي تدريجياً. في الثلث الأخير خففي السرعة واستمعي لجسمك وتوقفي عند الشعور بأي ألم أو تعب شديد أو دوخة أو ضيق تنفس.  احرصي على ارتداء ملابس فضفاضة ومريحة من القطن وحذاء رياضي بدعم جيد للكاحل والقوس. احملي معك زجاجة ماء واشربي قبل وأثناء وبعد المشي. تجنبي المشي في الأوقات الحارة واختاري الصباح الباكر أو المساء. إذا كنت تعانين من مضاعفات كالمشيمة المنزاحة أو تهديد بالولادة المبكرة فاستشيري طبيبتك قبل ممارسة أي نشاط رياضي. المشي مع صديقة أو زوجك يجعل التجربة أكثر متعة والتزاماً.'},
    {'title': 'يوغا الحوامل', 'category': 'رياضة ولياقة', 'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&q=80',
     'content': 'تساعد يوغا الحوامل على تحسين المرونة والتوازن وتخفيف التوتر والقلق المصاحب لفترة الحمل. تركز تمارين اليوغا المخصصة للحوامل على التنفس العميق وتقوية عضلات الحوض والظهر والتحضير الجسدي والنفسي للولادة. مارسي اليوغا في بيئة هادئة ومريحة واستخدمي الوسائد الداعمة. تجنبي الوضعيات التي تتطلب الاستلقاء على البطن أو التوازن الصعب أو الانحناء العميق.  من أهم فوائد يوغا الحوامل تقوية عضلات قاع الحوض التي تدعم الرحم والمثانة والأمعاء. هذه العضلات تتعرض لضغط كبير خلال الحمل وتقويتها يسهل عملية الولادة الطبيعية ويسرع التعافي بعدها. كما تساعد اليوغا على تخفيف آلام أسفل الظهر والوركين والشعور بالثقل في الحوض من خلال تمارين الإطالة اللطيفة.  تقنيات التنفس في اليوغا مفيدة جداً أثناء المخاض لأنها تعلمك كيف تتحكمين في تنفسك خلال الانقباضات. التنفس البطني العميق يهدئ الجهاز العصبي ويقلل الإحساس بالألم ويمنحك شعوراً بالسيطرة. مارسي تمرين التنفس المربع وهو الشهيق لأربع ثوانٍ والحبس لأربع ثوانٍ والزفير لأربع ثوانٍ والانتظار لأربع ثوانٍ.  ابدئي بحصص قصيرة مدتها خمس عشرة دقيقة ثم زيدي تدريجياً. اختاري مدربة متخصصة في يوغا الحوامل أو اتبعي فيديوهات موثوقة. الوضعيات الآمنة تشمل وضعية القطة والبقرة لتخفيف آلام الظهر ووضعية الفراشة لفتح الوركين ووضعية الطفل المعدلة للاسترخاء. تجنبي اليوغا الساخنة والحركات المفاجئة والوضعيات المقلوبة. إذا شعرت بأي ألم أو دوخة توقفي فوراً واستشيري طبيبتك.'},
    {'title': 'القلق من الولادة', 'category': 'صحة نفسية', 'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&q=80',
     'content': 'من الطبيعي أن تشعري ببعض القلق مع اقتراب موعد الولادة لكن المهم ألا يسيطر هذا القلق على حياتك اليومية ويمنعك من الاستمتاع بتجربة الحمل. تحدثي مع طبيبتك بصراحة عن مخاوفك واطلبي المعلومات الكافية عن مراحل الولادة لأن المعرفة تقلل الخوف من المجهول. مارسي تقنيات الاسترخاء والتنفس العميق يومياً واحاطي نفسك بأشخاص إيجابيين يدعمونك.  يُعرف القلق الشديد من الولادة طبياً بالتوكوفوبيا ويصيب نسبة ملحوظة من النساء خاصة في الحمل الأول. أعراضه تشمل كوابيس متكررة عن الولادة وتجنب الحديث عنها وأفكار وسواسية عن المضاعفات. إذا كان قلقك يؤثر على نومك أو شهيتك أو علاقاتك فمن المهم طلب المساعدة المتخصصة من أخصائية نفسية.  من أفضل الطرق للتغلب على القلق حضور دورات تحضيرية للولادة حيث تتعلمين مراحل المخاض والتعامل مع الألم وتقنيات التنفس والدفع. التعرف على قصص ولادة إيجابية من صديقات أو مجموعات دعم يساعد كثيراً في تغيير تصوراتك. ضعي خطة ولادة مرنة تناقشينها مع طبيبتك تشمل تفضيلاتك لكن كوني منفتحة على التغييرات.  التأمل الموجه والتخيل الإيجابي تقنيات فعالة جداً. تخيلي ولادة سلسة وآمنة وركزي على لحظة حمل طفلك لأول مرة. اكتبي مخاوفك في دفتر ثم اكتبي بجانب كل مخاوف حلاً منطقياً أو حقيقة مطمئنة. تذكري أن جسمك مصمم للولادة وأن الطب الحديث يوفر خيارات عديدة لتخفيف الألم. أحيطي نفسك بالدعم وثقي بنفسك وبفريقك الطبي.'},
    {'title': 'العناية بالبشرة', 'category': 'تغذية وجمال', 'image': 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80',
     'content': 'تتعرض بشرة المرأة الحامل لتغيرات كثيرة بسبب التقلبات الهرمونية مثل ظهور الكلف والبقع الداكنة وحب الشباب وعلامات التمدد والجفاف. استخدمي واقي شمس آمن بعامل حماية لا يقل عن ثلاثين يومياً ورطبي بشرتك بكريمات خالية من المواد الكيميائية الضارة. اشربي كمية كافية من الماء لا تقل عن ثمانية أكواب يومياً وتناولي الأطعمة الغنية بفيتامين سي وأحماض أوميغا 3.  الكلف أو قناع الحمل يظهر كبقع بنية على الوجه خاصة الجبين والخدين وأعلى الشفة. أهم وسيلة للوقاية هي الحماية من الشمس بارتداء قبعة واسعة واستخدام واقي شمس معدني يحتوي على أكسيد الزنك أو ثاني أكسيد التيتانيوم. تجنبي واقيات الشمس الكيميائية خلال الحمل واختاري منتجات خالية من الأوكسيبنزون والريتينول.  علامات التمدد تظهر عادة في البطن والصدر والأرداف والفخذين. رطبي هذه المناطق يومياً بزيت جوز الهند أو زبدة الشيا أو كريم يحتوي على فيتامين إي وزبدة الكاكاو. ابدئي الترطيب من بداية الحمل ودلكي بحركات دائرية لتحسين مرونة الجلد. الترطيب لن يمنع علامات التمدد تماماً لكنه يقلل شدتها.  نظفي بشرتك بغسول لطيف خالٍ من الكحول مرتين يومياً. تجنبي منتجات حب الشباب القوية كحمض الساليسيليك المركز والريتينويدات والبنزويل بيروكسيد بتركيز عالٍ. استخدمي بدائل آمنة كحمض الأزيليك وحمض الجليكوليك بتركيزات منخفضة. استشيري طبيبة جلدية إذا تفاقمت مشاكل بشرتك لأن بعض العلاجات تحتاج وصفة طبية آمنة للحمل.'},
    {'title': 'تحضير حقيبة المولود', 'category': 'أمومة وطفولة', 'image': 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400&q=80',
     'content': 'يُنصح بتجهيز حقيبة الولادة في الشهر الثامن تحسباً لأي طارئ قد يستدعي التوجه للمستشفى قبل الموعد المتوقع. جهزي ملابس مريحة لك وللمولود وأغراض النظافة الشخصية والمستندات الطبية اللازمة. لا تنسي ملابس قطنية ناعمة للطفل وحفاضات وبطانية دافئة. احتفظي بالحقيبة في مكان يسهل الوصول إليه وأخبري زوجك وأفراد عائلتك بمكانها.  أغراض الأم تشمل قميص نوم مفتوح من الأمام للرضاعة ورداء حمام مريح وملابس داخلية قطنية واسعة وفوط صحية كبيرة لما بعد الولادة. خذي شبشب مريح وجوارب دافئة لأن غرف المستشفى قد تكون باردة. لا تنسي أدوات النظافة الشخصية كفرشاة الأسنان والمعجون والشامبو والصابون ومزيل العرق ومرطب الشفاه.  أغراض المولود تشمل ثلاث إلى خمس بدلات قطنية داخلية وملابس خارجية مناسبة للطقس وقبعة صغيرة وجوارب وقفازات لمنع الخدش وبطانية ناعمة وحفاضات لحديثي الولادة ومناديل مبللة خالية من العطور وكريم الحفاضات. جهزي أيضاً مقعد السيارة للأطفال لأنه إلزامي لنقل المولود بأمان.  المستندات المطلوبة تشمل البطاقة الصحية للأم وتقارير المتابعة الطبية والتحاليل والأشعات والتأمين الصحي إن وجد وبطاقة الهوية. خذي شاحن الهاتف وكاميرا لتصوير اللحظات الأولى مع طفلك. بعض الأمهات يأخذن وسادة مريحة خاصة ووجبات خفيفة وماء. ضعي قائمة مكتوبة بجانب الحقيبة بالأشياء التي لا يمكن تجهيزها مسبقاً كالهاتف والنظارات والأدوية اليومية لتتذكريها وقت الخروج.'},
    {'title': 'دور الأب أثناء الحمل', 'category': 'علاقات أسرية', 'image': 'https://images.unsplash.com/photo-1531983412531-1f49a365ffed?w=400&q=80',
     'content': 'دور الأب لا يبدأ بعد الولادة بل يبدأ من اللحظة الأولى لمعرفة خبر الحمل. يمكن للأب المشاركة في مواعيد الطبيب والتعرف على مراحل نمو الجنين وتقديم الدعم العاطفي والعملي لزوجته. ساعد في الأعمال المنزلية ورافقها في المشي وكن صبوراً مع تقلبات مزاجها الطبيعية الناتجة عن التغيرات الهرمونية خلال هذه الفترة الحساسة.  المشاركة في المواعيد الطبية من أهم الأشياء التي يمكن للأب فعلها لأنها تظهر الاهتمام وتتيح له فهم ما يحدث طبياً. حضور جلسة السونار ورؤية الجنين وسماع نبضه تجربة مؤثرة تقوي الرابطة بين الأب وطفله قبل ولادته. اطرح الأسئلة على الطبيب ودوّن الملاحظات لتكون مرجعاً لكما معاً.  الدعم العاطفي يعني الاستماع لمخاوف زوجتك دون التقليل منها والتعبير عن حبك وامتنانك لما تتحمله. تعلم عن أعراض الحمل المختلفة في كل ثلث لتفهم ما تمر به. في الثلث الأول قد تعاني من غثيان وإرهاق شديد فساعدها في المطبخ والتنظيف. في الثلث الأخير قد تعاني من أرق وآلام ظهر فدلك ظهرها وساعدها على إيجاد وضعية نوم مريحة.  شارك في تحضيرات الاستقبال كاختيار اسم المولود وتجهيز غرفته وشراء المستلزمات. احضر دورة تحضيرية للولادة معها لتعرف كيف تدعمها خلال المخاض. تعلم أساسيات رعاية المولود كتغيير الحفاض والحمام والتجشؤ. حضورك ومشاركتك يمنحها الثقة والأمان ويبني علاقة أبوية قوية من البداية تستمر مدى الحياة.'},
    {'title': 'فحوصات الثلث الأول', 'category': 'نصائح طبية', 'image': 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&q=80',
     'content': 'يشمل الثلث الأول من الحمل من الأسبوع الأول حتى الثالث عشر فحوصات أساسية مهمة لصحة الأم والجنين. تبدأ هذه الفحوصات بتحليل الدم الشامل وفصيلة الدم وعامل ريسوس وفحص السكري ووظائف الغدة الدرقية والكبد والكلى. يُجرى أول سونار عادة بين الأسبوع السادس والثامن لتأكيد الحمل وسماع نبض الجنين وتحديد عمره بدقة. التزمي بمواعيد الفحوصات واسألي طبيبتك عن أي شيء يقلقك.  تحليل الدم الشامل يكشف عن فقر الدم الذي يصيب كثيراً من الحوامل بسبب زيادة حجم الدم. إذا كان مستوى الهيموغلوبين منخفضاً ستصف لك الطبيبة مكملات الحديد. فحص فصيلة الدم وعامل ريسوس مهم لأنه إذا كانت فصيلتك سالبة وفصيلة الأب موجبة فقد تحتاجين حقنة خاصة لمنع تكوين أجسام مضادة تؤثر على الجنين.  فحص الأمراض المعدية يشمل التهاب الكبد بي وسي وفيروس نقص المناعة والزهري والحصبة الألمانية وداء القطط. هذه الفحوصات ضرورية لأن بعض هذه الأمراض يمكن أن تنتقل للجنين وتسبب مضاعفات خطيرة لكن اكتشافها المبكر يتيح العلاج أو الوقاية.  بين الأسبوع الحادي عشر والرابع عشر يُجرى فحص الشفافية القفوية بالسونار مع تحليل دم لتقييم خطر المتلازمات الكروموسومية كمتلازمة داون. هذا فحص تقييمي وليس تشخيصياً وإذا كانت النتائج مقلقة فقد تُعرض عليك فحوصات إضافية كبزل السائل الأمنيوسي. ناقشي مع طبيبتك كل فحص وأهميته وخياراتك المتاحة واتخذي قراراتك بناء على معلومات واضحة.'},
    {'title': 'السباحة للحامل', 'category': 'رياضة ولياقة', 'image': 'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=400&q=80',
     'content': 'السباحة من أفضل الرياضات للحامل لأن الماء يدعم وزن الجسم ويخفف الضغط على المفاصل والعمود الفقري مما يمنحك شعوراً بالخفة والراحة. تساعد السباحة على تحسين اللياقة القلبية والتنفسية وتقليل التورم في الساقين وتخفيف آلام الظهر. اختاري حمام سباحة نظيفاً ومارسي السباحة بوتيرة معتدلة لمدة عشرين إلى ثلاثين دقيقة ثلاث مرات أسبوعياً.  يوفر الماء بيئة تدريب مثالية للحامل لأن الطفو يقلل الوزن المحسوس بنسبة تسعين بالمئة مما يسمح بحرية الحركة دون إجهاد. هذا يجعل السباحة مناسبة حتى في الثلث الأخير عندما تصبح معظم التمارين الأخرى صعبة. الماء البارد يساعد أيضاً على تقليل التورم في الكاحلين والقدمين وتحسين الدورة الدموية.  من فوائد السباحة تقوية عضلات الذراعين والساقين والظهر والبطن دون إجهاد المفاصل. كما تحسن القدرة على التحمل وتعد الجسم لمجهود الولادة. السباحة نشاط هوائي يحسن كفاءة القلب والرئتين ويساعد على تنظيم الوزن والتحكم في سكر الدم. الأثر النفسي إيجابي أيضاً لأن السباحة تقلل التوتر وتحسن النوم وتمنح شعوراً بالإنجاز والنشاط.  ابدئي بالإحماء ببطء واسبحي بوتيرة يمكنك فيها التحدث بشكل طبيعي. تجنبي السباحة على ظهرك بعد الأسبوع العشرين لأن وزن الرحم قد يضغط على الوريد الأجوف. لا تقفزي في الماء ولا تسبحي في مياه ساخنة تتجاوز اثنتين وثلاثين درجة. ارتدي مايوه مريح للحوامل واستخدمي نظارات سباحة لتجنب تهيج العينين. توقفي فوراً إذا شعرت بدوخة أو ضيق تنفس أو ألم.'},
    {'title': 'فحص السونار التفصيلي', 'category': 'نصائح طبية', 'image': 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=400&q=80',
     'content': 'يُجرى السونار التفصيلي عادة بين الأسبوع الثامن عشر والعشرين من الحمل ويُعد من أهم فحوصات الحمل وأكثرها شمولاً. يفحص الطبيب أعضاء الجنين بالتفصيل بما في ذلك الدماغ والقلب والكليتين والكبد والمعدة والعمود الفقري والأطراف. يقيّم أيضاً نمو الجنين ووزنه ووضع المشيمة وكمية السائل الأمنيوسي وطول عنق الرحم. هذا الفحص فرصة جميلة لرؤية طفلك ومعرفة جنسه إن رغبت في ذلك.  يستغرق الفحص عادة من عشرين إلى أربعين دقيقة حسب وضعية الجنين وتعاونه. قد يُطلب منك شرب كمية من الماء قبل الفحص لامتلاء المثانة مما يساعد في الحصول على صور أوضح. يستخدم الطبيب محول طاقة على بطنك مع هلام مائي ويحرك الجهاز لفحص كل عضو ومنطقة بعناية.  يركز الفحص على القلب بشكل خاص لأن عيوب القلب الخلقية من أكثر التشوهات شيوعاً. يتحقق الطبيب من أن القلب يحتوي على أربع حجرات وأن الصمامات تعمل بشكل طبيعي وأن الأوعية الدموية الكبرى في مكانها الصحيح. كما يفحص الدماغ للتأكد من تطور البنى الأساسية والعمود الفقري للتأكد من إغلاق الأنبوب العصبي بالكامل.  إذا اكتشف الطبيب أي شيء يحتاج متابعة فلا تقلقي فوراً لأن كثيراً من الملاحظات تكون طبيعية أو تحتاج فقط فحصاً إضافياً للتأكد. اسألي طبيبتك عن كل ما تودين معرفته واطلبي صوراً تذكارية لطفلك. بعض المستشفيات توفر سونار ثلاثي ورباعي الأبعاد يمنح صوراً أكثر وضوحاً لملامح الجنين. سجلي موعد الفحص القادم واحتفظي بنتائج الفحص في ملفك الطبي.'},
    {'title': 'فوائد الأسماك للحامل', 'category': 'تغذية وجمال', 'image': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400&q=80',
     'content': 'الأسماك مصدر ممتاز لأحماض أوميغا 3 الدهنية الضرورية لنمو دماغ الجنين وتطور جهازه العصبي. يوصي الخبراء بتناول حصتين إلى ثلاث حصص أسبوعياً من الأسماك منخفضة الزئبق كالسلمون والسردين والتونة الخفيفة المعلبة والروبيان.\n\nتجنبي الأسماك عالية الزئبق كسمك أبو سيف والقرش والماكريل الكبير. تأكدي من طهي السمك جيداً وتجنبي السوشي والأسماك النيئة. السلمون المشوي مع الخضروات وجبة مثالية توفر البروتين وأوميغا 3 والحديد. إذا كنتِ لا تحبين السمك يمكنك تناول مكمل زيت السمك بعد استشارة طبيبتك.'},
    {'title': 'تغذية الشهور الأخيرة', 'category': 'تغذية وجمال', 'image': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400&q=80',
     'content': 'في الثلث الأخير من الحمل يزداد احتياجك للسعرات الحرارية بنحو ثلاثمئة سعرة إضافية يومياً لدعم النمو السريع للجنين. ركزي على الأطعمة الغنية بالحديد والكالسيوم والبروتين لبناء مخزون صحي قبل الولادة والرضاعة.\n\nتناولي وجبات صغيرة ومتكررة لتجنب الحموضة والانتفاخ. أكثري من الألياف والسوائل لمنع الإمساك الشائع في هذه الفترة. التمر مفيد في الأسابيع الأخيرة وقد أشارت دراسات إلى أنه يسهل الولادة. احرصي على شرب ثمانية إلى عشرة أكواب ماء يومياً.'},
    {'title': 'اكتئاب ما بعد الولادة', 'category': 'صحة نفسية', 'image': 'https://images.unsplash.com/photo-1493836512294-502baa1986e2?w=400&q=80',
     'content': 'اكتئاب ما بعد الولادة يصيب واحدة من كل سبع أمهات ويختلف عن الكآبة النفاسية العابرة التي تصيب أغلب الأمهات في الأيام الأولى. الأعراض تشمل حزناً شديداً مستمراً وبكاءً متكرراً وعدم الرغبة في العناية بالطفل وأرقاً حتى عندما ينام الطفل وشعوراً بالذنب والعجز.\n\nلا تخجلي من طلب المساعدة فهذا ليس ضعفاً بل حالة طبية تحتاج علاجاً. تحدثي مع طبيبتك أو أخصائية نفسية. الدعم الأسري مهم جداً. العلاج يشمل المتابعة النفسية وأحياناً أدوية آمنة أثناء الرضاعة. معظم الأمهات يتعافين تماماً مع العلاج المناسب.'},
    {'title': 'التعامل مع الأرق أثناء الحمل', 'category': 'صحة نفسية', 'image': 'https://images.unsplash.com/photo-1515894203077-9cd36032142f?w=400&q=80',
     'content': 'الأرق من أكثر الشكاوى شيوعاً في الحمل خاصة في الثلث الأخير بسبب كبر حجم البطن والحاجة المتكررة للتبول وحرقة المعدة والقلق من الولادة. نامي على جانبك الأيسر مع وسادة بين ركبتيك وأخرى تحت بطنك.\n\nتجنبي الشاشات قبل النوم بساعة واستبدليها بالقراءة أو التأمل. خذي حماماً دافئاً واشربي كوب حليب دافئ. مارسي تمارين التنفس العميق والاسترخاء التدريجي للعضلات. لا تتناولي وجبات ثقيلة قبل النوم وقللي السوائل مساءً لتقليل الاستيقاظ للتبول.'},
    {'title': 'تجهيز غرفة المولود', 'category': 'أمومة وطفولة', 'image': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=400&q=80',
     'content': 'تجهيز غرفة المولود من أجمل مراحل الاستعداد للأمومة. اختاري سرير أطفال يلبي معايير السلامة الحديثة بمسافات بين القضبان لا تتجاوز ستة سنتيمترات ومرتبة مناطبقة تماماً لحجم السرير دون فراغات.\n\nاختاري ألوان هادئة للغرفة وستائر معتمة للنوم النهاري. وفري طاولة تغيير الحفاض بحواجز جانبية وأدراج تخزين قريبة. كرسي مريح للرضاعة ضروري. اجعلي الإضاءة خافتة ليلاً باستخدام ضوء ليلي خافت. تأكدي من سلامة المقابس والستائر وثبتي الأثاث على الجدران.'},
    {'title': 'الرضاعة الطبيعية: البداية الصحيحة', 'category': 'أمومة وطفولة', 'image': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=400&q=80',
     'content': 'الرضاعة الطبيعية تحتاج صبراً وممارسة وأول أسبوعين هما الأصعب. ابدئي بإرضاع طفلك خلال الساعة الأولى بعد الولادة للاستفادة من اللبأ الغني بالأجسام المضادة. تأكدي من إمساك الطفل الصحيح بالثدي حيث يغطي فمه الحلمة والهالة.\n\nأرضعي كل ساعتين إلى ثلاث ساعات ولا تنتظري بكاء الطفل. راقبي علامات الشبع كاسترخاء اليدين وتوقف المص. اشربي سوائل كافية وتناولي غذاءً متوازناً. استشيري أخصائية رضاعة إذا واجهتِ صعوبة في الإمساك أو ألماً شديداً. ست حفاضات مبللة يومياً بعد اليوم الرابع تدل على كفاية الحليب.'},
    {'title': 'التواصل مع الجنين', 'category': 'علاقات أسرية', 'image': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=400&q=80',
     'content': 'يمكنك بناء علاقة عاطفية مع طفلك قبل ولادته من خلال التحدث معه والغناء له وقراءة القصص بصوت عالٍ. الجنين يسمع الأصوات من الأسبوع الثامن عشر تقريباً ويتعرف على صوت أمه وأبيه ويستجيب لهما بعد الولادة.\n\nضعي يدك على بطنك وتحدثي مع طفلك عن يومك واحكي له عن أفراد العائلة الذين ينتظرونه. الموسيقى الهادئة تريح الجنين وتحفز نمو دماغه. شجعي الأب على التحدث للبطن أيضاً. تدليك البطن بحركات دائرية لطيفة يعزز الترابط ويهدئ الجنين عند حركته الزائدة.'},
    {'title': 'التغيرات الجسدية في كل ثلث', 'category': 'نصائح طبية', 'image': 'https://images.unsplash.com/photo-1457342813143-a1ae27a5e890?w=400&q=80',
     'content': 'جسمك يتغير بشكل مذهل خلال الحمل ومعرفة هذه التغيرات يساعدك على التعامل معها بثقة. في الثلث الأول تشعرين بالغثيان والإرهاق وتورم الثديين بسبب ارتفاع الهرمونات. البطن لا يظهر بعد لكن الرحم يبدأ بالنمو.\n\nفي الثلث الثاني تتحسن الطاقة ويبدأ البطن بالبروز وتشعرين بحركة الجنين. قد تظهر خطوط التمدد والكلف وآلام الظهر. في الثلث الأخير يكبر البطن بشكل ملحوظ وتزداد الحاجة للتبول والحموضة وصعوبة النوم. انقباضات براكستون هيكس التدريبية طبيعية. استمتعي بكل مرحلة فكل تغيير يقربك من لقاء طفلك.'},
    {'title': 'متى تتصلين بالطبيبة فوراً', 'category': 'نصائح طبية', 'image': 'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?w=400&q=80',
     'content': 'رغم أن معظم الحمل يمر بسلام هناك علامات تحذيرية تستدعي الاتصال بطبيبتك أو التوجه للطوارئ فوراً. نزيف مهبلي بأي كمية خاصة في الثلث الأول والأخير وتسرب سائل مائي من المهبل وانخفاض ملحوظ في حركة الجنين.\n\nعلامات أخرى تشمل صداع شديد مع تغيرات في الرؤية وتورم مفاجئ في الوجه واليدين وألم شديد في البطن لا يزول وحمى أعلى من ثمان وثلاثين درجة وحرقة أو ألم عند التبول. ثقي بغريزتك وإذا شعرت بأن شيئاً غير طبيعي لا تترددي في الاتصال حتى لو كان الوقت متأخراً.'},
  ];

  static const _categories = <Map<String, dynamic>>[
    {'name': 'تغذية وجمال', 'icon': IconData(59651, fontFamily: 'MaterialIcons'), 'color': 0xFF9C27B0},
    {'name': 'رياضة ولياقة', 'icon': IconData(57754, fontFamily: 'MaterialIcons'), 'color': 0xFFFF9800},
    {'name': 'صحة نفسية', 'icon': IconData(61261, fontFamily: 'MaterialIcons'), 'color': 0xFF009688},
    {'name': 'أمومة وطفولة', 'icon': IconData(57534, fontFamily: 'MaterialIcons'), 'color': 0xFF2196F3},
    {'name': 'علاقات أسرية', 'icon': IconData(59020, fontFamily: 'MaterialIcons'), 'color': 0xFF3F51B5},
    {'name': 'نصائح طبية', 'icon': IconData(58674, fontFamily: 'MaterialIcons'), 'color': 0xFFF44336},
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: DynamicContentService.getArticles(section: 'home'),
      builder: (context, dynamicSnap) {
        // Merge dynamic (Firestore) + static articles, dynamic first
        final dynamicArticles = (dynamicSnap.data?.docs ?? [])
            .map((doc) => DynamicContentService.docToArticle(doc))
            .toList();

        final allArticles = [...dynamicArticles, ..._articles];

        // Group by category
        final grouped = <String, List<Map<String, String>>>{};
        for (final art in allArticles) {
          grouped.putIfAbsent(art['category']!, () => []).add(art);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مقالات ونصائح', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1F1A20))),
            SizedBox(height: 4),
            Text('آخر المقالات في مختلف المجالات', style: TextStyle(fontSize: 14, color: const Color(0xFF8B8190))),
            SizedBox(height: 16),
            for (final catInfo in _categories)
              if (grouped.containsKey(catInfo['name']))
                _buildHomeSection(
                  context,
                  catInfo['name'] as String,
                  catInfo['icon'] as IconData,
                  Color(catInfo['color'] as int),
                  grouped[catInfo['name']]!,
                ),
          ],
        );
      },
    );
  }

  Widget _buildHomeSection(BuildContext context, String title, IconData icon, Color color, List<Map<String, String>> articles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1F1A20)))),
        ]),
        SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            padding: EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, i) {
              final art = articles[i];
              final imgUrl = art['image'] ?? '';
              final articleTitle = art['title'] ?? '';
              final content = art['content'] ?? '';
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => _ArticleDetailPage(
                    title: articleTitle, body: content, color: color,
                    imageUrl: imgUrl, contentImages: const [], section: 'home',
                  ),
                )),
                child: Container(
                  width: 200, margin: EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.15)),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.network(imgUrl, height: 120, width: 200, fit: BoxFit.cover,
                        loadingBuilder: (c, child, progress) => progress == null ? child
                          : Container(height: 120, width: 200, color: color.withOpacity(0.05),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: color))),
                        errorBuilder: (c, e, s) => Container(height: 120, width: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
                          ),
                          child: Icon(icon, size: 40, color: color.withOpacity(0.4)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(articleTitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1F1A20), height: 1.3)),
                          SizedBox(height: 4),
                          Expanded(child: Text(content, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: const Color(0xFF8B8190), height: 1.4))),
                        ]),
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}

// ==================== ARTICLE DETAIL PAGE ====================
class _ArticleDetailPage extends StatefulWidget {
  final String title;
  final String body;
  final Color color;
  final String imageUrl;
  final List<String> contentImages;
  final String? articleId; // Firestore override key
  final String section; // e.g. 'home', 'cycle', 'baby', 'pregnancy', 'news'
  const _ArticleDetailPage({required this.title, required this.body, required this.color, this.imageUrl = '', this.contentImages = const [], this.articleId, this.section = ''});

  @override
  State<_ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<_ArticleDetailPage> {
  final AdminService _admin = AdminService();
  final ImagePicker _picker = ImagePicker();
  late String _title;
  late String _body;
  late String _imageUrl;
  bool _isEditing = false;
  bool _hasOverride = false;
  bool _isUploading = false;
  Uint8List? _pickedImageBytes; // preview for picked image
  XFile? _pickedImageFile;
  Uint8List? _pickedContentImageBytes;
  XFile? _pickedContentImageFile;
  String _contentImageUrl = '';
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _contentImageCtrl;

  String get _docId => widget.articleId ?? widget.title.hashCode.toString();

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _body = widget.body;
    _imageUrl = widget.imageUrl;
    _titleCtrl = TextEditingController(text: _title);
    _bodyCtrl = TextEditingController(text: _body);
    _imageCtrl = TextEditingController(text: _imageUrl);
    _contentImageCtrl = TextEditingController();
    _loadOverride();
  }

  Future<void> _loadOverride() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('article_overrides')
          .doc(_docId)
          .get(const GetOptions(source: Source.server));
      if (doc.exists && mounted) {
        final d = doc.data()!;
        setState(() {
          _title = d['title'] ?? _title;
          _body = d['body'] ?? _body;
          _imageUrl = d['imageUrl'] ?? _imageUrl;
          _contentImageUrl = d['contentImageUrl'] ?? '';
          _hasOverride = true;
          _titleCtrl.text = _title;
          _bodyCtrl.text = _body;
          _imageCtrl.text = _imageUrl;
          _contentImageCtrl.text = _contentImageUrl;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickHeaderImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedImageFile = file;
          _pickedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u062E\u0637\u0623 \u0641\u064A \u0627\u062E\u062A\u064A\u0627\u0631 \u0627\u0644\u0635\u0648\u0631\u0629: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickContentImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedContentImageFile = file;
          _pickedContentImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u062E\u0637\u0623 \u0641\u064A \u0627\u062E\u062A\u064A\u0627\u0631 \u0627\u0644\u0635\u0648\u0631\u0629: \$e'), backgroundColor: Colors.red));
    }
  }

  Future<String?> _uploadPickedImage() async {
    if (_pickedImageFile == null) return null;
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance.ref().child('articles/headers/article_${_docId}_$ts.jpg');
      final bytes = await _pickedImageFile!.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u062E\u0637\u0623 \u0641\u064A \u0631\u0641\u0639 \u0627\u0644\u0635\u0648\u0631\u0629: $e'), backgroundColor: Colors.red));
      return null;
    }
  }

  Future<void> _saveOverride() async {
    setState(() => _isUploading = true);
    try {
      // Upload picked image if any
      String finalImageUrl = _imageCtrl.text.trim();
      if (_pickedImageFile != null) {
        final uploadedUrl = await _uploadPickedImage();
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
          _imageCtrl.text = finalImageUrl;
        }
      }

      // Upload content image if picked
      String finalContentImageUrl = _contentImageCtrl.text.trim();
      if (_pickedContentImageFile != null) {
        try {
          final ts = DateTime.now().millisecondsSinceEpoch;
          final ref = FirebaseStorage.instance.ref().child('articles/content/article_content_\${_docId}_\$ts.jpg');
          final bytes = await _pickedContentImageFile!.readAsBytes();
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
          finalContentImageUrl = await ref.getDownloadURL();
          _contentImageCtrl.text = finalContentImageUrl;
        } catch (_) {}
      }

      await FirebaseFirestore.instance.collection('article_overrides').doc(_docId).set({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'imageUrl': finalImageUrl,
        'contentImageUrl': finalContentImageUrl,
        'section': widget.section,
        'originalTitle': widget.title,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _title = _titleCtrl.text.trim();
        _body = _bodyCtrl.text.trim();
        _imageUrl = finalImageUrl;
        _contentImageUrl = finalContentImageUrl;
        _isEditing = false;
        _hasOverride = true;
        _pickedImageFile = null;
        _pickedImageBytes = null;
        _pickedContentImageFile = null;
        _pickedContentImageBytes = null;
        _isUploading = false;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('\u062A\u0645 \u062D\u0641\u0638 \u0627\u0644\u062A\u0639\u062F\u064A\u0644\u0627\u062A \u0628\u0646\u062C\u0627\u062D'), backgroundColor: Colors.teal));
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u062E\u0637\u0623 \u0641\u064A \u0627\u0644\u062D\u0641\u0638: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteArticle() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('\u062D\u0630\u0641 \u0627\u0644\u0645\u0642\u0627\u0644'),
        content: const Text('\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u062D\u0630\u0641 \u0647\u0630\u0627 \u0627\u0644\u0645\u0642\u0627\u0644\u061F'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('\u0625\u0644\u063A\u0627\u0621')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('\u062D\u0630\u0641', style: TextStyle(color: Colors.red))),
        ],
      ),
    ));
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('article_overrides').doc(_docId).set({
        'deleted': true, 'originalTitle': widget.title, 'section': widget.section,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) { Navigator.pop(context); }
    }
  }

  // Inline images matched to article content keywords
  // ── Products by section ──
  static const _productsBySection = <String, List<Map<String, String>>>{
    'pregnancy': [
      {'name': 'وسادة الحمل المريحة', 'image': 'https://images.unsplash.com/photo-1584839404210-0a5d92ea4861?w=300&q=80', 'price': '3500 د.ج', 'category': 'راحة الحامل'},
      {'name': 'كريم علامات التمدد', 'image': 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=300&q=80', 'price': '1800 د.ج', 'category': 'العناية بالبشرة'},
      {'name': 'حمض الفوليك 400mcg', 'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300&q=80', 'price': '950 د.ج', 'category': 'مكملات غذائية'},
      {'name': 'حزام دعم البطن', 'image': 'https://images.unsplash.com/photo-1584839404210-0a5d92ea4861?w=300&q=80', 'price': '2200 د.ج', 'category': 'راحة الحامل'},
      {'name': 'زيت اللوز للتدليك', 'image': 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=300&q=80', 'price': '1200 د.ج', 'category': 'العناية بالبشرة'},
      {'name': 'فيتامينات ما قبل الولادة', 'image': 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=300&q=80', 'price': '2800 د.ج', 'category': 'مكملات غذائية'},
    ],
    'cycle': [
      {'name': 'قربة ماء ساخن', 'image': 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=300&q=80', 'price': '800 د.ج', 'category': 'تخفيف الألم'},
      {'name': 'شاي البابونج العضوي', 'image': 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=300&q=80', 'price': '650 د.ج', 'category': 'مشروبات صحية'},
      {'name': 'مكمل المغنيسيوم', 'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300&q=80', 'price': '1500 د.ج', 'category': 'مكملات غذائية'},
      {'name': 'فوط صحية قطنية', 'image': 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=300&q=80', 'price': '450 د.ج', 'category': 'نظافة شخصية'},
      {'name': 'زيت زهرة الربيع', 'image': 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=300&q=80', 'price': '1100 د.ج', 'category': 'مكملات طبيعية'},
      {'name': 'كمادة حرارية كهربائية', 'image': 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=300&q=80', 'price': '2500 د.ج', 'category': 'تخفيف الألم'},
    ],
    'baby': [
      {'name': 'كريم حماية الحفاض', 'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=300&q=80', 'price': '750 د.ج', 'category': 'العناية بالطفل'},
      {'name': 'زيت تدليك الأطفال', 'image': 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=300&q=80', 'price': '900 د.ج', 'category': 'العناية بالطفل'},
      {'name': 'ميزان حرارة رقمي', 'image': 'https://images.unsplash.com/photo-1584308666544-27e30e01c6c6?w=300&q=80', 'price': '1200 د.ج', 'category': 'صحة الطفل'},
      {'name': 'رضاعة مضادة للمغص', 'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=300&q=80', 'price': '1800 د.ج', 'category': 'تغذية الطفل'},
      {'name': 'شامبو أطفال طبيعي', 'image': 'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=300&q=80', 'price': '550 د.ج', 'category': 'العناية بالطفل'},
      {'name': 'لهاية سيليكون طبية', 'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=300&q=80', 'price': '350 د.ج', 'category': 'مستلزمات الطفل'},
    ],
    'home': [
      {'name': 'فيتامين D3 للنساء', 'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300&q=80', 'price': '1400 د.ج', 'category': 'مكملات غذائية'},
      {'name': 'كريم ترطيب طبيعي', 'image': 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=300&q=80', 'price': '1600 د.ج', 'category': 'العناية بالبشرة'},
      {'name': 'شاي أعشاب مهدئ', 'image': 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=300&q=80', 'price': '700 د.ج', 'category': 'مشروبات صحية'},
      {'name': 'أوميغا 3 طبيعي', 'image': 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=300&q=80', 'price': '2200 د.ج', 'category': 'مكملات غذائية'},
      {'name': 'سيروم فيتامين C', 'image': 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=300&q=80', 'price': '1900 د.ج', 'category': 'العناية بالبشرة'},
      {'name': 'حديد + فوليك أسيد', 'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300&q=80', 'price': '1100 د.ج', 'category': 'مكملات غذائية'},
    ],
    'news': [
      {'name': 'كتاب أمومة سعيدة', 'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=300&q=80', 'price': '1500 د.ج', 'category': 'كتب ومراجع'},
      {'name': 'مفكرة تتبع الحمل', 'image': 'https://images.unsplash.com/photo-1517842645767-c639042777db?w=300&q=80', 'price': '950 د.ج', 'category': 'تنظيم'},
      {'name': 'حقيبة الأمومة الشاملة', 'image': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=300&q=80', 'price': '4500 د.ج', 'category': 'حقائب'},
      {'name': 'ألبوم ذكريات الطفل', 'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=300&q=80', 'price': '1800 د.ج', 'category': 'ذكريات'},
      {'name': 'تطبيق متابعة الحمل Pro', 'image': 'https://images.unsplash.com/photo-1517842645767-c639042777db?w=300&q=80', 'price': '500 د.ج', 'category': 'رقمي'},
      {'name': 'مجموعة العناية بالأم', 'image': 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=300&q=80', 'price': '3200 د.ج', 'category': 'هدايا'},
    ],
  };

  static final Map<String, List<String>> _inlineImageSets = {
    'حمل': [
      'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=700&q=80',
      'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=700&q=80',
    ],
    'حامل': [
      'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=700&q=80',
      'https://images.unsplash.com/photo-1509822929063-6b6cfc9b42f2?w=700&q=80',
    ],
    'طفل': [
      'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=700&q=80',
      'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=700&q=80',
    ],
    'رضاعة': [
      'https://images.unsplash.com/photo-1584582397869-3e903bfe9985?w=700&q=80',
      'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=700&q=80',
    ],
    'تغذية': [
      'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=700&q=80',
      'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=700&q=80',
    ],
    'غذاء': [
      'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=700&q=80',
      'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=700&q=80',
    ],
    'دورة': [
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=700&q=80',
      'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=700&q=80',
    ],
    'رياضة': [
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=700&q=80',
      'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=700&q=80',
    ],
    'تمارين': [
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=700&q=80',
      'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=700&q=80',
    ],
    'نوم': [
      'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=700&q=80',
      'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=700&q=80',
    ],
    'فيتامين': [
      'https://images.unsplash.com/photo-1505576399279-0d754c0fdc67?w=700&q=80',
      'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=700&q=80',
    ],
    'نفسية': [
      'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=700&q=80',
      'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=700&q=80',
    ],
    'طبيب': [
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=700&q=80',
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=700&q=80',
    ],
    'تطعيم': [
      'https://images.unsplash.com/photo-1632053002928-1919605ee6f7?w=700&q=80',
      'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=700&q=80',
    ],
    'بشرة': [
      'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=700&q=80',
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=700&q=80',
    ],
    'ولادة': [
      'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=700&q=80',
      'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=700&q=80',
    ],
  };

  List<String> _getInlineImages() {
    // Use override content image if available
    if (_contentImageUrl.isNotEmpty) return [_contentImageUrl];
    if (widget.contentImages.isNotEmpty) return widget.contentImages;
    for (final entry in _inlineImageSets.entries) {
      if (_title.contains(entry.key)) return entry.value;
    }
    return [
      'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=700&q=80',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasHeaderImage = _imageUrl.isNotEmpty;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title, style: TextStyle(fontSize: 18)),
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          color: Color(0xFFFFF8FB),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Admin Edit Mode ──
              if (_isEditing && _admin.isAdmin) Container(
                color: Colors.amber.shade50,
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('\u062A\u0639\u062F\u064A\u0644 \u0627\u0644\u0645\u0642\u0627\u0644', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_isUploading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: '\u0627\u0644\u0639\u0646\u0648\u0627\u0646', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  // ── Image picker section ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.image, color: widget.color, size: 20),
                        const SizedBox(width: 8),
                        const Text('\u0635\u0648\u0631\u0629 \u0627\u0644\u0645\u0642\u0627\u0644', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _pickHeaderImage,
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('\u0631\u0641\u0639 \u0645\u0646 \u0627\u0644\u062C\u0647\u0627\u0632', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: Colors.teal),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      if (_pickedImageBytes != null)
                        Stack(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(10),
                            child: Image.memory(_pickedImageBytes!, height: 140, width: double.infinity, fit: BoxFit.cover)),
                          Positioned(top: 4, left: 4, child: GestureDetector(
                            onTap: () => setState(() { _pickedImageFile = null; _pickedImageBytes = null; }),
                            child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                          Positioned(bottom: 4, right: 4, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                            child: const Text('\u0635\u0648\u0631\u0629 \u062C\u062F\u064A\u062F\u0629', style: TextStyle(color: Colors.white, fontSize: 10)))),
                        ])
                      else if (_imageCtrl.text.isNotEmpty)
                        ClipRRect(borderRadius: BorderRadius.circular(10),
                          child: Image.network(_imageCtrl.text, height: 140, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(height: 60, decoration: BoxDecoration(
                              color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))))),
                      const SizedBox(height: 8),
                      TextField(controller: _imageCtrl, decoration: InputDecoration(
                        labelText: '\u0623\u0648 \u0631\u0627\u0628\u0637 \u0627\u0644\u0635\u0648\u0631\u0629 (URL)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ), style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  // ── Content image picker section ──
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.photo_library, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Text('صورة داخل المقال', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _pickContentImage,
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('رفع من الجهاز', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: Colors.orange),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      if (_pickedContentImageBytes != null)
                        Stack(children: [
                          ClipRRect(borderRadius: BorderRadius.circular(10),
                            child: Image.memory(_pickedContentImageBytes!, height: 140, width: double.infinity, fit: BoxFit.cover)),
                          Positioned(top: 4, left: 4, child: GestureDetector(
                            onTap: () => setState(() { _pickedContentImageFile = null; _pickedContentImageBytes = null; }),
                            child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 16)))),
                          Positioned(bottom: 4, right: 4, child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                            child: const Text('صورة جديدة', style: TextStyle(color: Colors.white, fontSize: 10)))),
                        ])
                      else if (_contentImageCtrl.text.isNotEmpty)
                        ClipRRect(borderRadius: BorderRadius.circular(10),
                          child: Image.network(_contentImageCtrl.text, height: 140, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(height: 60, decoration: BoxDecoration(
                              color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))))),
                      const SizedBox(height: 8),
                      TextField(controller: _contentImageCtrl, decoration: InputDecoration(
                        labelText: 'أو رابط الصورة (URL)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ), style: const TextStyle(fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _bodyCtrl, maxLines: 10, decoration: InputDecoration(labelText: '\u0627\u0644\u0645\u062D\u062A\u0648\u0649', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), alignLabelWithHint: true), style: const TextStyle(fontSize: 14, height: 1.6)),
                  if (_hasOverride) Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('\u2705 \u064A\u0648\u062C\u062F \u062A\u0639\u062F\u064A\u0644 \u0645\u062D\u0641\u0648\u0638 \u0641\u064A Firestore', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                  ),
                ]),
              ),
              // Header image
              if (hasHeaderImage)
                Image.network(_imageUrl, height: 220, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 220,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.color.withOpacity(0.2), widget.color.withOpacity(0.05)])),
                    child: Center(child: Icon(Icons.image, color: widget.color.withOpacity(0.3), size: 60)))),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!hasHeaderImage)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [widget.color.withOpacity(0.15), widget.color.withOpacity(0.05)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Icon(Icons.article_outlined, color: widget.color, size: 40),
                        SizedBox(width: 14),
                        Expanded(child: Text(_title,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F1A20)))),
                      ]),
                    )
                  else ...[
                    Text(_title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F1A20))),
                    SizedBox(height: 20),
                  ],
                  // Paragraphs with smart inline images + ad space
                  ...() {
                    // Smart paragraph splitting: by \n\n or by sentences (~120 chars each)
                    List<String> paragraphs;
                    if (_body.contains('\n\n')) {
                      paragraphs = _body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
                    } else {
                      // Split long text into paragraphs by sentence endings
                      final allText = _body.trim();
                      paragraphs = [];
                      String current = '';
                      final sentences = allText.split(RegExp(r'(?<=[\.\!\?\:])\s+'));
                      int sentCount = 0;
                      for (final s in sentences) {
                        current += (current.isEmpty ? '' : ' ') + s;
                        sentCount++;
                        if (sentCount >= 3 && current.length > 100) {
                          paragraphs.add(current.trim());
                          current = '';
                          sentCount = 0;
                        }
                      }
                      if (current.trim().isNotEmpty) paragraphs.add(current.trim());
                    }
                    final inlineImgs = _getInlineImages();
                    final widgets = <Widget>[];
                    final midPoint = (paragraphs.length / 2).floor();
                    int imgIdx = 0;
                    for (int i = 0; i < paragraphs.length; i++) {
                      // Paragraph with subtle separator
                      widgets.add(Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: Text(paragraphs[i].trim(),
                          textAlign: TextAlign.justify,
                          style: TextStyle(fontSize: 16.5, height: 1.9, color: Color(0xFF3A343B), letterSpacing: 0.1)),
                      ));
                      // First image after paragraph 2
                      if (i == 1 && imgIdx < inlineImgs.length) {
                        widgets.add(Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(inlineImgs[imgIdx], width: double.infinity, height: 220, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => SizedBox.shrink()),
                          ),
                        ));
                        imgIdx++;
                      }
                      // Google Ads placeholder at midpoint
                      if (i == midPoint && paragraphs.length > 3) {
                        widgets.add(Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(vertical: 16),
                          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFFF5F0F7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Color(0xFFE8E0EC), width: 0.8),
                          ),
                          child: Column(children: [
                            Icon(Icons.campaign_outlined, color: Color(0xFFBBA8C4), size: 28),
                            SizedBox(height: 8),
                            Text('\u0645\u0633\u0627\u062D\u0629 \u0625\u0639\u0644\u0627\u0646\u064A\u0629', style: TextStyle(fontSize: 12, color: Color(0xFFBBA8C4), fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('Google AdMob', style: TextStyle(fontSize: 10, color: Color(0xFFD0C4D6))),
                          ]),
                        ));
                      }
                      // Second image after midpoint+2
                      if (i == midPoint + 2 && imgIdx < inlineImgs.length) {
                        widgets.add(Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(inlineImgs[imgIdx], width: double.infinity, height: 220, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => SizedBox.shrink()),
                          ),
                        ));
                        imgIdx++;
                      }
                    }
                    // Remaining images at end
                    while (imgIdx < inlineImgs.length) {
                      widgets.add(Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(inlineImgs[imgIdx], width: double.infinity, height: 220, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => SizedBox.shrink()),
                        ),
                      ));
                      imgIdx++;
                    }
                    return widgets;
                  }(),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.color.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, color: widget.color, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('هذا المقال للأغراض التثقيفية فقط. استشيري طبيبتك للحصول على نصيحة طبية شخصية.',
                        style: TextStyle(fontSize: 13, color: widget.color.withOpacity(0.8), fontStyle: FontStyle.italic))),
                    ]),
                  ),
                  // ── Products Carousel (dynamic + static) ──
                  SizedBox(height: 24),
                  Row(children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.shopping_bag_outlined, color: widget.color, size: 20),
                    ),
                    SizedBox(width: 10),
                    Text('منتجات قد تهمك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1A20))),
                  ]),
                  SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: DynamicContentService.getProducts(section: widget.section),
                    builder: (context, prodSnap) {
                      final dynamicProducts = (prodSnap.data?.docs ?? [])
                          .map((doc) => DynamicContentService.docToProduct(doc))
                          .toList();
                      final staticProducts = _productsBySection[widget.section] ?? _productsBySection['home']!;
                      final allProducts = [...dynamicProducts, ...staticProducts];
                      return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allProducts.length,
                      itemBuilder: (context, idx) {
                        final p = allProducts[idx];
                        return GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                                    // Handle bar
                                    Container(
                                      margin: EdgeInsets.only(top: 12, bottom: 8),
                                      width: 40, height: 4,
                                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                                    ),
                                    // Product image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        p['image']!,
                                        height: 200, width: double.infinity, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 200, color: widget.color.withOpacity(0.1),
                                          child: Center(child: Icon(Icons.shopping_bag, color: widget.color, size: 60))),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        // Category badge
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: widget.color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(p['category']!, style: TextStyle(fontSize: 11, color: widget.color, fontWeight: FontWeight.w700)),
                                        ),
                                        SizedBox(height: 10),
                                        // Product name
                                        Text(p['name']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F1A20), height: 1.3)),
                                        SizedBox(height: 10),
                                        // Price row
                                        Row(children: [
                                          Text(p['price']!, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: widget.color)),
                                          Spacer(),
                                          Icon(Icons.local_shipping_outlined, color: Colors.green.shade600, size: 18),
                                          SizedBox(width: 4),
                                          Text('شحن مجاني', style: TextStyle(fontSize: 12, color: Colors.green.shade600, fontWeight: FontWeight.w600)),
                                        ]),
                                        SizedBox(height: 20),
                                        // Shop button
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.push(context, MaterialPageRoute(
                                                builder: (_) => Directionality(
                                                  textDirection: TextDirection.rtl,
                                                  child: ShopPage(),
                                                ),
                                              ));
                                            },
                                            icon: Icon(Icons.shopping_cart_outlined, size: 20),
                                            label: Text('تسوق الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: widget.color,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                      ]),
                                    ),
                                  ]),
                                ),
                              ),
                            );
                          },
                          child: Container(
                          width: 150,
                          margin: EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 3))],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(p['image']!, height: 100, width: 150, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(height: 100, color: widget.color.withOpacity(0.1),
                                  child: Center(child: Icon(Icons.shopping_bag, color: widget.color, size: 30)))),
                            ),
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p['name']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                                SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(p['category']!, style: TextStyle(fontSize: 9, color: widget.color, fontWeight: FontWeight.w600)),
                                  ),
                                  Spacer(),
                                  Text(p['price']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: widget.color)),
                                ]),
                              ]),
                            ),
                          ]),
                        ),
                        );
                      },
                    ),
                  );
                    },
                  ),
                ]),
              ),
            ]),
          ),
        ),
      floatingActionButton: _admin.isAdmin ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isEditing) ...[
            FloatingActionButton.small(
              heroTag: 'delete',
              backgroundColor: Colors.red,
              onPressed: _deleteArticle,
              child: const Icon(Icons.delete, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'save',
              backgroundColor: Colors.teal,
              onPressed: _saveOverride,
              child: const Icon(Icons.save, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton(
            heroTag: 'edit',
            backgroundColor: _isEditing ? Colors.orange : widget.color,
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Icon(_isEditing ? Icons.close : Icons.edit, color: Colors.white),
          ),
        ],
      ) : null,
      ),
    );
  }
}

// ==================== PROFILE PAGE (FIRESTORE) ====================
class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final AdminService _admin = AdminService();
  bool _adminReady = false;
  int _totalPoints = 0;
  int _unlockedCount = 0;
  int _streak = 0;
  bool _achievementsLoaded = false;
  late AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _initAdmin();
    _loadAchievements();
    _arrowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  Future<void> _initAdmin() async {
    await _admin.initialize();
    if (mounted) setState(() => _adminReady = true);
  }

  Future<void> _loadAchievements() async {
    try {
      final doc = await DB.userDoc.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final achievements = data['achievements'] as Map<String, dynamic>? ?? {};
      final streak = (data['login_streak'] as num?)?.toInt() ?? 0;

      // Achievement points map
      final pointsMap = {
        'first_week': 10, 'trimester_1': 50, 'trimester_2': 75, 'trimester_3': 100, 'due_date': 200, 'baby_size_fan': 30,
        'first_weight': 10, 'weight_5': 25, 'weight_20': 75, 'vitamins_day': 15, 'vitamins_week': 50, 'exercise_first': 10,
        'bag_10': 20, 'bag_complete': 100, 'journal_first': 10, 'journal_10': 40, 'journal_30': 100, 'calendar_check': 10,
        'streak_3': 15, 'streak_7': 35, 'streak_14': 70, 'streak_30': 150, 'streak_60': 300, 'first_login': 5,
      };

      int points = 0;
      int count = 0;
      // Auto-unlock first_login
      if (achievements['first_login'] != true) {
        await DB.userDoc.set({'achievements': {'first_login': true}}, SetOptions(merge: true));
        achievements['first_login'] = true;
      }
      for (final entry in achievements.entries) {
        if (entry.value == true) { count++; points += pointsMap[entry.key] ?? 0; }
      }

      if (mounted) setState(() { _totalPoints = points; _unlockedCount = count; _streak = streak; _achievementsLoaded = true; });
    } catch (_) {
      if (mounted) setState(() => _achievementsLoaded = true);
    }
  }

  String get _levelName {
    if (_totalPoints >= 1000) return 'ملكة نبضة';
    if (_totalPoints >= 600) return 'خبيرة';
    if (_totalPoints >= 300) return 'متقدمة';
    if (_totalPoints >= 100) return 'نشيطة';
    if (_totalPoints >= 30) return 'مبتدئة';
    return 'جديدة';
  }

  int get _levelIndex {
    if (_totalPoints >= 1000) return 5;
    if (_totalPoints >= 600) return 4;
    if (_totalPoints >= 300) return 3;
    if (_totalPoints >= 100) return 2;
    if (_totalPoints >= 30) return 1;
    return 0;
  }

  Future<void> _editName(BuildContext context) async {
    final tr = AppLocalizations.t;
    final user = FirebaseAuth.instance.currentUser;
    final controller = TextEditingController(text: user?.displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: AppLocalizations.textDir,
        child: AlertDialog(
          title: Text(tr('edit_name')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: tr('full_name'), border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(tr('save'))),
          ],
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      await user?.updateDisplayName(result);
      await DB.userDoc.set({'name': result}, SetOptions(merge: true));
    }
  }

  void _showLanguagePicker(BuildContext context) {
    final languages = [
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    ];
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(AppLocalizations.t('language'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ...languages.map((lang) {
            bool isSelected = AppLocalizations.currentLang == lang['code'];
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Text(lang['flag']!, style: TextStyle(fontSize: 28)),
                title: Text(lang['name']!, style: TextStyle(fontSize: 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? Icon(Icons.check_circle, color: Colors.teal) : null,
                tileColor: isSelected ? Colors.teal.shade50 : Colors.grey.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  localeNotifier.setLocale(lang['code']!);
                  Navigator.pop(ctx);
                },
              ),
            );
          }),
          SizedBox(height: 12),
        ]),
      ),
    );
  }

  Future<void> _pickProfilePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('تغيير الصورة الشخصية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF00897B).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt, color: Color(0xFF00897B))),
              title: const Text('التقاط صورة'), onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFF4F93).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library, color: Color(0xFFFF4F93))),
              title: const Text('اختيار من المعرض'), onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
    if (source == null) return;
    final imgSource = source == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await picker.pickImage(source: imgSource, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final bytes = await picked.readAsBytes();
      debugPrint('Photo bytes size: ${bytes.length}');

      String url;
      try {
        // Try Firebase Storage first
        final ref = FirebaseStorage.instance.ref().child('profile_photos/${user.uid}.jpg');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        url = await ref.getDownloadURL();
        debugPrint('Storage upload success: $url');
      } catch (storageError) {
        debugPrint('Storage failed, falling back to base64: $storageError');
        // Fallback: save as base64 data URI in Firestore
        final base64Str = base64Encode(bytes);
        url = 'data:image/jpeg;base64,$base64Str';
      }

      await DB.userDoc.set({'photoUrl': url}, SetOptions(merge: true));
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تحديث الصورة بنجاح'),
          backgroundColor: Color(0xFF00897B),
        ));
      }
    } catch (e, stack) {
      debugPrint('Profile photo upload error: $e');
      debugPrint('Stack: $stack');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('فشل رفع الصورة: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.t;
    final user = FirebaseAuth.instance.currentUser;
    return Directionality(
      textDirection: AppLocalizations.textDir,
      child: Scaffold(
        body: StreamBuilder<DocumentSnapshot>(
          stream: DB.userDoc.snapshots(),
          builder: (context, snapshot) {
            String name = user?.displayName ?? tr('anonymous');
            String? photoUrl;
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              if (data['name'] != null && (data['name'] as String).isNotEmpty) {
                name = data['name'];
              }
              photoUrl = data['photoUrl'] as String?;
            }

            return SingleChildScrollView(
              child: Column(children: [
                // Gradient profile header (Claude Design)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 28, left: 20, right: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFFCE4EC), const Color(0xFFFFF8FB), const Color(0xFFE0F2F1)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(children: [
                    // Back button row
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.arrow_back_ios_new, size: 18, color: const Color(0xFF1F1A20)),
                        ),
                      ),
                      Spacer(),
                      Text(tr('profile'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1F1A20))),
                      Spacer(),
                      const SizedBox(width: 36),
                    ]),
                    SizedBox(height: 20),
                    // Avatar with gradient border + photo support
                    GestureDetector(
                      onTap: () => _pickProfilePhoto(context),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFF7E57C2)]),
                              boxShadow: [BoxShadow(color: const Color(0x40E91E63), blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: photoUrl != null
                                ? CircleAvatar(radius: 48, backgroundColor: Colors.white,
                                    backgroundImage: photoUrl.startsWith('data:')
                                        ? MemoryImage(base64Decode(photoUrl.split(',').last))
                                        : NetworkImage(photoUrl) as ImageProvider,
                                  )
                                : const CircleAvatar(radius: 48, backgroundColor: Colors.white,
                                    child: Icon(Icons.person, size: 56, color: Color(0xFF00897B))),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF15B8A6)]),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1F1A20))),
                    SizedBox(height: 4),
                    Text(user?.email ?? '', style: TextStyle(color: const Color(0xFF8B8190), fontSize: 13)),
                  ]),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(children: [
                SizedBox(height: 8),

                // ─── Admin Panel Button (visible only for staff) ───
                if (_adminReady && _admin.isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPanelScreen())),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [const Color(0xFF7E57C2), const Color(0xFF5E35B1)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0x407E57C2), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('لوحة التحكم', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text('إدارة الطلبات والمنتجات', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ─── Achievements & Levels Section ───
                if (_achievementsLoaded) ...[
                  _buildLevelProgressCard(),
                  const SizedBox(height: 12),
                  _buildAchievementStatsRow(),
                  const SizedBox(height: 16),
                ],

                _menuItem('الإنجازات والشارات', Icons.emoji_events, Colors.amber.shade700, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsScreen()));
                }),
                _menuItem(tr('edit_name'), Icons.edit, Colors.teal, () => _editName(context)),
                _menuItem(tr('language'), Icons.language, Colors.indigo, () => _showLanguagePicker(context)),
                _menuItem(tr('reset_data'), Icons.refresh, Colors.orange, () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => Directionality(
                      textDirection: AppLocalizations.textDir,
                      child: AlertDialog(
                        title: Text(tr('confirm')),
                        content: Text(AppLocalizations.currentLang == 'ar'
                            ? 'هل تريدين حذف جميع البيانات؟ لا يمكن التراجع'
                            : AppLocalizations.currentLang == 'fr'
                              ? 'Voulez-vous supprimer toutes les données? Irréversible'
                              : 'Delete all data? This cannot be undone'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: Text(tr('delete'))),
                        ],
                      ),
                    ),
                  );
                  if (confirm == true) {
                    await DB.userDoc.set({
                      'lastPeriodStart': null,
                      'pregnancyStartDate': null,
                      'babyName': '',
                      'babyBirthDate': null,
                      'baby_weight': null,
                      'baby_height': null,
                    }, SetOptions(merge: true));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('reset_data')), backgroundColor: Colors.orange));
                    }
                  }
                }),
                _menuItem(tr('notifications'), Icons.notifications, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RemindersPage()));
                }),
                _menuItem(tr('privacy'), Icons.lock, Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyPage()));
                }),
                _menuItem(tr('help'), Icons.help, Colors.green, null),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('onboarding_done');
                      await prefs.remove('life_stage');
                      await prefs.remove('user_name');
                      await prefs.remove('pregnancy_start');
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      // Pop the ProfilePage first, then navigate
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      GoRouter.of(context).go('/onboarding');
                    },
                    icon: Icon(Icons.logout),
                    label: Text(tr('logout'), style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
                  ),
                ),
              ])),  // close Padding + Column
              ]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLevelProgressCard() {
    final levels = [
      {'name': 'جديدة', 'emoji': '👋', 'points': 0},
      {'name': 'مبتدئة', 'emoji': '🌱', 'points': 30},
      {'name': 'نشيطة', 'emoji': '🔥', 'points': 100},
      {'name': 'متقدمة', 'emoji': '💎', 'points': 300},
      {'name': 'خبيرة', 'emoji': '🌟', 'points': 600},
      {'name': 'ملكة نبضة', 'emoji': '👑', 'points': 1000},
    ];
    final currentIdx = _levelIndex;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            // Current level header
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color(0xFFFFD700), const Color(0xFFFFC107)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 12)],
                  ),
                  child: Center(child: Text(levels[currentIdx]['emoji'] as String, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_levelName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('$_totalPoints نقطة  •  $_unlockedCount/24 إنجاز', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  ],
                )),
                const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              ],
            ),
            const SizedBox(height: 20),
            // Level path with animated arrow
            SizedBox(
              height: 80,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final stepWidth = totalWidth / (levels.length - 1);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Background line
                      Positioned(
                        top: 18, left: 0, right: 0,
                        child: Container(height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
                      ),
                      // Progress line
                      Positioned(
                        top: 18, left: 0,
                        child: Container(
                          height: 4,
                          width: (stepWidth * currentIdx).clamp(0, totalWidth),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFC107)]),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Level dots
                      ...List.generate(levels.length, (i) {
                        final x = i * stepWidth;
                        final isReached = i <= currentIdx;
                        final isCurrent = i == currentIdx;
                        return Positioned(
                          left: x - 14,
                          top: 6,
                          child: Column(
                            children: [
                              Container(
                                width: isCurrent ? 28 : 22,
                                height: isCurrent ? 28 : 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isReached ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.2),
                                  border: isCurrent ? Border.all(color: Colors.white, width: 2.5) : null,
                                  boxShadow: isCurrent ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 8)] : null,
                                ),
                                child: Center(child: Text(
                                  levels[i]['emoji'] as String,
                                  style: TextStyle(fontSize: isCurrent ? 14 : 10),
                                )),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                levels[i]['name'] as String,
                                style: TextStyle(
                                  fontSize: isCurrent ? 10 : 8,
                                  color: isReached ? const Color(0xFFFFD700) : Colors.white38,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // Animated arrow pointing to current level
                      AnimatedBuilder(
                        animation: _arrowController,
                        builder: (context, _) {
                          final bounce = _arrowController.value * 6;
                          return Positioned(
                            left: (currentIdx * stepWidth) - 8,
                            top: -14 - bounce,
                            child: Column(
                              children: [
                                Text('▼', style: TextStyle(fontSize: 14, color: const Color(0xFFFFD700), shadows: [Shadow(color: const Color(0xFFFFD700).withOpacity(0.6), blurRadius: 6)])),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementStatsRow() {
    return Row(
      children: [
        _achievementStatCard('🔥', '$_streak', 'أيام متتالية', const Color(0xFFFF6D00)),
        const SizedBox(width: 10),
        _achievementStatCard('⭐', '$_totalPoints', 'نقطة', const Color(0xFFFFB300)),
        const SizedBox(width: 10),
        _achievementStatCard('🏆', '$_unlockedCount', 'إنجاز', const Color(0xFF7B1FA2)),
      ],
    );
  }

  Widget _achievementStatCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(String title, IconData icon, Color color, VoidCallback? onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: Icon(AppLocalizations.isRtl ? Icons.chevron_left : Icons.chevron_right, color: const Color(0xFF8B8190)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: const Color(0xFFFAF7F8),
      ),
    );
  }
}

// ==================== COMMUNITY PAGE ====================
class CommunityPage extends StatefulWidget {
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  String _selectedCategory = 'all';

  final List<String> _categoryKeys = ['all', 'cat_general', 'cat_cycle', 'cat_pregnancy', 'cat_baby', 'cat_nutrition', 'cat_mental'];

  Color _categoryColor(String catKey) {
    switch (catKey) {
      case 'cat_cycle': return Colors.pink;
      case 'cat_pregnancy': return Colors.purple;
      case 'cat_baby': return Colors.blue;
      case 'cat_nutrition': return Colors.green;
      case 'cat_mental': return Colors.orange;
      default: return Colors.teal;
    }
  }

  IconData _categoryIcon(String catKey) {
    switch (catKey) {
      case 'cat_cycle': return Icons.calendar_month;
      case 'cat_pregnancy': return Icons.pregnant_woman;
      case 'cat_baby': return Icons.child_care;
      case 'cat_nutrition': return Icons.restaurant;
      case 'cat_mental': return Icons.psychology;
      default: return Icons.forum;
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return AppLocalizations.t('just_now');
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return AppLocalizations.t('just_now');
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${AppLocalizations.t('minutes_ago')}';
    if (diff.inHours < 24) return '${diff.inHours} ${AppLocalizations.t('hours_ago')}';
    return '${diff.inDays} ${AppLocalizations.t('days_ago')}';
  }

  void _showNewPostDialog() {
    final tr = AppLocalizations.t;
    final textController = TextEditingController();
    bool isAnonymous = false;
    String postCategory = 'cat_general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: AppLocalizations.textDir,
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Icon(Icons.edit_note, color: Colors.teal, size: 28),
                SizedBox(width: 8),
                Text(tr('new_post'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
              SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: tr('post_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 12),
              // Category selector
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categoryKeys.where((k) => k != 'all').map((catKey) {
                    bool sel = postCategory == catKey;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tr(catKey), style: TextStyle(fontSize: 12)),
                        selected: sel,
                        selectedColor: _categoryColor(catKey).withOpacity(0.2),
                        onSelected: (_) => setSheetState(() => postCategory = catKey),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 8),
              // Anonymous toggle
              Row(children: [
                Checkbox(
                  value: isAnonymous,
                  onChanged: (v) => setSheetState(() => isAnonymous = v ?? false),
                  activeColor: Colors.teal,
                ),
                Text(tr('post_as_anonymous'), style: TextStyle(fontSize: 14)),
              ]),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.send),
                  label: Text(tr('post'), style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (textController.text.trim().isEmpty) return;
                    final user = FirebaseAuth.instance.currentUser;
                    await DB.communityPosts.add({
                      'text': textController.text.trim(),
                      'category': postCategory,
                      'authorId': user?.uid ?? '',
                      'authorName': isAnonymous ? '' : (user?.displayName ?? ''),
                      'isAnonymous': isAnonymous,
                      'likes': [],
                      'likesCount': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('post')), backgroundColor: Colors.teal));
                    }
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.t;
    Query query = DB.communityPosts.orderBy('createdAt', descending: true);
    if (_selectedCategory != 'all') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return Directionality(
      textDirection: AppLocalizations.textDir,
      child: Scaffold(
        appBar: AppBar(centerTitle: true,
          title: Text(tr('community_title')),
          backgroundColor: Color(0xFFE91E63),
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE91E63), Colors.pink.shade300]),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showNewPostDialog,
          backgroundColor: Color(0xFFE91E63),
          child: Icon(Icons.add, color: Colors.white),
        ),
        body: Column(children: [
          // Category filter
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12),
              children: _categoryKeys.map((catKey) {
                bool sel = _selectedCategory == (catKey == 'all' ? 'all' : catKey);
                Color c = catKey == 'all' ? Colors.teal : _categoryColor(catKey);
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tr(catKey), style: TextStyle(fontSize: 12, color: sel ? Colors.white : c)),
                    selected: sel,
                    selectedColor: c,
                    backgroundColor: c.withOpacity(0.1),
                    onSelected: (_) => setState(() => _selectedCategory = catKey == 'all' ? 'all' : catKey),
                  ),
                );
              }).toList(),
            ),
          ),
          // Posts feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.limit(50).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade300),
                      SizedBox(height: 16),
                      Text(tr('no_posts'), textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ]),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final post = doc.data() as Map<String, dynamic>;
                    final isAnon = post['isAnonymous'] == true;
                    final authorName = isAnon ? tr('anonymous') : (post['authorName'] ?? tr('anonymous'));
                    final catKey = post['category'] ?? 'cat_general';
                    final color = _categoryColor(catKey);
                    final likes = List<String>.from(post['likes'] ?? []);
                    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final isLiked = likes.contains(uid);

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: isAnon ? Colors.grey.shade200 : Colors.teal.shade100,
                              child: Icon(isAnon ? Icons.person_off : Icons.person, size: 20,
                                color: isAnon ? Colors.grey : Colors.teal),
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(authorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(_timeAgo(post['createdAt'] as Timestamp?),
                                style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ])),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(_categoryIcon(catKey), size: 14, color: color),
                                SizedBox(width: 4),
                                Text(tr(catKey), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ]),
                        ),
                        // Post text
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Text(post['text'] ?? '', style: TextStyle(fontSize: 15, height: 1.6)),
                        ),
                        // Actions
                        Padding(
                          padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Row(children: [
                            TextButton.icon(
                              onPressed: () async {
                                if (isLiked) {
                                  await doc.reference.update({
                                    'likes': FieldValue.arrayRemove([uid]),
                                    'likesCount': FieldValue.increment(-1),
                                  });
                                } else {
                                  await doc.reference.update({
                                    'likes': FieldValue.arrayUnion([uid]),
                                    'likesCount': FieldValue.increment(1),
                                  });
                                }
                              },
                              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.grey, size: 20),
                              label: Text('${likes.length}', style: TextStyle(color: Colors.grey)),
                            ),
                          ]),
                        ),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ==================== AI CHAT PAGE (GEMINI) ====================
class AIChatPage extends StatefulWidget {
  @override
  State<AIChatPage> createState() => _AIChatPageState();
}


// ══════════════════════ NEWS SECTION ══════════════════════
class _NewsSection extends StatelessWidget {
  final Color accentColor;
  final String sectionTitle;
  const _NewsSection({this.accentColor = const Color(0xFFE91E63), this.sectionTitle = 'آخر الأخبار'});

  static const _news = <Map<String, String>>[
    {'title': 'أم رباعية التوائم تنجب 5 توائم دفعة واحدة', 'tag': 'أرقام قياسية',
     'image': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=400&q=80',
     'content': 'في واحدة من أغرب المصادفات الطبية أنجبت تيريزا ترويا وهي ممرضة أمريكية تبلغ من العمر ستة وثلاثين عاماً من مدينة إل باسو في تكساس خمسة توائم في يونيو 2025 دون استخدام أي أدوية خصوبة. المدهش أن تيريزا نفسها ولدت كرباعية توائم مما يجعل قصتها فريدة من نوعها في التاريخ الطبي.\n\nتحدث ولادة التوائم الخماسية بمعدل واحدة فقط من كل ستين مليون حالة ولادة طبيعية مما يجعلها من أندر الظواهر في عالم الطب. وُلد الأطفال الخمسة بعملية قيصرية وكانوا جميعاً بصحة جيدة رغم ولادتهم المبكرة. قالت تيريزا إنها شعرت بسعادة غامرة وأنها مستعدة لتربية عائلتها الكبيرة بفضل خبرتها في التمريض وتجربتها الشخصية كتوأم.'},
    {'title': 'أصغر توائم رباعية خدّج في التاريخ ينجون', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1504151932400-72d4384f04b3?w=400&q=80',
     'content': 'حطمت عائلة براينت الأمريكية رقماً قياسياً عمره ثلاثون عاماً في موسوعة غينيس عندما وُلد توائمهم الأربعة في الأسبوع الثالث والعشرين فقط من الحمل أي قبل موعدهم بمائة وخمسة عشر يوماً. وُلد الأطفال الأربعة بأوزان لا تتجاوز ستمائة غرام لكل منهم.\n\nبفضل الرعاية المكثفة في وحدة العناية بحديثي الولادة استعاد التوائم الأربعة عافيتهم تدريجياً وخرجوا جميعاً من المستشفى في ديسمبر 2024 بصحة ممتازة. وصف الأطباء حالتهم بالمعجزة الطبية وأكدوا أن التطور الهائل في طب حديثي الولادة هو ما أتاح نجاة هؤلاء الأطفال الذين كانوا أصغر من أن يعيشوا قبل عقود قليلة.'},
    {'title': 'امرأة ألمانية تنجب طفلها العاشر في سن 66 عاماً', 'tag': 'حول العالم',
     'image': 'https://images.unsplash.com/photo-1492725764893-90b379c2b6e7?w=400&q=80',
     'content': 'أذهلت ألكسندرا هيلدبراندت الألمانية العالم عندما أنجبت طفلها العاشر فيليب في مارس 2025 وهي في سن السادسة والستين دون أي أدوية خصوبة أو تلقيح صناعي. وُلد الطفل بعملية قيصرية في مستشفى شاريتيه في برلين بوزن ثلاثة كيلوغرامات ونصف وبصحة ممتازة.\n\nأثار الخبر جدلاً واسعاً في ألمانيا وأوروبا حول أخلاقيات الإنجاب في سن متقدمة لكن ألكسندرا أكدت أنها تتمتع بصحة جيدة وأن أطفالها التسعة الكبار يساعدونها في رعاية أخيهم الصغير. يحمل الرقم القياسي العالمي لأكبر أم تنجب السيدة الهندية إيراماتي مانغاما التي أنجبت توأماً في عمر أربعة وسبعين عاماً.'},
    {'title': 'طفل ينمو خارج الرحم وينجو بأعجوبة', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=400&q=80',
     'content': 'في حالة طبية نادرة للغاية لا تحدث إلا مرة واحدة من كل ثلاثين ألف حالة حمل اكتشف أطباء في مدينة بيكرزفيلد بكاليفورنيا أن طفل الممرضة سوز لوبيز نما في بطنها خارج الرحم مخفياً خلف كيس مبيضي بحجم كرة السلة. لم تعرف الأم بحملها حتى أيام قليلة قبل الولادة.\n\nنجا الطفل بأعجوبة رغم أن حالات الحمل البطني التي تصل لاكتمال النمو نادرة جداً بنسبة أقل من واحد في المليون. خضعت سوز لعملية جراحية طارئة وخرج الطفل بصحة جيدة. حالة مشابهة سُجلت في كيب تاون بجنوب أفريقيا حيث انغرست البويضة المخصبة في الشريان الحرقفي الخارجي بدلاً من الرحم.'},
    {'title': 'تسعة توائم من مالي يحتفلون بعيد ميلادهم الأول', 'tag': 'أرقام قياسية',
     'image': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=400&q=80',
     'content': 'احتفلت السيدة المالية حليمة سيسيه بعيد الميلاد الأول لتوائمها التسعة الذين سجلوا رقماً قياسياً في موسوعة غينيس كأكبر عدد مواليد أحياء من ولادة واحدة. وُلد الأطفال التسعة خمسة ذكور وأربع إناث بعملية قيصرية في المغرب حيث سافرت الأم خصيصاً لتلقي الرعاية الطبية المتقدمة.\n\nأمضى التوائم التسعة أشهراً في الحضانة قبل أن يتمكنوا من العودة لمنزلهم. تحتاج الأسرة يومياً لأكثر من مائة حفاضة وكميات هائلة من الحليب. رغم التحديات أعربت حليمة عن سعادتها الغامرة وقالت إن كل طفل من أطفالها هو نعمة من الله وأنها لن تغير شيئاً لو عاد بها الزمن.'},
    {'title': 'أم تلد في مطعم بعد أن أعادها المستشفى للمنزل', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80',
     'content': 'في أبريل 2024 عاشت أليس سباركمان الأمريكية وهي حامل في الأسبوع السابع والثلاثين تجربة لا تُنسى عندما أعادها المستشفى للمنزل رغم شعورها بانقباضات منتظمة. قررت مع زوجها التوقف لتناول العشاء في مطعم قريب وما إن قضمت أول لقمة من سلطة السيزر حتى نزل ماء الولادة.\n\nاستدعى طاقم المطعم الإسعاف فوراً وساعد المسعفون في توليدها في المطعم نفسه. وُلد الطفل بصحة تامة وأصبحت القصة حديث المدينة. قال مدير المطعم مازحاً إنهم سيقدمون وجبة مجانية للعائلة في كل عيد ميلاد للطفل. القصة ذكّرت الجميع بأن الأطفال يختارون لحظة وصولهم بأنفسهم.'},
    {'title': 'أول طفل في بريطانيا من رحم مزروع بعد عقد من الانتظار', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1531983412531-1f49a365ffed?w=400&q=80',
     'content': 'في إنجاز طبي تاريخي رحبت غريس وزوجها أنغوس من بريطانيا بطفلتهما إيمي إيزابيل في عام 2025 وهي أول طفلة تولد في المملكة المتحدة من رحم مزروع بعد عشر سنوات من الانتظار والمحاولات. كانت غريس قد فقدت رحمها بسبب حالة طبية وخضعت لعملية زراعة رحم معقدة.\n\nاستغرقت العملية سنوات من التحضير والمتابعة الطبية المكثفة قبل أن تتمكن من الحمل. قالت غريس إن لحظة حمل طفلتها لأول مرة كانت أجمل لحظة في حياتها وأنها لم تفقد الأمل يوماً رغم كل الصعوبات. هذا الإنجاز يفتح الباب لآلاف النساء اللواتي فقدن قدرتهن على الحمل.'},
    {'title': 'توأمان يولدان في سنتين مختلفتين بفارق 15 دقيقة', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1578922746465-3a80a228f223?w=400&q=80',
     'content': 'في ليلة رأس السنة 2024 شهد مستشفى في نيويورك ولادة فريدة من نوعها حيث وُلد التوأم الأول قبل منتصف الليل بدقائق في 31 ديسمبر والتوأم الثاني بعد منتصف الليل في الأول من يناير 2025. هكذا أصبح لكل توأم سنة ميلاد مختلفة رغم أن الفارق بينهما خمس عشرة دقيقة فقط.\n\nقالت الأم إنها لم تخطط لذلك أبداً لكنها سعيدة لأن أطفالها سيكون لديهم قصة مميزة يروونها طوال حياتهم. سيحتفل كل توأم بعيد ميلاده في يوم مختلف وسنة مختلفة وهو أمر يحدث نادراً جداً. أطلقت الأسرة على التوأمين اسمي آدم وحواء تيمناً ببداية جديدة.'},
    {'title': 'سيدة أفريقية تنجب 10 توائم في ولادة واحدة', 'tag': 'أرقام قياسية',
     'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80',
     'content': 'أذهلت غوسيامي تاماراسيتومبي من جنوب أفريقيا العالم عندما أنجبت عشرة توائم سبعة ذكور وثلاث إناث بعملية قيصرية في مستشفى بريتوريا بعد تسعة وعشرين أسبوعاً فقط من الحمل. وُلد جميع الأطفال بأوزان منخفضة ووُضعوا في الحضانة فوراً.\n\nقبل هذه الحالة كان الرقم القياسي تسعة توائم سجلته حليمة سيسيه من مالي. تحتاج الأسرة لدعم هائل لرعاية عشرة أطفال في وقت واحد وقد تلقت تبرعات ومساعدات من جهات عديدة. أثارت الحالة نقاشاً طبياً واسعاً حول حدود الحمل المتعدد والمخاطر الصحية المرتبطة به.'},
    {'title': 'طفل يولد بسنّين كاملتين يثير دهشة الأطباء', 'tag': 'حالات نادرة',
     'image': 'https://images.unsplash.com/photo-1519340241574-2cec6aef0c01?w=400&q=80',
     'content': 'في حالة طبية نادرة للغاية وُلد طفل في مستشفى بالهند بسنّين أماميتين كاملتين وهو ما يُعرف طبياً بأسنان الولادة. يحدث هذا في واحدة من كل ألفين إلى ثلاثة آلاف ولادة تقريباً لكن وجود سنّين كاملتين عند الولادة أمر أكثر ندرة.\n\nقرر الأطباء إزالة الأسنان لأنها كانت تسبب صعوبة في الرضاعة وخطر اختناق في حال سقوطها. والدة الطفل قالت إنها صُدمت عندما رأت ابنها يبتسم بأسنان حقيقية فور ولادته. يعتقد الأطباء أن أسنان الولادة مرتبطة بعوامل وراثية وتغذوية خلال الحمل لكن السبب الدقيق لا يزال غير واضح تماماً.'},
    {'title': 'أم تكتشف حملها قبل الولادة بساعات فقط', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1457342813143-a1ae27a5e890?w=400&q=80',
     'content': 'تتكرر حالات الحمل الخفي أو ما يُعرف بإنكار الحمل أكثر مما يتوقع الكثيرون. في عام 2024 ذهبت سيدة بريطانية إلى المستشفى بسبب آلام شديدة في البطن ظنتها التهاب الزائدة الدودية ليتفاجأ الأطباء بأنها في المخاض وأنجبت طفلاً سليماً بعد ساعتين فقط.\n\nيحدث الحمل الخفي في واحدة من كل خمسمائة حالة حمل تقريباً حيث لا تظهر على الأم أعراض الحمل المعتادة كغياب الدورة أو كبر البطن أو الغثيان. في بعض الحالات تستمر الدورة الشهرية بشكل خفيف ويبقى البطن مسطحاً بسبب وضعية الرحم. هذه الحالات تثبت أن جسم المرأة قادر على إخفاء الحمل تماماً حتى عن صاحبته.'},
    {'title': 'توأمان متطابقان يولدان بلونَي بشرة مختلفين تماماً', 'tag': 'حالات نادرة',
     'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&q=80',
     'content': 'في حالة وراثية مذهلة وُلد توأمان لأبوين من عرقين مختلفين في بريطانيا بلونَي بشرة متناقضين تماماً أحدهما ببشرة فاتحة جداً والآخر ببشرة داكنة. رغم أنهما توأمان أخويان إلا أن المظهر الخارجي لا يوحي بأي صلة قرابة بينهما وهو ما أثار دهشة حتى الأطباء المتمرسين.\n\nيفسر علماء الوراثة هذه الظاهرة بأن كل توأم ورث مجموعة مختلفة من الجينات المسؤولة عن لون البشرة من كلا الوالدين. تقول الأم إن الناس لا يصدقون أنهما أخوان ويطلبون إثباتاً دائماً. هذه الحالة تحدث بنسبة واحدة من كل مليون ولادة توائم وتثبت التنوع المذهل في الجينات البشرية.'},
    {'title': 'أصغر طفل خديج في العالم يحتفل بعيده الخامس', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1566004100631-35d015d6a491?w=400&q=80',
     'content': 'احتفل كورتيس مينز من ولاية ألاباما الأمريكية بعيد ميلاده الخامس بعد أن وُلد في الأسبوع الحادي والعشرين فقط من الحمل بوزن أقل من ثلاثمائة غرام وهو ما يعادل وزن تفاحة صغيرة. كان أصغر طفل خديج ينجو في التاريخ الطبي عند ولادته.\n\nاليوم يعيش كورتيس حياة طبيعية تماماً يلعب ويركض ويذهب للحضانة كأي طفل في عمره. قالت والدته إن رحلتهم كانت مليئة بالتحديات لكن الأمل والإيمان لم يفارقاها لحظة. قصته ألهمت آلاف العائلات التي تمر بنفس التجربة وأصبح رمزاً لقوة الإرادة والتقدم الطبي.'},
    {'title': 'امرأة تنجب طفلاً أثناء غيبوبة استمرت 3 أشهر', 'tag': 'حالات نادرة',
     'image': 'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?w=400&q=80',
     'content': 'في قصة أثارت اهتماماً طبياً واسعاً دخلت سيدة في غيبوبة بسبب حادث سير وهي حامل في شهرها السادس. حافظ الأطباء على حياتها واستمرار الحمل طوال ثلاثة أشهر كاملة حتى وُلد الطفل بعملية قيصرية في الشهر التاسع وبصحة ممتازة.\n\nالمفاجأة الأكبر كانت عندما استيقظت الأم من غيبوبتها بعد أسبوعين من الولادة لتجد طفلها بجانبها. وصفت اللحظة بأنها أجمل لحظة في حياتها رغم أنها لا تتذكر شيئاً من أشهر الحمل الأخيرة. أشاد الأطباء بالتقنيات الحديثة التي تمكنهم من الحفاظ على حياة الأم والجنين في أصعب الظروف.'},
    {'title': 'دراسة: أطفال يتعرفون على أصوات أمهاتهم من الرحم', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1491013516836-7db643ee125a?w=400&q=80',
     'content': 'كشفت دراسة علمية حديثة نُشرت في مجلة نيتشر أن الأجنة يبدأون بالتعرف على صوت أمهاتهم وتمييزه عن الأصوات الأخرى من الأسبوع الثامن عشر من الحمل. استخدم الباحثون تقنيات تصوير متقدمة لقياس استجابة دماغ الجنين للأصوات المختلفة ووجدوا نشاطاً دماغياً مميزاً عند سماع صوت الأم.\n\nالأكثر إثارة أن الأطفال حديثي الولادة يفضلون صوت أمهاتهم على أي صوت آخر ويهدأون فوراً عند سماعه. الدراسة أظهرت أيضاً أن الأجنة يتذكرون الأغاني والقصص التي كانت الأم تقرأها أو تغنيها خلال الحمل ويظهرون استجابة إيجابية لها بعد الولادة. هذا يؤكد أهمية تحدث الأم مع جنينها خلال الحمل.'},
    {'title': 'طفلة تولد بخصلة شعر بيضاء وراثية نادرة', 'tag': 'حالات نادرة',
     'image': 'https://images.unsplash.com/photo-1519689373023-dd07c7988603?w=400&q=80',
     'content': 'أذهلت طفلة حديثة الولادة الأطباء والممرضات عندما وُلدت بخصلة شعر بيضاء لامعة في مقدمة رأسها بينما باقي شعرها أسود. تبين أن الحالة وراثية تُعرف بالبهق الجزئي وهي غير ضارة تماماً ومجرد سمة جمالية فريدة.\n\nالمدهش أن والدة الطفلة وجدتها وجدة جدتها جميعهن يحملن نفس الخصلة البيضاء. انتشرت صور الطفلة على وسائل التواصل الاجتماعي وحصدت ملايين الإعجابات. أطلق عليها المتابعون لقب أميرة الثلج. الأطباء أكدوا أن الحالة لا تحتاج أي علاج وأن الطفلة ستحتفظ بهذه السمة المميزة طوال حياتها.'},
    {'title': 'دراسة: الرضاعة الطبيعية تحمي من 800 ألف وفاة سنوياً', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1609220136736-443140cffec6?w=400&q=80',
     'content': 'أكدت دراسة واسعة النطاق أجرتها منظمة الصحة العالمية بالتعاون مع يونيسف أن الرضاعة الطبيعية تمنع وفاة أكثر من ثمانمائة ألف طفل سنوياً حول العالم. الدراسة التي شملت بيانات من مائة وثلاثين دولة أظهرت أن حليب الأم يحتوي على أكثر من ألف مركب نشط بيولوجياً يحمي الرضيع من العدوى والأمراض المزمنة.\n\nكشفت الدراسة أيضاً أن الرضاعة الطبيعية تقلل خطر إصابة الأم بسرطان الثدي والمبيض بنسبة تصل لعشرين بالمائة وتساعد على التعافي السريع بعد الولادة. رغم هذه الفوائد الهائلة فإن أقل من خمسين بالمائة من الأطفال حول العالم يحصلون على رضاعة طبيعية حصرية في الأشهر الستة الأولى كما توصي المنظمة.'},
    {'title': 'أب يحضر ولادة ابنته عبر الفيديو من الفضاء', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400&q=80',
     'content': 'في لحظة مؤثرة تابع رائد فضاء روسي ولادة ابنته عبر مكالمة فيديو من محطة الفضاء الدولية على ارتفاع أربعمائة كيلومتر فوق سطح الأرض. كان الأب في مهمة فضائية مدتها ستة أشهر ولم يستطع العودة للأرض لكنه أصر على حضور اللحظة ولو افتراضياً.\n\nبكى رائد الفضاء من الفرح عندما سمع صرخة طفلته الأولى وقال إنه رأى الأرض كلها من نافذة المحطة لكن أجمل منظر كان وجه ابنته على شاشة الهاتف. عاد للأرض بعد شهرين وكان أول ما فعله حمل طفلته التي لم يلتقِ بها إلا في ذلك اليوم. القصة لامست قلوب الملايين حول العالم.'},
    {'title': 'اكتشاف أن حليب الأم يتغير تركيبه حسب جنس المولود', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=400&q=80',
     'content': 'توصل باحثون في جامعة هارفارد لاكتشاف مذهل وهو أن تركيبة حليب الأم تختلف تلقائياً حسب جنس المولود. حليب أمهات الذكور يحتوي على نسبة أعلى من الدهون والسعرات الحرارية بينما حليب أمهات الإناث يحتوي على نسبة أعلى من الكالسيوم والأجسام المضادة.\n\nيعتقد العلماء أن هذا التكيف التلقائي تطور عبر ملايين السنين ليلبي الاحتياجات البيولوجية المختلفة لكل جنس. الذكور يحتاجون سعرات أكثر لأنهم ينمون أسرع بينما الإناث تحتاج حماية مناعية أقوى. هذا الاكتشاف يضيف دليلاً جديداً على أن حليب الأم هو الغذاء الأمثل المصمم خصيصاً لكل طفل.'},
    {'title': 'مستشفى يعزف الموسيقى للأجنة ويحسن نموهم', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1485546246426-74dc88dec4d9?w=400&q=80',
     'content': 'بدأ مستشفى في برشلونة بإسبانيا برنامجاً مبتكراً يقوم على عزف موسيقى كلاسيكية للأجنة في أرحام أمهاتهم باستخدام جهاز صغير يوضع على البطن. أظهرت النتائج الأولية أن الأجنة الذين استمعوا للموسيقى أظهروا تطوراً عصبياً أفضل وحركات أكثر تناسقاً من المجموعة الضابطة.\n\nالبرنامج يستخدم موسيقى موتسارت وباخ بتردد منخفض يمكن للجنين سماعه من الأسبوع السادس عشر. أفاد الأطباء أن الأطفال الذين شاركت أمهاتهم في البرنامج كانوا أكثر هدوءاً بعد الولادة واستجابوا للموسيقى بشكل إيجابي. المستشفى يخطط لتوسيع البرنامج وتطوير تطبيق يمكن للأمهات استخدامه في المنزل.'},
    {'title': 'أم تنجب طفلتها في سيارة إسعاف على الطريق السريع', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=400&q=80',
     'content': 'لم تنتظر الطفلة ليلى وصول أمها للمستشفى فقررت القدوم للعالم في سيارة الإسعاف على الطريق السريع في القاهرة أثناء ساعة الذروة. المسعف الذي ساعد في التوليد قال إنها كانت المرة الأولى التي يولّد فيها طفلاً في سيارة متحركة وأن التجربة كانت مثيرة ومخيفة في آن واحد.\n\nوُلدت الطفلة بصحة ممتازة وبكت فوراً مما طمأن الجميع. عندما وصلوا للمستشفى لم يكن هناك حاجة سوى لفحص روتيني. أصبحت القصة حديث وسائل التواصل الاجتماعي في مصر وأطلق المتابعون على الطفلة لقب بنت الطريق. قالت الأم إنها ستحكي لابنتها هذه القصة كل عيد ميلاد.'},
    {'title': 'تقنية جديدة تتيح للأجنة التنفس خارج الرحم', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400&q=80',
     'content': 'يعمل فريق من العلماء في جامعة فيلادلفيا على تطوير رحم صناعي يشبه كيساً مملوءاً بسائل يحاكي السائل الأمنيوسي ويمكنه احتضان الأجنة الخدّج الذين يولدون مبكراً جداً. التجارب على الحملان أظهرت نتائج واعدة حيث تمكنت الحملان المولودة مبكراً من إكمال نموها في الرحم الصناعي.\n\nإذا نجحت التجارب البشرية فإن هذه التقنية قد تنقذ حياة آلاف الأطفال الخدج المولودين قبل الأسبوع الرابع والعشرين الذين تكون فرص نجاتهم حالياً منخفضة جداً. التقنية لا تهدف لاستبدال الرحم الطبيعي بل لتوفير بيئة مشابهة للأطفال الذين يحتاجون وقتاً إضافياً لإكمال نمو رئاتهم وأعضائهم الحيوية.'},
    {'title': 'ممرضة تكتشف أنها أنجبت التوأم الذي تعتني به في الحضانة', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1578307985320-34b61a66c195?w=400&q=80',
     'content': 'في مصادفة مذهلة اكتشفت ممرضة في مستشفى أمريكي أن الطفلة الخديجة التي كانت تعتني بها في وحدة حديثي الولادة قبل خمسة وعشرين عاماً هي نفس الممرضة الشابة التي انضمت للعمل معها في نفس القسم. جمعتهما صورة قديمة معلقة على جدار القسم تظهر الممرضة وهي تحمل الرضيعة.\n\nبكت كلتاهما من التأثر عندما أدركتا الرابط بينهما. قالت الممرضة المخضرمة إنها تذكرت الحالة جيداً لأن الطفلة كانت خديجة وبقيت في الحضانة أشهراً. أما الممرضة الشابة فقالت إن هذه المصادفة هي السبب الذي دفعها لدراسة التمريض لتساعد أطفالاً آخرين كما ساعدتها تلك الممرضة.'},
    {'title': 'دراسة: الأطفال الذين يسمعون لغتين يتطور دماغهم أسرع', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80',
     'content': 'أثبتت دراسة حديثة أجراها معهد ماكس بلانك أن أدمغة الأطفال الذين ينشأون في بيئة ثنائية اللغة تتطور بشكل أسرع وتظهر مرونة عصبية أعلى من أقرانهم أحاديي اللغة. التصوير بالرنين المغناطيسي أظهر نشاطاً أكبر في مناطق الدماغ المسؤولة عن حل المشكلات واتخاذ القرارات والتبديل بين المهام.\n\nالأطفال ثنائيو اللغة يبدأون بالنطق متأخرين قليلاً لكنهم يتفوقون لاحقاً في المهارات المعرفية والتركيز والذاكرة العاملة. الدراسة شجعت الآباء على التحدث بلغتهم الأم مع أطفالهم حتى لو كانوا يعيشون في بلد آخر لأن ثنائية اللغة هدية ثمينة تدوم مدى الحياة وتحمي الدماغ من التدهور المعرفي في الشيخوخة.'},
    {'title': 'توأمان ملتصقان يُفصلان بنجاح بعد عملية 36 ساعة', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=400&q=80',
     'content': 'نثجح فريق طبي مكون من ستين طبيباً وممرضاً في مستشفى جريت أورموند ستريت في لندن في فصل توأمين ملتصقين من الرأس في عملية استغرقت ستاً وثلاثين ساعة متواصلة. كان التوأمان يتشاركان أوعية دموية رئيسية في الدماغ مما جعل العملية من أعقد العمليات الجراحية في العالم.\n\nبعد أشهر من التعافي يعيش التوأمان الآن حياة طبيعية ويمارسان نشاطاتهما بشكل مستقل. قال الجراح الرئيسي إن التخطيط للعملية استغرق أشهراً واستخدموا نماذج ثلاثية الأبعاد مطبوعة لأدمغة التوأمين للتدرب على العملية قبل إجرائها. قصتهما ألهمت عائلات كثيرة حول العالم.'},
    {'title': 'أصغر أم تتبرع بحليبها لإنقاذ مائة طفل خديج', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=400&q=80',
     'content': 'أصبحت سارة من الأردن مصدر إلهام بعد أن تبرعت بأكثر من مائتي لتر من حليبها لبنك الحليب في المستشفى مما ساعد في إنقاذ حياة أكثر من مائة طفل خديج خلال عامين. بدأت التبرع بعد أن اكتشفت أنها تنتج حليباً أكثر بكثير مما يحتاجه طفلها.\n\nتقول سارة إن شعورها بأنها تساعد أطفالاً آخرين على النجاة يمنحها سعادة لا توصف وأنها ستستمر في التبرع طالما استطاعت. بنوك حليب الأم توفر حليباً بشرياً مبستراً للأطفال الخدج الذين لا تستطيع أمهاتهم إرضاعهم والذين يحتاجون لحليب بشري بدلاً من الصناعي لحمايتهم من التهابات الأمعاء الخطيرة.'},
    {'title': 'طفل يولد في طائرة على ارتفاع 10 آلاف متر', 'tag': 'حول العالم',
     'image': 'https://images.unsplash.com/photo-1436491865332-7a61a109db05?w=400&q=80',
     'content': 'على متن رحلة بين إسطنبول ونيويورك فاجأت سيدة تركية ركاب الطائرة عندما بدأت أعراض المخاض وهم على ارتفاع عشرة آلاف متر فوق المحيط الأطلسي. تطوع طبيبان كانا من الركاب للمساعدة في التوليد بينما وفرت طاقم الطائرة المناشف والبطانيات.\n\nوُلد الطفل بسلام وبكى فور خروجه مما أثار موجة من التصفيق والدموع بين الركاب. منحت شركة الطيران الطفل تذكرة سفر مجانية مدى الحياة وسمّاه والداه إيلان وهو اسم يعني المسافر في التركية. السؤال الذي أثار فضول الجميع هو أي جنسية سيحملها الطفل الذي وُلد في الأجواء الدولية.'},
    {'title': 'علماء يطورون حفاضاً ذكياً ينبه الوالدين صحياً', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1587616211892-f743fcca64f9?w=400&q=80',
     'content': 'طور فريق من المهندسين في معهد ماساتشوستس للتكنولوجيا حفاضاً ذكياً مزوداً بمستشعرات دقيقة يمكنه تحليل بول الرضيع واكتشاف علامات مبكرة لالتهابات المسالك البولية والجفاف وبعض الأمراض الاستقلابية. يرسل الحفاض تنبيهات للوالدين عبر تطبيق على الهاتف.\n\nالتقنية تستخدم مستشعرات بيولوجية رخيصة الثمن يمكن دمجها في الحفاضات العادية دون رفع تكلفتها بشكل كبير. في التجارب الأولية اكتشف الحفاض الذكي حالات التهاب مسالك بولية قبل ظهور الأعراض السريرية بيومين. يأمل المطورون أن يكون المنتج متاحاً تجارياً خلال سنتين ليصبح أداة فحص منزلية تساعد الآباء على مراقبة صحة أطفالهم.'},
    {'title': 'سيدة مصرية تنجب بعد 25 سنة من العقم', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1492725764893-90b379c2b6e7?w=400&q=80',
     'content': 'بعد خمسة وعشرين عاماً من الانتظار والمحاولات الفاشلة رُزقت سيدة مصرية من المنيا بتوأم ذكور بعد عملية حقن مجهري ناجحة في عامها الخمسين. قالت إنها لم تفقد الأمل يوماً رغم أن الجميع نصحوها بالتوقف عن المحاولة وأنها جربت كل الطرق الطبية والشعبية المتاحة.\n\nاستقبلت العائلة والحي بأكمله الخبر بفرح عارم وأقيمت احتفالات استمرت ثلاثة أيام. التوأمان بصحة ممتازة والأم تقول إن كل يوم انتظار كان يستحق العناء. قصتها أعطت أملاً لآلاف النساء اللواتي يعانين من تأخر الإنجاب وأثبتت أن الأمل لا يجب أن يموت مهما طال الانتظار.'},
    {'title': 'مولود يبتسم ابتسامة عريضة لحظة ولادته', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1519340241574-2cec6aef0c01?w=400&q=80',
     'content': 'انتشرت صورة مولود برازيلي على نطاق واسع بعد أن التقط المصور لحظة نادرة وهي ابتسامة المولود الأولى فور خروجه من رحم أمه بينما معظم المواليد يبكون. الصورة أصبحت من أكثر الصور المشاركة على وسائل التواصل الاجتماعي وحصدت أكثر من خمسين مليون مشاهدة.\n\nيقول أطباء الأطفال إن ما يبدو كابتسامة عند حديثي الولادة هو في الغالب رد فعل عضلي لا إرادي لكن توقيت هذه الابتسامة المثالي جعلها تبدو وكأن الطفل سعيد بقدومه للعالم. الأم قالت إنها بكت من الفرح عندما رأت الصورة وأنها ستعلقها في غرفة ابنها ليراها كل يوم. المصور قال إنها أجمل صورة التقطها في مسيرته المهنية.'},
    {'title': 'مدينة يابانية تقدم مكافأة مليون ين لكل مولود جديد', 'tag': 'حول العالم',
     'image': 'https://images.unsplash.com/photo-1480796927426-f609979314bd?w=400&q=80',
     'content': 'في محاولة لمكافحة أزمة انخفاض معدلات الولادة في اليابان أعلنت مدينة نايغي اليابانية الصغيرة عن تقديم مكافأة مالية قدرها مليون ين ياباني أي ما يعادل حوالي سبعة آلاف دولار لكل مولود جديد يولد لعائلة مقيمة في المدينة. المبادرة تأتي بعد أن انخفض عدد سكان المدينة بنسبة أربعين بالمائة خلال عشرين عاماً.\n\nتقدم المدينة أيضاً مساكن مجانية للعائلات الشابة ورعاية صحية مجانية للأطفال حتى سن المدرسة وحضانات مجانية. بعد عام من تطبيق البرنامج ارتفعت معدلات الولادة بنسبة خمسة عشر بالمائة وانتقلت عائلات جديدة للمدينة. تعاني اليابان من أدنى معدل ولادات في تاريخها وتحاول الحكومة إيجاد حلول إبداعية لتشجيع الإنجاب.'},
  ];

  /// Apply Firestore overrides to static news list
  static List<Map<String, String>> _applyOverrides(List<Map<String, String>> news, Map<String, Map<String, dynamic>> overrides) {
    if (overrides.isEmpty) return news;
    return news.map((n) {
      final title = n['title'] ?? '';
      if (overrides.containsKey(title)) {
        final o = overrides[title]!;
        return <String, String>{
          'title': (o['title'] as String?) ?? title,
          'tag': (o['tag'] as String?) ?? n['tag'] ?? '',
          'image': (o['imageUrl'] as String?) ?? n['image'] ?? '',
          'content': (o['content'] as String?) ?? n['content'] ?? '',
        };
      }
      return n;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('article_overrides').where('section', isEqualTo: 'news').snapshots(),
      builder: (context, overrideSnap) {
        final Map<String, Map<String, dynamic>> overrides = {};
        if (overrideSnap.hasData) {
          for (final doc in overrideSnap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final origTitle = (d['originalTitle'] as String?) ?? doc.id;
            overrides[origTitle] = d;
          }
        }
        final resolvedNews = _applyOverrides(_news, overrides);

        // Also load dynamic news articles from Firestore
        return StreamBuilder<QuerySnapshot>(
          stream: DynamicContentService.getArticles(section: 'news'),
          builder: (context, dynamicSnap) {
            final dynamicNews = (dynamicSnap.data?.docs ?? [])
                .map((doc) {
                  final a = DynamicContentService.docToArticle(doc);
                  return <String, String>{
                    'title': a['title'] ?? '',
                    'tag': a['category'] ?? 'جديد',
                    'image': a['image'] ?? '',
                    'content': a['content'] ?? '',
                  };
                }).toList();

            // Dynamic news first, then static
            final allNews = [...dynamicNews, ...resolvedNews];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.newspaper, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(sectionTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1F1A20)))),
                ]),
                const SizedBox(height: 4),
                Text('أخبار غريبة ومدهشة من عالم الأمومة', style: TextStyle(fontSize: 13, color: const Color(0xFF8B8190))),
                const SizedBox(height: 14),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allNews.length > 6 ? 6 : allNews.length,
                  itemBuilder: (context, i) {
                    final n = allNews[i];
                    return _newsCard(context, n, i);
                  },
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AllNewsScreen(accentColor: accentColor))),
                    icon: const Text('عرض جميع الأخبار', style: TextStyle(fontWeight: FontWeight.w600)),
                    label: const Icon(Icons.arrow_back_ios, size: 14),
                    style: TextButton.styleFrom(foregroundColor: accentColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _newsCard(BuildContext context, Map<String, String> n, int i) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => _ArticleDetailPage(title: n['title']!, body: n['content']!, color: accentColor, imageUrl: n['image']!, section: 'news'),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            child: Image.network(n['image']!, width: 100, height: 90, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 100, height: 90, color: accentColor.withOpacity(0.1), child: Icon(Icons.newspaper, color: accentColor))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(n['tag']!, style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                Text(n['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AllNewsScreen extends StatelessWidget {
  final Color accentColor;
  const _AllNewsScreen({this.accentColor = const Color(0xFFE91E63)});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FB),
        appBar: AppBar(title: const Text('آخر الأخبار'), backgroundColor: accentColor, foregroundColor: Colors.white),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('article_overrides').where('section', isEqualTo: 'news').snapshots(),
          builder: (context, overrideSnap) {
            final Map<String, Map<String, dynamic>> overrides = {};
            if (overrideSnap.hasData) {
              for (final doc in overrideSnap.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final origTitle = (d['originalTitle'] as String?) ?? doc.id;
                overrides[origTitle] = d;
              }
            }
            final resolvedNews = _NewsSection._applyOverrides(_NewsSection._news, overrides);
            return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resolvedNews.length,
          itemBuilder: (context, i) {
            final n = resolvedNews[i];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => _ArticleDetailPage(title: n['title']!, body: n['content']!, color: accentColor, imageUrl: n['image']!, section: 'news'),
              )),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(n['image']!, height: 160, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 160, color: accentColor.withOpacity(0.1), child: Icon(Icons.newspaper, color: accentColor, size: 50))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(n['tag']!, style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      Text(n['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
                      const SizedBox(height: 6),
                      Text(n['content']!.substring(0, n['content']!.length > 100 ? 100 : n['content']!.length) + '...', 
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8B8190), height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]),
              ),
            );
          },
        );
          },
        ),
      ),
    );
  }
}


class _AIChatPageState extends State<AIChatPage> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = false;
  final String _apiKey = 'AIzaSyB09gZH8igVPtC0yfPA5Twfp3KU0dC-kTI';

  // Quick suggestion buttons
  final quickQuestions = [
    'ما هي أعراض الحمل المبكر؟',
    'كيف أخفف آلام الدورة؟',
    'ما هي الأطعمة المفيدة للحامل؟',
    'كيف أعتني بطفلي الرضيع؟',
    'متى يجب زيارة الطبيب؟',
    'نصائح للرضاعة الطبيعية',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    messages.add({
      'role': 'assistant',
      'text': 'مرحباً! أنا المساعد الذكي لتطبيق نبضة. يمكنني مساعدتك في أسئلة صحة المرأة والحمل ورعاية الطفل.\n\nاختاري سؤالاً أو اكتبي سؤالك بالأسفل \u{1F49C}',
    });
  }

  // ===== Smart Health Knowledge Base =====
  static final Map<String, String> _healthKB = {
    // Period / Cycle
    'آلام الدورة|تشنجات|ألم الدورة|تخفيف الدورة':
      'دليل شامل لتخفيف آلام الدورة الشهرية:\n\nتعاني معظم النساء من تشنجات وآلام أثناء الدورة الشهرية، وهذا أمر طبيعي ناتج عن انقباضات الرحم للتخلص من بطانته. استخدمي الكمادات الدافئة على أسفل البطن، ومارسي المشي 20 دقيقة يوميا، واشربي شاي البابونج أو الزنجبيل. تناولي أطعمة غنية بالمغنيزيوم كالموز والشوكولاتة الداكنة. استشيري طبيبتك إذا كان الألم شديداً.',
    'انتظام الدورة|تأخر الدورة|عدم انتظام|دورة غير منتظمة':
      'الدورة الطبيعية تتراوح بين 21 و35 يوماً. أسباب عدم الانتظام تشمل: التوتر، تغير الوزن، تكيس المبايض، مشاكل الغدة الدرقية. حافظي على وزن صحي ومارسي الرياضة باعتدال. راجعي الطبيبة إذا غابت الدورة أكثر من 3 أشهر.',
    'التبويض|إباضة|خصوبة|أيام التبويض':
      'التبويض يحدث عادة قبل 14 يوماً من الدورة القادمة. فترة الخصوبة تمتد 6 أيام. علاماته: إفرازات شفافة مطاطية، ارتفاع طفيف في الحرارة، ألم خفيف في جانب واحد. تطبيق نبضة يحسب أيام الخصوبة تلقائياً.',
    // Pregnancy
    'أعراض الحمل|علامات الحمل|حمل مبكر':
      'أعراض الحمل المبكرة: تأخر الدورة، غثيان، تعب، انتفاخ الثدي، كثرة التبول، تقلبات مزاجية. للتأكد: اختبار منزلي بعد تأخر الدورة أو تحليل دم. ابدئي حمض الفوليك فوراً وحددي موعداً مع طبيبتك.',
    'غذاء الحامل|أطعمة الحامل|تغذية الحامل|أكل الحامل':
      'تناولي الخضروات الورقية والفواكه والبروتين والحليب والحبوب الكاملة. تجنبي الأسماك العالية بالزئبق واللحوم النيئة والكافيين الزائد. تناولي حمض الفوليك والحديد والكالسيوم وفيتامين D.',
    'غثيان|وحام|تقيؤ|غثيان الحمل':
      'الغثيان يصيب 70-80% من الحوامل. كلي وجبات صغيرة متكررة، تناولي الزنجبيل والنعناع، ضعي بسكويتاً جافاً بجانب سريرك. راجعي الطبيبة إذا كان التقيؤ شديداً.',
    // Baby Care
    'رضيع|رضاعة|حليب الأم|الرضاعة الطبيعية':
      'الرضاعة الطبيعية مثالية لـ 6 أشهر حصرياً. 8-12 رضعة يومياً في البداية. تأكدي من الالتقام الصحيح لمنع تشقق الحلمات. اشربي 10-12 كوب ماء يومياً.',
    'نوم الطفل|نوم الرضيع|بكاء الطفل':
      'حديث الولادة ينام 14-17 ساعة. نوميه على ظهره دائماً. ابني روتين نوم: حمام دافئ، تدليك، رضاعة، تهويدة. البكاء طبيعي للتواصل: جوع، حفاض، تعب، مغص.',
    'تطعيم|لقاح|تطعيمات الطفل':
      'التطعيمات ضرورية لحماية طفلك. عند الولادة: BCG + التهاب الكبد B. شهرين: الثلاثي + شلل الأطفال. 9 أشهر: الحصبة. التزمي بالمواعيد واحتفظي بدفتر التطعيمات.',
    // General Health
    'زيارة الطبيب|متى أزور الطبيب|استشارة طبية':
      'زوري الطبيبة فوراً عند: آلام شديدة، نزيف غزير، تأخر الدورة 3 أشهر، ألم أثناء الحمل، حرارة الطفل > 38.5. الفحوصات الدورية مهمة للاكتشاف المبكر.',
    'فيتامين|مكملات|حديد|فوليك|كالسيوم':
      'أهم المكملات: حمض الفوليك 400 ميكروغرام، الحديد 18 ملغ (27 للحامل)، الكالسيوم 1000 ملغ، فيتامين D 600 وحدة، أوميغا 3. استشيري طبيبتك قبل التناول.',
    'رياضة|تمارين|رياضة الحامل|مشي':
      'الرياضة أثناء الحمل مفيدة: 30 دقيقة يومياً. آمنة: المشي، السباحة، يوغا الحوامل، كيجل. تجنبي: الرياضات العنيفة والغوص والاستلقاء على الظهر بعد الشهر الرابع. توقفي عند أي نزيف أو دوخة.',
    'نفسية|اكتئاب|قلق|اكتئاب ما بعد الولادة':
      'اكتئاب ما بعد الولادة يصيب 10-15% من الأمهات. اطلبي المساعدة، نامي كلما نام الطفل، خذي وقتاً لنفسك، مارسي المشي. استشيري مختصة إذا استمرت الأعراض أكثر من أسبوعين. طلب المساعدة علامة قوة.',
  };


  String _getSmartReply(String question) {
    final q = question.toLowerCase();
    for (final entry in _healthKB.entries) {
      final keywords = entry.key.split('|');
      for (final kw in keywords) {
        if (q.contains(kw)) return entry.value;
      }
    }
    return 'شكراً على سؤالك! هذا الموضوع يحتاج استشارة طبية متخصصة. أنصحك بمراجعة طبيبتك للحصول على إجابة دقيقة ومخصصة لحالتك.\n\nيمكنك سؤالي عن:\n• آلام الدورة وانتظامها\n• أعراض الحمل والتغذية\n• الرضاعة ورعاية الطفل\n• التطعيمات والفيتامينات';
  }

  Future<String> _callGemini(String userMessage) async {
    _chatHistory.add({'role': 'user', 'parts': [{'text': userMessage}]});

    final sysText = 'أنت مساعد صحي ذكي اسمك نبضة، متخصص في صحة المرأة. أجب دائماً بالعربية. تخصصاتك: الدورة، الحمل، الولادة، رعاية الطفل، التغذية. أجب بإيجاز. إذا تطلب السؤال تشخيصاً طبياً انصحي بزيارة الطبيب.';

    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';
      final body = jsonEncode({
        'systemInstruction': {'parts': [{'text': sysText}]},
        'contents': _chatHistory,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String reply = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'لم أتمكن من الإجابة';
        _chatHistory.add({'role': 'model', 'parts': [{'text': reply}]});
        return reply;
      }
    } catch (_) {}

    // Fallback: smart local replies
    return _getSmartReply(userMessage);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _msgController.clear();

    setState(() {
      messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      String reply = await _callGemini(text);
      setState(() {
        messages.add({'role': 'assistant', 'text': reply});
        _isLoading = false;
      });
      DB.userDoc.collection('chat_history').add({
        'question': text,
        'answer': reply,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        messages.add({
          'role': 'assistant',
          'text': _getSmartReply(text),
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(centerTitle: true,
          title: Text('المساعد الذكي'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  messages.clear();
                  messages.add({
                    'role': 'assistant',
                    'text': 'تم مسح المحادثة. كيف يمكنني مساعدتك؟ \u{1F49C}'
                  });
                });
                _chatHistory.clear();
              },
              tooltip: 'مسح المحادثة',
            ),
          ],
        ),
        body: Column(children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isLoading) {
                  return _typingIndicator();
                }
                final msg = messages[index];
                bool isUser = msg['role'] == 'user';
                return _chatBubble(msg['text']!, isUser);
              },
            ),
          ),
          // Quick suggestions (show only at start)
          if (messages.length <= 1)
            Container(
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: quickQuestions.map((q) => Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: ActionChip(
                    label: Text(q, style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.teal.shade50,
                    onPressed: () => _sendMessage(q),
                  ),
                )).toList(),
              ),
            ),
          if (messages.length <= 1) SizedBox(height: 8),
          // Input bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1))],
            ),
            child: SafeArea(
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'اكتبي سؤالك هنا...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_msgController.text),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chatBubble(String text, bool isUser) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal.shade100,
              child: Icon(Icons.smart_toy, size: 18, color: Colors.teal),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? Colors.teal.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
                  bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
                ),
              ),
              child: Text(text, style: TextStyle(fontSize: 15, height: 1.5)),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 16, backgroundColor: Colors.teal.shade100,
          child: Icon(Icons.smart_toy, size: 18, color: Colors.teal)),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(0), SizedBox(width: 4),
            _dot(150), SizedBox(width: 4),
            _dot(300),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, val, child) => Opacity(opacity: val, child: child),
      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.teal.shade300, shape: BoxShape.circle)),
    );
  }
}
