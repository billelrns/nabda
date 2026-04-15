import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
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
import '../screens/ai_chat/ai_chat_screen.dart';
import '../screens/doctors/doctors_list_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
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
  static const String aiChat = '/ai-chat';
  static const String doctors = '/doctors';
  static const String profile = '/profile';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
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
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ')),
      body: Center(child: Text('الصفحة غير موجودة: ${state.error}')),
    ),
  );
}
