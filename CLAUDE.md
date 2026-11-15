# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run the app (requires connected device or emulator)
flutter run

# Build Android APK
flutter build apk

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Analyze code
flutter analyze

# Check for dependency updates
flutter pub outdated
```

## Architecture Overview

Nabda is a Flutter women's health app targeting Arabic-speaking users. It follows a layered architecture:

```
lib/
├── main.dart            # App entry point, locale management, inline translations (~135KB)
├── firebase_options.dart
├── config/              # Theme (Material 3, Almarai font) and GoRouter route definitions
├── models/              # Pure data classes (user, cycle, pregnancy, baby, community, doctor, message)
├── services/            # Firebase/external API wrappers (auth, firestore, notifications, AI)
├── blocs/               # BLoC state management — only auth and cycle are implemented
│   ├── auth/
│   └── cycle/
├── screens/             # One file per screen, organized by feature subdirectory
├── widgets/             # Reusable UI components (5 widgets)
├── utils/               # Constants, helpers, validators
└── l10n/                # ARB files (ar, en) — note: translations are also duplicated inline in main.dart
```

**State management split:** `AuthBloc` and `CycleBloc` use flutter_bloc. Other features (pregnancy, baby, community, doctors) call services directly from screens without a BLoC layer.

**Navigation:** GoRouter with 17 named routes defined in `lib/config/routes.dart`. Initial route is `/splash`.

**Data layer:** All remote data flows through `FirestoreService` (Firestore CRUD) and `AuthService` (Firebase Auth email/password). `sqflite` is declared as a dependency but the primary persistence is Firestore. Local preferences (language selection) use SharedPreferences.

**AI chat:** `lib/services/ai_service.dart` and the `AIChatScreen` in `lib/screens/ai_chat/` call the Google Gemini API directly from the client via `http`. The API key is embedded in `lib/main.dart` around line 2142.

**Localisation:** Three locales — Arabic (`ar-SA`, default), English (`en-US`), French (`fr-FR`). A custom `AppLocalizations` class with a large hardcoded translation map lives in `main.dart`. The `lib/l10n/` ARB files are a secondary/incomplete copy. Locale state is managed by a global `LocaleNotifier` (ChangeNotifier + Provider).

**Theme:** Material 3, primary teal `#00897B`, accent pink `#E91E63`, Almarai Google Font for all text (Arabic-optimised).

## Firebase Setup

The app requires Firebase before it can run:
1. Enable **Authentication** (Email/Password provider) in Firebase console.
2. Create a **Firestore** database.
3. Place `google-services.json` in `android/app/` (excluded from git).
4. Credentials are pre-configured in `lib/firebase_options.dart` for the `nabda-app-ca864` Firebase project.

## Google Play Release

- **Android applicationId is `com.nabda.womenhealth`** (changed 2026-09-26 — `com.nabda.app` was taken on Play). The Kotlin `namespace` / `MainActivity` package stays `com.nabda.app`; don't change it.
- Firebase has a separate Android app registered for `com.nabda.womenhealth` (appId `1:911912460091:android:b302018d2448f8235b611e`), used in `google-services.json` and `firebase_options.dart`.
- Release signing: `android/key.properties` → `C:/keys/nabda-release.jks` (never commit; back up offline).
- Build machine has ~7 GB RAM: `android/gradle.properties` is tuned (Xmx2048m, C2 off, 1 worker). Don't lower Xmx below 2048m — `mergeDexRelease` OOMs at 1024m. Avoid `flutter clean` before every build.
- Bump `version:` in `pubspec.yaml` (versionCode) for every Play upload. First upload was `1.0.0+2` to Closed testing (Alpha), testers via Google Group `nabda-testers@googlegroups.com`.
- Play declarations: Ads = No (the shop's `FeedVideoAd` only promotes own products), no Advertising ID, Data safety declares Crashlytics + FCM IDs. Update these before adding any ad SDK.
- **Personal Play account ⇒ no medical features.** `1.0.0+2` was rejected (Play Console Requirements: medical apps need an Organization account). `lib/config/play_compliance.dart` → `kHideMedicalFeatures = true` hides medication tracker, BP/sugar log, doctors directory, AI assistant, and 5 medical article subcategories. Flip to `false` only after moving to an Organization account. Any new medical-ish feature must be gated by this flag.
- Never attribute content to doctors or a "medical team" — there is none. Article `author` is always `kEditorialAuthor` («فريق تحرير نبضة»).
- `kShowLanguagePicker = false` until EN/FR translations are complete.
- Vaccination tracking is a Medical feature per Google ("Disease prevention and public health" lists vaccination tracking) — gated by `kHideMedicalFeatures`, as are vaccine/medication reminders, the kick counter, contraction timer, BP tracker and the prenatal medical checklist. Pregnancy is labelled «رحلة الحمل» (not «متابعة»).
- The Gemini assistant ships as a **non-medical lifestyle assistant** (`kShowLifestyleAssistant`, `kAssistantSystemPrompt`, `isMedicalQuestion()` pre-filter in `play_compliance.dart`). Never add health Q&A, dosages, or symptom answers to it or its offline KB.
- Supplements and medical devices are not sold: `lib/config/shop_config.dart` → `isHiddenProduct()` must wrap every product list/stream.
- Repeated Play rejections for the same policy can escalate to suspension — don't resubmit speculatively.

## Website (nabda.online)

- **Architecture:** static multi-page site (vanilla ES modules + Firebase JS SDK 10 compat) in `web/`, Flutter Web lives under **`/app/`**. Build with `.\tool\build_site.ps1` (builds Flutter with `--base-href /app/`, moves it to `build/web/app`, copies the static site to the root, `web/home.html` becomes `index.html`, regenerates sitemaps), then `firebase deploy --only hosting,functions,firestore:rules`. `web/index.html` is Flutter's bootstrap — don't turn it into a site page.
- **Logged-in = app experience (phones only):** on mobile (≤820px wide or Android/iPhone/iPad UA) logged-in users opening `/`, `/pregnancy`, `/baby`, `/cycle`, `/fertility` or `/community` (base paths only — week/month/post deep links stay site pages) are sent to `/app/` (`web/js/app-redirect.js` in `<head>` via the `nb_auth` localStorage hint, plus `shouldOpenApp()` in `shell.js`). **Desktop is unchanged on purpose** (owner's decision): the site stays the site after login, `login.html` defaults `next` to `/` on desktop and `/app/` on mobile, and Flutter Web keeps its wide sidebar layout. `?site=1` sets `sessionStorage.nb_site` = browse the site without redirect (cleared when the app opens or with `?app=1`). Articles, shop, product, cart, checkout, account, admin, fiqh/qadaa and tools are never redirected. `AuthGate` on mobile web: signed-out → redirect to `/` (after logout) or `/login?next=%2Fapp%2F` (direct visit), with a 15 s `nb_app_bounce` loop guard that falls back to `WebPublicHome`; desktop keeps `WebPublicHome`. `web/index.html` shows a PWA install banner on phones only (Android `beforeinstallprompt`, iOS instructions); manifest has `id`/`scope` for `/app/`. One-click deploy: `نشر_الموقع.bat` (build → preview channel → confirm → production).
- **Performance rules:** site images under `web/landing-assets/` are served as `.webp` (PNG originals kept only for og:image / Facebook); new images → WebP ≤1400px, and `<img loading="lazy" decoding="async">` below the fold. Firebase compat `<script>`s use `defer` (module scripts still run after them); never add a classic inline script that uses `firebase` on those pages. App start: splash 1.6 s, `MainNav` builds a tab only on first visit (`_visitedTabs`), timezone data is `latest_10y`, web font wait ≤2.5 s.
- **Notification schedule (`AppNotifs`):** products 3×/day (11:00, 15:00, 20:00) for 3 days, payload `product:<id>`; «مقال اليوم» daily 09:00 for 7 days (`_scheduleArticles`, `articles_channel`, ids 1600–1629, hours in `_articleHours`, picked from the user's stage category, most-read, `isHiddenArticleTitle` excluded), payload `article:<id>` → `SmartArticleDetailScreen`. Each type has an on/off key in `app_config/notifications` (`water|tips|pregnancy|products|articles`).
- **Notifications:** taps go through `lib/services/notification_router.dart` (`appNavigatorKey` on `MaterialApp`). Local product notifications carry payload `product:<id>`; FCM uses `data.linkType/linkId` or `data.productId` → opens `LandingProductScreen`. Images are rendered by `NotificationImages` as a 1200×600 card (whole product visible, pink background) with a 256px square thumbnail as largeIcon.
- **Shell:** every page has `<header id="nb-header">` + `<div id="nb-footer">` and loads `/js/shell.js` (header = the landing glass nav; logged-in users get an account dropdown instead of login buttons). Shared helpers: `js/utils.js` (`toDate`, `pregnancyFromStart`, product/article cards, `getVisibleProducts`, `getTopArticles`), `js/store-config.js` (shipping rates + `site_config/settings`), `js/cart.js`, `js/shop-rules.js` (`isHiddenProduct`, mirror of `shop_config.dart` — apply to every product list).
- **Data written by the site must match the app schema:** dates as Firestore `Timestamp` (never strings — the app casts them), `lifeStage` ∈ `pregnant|baby|planning|cycle` (planning also sets `goal: 'trying'`), cycle uses `lastPeriodStart` + `cycleLength`, babies in `users/{uid}/babies`, community posts use `CommunityPostModel.toJson()` fields (`author`, `category` ∈ general/pregnancy/baby/cycle, `id`), comments `{userId, author, text, createdAt}`. Pregnancy week = `floor(days/7)` clamped 1..42 like `main.dart`. Like `PregnancyDates`, `dueDate` takes priority over `pregnancyStartDate` (use `pregnancyFromUser()`); whenever the site writes `pregnancyStartDate` it also writes `dueDate` (+280 days) and `dueDateSource: 'lmp'`.
- **Birth-month clubs (community):** same logic as `CohortService` — key `due_YYYY_MM` (from dueDate, else LMP+280) or `born_YYYY_MM` (baby). `community.js` auto-joins on every visit (transaction on `users.cohortKey` + `cohort_members_count`, mirrored to `users_directory`); club posts carry `cohortKey` + `isPublic: false` and are posted only to the user's own club; other clubs (±6 months) are read-only for browsing. Public feed excludes posts with a `cohortKey`. Club UI = month carousel; each month has an icon `web/img/clubs/month_MM.webp` + pastel colours (`MONTH_THEME` in `community.js`). The app mirrors it in `lib/widgets/club_month_carousel.dart` (`ClubMonthTheme`, same icons copied to `assets/images/clubs/`) — keep both in sync.
- **Routes:** `/pregnancy/week-N`, `/baby/month-N`, `/cycle`, `/fertility`, `/community[/post/<id>]`, `/shop`, `/shop/c/<category>`, `/product/<slug>` (currently rewritten to static `product.html` because Cloud Functions are not deployed — project is not on Blaze. When Blaze is enabled, switch the rewrite to the `productPage` function for Facebook Open Graph previews; it injects meta at `<!--OG-->` and must never redirect to itself), `/cart`, `/checkout`, `/account`, `/login`, `/admin`. Old `/shop/<slug>` 301→`/product/<slug>`.
- **Articles:** `/article/<id>` (`web/article.html`) reads `web/data/articles/<id>.json`; numeric Facebook links (`/article/<originalId>/<slug>`) are mapped via `id_map.json`. `/articles` (listing) uses `index_<cat>.json` + `meta.json`; carousels use `top_<cat>.json`. Medical subcategories (`kMedicalSubcategories`) are excluded from listings/carousels and `noindex`ed. The article `id` (e.g. `art_04079`) is the shareable key — not `originalId`.
- **Markets (countries) — `web/js/market.js`:** each country is a separate market (currency, prices, availability, shipping, dialect); **never auto-convert currency**. Algeria = the original product fields (`price`, `oldPrice`, `stock`, `name`, `description`) + optional `markets.DZ.active`; other markets live in `markets.SA = {price, oldPrice, active, stock?}` (prices as strings, decimals allowed) and optional dialect text `i18n.SA = {name, description}`. A product without a price in a market is invisible there. `getVisibleProducts()` returns products already `localize()`d to the current market, so pages keep reading `p.price`/`p.name`; `formatDA()` formats in the current market's currency. Market choice: `/sa/...` path (rewrites in firebase.json for shop/product/cart/checkout) > saved choice (`nb_market`) > IP country (first visit) > DZ; flag switcher in the header; carts are per market (`nb_cart_v1` / `nb_cart_SA`). Saudi store is closed until `site_config/markets.SA.enabled` (admin «الأسواق والدول»); SA shipping = `site_config/shipping_SA`; SA WhatsApp/banner/policies = `site_config/markets.SA`. Orders carry `country`, `currency`, `phoneIntl` (`wilaya` holds the SA region). The admin console shows one market at a time (top switcher, `S.market`; `S.orders` is filtered, `S.allOrders` has all) so currencies are never summed together; SA stock = `markets.SA.stock`. Static page texts can carry `data-mk-sa="…"` alternatives. Admin «🌍 نسخ / تحويل» (`openConvert` in `mod-products.js`, also row button and bulk «تحويل إلى السعودية») either adds SA pricing to the same product (default — same images/data, two URLs) or creates an independent SA-only copy (`markets.DZ.active=false`, slug `…-sa`, `copiedFrom`); suggested prices use the reference rate `site_config/markets.SA.rateDZD` rounded to end in 9 — suggestions only, never shown to customers. The Flutter app follows the same rules: `CountryCurrencyService` has the market layer (`marketCode`, `marketOpen` from `site_config/markets`, `localize()`, `priceFor()`, `marketShipping()` from `site_config/shipping_SA`); `formatPrice()` **no longer converts** — it formats an already-localized price. Every customer-facing product list uses `isShopHidden()` (shop_config.dart = `isHiddenProduct` + market availability; admin keeps `isHiddenProduct`) and opens/displays `localize()`d maps. Legacy static/dynamic_products catalogs have no `markets` ⇒ Algeria only. Country pickers list only market countries; changing market clears the cart (`CountryCurrencyService.onMarketChanged`). App orders carry `country` + `currency`; SA stock decrements `markets.SA.stock` (allowed by a dedicated rule). The app admin product editor has the 🇸🇦 price fields (dotted `markets.SA.*` keys on update so web-only fields survive).
- **Babies (site ⇄ app, live):** `web/js/pages/baby.js` uses the same path as `DB.babies` in `main.dart` — `couples/{coupleId}/babies` when `users.coupleId` is set, else `users/{uid}/babies` — with `onSnapshot`; doc = `{name, birthDate: Timestamp, gender, weight, height, createdAt, userId}`; the active baby is `selectedBabyId` (+ `babyName`/`babyBirthDate`/`babyGender` mirrored on the user doc). Add/edit/delete exist on both sides (app: «تعديل / حذف» chip, long-press, top-bar edit; delete also removes `babies/{id}/logs`).
- **Fiqh & Qadaa:** `/fiqh` (`web/fiqh.html`) reads `web/data/fiqh/womens_fiqh.json`, exported from `lib/data/womens_fiqh_data.dart` (re-export if the Dart data changes). `/qadaa` (`web/qadaa.html`) edits `users/{uid}/qadaa_days/{year}` = `QadaaYearData.toMap()` (`updatedAt` ISO string, newest wins); deleting writes an empty `missedDays` tombstone (never `delete()`), and `QadaaService` now listens live and treats empty docs as deletions. Twin names: `web/tools/data/twin_names.json` from `lib/data/twin_names_database.dart`, shown in the «أسماء التوائم 👯» tab of `/tools/baby-names.html` (`#twins`).
- **Orders from the site:** one `orders` doc per cart line sharing `cartId`; guest orders satisfy the rule (`userId: null`, `source: 'website'`, `status: 'pending'`, …). Stock for website orders is decremented by the admin console on the first move into confirmed/shipped/delivered and restored on cancel/return (`setStatus` in `mod-orders.js`); app orders decrement their own stock at order time. Only products with a numeric `stock` are touched. Product cost goes to `products_private/{id}` (staff-only), never to `products`.
- **Admin console `/admin`:** `web/admin.html` + `js/admin/app.js` + `mod-*.js`. Access = `staff/{uid}.isActive`; roles `owner|supervisor|employee|agent` (UI perms in `core.js`, real enforcement in `firestore.rules`). Customers are derived from orders by phone — never read `users` (health data). Every admin write calls `log()` → `admin_logs`. Shipping table = `site_config/shipping`, home slides = `site_config/home`, store settings (WhatsApp number, policies, shop banner) = `site_config/settings`; WhatsApp buttons stay hidden until the number is set there. App-parity modules use the **same collections as `admin_panel_screen.dart`**: users (`users_directory` only — ban/role writes go to `users` + `users_directory`, role changes also write/delete `staff/{uid}`), coupons (`coupons`), app ads (`ads`, Storage `ads/`), support (`app_config/contact.whatsappNumber` + `password_reset_requests`), broadcast (`notifications` type `broadcast`, sent by the `sendBroadcast` function; toggles in `app_config/notifications`), reports (`reports`, statuses `pending|action_taken|dismissed`, targetType `community_post|comment|ai_response|direct_chat`). The site header shows «لوحة التحكم» in the account menu only when `staff/{uid}.isActive` (`showStaffLink` in `shell.js`).
- Headless test harness (mock Firebase SDK + local server applying firebase.json rewrites + puppeteer screenshots): `tool/web-harness/` (dev only, paths inside need adjusting).
- Facebook posts are scheduled via Metricool (brand 7528286, page nabda.official); assets in `brand_nabda/facebook_posts/`.
