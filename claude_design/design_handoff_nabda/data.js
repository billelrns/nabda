// Nabda — realistic data (Algerian Arabic, DZD)

window.NABDA_DATA = {
  user: {
    name: 'سارة',
    week: 25,
    dueDate: '15 سبتمبر 2026',
  },

  // Week info — sizes / facts indexed by week
  weekInfo: {
    25: {
      size: 'حجم القرنبيط',
      sizeIcon: '🥦',
      lengthCm: 34.6,
      weightG: 660,
      desc: 'جنينك الآن في حجم رأس قرنبيط متوسط. بدأ يستجيب للأصوات ويتعرّف على صوتك.',
      milestone: 'يمكنه فتح وغلق عينيه',
    },
    12: { size: 'حجم الليمونة', sizeIcon: '🍋', lengthCm: 5.4, weightG: 14, desc: 'كل أعضاء جنينك تكوّنت ويبدأ في تحريك أصابعه.', milestone: 'بدء تكوّن الأظافر' },
    20: { size: 'حجم الموزة', sizeIcon: '🍌', lengthCm: 25.6, weightG: 300, desc: 'أنت في منتصف الطريق! يمكنك الآن إحساس ركلاته.', milestone: 'يسمع الأصوات' },
    30: { size: 'حجم الملفوف', sizeIcon: '🥬', lengthCm: 39.9, weightG: 1320, desc: 'دماغ جنينك ينمو بسرعة كبيرة وأصبح يميّز بين النور والظلام.', milestone: 'يتنفّس بشكل منتظم' },
    36: { size: 'حجم البطيخة الصغيرة', sizeIcon: '🍈', lengthCm: 47.4, weightG: 2620, desc: 'جنينك جاهز تقريبًا. يكتسب وزنًا بسرعة استعدادًا للولادة.', milestone: 'استدارة الرأس للأسفل' },
  },

  // Article carousel
  articles: [
    { title: 'أهم الأطعمة الغنية بالحديد للحامل', cat: 'تغذية', read: '5 د', img: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600&q=80' },
    { title: 'تمارين كيغل: متى وكيف تبدئين؟', cat: 'رياضة', read: '4 د', img: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=600&q=80' },
    { title: 'كيف تتعاملين مع قلق ما قبل الولادة', cat: 'صحة نفسية', read: '7 د', img: 'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=600&q=80' },
    { title: 'وضعيات النوم الآمنة في الثلث الثالث', cat: 'نوم', read: '3 د', img: 'https://images.unsplash.com/photo-1455642305367-68834a9d4337?w=600&q=80' },
    { title: 'العناية بالبشرة أثناء الحمل: ما المسموح؟', cat: 'جمال', read: '6 د', img: 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=600&q=80' },
  ],

  // Categories shown on home as quick chips
  homeSections: [
    { id: 'nutrition', name: 'تغذية', icon: '🥗', color: 'teal' },
    { id: 'fitness', name: 'رياضة', icon: '🧘‍♀️', color: 'pink' },
    { id: 'mental', name: 'صحة نفسية', icon: '💆‍♀️', color: 'purple' },
    { id: 'sleep', name: 'النوم', icon: '🌙', color: 'teal' },
    { id: 'beauty', name: 'الجمال', icon: '💄', color: 'pink' },
  ],

  // Store categories — 15 of them
  storeCategories: [
    { id: 'maternity', name: 'ملابس حمل', icon: '👗' },
    { id: 'baby_clothes', name: 'لوازم رضيع', icon: '👶' },
    { id: 'feeding', name: 'الرضاعة', icon: '🍼' },
    { id: 'diapers', name: 'حفاضات', icon: '🧷' },
    { id: 'vitamins', name: 'فيتامينات', icon: '💊' },
    { id: 'birth_bag', name: 'حقيبة الولادة', icon: '👜' },
    { id: 'toys', name: 'ألعاب', icon: '🧸' },
    { id: 'skincare', name: 'العناية', icon: '🧴' },
    { id: 'strollers', name: 'عربات', icon: '🛒' },
    { id: 'beds', name: 'أسرّة وفرش', icon: '🛏️' },
    { id: 'bath', name: 'الاستحمام', icon: '🛁' },
    { id: 'pump', name: 'شفّاطات', icon: '🍶' },
    { id: 'safety', name: 'السلامة', icon: '🪪' },
    { id: 'books', name: 'كتب وقصص', icon: '📚' },
    { id: 'gifts', name: 'هدايا', icon: '🎁' },
  ],

  // Realistic products (DZ market, prices in DZD)
  products: [
    { id: 'p1', cat: 'maternity', name: 'فستان حمل صيفي قطن', price: 4500, oldPrice: 6200, rating: 4.7, reviews: 128, img: 'https://images.unsplash.com/photo-1558898479-33c0057a5d12?w=600&q=80', images: [
      'https://images.unsplash.com/photo-1558898479-33c0057a5d12?w=800&q=80',
      'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=800&q=80',
      'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=800&q=80',
    ], desc: 'فستان واسع وناعم مصنوع من القطن العضوي 100%. ينمو معك خلال شهور الحمل ويعطيك راحة كاملة في الجو الحار. متوفر بمقاسات S إلى XXL.' },
    { id: 'p2', cat: 'feeding', name: 'رضّاعة Avent زجاج 240 مل', price: 2200, oldPrice: 2800, rating: 4.9, reviews: 412, img: 'https://images.unsplash.com/photo-1515488825947-c69b40e07b9b?w=600&q=80', images: ['https://images.unsplash.com/photo-1515488825947-c69b40e07b9b?w=800&q=80'], desc: 'رضّاعة من الزجاج المقاوم للحرارة، آمنة ومضادة للمغص.' },
    { id: 'p3', cat: 'diapers', name: 'حفاضات بامبرز برميوم — 80 حبة', price: 3400, oldPrice: 3900, rating: 4.8, reviews: 1024, img: 'https://images.unsplash.com/photo-1607000975327-deea3f6f04dd?w=600&q=80', images: ['https://images.unsplash.com/photo-1607000975327-deea3f6f04dd?w=800&q=80'], desc: 'حفاضات قطنية ناعمة بامتصاص فائق لـ 12 ساعة. مقاس 3 (4–9 كغ).' },
    { id: 'p4', cat: 'vitamins', name: 'حبوب Elevit للحامل — 100 حبة', price: 5800, oldPrice: null, rating: 4.6, reviews: 256, img: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&q=80', images: ['https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800&q=80'], desc: 'مكمّل غذائي متكامل للحامل: حمض الفوليك، حديد، DHA وفيتامينات أساسية.' },
    { id: 'p5', cat: 'baby_clothes', name: 'طقم 5 قطع قطن للمولود', price: 2900, oldPrice: 3600, rating: 4.5, reviews: 89, img: 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=600&q=80', images: ['https://images.unsplash.com/photo-1522771930-78848d9293e8?w=800&q=80'], desc: 'طقم 5 قطع: 2 بيجامة، 2 بادي و قبعة. قطن ناعم 100%.' },
    { id: 'p6', cat: 'birth_bag', name: 'حقيبة ولادة جاهزة فاخرة', price: 8500, oldPrice: 11000, rating: 4.9, reviews: 67, img: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=600&q=80', images: ['https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=800&q=80'], desc: 'حقيبة جاهزة تحتوي على كل ما تحتاجينه أنت ومولودك في المستشفى.' },
    { id: 'p7', cat: 'toys', name: 'دمية تعليمية حسية للرضع', price: 1700, oldPrice: 2100, rating: 4.7, reviews: 143, img: 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=600&q=80', images: ['https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=800&q=80'], desc: 'دمية ناعمة بألوان متباينة لتحفيز الحواس البصرية واللمسية.' },
    { id: 'p8', cat: 'skincare', name: 'كريم Bio-Oil للسطور — 200 مل', price: 3200, oldPrice: 3800, rating: 4.8, reviews: 521, img: 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=600&q=80', images: ['https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=800&q=80'], desc: 'زيت متخصّص للوقاية من علامات تمدّد الجلد أثناء الحمل.' },
    { id: 'p9', cat: 'maternity', name: 'حزام دعم البطن للحامل', price: 2400, oldPrice: 3000, rating: 4.4, reviews: 76, img: 'https://images.unsplash.com/photo-1622445275576-721325763afe?w=600&q=80', images: ['https://images.unsplash.com/photo-1622445275576-721325763afe?w=800&q=80'], desc: 'حزام طبي قابل للتعديل يخفّف آلام أسفل الظهر.' },
    { id: 'p10', cat: 'feeding', name: 'شفّاطة حليب كهربائية', price: 9500, oldPrice: 12500, rating: 4.6, reviews: 198, img: 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=600&q=80', images: ['https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=800&q=80'], desc: 'شفّاطة كهربائية مزدوجة بـ 9 مستويات شفط، هادئة وسهلة الحمل.' },
    { id: 'p11', cat: 'strollers', name: 'عربة أطفال 3 في 1 قابلة للطي', price: 28000, oldPrice: 35000, rating: 4.8, reviews: 54, img: 'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?w=600&q=80', images: ['https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?w=800&q=80'], desc: 'عربة متعددة الوظائف من الولادة إلى 3 سنوات.' },
    { id: 'p12', cat: 'beds', name: 'سرير خشبي للمولود + فرشة', price: 18500, oldPrice: 22000, rating: 4.7, reviews: 41, img: 'https://images.unsplash.com/photo-1586683086022-08dde94c1a4f?w=600&q=80', images: ['https://images.unsplash.com/photo-1586683086022-08dde94c1a4f?w=800&q=80'], desc: 'سرير خشبي طبيعي مع جوانب قابلة للتعديل وفرشة طبية.' },
  ],

  // Algerian wilayas
  wilayas: ['الجزائر العاصمة', 'وهران', 'قسنطينة', 'عنابة', 'البليدة', 'سطيف', 'باتنة', 'تيزي وزو', 'بجاية', 'تلمسان', 'سيدي بلعباس', 'بسكرة', 'ورقلة', 'غرداية', 'الشلف'],

  // Admin modules
  adminModules: [
    { icon: '👩', title: 'المستخدمات', desc: 'إدارة الحسابات والملفات الشخصية' },
    { icon: '📦', title: 'الطلبات', desc: 'متابعة وتأكيد الطلبات الجديدة' },
    { icon: '🛍️', title: 'المنتجات', desc: 'إضافة وتعديل منتجات المتجر' },
    { icon: '📚', title: 'المقالات', desc: 'نشر المحتوى الصحي والمقالات' },
    { icon: '💬', title: 'الدردشة', desc: 'متابعة محادثات الذكاء الاصطناعي' },
    { icon: '🏷️', title: 'الأقسام', desc: 'تنظيم أقسام المتجر والمحتوى' },
    { icon: '💳', title: 'المدفوعات', desc: 'مراجعة المعاملات وطرق الدفع' },
    { icon: '🔔', title: 'الإشعارات', desc: 'إرسال إشعارات للمستخدمات' },
    { icon: '📊', title: 'التقارير', desc: 'إحصائيات ومؤشرات الأداء' },
  ],

  adminStats: [
    { label: 'مستخدمات نشطات', value: '12,840', delta: '+8%', icon: '👩' },
    { label: 'طلبات هذا الشهر', value: '1,247', delta: '+23%', icon: '📦' },
    { label: 'منتج في المتجر', value: '486', delta: '+12', icon: '🛍️' },
    { label: 'إيرادات الشهر', value: '4.2M دج', delta: '+15%', icon: '💰' },
  ],

  // Initial AI chat thread
  chatHistory: [
    { from: 'ai', text: 'أهلًا سارة 🌸 أنا نبضة، مرافقتك خلال رحلة الحمل. كيف أقدر أساعدك اليوم؟', time: '10:24' },
    { from: 'me', text: 'حابة أعرف هل القهوة مسموحة في الأسبوع 25؟', time: '10:25' },
    { from: 'ai', text: 'سؤال مهم 💛 يُسمح بكمية محدودة من الكافيين أثناء الحمل — حوالي 200 ملغ يوميًا، أي ما يعادل فنجان قهوة عربية متوسط أو فنجان إسبريسو واحد.\n\nمن الأفضل توزيعها على اليوم وتجنّبها قبل النوم. هل تشربينها مع الحليب عادة؟', time: '10:25' },
  ],

  chatSuggestions: [
    'ما هي أعراض الأسبوع 25؟',
    'تمارين آمنة لي الآن؟',
    'وصفة عشاء صحية',
    'متى أبدأ تجهيز حقيبة الولادة؟',
  ],
};

window.formatDZD = (n) => n.toLocaleString('ar-DZ') + ' دج';
