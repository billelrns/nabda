// ═══════════════════════════════════════════════════════════════════
//  Stub لـ non-web (موبايل/Desktop) — لا يحتوي dart:html/dart:ui_web.
//  لن يُستدعى فعليًّا لأنّ AuthGate يستخدمه فقط داخل if (kIsWeb).
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

class WebPublicHome extends StatelessWidget {
  final Widget articlesSection;
  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final void Function(String section) onOpenSection;
  const WebPublicHome({
    Key? key,
    required this.articlesSection,
    required this.onLogin,
    required this.onSignup,
    required this.onOpenSection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // لا يُفترض الوصول هنا على الموبايل — fallback آمن.
    return const Scaffold(
      backgroundColor: Color(0xFFFFF8FB),
      body: Center(child: Text('Web only')),
    );
  }
}
