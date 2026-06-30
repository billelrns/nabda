// ═══════════════════════════════════════════════════════════════════
//  Web-only: عرض landing.html داخل IFrame مع جسر postMessage إلى Flutter.
// ═══════════════════════════════════════════════════════════════════
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

bool _viewFactoryRegistered = false;
void _registerLandingIframeFactory() {
  if (_viewFactoryRegistered) return;
  _viewFactoryRegistered = true;
  ui_web.platformViewRegistry.registerViewFactory(
    'nabda-landing-iframe',
    (int viewId) {
      final iframe = html.IFrameElement();
      iframe.src = 'landing.html';
      iframe.style.border = 'none';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      return iframe;
    },
  );
}

class WebPublicHome extends StatefulWidget {
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
  State<WebPublicHome> createState() => _WebPublicHomeState();
}

class _WebPublicHomeState extends State<WebPublicHome> {
  StreamSubscription<html.MessageEvent>? _msgSub;

  @override
  void initState() {
    super.initState();
    _registerLandingIframeFactory();

    _msgSub = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is! Map) return;
      if (data['type'] != 'nabda') return;
      final action = data['action']?.toString();
      if (action == null) return;
      switch (action) {
        case 'login':
          widget.onLogin();
          break;
        case 'signup':
          widget.onSignup();
          break;
        case 'pregnancy':
        case 'baby':
        case 'cycle':
        case 'community':
        case 'shop':
          widget.onOpenSection(action);
          break;
        default:
          widget.onLogin();
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF8FB),
      body: SizedBox.expand(
        child: HtmlElementView(viewType: 'nabda-landing-iframe'),
      ),
    );
  }
}
