"""Nabda Facebook cards — 1080x1350 PNG, Almarai, RTL via Pillow+raqm. 0 credits."""
import json, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.abspath(__file__))
APP = os.path.abspath(os.path.join(ROOT, '..', '..'))
BG_DIR = os.path.join(APP, 'assets', 'images', 'articles_bg')
LOGO = os.path.join(APP, 'brand_nabda', 'deck_assets', 'img', 'logo.png')
FB = os.path.join(APP, 'brand_nabda', 'fonts_Almarai', 'Almarai-ExtraBold.ttf')
FR = os.path.join(APP, 'brand_nabda', 'fonts_Almarai', 'Almarai-Regular.ttf')
WEEK = os.environ.get('WEEK', 'week1')
OUT = os.path.join(ROOT, 'cards_' + WEEK)
os.makedirs(OUT, exist_ok=True)

W, H = 1080, 1350
PHOTO_H = 760
PINK, PINK_DK, TEAL, INK, BLUSH = (233, 30, 99), (194, 24, 91), (0, 137, 123), (58, 31, 43), (255, 245, 248)


def font(path, size):
    return ImageFont.truetype(path, size, layout_engine=ImageFont.Layout.RAQM)


def tw(d, s, f):
    return d.textlength(s, font=f, direction='rtl', language='ar')


def wrap(d, text, f, maxw):
    words, lines, cur = text.split(), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if tw(d, t, f) <= maxw:
            cur = t
        else:
            lines.append(cur); cur = w
    if cur:
        lines.append(cur)
    return lines


def cover(img, w, h):
    r = max(w / img.width, h / img.height)
    img = img.resize((int(img.width * r + 1), int(img.height * r + 1)), Image.LANCZOS)
    x, y = (img.width - w) // 2, (img.height - h) // 2
    return img.crop((x, y, x + w, y + h))


def card(p):
    im = Image.new('RGB', (W, H), BLUSH)
    photo = cover(Image.open(os.path.join(BG_DIR, p['bg'] + '.jpg')).convert('RGB'), W, PHOTO_H)
    im.paste(photo, (0, 0))
    d = ImageDraw.Draw(im)
    # soft blush curve under the photo
    d.rounded_rectangle((0, PHOTO_H - 60, W, H + 60), radius=60, fill=BLUSH)
    # logo badge at top-right of photo
    badge = Image.new('RGBA', (150, 150), (0, 0, 0, 0))
    bd = ImageDraw.Draw(badge)
    bd.ellipse((0, 0, 149, 149), fill=(255, 255, 255, 240))
    logo = Image.open(LOGO).convert('RGBA').resize((104, 104), Image.LANCZOS)
    badge.alpha_composite(logo, (23, 23))
    im.paste(badge, (W - 150 - 40, 40), badge)

    # chip
    fc = font(FB, 30)
    cw = tw(d, p['chip'], fc) + 56
    x1 = W - 70
    d.rounded_rectangle((x1 - cw, PHOTO_H - 28, x1, PHOTO_H + 30), radius=29, fill=PINK)
    d.text((x1 - 28, PHOTO_H + 1), p['chip'], font=fc, fill='white', anchor='rm', direction='rtl', language='ar')

    # title
    size = 76
    while True:
        ft = font(FB, size)
        lines = wrap(d, p['card'], ft, W - 140)
        if len(lines) <= 2 or size <= 56:
            break
        size -= 4
    lh = int(size * 1.5)
    top, bottom = PHOTO_H + 40, H - 150
    y = (top + bottom) // 2 - (lh * len(lines)) // 2 + lh // 2
    for ln in lines:
        d.text((W - 70, y), ln, font=ft, fill=INK, anchor='rm', direction='rtl', language='ar')
        y += lh

    # footer
    fy = H - 110
    d.line((70, fy - 40, W - 70, fy - 40), fill=(244, 194, 213), width=2)
    fr = font(FR, 30)
    d.text((W - 70, fy + 10), 'اقرئي المقال كاملاً على تطبيق نبضة', font=fr, fill=TEAL, anchor='rm', direction='rtl', language='ar')
    fl = font(FB, 34)
    d.text((70, fy + 10), 'nabda.online', font=fl, fill=PINK_DK, anchor='lm')
    name = f"d{p['day']}_{p['slot']}_{p['id']}.png"
    im.save(os.path.join(OUT, name), optimize=True)
    return name


if __name__ == '__main__':
    posts = json.load(open(os.path.join(ROOT, 'posts_' + WEEK + '.json'), encoding='utf8'))
    only = sys.argv[1:] and int(sys.argv[1])
    for p in posts[:only] if only else posts:
        print(card(p))
