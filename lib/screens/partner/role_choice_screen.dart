import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/partner_service.dart';

/// ═══════════════════════════════════════════════════════════════════
///  اختيار الدور عند أول دخول — أم/حامل أم أب/زوج
///  يُعرض فقط للحسابات التي لم يُحدَّد دورها بعد، فلا يتأثّر المستخدمون
///  الحاليون (الذين أكملوا onboarding قبل إضافة وضع الأب).
/// ═══════════════════════════════════════════════════════════════════
class RoleChoiceScreen extends StatefulWidget {
  final VoidCallback? onChosen;
  const RoleChoiceScreen({super.key, this.onChosen});

  @override
  State<RoleChoiceScreen> createState() => _RoleChoiceScreenState();
}

const _pink = Color(0xFFE0195B);
const _blue = Color(0xFF2E6B8F);
const _ink = Color(0xFF1F1A20);
const _ink3 = Color(0xFF9B8F95);

class _RoleChoiceScreenState extends State<RoleChoiceScreen> {
  bool _busy = false;

  Future<void> _choose(String role) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    await PartnerService.setLocalRole(role);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': role,
        // الأب لا يمرّ بأسئلة onboarding النسائية
        if (role == PartnerService.rolePartner) 'onboardingDone': true,
      }, SetOptions(merge: true));
    } catch (_) {/* الدور محفوظ محلياً على الأقل */}
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onChosen?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8FB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
            child: Column(children: [
              const Spacer(flex: 2),
              const Text('💗', style: TextStyle(fontSize: 46)),
              const SizedBox(height: 18),
              const Text('مرحباً بك في نبضة',
                  style: TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w900, color: _ink)),
              const SizedBox(height: 10),
              const Text('من أنت؟ لنُظهر لك ما يناسبك.',
                  style: TextStyle(fontSize: 14, color: _ink3)),
              const Spacer(),
              _card(
                emoji: '🤰',
                title: 'أنا امرأة',
                sub: 'تتبّع الدورة، الحمل، ورعاية الطفل',
                color: _pink,
                onTap: _busy ? null : () => _choose(PartnerService.roleMother),
              ),
              const SizedBox(height: 14),
              _card(
                emoji: '👨',
                title: 'أنا أب / زوج',
                sub: 'تابع حمل زوجتك ونموّ طفلكما',
                color: _blue,
                onTap: _busy ? null : () => _choose(PartnerService.rolePartner),
              ),
              const Spacer(flex: 2),
              if (_busy) const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 10),
              const Text('يمكنك تغيير هذا لاحقاً من الإعدادات.',
                  style: TextStyle(fontSize: 11.5, color: _ink3)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required String emoji,
    required String title,
    required String sub,
    required Color color,
    VoidCallback? onTap,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.28), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(sub,
                        style: const TextStyle(
                            fontSize: 12.5, color: _ink3, height: 1.5)),
                  ]),
            ),
            Icon(Icons.arrow_back_ios, size: 15, color: color),
          ]),
        ),
      );
}
