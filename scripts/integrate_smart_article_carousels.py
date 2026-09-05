"""
Integrates SmartArticleCarousel into lib/main.dart across HomePage, BabyPage, and CyclePage.
"""
import sys
sys.stdout.reconfigure(encoding='utf-8')


def main():
    path = 'lib/main.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add import
    import_target = "import 'widgets/smart_articles_carousel.dart';"
    import_replacement = "import 'widgets/smart_articles_carousel.dart';\nimport 'widgets/smart_article_carousel.dart';"
    if import_target not in content:
        print("ERROR: import_target not found")
        sys.exit(1)
    if "import 'widgets/smart_article_carousel.dart';" not in content:
        content = content.replace(import_target, import_replacement, 1)
        print("✓ Import added")
    else:
        print("✓ Import already present")

    # 2. HomePage: replace SmartArticlesCarousel with top viewed + beauty carousels
    home_marker = "// ════════════ SMART INTERACTIVE ARTICLES ════════════"
    if home_marker not in content:
        print("ERROR: home_marker not found")
        sys.exit(1)

    # Let's inspect the exact lines around home_marker
    # We can replace the block
    old_home_block = """                        // ════════════ SMART INTERACTIVE ARTICLES ════════════
                        const SmartArticlesCarousel(
                          sectionTitle: 'مقالات ذكية وإرشادية',
                          sectionSubtitle: 'محتوى طبي تفاعلي موثق لتلبية جميع تساؤلاتكِ',
                        ),
                        const SizedBox(height: 16),"""

    new_home_block = """                        // ════════════ SMART INTERACTIVE ARTICLES ════════════
                        const SmartArticleCarousel(
                          categoryId: null,
                          title: '🔥 الأكثر قراءة في نبضة',
                          maxItems: 10,
                        ),
                        const SizedBox(height: 12),
                        const SmartArticleCarousel(
                          categoryId: 'beauty',
                          title: '💄 جمالكِ وعنايتك',
                          maxItems: 8,
                        ),
                        const SizedBox(height: 16),"""

    if old_home_block in content:
        content = content.replace(old_home_block, new_home_block, 1)
        print("✓ HomePage carousels integrated")
    elif "title: '🔥 الأكثر قراءة في نبضة'" in content:
        print("✓ HomePage carousels already present")
    else:
        print("ERROR: old_home_block not found in content")
        sys.exit(1)

    # 3. BabyPage: replace SmartArticlesCarousel with baby SmartArticleCarousel
    # Match by categoryFilter: 'baby'
    baby_marker = "categoryFilter: 'baby'"
    if baby_marker in content:
        # Find start of const SmartArticlesCarousel before baby_marker
        idx = content.find(baby_marker)
        start_idx = content.rfind("const SmartArticlesCarousel(", 0, idx)
        end_idx = content.find("),", idx) + 2
        baby_block = content[start_idx:end_idx]
        new_baby_block = """const SmartArticleCarousel(
                          categoryId: 'baby',
                          title: '👶 مقالات رعاية الرضيع',
                          maxItems: 10,
                        )"""
        content = content[:start_idx] + new_baby_block + content[end_idx:]
        print("✓ BabyPage carousel integrated")
    elif "title: '👶 مقالات رعاية الرضيع'" in content:
        print("✓ BabyPage carousel already present")
    else:
        print("ERROR: baby_marker not found in content")
        sys.exit(1)

    # 4. CyclePage: add fertility + health carousels
    cycle_marker = "child: _CycleArticlesSection(),"
    if cycle_marker in content:
        idx = content.find(cycle_marker)
        padding_end = content.find("),", idx) + 2
        new_cycle_carousels = """
                        const SizedBox(height: 12),
                        const SmartArticleCarousel(categoryId: 'fertility', title: '🌸 التبويض والخصوبة', maxItems: 8),
                        const SizedBox(height: 12),
                        const SmartArticleCarousel(categoryId: 'health', title: '💗 صحّة المرأة', maxItems: 8),"""
        content = content[:padding_end] + new_cycle_carousels + content[padding_end:]
        print("✓ CyclePage carousels integrated")
    elif "title: '🌸 التبويض والخصوبة'" in content:
        print("✓ CyclePage carousels already present")
    else:
        print("ERROR: cycle_marker not found in content")
        sys.exit(1)


    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("✓ Successfully updated lib/main.dart")

if __name__ == '__main__':
    main()
