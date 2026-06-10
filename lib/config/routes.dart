import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/cycle/cycle_dashboard.dart';
import '../screens/cycle/symptom_logger.dart';
import '../screens/pregnancy/pregnancy_dashboard.dart';
import '../screens/pregnancy/kick_counter_screen.dart';
import '../screens/baby/baby_dashboard.dart';
import '../screens/baby/vaccination_schedule.dart';
import '../screens/community/community_screen.dart';
import '../screens/community/create_post_screen.dart';
import '../screens/community/post_detail_screen.dart';
import '../screens/ai_chat/ai_chat_screen.dart';
import '../screens/doctors/doctors_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_panel_screen.dart';
import '../screens/shop/cart_screen.dart';
import '../screens/baby_names/baby_names_screen.dart';
import '../screens/health/medication_tracker_screen.dart';
import '../screens/health/health_measurements_screen.dart';
import '../services/admin_service.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String intro = '/intro';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String cycleDashboard = '/cycle';
  static const String symptomLogger = '/symptom-logger';
  static const String pregnancyDashboard = '/pregnancy';
  static const String kickCounter = '/kick-counter';
  static const String babyDashboard = '/baby';
  static const String vaccinationSchedule = '/vaccinations';
  static const String community = '/community';
  static const String createPost = '/create-post';
  static const String postDetail = '/post';
  static const String aiChat = '/ai-chat';
  static const String doctors = '/doctors';
  static const String profile = '/profile';
  static const String adminPanel = '/admin';
  static const String cart = '/cart';
  static const String babyNames = '/baby-names';
  static const String terms = '/terms';
  static const String privacy = '/privacy';
  static const String medicationTracker = '/medications';
  static const String healthMeasurements = '/health-measurements';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: intro,
        builder: (context, state) => const IntroScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: cycleDashboard,
        builder: (context, state) => const CycleDashboard(),
      ),
      GoRoute(
        path: symptomLogger,
        builder: (context, state) => const SymptomLogger(),
      ),
      GoRoute(
        path: pregnancyDashboard,
        builder: (context, state) => const PregnancyDashboard(),
      ),
      GoRoute(
        path: kickCounter,
        builder: (context, state) => const KickCounterScreen(),
      ),
      GoRoute(
        path: babyDashboard,
        builder: (context, state) => const BabyDashboard(),
      ),
      GoRoute(
        path: vaccinationSchedule,
        builder: (context, state) => const VaccinationSchedule(),
      ),
      GoRoute(
        path: community,
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        path: createPost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/post/:postId',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['postId']!,
        ),
      ),
      GoRoute(
        path: aiChat,
        builder: (context, state) => const AIChatScreen(),
      ),
      GoRoute(
        path: doctors,
        builder: (context, state) => const DoctorsListScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: adminPanel,
        redirect: (context, state) async {
          // يجب أن يكون المستخدم مسجلاً دخوله
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return login;
          // يجب أن يكون له دور إداري
          final admin = AdminService();
          await admin.initialize();
          if (!admin.isAdmin) return home;
          return null;
        },
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: babyNames,
        builder: (context, state) => const BabyNamesScreen(),
      ),
      GoRoute(
        path: terms,
        builder: (context, state) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: privacy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: medicationTracker,
        builder: (context, state) => const MedicationTrackerScreen(),
      ),
      GoRoute(
        path: healthMeasurements,
        builder: (context, state) => const HealthMeasurementsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ')),
      body: Center(child: Text('الصفحة غير موجودة: ${state.error}')),
    ),
  );
}






