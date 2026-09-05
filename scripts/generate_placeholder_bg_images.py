"""
يولّد 30 صورة قالبية placeholder بتدرّجات لطيفة + نص فئة.
تعمل مباشرة، تُستبدل لاحقاً بصور Higgsfield الحقيقية بنفس الاسم.
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import hashlib
import sys

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

OUT_DIR = Path(r'C:\nabda_app\assets\images\articles_bg')
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ألوان تدرّج لكل فئة (وسط الفئة → أفتح قليلاً)
GRADIENTS = {
    'pregnancy':  [(233, 30, 99), (255, 96, 144)],   # وردي → وردي فاتح
    'beauty':     [(255, 96, 144), (255, 183, 197)],  # وردي ناعم → زهري فاتح
    'marriage':   [(236, 64, 122), (255, 138, 178)],  # روز → فاتح
    'fertility':  [(126, 87, 194), (179, 136, 235)],  # لافندر → فاتح
    'health':     [(0, 137, 123), (77, 182, 172)],    # تركوازي → فاتح
    'baby':       [(41, 182, 246), (129, 212, 250)],  # أزرق → فاتح
}

LABELS = {
    'pregnancy': 'الحمل والولادة',
    'beauty':    'جمالي وعنايتي',
    'marriage':  'العلاقة الزوجية',
    'fertility': 'التبويض والخصوبة',
    'health':    'صحة المرأة',
    'baby':      'رعاية الرضيع',
}

def make_gradient(w, h, c1, c2):
    """يصنع خلفية تدرّج لوني عمودي ناعم مع لمسة قطرية خفيفة."""
    img = Image.new('RGB', (w, h))
    pixels = img.load()
    for y in range(h):
        ratio_y = y / h
        for x in range(w):
            ratio = (ratio_y * 0.7) + ((x / w) * 0.3)
            r = int(c1[0] + (c2[0] - c1[0]) * ratio)
            g = int(c1[1] + (c2[1] - c1[1]) * ratio)
            b = int(c1[2] + (c2[2] - c1[2]) * ratio)
            pixels[x, y] = (r, g, b)
    return img

def get_font(size):
    for f in ['arialbd.ttf', 'arial.ttf', 'calibri.ttf', 'segoeui.ttf']:
        try:
            return ImageFont.truetype(f, size)
        except Exception:
            pass
    try:
        return ImageFont.load_default()
    except Exception:
        return None

font_large = get_font(72)
font_small = get_font(36)

count = 0
for cat, colors in GRADIENTS.items():
    for i in range(1, 6):
        seed = int(hashlib.md5(f'{cat}{i}'.encode()).hexdigest()[:8], 16)
        c1 = tuple(max(0, min(255, c + (seed % 30) - 15)) for c in colors[0])
        c2 = tuple(max(0, min(255, c + ((seed // 100) % 30) - 15)) for c in colors[1])

        img = make_gradient(1200, 800, c1, c2)
        draw = ImageDraw.Draw(img)

        # زخارف هندسية دائرية ناعمة وشبه شفافة في الخلفية
        overlay = Image.new('RGBA', (1200, 800), (0, 0, 0, 0))
        overlay_draw = ImageDraw.Draw(overlay)
        cx, cy = 600, 400
        overlay_draw.ellipse((cx - 300, cy - 300, cx + 300, cy + 300), outline=(255, 255, 255, 40), width=3)
        overlay_draw.ellipse((cx - 350, cy - 350, cx + 350, cy + 350), outline=(255, 255, 255, 25), width=2)
        
        img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
        draw = ImageDraw.Draw(img)

        text = f'{cat.upper()} · {i:02d}'
        if font_large:
            bbox = draw.textbbox((0, 0), text, font=font_large)
            tw = bbox[2] - bbox[0]
            th = bbox[3] - bbox[1]
            draw.text(((1200 - tw) // 2, (800 - th) // 2 - 20), text, fill=(255, 255, 255, 220), font=font_large)

        subtext = 'NABDA HEALTH ENCYCLOPEDIA'
        if font_small:
            bbox_sub = draw.textbbox((0, 0), subtext, font=font_small)
            sw = bbox_sub[2] - bbox_sub[0]
            sh = bbox_sub[3] - bbox_sub[1]
            draw.text(((1200 - sw) // 2, (800 - sh) // 2 + 50), subtext, fill=(255, 255, 255, 180), font=font_small)

        path = OUT_DIR / f'bg_{cat}_{i:02d}.jpg'
        img.save(path, 'JPEG', quality=85, optimize=True)
        count += 1
        print(f'✓ {path.name}')

print(f'\n✓ تم توليد {count} صورة قالبية بنجاح في: {OUT_DIR}')
