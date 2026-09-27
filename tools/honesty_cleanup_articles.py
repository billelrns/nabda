"""تنظيف ادعاءات الإشراف الطبي من مقالات نبضة (27 سبتمبر 2026).

لا يوجد فريق طبي ولا أطباء يراجعون المحتوى، فتُزال كل صياغة توحي بذلك:
- الكاتب  → «فريق تحرير نبضة»
- الشارات «موثق طبياً / نصيحة طبيبة / دليل معتمد / إرشادات طبية» → صيغ محايدة
- عناوين الأقسام «تفاصيل طبية / تفسير طبي / سريرية» → صيغ محايدة
- قسم «المصادر والمراجع الطبية المعتمدة» يُعاد تسميته ويُوضَّح أنه مصادر
  للاستزادة وليس مراجع كُتب منها المقال
- «أطباء نبضة / خبراء نبضة» في المتن → صيغ لا تدّعي وجود مختصين

يحافظ على صيغة الملف حرفيًا (indent=2, ensure_ascii=False).
الاستعمال: python tools/honesty_cleanup_articles.py
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = [
    os.path.join(ROOT, 'assets', 'data', 'smart_2500_articles.json'),
    os.path.join(ROOT, 'assets', 'data', 'smart_100_articles.json'),
]

AUTHOR = 'فريق تحرير نبضة'

BADGES = {
    'موثق طبياً 🩺': 'دليل شامل 📘',
    'نصيحة طبيبة 💡': 'نصيحة عملية 💡',
    'دليل معتمد': 'دليل مبسّط',
    'إرشادات طبية': 'إرشادات عامة',
    'شامل وموثق': 'شامل ومبسّط',
}

SECTION_TITLES = {
    '📚 المصادر والمراجع الطبية المعتمدة': '📚 للاستزادة: مصادر عالمية موثوقة',
    'نظرة شاملة وتفاصيل طبية هامة': 'نظرة شاملة وتفاصيل مهمة',
    'مدخل وتفسير طبي شامل': 'مدخل وتفسير شامل',
    'التفاصيل السريرية والخطوات الموصى بها': 'التفاصيل العملية والخطوات الموصى بها',
    'أهم التفاصيل والإرشادات الطبية': 'أهم التفاصيل والإرشادات',
}

REFS_PREFIX = ('هذه جهات عالمية موثوقة للاستزادة في الموضوع، وليست مراجع '
               'اعتمد عليها هذا المقال حرفيًا:\n')

TEXT = {
    'ويمكنك أيضًا استشارة أطباء نبضة في أي شيء يقلقك':
        'ولا تترددي في استشارة طبيبتك في أي شيء يقلقك',
    'لا ينصح أطباء نبضة بالصيام': 'لا يُنصح عادةً بالصيام',
    'لتجيبك عنه طبيبات وأطباء نبضة': 'في مجتمع نبضة، واستشيري طبيبتك دائمًا',
    'خبراء العلاقات في نبضة يخبرونك بأسرار السعادة في سنة أولى زواج':
        'أسرار السعادة في سنة أولى زواج',
    'بمحتوى طبي موثوق': 'بمحتوى مبسّط',
}


def fix_text(s):
    for a, b in TEXT.items():
        s = s.replace(a, b)
    return s


def clean(article, stats):
    if article.get('author') != AUTHOR:
        article['author'] = AUTHOR
        stats['author'] += 1
    b = article.get('badge')
    if b in BADGES:
        article['badge'] = BADGES[b]
        stats['badge'] += 1
    for key in ('title', 'originalTitle', 'summary', 'description'):
        if isinstance(article.get(key), str):
            new = fix_text(article[key])
            if new != article[key]:
                article[key] = new
                stats['text'] += 1
    for sec in article.get('sections', []) or []:
        t = sec.get('title')
        if t in SECTION_TITLES:
            sec['title'] = SECTION_TITLES[t]
            stats['section_title'] += 1
            if t.startswith('📚') and not sec.get('content', '').startswith(REFS_PREFIX):
                sec['content'] = REFS_PREFIX + sec.get('content', '')
                stats['refs'] += 1
        for key in ('content', 'calloutTip', 'calloutWarning'):
            if isinstance(sec.get(key), str):
                new = fix_text(sec[key])
                if new != sec[key]:
                    sec[key] = new
                    stats['text'] += 1
    for faq in article.get('faqs', []) or []:
        for key in ('question', 'answer'):
            if isinstance(faq.get(key), str):
                new = fix_text(faq[key])
                if new != faq[key]:
                    faq[key] = new
                    stats['text'] += 1


def main():
    for path in FILES:
        raw = open(path, encoding='utf-8').read()
        data = json.loads(raw)
        if json.dumps(data, ensure_ascii=False, indent=2) != raw.rstrip('\n'):
            sys.exit(f'Format mismatch, refusing to rewrite: {path}')
        stats = {'author': 0, 'badge': 0, 'section_title': 0, 'refs': 0, 'text': 0}
        for a in data['articles']:
            clean(a, stats)
        out = json.dumps(data, ensure_ascii=False, indent=2)
        if raw.endswith('\n'):
            out += '\n'
        open(path, 'w', encoding='utf-8').write(out)
        print(os.path.basename(path), stats)


if __name__ == '__main__':
    main()
