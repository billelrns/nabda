# نبضة - Nabda (Women's Health App)

A comprehensive Flutter application for women's health tracking, including menstrual cycle monitoring, pregnancy tracking, baby care, and community support.

## Features

### 1. Menstrual Cycle Tracking
- Calendar-based cycle tracking
- Symptom logging (mood, flow, symptoms)
- Cycle predictions
- Fertility window detection

### 2. Pregnancy Monitoring
- Gestational week tracking
- Baby size information
- Doctor appointments
- Kick counter

### 3. Baby Care
- Growth tracking (weight, height, head circumference)
- Milestone tracking
- Vaccination schedule
- Health updates

### 4. Community
- Discussion forums by category
- Anonymous posting option
- Like and comment system
- User engagement features

### 5. AI-Powered Support
- Intelligent chat support
- Health tips and recommendations
- Arabic language support

### 6. Doctor Directory
- Search and filter doctors
- Ratings and reviews
- Appointment booking
- Contact information

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── config/
│   ├── theme.dart
│   └── routes.dart
├── models/
│   ├── user_model.dart
│   ├── cycle_model.dart
│   ├── pregnancy_model.dart
│   ├── baby_model.dart
│   ├── community_post_model.dart
│   ├── doctor_model.dart
│   └── message_model.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── notification_service.dart
│   └── ai_service.dart
├── blocs/
│   ├── auth/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   └── auth_state.dart
│   └── cycle/
│       ├── cycle_bloc.dart
│       ├── cycle_event.dart
│       └── cycle_state.dart
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── cycle/
│   │   ├── cycle_dashboard.dart
│   │   └── symptom_logger.dart
│   ├── pregnancy/
│   │   ├── pregnancy_dashboard.dart
│   │   └── kick_counter_screen.dart
│   ├── baby/
│   │   ├── baby_dashboard.dart
│   │   └── vaccination_schedule.dart
│   ├── community/
│   │   ├── community_screen.dart
│   │   └── create_post_screen.dart
│   ├── ai_chat/
│   │   └── ai_chat_screen.dart
│   ├── doctors/
│   │   └── doctors_list_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── widgets/
│   ├── custom_app_bar.dart
│   ├── mood_selector.dart
│   ├── symptom_chip.dart
│   ├── post_card.dart
│   └── chat_bubble.dart
├── utils/
│   ├── constants.dart
│   ├── helpers.dart
│   └── validators.dart
└── l10n/
    ├── app_ar.arb
    └── app_en.arb
```

## Dependencies

- **flutter_bloc**: State management
- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication
- **cloud_firestore**: Database
- **go_router**: Navigation
- **table_calendar**: Calendar widget
- **fl_chart**: Charts
- **google_fonts**: Custom fonts
- **intl**: Internationalization
- **http**: HTTP requests
- **image_picker**: Image selection
- **shared_preferences**: Local storage
- **cached_network_image**: Image caching

## Getting Started

1. **Clone the repository**
```bash
git clone <repository_url>
cd nabda_flutter
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
- Replace Firebase credentials in `lib/firebase_options.dart`
- Download google-services.json for Android
- Download GoogleService-Info.plist for iOS

4. **Run the app**
```bash
flutter run
```

## Configuration

### Firebase Setup
1. Create a Firebase project at https://console.firebase.google.com
2. Enable Authentication (Email/Password)
3. Create Firestore database
4. Update Firebase credentials in `firebase_options.dart`

### Localization
- Arabic (ar) - Default
- English (en)

## Theme
- Primary Color: Teal (#00897B)
- Accent Color: Pink (#E91E63)
- Font: Almarai, Cairo (Arabic fonts)

## Architecture

The app follows clean architecture principles:
- **Models**: Data structures
- **Services**: Business logic and API calls
- **BLoCs**: State management
- **Screens**: UI pages
- **Widgets**: Reusable UI components
- **Utils**: Helpers and validators

## Testing

(Testing files to be added)

## Contributing

Guidelines for contributing to the project.

## License

This project is licensed under the MIT License.

## Support

For support, email support@nabda.app

---

Made with ❤️ for women's health
