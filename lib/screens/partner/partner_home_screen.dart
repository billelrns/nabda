import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/partner_service.dart';
import '../../utils/fetus_size.dart';
import '../../widgets/nabda_ui.dart';
import '../shop/shop_page.dart';
import 'join_partner_screen.dart';
import 'partner_tips.dart';
import 'partner_notifications_screen.dart';
import 'partner_read_screen.dart';
import 'partner_shell.dart' show PartnerAccountScreen;
import 'shared_baby_care_screen.dart';
import 'shared_lists_screen.dart';
import 'name_match_screen.dart';

/// ═══════════════════════════════════════════════════════════════════
///  الواجهة الرئيسية للأب
///  يقرأ **فقط** اللقطة المنقّاة من couples/{id}/shared/*
///  ولا يصل إطلاقاً إلى وثيقة الزوجة أو بيانات الدورة.
/// ═══════════════════════════════════════════════════════════════════
class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

const _blue = Color(0xFF2E6B8F);
const _deepBlue = Color(0xFF1E4A66);
const _teal = Color(0xFF00897B);
const _amber = Color(0xFFD98324);
const _ink = Color(0xFF1F1A20);
const _ink3 = Color(0xFF9B8F95);
const _bg = Color(0xFFF7FAFC);

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _coupleId == null
                  ? _buildNotLinked()
                  : _buildLinked(_coupleId!),
        ),
      ),
    );
  }

  // ── غير مرتبط بعد ────────────────────────────────────────────
  Widget _buildNotLinked() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔗', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 18),
            const Text('لم تربط حسابك بعد',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
            const SizedBox(height: 10),
            const Text(
              'اطلب من زوجتك كود الربط من تطبيقها،\nثم أدخله هنا لتبدأ المتابعة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.8, color: _ink3),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => JoinPartnerScreen(onLinked: _load)),
                );
                _load();
              },
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('أدخل كود الربط',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      );

  // ── مرتبط ────────────────────────────────────────────────────
  Widget _buildLinked(String coupleId) => StreamBuilder<SharedPregnancy?>(
        stream: PartnerService.watchPregnancy(coupleId),
        builder: (context, pregSnap) {
          return StreamBuilder<SharedBaby?>(
            stream: PartnerService.watchBaby(coupleId),
            builder: (context, babySnap) {
              final preg = pregSnap.data;
              final baby = babySnap.data;
              final hasBaby = baby?.birthDate != null;

              return RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  children: [
                    _greeting(),
                    const SizedBox(height: 18),
                    if (hasBaby)
                      _babyCard(baby!)
                    else if (preg != null && preg.week > 0)
                      _pregnancyCard(preg)
                    else
                      _waitingData(),
                    const SizedBox(height: 16),
                    if (!hasBaby && preg != null && preg.week > 0)
                      _tipCard(preg.week),
                    if (hasBaby) _babyChart(baby!),
                    const SizedBox(height: 16),
                    _actionsGrid(coupleId),
                    const SizedBox(height: 16),
                    _storeCta(),
                    const SizedBox(height: 22),
                    // قسم «اقرأ وتعلّم» مدمجاً هنا بدل تبويب مستقل
                    PartnerLearnSection(coupleId: coupleId),
                  ],
                ),
              );
            },
          );
        },
      );

  Widget _greeting() => Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, color: _blue),
        ),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('أهلاً بك',
              style: TextStyle(fontSize: 12.5, color: _ink3)),
          SizedBox(height: 2),
          Text('رحلتكما معاً',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: _ink)),
        ]),
        const Spacer(),
        if (_coupleId != null) _bell(_coupleId!),
        // أيقونة الحساب دائرية في الأعلى — كما في حساب الأم
        const SizedBox(width: 2),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PartnerAccountScreen())),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: _blue.withOpacity(0.30), width: 2),
            ),
            child: const Icon(Icons.person, size: 21, color: _blue),
          ),
        ),
      ]);

  /// جرس التنبيهات مع شارة عدد أحداث الطرف الآخر غير المقروءة
  Widget _bell(String coupleId) => StreamBuilder<List<PartnerNotification>>(
        stream: PartnerService.watchNotifications(coupleId),
        builder: (context, snap) {
          final me = FirebaseAuth.instance.currentUser?.uid;
          final unread = (snap.data ?? [])
              .where((n) => !n.readBy.contains(me))
              .length;
          return Stack(clipBehavior: Clip.none, children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: _ink),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        PartnerNotificationsScreen(coupleId: coupleId)),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 17),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0195B),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _bg, width: 1.5),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
              ),
          ]);
        },
      );

  // ── بطاقة الحمل ──────────────────────────────────────────────
  Widget _pregnancyCard(SharedPregnancy p) {
    final week = p.week.clamp(1, 42);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_blue, _deepBlue],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: _deepBlue.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ClipOval(
            child: SizedBox(
              width: 104,
              height: 104,
              child: WombFloatingFetus(
                fetusAsset:
                    'assets/images/fetus_hd/week_${week.clamp(4, 41)}.png',
                size: 104,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الأسبوع $week',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('بحجم ${FetusSize.labeled(week)}',
                      style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withOpacity(0.92))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      p.daysLeft > 0
                          ? 'باقي ${p.daysLeft} يوماً'
                          : 'الموعد قد حلّ 🎉',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ]),
          ),
        ]),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: p.progress,
            minHeight: 7,
            backgroundColor: Colors.white.withOpacity(0.22),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('الثلث ${_trimesterAr(p.trimester)}',
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withOpacity(0.85))),
          Text('${(p.progress * 100).round()}%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.95))),
        ]),
      ]),
    );
  }

  static String _trimesterAr(int t) =>
      t == 1 ? 'الأول' : (t == 2 ? 'الثاني' : 'الثالث');

  // ── بطاقة الطفل ──────────────────────────────────────────────
  Widget _babyCard(SharedBaby b) {
    final days = b.ageInDays;
    final months = (days / 30.44).floor();
    final ageText = days < 31
        ? '$days يوماً'
        : (months < 24 ? '$months شهراً' : '${(months / 12).floor()} سنوات');
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_teal, _teal.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
              child: Text('👶', style: TextStyle(fontSize: 30))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                b.babyName.trim().isEmpty ? 'طفلكما' : b.babyName.trim(),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('عمره $ageText',
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withOpacity(0.92))),
          ]),
        ),
      ]),
    );
  }

  Widget _waitingData() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE6EDF2)),
        ),
        child: Column(children: const [
          Icon(Icons.hourglass_empty, size: 34, color: _ink3),
          SizedBox(height: 12),
          Text('بانتظار بيانات زوجتك',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
          SizedBox(height: 8),
          Text(
            'ستظهر هنا فور أن تُدخل تاريخ الولادة المتوقّع في تطبيقها.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, height: 1.7, color: _ink3),
          ),
        ]),
      );

  // ── نصيحة الأسبوع ────────────────────────────────────────────
  Widget _tipCard(int week) {
    final tip = PartnerTips.forWeek(week);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: _amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _amber.withOpacity(0.22)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.lightbulb_outline, size: 19, color: _amber),
          SizedBox(width: 8),
          Text('كيف تسندها هذا الأسبوع',
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
        ]),
        const SizedBox(height: 10),
        Text(tip,
            style: const TextStyle(fontSize: 13, height: 1.9, color: _ink)),
      ]),
    );
  }

  // ── مخطّط نشاط الطفل (من اللقطة، لا من Firestore مباشرة) ─────
  Widget _babyChart(SharedBaby b) {
    final today = DateTime.now();
    final keys = List.generate(7, (i) {
      final d = DateTime(today.year, today.month, today.day - (6 - i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
    final feeding = keys.map((k) => b.last7[k]?['feeding'] ?? 0).toList();
    final maxV = feeding.isEmpty ? 0 : feeding.reduce((a, c) => a > c ? a : c);
    const names = ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EDF2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Text('🍼', style: TextStyle(fontSize: 15)),
          SizedBox(width: 6),
          Text('الرضعات — آخر 7 أيام',
              style: TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 104,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final v = feeding[i];
              final h = maxV == 0 ? 0.0 : (v / maxV) * 62.0;
              final isToday = i == 6;
              final d = DateTime(today.year, today.month, today.day - (6 - i));
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(v == 0 ? '' : '$v',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isToday ? _teal : _ink3)),
                    const SizedBox(height: 3),
                    Container(
                      height: h < 4 && v > 0 ? 4 : h,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: _teal.withOpacity(isToday ? 1 : 0.28),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(names[d.weekday - 1],
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isToday ? _ink : _ink3)),
                  ],
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }

  // ── الإجراءات ────────────────────────────────────────────────
  Widget _actionsGrid(String coupleId) => Column(children: [
        Row(children: [
          Expanded(
            child: _actionTile(
              '🎒',
              'القوائم المشتركة',
              'حقيبة الولادة والتحضير',
              _blue,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SharedListsScreen(coupleId: coupleId))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionTile(
              '💗',
              'اختيار الاسم',
              'وافِقا على اسم واحد',
              const Color(0xFFE0195B),
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => NameMatchScreen(
                          coupleId: coupleId, isMother: false))),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _actionTile(
              '👶',
              'العناية بالطفل',
              'سجّل أنت أيضاً — يظهر عندها فوراً',
              const Color(0xFF9B6FE1),
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SharedBabyCareScreen(
                          coupleId: coupleId, isMother: false))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionTile(
              '🔔',
              'التنبيهات',
              'ماذا فعلت زوجتك اليوم',
              _teal,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          PartnerNotificationsScreen(coupleId: coupleId))),
            ),
          ),
        ]),
      ]);

  Widget _actionTile(String emoji, String title, String sub, Color c,
          VoidCallback onTap) =>
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6EDF2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 3),
            Text(sub,
                style: const TextStyle(
                    fontSize: 11, color: _ink3, height: 1.4)),
          ]),
        ),
      );

  // ── بوابة المتجر ─────────────────────────────────────────────
  Widget _storeCta() => InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ShopPage())),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [_amber, _amber.withOpacity(0.82)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(children: [
            const Text('🛍️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('جهّز ما ينقصكما',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('توصيل لكل الولايات والدفع عند الاستلام',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.93))),
                  ]),
            ),
            const Icon(Icons.arrow_back_ios, size: 15, color: Colors.white),
          ]),
        ),
      );
}
