import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/partner_service.dart';
import 'shared_lists_screen.dart';
import 'name_match_screen.dart';
import 'shared_baby_care_screen.dart';
import 'partner_notifications_screen.dart';

/// ═══════════════════════════════════════════════════════════════════
///  شاشة الزوجة — «أشركي زوجكِ في الرحلة»
///  تولّد كود اقتران، تشاركه عبر واتساب، وتُظهر حالة الربط،
///  مع إمكانية إلغاء المشاركة في أي لحظة.
/// ═══════════════════════════════════════════════════════════════════
class InvitePartnerScreen extends StatefulWidget {
  const InvitePartnerScreen({super.key});

  @override
  State<InvitePartnerScreen> createState() => _InvitePartnerScreenState();
}

const _pink = Color(0xFFE0195B);
const _deepPink = Color(0xFFC2185B);
const _teal = Color(0xFF00897B);
const _ink = Color(0xFF1F1A20);
const _ink3 = Color(0xFF9B8F95);
const _bg = Color(0xFFFFF8FB);

class _InvitePartnerScreenState extends State<InvitePartnerScreen> {
  String? _coupleId;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = await PartnerService.currentCoupleId();
    if (!mounted) return;
    setState(() {
      _coupleId = id;
      _loading = false;
    });
  }

  Future<String> _motherName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'زوجتك';
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final d = snap.data() ?? {};
      final n = (d['name'] ?? d['displayName'] ?? user.displayName ?? '') as String;
      return n.trim().isEmpty ? 'زوجتك' : n.trim();
    } catch (_) {
      return user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'زوجتك';
    }
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    final res = await PartnerService.createInvite(motherName: await _motherName());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _coupleId = res.code;
    });
    if (res.code == null) {
      _snack(res.error ?? 'تعذّر إنشاء الكود');
    }
  }

  Future<void> _confirmUnlink() async {
    final id = _coupleId;
    if (id == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إلغاء المشاركة؟',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            'لن يعود زوجك يرى أسبوع الحمل ولا سجلّ الطفل. '
            'يمكنكِ دعوته مجدداً بكود جديد في أي وقت.',
            style: TextStyle(height: 1.6),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('تراجع')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _pink),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('نعم، ألغِ'),
            ),
          ],
        ),
      ),
    );
    if (yes != true) return;
    setState(() => _busy = true);
    await PartnerService.unlink(id);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _coupleId = null;
    });
    _snack('تم إلغاء المشاركة');
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          foregroundColor: _ink,
          title: const Text('أشركي زوجكِ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _coupleId == null
                ? _buildIntro()
                : StreamBuilder<CoupleLink?>(
                    stream: PartnerService.watchCouple(_coupleId!),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      final link = snap.data;
                      if (link == null) return _buildIntro();
                      if (link.isLinked) return _buildLinked(link);
                      return _buildWaiting(link);
                    },
                  ),
      ),
    );
  }

  // ── قبل إنشاء الكود ──────────────────────────────────────────
  Widget _buildIntro() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(),
            const SizedBox(height: 22),
            const Text('ماذا سيرى زوجك؟',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 12),
            _perm(Icons.pregnant_woman, 'أسبوع الحمل وحجم الجنين',
                'نفس الدائرة التي ترينها، مع الأيام المتبقّية للولادة', true),
            _perm(Icons.child_care, 'سجلّ الطفل بعد الولادة',
                'الرضعات والنوم والحفاضات — ويمكنه هو أيضاً تسجيلها', true),
            _perm(Icons.checklist_rtl, 'القوائم المشتركة',
                'حقيبة الولادة وتحضير الطفل واختيار الاسم', true),
            const SizedBox(height: 6),
            _perm(Icons.lock_outline, 'دورتك الشهرية ومزاجك وأعراضك',
                'خاصّة بكِ وحدك — لا يصل إليها إطلاقاً', false),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _pink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _busy ? null : _generate,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.favorite),
                label: Text(_busy ? 'جارٍ التحضير…' : 'أنشئي كود الدعوة',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'يمكنكِ إلغاء المشاركة في أي وقت بضغطة واحدة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _ink3),
            ),
          ],
        ),
      );

  Widget _hero() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [_pink, _deepPink],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: _pink.withOpacity(0.28),
                blurRadius: 22,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(children: [
          const Text('💑', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 10),
          const Text('الرحلة أجمل باثنين',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'ادعي زوجك ليتابع أسبوع الحمل ونموّ طفلكما من هاتفه،\nويعرف كيف يسندكِ في كل مرحلة.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: Colors.white.withOpacity(0.92)),
          ),
        ]),
      );

  Widget _perm(IconData icon, String title, String sub, bool allowed) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (allowed ? _teal : _ink3).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: allowed ? _teal : _ink3),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: allowed ? _ink : _ink3)),
                ),
                const SizedBox(width: 6),
                Icon(allowed ? Icons.check_circle : Icons.cancel,
                    size: 15, color: allowed ? _teal : _ink3),
              ]),
              const SizedBox(height: 2),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 11.5, color: _ink3, height: 1.5)),
            ]),
          ),
        ]),
      );

  // ── بانتظار قبول الزوج ───────────────────────────────────────
  Widget _buildWaiting(CoupleLink link) {
    final code = link.id;
    final expired = link.isExpired;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _pink.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(children: [
            Text(expired ? 'انتهت صلاحية الكود' : 'كود الدعوة',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: expired ? _pink : _ink3)),
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                code.split('').join(' '),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: expired ? _ink3 : _deepPink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!expired) ...[
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _deepPink,
                    side: BorderSide(color: _pink.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    _snack('نُسخ الكود');
                  },
                  icon: const Icon(Icons.copy, size: 17),
                  label: const Text('نسخ'),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Share.share(
                    'حبيبي، نزّل تطبيق نبضة وتابع معي حملنا أسبوعاً بأسبوع 💗\n\n'
                    'كود الربط: $code\n\n'
                    'https://nabda.online',
                  ),
                  icon: const Icon(Icons.share, size: 17),
                  label: const Text('أرسلي لزوجك'),
                ),
              ]),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('بانتظار أن يُدخل زوجك الكود…',
                    style: TextStyle(fontSize: 12.5, color: _ink3)),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('كيف يستعمله زوجك؟',
                style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink)),
            SizedBox(height: 10),
            Text(
              '١. يُنزّل تطبيق نبضة على هاتفه\n'
              '٢. يختار «أنا أب» عند إنشاء الحساب\n'
              '٣. يُدخل هذا الكود — وتظهر له رحلتكما فوراً',
              style: TextStyle(fontSize: 12.5, height: 2, color: _ink),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: _busy ? null : (link.isExpired ? _generate : _confirmUnlink),
          icon: Icon(link.isExpired ? Icons.refresh : Icons.link_off,
              size: 18, color: _pink),
          label: Text(link.isExpired ? 'أنشئي كوداً جديداً' : 'إلغاء الدعوة',
              style: const TextStyle(color: _pink, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  // ── مرتبطان ──────────────────────────────────────────────────
  Widget _buildLinked(CoupleLink link) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [_teal, _teal.withOpacity(0.78)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(children: [
              const Icon(Icons.verified_rounded, color: Colors.white, size: 44),
              const SizedBox(height: 12),
              const Text('مرتبطان 💗',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                '${link.partnerName?.trim().isNotEmpty == true ? link.partnerName : "زوجك"} '
                'يتابع رحلتكما الآن من هاتفه.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.white.withOpacity(0.93)),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: _linkedAction(
                '🎒',
                'قوائمنا',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SharedListsScreen(coupleId: link.id))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _linkedAction(
                '💗',
                'اسم طفلنا',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => NameMatchScreen(
                            coupleId: link.id, isMother: true))),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _linkedAction(
                '👶',
                'العناية بالطفل',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SharedBabyCareScreen(
                            coupleId: link.id, isMother: true))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _linkedAction(
                '🔔',
                'تنبيهاتنا',
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PartnerNotificationsScreen(coupleId: link.id))),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF0EBEE)),
            ),
            child: Row(children: const [
              Icon(Icons.lock_outline, size: 19, color: _teal),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'دورتك الشهرية وأعراضك ومزاجك لا تُشارَك معه إطلاقاً.',
                  style: TextStyle(fontSize: 12.5, height: 1.6, color: _ink),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          // ⚠️ أطفالكِ وتواريخ حملكِ لا يمكن لتطبيق زوجك قراءتها بنفسه
          //    (القواعد تمنعه من وثيقتكِ)، فهذا الزرّ هو ما يدفعها إليه.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: BorderSide(color: _teal.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await PartnerService.syncAll();
                      if (!mounted) return;
                      setState(() => _busy = false);
                      _snack('تمت مزامنة بياناتكِ مع زوجك');
                    },
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync, size: 18),
              label: const Text('مزامنة بياناتي الآن',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'يدفع أطفالكِ وتواريخ حملكِ إلى تطبيق زوجك.\nيحدث تلقائياً عند كل فتح للتطبيق أيضاً.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: _ink3, height: 1.6),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _busy ? null : _confirmUnlink,
            icon: const Icon(Icons.link_off, size: 18, color: _pink),
            label: const Text('إلغاء المشاركة',
                style: TextStyle(color: _pink, fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _linkedAction(String emoji, String title, VoidCallback onTap) =>
      InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0EBEE)),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          ]),
        ),
      );
}
