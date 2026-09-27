import 'package:flutter/material.dart';

/// يقسّم متن المقال إلى فقرات نظيفة، ويُسقط الفارغة والفضلات القصيرة.
List<String> splitParagraphs(String raw) {
  return raw
      .replaceAll(' ', ' ')
      .split(RegExp(r'\n+'))
      .map((p) => p.trim())
      .where((p) => p.length > 1)
      .toList();
}

/// ودجت لعرض النصوص العربية وتنسيق النجوم **عريض** إلى خط عريض حقيقي
class RichArabic extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? boldStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;

  const RichArabic(
    this.text, {
    Key? key,
    this.style,
    this.boldStyle,
    this.textAlign = TextAlign.start,
    this.textDirection = TextDirection.rtl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle(fontSize: 14.5, color: Color(0xFF4A3F4F), height: 1.75);
    final bold = boldStyle ??
        base.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1B1320),
        );
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
    var i = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > i) spans.add(TextSpan(text: text.substring(i, m.start)));
      spans.add(TextSpan(
        text: m.group(1),
        style: bold,
      ));
      i = m.end;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
    return RichText(
      textAlign: textAlign,
      textDirection: textDirection,
      text: TextSpan(style: base, children: spans),
    );
  }
}
