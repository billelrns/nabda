import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/partner_service.dart';

/// ═══════════════════════════════════════════════════════════════════
///  شاشة الزوج — إدخال كود الاقتران
///  تتحقّق من الكود أولاً وتعرض اسم الزوجة للتأكيد قبل الربط.
/// ═══════════════════════════════════════════════════════════════════
class JoinPartnerScreen extends StatefulWidget {
  /// تُستدعى بعد نجاح الربط (عادةً لإعادة بناء التوجيه في main)
  final VoidCallback? onLinked;
  const JoinPartnerScreen({super.key, this.onLinked});

  @override
  State<JoinPartnerScreen> createState() => _JoinPartnerScreenState();
}

const _blue = Color(0xFF2E6B8F);
const _deepBlue = Color(0xFF1E4A66);
const _pink = Color(0xFFE0195B);
const _ink = Color(0xFF1F1A20);
const _ink3 = Color(0xFF9B8F95);
const _bg = Color(0xFFF7FAFC);

class _JoinPartnerScreenState extends State<JoinPartnerScreen> {
  final _c = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _foundName;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<String> _partnerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'زوجك';
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final d = snap.data() ?? {};
      final n = (d['name'] ?? d['displayName'] ?? user.displayName ?? '') as String;
      return n.trim().isEmpty ? 'زوجك' : n.trim();
    } catch (_) {
      return 'زوجك';
    }
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _foundName = null;
    });
    final res = await PartnerService.previewInvite(_c.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (res.ok) {
        _foundName = res.motherName ?? 'زوجتك';
      } else {
        _error = res.message;
      }
    });
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final res =
        await PartnerService.acceptInvite(_c.text, partnerName: await _partnerName());
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      widget.onLinked?.call();
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = res.message;
        _foundName = null;
      });
    }
  }

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
          title: const Text('الربط بزوجتك',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [_blue, _deepBlue],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(children: [
                const Text('👨‍👩‍👦', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 10),
                const Text('كن معها خطوة بخطوة',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  'اطلب من زوجتك كود الربط من تطبيقها،\nوستتابع الحمل ونموّ طفلكما من هاتفك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.7,
                      color: Colors.white.withOpacity(0.9)),
                ),
              ]),
            ),
            const SizedBox(height: 26),
            const Text('أدخل كود الربط (6 خانات)',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _c,
                textAlign: TextAlign.center,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: _deepBlue),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  TextInputFormatter.withFunction((o, n) =>
                      n.copyWith(text: n.text.toUpperCase())),
                ],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'ABC123',
                  hintStyle: TextStyle(
                      color: _ink3.withOpacity(0.4), letterSpacing: 8),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _ink3.withOpacity(0.25)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: _ink3.withOpacity(0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _blue, width: 2),
                  ),
                ),
                onChanged: (_) {
                  if (_error != null || _foundName != null) {
                    setState(() {
                      _error = null;
                      _foundName = null;
                    });
                  }
                },
                onSubmitted: (_) => _verify(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.error_outline, size: 17, color: _pink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: _pink,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
            if (_foundName != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFF00897B).withOpacity(0.25)),
                ),
                child: Column(children: [
                  const Icon(Icons.favorite,
                      color: Color(0xFF00897B), size: 26),
                  const SizedBox(height: 10),
                  Text('دعوة من $_foundName',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _ink)),
                  const SizedBox(height: 6),
                  const Text('هل تريد الربط بحسابها؟',
                      style: TextStyle(fontSize: 12.5, color: _ink3)),
                ]),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _foundName != null ? const Color(0xFF00897B) : _blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _busy
                  ? null
                  : (_foundName != null ? _confirm : _verify),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_foundName != null ? 'نعم، اربطني' : 'تحقّق من الكود',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا يمكنك الاطّلاع على بياناتها الخاصّة — فقط ما تختار مشاركته معك.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: _ink3, height: 1.6),
            ),
          ]),
        ),
      ),
    );
  }
}
