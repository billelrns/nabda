# -*- coding: utf-8 -*-
"""
محرّك لقطات متجر نبضة — Google Play / App Store
================================================
يبني 8 لقطات 1080x1920 (PNG 24-bit بلا شفافية) من لقطات حقيقية للتطبيق.

لماذا محلياً وليس بالذكاء الاصطناعي؟
  سياسة Google Play تُلزم أن تُظهر لقطات المتجر تجربة التطبيق الفعلية.
  لذلك الصورة الأساسية داخل الهاتف = لقطة حقيقية من التطبيق، والتصميم
  حولها (الخلفية، العنوان، الإطار، الشعار) يُبنى هنا بـ0 كريدت.

التشغيل:
    python3 build_store_shots.py            # كل اللقطات
    python3 build_store_shots.py 01_week    # لقطة واحدة

المدخلات : marketing/store/raw/<src>        (لقطات الهاتف بدقّتها الأصلية)
المخرجات : marketing/store/out/<id>.png     (1080x1920)
           marketing/store/out/_strip.png   (شريط معاينة للثمانية)
"""
import json, math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# ------------------------------------------------------------------ مسارات
HERE  = os.path.dirname(os.path.abspath(__file__))
ROOT  = os.path.dirname(os.path.dirname(HERE))          # جذر المشروع
RAW   = os.path.join(HERE, 'raw')
OUT   = os.path.join(HERE, 'out')
FONTS = os.path.join(HERE, 'fonts')
CFG   = os.path.join(HERE, 'shots.json')

F_BOLD = os.path.join(FONTS, 'Almarai-ExtraBold.ttf')
F_REG  = os.path.join(FONTS, 'Almarai-Regular.ttf')

HEART_BIG   = os.path.join(ROOT, 'web', 'landing-assets', 'heart-big.png')
HEART_SMALL = os.path.join(ROOT, 'web', 'landing-assets', 'heart-small.png')

W, H = 1080, 1920

# كسور تُقصّ من لقطة الهاتف الخام: شريط الحالة أعلى، شريط تنقّل أندرويد أسفل
CROP_TOP, CROP_BOTTOM = 0.033, 0.045

# ------------------------------------------------------------------ أدوات
def hx(s):
    s = s.lstrip('#')
    return tuple(int(s[i:i+2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def vgrad(size, top, bottom):
    """تدرّج رأسي سريع."""
    w, h = size
    g = Image.new('RGB', (1, h))
    px = g.load()
    for y in range(h):
        px[0, y] = lerp(top, bottom, y / max(1, h - 1))
    return g.resize((w, h), Image.BILINEAR)


def rrect_mask(size, radius, ss=4):
    """قناع مستطيل بزوايا دائرية، مضاعَف العيّنات لحواف ناعمة."""
    w, h = size
    m = Image.new('L', (w * ss, h * ss), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * ss - 1, h * ss - 1],
                                        radius=radius * ss, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def fit_font(path, text, max_w, start, min_size=28):
    """أكبر مقاس يجعل النص يدخل داخل max_w."""
    size = start
    while size > min_size:
        f = ImageFont.truetype(path, size)
        bb = f.getbbox(text)
        if bb[2] - bb[0] <= max_w:
            return f
        size -= 2
    return ImageFont.truetype(path, min_size)


def draw_ar(d, xy, text, font, fill, anchor='ra'):
    d.text(xy, text, font=font, fill=fill, anchor=anchor,
           direction='rtl', language='ar')


# ------------------------------------------------------------------ الشعار
def build_logo(width=260, word=True, word_color=(173, 20, 87)):
    big   = Image.open(HEART_BIG).convert('RGBA')
    small = Image.open(HEART_SMALL).convert('RGBA')
    ar = big.size[0] / big.size[1]
    bw = width
    bh = int(bw / ar)
    big = big.resize((bw, bh), Image.LANCZOS)
    sw = int(0.45 * bw)
    sh = int(sw * small.size[1] / small.size[0])
    small = small.resize((sw, sh), Image.LANCZOS)

    word_h = int(bh * 0.40) if word else 0
    gap    = int(bh * 0.12) if word else 0
    canvas = Image.new('RGBA', (bw, bh + gap + word_h + (10 if word else 0)), (0, 0, 0, 0))
    canvas.alpha_composite(big, (0, 0))
    canvas.alpha_composite(small, (int(bw / 2 - sw / 2 + 0.027 * bw),
                                   int(bh / 2 - sh / 2 + 0.07 * bh)))
    if word:
        f = fit_font(F_BOLD, 'نبضة', int(bw * 0.92), word_h + 8, 12)
        d = ImageDraw.Draw(canvas)
        draw_ar(d, (bw // 2, bh + gap), 'نبضة', f, word_color + (255,), anchor='ma')
    return canvas


# ------------------------------------------------------------------ الخلفية
def ecg_points(x0, x1, base_y, amp, period, phase=0.0, step=3):
    """مسار تخطيط قلب مستمر: خط مسطّح تقطعه نبضة QRS كل period."""
    pts = []
    x = x0
    while x <= x1:
        t = ((x + phase) % period) / period          # 0..1 داخل النبضة
        y = 0.0
        if 0.42 <= t < 0.47:      y = -0.18 * amp * math.sin((t - 0.42) / 0.05 * math.pi)
        elif 0.47 <= t < 0.505:   y = +0.35 * amp * ((t - 0.47) / 0.035)
        elif 0.505 <= t < 0.545:  y = -1.00 * amp * ((t - 0.505) / 0.04) + 0.35 * amp
        elif 0.545 <= t < 0.585:  y = -0.65 * amp + 0.95 * amp * ((t - 0.545) / 0.04)
        elif 0.585 <= t < 0.625:  y = 0.30 * amp - 0.30 * amp * ((t - 0.585) / 0.04)
        elif 0.70 <= t < 0.80:    y = -0.22 * amp * math.sin((t - 0.70) / 0.10 * math.pi)
        pts.append((x, base_y + y))
        x += step
    return pts


def zellige(size, color, alpha=16, cell=150):
    """زخرفة نجمة ثمانية خفيفة — لمسة جزائرية في الخلفية."""
    w, h = size
    lay = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    r = cell * 0.30
    for cy in range(0, h + cell, cell):
        for cx in range(0, w + cell, cell):
            for k in range(2):
                a0 = math.radians(22.5 * k)
                pts = []
                for i in range(4):
                    a = a0 + i * math.pi / 2
                    pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
                    a2 = a + math.pi / 4
                    pts.append((cx + r * 0.42 * math.cos(a2), cy + r * 0.42 * math.sin(a2)))
                d.polygon(pts, outline=color + (alpha,))
    return lay


# تدرّج الخلفية: يمشي عبر الثمانية كشروق واحد (وردي حار -> برقوقي عميق)
RAMP_TOP = ['#FF5C8D', '#FF4F86', '#F43F7C', '#E8367A', '#D62E78', '#C22878', '#AB2478', '#93207A']
RAMP_BOT = ['#8E1250', '#87124F', '#7E1150', '#761152', '#6D1054', '#651056', '#5C0F58', '#54105B']


def background(idx, n, theme, brand):
    """خلفية داكنة غنيّة — تجعل شاشة التطبيق الفاتحة تقفز للعين.
    الموجة والتدرّج يكملان عبر اللقطات الثماني كشريط واحد."""
    teal = hx(brand['teal'])
    i = min(idx, len(RAMP_TOP) - 1)
    bg = vgrad((W, H), hx(RAMP_TOP[i]), hx(RAMP_BOT[i])).convert('RGBA')

    # زخرفة الزليج — لمسة جزائرية خفيفة في الثلث العلوي
    bg.alpha_composite(zellige((W, 620), (255, 255, 255), alpha=20, cell=160), (0, 0))

    # هالات ضوئية: تركواز (لون التطبيق الثانوي) + وهج فاتح
    halo = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    if theme == 'teal':
        hd.ellipse([W - 620, -260, W + 260, 420], fill=teal + (70,))
    hd.ellipse([-360, H - 520, 420, H + 260], fill=(255, 255, 255, 34))
    hd.ellipse([W - 420, H - 300, W + 340, H + 320], fill=(255, 120, 170, 60))
    bg.alpha_composite(halo.filter(ImageFilter.GaussianBlur(120)))

    # موجة النبض — مستمرة عبر الشريط كله
    wave = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wave)
    period, phase = 560.0, idx * W
    wd.line(ecg_points(-20, W + 20, 462, 118, period, phase),
            fill=(255, 255, 255, 235), width=6, joint='curve')
    wd.line(ecg_points(-20, W + 20, 462, 118, period, phase),
            fill=(255, 255, 255, 60), width=20, joint='curve')
    bg.alpha_composite(wave.filter(ImageFilter.GaussianBlur(0.6)))
    return bg


# ------------------------------------------------------------------ الجهاز
def device(shot_img, screen_w=690):
    """يضع لقطة التطبيق داخل إطار هاتف حديث ويعيد RGBA + إزاحة الظل."""
    sw, sh0 = shot_img.size
    screen_h = int(round(screen_w * sh0 / sw))
    screen = shot_img.convert('RGB').resize((screen_w, screen_h), Image.LANCZOS)

    bez = 13
    rad_out, rad_in = 62, 50
    ow, oh = screen_w + bez * 2, screen_h + bez * 2

    body = Image.new('RGBA', (ow, oh), (0, 0, 0, 0))
    bm = rrect_mask((ow, oh), rad_out)
    fill = Image.new('RGBA', (ow, oh), (26, 26, 30, 255))
    body.paste(fill, (0, 0), bm)

    sm = rrect_mask((screen_w, screen_h), rad_in)
    body.paste(screen.convert('RGBA'), (bez, bez), sm)

    # لمعة زجاجية خفيفة من أعلى اليسار
    gl = Image.new('RGBA', (ow, oh), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gl)
    gd.polygon([(0, 0), (ow * 0.62, 0), (0, oh * 0.42)], fill=(255, 255, 255, 16))
    body.alpha_composite(Image.composite(gl, Image.new('RGBA', (ow, oh), (0, 0, 0, 0)), bm))

    # حافّة فاتحة تحاكي إطار المعدن
    ed = ImageDraw.Draw(body)
    ed.rounded_rectangle([0, 0, ow - 1, oh - 1], radius=rad_out,
                         outline=(255, 255, 255, 46), width=3)
    return body


def paste_device(bg, dev, x, y):
    ow, oh = dev.size
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sm = rrect_mask((ow, oh), 62)
    sh = Image.new('RGBA', (ow, oh), (120, 20, 60, 120))
    shadow.paste(sh, (x, y + 22), sm)
    bg.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(34)))
    bg.alpha_composite(dev, (x, y))
    return bg


# ------------------------------------------------------------------ لقطة
def render(shot, idx, n, brand):
    src = os.path.join(RAW, shot['src'])
    if not os.path.exists(src):
        return None, 'مفقود: raw/%s' % shot['src']

    img = Image.open(src)

    # قصّ شريط الحالة أعلى الشاشة وشريط التنقّل الأسود أسفلها (كسور من الارتفاع)
    ct = float(shot.get('crop_top_frac', CROP_TOP))
    cb = float(shot.get('crop_bottom_frac', CROP_BOTTOM))
    iw, ih = img.size
    img = img.crop((0, int(ih * ct), iw, int(ih * (1 - cb))))

    bg = background(idx, n, shot.get('theme', 'pink'), brand)
    d = ImageDraw.Draw(bg)

    # --- النص (محاذاة يمين، RTL) — أبيض على خلفية داكنة
    right = W - 78
    f_head = fit_font(F_BOLD, shot['headline'], W - 156, 84, 46)
    hb = f_head.getbbox(shot['headline'])

    # ظل ناعم خلف العنوان ليبقى مقروءًا فوق أي هالة
    sh = Image.new('RGBA', (W, 420), (0, 0, 0, 0))
    ImageDraw.Draw(sh).text((right, 142), shot['headline'], font=f_head,
                            fill=(90, 0, 40, 130), anchor='ra',
                            direction='rtl', language='ar')
    bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(14)), (0, 0))

    draw_ar(d, (right, 138), shot['headline'], f_head, (255, 255, 255, 255))
    y_sub = 138 + (hb[3] - hb[1]) + 52

    f_sub = fit_font(F_REG, shot['sub'], W - 156, 44, 26)
    draw_ar(d, (right, y_sub), shot['sub'], f_sub, (255, 228, 240, 240))

    # شرطة تحت العنوان
    d.rounded_rectangle([right - 124, y_sub - 30, right, y_sub - 21],
                        radius=5, fill=(255, 255, 255, 235))

    # --- الجهاز
    dev = device(img, screen_w=690)
    paste_device(bg, dev, (W - dev.size[0]) // 2, 512)

    # --- الشعار أسفل اليسار (فوق الهاتف الذي ينزف خارج الإطار)
    logo = build_logo(118, word=False)
    plate_w, plate_h = 300, 108
    px, py = 52, H - plate_h - 46
    plate = Image.new('RGBA', (plate_w, plate_h), (0, 0, 0, 0))
    plate.paste(Image.new('RGBA', (plate_w, plate_h), (255, 255, 255, 232)),
                (0, 0), rrect_mask((plate_w, plate_h), 54))
    lg = logo.resize((74, int(74 * logo.size[1] / logo.size[0])), Image.LANCZOS)
    plate.alpha_composite(lg, (plate_w - 74 - 22, (plate_h - lg.size[1]) // 2))
    pd = ImageDraw.Draw(plate)
    f_w = ImageFont.truetype(F_BOLD, 46)
    draw_ar(pd, (plate_w - 74 - 40, (plate_h - 58) // 2), 'نبضة', f_w, hx(brand['deep']) + (255,))
    bg.alpha_composite(plate, (px, py))

    return bg.convert('RGB'), None


# ------------------------------------------------------------------ صورة الغلاف
def feature_graphic(brand, out_path, fw=1024, fh=500):
    """Feature graphic إلزامية في Google Play — 1024x500، بلا شفافية.
    تُترك المنطقة الوسطى شبه فارغة لأن Play قد يقصّها على أجهزة مختلفة."""
    bg = vgrad((fw, fh), hx('#FF5C8D'), hx('#6B1156')).convert('RGBA')
    bg.alpha_composite(zellige((fw, fh), (255, 255, 255), alpha=18, cell=120))

    halo = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.ellipse([-160, fh - 220, 320, fh + 190], fill=(255, 255, 255, 40))
    hd.ellipse([fw - 300, -180, fw + 180, 260], fill=hx(brand['teal']) + (70,))
    bg.alpha_composite(halo.filter(ImageFilter.GaussianBlur(90)))

    wave = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wave)
    wd.line(ecg_points(-10, fw + 10, int(fh * 0.72), 62, 340.0, 0),
            fill=(255, 255, 255, 190), width=4, joint='curve')
    wd.line(ecg_points(-10, fw + 10, int(fh * 0.72), 62, 340.0, 0),
            fill=(255, 255, 255, 55), width=14, joint='curve')
    bg.alpha_composite(wave)

    # هاتفان مائلان يطلّان من اليسار — يوحيان بتطبيق حقيقي لا ببانر نصّي
    picks = [s for s in ('01_week.png', '03_names.png') if os.path.exists(os.path.join(RAW, s))]
    for k, name in enumerate(reversed(picks)):
        im = Image.open(os.path.join(RAW, name))
        iw, ih = im.size
        im = im.crop((0, int(ih * CROP_TOP), iw, int(ih * (1 - CROP_BOTTOM))))
        dev = device(im, screen_w=196 - k * 18)
        dev = dev.rotate(-9 + k * 3, resample=Image.BICUBIC, expand=True)
        bg.alpha_composite(dev, (6 + k * 138, 86 + k * 26))

    d = ImageDraw.Draw(bg)
    logo = build_logo(150, word=False)
    lg = logo.resize((126, int(126 * logo.size[1] / logo.size[0])), Image.LANCZOS)
    bg.alpha_composite(lg, (fw - 126 - 74, 62))

    f1 = fit_font(F_BOLD, 'نبضة', 250, 96, 40)
    draw_ar(d, (fw - 74 - 148, 58), 'نبضة', f1, (255, 255, 255, 255))
    f2 = fit_font(F_BOLD, 'رفيقتكِ في الدورة والحمل والطفل', 486, 44, 20)
    draw_ar(d, (fw - 74, 218), 'رفيقتكِ في الدورة والحمل والطفل', f2, (255, 255, 255, 250))
    f3 = fit_font(F_REG, 'بالعربية · مصمَّم للأم الجزائرية', 440, 32, 16)
    draw_ar(d, (fw - 74, 284), 'بالعربية · مصمَّم للأم الجزائرية', f3, (255, 224, 238, 215))

    bg.convert('RGB').save(out_path, 'PNG')
    return out_path


# ------------------------------------------------------------------ main
def main():
    cfg = json.load(open(CFG, encoding='utf-8'))
    brand, shots = cfg['brand'], cfg['shots']
    only = sys.argv[1] if len(sys.argv) > 1 else None
    os.makedirs(OUT, exist_ok=True)

    done, missing = [], []
    for i, s in enumerate(shots):
        if only and s['id'] != only:
            continue
        im, err = render(s, i, len(shots), brand)
        if err:
            missing.append(err)
            print('  [-] %s  %s' % (s['id'], err))
            continue
        p = os.path.join(OUT, s['id'] + '.png')
        im.save(p, 'PNG')
        done.append(p)
        print('  [ok] %-18s %dx%d  %s' % (s['id'], im.size[0], im.size[1], s['headline']))

    if len(done) > 1:
        strip = Image.new('RGB', (len(done) * 280, 498), 'white')
        for i, p in enumerate(done):
            strip.paste(Image.open(p).resize((270, 480), Image.LANCZOS), (i * 280 + 5, 9))
        strip.save(os.path.join(OUT, '_strip.png'))
        print('  [ok] _strip.png')

    if not only:
        feature_graphic(brand, os.path.join(OUT, 'feature_graphic_1024x500.png'))
        print('  [ok] feature_graphic_1024x500.png')

    print('\nتم %d | ناقص %d' % (len(done), len(missing)))
    for m in missing:
        print('   ' + m)


if __name__ == '__main__':
    main()
