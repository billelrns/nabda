import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/community/community_screen.dart';
import 'screens/pregnancy/pregnancy_weeks_screen.dart';
import 'screens/shop/shop_page.dart';
import 'services/country_currency_service.dart';
import 'services/notification_service.dart';
import 'services/admin_service.dart';
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
        if (snap.hasData) return MainNav();
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
  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [HomePage(onCardTap: goToTab), CyclePage(), PregnancyPage(), BabyPage(), ShopPage()];
    return Directionality(
      textDirection: AppLocalizations.textDir,
      child: Scaffold(
        body: Stack(
          children: [
            pages[_index],
            // Profile circle button at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [const Color(0xFFE91E63), const Color(0xFF7E57C2)]),
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
                      child: const Icon(Icons.person, color: Color(0xFF00897B), size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            NavigationDestination(icon: Icon(Icons.home), label: AppLocalizations.t('home')),
            NavigationDestination(icon: Icon(Icons.calendar_month), label: AppLocalizations.t('cycle')),
            NavigationDestination(icon: Icon(Icons.pregnant_woman), label: AppLocalizations.t('pregnancy')),
            NavigationDestination(icon: Icon(Icons.child_care), label: AppLocalizations.t('baby')),
            NavigationDestination(icon: Icon(Icons.store), label: AppLocalizations.t('shop')),
          ],
        ),
      ),
    );
  }
}

// ==================== HOME PAGE ====================
class HomePage extends StatelessWidget {
  final Function(int)? onCardTap;
  const HomePage({this.onCardTap});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final tr = AppLocalizations.t;
    return Directionality(
      textDirection: AppLocalizations.textDir,
      child: Scaffold(
        appBar: AppBar(centerTitle: true,
          title: Text(tr('app_name'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: 0.5)),
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF1F1A20),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFFCE4EC), const Color(0xFFFFF8FB), const Color(0xFFE0F2F1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.notifications_outlined, color: const Color(0xFF5E35B1)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RemindersPage())),
                tooltip: tr('reminders'),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: DB.userDoc.snapshots(),
          builder: (context, snapshot) {
            Map<String, dynamic> data = {};
            if (snapshot.hasData && snapshot.data!.exists) {
              data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            }
            int cycleDay = _calcCycleDay(data);
            int cycleLength = (data['cycleLength'] as int?) ?? 28;

            return SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header with warm gradient (Claude Design)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFFCE4EC), const Color(0xFFFFF8FB), const Color(0xFFE0F2F1)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.8)),
                      boxShadow: [
                        BoxShadow(color: const Color(0x14E91E63), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${tr('hello')} ${user?.displayName ?? ""}!',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1F1A20))),
                      SizedBox(height: 4),
                      Text(tr('how_are_you'), style: TextStyle(fontSize: 15, color: const Color(0xFF8B8190))),
                    ]),
                  ),
                  SizedBox(height: 16),
                  // Cycle status card
                  if (data['lastPeriodStart'] != null)
                    Container(
                      width: double.infinity, padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: cycleDay <= 5
                            ? [Colors.pink.shade400, Colors.pink.shade200]
                            : cycleDay >= 10 && cycleDay <= 16
                              ? [Colors.purple.shade400, Colors.purple.shade200]
                              : [Colors.teal.shade400, Colors.teal.shade200],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: const Color(0x40E91E63), blurRadius: 20, offset: Offset(0, 8))],
                      ),
                      child: Row(children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.calendar_today, color: Colors.white, size: 32),
                        ),
                        SizedBox(width: 16),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${tr('day_of')} $cycleDay ${tr('of_days')} $cycleLength',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(999)),
                            child: Text(cycleDay <= 5 ? tr('period_phase') :
                                 cycleDay >= 10 && cycleDay <= 16 ? tr('fertile_phase') :
                                 tr('regular_phase'),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          ),
                        ]),
                      ]),
                    ),
                  // Feature cards
                  Row(children: [
                    _buildCard(tr('cycle_tracking'), Icons.calendar_month, Colors.pink.shade50, Colors.pink, () => onCardTap?.call(1)),
                    SizedBox(width: 12),
                    _buildCard(tr('pregnancy_tracking'), Icons.pregnant_woman, Colors.purple.shade50, Colors.purple, () => onCardTap?.call(2)),
                  ]),
                  SizedBox(height: 12),
                  Row(children: [
                    _buildCard(tr('baby_care'), Icons.child_care, Colors.blue.shade50, Colors.blue, () => onCardTap?.call(3)),
                    SizedBox(width: 12),
                    _buildCard(tr('ai_assistant'), Icons.smart_toy, Colors.teal.shade50, Colors.teal, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AIChatPage()));
                    }),
                  ]),
                  SizedBox(height: 12),
                  // Community & Baby Names cards
                  Row(children: [
                    _buildCard(tr('community'), Icons.people, Colors.pink.shade50, Color(0xFFE91E63), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityScreen()));
                    }),
                    SizedBox(width: 12),
                    _buildCard('أسماء المواليد', Icons.child_care, Colors.purple.shade50, Color(0xFF7C4DFF), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BabyNamesScreen()));
                    }),
                  ]),
                  SizedBox(height: 12),
                  // Weight tracker & health trackers
                  Row(children: [
                    _buildCard('تتبع الوزن', Icons.monitor_weight, Colors.indigo.shade50, Color(0xFF5C6BC0), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => WeightTrackerScreen()));
                    }),
                    SizedBox(width: 12),
                    _buildCard('العدادات الصحية', Icons.monitor_heart, Colors.teal.shade50, Color(0xFF00897B), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HealthTrackersScreen()));
                    }),
                  ]),
                  SizedBox(height: 12),
                  // Calendar & more
                  Row(children: [
                    _buildCard('تقويم الحمل', Icons.calendar_month, Colors.orange.shade50, Color(0xFFFF7043), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PregnancyCalendarScreen()));
                    }),
                    SizedBox(width: 12),
                    _buildCard('حقيبة الولادة', Icons.card_travel, Colors.green.shade50, Color(0xFF66BB6A), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HospitalBagScreen()));
                    }),
                  ]),
                  SizedBox(height: 12),
                  Row(children: [
                    _buildCard('يوميات الحمل', Icons.auto_stories, Colors.pink.shade50, Color(0xFFE91E63), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PregnancyJournalScreen()));
                    }),
                    SizedBox(width: 12),
                    _buildCard('حجم الجنين', Icons.child_friendly, Colors.amber.shade50, Color(0xFFFF8F00), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FetusSizeScreen()));
                    }),
                  ]),
                  SizedBox(height: 12),
                  Row(children: [
                    _buildCard('العد التنازلي', Icons.timer, Colors.red.shade50, Color(0xFFE91E63), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DueDateCountdownScreen()));
                    }),
                    SizedBox(width: 12),
                    _buildCard('التغذية', Icons.restaurant_menu, Colors.green.shade50, Color(0xFF43A047), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => NutritionScreen()));
                    }),
                  ]),
                  SizedBox(height: 12),
                  Row(children: [
                    _buildCard('التمارين', Icons.fitness_center, Colors.purple.shade50, Color(0xFF7B1FA2), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ExercisesScreen()));
                    }),
                    SizedBox(width: 12),
                    _buildCard('مراحل الحمل', Icons.auto_awesome, Colors.cyan.shade50, Color(0xFF00ACC1), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PregnancyWeeksScreen()));
                    }),
                  ]),
                  SizedBox(height: 12),
                  Row(children: [
                    _buildCard('الإنجازات', Icons.emoji_events, Colors.amber.shade50, Color(0xFFFF8F00), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsScreen()));
                    }),
                    SizedBox(width: 12),
                    _buildCard('شاركي تقدمك', Icons.share, Colors.blue.shade50, Color(0xFF1565C0), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ShareProgressScreen()));
                    }),
                  ]),
                  SizedBox(height: 12),
                  // Reminders quick card
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RemindersPage())),
                    child: Container(
                      width: double.infinity, padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.amber.shade100, Colors.orange.shade50]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.notifications_active, color: Colors.orange.shade700, size: 28),
                        ),
                        SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('reminders'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange.shade800)),
                          Text(tr('reminders_subtitle'), style: TextStyle(color: Colors.orange.shade600, fontSize: 13)),
                        ])),
                        Icon(Icons.arrow_forward_ios, color: Colors.orange.shade400, size: 18),
                      ]),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(tr('quick_tips'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _tipCard(tr('tip_water'), Icons.water_drop, Colors.blue),
                  SizedBox(height: 8),
                  _tipCard(tr('tip_sleep'), Icons.bedtime, Colors.indigo),
                  SizedBox(height: 8),
                  _tipCard(tr('tip_walk'), Icons.directions_walk, Colors.green),
                  SizedBox(height: 28),
                  // ─── Home Articles from Firestore ───
                  _HomeArticlesSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
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

  Widget _buildCard(String title, IconData icon, Color bg, Color fg, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: fg.withOpacity(0.12), blurRadius: 12, offset: Offset(0, 6)),
              BoxShadow(color: const Color(0x0AE91E63), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(color: fg.withOpacity(0.15), borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, size: 32, color: fg),
            ),
            SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: fg, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  Widget _tipCard(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0x0AE91E63), blurRadius: 8, offset: Offset(0, 2)),
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4)),
        ],
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 22),
        ),
        SizedBox(width: 14),
        Expanded(child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF4A434B)))),
      ]),
    );
  }
}

// ==================== CYCLE PAGE (FIRESTORE) ====================
class CyclePage extends StatefulWidget {
  @override
  State<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends State<CyclePage> {
  String mood = '';
  List<String> symptoms = [];
  final allSymptoms = ['\u062A\u0634\u0646\u062C\u0627\u062A', '\u0635\u062F\u0627\u0639', '\u0625\u0631\u0647\u0627\u0642', '\u0627\u0646\u062A\u0641\u0627\u062E', '\u0622\u0644\u0627\u0645 \u0627\u0644\u0638\u0647\u0631', '\u062A\u0642\u0644\u0628\u0627\u062A \u0645\u0632\u0627\u062C\u064A\u0629'];

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
          symptoms = List<String>.from(d['symptoms'] ?? []);
        });
      }
    } catch (_) {}
    // loaded
  }

  Future<void> _saveTodayLog() async {
    await DB.cycleLogs.doc(DB.dateKey()).set({
      'date': DB.dateKey(),
      'mood': mood,
      'symptoms': symptoms,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _startPeriod() async {
    await DB.userDoc.set({'lastPeriodStart': Timestamp.now()}, SetOptions(merge: true));
    await DB.cycleLogs.doc(DB.dateKey()).set({
      'date': DB.dateKey(),
      'isPeriod': true,
      'mood': mood,
      'symptoms': symptoms,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u062A\u0645 \u062A\u0633\u062C\u064A\u0644 \u0628\u062F\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629'), backgroundColor: Colors.pink));
    }
  }

  Future<void> _endPeriod() async {
    await DB.cycleLogs.doc(DB.dateKey()).set({
      'date': DB.dateKey(),
      'isPeriod': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u062A\u0645 \u062A\u0633\u062C\u064A\u0644 \u0646\u0647\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629'), backgroundColor: Colors.grey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062F\u0648\u0631\u0629'), backgroundColor: Colors.pink, foregroundColor: Colors.white),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DB.userDoc.snapshots(),
        builder: (context, snapshot) {
          int cycleLength = 28;
          int cycleDay = 1;
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
          double progress = cycleDay / cycleLength;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(children: [
              // Circular progress
              Container(
                width: 200, height: 200,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(width: 180, height: 180,
                    child: CircularProgressIndicator(value: progress, strokeWidth: 12,
                      backgroundColor: Colors.pink.shade50, color: Colors.pink)),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('\u0627\u0644\u064A\u0648\u0645 $cycleDay', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pink)),
                    Text('\u0645\u0646 $cycleLength \u064A\u0648\u0645', style: TextStyle(color: Colors.grey)),
                  ]),
                ]),
              ),
              SizedBox(height: 24),
              // Action buttons
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _cycleBtn('\u0628\u062F\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629', Icons.play_arrow, Colors.red, _startPeriod),
                _cycleBtn('\u0646\u0647\u0627\u064A\u0629 \u0627\u0644\u062F\u0648\u0631\u0629', Icons.stop, Colors.grey, _endPeriod),
                _cycleBtn('\u062D\u0641\u0638 \u0627\u0644\u064A\u0648\u0645', Icons.save, Colors.pink, () async {
                  await _saveTodayLog();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('\u062A\u0645 \u062D\u0641\u0638 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u064A\u0648\u0645'), backgroundColor: Colors.green));
                }),
              ]),
              SizedBox(height: 24),
              // Mood
              Align(alignment: Alignment.centerRight,
                child: Text('\u0627\u0644\u0645\u0632\u0627\u062C \u0627\u0644\u064A\u0648\u0645', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _moodBtn('\u0645\u0645\u062A\u0627\u0632', '\u{1F60A}'), _moodBtn('\u062C\u064A\u062F', '\u{1F642}'),
                _moodBtn('\u0639\u0627\u062F\u064A', '\u{1F610}'), _moodBtn('\u0633\u064A\u0626', '\u{1F622}'), _moodBtn('\u0633\u064A\u0626 \u062C\u062F\u0627\u064B', '\u{1F62B}'),
              ]),
              SizedBox(height: 24),
              // Symptoms
              Align(alignment: Alignment.centerRight,
                child: Text('\u0627\u0644\u0623\u0639\u0631\u0627\u0636', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: allSymptoms.map((s) =>
                FilterChip(
                  label: Text(s),
                  selected: symptoms.contains(s),
                  onSelected: (v) => setState(() { v ? symptoms.add(s) : symptoms.remove(s); }),
                  selectedColor: Colors.pink.shade100,
                )).toList()),
              SizedBox(height: 24),
              // Cycle insights
              Container(
                width: double.infinity, padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('\u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u062F\u0648\u0631\u0629', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0642\u0627\u062F\u0645\u0629: \u0628\u0639\u062F ~${cycleLength - cycleDay} \u064A\u0648\u0645'),
                  Text('\u0641\u062A\u0631\u0629 \u0627\u0644\u062E\u0635\u0648\u0628\u0629: \u0627\u0644\u064A\u0648\u0645 ${(cycleLength * 0.36).round()}-${(cycleLength * 0.57).round()}'),
                  Text('\u0627\u0644\u0625\u0628\u0627\u0636\u0629: ~\u0627\u0644\u064A\u0648\u0645 ${(cycleLength * 0.5).round()}'),
                ]),
              ),
              SizedBox(height: 16),
              // Cycle length setting
              Container(
                width: double.infinity, padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Text('\u0637\u0648\u0644 \u0627\u0644\u062F\u0648\u0631\u0629:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Spacer(),
                  IconButton(icon: Icon(Icons.remove_circle_outline, color: Colors.pink),
                    onPressed: () async {
                      if (cycleLength > 20) {
                        await DB.userDoc.set({'cycleLength': cycleLength - 1}, SetOptions(merge: true));
                      }
                    }),
                  Text('$cycleLength \u064A\u0648\u0645', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: Icon(Icons.add_circle_outline, color: Colors.pink),
                    onPressed: () async {
                      if (cycleLength < 45) {
                        await DB.userDoc.set({'cycleLength': cycleLength + 1}, SetOptions(merge: true));
                      }
                    }),
                ]),
              ),
              SizedBox(height: 24),
              // \u2500\u2500\u2500 Articles & Tips (Firestore) \u2500\u2500\u2500
              _CycleArticlesSection(),
            ]),
          );
        },
      ),
    );
  }

  Widget _cycleBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        CircleAvatar(radius: 24, backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color)),
        SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 11)),
      ]),
    );
  }

  Widget _moodBtn(String label, String emoji) {
    bool sel = mood == label;
    return GestureDetector(
      onTap: () => setState(() => mood = label),
      child: Column(children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: sel ? Colors.pink.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: sel ? Border.all(color: Colors.pink, width: 2) : null),
          child: Text(emoji, style: TextStyle(fontSize: 28))),
        SizedBox(height: 4), Text(label, style: TextStyle(fontSize: 11)),
      ]),
    );
  }
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
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(centerTitle: true,
              title: Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062D\u0645\u0644'),
              backgroundColor: Colors.purple, foregroundColor: Colors.white,
              actions: [
                IconButton(icon: Icon(Icons.date_range), onPressed: _setPregnancyStart,
                  tooltip: '\u062A\u062D\u062F\u064A\u062F \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629'),
              ],
            ),
            body: _noPregnancy(),
          );
        }
        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        if (data['pregnancyStartDate'] == null) {
          return Scaffold(
            appBar: AppBar(centerTitle: true,
              title: Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062D\u0645\u0644'),
              backgroundColor: Colors.purple, foregroundColor: Colors.white,
              actions: [
                IconButton(icon: Icon(Icons.date_range), onPressed: _setPregnancyStart,
                  tooltip: '\u062A\u062D\u062F\u064A\u062F \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629'),
              ],
            ),
            body: _noPregnancy(),
          );
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
        padding: EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.pregnant_woman, size: 80, color: Colors.purple.shade200),
          SizedBox(height: 20),
          Text('\u0644\u0645 \u064A\u062A\u0645 \u062A\u062D\u062F\u064A\u062F \u062A\u0627\u0631\u064A\u062E \u0627\u0644\u062D\u0645\u0644',
            style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _setPregnancyStart,
            icon: Icon(Icons.date_range),
            label: Text('\u062D\u062F\u062F\u064A \u062A\u0627\u0631\u064A\u062E \u0622\u062E\u0631 \u062F\u0648\u0631\u0629'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white)),
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
  Future<void> _setBabyInfo() async {
    final nameC = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('\u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameC,
            decoration: InputDecoration(labelText: '\u0627\u0633\u0645 \u0627\u0644\u0637\u0641\u0644',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now().subtract(Duration(days: 90)),
                firstDate: DateTime.now().subtract(Duration(days: 365 * 3)),
                lastDate: DateTime.now(),
                helpText: '\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0645\u064A\u0644\u0627\u062F',
              );
              if (date != null) {
                Navigator.pop(ctx, {'name': nameC.text, 'birthDate': date});
              }
            },
            child: Text('\u0627\u062E\u062A\u0627\u0631\u064A \u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0645\u064A\u0644\u0627\u062F'),
          ),
        ]),
      ),
    );
    if (result != null) {
      await DB.userDoc.set({
        'babyName': result['name'],
        'babyBirthDate': Timestamp.fromDate(result['birthDate']),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _addLog(String type) async {
    final doc = DB.babyLogs.doc(DB.dateKey());
    final snap = await doc.get();
    Map<String, dynamic> data = {};
    if (snap.exists) data = snap.data() as Map<String, dynamic>? ?? {};

    int current = (data[type] as int?) ?? 0;
    data[type] = current + 1;
    data['date'] = DB.dateKey();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data, SetOptions(merge: true));
  }

  Future<void> _updateGrowth(String field, double value) async {
    await DB.userDoc.set({
      'baby_$field': value,
      'baby_${field}_date': DB.dateKey(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true,
        title: Text('\u0631\u0639\u0627\u064A\u0629 \u0627\u0644\u0637\u0641\u0644'),
        backgroundColor: Colors.blue, foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.edit), onPressed: _setBabyInfo,
            tooltip: '\u062A\u0639\u062F\u064A\u0644 \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644'),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: DB.userDoc.snapshots(),
        builder: (context, userSnap) {
          Map<String, dynamic> userData = {};
          if (userSnap.hasData && userSnap.data!.exists) {
            userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
          }
          String babyName = userData['babyName'] ?? '';
          String ageText = '';
          if (userData['babyBirthDate'] != null) {
            try {
              Timestamp ts = userData['babyBirthDate'];
              int days = DateTime.now().difference(ts.toDate()).inDays;
              if (days < 30) ageText = '$days \u064A\u0648\u0645';
              else if (days < 365) ageText = '${(days / 30).floor()} \u0623\u0634\u0647\u0631';
              else ageText = '${(days / 365).floor()} \u0633\u0646\u0629 \u0648 ${((days % 365) / 30).floor()} \u0623\u0634\u0647\u0631';
            } catch (_) {}
          }
          double weight = (userData['baby_weight'] as num?)?.toDouble() ?? 0;
          double height = (userData['baby_height'] as num?)?.toDouble() ?? 0;

          if (babyName.isEmpty && userData['babyBirthDate'] == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.child_care, size: 80, color: Colors.blue.shade200),
                  SizedBox(height: 20),
                  Text('\u0644\u0645 \u064A\u062A\u0645 \u0625\u0636\u0627\u0641\u0629 \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644',
                    style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _setBabyInfo,
                    icon: Icon(Icons.add),
                    label: Text('\u0623\u0636\u064A\u0641\u064A \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)),
                ]),
              ),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: DB.babyLogs.doc(DB.dateKey()).snapshots(),
            builder: (context, logSnap) {
              Map<String, dynamic> log = {};
              if (logSnap.hasData && logSnap.data!.exists) {
                log = logSnap.data!.data() as Map<String, dynamic>? ?? {};
              }
              int feeding = (log['feeding'] as int?) ?? 0;
              int sleep = (log['sleep'] as int?) ?? 0;
              int diaper = (log['diaper'] as int?) ?? 0;

              return SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Baby header
                  Container(
                    width: double.infinity, padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade100]),
                      borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Icon(Icons.child_care, size: 60, color: Colors.white),
                      SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(babyName.isEmpty ? '\u0637\u0641\u0644\u064A' : babyName,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (ageText.isNotEmpty)
                          Text('\u0627\u0644\u0639\u0645\u0631: $ageText', style: TextStyle(color: Colors.white70)),
                      ]),
                    ]),
                  ),
                  SizedBox(height: 20),
                  // Growth
                  Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u0646\u0645\u0648', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(children: [
                    _growthCard('\u0627\u0644\u0648\u0632\u0646', weight > 0 ? '${weight.toStringAsFixed(1)} \u0643\u063A' : '-- \u0643\u063A',
                      Icons.monitor_weight, Colors.orange, () => _showGrowthInput('\u0627\u0644\u0648\u0632\u0646 (\u0643\u063A)', 'weight')),
                    SizedBox(width: 12),
                    _growthCard('\u0627\u0644\u0637\u0648\u0644', height > 0 ? '${height.toStringAsFixed(0)} \u0633\u0645' : '-- \u0633\u0645',
                      Icons.height, Colors.green, () => _showGrowthInput('\u0627\u0644\u0637\u0648\u0644 (\u0633\u0645)', 'height')),
                  ]),
                  SizedBox(height: 20),
                  // Daily log
                  Text('\u0627\u0644\u0633\u062C\u0644 \u0627\u0644\u064A\u0648\u0645\u064A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _logItem('\u0627\u0644\u0631\u0636\u0627\u0639\u0629', '$feeding \u0645\u0631\u0629', Icons.restaurant, Colors.orange, () => _addLog('feeding')),
                  _logItem('\u0627\u0644\u0646\u0648\u0645', '$sleep \u0633\u0627\u0639\u0629', Icons.bedtime, Colors.indigo, () => _addLog('sleep')),
                  _logItem('\u0627\u0644\u062D\u0641\u0627\u0636', '$diaper \u062A\u063A\u064A\u064A\u0631', Icons.baby_changing_station, Colors.teal, () => _addLog('diaper')),
                  SizedBox(height: 20),
                  // Vaccines
                  Text('\u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _vaccineItem('\u0644\u0642\u0627\u062D \u0627\u0644\u062A\u0647\u0627\u0628 \u0627\u0644\u0643\u0628\u062F \u0628', 'hepb'),
                  _vaccineItem('\u0644\u0642\u0627\u062D BCG', 'bcg'),
                  _vaccineItem('\u0627\u0644\u0644\u0642\u0627\u062D \u0627\u0644\u062B\u0644\u0627\u062B\u064A', 'dtap'),
                  _vaccineItem('\u0644\u0642\u0627\u062D \u0634\u0644\u0644 \u0627\u0644\u0623\u0637\u0641\u0627\u0644', 'polio'),
                  _vaccineItem('\u0644\u0642\u0627\u062D \u0627\u0644\u062D\u0635\u0628\u0629', 'mmr'),
                  SizedBox(height: 24),
                  _BabyArticlesSection(),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  void _showGrowthInput(String label, String field) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('\u0625\u0644\u063A\u0627\u0621')),
          ElevatedButton(
            onPressed: () {
              double? val = double.tryParse(controller.text);
              if (val != null) {
                _updateGrowth(field, val);
                Navigator.pop(ctx);
              }
            },
            child: Text('\u062D\u0641\u0638')),
        ],
      ),
    );
  }

  Widget _growthCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Icon(icon, color: color, size: 32), SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text('\u0627\u0636\u063A\u0637\u064A \u0644\u0644\u062A\u062D\u062F\u064A\u062B', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  Widget _logItem(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 20)),
            SizedBox(width: 14),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Spacer(),
            Text(value, style: TextStyle(color: Colors.grey.shade700)),
            SizedBox(width: 8),
            Icon(Icons.add_circle, color: color, size: 24),
          ]),
        ),
      ),
    );
  }

  Widget _vaccineItem(String name, String key) {
    return StreamBuilder<DocumentSnapshot>(
      stream: DB.userDoc.collection('vaccines').doc(key).snapshots(),
      builder: (context, snap) {
        bool done = false;
        if (snap.hasData && snap.data!.exists) {
          done = (snap.data!.data() as Map<String, dynamic>?)?['done'] ?? false;
        }
        return InkWell(
          onTap: () {
            DB.userDoc.collection('vaccines').doc(key).set({
              'name': name, 'done': !done, 'updatedAt': FieldValue.serverTimestamp()
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: done ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(done ? Icons.check_circle : Icons.schedule,
                  color: done ? Colors.green : Colors.orange),
                SizedBox(width: 10),
                Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Text(done ? '\u0645\u0643\u062A\u0645\u0644' : '\u0642\u0627\u062F\u0645',
                  style: TextStyle(fontSize: 12, color: done ? Colors.green : Colors.orange)),
              ]),
            ),
          ),
        );
      },
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

  Widget _firestoreArticleCard(BuildContext context, String title, String content, String imageUrl, List<String> contentImages, Color cardColor) {
    final hasImage = imageUrl.isNotEmpty;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => _ArticleDetailPage(title: title, body: content, color: cardColor, imageUrl: imageUrl, contentImages: contentImages))),
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
              child: Image.network(imageUrl, height: 100, width: 260, fit: BoxFit.cover,
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
  @override
  Widget build(BuildContext context) => _FirestoreArticlesSection(type: 'cycle', color: Colors.pink);
}

class _BabyArticlesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _FirestoreArticlesSection(type: 'baby', color: Colors.blue);
}

class _HomeArticlesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'صحة المرأة', 'icon': Icons.favorite, 'color': Colors.pink},
      {'name': 'تغذية وجمال', 'icon': Icons.spa, 'color': Colors.purple},
      {'name': 'صحة نفسية', 'icon': Icons.psychology, 'color': Colors.teal},
      {'name': 'أمومة وطفولة', 'icon': Icons.child_care, 'color': Colors.blue},
      {'name': 'رياضة ولياقة', 'icon': Icons.fitness_center, 'color': Colors.orange},
      {'name': 'وصفات صحية', 'icon': Icons.restaurant, 'color': Colors.green},
      {'name': 'علاقات أسرية', 'icon': Icons.people, 'color': Colors.indigo},
      {'name': 'نصائح طبية', 'icon': Icons.medical_services, 'color': Colors.red},
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('articles')
        .where('type', isEqualTo: 'home')
        .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SizedBox.shrink();
        }
        final allDocs = snapshot.data!.docs;
        // Group by category
        final grouped = <String, List<QueryDocumentSnapshot>>{};
        for (final doc in allDocs) {
          final cat = (doc.data() as Map<String, dynamic>)['category'] ?? '';
          grouped.putIfAbsent(cat, () => []).add(doc);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مقالات ونصائح', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1F1A20))),
            SizedBox(height: 4),
            Text('آخر المقالات في مختلف المجالات', style: TextStyle(fontSize: 14, color: const Color(0xFF8B8190))),
            SizedBox(height: 16),
            for (final catInfo in categories)
              if (grouped.containsKey(catInfo['name']))
                _buildHomeSection(
                  context,
                  catInfo['name'] as String,
                  catInfo['icon'] as IconData,
                  catInfo['color'] as Color,
                  grouped[catInfo['name']]!,
                ),
          ],
        );
      },
    );
  }

  Widget _buildHomeSection(BuildContext context, String title, IconData icon, Color color, List<QueryDocumentSnapshot> docs) {
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
            itemCount: docs.length,
            padding: EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final imgUrl = data['imageUrl'] ?? '';
              final articleTitle = data['title'] ?? '';
              final content = data['content'] ?? '';
              final contentImages = List<String>.from(data['contentImages'] ?? []);
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => _ArticleDetailPage(
                    title: articleTitle, body: content, color: color,
                    imageUrl: imgUrl, contentImages: contentImages,
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
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      child: imgUrl.isNotEmpty
                        ? Image.network(imgUrl, height: 120, width: 200, fit: BoxFit.cover,
                            loadingBuilder: (c, child, progress) => progress == null ? child
                              : Container(height: 120, width: 200, color: color.withOpacity(0.05),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: color))),
                            errorBuilder: (c, e, s) => Container(height: 120, width: 200,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
                              ),
                              child: Icon(icon, size: 40, color: color.withOpacity(0.4)),
                            ),
                          )
                        : Container(height: 120, width: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
                            ),
                            child: Icon(icon, size: 40, color: color.withOpacity(0.4)),
                          ),
                    ),
                    // Title & preview
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
class _ArticleDetailPage extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final String imageUrl;
  final List<String> contentImages;
  const _ArticleDetailPage({required this.title, required this.body, required this.color, this.imageUrl = '', this.contentImages = const []});

  @override
  Widget build(BuildContext context) {
    final hasHeaderImage = imageUrl.isNotEmpty;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: TextStyle(fontSize: 18)),
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          color: Color(0xFFFFF8FB),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header image
              if (hasHeaderImage)
                Image.network(imageUrl, height: 220, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 220,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)])),
                    child: Center(child: Icon(Icons.image, color: color.withOpacity(0.3), size: 60)))),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!hasHeaderImage)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Icon(Icons.article_outlined, color: color, size: 40),
                        SizedBox(width: 14),
                        Expanded(child: Text(title,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F1A20)))),
                      ]),
                    )
                  else ...[
                    Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F1A20))),
                    SizedBox(height: 20),
                  ],
                  ...body.split('\n\n').map((para) => Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(para.trim(),
                      style: TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF4A434B))),
                  )),
                  // Content images
                  if (contentImages.isNotEmpty) ...[
                    SizedBox(height: 10),
                    ...contentImages.map((url) => Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(url, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => SizedBox.shrink()),
                      ),
                    )),
                  ],
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, color: color, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('هذا المقال للأغراض التثقيفية فقط. استشيري طبيبتك للحصول على نصيحة طبية شخصية.',
                        style: TextStyle(fontSize: 13, color: color.withOpacity(0.8), fontStyle: FontStyle.italic))),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
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
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              if (data['name'] != null && (data['name'] as String).isNotEmpty) {
                name = data['name'];
              }
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
                    // Avatar with gradient border
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [const Color(0xFFE91E63), const Color(0xFF7E57C2)]),
                        boxShadow: [BoxShadow(color: const Color(0x40E91E63), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: CircleAvatar(radius: 48, backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 56, color: const Color(0xFF00897B))),
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

class _AIChatPageState extends State<AIChatPage> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = false;
  final String _apiKey = 'AIzaSyB09gZH8igVPtC0yfPA5Twfp3KU0dC-kTI';

  // Quick suggestion buttons
  final quickQuestions = [
    '\u0645\u0627 \u0647\u064A \u0623\u0639\u0631\u0627\u0636 \u0627\u0644\u062D\u0645\u0644 \u0627\u0644\u0645\u0628\u0643\u0631\u061F',
    '\u0643\u064A\u0641 \u0623\u062E\u0641\u0641 \u0622\u0644\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629\u061F',
    '\u0645\u0627 \u0647\u064A \u0627\u0644\u0623\u0637\u0639\u0645\u0629 \u0627\u0644\u0645\u0641\u064A\u062F\u0629 \u0644\u0644\u062D\u0627\u0645\u0644\u061F',
    '\u0643\u064A\u0641 \u0623\u0639\u062A\u0646\u064A \u0628\u0637\u0641\u0644\u064A \u0627\u0644\u0631\u0636\u064A\u0639\u061F',
    '\u0645\u062A\u0649 \u064A\u062C\u0628 \u0632\u064A\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628\u061F',
    '\u0646\u0635\u0627\u0626\u062D \u0644\u0644\u0631\u0636\u0627\u0639\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629',
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    messages.add({
      'role': 'assistant',
      'text': '\u0645\u0631\u062D\u0628\u0627\u064B! \u0623\u0646\u0627 \u0627\u0644\u0645\u0633\u0627\u0639\u062F \u0627\u0644\u0630\u0643\u064A \u0644\u062A\u0637\u0628\u064A\u0642 \u0646\u0628\u0636\u0629. \u064A\u0645\u0643\u0646\u0646\u064A \u0645\u0633\u0627\u0639\u062F\u062A\u0643 \u0641\u064A \u0623\u0633\u0626\u0644\u0629 \u0635\u062D\u0629 \u0627\u0644\u0645\u0631\u0623\u0629 \u0648\u0627\u0644\u062D\u0645\u0644 \u0648\u0631\u0639\u0627\u064A\u0629 \u0627\u0644\u0637\u0641\u0644.\n\n\u0627\u062E\u062A\u0627\u0631\u064A \u0633\u0624\u0627\u0644\u0627\u064B \u0623\u0648 \u0627\u0643\u062A\u0628\u064A \u0633\u0624\u0627\u0644\u0643 \u0628\u0627\u0644\u0623\u0633\u0641\u0644 \u{1F49C}',
    });
  }

  // ===== Smart Health Knowledge Base =====
  static final Map<String, String> _healthKB = {
    // Period / Cycle
    '\u0622\u0644\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629|\u062A\u0634\u0646\u062C\u0627\u062A|\u0623\u0644\u0645 \u0627\u0644\u062F\u0648\u0631\u0629|\u062A\u062E\u0641\u064A\u0641 \u0627\u0644\u062F\u0648\u0631\u0629':
      '\u0644\u062A\u062E\u0641\u064A\u0641 \u0622\u0644\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0634\u0647\u0631\u064A\u0629:\n\n\u2022 \u0636\u0639\u064A \u0643\u0645\u0627\u062F\u0629 \u062F\u0627\u0641\u0626\u0629 \u0639\u0644\u0649 \u0623\u0633\u0641\u0644 \u0627\u0644\u0628\u0637\u0646 \u0644\u0645\u062F\u0629 15-20 \u062F\u0642\u064A\u0642\u0629\n\u2022 \u0645\u0627\u0631\u0633\u064A \u0631\u064A\u0627\u0636\u0629 \u062E\u0641\u064A\u0641\u0629 \u0643\u0627\u0644\u0645\u0634\u064A \u0623\u0648 \u0627\u0644\u064A\u0648\u063A\u0627\n\u2022 \u0627\u0634\u0631\u0628\u064A \u0645\u0634\u0631\u0648\u0628\u0627\u062A \u062F\u0627\u0641\u0626\u0629 \u0643\u0627\u0644\u0628\u0627\u0628\u0648\u0646\u062C \u0648\u0627\u0644\u0632\u0646\u062C\u0628\u064A\u0644 \u0648\u0627\u0644\u0642\u0631\u0641\u0629\n\u2022 \u062A\u062C\u0646\u0628\u064A \u0627\u0644\u0643\u0627\u0641\u064A\u064A\u0646 \u0648\u0627\u0644\u0623\u0637\u0639\u0645\u0629 \u0627\u0644\u0645\u0627\u0644\u062D\u0629\n\u2022 \u062F\u0644\u0643\u064A \u0645\u0646\u0637\u0642\u0629 \u0627\u0644\u0628\u0637\u0646 \u0628\u062D\u0631\u0643\u0627\u062A \u062F\u0627\u0626\u0631\u064A\u0629\n\u2022 \u064A\u0645\u0643\u0646 \u062A\u0646\u0627\u0648\u0644 \u0645\u0633\u0643\u0646 \u062E\u0641\u064A\u0641 \u0639\u0646\u062F \u0627\u0644\u062D\u0627\u062C\u0629\n\n\u0625\u0630\u0627 \u0643\u0627\u0646 \u0627\u0644\u0623\u0644\u0645 \u0634\u062F\u064A\u062F\u0627\u064B \u062C\u062F\u0627\u064B \u0623\u0648 \u064A\u0645\u0646\u0639\u0643 \u0645\u0646 \u0645\u0645\u0627\u0631\u0633\u0629 \u062D\u064A\u0627\u062A\u0643 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629\u060C \u0627\u0633\u062A\u0634\u064A\u0631\u064A \u0637\u0628\u064A\u0628\u062A\u0643.',
    '\u0627\u0646\u062A\u0638\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629|\u062A\u0623\u062E\u0631 \u0627\u0644\u062F\u0648\u0631\u0629|\u0639\u062F\u0645 \u0627\u0646\u062A\u0638\u0627\u0645|\u062F\u0648\u0631\u0629 \u063A\u064A\u0631 \u0645\u0646\u062A\u0638\u0645\u0629':
      '\u0639\u062F\u0645 \u0627\u0646\u062A\u0638\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629 \u0642\u062F \u064A\u0643\u0648\u0646 \u0628\u0633\u0628\u0628:\n\n\u2022 \u0627\u0644\u062A\u0648\u062A\u0631 \u0648\u0627\u0644\u0636\u063A\u0637 \u0627\u0644\u0646\u0641\u0633\u064A\n\u2022 \u062A\u063A\u064A\u0631 \u0627\u0644\u0648\u0632\u0646 \u0627\u0644\u0645\u0641\u0627\u062C\u0626\n\u2022 \u0627\u0636\u0637\u0631\u0627\u0628\u0627\u062A \u0647\u0631\u0645\u0648\u0646\u064A\u0629 \u0645\u062B\u0644 \u062A\u0643\u064A\u0633 \u0627\u0644\u0645\u0628\u0627\u064A\u0636\n\u2022 \u0645\u0634\u0627\u0643\u0644 \u0627\u0644\u063A\u062F\u0629 \u0627\u0644\u062F\u0631\u0642\u064A\u0629\n\u2022 \u0627\u0644\u0631\u064A\u0627\u0636\u0629 \u0627\u0644\u0645\u0641\u0631\u0637\u0629\n\n\u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629 \u0628\u064A\u0646 21-35 \u064A\u0648\u0645\u0627\u064B. \u0625\u0630\u0627 \u062A\u0623\u062E\u0631\u062A \u0623\u0643\u062B\u0631 \u0645\u0646 3 \u0623\u0634\u0647\u0631\u060C \u0631\u0627\u062C\u0639\u064A \u0627\u0644\u0637\u0628\u064A\u0628\u0629.',
    '\u0627\u0644\u062A\u0628\u0648\u064A\u0636|\u0625\u0628\u0627\u0636\u0629|\u062E\u0635\u0648\u0628\u0629|\u0623\u064A\u0627\u0645 \u0627\u0644\u062A\u0628\u0648\u064A\u0636':
      '\u0641\u062A\u0631\u0629 \u0627\u0644\u062A\u0628\u0648\u064A\u0636 \u0647\u064A \u0627\u0644\u0641\u062A\u0631\u0629 \u0627\u0644\u062A\u064A \u062A\u0643\u0648\u0646 \u0641\u064A\u0647\u0627 \u0627\u0644\u062E\u0635\u0648\u0628\u0629 \u0641\u064A \u0623\u0639\u0644\u0649 \u0645\u0633\u062A\u0648\u064A\u0627\u062A\u0647\u0627:\n\n\u2022 \u062A\u062D\u062F\u062B \u0639\u0627\u062F\u0629 \u0641\u064A \u0627\u0644\u064A\u0648\u0645 14 \u0645\u0646 \u0627\u0644\u062F\u0648\u0631\u0629 (\u0644\u0644\u062F\u0648\u0631\u0629 28 \u064A\u0648\u0645\u0627\u064B)\n\u2022 \u0639\u0644\u0627\u0645\u0627\u062A\u0647\u0627: \u0625\u0641\u0631\u0627\u0632\u0627\u062A \u0634\u0641\u0627\u0641\u0629\u060C \u0627\u0631\u062A\u0641\u0627\u0639 \u0637\u0641\u064A\u0641 \u0641\u064A \u062F\u0631\u062C\u0629 \u0627\u0644\u062D\u0631\u0627\u0631\u0629\n\u2022 \u0623\u064A\u0627\u0645 \u0627\u0644\u062E\u0635\u0648\u0628\u0629: 5 \u0623\u064A\u0627\u0645 \u0642\u0628\u0644 \u0627\u0644\u062A\u0628\u0648\u064A\u0636 + \u064A\u0648\u0645 \u0627\u0644\u062A\u0628\u0648\u064A\u0636\n\u2022 \u062A\u0637\u0628\u064A\u0642 \u0646\u0628\u0636\u0629 \u064A\u0633\u0627\u0639\u062F\u0643 \u0641\u064A \u062A\u062A\u0628\u0639 \u0647\u0630\u0647 \u0627\u0644\u0623\u064A\u0627\u0645 \u062A\u0644\u0642\u0627\u0626\u064A\u0627\u064B',
    // Pregnancy
    '\u0623\u0639\u0631\u0627\u0636 \u0627\u0644\u062D\u0645\u0644|\u0639\u0644\u0627\u0645\u0627\u062A \u0627\u0644\u062D\u0645\u0644|\u062D\u0645\u0644 \u0645\u0628\u0643\u0631':
      '\u0623\u0639\u0631\u0627\u0636 \u0627\u0644\u062D\u0645\u0644 \u0627\u0644\u0645\u0628\u0643\u0631\u0629 \u062A\u0634\u0645\u0644:\n\n\u2022 \u062A\u0623\u062E\u0631 \u0627\u0644\u062F\u0648\u0631\u0629 \u0627\u0644\u0634\u0647\u0631\u064A\u0629 (\u0623\u0648\u0644 \u0639\u0644\u0627\u0645\u0629)\n\u2022 \u063A\u062B\u064A\u0627\u0646 \u0648\u062A\u0642\u064A\u0624 (\u062E\u0627\u0635\u0629 \u0635\u0628\u0627\u062D\u0627\u064B)\n\u2022 \u062A\u0639\u0628 \u0648\u0625\u0631\u0647\u0627\u0642 \u063A\u064A\u0631 \u0639\u0627\u062F\u064A\n\u2022 \u0627\u0646\u062A\u0641\u0627\u062E \u0648\u062D\u0633\u0627\u0633\u064A\u0629 \u0627\u0644\u062B\u062F\u064A\n\u2022 \u0643\u062B\u0631\u0629 \u0627\u0644\u062A\u0628\u0648\u0644\n\u2022 \u062A\u0642\u0644\u0628\u0627\u062A \u0645\u0632\u0627\u062C\u064A\u0629\n\u2022 \u0646\u0641\u0648\u0631 \u0645\u0646 \u0628\u0639\u0636 \u0627\u0644\u0623\u0637\u0639\u0645\u0629 \u0648\u0627\u0644\u0631\u0648\u0627\u0626\u062D\n\n\u0644\u0644\u062A\u0623\u0643\u062F\u060C \u0627\u0639\u0645\u0644\u064A \u0627\u062E\u062A\u0628\u0627\u0631 \u062D\u0645\u0644 \u0645\u0646\u0632\u0644\u064A \u0623\u0648 \u062A\u062D\u0644\u064A\u0644 \u062F\u0645.',
    '\u063A\u0630\u0627\u0621 \u0627\u0644\u062D\u0627\u0645\u0644|\u0623\u0637\u0639\u0645\u0629 \u0627\u0644\u062D\u0627\u0645\u0644|\u062A\u063A\u0630\u064A\u0629 \u0627\u0644\u062D\u0627\u0645\u0644|\u0623\u0643\u0644 \u0627\u0644\u062D\u0627\u0645\u0644':
      '\u0627\u0644\u062A\u063A\u0630\u064A\u0629 \u0627\u0644\u0633\u0644\u064A\u0645\u0629 \u0644\u0644\u062D\u0627\u0645\u0644:\n\n\u2714\uFE0F \u0623\u0637\u0639\u0645\u0629 \u0645\u0641\u064A\u062F\u0629:\n\u2022 \u0627\u0644\u062E\u0636\u0631\u0648\u0627\u062A \u0627\u0644\u0648\u0631\u0642\u064A\u0629 (\u0627\u0644\u0633\u0628\u0627\u0646\u062E\u060C \u0627\u0644\u0628\u0631\u0648\u0643\u0644\u064A)\n\u2022 \u0627\u0644\u0641\u0648\u0627\u0643\u0647 \u0627\u0644\u0637\u0627\u0632\u062C\u0629 \u0648\u0627\u0644\u0645\u0643\u0633\u0631\u0627\u062A\n\u2022 \u0627\u0644\u0628\u0631\u0648\u062A\u064A\u0646 (\u062F\u062C\u0627\u062C\u060C \u0633\u0645\u0643\u060C \u0628\u064A\u0636\u060C \u0628\u0642\u0648\u0644\u064A\u0627\u062A)\n\u2022 \u0627\u0644\u062D\u0644\u064A\u0628 \u0648\u0645\u0634\u062A\u0642\u0627\u062A\u0647\n\u2022 \u0627\u0644\u062D\u0628\u0648\u0628 \u0627\u0644\u0643\u0627\u0645\u0644\u0629\n\n\u274C \u062A\u062C\u0646\u0628\u064A:\n\u2022 \u0627\u0644\u0623\u0633\u0645\u0627\u0643 \u0627\u0644\u0639\u0627\u0644\u064A\u0629 \u0628\u0627\u0644\u0632\u0626\u0628\u0642\n\u2022 \u0627\u0644\u0644\u062D\u0648\u0645 \u0627\u0644\u0646\u064A\u0626\u0629\n\u2022 \u0627\u0644\u0643\u0627\u0641\u064A\u064A\u0646 \u0628\u0643\u0645\u064A\u0627\u062A \u0643\u0628\u064A\u0631\u0629\n\u2022 \u0627\u0644\u0623\u062C\u0628\u0627\u0646 \u0627\u0644\u0637\u0631\u064A\u0629 \u063A\u064A\u0631 \u0627\u0644\u0645\u0628\u0633\u062A\u0631\u0629\n\n\u0644\u0627 \u062A\u0646\u0633\u064A \u062A\u0646\u0627\u0648\u0644 \u062D\u0645\u0636 \u0627\u0644\u0641\u0648\u0644\u064A\u0643 \u0648\u0627\u0644\u062D\u062F\u064A\u062F \u062D\u0633\u0628 \u062A\u0648\u062C\u064A\u0647\u0627\u062A \u0637\u0628\u064A\u0628\u062A\u0643.',
    '\u063A\u062B\u064A\u0627\u0646|\u0648\u062D\u0627\u0645|\u062A\u0642\u064A\u0624|\u063A\u062B\u064A\u0627\u0646 \u0627\u0644\u062D\u0645\u0644':
      '\u0644\u062A\u062E\u0641\u064A\u0641 \u0627\u0644\u063A\u062B\u064A\u0627\u0646 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062D\u0645\u0644:\n\n\u2022 \u0643\u0644\u064A \u0648\u062C\u0628\u0627\u062A \u0635\u063A\u064A\u0631\u0629 \u0648\u0645\u062A\u0643\u0631\u0631\u0629 (5-6 \u0645\u0631\u0627\u062A \u064A\u0648\u0645\u064A\u0627\u064B)\n\u2022 \u062A\u062C\u0646\u0628\u064A \u0627\u0644\u0645\u0639\u062F\u0629 \u0627\u0644\u0641\u0627\u0631\u063A\u0629 - \u0643\u0644\u064A \u0628\u0633\u0643\u0648\u064A\u062A \u062C\u0627\u0641 \u0642\u0628\u0644 \u0627\u0644\u0642\u064A\u0627\u0645 \u0645\u0646 \u0627\u0644\u0633\u0631\u064A\u0631\n\u2022 \u0627\u0634\u0631\u0628\u064A \u0627\u0644\u0632\u0646\u062C\u0628\u064A\u0644 \u0623\u0648 \u0627\u0644\u0646\u0639\u0646\u0627\u0639\n\u2022 \u062A\u062C\u0646\u0628\u064A \u0627\u0644\u0631\u0648\u0627\u0626\u062D \u0627\u0644\u0642\u0648\u064A\u0629 \u0648\u0627\u0644\u0623\u0637\u0639\u0645\u0629 \u0627\u0644\u062F\u0633\u0645\u0629\n\u2022 \u0627\u0633\u062A\u0631\u064A\u062D\u064A \u0628\u0639\u062F \u0627\u0644\u0623\u0643\u0644\n\n\u0627\u0644\u063A\u062B\u064A\u0627\u0646 \u0637\u0628\u064A\u0639\u064A \u0641\u064A \u0627\u0644\u0623\u0634\u0647\u0631 \u0627\u0644\u062B\u0644\u0627\u062B\u0629 \u0627\u0644\u0623\u0648\u0644\u0649 \u0648\u064A\u062E\u0641 \u062A\u062F\u0631\u064A\u062C\u064A\u0627\u064B. \u0625\u0630\u0627 \u0643\u0627\u0646 \u0634\u062F\u064A\u062F\u0627\u064B \u062C\u062F\u0627\u064B \u0631\u0627\u062C\u0639\u064A \u0627\u0644\u0637\u0628\u064A\u0628\u0629.',
    // Baby Care
    '\u0631\u0636\u064A\u0639|\u0631\u0636\u0627\u0639\u0629|\u062D\u0644\u064A\u0628 \u0627\u0644\u0623\u0645|\u0627\u0644\u0631\u0636\u0627\u0639\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629':
      '\u0646\u0635\u0627\u0626\u062D \u0644\u0644\u0631\u0636\u0627\u0639\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629:\n\n\u2022 \u0627\u0628\u062F\u0626\u064A \u0627\u0644\u0631\u0636\u0627\u0639\u0629 \u062E\u0644\u0627\u0644 \u0627\u0644\u0633\u0627\u0639\u0629 \u0627\u0644\u0623\u0648\u0644\u0649 \u0628\u0639\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629\n\u2022 \u0623\u0631\u0636\u0639\u064A 8-12 \u0645\u0631\u0629 \u064A\u0648\u0645\u064A\u0627\u064B (\u0643\u0644 2-3 \u0633\u0627\u0639\u0627\u062A)\n\u2022 \u062A\u0623\u0643\u062F\u064A \u0645\u0646 \u0627\u0644\u062A\u0642\u0627\u0645 \u0627\u0644\u0637\u0641\u0644 \u0627\u0644\u0635\u062D\u064A\u062D (\u0627\u0644\u0641\u0645 \u064A\u063A\u0637\u064A \u0627\u0644\u0647\u0627\u0644\u0629)\n\u2022 \u0627\u0644\u0631\u0636\u0627\u0639\u0629 \u0627\u0644\u0637\u0628\u064A\u0639\u064A\u0629 \u062D\u0635\u0631\u064A\u0627\u064B \u0644\u0645\u062F\u0629 6 \u0623\u0634\u0647\u0631\n\u2022 \u0627\u0634\u0631\u0628\u064A \u0645\u0627\u0621 \u0643\u062B\u064A\u0631 \u0648\u062A\u063A\u0630\u064A \u062C\u064A\u062F\u0627\u064B\n\u2022 \u0627\u0633\u062A\u0634\u064A\u0631\u064A \u0645\u062E\u062A\u0635\u0629 \u0631\u0636\u0627\u0639\u0629 \u0625\u0630\u0627 \u0648\u0627\u062C\u0647\u062A \u0635\u0639\u0648\u0628\u0627\u062A',
    '\u0646\u0648\u0645 \u0627\u0644\u0637\u0641\u0644|\u0646\u0648\u0645 \u0627\u0644\u0631\u0636\u064A\u0639|\u0628\u0643\u0627\u0621 \u0627\u0644\u0637\u0641\u0644':
      '\u0646\u0635\u0627\u0626\u062D \u0644\u0646\u0648\u0645 \u0627\u0644\u0637\u0641\u0644:\n\n\u2022 \u0646\u0648\u0645\u064A \u0627\u0644\u0637\u0641\u0644 \u0639\u0644\u0649 \u0638\u0647\u0631\u0647 (\u0627\u0644\u0623\u0643\u062B\u0631 \u0623\u0645\u0627\u0646\u0627\u064B)\n\u2022 \u0623\u0646\u0634\u0626\u064A \u0631\u0648\u062A\u064A\u0646 \u0646\u0648\u0645 \u062B\u0627\u0628\u062A (\u062D\u0645\u0627\u0645\u060C \u062A\u062F\u0644\u064A\u0643\u060C \u0631\u0636\u0627\u0639\u0629)\n\u2022 \u0627\u0644\u063A\u0631\u0641\u0629 \u0645\u0638\u0644\u0645\u0629 \u0648\u0647\u0627\u062F\u0626\u0629 \u0648\u062F\u0631\u062C\u0629 \u062D\u0631\u0627\u0631\u0629 \u0645\u0646\u0627\u0633\u0628\u0629\n\u2022 \u0627\u0644\u0645\u0648\u0644\u0648\u062F \u064A\u0646\u0627\u0645 16-17 \u0633\u0627\u0639\u0629 \u064A\u0648\u0645\u064A\u0627\u064B\n\u2022 \u0644\u0627 \u062A\u0636\u0639\u064A \u0648\u0633\u0627\u0626\u062F \u0623\u0648 \u0623\u0644\u0639\u0627\u0628 \u0641\u064A \u0627\u0644\u0633\u0631\u064A\u0631\n\n\u0627\u0644\u0628\u0643\u0627\u0621 \u0637\u0628\u064A\u0639\u064A - \u062A\u0623\u0643\u062F\u064A \u0645\u0646: \u0627\u0644\u062C\u0648\u0639\u060C \u0627\u0644\u062D\u0641\u0627\u0636\u060C \u0627\u0644\u062D\u0631\u0627\u0631\u0629\u060C \u0627\u0644\u062D\u0627\u062C\u0629 \u0644\u0644\u062D\u0636\u0646.',
    '\u062A\u0637\u0639\u064A\u0645|\u0644\u0642\u0627\u062D|\u062A\u0637\u0639\u064A\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644':
      '\u062C\u062F\u0648\u0644 \u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A \u0627\u0644\u0623\u0633\u0627\u0633\u064A\u0629:\n\n\u2022 \u0639\u0646\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629: BCG + \u0627\u0644\u062A\u0647\u0627\u0628 \u0627\u0644\u0643\u0628\u062F B\n\u2022 \u0634\u0647\u0631\u064A\u0646: \u0627\u0644\u062B\u0644\u0627\u062B\u064A + \u0634\u0644\u0644 \u0627\u0644\u0623\u0637\u0641\u0627\u0644 + \u0627\u0644\u0631\u0648\u062A\u0627\n\u2022 4 \u0623\u0634\u0647\u0631: \u062C\u0631\u0639\u0629 \u062B\u0627\u0646\u064A\u0629\n\u2022 6 \u0623\u0634\u0647\u0631: \u062C\u0631\u0639\u0629 \u062B\u0627\u0644\u062B\u0629\n\u2022 9 \u0623\u0634\u0647\u0631: \u0627\u0644\u062D\u0635\u0628\u0629\n\u2022 12 \u0634\u0647\u0631: MMR\n\u2022 18 \u0634\u0647\u0631: \u062C\u0631\u0639\u0627\u062A \u062A\u0646\u0634\u064A\u0637\u064A\u0629\n\n\u0627\u0644\u062A\u0632\u0645\u064A \u0628\u062C\u062F\u0648\u0644 \u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A \u0644\u062D\u0645\u0627\u064A\u0629 \u0637\u0641\u0644\u0643. \u0631\u0627\u062C\u0639\u064A \u0637\u0628\u064A\u0628 \u0627\u0644\u0623\u0637\u0641\u0627\u0644 \u0644\u0644\u062C\u062F\u0648\u0644 \u0627\u0644\u0643\u0627\u0645\u0644.',
    // General Health
    '\u0632\u064A\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628|\u0645\u062A\u0649 \u0623\u0632\u0648\u0631 \u0627\u0644\u0637\u0628\u064A\u0628|\u0627\u0633\u062A\u0634\u0627\u0631\u0629 \u0637\u0628\u064A\u0629':
      '\u064A\u062C\u0628 \u0632\u064A\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628\u0629 \u0641\u064A \u0647\u0630\u0647 \u0627\u0644\u062D\u0627\u0644\u0627\u062A:\n\n\u2022 \u0622\u0644\u0627\u0645 \u0634\u062F\u064A\u062F\u0629 \u063A\u064A\u0631 \u0637\u0628\u064A\u0639\u064A\u0629 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062F\u0648\u0631\u0629\n\u2022 \u0646\u0632\u064A\u0641 \u063A\u0632\u064A\u0631 \u0623\u0648 \u063A\u064A\u0631 \u0637\u0628\u064A\u0639\u064A\n\u2022 \u062A\u0623\u062E\u0631 \u0627\u0644\u062F\u0648\u0631\u0629 \u0623\u0643\u062B\u0631 \u0645\u0646 3 \u0623\u0634\u0647\u0631\n\u2022 \u0623\u0644\u0645 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062D\u0645\u0644 \u0623\u0648 \u0646\u0632\u064A\u0641\n\u2022 \u062D\u0631\u0627\u0631\u0629 \u0627\u0644\u0637\u0641\u0644 \u0623\u0643\u062B\u0631 \u0645\u0646 38.5\n\u2022 \u0627\u0644\u0641\u062D\u0635 \u0627\u0644\u062F\u0648\u0631\u064A \u0627\u0644\u0633\u0646\u0648\u064A \u0644\u0644\u0646\u0633\u0627\u0621\n\n\u0644\u0627 \u062A\u062A\u0631\u062F\u062F\u064A \u0641\u064A \u0627\u0633\u062A\u0634\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628\u0629 \u0639\u0646\u062F \u0627\u0644\u0634\u0643.',
    '\u0641\u064A\u062A\u0627\u0645\u064A\u0646|\u0645\u0643\u0645\u0644\u0627\u062A|\u062D\u062F\u064A\u062F|\u0641\u0648\u0644\u064A\u0643|\u0643\u0627\u0644\u0633\u064A\u0648\u0645':
      '\u0627\u0644\u0641\u064A\u062A\u0627\u0645\u064A\u0646\u0627\u062A \u0627\u0644\u0645\u0647\u0645\u0629 \u0644\u0644\u0645\u0631\u0623\u0629:\n\n\u2022 \u062D\u0645\u0636 \u0627\u0644\u0641\u0648\u0644\u064A\u0643: \u0636\u0631\u0648\u0631\u064A \u0642\u0628\u0644 \u0648\u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062D\u0645\u0644\n\u2022 \u0627\u0644\u062D\u062F\u064A\u062F: \u0644\u0645\u0646\u0639 \u0641\u0642\u0631 \u0627\u0644\u062F\u0645 (\u062E\u0627\u0635\u0629 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062F\u0648\u0631\u0629 \u0648\u0627\u0644\u062D\u0645\u0644)\n\u2022 \u0627\u0644\u0643\u0627\u0644\u0633\u064A\u0648\u0645: \u0644\u0635\u062D\u0629 \u0627\u0644\u0639\u0638\u0627\u0645\n\u2022 \u0641\u064A\u062A\u0627\u0645\u064A\u0646 D: \u0644\u0627\u0645\u062A\u0635\u0627\u0635 \u0627\u0644\u0643\u0627\u0644\u0633\u064A\u0648\u0645\n\u2022 \u0623\u0648\u0645\u064A\u063A\u0627 3: \u0644\u0635\u062D\u0629 \u0627\u0644\u0642\u0644\u0628 \u0648\u0627\u0644\u062F\u0645\u0627\u063A\n\n\u0627\u0633\u062A\u0634\u064A\u0631\u064A \u0637\u0628\u064A\u0628\u062A\u0643 \u0642\u0628\u0644 \u062A\u0646\u0627\u0648\u0644 \u0623\u064A \u0645\u0643\u0645\u0644\u0627\u062A.',
    '\u0631\u064A\u0627\u0636\u0629|\u062A\u0645\u0627\u0631\u064A\u0646|\u0631\u064A\u0627\u0636\u0629 \u0627\u0644\u062D\u0627\u0645\u0644|\u0645\u0634\u064A':
      '\u0627\u0644\u0631\u064A\u0627\u0636\u0629 \u0623\u062B\u0646\u0627\u0621 \u0627\u0644\u062D\u0645\u0644:\n\n\u2714\uFE0F \u0622\u0645\u0646\u0629 \u0648\u0645\u0641\u064A\u062F\u0629:\n\u2022 \u0627\u0644\u0645\u0634\u064A 30 \u062F\u0642\u064A\u0642\u0629 \u064A\u0648\u0645\u064A\u0627\u064B\n\u2022 \u0627\u0644\u0633\u0628\u0627\u062D\u0629\n\u2022 \u064A\u0648\u063A\u0627 \u0627\u0644\u062D\u0648\u0627\u0645\u0644\n\u2022 \u062A\u0645\u0627\u0631\u064A\u0646 \u0643\u064A\u062C\u0644\n\n\u274C \u062A\u062C\u0646\u0628\u064A:\n\u2022 \u0627\u0644\u0631\u064A\u0627\u0636\u0627\u062A \u0627\u0644\u0639\u0646\u064A\u0641\u0629\n\u2022 \u0627\u0644\u0642\u0641\u0632 \u0648\u0627\u0644\u062C\u0631\u064A \u0627\u0644\u0633\u0631\u064A\u0639\n\u2022 \u062D\u0645\u0644 \u0627\u0644\u0623\u062B\u0642\u0627\u0644\n\n\u0627\u0633\u062A\u0634\u064A\u0631\u064A \u0637\u0628\u064A\u0628\u062A\u0643 \u0642\u0628\u0644 \u0627\u0644\u0628\u062F\u0621.',
    '\u0646\u0641\u0633\u064A\u0629|\u0627\u0643\u062A\u0626\u0627\u0628|\u0642\u0644\u0642|\u0627\u0643\u062A\u0626\u0627\u0628 \u0645\u0627 \u0628\u0639\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629':
      '\u0627\u0644\u0635\u062D\u0629 \u0627\u0644\u0646\u0641\u0633\u064A\u0629 \u0645\u0647\u0645\u0629 \u062C\u062F\u0627\u064B:\n\n\u0627\u0643\u062A\u0626\u0627\u0628 \u0645\u0627 \u0628\u0639\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629 \u0634\u0627\u0626\u0639 \u0648\u0639\u0644\u0627\u0645\u0627\u062A\u0647:\n\u2022 \u062D\u0632\u0646 \u0645\u0633\u062A\u0645\u0631 \u0648\u0628\u0643\u0627\u0621\n\u2022 \u0635\u0639\u0648\u0628\u0629 \u0627\u0644\u062A\u0631\u0627\u0628\u0637 \u0645\u0639 \u0627\u0644\u0637\u0641\u0644\n\u2022 \u0623\u0631\u0642 \u0623\u0648 \u0646\u0648\u0645 \u0645\u0641\u0631\u0637\n\u2022 \u0641\u0642\u062F\u0627\u0646 \u0627\u0644\u0634\u0647\u064A\u0629\n\n\u0644\u0644\u0639\u0646\u0627\u064A\u0629 \u0628\u0646\u0641\u0633\u0643:\n\u2022 \u0627\u0637\u0644\u0628\u064A \u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629 \u0645\u0646 \u0627\u0644\u0639\u0627\u0626\u0644\u0629\n\u2022 \u062E\u0630\u064A \u0648\u0642\u062A\u0627\u064B \u0644\u0646\u0641\u0633\u0643\n\u2022 \u062A\u062D\u062F\u062B\u064A \u0645\u0639 \u0635\u062F\u064A\u0642\u0629 \u0623\u0648 \u0645\u062E\u062A\u0635\u0629\n\n\u0644\u0627 \u062A\u062A\u0631\u062F\u062F\u064A \u0641\u064A \u0637\u0644\u0628 \u0627\u0644\u0645\u0633\u0627\u0639\u062F\u0629 \u0627\u0644\u0645\u062A\u062E\u0635\u0635\u0629. \u0635\u062D\u062A\u0643 \u0627\u0644\u0646\u0641\u0633\u064A\u0629 \u0623\u0648\u0644\u0648\u064A\u0629!',
  };

  String _getSmartReply(String question) {
    final q = question.toLowerCase();
    for (final entry in _healthKB.entries) {
      final keywords = entry.key.split('|');
      for (final kw in keywords) {
        if (q.contains(kw)) return entry.value;
      }
    }
    return '\u0634\u0643\u0631\u0627\u064B \u0639\u0644\u0649 \u0633\u0624\u0627\u0644\u0643! \u0647\u0630\u0627 \u0627\u0644\u0645\u0648\u0636\u0648\u0639 \u064A\u062D\u062A\u0627\u062C \u0627\u0633\u062A\u0634\u0627\u0631\u0629 \u0637\u0628\u064A\u0629 \u0645\u062A\u062E\u0635\u0635\u0629. \u0623\u0646\u0635\u062D\u0643 \u0628\u0645\u0631\u0627\u062C\u0639\u0629 \u0637\u0628\u064A\u0628\u062A\u0643 \u0644\u0644\u062D\u0635\u0648\u0644 \u0639\u0644\u0649 \u0625\u062C\u0627\u0628\u0629 \u062F\u0642\u064A\u0642\u0629 \u0648\u0645\u062E\u0635\u0635\u0629 \u0644\u062D\u0627\u0644\u062A\u0643.\n\n\u064A\u0645\u0643\u0646\u0643 \u0633\u0624\u0627\u0644\u064A \u0639\u0646:\n\u2022 \u0622\u0644\u0627\u0645 \u0627\u0644\u062F\u0648\u0631\u0629 \u0648\u0627\u0646\u062A\u0638\u0627\u0645\u0647\u0627\n\u2022 \u0623\u0639\u0631\u0627\u0636 \u0627\u0644\u062D\u0645\u0644 \u0648\u0627\u0644\u062A\u063A\u0630\u064A\u0629\n\u2022 \u0627\u0644\u0631\u0636\u0627\u0639\u0629 \u0648\u0631\u0639\u0627\u064A\u0629 \u0627\u0644\u0637\u0641\u0644\n\u2022 \u0627\u0644\u062A\u0637\u0639\u064A\u0645\u0627\u062A \u0648\u0627\u0644\u0641\u064A\u062A\u0627\u0645\u064A\u0646\u0627\u062A';
  }

  Future<String> _callGemini(String userMessage) async {
    _chatHistory.add({'role': 'user', 'parts': [{'text': userMessage}]});

    final sysText = '\u0623\u0646\u062A \u0645\u0633\u0627\u0639\u062F \u0635\u062D\u064A \u0630\u0643\u064A \u0627\u0633\u0645\u0643 \u0646\u0628\u0636\u0629\u060C \u0645\u062A\u062E\u0635\u0635 \u0641\u064A \u0635\u062D\u0629 \u0627\u0644\u0645\u0631\u0623\u0629. \u0623\u062C\u0628 \u062F\u0627\u0626\u0645\u0627\u064B \u0628\u0627\u0644\u0639\u0631\u0628\u064A\u0629. \u062A\u062E\u0635\u0635\u0627\u062A\u0643: \u0627\u0644\u062F\u0648\u0631\u0629\u060C \u0627\u0644\u062D\u0645\u0644\u060C \u0627\u0644\u0648\u0644\u0627\u062F\u0629\u060C \u0631\u0639\u0627\u064A\u0629 \u0627\u0644\u0637\u0641\u0644\u060C \u0627\u0644\u062A\u063A\u0630\u064A\u0629. \u0623\u062C\u0628 \u0628\u0625\u064A\u062C\u0627\u0632. \u0625\u0630\u0627 \u062A\u0637\u0644\u0628 \u0627\u0644\u0633\u0624\u0627\u0644 \u062A\u0634\u062E\u064A\u0635\u0627\u064B \u0637\u0628\u064A\u0627\u064B \u0627\u0646\u0635\u062D\u064A \u0628\u0632\u064A\u0627\u0631\u0629 \u0627\u0644\u0637\u0628\u064A\u0628.';

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
        String reply = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '\u0644\u0645 \u0623\u062A\u0645\u0643\u0646 \u0645\u0646 \u0627\u0644\u0625\u062C\u0627\u0628\u0629';
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
          title: Text('\u0627\u0644\u0645\u0633\u0627\u0639\u062F \u0627\u0644\u0630\u0643\u064A'),
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
                    'text': '\u062A\u0645 \u0645\u0633\u062D \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629. \u0643\u064A\u0641 \u064A\u0645\u0643\u0646\u0646\u064A \u0645\u0633\u0627\u0639\u062F\u062A\u0643\u061F \u{1F49C}'
                  });
                });
                _chatHistory.clear();
              },
              tooltip: '\u0645\u0633\u062D \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629',
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
                      hintText: '\u0627\u0643\u062A\u0628\u064A \u0633\u0624\u0627\u0644\u0643 \u0647\u0646\u0627...',
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
            borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal)),
            SizedBox(width: 10),
            Text('\u062C\u0627\u0631\u064A \u0627\u0644\u062A\u0641\u0643\u064A\u0631...', style: TextStyle(color: Colors.grey))          ]),
        ),
      ]),
    );
  }
}
