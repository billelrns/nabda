import 'package:flutter/material.dart';

// ─── Colors ───
const Color _bgColor = Color(0xFFFFF5F7);
const Color _cardColor = Colors.white;
const Color _teal = Color(0xFF00897B);
const Color _pink = Color(0xFFE91E63);
const Color _softPink = Color(0xFFFFE8EC);
const Color _textPrimary = Color(0xFF2D2D3A);
const Color _textSecondary = Color(0xFF6B7280);

// ─── Article Model ───
class _DiscoverArticle {
  final String title;
  final String content;
  final String emoji;
  final Color gradientStart;
  final Color gradientEnd;

  const _DiscoverArticle({
    required this.title,
    required this.content,
    required this.emoji,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

// ─── Category Model ───
class _ArticleCategory {
  final String name;
  final String emoji;
  final List<_DiscoverArticle> articles;

  const _ArticleCategory({
    required this.name,
    required this.emoji,
    required this.articles,
  });
}

// ─── All Categories Data ───
final List<_ArticleCategory> _categories = [
  // ── أسبوع بأسبوع ──
  _ArticleCategory(
    name: 'أسبوع بأسبوع',
    emoji: '🤰',
    articles: [
      _DiscoverArticle(
        title: 'التغيرات في جسمك أسبوعياً',
        emoji: '🤰',
        gradientStart: const Color(0xFFE91E63),
        gradientEnd: const Color(0xFFAD1457),
        content: 'يمر جسمك بتغيرات مذهلة كل أسبوع. في الثلث الأول يبدأ الرحم بالتوسع وتشعرين بالغثيان الصباحي بسبب ارتفاع هرمون HCG. في الثلث الثاني يكبر البطن ويبدأ الجنين بالحركة، وتتحسن الطاقة عادة. في الثلث الأخير يزداد الوزن بشكل ملحوظ ويستعد الجسم للولادة مع تقلصات براكستون هيكس. راقبي التغيرات واستشيري طبيبتك عند أي قلق.',
      ),
      _DiscoverArticle(
        title: 'مراحل نمو الجنين',
        emoji: '👶',
        gradientStart: const Color(0xFF7E57C2),
        gradientEnd: const Color(0xFF4527A0),
        content: 'في الأسابيع 1-4 تتكون البويضة المخصبة وتنغرس في الرحم. في الأسبوع 8 تتشكل الأعضاء الرئيسية والقلب يبدأ بالنبض. في الأسبوع 12 يكتمل تشكل الأعضاء. في الأسبوع 20 تشعرين بحركة الجنين. في الأسبوع 28 تتطور الرئتان. في الأسبوع 36 ينزل الرأس للحوض استعداداً للولادة. في الأسبوع 40 يكون الجنين مكتمل النمو وجاهز للقاء العالم.',
      ),
      _DiscoverArticle(
        title: 'متى تزورين الطبيبة؟',
        emoji: '🏥',
        gradientStart: const Color(0xFF00897B),
        gradientEnd: const Color(0xFF00695C),
        content: 'الزيارة الأولى تكون بعد تأخر الدورة بأسبوعين. بعدها كل 4 أسابيع حتى الأسبوع 28، ثم كل أسبوعين حتى الأسبوع 36، ثم أسبوعياً حتى الولادة. اذهبي فوراً إذا حدث نزيف، ألم شديد، صداع مستمر، تورم مفاجئ في الوجه واليدين، أو توقف حركة الجنين. لا تترددي أبداً في الاتصال بطبيبتك عند أي قلق.',
      ),
    ],
  ),

  // ── التغذية ──
  _ArticleCategory(
    name: 'التغذية والأطعمة',
    emoji: '🥗',
    articles: [
      _DiscoverArticle(
        title: 'الأطعمة المفيدة للحامل',
        emoji: '🥑',
        gradientStart: const Color(0xFF43A047),
        gradientEnd: const Color(0xFF2E7D32),
        content: 'أهم الأطعمة: السلمون (أوميغا 3 لنمو دماغ الجنين)، البيض (بروتين وكولين)، البقوليات (حمض الفوليك والحديد)، البطاطا الحلوة (فيتامين A)، الخضراوات الورقية (كالسيوم وحديد)، التوت والفراولة (فيتامين C ومضادات أكسدة)، اللحوم الحمراء قليلة الدهن (حديد)، منتجات الألبان (كالسيوم وبروتين)، والمكسرات (دهون صحية وبروتين).',
      ),
      _DiscoverArticle(
        title: 'أطعمة يجب تجنبها',
        emoji: '⚠️',
        gradientStart: const Color(0xFFE53935),
        gradientEnd: const Color(0xFFC62828),
        content: 'تجنبي: اللحوم والأسماك النيئة (السوشي)، الأجبان الطرية غير المبسترة، البيض النيء، الأسماك عالية الزئبق (التونة الكبيرة، سمك أبو سيف)، الكبد بكميات كبيرة (فيتامين A الزائد)، الكافيين أكثر من 200 ملغ يومياً (كوب واحد قهوة)، الكحول نهائياً، والأطعمة غير المطهية جيداً. اغسلي الفواكه والخضراوات جيداً قبل الأكل.',
      ),
      _DiscoverArticle(
        title: 'المشروبات الصحية للحامل',
        emoji: '🥤',
        gradientStart: const Color(0xFF00ACC1),
        gradientEnd: const Color(0xFF00838F),
        content: 'الماء هو الأفضل - اشربي 8-10 أكواب يومياً. عصائر الفواكه الطبيعية بدون سكر مضاف، حليب قليل الدسم أو حليب اللوز المدعم بالكالسيوم، شاي الأعشاب الآمنة مثل البابونج والزنجبيل (يخفف الغثيان)، ماء جوز الهند (غني بالمعادن). قللي من الشاي الأخضر والأسود لاحتوائهما على كافيين، وتجنبي المشروبات الغازية والطاقة.',
      ),
      _DiscoverArticle(
        title: 'الفيتامينات الضرورية',
        emoji: '💊',
        gradientStart: const Color(0xFFFF8F00),
        gradientEnd: const Color(0xFFEF6C00),
        content: 'حمض الفوليك (400 ميكروغرام يومياً) يمنع تشوهات الأنبوب العصبي - ابدأي قبل الحمل إن أمكن. الحديد (27 ملغ) يمنع فقر الدم. الكالسيوم (1000 ملغ) لعظام الجنين. فيتامين D (600 وحدة) لامتصاص الكالسيوم. أوميغا 3 DHA لنمو دماغ وعيني الجنين. فيتامين C لتقوية المناعة وامتصاص الحديد. استشيري طبيبتك قبل تناول أي مكملات.',
      ),
    ],
  ),

  // ── الجسم والتغيرات ──
  _ArticleCategory(
    name: 'الجسم والتغيرات',
    emoji: '🩺',
    articles: [
      _DiscoverArticle(
        title: 'آلام الظهر وكيفية التخفيف',
        emoji: '💆‍♀️',
        gradientStart: const Color(0xFF5C6BC0),
        gradientEnd: const Color(0xFF3949AB),
        content: 'آلام الظهر شائعة بسبب الوزن الزائد وتغير مركز الثقل. للتخفيف: حافظي على وضعية جلوس صحيحة، استخدمي وسادة داعمة للظهر، ارتدي أحذية مريحة مسطحة، نامي على جانبك مع وسادة بين الركبتين، مارسي تمارين إطالة خفيفة يومياً، جربي الكمادات الدافئة، والسباحة ممتازة لتخفيف الضغط على العمود الفقري.',
      ),
      _DiscoverArticle(
        title: 'الغثيان الصباحي',
        emoji: '🤢',
        gradientStart: const Color(0xFF26A69A),
        gradientEnd: const Color(0xFF00897B),
        content: 'يصيب 80% من الحوامل عادة في الثلث الأول. للتخفيف: كلي بسكويت جاف قبل النهوض من السرير، قسّمي الوجبات لـ 5-6 وجبات صغيرة، تجنبي الأطعمة الدسمة والروائح القوية، جربي الزنجبيل (شاي أو حلوى)، اشربي الماء بين الوجبات وليس أثناءها، وارتدي سوار ضغط المعصم. إذا كان الغثيان شديداً ولا تستطيعين الأكل أو الشرب، راجعي طبيبتك فوراً.',
      ),
      _DiscoverArticle(
        title: 'تورم القدمين والساقين',
        emoji: '🦶',
        gradientStart: const Color(0xFF8E24AA),
        gradientEnd: const Color(0xFF6A1B9A),
        content: 'التورم طبيعي في النصف الثاني من الحمل بسبب احتباس السوائل وضغط الرحم. للتخفيف: ارفعي قدميك عند الجلوس، تجنبي الوقوف لفترات طويلة، ارتدي جوارب ضغط طبية، اشربي ماء أكثر (يساعد على التخلص من السوائل الزائدة)، قللي الملح، وامشي يومياً. إذا كان التورم مفاجئاً في الوجه واليدين مع صداع شديد، اذهبي للطوارئ فوراً فقد يكون تسمم حمل.',
      ),
      _DiscoverArticle(
        title: 'علامات التمدد والوقاية',
        emoji: '✨',
        gradientStart: const Color(0xFFEC407A),
        gradientEnd: const Color(0xFFC2185B),
        content: 'تظهر علامات التمدد عند 90% من الحوامل، خاصة على البطن والصدر والأرداف. للوقاية: رطبي بشرتك يومياً بزيت اللوز الحلو أو زبدة الشيا أو زبدة الكاكاو، اشربي كمية كافية من الماء، تناولي أطعمة غنية بفيتامين C وE والزنك، وحافظي على زيادة وزن تدريجية. العلامات تتحسن وتبهت بعد الولادة. لا تستخدمي كريمات الريتينول أثناء الحمل.',
      ),
    ],
  ),

  // ── التمارين والرياضة ──
  _ArticleCategory(
    name: 'التمارين والرياضة',
    emoji: '🧘‍♀️',
    articles: [
      _DiscoverArticle(
        title: 'المشي أثناء الحمل',
        emoji: '🚶‍♀️',
        gradientStart: const Color(0xFF66BB6A),
        gradientEnd: const Color(0xFF43A047),
        content: 'المشي هو أفضل تمرين للحامل. ابدأي بـ 15 دقيقة يومياً وزيدي تدريجياً حتى 30 دقيقة. فوائده: يحسن الدورة الدموية، يقلل التورم والإمساك، يحسن المزاج والنوم، يساعد على التحكم بالوزن، ويقوي العضلات استعداداً للولادة. ارتدي حذاء مريح وداعم، اختاري أوقات معتدلة الحرارة، واحملي معك ماء. توقفي عند الشعور بدوخة أو ضيق تنفس.',
      ),
      _DiscoverArticle(
        title: 'يوغا الحوامل',
        emoji: '🧘‍♀️',
        gradientStart: const Color(0xFF7E57C2),
        gradientEnd: const Color(0xFF5E35B1),
        content: 'يوغا الحوامل تجمع بين التنفس والإطالة والتأمل. فوائدها: تقوي عضلات الحوض وقاع الحوض، تخفف آلام الظهر، تحسن التوازن والمرونة، تقلل التوتر والقلق، وتحضرك لتقنيات التنفس أثناء المخاض. وضعيات آمنة: وضعية القطة والبقرة، وضعية الفراشة، وضعية المحارب المعدلة. تجنبي وضعيات الاستلقاء على الظهر بعد الأسبوع 20 والالتواءات العميقة.',
      ),
      _DiscoverArticle(
        title: 'السباحة للحامل',
        emoji: '🏊‍♀️',
        gradientStart: const Color(0xFF29B6F6),
        gradientEnd: const Color(0xFF0288D1),
        content: 'السباحة من أفضل الرياضات أثناء الحمل لأن الماء يدعم وزنك ويخفف الضغط على المفاصل والظهر. فوائدها: تمرين كامل للجسم بدون إجهاد، تخفف تورم القدمين، تحسن الدورة الدموية، وتبرد الجسم في الأيام الحارة. يمكنك السباحة طوال فترة الحمل ما لم تمنعك طبيبتك. تجنبي الماء الساخن جداً (الجاكوزي) وحمامات البخار.',
      ),
      _DiscoverArticle(
        title: 'تمارين كيجل المهمة',
        emoji: '💪',
        gradientStart: const Color(0xFFEF5350),
        gradientEnd: const Color(0xFFE53935),
        content: 'تمارين كيجل تقوي عضلات قاع الحوض المهمة للولادة ومنع سلس البول. الطريقة: اقبضي عضلات الحوض (كأنك تمنعين التبول) لمدة 5 ثوان ثم استرخي 5 ثوان. كرري 10 مرات، 3 مجموعات يومياً. يمكنك ممارستها في أي مكان - أثناء الجلوس أو الوقوف أو الاستلقاء. ابدأي من الثلث الأول واستمري بعد الولادة. هذه التمارين تسرع التعافي بعد الولادة أيضاً.',
      ),
    ],
  ),

  // ── الرضاعة والمولود ──
  _ArticleCategory(
    name: 'الرضاعة والمولود',
    emoji: '🤱',
    articles: [
      _DiscoverArticle(
        title: 'الرضاعة الطبيعية: البداية',
        emoji: '🤱',
        gradientStart: const Color(0xFFE91E63),
        gradientEnd: const Color(0xFFC2185B),
        content: 'ابدأي الرضاعة خلال الساعة الأولى بعد الولادة. اللبأ (الحليب الأول) غني بالأجسام المضادة. ضعي طفلك على بطنك مباشرة (ملامسة الجلد للجلد). تأكدي أن فمه يغطي معظم الهالة وليس فقط الحلمة. أرضعيه عند الطلب (8-12 مرة يومياً في البداية). الرضاعة الصحيحة لا تسبب ألماً - إذا كان هناك ألم فالوضعية تحتاج تعديل. لا تترددي في طلب مساعدة استشارية رضاعة.',
      ),
      _DiscoverArticle(
        title: 'تحضير حقيبة المولود',
        emoji: '👶',
        gradientStart: const Color(0xFF42A5F5),
        gradientEnd: const Color(0xFF1E88E5),
        content: 'أساسيات المولود: 6-8 بدلات قطنية (أحجام مختلفة)، قبعات وجوارب، بطانيات قطنية خفيفة، حفاضات حديثي الولادة (كمية كبيرة!)، مناديل مبللة خالية من العطور، كريم طفح الحفاض، حوض استحمام صغير، شامبو وصابون لطيف، فرشاة شعر ناعمة، مقص أظافر خاص بالأطفال، ميزان حرارة، وكرسي سيارة آمن. جهزي كل شيء من الأسبوع 34.',
      ),
      _DiscoverArticle(
        title: 'الرضاعة بالزجاجة',
        emoji: '🍼',
        gradientStart: const Color(0xFF26C6DA),
        gradientEnd: const Color(0xFF00ACC1),
        content: 'إذا اخترتِ الرضاعة الصناعية أو تحتاجين للمزج: اختاري حليباً صناعياً مناسباً لعمر طفلك. عقمي الزجاجات والحلمات قبل كل استخدام. حضري الحليب بالماء المغلي المبرد (70 درجة). لا تسخني في الميكروويف. تأكدي من درجة حرارة الحليب بوضع قطرات على معصمك. احملي طفلك بزاوية 45 درجة أثناء الرضاعة. تخلصي من الحليب المتبقي خلال ساعة.',
      ),
    ],
  ),

  // ── النوم والراحة ──
  _ArticleCategory(
    name: 'النوم والراحة',
    emoji: '😴',
    articles: [
      _DiscoverArticle(
        title: 'وضعيات النوم الآمنة',
        emoji: '🛏️',
        gradientStart: const Color(0xFF5C6BC0),
        gradientEnd: const Color(0xFF3F51B5),
        content: 'النوم على الجانب الأيسر هو الأفضل - يحسن تدفق الدم للجنين والكلى والرحم. ضعي وسادة بين ركبتيك لراحة الحوض والظهر. استخدمي وسادة الحمل الطويلة (U-shape) لدعم البطن والظهر معاً. بعد الأسبوع 20 تجنبي النوم على الظهر لأن وزن الرحم يضغط على الوريد الأجوف السفلي. إذا استيقظتِ على ظهرك لا تقلقي، فقط انقلبي على جانبك.',
      ),
      _DiscoverArticle(
        title: 'التغلب على الأرق',
        emoji: '🌙',
        gradientStart: const Color(0xFF7E57C2),
        gradientEnd: const Color(0xFF512DA8),
        content: 'الأرق شائع خاصة في الثلث الثالث. نصائح: حافظي على روتين نوم ثابت، تجنبي الشاشات قبل النوم بساعة، خذي حماماً دافئاً قبل النوم، مارسي تمارين تنفس عميق أو تأمل، اشربي حليباً دافئاً أو بابونج، تجنبي الأكل الثقيل قبل النوم بـ 3 ساعات، قللي السوائل مساءً لتقليل زيارات الحمام، واجعلي غرفة النوم مظلمة وباردة.',
      ),
      _DiscoverArticle(
        title: 'التعب والإرهاق',
        emoji: '😮‍💨',
        gradientStart: const Color(0xFF78909C),
        gradientEnd: const Color(0xFF546E7A),
        content: 'التعب طبيعي خاصة في الثلث الأول والأخير بسبب التغيرات الهرمونية وزيادة الوزن. للتعامل معه: خذي قيلولة قصيرة (20-30 دقيقة) عند الإمكان، كلي وجبات صغيرة متكررة للحفاظ على الطاقة، مارسي رياضة خفيفة كالمشي، اقبلي المساعدة من الآخرين، لا تشعري بالذنب للراحة، وتأكدي من عدم نقص الحديد - فقر الدم يزيد التعب بشكل كبير.',
      ),
    ],
  ),

  // ── الصحة النفسية ──
  _ArticleCategory(
    name: 'الصحة النفسية',
    emoji: '🧠',
    articles: [
      _DiscoverArticle(
        title: 'التقلبات المزاجية',
        emoji: '😊',
        gradientStart: const Color(0xFFFFB300),
        gradientEnd: const Color(0xFFF57F17),
        content: 'التقلبات المزاجية طبيعية 100% بسبب الهرمونات المتغيرة (الإستروجين والبروجسترون). من الطبيعي أن تبكي بدون سبب، تشعري بالفرح ثم الحزن فجأة، أو تنزعجي من أشياء صغيرة. للتعامل: تحدثي عن مشاعرك مع شريكك أو صديقة، مارسي رياضة خفيفة، خصصي وقتاً لهوايتك، نامي كفاية. تذكري أن هذا مؤقت وليس ضعفاً.',
      ),
      _DiscoverArticle(
        title: 'القلق من الولادة',
        emoji: '💭',
        gradientStart: const Color(0xFF26A69A),
        gradientEnd: const Color(0xFF00897B),
        content: 'القلق من الولادة طبيعي خاصة في الحمل الأول. للتعامل: تعلمي عن مراحل الولادة (المعرفة تقلل الخوف)، احضري دورة تحضير للولادة، تعلمي تقنيات التنفس والاسترخاء، تحدثي مع أمهات مررن بالتجربة، ناقشي مخاوفك مع طبيبتك بصراحة، حضري خطة ولادة مرنة. تذكري أن جسمك مصمم لهذه اللحظة وأنتِ أقوى مما تظنين.',
      ),
      _DiscoverArticle(
        title: 'اكتئاب ما بعد الولادة',
        emoji: '🤗',
        gradientStart: const Color(0xFFAB47BC),
        gradientEnd: const Color(0xFF8E24AA),
        content: 'يصيب 1 من كل 7 أمهات. الأعراض: حزن مستمر لأكثر من أسبوعين، عدم الرغبة في الاهتمام بالطفل، بكاء مستمر، أرق أو نوم مفرط، فقدان الشهية، شعور بالذنب أو عدم الكفاءة. هذا ليس ضعفاً بل حالة طبية تحتاج علاج. تحدثي مع طبيبتك فوراً إذا شعرتِ بهذه الأعراض. العلاج متوفر وفعال، ومعظم الأمهات يتعافين تماماً.',
      ),
    ],
  ),

  // ── العمل والحمل ──
  _ArticleCategory(
    name: 'العمل والحمل',
    emoji: '💼',
    articles: [
      _DiscoverArticle(
        title: 'متى تخبرين عملك؟',
        emoji: '📢',
        gradientStart: const Color(0xFF42A5F5),
        gradientEnd: const Color(0xFF1976D2),
        content: 'معظم النساء ينتظرن حتى نهاية الثلث الأول (أسبوع 12-13) بعد التأكد من استقرار الحمل. أخبري مديرك المباشر أولاً في اجتماع خاص، ثم قسم الموارد البشرية. حضري خطة لتغطية عملك أثناء إجازة الأمومة. اعرفي حقوقك القانونية في إجازة الأمومة. إذا كان عملك يتضمن مخاطر (مواد كيميائية، أعمال بدنية شاقة)، أخبريهم مبكراً لترتيب بديل.',
      ),
      _DiscoverArticle(
        title: 'الراحة في المكتب',
        emoji: '🪑',
        gradientStart: const Color(0xFF78909C),
        gradientEnd: const Color(0xFF455A64),
        content: 'نصائح للعمل المكتبي: استخدمي كرسي مريح مع دعم للظهر، ضعي مسنداً للقدمين، قومي وتمشي كل 30 دقيقة، اشربي ماء كافي، احتفظي بوجبات خفيفة صحية في مكتبك، ارتدي ملابس مريحة وواسعة، ارفعي شاشة الكمبيوتر لمستوى العين. إذا كنتِ تقفين كثيراً استخدمي مسنداً مضاداً للتعب وارتدي حذاءً مريحاً.',
      ),
      _DiscoverArticle(
        title: 'إجازة الأمومة والتحضير',
        emoji: '📋',
        gradientStart: const Color(0xFFFF7043),
        gradientEnd: const Color(0xFFE64A19),
        content: 'حضري مبكراً: وثقي كل مهامك ومسؤولياتك لمن سيغطي عملك، درّبي زميلتك البديلة قبل الإجازة بشهر، نظمي ملفاتك الرقمية والورقية، أبلغي العملاء والشركاء المهمين، حددي تاريخ بداية الإجازة (عادة أسبوع 36-38). خططي للعودة: هل ستعودين بدوام كامل أم جزئي؟ هل يوجد خيار عمل من المنزل؟ رتبي رعاية الطفل مسبقاً.',
      ),
    ],
  ),

  // ── العلاقات الأسرية ──
  _ArticleCategory(
    name: 'العلاقات والأسرة',
    emoji: '👨‍👩‍👧',
    articles: [
      _DiscoverArticle(
        title: 'دور الأب أثناء الحمل',
        emoji: '👨',
        gradientStart: const Color(0xFF5C6BC0),
        gradientEnd: const Color(0xFF283593),
        content: 'كيف يدعم الزوج: حضور مواعيد الطبيبة ومتابعة تطور الحمل، المساعدة في الأعمال المنزلية خاصة التي تتطلب جهداً بدنياً، تحضير وجبات صحية، تدليك الظهر والقدمين، التحدث مع الجنين (يسمع من الأسبوع 25)، المشاركة في دورة تحضير الولادة، تحضير غرفة الطفل معاً، والأهم: الصبر والتفهم للتقلبات المزاجية.',
      ),
      _DiscoverArticle(
        title: 'تحضير الأبناء للمولود',
        emoji: '👧',
        gradientStart: const Color(0xFFEC407A),
        gradientEnd: const Color(0xFFD81B60),
        content: 'إذا لديكِ أطفال: أخبريهم بالحمل بعد الثلث الأول بطريقة مبسطة تناسب عمرهم. اشركيهم في التحضيرات (اختيار اسم، تزيين الغرفة). اقرأي لهم كتب عن قدوم مولود جديد. أكدي لهم أن حبكم لن يتغير. حضريهم لما سيحدث: "ماما ستذهب للمستشفى وستعود مع أخ/أخت صغير". بعد الولادة خصصي وقتاً خاصاً لكل طفل.',
      ),
      _DiscoverArticle(
        title: 'العلاقة الزوجية والحمل',
        emoji: '❤️',
        gradientStart: const Color(0xFFE91E63),
        gradientEnd: const Color(0xFFAD1457),
        content: 'الحمل يغير ديناميكية العلاقة. تواصلوا بصراحة عن المشاعر والمخاوف. خططوا لمواعيد رومانسية قبل وصول المولود. تقاسموا المسؤوليات والتحضيرات. ناقشوا أسلوب التربية الذي تريدونه. العلاقة الحميمية آمنة في معظم حالات الحمل (استشيري طبيبتك). تذكروا أنكم فريق واحد، والتحديات الحالية مؤقتة وستقوي علاقتكم.',
      ),
    ],
  ),

  // ── الفحوصات الطبية ──
  _ArticleCategory(
    name: 'الفحوصات الطبية',
    emoji: '🔬',
    articles: [
      _DiscoverArticle(
        title: 'فحوصات الثلث الأول',
        emoji: '🩸',
        gradientStart: const Color(0xFFE53935),
        gradientEnd: const Color(0xFFC62828),
        content: 'أسبوع 6-8: أول سونار للتأكد من الحمل ونبض القلب. أسبوع 8-10: تحاليل دم شاملة (فصيلة الدم، فقر الدم، السكر، الغدة الدرقية، التهاب الكبد B، فيروس نقص المناعة). أسبوع 11-13: فحص الشفافية القفوية (nuchal translucency) للكشف عن متلازمة داون، مع تحليل دم PAPP-A. هذه الفحوصات مهمة جداً لاكتشاف أي مشاكل مبكراً.',
      ),
      _DiscoverArticle(
        title: 'فحص السونار التفصيلي',
        emoji: '📺',
        gradientStart: const Color(0xFF7E57C2),
        gradientEnd: const Color(0xFF4527A0),
        content: 'يجرى في الأسبوع 18-22 ويسمى "فحص التشوهات" أو Anomaly Scan. يفحص الطبيب: الدماغ والعمود الفقري، القلب وحجراته الأربع، الكلى والمثانة، المعدة والأمعاء، الأطراف والأصابع، المشيمة وكمية السائل الأمنيوسي، وطول عنق الرحم. يمكن معرفة جنس الجنين في هذا الفحص. هذا أهم فحص خلال الحمل - لا تفوتيه.',
      ),
      _DiscoverArticle(
        title: 'فحص سكر الحمل',
        emoji: '🍬',
        gradientStart: const Color(0xFFFF8F00),
        gradientEnd: const Color(0xFFEF6C00),
        content: 'يجرى في الأسبوع 24-28. الطريقة: تشربين محلول سكري (75 أو 100 غرام جلوكوز) ويقاس السكر في الدم قبل وبعد ساعة وساعتين. سكر الحمل يصيب 5-10% من الحوامل ويزيد خطر كبر حجم الجنين وصعوبات الولادة. إذا شُخّص: اتبعي حمية قليلة السكر، مارسي رياضة خفيفة، وقد تحتاجين إنسولين. معظم الحالات تختفي بعد الولادة.',
      ),
    ],
  ),

  // ── الجمال والعناية ──
  _ArticleCategory(
    name: 'الجمال والعناية',
    emoji: '💅',
    articles: [
      _DiscoverArticle(
        title: 'العناية بالبشرة',
        emoji: '🧴',
        gradientStart: const Color(0xFFFF7043),
        gradientEnd: const Color(0xFFD84315),
        content: 'التغيرات الهرمونية تؤثر على البشرة. واقي الشمس SPF 50 ضروري يومياً لمنع الكلف. رطبي بشرتك صباحاً ومساءً. استخدمي غسول لطيف خالٍ من العطور. تجنبي: الريتينول، حمض الساليسيليك، البنزويل بيروكسايد، وتفتيح البشرة بالهيدروكينون. آمنة: حمض الهيالورونيك، فيتامين C، نياسيناميد، وزيوت طبيعية. إذا ظهر حب شباب الحمل استشيري طبيبة جلدية.',
      ),
      _DiscoverArticle(
        title: 'العناية بالشعر',
        emoji: '💇‍♀️',
        gradientStart: const Color(0xFF8D6E63),
        gradientEnd: const Color(0xFF5D4037),
        content: 'هرمونات الحمل تجعل الشعر أكثر كثافة ولمعاناً (بسبب تأخر تساقطه الطبيعي). استخدمي شامبو وبلسم لطيفين بدون كبريتات. تجنبي صبغات الشعر الكيميائية في الثلث الأول - يمكنك استخدام الحناء الطبيعية. البروتين والكيراتين غير آمنين أثناء الحمل بسبب الفورمالديهايد. بعد الولادة بـ 3-6 أشهر سيتساقط الشعر الزائد - هذا طبيعي ومؤقت.',
      ),
      _DiscoverArticle(
        title: 'الملابس المريحة',
        emoji: '👗',
        gradientStart: const Color(0xFFAB47BC),
        gradientEnd: const Color(0xFF7B1FA2),
        content: 'استثمري في ملابس حمل مريحة: أقمشة قطنية قابلة للتمدد، حمالات صدر داعمة بدون أسلاك، بنطلونات بحزام مطاطي مريح، فساتين واسعة، وأحذية مسطحة مريحة. لا تحتاجين شراء خزانة كاملة - اشتري قطع أساسية يمكن تنسيقها معاً. يمكنك استخدام حزام تمديد البنطلون لارتداء بنطلوناتك العادية فترة أطول.',
      ),
    ],
  ),
];


// ══════════════════════════════════════════════
//  Discover Articles Screen (صفحة اكتشفي)
// ══════════════════════════════════════════════

class DiscoverArticlesScreen extends StatelessWidget {
  const DiscoverArticlesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 70,
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'اكتشفي',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _softPink,
                      shape: BoxShape.circle,
                      border: Border.all(color: _pink.withOpacity(0.2), width: 1.5),
                    ),
                    child: const Icon(Icons.person, color: _pink, size: 24),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: const Color(0xFFEEEEEE)),
              ),
            ),

            // ── Categories list ──
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = _categories[index];
                  return _CategorySection(category: category);
                },
                childCount: _categories.length,
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}


// ── Category Section Widget ──
class _CategorySection extends StatelessWidget {
  final _ArticleCategory category;
  const _CategorySection({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine layout: first article big, rest in grid of 2
    final articles = category.articles;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(category.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal scrollable cards
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true, // RTL support
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: articles.length,
              itemBuilder: (context, i) {
                final article = articles[i];
                final isFirst = i == 0;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _DiscoverArticleDetailScreen(
                          article: article,
                          categoryName: category.name,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: isFirst ? 280 : 200,
                    margin: EdgeInsets.only(left: i == articles.length - 1 ? 0 : 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          article.gradientStart.withOpacity(0.15),
                          article.gradientStart.withOpacity(0.05),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: article.gradientStart.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background emoji pattern
                        Positioned(
                          left: -10,
                          bottom: -10,
                          child: Text(
                            article.emoji,
                            style: TextStyle(
                              fontSize: isFirst ? 100 : 70,
                              color: article.gradientStart.withOpacity(0.08),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: article.gradientStart.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.article_outlined, size: 14, color: article.gradientStart),
                                    const SizedBox(width: 4),
                                    Text(
                                      'مقال',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: article.gradientStart,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Emoji
                              Text(article.emoji, style: const TextStyle(fontSize: 36)),
                              const SizedBox(height: 8),
                              // Title
                              Text(
                                article.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


// ── Article Detail Screen ──
class _DiscoverArticleDetailScreen extends StatelessWidget {
  final _DiscoverArticle article;
  final String categoryName;

  const _DiscoverArticleDetailScreen({
    Key? key,
    required this.article,
    required this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _teal,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  categoryName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        article.gradientStart.withOpacity(0.2),
                        article.gradientEnd.withOpacity(0.05),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: article.gradientStart.withOpacity(0.15),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(article.emoji, style: const TextStyle(fontSize: 50)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: article.gradientStart.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.article_outlined, size: 14, color: article.gradientStart),
                          const SizedBox(width: 4),
                          Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: article.gradientStart,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Meta
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: _textSecondary.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          '3 دقائق قراءة',
                          style: TextStyle(fontSize: 12, color: _textSecondary.withOpacity(0.6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: const Color(0xFFEEEEEE)),
                    const SizedBox(height: 20),

                    // Content card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        article.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 2.0,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tip box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _teal.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _teal.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lightbulb_outline, color: _teal, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'نصيحة مهمة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _teal,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'استشيري طبيبتك دائماً قبل اتخاذ أي قرارات صحية. كل حمل مختلف وما يناسب غيرك قد لا يناسبك.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
