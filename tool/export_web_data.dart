// ═══════════════════════════════════════════════════════════════════
//  تصدير بيانات التطبيق إلى JSON للموقع — nabda.online
//  يُشغّل بـ: dart run tool/export_web_data.dart
// ═══════════════════════════════════════════════════════════════════

import 'dart:io';

void main() async {
  print('🚀 بدء تصدير بيانات نبضة للموقع الإلكتروني (Stage 1)...');
  
  final scriptPath = 'tool/export_data.py';
  final result = await Process.run('python', [scriptPath], runInShell: true);
  
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  
  if (result.exitCode == 0) {
    print('✅ تم تصدير جميع البيانات بنجاح إلى web/data/ و web/img/');
  } else {
    print('❌ حدث خطأ أثناء التصدير (كود: ${result.exitCode})');
    exit(result.exitCode);
  }
}
