import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'c:\nabda_app\assets\data\smart_100_articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for art in data['articles']:
    title_short = art['title'][:60]
    cat = art.get('categoryId', '')
    tag = art.get('photoTag', '')
    print(f"{art['id']}|{cat}|{tag}|{title_short}")
