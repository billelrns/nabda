import 'dart:typed_data';
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
      child: Scaffold(
        backgroundColor: _cream,
        body: Container(
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
      child: Scaffold(
        backgroundColor: _cream,
        body: Container(
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
    return Container(
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
    );
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
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
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
          return Scaffold(
            appBar: AppBar(centerTitle: true,
              title: Text('\u0645\u062A\u0627\u0628\u0639\u0629 \u0627\u0644\u062D\u0645\u0644'),
              backgroundColor: Color(0xFF00897B), foregroundColor: Colors.white,
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
              backgroundColor: Color(0xFF00897B), foregroundColor: Colors.white,
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

  // \u2500\u2500 Data Methods (preserved) \u2500\u2500
  Future<void> _setBabyInfo() async {
    final nameC = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          title: const Text('\u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0637\u0641\u0644', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
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
                final date = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now().subtract(const Duration(days: 90)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                  lastDate: DateTime.now(),
                  helpText: '\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0645\u064A\u0644\u0627\u062F',
                );
                if (date != null) {
                  Navigator.pop(ctx, {'name': nameC.text, 'birthDate': date});
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(colors: [Color(0xFFFF6BA3), _pink, _pinkHot]),
                  boxShadow: [BoxShadow(color: _pink.withOpacity(0.22), blurRadius: 28, offset: const Offset(0, 12))],
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.calendar_month, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('\u0627\u062E\u062A\u0627\u0631\u064A \u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0645\u064A\u0644\u0627\u062F', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ),
          ]),
        ),
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('\u062A\u0645 \u062A\u0633\u062C\u064A\u0644 $type \u2713'), backgroundColor: _teal, duration: const Duration(seconds: 1)));
  }

  Future<void> _updateGrowth(String field, double value) async {
    await DB.userDoc.set({
      'baby_$field': value,
      'baby_${field}_date': DB.dateKey(),
    }, SetOptions(merge: true));
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
      child: Scaffold(
        backgroundColor: _cream,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_cream, Colors.white, _cream],
            ),
          ),
          child: StreamBuilder<DocumentSnapshot>(
            stream: DB.userDoc.snapshots(),
            builder: (context, userSnap) {
              Map<String, dynamic> userData = {};
              if (userSnap.hasData && userSnap.data!.exists) {
                userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
              }
              String babyName = userData['babyName'] ?? '';
              int ageDays = 0;
              String ageText = '';
              if (userData['babyBirthDate'] != null) {
                try {
                  Timestamp ts = userData['babyBirthDate'];
                  ageDays = DateTime.now().difference(ts.toDate()).inDays;
                  if (ageDays < 30) ageText = '$ageDays \u064A\u0648\u0645';
                  else if (ageDays < 365) ageText = '${(ageDays / 30).floor()} \u0623\u0634\u0647\u0631';
                  else ageText = '${(ageDays / 365).floor()} \u0633\u0646\u0629 \u0648 ${((ageDays % 365) / 30).floor()} \u0623\u0634\u0647\u0631';
                } catch (_) {}
              }
              double weight = (userData['baby_weight'] as num?)?.toDouble() ?? 0;
              double babyHeight = (userData['baby_height'] as num?)?.toDouble() ?? 0;

              if (babyName.isEmpty && userData['babyBirthDate'] == null) {
                return _buildEmptyState();
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
                            _vaccineItem('\u0644\u0642\u0627\u062D \u0627\u0644\u062A\u0647\u0627\u0628 \u0627\u0644\u0643\u0628\u062F \u0628', 'hepb', '\u0639\u0646\u062F \u0627\u0644\u0648\u0644\u0627\u062F\u0629'),
                            _vaccineItem('\u0644\u0642\u0627\u062D BCG', 'bcg', '\u0627\u0644\u0623\u0633\u0628\u0648\u0639 \u0627\u0644\u0623\u0648\u0644'),
                            _vaccineItem('\u0627\u0644\u0644\u0642\u0627\u062D \u0627\u0644\u062B\u0644\u0627\u062B\u064A', 'dtap', '\u0634\u0647\u0631\u064A\u0646'),
                            _vaccineItem('\u0644\u0642\u0627\u062D \u0634\u0644\u0644 \u0627\u0644\u0623\u0637\u0641\u0627\u0644', 'polio', '\u0634\u0647\u0631\u064A\u0646'),
                            _vaccineItem('\u0644\u0642\u0627\u062D \u0627\u0644\u062D\u0635\u0628\u0629', 'mmr', '9 \u0623\u0634\u0647\u0631'),
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
                          child: _BabyArticlesSection(),
                        ),
                        const SizedBox(height: 30),
                      ])),
                    ],
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
  Widget _vaccineItem(String name, String key, String timing) {
    return StreamBuilder<DocumentSnapshot>(
      stream: DB.userDoc.collection('vaccines').doc(key).snapshots(),
      builder: (context, snap) {
        bool done = false;
        if (snap.hasData && snap.data!.exists) {
          done = (snap.data!.data() as Map<String, dynamic>?)?['done'] ?? false;
        }
        return GestureDetector(
          onTap: () {
            DB.userDoc.collection('vaccines').doc(key).set({
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
        builder: (_) => _ArticleDetailPage(title: title, body: content, color: cardColor, imageUrl: resolvedImage, contentImages: contentImages))),
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
       'content': 'الدورة الشهرية هي عملية طبيعية يمر بها جسم المرأة كل شهر تقريباً وتتراوح مدتها بين واحد وعشرين يوماً وخمسة وثلاثين يوماً بمتوسط ثمانية وعشرين يوماً. تبدأ الدورة من أول يوم للحيض وتنتهي قبل اليوم الأول للحيض التالي. خلال هذه الفترة يمر جسمك بأربع مراحل رئيسية تتحكم فيها الهرمونات بدقة متناهية.

المرحلة الأولى هي مرحلة الحيض التي تستمر من ثلاثة إلى سبعة أيام يتخلص فيها الرحم من بطانته عبر نزيف مهبلي. الكمية الطبيعية للدم تتراوح بين ثلاثين وثمانين ملليلتراً خلال الدورة كاملة. إذا كان النزيف غزيراً جداً يغرق أكثر من فوطة صحية كل ساعة فاستشيري طبيبتك.

المرحلة الثانية هي المرحلة الجريبية التي تبدأ مع الحيض وتستمر حتى التبويض. يرتفع فيها هرمون الإستروجين مما يحفز نمو بويضة واحدة ناضجة داخل حويصلة في المبيض ويعيد بناء بطانة الرحم. ثم تأتي مرحلة التبويض في منتصف الدورة تقريباً حين تنطلق البويضة الناضجة من المبيض إلى قناة فالوب. هذه هي فترة الخصوبة العالية وتستمر البويضة حية لمدة اثنتي عشرة إلى أربع وعشرين ساعة فقط.

المرحلة الأخيرة هي المرحلة الأصفرية التي يفرز فيها الجسم الأصفر هرمون البروجسترون لتهيئة بطانة الرحم لاستقبال الحمل. إذا لم يحدث إخصاب ينخفض مستوى البروجسترون والإستروجين مما يؤدي لانسلاخ البطانة وبدء دورة جديدة. تتبعي دورتك بانتظام باستخدام تطبيق موثوق وسجلي الأعراض المصاحبة كالمزاج والطاقة والألم لفهم نمطك الشخصي. الدورة المنتظمة مؤشر على الصحة الهرمونية فإذا لاحظتِ اضطراباً مستمراً أو غياباً للدورة أو نزيفاً غير طبيعي فراجعي طبيبتك.'},
      {'title': 'تخفيف آلام الدورة', 'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=600&q=80',
       'content': 'آلام الدورة الشهرية أو ما يُعرف طبياً بعسر الطمث من أكثر الشكاوى شيوعاً بين النساء وتتراوح من تقلصات خفيفة إلى آلام شديدة تؤثر على النشاط اليومي. تحدث هذه الآلام بسبب انقباضات الرحم لطرد بطانته وإفراز مادة البروستاغلاندين التي تحفز التقلصات العضلية. كلما زاد إفراز البروستاغلاندين زادت حدة الألم.

لتخفيف الألم بطرق طبيعية جربي وضع كمادة دافئة أو قربة ماء ساخن على أسفل البطن أو أسفل الظهر لمدة خمس عشرة إلى عشرين دقيقة فالحرارة تساعد على استرخاء عضلات الرحم وتحسين تدفق الدم. أثبتت الدراسات أن الحرارة الموضعية فعالة بقدر المسكنات في كثير من الحالات.

مارسي رياضة خفيفة كالمشي السريع أو اليوغا اللطيفة أو السباحة فالحركة تحسن الدورة الدموية وتفرز الإندورفين الذي يعمل كمسكن طبيعي. تمارين الإطالة لمنطقة الحوض وأسفل الظهر مفيدة جداً. تناولي أطعمة غنية بالمغنيسيوم كالموز والشوكولاتة الداكنة والمكسرات واللوز لأن المغنيسيوم يساعد على استرخاء العضلات. أحماض أوميغا ثلاثة الموجودة في السلمون وبذور الكتان والجوز لها خصائص مضادة للالتهاب تقلل إنتاج البروستاغلاندين.

اشربي شاي الزنجبيل الطازج أو البابونج أو القرفة فلها خصائص مضادة للتقلصات ومهدئة. تجنبي الكافيين والمشروبات الغازية والملح الزائد لأنها تزيد الانتفاخ والاحتباس والتقلصات. النوم الكافي والاسترخاء يساعدان أيضاً في تقليل الألم. إذا كان الألم شديداً ولا يستجيب للطرق الطبيعية يمكنك تناول مسكن كالإيبوبروفين الذي يثبط البروستاغلاندين لكن استشيري طبيبتك إذا استمر الألم شديداً كل شهر لاستبعاد أسباب مثل بطانة الرحم المهاجرة أو الأورام الليفية.'},
    ],
    'التبويض والخصوبة': [
      {'title': 'حساب أيام التبويض', 'image': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&q=80',
       'content': 'التبويض هو المرحلة التي تنطلق فيها البويضة الناضجة من أحد المبيضين لتنتقل عبر قناة فالوب استعداداً للإخصاب. يحدث التبويض عادة في منتصف الدورة الشهرية أي حوالي اليوم الرابع عشر في دورة مدتها ثمانية وعشرون يوماً لكنه يختلف من امرأة لأخرى ومن شهر لآخر حسب طول الدورة والعوامل الهرمونية.

لتحديد يوم التبويض بدقة يمكنك استخدام عدة طرق متكاملة. الأولى قياس درجة حرارة الجسم الأساسية كل صباح قبل النهوض من السرير باستخدام ميزان حرارة دقيق. قبل التبويض تكون الحرارة منخفضة نسبياً ثم ترتفع بمقدار نصف درجة تقريباً بعد التبويض بسبب هرمون البروجسترون. سجلي القراءات يومياً لعدة أشهر لتتعرفي على نمطك.

الطريقة الثانية مراقبة إفرازات عنق الرحم. في الأيام العادية تكون الإفرازات قليلة وسميكة. قبل التبويض بيومين إلى ثلاثة تصبح غزيرة وشفافة ومطاطة تشبه بياض البيض النيء وهذا أفضل مؤشر على اقتراب التبويض وبداية فترة الخصوبة العالية.

الطريقة الثالثة استخدام اختبارات التبويض المنزلية المتوفرة في الصيدليات. هذه الاختبارات تكشف ارتفاع هرمون اللوتين الذي يرتفع قبل التبويض بأربع وعشرين إلى ست وثلاثين ساعة. ابدئي الاختبار من اليوم العاشر للدورة وكرريه يومياً حتى تحصلي على نتيجة إيجابية. تتراوح فترة الخصوبة بين خمسة أيام قبل التبويض ويوم بعده لأن البويضة تعيش اثنتي عشرة إلى أربعاً وعشرين ساعة فقط بينما يعيش الحيوان المنوي حتى خمسة أيام داخل الجهاز التناسلي. الجمع بين عدة طرق يعطي أدق النتائج.'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final color = Colors.pink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _cycleArticles.entries.map((entry) {
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ArticleDetailPage(title: d['title']!, body: d['content']!, color: color, imageUrl: d['image']!))),
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
  }
}

class _BabyArticlesSection extends StatelessWidget {
  static const _babyArticles = <String, List<Map<String, String>>>{
    'صحة الطفل العامة': [
      {'title': 'الحمى عند الرضع: متى تقلقين', 'image': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=600&q=80',
       'content': 'الحمى هي استجابة طبيعية من جهاز المناعة لدى الرضيع لمكافحة العدوى وهي ليست مرضاً بحد ذاتها بل عرض يدل على أن الجسم يقاوم شيئاً ما. تُعتبر درجة حرارة ثمانية وثلاثين درجة مئوية أو أكثر حمى عند الرضيع عند قياسها من تحت الإبط وثمانية وثلاثين ونصف من الشرج.

استخدمي ميزان حرارة رقمي دقيق وقيسي الحرارة من تحت الإبط لمدة ثلاث دقائق أو من الأذن باستخدام ميزان أذن مخصص. تجنبي الموازين الزئبقية القديمة وشرائط الجبهة لأنها أقل دقة. قيسي الحرارة مرتين يومياً على الأقل وسجلي القراءات مع الوقت.

للعناية بالرضيع المحموم ألبسيه ملابس قطنية خفيفة لا تكثري من التغطية حتى لو شعر بالبرد. قدمي السوائل بكثرة سواء حليب الأم أو الماء للأطفال فوق ستة أشهر لمنع الجفاف. استخدمي كمادات فاترة وليست باردة على الجبهة والرقبة واليدين. يمكنك إعطاء الباراسيتامول المخصص للرضع حسب وزن الطفل وعمره بعد استشارة الطبيب ولا تعطي الإيبوبروفين للأطفال أقل من ستة أشهر ولا تستخدمي الأسبرين أبداً للأطفال.

اتصلي بالطبيب فوراً إذا كان عمر الطفل أقل من ثلاثة أشهر وحرارته مرتفعة أو إذا استمرت الحمى أكثر من ثلاثة أيام أو تجاوزت أربعين درجة أو رافقتها أعراض مقلقة كالطفح الجلدي أو صعوبة التنفس أو الخمول الشديد أو القيء المستمر أو رفض الرضاعة أو بكاء غير معتاد أو انتفاخ اليافوخ. في حالات نادرة قد تسبب الحمى العالية تشنجات حرارية وهي مخيفة لكنها غالباً غير خطيرة. حافظي على هدوئك وضعي الطفل على جنبه واتصلي بالإسعاف.'},
      {'title': 'العناية ببشرة الطفل الحساسة', 'image': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=600&q=80',
       'content': 'بشرة الرضيع رقيقة وحساسة للغاية وأرق بعشرين إلى ثلاثين بالمئة من بشرة البالغين مما يجعلها أكثر عرضة للجفاف والتهيج والعدوى. تحتاج هذه البشرة الناعمة إلى عناية خاصة ولطيفة باستخدام منتجات مخصصة للأطفال خالية من العطور والمواد الكيميائية القاسية والأصباغ والكحول.

الحمام يجب أن يكون لطيفاً ومرتين إلى ثلاث مرات أسبوعياً فقط في الأشهر الأولى لأن الاستحمام اليومي يزيل الزيوت الطبيعية ويسبب الجفاف. استخدمي ماء فاتر بدرجة حرارة سبعة وثلاثين درجة تقريباً وغسول خفيف بدون صابون. لا تتركي الطفل في الماء أكثر من عشر دقائق. جففي بشرته بلطف بالتربيت وليس الفرك.

رطبي بشرة طفلك بعد كل حمام بكريم أو لوشن مرطب لطيف خاصة في فصل الشتاء عندما يكون الهواء جافاً. الإكزيما شائعة عند الرضع وتظهر كبقع حمراء متقشرة ومثيرة للحكة على الوجه والمرفقين والركبتين. استخدمي مرطباً كثيفاً عدة مرات يومياً واستشيري طبيب الأطفال لوصف كريم كورتيزون خفيف إذا لزم الأمر.

تجنبي تعريض بشرة الطفل لأشعة الشمس المباشرة في الأشهر الستة الأولى واستخدمي ملابس قطنية فاتحة اللون تغطي الجسم وقبعة واسعة الحواف. بعد ستة أشهر يمكنك استخدام واقي شمس معدني مخصص للأطفال. اختاري حفاضات ناعمة وغيريها فور اتساخها لمنع التسلخات واستخدمي كريم حاجز يحتوي على أكسيد الزنك عند كل تغيير. اغسلي ملابس الطفل بمنظف خاص خالٍ من العطور واشطفيها مرتين لإزالة أي بقايا مهيجة.'},
    ],
    'تغذية الطفل': [
      {'title': 'الرضاعة الطبيعية: أساس صحة طفلك', 'image': 'https://images.unsplash.com/photo-1609220136736-443140cffec6?w=600&q=80',
       'content': 'تُعد الرضاعة الطبيعية الغذاء الأمثل والأكمل للرضيع في الأشهر الستة الأولى من حياته وتوصي بها منظمة الصحة العالمية حصرياً دون أي إضافات. يحتوي حليب الأم على جميع العناصر الغذائية والأجسام المضادة والإنزيمات والهرمونات التي يحتاجها الطفل للنمو والحماية من الأمراض والعدوى.

ابدئي الرضاعة في الساعة الأولى بعد الولادة للحصول على اللبأ وهو السائل الأصفر الغني بالأجسام المضادة الذي يشكل أول لقاح طبيعي لطفلك. اللبأ يحمي أمعاء المولود ويساعد على تطوير جهازه المناعي ويسهل خروج العقي وهو أول براز للمولود.

أرضعي طفلك عند الطلب دون تحديد جدول صارم في الأسابيع الأولى فهذا يساعد على تثبيت إنتاج الحليب وتلبية احتياجات الطفل المتغيرة. قد يرضع المولود ثماني إلى اثنتي عشرة مرة يومياً في البداية. تأكدي من أن الطفل يمسك بالثدي بشكل صحيح بحيث يشمل فمه الحلمة والهالة كاملة وذقنه يلامس الثدي وشفته السفلى مقلوبة للخارج. الإمساك الصحيح يمنع ألم الحلمة والتشقق ويضمن حصول الطفل على كمية كافية.

كل رضعة تستغرق عادة من عشر إلى عشرين دقيقة من كل ثدي. بدلي الثدي الذي تبدئين به في كل رضعة. اشربي كميات كافية من الماء لا تقل عن ثمانية أكواب يومياً وتناولي غذاء متوازناً غنياً بالبروتين والكالسيوم. الرضاعة تفيد الأم أيضاً فهي تساعد الرحم على الانقباض بعد الولادة وتقلل خطر الإصابة بسرطان الثدي والمبيض وتساعد على خسارة وزن الحمل. لا تقلقي إذا واجهتِ صعوبة في البداية واستشيري استشارية رضاعة معتمدة عند الحاجة.'},
      {'title': 'متى وكيف تبدئين بالأطعمة الصلبة', 'image': 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=600&q=80',
       'content': 'يمكن البدء بإدخال الأطعمة التكميلية عند بلوغ الطفل ستة أشهر مع الاستمرار بالرضاعة الطبيعية حتى عمر سنتين أو أكثر. علامات الاستعداد تشمل قدرة الطفل على الجلوس بدعم وإبداء اهتمام بالطعام وفقدان منعكس دفع اللسان الذي يخرج به الطعام من فمه.

ابدئي بالأطعمة المهروسة الناعمة مثل الأرز المسلوق المهروس والبطاطا الحلوة المسلوقة والجزر المسلوق والكوسا والموز المهروس والتفاح المسلوق المهروس. قدمي كمية صغيرة بملعقة ناعمة مخصصة للأطفال. ابدئي بملعقة واحدة إلى ملعقتين وزيدي تدريجياً حسب شهية الطفل.

قاعدة مهمة هي تقديم طعام واحد جديد كل ثلاثة إلى خمسة أيام لمراقبة أي تحسس محتمل. علامات الحساسية تشمل طفح جلدي وإسهال وقيء وتورم الشفتين أو العينين. إذا ظهرت أي من هذه الأعراض أوقفي الطعام الجديد واستشيري الطبيب.

في الشهر السابع أضيفي البروتينات كالدجاج المهروس والعدس المسلوق والبيض المسلوق جيداً والسمك الأبيض المهروس. أضيفي الزبادي الكامل الدسم كمصدر للكالسيوم. في الشهر الثامن قدمي أطعمة مقطعة قطعاً صغيرة ناعمة ليبدأ الطفل بتعلم المضغ واستكشاف القوام المختلف. تجنبي العسل قبل عمر السنة لخطر التسمم الوشيقي والمكسرات الكاملة لخطر الاختناق والملح والسكر المضاف. اجعلي وقت الطعام تجربة ممتعة ومريحة ولا تجبري الطفل على الأكل. قد يحتاج الطفل لتذوق طعام جديد من ثماني إلى خمس عشرة مرة قبل تقبله فتحلي بالصبر.'},
    ],
    'النمو والتطور': [
      {'title': 'مراحل نمو الطفل في السنة الأولى', 'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=600&q=80',
       'content': 'السنة الأولى من حياة طفلك مليئة بالتطورات المذهلة في المهارات الحركية واللغوية والاجتماعية والمعرفية. كل شهر يحمل إنجازات جديدة تستحق المتابعة والتوثيق والاحتفاء.

في الشهر الأول يبدأ المولود بتتبع الأشياء القريبة بعينيه ويستجيب للأصوات العالية ويرفع رأسه لثوانٍ قليلة. في الشهر الثاني يبدأ بالابتسام عند رؤية وجوه مألوفة ويصدر أصوات مناغاة. بحلول الشهر الثالث يرفع رأسه وصدره أثناء الاستلقاء على بطنه ويمسك الأشياء بيده لفترات قصيرة ويبتسم اجتماعياً استجابة للتفاعل.

بين الشهر الرابع والسادس يتعلم الطفل التقلب من بطنه لظهره ثم العكس ويمسك الأشياء ويحملها لفمه ويضحك بصوت عالٍ ويتعرف على اسمه. يبدأ بالجلوس بمساعدة ثم بمفرده ويظهر اهتماماً بالطعام مما يشير لاستعداده للأطعمة التكميلية.

من الشهر السابع إلى التاسع يحبو أو يزحف ويقف مستنداً على الأثاث ويلتقط الأشياء الصغيرة بإبهامه وسبابته ويبدأ بقول مقاطع مثل ماما وبابا وتاتا ويفهم كلمة لا ويلوح بيده. من الشهر العاشر إلى الثاني عشر يمشي مستنداً ثم يخطو خطواته الأولى المستقلة ويقول كلمات بسيطة ويفهم تعليمات بسيطة ويشير لما يريد.

تذكري أن كل طفل يتطور بسرعته الخاصة وهناك مدى طبيعي واسع لكل مهارة. بعض الأطفال يتخطون مرحلة الحبو ويمشون مباشرة وهذا طبيعي. وفري بيئة آمنة ومحفزة للاستكشاف وتحدثي مع طفلك كثيراً واقرئي له يومياً فالتفاعل اللغوي المبكر يعزز النمو العقلي واللغوي بشكل كبير. إذا لاحظتِ تأخراً ملحوظاً كعدم الجلوس في الشهر التاسع أو عدم الاستجابة للأصوات فاستشيري طبيب الأطفال مبكراً.'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final color = Colors.blue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _babyArticles.entries.map((entry) {
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ArticleDetailPage(title: d['title']!, body: d['content']!, color: color, imageUrl: d['image']!))),
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
  }
}



class _HomeArticlesSection extends StatelessWidget {
  static const _articles = <Map<String, String>>[
    {'title': 'الأطعمة المفيدة للحامل', 'category': 'تغذية وجمال', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
     'content': 'تعتبر التغذية السليمة من أهم الركائز التي تضمن صحة الأم والجنين طوال فترة الحمل. يحتاج جسم المرأة الحامل إلى عناصر غذائية متنوعة تشمل البروتينات والفيتامينات والمعادن الأساسية مثل الحديد والكالسيوم وحمض الفوليك. احرصي على تناول الخضروات الورقية الداكنة كالسبانخ والبروكلي والفواكه الطازجة كالبرتقال والموز والتفاح والحبوب الكاملة والبقوليات يومياً. تجنبي الأطعمة المصنعة والمشروبات الغازية واستبدليها بالعصائر الطبيعية والماء.

الحديد من أهم المعادن خلال الحمل لأنه يساعد في تكوين الهيموغلوبين الذي ينقل الأكسجين إلى الجنين. تجدينه في اللحوم الحمراء والعدس والفاصوليا والسبانخ. يُفضل تناول مصادر الحديد مع فيتامين سي لتحسين امتصاصه كأن تضيفي عصير الليمون إلى طبق العدس. الكالسيوم ضروري لبناء عظام الجنين وأسنانه ويتوفر في الحليب والزبادي والجبن والسمسم واللوز.

حمض الفوليك يحمي الجنين من تشوهات الأنبوب العصبي ويوجد في الخضروات الورقية والبقوليات والحمضيات. يوصي الأطباء بتناول مكمل حمض الفوليك قبل الحمل وخلال الثلث الأول على الأقل. أحماض أوميغا 3 تساعد في نمو دماغ الجنين وتتوفر في الأسماك الدهنية كالسلمون والسردين وبذور الكتان والجوز.

تجنبي الأسماك العالية بالزئبق كسمك أبو سيف والماكريل الكبير. ابتعدي عن الأجبان الطرية غير المبسترة واللحوم النيئة والبيض غير المطبوخ جيداً. قللي من الكافيين إلى أقل من مائتي ملليغرام يومياً أي ما يعادل فنجان قهوة واحد. نظمي وجباتك على خمس إلى ست وجبات صغيرة بدل ثلاث كبيرة لتجنب الغثيان والحموضة. استشيري أخصائية تغذية لوضع خطة غذائية مناسبة لاحتياجاتك الخاصة وتأكدي من تناول المكملات التي يصفها طبيبك بانتظام.'},
    {'title': 'المشي أثناء الحمل', 'category': 'رياضة ولياقة', 'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
     'content': 'يُعد المشي من أفضل التمارين وأكثرها أماناً خلال فترة الحمل لأنه لا يتطلب معدات خاصة ويمكن ممارسته في أي وقت ومكان. فهو يساعد على تحسين الدورة الدموية وتقوية عضلات الحوض والساقين وتخفيف آلام الظهر والتورم. ابدئي بالمشي لمدة عشر دقائق يومياً ثم زيدي تدريجياً حتى ثلاثين دقيقة. اختاري أحذية مريحة وأماكن مسطحة وآمنة وتجنبي الحرارة الشديدة.

يساعد المشي المنتظم على تنظيم الوزن خلال الحمل ويقلل من خطر الإصابة بسكري الحمل وارتفاع ضغط الدم. كما يحسن المزاج ويقلل التوتر والقلق بفضل إفراز هرمونات السعادة الطبيعية كالإندورفين. أظهرت الدراسات أن الحوامل اللواتي يمارسن المشي بانتظام يتعافين أسرع بعد الولادة ويعانين أقل من اكتئاب ما بعد الولادة.

في الثلث الأول يمكنك المشي بوتيرة طبيعية مع الحرص على الترطيب الكافي. في الثلث الثاني قد تشعرين بمزيد من الطاقة فاستغلي ذلك لزيادة مدة المشي تدريجياً. في الثلث الأخير خففي السرعة واستمعي لجسمك وتوقفي عند الشعور بأي ألم أو تعب شديد أو دوخة أو ضيق تنفس.

احرصي على ارتداء ملابس فضفاضة ومريحة من القطن وحذاء رياضي بدعم جيد للكاحل والقوس. احملي معك زجاجة ماء واشربي قبل وأثناء وبعد المشي. تجنبي المشي في الأوقات الحارة واختاري الصباح الباكر أو المساء. إذا كنت تعانين من مضاعفات كالمشيمة المنزاحة أو تهديد بالولادة المبكرة فاستشيري طبيبتك قبل ممارسة أي نشاط رياضي. المشي مع صديقة أو زوجك يجعل التجربة أكثر متعة والتزاماً.'},
    {'title': 'يوغا الحوامل', 'category': 'رياضة ولياقة', 'image': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&q=80',
     'content': 'تساعد يوغا الحوامل على تحسين المرونة والتوازن وتخفيف التوتر والقلق المصاحب لفترة الحمل. تركز تمارين اليوغا المخصصة للحوامل على التنفس العميق وتقوية عضلات الحوض والظهر والتحضير الجسدي والنفسي للولادة. مارسي اليوغا في بيئة هادئة ومريحة واستخدمي الوسائد الداعمة. تجنبي الوضعيات التي تتطلب الاستلقاء على البطن أو التوازن الصعب أو الانحناء العميق.

من أهم فوائد يوغا الحوامل تقوية عضلات قاع الحوض التي تدعم الرحم والمثانة والأمعاء. هذه العضلات تتعرض لضغط كبير خلال الحمل وتقويتها يسهل عملية الولادة الطبيعية ويسرع التعافي بعدها. كما تساعد اليوغا على تخفيف آلام أسفل الظهر والوركين والشعور بالثقل في الحوض من خلال تمارين الإطالة اللطيفة.

تقنيات التنفس في اليوغا مفيدة جداً أثناء المخاض لأنها تعلمك كيف تتحكمين في تنفسك خلال الانقباضات. التنفس البطني العميق يهدئ الجهاز العصبي ويقلل الإحساس بالألم ويمنحك شعوراً بالسيطرة. مارسي تمرين التنفس المربع وهو الشهيق لأربع ثوانٍ والحبس لأربع ثوانٍ والزفير لأربع ثوانٍ والانتظار لأربع ثوانٍ.

ابدئي بحصص قصيرة مدتها خمس عشرة دقيقة ثم زيدي تدريجياً. اختاري مدربة متخصصة في يوغا الحوامل أو اتبعي فيديوهات موثوقة. الوضعيات الآمنة تشمل وضعية القطة والبقرة لتخفيف آلام الظهر ووضعية الفراشة لفتح الوركين ووضعية الطفل المعدلة للاسترخاء. تجنبي اليوغا الساخنة والحركات المفاجئة والوضعيات المقلوبة. إذا شعرت بأي ألم أو دوخة توقفي فوراً واستشيري طبيبتك.'},
    {'title': 'القلق من الولادة', 'category': 'صحة نفسية', 'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&q=80',
     'content': 'من الطبيعي أن تشعري ببعض القلق مع اقتراب موعد الولادة لكن المهم ألا يسيطر هذا القلق على حياتك اليومية ويمنعك من الاستمتاع بتجربة الحمل. تحدثي مع طبيبتك بصراحة عن مخاوفك واطلبي المعلومات الكافية عن مراحل الولادة لأن المعرفة تقلل الخوف من المجهول. مارسي تقنيات الاسترخاء والتنفس العميق يومياً واحاطي نفسك بأشخاص إيجابيين يدعمونك.

يُعرف القلق الشديد من الولادة طبياً بالتوكوفوبيا ويصيب نسبة ملحوظة من النساء خاصة في الحمل الأول. أعراضه تشمل كوابيس متكررة عن الولادة وتجنب الحديث عنها وأفكار وسواسية عن المضاعفات. إذا كان قلقك يؤثر على نومك أو شهيتك أو علاقاتك فمن المهم طلب المساعدة المتخصصة من أخصائية نفسية.

من أفضل الطرق للتغلب على القلق حضور دورات تحضيرية للولادة حيث تتعلمين مراحل المخاض والتعامل مع الألم وتقنيات التنفس والدفع. التعرف على قصص ولادة إيجابية من صديقات أو مجموعات دعم يساعد كثيراً في تغيير تصوراتك. ضعي خطة ولادة مرنة تناقشينها مع طبيبتك تشمل تفضيلاتك لكن كوني منفتحة على التغييرات.

التأمل الموجه والتخيل الإيجابي تقنيات فعالة جداً. تخيلي ولادة سلسة وآمنة وركزي على لحظة حمل طفلك لأول مرة. اكتبي مخاوفك في دفتر ثم اكتبي بجانب كل مخاوف حلاً منطقياً أو حقيقة مطمئنة. تذكري أن جسمك مصمم للولادة وأن الطب الحديث يوفر خيارات عديدة لتخفيف الألم. أحيطي نفسك بالدعم وثقي بنفسك وبفريقك الطبي.'},
    {'title': 'العناية بالبشرة', 'category': 'تغذية وجمال', 'image': 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80',
     'content': 'تتعرض بشرة المرأة الحامل لتغيرات كثيرة بسبب التقلبات الهرمونية مثل ظهور الكلف والبقع الداكنة وحب الشباب وعلامات التمدد والجفاف. استخدمي واقي شمس آمن بعامل حماية لا يقل عن ثلاثين يومياً ورطبي بشرتك بكريمات خالية من المواد الكيميائية الضارة. اشربي كمية كافية من الماء لا تقل عن ثمانية أكواب يومياً وتناولي الأطعمة الغنية بفيتامين سي وأحماض أوميغا 3.

الكلف أو قناع الحمل يظهر كبقع بنية على الوجه خاصة الجبين والخدين وأعلى الشفة. أهم وسيلة للوقاية هي الحماية من الشمس بارتداء قبعة واسعة واستخدام واقي شمس معدني يحتوي على أكسيد الزنك أو ثاني أكسيد التيتانيوم. تجنبي واقيات الشمس الكيميائية خلال الحمل واختاري منتجات خالية من الأوكسيبنزون والريتينول.

علامات التمدد تظهر عادة في البطن والصدر والأرداف والفخذين. رطبي هذه المناطق يومياً بزيت جوز الهند أو زبدة الشيا أو كريم يحتوي على فيتامين إي وزبدة الكاكاو. ابدئي الترطيب من بداية الحمل ودلكي بحركات دائرية لتحسين مرونة الجلد. الترطيب لن يمنع علامات التمدد تماماً لكنه يقلل شدتها.

نظفي بشرتك بغسول لطيف خالٍ من الكحول مرتين يومياً. تجنبي منتجات حب الشباب القوية كحمض الساليسيليك المركز والريتينويدات والبنزويل بيروكسيد بتركيز عالٍ. استخدمي بدائل آمنة كحمض الأزيليك وحمض الجليكوليك بتركيزات منخفضة. استشيري طبيبة جلدية إذا تفاقمت مشاكل بشرتك لأن بعض العلاجات تحتاج وصفة طبية آمنة للحمل.'},
    {'title': 'تحضير حقيبة المولود', 'category': 'أمومة وطفولة', 'image': 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400&q=80',
     'content': 'يُنصح بتجهيز حقيبة الولادة في الشهر الثامن تحسباً لأي طارئ قد يستدعي التوجه للمستشفى قبل الموعد المتوقع. جهزي ملابس مريحة لك وللمولود وأغراض النظافة الشخصية والمستندات الطبية اللازمة. لا تنسي ملابس قطنية ناعمة للطفل وحفاضات وبطانية دافئة. احتفظي بالحقيبة في مكان يسهل الوصول إليه وأخبري زوجك وأفراد عائلتك بمكانها.

أغراض الأم تشمل قميص نوم مفتوح من الأمام للرضاعة ورداء حمام مريح وملابس داخلية قطنية واسعة وفوط صحية كبيرة لما بعد الولادة. خذي شبشب مريح وجوارب دافئة لأن غرف المستشفى قد تكون باردة. لا تنسي أدوات النظافة الشخصية كفرشاة الأسنان والمعجون والشامبو والصابون ومزيل العرق ومرطب الشفاه.

أغراض المولود تشمل ثلاث إلى خمس بدلات قطنية داخلية وملابس خارجية مناسبة للطقس وقبعة صغيرة وجوارب وقفازات لمنع الخدش وبطانية ناعمة وحفاضات لحديثي الولادة ومناديل مبللة خالية من العطور وكريم الحفاضات. جهزي أيضاً مقعد السيارة للأطفال لأنه إلزامي لنقل المولود بأمان.

المستندات المطلوبة تشمل البطاقة الصحية للأم وتقارير المتابعة الطبية والتحاليل والأشعات والتأمين الصحي إن وجد وبطاقة الهوية. خذي شاحن الهاتف وكاميرا لتصوير اللحظات الأولى مع طفلك. بعض الأمهات يأخذن وسادة مريحة خاصة ووجبات خفيفة وماء. ضعي قائمة مكتوبة بجانب الحقيبة بالأشياء التي لا يمكن تجهيزها مسبقاً كالهاتف والنظارات والأدوية اليومية لتتذكريها وقت الخروج.'},
    {'title': 'دور الأب أثناء الحمل', 'category': 'علاقات أسرية', 'image': 'https://images.unsplash.com/photo-1531983412531-1f49a365ffed?w=400&q=80',
     'content': 'دور الأب لا يبدأ بعد الولادة بل يبدأ من اللحظة الأولى لمعرفة خبر الحمل. يمكن للأب المشاركة في مواعيد الطبيب والتعرف على مراحل نمو الجنين وتقديم الدعم العاطفي والعملي لزوجته. ساعد في الأعمال المنزلية ورافقها في المشي وكن صبوراً مع تقلبات مزاجها الطبيعية الناتجة عن التغيرات الهرمونية خلال هذه الفترة الحساسة.

المشاركة في المواعيد الطبية من أهم الأشياء التي يمكن للأب فعلها لأنها تظهر الاهتمام وتتيح له فهم ما يحدث طبياً. حضور جلسة السونار ورؤية الجنين وسماع نبضه تجربة مؤثرة تقوي الرابطة بين الأب وطفله قبل ولادته. اطرح الأسئلة على الطبيب ودوّن الملاحظات لتكون مرجعاً لكما معاً.

الدعم العاطفي يعني الاستماع لمخاوف زوجتك دون التقليل منها والتعبير عن حبك وامتنانك لما تتحمله. تعلم عن أعراض الحمل المختلفة في كل ثلث لتفهم ما تمر به. في الثلث الأول قد تعاني من غثيان وإرهاق شديد فساعدها في المطبخ والتنظيف. في الثلث الأخير قد تعاني من أرق وآلام ظهر فدلك ظهرها وساعدها على إيجاد وضعية نوم مريحة.

شارك في تحضيرات الاستقبال كاختيار اسم المولود وتجهيز غرفته وشراء المستلزمات. احضر دورة تحضيرية للولادة معها لتعرف كيف تدعمها خلال المخاض. تعلم أساسيات رعاية المولود كتغيير الحفاض والحمام والتجشؤ. حضورك ومشاركتك يمنحها الثقة والأمان ويبني علاقة أبوية قوية من البداية تستمر مدى الحياة.'},
    {'title': 'فحوصات الثلث الأول', 'category': 'نصائح طبية', 'image': 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&q=80',
     'content': 'يشمل الثلث الأول من الحمل من الأسبوع الأول حتى الثالث عشر فحوصات أساسية مهمة لصحة الأم والجنين. تبدأ هذه الفحوصات بتحليل الدم الشامل وفصيلة الدم وعامل ريسوس وفحص السكري ووظائف الغدة الدرقية والكبد والكلى. يُجرى أول سونار عادة بين الأسبوع السادس والثامن لتأكيد الحمل وسماع نبض الجنين وتحديد عمره بدقة. التزمي بمواعيد الفحوصات واسألي طبيبتك عن أي شيء يقلقك.

تحليل الدم الشامل يكشف عن فقر الدم الذي يصيب كثيراً من الحوامل بسبب زيادة حجم الدم. إذا كان مستوى الهيموغلوبين منخفضاً ستصف لك الطبيبة مكملات الحديد. فحص فصيلة الدم وعامل ريسوس مهم لأنه إذا كانت فصيلتك سالبة وفصيلة الأب موجبة فقد تحتاجين حقنة خاصة لمنع تكوين أجسام مضادة تؤثر على الجنين.

فحص الأمراض المعدية يشمل التهاب الكبد بي وسي وفيروس نقص المناعة والزهري والحصبة الألمانية وداء القطط. هذه الفحوصات ضرورية لأن بعض هذه الأمراض يمكن أن تنتقل للجنين وتسبب مضاعفات خطيرة لكن اكتشافها المبكر يتيح العلاج أو الوقاية.

بين الأسبوع الحادي عشر والرابع عشر يُجرى فحص الشفافية القفوية بالسونار مع تحليل دم لتقييم خطر المتلازمات الكروموسومية كمتلازمة داون. هذا فحص تقييمي وليس تشخيصياً وإذا كانت النتائج مقلقة فقد تُعرض عليك فحوصات إضافية كبزل السائل الأمنيوسي. ناقشي مع طبيبتك كل فحص وأهميته وخياراتك المتاحة واتخذي قراراتك بناء على معلومات واضحة.'},
    {'title': 'السباحة للحامل', 'category': 'رياضة ولياقة', 'image': 'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=400&q=80',
     'content': 'السباحة من أفضل الرياضات للحامل لأن الماء يدعم وزن الجسم ويخفف الضغط على المفاصل والعمود الفقري مما يمنحك شعوراً بالخفة والراحة. تساعد السباحة على تحسين اللياقة القلبية والتنفسية وتقليل التورم في الساقين وتخفيف آلام الظهر. اختاري حمام سباحة نظيفاً ومارسي السباحة بوتيرة معتدلة لمدة عشرين إلى ثلاثين دقيقة ثلاث مرات أسبوعياً.

يوفر الماء بيئة تدريب مثالية للحامل لأن الطفو يقلل الوزن المحسوس بنسبة تسعين بالمئة مما يسمح بحرية الحركة دون إجهاد. هذا يجعل السباحة مناسبة حتى في الثلث الأخير عندما تصبح معظم التمارين الأخرى صعبة. الماء البارد يساعد أيضاً على تقليل التورم في الكاحلين والقدمين وتحسين الدورة الدموية.

من فوائد السباحة تقوية عضلات الذراعين والساقين والظهر والبطن دون إجهاد المفاصل. كما تحسن القدرة على التحمل وتعد الجسم لمجهود الولادة. السباحة نشاط هوائي يحسن كفاءة القلب والرئتين ويساعد على تنظيم الوزن والتحكم في سكر الدم. الأثر النفسي إيجابي أيضاً لأن السباحة تقلل التوتر وتحسن النوم وتمنح شعوراً بالإنجاز والنشاط.

ابدئي بالإحماء ببطء واسبحي بوتيرة يمكنك فيها التحدث بشكل طبيعي. تجنبي السباحة على ظهرك بعد الأسبوع العشرين لأن وزن الرحم قد يضغط على الوريد الأجوف. لا تقفزي في الماء ولا تسبحي في مياه ساخنة تتجاوز اثنتين وثلاثين درجة. ارتدي مايوه مريح للحوامل واستخدمي نظارات سباحة لتجنب تهيج العينين. توقفي فوراً إذا شعرت بدوخة أو ضيق تنفس أو ألم.'},
    {'title': 'فحص السونار التفصيلي', 'category': 'نصائح طبية', 'image': 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=400&q=80',
     'content': 'يُجرى السونار التفصيلي عادة بين الأسبوع الثامن عشر والعشرين من الحمل ويُعد من أهم فحوصات الحمل وأكثرها شمولاً. يفحص الطبيب أعضاء الجنين بالتفصيل بما في ذلك الدماغ والقلب والكليتين والكبد والمعدة والعمود الفقري والأطراف. يقيّم أيضاً نمو الجنين ووزنه ووضع المشيمة وكمية السائل الأمنيوسي وطول عنق الرحم. هذا الفحص فرصة جميلة لرؤية طفلك ومعرفة جنسه إن رغبت في ذلك.

يستغرق الفحص عادة من عشرين إلى أربعين دقيقة حسب وضعية الجنين وتعاونه. قد يُطلب منك شرب كمية من الماء قبل الفحص لامتلاء المثانة مما يساعد في الحصول على صور أوضح. يستخدم الطبيب محول طاقة على بطنك مع هلام مائي ويحرك الجهاز لفحص كل عضو ومنطقة بعناية.

يركز الفحص على القلب بشكل خاص لأن عيوب القلب الخلقية من أكثر التشوهات شيوعاً. يتحقق الطبيب من أن القلب يحتوي على أربع حجرات وأن الصمامات تعمل بشكل طبيعي وأن الأوعية الدموية الكبرى في مكانها الصحيح. كما يفحص الدماغ للتأكد من تطور البنى الأساسية والعمود الفقري للتأكد من إغلاق الأنبوب العصبي بالكامل.

إذا اكتشف الطبيب أي شيء يحتاج متابعة فلا تقلقي فوراً لأن كثيراً من الملاحظات تكون طبيعية أو تحتاج فقط فحصاً إضافياً للتأكد. اسألي طبيبتك عن كل ما تودين معرفته واطلبي صوراً تذكارية لطفلك. بعض المستشفيات توفر سونار ثلاثي ورباعي الأبعاد يمنح صوراً أكثر وضوحاً لملامح الجنين. سجلي موعد الفحص القادم واحتفظي بنتائج الفحص في ملفك الطبي.'},
  ];

  @override
  Widget build(BuildContext context) {
    final categories = <Map<String, dynamic>>[
      {'name': 'تغذية وجمال', 'icon': Icons.spa, 'color': Colors.purple},
      {'name': 'رياضة ولياقة', 'icon': Icons.fitness_center, 'color': Colors.orange},
      {'name': 'صحة نفسية', 'icon': Icons.psychology, 'color': Colors.teal},
      {'name': 'أمومة وطفولة', 'icon': Icons.child_care, 'color': Colors.blue},
      {'name': 'علاقات أسرية', 'icon': Icons.people, 'color': Colors.indigo},
      {'name': 'نصائح طبية', 'icon': Icons.medical_services, 'color': Colors.red},
    ];

    // Group articles by category
    final grouped = <String, List<Map<String, String>>>{};
    for (final art in _articles) {
      grouped.putIfAbsent(art['category']!, () => []).add(art);
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
                    imageUrl: imgUrl, contentImages: const [],
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
class _ArticleDetailPage extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final String imageUrl;
  final List<String> contentImages;
  const _ArticleDetailPage({required this.title, required this.body, required this.color, this.imageUrl = '', this.contentImages = const []});

  // Inline images matched to article content keywords
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
    if (contentImages.isNotEmpty) return contentImages;
    for (final entry in _inlineImageSets.entries) {
      if (title.contains(entry.key)) return entry.value;
    }
    return [
      'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=700&q=80',
    ];
  }

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
                  // Paragraphs with smart inline images
                  ...() {
                    final paragraphs = body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
                    final inlineImgs = _getInlineImages();
                    final widgets = <Widget>[];
                    // Insert first image after 2nd paragraph, second after 5th
                    final insertPoints = [2, 5];
                    int imgIdx = 0;
                    for (int i = 0; i < paragraphs.length; i++) {
                      widgets.add(Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(paragraphs[i].trim(),
                          style: TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF4A434B))),
                      ));
                      if (insertPoints.contains(i) && imgIdx < inlineImgs.length) {
                        widgets.add(Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(inlineImgs[imgIdx], width: double.infinity, height: 200, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => SizedBox.shrink()),
                          ),
                        ));
                        imgIdx++;
                      }
                    }
                    // Remaining images at the end
                    while (imgIdx < inlineImgs.length) {
                      widgets.add(Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(inlineImgs[imgIdx], width: double.infinity, height: 200, fit: BoxFit.cover,
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
    'آلام الدورة|تشنجات|ألم الدورة|تخفيف الدورة':
      'دليل شامل لتخفيف آلام الدورة الشهرية:\n\nتعاني معظم النساء من تشنجات وآلام أثناء الدورة الشهرية، وهذا أمر طبيعي ناتج عن انقباضات الرحم للتخلص من بطانته. هرمون البروستاجلاندين هو المسؤول عن هذه الانقباضات، وكلما زاد مستواه زادت شدة الألم. تبدأ الآلام عادة قبل يوم أو يومين من نزول الدورة وتستمر لمدة 2-3 أيام.\n\nطرق طبيعية فعالة لتخفيف الألم:\n\n• الكمادات الدافئة: ضعي كمادة دافئة أو قربة ماء ساخن على أسفل البطن أو أسفل الظهر لمدة 15-20 دقيقة. الحرارة تساعد على استرخاء عضلات الرحم وتحسين تدفق الدم وتقليل التشنجات بشكل ملحوظ.\n• الرياضة الخفيفة: المشي لمدة 20-30 دقيقة يوميا يفرز هرمون الاندورفين الذي يعمل كمسكن طبيعي للألم. اليوغا وتمارين التمدد اللطيفة مفيدة جدا أيضا لتخفيف التوتر العضلي.\n• المشروبات الدافئة: شاي البابونج مضاد طبيعي للتشنج ويساعد على الاسترخاء. الزنجبيل مضاد قوي للالتهاب ويخفف الغثيان المصاحب. القرفة تساعد في تنظيم تدفق الدم وتقليل النزيف الغزير.\n• التدليك: دلكي منطقة البطن بحركات دائرية لطيفة باستخدام زيت اللافندر أو زيت النعناع المخفف. التدليك يحسن الدورة الدموية ويخفف التوتر العضلي والنفسي.\n• التغذية السليمة: تناولي الأطعمة الغنية بالمغنيزيوم كالموز والشوكولاتة الداكنة والسبانخ واللوز. تجنبي الكافيين والأطعمة المالحة والمقلية لأنها تزيد الانتفاخ والألم. الأطعمة الغنية بالحديد تعوض ما يفقده الجسم.\n• شرب الماء: اشربي 8-10 أكواب ماء يوميا. الجفاف يزيد من حدة التشنجات والصداع المصاحب للدورة.\n• النوم الكافي: احرصي على 7-8 ساعات نوم يوميا. قلة النوم تزيد من حساسية الجسم للألم وتضعف المناعة.\n• تقنيات الاسترخاء: التنفس العميق والتأمل يساعدان في تخفيف التوتر الذي يفاقم الألم. جربي تمارين التنفس 4-7-8 قبل النوم.\n• المسكنات: يمكن تناول الباراسيتامول أو الايبوبروفين عند الحاجة حسب ارشادات الطبيبة. الايبوبروفين أكثر فعالية لأنه يقلل انتاج البروستاجلاندين.\n\nمتى يجب زيارة الطبيبة:\n\n• اذا كان الألم شديدا لدرجة تمنعك من العمل أو الدراسة لعدة أيام\n• اذا لم تستجيبي للمسكنات العادية بعد تجربة أكثر من نوع\n• اذا كان النزيف غزيرا جدا يتطلب تغيير الفوطة كل ساعة أو أقل\n• اذا ظهرت أعراض جديدة لم تكن موجودة سابقا كألم شديد مفاجئ\n• اذا صاحب الدورة افرازات غير طبيعية أو رائحة كريهة\n\nتذكري أن العناية بنفسك خلال فترة الدورة ليست رفاهية بل ضرورة صحية. استمعي لجسمك وامنحي نفسك الراحة التي تحتاجينها. كل امرأة مختلفة، وما يناسبك قد يختلف عن غيرك.',
    'انتظام الدورة|تأخر الدورة|عدم انتظام|دورة غير منتظمة':
      'دليل شامل عن انتظام الدورة الشهرية وأسباب اضطرابها:\n\nالدورة الشهرية الطبيعية تتراوح بين 21 و35 يوما، ومتوسطها 28 يوما. من الطبيعي أن تختلف مدة الدورة بيوم أو يومين من شهر لآخر. لكن اذا كان الاختلاف أكثر من 7 أيام بشكل متكرر فهذا يعتبر عدم انتظام.\n\nالأسباب الشائعة لعدم انتظام الدورة:\n\n• التوتر والضغط النفسي: الاجهاد المزمن يؤثر على محور الغدة النخامية ويعطل انتاج الهرمونات التناسلية مما يسبب تأخر الاباضة أو غيابها.\n• تغير الوزن المفاجئ: زيادة أو نقصان الوزن بأكثر من 5 كيلو في فترة قصيرة يربك توازن الهرمونات. الدهون الزائدة تنتج استروجين اضافي والنحافة المفرطة قد توقف الدورة.\n• متلازمة تكيس المبايض PCOS: من أكثر الأسباب شيوعا عند النساء في سن الانجاب. تسبب ارتفاع هرمون الذكورة مما يعيق الاباضة ويسبب عدم انتظام الدورة وظهور حب الشباب وزيادة نمو الشعر.\n• مشاكل الغدة الدرقية: سواء فرط النشاط أو قصور الغدة الدرقية يؤثران بشكل مباشر على انتظام الدورة لأن هرمونات الغدة الدرقية تتحكم في عملية الأيض بالكامل.\n• الرياضة المفرطة: التمارين الشاقة لفترات طويلة خاصة عند الرياضيات المحترفات قد تسبب غياب الدورة لأن الجسم يوجه طاقته للعضلات بدل الجهاز التناسلي.\n• فترة ما بعد الولادة والرضاعة: من الطبيعي أن تتأخر عودة الدورة بعد الولادة خاصة مع الرضاعة الطبيعية بسبب هرمون البرولاكتين.\n• الأدوية: بعض الأدوية مثل حبوب منع الحمل ومضادات الاكتئاب وأدوية الغدة الدرقية تؤثر على انتظام الدورة.\n• فترة ما قبل انقطاع الطمث: بعد سن 40-45 تبدأ الدورة تصبح غير منتظمة تدريجيا وهذا طبيعي.\n\nنصائح لتنظيم الدورة طبيعيا:\n\n• حافظي على وزن صحي ومتوازن\n• مارسي الرياضة باعتدال 3-4 مرات أسبوعيا\n• قللي التوتر عبر تقنيات الاسترخاء واليوغا\n• نامي 7-8 ساعات يوميا في أوقات منتظمة\n• تناولي غذاء متوازنا غني بالحديد وفيتامين B والمغنيزيوم\n• تتبعي دورتك بانتظام عبر تطبيق نبضة لاكتشاف أي تغيرات مبكرا\n\nمتى تراجعين الطبيبة:\n\n• اذا غابت الدورة لأكثر من 3 أشهر متتالية\n• اذا كانت الدورة أقصر من 21 يوما أو أطول من 35 يوما باستمرار\n• اذا صاحبها ألم شديد أو نزيف غزير\n• اذا لاحظت نزيفا بين الدورات\n\nتذكري أن جسمك يتحدث اليك من خلال دورتك الشهرية. أي تغيير كبير هو رسالة تستحق الانتباه.',
    'التبويض|إباضة|خصوبة|أيام التبويض':
      'دليل شامل عن التبويض والخصوبة:\n\nالتبويض هو عملية اطلاق البويضة الناضجة من المبيض لتنتقل عبر قناة فالوب استعدادا للاخصاب. هذه العملية تحدث مرة واحدة كل دورة شهرية وتستمر البويضة قابلة للاخصاب لمدة 12-24 ساعة فقط بعد خروجها من المبيض.\n\nتوقيت التبويض:\n\n• في الدورة المنتظمة 28 يوما يحدث التبويض عادة في اليوم 14 أي في منتصف الدورة تقريبا\n• الحساب الأدق: التبويض يحدث قبل 14 يوما من بداية الدورة القادمة. فاذا كانت دورتك 30 يوما فالتبويض حوالي اليوم 16\n• فترة الخصوبة تمتد لحوالي 6 أيام: 5 أيام قبل التبويض + يوم التبويض نفسه. هذا لأن الحيوانات المنوية تعيش في الجهاز التناسلي حتى 5 أيام\n\nعلامات التبويض التي يمكنك ملاحظتها:\n\n• تغير الافرازات المهبلية: تصبح شفافة ومطاطة تشبه بياض البيض. هذا النوع من المخاط يسهل حركة الحيوانات المنوية\n• ارتفاع طفيف في درجة حرارة الجسم الأساسية بمقدار 0.2-0.5 درجة بعد التبويض\n• ألم خفيف في جانب واحد من أسفل البطن يسمى ألم الاباضة أو mittelschmerz\n• زيادة الرغبة الجنسية بشكل طبيعي حول فترة التبويض\n• حساسية خفيفة في الثدي\n• انتفاخ بسيط في البطن\n\nطرق تتبع التبويض:\n\n• تطبيق نبضة: يحسب تلقائيا أيام الخصوبة المتوقعة بناء على بيانات دورتك\n• قياس درجة الحرارة الأساسية: قيسي حرارتك كل صباح قبل النهوض من السرير وسجليها. ستلاحظين ارتفاعا بعد التبويض\n• شرائط اختبار التبويض: تكشف ارتفاع هرمون LH في البول الذي يسبق التبويض بيوم أو يومين\n• مراقبة الافرازات: تعلمي التمييز بين أنواع المخاط المهبلي لمعرفة وقت الخصوبة\n\nنصائح لزيادة فرص الحمل:\n\n• مارسي العلاقة الزوجية كل يوم أو يومين خلال فترة الخصوبة\n• حافظي على وزن صحي لأن السمنة والنحافة تؤثران على التبويض\n• قللي التوتر لأنه يؤخر التبويض أو يمنعه\n• تناولي حمض الفوليك قبل الحمل بشهرين على الأقل\n• تجنبي التدخين والكحول والكافيين الزائد\n\nتطبيق نبضة يساعدك في تتبع كل هذه المعلومات تلقائيا ويرسل لك اشعارات في أيام الخصوبة المتوقعة.',
    // Pregnancy
    'أعراض الحمل|علامات الحمل|حمل مبكر':
      'دليل شامل عن أعراض الحمل المبكرة وكيفية التأكد منه:\n\nتختلف أعراض الحمل من امرأة لأخرى ومن حمل لآخر. بعض النساء تشعرن بالأعراض خلال الأسبوع الأول بعد الاخصاب بينما أخريات لا تظهر عليهن أعراض واضحة حتى الشهر الثاني. الأعراض ناتجة عن التغيرات الهرمونية الكبيرة التي تحدث في الجسم.\n\nالأعراض الشائعة في الأسابيع الأولى:\n\n• تأخر الدورة الشهرية: العلامة الأولى والأكثر وضوحا خاصة اذا كانت دورتك منتظمة. تأخر يوم واحد فقط قد يكون علامة\n• الغثيان والتقيؤ: يسمى غثيان الصباح لكنه قد يحدث في أي وقت. يبدأ عادة في الأسبوع السادس ويخف بعد الشهر الثالث. سببه ارتفاع هرمون HCG\n• التعب والارهاق غير العادي: شعور بالنعاس والحاجة للراحة أكثر من المعتاد بسبب ارتفاع هرمون البروجسترون الذي له تأثير مهدئ\n• انتفاخ وحساسية الثدي: يصبح الثدي أكبر حجما ومؤلما عند اللمس مع تغير لون الحلمة الى لون أغمق\n• كثرة التبول: الحاجة المتكررة للذهاب الى الحمام حتى في الليل بسبب زيادة تدفق الدم الى الكلى\n• تقلبات مزاجية: تغيرات مفاجئة في المزاج من فرح الى بكاء بسبب التقلبات الهرمونية الحادة\n• نفور من بعض الأطعمة والروائح: حاسة الشم تصبح أقوى وقد تشعرين بالاشمئزاز من أطعمة كنت تحبينها\n• نزيف خفيف وردي: نزول قطرات دم خفيفة في وقت مبكر قد يكون نزيف الانغراس وهو طبيعي\n• الامساك والانتفاخ: بسبب تأثير البروجسترون على حركة الأمعاء\n• الصداع والدوخة: بسبب تغيرات ضغط الدم وزيادة حجم الدورة الدموية\n\nكيف تتأكدين من الحمل:\n\n• اختبار الحمل المنزلي: دقيق بنسبة 99% اذا استخدم بعد تأخر الدورة. استخدمي أول بول في الصباح لنتيجة أدق\n• تحليل الدم: أدق من الاختبار المنزلي ويكشف الحمل قبل موعد الدورة. يقيس مستوى هرمون HCG بدقة\n• السونار: يظهر كيس الحمل بعد الأسبوع الخامس ونبض الجنين بعد الأسبوع السادس\n\nنصائح مهمة في بداية الحمل:\n\n• ابدئي بتناول حمض الفوليك فورا 400 ميكروغرام يوميا\n• حددي موعدا مع طبيبة النساء في أقرب وقت\n• تجنبي التدخين والكحول والأدوية بدون استشارة الطبيبة\n• قللي الكافيين الى أقل من 200 ملغ يوميا\n• تناولي غذاء متوازنا واشربي الماء بكثرة\n\nتذكري أن كل حمل تجربة فريدة. اذا كانت لديك أي مخاوف لا تترددي في استشارة طبيبتك.',
    'غذاء الحامل|أطعمة الحامل|تغذية الحامل|أكل الحامل':
      'دليل التغذية المتكامل للحامل - ما تأكلينه يؤثر مباشرة على صحة طفلك:\n\nالتغذية السليمة أثناء الحمل ليست مجرد أكل أكثر بل أكل أفضل وأذكى. جسمك يحتاج سعرات حرارية اضافية تدريجيا: لا شيء اضافي في الثلث الأول، حوالي 340 سعرة اضافية في الثلث الثاني، و450 سعرة في الثلث الثالث.\n\nالأطعمة المفيدة والضرورية:\n\n• الخضروات الورقية الداكنة: السبانخ والبروكلي والملوخية غنية بحمض الفوليك والحديد والكالسيوم. تناولي حصتين على الأقل يوميا\n• الفواكه الطازجة: التوت والبرتقال والموز والتفاح غنية بالفيتامينات والألياف ومضادات الأكسدة. 3-4 حصص يوميا مثالية\n• البروتين: الدجاج والسمك والبيض والبقوليات ضرورية لبناء أنسجة الجنين. احتياجك 75-100 غرام بروتين يوميا\n• الحليب ومشتقاته: مصدر أساسي للكالسيوم لبناء عظام وأسنان الجنين. 3 حصص يوميا من الحليب أو الزبادي أو الجبن\n• الحبوب الكاملة: الشوفان والأرز البني وخبز القمح الكامل توفر الطاقة المستدامة والألياف التي تمنع الامساك\n• المكسرات والبذور: اللوز والجوز وبذور الشيا غنية بأوميغا 3 والمغنيزيوم والبروتين النباتي\n• الأسماك الآمنة: السلمون والسردين غنيان بأوميغا 3 الضروري لنمو دماغ الجنين. تناولي 2-3 حصص أسبوعيا\n\nالأطعمة التي يجب تجنبها:\n\n• الأسماك العالية بالزئبق: سمك القرش وأبو سيف والماكريل الملكي لأن الزئبق يضر بالجهاز العصبي للجنين\n• اللحوم النيئة وغير المطبوخة جيدا: تحمل خطر بكتيريا التوكسوبلازما والسالمونيلا\n• الأجبان الطرية غير المبسترة: كالبري والفيتا والروكفور قد تحتوي على بكتيريا الليستيريا الخطرة\n• البيض النيئ: تجنبي المايونيز المنزلي والحلويات التي تحتوي بيضا غير مطبوخ\n• الكافيين الزائد: حددي استهلاكك بأقل من 200 ملغ يوميا أي حوالي فنجان قهوة واحد\n• الكحول: ممنوع تماما في جميع مراحل الحمل بأي كمية\n\nالمكملات الغذائية الضرورية:\n\n• حمض الفوليك: 400-800 ميكروغرام يوميا لمنع تشوهات الأنبوب العصبي\n• الحديد: 27 ملغ يوميا لمنع فقر الدم وضمان وصول الأكسجين للجنين\n• الكالسيوم: 1000 ملغ يوميا لبناء عظام الجنين دون استنزاف عظامك\n• فيتامين D: 600 وحدة دولية يوميا لامتصاص الكالسيوم\n• أوميغا 3 DHA: 200 ملغ يوميا لتطور دماغ وعيون الجنين\n\nنصائح عملية:\n\n• كلي 5-6 وجبات صغيرة بدل 3 كبيرة لتجنب الغثيان والحموضة\n• اشربي 8-10 أكواب ماء يوميا\n• اغسلي الفواكه والخضروات جيدا قبل الأكل\n• اطبخي اللحوم والبيض جيدا\n\nاستشيري طبيبتك قبل تناول أي مكملات اضافية.',
    'غثيان|وحام|تقيؤ|غثيان الحمل':
      'دليل شامل للتعامل مع الغثيان والوحام أثناء الحمل:\n\nيعتبر الغثيان من أكثر أعراض الحمل شيوعا حيث تعاني منه حوالي 70-80% من الحوامل. يسمى غثيان الصباح لكنه قد يحدث في أي وقت من اليوم. يبدأ عادة في الأسبوع السادس من الحمل ويبلغ ذروته بين الأسبوعين 8 و12 ثم يخف تدريجيا بعد الأسبوع 14 عند معظم النساء.\n\nأسباب الغثيان:\n\n• ارتفاع هرمون HCG الذي يفرزه الجنين وهو السبب الرئيسي\n• ارتفاع هرمون الاستروجين الذي يزيد حساسية حاسة الشم\n• تغيرات في الجهاز الهضمي بسبب هرمون البروجسترون الذي يبطئ عملية الهضم\n• انخفاض سكر الدم خاصة عند الاستيقاظ صباحا\n\nنصائح فعالة لتخفيف الغثيان:\n\n• كلي وجبات صغيرة ومتكررة: قسمي طعامك الى 5-6 وجبات صغيرة بدل 3 كبيرة. المعدة الفارغة تزيد الغثيان والمعدة الممتلئة جدا أيضا\n• بسكويت الصباح: ضعي بسكويتا جافا أو مقرمشات بجانب سريرك وكلي قطعتين قبل النهوض بعشرين دقيقة. انهضي ببطء\n• الزنجبيل: من أقوى مضادات الغثيان الطبيعية. اشربي شاي الزنجبيل الطازج أو تناولي حلوى الزنجبيل أو أضيفيه للطعام\n• النعناع: شاي النعناع أو استنشاق زيت النعناع يهدئ المعدة ويقلل الشعور بالغثيان\n• الليمون: شم شريحة ليمون طازج أو شرب ماء بالليمون يساعد في تخفيف الغثيان بشكل فوري\n• تجنبي المحفزات: ابتعدي عن الروائح القوية والأطعمة الدسمة والحارة والمقلية. اذا كان طهي الطعام يزعجك اطلبي المساعدة من شخص آخر\n• الترطيب: اشربي السوائل بين الوجبات وليس أثناءها. الماء والعصائر الطبيعية المخففة وماء جوز الهند خيارات جيدة\n• الراحة: التعب يفاقم الغثيان. خذي قيلولة عند الحاجة ونامي مبكرا\n• الأطعمة الباردة: قد تكون أقل اثارة للغثيان من الساخنة لأن رائحتها أخف\n• فيتامين B6: 25 ملغ ثلاث مرات يوميا يخفف الغثيان عند كثير من النساء. استشيري طبيبتك قبل تناوله\n\nالوحام:\n\nالوحام أو الرغبة الشديدة في أطعمة معينة أو النفور من أخرى طبيعي تماما. سببه التغيرات الهرمونية وأحيانا نقص بعض المعادن. استجيبي لرغباتك باعتدال لكن تجنبي الأطعمة الضارة.\n\nمتى تراجعين الطبيبة:\n\n• اذا كان التقيؤ شديدا ومستمرا أكثر من 3-4 مرات يوميا\n• اذا لم تستطيعي الاحتفاظ بأي طعام أو شراب لمدة 24 ساعة\n• اذا فقدت أكثر من 2 كيلو من وزنك\n• اذا شعرت بدوخة شديدة أو جفاف\n\nهذه قد تكون علامات القيء المفرط للحامل الذي يحتاج علاجا طبيا.',
    // Baby Care
    'رضيع|رضاعة|حليب الأم|الرضاعة الطبيعية':
      'دليل شامل للرضاعة الطبيعية - أفضل هدية تقدمينها لطفلك:\n\nالرضاعة الطبيعية هي الطريقة المثلى لتغذية المولود الجديد حيث يحتوي حليب الأم على كل ما يحتاجه الطفل من عناصر غذائية وأجسام مضادة تحميه من الأمراض. توصي منظمة الصحة العالمية بالرضاعة الطبيعية الحصرية لمدة 6 أشهر ثم الاستمرار مع الأطعمة التكميلية حتى عمر سنتين أو أكثر.\n\nفوائد الرضاعة الطبيعية للطفل:\n\n• حماية من الأمراض: تقلل خطر الاسهال والتهابات الأذن والجهاز التنفسي بنسبة 50-70%\n• تقوية المناعة: الأجسام المضادة في حليب الأم تحمي الطفل من الفيروسات والبكتيريا\n• نمو الدماغ: أحماض DHA و ARA في حليب الأم ضرورية لتطور الدماغ والبصر\n• تقليل خطر الحساسية: الأطفال الذين يرضعون طبيعيا أقل عرضة للحساسية والربو والأكزيما\n• هضم سهل: حليب الأم مصمم خصيصا لمعدة الرضيع ويقلل المغص والامساك\n\nفوائد الرضاعة للأم:\n\n• تساعد الرحم على العودة لحجمه الطبيعي بعد الولادة\n• تقلل خطر اكتئاب ما بعد الولادة\n• تساعد على فقدان الوزن المكتسب أثناء الحمل\n• تقلل خطر سرطان الثدي والمبيض على المدى البعيد\n\nأساسيات الرضاعة الناجحة:\n\n• البداية المبكرة: ابدئي الرضاعة خلال الساعة الأولى بعد الولادة. الملامسة المباشرة جلد لجلد تحفز غريزة الرضاعة\n• عدد الرضعات: 8-12 رضعة يوميا في الأسابيع الأولى أي كل 2-3 ساعات تقريبا. لا تنتظري بكاء الطفل بل ارضعيه عند أول علامات الجوع\n• الالتقام الصحيح: فم الطفل يجب أن يغطي معظم الهالة وليس فقط الحلمة. الالتقام الصحيح يمنع تشقق الحلمات ويضمن حصول الطفل على كمية كافية\n• المدة: دعي الطفل يرضع من ثدي واحد حتى يتركه بنفسه ثم اعرضي الثاني. بدلي الثدي الذي تبدئين به في كل رضعة\n• علامات الشبع: الطفل يترك الثدي بنفسه، يبدو مسترخيا، ينام بهدوء\n• التأكد من كفاية الحليب: 6 حفاضات مبللة يوميا على الأقل وزيادة مستمرة في الوزن تعني أن الحليب كاف\n\nتحديات شائعة وحلولها:\n\n• تشقق الحلمات: تأكدي من الالتقام الصحيح واستخدمي كريم اللانولين بعد كل رضعة\n• احتقان الثدي: أرضعي بانتظام واستخدمي كمادات دافئة قبل الرضاعة وباردة بعدها\n• قلة الحليب: أكثري من الرضاعة والملامسة وشرب السوائل والراحة\n\nتغذية الأم المرضعة:\n\n• اشربي 10-12 كوب ماء يوميا على الأقل\n• تناولي 500 سعرة حرارية اضافية يوميا\n• أكثري من البروتين والكالسيوم والحديد\n• تناولي أوميغا 3 من الأسماك أو المكملات\n\nاذا واجهت صعوبات لا تترددي في استشارة أخصائية رضاعة. المساعدة المبكرة تحل معظم المشاكل.',
    'نوم الطفل|نوم الرضيع|بكاء الطفل':
      'دليل شامل لنوم الطفل الرضيع والتعامل مع البكاء:\n\nالنوم ضروري لنمو الطفل وتطور دماغه. خلال النوم يفرز الجسم هرمون النمو ويقوي الجهاز المناعي ويعالج المعلومات التي تعلمها الطفل أثناء اليقظة. فهم أنماط نوم طفلك يساعدك على التعامل معها بشكل أفضل.\n\nساعات النوم حسب العمر:\n\n• حديث الولادة 0-3 أشهر: 14-17 ساعة يوميا موزعة على فترات قصيرة 2-4 ساعات لأن معدته صغيرة ويحتاج الرضاعة بانتظام\n• 4-6 أشهر: 12-15 ساعة يوميا. يبدأ النوم ليلا لفترات أطول 5-6 ساعات متواصلة مع 2-3 قيلولات نهارية\n• 7-12 شهر: 12-14 ساعة يوميا مع نوم ليلي أطول 8-10 ساعات وقيلولتين نهاريتين\n• 1-3 سنوات: 11-14 ساعة يوميا مع قيلولة واحدة نهارية\n\nقواعد النوم الآمن:\n\n• نومي الطفل على ظهره دائما وهذه أهم قاعدة لمنع متلازمة الموت المفاجئ SIDS\n• استخدمي فرشة مسطحة وصلبة بدون وسائد أو بطانيات سميكة أو ألعاب في السرير\n• درجة حرارة الغرفة المثالية 20-22 درجة مئوية. تجنبي التدفئة المفرطة\n• ألبسي الطفل طبقة واحدة أكثر مما ترتدينه أنت. يمكن استخدام كيس نوم بدل البطانية\n• ضعي سرير الطفل في غرفتك لكن ليس في سريرك خلال الأشهر الستة الأولى\n\nبناء روتين نوم صحي:\n\n• ابدئي الروتين في نفس الوقت كل ليلة حوالي الساعة 7-8 مساء\n• حمام دافئ لمدة 10 دقائق يساعد على الاسترخاء\n• تدليك لطيف بزيت الأطفال يهدئ الجهاز العصبي\n• ارضعي الطفل أو أعطيه رضعته الأخيرة\n• اقرئي قصة قصيرة أو غني تهويدة بصوت هادئ\n• ضعي الطفل في سريره وهو نعسان لكن لم ينم بعد ليتعلم النوم بنفسه\n• أطفئي الأنوار واستخدمي ضوءا خافتا اذا لزم الأمر\n\nالتعامل مع بكاء الطفل:\n\nالبكاء هو الطريقة الوحيدة التي يتواصل بها الرضيع. الأسباب الشائعة:\n\n• الجوع: أكثر الأسباب شيوعا. راقبي علامات الجوع المبكرة كوضع اليد في الفم والبحث عن الثدي\n• الحفاض المبلل أو المتسخ: بعض الأطفال حساسون جدا ويبكون فورا\n• التعب والحاجة للنوم: الطفل المتعب يصبح عصبيا ويصعب تهدئته\n• المغص: بكاء شديد لأكثر من 3 ساعات يوميا خاصة في المساء. يبدأ عادة في الأسبوع الثاني ويخف بعد الشهر الثالث\n• الحاجة للحضن: الطفل يحتاج الشعور بالأمان والقرب من أمه\n• الحرارة أو البرد: تحسسي رقبة الطفل لمعرفة اذا كان يشعر بالحرارة أو البرد\n\nنصائح لتهدئة الطفل الباكي:\n\n• احمليه قريبا من صدرك ليسمع نبضات قلبك\n• هزيه بلطف أو امشي به في الغرفة\n• استخدمي صوت الشيش المهدئ أو الضوضاء البيضاء\n• لفيه بقماط خفيف يشعره بالأمان\n\nمتى تقلقين: اذا كان البكاء مصحوبا بحرارة أعلى من 38 درجة أو رفض الرضاعة أو خمول غير طبيعي راجعي الطبيب فورا.',
    'تطعيم|لقاح|تطعيمات الطفل':
      'دليل شامل لتطعيمات الأطفال - حماية طفلك تبدأ من اللقاح:\n\nالتطعيمات من أهم الانجازات الطبية التي أنقذت ملايين الأرواح. تعمل اللقاحات بتعريض الجهاز المناعي لنسخة ضعيفة أو معطلة من الفيروس أو البكتيريا فيتعلم الجسم كيف يحاربها دون أن يمرض. عندما يتعرض الطفل لاحقا للمرض الحقيقي يكون جسمه مستعدا لمواجهته.\n\nجدول التطعيمات الأساسية:\n\n• عند الولادة: لقاح BCG ضد السل ولقاح التهاب الكبد B الجرعة الأولى. يعطى BCG في الذراع الأيسر ويترك ندبة صغيرة طبيعية\n• شهرين: اللقاح الثلاثي DTP ضد الدفتيريا والتيتانوس والسعال الديكي + لقاح شلل الأطفال الفموي أو بالحقن + لقاح الروتا ضد الاسهال الفيروسي + التهاب الكبد B الجرعة الثانية + لقاح المستدمية النزلية Hib\n• 4 أشهر: الجرعة الثانية من نفس اللقاحات السابقة. المناعة تتعزز مع كل جرعة تكرارية\n• 6 أشهر: الجرعة الثالثة + لقاح الانفلونزا الموسمية. التهاب الكبد B الجرعة الثالثة والأخيرة\n• 9 أشهر: لقاح الحصبة الأولى. يعطى في بعض البلدان لقاح الحمى الصفراء أيضا\n• 12 شهر: لقاح MMR الثلاثي ضد الحصبة والنكاف والحصبة الألمانية + لقاح جدري الماء + لقاح التهاب الكبد A\n• 18 شهر: جرعات تنشيطية من اللقاح الثلاثي وشلل الأطفال والمستدمية النزلية + الجرعة الثانية من MMR\n• 4-6 سنوات: جرعات تنشيطية اضافية قبل دخول المدرسة\n\nأعراض جانبية طبيعية بعد التطعيم:\n\n• احمرار أو تورم خفيف في مكان الحقنة يختفي خلال 2-3 أيام\n• حرارة خفيفة أقل من 38.5 درجة لمدة يوم أو يومين\n• بكاء وعصبية مؤقتة\n• فقدان شهية خفيف ليوم واحد\n\nكيف تخففين الأعراض:\n\n• ضعي كمادة باردة على مكان الحقنة\n• أعطي الطفل باراسيتامول بجرعة مناسبة لعمره\n• أكثري من الرضاعة والسوائل\n• دعي الطفل يرتاح ولا تقلقي فهذه علامة أن الجسم يبني المناعة\n\nنصائح مهمة:\n\n• التزمي بجدول التطعيمات في مواعيدها لضمان أقصى حماية\n• احتفظي بدفتر التطعيمات في مكان آمن وأحضريه في كل زيارة\n• أخبري الطبيب اذا كان الطفل مريضا أو لديه حساسية قبل التطعيم\n• لا تؤجلي التطعيم بسبب رشح خفيف فهو آمن\n• تطبيق نبضة يذكرك بمواعيد التطعيمات القادمة\n\nراجعي طبيب الأطفال للجدول الكامل المعتمد في بلدك.',
    // General Health
    'زيارة الطبيب|متى أزور الطبيب|استشارة طبية':
      'دليل شامل - متى يجب زيارة الطبيبة وأهمية الفحوصات الدورية:\n\nالعناية بصحتك ليست فقط عند المرض بل تشمل الفحوصات الوقائية المنتظمة التي تكشف المشاكل مبكرا عندما يكون العلاج أسهل وأنجح. كثير من الأمراض النسائية لا تظهر لها أعراض واضحة في البداية.\n\nحالات تستدعي زيارة الطبيبة فورا:\n\n• آلام شديدة غير طبيعية أثناء الدورة الشهرية لا تستجيب للمسكنات العادية وتمنعك من ممارسة حياتك\n• نزيف غزير يتطلب تغيير الفوطة كل ساعة أو أقل أو نزيف بين الدورات\n• تأخر الدورة أكثر من 3 أشهر بدون حمل\n• ألم أثناء الحمل خاصة في أسفل البطن أو أي نزيف مهبلي\n• حرارة الطفل أكثر من 38.5 درجة خاصة اذا كان عمره أقل من 3 أشهر\n• افرازات مهبلية غير طبيعية برائحة كريهة أو لون غريب أو مصحوبة بحكة\n• كتلة أو تغير في الثدي\n• ألم شديد أثناء العلاقة الزوجية\n\nفحوصات دورية مهمة لكل امرأة:\n\n• الفحص السنوي النسائي: يشمل فحص الحوض وعنق الرحم ومسحة باب للكشف المبكر عن سرطان عنق الرحم. يوصى به سنويا بعد سن 21\n• فحص الثدي: الفحص الذاتي شهريا بعد انتهاء الدورة + الماموغرام كل سنة أو سنتين بعد سن 40\n• تحاليل الدم الشاملة: مرة سنويا على الأقل تشمل صورة دم كاملة لفقر الدم ووظائف الغدة الدرقية والسكر والدهون وفيتامين D والكالسيوم\n• فحص ضغط الدم: خاصة اذا كنت حاملا أو تتناولين حبوب منع الحمل\n• فحص العظام: بعد سن 50 أو مبكرا اذا كان هناك عوامل خطر لهشاشة العظام\n\nزيارات الحامل الدورية:\n\n• الثلث الأول: زيارة كل 4 أسابيع مع سونار للتأكد من نبض الجنين وتحديد عمر الحمل\n• الثلث الثاني: زيارة كل 4 أسابيع مع سونار الشذوذات في الأسبوع 20\n• الثلث الثالث: زيارة كل أسبوعين ثم كل أسبوع في الشهر الأخير مع متابعة نمو الجنين وتحضيرات الولادة\n\nزيارات طبيب الأطفال:\n\n• الأسبوع الأول: فحص شامل للمولود\n• شهر 1 و2 و4 و6 و9 و12 و18: فحوصات نمو وتطعيمات\n• بعد السنة الأولى: كل 6 أشهر ثم سنويا\n\nnصائح للاستفادة القصوى من الزيارة:\n\n• حضري قائمة بأسئلتك ومخاوفك مسبقا\n• سجلي أي أعراض جديدة مع تاريخ ظهورها\n• أحضري نتائج تحاليل وأدوية سابقة\n• لا تخجلي من أي سؤال مهما بدا محرجا فالطبيبة موجودة لمساعدتك\n\nلا تترددي في استشارة الطبيبة عند الشك. الاكتشاف المبكر هو مفتاح العلاج الناجح.',
    'فيتامين|مكملات|حديد|فوليك|كالسيوم':
      'دليل شامل للفيتامينات والمكملات الغذائية المهمة لصحة المرأة:\n\nجسم المرأة له احتياجات غذائية خاصة تتغير حسب مراحل الحياة من البلوغ الى الحمل والرضاعة وبعد انقطاع الطمث. المكملات الغذائية لا تغني عن الطعام المتوازن لكنها تكمل النقص الذي قد لا يغطيه الغذاء وحده.\n\nالفيتامينات والمعادن الأساسية:\n\n• حمض الفوليك (فيتامين B9): من أهم الفيتامينات للمرأة خاصة قبل وأثناء الحمل. يمنع تشوهات الأنبوب العصبي عند الجنين مثل الشوكة المشقوقة. الجرعة اليومية: 400 ميكروغرام لجميع النساء في سن الانجاب و600-800 ميكروغرام للحامل. مصادره الطبيعية: السبانخ والعدس والحمص والبروكلي والبرتقال\n• الحديد: ضروري لانتاج الهيموغلوبين الذي ينقل الأكسجين في الدم. المرأة تفقد حديدا مع كل دورة شهرية وتحتاج أكثر أثناء الحمل. نقص الحديد يسبب فقر الدم والتعب والدوخة وتساقط الشعر. الجرعة: 18 ملغ يوميا للنساء و27 ملغ للحامل. لتحسين الامتصاص تناوليه مع فيتامين C وتجنبي الشاي والقهوة بعده بساعتين\n• الكالسيوم: ضروري لصحة العظام والأسنان ومنع هشاشة العظام لاحقا. أثناء الحمل يسحب الجنين الكالسيوم من عظام الأم اذا لم يكن كافيا في غذائها. الجرعة: 1000 ملغ يوميا. مصادره: الحليب والزبادي والجبن والسمسم واللوز والسردين\n• فيتامين D: ضروري لامتصاص الكالسيوم في الأمعاء وتقوية العظام ودعم المناعة. نقصه شائع جدا خاصة في المناطق قليلة الشمس. الجرعة: 600-1000 وحدة دولية يوميا. أفضل مصدر هو التعرض لأشعة الشمس 15-20 دقيقة يوميا\n• أوميغا 3 DHA و EPA: أحماض دهنية أساسية لصحة القلب والدماغ وتقليل الالتهابات. أثناء الحمل ضرورية لتطور دماغ الجنين وعيونه. الجرعة: 200-300 ملغ DHA يوميا. مصادره: السلمون والسردين والجوز وبذور الشيا\n• فيتامين B12: ضروري لصحة الأعصاب وانتاج خلايا الدم الحمراء. نقصه يسبب تنميل الأطراف والتعب وضعف الذاكرة. مهم خاصة للنباتيات لأنه موجود أساسا في المنتجات الحيوانية\n• المغنيزيوم: يخفف تشنجات الدورة الشهرية ويحسن النوم ويقلل القلق. نقصه يسبب تشنجات عضلية وصداع وأرق. الجرعة: 310-360 ملغ يوميا. مصادره: الموز والشوكولاتة الداكنة واللوز والسبانخ\n• الزنك: يدعم المناعة ويساعد في التئام الجروح وصحة البشرة والشعر. مهم أثناء الحمل لنمو الجنين. الجرعة: 8-11 ملغ يوميا\n\nنصائح مهمة:\n\n• استشيري طبيبتك قبل تناول أي مكملات خاصة أثناء الحمل والرضاعة\n• أجري تحليل دم لمعرفة النقص الفعلي قبل البدء بالمكملات\n• تناولي المكملات مع الطعام لتحسين الامتصاص وتقليل اضطرابات المعدة\n• لا تتجاوزي الجرعات الموصى بها فالزيادة قد تكون ضارة\n• الطعام المتوازن هو الأساس والمكملات تكمله فقط\n\nتذكري أن احتياجاتك تتغير حسب عمرك وحالتك الصحية. المتابعة المنتظمة مع طبيبتك تضمن حصولك على ما تحتاجينه.',
    'رياضة|تمارين|رياضة الحامل|مشي':
      'دليل شامل للرياضة أثناء الحمل - حركي جسمك بأمان:\n\nالرياضة أثناء الحمل ليست خطيرة بل هي مفيدة جدا لصحة الأم والجنين اذا مورست بالطريقة الصحيحة. توصي الكلية الأمريكية لأطباء النساء والولادة بممارسة 150 دقيقة رياضة معتدلة أسبوعيا أي حوالي 30 دقيقة يوميا 5 أيام في الأسبوع.\n\nفوائد الرياضة أثناء الحمل:\n\n• تخفيف آلام الظهر وتقوية العضلات التي تدعم العمود الفقري\n• تقليل خطر سكري الحمل وتسمم الحمل بنسبة 30-40%\n• تحسين المزاج وتقليل القلق والاكتئاب بفضل هرمون الاندورفين\n• تحسين النوم وتقليل الأرق الشائع في الحمل\n• تسهيل الولادة الطبيعية وتقصير مدة المخاض\n• سرعة التعافي بعد الولادة والعودة للوزن الطبيعي\n• تقليل الامساك والانتفاخ بتحسين حركة الأمعاء\n• تحسين الدورة الدموية وتقليل تورم القدمين\n\nرياضات آمنة ومفيدة:\n\n• المشي: أفضل رياضة للحامل وأكثرها أمانا. ابدئي بعشر دقائق وزيدي تدريجيا حتى 30 دقيقة. ارتدي حذاء مريحا وامشي على سطح مستو\n• السباحة: تدعم الماء وزنك الزائد وتخفف الضغط على المفاصل. ممتازة لآلام الظهر. تجنبي المياه الحارة جدا\n• يوغا الحوامل: تحسن المرونة والتنفس والاسترخاء. اختاري حصص مخصصة للحوامل وتجنبي وضعيات الاستلقاء على الظهر بعد الشهر الرابع\n• تمارين كيجل: تقوي عضلات قاع الحوض وتسهل الولادة وتمنع سلس البول. اقبضي عضلات الحوض لمدة 10 ثوان ثم استرخي. كرري 10-15 مرة 3 مرات يوميا\n• التمدد الخفيف: يخفف التوتر العضلي ويحسن المرونة. ركزي على تمارين الظهر والساقين والكتفين\n• ركوب الدراجة الثابتة: آمن لأنه لا يوجد خطر السقوط. حافظي على سرعة معتدلة\n\nرياضات يجب تجنبها:\n\n• الرياضات التي فيها خطر السقوط: ركوب الخيل والتزلج وركوب الدراجة في الشارع\n• الرياضات العنيفة والتصادمية: كرة القدم والملاكمة والفنون القتالية\n• الغوص: ضغط الماء خطير على الجنين\n• القفز والحركات المفاجئة: تؤثر على الأربطة المرتخية بسبب هرمون الريلاكسين\n• حمل الأثقال الثقيلة: أكثر من 5 كيلو خطر\n• الاستلقاء على الظهر: بعد الشهر الرابع لأن وزن الرحم يضغط على الوريد الأجوف\n\nعلامات يجب التوقف فورا:\n\n• نزيف مهبلي أو تسرب سوائل\n• دوخة أو صداع شديد\n• ألم في الصدر أو ضيق تنفس\n• تقلصات رحمية منتظمة\n• ألم أو تورم في الساق\n\nاستشيري طبيبتك قبل البدء وأخبريها بنوع الرياضة التي تمارسينها.',
    'نفسية|اكتئاب|قلق|اكتئاب ما بعد الولادة':
      'دليل شامل للصحة النفسية للأم - صحتك النفسية أولوية وليست رفاهية:\n\nالأمومة تجربة جميلة لكنها مليئة بالتحديات النفسية والعاطفية. من الطبيعي أن تشعري بمشاعر متضاربة من الفرح والقلق والخوف والتعب. المهم أن تعرفي متى تكون هذه المشاعر طبيعية ومتى تحتاجين مساعدة.\n\nالكآبة النفاسية Baby Blues:\n\nتصيب 70-80% من الأمهات الجدد في الأيام الأولى بعد الولادة. تشمل البكاء بلا سبب واضح وتقلبات مزاجية وقلق على الطفل. هذه حالة طبيعية تزول خلال أسبوعين بسبب الانخفاض المفاجئ في الهرمونات بعد الولادة.\n\nاكتئاب ما بعد الولادة:\n\nحالة أخطر تصيب 10-15% من الأمهات وقد تبدأ في أي وقت خلال السنة الأولى بعد الولادة. الأعراض تشمل:\n\n• حزن مستمر وشعور بالفراغ لأكثر من أسبوعين\n• صعوبة الترابط مع الطفل والشعور بالذنب تجاهه\n• بكاء متكرر وشعور باليأس وعدم القيمة\n• أرق شديد حتى عندما يكون الطفل نائما أو نوم مفرط\n• فقدان الشهية أو الأكل العاطفي المفرط\n• فقدان الاهتمام بالأنشطة التي كنت تستمتعين بها\n• صعوبة التركيز واتخاذ القرارات البسيطة\n• الانسحاب من العائلة والأصدقاء\n• أفكار مخيفة عن ايذاء النفس أو الطفل\n\nعوامل الخطر:\n\n• تاريخ سابق مع الاكتئاب أو القلق\n• مشاكل في العلاقة الزوجية\n• ولادة صعبة أو مضاعفات صحية\n• عدم وجود دعم عائلي\n• ضغوط مادية\n• حمل غير مخطط له\n\nنصائح للعناية بصحتك النفسية:\n\n• اطلبي المساعدة: لا تحاولي فعل كل شيء بمفردك. اطلبي من زوجك وعائلتك المشاركة في رعاية الطفل والمنزل\n• نامي كلما نام الطفل: الحرمان من النوم يفاقم الاكتئاب بشكل كبير. أجلي الأعمال المنزلية ونامي\n• خذي وقتا لنفسك: حتى 15 دقيقة يوميا للاستحمام بهدوء أو قراءة أو المشي تفعل المعجزات\n• تواصلي مع أمهات أخريات: الشعور بأنك لست وحدك يخفف كثيرا. انضمي لمجموعات الأمهات\n• مارسي الرياضة الخفيفة: المشي 20 دقيقة يوميا يفرز هرمونات السعادة ويحسن المزاج بشكل ملحوظ\n• تحدثي عن مشاعرك: لا تكبتي مشاعرك. تحدثي مع زوجك أو صديقة مقربة أو مختصة\n• تغذي جيدا: سوء التغذية يزيد التعب ويفاقم المزاج السيء. تناولي أوميغا 3 وفيتامين D\n• قللي التوقعات: لا يوجد أم مثالية. كفى بالطفل أن يكون محبوبا ومغذى ونظيفا وآمنا\n\nمتى تطلبين مساعدة متخصصة:\n\n• اذا استمرت الأعراض أكثر من أسبوعين بعد الولادة\n• اذا شعرت بأنك لا تستطيعين الاعتناء بنفسك أو بطفلك\n• اذا راودتك أفكار عن ايذاء نفسك\n• اذا كنت تشعرين بالخوف المستمر أو نوبات هلع\n\nالعلاج متاح وفعال. العلاج النفسي والأدوية عند الحاجة يساعدان الغالبية العظمى من الأمهات على التعافي. طلب المساعدة علامة قوة وليس ضعف. صحتك النفسية هي أساس صحة عائلتك بأكملها.',
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
