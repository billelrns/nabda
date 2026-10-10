import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// صفحتا الحمل والطفل الكاملتان مُعرَّفتان في main.dart
import '../../main.dart' show PregnancyPage, BabyPage;

import '../../widgets/nabda_animated_logo.dart' show NabdaBeatingHearts;
import '../../widgets/nabda_ui.dart' show NabdaPulse, kNabdaPink, kNabdaPinkDeep;
import '../../services/app_rating_share_service.dart';
import '../../services/cart_service.dart';
import '../../services/partner_service.dart';
import '../profile/about_screen.dart';
import '../profile/blocked_users_screen.dart';
import '../profile/data_control_screen.dart';
import '../profile/favorites_screen.dart';
import '../profile/support_screen.dart';
import '../shop/shop_page.dart';
import 'partner_home_screen.dart';
import 'partner_notifications_screen.dart';
import 'join_partner_screen.dart';

/// ═══════════════════════════════════════════════════════════════════
///  الهيكل الرئيسي لوضع الأب — بديل MainNav للحسابات ذات role = partner
///  ثلاثة تبويبات فقط: رحلتنا • المتجر • حسابي.
///  (التبويبات النسائية — الدورة والحمل والطفل — لا تظهر له إطلاقاً.)
/// ═══════════════════════════════════════════════════════════════════
class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});

  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

const _blue = Color(0xFF2E6B8F);
const _ink = Color(0xFF1F1A20);
const _ink3 = Color(0xFF9B8F95);
const _bg = Color(0xFFF7FAFC);

class _PartnerShellState extends State<PartnerShell> {
  int _i = 0;
  String? _coupleId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await PartnerService.currentCoupleId();
    if (id != null) {
      // ① أصلح المرآة إن لم يكن تطبيق الزوجة قد كتبها بعد،
      //    وإلا طلبت صفحة الحمل «تحديد آخر دورة» عند الأب.
      await PartnerService.healMirrorFromSnapshot(id);
      // ② السلّة تصبح مشتركة فور الاقتران
      await CartService().enableCoupleSync(id);
    }
    if (!mounted) return;
    setState(() => _coupleId = id);
  }

  @override
  Widget build(BuildContext context) {
    // صفحتا الحمل والطفل هما **نفس** صفحتَي الزوجة بالضبط — بكل
    // المقالات والأدوات ووزن الجنين وطوله. تعملان عند الأب لأن
    // `DB.userDoc` مُحوَّل إلى مرآة الزوجين (انظر DB في main.dart).
    final pages = [
      const PartnerHomeScreen(),
      PregnancyPage(),
      BabyPage(),
      const ShopPage(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _i, children: pages),
        bottomNavigationBar: _bottomNav(),
      ),
    );
  }

  /// نفس شريط الأم بالضبط — أيقونات 3D وشعار القلبين النابض والتدرّج
  /// الوردي للعنصر النشط. الفرق الوحيد أنّ تبويباته أربعة لا خمسة.
  Widget _bottomNav() {
    const navAssets = [
      null, // رحلتنا → شعار القلبين الحي
      'assets/icons_3d/icon_pregnancy.png',
      'assets/icons_3d/icon_nav_baby.png',
      'assets/icons_3d/icon_shop.png',
    ];
    const fallback = [
      Icons.favorite_border,
      Icons.pregnant_woman,
      Icons.child_care_outlined,
      Icons.store_outlined,
    ];
    const fallbackActive = [
      Icons.favorite,
      Icons.pregnant_woman,
      Icons.child_care,
      Icons.store,
    ];
    const labels = ['رحلتنا', 'الحمل', 'الطفل', 'المتجر'];
    const slot = 30.0;

    return Container(
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
        children: List.generate(4, (i) {
          final isActive = _i == i;

          Widget navIcon() {
            if (navAssets[i] == null) {
              return const SizedBox(
                width: slot,
                height: slot,
                child: OverflowBox(
                  maxWidth: 38,
                  maxHeight: 38,
                  child: NabdaBeatingHearts(size: 38),
                ),
              );
            }
            return SizedBox(
              width: slot,
              height: slot,
              child: OverflowBox(
                maxWidth: 42,
                maxHeight: 42,
                child: Image.asset(
                  navAssets[i]!,
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    isActive ? fallbackActive[i] : fallback[i],
                    color: isActive ? Colors.white : const Color(0xFF8E8295),
                    size: 22,
                  ),
                ),
              ),
            );
          }

          return Flexible(
            fit: FlexFit.loose,
            child: GestureDetector(
              onTap: () => setState(() => _i = i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 10 : 5,
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
                            kNabdaPink,
                            kNabdaPinkDeep,
                          ],
                        )
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: kNabdaPinkDeep.withOpacity(0.40),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isActive
                        ? NabdaPulse(child: navIcon())
                        : Opacity(opacity: 0.82, child: navIcon()),
                    if (isActive) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  حساب الأب — الربط، فكّ الارتباط، تسجيل الخروج
// ══════════════════════════════════════════════════════════════
class PartnerAccountScreen extends StatefulWidget {
  const PartnerAccountScreen({super.key});

  @override
  State<PartnerAccountScreen> createState() => _PartnerAccountScreenState();
}

class _PartnerAccountScreenState extends State<PartnerAccountScreen> {
  String? _coupleId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await PartnerService.currentCoupleId();
    if (!mounted) return;
    setState(() {
      _coupleId = id;
      _loading = false;
    });
  }

  Future<void> _unlink() async {
    final id = _coupleId;
    if (id == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('فكّ الارتباط؟',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
              'لن تعود ترى بيانات زوجتك. يمكنك الربط مجدداً بكود جديد.',
              style: TextStyle(height: 1.6)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('تراجع')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE0195B)),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('نعم'),
            ),
          ],
        ),
      ),
    );
    if (yes != true) return;
    await PartnerService.unlink(id);
    if (!mounted) return;
    setState(() => _coupleId = null);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: _ink,
          title: const Text('حسابي',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE6EDF2)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person, color: _blue),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('وضع الأب',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _ink)),
                              const SizedBox(height: 3),
                              Text(email,
                                  style: const TextStyle(
                                      fontSize: 12, color: _ink3)),
                            ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // ── الارتباط ──
                  _sectionTitle('الارتباط'),
                  if (_coupleId == null)
                    _action(Icons.vpn_key_outlined, 'الربط بزوجتك',
                        'أدخل كود الدعوة', _blue, () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => JoinPartnerScreen(onLinked: _load)));
                      _load();
                    })
                  else ...[
                    _action(Icons.notifications_none, 'التنبيهات',
                        'ماذا فعلت زوجتك', _blue, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PartnerNotificationsScreen(
                                  coupleId: _coupleId!)));
                    }),
                    const SizedBox(height: 10),
                    _action(Icons.link_off, 'فكّ الارتباط',
                        'إيقاف متابعة بيانات زوجتك',
                        const Color(0xFFE0195B), _unlink),
                  ],

                  // ── نشاطي ──
                  _sectionTitle('نشاطي'),
                  _action(Icons.bookmark_outline, 'المفضلة',
                      'المقالات التي حفظتها', const Color(0xFFD98324), () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                  }),
                  const SizedBox(height: 10),
                  _action(Icons.block, 'الحسابات المحظورة', '',
                      const Color(0xFFE53935), () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BlockedUsersScreen()));
                  }),

                  // ── أخرى ──
                  _sectionTitle('أخرى'),
                  _action(Icons.support_agent, 'الدعم والمساعدة', '',
                      const Color(0xFF00897B), () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SupportScreen()));
                  }),
                  const SizedBox(height: 10),
                  _action(Icons.star_outline, 'قيّم التطبيق',
                      'رأيك يساعدنا على التحسّن', const Color(0xFFFFA726),
                      () => AppRatingShareService.rateApp()),
                  const SizedBox(height: 10),
                  _action(Icons.share_outlined, 'شارك نبضة', '',
                      const Color(0xFF2E6B8F),
                      () => AppRatingShareService.shareApp()),
                  const SizedBox(height: 10),
                  _action(Icons.shield_outlined, 'الخصوصية والبيانات', '',
                      const Color(0xFF7E57C2), () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DataControlScreen()));
                  }),
                  const SizedBox(height: 10),
                  _action(Icons.info_outline, 'عن نبضة', '', _ink3, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()));
                  }),
                  const SizedBox(height: 10),
                  _action(Icons.logout, 'تسجيل الخروج', '', _ink3, () async {
                    await PartnerService.clearLocal();
                    await CartService().disableCoupleSync();
                    await FirebaseAuth.instance.signOut();
                  }),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(children: const [
                      Icon(Icons.shield_outlined, size: 19, color: _blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'أنت ترى فقط ما اختارت زوجتك مشاركته. بياناتها الخاصّة محميّة تماماً.',
                          style: TextStyle(
                              fontSize: 12, height: 1.6, color: _ink),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Row(children: [
          Container(
              width: 3,
              height: 15,
              decoration: BoxDecoration(
                  color: _blue, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(t,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
        ]),
      );

  Widget _action(IconData icon, String title, String sub, Color c,
          VoidCallback onTap) =>
      InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EDF2)),
          ),
          child: Row(children: [
            Icon(icon, color: c, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: c)),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(sub,
                          style:
                              const TextStyle(fontSize: 11.5, color: _ink3)),
                    ],
                  ]),
            ),
            const Icon(Icons.arrow_back_ios, size: 14, color: _ink3),
          ]),
        ),
      );
}

/// يُستدعى من تطبيق الزوجة عند الإقلاع: يدفع اللقطة المشتركة،
/// يُرحّل سجلّ الطفل لملكية الزوجين، ويُفعّل السلّة المشتركة.
/// آمن تماماً إن لم يكن هناك اقتران (يخرج فوراً).
Future<void> syncPartnerSnapshotIfLinked() async {
  try {
    final id = await PartnerService.currentCoupleId();
    if (id == null) return;
    // تأكّد أن الاقتران ما زال قائماً قبل الكتابة
    final snap =
        await FirebaseFirestore.instance.collection('couples').doc(id).get();
    if (!snap.exists) {
      await PartnerService.unlink(id);
      await CartService().disableCoupleSync();
      return;
    }
    await PartnerService.syncAll();
    await CartService().enableCoupleSync(id);
  } catch (_) {/* أفضل-جهد */}
}
