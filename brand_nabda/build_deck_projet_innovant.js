// العرض التفصيلي لمشروع نبضة — وفق قالب «Canevas Label Projet Innovant 2025»
const pptxgen = require('pptxgenjs');
const React = require('react');
const RDS = require('react-dom/server');
const sharp = require('sharp');
const fa = require('react-icons/fa');
const path = require('path');

const IMG = '/tmp/deck/img/';
const C = {
  teal: '00897B', tealDk: '00574F', tealLt: 'E0F2F1',
  pink: 'E91E63', pinkLt: 'FCE4EC', blush: 'FFF5F8',
  rose: 'C2185B', roseDk: '8E1450', roseMute: '9C6B80',
  ink: '2B1D2A', mute: '6B5E6A', white: 'FFFFFF', line: 'EADFE5',
};
const F = 'Almarai';
const FB = 'Almarai ExtraBold';
const BG = '/tmp/deck/bg/';
const W = 13.333, H = 7.5;

async function icon(name, color = C.white, size = 256) {
  const svg = RDS.renderToStaticMarkup(React.createElement(fa[name], { color: '#' + color, size }));
  const buf = await sharp(Buffer.from(svg)).resize(size, size).png().toBuffer();
  return 'image/png;base64,' + buf.toString('base64');
}

const lu = require('react-icons/lu');
async function badge(name, c1, c2, size = 300) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 300 300">
    <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#${c1}"/><stop offset="1" stop-color="#${c2}"/></linearGradient>
    <radialGradient id="h" cx="0.35" cy="0.3" r="0.7"><stop offset="0" stop-color="#ffffff" stop-opacity="0.45"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient></defs>
    <circle cx="150" cy="150" r="146" fill="#${c2}" opacity="0.13"/>
    <circle cx="150" cy="150" r="124" fill="#${c1}" opacity="0.18"/>
    <circle cx="150" cy="150" r="100" fill="url(#g)"/>
    <circle cx="150" cy="150" r="100" fill="url(#h)"/></svg>`;
  const ic = RDS.renderToStaticMarkup(React.createElement(lu[name], { color: '#ffffff', size: 96, strokeWidth: 2.2 }));
  const icPng = await sharp(Buffer.from(ic)).resize(96, 96).png().toBuffer();
  const buf = await sharp(Buffer.from(svg)).composite([{ input: icPng, left: 102, top: 102 }]).png().toBuffer();
  return 'image/png;base64,' + buf.toString('base64');
}
const T = (extra) => {
  const o = Object.assign({ fontFace: F, rtlMode: true, align: 'right', lang: 'ar-DZ', margin: 0, isTextBox: true, color: C.ink }, extra);
  if (o.bold) { o.fontFace = FB; o.bold = false; }
  return o;
};

(async () => {
  const pres = new pptxgen();
  pres.layout = 'LAYOUT_WIDE';
  pres.title = 'نبضة — العرض التفصيلي للمشروع المبتكر';
  pres.author = 'Billel NOUI';
  pres.rtlMode = true;

  const I = {};
  for (const n of ['FaHeart','FaCalendarAlt','FaBaby','FaBookOpen','FaMosque','FaUsers','FaShoppingBag','FaMagic','FaShieldAlt','FaClock','FaCoins','FaLanguage','FaStore','FaHandsHelping','FaUser','FaEnvelope','FaPhoneAlt','FaGlobe','FaIdBadge','FaExclamationTriangle','FaLightbulb','FaChartLine','FaLink','FaCertificate','FaCopyright','FaCode','FaRocket','FaFlag','FaBullseye','FaSeedling','FaUserPlus','FaFemale','FaAndroid','FaTruck','FaBullhorn','FaCrown','FaHandshake','FaServer','FaTag','FaGraduationCap','FaBriefcase','FaMobileAlt','FaStar','FaCheckCircle','FaCut','FaBirthdayCake','FaRobot','FaLayerGroup','FaUserFriends','FaYoutube','FaGoogleDrive','FaUserCheck']) {
    I[n] = await icon(n);
  }

  // دائرة أيقونة (الموتيف المتكرّر)
  const dot = (s, name, x, y, d = 0.62, fill = C.teal) => {
    s.addShape(pres.shapes.OVAL, { x, y, w: d, h: d, fill: { color: fill }, line: { color: fill } });
    const p = d * 0.26;
    s.addImage({ data: I[name], x: x + p, y: y + p, w: d - 2 * p, h: d - 2 * p });
  };

  // ترويسة الشرائح الداخلية: رقم القسم + العنوان + التعليمة
  // عدد شرائح كل قسم: يُظهر «1/3» تحت رقم القسم حتى لا تبدو الشرائح مكرّرة
  const PARTS = { '01': 2, '04': 3, '05': 3, '06': 3, '09': 3, '10': 4, '11': 3 };
  const seen = {};
  const header = (s, num, title, hint) => {
    s.background = { path: BG + 'content.jpg' };
    seen[num] = (seen[num] || 0) + 1;
    s.slideNumber = { x: W - 1.1, y: H - 0.6, w: 0.55, h: 0.34, fontFace: F, fontSize: 10, color: C.mute, align: 'right' };
    s.addShape(pres.shapes.OVAL, { x: W - 1.35, y: 0.42, w: 0.85, h: 0.85, fill: { color: C.pink }, line: { color: 'FFFFFF', width: 2.5 }, shadow: { type: 'outer', color: 'E91E63', opacity: 0.25, blur: 8, offset: 2, angle: 90 } });
    if (PARTS[num]) {
      s.addText(num, T({ x: W - 1.35, y: 0.5, w: 0.85, h: 0.42, align: 'center', valign: 'middle', fontSize: 20, bold: true, color: C.white, rtlMode: false }));
      s.addText(seen[num] + '/' + PARTS[num], T({ x: W - 1.35, y: 0.9, w: 0.85, h: 0.26, align: 'center', valign: 'middle', fontSize: 10, bold: true, color: 'FFE3EE', rtlMode: false }));
    } else {
      s.addText(num, T({ x: W - 1.35, y: 0.42, w: 0.85, h: 0.85, align: 'center', valign: 'middle', fontSize: 22, bold: true, color: C.white, rtlMode: false }));
    }
    s.addText(title, T({ x: 0.6, y: 0.4, w: W - 2.15, h: 0.6, fontSize: 30, bold: true, color: C.rose, valign: 'middle' }));
    if (hint) s.addText(hint, T({ x: 0.6, y: 1.0, w: W - 2.15, h: 0.36, fontSize: 13, color: C.roseMute, valign: 'middle' }));
    // تذييل خفيف
    s.addImage({ path: IMG + 'logo.png', x: 0.55, y: H - 0.6, w: 0.34, h: 0.34 });
    s.addText('نبضة | Nabda  ·  طلب علامة «مشروع مبتكر»', T({ x: 0.95, y: H - 0.6, w: 5, h: 0.34, fontSize: 10, color: C.mute, align: 'left', valign: 'middle' }));
  };

  const CARD = { [C.blush]: ['FFFFFF', 'F6D3E1'], [C.pinkLt]: ['FDEBF2', 'F4C2D5'], [C.tealLt]: ['EDF8F6', 'C7E7E2'] };
  const card = (s, x, y, w, h, fill = C.blush) => {
    const [f, l] = CARD[fill] || [fill, fill];
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, fill: { color: f, transparency: 6 }, line: { color: l, width: 1 }, rectRadius: 0.18,
      shadow: { type: 'outer', color: 'C2185B', opacity: 0.10, blur: 10, offset: 3, angle: 90 } });
  };

  // ═════════ 1. الغلاف ═════════
  {
    const s = pres.addSlide(); s.background = { path: BG + 'cover.jpg' };
    s.addText('وزارة اقتصاد المعرفة والمؤسسات الناشئة والمؤسسات المصغّرة', T({ x: 4.3, y: 0.55, w: 6.5, h: 0.4, fontSize: 13, color: C.roseMute }));
    s.addText('PITCH DECK', T({ x: 4.3, y: 1.35, w: 6.5, h: 0.5, fontSize: 18, bold: true, color: 'F06292', rtlMode: false, align: 'right', charSpacing: 4 }));
    s.addText('العرض التفصيلي\nللمشروع المبتكر', T({ x: 4.3, y: 1.85, w: 6.5, h: 1.75, fontSize: 44, lineSpacingMultiple: 1.0, bold: true, color: C.rose }));
    s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 4.6, y: 4.1, w: 6.2, h: 1.6, fill: { color: C.white, transparency: 4 }, line: { color: 'F6D3E1', width: 1 }, rectRadius: 0.25,
      shadow: { type: 'outer', color: 'C2185B', opacity: 0.18, blur: 14, offset: 4, angle: 90 } });
    s.addImage({ path: IMG + 'logo.png', x: 9.3, y: 4.25, w: 1.3, h: 1.3 });
    s.addText('نبضة | Nabda', T({ x: 4.85, y: 4.27, w: 4.3, h: 0.65, fontSize: 30, bold: true, color: C.pink }));
    s.addText('رفيقتكِ في رحلة الأنوثة والأمومة، خطوةً بخطوة، ونبضةً بنبضة.', T({ x: 4.85, y: 4.95, w: 4.3, h: 0.6, fontSize: 13, color: C.ink }));
    s.addText('اللجنة الوطنية لمنح علامات «مشروع مبتكر» و«مؤسسة ناشئة» و«حاضنة»', T({ x: 4.3, y: 6.6, w: 6.5, h: 0.4, fontSize: 12, color: C.roseMute }));
  }

  // ═════════ 2. تقديم عام ═════════
  {
    const s = pres.addSlide(); header(s, '01', 'تقديم عام للمشروع المبتكر', null);
    const rows = [
      ['FaIdBadge', 'عنوان المشروع', 'نبضة | Nabda — تطبيق جوّال ومنصة ويب لصحة المرأة والأم ورعاية الطفل'],
      ['FaHeart', 'شعار المشروع', 'قلبان متداخلان: قلب للأم وقلب لطفلها (الشعار الرسمي على اليسار)'],
      ['FaStar', 'الشعار اللفظي', '«نبضة — رفيقتكِ في رحلة الأنوثة والأمومة، خطوةً بخطوة، ونبضةً بنبضة.»'],
      ['FaTag', 'القطاع', 'الصحة الرقمية (E-Health) · تقنيات صحة المرأة (FemTech)'],
    ];
    rows.forEach(([ic, k, v], i) => {
      const y = 1.7 + i * 1.22;
      dot(s, ic, W - 1.35, y + 0.05);
      s.addText(k, T({ x: 5.0, y, w: 6.8, h: 0.4, fontSize: 18, bold: true, color: C.teal }));
      s.addText(v, T({ x: 5.0, y: y + 0.42, w: 6.8, h: 0.6, fontSize: 15, color: C.ink }));
    });
    card(s, 0.6, 1.6, 3.9, 4.9, C.blush);
    s.addImage({ path: IMG + 'logo.png', x: 1.3, y: 2.0, w: 2.5, h: 2.5 });
    s.addText('نبضة', T({ x: 0.6, y: 4.65, w: 3.9, h: 0.7, fontSize: 36, bold: true, color: C.pink, align: 'center' }));
    s.addText('Nabda', T({ x: 0.6, y: 5.35, w: 3.9, h: 0.45, fontSize: 18, color: C.teal, align: 'center', rtlMode: false }));
  }

  // ═════════ 3. معلومات الاتصال ═════════
  {
    const s = pres.addSlide(); header(s, '01', 'معلومات الاتصال', null);
    card(s, 4.4, 1.45, 8.3, 5.3, C.blush);
    const rows = [
      ['FaUser', 'اسم المسؤول', 'بلال نوي — Billel NOUI'],
      ['FaBriefcase', 'الصفة', 'المؤسس والمطوّر الرئيسي لمشروع نبضة'],
      ['FaEnvelope', 'البريد الإلكتروني', 'billelnoui19@gmail.com'],
      ['FaPhoneAlt', 'رقم الهاتف', '0661 35 38 28'],
      ['FaGlobe', 'الموقع الإلكتروني', 'https://nabda.online', 'https://nabda.online'],
      ['FaEnvelope', 'بريد المشروع', 'info@nabda.online'],
      ['FaYoutube', 'فيديو عرض التطبيق (YouTube)', 'https://youtu.be/xSc8cw9gDQQ', 'https://youtu.be/xSc8cw9gDQQ'],
      ['FaGoogleDrive', 'ملفات المشروع (Google Drive)', 'drive.google.com/…/1GLVYFSFjMiXSNUbOR39YEG8S6rBSW-kD', 'https://drive.google.com/drive/folders/1GLVYFSFjMiXSNUbOR39YEG8S6rBSW-kD?usp=sharing'],
      ['FaUserCheck', 'حساب تجريبي للتطبيق', 'test@nabda.online  ·  test+123'],
    ];
    rows.forEach(([ic, k, v, url], i) => {
      const y = 1.6 + i * 0.57;
      dot(s, ic, 11.85, y, 0.46);
      s.addText(k, T({ x: 8.25, y, w: 3.45, h: 0.46, fontSize: 13.5, bold: true, color: C.teal, valign: 'middle' }));
      const ltr = /^[A-Za-z0-9h]/.test(v) && !/[؀-ۿ]/.test(v);
      s.addText([{ text: v, options: url ? { hyperlink: { url } } : {} }], T({ x: 4.6, y, w: 3.6, h: 0.46, fontSize: v.length > 40 ? 8.5 : 13.5, color: C.ink, valign: 'middle', align: 'right', rtlMode: !ltr }));
    });
    s.addImage({ path: IMG + 'home_articles.png', x: 0.9, y: 1.45, w: 2.6, h: 5.35, sizing: { type: 'contain', w: 2.6, h: 5.35 } });
  }

  // ═════════ 4. ملخّص المشروع ═════════
  {
    const s = pres.addSlide();
    header(s, '02', 'ملخّص المشروع', 'الإشكالية المعالَجة، والحل المقدَّم، والأثر المنتظر');
    const B = {
      p: await badge('LuPuzzle', 'F06292', 'C2185B'),
      s: await badge('LuLightbulb', '26A69A', '00695C'),
      i: await badge('LuSprout', 'FFB74D', 'E65100'),
      ai: await icon('FaMagic', C.white, 128),
    };
    const cols = [
      [B.p, 'الإشكالية', 'C2185B', 'معلومة مغلوطة وتشتّت وغياب حلّ عربي', [
        'معلومات مغلوطة قد تهدّد حياة الأم والجنين والرضيع',
        'تطبيقات مترجمة لا تراعي ثقافتها ولا دينها',
        'مجموعات فيسبوك بلا تدقيق للمعلومة',
        'متاجر لا تعرف مرحلتها ولا توقيت حاجتها',
        'لا حلّ عربي واحد يرافقها في كل مراحلها',
      ]],
      [B.s, 'الحل', '00796B', 'منظومة عربية واحدة متكاملة', [
        'تطبيق جوّال ومنصة ويب بالعربية',
        'الدورة والحمل ورعاية الطفل في مكان واحد',
        'مكتبة تثقيفية وفقه المرأة',
        'مجتمع خاص بالحوامل والأمهات، مع نوادي أشهر الولادة',
        'متجر محلي بالدفع عند الاستلام',
        'مساعدة ذكية مدعومة بالذكاء الاصطناعي',
      ]],
      [B.i, 'الأثر المنتظر', 'E65100', 'وعيٌ أكبر، ووقتٌ أقل، واقتصادٌ محلي', [
        'معلومة موثوقة ومبسّطة بلغة الأم بدل الإشاعات',
        'وقت وجهد أقل في البحث والشراء',
        'حماية البيانات الشخصية',
        'دعم التجارة الإلكترونية والتوصيل إلى الولايات',
        'فرص عمل رقمية وحرفية للنساء',
      ]],
    ];
    cols.forEach(([bd, t, col, sub, items], i) => {
      const cw = 3.95, x = W - 0.6 - (i + 1) * cw - i * 0.125, y0 = 1.6, ch = 5.0;
      card(s, x, y0, cw, ch, C.blush);
      s.addShape(pres.shapes.RECTANGLE, { x: x + 0.9, y: y0, w: cw - 1.8, h: 0.07, fill: { color: col }, line: { color: col, width: 0 } });
      s.addImage({ data: bd, x: x + cw / 2 - 0.62, y: y0 + 0.22, w: 1.24, h: 1.24 });
      s.addText(t, T({ x: x + 0.2, y: y0 + 1.5, w: cw - 0.4, h: 0.5, fontSize: 24, bold: true, color: col, align: 'center', valign: 'middle' }));
      s.addText(sub, T({ x: x + 0.2, y: y0 + 1.98, w: cw - 0.4, h: 0.36, fontSize: 13, color: C.roseMute, align: 'center', valign: 'middle' }));
      s.addShape(pres.shapes.LINE, { x: x + 1.2, y: y0 + 2.45, w: cw - 2.4, h: 0, line: { color: 'F2D7E3', width: 1 } });
      s.addText(items.map((p, k) => ({ text: '\u202B◂  ' + p + '\u202C', options: { breakLine: k < items.length - 1, paraSpaceAfter: 7 } })),
        T({ x: x + 0.3, y: y0 + 2.6, w: cw - 0.55, h: 2.25, fontSize: 13.5, color: C.ink, valign: 'top', lineSpacingMultiple: 1.05 }));
    });
  }

  // ═════════ 5. الفريق ═════════
  {
    const s = pres.addSlide();
    header(s, '03', 'الفريق', 'تقديم الأعضاء: الاسم واللقب والملمح · الكفاءات الخاصة والدور في المشروع');
    s.background = { path: BG + 'team.jpg' };
    const TR = 30;
    const tcard = (x, y, w, h, f = 'FFFFFF', l = 'F6D3E1') =>
      s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, fill: { color: f, transparency: TR }, line: { color: l, width: 1 }, rectRadius: 0.18,
        shadow: { type: 'outer', color: '6D2A45', opacity: 0.15, blur: 12, offset: 3, angle: 90 } });
    const label = (x, w, t, col) => {
      s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: x + w - 3.2, y: 1.5, w: 3.2, h: 0.42, fill: { color: col }, line: { color: 'FFFFFF', width: 1.5 }, rectRadius: 0.21 });
      s.addText(t, T({ x: x + w - 3.2, y: 1.5, w: 3.2, h: 0.42, fontSize: 13.5, bold: true, color: C.white, align: 'center', valign: 'middle' }));
    };
    // ── القسم الأول: الفريق الحالي (يمين)
    const RX = 8.05, RW = 4.65;
    label(RX, RW, 'الفريق الحالي', 'C2185B');
    tcard(RX, 2.05, RW, 2.45);
    s.addImage({ data: await badge('LuCodeXml', '26A69A', '00695C'), x: RX + RW - 0.95, y: 2.18, w: 0.8, h: 0.8 });
    s.addText('بلال نوي', T({ x: RX + 0.2, y: 2.2, w: RW - 1.25, h: 0.42, fontSize: 20, bold: true }));
    s.addText('المؤسس والمطوّر الرئيسي · منذ 2020', T({ x: RX + 0.2, y: 2.62, w: RW - 1.25, h: 0.32, fontSize: 12.5, bold: true, color: C.pink }));
    const cv = ['مهندس دولة في شركة سوناطراك مع 12 سنة خبرة في المجال', 'مطوّر تطبيقات بتقنية Flutter و Firebase', 'يتولّى التصميم والتطوير وإدارة المشروع'];
    s.addText(cv.map((p, i) => ({ text: '\u202B• ' + p + '\u202C', options: { breakLine: i < cv.length - 1, paraSpaceAfter: 3 } })),
      T({ x: RX + 0.2, y: 3.05, w: RW - 0.4, h: 1.38, fontSize: 12.5, valign: 'top' }));
    tcard(RX, 4.65, RW, 1.95, 'FDEBF2', 'F4C2D5');
    s.addImage({ data: await badge('LuHeartHandshake', 'F06292', 'C2185B'), x: RX + RW - 0.95, y: 4.78, w: 0.8, h: 0.8 });
    s.addText('مراجِعة تجربة المستخدم والمحتوى', T({ x: RX + 0.2, y: 4.8, w: RW - 1.25, h: 0.42, fontSize: 16, bold: true }));
    s.addText('UX & Content Reviewer · (زوجة المؤسس)', T({ x: RX + 0.2, y: 5.2, w: RW - 1.25, h: 0.5, fontSize: 11.5, bold: true, color: C.pink, valign: 'top' }));
    s.addText('تختبر التطبيق من منظور المستخدمة وتقترح الأقسام والخصائص الناقصة.', T({ x: RX + 0.2, y: 5.85, w: RW - 0.4, h: 0.65, fontSize: 12, valign: 'top' }));
    // ── القسم الثاني: الكفاءات المطلوبة (يسار — أكبر)
    const LX = 0.6, LW = 7.2;
    label(LX, LW, 'كفاءات نسعى إلى استقطابها', '00796B');
    const roles = [
      ['LuMegaphone', 'التسويق الرقمي والمجتمع', 'حملات فيسبوك وتيك توك وإدارة مجتمع الأمهات'],
      ['LuPalette', 'تصميم المحتوى المرئي', 'فيديوهات ومنشورات وتصاميم للتطبيق'],
      ['LuStethoscope', 'أطباء وقابلات متعاقدون', 'مراجعة المحتوى ومرافقة الأمهات (مرحلة قادمة)'],
      ['LuTruck', 'العمليات: المتجر والتوصيل', 'الموردون والطلبيات والتوصيل إلى الولايات'],
    ];
    const cw = (LW - 0.15) / 2;
    for (let i = 0; i < roles.length; i++) {
      const [ic, t, d] = roles[i];
      const c = i % 2, r = Math.floor(i / 2);
      const x = LX + LW - (c + 1) * cw - c * 0.15, y = 2.05 + r * 1.32;
      tcard(x, y, cw, 1.2, 'FFFFFF', 'C7E7E2');
      s.addImage({ data: await badge(ic, '26A69A', '00695C'), x: x + cw - 0.85, y: y + 0.2, w: 0.72, h: 0.72 });
      s.addText(t, T({ x: x + 0.15, y: y + 0.14, w: cw - 1.05, h: 0.45, fontSize: 13.5, bold: true, color: C.tealDk, valign: 'middle' }));
      s.addText(d, T({ x: x + 0.15, y: y + 0.6, w: cw - 1.05, h: 0.5, fontSize: 11.5, valign: 'top' }));
    }
    tcard(LX, 4.75, LW, 1.85, 'FDEBF2', 'F4C2D5');
    s.addImage({ data: await badge('LuScissors', 'F06292', 'C2185B'), x: LX + LW - 0.95, y: 4.9, w: 0.75, h: 0.75 });
    s.addImage({ data: await badge('LuCakeSlice', 'FFB74D', 'E65100'), x: LX + LW - 0.95, y: 5.7, w: 0.75, h: 0.75 });
    s.addText('مرحلة لاحقة: شبكة حرفيّات في كل ولاية', T({ x: LX + 0.25, y: 4.9, w: LW - 1.4, h: 0.45, fontSize: 15, bold: true, color: 'C2185B', valign: 'middle' }));
    s.addText('تشغيل خيّاطات لصنع ملابس الحمل والرضّع، وصانعات للحلويات التقليدية، في كل ولاية: إنتاجٌ محلي أقرب إلى الزبونة، وفرصُ عمل للنساء في بيوتهن ومدنهن.',
      T({ x: LX + 0.25, y: 5.4, w: LW - 1.4, h: 1.1, fontSize: 13, valign: 'top' }));
  }

  // ═════════ 6. الإشكالية (1/2) ═════════
  {
    const s = pres.addSlide();
    header(s, '04', 'الإشكالية المستهدفة', 'ما هي المشكلة التي حدّدناها؟ ولماذا هي حقيقية وكبيرة؟');
    // ① الآلام الثلاثة
    const pains = [
      ['LuLayoutGrid', 'تشتّت الأدوات', 'تضطر المرأة إلى عدة تطبيقات منفصلة: للدورة، وللحمل، ولنمو الطفل، وللجانب الديني وفقه المرأة. نبضة تجمع كل ذلك في مكان واحد'],
      ['LuBookX', 'محتوى غير موثوق ولا مكيّف ثقافياً', 'أغلب التطبيقات الاحترافية أجنبية، والعربية منها تفتقر إلى الشمول ولا تراعي الجانب الثقافي والديني، مثل فقه المرأة في الحيض والنفاس'],
      ['LuCalendarX', 'القلق ونقص التوجيه', 'الأم الجديدة تتابع وحدها مواعيد التطعيمات ومراحل نمو طفلها، وتبحث عن إجابات سريعة في منتديات عشوائية'],
      ['LuUsersRound', 'لا فضاء خاص يجمعهن', 'الحوامل والأمهات العربيات لا يجدن مكاناً خاصاً بهن للتعارف وتبادل الخبرات. نبضة توفّر لهن ملتقى آمناً ونوادي حسب شهر الولادة'],
    ];
    for (let i = 0; i < pains.length; i++) {
      const [ic, t, d] = pains[i];
      const cw = 2.93, x = W - 0.6 - (i + 1) * cw - i * 0.12, y = 1.55;
      card(s, x, y, cw, 2.25, i % 2 ? C.pinkLt : C.blush);
      s.addImage({ data: await badge(ic, 'F06292', 'C2185B'), x: x + cw - 0.82, y: y + 0.14, w: 0.68, h: 0.68 });
      s.addText(t, T({ x: x + 0.15, y: y + 0.14, w: cw - 0.98, h: 0.68, fontSize: 13.5, bold: true, color: 'C2185B', valign: 'middle' }));
      s.addText(d, T({ x: x + 0.15, y: y + 0.88, w: cw - 0.3, h: 1.32, fontSize: 11, valign: 'top', lineSpacingMultiple: 1.05 }));
    }
    // ② أرقام تثبت المشكلة
    const data = [
      ['3 تطبيقات', 'تحمّلها الحامل في المتوسط للحمل وحده', 'JMIR 2021'],
      ['أكثر من 100 مليون', 'امرأة عربية في سن الإنجاب', 'UNFPA'],
      ['78٪', 'نسبة تبنّي الهواتف الذكية في الشرق الأوسط وشمال أفريقيا', 'GSMA 2024'],
    ];
    data.forEach(([n, l, src], i) => {
      const cw = 2.38, x = W - 0.6 - (i + 1) * cw - i * 0.12, y = 3.95;
      card(s, x, y, cw, 2.65, i === 0 ? C.pinkLt : C.tealLt);
      s.addText(n, T({ x: x + 0.1, y: y + 0.25, w: cw - 0.2, h: 0.75, fontSize: n.length > 10 ? 18 : 28, bold: true, color: i === 0 ? 'C2185B' : C.teal, align: 'center', valign: 'middle' }));
      s.addText(l, T({ x: x + 0.15, y: y + 1.05, w: cw - 0.3, h: 1.0, fontSize: 12.5, align: 'center', valign: 'top' }));
      s.addText(src, T({ x: x + 0.15, y: y + 2.2, w: cw - 0.3, h: 0.3, fontSize: 9.5, color: C.mute, align: 'center', rtlMode: false }));
    });
    // ③ الفجوة: رسمان دائريان
    card(s, 0.6, 3.95, 4.55, 2.65, C.blush);
    s.addText('فجوة المحتوى العربي', T({ x: 0.8, y: 4.02, w: 4.15, h: 0.36, fontSize: 13.5, bold: true, color: 'C2185B', align: 'center' }));
    const pie = (x, val, col, cap) => {
      s.addChart(pres.charts.DOUGHNUT, [{ name: cap, labels: ['', ''], values: [val, 100 - val] }], {
        x, y: 4.35, w: 2.1, h: 1.6, holeSize: 62, chartColors: [col, 'EADFE5'], showLegend: false, showValue: false, showPercent: false, showLabel: false, dataBorder: { pt: 0.5, color: 'FFFFFF' } });
      s.addText(val + '٪', T({ x: x + 0.55, y: 4.93, w: 1.0, h: 0.42, fontSize: 15, bold: true, color: col, align: 'center', valign: 'middle', rtlMode: false }));
      s.addText(cap, T({ x: x - 0.05, y: 5.95, w: 2.2, h: 0.5, fontSize: 10.5, align: 'center', valign: 'top' }));
    };
    pie(2.95, 6, C.teal, 'نسبة العرب من سكان العالم');
    pie(0.75, 0.6, 'E91E63', 'نسبة مواقع الويب بالعربية');
    s.addText('المصادر: JMIR mHealth 2021 · UNFPA الدول العربية · GSMA «Mobile Economy MENA 2024» · البنك الدولي · W3Techs (أكتوبر 2026)', T({ x: 0.6, y: 6.66, w: 12.1, h: 0.3, fontSize: 9, color: C.mute }));
  }

  // ═════════ 6-أ. الإشكالية الأخطر: المعلومة المغلوطة ═════════
  {
    const s = pres.addSlide();
    header(s, '04', 'الإشكالية الأخطر: معلومة مغلوطة قد تكلّف حياة', 'لماذا أُنشئت نبضة؟ لأن الخطأ في المعلومة الصحية قد يمسّ حياة الأم والجنين والرضيع');
    // السرد (يمين)
    const PX = 7.75, PW = 4.95;
    card(s, PX, 1.55, PW, 5.05, C.pinkLt);
    s.addImage({ data: await badge('LuTriangleAlert', 'F06292', 'C2185B'), x: PX + PW - 0.92, y: 1.66, w: 0.78, h: 0.78 });
    s.addText('لماذا أُنشئت نبضة؟', T({ x: PX + 0.2, y: 1.66, w: PW - 1.25, h: 0.34, fontSize: 12, bold: true, color: C.roseMute }));
    s.addText('نصيحة خاطئة واحدة قد تكلّف حياة', T({ x: PX + 0.2, y: 1.98, w: PW - 1.25, h: 0.42, fontSize: 15.5, bold: true, color: 'C2185B' }));
    const B_ = (t) => ({ text: t, options: { fontFace: FB, color: C.tealDk } });
    const N_ = (t, br) => ({ text: t, options: br ? { breakLine: true, paraSpaceAfter: 8 } : {} });
    s.addText([
      B_('في مجموعات فيسبوك والمنتديات '), N_('تتداول الأمهات نصائح غير مدقّقة: وصفات شعبية، وتهوين من أعراض خطيرة، وتأجيل لزيارة الطبيب أو القابلة', true),
      B_('وقد يؤخّر ذلك '), N_('طلب الرعاية في الوقت المناسب، فتتحوّل حالة يمكن تداركها إلى خطر على حياة الأم أو الجنين أو الرضيع', true),
      B_('لهذا أُنشئت نبضة: '), N_('مرجعٌ عربي موثوق يضع المعلومة الصحيحة بين يدي الأم، ويوجّهها دائماً إلى المختصّين عند أي علامة خطر', false),
    ], T({ x: PX + 0.25, y: 2.6, w: PW - 0.5, h: 3.35, fontSize: 14, valign: 'top', lineSpacingMultiple: 1.15 }));
    s.addShape(pres.shapes.LINE, { x: PX + 0.8, y: 6.02, w: PW - 1.6, h: 0, line: { color: 'F4C2D5', width: 1 } });
    s.addText('هدفنا: ألّا تبقى أي أم وحدها أمام معلومة خاطئة', T({ x: PX + 0.2, y: 6.05, w: PW - 0.4, h: 0.5, fontSize: 12.5, bold: true, color: 'C2185B', align: 'center', valign: 'middle' }));
    // الأرقام (يسار): شبكة 2×2
    const stats = [
      ['62', 'وفاة أمومية لكل 100 ألف ولادة حيّة في الجزائر (2023)، أي نحو 500 أمّ سنوياً*', 'WHO · البنك الدولي', 'C2185B', C.pinkLt],
      ['15 من كل 1000', 'مولود حيّ في الجزائر يموتون في شهرهم الأول (2023)، أي نحو 12 ألف مولود سنوياً*', 'UN IGME', 'C2185B', C.blush],
      ['80٪', 'من الحوامل في دراسة تركية قلن إن معلومات مواقع التواصل أثّرت في قراراتهن، و33٪ يصدّقنها دائماً دون تحقّق', 'مراجعة علمية · PMC 2025', C.teal, C.tealLt],
      ['أغلبها يمكن تفاديه', 'نحو 260 ألف وفاة أمومية في العالم سنة 2023، أي وفاة كل دقيقتين تقريباً', 'منظمة الصحة العالمية 2025', C.tealDk, C.tealLt],
    ];
    const GX = 0.6, GW = 6.95, gcw = (GW - 0.15) / 2, gch = 1.88;
    stats.forEach(([n, l, src, col, bg], i) => {
      const c = i % 2, r = Math.floor(i / 2);
      const x = GX + GW - (c + 1) * gcw - c * 0.15, y = 1.55 + r * (gch + 0.12);
      card(s, x, y, gcw, gch, bg);
      s.addText(n, T({ x: x + 0.2, y: y + 0.12, w: gcw - 0.4, h: 0.55, fontSize: n.length > 6 ? 20 : 28, bold: true, color: col, valign: 'middle' }));
      s.addText(l, T({ x: x + 0.2, y: y + 0.7, w: gcw - 0.4, h: 0.85, fontSize: 11.5, valign: 'top' }));
      s.addText(src, T({ x: x + 0.2, y: y + 1.55, w: gcw - 0.4, h: 0.26, fontSize: 9, color: C.mute }));
    });
    // ردّ نبضة
    card(s, GX, 5.55, GW, 1.05, C.tealLt);
    dot(s, 'FaShieldAlt', GX + GW - 0.8, 5.75, 0.62, C.teal);
    s.addText([
      { text: 'ردّ نبضة', options: { fontFace: FB, color: C.tealDk, fontSize: 14.5, breakLine: true } },
      { text: 'معلومة موثوقة ومبسّطة · توجيه فوري إلى الطبيب أو القابلة · شبكة أطباء وقابلات متعاقدين لمراجعة المحتوى (مرحلة قادمة)' },
    ], T({ x: GX + 0.2, y: 5.6, w: GW - 1.15, h: 0.95, fontSize: 12, valign: 'middle' }));
    s.addText('* تقدير محسوب على أساس نحو 825 ألف ولادة سنوياً. الأرقام تبيّن حجم الخطر ولا تعني أن كل الوفيات سببها المعلومة المغلوطة. المصادر: WHO «Maternal mortality» 2025 · البنك الدولي · UN IGME 2024 · PMC12443360',
      T({ x: 0.6, y: 6.66, w: 12.1, h: 0.3, fontSize: 9, color: C.mute }));
  }

  // ═════════ 6-ب. الإشكالية (2/2): الحالة ورحلة المستخدمة ═════════
  {
    const s = pres.addSlide();
    header(s, '04', 'الإشكالية: حالة واقعية ورحلة المستخدمة', 'من تجربة حقيقية ومعاناة يومية… إلى رحلتها مع نبضة');
    // دراسة الحالة
    const PX = 7.75, PW = 4.95;
    card(s, PX, 1.55, PW, 5.05, C.pinkLt);
    s.addImage({ data: await badge('LuBaby', 'F06292', 'C2185B'), x: PX + PW - 0.92, y: 1.66, w: 0.78, h: 0.78 });
    s.addText('دراسة حالة حقيقية', T({ x: PX + 0.2, y: 1.66, w: PW - 1.25, h: 0.34, fontSize: 12, bold: true, color: C.roseMute }));
    s.addText('معاناة زوجتي: من الدورة إلى الولادة', T({ x: PX + 0.2, y: 1.98, w: PW - 1.25, h: 0.42, fontSize: 15.5, bold: true, color: 'C2185B' }));
    const B_ = (t) => ({ text: t, options: { fontFace: FB, color: C.tealDk } });
    const N_ = (t, br) => ({ text: t, options: br ? { breakLine: true, paraSpaceAfter: 7 } : {} });
    s.addText([
      B_('بدأت رحلتها '), N_('بتتبّعٍ غير دقيق لدورتها عبر تطبيقات أجنبية مترجمة، لا تجد فيها محتوى جزائرياً يشبهها', true),
      B_('ولمّا حملت، '), N_('احتاجت تطبيقاً للحمل وآخر للأسماء، وبحثت وحدها عن أحكام الطهارة والنفاس، دون أي توجيه ديني أو فقهي', true),
      B_('وبعد الولادة، '), N_('لم تجد إشعارات تذكّرها بالتطعيمات، فنسيت موعد تطعيم طفلها', true),
      B_('وفي كل هذه المراحل، '), N_('لم تجد مكاناً يجمعها بأمهات يعشن المرحلة نفسها لتتبادل معهن الخبرة', false),
    ], T({ x: PX + 0.25, y: 2.6, w: PW - 0.5, h: 3.35, fontSize: 14, valign: 'top', lineSpacingMultiple: 1.15 }));
    s.addShape(pres.shapes.LINE, { x: PX + 0.8, y: 6.02, w: PW - 1.6, h: 0, line: { color: 'F4C2D5', width: 1 } });
    s.addText('تجربتها ليست استثناءً: إنها يوميات آلاف الأمهات الجزائريات والعربيات', T({ x: PX + 0.2, y: 6.05, w: PW - 0.4, h: 0.5, fontSize: 12, bold: true, color: 'C2185B', align: 'center', valign: 'middle' }));
    // الإنفوغرافيك: قبل / بعد
    const row = async (y, title, col, bg, items, grad) => {
      card(s, 0.6, y, 6.95, 2.4, bg);
      s.addText(title, T({ x: 0.8, y: y + 0.1, w: 6.55, h: 0.4, fontSize: 15, bold: true, color: col }));
      const sw = 1.6, gap = 0.08;
      for (let i = 0; i < items.length; i++) {
        const [ic, t] = items[i];
        const x = 7.38 - (i + 1) * sw - i * gap;
        s.addImage({ data: await badge(ic, grad[0], grad[1]), x: x + sw / 2 - 0.4, y: y + 0.62, w: 0.8, h: 0.8 });
        s.addText(t, T({ x, y: y + 1.5, w: sw, h: 0.8, fontSize: 12, bold: true, align: 'center', valign: 'top' }));
      }
    };
    await row(1.55, 'معاناتها سابقاً مع التطبيقات الأخرى: فوضى وتشتّت', 'C2185B', C.blush, [
      ['LuLayoutGrid', '4 تطبيقات مختلفة'], ['LuSearch', 'بحث عشوائي في جوجل والمنتديات'], ['LuCalendarX', 'نسيان المواعيد'], ['LuFrown', 'قلق وحيرة'],
    ], ['F48FB1', 'AD1457']);
    s.addText('⬇', T({ x: 3.78, y: 3.92, w: 0.6, h: 0.3, fontSize: 16, color: C.teal, align: 'center', rtlMode: false }));
    await row(4.2, 'رحلتها مع نبضة: وضوح وراحة بال', C.tealDk, C.tealLt, [
      ['LuSmartphone', 'تطبيق واحد شامل بالعربية'], ['LuBookOpenCheck', 'محتوى منظّم حسب مرحلتها'], ['LuBellRing', 'تتبّع دقيق وتذكيرات*'], ['LuUsersRound', 'ملتقى أمهات وراحة بال'],
    ], ['26A69A', '00695C']);
    s.addText('* جدول تطعيمات الطفل وتذكيراته جاهز في التطبيق، ويُفعَّل على Google Play بعد اعتماد حساب المنظّمة.', T({ x: 0.6, y: 6.66, w: 12.1, h: 0.3, fontSize: 9.5, color: C.mute }));
  }

  // ═════════ 7. الحل ═════════
  {
    const s = pres.addSlide();
    header(s, '05', 'الحل المقترح', 'منظومة واحدة متكاملة ترافق المرأة في كل مراحلها — بالعربية');
    const mods = [
      ['FaCalendarAlt', 'الدورة والخصوبة', 'تقويم يتوقّع الدورة ونافذة الخصوبة'],
      ['FaFemale', 'رحلة الحمل', 'أسبوعاً بأسبوع مع حجم الجنين والعدّ التنازلي'],
      ['FaBaby', 'رعاية الطفل', 'متابعة النمو والتغذية والنوم'],
      ['FaBookOpen', 'مكتبة نبضة', 'أكثر من 5,900 مقال تثقيفي مبسّط'],
      ['FaMosque', 'فقه المرأة', 'أحكام الطهارة وحساب أيام القضاء'],
      ['FaStar', 'أسماء المواليد', 'أكثر من 1,700 اسم بمعانيها'],
      ['FaUsers', 'مجتمع الأمهات', 'نقاش آمن مع إمكانية النشر المجهول'],
      ['FaStore', 'متجر نبضة', 'مستلزمات الأم والطفل بالدينار والدفع عند الاستلام'],
      ['FaMagic', 'مساعدة نبضة الذكية', 'أسماء وتنظيم وأفكار — دون أسئلة طبية'],
    ];
    mods.forEach(([ic, t, d], i) => {
      const col = i % 3, row = Math.floor(i / 3);
      const x = W - 0.6 - (col + 1) * 2.72 - col * 0.12, y = 1.6 + row * 1.52;
      card(s, x, y, 2.72, 1.4, row % 2 ? C.tealLt : C.blush);
      dot(s, ic, x + 2.72 - 0.72, y + 0.18, 0.52, i === 7 ? C.pink : C.teal);
      s.addText(t, T({ x: x + 0.1, y: y + 0.2, w: 1.8, h: 0.45, fontSize: 13.5, bold: true, valign: 'middle' }));
      s.addText(d, T({ x: x + 0.15, y: y + 0.75, w: 2.45, h: 0.55, fontSize: 11.5, color: C.mute }));
    });
    s.addImage({ path: IMG + 'cycle_circle.png', x: 0.45, y: 1.5, w: 2.35, h: 4.95, sizing: { type: 'contain', w: 2.35, h: 4.95 } });
    s.addText('الأصالة: تطبيق واحد يربط مرحلة المرأة بما تحتاجه — معلومةً وأداةً ومنتجاً — في اللحظة المناسبة.', T({ x: 3.0, y: 6.25, w: 9.7, h: 0.45, fontSize: 13.5, bold: true, color: C.tealDk }));
  }

  // ═════════ 7-ب. جوانب الابتكار ═════════
  {
    const s = pres.addSlide();
    header(s, '05', 'جوانب الابتكار والتميّز التكنولوجي', 'ما الذي يجعل نبضة أكثر من تطبيق تقليدي؟');
    const inv = [
      ['FaRobot', 'ذكاء اصطناعي توليدي مضبوط محلياً', 'مساعدة ذكية غير طبية مبنية على Google Gemini، بتعليمات نظام بالعربية، مع مصفاة تحجب الأسئلة الطبية وتوجّه إلى الطبيب أو القابلة.'],
      ['FaUsers', 'نوادي أشهر الولادة الذكية', 'انضمام تلقائي إلى نادي الأمهات اللواتي يلدن في الشهر نفسه، يُحسب من تاريخ الولادة المتوقّع أو من شهر ميلاد الطفل.'],
      ['FaSeedling', 'محتوى يتكيّف مع المرحلة', 'النصائح والمقالات والبطاقات تتغيّر حسب مرحلة المستخدمة (دورة، حمل، أمومة) وحسب أسبوع الحمل.'],
      ['FaMosque', 'فقه المرأة كأداة رقمية', 'حاسبة أيام القضاء وأحكام الطهارة داخل التطبيق نفسه — بُعد ثقافي وديني غائب عن التطبيقات العالمية.'],
      ['FaLayerGroup', 'منظومة متكاملة في تطبيق واحد', 'التثقيف والتتبّع والمجتمع والتجارة المحلية بالدفع عند الاستلام في تطبيق واحد، ما يسمح بربط المنتج بتوقيت الحاجة.'],
      ['FaShieldAlt', 'الخصوصية بالتصميم', 'نشر مجهول في المجتمع، وحذف الحساب والبيانات من داخل التطبيق، ولا بيع للبيانات ولا إعلانات مبنية عليها.'],
    ];
    inv.forEach(([ic, t, d], i) => {
      const col = i % 3, row = Math.floor(i / 3);
      const cw = 3.95, ch = 2.2;
      const x = W - 0.6 - (col + 1) * cw - col * 0.125, y = 1.6 + row * (ch + 0.15);
      card(s, x, y, cw, ch, (i === 0 || i === 4) ? C.pinkLt : C.blush);
      dot(s, ic, x + cw - 0.8, y + 0.2, 0.6, (i === 0 || i === 4) ? C.pink : C.teal);
      s.addText(t, T({ x: x + 0.15, y: y + 0.2, w: cw - 1.05, h: 0.6, fontSize: 14.5, bold: true, valign: 'middle' }));
      s.addText(d, T({ x: x + 0.2, y: y + 0.92, w: cw - 0.4, h: 1.15, fontSize: 12, color: C.mute, valign: 'top' }));
    });
    card(s, 0.6, 6.3, 12.1, 0.5, C.tealLt);
    s.addText('حسب بحثنا للسوق، لا يوجد تطبيق جزائري يجمع هذه العناصر معاً بالعربية، مع مراعاة الخصوصية الثقافية والدينية.', T({ x: 0.85, y: 6.3, w: 11.6, h: 0.5, fontSize: 13.5, bold: true, color: C.tealDk, valign: 'middle', align: 'center' }));
  }

  // ═════════ 7-ج. شبكة الأطباء والقابلات ═════════
  {
    const s = pres.addSlide();
    header(s, '05', 'الثقة أولاً: شبكة أطباء وقابلات متعاقدين', 'مرحلة قادمة: التعاقد مع مختصّين لضمان صحة المعلومة ومرافقة الأمهات');
    // من نتعاقد معهم؟ (يمين)
    const RX = 8.35, RW = 4.35;
    card(s, RX, 1.55, RW, 3.85, C.tealLt);
    s.addImage({ data: await badge('LuStethoscope', '26A69A', '00695C'), x: RX + RW - 0.9, y: 1.66, w: 0.76, h: 0.76 });
    s.addText('من نتعاقد معهم؟', T({ x: RX + 0.2, y: 1.75, w: RW - 1.2, h: 0.5, fontSize: 16, bold: true, color: C.tealDk, valign: 'middle' }));
    const who = ['أطباء أمراض النساء والتوليد', 'قابلات', 'أطباء الأطفال', 'مختصّون في التغذية والرضاعة', 'أخصائيون نفسانيون للدعم بعد الولادة'];
    s.addText(who.map((p, k) => ({ text: '‫◂  ' + p + '‬', options: { breakLine: k < who.length - 1, paraSpaceAfter: 6 } })),
      T({ x: RX + 0.3, y: 2.55, w: RW - 0.55, h: 2.0, fontSize: 13.5, valign: 'top' }));
    s.addShape(pres.shapes.LINE, { x: RX + 0.6, y: 4.6, w: RW - 1.2, h: 0, line: { color: 'C7E7E2', width: 1 } });
    s.addText('متى؟ بعد تأسيس الكيان القانوني، بالتوازي مع حساب المنظّمة على Google Play.', T({ x: RX + 0.25, y: 4.65, w: RW - 0.5, h: 0.65, fontSize: 11.5, bold: true, color: C.tealDk, valign: 'middle' }));
    // أدوار المختصّين (يسار): شبكة 2×2
    const roles = [
      ['LuBadgeCheck', 'مراجعة المحتوى واعتماده', 'يراجع مختصّ كل مقال صحي قبل نشره، مع شارة «راجعته قابلة» أو «راجعه طبيب».'],
      ['LuMessagesSquare', 'جلسات أسئلة مباشرة', 'لقاءات دورية مع قابلات وأطباء داخل مجتمع نبضة، تجيب عن أسئلة الأمهات.'],
      ['LuVideo', 'جلسات مرافقة عن بُعد', 'توجيه ودعم نفسي وإرشاد غذائي ورعاية الأمومة والرضاعة — دون وصفات طبية.'],
      ['LuBrainCircuit', 'مساعدة ذكية بخبرة بشرية', 'تبقى غير طبية وتحجب الأسئلة الطبية؛ يراجع المختصّون حدودها ورسائل التوجيه إليهم.'],
    ];
    const LX = 0.6, LW = 7.6, rcw = (LW - 0.15) / 2, rch = 1.85;
    for (let i = 0; i < roles.length; i++) {
      const [ic, t, d] = roles[i];
      const c = i % 2, r = Math.floor(i / 2);
      const x = LX + LW - (c + 1) * rcw - c * 0.15, y = 1.55 + r * (rch + 0.15);
      card(s, x, y, rcw, rch, (i === 0 || i === 3) ? C.pinkLt : C.blush);
      s.addImage({ data: await badge(ic, 'F06292', 'C2185B'), x: x + rcw - 0.85, y: y + 0.15, w: 0.7, h: 0.7 });
      s.addText(t, T({ x: x + 0.2, y: y + 0.2, w: rcw - 1.1, h: 0.6, fontSize: 14.5, bold: true, color: 'C2185B', valign: 'middle' }));
      s.addText(d, T({ x: x + 0.2, y: y + 0.92, w: rcw - 0.4, h: 0.85, fontSize: 13, color: C.ink, valign: 'top' }));
    }
    // المبادئ
    card(s, 0.6, 5.5, 12.1, 1.1, C.pinkLt);
    dot(s, 'FaShieldAlt', W - 1.35, 5.74, 0.62, C.pink);
    s.addText([
      { text: 'تنبيه: لا تطبيب عن بُعد ولا وصفات (Pas d\'ordonnances)', options: { fontFace: FB, color: 'C2185B', fontSize: 14, breakLine: true } },
      { text: 'جلسات المرافقة لا تتضمّن وصفات طبية علاجية ولا تشخيصاً، بل تقتصر على التوجيه والدعم النفسي والإرشاد الغذائي ورعاية الأمومة والرضاعة، مع إخلاء مسؤولية صريح وتوجيه فوري إلى الطبيب أو الاستعجالات عند علامات الخطر.', options: { fontFace: FB } },
    ], T({ x: 0.85, y: 5.53, w: 10.95, h: 1.04, fontSize: 11.5, valign: 'middle' }));
    s.addText('لا يضمّ المشروع حالياً أطباء أو قابلات؛ التعاقد معهم مبرمج ضمن خارطة الطريق.', T({ x: 0.6, y: 6.66, w: 12.1, h: 0.3, fontSize: 9.5, color: C.mute }));
  }

  // ═════════ 8. النموذج الأولي ═════════
  {
    const s = pres.addSlide();
    header(s, '06', 'تقديم النموذج الأولي (المنتج / الخدمة)', 'نموذج أولي عملي: تطبيق أندرويد ونسخة ويب يعملان فعلياً');
    const shots = ['cycle_circle', 'pregnancy_week', 'baby_care', 'fiqh', 'store'];
    shots.forEach((n, i) => s.addImage({ path: IMG + n + '.png', x: 0.45 + i * 1.68, y: 1.55, w: 1.62, h: 3.7, sizing: { type: 'contain', w: 1.62, h: 3.7 } }));
    const links = [
      ['FaGlobe', 'الموقع ونسخة الويب', 'https://nabda.online', 'https://nabda.online'],
      ['FaYoutube', 'فيديو عرض التطبيق (YouTube)', 'https://youtu.be/xSc8cw9gDQQ', 'https://youtu.be/xSc8cw9gDQQ'],
      ['FaGoogleDrive', 'ملفات المشروع (Google Drive)', 'drive.google.com/…/1GLVYFSFjMiXSNUbOR39YEG8S6rBSW-kD', 'https://drive.google.com/drive/folders/1GLVYFSFjMiXSNUbOR39YEG8S6rBSW-kD?usp=sharing'],
      ['FaUserCheck', 'حساب تجريبي للدخول إلى التطبيق', 'test@nabda.online  ·  test+123', null],
    ];
    links.forEach(([ic, k, v, url], i) => {
      const y = 1.45 + i * 0.8;
      dot(s, ic, W - 1.15, y, 0.48);
      s.addText(k, T({ x: 8.6, y: y + 0.03, w: 3.45, h: 0.42, fontSize: 13, bold: true, color: C.teal, valign: 'middle' }));
      s.addText([{ text: v, options: url ? { hyperlink: { url } } : {} }], T({ x: 8.8, y: y + 0.5, w: 3.95, h: 0.28, fontSize: v.length > 40 ? 9.5 : 12, rtlMode: false, align: 'right', valign: 'middle' }));
    });
    card(s, 9.1, 4.72, 3.65, 0.66, C.tealLt);
    s.addText([{ text: 'التقنيات المستعملة', options: { fontFace: FB, color: C.tealDk, breakLine: true } }, { text: 'Flutter و Dart · Firebase · Google Gemini' }], T({ x: 9.3, y: 4.74, w: 3.25, h: 0.62, fontSize: 11, valign: 'middle' }));
    const st = ['التطبيق مكتمل الوظائف ومبني بنسخة إصدار موقَّعة', 'نسخة الويب منشورة على nabda.online مع أدوات عامة (حاسبة الولادة، التبويض، حجم الجنين، الأسماء)', 'قيد النشر على Google Play بعد إنشاء حساب المنظّمة'];
    s.addText(st.map((p, i) => ({ text: '\u202B• ' + p + '\u202C', options: { breakLine: i < st.length - 1, paraSpaceAfter: 4 } })), T({ x: 0.6, y: 5.45, w: 12.1, h: 1.2, fontSize: 13, valign: 'top' }));
  }

  // ═════════ 8-ب. استعراض الشاشات ═════════
  const showcase = (title, hint, shots) => {
    const s = pres.addSlide();
    header(s, '06', title, hint);
    const n = shots.length, gap = 0.18, pw = (W - 1.0 - (n - 1) * gap) / n, ph = Math.min(4.55, pw * 1296 / 687);
    shots.forEach(([img, cap, sub], i) => {
      const x = W - 0.5 - (i + 1) * pw - i * gap;
      s.addImage({ path: IMG + img + '.png', x, y: 1.55, w: pw, h: ph, sizing: { type: 'contain', w: pw, h: ph } });
      s.addText(cap, T({ x, y: 1.6 + ph + 0.05, w: pw, h: 0.38, fontSize: 13.5, bold: true, color: C.rose, align: 'center' }));
      s.addText(sub, T({ x, y: 1.6 + ph + 0.42, w: pw, h: 0.5, fontSize: 11, color: C.mute, align: 'center', valign: 'top' }));
    });
  };
  showcase('استعراض شاشات التطبيق — رحلة المرأة', 'لقطات حقيقية من النسخة الحالية للتطبيق', [
    ['cycle_circle', 'تقويم الدورة', 'توقّع الدورة ونافذة الخصوبة'],
    ['cycle_symptoms', 'الأعراض والمزاج', 'تسجيل يومي بسيط'],
    ['ttc', 'التخطيط للحمل', 'مرافقة مرحلة الانتظار'],
    ['pregnancy_week', 'رحلة الحمل', 'أسبوعاً بأسبوع مع حجم الجنين'],
    ['hospital_bag', 'حقيبة الولادة', 'قائمة تجهيز تفاعلية'],
  ]);
  showcase('استعراض شاشات التطبيق — المحتوى والمتجر', 'لقطات حقيقية من النسخة الحالية للتطبيق', [
    ['baby_care', 'رعاية الطفل', 'النمو والتغذية والنوم'],
    ['home_articles', 'مكتبة نبضة', 'مقالات تثقيفية مبسّطة'],
    ['fiqh', 'فقه المرأة', 'أحكام الطهارة'],
    ['qada', 'حاسبة القضاء', 'حساب أيام القضاء'],
    ['names_girls', 'أسماء المواليد', 'أسماء بمعانيها'],
    ['store', 'متجر نبضة', 'بالدينار والدفع عند الاستلام'],
  ]);

  // ═════════ 9. الملكية الفكرية ═════════
  {
    const s = pres.addSlide();
    header(s, '07', 'البراءات والعلامات وحقوق الملكية الفكرية', 'وضع الملكية الفكرية للمشروع');
    const rows = [
      ['FaCertificate', 'براءات الاختراع', 'لا توجد براءات مودعة — المشروع حلّ برمجي وخدمة رقمية.'],
      ['FaTag', 'العلامات والتصاميم', 'إجراءات حماية العلامة «نبضة | Nabda» وشعارها قيد التحضير للإيداع لدى المعهد الوطني الجزائري للملكية الصناعية (INAPI)، والإيداع مبرمج فور الحصول على علامة «مشروع مبتكر» للاستفادة من مرافقة حاملي العلامة في حماية الملكية الفكرية.'],
      ['FaCopyright', 'حقوق المؤلف', 'فكرة التطبيق وحدها لا تُحمى، لذا نحمي الكود المصدري والواجهات والهوية البصرية (من إنجاز المؤسس) بحقوق المؤلف، وإيداعها لدى الديوان الوطني لحقوق المؤلف والحقوق المجاورة (ONDA) مبرمج. النطاق nabda.online مملوك للمشروع.'],
      ['FaCode', 'التراخيص', 'المكتبات المستعملة مفتوحة المصدر (Flutter و Dart وغيرها) وفق تراخيصها، وخدمات Google (Firebase و Gemini) باشتراك.'],
    ];
    rows.forEach(([ic, k, v], i) => {
      const y = 1.65 + i * 1.22;
      card(s, 0.6, y, 12.1, 1.05, i % 2 ? C.tealLt : C.blush);
      dot(s, ic, W - 1.45, y + 0.2, 0.65);
      s.addText(k, T({ x: 8.9, y: y + 0.15, w: 2.8, h: 0.75, fontSize: 17, bold: true, color: C.teal, valign: 'middle' }));
      s.addText(v, T({ x: 0.9, y: y + 0.08, w: 7.85, h: 0.9, fontSize: (i === 1 || i === 2) ? 12.5 : 13.5, valign: 'middle' }));
    });
  }

  // ═════════ 10. القيمة المضافة ═════════
  {
    const s = pres.addSlide();
    header(s, '08', 'القيمة المضافة', 'ما يقدّمه المشروع للمستخدمات: ربح الوقت، التوفير، الابتكار، الأثر');
    const v = [
      ['FaClock', 'ربح الوقت', 'كل احتياجاتها في تطبيق واحد بدل عدة تطبيقات ومجموعات.'],
      ['FaCoins', 'التوفير', 'تطبيق مجاني، وأسعار بالدينار، ودفع عند الاستلام.'],
      ['FaLanguage', 'لغتها وثقافتها', 'عربية أصيلة، وفقه المرأة، وأسماء عربية وإسلامية.'],
      ['FaShieldAlt', 'خصوصية البيانات', 'لا بيع ولا مشاركة للبيانات الصحية، وتشفير، وحذف الحساب من التطبيق.'],
      ['FaHandsHelping', 'أثر اجتماعي', 'توعية مبسّطة، ومجتمع دعم يكسر عزلة الأم الجديدة.'],
      ['FaTruck', 'اقتصاد محلي', 'تجارة إلكترونية محلية، وتوصيل للولايات، وفرص عمل رقمية.'],
    ];
    v.forEach(([ic, t, d], i) => {
      const col = i % 2, row = Math.floor(i / 2);
      const x = W - 0.6 - (col + 1) * 4.2 - col * 0.2, y = 1.6 + row * 1.6;
      card(s, x, y, 4.2, 1.42, row === 1 ? C.tealLt : C.blush);
      dot(s, ic, x + 4.2 - 0.85, y + 0.33, 0.7, i === 3 ? C.pink : C.teal);
      s.addText(t, T({ x: x + 0.2, y: y + 0.18, w: 3.0, h: 0.45, fontSize: 16, bold: true }));
      s.addText(d, T({ x: x + 0.2, y: y + 0.65, w: 3.0, h: 0.65, fontSize: 12.5, color: C.mute }));
    });
    s.addImage({ path: IMG + 'privacy.jpg', x: 0.6, y: 1.6, w: 3.3, h: 3.3, rounding: false });
    s.addText('الخصوصية بالتصميم: البيانات الصحية تُحفظ في حساب المستخدمة وتحذفها متى شاءت.', T({ x: 0.6, y: 5.05, w: 3.3, h: 1.1, fontSize: 12.5, color: C.tealDk, bold: true }));
  }

  // ═════════ 11. التحليل التنافسي ═════════
  {
    const s = pres.addSlide();
    header(s, '09', 'التحليل التنافسي', 'أهم المنافسين المباشرين وغير المباشرين، والتميّز');
    const hdr = (t) => ({ text: t, options: { color: C.white, fill: { color: C.pink }, fontFace: FB, fontSize: 13, align: 'right', rtlMode: true } });
    const cell = (t, b) => ({ text: t, options: { fontFace: b ? FB : F, fontSize: 12, color: C.ink, align: 'right', rtlMode: true } });
    const rows = [
      [hdr('الفجوة التي تسدّها نبضة'), hdr('نقطة القوة'), hdr('النوع'), hdr('المنافس')],
      [cell('مترجمة، بلا بعد ثقافي وديني ولا تجارة محلية، واشتراك بالعملة الصعبة'), cell('تتبّع دقيق وقاعدة مستخدمين ضخمة'), cell('مباشر · دولي'), cell('Flo / Clue', 1)],
      [cell('محتوى غير عربي أو مترجم، بلا متجر بالدينار'), cell('محتوى حمل ورعاية غني'), cell('مباشر · دولي'), cell('What to Expect / Pregnancy+ / BabyCenter', 1)],
      [cell('معلومة بلا تدقيق، بلا أدوات ولا خصوصية'), cell('تفاعل واسع ومجاني'), cell('غير مباشر'), cell('مجموعات فيسبوك للأمهات', 1)],
      [cell('بلا رفقة يومية ولا معرفة بمرحلة الأم'), cell('تشكيلة منتجات وتوصيل'), cell('غير مباشر'), cell('متاجر مستلزمات الأم والطفل المحلية', 1)],
    ];
    s.addTable(rows, { x: 0.6, y: 1.6, w: 12.1, colW: [4.6, 2.9, 1.5, 3.1], border: { type: 'solid', pt: 0.75, color: C.line }, fill: { color: C.white }, rowH: 0.62, valign: 'middle' });
    card(s, 0.6, 5.0, 12.1, 1.55, C.pinkLt);
    dot(s, 'FaCrown', W - 1.35, 5.3, 0.7, C.pink);
    s.addText('التميّز: التكامل. نبضة تعرف مرحلة المرأة (دورة، حمل، أمومة) فتقدّم لها المعلومة والأداة والمنتج المناسب في الوقت المناسب — بالعربية، مع احترام خصوصيتها الثقافية والدينية، وبطرق الدفع المحلية.', T({ x: 0.9, y: 5.12, w: 10.9, h: 1.3, fontSize: 14, valign: 'middle' }));
  }

  // ═════════ 11-ب. SWOT ═════════
  {
    const s = pres.addSlide();
    header(s, '09', 'تحليل SWOT مقارنةً بالمنافسين', 'نقاط القوة والضعف، والفرص والتهديدات');
    const q = [
      ['نقاط القوة', C.teal, C.tealLt, ['عربية أصيلة ومحتوى محلي', 'منظومة متكاملة: تتبّع + محتوى + فقه + مجتمع + متجر', 'نموذج أولي جاهز وتكلفة تشغيل منخفضة', 'الدفع عند الاستلام يناسب السوق']],
      ['نقاط الضعف', C.pink, C.pinkLt, ['فريق صغير حالياً (عضوان)', 'علامة جديدة غير معروفة بعد', 'تمويل ذاتي محدود', 'اعتماد على خدمات سحابية أجنبية']],
      ['الفرص', C.tealDk, C.tealLt, ['11.7 مليون امرأة في سن الإنجاب', 'انتشار الإنترنت: 79.5٪ من السكان', 'منظومة دعم المؤسسات الناشئة', 'إقبال المستثمرين على تطبيقات الأمومة الذكية', 'التوسّع نحو المغرب العربي والعالم العربي']],
      ['التهديدات', 'AD1457', C.pinkLt, ['تعريب المنافسين الدوليين', 'اشتراطات متاجر التطبيقات لتطبيقات الصحة', 'نسبة الإلغاء في الدفع عند الاستلام', 'ثقة المستخدمات في حماية بياناتهن']],
    ];
    q.forEach(([t, col, bg, items], i) => {
      const c = i % 2, r = Math.floor(i / 2);
      const x = W - 0.6 - (c + 1) * 5.95 - c * 0.2, y = 1.6 + r * 2.5;
      card(s, x, y, 5.95, 2.35, bg);
      s.addText(t, T({ x: x + 0.3, y: y + 0.15, w: 5.35, h: 0.5, fontSize: 18, bold: true, color: col }));
      s.addText(items.map((p, k) => ({ text: '\u202B• ' + p + '\u202C', options: { breakLine: k < items.length - 1, paraSpaceAfter: 3 } })), T({ x: x + 0.3, y: y + 0.7, w: 5.35, h: 1.55, fontSize: 13, valign: 'top' }));
    });
  }

  // ═════════ 11-ج. تجربة دولية: SOULA ═════════
  {
    const s = pres.addSlide();
    header(s, '09', 'تجربة دولية تؤكّد الفرصة: SOULA في Shark Tank مالطا', 'مساعدة ذكية لمرافقة الأمومة نالت استثماراً بـ 500 ألف يورو — ماذا نتعلّم منها؟');
    // الأرقام (يمين): 2×2
    const st = [
      ['500 ألف €', 'مقابل 7٪ من الشركة، من 5 مستثمرين في البرنامج', 'C2185B', C.pinkLt],
      ['45,000', 'مستخدمة، بدءاً بالسوق الأمريكية', 'C2185B', C.blush],
      ['أكثر من 30 خبيراً', 'مدرّبات أمومة ومرافقات ولادة يُدرّبن مساعدتها الذكية', C.teal, C.tealLt],
      ['12.8٪', 'من المستخدمات يتحوّلن من التجربة المجانية إلى الاشتراك المدفوع', C.tealDk, C.tealLt],
    ];
    const SX = 6.95, SW = 5.75, scw = (SW - 0.15) / 2, sch = 1.9;
    st.forEach(([n, l, col, bg], i) => {
      const c = i % 2, r = Math.floor(i / 2);
      const x = SX + SW - (c + 1) * scw - c * 0.15, y = 1.55 + r * (sch + 0.12);
      card(s, x, y, scw, sch, bg);
      s.addText(n, T({ x: x + 0.15, y: y + 0.18, w: scw - 0.3, h: 0.65, fontSize: n.length > 7 ? 22 : 28, bold: true, color: col, align: 'center', valign: 'middle' }));
      s.addText(l, T({ x: x + 0.2, y: y + 0.9, w: scw - 0.4, h: 0.9, fontSize: 12, align: 'center', valign: 'top' }));
    });
    // ما نستفيده (يسار)
    card(s, 0.6, 1.55, 6.2, 3.92, C.blush);
    s.addImage({ data: await badge('LuLightbulb', '26A69A', '00695C'), x: 5.9, y: 1.66, w: 0.76, h: 0.76 });
    s.addText('ما نستفيده في نبضة', T({ x: 0.85, y: 1.75, w: 4.9, h: 0.5, fontSize: 17, bold: true, color: C.tealDk, valign: 'middle' }));
    const les = [
      'المصداقية تُبنى بخبراء حقيقيين، لا ببرنامج محادثة وحده',
      'تتبّع + مكتبة + مساعدة ذكية = وقت أطول داخل التطبيق',
      '«وضع الشريك»: تنبيه الزوج بحالة زوجته ونصائح لدعمها',
      'البدء بالمستخدمات مباشرة (B2C)، ثم الشراكات مع المؤسسات (B2B)',
      'ولاء طويل: الأم التي تُرافَق في حملها تبقى وفيّة للعلامة ومنتجاتها',
    ];
    s.addText(les.map((p, k) => ({ text: '‫◂  ' + p + '‬', options: { breakLine: k < les.length - 1, paraSpaceAfter: 11 } })),
      T({ x: 0.85, y: 2.5, w: 5.75, h: 2.9, fontSize: 14, valign: 'top' }));
    // التميّز
    card(s, 0.6, 5.6, 12.1, 0.95, C.pinkLt);
    dot(s, 'FaCrown', W - 1.35, 5.76, 0.62, C.pink);
    s.addText('ما يميّز نبضة: عربية أصيلة · فقه المرأة · متجر محلي بالدفع عند الاستلام · مجتمع ونوادي أشهر الولادة — في السوق العربية، بينما بدأت SOULA بالسوق الأمريكية.',
      T({ x: 0.85, y: 5.62, w: 10.95, h: 0.9, fontSize: 13.5, bold: true, color: 'C2185B', valign: 'middle' }));
    s.addText('المصدر: عرض SOULA في برنامج Shark Tank Malta، الموسم 3 (YouTube) — أرقام صرّحت بها المؤسِّسة أثناء العرض.', T({ x: 0.6, y: 6.66, w: 12.1, h: 0.3, fontSize: 9.5, color: C.mute }));
  }

  // ═════════ 12. السوق المستهدف ═════════
  {
    const s = pres.addSlide();
    header(s, '10', 'تحليل السوق المستهدف', 'الفئة الأساسية: المستخدمات والمستفيدون');
    const per = [
      ['FaFemale', 'نور (20–45)', 'واعية بصحّتها: تتبّع الدورة والمحتوى التثقيفي'],
      ['FaCalendarAlt', 'سلمى (24–32)', 'تخطّط للحمل: نافذة الخصوبة والإرشاد'],
      ['FaHeart', 'هبة (26–35)', 'حامل لأول مرة: رحلة الحمل وحقيبة الولادة'],
      ['FaBaby', 'أمينة (25–38)', 'أم جديدة: نمو الطفل والرضاعة واللوازم'],
    ];
    per.forEach(([ic, t, d], i) => {
      const x = W - 0.6 - (i + 1) * 2.9 - i * 0.17;
      card(s, x, 1.6, 2.9, 2.35, i % 2 ? C.tealLt : C.blush);
      dot(s, ic, x + 1.1, 1.8, 0.7, i % 2 ? C.teal : C.pink);
      s.addText(t, T({ x: x + 0.15, y: 2.6, w: 2.6, h: 0.45, fontSize: 16, bold: true, align: 'center' }));
      s.addText(d, T({ x: x + 0.15, y: 3.05, w: 2.6, h: 0.8, fontSize: 12, color: C.mute, align: 'center' }));
    });
    const mk = [
      ['السوق الأساسي: الجزائر', '11.7 مليون امرأة في سن الإنجاب · نحو 825 ألف ولادة سنوياً · 37.8 مليون مستخدم للإنترنت', C.teal],
      ['السوق الثانوي: المغرب العربي', 'نفس اللغة والثقافة وطرق الدفع عند الاستلام', C.tealDk],
      ['على المدى البعيد: العالم العربي', 'منصة عربية أصيلة لصحة المرأة والأمومة', C.pink],
    ];
    mk.forEach(([t, d, col], i) => {
      const y = 4.2 + i * 0.78;
      dot(s, 'FaBullseye', W - 1.2, y + 0.05, 0.55, col);
      s.addText(t, T({ x: 5.2, y, w: 6.8, h: 0.35, fontSize: 15, bold: true, color: col }));
      s.addText(d, T({ x: 5.2, y: y + 0.35, w: 6.8, h: 0.35, fontSize: 12.5, color: C.mute }));
    });
    card(s, 0.6, 4.2, 4.3, 2.35, C.blush);
    s.addText('المستفيدون أيضاً', T({ x: 0.85, y: 4.35, w: 3.8, h: 0.4, fontSize: 15, bold: true, color: C.teal }));
    const ben = ['الأسر والأزواج', 'بائعو مستلزمات الأم والطفل المحليون', 'شركات التوصيل'];
    s.addText(ben.map((p, k) => ({ text: '\u202B• ' + p + '\u202C', options: { breakLine: k < ben.length - 1, paraSpaceAfter: 4 } })), T({ x: 0.85, y: 4.85, w: 3.8, h: 1.55, fontSize: 13, valign: 'top' }));
  }

  // ═════════ 12-أ. السوق الجزائري بالأرقام ═════════
  {
    const s = pres.addSlide();
    header(s, '10', 'السوق الجزائري بالأرقام', 'جمهور كبير ومتّصل بالإنترنت');
    const stats = [
      ['11.7 مليون', 'امرأة في سن الإنجاب (24٪ من السكان)', 'C2185B', C.pinkLt],
      ['825 ألف', 'ولادة سنوياً (تقدير 2025)', 'E91E63', C.pinkLt],
      ['79.5٪', 'من السكان يستعملون الإنترنت (37.8 مليون)', C.teal, C.tealLt],
    ];
    stats.forEach(([n, l, col, bg], i) => {
      const y = 1.6 + i * 1.62;
      card(s, 7.6, y, 5.1, 1.45, bg);
      s.addText(n, T({ x: 7.85, y: y + 0.12, w: 4.6, h: 0.7, fontSize: 30, bold: true, color: col, valign: 'middle' }));
      s.addText(l, T({ x: 7.85, y: y + 0.85, w: 4.6, h: 0.45, fontSize: 13.5, valign: 'top' }));
    });
    card(s, 0.6, 1.6, 6.8, 4.67, C.blush);
    s.addChart(pres.charts.BAR, [{ name: 'مليون مستخدم', labels: ['الإنترنت', 'فيسبوك', 'تيك توك (18+)', 'إنستغرام'], values: [37.8, 35.05, 24.8, 15.37] }], {
      x: 0.75, y: 1.7, w: 6.5, h: 4.0, barDir: 'bar', dataLabelFormatCode: '0.0', chartColors: [C.teal],
      showTitle: true, title: 'الجزائر رقمياً 2026 (مليون مستخدم)', titleFontFace: FB, titleFontSize: 15, titleColor: C.ink,
      showValue: true, dataLabelPosition: 'outEnd', dataLabelFontSize: 14, dataLabelColor: C.ink, dataLabelFontFace: F,
      catAxisLabelFontFace: FB, catAxisLabelFontSize: 14, catAxisLabelColor: C.ink, valAxisHidden: true,
      valGridLine: { style: 'none' }, catGridLine: { style: 'none' }, showLegend: false, catAxisOrientation: 'maxMin',
    });
    s.addText('الأمهات متّصلات بالفعل، لكن على منصات عامة لا صُمّمت لاحتياجاتهن.', T({ x: 0.8, y: 5.72, w: 6.4, h: 0.45, fontSize: 13, bold: true, color: C.tealDk, align: 'center' }));
    s.addText('المصادر: وزارة الصحة / الديوان الوطني للإحصائيات عبر TSA (جويلية 2025) · DataReportal «Digital 2026: Algeria»', T({ x: 0.6, y: 6.5, w: 12.1, h: 0.3, fontSize: 10, color: C.mute }));
  }

  // ═════════ 12-ب. السوق في العالم العربي ═════════
  {
    const s = pres.addSlide();
    header(s, '10', 'السوق على مستوى العالم العربي', 'سوق واسع يتحدّث العربية… ومحتوى رقمي عربي شحيح');
    const st = [
      ['492.6 مليون', 'نسمة في العالم العربي (2024)', C.pink, 'LuUsers'],
      ['أكثر من 100 مليون', 'امرأة في سن الإنجاب (15–49 سنة)', 'C2185B', 'LuHeartHandshake'],
      ['نحو 11.4 مليون', 'ولادة سنوياً (تقدير محسوب)', C.teal, 'LuSprout'],
      ['70٪', 'من سكان الدول العربية يستعملون الإنترنت', '00796B', 'LuGlobe'],
    ];
    for (let i = 0; i < st.length; i++) {
      const [n, l, col, ic] = st[i];
      const cw = 2.92, x = W - 0.6 - (i + 1) * cw - i * 0.14;
      card(s, x, 1.6, cw, 2.15, i < 2 ? C.pinkLt : C.tealLt);
      s.addImage({ data: await badge(ic, i < 2 ? 'F06292' : '26A69A', col), x: x + cw / 2 - 0.36, y: 1.7, w: 0.72, h: 0.72 });
      s.addText(n, T({ x: x + 0.1, y: 2.45, w: cw - 0.2, h: 0.6, fontSize: n.length > 10 ? 21 : 26, bold: true, color: col, align: 'center', valign: 'middle' }));
      s.addText(l, T({ x: x + 0.15, y: 3.05, w: cw - 0.3, h: 0.6, fontSize: 12.5, color: C.ink, align: 'center', valign: 'top' }));
    }
    // مقارنة: حصة العرب من سكان العالم مقابل حصة المحتوى العربي
    card(s, 6.55, 3.95, 6.15, 2.65, C.blush);
    s.addText('الفجوة الرقمية العربية', T({ x: 6.8, y: 4.05, w: 5.7, h: 0.45, fontSize: 17, bold: true, color: C.rose }));
    const bars = [['نسبة العرب من سكان العالم', 6.0, C.teal, 'نحو 6٪'], ['نسبة المواقع المكتوبة بالعربية', 0.6, C.pink, '0.6٪ فقط']];
    bars.forEach(([lab, v, col, txt], k) => {
      const y = 4.62 + k * 0.92, maxW = 3.3, bw = Math.max(0.12, maxW * v / 6.0);
      s.addText(lab, T({ x: 9.2, y, w: 3.3, h: 0.38, fontSize: 13, bold: true }));
      s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 12.5 - bw, y: y + 0.42, w: bw, h: 0.3, fill: { color: col }, line: { color: col, width: 0 }, rectRadius: 0.08 });
      s.addText(txt, T({ x: 6.8, y: y + 0.36, w: 12.5 - bw - 6.85 - 0.1, h: 0.42, fontSize: 15, bold: true, color: col, valign: 'middle' }));
    });
    // الدلالة لنبضة
    card(s, 0.6, 3.95, 5.8, 2.65, C.tealLt);
    s.addImage({ data: await badge('LuLightbulb', '26A69A', '00695C'), x: 5.45, y: 4.08, w: 0.75, h: 0.75 });
    s.addText('ماذا يعني ذلك لنبضة؟', T({ x: 0.85, y: 4.15, w: 4.5, h: 0.45, fontSize: 17, bold: true, color: C.tealDk, valign: 'middle' }));
    const imp = ['ملايين النساء العربيات يبحثن يومياً عن معلومة موثوقة بلغتهن', 'نفس الإشكالية تتكرّر في كل البلدان العربية: محتوى مترجم وأدوات لا تراعي الثقافة', 'نبضة قابلة للتوسّع عربياً بنفس اللغة والمحتوى، بدءاً من المغرب العربي'];
    s.addText(imp.map((p, k) => ({ text: '\u202B◂  ' + p + '\u202C', options: { breakLine: k < imp.length - 1, paraSpaceAfter: 6 } })), T({ x: 0.85, y: 4.75, w: 5.35, h: 1.8, fontSize: 13, valign: 'top' }));
    s.addText('المصادر: البنك الدولي (السكان ومعدل المواليد 2024) · صندوق الأمم المتحدة للسكان UNFPA · الاتحاد الدولي للاتصالات ITU «Facts and Figures 2024» · W3Techs (أكتوبر 2026)', T({ x: 6.1, y: 6.66, w: 6.6, h: 0.42, fontSize: 9, color: C.mute }));
  }

  // ═════════ 12-ب. حجم السوق ═════════
  {
    const s = pres.addSlide();
    header(s, '10', 'حجم السوق: الكلّي · المتاح · المستهدف', 'TAM · SAM · SOM');
    const cx = 3.55, cy = 4.1;
    [[2.55, 'FCE4EC', 'F48FB1'], [1.75, 'F8BBD0', 'EC407A'], [0.95, 'E91E63', 'C2185B']].forEach(([r, f, l]) => {
      s.addShape(pres.shapes.OVAL, { x: cx - r, y: cy + 2.55 - 2 * r, w: 2 * r, h: 2 * r, fill: { color: f, transparency: 8 }, line: { color: l, width: 1.5 } });
    });
    s.addText('TAM', T({ x: cx - 1, y: cy - 2.35, w: 2, h: 0.4, fontSize: 16, bold: true, color: 'C2185B', align: 'center', rtlMode: false }));
    s.addText('SAM', T({ x: cx - 1, y: cy - 0.75, w: 2, h: 0.4, fontSize: 16, bold: true, color: C.white, align: 'center', rtlMode: false }));
    s.addText('SOM', T({ x: cx - 1, y: cy + 1.35, w: 2, h: 0.5, fontSize: 18, bold: true, color: C.white, align: 'center', rtlMode: false }));
    const rows = [
      ['السوق الكلّي (TAM)', 'أكثر من 100 مليون امرأة', 'في سن الإنجاب في العالم العربي، يتحدّثن العربية — المصدر: UNFPA', 'C2185B'],
      ['السوق المتاح (SAM)', 'نحو 9.3 مليون امرأة', 'في الجزائر: 11.7 مليون امرأة في سن الإنجاب × 79.5٪ نسبة استعمال الإنترنت (تقدير محسوب)', 'E91E63'],
      ['السوق المستهدف (SOM)', '50,000 مستخدمة', 'هدف السنة الأولى، أي نحو 0.5٪ فقط من السوق المتاح', C.teal],
    ];
    rows.forEach(([k, n, d, col], i) => {
      const y = 1.6 + i * 1.5;
      card(s, 7.0, y, 5.7, 1.35, i === 2 ? C.tealLt : C.blush);
      s.addShape(pres.shapes.RECTANGLE, { x: 12.62, y: y + 0.2, w: 0.08, h: 0.95, fill: { color: col }, line: { color: col, width: 0 } });
      s.addText(k, T({ x: 7.25, y: y + 0.1, w: 5.2, h: 0.35, fontSize: 13, bold: true, color: C.roseMute }));
      s.addText(n, T({ x: 7.25, y: y + 0.42, w: 5.2, h: 0.45, fontSize: 21, bold: true, color: col }));
      s.addText(d, T({ x: 7.25, y: y + 0.88, w: 5.2, h: 0.42, fontSize: 11, color: C.mute }));
    });
    card(s, 7.0, 6.15, 5.7, 0.55, C.pinkLt);
    s.addText('وكل عام: نحو 825 ألف أمّ جديدة تحتاج حقيبة ولادة ولوازم مولود', T({ x: 7.2, y: 6.15, w: 5.3, h: 0.55, fontSize: 12, bold: true, color: 'C2185B', valign: 'middle' }));
  }

  // ═════════ 13. النموذج الاقتصادي ═════════
  {
    const s = pres.addSlide();
    header(s, '11', 'النموذج الاقتصادي', 'كيف يحقّق المشروع مداخيله ويضمن ربحيته');
    const st = [
      ['FaStore', 'متجر نبضة', 'الآن', 'هامش ربح على مستلزمات الأم والطفل · دفع عند الاستلام · توصيل للولايات'],
      ['FaHandshake', 'شراكات العلامات', 'المدى القصير', 'عروض لعلامات الأم والطفل المحلية داخل المتجر'],
      ['FaBullhorn', 'الإعلانات', 'لاحقاً', 'إعلانات غير مخصّصة، بعيدة تماماً عن البيانات الصحية'],
      ['FaCrown', 'اشتراك «نبضة بلس»', 'المدى المتوسط', 'ميزات متقدّمة اختيارية، والتطبيق الأساسي يبقى مجانياً'],
    ];
    st.forEach(([ic, t, when, d], i) => {
      const y = 1.6 + i * 1.08;
      card(s, 5.0, y, 7.7, 0.95, i === 0 ? C.pinkLt : C.blush);
      dot(s, ic, W - 1.35, y + 0.17, 0.6, i === 0 ? C.pink : C.teal);
      s.addText(t, T({ x: 9.3, y: y + 0.1, w: 2.6, h: 0.4, fontSize: 15, bold: true }));
      s.addText(when, T({ x: 9.3, y: y + 0.5, w: 2.6, h: 0.35, fontSize: 12, color: C.pink, bold: true }));
      s.addText(d, T({ x: 5.25, y: y + 0.08, w: 4.0, h: 0.8, fontSize: 12.5, color: C.mute, valign: 'middle' }));
    });
    card(s, 0.6, 1.6, 4.15, 2.6, C.tealLt);
    s.addText('منطق الربحية', T({ x: 0.85, y: 1.75, w: 3.65, h: 0.4, fontSize: 16, bold: true, color: C.tealDk }));
    s.addText('التطبيق المجاني يجذب الجمهور، ومرحلة المرأة تتحوّل إلى حاجة شرائية في وقتها. مثال: الأسبوع 34 ← قائمة حقيبة الولادة ← الشراء من متجر نبضة.', T({ x: 0.85, y: 2.2, w: 3.65, h: 1.9, fontSize: 13, valign: 'top' }));
    card(s, 0.6, 4.35, 4.15, 2.25, C.blush);
    s.addText('هيكل التكاليف', T({ x: 0.85, y: 4.48, w: 3.65, h: 0.4, fontSize: 16, bold: true, color: C.pink }));
    const cost = ['الخدمات السحابية (Firebase و Gemini)', 'التسويق الرقمي', 'اللوجستيك والتوصيل', 'الفريق'];
    s.addText(cost.map((p, k) => ({ text: '\u202B• ' + p + '\u202C', options: { breakLine: k < cost.length - 1, paraSpaceAfter: 3 } })), T({ x: 0.85, y: 4.95, w: 3.65, h: 1.55, fontSize: 13, valign: 'top' }));
  }

  // ═════════ 13-ب. Business Model Canvas ═════════
  {
    const s = pres.addSlide();
    header(s, '11', 'نموذج العمل التجاري (Business Model Canvas)', 'المكوّنات التسعة لنموذج نبضة');
    const X0 = 0.6, Y0 = 1.5, TW = 12.1, cw = TW / 5, H1 = 3.55, H2 = 1.5, g = 0.08;
    const box = (x, y, w, h, t, items, accent) => {
      card(s, x + g / 2, y + g / 2, w - g, h - g, accent ? C.pinkLt : C.blush);
      s.addText(t, T({ x: x + 0.15, y: y + 0.1, w: w - 0.3, h: 0.36, fontSize: 12.5, bold: true, color: accent ? 'C2185B' : C.teal }));
      s.addText(items.map((p, k) => ({ text: '\u202B• ' + p + '\u202C', options: { breakLine: k < items.length - 1, paraSpaceAfter: 2 } })), T({ x: x + 0.15, y: y + 0.48, w: w - 0.3, h: h - 0.58, fontSize: 10.5, valign: 'top' }));
    };
    // RTL: الأعمدة من اليمين إلى اليسار
    const col = (i) => X0 + TW - (i + 1) * cw;
    box(col(0), Y0, cw, H1, 'الشركاء الرئيسيون', ['أطباء وقابلات متعاقدون (مرحلة قادمة)', 'موردو مستلزمات الأم والطفل', 'شركات التوصيل', 'Google (Firebase و Gemini)', 'الحاضنات وهيئات الدعم']);
    box(col(1), Y0, cw, H1 / 2, 'الأنشطة الرئيسية', ['تطوير التطبيق', 'إنتاج المحتوى ومراجعته مع مختصّين', 'تشغيل المتجر']);
    box(col(1), Y0 + H1 / 2, cw, H1 / 2, 'الموارد الرئيسية', ['التطبيق والكود المصدري', 'مكتبة 5,900+ مقال', 'العلامة والفريق']);
    box(col(2), Y0, cw, H1, 'عرض القيمة', ['رفيقة عربية واحدة من الدورة إلى الأمومة', 'معلومة + أداة + مجتمع + منتج', 'تحترم الثقافة والدين', 'دفع عند الاستلام'], true);
    box(col(3), Y0, cw, H1 / 2, 'العلاقة مع المستخدمات', ['تخصيص حسب المرحلة', 'نوادي الولادة والمجتمع', 'المساعدة الذكية']);
    box(col(3), Y0 + H1 / 2, cw, H1 / 2, 'القنوات', ['Google Play والويب', 'فيسبوك وتيك توك وإنستغرام', 'التوصية بين الأمهات']);
    box(col(4), Y0, cw, H1, 'شرائح الزبائن', ['نساء 18–45 سنة', 'المخطّطات للحمل والحوامل', 'الأمهات الجدد', 'العلامات المحلية للأم والطفل']);
    box(X0 + TW / 2, Y0 + H1, TW / 2, H2, 'هيكل التكاليف', ['الخدمات السحابية · التسويق الرقمي · اللوجستيك · الفريق']);
    box(X0, Y0 + H1, TW / 2, H2, 'مصادر الدخل', ['هامش المتجر · شراكات العلامات · اشتراك «نبضة بلس» · لاحقاً: جلسات مرافقة عن بُعد (دون وصفات) وإعلانات غير مخصّصة'], true);
  }

  // ═════════ 13-ج. قابلية التوسّع ═════════
  {
    const s = pres.addSlide();
    header(s, '11', 'قابلية التوسّع: ما يجعل نبضة مؤسسة ناشئة', 'المداخيل تنمو أسرع من التكاليف');
    card(s, 0.6, 1.55, 6.6, 4.95, C.blush);
    const yrs = ['البداية', '', '', '', '', '', '', 'النمو'];
    const rev = [0.2, 0.5, 1.0, 1.8, 3.0, 4.6, 6.6, 9.0];
    const lin = [1.0, 1.6, 2.2, 2.8, 3.4, 4.0, 4.6, 5.2];
    const cst = [1.0, 1.15, 1.3, 1.5, 1.7, 1.9, 2.1, 2.3];
    s.addChart(pres.charts.LINE, [
      { name: 'مداخيل نبضة', labels: yrs, values: rev },
      { name: 'تكاليف نبضة (سحابية، شبه ثابتة)', labels: yrs, values: cst },
      { name: 'تكاليف شركة تقليدية (تنمو مع النشاط)', labels: yrs, values: lin },
    ], {
      x: 0.75, y: 1.65, w: 6.3, h: 4.4, chartColors: ['E91E63', '00897B', 'B0A4AA'], lineSize: 3, lineDataSymbol: 'none',
      showLegend: true, legendPos: 'b', legendFontFace: F, legendFontSize: 11, valAxisHidden: true,
      catAxisLabelFontFace: F, catAxisLabelFontSize: 11, valGridLine: { style: 'none' }, catGridLine: { style: 'none' },
    });
    s.addText('رسم توضيحي للمبدأ — ليس توقّعاً مالياً', T({ x: 0.75, y: 6.08, w: 6.3, h: 0.32, fontSize: 10.5, color: C.mute, align: 'center' }));
    const pts = [
      ['LuServer', 'تكلفة شبه منعدمة لكل مستخدمة جديدة', 'بنية سحابية (Firebase) تتوسّع تلقائياً: المستخدمة رقم 100,000 لا تكلّف أكثر من الأولى تقريباً.'],
      ['LuCopy', 'محتوى يُنتَج مرة ويُستعمل ملايين المرات', 'مكتبة المقالات والأدوات والحاسبات رقمية بالكامل وقابلة للتكرار دون تكلفة إضافية.'],
      ['LuGlobe', 'سوق عربي بنفس المنتج', 'نفس اللغة ونفس المحتوى: التوسّع نحو المغرب العربي ثم العالم العربي دون إعادة البناء.'],
      ['LuTrendingUp', 'مداخيل متعدّدة تتراكم', 'كل مستخدمة جديدة تفتح فرص المتجر والشراكات والاشتراك في آن واحد.'],
    ];
    for (let i = 0; i < pts.length; i++) {
      const [ic, t, d] = pts[i];
      const y = 1.55 + i * 1.25;
      card(s, 7.45, y, 5.25, 1.12, i % 2 ? C.tealLt : C.blush);
      s.addImage({ data: await badge(ic, i % 2 ? '26A69A' : 'F06292', i % 2 ? '00695C' : 'C2185B'), x: 11.95, y: y + 0.2, w: 0.72, h: 0.72 });
      s.addText(t, T({ x: 7.6, y: y + 0.08, w: 4.3, h: 0.38, fontSize: 13.5, bold: true }));
      s.addText(d, T({ x: 7.6, y: y + 0.46, w: 4.3, h: 0.62, fontSize: 11, color: C.mute, valign: 'top' }));
    }
  }

  // ═════════ 14. خارطة الطريق ═════════
  {
    const s = pres.addSlide();
    header(s, '12', 'خارطة الطريق واستراتيجية التطوير', 'المراحل الأساسية · الأهداف بعد 6 أشهر وسنة و3 سنوات · الموارد اللازمة');
    const ph = [
      ['6 أشهر', 'الإطلاق', C.pink, ['تأسيس الكيان القانوني وحساب منظّمة على Google Play', 'نشر التطبيق على Google Play', 'حملة محتوى عضوي على فيسبوك وتيك توك', 'أولى مبيعات المتجر', 'هدف: 10,000 تحميل']],
      ['سنة واحدة', 'النمو', C.teal, ['التعاقد مع أول أطباء وقابلات لمراجعة المحتوى', 'نسخة iOS', 'توسيع كتالوج المتجر وشراكات الموردين', 'طلب علامة «مؤسسة ناشئة»', 'هدف: 50,000 مستخدمة']],
      ['3 سنوات', 'التوسّع', C.tealDk, ['التوسّع نحو المغرب العربي', 'اشتراك «نبضة بلس» وجلسات مرافقة عن بُعد', '«وضع الشريك» وشبكة حرفيّات في الولايات', 'فريق من 8 إلى 10 أعضاء', 'هدف: ربحية تشغيلية']],
    ];
    s.addShape(pres.shapes.LINE, { x: 0.9, y: 2.02, w: 11.5, h: 0, line: { color: C.line, width: 2 } });
    ph.forEach(([when, t, col, items], i) => {
      const x = W - 0.6 - (i + 1) * 3.95 - i * 0.1;
      s.addShape(pres.shapes.OVAL, { x: x + 3.95 - 0.75, y: 1.72, w: 0.6, h: 0.6, fill: { color: col }, line: { color: C.white, width: 3 } });
      s.addText(String(i + 1), T({ x: x + 3.95 - 0.75, y: 1.72, w: 0.6, h: 0.6, fontSize: 16, bold: true, color: C.white, align: 'center', valign: 'middle', rtlMode: false }));
      s.addText(when + ' — ' + t, T({ x: x + 0.15, y: 1.75, w: 3.0, h: 0.55, fontSize: 17, bold: true, color: col, valign: 'middle' }));
      card(s, x, 2.5, 3.95, 2.6, i === 1 ? C.tealLt : C.blush);
      s.addText(items.map((p, k) => ({ text: '\u202B• ' + p + '\u202C', options: { breakLine: k < items.length - 1, paraSpaceAfter: 4, bold: p.startsWith('هدف') } })), T({ x: x + 0.25, y: 2.65, w: 3.45, h: 2.35, fontSize: 12.5, valign: 'top' }));
    });
    const res = [
      ['FaUsers', 'بشرية', 'تسويق ومجتمع، محتوى، عمليات المتجر، أطباء وقابلات متعاقدون'],
      ['FaCoins', 'مالية', 'تمويل أولي للتسويق والفريق (حاضنة، Algeria Startup Fund)'],
      ['FaServer', 'تقنية', 'خدمات سحابية، حسابات المطوّر (Google و Apple)، أدوات التصميم'],
    ];
    res.forEach(([ic, k, v], i) => {
      const x = W - 0.6 - (i + 1) * 3.95 - i * 0.1;
      dot(s, ic, x + 3.95 - 0.6, 5.4, 0.5, C.teal);
      s.addText(k, T({ x: x + 0.1, y: 5.35, w: 3.2, h: 0.35, fontSize: 14, bold: true, color: C.teal }));
      s.addText(v, T({ x: x + 0.1, y: 5.72, w: 3.75, h: 0.75, fontSize: 11.5, color: C.mute }));
    });
  }

  // ═════════ 15. شكراً ═════════
  {
    const s = pres.addSlide(); s.background = { path: BG + 'thanks.jpg' };
    const cx = 4.3, cw = 6.6, mid = cx + cw / 2;
    s.addShape(pres.shapes.OVAL, { x: mid - 1.2, y: 0.8, w: 2.4, h: 2.4, fill: { color: C.white, transparency: 4 }, line: { color: 'F6D3E1', width: 1 },
      shadow: { type: 'outer', color: 'C2185B', opacity: 0.18, blur: 14, offset: 4, angle: 90 } });
    s.addImage({ path: IMG + 'logo.png', x: mid - 0.85, y: 1.15, w: 1.7, h: 1.7 });
    s.addText('شكراً على اهتمامكم', T({ x: cx, y: 3.55, w: cw, h: 0.95, fontSize: 46, bold: true, color: C.rose, align: 'center' }));
    s.addText('MERCI', T({ x: cx, y: 4.5, w: cw, h: 0.55, fontSize: 20, bold: true, color: 'F06292', align: 'center', rtlMode: false, charSpacing: 6 }));
    s.addText('بلال نوي — Billel NOUI', T({ x: cx, y: 5.15, w: cw, h: 0.4, fontSize: 16, bold: true, color: C.ink, align: 'center' }));
    s.addText('billelnoui19@gmail.com   |   0661 35 38 28   |   nabda.online', T({ x: cx, y: 5.6, w: cw, h: 0.4, fontSize: 14, color: C.ink, align: 'center', rtlMode: false, lang: 'fr-FR' }));
    s.addText('«نبضة — رفيقتكِ في رحلة الأنوثة والأمومة، خطوةً بخطوة، ونبضةً بنبضة.»', T({ x: cx, y: 6.3, w: cw, h: 0.45, fontSize: 13.5, color: C.roseMute, align: 'center' }));
  }

  await pres.writeFile({ fileName: process.env.OUT || '/tmp/deck/nabda_projet_innovant.pptx' });
  console.log('written');
})();
