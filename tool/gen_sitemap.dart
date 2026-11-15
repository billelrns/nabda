import 'dart:convert';
import 'dart:io';

void main() async {
  print('Generating sitemap.xml for nabda.online...');
  final nowStr = DateTime.now().toUtc().toIso8601String().split('T')[0];
  final sitemapFile = File('web/sitemap.xml');
  final sink = sitemapFile.openWrite();

  sink.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  sink.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');

  void addUrl(String loc, String priority, String changefreq) {
    sink.writeln('  <url>');
    sink.writeln('    <loc>$loc</loc>');
    sink.writeln('    <lastmod>$nowStr</lastmod>');
    sink.writeln('    <changefreq>$changefreq</changefreq>');
    sink.writeln('    <priority>$priority</priority>');
    sink.writeln('  </url>');
  }

  // 1. Static Pages
  final staticPages = [
    {'url': 'https://nabda.online/', 'p': '1.0', 'f': 'daily'},
    {'url': 'https://nabda.online/pregnancy', 'p': '0.9', 'f': 'weekly'},
    {'url': 'https://nabda.online/baby', 'p': '0.9', 'f': 'weekly'},
    {'url': 'https://nabda.online/cycle', 'p': '0.8', 'f': 'weekly'},
    {'url': 'https://nabda.online/fertility', 'p': '0.8', 'f': 'weekly'},
    {'url': 'https://nabda.online/community', 'p': '0.8', 'f': 'daily'},
    {'url': 'https://nabda.online/shop', 'p': '0.9', 'f': 'daily'},
    {'url': 'https://nabda.online/articles', 'p': '0.8', 'f': 'daily'},
  ];

  for (final sp in staticPages) {
    addUrl(sp['url']!, sp['p']!, sp['f']!);
  }

  // 2. 42 Weeks of Pregnancy
  for (int w = 1; w <= 42; w++) {
    addUrl('https://nabda.online/pregnancy/week-$w', '0.8', 'monthly');
  }

  // 3. 25 Months of Baby
  for (int m = 0; m <= 24; m++) {
    addUrl('https://nabda.online/baby/month-$m', '0.8', 'monthly');
  }

  // 4. Articles from id_map.json (lightweight, ~172KB)
  final idMapFile = File('web/data/articles/id_map.json');
  if (await idMapFile.exists()) {
    try {
      final jsonStr = await idMapFile.readAsString();
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      final uniqueIds = map.values.map((v) => v.toString()).toSet();
      print('Found ${uniqueIds.length} canonical article IDs to add to sitemap.');
      for (final id in uniqueIds) {
        addUrl('https://nabda.online/article/$id', '0.7', 'weekly');
      }
    } catch (e) {
      print('Error parsing articles id_map: $e');
    }
  }

  sink.writeln('</urlset>');
  await sink.flush();
  await sink.close();

  print('Successfully generated ${sitemapFile.path} (${(await sitemapFile.length()) ~/ 1024} KB).');
}
