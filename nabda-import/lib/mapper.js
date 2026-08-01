// تحويل منتج موحّد → مخطط Firestore 'products' الذي يقرأه تطبيق/موقع نبضة

// فئات نبضة الرسمية (من admin_panel_screen.dart)
const NABDA_CATEGORIES = [
  'ملابس الحمل', 'لوازم الرضيع', 'ملابس المولود', 'الرضاعة والتغذية', 'الحفاضات والنظافة',
  'عناية بالحامل', 'فيتامينات ومكملات', 'حقيبة الولادة', 'ألعاب وتحفيز', 'راحة الأم',
  'كتب وأدلة', 'أجهزة طبية', 'تذكارات وهدايا', 'سفر وتنقل', 'ديكور غرفة الطفل',
];

// كلمات مفتاحية (عربي/فرنسي/إنجليزي) → فئة نبضة. الترتيب مهم: الأخص أولاً.
const CATEGORY_RULES = [
  [/رضاع|حليب|شفاط|biberon|allaitement|breast ?pump|feeding|bottle|tetine|tétine|حلمة/i, 'الرضاعة والتغذية'],
  [/حفاض|couche|diaper|nettoyage|lingette|wipe|potty|قصري/i, 'الحفاضات والنظافة'],
  [/عرب|poussette|stroller|siege auto|siège auto|car ?seat|porte-bebe|porte-bébé|carrier|transat/i, 'سفر وتنقل'],
  [/لعب|jouet|toy|eveil|éveil|hochet|تحفيز|puzzle/i, 'ألعاب وتحفيز'],
  [/مولود|nouveau-ne|nouveau-né|newborn|body bebe|body bébé|grenouillere|grenouillère/i, 'ملابس المولود'],
  [/فيتامين|vitamine|complement|complément|supplement|folic|folique|omega|oméga|مكمل/i, 'فيتامينات ومكملات'],
  // العناية بالبشرة قبل قاعدة ملابس الحمل (كريم مضاد لتشققات الحمل ليس ملابس)
  [/كريم|زيت|creme|crème|huile|soin|skin|بشرة|تشقق|vergeture/i, 'عناية بالحامل'],
  [/ملابس.*حمل|ملابس.*حامل|vetement.*grossesse|robe.*grossesse|maternite|maternité|enceinte/i, 'ملابس الحمل'],
  [/حامل|grossesse|بطن الحامل|pregnan/i, 'عناية بالحامل'],
  [/حقيبة الولادة|sac maternite|sac maternité|valise/i, 'حقيبة الولادة'],
  [/جهاز|thermometre|thermomètre|thermometer|tensiometre|tensiomètre|monitor|طبي|test/i, 'أجهزة طبية'],
  [/chambre|decor|décor|veilleuse|tapis|ديكور|mobile bebe|mobile bébé/i, 'ديكور غرفة الطفل'],
  [/هدي|cadeau|gift|تذكار|souvenir/i, 'تذكارات وهدايا'],
  [/كتاب|livre|book|دليل|guide/i, 'كتب وأدلة'],
  [/راحة|coussin|oreiller|وسادة|nursing pillow/i, 'راحة الأم'],
];

function guessCategory(p, fallback) {
  const hay = [p.name, p.description, p.productType, (p.tags || []).join(' ')]
    .filter(Boolean)
    .join(' ');
  for (const [re, cat] of CATEGORY_RULES) {
    if (re.test(hay)) return cat;
  }
  return NABDA_CATEGORIES.includes(fallback) ? fallback : 'لوازم الرضيع';
}

function slugify(name, sourceId) {
  const base = (name || '')
    .toString()
    .trim()
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40);
  const suffix = String(sourceId || Math.random().toString(36).slice(2))
    .replace(/[^\w]/g, '')
    .slice(-6);
  return base ? base + '-' + suffix : 'p-' + suffix;
}

function applyMarkup(priceStr, markup) {
  const n = Number(String(priceStr).replace(/[^\d.]/g, ''));
  if (!Number.isFinite(n) || n <= 0) return priceStr || '';
  if (!markup) return String(Math.round(n));
  return String(Math.round(n * (1 + markup)));
}

// p: منتج موحّد ; store: عنصر من config.stores ; cfg: config كامل
function toNabda(p, store, cfg) {
  const images = (p.images || []).filter(Boolean);
  const category = guessCategory(p, store.defaultCategory);
  const price = applyMarkup(p.price, cfg.markup);
  const oldPrice = p.oldPrice ? applyMarkup(p.oldPrice, cfg.markup) : '';

  return {
    name: p.name || '',
    price: price,
    oldPrice: oldPrice,
    description: p.description || '',
    emoji: '\u{1F6CD}\u{FE0F}',
    category: category,
    slug: slugify(p.name, p.sourceId),
    imageUrl: images[0] || '',
    imageUrls: images,
    descImages: [],
    shortName: (p.name || '').slice(0, 40),
    shortDescription: (p.description || '').slice(0, 120),
    weight: 0,
    costPrice: String(p.price || '').replace(/[^\d.]/g, ''),
    stock: 100,
    coverImage: images[0] || '',
    displayType: 'grid',
    settings: {
      skipCart: false, allowBackorder: false, hideRelated: false,
      strictOptions: false, customThankYou: false, thankYouText: '',
    },
    shipping: {
      freeShipping: false, freeShippingPickupOnly: false, customShipping: false,
      customShippingPrice: 0.0, customShippingPickup: false, customShippingPickupPrice: 0.0,
    },
    variants: [], secondaryOptions: [], offers: [], reviews: [],
    videoUrl: '', videoType: '', videoThumbnail: '', showVideoInFeed: false,
    rating: 4.5,
    _source: { store: store.name, url: p.url || '', sourceId: String(p.sourceId || '') },
  };
}

module.exports = { toNabda, NABDA_CATEGORIES, guessCategory, slugify };
