import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feature_tour.dart';

/// ═══════════════════════════════════════════════════════════════════
///  الجولة التعريفية لنبضة — مفاتيح العناصر + الخطوات + التشغيل
///
///  المفاتيح تُعلَّق على العناصر الحقيقية في main.dart:
///    profile → زرّ الحساب الدائري العائم (MainNav._buildContent)
///    search / bell → شريط الصفحة الرئيسية (HomePage)
///    tabs[0..4] → عناصر الشريط السفلي (MainNav._buildBottomNav)
///
///  ⚠️ GlobalKey لا يُستعمل إلا مرّة واحدة في الشجرة. هذه العناصر تُبنى
///     مرّة واحدة في التخطيط الضيّق (الهاتف)؛ على سطح المكتب لا يوجد شريط
///     سفلي فتتخطّى الجولة خطواته تلقائياً.
/// ═══════════════════════════════════════════════════════════════════
class TourKeys {
  TourKeys._();
  static final profile = GlobalKey(debugLabel: 'tour_profile');
  static final search = GlobalKey(debugLabel: 'tour_search');
  static final bell = GlobalKey(debugLabel: 'tour_bell');
  static final tabs = List.generate(5, (i) => GlobalKey(debugLabel: 'tour_tab_$i'));
}

class AppTour {
  AppTour._();

  /// غيّر الرقم لإعادة عرض الجولة على الجميع بعد تغيير كبير في الواجهة
  static const String doneKey = 'feature_tour_v1_done';

  /// طلب إعادة الجولة من صفحة الحساب — MainNav يستمع إليه
  static final ValueNotifier<int> replayRequests = ValueNotifier(0);

  static void requestReplay() => replayRequests.value++;

  static Future<bool> isDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(doneKey) ?? false;
  }

  static Future<void> markDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(doneKey, true);
  }

  /// خطوات جولة الأم / المرأة
  static List<TourStep> motherSteps() => [
        const TourStep(
          emoji: '💗',
          title: 'أهلاً بكِ في نبضة',
          body: 'جولة سريعة (نصف دقيقة) لتعرفي أين تجدين كل شيء.\n'
              'يمكنكِ تخطّيها الآن وإعادتها لاحقاً من حسابكِ.',
        ),
        TourStep(
          target: TourKeys.profile,
          circle: true,
          padding: 6,
          emoji: '👤',
          title: 'حسابكِ',
          body: 'صورتكِ وإعداداتكِ: المقالات المحفوظة، الخصوصية، الدعم، '
              'و«أشركي زوجكِ» ليتابع الرحلة معكِ من هاتفه.',
        ),
        TourStep(
          target: TourKeys.search,
          circle: true,
          padding: 6,
          emoji: '🔍',
          title: 'البحث',
          body: 'ابحثي في آلاف المقالات والأدوات الذكية بكلمة واحدة.',
        ),
        TourStep(
          target: TourKeys.bell,
          circle: true,
          padding: 6,
          emoji: '🔔',
          title: 'التذكيرات',
          body: 'مواعيدكِ وتذكيرات شرب الماء والنصائح اليومية في مكان واحد.',
        ),
        TourStep(
          target: TourKeys.tabs[0],
          emoji: '🏠',
          title: 'الرئيسية',
          body: 'ملخّص يومكِ: مرحلتكِ الحالية، مقالات مختارة لكِ، وآخر الأخبار.',
        ),
        TourStep(
          target: TourKeys.tabs[1],
          emoji: '📅',
          title: 'الدورة',
          body: 'سجّلي دورتكِ واعرفي موعدها القادم وأيام الخصوبة المتوقّعة.',
        ),
        TourStep(
          target: TourKeys.tabs[2],
          emoji: '🤰',
          title: 'رحلة الحمل',
          body: 'أسبوعاً بأسبوع: حجم الجنين ووزنه وطوله، تاريخ الولادة المتوقّع، '
              'ومقالات كل أسبوع.',
        ),
        TourStep(
          target: TourKeys.tabs[3],
          emoji: '👶',
          title: 'الطفل',
          body: 'الرضعات والنوم والحفاضات، ومخطّط آخر 7 أيام، '
              'و«دفتر الذكريات» لأول سنّ وأول خطوة ✨',
        ),
        TourStep(
          target: TourKeys.tabs[4],
          emoji: '🛍️',
          title: 'المتجر',
          body: 'مستلزمات الأم والطفل — توصيل لكل الولايات والدفع عند الاستلام.',
        ),
        const TourStep(
          emoji: '🎉',
          title: 'أنتِ جاهزة!',
          body: 'لإعادة هذه الجولة: حسابكِ ← «الجولة التعريفية».\n'
              'نتمنّى لكِ رحلة جميلة مع نبضة 💗',
        ),
      ];

  /// يشغّل جولة الأم. [goToTab] / [currentTab] لفتح الرئيسية أثناء الجولة
  /// (البحث والتذكيرات في شريطها) ثم العودة إلى تبويب المستخدمة الأصلي.
  static Future<void> runMother(
    BuildContext context, {
    required void Function(int) goToTab,
    required int currentTab,
  }) async {
    if (FeatureTour.isRunning) return;
    final original = currentTab;
    if (original != 0) {
      goToTab(0);
      // إطاران: بناء الرئيسية (التبويبات تُبنى عند أول زيارة) ثم تخطيطها
      await Future.delayed(const Duration(milliseconds: 350));
    }
    if (!context.mounted) return;
    await FeatureTour.show(
      context,
      motherSteps(),
      onFinish: (_) => markDone(), // تخطّي أو إكمال: لا تُعرض تلقائياً مرّة أخرى
    );
    if (original != 0) goToTab(original);
  }
}
