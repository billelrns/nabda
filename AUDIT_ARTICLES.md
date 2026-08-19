# AUDIT_ARTICLES.md - Article Page Audit

This audit lists all screen components in the Nabda app that display article content. 

| الملف | السطر | اسم الكلاس | مصدر المحتوى | صورة الرأس | عدد مواضع الإعلان | زر إعجاب | زر مشاركة |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| [`lib/main.dart`](file:///C:/nabda_app/lib/main.dart) | 6833 | `_ArticleDetailPage` | `widget.body` / overrides | `ArticleImage` | 3 | ❌ لا يوجد | ❌ لا يوجد |
| [`lib/widgets/names_articles_carousel.dart`](file:///C:/nabda_app/lib/widgets/names_articles_carousel.dart) | 326 | `NameArticleDetailScreen` | `article.body` | `ArticleImage` | 0 | ❌ لا يوجد | ❌ لا يوجد |
| [`lib/screens/baby_names/baby_names_screen.dart`](file:///C:/nabda_app/lib/screens/baby_names/baby_names_screen.dart) | 1062 | `BabyNameArticleDetailScreen` | `article.body` | لا يوجد (أيقونة فقط) | 0 | ❌ لا يوجد | ❌ لا يوجد |
| [`lib/screens/pregnancy/pregnancy_weeks_screen.dart`](file:///C:/nabda_app/lib/screens/pregnancy/pregnancy_weeks_screen.dart) | 2907 | `_DiscoverDetailScreen` | `article.content` | `ArticleImage` | 1 | ❌ لا يوجد | ❌ لا يوجد |
| [`lib/screens/pregnancy/pregnancy_weeks_screen.dart`](file:///C:/nabda_app/lib/screens/pregnancy/pregnancy_weeks_screen.dart) | 2209 | `_ArticleDetailScreen` | `article.content` | لا يوجد (إيموجي دائري) | 1 | ❌ لا يوجد | ❌ لا يوجد |
| [`lib/screens/pregnancy/discover_articles_screen.dart`](file:///C:/nabda_app/lib/screens/pregnancy/discover_articles_screen.dart) | 779 | `_DiscoverArticleDetailScreen` | `article.content` | `Image.network` | 1 | ❌ لا يوجد | ❌ لا يوجد |
| [`lib/screens/pregnancy/pregnancy_weeks_screen.dart`](file:///C:/nabda_app/lib/screens/pregnancy/pregnancy_weeks_screen.dart) | 502 | `WeekDetailScreen` | `PregnancyWeekArticle` | `WombFloatingFetus` | 0 | ❌ لا يوجد | ❌ لا يوجد |
| [`lib/screens/pregnancy/end_pregnancy_screen.dart`](file:///C:/nabda_app/lib/screens/pregnancy/end_pregnancy_screen.dart) | 362 | `_LossSupportArticleScreen` | مصفوفة نصوص ثابتة | لا يوجد | 0 | ❌ لا يوجد | ❌ لا يوجد |
| [`lib/widgets/news_section.dart`](file:///C:/nabda_app/lib/widgets/news_section.dart) | 358 | `_NewsDetailPage` | `_body` / overrides | `Image.network` | 3 | ❌ لا يوجد | ❌ لا يوجد |
| [`lib/widgets/conditional_content.dart`](file:///C:/nabda_app/lib/widgets/conditional_content.dart) | 369 | `_ArticlePage` | `body` | `ArticleImage` | 3 | ❌ لا يوجد | ❌ لا يوجد |
