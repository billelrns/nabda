# -*- coding: utf-8 -*-
"""
لقطات متجر نبضة — النسخة 3
===========================
بنية مستوحاة من أفضل ما في قوائم المنافسين العالميين (Flo): خلفية باستيل
هادئة، عنوان عربي على سطرين (تمهيد صغير + جملة كبيرة)، وبطاقة بيضاء واحدة
تحمل لقطة حقيقية من التطبيق وتنزف خارج الحافة السفلية.

وما يتجاوزها:
  * لوحة افتتاحية بصورة أم جزائرية حقيقية المظهر (Higgsfield) بدل صورة عامة
  * لون خلفية مختلف لكل لقطة مشتق من لون الشاشة نفسها، بدل لون واحد للجميع
  * كتل ضوء ناعمة خلف البطاقة تعطي عمقًا تفتقده البطاقات المسطّحة
  * لقطات لا يملك المنافس العالمي ما يقابلها: فقه المرأة، أيام القضاء، المتجر

المخرجات 1080x1920 PNG بلا شفافية — مطابقة لمواصفات Google Play.
    python3 build_store_v3.py          # الثمانية الأساسية + البدائل
"""
import json, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE  = os.path.dirname(os.path.abspath(__file__))
ROOT  = os.path.dirname(os.path.dirname(HERE))
RAW   = os.path.join(HERE, 'raw2')
OUT   = os.path.join(HERE, 'out_v3')
FONTS = os.path.join(HERE, 'fonts')
CFG   = os.path.join(HERE, 'shots_v3.json')

F_BOLD = os.path.join(FONTS, 'Almarai-ExtraBold.ttf')
F_REG  = os.path.join(FONTS, 'Almarai-Regular.ttf')
HEART_BIG   = os.path.join(ROOT, 'web', 'landing-assets', 'heart-big.png')
HEART_SMALL = os.path.join(ROOT, 'web', 'landing-assets', 'heart-small.png')

W, H = 1080, 1920
CROP_TOP, CROP_BOTTOM = 0.031, 0.044       # شريط الحالة / شريط تنقّل أندرويد

CARD_X      = 126                           # هامش البطاقة يمينًا ويسارًا
CARD_RADIUS = 48


# ----------------------------------------------------------------- أدوات
def hx(s):
    s = s.lstrip('#')
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def rrect_mask(size, radius, ss=4):
    w, h = size
    m = Image.new('L', (w * ss, h * ss), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * ss - 1, h * ss - 1],
                                        radius=radius * ss, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def ar_w(font, text):
    bb = font.getbbox(text)
    return bb[2] - bb[0]


def wrap_ar(font, text, max_w):
    """لفّ النص العربي على الكلمات بحيث لا يتجاوز أي سطر max_w."""
    words, lines, cur = text.split(), [], ''
    for w_ in words:
        t = (cur + ' ' + w_).strip()
        if cur and ar_w(font, t) > max_w:
            lines.append(cur)
            cur = w_
        else:
            cur = t
    if cur:
        lines.append(cur)
    return lines


def fit_block(path, text, max_w, start, min_size, max_lines):
    """أكبر مقاس يُبقي النص داخل max_w وداخل max_lines من الأسطر."""
    size = start
    while size > min_size:
        f = ImageFont.truetype(path, size)
        ls = wrap_ar(f, text, max_w)
        if len(ls) <= max_lines:
            return f, ls
        size -= 2
    f = ImageFont.truetype(path, min_size)
    return f, wrap_ar(f, text, max_w)


def draw_ar(d, xy, text, font, fill, anchor='ma'):
    d.text(xy, text, font=font, fill=fill, anchor=anchor,
           direction='rtl', language='ar')


def logo(width=200, word=False):
    big = Image.open(HEART_BIG).convert('RGBA')
    small = Image.open(HEART_SMALL).convert('RGBA')
    bw = width
    bh = int(bw / (big.size[0] / big.size[1]))
    big = big.resize((bw, bh), Image.LANCZOS)
    sw = int(0.45 * bw)
    sh = int(sw * small.size[1] / small.size[0])
    small = small.resize((sw, sh), Image.LANCZOS)
    c = Image.new('RGBA', (bw, bh), (0, 0, 0, 0))
    c.alpha_composite(big, (0, 0))
    c.alpha_composite(small, (int(bw / 2 - sw / 2 + 0.027 * bw),
                              int(bh / 2 - sh / 2 + 0.07 * bh)))
    return c


def load_screen(name):
    im = Image.open(os.path.join(RAW, name)).convert('RGB')
    w, h = im.size
    return im.crop((0, int(h * CROP_TOP), w, int(h * (1 - CROP_BOTTOM))))


# ----------------------------------------------------------------- لوحة عادية
def render_shot(shot, pal):
    ink = hx(pal['ink'])
    sub = hx(pal['sub'])
    base = hx(pal[shot.get('bg', 'blush')])

    bg = Image.new('RGB', (W, H), base).convert('RGBA')

    # وهج واحد خفيف جدًا خلف البطاقة — عمق بلا بقع مرئية
    blob = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(blob).ellipse(
        [-200, 560, W + 200, 1900],
        fill=mix(base, (255, 255, 255), 0.42) + (150,))
    bg.alpha_composite(blob.filter(ImageFilter.GaussianBlur(190)))

    d = ImageDraw.Draw(bg)
    cx = W // 2

    # --- التمهيد الصغير
    f_lead = ImageFont.truetype(F_REG, 46)
    lead_lines = wrap_ar(f_lead, shot['lead'], W - 200)
    y = 124
    for ln in lead_lines:
        draw_ar(d, (cx, y), ln, f_lead, sub + (255,))
        y += 60
    y += 10

    # --- الجملة الكبيرة
    f_big, big_lines = fit_block(F_BOLD, shot['big'], W - 196, 104, 58, 2)
    lh = int(f_big.size * 1.16)
    for ln in big_lines:
        draw_ar(d, (cx, y), ln, f_big, ink + (255,))
        y += lh

    # --- البطاقة
    card_top = max(y + 58, 470)
    cw = W - CARD_X * 2
    src = load_screen(shot['src'])
    ch = int(round(cw * src.size[1] / src.size[0]))
    card = src.resize((cw, ch), Image.LANCZOS)
    card = card.filter(ImageFilter.UnsharpMask(radius=1.6, percent=62, threshold=3))

    m = rrect_mask((cw, ch), CARD_RADIUS)

    # ظل البطاقة
    sh_l = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sh_l.paste(Image.new('RGBA', (cw, ch), mix(base, (60, 34, 58), 0.62) + (105,)),
               (CARD_X, card_top + 26), m)
    bg.alpha_composite(sh_l.filter(ImageFilter.GaussianBlur(26)))

    layer = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    layer.paste(card.convert('RGBA'), (CARD_X, card_top), m)
    bg.alpha_composite(layer)

    # حافّة بيضاء رفيعة تفصل البطاقة عن الخلفية
    ImageDraw.Draw(bg).rounded_rectangle(
        [CARD_X, card_top, CARD_X + cw - 1, card_top + ch - 1],
        radius=CARD_RADIUS, outline=(255, 255, 255, 190), width=4)

    return bg.convert('RGB')


# ----------------------------------------------------------------- اللوحة الافتتاحية
def render_hero(shot, pal):
    ink = hx(pal['ink'])
    src = Image.open(os.path.join(RAW, shot['src'])).convert('RGB')

    # cover-crop إلى 1080x1920
    sw, sh = src.size
    sc = max(W / sw, H / sh)
    src = src.resize((int(sw * sc + 1), int(sh * sc + 1)), Image.LANCZOS)
    sw, sh = src.size
    bg = src.crop(((sw - W) // 2, 0, (sw - W) // 2 + W, H)).convert('RGBA')

    # تعتيم متدرّج أعلى وأسفل ليقرأ النص
    scrim = Image.new('L', (1, H))
    px = scrim.load()
    for yy in range(H):
        t = yy / (H - 1)
        v = 0
        if t < 0.34:
            v = int(150 * (1 - t / 0.34) ** 1.3)
        if t > 0.80:
            v = max(v, int(165 * ((t - 0.80) / 0.20) ** 1.2))
        px[0, yy] = v
    scrim = scrim.resize((W, H))
    dark = Image.new('RGBA', (W, H), (26, 18, 26, 255))
    dark.putalpha(scrim)
    bg.alpha_composite(dark)

    d = ImageDraw.Draw(bg)
    cx = W // 2

    # الشعار + الاسم
    lg = logo(112)
    bg.alpha_composite(lg, (cx - lg.size[0] // 2, 86))
    f_name = ImageFont.truetype(F_BOLD, 74)
    draw_ar(d, (cx, 86 + lg.size[1] + 6), 'نبضة', f_name, (255, 255, 255, 255))

    # حبّتا نص (pills)
    y = 86 + lg.size[1] + 6 + 108
    for txt, fill, fg in ((shot['pill1'], (255, 255, 255, 240), ink),
                          (shot['pill2'], hx(pal['rose']) + (250,), ink)):
        f = ImageFont.truetype(F_BOLD, 62)
        tw = ar_w(f, txt)
        pw, ph = tw + 90, 104
        pill = Image.new('RGBA', (pw, ph), (0, 0, 0, 0))
        pill.paste(Image.new('RGBA', (pw, ph), fill), (0, 0), rrect_mask((pw, ph), ph // 2))
        pd = ImageDraw.Draw(pill)
        draw_ar(pd, (pw // 2, (ph - f.size) // 2 - 8), txt, f, fg + (255,))
        bg.alpha_composite(pill, (cx - pw // 2, y))
        y += ph + 18

    # سطر الإثبات أسفل الصورة
    f_p = ImageFont.truetype(F_REG, 44)
    draw_ar(d, (cx, H - 150), shot['proof'], f_p, (255, 255, 255, 235))

    return bg.convert('RGB')


# ----------------------------------------------------------------- لوحة الأمان والخصوصية
def render_privacy(shot, pal):
    """لوحة بلا لقطة شاشة: مجسّم ثلاثي الأبعاد + وعود مُتحقَّق منها في الكود.

    كل سطر هنا قابل للإثبات:
      - firestore.rules يمنع الأدمن صراحةً من قراءة /users/{uid}
      - حقل isAnonymous في منشورات المجتمع
      - Firestore يشفّر البيانات أثناء النقل وفي التخزين افتراضيًا
    لا نعِد بقفل بصمة ولا تشفير طرف-لطرف لأنهما غير موجودين.
    """
    ink = hx(pal['ink'])
    sub = hx(pal['sub'])

    art = Image.open(os.path.join(RAW, shot['src'])).convert('RGB')
    # لون الخلفية يُسحب من زاوية الصورة نفسها فيذوب المجسّم بلا حافّة مرئية
    sw, sh = art.size
    corner = art.crop((0, 0, sw // 8, sh // 8)).resize((1, 1), Image.BOX).getpixel((0, 0))
    base = corner

    bg = Image.new('RGB', (W, H), base).convert('RGBA')
    d = ImageDraw.Draw(bg)
    cx = W // 2

    f_lead = ImageFont.truetype(F_REG, 46)
    y = 124
    for ln in wrap_ar(f_lead, shot['lead'], W - 200):
        draw_ar(d, (cx, y), ln, f_lead, sub + (255,))
        y += 60
    y += 10

    f_big, big_lines = fit_block(F_BOLD, shot['big'], W - 196, 104, 58, 2)
    for ln in big_lines:
        draw_ar(d, (cx, y), ln, f_big, ink + (255,))
        y += int(f_big.size * 1.16)

    # المجسّم، بحوافّ متلاشية في الخلفية
    aw = 760
    ah = int(round(aw * sh / sw))
    art = art.resize((aw, ah), Image.LANCZOS).convert('RGBA')
    feather = Image.new('L', (aw, ah), 0)
    ImageDraw.Draw(feather).rounded_rectangle([40, 40, aw - 41, ah - 41],
                                              radius=180, fill=255)
    art.putalpha(feather.filter(ImageFilter.GaussianBlur(46)))
    ay = max(y + 10, 430)
    bg.alpha_composite(art, (cx - aw // 2, ay))

    # بطاقات الوعود
    cy = ay + ah - 40
    f_c = ImageFont.truetype(F_REG, 40)
    cw, pad = W - 2 * 96, 30
    for txt in shot['claims']:
        lines = wrap_ar(f_c, txt, cw - 2 * pad - 92)
        chh = 46 * len(lines) + 2 * pad + 12
        card = Image.new('RGBA', (cw, chh), (0, 0, 0, 0))
        card.paste(Image.new('RGBA', (cw, chh), (255, 255, 255, 236)),
                   (0, 0), rrect_mask((cw, chh), 34))
        cd = ImageDraw.Draw(card)
        cd.ellipse([cw - 78, chh // 2 - 19, cw - 40, chh // 2 + 19],
                   fill=hx(pal['sage']) + (255,))
        cd.line([(cw - 68, chh // 2 + 1), (cw - 61, chh // 2 + 9),
                 (cw - 48, chh // 2 - 9)], fill=(46, 104, 88, 255), width=6,
                joint='curve')
        ty = pad
        for ln in lines:
            cd.text((cw - 96, ty), ln, font=f_c, fill=ink + (245,), anchor='ra',
                    direction='rtl', language='ar')
            ty += 46

        shl = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        shl.paste(Image.new('RGBA', (cw, chh), mix(base, (70, 38, 60), 0.55) + (95,)),
                  (96, cy + 14), rrect_mask((cw, chh), 34))
        bg.alpha_composite(shl.filter(ImageFilter.GaussianBlur(18)))
        bg.alpha_composite(card, (96, cy))
        cy += chh + 26

    return bg.convert('RGB')


# ----------------------------------------------------------------- صورة الغلاف
def render_feature(pal, out_path, fw=1024, fh=500, proof='بالعربية'):
    """Feature graphic إلزامية في Google Play — 1024x500 بلا شفافية."""
    ink = hx(pal['ink'])
    left, right = hx(pal['sage']), hx(pal['blush'])
    g = Image.new('RGB', (fw, 1))
    px = g.load()
    for x in range(fw):
        px[x, 0] = mix(left, right, x / (fw - 1))
    bg = g.resize((fw, fh), Image.BILINEAR).convert('RGBA')

    # صورة الأم على اليسار، تذوب في الخلفية
    hero = os.path.join(RAW, 'hero_mother.png')
    if os.path.exists(hero):
        im = Image.open(hero).convert('RGB')
        iw, ih = im.size
        sc = fh / ih * 1.18
        im = im.resize((int(iw * sc), int(ih * sc)), Image.LANCZOS)
        im = im.crop((0, int(im.size[1] * 0.06), min(im.size[0], 470),
                      int(im.size[1] * 0.06) + fh))
        fade = Image.new('L', im.size, 255)
        fd = ImageDraw.Draw(fade)
        for x in range(im.size[0] - 170, im.size[0]):
            fd.line([(x, 0), (x, fh)],
                    fill=int(255 * (1 - (x - (im.size[0] - 170)) / 170)))
        bg.paste(im, (0, 0), fade)

    d = ImageDraw.Draw(bg)
    ax = fw - 62                                  # محاذاة يمين

    lg = logo(96)
    bg.alpha_composite(lg, (ax - lg.size[0], 56))
    f_name = ImageFont.truetype(F_BOLD, 88)
    d.text((ax - lg.size[0] - 24, 56), 'نبضة', font=f_name, fill=ink + (255,),
           anchor='ra', direction='rtl', language='ar')

    f1, l1 = fit_block(F_BOLD, 'رفيقتكِ من الدورة إلى طفلكِ الأول', 470, 44, 24, 2)
    y = 206
    for ln in l1:
        d.text((ax, y), ln, font=f1, fill=ink + (255,), anchor='ra',
               direction='rtl', language='ar')
        y += int(f1.size * 1.28)

    f2 = ImageFont.truetype(F_REG, 30)
    d.text((ax, y + 14), 'دورة · حمل · طفل · فقه المرأة', font=f2,
           fill=mix(ink, (255, 255, 255), 0.30) + (255,), anchor='ra',
           direction='rtl', language='ar')
    d.text((ax, y + 58), proof, font=f2,
           fill=mix(ink, (255, 255, 255), 0.45) + (255,), anchor='ra',
           direction='rtl', language='ar')

    bg.convert('RGB').save(out_path, 'PNG')
    return out_path


# ----------------------------------------------------------------- main
def main():
    cfg = json.load(open(CFG, encoding='utf-8'))
    pal = cfg['palette']
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(os.path.join(OUT, 'alt'), exist_ok=True)

    done = []
    for s in cfg['shots']:
        if not os.path.exists(os.path.join(RAW, s['src'])):
            print('  [-] %s  مفقود raw2/%s' % (s['id'], s['src']))
            continue
        im = render_hero(s, pal) if s.get('type') == 'hero' else render_shot(s, pal)
        p = os.path.join(OUT, s['id'] + '.png')
        im.save(p, 'PNG')
        done.append(p)
        print('  [ok] %-14s %dx%d' % (s['id'], im.size[0], im.size[1]))

    ps = cfg.get('privacy_shot')
    if ps and os.path.exists(os.path.join(RAW, ps['src'])):
        im = render_privacy(ps, pal)
        im.save(os.path.join(OUT, ps['id'] + '.png'), 'PNG')
        print('  [ok] %-14s %dx%d' % (ps['id'], im.size[0], im.size[1]))

    for s in cfg.get('alternates', []):
        if not os.path.exists(os.path.join(RAW, s['src'])):
            continue
        im = render_shot(s, pal)
        im.save(os.path.join(OUT, 'alt', s['id'] + '.png'), 'PNG')
        print('  [ok] alt/%-12s' % s['id'])

    if len(done) > 1:
        strip = Image.new('RGB', (len(done) * 286, 510), 'white')
        for i, p in enumerate(done):
            strip.paste(Image.open(p).resize((276, 490), Image.LANCZOS), (i * 286 + 5, 10))
        strip.save(os.path.join(OUT, '_strip.png'))
        print('  [ok] _strip.png')

    hero = next((s for s in cfg['shots'] if s.get('type') == 'hero'), {})
    render_feature(pal, os.path.join(OUT, 'feature_graphic_1024x500.png'),
                   proof=hero.get('proof', 'بالعربية'))
    print('  [ok] feature_graphic_1024x500.png')


if __name__ == '__main__':
    main()
