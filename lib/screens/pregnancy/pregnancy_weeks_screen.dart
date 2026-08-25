import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/pregnancy_week_articles.dart';
import 'end_pregnancy_screen.dart';
import '../trackers/health_trackers_screen.dart';
import '../../widgets/news_section.dart';
import '../../widgets/personalized_tips.dart';
import '../../widgets/conditional_content.dart';
import '../../services/dynamic_content_service.dart';
import '../../widgets/nabda_ui.dart';
import '../../utils/article_images.dart';


// ─── Fetus Image Helper ───
String _fetusImagePath(int week) {
  // المجموعة الموحدة الجديدة (خلفية شفافة): كل الأسابيع 4..41 متوفرة
  final w = week.clamp(4, 41);
  return 'assets/images/fetus_hd/week_$w.png';
}

// ─── Light Theme Colors ───
const Color _bgColor = Color(0xFFFFF5F7); // Very light pink background
const Color _cardColor = Colors.white;
const Color _teal = Color(0xFF00897B); // Primary teal
const Color _pink = Color(0xFFE91E63); // Accent pink
const Color _softPink = Color(0xFFFFE8EC); // Soft pink for badges/cards
const Color _lightTeal = Color(0xFFE0F2F1); // Light teal for badges
const Color _textPrimary = Color(0xFF2D2D3A); // Dark text
const Color _textSecondary = Color(0xFF6B7280); // Grey text
const Color _divider = Color(0xFFEEEEEE);

// ─── Pregnancy Articles Data ───
class _PregnancyArticle {
  final String title;
  final String subtitle;
  final String category;
  final String emoji;
  final Color color;
  final Color bgColor;
  final String content;
  final String image;

  const _PregnancyArticle({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.content,
    this.image = '',
  });
}

final List<_PregnancyArticle> _pregnancyArticles = [
  _PregnancyArticle(
    title: 'التغذية السليمة أثناء الحمل',
    subtitle: 'دليلك الشامل للأكل الصحي',
    category: 'التغذية',
    emoji: '🥗',
    color: const Color(0xFF43A047),
    bgColor: const Color(0xFFE8F5E9),
    image: 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=800&q=80',
    content: 'التغذية السليمة خلال فترة الحمل ليست مجرد رفاهية بل هي ركيزة أساسية تضمن صحة الأم وسلامة نمو الجنين طوال أشهر الحمل التسعة. يحتاج جسم المرأة الحامل إلى عناصر غذائية محددة بكميات أكبر من المعتاد لدعم التغيرات الجسدية المتسارعة وتلبية احتياجات الطفل المتنامي في الرحم. من أهم هذه العناصر البروتينات التي تحصلين عليها من اللحوم البيضاء كالدجاج والأسماك ومن البقوليات كالعدس والفول والحمص. الكالسيوم ضروري لبناء عظام وأسنان الجنين ويمكنك الحصول عليه من منتجات الألبان والخضروات الورقية الداكنة مثل السبانخ والبروكلي والكرنب. حمض الفوليك من أهم الفيتامينات خاصة في الثلث الأول من الحمل إذ يساعد في تكوين الأنبوب العصبي للجنين ويقلل من مخاطر التشوهات الخلقية. تجدينه في السبانخ والعدس والأفوكادو والحمضيات. الحديد أيضاً عنصر حيوي لأن حجم الدم يزداد بنسبة خمسين بالمئة أثناء الحمل فتحتاجين إلى كمية أكبر منه لمنع فقر الدم. تناولي اللحوم الحمراء والسبانخ والتمر لتعزيز مخزون الحديد. اشربي ما لا يقل عن ثمانية أكواب من الماء يومياً للحفاظ على ترطيب الجسم ودعم السائل الأمنيوسي. تجنبي الأطعمة النيئة والأسماك عالية الزئبق مثل التونة الكبيرة وسمك أبو سيف لأنها قد تضر بالجهاز العصبي للجنين. قللي من الكافيين إلى أقل من مئتي ملليغرام يومياً أي ما يعادل فنجاناً واحداً من القهوة. قسمي وجباتك إلى خمس أو ست وجبات صغيرة على مدار اليوم بدلاً من ثلاث وجبات كبيرة لتجنب الغثيان والحموضة وللحفاظ على مستوى مستقر من السكر في الدم. لا تنسي تناول مكملات الحمل التي وصفتها لك طبيبتك بانتظام واستشيريها قبل إضافة أي مكمل جديد إلى نظامك الغذائي. احرصي على تنويع مصادر غذائك بين الحبوب الكاملة كالشوفان والأرز البني والكينوا والفواكه الطازجة الموسمية والمكسرات النيئة غير المملحة كاللوز والجوز. تناولي وجبة إفطار متكاملة كل صباح ولا تتخطيها أبداً فهي تمنحك الطاقة اللازمة لبداية يومك. أضيفي البذور مثل بذور الشيا والكتان إلى السلطات والعصائر لزيادة محتوى أوميغا ثلاثة المهم لنمو دماغ الجنين. استمتعي بوجباتك واجعلي من وقت الطعام تجربة ممتعة تشاركينها مع عائلتك فالسعادة أثناء الأكل تحسن عملية الهضم والامتصاص.',
  ),
  _PregnancyArticle(
    title: 'تمارين رياضية آمنة للحامل',
    subtitle: 'حافظي على لياقتك بأمان',
    category: 'الرياضة',
    emoji: '🧘‍♀️',
    color: const Color(0xFF5C6BC0),
    bgColor: const Color(0xFFE8EAF6),
    image: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&q=80',
    content: 'ممارسة الرياضة أثناء الحمل من أفضل القرارات التي يمكنك اتخاذها لصحتك وصحة جنينك شرط أن تكون التمارين مناسبة وآمنة ومعتمدة من طبيبتك المتابعة لحملك. الرياضة المنتظمة تساعد على تخفيف آلام الظهر المزعجة التي تصاحب زيادة وزن البطن وتحسن المزاج بفضل إفراز هرمونات السعادة كالإندورفين وتعزز جودة النوم وتقلل من خطر سكري الحمل وتسمم الحمل. المشي اليومي من أبسط وأفضل التمارين يمكنك البدء بعشر دقائق وزيادة المدة تدريجياً حتى ثلاثين دقيقة يومياً. اختاري أحذية مريحة ومسطحات آمنة وتجنبي الأرض غير المستوية والحرارة الشديدة. السباحة تعتبر رياضة مثالية للحامل لأن الماء يدعم وزن الجسم ويخفف الضغط على المفاصل والعمود الفقري ويقلل التورم في القدمين والساقين. يوغا الحوامل تركز على التنفس العميق والاسترخاء وتقوية عضلات الحوض والظهر مما يساعد في تسهيل الولادة. ابحثي عن حصص مخصصة للحوامل مع مدربة متخصصة. تمارين كيجل من أهم التمارين التي يجب ممارستها يومياً فهي تقوي عضلات قاع الحوض وتساعد في التحكم بالمثانة وتسهل عملية الولادة الطبيعية وتسرع التعافي بعدها. مارسيها ثلاث مرات يومياً بعشر تكرارات في كل مرة. تجنبي التمارين العنيفة والرياضات التي تتضمن خطر السقوط كركوب الخيل والتزلج والغطس. توقفي فوراً عن التمرين إذا شعرتِ بدوخة أو ضيق تنفس شديد أو ألم في البطن أو نزيف أو تسرب سوائل. استشيري طبيبتك قبل البدء بأي برنامج رياضي واستمعي لجسمك دائماً فهو أفضل مرشد لك. من المهم أيضاً ممارسة تمارين الإطالة اللطيفة صباحاً لتخفيف تيبس العضلات والمفاصل خاصة في منطقة الظهر والكتفين. يمكنك استخدام كرة التمارين الكبيرة للجلوس عليها بدلاً من الكرسي العادي فهي تساعد في تقوية عضلات الجذع وتحسين وضعية الجسم. تمارين التنفس العميق ليست فقط للاسترخاء بل تدربك على التنفس الصحيح أثناء المخاض وتزود جسمك وجنينك بالأكسجين الكافي. خصصي وقتاً ثابتاً يومياً للتمرين واجعليه جزءاً من روتينك اليومي الذي تستمتعين به. تذكري أن الهدف ليس خسارة الوزن بل الحفاظ على لياقة جسمك وتهيئته للولادة والتعافي بعدها. كل دقيقة تقضينها في الحركة هي استثمار في صحتك وصحة طفلك ومستقبل ولادتك السعيدة بإذن الله.',
  ),
  _PregnancyArticle(
    title: 'الصحة النفسية أثناء الحمل',
    subtitle: 'اعتني بمشاعرك وصحتك النفسية',
    category: 'الصحة النفسية',
    emoji: '💆‍♀️',
    color: const Color(0xFF7E57C2),
    bgColor: const Color(0xFFF3E5F5),
    image: 'https://images.unsplash.com/photo-1515894203077-3c3d655c1b53?w=800&q=80',
    content: 'الصحة النفسية أثناء الحمل لا تقل أهمية عن الصحة الجسدية بل إنها تؤثر بشكل مباشر على صحة الجنين ونموه وعلى تجربة الحمل بأكملها. التقلبات المزاجية من أكثر الأعراض شيوعاً خلال الحمل وهي ناتجة عن التغيرات الهرمونية الكبيرة التي يمر بها الجسم إضافة إلى المخاوف الطبيعية المرتبطة بالأمومة والمسؤولية الجديدة. من الطبيعي أن تشعري بالقلق أحياناً لكن المهم ألا تدعي هذه المشاعر تسيطر على حياتك اليومية. تحدثي بصراحة عن مشاعرك مع شريكك أو صديقة مقربة أو أحد أفراد عائلتك فمشاركة المشاعر تخفف من ثقلها كثيراً. مارسي تقنيات الاسترخاء يومياً مثل التنفس العميق والتأمل الموجه فعشر دقائق فقط يومياً يمكن أن تحدث فرقاً كبيراً في مستوى القلق والتوتر. خصصي وقتاً لنفسك كل يوم للقيام بأنشطة تستمتعين بها كالقراءة أو الرسم أو الاستماع للموسيقى الهادئة أو المشي في الطبيعة. النوم الكافي بين سبع وتسع ساعات يلعب دوراً محورياً في تحسين المزاج والحفاظ على الاستقرار النفسي. حاولي تنظيم مواعيد نومك والابتعاد عن الشاشات قبل النوم بساعة على الأقل. النشاط البدني المعتدل كالمشي أو اليوغا يساعد في إفراز هرمونات السعادة ويحسن الحالة النفسية. حافظي على تغذية سليمة لأن نقص بعض الفيتامينات كفيتامين د والحديد وأوميغا ثلاثة يمكن أن يؤثر سلباً على المزاج. إذا شعرتِ بحزن مستمر أو قلق شديد أو فقدان الاهتمام بالأنشطة التي كنتِ تستمتعين بها لأكثر من أسبوعين فلا تترددي في استشارة متخصص في الصحة النفسية. طلب المساعدة ليس ضعفاً بل هو أقوى خطوة يمكنك اتخاذها من أجلك ومن أجل طفلك. انضمي إلى مجموعة دعم للحوامل سواء محلياً أو عبر الإنترنت فمشاركة تجربتك مع أمهات يمررن بنفس المرحلة يخفف الشعور بالوحدة ويمنحك نصائح عملية قيمة. دوني مشاعرك في مذكرة يومية فالكتابة التعبيرية أداة فعالة لتفريغ المشاعر وفهمها بشكل أعمق. تجنبي مقارنة تجربتك بتجارب الأخريات فكل حمل فريد ومميز بطريقته. ركزي على اللحظة الحالية واستمتعي بكل مرحلة من مراحل هذه الرحلة الاستثنائية التي لن تتكرر بنفس الشكل. أحيطي نفسك بأشخاص إيجابيين يدعمونك وابتعدي عن مصادر الطاقة السلبية. تذكري دائماً أنك تقومين بعمل عظيم وأن جسمك يصنع معجزة حقيقية تستحقين عليها كل التقدير والاحتفاء.',
  ),
  _PregnancyArticle(
    title: 'تحضيرات ما قبل الولادة',
    subtitle: 'كل ما تحتاجين معرفته',
    category: 'الولادة',
    emoji: '🏥',
    color: _pink,
    bgColor: _softPink,
    image: 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=800&q=80',
    content: 'التحضير للولادة رحلة ممتعة ومهمة تبدأ من الثلث الثالث للحمل وتتطلب تنظيماً وتخطيطاً مسبقاً لضمان تجربة سلسة وآمنة لك ولطفلك القادم. ابدئي بتحضير حقيبة المستشفى من الأسبوع السادس والثلاثين تحسباً لأي طارئ. جهزي لنفسك ملابس مريحة وفضفاضة وقميص نوم يسهل فتحه للرضاعة ونعال مريحة وأدوات النظافة الشخصية ومستحضرات الترطيب. لا تنسي أوراقك الطبية ونتائج كل الفحوصات وبطاقة التأمين الصحي وبطاقة الهوية. للمولود حضري ملابس قطنية ناعمة مناسبة للموسم وحفاضات لحديثي الولادة وبطانية دافئة وقبعة صغيرة. اختاري مستشفى الولادة مسبقاً وقومي بزيارتها للتعرف على أقسامها وغرف الولادة وطاقم التمريض. اسألي عن سياسات المرافقة أثناء الولادة وعن توفر غرف خاصة. حضري خطة ولادة مكتوبة تتضمن تفضيلاتك حول نوع الولادة سواء طبيعية أو قيصرية ونوع التخدير المفضل ومن تريدين بجانبك أثناء المخاض. ناقشي هذه الخطة مع طبيبتك مع الأخذ بعين الاعتبار أن المرونة مطلوبة لأن الظروف قد تتغير. التحقي بدورة تحضير للولادة إن أمكن فهي تعلمك تقنيات التنفس والاسترخاء أثناء المخاض ووضعيات تسهيل الولادة وكيفية التعامل مع الألم. جهزي غرفة الطفل بالأساسيات فقط في البداية مثل سرير آمن يتوافق مع معايير السلامة وطاولة تغيير وأدراج لتنظيم الملابس. رتبي أمور إجازة الأمومة وأبلغي جهة عملك قبل وقت كاف واتفقي مع عائلتك أو أصدقائك على من يمكنه مساعدتك في الأسابيع الأولى بعد الولادة. حضري قائمة بأرقام الطوارئ المهمة واحتفظي بها في مكان يسهل الوصول إليه. فكري أيضاً في تحضير وجبات مجمدة صحية يمكنك تسخينها بسهولة في الأسابيع الأولى بعد الولادة حين يكون وقتك وطاقتك محدودين. اختاري اسماً لطفلك أو حضري قائمة مختصرة من الأسماء المفضلة لديك ولدى شريكك. إذا كان لديك أطفال آخرون حضريهم نفسياً لاستقبال الأخ أو الأخت الجديدة بطريقة إيجابية ومشوقة. ركبي مقعد السيارة الخاص بالرضع قبل الموعد المتوقع واتأكدي من تركيبه بشكل صحيح وفق تعليمات السلامة. تأكدي أن هاتفك مشحون دائماً في الأسابيع الأخيرة واحتفظي بحقيبة المستشفى جاهزة في السيارة أو عند الباب. استمتعي بهذه الفترة الأخيرة قبل قدوم طفلك واستغليها في الراحة والاسترخاء وقضاء وقت ممتع مع شريكك وعائلتك.',
  ),
  _PregnancyArticle(
    title: 'نوم الحامل: نصائح ذهبية',
    subtitle: 'كيف تنامين بشكل مريح',
    category: 'النوم',
    emoji: '😴',
    color: const Color(0xFF0097A7),
    bgColor: const Color(0xFFE0F7FA),
    image: 'https://images.unsplash.com/photo-1531353826977-0941b4779a1c?w=800&q=80',
    content: 'النوم الجيد أثناء الحمل من أكثر التحديات التي تواجه المرأة الحامل خاصة مع تقدم أشهر الحمل وزيادة حجم البطن والتغيرات الهرمونية والجسدية المتلاحقة. لكن بإمكانك تحسين جودة نومك بشكل ملحوظ باتباع مجموعة من النصائح المجربة والفعالة. النوم على الجانب الأيسر هو الوضعية المثلى أثناء الحمل لأنه يحسن تدفق الدم والمغذيات إلى المشيمة والجنين ويساعد الكلى على العمل بكفاءة أكبر في التخلص من السوائل والفضلات مما يقلل التورم في اليدين والقدمين والكاحلين. استخدمي وسادة خاصة بالحوامل أو ضعي وسادة بين ركبتيك لتخفيف الضغط على أسفل الظهر والوركين ووسادة صغيرة تحت البطن لتوفير دعم إضافي. تجنبي تناول وجبات ثقيلة أو حارة قبل النوم بساعتين على الأقل لتقليل الحموضة والارتجاع المريئي. قللي من شرب السوائل في المساء لتقليل عدد زيارات الحمام الليلية لكن احرصي على شرب كميات كافية خلال النهار. حافظي على درجة حرارة غرفة النوم معتدلة ومائلة للبرودة واستخدمي ملابس نوم قطنية خفيفة ومريحة. أنشئي روتيناً مسائياً مهدئاً قبل النوم مثل حمام دافئ أو قراءة كتاب خفيف أو تمارين تنفس واسترخاء. تجنبي استخدام الهاتف والشاشات قبل النوم بساعة لأن الضوء الأزرق يعطل إفراز هرمون الميلاتونين المسؤول عن النوم. إذا كنتِ تعانين من حرقة المعدة ارفعي رأسك بوسادة إضافية أو ارفعي مقدمة السرير قليلاً. تجنبي النوم على الظهر بعد الأسبوع العشرين لأن وزن الرحم يضغط على الوريد الأجوف السفلي مما يقلل تدفق الدم. إذا استيقظتِ ليلاً ولم تستطيعي العودة للنوم فلا تقلقي بل قومي بنشاط هادئ حتى تشعري بالنعاس مجدداً. جربي أيضاً تقنيات الاسترخاء التدريجي للعضلات قبل النوم حيث تشدين كل مجموعة عضلية لبضع ثوانٍ ثم ترخينها بدءاً من القدمين وصولاً للرأس. الروائح المهدئة مثل اللافندر يمكن أن تساعد في الاسترخاء ضعي بضع قطرات على وسادتك أو استخدمي موزعاً للزيوت العطرية في غرفة النوم. إذا كنتِ تعانين من تشنجات الساقين الليلية تناولي أطعمة غنية بالمغنيسيوم مثل الموز والمكسرات وافردي ساقيك قبل النوم. حافظي على نمط نوم منتظم حتى في عطلة نهاية الأسبوع. تذكري أن صعوبات النوم مؤقتة وستنتهي وأن جسمك يتكيف مع وضع استثنائي يستحق كل الصبر والرعاية.',
  ),
  _PregnancyArticle(
    title: 'العناية بالبشرة أثناء الحمل',
    subtitle: 'حافظي على إشراقتك',
    category: 'الجمال',
    emoji: '✨',
    color: const Color(0xFFEF6C00),
    bgColor: const Color(0xFFFFF3E0),
    image: 'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=800&q=80',
    content: 'بشرتك أثناء الحمل تمر بتغيرات كبيرة بسبب التقلبات الهرمونية فقد تلاحظين ظهور الكلف والبقع الداكنة على الوجه أو حب الشباب أو جفاف البشرة أو على العكس زيادة الدهون وتوهج الحمل الشهير. العناية بالبشرة خلال هذه الفترة تتطلب اهتماماً خاصاً مع التأكد من أن كل المنتجات التي تستخدمينها آمنة لك وللجنين. لتجنب الكلف وتصبغات الحمل استخدمي واقي شمس بعامل حماية لا يقل عن خمسين يومياً حتى في الأيام الغائمة وأعيدي تطبيقه كل ساعتين عند التعرض للشمس. ارتدي قبعة واسعة ونظارات شمسية عند الخروج. للوقاية من علامات التمدد التي تظهر عادة على البطن والصدر والأرداف والفخذين رطبي بشرتك يومياً بزيت اللوز الحلو أو زبدة الشيا أو زيت جوز الهند بدءاً من الشهر الثالث ودلكي المنطقة بحركات دائرية لتحسين مرونة الجلد. استخدمي غسولاً لطيفاً خالياً من العطور والكحول لتنظيف الوجه صباحاً ومساءً ورطبي بكريم مناسب لنوع بشرتك. تجنبي تماماً منتجات الريتينول وحمض الساليسيليك المركز والهيدروكينون لأنها غير آمنة أثناء الحمل. اشربي كمية وفيرة من الماء فالترطيب الداخلي ينعكس إيجاباً على نضارة البشرة. تناولي أطعمة غنية بفيتامين سي مثل البرتقال والفراولة والفلفل الأحمر لتعزيز إنتاج الكولاجين وفيتامين إي الموجود في المكسرات والأفوكادو لحماية خلايا البشرة. إذا ظهر حب شباب الحمل تجنبي العبث به واستشيري طبيبة جلدية لوصف منتجات آمنة. تذكري أن معظم هذه التغيرات مؤقتة وستتحسن بعد الولادة فتحلي بالصبر واعتني ببشرتك بلطف ومحبة. يمكنك أيضاً استخدام ماسكات طبيعية آمنة أسبوعياً مثل ماسك العسل مع الزبادي لترطيب البشرة وتفتيحها أو ماسك الأفوكادو المهروس لتغذية البشرة الجافة. خط البطن الداكن الذي يظهر أثناء الحمل طبيعي تماماً ويختفي تدريجياً بعد الولادة فلا تقلقي بشأنه. حافظي على تقشير لطيف للبشرة مرة أسبوعياً بمقشر ناعم لإزالة الخلايا الميتة وتجديد البشرة. دللي نفسك واستمتعي بروتين العناية ببشرتك واعتبريه وقتاً خاصاً بك تستحقينه. احمي شفتيك بمرطب شفاه طبيعي واستخدمي كريم يدين مرطب خاصة في فصل الشتاء. اهتمي بتغذية أظافرك أيضاً فقد تصبح هشة أثناء الحمل بسبب التغيرات الهرمونية واستخدمي زيت فيتامين إي لتقويتها.',
  ),
  _PregnancyArticle(
    title: 'الرضاعة الطبيعية: استعدي مبكراً',
    subtitle: 'فوائدها وكيفية التحضير',
    category: 'الرضاعة',
    emoji: '🤱',
    color: _teal,
    bgColor: _lightTeal,
    image: 'https://images.unsplash.com/photo-1584582397869-3e903bfe9985?w=800&q=80',
    content: 'الرضاعة الطبيعية هي الهدية الأثمن التي يمكنك تقديمها لطفلك فحليب الأم هو الغذاء المثالي الذي صممه الله ليلبي كل احتياجات المولود الجديد الغذائية والمناعية والعاطفية. التحضير المبكر للرضاعة من أهم الخطوات التي يمكنك اتخاذها لضمان تجربة رضاعة ناجحة ومريحة. ابدئي التحضير من الثلث الثالث بقراءة كتب ومقالات موثوقة عن الرضاعة الطبيعية وإن أمكن حضور دورة تحضيرية مع استشارية رضاعة معتمدة. تعرفي على آلية إنتاج الحليب وكيف يتكيف جسمك تلقائياً مع احتياجات طفلك المتغيرة. حليب الأم يحتوي على أجسام مضادة فريدة تحمي الطفل من العدوى والأمراض ويتغير تركيبه باستمرار ليناسب عمر الطفل ووقت الرضاعة من اليوم. الرضاعة الأولى بعد الولادة مباشرة مهمة للغاية فاللبأ وهو الحليب الأول السميك المائل للاصفرار غني جداً بالأجسام المضادة والعناصر الغذائية المركزة ويشكل أول تطعيم طبيعي لطفلك. حاولي إرضاع طفلك خلال الساعة الأولى بعد الولادة إن سمحت الظروف. تعلمي وضعيات الرضاعة الصحيحة لأن الإمساك الصحيح هو مفتاح رضاعة مريحة بدون ألم. يجب أن يفتح الطفل فمه واسعاً ويمسك بالحلمة والهالة المحيطة بها وليس فقط طرف الحلمة. أرضعي طفلك عند الطلب أي كلما أبدى علامات الجوع مثل تحريك الرأس والبحث ومص الأصابع وهذا يعني عادة من ثماني إلى اثنتي عشرة رضعة يومياً في الأسابيع الأولى. اشربي كمية وفيرة من الماء وتناولي ما بين ثلاثمئة وخمسمئة سعرة حرارية إضافية يومياً من مصادر صحية ومتنوعة لدعم إنتاج الحليب. لا تترددي في طلب المساعدة من استشارية رضاعة إذا واجهتِ أي صعوبات فمعظم مشاكل الرضاعة يمكن حلها بتوجيه مختص. تعرفي مسبقاً على علامات الرضاعة الناجحة مثل بلع الطفل المسموع وزيادة وزنه المنتظمة وعدد الحفاضات المبللة الكافي يومياً. جهزي ركناً مريحاً للرضاعة في منزلك بكرسي مريح ووسادة داعمة وطاولة جانبية لوضع الماء والوجبات الخفيفة. اعلمي أن الأيام الأولى قد تكون صعبة لكن الأمور تتحسن كثيراً بعد الأسبوعين الأولين عندما يتعلم الطفل الإمساك الصحيح ويزداد إنتاج الحليب. كوني صبورة مع نفسك وتذكري أنك تتعلمين مهارة جديدة. احتفظي بأرقام استشاريات الرضاعة واخصائيات التغذية لتستشيريهن عند الحاجة وتذكري أن الرضاعة مهارة تتعلمينها أنت وطفلك معاً يوماً بعد يوم.',
  ),
  _PregnancyArticle(
    title: 'فحوصات الحمل المهمة',
    subtitle: 'جدول الفحوصات الدورية',
    category: 'الفحوصات',
    emoji: '🔬',
    color: const Color(0xFFC62828),
    bgColor: const Color(0xFFFFEBEE),
    image: 'https://images.unsplash.com/photo-1631815588090-d4bfec5b1ccb?w=800&q=80',
    content: 'فحوصات الحمل الدورية هي خط الدفاع الأول لضمان سلامتك وسلامة جنينك طوال أشهر الحمل. الالتزام بجدول الفحوصات يمكن الطبيبة من اكتشاف أي مشاكل مبكراً والتعامل معها قبل أن تتفاقم. في الثلث الأول من الحمل تبدأ الرحلة بفحص الدم الشامل الذي يكشف عن مستوى الهيموغلوبين ووظائف الكلى والكبد وفصيلة الدم والعامل الريسوسي. يُجرى فحص السكر الصيامي للكشف عن السكري الموجود مسبقاً وفحص الغدة الدرقية لأن اضطراباتها شائعة أثناء الحمل. أول أشعة تلفزيونية تكون عادة بين الأسبوع السادس والثامن لتأكيد الحمل داخل الرحم وسماع نبض الجنين لأول مرة وهي لحظة لا تُنسى. في الأسبوع الحادي عشر إلى الرابع عشر يُجرى فحص الشفافية القفوية لتقييم مخاطر متلازمة داون. في الثلث الثاني يأتي أهم فحص وهو السونار التفصيلي بين الأسبوع الثامن عشر والثاني والعشرين حيث يفحص الطبيب جميع أعضاء الجنين بالتفصيل من القلب والدماغ والكلى والعمود الفقري والأطراف ويتحقق من وضع المشيمة وكمية السائل الأمنيوسي. في هذا الفحص يمكنك أيضاً معرفة جنس المولود إن رغبتِ. بين الأسبوع الرابع والعشرين والثامن والعشرين يُجرى اختبار تحمل الجلوكوز للكشف عن سكري الحمل وهو فحص مهم جداً لأن سكري الحمل غير المعالج قد يسبب مضاعفات للأم والجنين. في الثلث الثالث تكثر المتابعات فتصبح كل أسبوعين ثم أسبوعياً مع اقتراب الولادة. يُراقب نمو الجنين وحركته ونبضه وكمية السائل ووضعيته. بين الأسبوع الخامس والثلاثين والسابع والثلاثين يُجرى فحص البكتيريا العقدية من المجموعة ب. يُقاس ضغط الدم في كل زيارة للكشف المبكر عن تسمم الحمل. لا تفوتي أي موعد متابعة مع طبيبتك واسأليها عن كل ما يقلقك. احتفظي بملف منظم لجميع نتائج فحوصاتك وأشعتك واحمليه معك في كل زيارة للطبيبة. دوني أسئلتك واستفساراتك قبل كل موعد لتتأكدي من أنك لن تنسي شيئاً مهماً. اسألي طبيبتك عن أي فحص لا تفهمينه ولا تخجلي من طلب التوضيح فصحتك وصحة طفلك تستحقان كل اهتمام. اعتبري كل زيارة فرصة للاطمئنان والتواصل مع طفلك لا مصدر قلق. تذكري أن التقنيات الطبية الحديثة تتيح متابعة دقيقة وآمنة لكل مراحل الحمل. ثقي بفريقك الطبي واستمتعي برؤية طفلك ينمو ويتطور مع كل فحص جديد فهذه لحظات ثمينة تستحق أن تعيشيها بفرح واطمئنان.',
  ),
];

// Fruit data mapping for all 40 weeks
const Map<int, List<String>> _fruitData = {
  1: ['🌱', 'بذرة'],
  2: ['🟤', 'حبة سمسم'],
  3: ['⚪', 'كرة خلوية'],
  4: ['🟤', 'حبة سمسم'],
  5: ['🍎', 'بذرة تفاحة'],
  6: ['🫘', 'حبة عدس'],
  7: ['🫛', 'حبة حمّص'],
  8: ['🫘', 'حبة فاصولياء'],
  9: ['🍒', 'حبة كرز'],
  10: ['🍓', 'فراولة'],
  11: ['🍋', 'ليمونة صغيرة'],
  12: ['🥝', 'كيوي'],
  13: ['🍋', 'ليمونة'],
  14: ['🍑', 'خوخة'],
  15: ['🍎', 'تفاحة'],
  16: ['🥑', 'أفوكادو'],
  17: ['🍐', 'إجاصة'],
  18: ['🔴', 'رمّانة'],
  19: ['🥭', 'مانجو'],
  20: ['🍌', 'موزة'],
  21: ['🥕', 'جزرة'],
  22: ['🥒', 'كوسة'],
  23: ['🍠', 'بطاطا حلوة'],
  24: ['🌽', 'كوز ذرة'],
  25: ['🥔', 'بطاطا كبيرة'],
  26: ['🥬', 'خسّة'],
  27: ['🥦', 'قرنبيطة'],
  28: ['🍆', 'باذنجانة'],
  29: ['🍈', 'شمّامة صغيرة'],
  30: ['🥬', 'رأس ملفوف'],
  31: ['🥥', 'جوز الهند'],
  32: ['🥬', 'ملفوفة حمراء'],
  33: ['🍍', 'أناناس'],
  34: ['🍈', 'شمّامة'],
  35: ['🍈', 'بطيخة صفراء'],
  36: ['🥬', 'رأس خسّ كبير'],
  37: ['🥦', 'قرنبيطة عملاقة'],
  38: ['🍍', 'أناناس كبير'],
  39: ['🍉', 'بطيخة صغيرة'],
  40: ['🍉', 'بطيخة حمراء'],
  41: ['🎃', 'يقطينة كبيرة'],
};

// Trimester-specific medical checklist items
const Map<int, List<List<String>>> _trimesterChecklist = {
  1: [
    ['تناول حمض الفوليك 400 ميكروغرام يومياً', 'folic_acid'],
    ['زيارة طبيب النساء وتسجيل الحمل', 'obgyn_register'],
    ['إجراء اختبارات الدم الأولية', 'blood_test'],
    ['قياس ضغط الدم', 'blood_pressure'],
    ['الفحص الموجات الصوتية الأولى (الثلاثي)', 'ultrasound_1'],
  ],
  2: [
    ['الفحص الموجات الصوتية التفصيلي', 'ultrasound_detailed'],
    ['اختبار تحمل الجلوكوز (screening)', 'glucose_screening'],
    ['فحص الأجسام المضادة', 'antibody_test'],
    ['معالجة أي مشاكل صحية', 'health_issues'],
    ['ممارسة تمارين آمنة للحمل', 'safe_exercises'],
  ],
  3: [
    ['المزيد من اختبارات الموجات الصوتية', 'ultrasound_final'],
    ['فحص انخفاض المشيمة', 'placenta_check'],
    ['قياس كمية السائل الأمنيوسي', 'amniotic_fluid'],
    ['اختبار المجموعة الدموية والعامل الريسوسي', 'blood_group'],
    ['إجراء اختبار المكورات العقدية B', 'strep_b_test'],
  ],
};

class PregnancyWeeksScreen extends StatelessWidget {
  final int? currentWeek;
  final int? daysLeft;
  final double? percent;
  const PregnancyWeeksScreen({Key? key, this.currentWeek, this.daysLeft, this.percent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentWeek != null && currentWeek! >= 1) {
      final week = currentWeek!.clamp(1, 40);
      final article = pregnancyWeekArticles.firstWhere((a) => a.week == week, orElse: () => pregnancyWeekArticles.last);
      return WeekDetailScreen(article: article, currentWeek: currentWeek, daysLeft: daysLeft, percent: percent);
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: const Text(
            'دليل الحمل أسبوعياً',
            style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _divider),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...List.generate(3, (ti) {
            final name = ['الثلث الأول', 'الثلث الثاني', 'الثلث الثالث'][ti];
            final weeks = [
              pregnancyWeekArticles.where((a) => a.week <= 12).toList(),
              pregnancyWeekArticles.where((a) => a.week > 12 && a.week <= 27).toList(),
              pregnancyWeekArticles.where((a) => a.week > 27).toList(),
            ][ti];
            final color = [_teal, _pink, const Color(0xFF7E57C2)][ti];
            final bgGradient = [_lightTeal, _softPink, const Color(0xFFF3E5F5)][ti];
            final range = ['1 - 12', '13 - 27', '28 - 40'][ti];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon([Icons.spa, Icons.child_friendly, Icons.favorite][ti], color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('الأسبوع $range', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${weeks.length} أسبوع',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ]),
              ),
              ...weeks.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WeekDetailScreen(article: a))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: bgGradient,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.asset(
                              _fetusImagePath(a.week),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => CustomPaint(painter: RealisticFetusIllustration(week: a.week, isSmall: true, isOnDark: false)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              'الأسبوع ${a.week}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${a.babySizeAr} (${a.babyLength})',
                              style: const TextStyle(color: _textSecondary, fontSize: 12),
                            ),
                          ]),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: bgGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.arrow_back_ios, size: 14, color: color),
                        ),
                      ]),
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 12),
            ]);
          }),
        ],
      ),
      ),
    );
  }
}

class WeekDetailScreen extends StatefulWidget {
  final PregnancyWeekArticle article;
  final int? currentWeek;
  final int? daysLeft;
  final double? percent;
  const WeekDetailScreen({Key? key, required this.article, this.currentWeek, this.daysLeft, this.percent}) : super(key: key);
  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  Uint8List? _echoImage;
  bool _loadingEcho = true;
  int _kickCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedEcho();
  }

  Future<void> _loadSavedEcho() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingEcho = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('echo_images')
          .doc('week_${widget.article.week}')
          .get();
      if (doc.exists && doc.data()?['imageBase64'] != null) {
        setState(() {
          _echoImage = base64Decode(doc.data()!['imageBase64']);
          _loadingEcho = false;
        });
      } else {
        setState(() => _loadingEcho = false);
      }
    } catch (_) {
      setState(() => _loadingEcho = false);
    }
  }

  Future<void> _pickEchoImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 72, maxWidth: 1024);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.length > 500 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الصورة كبيرة جداً')));
      return;
    }
    setState(() => _echoImage = bytes);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('echo_images')
          .doc('week_${widget.article.week}')
          .set({
        'imageBase64': base64Encode(bytes),
        'week': widget.article.week,
        'updatedAt': FieldValue.serverTimestamp()
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ صورة الإيكو بنجاح'),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// Splits long text into styled paragraphs with spacing
  Widget _buildParagraphedText(String text) {
    List<String> paragraphs;
    if (text.contains('\n\n')) {
      paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    } else {
      paragraphs = [];
      String current = '';
      final sentences = text.trim().split(RegExp(r'(?<=[\.!\?:،])\s+'));
      int sentCount = 0;
      for (final s in sentences) {
        current += (current.isEmpty ? '' : ' ') + s;
        sentCount++;
        if (sentCount >= 3 && current.length > 80) {
          paragraphs.add(current.trim());
          current = '';
          sentCount = 0;
        }
      }
      if (current.trim().isNotEmpty) paragraphs.add(current.trim());
    }
    if (paragraphs.length <= 1) {
      return Text(text, style: const TextStyle(fontSize: 14, height: 1.8, color: _textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(p.trim(), textAlign: TextAlign.justify,
          style: const TextStyle(fontSize: 14, height: 1.8, color: _textSecondary)),
      )).toList(),
    );
  }

  Color get _trimesterColor {
    final w = widget.article.week;
    if (w <= 12) return _teal;
    if (w <= 27) return _pink;
    return const Color(0xFF7E57C2);
  }

  Color get _trimesterBg {
    final w = widget.article.week;
    if (w <= 12) return _lightTeal;
    if (w <= 27) return _softPink;
    return const Color(0xFFF3E5F5);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    final color = _trimesterColor;
    final trimester = a.week <= 12 ? 1 : a.week <= 27 ? 2 : 3;

    final bool isEmbedded = widget.currentWeek != null;
    final content = CustomScrollView(
          slivers: [
            // ─── Header with fetus illustration ───
            SliverAppBar(
              expandedHeight: 380,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _teal,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: !isEmbedded,
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.list_alt, size: 20),
                  ),
                  tooltip: 'جميع الأسابيع',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PregnancyWeeksScreen()),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.date_range, size: 20),
                  ),
                  tooltip: 'تغيير تاريخ الحمل',
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 140)),
                      firstDate: DateTime.now().subtract(const Duration(days: 280)),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Localizations.override(
                          context: context,
                          locale: const Locale('en'),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: _teal, secondary: _pink),
                            ),
                            child: child!,
                          ),
                        );
                      },
                    );
                    if (date != null) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
                          {'pregnancyStartDate': Timestamp.fromDate(date)},
                          SetOptions(merge: true),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.more_horiz, size: 20),
                  ),
                  tooltip: 'تحديث حالة الحمل',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EndPregnancyScreen()),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  a.getMonthAr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 16),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _softPink.withOpacity(0.6),
                        _lightTeal.withOpacity(0.3),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      // ── Circular progress ring with fetus ──
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background ring
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _divider, width: 2),
                              ),
                            ),
                            // Progress ring
                            SizedBox(
                              width: 190,
                              height: 190,
                              child: CustomPaint(
                                painter: _ProgressRingPainter(
                                  progress: (a.week / 40).clamp(0.0, 1.0),
                                  color: _pink,
                                  bgColor: _softPink,
                                ),
                              ),
                            ),
                            // Fetus illustration — جنين يطفو داخل رحم ثابت
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: _pink.withOpacity(0.12), blurRadius: 20, spreadRadius: 5),
                                ],
                              ),
                              child: WombFloatingFetus(
                                fetusAsset: _fetusImagePath(a.week),
                                size: 145,
                              ),
                            ),
                            // Week badge
                            Positioned(
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _teal,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Text(
                                  'الأسبوع ${a.week}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Fruit comparison
                      if (_fruitData[a.week] != null) ...[
                        Text(
                          _fruitData[a.week]![0],
                          style: const TextStyle(fontSize: 30),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'بحجم ${_fruitData[a.week]![1]}',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _trimesterBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            a.getTrimesterAr(),
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ─── Content ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Progress card (if current week)
                    if (widget.currentWeek != null) ...[
                      _buildProgressCard(color),
                      const SizedBox(height: 16),
                    ],

                    // ── Quick info row ──
                    _buildQuickInfoRow(a),
                    const SizedBox(height: 16),

                    // محتوى مخصّص حسب ملف المستخدمة — يظهر بشكل كاروسال أفقي
                    const ConditionalContentSection(stage: 'pregnant', horizontal: true),
                    const SizedBox(height: 16),

                    // ── بطاقة خطّة الولادة (الشهر الثامن، أسبوع ≥ 32) ──
                    if (widget.currentWeek != null && widget.currentWeek! >= 32) ...[
                      const _BirthPlanPrompt(),
                    ],

                    // ── Articles Carousel ──
                    _buildArticlesCarousel(),
                    const SizedBox(height: 16),

                    // Baby size card
                    _buildArticleCard(
                      '🍎 حجم الجنين',
                      'عن البيبي',
                      _teal,
                      _lightTeal,
                      child: Column(
                        children: [
                          _buildSizeRow('مثل', a.babySizeAr, Icons.circle),
                          const Divider(height: 20, color: _divider),
                          _buildSizeRow('الطول', a.babyLength, Icons.height),
                          const Divider(height: 20, color: _divider),
                          _buildSizeRow('الوزن', a.babyWeight, Icons.monitor_weight_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Echo card
                    _buildEchoCard(color),
                    const SizedBox(height: 14),

                    // Fetal development card
                    _buildArticleCard(
                      '👶 تطور الجنين',
                      'عن البيبي',
                      _teal,
                      _lightTeal,
                      child: _buildParagraphedText(a.fetalDevAr),
                    ),
                    const SizedBox(height: 14),

                    // Mother symptoms card
                    _buildArticleCard(
                      '❤️ أعراض الأم',
                      'عن الأم',
                      _pink,
                      _softPink,
                      child: _buildParagraphedText(a.symptomsAr),
                    ),
                    const SizedBox(height: 14),

                    // Nutrition card
                    _buildArticleCard(
                      '🥗 التغذية',
                      'التغذية',
                      const Color(0xFF43A047),
                      const Color(0xFFE8F5E9),
                      child: _buildParagraphedText(a.nutritionAr),
                    ),
                    const SizedBox(height: 14),

                    // Tips card
                    _buildArticleCard(
                      '💡 نصائح',
                      'نصائح نفسية',
                      const Color(0xFF5C6BC0),
                      const Color(0xFFE8EAF6),
                      child: _buildParagraphedText(a.tipsAr),
                    ),
                    const SizedBox(height: 14),

                    // Medical checklist
                    if (widget.currentWeek != null) ...[
                      _buildMedicalChecklist(trimester, color),
                      const SizedBox(height: 14),
                      // Kick counter
                      _buildKickCounter(color),
                      const SizedBox(height: 14),
                    ],

                    // ── Discover Section Header ──
                    const SizedBox(height: 24),
                    // محتوى مخصّص حسب ملف المستخدمة — يظهر قبل كل المقالات العامة
                    const PersonalizedTipsCard(stage: 'pregnant'),
                    // ─── Health Trackers Banner ───
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthTrackersScreen())),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF5C6BC0).withOpacity(0.1), _teal.withOpacity(0.08)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5C6BC0).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.monitor_heart, color: Color(0xFF5C6BC0), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("العدادات الصحية 📊", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D3A))),
                                  SizedBox(height: 2),
                                  Text("تتبعي الوزن والضغط والانقباضات وشرب الماء", style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF6B7280)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_pink.withOpacity(0.08), _teal.withOpacity(0.06)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _pink.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.explore, color: _pink, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('اكتشفي المزيد 💡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                                SizedBox(height: 2),
                                Text('مقالات ونصائح في مختلف المجالات', style: TextStyle(fontSize: 13, color: _textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Featured Articles Section (hardcoded) ──
                    ..._buildFeaturedArticles(context),

                    // ── Dynamic Discover Articles from Firestore ──
                    StreamBuilder<QuerySnapshot>(
                      stream: DynamicContentService.getArticles(section: 'pregnancy'),
                      builder: (context, dynamicSnap) {
                        final dynamicArticles = (dynamicSnap.data?.docs ?? [])
                            .map((doc) => DynamicContentService.docToArticle(doc))
                            .toList();
                        if (dynamicArticles.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Row(children: [
                              Container(width: 4, height: 22, decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              const Icon(Icons.new_releases, color: _teal, size: 20),
                              const SizedBox(width: 6),
                              const Expanded(child: Text('مقالات جديدة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _textPrimary))),
                            ]),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 195,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                itemCount: dynamicArticles.length,
                                itemBuilder: (context, i) {
                                  final art = dynamicArticles[i];
                                  return GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => _DiscoverDetailScreen(
                                        article: _DiscoverArt(
                                          title: art['title'] ?? '',
                                          emoji: '📰',
                                          color1: _teal,
                                          content: art['content'] ?? '',
                                          image: art['image'] ?? '',
                                        ),
                                        categoryName: art['category'] ?? 'مقالات جديدة',
                                      ),
                                    )),
                                    child: Container(
                                      width: i == 0 ? 270 : 195,
                                      margin: EdgeInsets.only(left: i == dynamicArticles.length - 1 ? 0 : 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [BoxShadow(color: _teal.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: (art['image'] ?? '').isNotEmpty
                                        ? Stack(fit: StackFit.expand, children: [
                                            Image.network(art['image']!, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(color: _teal.withOpacity(0.15), child: const Center(child: Text('📰', style: TextStyle(fontSize: 48))))),
                                            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.65)]))),
                                            Positioned(bottom: 12, right: 12, left: 12, child: Text(art['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                          ])
                                        : Container(
                                            color: _teal.withOpacity(0.15),
                                            child: Center(child: Text(art['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // ── All Discover Sections ──
                    ..._buildAllDiscoverSections(),

                    // ════════════ LATEST NEWS ════════════
                    const SizedBox(height: 16),
                    NewsSection(accentColor: Color(0xFF00897B), sectionTitle: 'آخر أخبار الحمل والأمومة'),
                    const SizedBox(height: 16),

                    // Navigation buttons
                    Row(
                      children: [
                        if (a.week > 1)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final p = pregnancyWeekArticles.firstWhere((x) => x.week == a.week - 1);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WeekDetailScreen(
                                      article: p,
                                      currentWeek: widget.currentWeek,
                                      daysLeft: widget.daysLeft,
                                      percent: widget.percent,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: Text('الأسبوع ${a.week - 1}'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: color,
                                side: BorderSide(color: color.withOpacity(0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        if (a.week > 1 && a.week < 40) const SizedBox(width: 12),
                        if (a.week < 40)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final n = pregnancyWeekArticles.firstWhere((x) => x.week == a.week + 1);
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WeekDetailScreen(
                                      article: n,
                                      currentWeek: widget.currentWeek,
                                      daysLeft: widget.daysLeft,
                                      percent: widget.percent,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: Text('الأسبوع ${a.week + 1}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        );

    if (isEmbedded) {
      return Directionality(textDirection: TextDirection.rtl, child: content);
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(backgroundColor: _bgColor, body: content),
    );
  }

  // ── Quick info chips ──
  Widget _buildQuickInfoRow(PregnancyWeekArticle a) {
    return Row(
      children: [
        Expanded(child: _infoChip('📏', 'الطول', a.babyLength, _lightTeal, _teal)),
        const SizedBox(width: 10),
        Expanded(child: _infoChip('⚖️', 'الوزن', a.babyWeight, _softPink, _pink)),
        const SizedBox(width: 10),
        Expanded(child: _infoChip(_fruitData[a.week]?[0] ?? '🍎', 'بحجم', _fruitData[a.week]?[1] ?? '', const Color(0xFFFFF3E0), const Color(0xFFE65100))),
      ],
    );
  }

  Widget _infoChip(String emoji, String label, String value, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Articles Carousel ──
  Widget _buildArticlesCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _pink,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'مقالات مفيدة لكِ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const _AllArticlesScreen()),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('عرض الكل', style: TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_back_ios, size: 12, color: _teal),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Carousel
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL
            itemCount: _pregnancyArticles.length,
            itemBuilder: (context, index) {
              final article = _pregnancyArticles[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ArticleDetailScreen(article: article),
                    ),
                  );
                },
                child: Container(
                  width: 240,
                  margin: EdgeInsets.only(left: index == _pregnancyArticles.length - 1 ? 0 : 12),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top colored section
                      Container(
                        width: double.infinity,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [article.bgColor, article.bgColor.withOpacity(0.5)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(18),
                            topLeft: Radius.circular(18),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Background emoji
                            Positioned(
                              left: 10,
                              bottom: 5,
                              child: Text(
                                article.emoji,
                                style: TextStyle(fontSize: 50, color: Colors.white.withOpacity(0.3)),
                              ),
                            ),
                            // Category badge
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  article.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: article.color,
                                  ),
                                ),
                              ),
                            ),
                            // Main emoji
                            Positioned(
                              right: 12,
                              bottom: 10,
                              child: Text(article.emoji, style: const TextStyle(fontSize: 36)),
                            ),
                          ],
                        ),
                      ),
                      // Text section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: _textSecondary.withOpacity(0.6)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '3 دقائق قراءة',
                                    style: TextStyle(fontSize: 10, color: _textSecondary.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
    );
  }

  // ── All Discover Sections embedded in page ──
  void _showFirestoreArticle(BuildContext context, Map<String, dynamic> d) {
    final hasImg = d['imageUrl'] != null && (d['imageUrl'] as String).isNotEmpty;
    final contentImages = (d['contentImages'] as List<dynamic>?) ?? [];
    Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(d['category'] ?? '', style: const TextStyle(color: _textPrimary, fontSize: 16)),
          backgroundColor: Colors.white, foregroundColor: _teal, elevation: 0, surfaceTintColor: Colors.transparent),
        body: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (hasImg)
            Image.network(d['imageUrl'], width: double.infinity, height: 220, fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return SizedBox(height: 220, child: Center(child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null,
                  color: _teal)));
              },
              errorBuilder: (_, error, ___) {
                debugPrint('Article header image error: $error');
                return Container(height: 120, color: _teal.withOpacity(0.05),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.image_not_supported_outlined, size: 40, color: _teal.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Text('تعذّر تحميل الصورة', style: TextStyle(fontSize: 12, color: _textSecondary)),
                  ])));
              }),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary, height: 1.4)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(d['category'] ?? '', style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Text(d['content'] ?? '', style: TextStyle(fontSize: 16, color: _textSecondary, height: 1.8)),
            if (contentImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...contentImages.map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(borderRadius: BorderRadius.circular(12),
                  child: Image.network(url.toString(), width: double.infinity, fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: _teal)));
                    },
                    errorBuilder: (_, error, ___) {
                      debugPrint('Article content image error: $error');
                      return const SizedBox.shrink();
                    })))),
            ],
          ])),
        ])),
      ),
    )));
  }

  List<Widget> _buildFeaturedArticles(BuildContext context) {
    final featured = <Map<String, dynamic>>[
      {'title': 'التغيرات في جسمك أسبوعياً', 'category': 'أسبوع بأسبوع', 'image': 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=400&q=80'},
      {'title': 'الأطعمة المفيدة للحامل', 'category': 'التغذية', 'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80'},
      {'title': 'المشي أثناء الحمل', 'category': 'الرياضة', 'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80'},
      {'title': 'تحضير حقيبة المولود', 'category': 'التحضير للولادة', 'image': 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400&q=80'},
      {'title': 'القلق من الولادة', 'category': 'الصحة النفسية', 'image': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&q=80'},
      {'title': 'دور الأب أثناء الحمل', 'category': 'العلاقة الزوجية', 'image': 'https://images.unsplash.com/photo-1531983412531-1f49a365ffed?w=400&q=80'},
      {'title': 'فحوصات الثلث الأول', 'category': 'الفحوصات', 'image': 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&q=80'},
      {'title': 'العناية بالبشرة', 'category': 'الجمال والعناية', 'image': 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400&q=80'},
    ];

    return [
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Container(width: 4, height: 22, decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          const Text('\u{1F4F0}', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          const Text('مقالات جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
        ]),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: featured.length,
          itemBuilder: (_, i) {
            final item = featured[i];
            return GestureDetector(
              onTap: () {
                // Find matching article in discover categories
                for (final cat in _discoverCategories) {
                  for (final art in cat.articles) {
                    if (art.title == item['title']) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _DiscoverDetailScreen(article: art, categoryName: cat.name),
                      ));
                      return;
                    }
                  }
                }
              },
              child: Container(
                width: 160, margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(item['image']!, width: 160, height: 100, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(height: 100, color: _teal.withOpacity(0.08),
                        child: const Center(child: Icon(Icons.article, size: 40, color: _teal)))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['title']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textPrimary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(item['category']!, style: TextStyle(fontSize: 9, color: _teal, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildAllDiscoverSections() {
    return _discoverCategories.map((cat) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Section title
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(color: _pink, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(cat.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cat.name,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _textPrimary),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _CategoryArticlesScreen(category: cat),
                  ));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('عرض الكل', style: TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_back_ios, size: 12, color: _teal),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal carousel
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: cat.articles.length,
              itemBuilder: (context, i) {
                final art = cat.articles[i];
                final isFirst = i == 0;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _DiscoverDetailScreen(article: art, categoryName: cat.name),
                    ));
                  },
                  child: Container(
                    width: isFirst ? 270 : 195,
                    margin: EdgeInsets.only(left: i == cat.articles.length - 1 ? 0 : 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: art.color1.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: art.image.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background image
                            art.image.startsWith('http')
                              ? ArticleImage(
                                  title: art.title,
                                  section: 'pregnancy',
                                  networkUrl: art.image,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  art.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: art.color1.withOpacity(0.15),
                                    child: Center(child: Text(art.emoji, style: const TextStyle(fontSize: 48))),
                                  ),
                                ),
                            // Gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  stops: const [0.3, 0.6, 1.0],
                                ),
                              ),
                            ),
                            // Badge and title
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.article_outlined, size: 13, color: art.color1),
                                        const SizedBox(width: 3),
                                        Text('مقال', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: art.color1)),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    art.title,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            // Fallback gradient background
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [art.color1.withOpacity(0.15), art.color1.withOpacity(0.04)],
                                ),
                              ),
                            ),
                            // Background emoji
                            Positioned(
                              left: -10,
                              bottom: -10,
                              child: Text(art.emoji, style: TextStyle(fontSize: isFirst ? 90 : 65, color: art.color1.withOpacity(0.07))),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: art.color1.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.article_outlined, size: 13, color: art.color1),
                                        const SizedBox(width: 3),
                                        Text('مقال', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: art.color1)),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(art.emoji, style: const TextStyle(fontSize: 32)),
                                  const SizedBox(height: 6),
                                  Text(
                                    art.title,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textPrimary, height: 1.3),
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
      );
    }).toList();
  }

  Widget _buildProgressCard(Color color) {
    final w = widget.currentWeek ?? widget.article.week;
    final d = widget.daysLeft ?? max(0, (40 * 7) - (w * 7));
    final p = widget.percent ?? (w / 40).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_teal, _teal.withOpacity(0.85)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _teal.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الأسبوع $w',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pregnancyMonthArForWeek(w)} · $d يوم متبقي',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${(p * 100).toInt()}%',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p,
              backgroundColor: Colors.white.withOpacity(0.25),
              color: Colors.white,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(
    String title,
    String category,
    Color accentColor,
    Color bgTint, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgTint.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSizeRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _lightTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: _teal),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: _textSecondary),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildEchoCard(Color c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5).withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: _pink, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'صورة الإيكو / السونار 3D',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textPrimary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _loadingEcho
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: _pink),
                    ),
                  )
                : _echoImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _echoImage!,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: GestureDetector(
                              onTap: _pickEchoImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit, color: _pink, size: 14),
                                    const SizedBox(width: 4),
                                    const Text('تغيير', style: TextStyle(color: _pink, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: _pickEchoImage,
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: _softPink.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _pink.withOpacity(0.2), width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _pink.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add_a_photo, size: 32, color: _pink.withOpacity(0.6)),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'أضيفي صورة الإيكو أو السونار 3D',
                                style: TextStyle(
                                  color: _pink.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalChecklist(int trimester, Color c) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final mk = DateTime.now().toIso8601String().substring(0, 7);
    final items = _trimesterChecklist[trimester] ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _lightTeal.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'أسئلة للطبيب',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _teal),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '📋 الفحوصات - الثلث ${['الأول', 'الثاني', 'الثالث'][trimester - 1]}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _teal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.map((item) {
                final did = '${mk}_${item[1]}';
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('weekly_checklist')
                      .doc(did)
                      .snapshots(),
                  builder: (ctx, snap) {
                    bool done = snap.hasData &&
                        snap.data!.exists &&
                        ((snap.data!.data() as Map<String, dynamic>?)?['done'] ?? false);
                    return InkWell(
                      onTap: () => FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('weekly_checklist')
                          .doc(did)
                          .set({
                        'text': item[0],
                        'done': !done,
                        'key': item[1],
                        'updatedAt': FieldValue.serverTimestamp()
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: done ? _teal : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: done ? _teal : _textSecondary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: done
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item[0],
                                style: TextStyle(
                                  fontSize: 14,
                                  decoration: done ? TextDecoration.lineThrough : null,
                                  color: done ? _textSecondary : _textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKickCounter(Color c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _softPink.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                topLeft: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'مراقبة',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _pink),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '👣 عداد حركات الجنين',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _pink),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _softPink.withOpacity(0.5),
                    border: Border.all(color: _pink.withOpacity(0.2), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$_kickCount',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _pink),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'حركة',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _kickCount++),
                      icon: const Icon(Icons.touch_app),
                      label: const Text('ركلة!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final dk = DateTime.now().toIso8601String().substring(0, 10);
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('kick_logs')
                              .doc(dk)
                              .set({
                            'count': _kickCount,
                            'date': dk,
                            'updatedAt': FieldValue.serverTimestamp()
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم حفظ $_kickCount حركة'),
                                backgroundColor: _teal,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                        setState(() => _kickCount = 0);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _teal,
                        side: BorderSide(color: _teal.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('حفظ وإعادة'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Article Detail Screen ───
class _ArticleDetailScreen extends StatelessWidget {
  final _PregnancyArticle article;
  const _ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _teal,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  article.category,
                  style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [article.bgColor, article.bgColor.withOpacity(0.3), Colors.white],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: article.color.withOpacity(0.15), blurRadius: 20, spreadRadius: 5),
                            ],
                          ),
                          child: Center(
                            child: Text(article.emoji, style: const TextStyle(fontSize: 45)),
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
                        color: article.bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        article.category,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: article.color),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle
                    Text(
                      article.subtitle,
                      style: const TextStyle(fontSize: 15, color: _textSecondary),
                    ),
                    const SizedBox(height: 8),
                    // Meta info
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: _textSecondary.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text('3 دقائق قراءة', style: TextStyle(fontSize: 12, color: _textSecondary.withOpacity(0.6))),
                        const SizedBox(width: 16),
                        Icon(Icons.favorite_border, size: 14, color: _textSecondary.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text('مقال مفيد', style: TextStyle(fontSize: 12, color: _textSecondary.withOpacity(0.6))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Divider
                    Container(height: 1, color: _divider),
                    const SizedBox(height: 20),
                    // Content with paragraphs + ad space
                    ..._buildArticleParagraphs(article.content, article.color),
                    const SizedBox(height: 20),
                    // Tip box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lightTeal,
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
                                  'نصيحة',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _teal),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'استشيري طبيبتك دائماً قبل اتخاذ أي قرارات صحية مهمة أثناء الحمل.',
                                  style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.6),
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

  static List<Widget> _buildArticleParagraphs(String body, Color accentColor) {
    List<String> paragraphs;
    if (body.contains('\n\n')) {
      paragraphs = body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    } else {
      paragraphs = [];
      String current = '';
      final sentences = body.trim().split(RegExp(r'(?<=[\.!\?:])\s+'));
      int sentCount = 0;
      for (final s in sentences) {
        current += (current.isEmpty ? '' : ' ') + s;
        sentCount++;
        if (sentCount >= 3 && current.length > 100) {
          paragraphs.add(current.trim());
          current = '';
          sentCount = 0;
        }
      }
      if (current.trim().isNotEmpty) paragraphs.add(current.trim());
    }
    final widgets = <Widget>[];
    final midPoint = (paragraphs.length / 2).floor();
    for (int i = 0; i < paragraphs.length; i++) {
      widgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: EdgeInsets.only(bottom: i < paragraphs.length - 1 ? 12 : 0),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Text(paragraphs[i].trim(), textAlign: TextAlign.justify,
          style: const TextStyle(fontSize: 16.5, height: 1.9, color: _textPrimary)),
      ));
      if (i == midPoint && paragraphs.length > 3) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: NabdaAd(slot: 0, groupId: 'pwk1', place: 'pregnancy', color: Color(0xFFE91E63)),
        ));
      }
    }
    return widgets;
  }
}

// ─── All Articles Screen ───
class _AllArticlesScreen extends StatelessWidget {
  const _AllArticlesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: const Text(
            'مقالات الحمل',
            style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _divider),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pregnancyArticles.length,
          itemBuilder: (context, index) {
            final article = _pregnancyArticles[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ArticleDetailScreen(article: article),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    // Image section
                    Container(
                      width: 100,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [article.bgColor, article.bgColor.withOpacity(0.5)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      child: Center(
                        child: Text(article.emoji, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
                    // Text section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: article.bgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                article.category,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: article.color),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              article.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              article.subtitle,
                              style: const TextStyle(fontSize: 12, color: _textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(Icons.arrow_back_ios, size: 14, color: _textSecondary.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Discover Data Models ───
class _DiscoverArt {
  final String title;
  final String emoji;
  final Color color1;
  final String content;
  final String image; // URL or asset path
  const _DiscoverArt({required this.title, required this.emoji, required this.color1, required this.content, this.image = ''});
}

class _DiscoverCat {
  final String name;
  final String emoji;
  final List<_DiscoverArt> articles;
  const _DiscoverCat({required this.name, required this.emoji, required this.articles});
}

final List<_DiscoverCat> _discoverCategories = [
  _DiscoverCat(name: 'التغذية والأطعمة', emoji: '🥗', articles: [
    _DiscoverArt(title: 'الأطعمة المفيدة للحامل', emoji: '🥑', color1: const Color(0xFF43A047),
      image: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
      content: 'التغذية السليمة أثناء الحمل تشكل الأساس لصحة الأم والجنين معاً. أهم الأطعمة التي يجب أن تكون في نظامك الغذائي اليومي تشمل السلمون الغني بأحماض أوميغا 3 الضرورية لنمو دماغ الجنين وتطور جهازه العصبي. البيض مصدر ممتاز للبروتين والكولين المهم لتطور ذاكرة الجنين. البقوليات كالعدس والفاصوليا والحمص توفر حمض الفوليك والحديد والألياف. البطاطا الحلوة غنية بفيتامين أ الضروري لنمو الجلد والعينين والعظام. الخضراوات الورقية الداكنة كالسبانخ والبروكلي تمد جسمك بالكالسيوم والحديد وحمض الفوليك. التوت والفراولة غنية بفيتامين سي ومضادات الأكسدة التي تعزز المناعة وتحسن امتصاص الحديد. اللحوم الحمراء قليلة الدهن مصدر رئيسي للحديد والبروتين وفيتامين ب12. منتجات الألبان كالحليب والزبادي والجبن توفر الكالسيوم والبروتين الضروريين لبناء عظام الجنين. المكسرات كاللوز والجوز تحتوي على دهون صحية وبروتين ومعادن مهمة. الحبوب الكاملة كالشوفان والأرز البني توفر الطاقة والألياف وفيتامينات ب المركبة. نظمي وجباتك على خمس إلى ست وجبات صغيرة يومياً واحرصي على التنويع لضمان حصولك على جميع العناصر الغذائية.'),
    _DiscoverArt(title: 'أطعمة يجب تجنبها', emoji: '⚠️', color1: const Color(0xFFE53935),
      image: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
      content: 'خلال فترة الحمل يجب أن تكوني حذرة بشأن ما تأكلينه لحماية نفسك وجنينك من المخاطر الصحية. تجنبي تماماً اللحوم والأسماك النيئة أو غير المطهية جيداً بما في ذلك السوشي والساشيمي لأنها قد تحتوي على بكتيريا ضارة كالليستيريا والسالمونيلا أو طفيليات قد تضر بالجنين. ابتعدي عن الأجبان الطرية غير المبسترة مثل البري والكاممبير والجبن الأزرق لاحتمال تلوثها بالليستيريا. البيض النيء أو غير المطبوخ جيداً يشكل خطر السالمونيلا فتأكدي من طهيه حتى يتماسك الصفار والبياض تماماً. الأسماك عالية الزئبق كالتونة الكبيرة وسمك أبو سيف والماكريل الملكي قد تؤثر سلباً على نمو الجهاز العصبي للجنين. تجنبي الكبد بكميات كبيرة لاحتوائه على فيتامين أ المركز الذي قد يسبب تشوهات جنينية بالجرعات العالية. الكافيين يجب ألا يتجاوز مائتي ملليغرام يومياً أي ما يعادل فنجان قهوة صغير واحد. الكحول ممنوع تماماً طوال فترة الحمل لأنه يسبب اضطرابات نمو خطيرة للجنين. تجنبي الأطعمة المصنعة الغنية بالمواد الحافظة والأطعمة الحارة جداً التي تزيد الحموضة. اغسلي الفواكه والخضراوات جيداً تحت الماء الجاري لإزالة أي ملوثات أو بقايا مبيدات.'),
    _DiscoverArt(title: 'المشروبات الصحية', emoji: '🥤', color1: const Color(0xFF00ACC1),
      image: 'https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=400&q=80',
      content: 'الترطيب الكافي أثناء الحمل ضروري لصحتك ولتكوين السائل الأمنيوسي ودعم الدورة الدموية المتزايدة. الماء هو المشروب الأمثل واحرصي على شرب ثمانية إلى عشرة أكواب يومياً على الأقل. زيدي الكمية في الطقس الحار أو عند ممارسة الرياضة. العصائر الطبيعية الطازجة بدون سكر مضاف مفيدة خاصة عصير البرتقال الغني بفيتامين سي وحمض الفوليك وعصير الرمان المضاد للأكسدة. الحليب قليل الدسم أو كامل الدسم يوفر الكالسيوم والبروتين ويمكنك إضافة الفواكه لعمل سموذي صحي ومغذ. شاي الزنجبيل الطازج من أفضل المشروبات لتخفيف الغثيان الصباحي وتحسين الهضم. ماء جوز الهند مصدر طبيعي للإلكتروليتات ويساعد على الترطيب والتخلص من الحموضة. شاي البابونج مهدئ ويساعد على النوم لكن اشربيه باعتدال. قللي من الشاي الأخضر والأسود لاحتوائهما على الكافيين واستبدليهما بشاي الأعشاب الآمن. تجنبي المشروبات الغازية تماماً لأنها تسبب الانتفاخ وتحتوي على سكر مضاف وكيماويات ومشروبات الطاقة الممنوعة أثناء الحمل لاحتوائها على كافيين عالي ومحفزات أخرى. يمكنك تحضير ماء منكه بإضافة شرائح الليمون والخيار والنعناع للماء البارد.'),
    _DiscoverArt(title: 'الفيتامينات الضرورية', emoji: '💊', color1: const Color(0xFFFF8F00),
      image: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&q=80',
      content: 'المكملات الغذائية والفيتامينات تلعب دوراً حيوياً في دعم صحة الحمل وضمان حصول الجنين على كل ما يحتاجه للنمو السليم. حمض الفوليك هو الأهم ويجب تناول أربعمائة ميكروغرام يومياً قبل الحمل بشهر وخلال الثلث الأول على الأقل لأنه يمنع تشوهات الأنبوب العصبي كالشق الشوكي. الحديد ضروري بجرعة سبعة وعشرين ملليغراماً يومياً لمنع فقر الدم الذي يصيب كثيراً من الحوامل بسبب زيادة حجم الدم. تناولي الحديد مع فيتامين سي لتحسين امتصاصه وتجنبي تناوله مع الشاي أو الحليب. الكالسيوم بجرعة ألف ملليغرام يومياً ضروري لبناء عظام الجنين وأسنانه ولحماية عظامك أنتِ من الهشاشة. فيتامين د يساعد على امتصاص الكالسيوم ويوصى بستمائة وحدة دولية يومياً ويمكنك الحصول عليه من التعرض المعتدل للشمس. أحماض أوميغا 3 وخاصة دي إتش أيه ضرورية لنمو دماغ الجنين وعينيه وتوجد في السمك أو يمكن تناولها كمكمل. فيتامين ب12 مهم لتكوين الخلايا العصبية والحمراء. اليود ضروري لوظيفة الغدة الدرقية ونمو دماغ الجنين. استشيري طبيبتك دائماً قبل تناول أي مكملات لتحديد الجرعات المناسبة لحالتك وتجنب أي تعارض مع أدوية أخرى.'),
  ]),
  _DiscoverCat(name: 'الجسم والتغيرات', emoji: '🩺', articles: [
    _DiscoverArt(title: 'آلام الظهر وكيفية التخفيف', emoji: '💆‍♀️', color1: const Color(0xFF5C6BC0),
      image: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&q=80',
      content: 'آلام الظهر من أكثر الشكاوى شيوعاً أثناء الحمل وتصيب أكثر من ثلثي النساء الحوامل خاصة في الثلثين الثاني والثالث. تحدث بسبب عدة عوامل منها زيادة الوزن وتغير مركز الثقل وارتخاء الأربطة بتأثير هرمون الريلاكسين. لتخفيف آلام الظهر حافظي على وضعية جسم صحيحة أثناء الجلوس بحيث يكون ظهرك مستقيماً ومدعوماً بوسادة خلف منطقة أسفل الظهر. عند الوقوف لفترات طويلة ضعي إحدى قدميك على مسند منخفض وبدلي بين القدمين. ارتدي أحذية مريحة مسطحة أو بكعب منخفض جداً وتجنبي الكعب العالي تماماً. عند النوم استلقي على جانبك مع وسادة بين ركبتيك لتخفيف الضغط على أسفل الظهر والحوض. مارسي تمارين إطالة خفيفة يومياً مثل وضعية القطة والبقرة التي تحرك العمود الفقري بلطف وتخفف التشنج. الكمادات الدافئة على منطقة الألم لمدة خمس عشرة دقيقة تساعد على استرخاء العضلات. السباحة ممتازة لتخفيف آلام الظهر لأن الماء يدعم وزن الجسم. التدليك اللطيف من شريكك أو من مختصة تدليك الحوامل يخفف التوتر العضلي. عند رفع الأشياء اثني ركبتيك بدل الانحناء من الخصر واطلبي المساعدة للأشياء الثقيلة.'),
    _DiscoverArt(title: 'الغثيان الصباحي', emoji: '🤢', color1: const Color(0xFF26A69A),
      image: 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=400&q=80',
      content: 'الغثيان الصباحي يصيب حوالي ثمانين بالمئة من النساء الحوامل ويبدأ عادة في الأسبوع السادس ويتحسن بحلول الأسبوع الثاني عشر إلى الرابع عشر رغم أنه قد يستمر لفترة أطول عند بعض النساء. رغم تسميته بالصباحي إلا أنه قد يحدث في أي وقت من اليوم. يحدث بسبب ارتفاع هرمون الحمل وحساسية المعدة المتزايدة. لتخفيفه كلي قطعة بسكويت جاف أو خبز محمص قبل النهوض من السرير صباحاً لأن المعدة الفارغة تزيد الغثيان. قسمي وجباتك إلى خمس أو ست وجبات صغيرة بدل ثلاث كبيرة فالأكل المتكرر بكميات قليلة يمنع هبوط السكر ويقلل الغثيان. تجنبي الأطعمة الدسمة والمقلية والحارة والروائح القوية التي تثير المعدة. الزنجبيل الطازج من أفضل العلاجات الطبيعية سواء كشاي أو حلوى زنجبيل أو حتى شمه مباشرة. تناولي أطعمة باردة لأنها أقل رائحة من الساخنة. اشربي السوائل بين الوجبات وليس أثناءها لتجنب امتلاء المعدة. مصي مكعبات ثلج أو حلوى حامضة عند الشعور بالغثيان. فيتامين ب6 بجرعة خمسة وعشرين ملليغراماً ثلاث مرات يومياً يخفف الغثيان عند كثير من النساء. إذا كان الغثيان شديداً ولا تستطيعين الاحتفاظ بأي طعام أو سوائل راجعي طبيبتك فوراً لأن هذا قد يكون القيء المفرط الحملي ويحتاج علاجاً.'),
    _DiscoverArt(title: 'تورم القدمين والساقين', emoji: '🦶', color1: const Color(0xFF8E24AA),
      image: 'https://images.unsplash.com/photo-1590650153855-d9e808231d41?w=400&q=80',
      content: 'التورم أو الوذمة من الأعراض الشائعة جداً في النصف الثاني من الحمل ويصيب معظم النساء الحوامل خاصة في الكاحلين والقدمين واليدين. يحدث بسبب زيادة حجم الدم واحتباس السوائل الطبيعي خلال الحمل وضغط الرحم المتزايد على الأوردة الكبيرة. لتخفيف التورم ارفعي قدميك فوق مستوى القلب عند الجلوس أو الاستلقاء واستخدمي وسادة تحت قدميك أثناء النوم. تجنبي الوقوف أو الجلوس لفترات طويلة وإذا كان عملك يتطلب ذلك فحركي قدميك وساقيك بانتظام ومشي قليلاً كل ساعة. ارتدي جوارب ضغط طبية تساعد على تحسين الدورة الدموية وتقليل احتباس السوائل واستشيري طبيبتك في اختيار الدرجة المناسبة. اشربي كمية أكبر من الماء فقد يبدو هذا متناقضاً لكن الترطيب الكافي يساعد الكلى على التخلص من السوائل الزائدة. قللي من الملح في طعامك لأنه يزيد احتباس السوائل. السباحة والمشي في الماء مفيدان جداً لتقليل التورم. ارتدي أحذية مريحة واسعة واتركي الخواتم الضيقة. إذا كان التورم مفاجئاً وشديداً خاصة في الوجه واليدين ومصحوباً بصداع شديد أو تشوش في الرؤية أو ألم في أعلى البطن اذهبي للطوارئ فوراً لأن هذه أعراض تسمم الحمل وتحتاج تدخلاً طبياً عاجلاً.'),
    _DiscoverArt(title: 'علامات التمدد والوقاية', emoji: '✨', color1: const Color(0xFFEC407A),
      image: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=400&q=80',
      content: 'علامات التمدد أو التشققات الجلدية تظهر عند حوالي تسعين بالمئة من النساء الحوامل عادة في البطن والصدر والأرداف والفخذين وأحياناً الذراعين. تحدث عندما يتمدد الجلد بسرعة تفوق قدرة ألياف الكولاجين والإيلاستين على التكيف مما يسبب تمزقاً في الطبقات العميقة من الجلد. العوامل الوراثية تلعب دوراً كبيراً فإذا ظهرت عند والدتك فاحتمال ظهورها عندك أعلى. للوقاية والتقليل من شدتها رطبي بشرتك يومياً بدءاً من بداية الحمل باستخدام زيت اللوز الحلو أو زبدة الشيا أو زبدة الكاكاو أو زيت جوز الهند. دلكي المناطق المعرضة بحركات دائرية لمدة خمس دقائق لتحسين الدورة الدموية وتغذية الجلد. اشربي كمية كافية من الماء لا تقل عن ثمانية أكواب يومياً للحفاظ على مرونة الجلد من الداخل. تناولي أطعمة غنية بفيتامين سي الذي يعزز إنتاج الكولاجين مثل البرتقال والفراولة والفلفل وفيتامين إي الموجود في المكسرات والأفوكادو. حافظي على زيادة وزن تدريجية ومنتظمة وتجنبي الزيادة السريعة لأنها تمد الجلد بشكل مفاجئ. العلامات تبدأ وردية أو أرجوانية ثم تتحول تدريجياً إلى بيضاء فضية وتبهت كثيراً بعد الولادة. كريمات الريتينول فعالة لعلاجها بعد الولادة لكنها ممنوعة أثناء الحمل والرضاعة.'),
  ]),
  _DiscoverCat(name: 'التمارين والرياضة', emoji: '🧘‍♀️', articles: [
    _DiscoverArt(title: 'المشي أثناء الحمل', emoji: '🚶‍♀️', color1: const Color(0xFF66BB6A),
      image: 'https://images.unsplash.com/photo-1609710228159-0fa9bd7c0827?w=400&q=80',
      content: 'المشي هو أفضل وأسلم تمرين يمكن للحامل ممارسته طوال فترة الحمل ولا يحتاج لمعدات خاصة أو اشتراك في نادٍ رياضي. ابدئي بخمس عشرة دقيقة يومياً إذا لم تكوني معتادة على الرياضة ثم زيدي تدريجياً حتى ثلاثين دقيقة أو أكثر. المشي يحسن الدورة الدموية مما يساعد على توصيل الأكسجين والمغذيات للجنين بكفاءة ويقلل التورم في القدمين والساقين. يساعد على تنظيم الوزن وتقليل خطر سكري الحمل وارتفاع ضغط الدم. يقوي عضلات الساقين والحوض استعداداً للولادة. يحسن المزاج بشكل ملحوظ بفضل إفراز هرمونات الإندورفين ويقلل أعراض الاكتئاب والقلق. يساعد على تحسين جودة النوم ويقلل الإمساك الشائع أثناء الحمل. ارتدي حذاءً رياضياً مريحاً بدعم جيد للقوس والكاحل وملابس قطنية فضفاضة. احملي زجاجة ماء واشربي قبل وأثناء وبعد المشي. اختاري أوقات معتدلة الحرارة كالصباح الباكر أو المساء وتجنبي الأسطح غير المستوية. توقفي فوراً إذا شعرت بدوخة أو ضيق تنفس أو ألم أو نزيف. في الثلث الأخير خففي السرعة واستمعي لجسمك. المشي مع صديقة أو زوجك يجعل التمرين أكثر متعة وانتظاماً.'),
    _DiscoverArt(title: 'يوغا الحوامل', emoji: '🧘‍♀️', color1: const Color(0xFF7E57C2),
      image: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&q=80',
      content: 'يوغا الحوامل من أفضل التمارين لتقوية الجسم والعقل خلال فترة الحمل وتحضيرك للولادة. تركز على تقوية عضلات الحوض وقاع الحوض التي تتحمل ضغطاً كبيراً أثناء الحمل والولادة. تمارين التنفس في اليوغا مفيدة جداً لأنها تعلمك التحكم في تنفسك خلال الانقباضات أثناء المخاض. تخفف آلام أسفل الظهر والوركين من خلال تمارين الإطالة اللطيفة وتحسن وضعية الجسم. تعزز التوازن والمرونة اللذين يتأثران بتغير مركز الثقل أثناء الحمل. تقلل التوتر والقلق وتحسن النوم بفضل تقنيات الاسترخاء والتأمل. الوضعيات الآمنة والمفيدة تشمل وضعية القطة والبقرة لتحريك العمود الفقري بلطف وتخفيف آلام الظهر ووضعية الفراشة لفتح الوركين وتقوية عضلات الفخذ الداخلية ووضعية المحارب المعدلة لتقوية الساقين والتوازن ووضعية الطفل المعدلة للاسترخاء. تجنبي الاستلقاء على الظهر بعد الأسبوع العشرين والالتواءات العميقة التي تضغط على البطن والوضعيات المقلوبة والقفزات. ابدئي بحصص قصيرة خمس عشرة دقيقة وزيدي تدريجياً. اختاري مدربة متخصصة في يوغا الحوامل أو اتبعي فيديوهات موثوقة. توقفي فوراً عند أي ألم أو دوخة. اليوغا ليست مجرد تمارين بل هي أسلوب للتواصل مع جسمك وطفلك.'),
    _DiscoverArt(title: 'السباحة للحامل', emoji: '🏊‍♀️', color1: const Color(0xFF29B6F6),
      image: 'https://images.unsplash.com/photo-1530549387789-4c1017266635?w=400&q=80',
      content: 'السباحة من أفضل الرياضات وأكثرها أماناً للحامل لأن الماء يدعم وزن الجسم المتزايد ويخفف الضغط على المفاصل والعمود الفقري ويمنحك شعوراً رائعاً بالخفة والحرية في الحركة. تعتبر تمريناً كاملاً للجسم يقوي عضلات الذراعين والساقين والظهر والبطن دون إجهاد المفاصل. تخفف تورم القدمين بشكل ملحوظ لأن ضغط الماء يساعد على دفع السوائل المحتبسة وتحسين الدورة الدموية. تبرد الجسم وتمنع ارتفاع حرارته وهذا مهم خاصة في الأشهر الحارة. تحسن القدرة القلبية والتنفسية وتعد الجسم لمجهود الولادة. يمكنك السباحة طوال فترة الحمل حتى الأسابيع الأخيرة ما لم تمنعك طبيبتك لسبب طبي. ابدئي بعشرين دقيقة واسبحي بوتيرة معتدلة يمكنك فيها التحدث بشكل طبيعي. تجنبي السباحة على ظهرك بعد الأسبوع العشرين. لا تقفزي أو تغوصي في الماء. اختاري حمام سباحة نظيفاً ومعتدل الحرارة. تجنبي الجاكوزي وحمامات البخار والساونا تماماً أثناء الحمل لأن الحرارة العالية خطيرة على الجنين. ارتدي مايوه مريح للحوامل ونظارات سباحة. التمارين المائية الجماعية للحوامل خيار ممتاز يجمع بين الرياضة والمتعة الاجتماعية.'),
    _DiscoverArt(title: 'تمارين كيجل المهمة', emoji: '💪', color1: const Color(0xFFEF5350),
      image: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=400&q=80',
      content: 'تمارين كيجل من أهم التمارين التي يجب أن تمارسها كل حامل لأنها تقوي عضلات قاع الحوض المسؤولة عن دعم الرحم والمثانة والأمعاء. هذه العضلات تتعرض لضغط كبير بسبب وزن الحمل المتزايد مما قد يسبب ضعفها ويؤدي لسلس البول أثناء الحمل وبعد الولادة. تقوية هذه العضلات تسهل عملية الولادة الطبيعية وتساعد على التحكم أثناء الدفع وتسرع التعافي بعد الولادة. لممارسة تمارين كيجل اقبضي عضلات الحوض كأنك تحاولين إيقاف تدفق البول واستمري في القبض لخمس ثوانٍ ثم استرخي تماماً لخمس ثوانٍ. كرري عشر مرات وهذه مجموعة واحدة. مارسي ثلاث مجموعات يومياً. مع التمرين المنتظم زيدي مدة القبض تدريجياً حتى عشر ثوانٍ. يمكنك ممارسة كيجل في أي وقت ومكان أثناء الجلوس في السيارة أو مشاهدة التلفاز أو الانتظار في الطابور فلا أحد يلاحظ أنك تمارسين التمرين. تأكدي من أنك تقبضين العضلات الصحيحة وليس عضلات البطن أو الأرداف. لا تمارسي كيجل أثناء التبول فعلياً لأن ذلك قد يسبب مشاكل في المثانة. ابدئي من الثلث الأول واستمري طوال الحمل وبعد الولادة. النتائج تظهر بعد أربعة إلى ستة أسابيع من الممارسة المنتظمة.'),
  ]),
  _DiscoverCat(name: 'الرضاعة والمولود', emoji: '🤱', articles: [
    _DiscoverArt(title: 'الرضاعة الطبيعية: البداية', emoji: '🤱', color1: const Color(0xFFE91E63),
      image: 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=400&q=80',
      content: 'البداية الصحيحة للرضاعة الطبيعية هي مفتاح نجاحها على المدى الطويل. ابدئي الرضاعة خلال الساعة الأولى بعد الولادة إن سمحت الظروف لأن هذا يحفز إنتاج الحليب ويمنح طفلك اللبأ وهو الحليب الأول السميك المائل للاصفرار الغني جداً بالأجسام المضادة والعناصر الغذائية المركزة. اللبأ يشكل أول تطعيم طبيعي لطفلك ويحمي أمعاءه الحساسة. تأكدي من أن فم طفلك يغطي معظم الهالة المحيطة بالحلمة وليس فقط طرفها لأن الإمساك الصحيح يمنع ألم الحلمة ويضمن حصول الطفل على كمية كافية من الحليب. أرضعي طفلك عند الطلب أي كلما أبدى علامات الجوع مثل تحريك رأسه ومص يديه وهذا يعني ثماني إلى اثنتي عشرة رضعة يومياً في الأسابيع الأولى. الرضاعة الصحيحة لا تسبب ألماً فإذا شعرت بألم فقد يكون الإمساك غير صحيح أدخلي إصبعك الصغير في زاوية فم الطفل لفك الإمساك وأعيدي المحاولة. لا تترددي في طلب مساعدة استشارية رضاعة معتمدة في الأيام الأولى فمعظم مشاكل الرضاعة يمكن حلها بتوجيه متخصص. تحلي بالصبر فالرضاعة مهارة جديدة تتعلمينها أنت وطفلك معاً وتتحسن كثيراً بعد الأسبوعين الأولين.'),
    _DiscoverArt(title: 'تحضير حقيبة المولود', emoji: '👶', color1: const Color(0xFF42A5F5),
      image: 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400&q=80',
      content: 'تحضير مستلزمات المولود من اللحظات الممتعة في رحلة الحمل ومن الأفضل البدء من الأسبوع الرابع والثلاثين تحسباً لأي ولادة مبكرة. الملابس تحتاجين من ستة إلى ثمانية بدلات قطنية داخلية وأربع إلى خمس قطع ملابس خارجية مناسبة للموسم. قبعات صغيرة لحماية رأس المولود خاصة في الأيام الأولى وجوارب ناعمة وقفازات صغيرة لمنع خدش الوجه. بطانيات قطنية ناعمة لللف والتدفئة. الحفاضات اشتري عبوة حفاضات لحديثي الولادة ومناديل مبللة خالية من العطور والكحول وكريم طفح الحفاض الذي يحتوي على أكسيد الزنك. للاستحمام حوض صغير مخصص للرضع وشامبو وغسول لطيف بدون دموع ومنشفة ناعمة بقبعة. مقص أظافر خاص بالرضع لأن أظافرهم تنمو بسرعة مذهلة. ميزان حرارة رقمي دقيق لمراقبة الحرارة. كرسي سيارة آمن ومعتمد لحديثي الولادة وهو إلزامي قبل الخروج من المستشفى. سرير آمن بمرتبة مناسبة بدون وسادة أو أغطية فضفاضة. إذا كنت تنوين الرضاعة بالزجاجة جهزي رضاعات وحلمات وفرشاة تنظيف وجهاز تعقيم. لا تبالغي في الشراء في البداية فالمولود يحتاج أشياء بسيطة وسيخبرك بنفسه ما يحتاجه مع الوقت.'),
    _DiscoverArt(title: 'الرضاعة بالزجاجة', emoji: '🍼', color1: const Color(0xFF26C6DA),
      image: 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&q=80',
      content: 'الرضاعة بالزجاجة خيار صحي ومقبول سواء كنت تستخدمين حليباً صناعياً أو حليب الأم المشفوط. اختاري حليباً صناعياً مناسباً لعمر طفلك واستشيري طبيب الأطفال في الاختيار خاصة إذا كان طفلك يعاني من حساسية أو ارتجاع. عقمي جميع الزجاجات والحلمات والأغطية قبل كل استخدام في الأسابيع الأولى بغليها في الماء لعشر دقائق أو باستخدام جهاز تعقيم بالبخار. حضري الحليب بالماء المغلي المبرد إلى سبعين درجة مئوية وأضيفي المسحوق حسب التعليمات بدقة فالتركيز الزائد أو الناقص يضر بالطفل. رجي الزجاجة جيداً حتى يذوب المسحوق تماماً. لا تسخني الحليب في الميكروويف أبداً لأنه يسخن بشكل غير متساوٍ وقد يحرق فم الطفل. سخنيه بوضع الزجاجة في ماء دافئ. تأكدي من درجة الحرارة بوضع قطرات على معصمك الداخلي يجب أن تكون فاترة. احملي طفلك بزاوية خمسة وأربعين درجة أثناء الرضاعة لتقليل ابتلاع الهواء والتجشؤ. لا تتركي الزجاجة في فم الطفل وهو نائم. تخلصي من أي حليب متبقٍ بعد ساعة من التحضير. نظفي الزجاجات فوراً بعد الاستخدام بفرشاة مخصصة. راقبي علامات الشبع عند طفلك ولا تجبريه على إنهاء الزجاجة.'),
  ]),
  _DiscoverCat(name: 'النوم والراحة', emoji: '😴', articles: [
    _DiscoverArt(title: 'وضعيات النوم الآمنة', emoji: '🛏️', color1: const Color(0xFF5C6BC0),
      image: 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=400&q=80',
      content: 'النوم المريح أثناء الحمل يصبح تحدياً حقيقياً مع تقدم الأشهر وكبر حجم البطن. الوضعية المثلى هي النوم على الجانب الأيسر لأنها تحسن تدفق الدم من القلب إلى الرحم والكلى والجنين وتساعد الكلى على التخلص من الفضلات والسوائل الزائدة بكفاءة مما يقلل تورم اليدين والقدمين والكاحلين. ضعي وسادة مريحة بين ركبتيك لتخفيف الضغط على أسفل الظهر والوركين والحفاظ على استقامة العمود الفقري. وسادة الحمل على شكل حرف يو من أفضل الاستثمارات لأنها تدعم الظهر والبطن والركبتين في آنٍ واحد. يمكنك أيضاً وضع وسادة صغيرة تحت البطن لدعم إضافي. بعد الأسبوع العشرين تجنبي النوم على الظهر لأن وزن الرحم يضغط على الوريد الأجوف السفلي مما يقلل تدفق الدم ويسبب دوخة وانخفاض ضغط الدم وقد يؤثر على وصول الأكسجين للجنين. إذا استيقظتِ ووجدت نفسك على ظهرك لا تقلقي فقط انقلبي على جانبك لأن جسمك يوقظك قبل أن يتأثر الجنين. النوم على الجانب الأيمن مقبول أيضاً إذا لم تستريحي على الأيسر. ارفعي رأسك قليلاً إذا كنت تعانين من حرقة المعدة. أنشئي روتيناً مهدئاً قبل النوم للمساعدة على الاسترخاء والنوم بسرعة.'),
    _DiscoverArt(title: 'التغلب على الأرق', emoji: '🌙', color1: const Color(0xFF7E57C2),
      image: 'https://images.unsplash.com/photo-1511295742362-92c96b1cf484?w=400&q=80',
      content: 'الأرق من المشكلات الشائعة التي تعاني منها كثير من الحوامل خاصة في الثلثين الأول والثالث. في الثلث الأول يسببه ارتفاع هرمون البروجسترون والغثيان وكثرة التبول وفي الثلث الثالث يسببه كبر حجم البطن وآلام الظهر وحركة الجنين وقلق ما قبل الولادة. لمحاربة الأرق أنشئي روتيناً ثابتاً للنوم بالذهاب للسرير والاستيقاظ في نفس الوقت يومياً حتى في عطلة نهاية الأسبوع. خذي حماماً دافئاً قبل النوم بساعة لأنه يرخي العضلات ويساعد الجسم على الاستعداد للنوم. اشربي كوباً من الحليب الدافئ أو شاي البابونج. مارسي تقنيات التنفس العميق والاسترخاء التدريجي للعضلات حيث تشدين كل مجموعة عضلية لبضع ثوانٍ ثم ترخينها من القدمين وصولاً للرأس. تجنبي استخدام الهاتف والشاشات قبل النوم بساعة لأن الضوء الأزرق يثبط إفراز الميلاتونين. اجعلي غرفة النوم مظلمة وهادئة وباردة قليلاً. تجنبي الكافيين بعد الظهر والوجبات الثقيلة قبل النوم. قللي شرب السوائل في المساء لتقليل زيارات الحمام الليلية. إذا لم تستطيعي النوم خلال عشرين دقيقة انهضي وافعلي شيئاً هادئاً حتى تشعري بالنعاس ولا تبقي في السرير قلقة. القيلولة القصيرة عشرين دقيقة في النهار مفيدة لكن لا تطيليها حتى لا تؤثر على نوم الليل.'),
    _DiscoverArt(title: 'التعب والإرهاق', emoji: '😮‍💨', color1: const Color(0xFF78909C),
      image: 'https://images.unsplash.com/photo-1520206183501-b80df61043c2?w=400&q=80',
      content: 'الشعور بالتعب والإرهاق من أكثر أعراض الحمل شيوعاً ويصيب معظم النساء خاصة في الثلث الأول والثالث. في الثلث الأول يسبب ارتفاع هرمون البروجسترون نعاساً شديداً كما أن جسمك يعمل بكامل طاقته لتكوين المشيمة ودعم نمو الجنين. في الثلث الثاني تشعر معظم النساء بعودة الطاقة وهذه فترة ذهبية استغليها. في الثلث الثالث يعود التعب بسبب وزن الحمل وصعوبة النوم وزيادة حجم الدم والتحضير للولادة. للتعامل مع الإرهاق استمعي لجسمك ونامي عندما تشعرين بالتعب ولا تقاوميه. القيلولة القصيرة من عشرين إلى ثلاثين دقيقة في منتصف اليوم تعيد شحن طاقتك بشكل ملحوظ. تناولي وجبات صغيرة ومتكررة غنية بالبروتين والكربوهيدرات المعقدة للحفاظ على مستوى ثابت من الطاقة. اشربي كمية كافية من الماء لأن الجفاف يزيد الإرهاق. مارسي رياضة خفيفة كالمشي لأنها تعزز الطاقة رغم أن هذا يبدو متناقضاً. تأكدي من تناول مكملات الحديد إذا وصفتها لك طبيبتك لأن فقر الدم سبب رئيسي للإرهاق. اطلبي المساعدة من عائلتك في الأعمال المنزلية ولا تحاولي فعل كل شيء بنفسك. رتبي أولوياتك وتخلي عن المهام غير الضرورية. نظمي جدولك بحيث تقومين بالمهام المهمة في أوقات الطاقة العالية.'),
  ]),
  _DiscoverCat(name: 'الصحة النفسية', emoji: '🧠', articles: [
    _DiscoverArt(title: 'التقلبات المزاجية', emoji: '😊', color1: const Color(0xFFFFB300),
      image: 'https://images.unsplash.com/photo-1474552226712-ac0f0961a954?w=400&q=80',
      content: 'التقلبات المزاجية أثناء الحمل أمر طبيعي جداً يصيب معظم النساء الحوامل وتحدث بسبب التغيرات الهرمونية الكبيرة في مستويات الإستروجين والبروجسترون التي تؤثر مباشرة على كيمياء الدماغ والنواقل العصبية المسؤولة عن المزاج. قد تجدين نفسك سعيدة في لحظة وحزينة في اللحظة التالية أو تبكين بسبب أمر تافه أو تغضبين بسهولة وهذا كله طبيعي ومؤقت. للتعامل مع هذه التقلبات اعترفي أولاً بأنها حقيقية وطبيعية ولا تلومي نفسك عليها. تحدثي بصراحة مع شريكك وعائلتك عما تشعرين به لأن فهمهم يخفف كثيراً من الضغط. مارسي رياضة خفيفة بانتظام كالمشي أو اليوغا لأنها تفرز هرمونات السعادة الطبيعية. خصصي وقتاً يومياً لنشاط تستمتعين به سواء كان قراءة أو رسم أو الاستماع للموسيقى أو قضاء وقت مع صديقة. النوم الكافي ضروري لاستقرار المزاج فاحرصي على سبع إلى تسع ساعات ليلاً. التغذية المتوازنة تؤثر على المزاج فتناولي أطعمة غنية بأوميغا 3 والمغنيسيوم وفيتامين ب. تقنيات التنفس العميق والتأمل لدقائق قليلة يومياً تهدئ الجهاز العصبي. إذا شعرت بحزن مستمر لأكثر من أسبوعين أو فقدت الاهتمام بالأشياء التي كنت تستمتعين بها فتحدثي مع طبيبتك لأن هذا قد يكون اكتئاب الحمل ويحتاج دعماً متخصصاً.'),
    _DiscoverArt(title: 'القلق من الولادة', emoji: '💭', color1: const Color(0xFF26A69A),
      image: 'https://images.unsplash.com/photo-1491013516836-7db643ee125a?w=400&q=80',
      content: 'القلق من الولادة شعور طبيعي يصيب كثيراً من النساء خاصة في الحمل الأول لكن المهم ألا يتحول لخوف مسيطر يمنعك من الاستمتاع بحملك. الخوف من المجهول هو السبب الرئيسي فكلما عرفتِ أكثر عن مراحل الولادة قل خوفك. احضري دورة تحضيرية للولادة تتعلمين فيها مراحل المخاض والولادة وتقنيات التنفس والاسترخاء والدفع الفعال وخيارات تخفيف الألم المتاحة من الحقنة فوق الجافية إلى التنفس والماء والتدليك. تحدثي مع طبيبتك بصراحة عن مخاوفك فالأطباء يتفهمون تماماً هذا القلق ويمكنهم طمأنتك وشرح كل شيء بالتفصيل. ضعي خطة ولادة تشمل تفضيلاتك لكن كوني مرنة لأن الولادة قد لا تسير كما خططتِ وهذا طبيعي. اسمعي قصص ولادة إيجابية من صديقات وتجنبي القصص المخيفة على الإنترنت. التأمل الموجه والتخيل الإيجابي تقنيات فعالة جداً تخيلي ولادة سلسة وآمنة وركزي على لحظة حمل طفلك لأول مرة. اكتبي مخاوفك في دفتر واكتبي بجانب كل مخاوف حلاً أو حقيقة مطمئنة. تذكري أن ملايين النساء يلدن بأمان كل يوم وأن الطب الحديث يوفر رعاية ممتازة. حضور الزوج أو شخص تثقين به أثناء الولادة يخفف القلق كثيراً. تذكري أن الألم مؤقت وينتهي بأجمل هدية في العالم.'),
    _DiscoverArt(title: 'الاسترخاء والتأمل', emoji: '🕊️', color1: const Color(0xFFAB47BC),
      image: 'https://images.unsplash.com/photo-1528715471579-d1bcf0ba5e83?w=400&q=80',
      content: 'الاسترخاء والتأمل أدوات قوية للحفاظ على صحتك النفسية والجسدية أثناء الحمل وتحضيرك لتجربة ولادة أكثر هدوءاً وسلاسة. التأمل الذهني أو المايندفولنس يساعدك على التركيز في اللحظة الحالية بدل القلق بشأن المستقبل. ابدئي بخمس دقائق يومياً واجلسي في مكان هادئ ومريح وأغمضي عينيك وركزي على تنفسك. لاحظي الهواء يدخل ويخرج من أنفك دون محاولة تغييره. عندما تشرد أفكارك أعيدي انتباهك بلطف للتنفس دون الحكم على نفسك. تمرين التنفس العميق البطني يهدئ الجهاز العصبي ويقلل هرمونات التوتر. استنشقي ببطء من الأنف لأربع ثوانٍ واملئي بطنك بالهواء ثم ازفري ببطء من الفم لست ثوانٍ. كرري عشر مرات. الاسترخاء التدريجي للعضلات تقنية فعالة شدي كل مجموعة عضلية لخمس ثوانٍ ثم أرخيها تماماً بدءاً من أصابع القدمين وصولاً للرأس. التخيل الموجه تقنية جميلة تخيلي مكاناً آمناً ومريحاً كشاطئ أو حديقة وتخيلي التفاصيل الحسية من أصوات وروائح وألوان. التأمل أثناء الحمل يقلل التوتر والقلق ويحسن النوم ويخفف آلام الجسم ويقوي الرابطة مع الجنين. جربي تطبيقات التأمل الموجه التي تقدم جلسات مخصصة للحوامل. اجعلي التأمل عادة يومية ثابتة.'),
  ]),
  _DiscoverCat(name: 'العمل والحمل', emoji: '💼', articles: [
    _DiscoverArt(title: 'متى تخبرين عملك؟', emoji: '📢', color1: const Color(0xFF42A5F5),
      image: 'https://images.unsplash.com/photo-1573497620053-ea5300f94f21?w=400&q=80',
      content: 'معرفة التوقيت المناسب لإخبار جهة عملك بحملك قرار شخصي يعتمد على عدة عوامل. كثير من النساء يفضلن الانتظار حتى نهاية الثلث الأول أي بعد الأسبوع الثاني عشر عندما ينخفض خطر الإجهاض بشكل كبير. لكن إذا كانت طبيعة عملك تتضمن مخاطر كالتعرض لمواد كيميائية أو رفع أثقال أو إجهاد بدني شديد فمن الأفضل الإخبار مبكراً لطلب تعديلات على مهامك. قانونياً يحق لك الحصول على تسهيلات معقولة في العمل أثناء الحمل مثل فترات راحة إضافية وتعديل ساعات العمل. عند إخبار مديرك اختاري وقتاً هادئاً للحديث بخصوصية وقدمي خطة واضحة لكيفية إدارة مهامك قبل إجازة الأمومة. اقترحي حلولاً لتغطية مسؤولياتك أثناء غيابك مما يظهر مهنيتك والتزامك. تعرفي مسبقاً على حقوقك في إجازة الأمومة حسب قوانين بلدك ونظام شركتك. اسألي قسم الموارد البشرية عن المدة المسموحة والراتب أثناء الإجازة وكيفية التقديم. جهزي ملفاً واضحاً بمهامك ومشاريعك الحالية لتسهيل التسليم. لا تدعي القلق بشأن العمل يؤثر على صحتك فصحتك وصحة طفلك أولوية. تواصلي مع زميلات مررن بنفس التجربة للحصول على نصائح عملية.'),
    _DiscoverArt(title: 'الراحة في المكتب', emoji: '🪑', color1: const Color(0xFF78909C),
      image: 'https://images.unsplash.com/photo-1497215842964-222b430dc094?w=400&q=80',
      content: 'العمل المكتبي أثناء الحمل يحتاج لتعديلات بسيطة لضمان راحتك وصحة حملك. الجلوس لفترات طويلة يزيد آلام الظهر والتورم والإمساك لذلك احرصي على النهوض والمشي لبضع دقائق كل ساعة على الأقل. اضبطي كرسيك بحيث يكون ظهرك مدعوماً تماماً وقدماك مسطحتان على الأرض أو على مسند واستخدمي وسادة داعمة لأسفل الظهر. اجعلي شاشة الكمبيوتر على مستوى عينيك لتجنب إجهاد الرقبة وألم الظهر العلوي. احتفظي بوجبات خفيفة صحية في درج مكتبك مثل المكسرات والفواكه المجففة والبسكويت الكامل لتجنب انخفاض السكر والغثيان. اشربي الماء بانتظام واحتفظي بزجاجة على مكتبك. خذي استراحات قصيرة لتمارين الإطالة ودوري كاحليك أثناء الجلوس لتحسين الدورة الدموية ومنع التورم. إذا كان عملك يتطلب الوقوف لفترات طويلة اطلبي كرسياً للجلوس بين الحين والآخر وارتدي جوارب ضغط طبية. تجنبي رفع الأشياء الثقيلة واطلبي المساعدة. إذا كنت تعانين من غثيان الصباح احتفظي ببسكويت جاف في حقيبتك. تحدثي مع مديرك عن أي تعديلات تحتاجينها فمعظم جهات العمل تتفهم احتياجات الحامل. لا تتجاهلي أي أعراض غير طبيعية أثناء العمل واتصلي بطبيبتك فوراً عند الحاجة.'),
    _DiscoverArt(title: 'إجازة الأمومة', emoji: '📋', color1: const Color(0xFFFF7043),
      image: 'https://images.unsplash.com/photo-1565843708714-52ecf69ab81f?w=400&q=80',
      content: 'إجازة الأمومة حقك القانوني وفترة مهمة للتعافي من الولادة وبناء علاقة قوية مع مولودك الجديد وتأسيس الرضاعة الطبيعية. تختلف مدة إجازة الأمومة حسب قوانين كل بلد ونظام كل شركة لكنها عادة تتراوح بين شهرين وستة أشهر. ابدئي بالتخطيط لإجازتك من الثلث الثاني بالتواصل مع قسم الموارد البشرية لمعرفة حقوقك ومدة الإجازة المدفوعة وغير المدفوعة والأوراق المطلوبة ومواعيد التقديم. جهزي ملفاً شاملاً بجميع مهامك ومشاريعك الحالية والمستقبلية مع تعليمات واضحة لمن سيتولاها أثناء غيابك. درّبي زميلة أو زميل على المهام الأساسية قبل إجازتك بوقت كاف. حددي كيفية التواصل أثناء الإجازة مع الفريق هل تفضلين عدم الإزعاج تماماً أم تقبلين رسائل الطوارئ فقط. فكري أيضاً في خطة العودة للعمل هل ستعودين بدوام كامل أم تفضلين دواماً جزئياً في البداية. بعض الشركات توفر مرونة في ساعات العمل أو العمل من المنزل للأمهات الجدد. خططي للرعاية أثناء عودتك هل ستعتنين بالطفل الأم أو الحماة أو حاضنة أو حضانة. ابدئي البحث مبكراً خاصة إذا كنت تفكرين في حضانة لأن الأماكن تُحجز سريعاً. استمتعي بإجازتك قدر الإمكان وركزي على التعافي والتعرف على طفلك الجديد.'),
  ]),
  _DiscoverCat(name: 'العلاقات والأسرة', emoji: '👨‍👩‍👧', articles: [
    _DiscoverArt(title: 'دور الأب أثناء الحمل', emoji: '👨', color1: const Color(0xFF5C6BC0),
      image: 'https://images.unsplash.com/photo-1476703993599-0035a21b17a9?w=400&q=80',
      content: 'دور الأب لا يقل أهمية عن دور الأم أثناء الحمل ومشاركته الفعالة تصنع فرقاً كبيراً في صحة الأم النفسية والجسدية وتقوي الرابطة الأسرية من البداية. يمكن للأب المشاركة في مواعيد الطبيب الدورية وحضور جلسات السونار ورؤية الجنين وسماع نبضه مما يعمق ارتباطه بالطفل قبل ولادته. المشاركة في اتخاذ القرارات المتعلقة بالحمل والولادة مثل اختيار المستشفى ونوع الولادة واسم المولود تجعل الأب شريكاً حقيقياً في الرحلة. الدعم العاطفي يعني الاستماع لمخاوف الزوجة دون التقليل منها والتفهم والصبر على التقلبات المزاجية الطبيعية الناتجة عن التغيرات الهرمونية. الدعم العملي يشمل المساعدة في الأعمال المنزلية والطبخ والتسوق خاصة عندما تكون الزوجة متعبة أو تعاني من الغثيان. تعلم عن مراحل الحمل المختلفة والأعراض المتوقعة في كل ثلث لتفهم ما تمر به زوجتك. رافقها في المشي وشاركها في تمارين الاسترخاء. شارك في تحضيرات استقبال المولود وتجهيز الغرفة وشراء المستلزمات. احضر دورة تحضيرية للولادة معها لتعرف كيف تدعمها أثناء المخاض. تعلم أساسيات رعاية المولود كتغيير الحفاض والاستحمام والتجشؤ. حضورك ومشاركتك النشطة يمنحها الثقة والأمان ويبني علاقة أبوية قوية تستمر مدى الحياة.'),
    _DiscoverArt(title: 'تحضير الأبناء للمولود', emoji: '👧', color1: const Color(0xFFEC407A),
      image: 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80',
      content: 'إذا كان لديك أطفال أكبر سناً فتحضيرهم نفسياً لاستقبال الأخ أو الأخت الجديدة من أهم الخطوات لضمان انتقال سلس للعائلة بأكملها. ابدئي بالحديث عن المولود القادم مبكراً بطريقة إيجابية ومشوقة مناسبة لعمر الطفل. للأطفال الصغار تحت ثلاث سنوات اقرئي كتباً مصورة عن الأخوة الجدد وأشركيهم في مشاهدة صور السونار ولمس بطنك عندما يتحرك الجنين. للأطفال الأكبر اشركيهم في التحضيرات كاختيار ملابس المولود وتزيين غرفته واختيار هدية يقدمونها للأخ الجديد. كوني صادقة بشأن التغييرات القادمة واشرحي لهم أن المولود سيبكي كثيراً ويحتاج اهتماماً ولكن هذا لا يعني أنكم تحبونهم أقل. حافظي على روتين الأطفال الحاليين قدر الإمكان بعد الولادة لأن التغيير المفاجئ يزيد شعورهم بعدم الأمان. خصصي وقتاً يومياً لكل طفل بمفرده لتجنب الغيرة. عند وصول المولود اسمحي للأطفال بمساعدتك في مهام بسيطة كإحضار الحفاض أو الغناء للمولود فهذا يشعرهم بالأهمية والمسؤولية. لا تتوقعي حباً فورياً فبعض الأطفال يحتاجون وقتاً للتأقلم وقد يظهرون سلوكيات تراجعية كالتبول اللاإرادي أو التعلق الزائد وهذا طبيعي ومؤقت. امدحي أي تفاعل إيجابي بين الأخوة. تحلي بالصبر والمحبة.'),
    _DiscoverArt(title: 'العلاقة الزوجية والحمل', emoji: '❤️', color1: const Color(0xFFE91E63),
      image: 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=400&q=80',
      content: 'الحمل يؤثر على العلاقة الزوجية بطرق متعددة ويحتاج الزوجان لتفهم والتواصل المفتوح للمحافظة على علاقة صحية وقوية خلال هذه المرحلة. التغيرات الهرمونية قد تؤثر على الرغبة الجنسية لدى الزوجة فقد تزيد في فترات وتنخفض في أخرى وهذا طبيعي تماماً. العلاقة الحميمية آمنة في معظم حالات الحمل الطبيعية ما لم تمنعها الطبيبة لسبب طبي محدد. تحدثا بصراحة عن احتياجاتكما ومشاعركما دون خجل لأن التواصل المفتوح يمنع سوء الفهم والإحباط. التقارب العاطفي لا يقل أهمية عن التقارب الجسدي فخصصا وقتاً للتحدث والاستماع لبعضكما وتبادل المخاوف والأحلام المتعلقة بالأبوة والأمومة. خططا لأنشطة ممتعة معاً كالخروج لعشاء رومانسي أو مشاهدة فيلم أو المشي في الطبيعة فهذه اللحظات تقوي الرابطة بينكما. من الطبيعي أن يشعر الزوج بالقلق أيضاً بشأن مسؤوليات الأبوة والوضع المالي والتغيرات في الحياة. شاركا هذه المخاوف معاً وابحثا عن حلول مشتركة. اذهبا لمواعيد الطبيب معاً وشاركا في دورات تحضيرية للولادة فهذه التجارب المشتركة تعمق الشراكة. تذكرا أن الحمل مرحلة مؤقتة وأن العائلة التي ستبنيانها معاً هي أجمل مشروع في حياتكما. ادعما بعضكما بالحب والصبر والتفهم.'),
  ]),
  _DiscoverCat(name: 'الفحوصات الطبية', emoji: '🔬', articles: [
    _DiscoverArt(title: 'فحوصات الثلث الأول', emoji: '🩸', color1: const Color(0xFFE53935),
      image: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&q=80',
      content: 'الثلث الأول من الحمل يمتد من الأسبوع الأول حتى الثالث عشر وهو فترة حاسمة تتكون فيها جميع أعضاء الجنين الرئيسية. الفحوصات في هذه المرحلة تهدف لتأكيد الحمل وتقييم صحة الأم واكتشاف أي مخاطر مبكراً. أول فحص هو تحليل الدم الشامل الذي يقيس مستوى الهيموغلوبين وخلايا الدم ويكشف عن فقر الدم. فحص فصيلة الدم وعامل ريسوس ضروري لأنه إذا كانت فصيلتك سالبة وفصيلة الأب موجبة فقد تحتاجين حقنة مضادة لمنع تكوين أجسام مضادة تهاجم خلايا دم الجنين. فحص السكر الصيامي يكشف عن وجود سكري مسبق يحتاج إدارة دقيقة أثناء الحمل. فحص وظائف الغدة الدرقية مهم لأن اضطراباتها شائعة وتؤثر على نمو الجنين العقلي. فحص الأمراض المعدية يشمل التهاب الكبد وفيروس نقص المناعة والحصبة الألمانية وداء القطط. أول سونار يكون بين الأسبوع السادس والثامن لتأكيد الحمل داخل الرحم وسماع نبض الجنين وتحديد عمره بدقة. في الأسبوع الحادي عشر إلى الرابع عشر يُجرى فحص الشفافية القفوية مع تحليل دم لتقييم خطر المتلازمات الكروموسومية كمتلازمة داون. هذا فحص تقييمي وليس تشخيصياً وإذا كانت النتائج مقلقة تتوفر فحوصات إضافية. التزمي بكل المواعيد واسألي طبيبتك عن كل ما يقلقك.'),
    _DiscoverArt(title: 'فحص السونار التفصيلي', emoji: '📺', color1: const Color(0xFF7E57C2),
      image: 'https://images.unsplash.com/photo-1559757175-5700dde675bc?w=400&q=80',
      content: 'السونار التفصيلي أو فحص التشريح يُجرى بين الأسبوع الثامن عشر والثاني والعشرين ويعتبر أهم فحص بالموجات فوق الصوتية خلال الحمل. يستغرق من عشرين إلى أربعين دقيقة حسب وضعية الجنين وتعاونه. يفحص الطبيب بدقة جميع أعضاء الجنين بما في ذلك الدماغ والوجه والقلب بحجراته الأربع وصماماته والعمود الفقري فقرة فقرة والكليتين والمعدة والأمعاء والمثانة والأطراف بعظامها وأصابعها. يقيس محيط الرأس ومحيط البطن وطول عظم الفخذ لتقييم نمو الجنين ومقارنته بالمعدلات الطبيعية. يتحقق من وضع المشيمة وموقعها من عنق الرحم وكمية السائل الأمنيوسي وطول عنق الرحم. إذا كانت المشيمة منخفضة فقد يُطلب فحص متابعة لاحق لأنها غالباً ترتفع مع نمو الرحم. يمكنك في هذا الفحص معرفة جنس المولود إن رغبت في ذلك. قد يُطلب منك شرب ماء قبل الفحص لامتلاء المثانة جزئياً مما يحسن جودة الصور. إذا لم تكن الصور واضحة بسبب وضعية الجنين قد يُطلب منك المشي قليلاً أو العودة لفحص تكميلي. لا تقلقي إذا طلب الطبيب إعادة فحص جزء معين فهذا لا يعني بالضرورة وجود مشكلة بل قد يكون بسبب صعوبة الرؤية. اسألي عن كل ما يقلقك واطلبي صوراً تذكارية.'),
    _DiscoverArt(title: 'فحص سكر الحمل', emoji: '🍬', color1: const Color(0xFFFF8F00),
      image: 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=400&q=80',
      content: 'فحص سكري الحمل أو اختبار تحمل الجلوكوز يُجرى عادة بين الأسبوع الرابع والعشرين والثامن والعشرين وهو من أهم فحوصات الحمل لأن سكري الحمل يصيب من خمسة إلى عشرة بالمئة من الحوامل وقد لا تظهر له أعراض واضحة. يحدث سكري الحمل عندما لا يستطيع الجسم إنتاج كمية كافية من الأنسولين لمواكبة مقاومة الأنسولين الطبيعية التي تحدث أثناء الحمل. الفحص يتم بشرب محلول سكري يحتوي على خمسين أو خمسة وسبعين غراماً من الجلوكوز ثم قياس مستوى السكر في الدم بعد ساعة أو ساعتين. لا تحتاجين الصيام قبل الفحص بخمسين غراماً لكن فحص الخمسة والسبعين يتطلب صياماً ليلياً. إذا كانت النتيجة مرتفعة في الفحص الأول قد تُطلب منك إعادته بجرعة أعلى للتأكيد. سكري الحمل غير المعالج يسبب مضاعفات مثل كبر حجم الجنين وصعوبة الولادة وانخفاض سكر المولود بعد الولادة وزيادة خطر الولادة القيصرية واحتمال إصابة الأم بسكري من النوع الثاني مستقبلاً. العلاج يبدأ بنظام غذائي متوازن يعتمد على تقليل الكربوهيدرات البسيطة وزيادة الألياف والبروتين مع قياس السكر عدة مرات يومياً. الرياضة المنتظمة كالمشي تحسن حساسية الأنسولين. إذا لم يكفِ النظام الغذائي والرياضة فقد تحتاجين حقن الأنسولين. سكري الحمل يختفي عادة بعد الولادة لكن يجب فحص السكر بعد ستة أسابيع.'),
  ]),
  _DiscoverCat(name: 'الجمال والعناية', emoji: '💅', articles: [
    _DiscoverArt(title: 'العناية بالبشرة', emoji: '🧴', color1: const Color(0xFFFF7043),
      image: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=400&q=80',
      content: 'بشرتك أثناء الحمل تمر بتحولات ملحوظة بسبب التغيرات الهرمونية وزيادة تدفق الدم. بعض النساء يحظين بتوهج الحمل الشهير وبشرة نضرة ومشرقة بينما تعاني أخريات من مشاكل جلدية مختلفة. الكلف أو قناع الحمل يظهر كبقع بنية على الجبين والخدين وأعلى الشفة بسبب زيادة إنتاج الميلانين. أفضل وقاية هي واقي الشمس المعدني بعامل حماية خمسين أو أكثر يومياً مع قبعة واسعة ونظارات شمسية. حب شباب الحمل شائع في الثلث الأول بسبب ارتفاع هرمونات الأندروجين. نظفي وجهك بغسول لطيف خالٍ من الكحول مرتين يومياً واستخدمي حمض الأزيليك الآمن للحمل. تجنبي الريتينول وحمض الساليسيليك المركز والبنزويل بيروكسيد بتركيز عالٍ والهيدروكينون. للترطيب اختاري كريمات خالية من العطور ومناسبة لنوع بشرتك. اشربي كمية وفيرة من الماء وتناولي أطعمة غنية بفيتامين سي والإي وأوميغا 3 لتغذية البشرة من الداخل. خط البطن الداكن أو لينيا نيغرا طبيعي تماماً ويختفي بعد الولادة. استخدمي ماسكات طبيعية آمنة أسبوعياً كالعسل مع الزبادي. دللي نفسك بروتين عناية يومي واعتبريه وقتاً خاصاً بك.'),
    _DiscoverArt(title: 'العناية بالشعر', emoji: '💇‍♀️', color1: const Color(0xFF8D6E63),
      image: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80',
      content: 'شعرك أثناء الحمل قد يمر بتغيرات ملحوظة بفضل ارتفاع هرمون الإستروجين الذي يطيل دورة نمو الشعر. كثير من النساء يلاحظن أن شعرهن أصبح أكثر كثافة ولمعاناً خلال الحمل وهذا من الآثار الجميلة للتغيرات الهرمونية. لكن بعض النساء يعانين من جفاف الشعر أو تساقطه خاصة إذا كان هناك نقص في الحديد أو الفيتامينات. استخدمي شامبو لطيف خالي من الكبريتات والبارابين وبلسم مرطب مناسب لنوع شعرك. قللي استخدام مجفف الشعر ومكواة التمليس لتجنب تلف الشعر. حمام الزيت الأسبوعي بزيت جوز الهند أو زيت الأرغان أو زيت الزيتون يغذي الشعر ويمنحه لمعاناً. بالنسبة للصبغة فالأبحاث الحديثة تشير إلى أن صبغات الشعر آمنة نسبياً بعد الثلث الأول لكن من الأفضل اختيار صبغات خالية من الأمونيا أو صبغات نباتية كالحناء واستخدامها في مكان جيد التهوية. تجنبي فرد الشعر الكيميائي الكيراتين والبروتين أثناء الحمل بسبب مخاوف من المواد الكيميائية المستخدمة. تناولي أطعمة غنية بالبيوتين والحديد والزنك وأوميغا 3 لتغذية الشعر من الداخل. بعد الولادة من الطبيعي تساقط الشعر بكثافة في الشهر الثالث إلى السادس وهذا يسمى تساقط ما بعد الولادة وهو مؤقت ويعود الشعر لطبيعته خلال سنة.'),
    _DiscoverArt(title: 'الولادة والتحضير', emoji: '🏥', color1: const Color(0xFFAB47BC),
      image: 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=400&q=80',
      content: 'التحضير الجيد للولادة يمنحك الثقة والهدوء ويساعد على تجربة أكثر إيجابية سواء كانت ولادة طبيعية أو قيصرية. ابدئي التحضير من الثلث الثالث بحضور دورة تحضيرية للولادة تتعلمين فيها مراحل المخاض الثلاث وتقنيات التنفس والاسترخاء ووضعيات تسهيل الولادة وطرق تخفيف الألم المتاحة. تعرفي على مراحل المخاض المرحلة الأولى وهي انفتاح عنق الرحم وتنقسم لمرحلة كامنة بطيئة ومرحلة نشطة أسرع ثم المرحلة الثانية وهي الدفع وخروج الطفل والمرحلة الثالثة وهي نزول المشيمة. ضعي خطة ولادة مرنة تشمل تفضيلاتك حول مكان الولادة ومن تريدين بجانبك وموقفك من التخدير والتدخلات الطبية. ناقشيها مع طبيبتك مع فهم أن الظروف قد تتغير والمرونة ضرورية. تعرفي على خيارات تخفيف الألم من التنفس والتدليك والماء الدافئ إلى الحقنة فوق الجافية. جهزي حقيبة المستشفى من الأسبوع السادس والثلاثين واحفظي أرقام الطوارئ. تعرفي على علامات بدء المخاض الحقيقي وهي انقباضات منتظمة تقترب من بعضها وتشتد ونزول ماء الرأس وآلام أسفل الظهر المنتظمة. اعرفي متى تذهبين للمستشفى عادة عندما تصبح الانقباضات كل خمس دقائق لمدة دقيقة واحدة لساعة كاملة. ثقي بجسمك وبفريقك الطبي وتذكري أن كل انقباض يقربك لحظة من لقاء طفلك.'),
  ]),

  _DiscoverCat(name: 'أخبار الحمل الحديثة', emoji: '📰', articles: [
    _DiscoverArt(
      title: 'توصيات منظمة الصحة العالمية الجديدة للحوامل',
      emoji: '🌍',
      color1: const Color(0xFF43A047),
      image: 'assets/images/pregnancy_news/1a35f769970a25566a64f468e8ef9c33.jpg',
      content: 'أصدرت منظمة الصحة العالمية مؤخراً مجموعة محدّثة من التوصيات الخاصة برعاية الحوامل، وذلك في إطار سعيها المستمر لتحسين صحة الأمهات والأجنّة حول العالم. تتضمّن هذه التوصيات الجديدة زيادة عدد زيارات المتابعة خلال فترة الحمل من أربع زيارات كحدّ أدنى إلى ثماني زيارات على الأقل، وذلك بهدف الكشف المبكّر عن أي مضاعفات محتملة والتعامل معها في الوقت المناسب. كما شدّدت المنظمة على أهمية إجراء فحوصات الدم الشاملة في كل زيارة، بما في ذلك فحص مستوى الهيموغلوبين وفحص سكر الدم وفحص وظائف الكلى والكبد. وأوصت المنظمة كذلك بضرورة توفير الدعم النفسي والاجتماعي للحوامل كجزء أساسي من الرعاية الصحية، حيث أظهرت الدراسات أن الصحة النفسية للأم تؤثّر بشكل مباشر على نمو الجنين وتطوّره. ومن أبرز التوصيات الجديدة أيضاً التأكيد على أهمية التغذية المتوازنة وتناول المكمّلات الغذائية الضرورية مثل حمض الفوليك والحديد والكالسيوم وفيتامين د، مع مراعاة الجرعات المناسبة لكل مرحلة من مراحل الحمل. وفيما يخصّ النشاط البدني، أكّدت المنظمة على أن ممارسة التمارين الرياضية المعتدلة لمدة مائة وخمسين دقيقة أسبوعياً على الأقل تُعدّ آمنة ومفيدة لمعظم الحوامل، شريطة عدم وجود موانع طبية. كما تناولت التوصيات موضوع التطعيمات خلال الحمل، حيث أوصت بضرورة حصول الحوامل على لقاح الإنفلونزا الموسمية ولقاح السعال الديكي في الثلث الثالث من الحمل لحماية الأم والمولود. وأشارت المنظمة إلى أهمية استخدام التكنولوجيا الحديثة في متابعة الحمل، بما في ذلك تطبيقات الهاتف المحمول والاستشارات الطبية عن بُعد، خاصةً في المناطق النائية التي يصعب فيها الوصول إلى المرافق الصحية. وختاماً، دعت المنظمة جميع الدول إلى تبنّي هذه التوصيات وتوفير الموارد اللازمة لتطبيقها على أرض الواقع.',
    ),
    _DiscoverArt(
      title: 'تحديثات مهمة حول فيتامينات الحمل',
      emoji: '💊',
      color1: const Color(0xFFE53935),
      image: 'assets/images/pregnancy_news/2f7b711d05273620ad71b038d996bcb2.jpg',
      content: 'شهدت الأوساط الطبية مؤخراً تحديثات مهمة فيما يتعلّق بالمكمّلات الغذائية والفيتامينات الموصى بها خلال فترة الحمل، حيث أظهرت الأبحاث الحديثة أن بعض الجرعات التقليدية قد لا تكون كافية لتلبية احتياجات الأم والجنين. من أبرز هذه التحديثات ما يتعلّق بفيتامين د، إذ رفعت العديد من الهيئات الصحية الجرعة اليومية الموصى بها للحوامل من أربعمائة وحدة دولية إلى ألف وحدة دولية يومياً، وذلك بعد أن أثبتت الدراسات أن نقص فيتامين د شائع جداً بين الحوامل ويرتبط بزيادة خطر الإصابة بتسمّم الحمل وسكّري الحمل وانخفاض وزن المولود. كما أُضيفت توصيات جديدة بشأن أحماض أوميغا ثلاثة الدهنية، حيث أصبح يُنصح بتناول مكمّلات تحتوي على حمض الدوكوساهيكسانويك بجرعة لا تقل عن مائتي ملليغرام يومياً لدعم نمو دماغ الجنين وشبكية عينه. أما بالنسبة لحمض الفوليك، فقد أكّدت التوصيات الجديدة على أهمية البدء بتناوله قبل الحمل بثلاثة أشهر على الأقل، مع زيادة الجرعة للنساء اللواتي لديهنّ تاريخ سابق لعيوب الأنبوب العصبي. وفيما يخصّ الحديد، أوصت الدراسات بإجراء فحص مستوى الفيريتين في بداية الحمل لتحديد ما إذا كانت المرأة بحاجة إلى مكمّلات حديد إضافية، بدلاً من وصف الحديد بشكل روتيني لجميع الحوامل. كذلك سلّطت الأبحاث الضوء على أهمية الكولين كعنصر غذائي أساسي خلال الحمل، حيث يلعب دوراً محورياً في تطوّر الجهاز العصبي للجنين، ويُنصح بتناول أربعمائة وخمسين ملليغراماً منه يومياً. ومن المستجدات أيضاً التأكيد على أن البروبيوتيك يمكن أن يساعد في تقليل خطر الإصابة بسكّري الحمل وتسمّم الحمل، وهو ما يمثّل إضافة واعدة لبرنامج المكمّلات الغذائية أثناء الحمل. تبقى استشارة الطبيب المتابع ضرورية قبل تناول أي مكمّلات جديدة لضمان السلامة والجرعة المناسبة.',
    ),
    _DiscoverArt(
      title: 'فحص سكّري الحمل: إرشادات محدّثة',
      emoji: '🩸',
      color1: const Color(0xFF00ACC1),
      image: 'assets/images/pregnancy_news/4501336a157ccc7bb5f033329f2cd105.jpg',
      content: 'أعلنت الجمعية الأمريكية للسكّري عن تحديثات جوهرية في بروتوكول فحص سكّري الحمل، وهي تحديثات من المتوقّع أن تغيّر الطريقة التي يتم بها الكشف عن هذه الحالة الشائعة التي تصيب ما بين ستة إلى تسعة بالمائة من الحوامل حول العالم. تتضمّن الإرشادات الجديدة التوصية بإجراء فحص مبكّر لسكّر الدم في الزيارة الأولى للحامل، وذلك للكشف عن حالات السكّري غير المشخّصة مسبقاً، خاصةً لدى النساء اللواتي لديهنّ عوامل خطر مثل السمنة أو التاريخ العائلي للسكّري أو الإصابة بسكّري الحمل في حمل سابق. أما الفحص الروتيني الذي يُجرى عادةً بين الأسبوع الرابع والعشرين والثامن والعشرين من الحمل، فقد شهد تغييرات في معايير التشخيص، حيث أصبح يُستخدم اختبار تحمّل الغلوكوز بخطوة واحدة بدلاً من الخطوتين التقليديتين، مما يوفّر الوقت ويزيد دقّة التشخيص. وتشمل المعايير الجديدة خفض عتبة تشخيص سكّري الحمل، مما يعني أن عدداً أكبر من النساء سيتم تشخيصهنّ والبدء في علاجهنّ مبكّراً، وهو ما يُسهم في تقليل المضاعفات. كما أكّدت الإرشادات على أهمية المتابعة المستمرة بعد الولادة، حيث أن النساء اللواتي أُصبن بسكّري الحمل يكنّ أكثر عرضة للإصابة بالسكّري من النوع الثاني في المستقبل بنسبة تصل إلى خمسين بالمائة. ولذلك يُنصح بإجراء فحص سكّر الدم بعد ستة إلى اثني عشر أسبوعاً من الولادة، ثم بشكل دوري كل سنة إلى ثلاث سنوات. وتضمّنت التحديثات أيضاً إرشادات غذائية مفصّلة تُركّز على تقليل الكربوهيدرات المكرّرة وزيادة تناول الألياف والبروتين، مع التأكيد على أن النظام الغذائي وحده قد لا يكون كافياً في بعض الحالات وأن استخدام الأنسولين أو الميتفورمين قد يكون ضرورياً. هذه التحديثات تمثّل خطوة مهمة نحو رعاية أفضل للحوامل المصابات بسكّري الحمل.',
    ),
    _DiscoverArt(
      title: 'دليل متابعة الحمل: ما الجديد في الرعاية السابقة للولادة؟',
      emoji: '📋',
      color1: const Color(0xFFFF8F00),
      image: 'assets/images/pregnancy_news/46842e7f63a068fc5efb5c8c5657a7e6.jpg',
      content: 'تطوّرت إرشادات الرعاية السابقة للولادة بشكل ملحوظ في السنوات الأخيرة، حيث باتت تركّز على نهج أكثر شمولية يأخذ بعين الاعتبار الجوانب الجسدية والنفسية والاجتماعية لصحة الأم. من أبرز التطوّرات الجديدة اعتماد نموذج الرعاية الجماعية للحوامل، وهو نموذج يجمع بين ثماني إلى اثنتي عشرة حاملاً في جلسات متابعة مشتركة يقودها طبيب أو قابلة مؤهّلة. أثبت هذا النموذج فعاليته في تحسين نتائج الحمل وتقليل معدّلات الولادة المبكّرة وزيادة رضا الأمهات عن الرعاية المقدّمة لهنّ. كما شهدت إرشادات الفحوصات الروتينية تحديثات مهمة، حيث أُضيف فحص الغدة الدرقية في بداية الحمل كفحص روتيني بدلاً من قصره على النساء ذوات عوامل الخطر فقط، وذلك بعد أن أظهرت الدراسات أن اضطرابات الغدة الدرقية غير المعالجة تؤثّر سلباً على النمو العقلي للجنين. وفيما يتعلّق بالتصوير بالموجات فوق الصوتية، أصبح يُوصى بإجراء فحص مفصّل للتشوّهات في الأسبوع العشرين مع استخدام تقنية الدوبلر لتقييم تدفّق الدم في الشرايين الرحمية، مما يساعد في التنبّؤ المبكّر بتسمّم الحمل. وتناولت الإرشادات الحديثة أيضاً موضوع الصحة النفسية، حيث أصبح يُنصح بإجراء فحص روتيني للاكتئاب والقلق في كل ثلث من أثلاث الحمل باستخدام استبيانات معيارية مثل مقياس إدنبرة للاكتئاب بعد الولادة. ومن التحديثات اللافتة كذلك التوصية باستخدام الأسبرين بجرعة منخفضة ابتداءً من الأسبوع الثاني عشر للنساء المعرّضات لخطر الإصابة بتسمّم الحمل، وهي توصية أثبتت فعاليتها في تقليل حدوث هذه المضاعفة الخطيرة بنسبة تتراوح بين عشرين وثلاثين بالمائة. تهدف جميع هذه التحديثات إلى ضمان حمل أكثر أماناً وصحةً للأم والجنين معاً.',
    ),
    _DiscoverArt(
      title: 'تطوّرات مراقبة نبض الجنين وحركته',
      emoji: '💓',
      color1: const Color(0xFF5C6BC0),
      image: 'https://images.unsplash.com/photo-1584515933487-779824d29309?w=800&q=80',
      content: 'شهد مجال مراقبة الجنين تطوّرات تقنية مذهلة في الفترة الأخيرة، حيث انتقلنا من الاعتماد الكامل على أجهزة المستشفى الضخمة إلى أجهزة محمولة صغيرة الحجم يمكن استخدامها في المنزل. من أبرز هذه التطوّرات ظهور أجهزة مراقبة نبض الجنين المنزلية المتّصلة بالهاتف الذكي، والتي تستخدم تقنية الدوبلر الآمنة لرصد نبضات قلب الجنين وإرسال البيانات مباشرةً إلى الطبيب المتابع. ومع ذلك، حذّرت الجمعيات الطبية من الاعتماد الكلّي على هذه الأجهزة دون إشراف طبي، إذ قد تعطي نتائج مطمئنة خاطئة أو تسبّب قلقاً غير مبرّر. وفي مجال التخطيط الكهربائي لقلب الجنين، طُوِّرت تقنية جديدة تعتمد على أقطاب كهربائية مرنة تُوضع على بطن الأم وتُسجّل النشاط الكهربائي لقلب الجنين بدقّة عالية، مما يتيح الكشف المبكّر عن اضطرابات نظم القلب الجنينية. كما أحدثت تقنيات الذكاء الاصطناعي ثورة في تحليل تسجيلات تخطيط قلب الجنين، حيث أصبحت الخوارزميات قادرة على تحليل الأنماط المعقّدة واكتشاف علامات الضائقة الجنينية قبل أن يتمكّن الطبيب البشري من ملاحظتها. وتتضمّن التطوّرات الحديثة أيضاً تطبيقات ذكية لتتبّع حركة الجنين، حيث يمكن للأم تسجيل عدد الركلات والحركات يومياً، ويقوم التطبيق بتحليل الأنماط وتنبيه الأم إذا لاحظ أي انخفاض غير طبيعي في النشاط الحركي. ومن التقنيات الواعدة كذلك استخدام الموجات فوق الصوتية ثلاثية الأبعاد بشكل دوري لمراقبة نمو الجنين وتقييم حجم السائل الأمنيوسي ووظيفة المشيمة. كل هذه التطوّرات تهدف إلى تمكين الأم والفريق الطبي من متابعة صحة الجنين بشكل أكثر دقّة واستمرارية، مما يسهم في تحسين نتائج الحمل والولادة بشكل ملموس.',
    ),
    _DiscoverArt(
      title: 'إرشادات الرياضة أثناء الحمل: تحديثات مبنية على الأدلّة',
      emoji: '🏃‍♀️',
      color1: const Color(0xFF26A69A),
      image: 'assets/images/pregnancy_news/525570d8fd6740c5d5a545dcd0682e54.jpg',
      content: 'أصدرت الكلية الأمريكية لأطباء النساء والتوليد إرشادات محدّثة حول ممارسة الرياضة أثناء الحمل، مؤكّدةً أن النشاط البدني المنتظم يُعدّ آمناً ومفيداً لمعظم الحوامل وأنه يجب تشجيعه كجزء أساسي من الرعاية السابقة للولادة. تنصح الإرشادات الجديدة بممارسة نشاط بدني متوسّط الشدّة لمدة لا تقل عن مائة وخمسين دقيقة أسبوعياً، ويمكن توزيعها على خمسة أيام بمعدّل ثلاثين دقيقة يومياً. ومن أهم الفوائد المثبتة علمياً لممارسة الرياضة أثناء الحمل تقليل خطر الإصابة بسكّري الحمل بنسبة تصل إلى خمسة وعشرين بالمائة، وتقليل خطر تسمّم الحمل، وتحسين المزاج وتقليل أعراض الاكتئاب والقلق، وتسهيل عملية الولادة وتقصير مدّتها، وتسريع التعافي بعد الولادة. وتشمل التمارين الموصى بها المشي السريع والسباحة وركوب الدراجة الثابتة واليوغا المعدّلة للحوامل وتمارين القوّة الخفيفة. أما التمارين التي يجب تجنّبها فتشمل الرياضات التي تنطوي على خطر السقوط أو الصدمات مثل ركوب الخيل والتزلّج والرياضات القتالية، وكذلك التمارين التي تتطلّب الاستلقاء على الظهر لفترات طويلة بعد الثلث الأول من الحمل. وأكّدت الإرشادات على ضرورة التوقّف عن التمرين فوراً واستشارة الطبيب في حال ظهور أعراض مثل النزيف المهبلي أو ضيق التنفّس الشديد أو الدوخة أو آلام الصدر أو تقلّصات الرحم المنتظمة أو تسرّب السائل الأمنيوسي. كما نبّهت إلى أهمية الحفاظ على ترطيب الجسم وتجنّب ارتفاع درجة حرارة الجسم المفرط أثناء التمرين، خاصةً في الثلث الأول من الحمل. وأشارت الإرشادات إلى أن النساء اللواتي كنّ يمارسن رياضة عالية الشدّة قبل الحمل يمكنهنّ الاستمرار في ذلك بعد استشارة الطبيب، مع إجراء التعديلات اللازمة مع تقدّم الحمل.',
    ),
  ]),

  _DiscoverCat(name: 'دراسات وأبحاث', emoji: '🔬', articles: [
    _DiscoverArt(
      title: 'الميكروبيوم المعوي والحمل: اكتشافات مذهلة',
      emoji: '🦠',
      color1: const Color(0xFF8E24AA),
      image: 'assets/images/pregnancy_news/5f2cdc3f6e71c31585aa1a68f767a70b.jpg',
      content: 'كشفت دراسات علمية حديثة عن العلاقة المعقّدة والمثيرة بين الميكروبيوم المعوي للأم الحامل وصحة الحمل ونمو الجنين. يتكوّن الميكروبيوم المعوي من تريليونات البكتيريا والكائنات الدقيقة التي تعيش في الجهاز الهضمي، وقد تبيّن أن تركيبة هذا المجتمع الميكروبي تتغيّر بشكل كبير خلال فترة الحمل. ففي الثلث الأول من الحمل يكون الميكروبيوم مشابهاً لما هو عليه قبل الحمل، لكن مع تقدّم الحمل تحدث تحوّلات جذرية في تنوّع وتركيبة البكتيريا المعوية. أظهرت الأبحاث أن هذه التغيّرات ليست عشوائية بل هي تكيّفات طبيعية تساعد جسم الأم على تخزين المزيد من الدهون والطاقة لدعم نمو الجنين. ومن الاكتشافات المثيرة أن بكتيريا الأمعاء تنتقل من الأم إلى الجنين عبر المشيمة والسائل الأمنيوسي، مما يعني أن تأسيس الميكروبيوم الخاص بالطفل يبدأ قبل الولادة وليس خلالها كما كان يُعتقد سابقاً. وربطت دراسات أخرى بين اختلال توازن الميكروبيوم المعوي للأم وزيادة خطر الإصابة بمضاعفات مثل تسمّم الحمل وسكّري الحمل والولادة المبكّرة. كما أظهرت الأبحاث أن تناول البروبيوتيك خلال الحمل يمكن أن يقلّل من خطر إصابة المولود بالحساسية والإكزيما في السنوات الأولى من حياته. ومن النتائج الواعدة أيضاً أن النظام الغذائي الغني بالألياف والأطعمة المخمّرة يُسهم في تعزيز تنوّع الميكروبيوم وتحسين نتائج الحمل. وتفتح هذه الاكتشافات آفاقاً جديدة لتطوير علاجات مبتكرة تعتمد على تعديل الميكروبيوم المعوي لتحسين صحة الأم والجنين، وهو مجال بحثي واعد يشهد نمواً متسارعاً في الأوساط العلمية.',
    ),
    _DiscoverArt(
      title: 'تأثير التوتّر على الحمل: ماذا تقول الأبحاث؟',
      emoji: '🧠',
      color1: const Color(0xFFEC407A),
      image: 'assets/images/pregnancy_news/6f837870b234527e967babe6452041b3.jpg',
      content: 'سلّطت الأبحاث العلمية الحديثة الضوء على التأثيرات العميقة والمتعدّدة الأبعاد للتوتّر والإجهاد النفسي خلال فترة الحمل على صحة الأم والجنين معاً. عندما تتعرّض الحامل لمستويات عالية من التوتّر المزمن، يفرز جسمها كمّيات كبيرة من هرمون الكورتيزول الذي يمكن أن يعبر المشيمة ويؤثّر على نمو الجنين وتطوّر دماغه. أظهرت دراسة واسعة النطاق شملت أكثر من خمسة آلاف حامل أن التعرّض للتوتّر الشديد خلال الثلث الأول من الحمل يرتبط بزيادة خطر الولادة المبكّرة بنسبة خمسة وثلاثين بالمائة وانخفاض وزن المولود عند الولادة. كما كشفت أبحاث أخرى أن التوتّر المزمن يؤثّر على الجهاز المناعي للأم، مما يزيد من القابلية للإصابة بالعدوى ومضاعفات الحمل. ومن النتائج المقلقة أن الأطفال الذين تعرّضت أمهاتهم لتوتّر شديد أثناء الحمل يكونون أكثر عرضة لمشكلات سلوكية وعاطفية في مرحلة الطفولة المبكّرة، بما في ذلك صعوبات التركيز والانتباه وزيادة مستويات القلق. لكن الخبر الجيد هو أن الأبحاث أثبتت أيضاً فعالية العديد من التقنيات في تقليل مستويات التوتّر وحماية الأم والجنين. ومن هذه التقنيات ممارسة التأمّل الواعي واليوغا والتنفّس العميق، حيث أظهرت دراسة أن ممارسة التأمّل لمدة عشر دقائق يومياً يقلّل مستويات الكورتيزول بنسبة عشرين بالمائة. كما أثبت الدعم الاجتماعي والعلاج السلوكي المعرفي فعاليتهما في تحسين الصحة النفسية للحوامل. وأوصت الجمعيات الطبية بإدراج تقييم مستوى التوتّر كجزء روتيني من زيارات متابعة الحمل وتوفير برامج دعم نفسي متخصّصة للحوامل اللواتي يعانين من مستويات عالية من الإجهاد النفسي.',
    ),
    _DiscoverArt(
      title: 'علم التخلّق وبرمجة صحة الجنين المستقبلية',
      emoji: '🧬',
      color1: const Color(0xFF66BB6A),
      image: 'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?w=800&q=80',
      content: 'يُعدّ علم التخلّق أو الإبيجينيتيكس من أكثر المجالات العلمية إثارةً في فهم كيفية تأثير بيئة الرحم على صحة الطفل مدى الحياة. يدرس هذا العلم التغيّرات في التعبير الجيني التي تحدث دون تغيير في تسلسل الحمض النووي نفسه، وهي تغيّرات يمكن أن تنتقل عبر الأجيال. كشفت الأبحاث الحديثة أن ما تتعرّض له الأم خلال الحمل من غذاء وتوتّر وملوّثات بيئية يمكن أن يُحدث تعديلات تخلّقية في جينوم الجنين تؤثّر على قابليته للإصابة بأمراض مزمنة في المستقبل مثل السكّري وأمراض القلب والسمنة. ومن أبرز الاكتشافات في هذا المجال ما يُعرف بفرضية بيئة الرحم التي تقول إن ظروف التغذية أثناء الحمل تُبرمج أنظمة الأيض والغدد الصمّاء لدى الجنين استعداداً للبيئة التي سيولد فيها. فإذا كانت التغذية أثناء الحمل سيّئة، يتكيّف الجنين لتوقّع بيئة شحيحة الموارد بعد الولادة، لكن إذا وُلد في بيئة غنيّة بالغذاء فإن هذا التناقض يزيد خطر الإصابة بالسمنة والأمراض الأيضية. وأظهرت دراسات أن تناول الأم لحمض الفوليك والكولين وفيتامينات ب يؤثّر بشكل مباشر على عمليات المثيلة التخلّقية التي تنظّم التعبير الجيني لدى الجنين. كما أثبتت أبحاث حديثة أن التعرّض للملوّثات البيئية مثل المبيدات الحشرية والبلاستيك يُحدث تعديلات تخلّقية سلبية يمكن أن تنتقل إلى الجيل التالي. وفي المقابل أظهرت الدراسات أن التغذية المتوازنة والنشاط البدني المنتظم والحدّ من التوتّر يمكن أن تُنتج تعديلات تخلّقية إيجابية تحمي الطفل من الأمراض المزمنة. هذه النتائج تؤكّد أن العناية بصحة الأم أثناء الحمل لا تحمي صحتها وصحة جنينها فحسب بل تمتد آثارها الإيجابية إلى الأجيال القادمة.',
    ),
    _DiscoverArt(
      title: 'تغذية الأم والنمو العقلي للجنين',
      emoji: '🥗',
      color1: const Color(0xFFAB47BC),
      image: 'assets/images/pregnancy_news/700839151633f2fc58507ec9c6454e62.jpg',
      content: 'تتزايد الأدلّة العلمية التي تؤكّد الدور المحوري لتغذية الأم خلال الحمل في تشكيل البنية الدماغية للجنين وقدراته المعرفية المستقبلية. أجرت جامعات عالمية مرموقة سلسلة من الدراسات الطولية التي تابعت آلاف الأطفال منذ مرحلة الحمل وحتى سنّ المدرسة، وخلصت إلى نتائج بالغة الأهمية. أظهرت هذه الدراسات أن النظام الغذائي الغني بأحماض أوميغا ثلاثة الدهنية، وخاصةً حمض الدوكوساهيكسانويك الموجود بكثرة في الأسماك الدهنية والجوز وبذور الكتّان، يرتبط بتحسّن ملحوظ في الذاكرة والانتباه والقدرة على التعلّم لدى الأطفال. كما أثبتت الأبحاث أن نقص اليود خلال الحمل، حتى لو كان طفيفاً، يمكن أن يؤدّي إلى انخفاض في معدّل الذكاء لدى الطفل يصل إلى عشر نقاط. وسلّطت دراسات أخرى الضوء على أهمية الحديد في نمو الدماغ، حيث يلعب دوراً أساسياً في تكوين غلاف الميالين الذي يغطّي الألياف العصبية ويسرّع نقل الإشارات بين خلايا الدماغ. ومن النتائج المثيرة أن تناول الأم للفواكه والخضروات الملوّنة الغنية بمضادّات الأكسدة يرتبط بتحسّن وظائف الذاكرة لدى أطفالها في سنّ الرابعة. كما أظهرت الأبحاث أن البروتين الكافي ضروري لبناء الناقلات العصبية في دماغ الجنين، وأن نقصه يمكن أن يؤثّر على السلوك والمزاج في مرحلة لاحقة من الحياة. وأكّدت الدراسات على أهمية تجنّب الأطعمة فائقة التصنيع والسكّريات المضافة والدهون المتحوّلة، حيث ترتبط بزيادة الالتهابات في الجسم مما قد يؤثّر سلباً على نمو الدماغ. وخلصت مراجعة شاملة إلى أن اتّباع نظام غذائي متوسّطي خلال الحمل يوفّر أفضل حماية لصحة دماغ الجنين بفضل تنوّعه وغناه بالعناصر الغذائية الأساسية.',
    ),
    _DiscoverArt(
      title: 'جودة النوم أثناء الحمل وتأثيرها على الجنين',
      emoji: '😴',
      color1: const Color(0xFFFF7043),
      image: 'assets/images/pregnancy_news/8e3d386ae8d483b008b4ed05af8c4d89.jpg',
      content: 'حظيت جودة النوم أثناء الحمل باهتمام بحثي متزايد في السنوات الأخيرة، حيث كشفت الدراسات عن علاقة وثيقة بين اضطرابات النوم لدى الحامل ومضاعفات الحمل المختلفة. تعاني نسبة كبيرة من الحوامل تصل إلى ثمانين بالمائة من مشكلات في النوم، تتراوح بين الأرق وانقطاع النفس أثناء النوم ومتلازمة تململ الساقين والاستيقاظ المتكرّر. أظهرت دراسة نُشرت في مجلّة النوم أن الحوامل اللواتي ينمن أقل من ستّ ساعات يومياً يكنّ أكثر عرضة بنسبة أربعة أضعاف ونصف للولادة القيصرية مقارنةً باللواتي ينمن سبع ساعات أو أكثر. كما ربطت أبحاث أخرى بين انقطاع النفس أثناء النوم عند الحوامل وزيادة خطر الإصابة بتسمّم الحمل وسكّري الحمل وتأخّر نمو الجنين. ومن الاكتشافات الحديثة أن وضعية النوم تلعب دوراً في سلامة الحمل، حيث أظهرت دراسات متعدّدة أن النوم على الظهر في الثلث الثالث من الحمل يرتبط بزيادة خطر الإملاص، ويُنصح بالنوم على الجانب الأيسر لتحسين تدفّق الدم إلى الرحم والمشيمة. وتناولت الأبحاث أيضاً تأثير هرمون الميلاتونين على الحمل، حيث تبيّن أنه يلعب دوراً في تنظيم إيقاع الساعة البيولوجية للجنين ويحمي المشيمة من الإجهاد التأكسدي. وأوصت الدراسات باتّباع عادات نوم صحية تشمل الالتزام بمواعيد ثابتة للنوم والاستيقاظ وتجنّب الشاشات قبل النوم بساعة على الأقل وتهيئة غرفة نوم مريحة ومظلمة وباردة نسبياً. كما أثبتت تقنيات الاسترخاء مثل التنفّس العميق والتأمّل الموجّه فعاليتها في تحسين جودة النوم لدى الحوامل دون الحاجة إلى أدوية.',
    ),
    _DiscoverArt(
      title: 'العلاج بالموسيقى قبل الولادة: فوائد مثبتة علمياً',
      emoji: '🎵',
      color1: const Color(0xFF8D6E63),
      image: 'https://images.unsplash.com/photo-1503431128871-cd250803fa41?w=800&q=80',
      content: 'أثبتت الأبحاث العلمية الحديثة أن تعريض الجنين للموسيقى خلال فترة الحمل يحمل فوائد متعدّدة تتجاوز مجرّد التحفيز السمعي. يبدأ الجنين في سماع الأصوات الخارجية بدءاً من الأسبوع السادس عشر تقريباً، وبحلول الأسبوع السادس والعشرين يكون قادراً على التمييز بين الأصوات المختلفة والاستجابة لها. أجرت جامعة هلسنكي دراسة رائدة تابعت أطفالاً تم تعريضهم لموسيقى محدّدة خلال الثلث الأخير من الحمل، ووجدت أن هؤلاء الأطفال أظهروا استجابات دماغية أقوى لتلك الموسيقى بعد الولادة مقارنةً بالأطفال الذين لم يتعرّضوا لها. وهذا يُثبت أن الذاكرة السمعية تبدأ في التشكّل قبل الولادة. كما أظهرت دراسات أخرى أن الاستماع إلى الموسيقى الهادئة يقلّل من مستويات التوتّر لدى الأم والجنين معاً، حيث ينخفض معدّل ضربات قلب الجنين ويصبح أكثر انتظاماً. ومن الفوائد المثبتة أيضاً أن الغناء للجنين يُعزّز الرابطة العاطفية بين الأم وطفلها ويقلّل من أعراض اكتئاب ما قبل الولادة. وفي مجال الموسيقى العلاجية، طُوِّرت برامج متخصّصة تستخدم ترددات صوتية محدّدة لتحفيز نمو الدماغ الجنيني وتعزيز تطوّر المسارات العصبية المسؤولة عن اللغة والتواصل. ومن النتائج المثيرة أن الأطفال الخدّج الذين تعرّضوا للموسيقى العلاجية في وحدة العناية المركّزة أظهروا تحسّناً أسرع في الوزن والتغذية مقارنةً بنظرائهم. وينصح الخبراء باختيار موسيقى هادئة ومنتظمة الإيقاع مثل الموسيقى الكلاسيكية أو التلاوات القرآنية بصوت هادئ، وتجنّب الموسيقى الصاخبة التي قد تسبّب إزعاجاً للجنين. كما يُوصى بأن تكون جلسات الاستماع قصيرة ومنتظمة لا تتجاوز ثلاثين دقيقة في المرّة الواحدة.',
    ),
  ]),

  _DiscoverCat(name: 'تقنيات حديثة في متابعة الحمل', emoji: '📱', articles: [
    _DiscoverArt(
      title: 'التصوير ثلاثي ورباعي الأبعاد: نافذة على عالم الجنين',
      emoji: '📸',
      color1: const Color(0xFF00897B),
      image: 'assets/images/pregnancy_news/976abc1fc3913e1c150c4e7291a635c4.jpg',
      content: 'أحدث التصوير بالموجات فوق الصوتية ثلاثي ورباعي الأبعاد ثورة حقيقية في عالم متابعة الحمل، حيث أصبح بإمكان الأبوين رؤية ملامح طفلهما بوضوح مذهل قبل ولادته بأشهر. يختلف التصوير ثلاثي الأبعاد عن التصوير التقليدي ثنائي الأبعاد في قدرته على إنتاج صور مجسّمة تُظهر سطح جسم الجنين بتفاصيل دقيقة، بينما يضيف التصوير رباعي الأبعاد بُعد الحركة فيُتيح مشاهدة الجنين في الوقت الحقيقي وهو يتحرّك ويبتسم ويتثاءب. لكن الأهمية الطبية لهذه التقنية تتجاوز الجانب العاطفي بكثير. في مجال تشخيص التشوّهات الخلقية، أثبت التصوير ثلاثي الأبعاد تفوّقه في الكشف عن عيوب الوجه مثل الشفة الأرنبية وشقّ سقف الحلق، وعيوب الجهاز العصبي مثل عيوب الأنبوب العصبي، وتشوّهات الأطراف والأصابع. كما تُستخدم تقنية رباعية الأبعاد في دراسة سلوك الجنين داخل الرحم، حيث يمكن مراقبة حركات التنفّس والبلع وتعبيرات الوجه التي تعكس مستوى نضج الجهاز العصبي. وقد طُوِّرت مؤخراً تقنية التصوير عالي الدقّة التي تجمع بين الأبعاد الثلاثة والدوبلر الملوّن لتقييم تدفّق الدم في الأعضاء الحيوية للجنين مثل القلب والدماغ والكلى. ومن التطبيقات الحديثة استخدام التصوير ثلاثي الأبعاد في التخطيط للجراحات الجنينية، حيث يساعد الجرّاح في تحديد موقع المشكلة بدقّة قبل إجراء التدخّل. ورغم هذه الفوائد العديدة، يحذّر الأطباء من الإفراط في استخدام هذه التقنية لأغراض غير طبية، إذ لا يُنصح بإجراء جلسات تصوير متكرّرة بهدف الحصول على صور تذكارية فقط. ويُؤكّد الخبراء أن التصوير يجب أن يتم تحت إشراف متخصّصين قادرين على تفسير الصور بشكل صحيح وتقديم التشخيص الدقيق.',
    ),
    _DiscoverArt(
      title: 'أجهزة مراقبة الجنين القابلة للارتداء',
      emoji: '⌚',
      color1: const Color(0xFF7E57C2),
      image: 'assets/images/pregnancy_news/a41d2b78250bfab64804356c22c4b75f.jpg',
      content: 'دخلت أجهزة المراقبة القابلة للارتداء مجال رعاية الحمل بقوّة في السنوات الأخيرة، مقدّمةً للأمهات الحوامل أدوات متطوّرة لمتابعة صحتهنّ وصحة أجنّتهنّ في المنزل بشكل مستمر. تتنوّع هذه الأجهزة بين أحزمة ذكية تُرتدى حول البطن لرصد تقلّصات الرحم ونبض الجنين وحركته، وأساور معصم تراقب المؤشّرات الحيوية للأم مثل معدّل ضربات القلب وجودة النوم ومستوى النشاط البدني والتوتّر. من أبرز الابتكارات في هذا المجال جهاز يستخدم مستشعرات كهربائية مرنة تُلصق على بطن الأم وتُرسل بيانات مستمرّة عن نبض الجنين وتقلّصات الرحم إلى تطبيق على الهاتف الذكي، والذي بدوره يحلّل البيانات باستخدام خوارزميات الذكاء الاصطناعي ويُنبّه الأم إذا اكتشف أي شيء غير طبيعي. وتتميّز الأجهزة الحديثة بقدرتها على التمييز بين نبض قلب الأم ونبض قلب الجنين بدقّة عالية، مما يقلّل من النتائج الخاطئة. كما طُوِّرت أجهزة خاصة للحمل عالي الخطورة تُتيح المراقبة المستمرّة على مدار الساعة وإرسال البيانات مباشرةً إلى الفريق الطبي في المستشفى. ومن الميزات المبتكرة في هذه الأجهزة إمكانية تسجيل أصوات الجنين ومشاركتها مع أفراد العائلة، وتتبّع أنماط نوم الجنين واستيقاظه، ورسم خرائط لحركاته داخل الرحم. ومع ذلك يحذّر الخبراء من أن هذه الأجهزة لا تُغني عن المتابعة الطبية المنتظمة ولا يجب استخدامها كبديل عن زيارات الطبيب. كما تثار مخاوف بشأن خصوصية البيانات الصحية التي تجمعها هذه الأجهزة وكيفية حمايتها من الاختراق. ويُنصح الحوامل باختيار الأجهزة المعتمدة من الهيئات الصحية الرسمية واستخدامها تحت إشراف طبي.',
    ),
    _DiscoverArt(
      title: 'تطبيقات الحمل الذكية: دليلكِ الرقمي',
      emoji: '📲',
      color1: const Color(0xFF3949AB),
      image: 'https://images.unsplash.com/photo-1526256262350-7da7584cf5eb?w=800&q=80',
      content: 'أصبحت تطبيقات الحمل الذكية رفيقاً لا غنى عنه لملايين الحوامل حول العالم، حيث توفّر معلومات شاملة وأدوات تفاعلية تساعد في متابعة كل مرحلة من مراحل الحمل. تتنافس المئات من التطبيقات في تقديم أفضل تجربة للمستخدمات، لكنّ الأبحاث الحديثة سلّطت الضوء على الفوائد والمخاطر المحتملة لهذه التطبيقات. من أبرز ميزات تطبيقات الحمل الحديثة تتبّع نمو الجنين أسبوعاً بأسبوع مع صور ومعلومات تفصيلية عن حجمه ومراحل تطوّره، وتسجيل الأعراض والمؤشّرات الصحية مثل ضغط الدم والوزن ومعدّل السكّر، وإرسال تذكيرات بمواعيد الفحوصات والتطعيمات وتناول الفيتامينات. كما تتضمّن بعض التطبيقات المتقدّمة نظام عدّ الركلات الذكي الذي يستخدم الذكاء الاصطناعي لتحليل أنماط حركة الجنين والتنبيه عند حدوث تغيّرات غير طبيعية. ومن الميزات المبتكرة أيضاً توفير محتوى تعليمي مخصّص بناءً على مرحلة الحمل، ومنتديات مجتمعية تتيح للحوامل تبادل الخبرات والدعم فيما بينهنّ. لكن دراسة حديثة حذّرت من أن بعض التطبيقات تقدّم معلومات طبية غير دقيقة أو قديمة قد تُضلّل المستخدمات. كما أثارت مخاوف بشأن جمع البيانات الشخصية الحسّاسة ومشاركتها مع أطراف ثالثة لأغراض تسويقية. ولذلك ينصح الخبراء باختيار التطبيقات التي طوّرها متخصّصون في الرعاية الصحية والتي تلتزم بمعايير حماية البيانات. ومن المهم أيضاً التأكيد على أن هذه التطبيقات أدوات مساعدة وليست بديلاً عن الاستشارة الطبية المتخصّصة، وأن أي قلق بشأن أعراض أو مضاعفات يستوجب التواصل مع الطبيب مباشرةً بدلاً من الاعتماد على التطبيق.',
    ),
    _DiscoverArt(
      title: 'الذكاء الاصطناعي في التشخيص قبل الولادة',
      emoji: '🤖',
      color1: const Color(0xFFF4511E),
      image: 'assets/images/pregnancy_news/c5811daeb59671c0586922678e3d5ee4.jpg',
      content: 'يُحدث الذكاء الاصطناعي تحوّلاً جذرياً في مجال التشخيص قبل الولادة، حيث أصبحت الخوارزميات المتقدّمة قادرة على تحليل الصور الطبية والبيانات الجينية بدقّة تتجاوز في كثير من الأحيان قدرات الأطباء البشريين. في مجال تحليل صور الموجات فوق الصوتية، طوّر باحثون أنظمة ذكاء اصطناعي يمكنها فحص صور الجنين والكشف عن التشوّهات الخلقية بنسبة دقّة تصل إلى خمسة وتسعين بالمائة، مقارنةً بنسبة خمسة وثمانين بالمائة للأطباء المتخصّصين. وتتميّز هذه الأنظمة بقدرتها على تحليل آلاف الصور في دقائق معدودة وتحديد أنماط دقيقة قد يصعب على العين البشرية ملاحظتها. ومن التطبيقات الرائدة استخدام التعلّم العميق في تحليل تسجيلات تخطيط قلب الجنين للتنبّؤ بالضائقة الجنينية قبل أن تتطوّر إلى حالة طارئة، مما يمنح الفريق الطبي وقتاً كافياً للتدخّل. كما طُوِّرت خوارزميات تستخدم بيانات الأم مثل العمر والتاريخ الطبي ونتائج الفحوصات لحساب احتمالية الإصابة بمضاعفات مثل تسمّم الحمل والولادة المبكّرة بدقّة عالية. وفي مجال الفحص الجيني، يُستخدم الذكاء الاصطناعي في تحليل الحمض النووي الجنيني الحرّ في دم الأم للكشف عن الاضطرابات الصبغية مثل متلازمة داون بدقّة تقترب من مائة بالمائة ودون الحاجة إلى إجراءات جراحية مثل بزل السائل الأمنيوسي. ورغم هذه الإنجازات المبهرة، يؤكّد الخبراء أن الذكاء الاصطناعي يجب أن يُستخدم كأداة مساعدة للطبيب وليس بديلاً عنه، وأن القرارات الطبية النهائية يجب أن تبقى في يد الفريق الطبي المتخصّص. كما تُطرح تساؤلات أخلاقية مهمة حول استخدام الذكاء الاصطناعي في التشخيص الجيني والتبعات المترتّبة على ذلك.',
    ),
    _DiscoverArt(
      title: 'الطبّ عن بُعد في متابعة الحمل',
      emoji: '💻',
      color1: const Color(0xFF00796B),
      image: 'assets/images/pregnancy_news/d94b258e94d4752eb1504fb6e8d00dec.jpg',
      content: 'شهد الطبّ عن بُعد في مجال متابعة الحمل نمواً هائلاً وتسارعاً غير مسبوق، خاصةً بعد أن أثبتت التجربة أنه يمكن أن يكون فعّالاً وآمناً في العديد من جوانب الرعاية السابقة للولادة. أصبحت الاستشارات الطبية عبر الفيديو جزءاً أساسياً من نموذج المتابعة المختلط الذي يجمع بين الزيارات الحضورية والزيارات الافتراضية. وقد أظهرت دراسات متعدّدة أن هذا النموذج المختلط يحقّق نتائج مماثلة للمتابعة التقليدية من حيث سلامة الأم والجنين، مع ميزة إضافية تتمثّل في زيادة رضا المريضات وتقليل العبء على المرافق الصحية. ومن التطبيقات الناجحة للطبّ عن بُعد في الحمل مراقبة ضغط الدم في المنزل للحوامل المعرّضات لخطر تسمّم الحمل، حيث تُزوَّد الحامل بجهاز قياس ضغط متّصل بالإنترنت يُرسل القراءات تلقائياً إلى فريقها الطبي. كذلك يُستخدم الطبّ عن بُعد في متابعة سكّري الحمل، حيث تُرسل الحامل قراءات سكّر الدم يومياً ويتلقّى فريق العناية السكّرية التنبيهات في حال وجود قراءات غير طبيعية ويتم تعديل العلاج عن بُعد. كما أتاحت تقنيات الطبّ عن بُعد الوصول إلى استشارات المتخصّصين في طبّ الأجنّة للحوامل في المناطق النائية التي يندر فيها وجود هؤلاء المتخصّصين. وتتضمّن الابتكارات الحديثة أجهزة منزلية لقياس معدّل نبض الجنين وتقلّصات الرحم يمكن ربطها بمنصّات الطبّ عن بُعد. ومع ذلك يجب الإشارة إلى أن بعض جوانب المتابعة لا يمكن استبدالها بالطبّ عن بُعد، مثل الفحص السريري والتصوير بالموجات فوق الصوتية وسحب عيّنات الدم. ولذلك يُنصح بنموذج مختلط يوازن بين الراحة والشمولية.',
    ),
    _DiscoverArt(
      title: 'الفحص الجيني المتقدّم: ما الذي أصبح ممكناً؟',
      emoji: '🔎',
      color1: const Color(0xFFC62828),
      image: 'https://images.unsplash.com/photo-1579154204601-01588f351e67?w=800&q=80',
      content: 'شهد مجال الفحص الجيني قبل الولادة تطوّرات هائلة غيّرت بشكل جذري قدرتنا على الكشف المبكّر عن الاضطرابات الوراثية والصبغية لدى الأجنّة. أبرز هذه التطوّرات هو فحص الحمض النووي الجنيني الحرّ في دم الأم، وهو فحص غير جراحي يُجرى بسحب عيّنة بسيطة من دم الأم ابتداءً من الأسبوع العاشر من الحمل. يعمل هذا الفحص على تحليل شظايا الحمض النووي الجنيني التي تعبر إلى مجرى دم الأم عبر المشيمة، ويمكنه الكشف عن الاضطرابات الصبغية الشائعة مثل متلازمة داون ومتلازمة إدواردز ومتلازمة باتو بنسبة دقّة تتجاوز تسعة وتسعين بالمائة. وتتطوّر هذه التقنية باستمرار، حيث أصبح بالإمكان الآن الكشف عن اضطرابات صبغية أقل شيوعاً وحتى بعض الطفرات الجينية المفردة المسبّبة لأمراض وراثية خطيرة. كما ظهرت تقنيات جديدة تُتيح تسلسل الجينوم الكامل للجنين من عيّنة دم الأم، مما يفتح آفاقاً واسعة للكشف عن آلاف الاضطرابات الوراثية في فحص واحد. ومن التطوّرات اللافتة أيضاً تحسين تقنية أخذ عيّنات الزغابات المشيمية وبزل السائل الأمنيوسي بتوجيه الموجات فوق الصوتية عالية الدقّة، مما قلّل من مخاطر هذه الإجراءات بشكل كبير. وطُوِّرت كذلك تقنيات تحليل الجينات باستخدام المصفوفات الدقيقة التي يمكنها الكشف عن حذف أو تكرار أجزاء صغيرة من الكروموسومات لا يمكن رؤيتها بالفحص التقليدي. لكنّ هذه التطوّرات تطرح تحدّيات أخلاقية معقّدة تتعلّق بحقّ المعرفة وحقّ عدم المعرفة والقرارات المترتّبة على نتائج الفحوصات. ولذلك يُنصح بأن يسبق أي فحص جيني استشارة مع متخصّص في علم الوراثة لمناقشة الخيارات المتاحة وتبعاتها.',
    ),
  ]),

  _DiscoverCat(name: 'صحة الأم والجنين', emoji: '🩺', articles: [
    _DiscoverArt(
      title: 'ارتفاع ضغط الدم أثناء الحمل: الوقاية والعلاج',
      emoji: '❤️‍🩹',
      color1: const Color(0xFF0288D1),
      image: 'assets/images/pregnancy_news/dae4b8a07b1a44442414620ff7a30d35.jpg',
      content: 'يُعدّ ارتفاع ضغط الدم أثناء الحمل من أخطر المضاعفات التي تهدّد صحة الأم والجنين، ويصيب ما بين خمسة إلى عشرة بالمائة من الحوامل حول العالم. تتراوح حالات ارتفاع ضغط الدم المرتبطة بالحمل بين ارتفاع الضغط الحملي البسيط الذي يظهر بعد الأسبوع العشرين دون وجود بروتين في البول، وتسمّم الحمل الذي يتميّز بارتفاع الضغط مع وجود بروتين في البول أو خلل في وظائف الأعضاء، والحالة الأشدّ خطورة وهي الارتعاج أو تشنّجات الحمل التي قد تهدّد حياة الأم والجنين. أظهرت الأبحاث الحديثة أن هناك عوامل خطر متعدّدة لتسمّم الحمل تشمل الحمل الأول والسمنة والعمر فوق خمسة وثلاثين سنة والحمل بتوأم والتاريخ العائلي والأمراض المزمنة مثل السكّري وأمراض الكلى. ومن أهمّ التحديثات في مجال الوقاية التوصية بتناول الأسبرين بجرعة منخفضة تتراوح بين مائة وخمسين إلى مائة وستين ملليغراماً يومياً ابتداءً من الأسبوع الثاني عشر وحتى الأسبوع السادس والثلاثين للنساء المعرّضات للخطر. وقد أثبتت هذه الاستراتيجية فعاليتها في تقليل حدوث تسمّم الحمل المبكّر بنسبة تصل إلى ستين بالمائة. كما أظهرت دراسات أن تناول مكمّلات الكالسيوم بجرعة غرام واحد يومياً يقلّل من خطر تسمّم الحمل لدى النساء اللواتي لا يحصلن على كمية كافية من الكالسيوم في غذائهنّ. وفيما يخصّ العلاج، طُوِّرت بروتوكولات محدّثة تعتمد على المراقبة المكثّفة واستخدام أدوية خافضة للضغط آمنة أثناء الحمل مثل لابيتالول ونيفيديبين وميثيل دوبا. وتبقى الولادة هي العلاج النهائي لتسمّم الحمل، ويُحدَّد توقيتها بناءً على شدّة الحالة وعمر الحمل ومصلحة الأم والجنين.',
    ),
    _DiscoverArt(
      title: 'فقر الدم والحمل: كيف تحمين نفسكِ وجنينكِ',
      emoji: '🩸',
      color1: const Color(0xFF6D4C41),
      image: 'assets/images/pregnancy_news/download (1).jpg',
      content: 'يُعدّ فقر الدم من أكثر المشكلات الصحية شيوعاً أثناء الحمل، حيث تصيب هذه الحالة ما يقارب أربعين بالمائة من الحوامل حول العالم وفقاً لتقديرات منظمة الصحة العالمية. يحدث فقر الدم عندما ينخفض مستوى الهيموغلوبين في الدم عن أحد عشر غراماً لكل ديسيلتر خلال الثلث الأول والثالث أو عن عشرة ونصف غرام خلال الثلث الثاني. يُعدّ نقص الحديد السبب الأكثر شيوعاً لفقر الدم أثناء الحمل، حيث يزداد احتياج الجسم للحديد بشكل كبير لتلبية متطلّبات زيادة حجم الدم ونمو الجنين والمشيمة. ولكن هناك أسباب أخرى يجب عدم إغفالها مثل نقص حمض الفوليك ونقص فيتامين ب اثني عشر وفقر الدم المنجلي والثلاسيميا. تشمل أعراض فقر الدم أثناء الحمل التعب الشديد وضيق التنفّس وشحوب البشرة وتسارع ضربات القلب والدوخة وصعوبة التركيز والصداع المتكرّر. وقد أظهرت الدراسات أن فقر الدم الشديد غير المعالج يزيد من خطر الولادة المبكّرة وانخفاض وزن المولود ونزيف ما بعد الولادة واكتئاب ما بعد الولادة. كما يؤثّر على مخزون الحديد لدى المولود مما قد يسبّب فقر دم في الأشهر الأولى من حياته. وتتضمّن استراتيجيات الوقاية والعلاج إجراء فحص مستوى الهيموغلوبين والفيريتين في بداية الحمل وتكراره في كل ثلث، وتناول نظام غذائي غني بالحديد يشمل اللحوم الحمراء والدواجن والبقوليات والخضروات الورقية الداكنة، مع الحرص على تناول الأطعمة الغنية بفيتامين سي لتعزيز امتصاص الحديد. وفي حالات النقص، يُوصف الحديد عن طريق الفم بجرعة تتراوح بين ستين ومائة وعشرين ملليغراماً يومياً، وفي الحالات الشديدة قد يُعطى الحديد عن طريق الوريد لتعويض النقص بسرعة.',
    ),
    _DiscoverArt(
      title: 'صحة الأسنان واللثة خلال الحمل',
      emoji: '🦷',
      color1: const Color(0xFFEF6C00),
      image: 'assets/images/pregnancy_news/download.jpg',
      content: 'تُعدّ صحة الفم والأسنان جانباً مهمّاً من جوانب الرعاية الصحية أثناء الحمل غالباً ما يُهمل رغم تأثيره المباشر على صحة الأم والجنين. تحدث خلال الحمل تغيّرات هرمونية كبيرة تؤثّر بشكل مباشر على صحة اللثة والأنسجة المحيطة بالأسنان، حيث يؤدّي ارتفاع مستويات البروجستيرون والإستروجين إلى زيادة تدفّق الدم إلى اللثة مما يجعلها أكثر حساسية وعرضة للالتهاب والنزيف. يُصاب ما بين ستين إلى خمسة وسبعين بالمائة من الحوامل بالتهاب اللثة الحملي الذي يتميّز باحمرار وتورّم ونزيف اللثة عند تنظيف الأسنان. ومن المضاعفات الأكثر خطورة ما يُعرف بورم الحمل الحبيبي وهو نموّ حميد في اللثة يظهر عادةً في الثلث الثاني ويختفي بعد الولادة. وقد أثبتت الأبحاث وجود علاقة بين أمراض اللثة الشديدة ومضاعفات الحمل مثل الولادة المبكّرة وانخفاض وزن المولود وتسمّم الحمل. ويُعتقد أن البكتيريا المسبّبة لالتهاب اللثة يمكن أن تدخل مجرى الدم وتصل إلى المشيمة مسبّبةً استجابة التهابية تحفّز تقلّصات الرحم. ولذلك تُوصي الجمعيات الطبية بزيارة طبيب الأسنان في بداية الحمل لإجراء فحص شامل ومعالجة أي مشكلات موجودة. ويُعدّ الثلث الثاني من الحمل الوقت الأمثل لإجراء علاجات الأسنان غير الطارئة مثل الحشوات وتنظيف اللثة. أما التصوير بالأشعة السينية فيمكن إجراؤه أثناء الحمل مع استخدام واقي الرصاص لحماية البطن. ومن النصائح المهمة تنظيف الأسنان مرتين يومياً واستخدام خيط الأسنان يومياً وشطف الفم بماء وملح أو غسول فم خالٍ من الكحول، والحدّ من تناول السكّريات والأطعمة الحمضية التي تُسهم في تسوّس الأسنان.',
    ),
    _DiscoverArt(
      title: 'اضطرابات الغدة الدرقية والحمل',
      emoji: '🦋',
      color1: const Color(0xFF1565C0),
      image: 'assets/images/pregnancy_news/download.png',
      content: 'تؤدّي الغدة الدرقية دوراً حيوياً في تنظيم العمليات الأيضية في الجسم، ويزداد أهمية هذا الدور خلال فترة الحمل حيث تحتاج الأم والجنين إلى كمّيات كافية من هرمونات الغدة الدرقية لضمان النمو الطبيعي والتطوّر السليم. تصيب اضطرابات الغدة الدرقية ما بين اثنين إلى ثلاثة بالمائة من الحوامل، وقد تكون هذه الاضطرابات موجودة قبل الحمل أو تظهر لأول مرّة خلاله. ينقسم الاضطراب إلى نوعين رئيسيين: قصور الغدة الدرقية حيث تنتج كمّية غير كافية من الهرمونات، وفرط نشاط الغدة الدرقية حيث تنتج كمّية مفرطة. يُعدّ قصور الغدة الدرقية الأكثر شيوعاً أثناء الحمل ويمكن أن يؤدّي إذا لم يُعالج إلى مضاعفات خطيرة تشمل الإجهاض المتكرّر وتسمّم الحمل وانفصال المشيمة المبكّر وفقر الدم والولادة المبكّرة وانخفاض وزن المولود. والأخطر من ذلك أن نقص هرمونات الغدة الدرقية يؤثّر بشكل مباشر على نمو دماغ الجنين وتطوّره العقلي، خاصةً في الأشهر الثلاثة الأولى عندما يعتمد الجنين كلياً على هرمونات أمّه قبل أن تبدأ غدته الدرقية بالعمل. أما فرط نشاط الغدة الدرقية فيمكن أن يسبّب تسارع قلب الأم والجنين وتأخّر النمو داخل الرحم والولادة المبكّرة. ولذلك تُوصي الإرشادات الحديثة بفحص وظائف الغدة الدرقية في بداية الحمل لجميع الحوامل وليس فقط اللواتي لديهنّ عوامل خطر. يتضمّن الفحص قياس هرمون المنبّه للدرقية والثيروكسين الحرّ، ويجب مراعاة أن المعدّلات الطبيعية تختلف أثناء الحمل عن المعدّلات الطبيعية للبالغين. ويُعالج قصور الغدة الدرقية بالليفوثيروكسين مع تعديل الجرعة بانتظام طوال فترة الحمل، بينما يُعالج فرط النشاط بأدوية مضادّة للدرقية تحت إشراف طبي دقيق.',
    ),
    _DiscoverArt(
      title: 'التطعيمات أثناء الحمل: حماية مزدوجة',
      emoji: '💉',
      color1: const Color(0xFFAD1457),
      image: 'https://images.unsplash.com/photo-1578307992618-23aborob7b8d?w=800&q=80',
      content: 'تُمثّل التطعيمات أثناء الحمل استراتيجية فعّالة لحماية الأم والمولود معاً من الأمراض المعدية الخطيرة، حيث تنتقل الأجسام المضادّة التي يُنتجها جسم الأم استجابةً للقاح عبر المشيمة إلى الجنين لتوفّر له حماية في الأشهر الأولى من حياته قبل أن يتمكّن من تلقّي التطعيمات بنفسه. ومن أهمّ التطعيمات الموصى بها أثناء الحمل لقاح الإنفلونزا الموسمية الذي يُنصح بتلقّيه في أي مرحلة من الحمل، حيث إن الحوامل أكثر عرضة لمضاعفات الإنفلونزا الشديدة بسبب التغيّرات في الجهاز المناعي والجهاز التنفّسي. وأظهرت الدراسات أن تطعيم الأم يقلّل من خطر دخول المولود إلى المستشفى بسبب الإنفلونزا في الأشهر الستة الأولى بنسبة تصل إلى ثلاثة وستين بالمائة. أما اللقاح الثاني المهمّ فهو لقاح السعال الديكي المركّب الذي يُنصح بتلقّيه بين الأسبوع السابع والعشرين والسادس والثلاثين من الحمل، ويُفضّل أن يكون في أقرب وقت ممكن بعد الأسبوع السابع والعشرين لإعطاء الجسم وقتاً كافياً لإنتاج الأجسام المضادّة ونقلها إلى الجنين. وتكمن أهمية هذا اللقاح في أن السعال الديكي يُشكّل خطراً كبيراً على حديثي الولادة الذين لا يمكنهم تلقّي اللقاح قبل عمر شهرين. وفيما يخصّ اللقاحات المضادّة لفيروس كورونا المستجدّ، أكّدت الجمعيات الطبية على سلامتها وأهميتها أثناء الحمل. في المقابل هناك لقاحات يُمنع تلقّيها أثناء الحمل لأنها تحتوي على فيروسات حيّة مُضعّفة مثل لقاح الحصبة والنكاف والحصبة الألمانية ولقاح الجدري. ويُنصح بتلقّي هذه اللقاحات قبل الحمل بأربعة أسابيع على الأقل. ومن المهم أن تناقش كل حامل مع طبيبها خطّة التطعيمات المناسبة لحالتها الصحية.',
    ),
    _DiscoverArt(
      title: 'الصحة النفسية للحامل: فحص وعلاج مبكّر',
      emoji: '🧘‍♀️',
      color1: const Color(0xFF2E7D32),
      image: 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22?w=800&q=80',
      content: 'حظيت الصحة النفسية للحامل باهتمام متزايد في السنوات الأخيرة بعد أن أثبتت الأبحاث أن الاضطرابات النفسية خلال الحمل لا تؤثّر على الأم فحسب بل تمتد تأثيراتها إلى الجنين وإلى العلاقة بين الأم وطفلها بعد الولادة. تشير الإحصاءات إلى أن ما بين عشرة إلى عشرين بالمائة من الحوامل يعانين من الاكتئاب أو القلق خلال فترة الحمل، لكنّ نسبة كبيرة منهنّ لا يتلقّين التشخيص أو العلاج المناسب. ولذلك أوصت الكلية الأمريكية لأطباء النساء والتوليد بإجراء فحص روتيني للصحة النفسية في كل ثلث من أثلاث الحمل وفي الزيارة الأولى بعد الولادة. يتمّ هذا الفحص باستخدام استبيانات معيارية مثل مقياس إدنبرة للاكتئاب بعد الولادة ومقياس القلق المعمّم الذي يمكن إجراؤهما في دقائق معدودة أثناء زيارة المتابعة. ومن عوامل الخطر التي تزيد من احتمالية الإصابة بالاكتئاب أثناء الحمل وجود تاريخ سابق للاكتئاب ونقص الدعم الاجتماعي والتعرّض للعنف الأسري والحمل غير المخطّط له والمشكلات المالية. وتتضمّن خيارات العلاج العلاج النفسي السلوكي المعرفي الذي أثبت فعاليته العالية في علاج الاكتئاب والقلق أثناء الحمل دون الحاجة إلى أدوية، والعلاج بالتأمّل الواعي وتقنيات الاسترخاء واليوغا والتمارين الرياضية المنتظمة. وفي الحالات المتوسّطة والشديدة قد يكون العلاج الدوائي ضرورياً، حيث أظهرت الدراسات أن بعض مضادّات الاكتئاب وخاصةً من فئة مثبّطات استرداد السيروتونين الانتقائية آمنة نسبياً أثناء الحمل وأن فوائد العلاج تفوق مخاطره في الحالات الشديدة. ومن الضروري عدم التوقّف عن تناول الأدوية النفسية فجأةً عند اكتشاف الحمل دون استشارة الطبيب لأن ذلك قد يؤدّي إلى انتكاسة خطيرة.',
    ),
  ]),

  _DiscoverCat(name: 'ما بعد الولادة', emoji: '👩‍👦', articles: [
    _DiscoverArt(
      title: 'الجدول الزمني للتعافي بعد الولادة',
      emoji: '📅',
      color1: const Color(0xFF6A1B9A),
      image: 'assets/images/pregnancy_news/fb7b1c064926fc9bdd4592134a6db8d0.jpg',
      content: 'تُعدّ فترة ما بعد الولادة من أكثر المراحل تحدّياً في حياة المرأة، حيث يمرّ جسمها بتغيّرات عميقة أثناء عودته تدريجياً إلى حالته قبل الحمل. يختلف الجدول الزمني للتعافي من امرأة لأخرى ويعتمد على نوع الولادة ووجود مضاعفات والصحة العامة ومستوى الدعم المتاح. في الأيام الأولى بعد الولادة الطبيعية تعاني معظم النساء من ألم في منطقة العجان وتقلّصات رحمية تُعرف بالطلق البعدي وخاصةً أثناء الرضاعة، بالإضافة إلى نزيف مهبلي يُسمّى الهلابة يستمرّ لأربعة إلى ستة أسابيع ويتحوّل تدريجياً من اللون الأحمر القاني إلى الوردي ثم الأصفر. يحتاج الرحم إلى حوالي ستة أسابيع للعودة إلى حجمه الطبيعي في عملية تُسمّى الانكماش الرحمي. أما بالنسبة للولادة القيصرية فيضاف إلى ذلك فترة تعافي الجرح الجراحي التي تستغرق عادةً من أربعة إلى ستة أسابيع، مع توصية بتجنّب رفع الأثقال والنشاط البدني المكثّف خلال هذه الفترة. في الأسابيع الأولى من الطبيعي الشعور بتعب شديد بسبب قلّة النوم والتغيّرات الهرمونية الكبيرة التي تحدث مع انخفاض مستويات البروجستيرون والإستروجين وارتفاع هرمون البرولاكتين المسؤول عن إنتاج الحليب. وبحلول الأسبوع السادس تكون معظم النساء جاهزات للفحص الطبي الشامل بعد الولادة الذي يتضمّن فحص الجرح والرحم وضغط الدم ومناقشة وسائل تنظيم الأسرة. أما التعافي الكامل للجسم فقد يستغرق من ستة أشهر إلى سنة كاملة، خاصةً فيما يتعلّق بعودة عضلات البطن والحوض إلى قوّتها الطبيعية. وينصح الخبراء بالتدرّج في العودة إلى النشاط البدني والاستماع إلى إشارات الجسم وطلب المساعدة من العائلة والأصدقاء.',
    ),
    _DiscoverArt(
      title: 'تحدّيات الرضاعة الطبيعية وحلولها العملية',
      emoji: '🤱',
      color1: const Color(0xFFD84315),
      image: 'assets/images/pregnancy_news/images (1).jpg',
      content: 'رغم أن الرضاعة الطبيعية عملية طبيعية، إلا أن الكثير من الأمهات الجدد يواجهن تحدّيات حقيقية قد تؤدّي إلى الإحباط والتخلّي عن الرضاعة مبكّراً إذا لم يحصلن على الدعم المناسب. تشير الإحصاءات إلى أن حوالي ستين بالمائة من الأمهات يتوقّفن عن الرضاعة الطبيعية قبل الموعد الذي خطّطن له، وغالباً ما يكون السبب مشكلات قابلة للحلّ بالمعرفة والدعم الصحيحين. من أكثر التحدّيات شيوعاً التقام الثدي غير الصحيح الذي يسبّب ألماً شديداً وتشقّق الحلمات، ويمكن التغلّب عليه بتعلّم وضعيات الرضاعة الصحيحة والتأكّد من أن الطفل يفتح فمه واسعاً ويمسك بجزء كبير من الهالة وليس الحلمة فقط. ومن التحدّيات الشائعة أيضاً الشعور بعدم كفاية الحليب، وهو قلق يراود الكثير من الأمهات رغم أن النقص الحقيقي في إنتاج الحليب نادر ويصيب أقل من خمسة بالمائة من النساء. وأفضل طريقة لزيادة إنتاج الحليب هي زيادة تواتر الرضعات والحرص على إفراغ الثدي جيداً وشرب كمّيات كافية من السوائل وتناول غذاء متوازن. ومن المشكلات التي تواجه بعض الأمهات احتقان الثدي الشديد في الأيام الأولى عند نزول الحليب، ويمكن تخفيفه بالرضاعة المتكرّرة والكمّادات الباردة بين الرضعات وتدليك الثدي بلطف. كما تُعدّ التهابات الثدي من التحدّيات الجدّية التي تتطلّب علاجاً سريعاً بالمضادّات الحيوية مع الاستمرار في الرضاعة من الثدي المصاب. ويواجه بعض الأطفال صعوبات في الرضاعة بسبب ربط اللسان وهو حالة يكون فيها اللجام تحت اللسان قصيراً جداً مما يعيق حركة اللسان ويمكن علاجه بإجراء بسيط في العيادة. وينصح الخبراء بطلب استشارة متخصّصة في الرضاعة الطبيعية في أقرب وقت عند مواجهة أي صعوبة.',
    ),
    _DiscoverArt(
      title: 'اكتئاب ما بعد الولادة: العلامات والعلاج',
      emoji: '💜',
      color1: const Color(0xFF00838F),
      image: 'https://images.unsplash.com/photo-1531983412531-1f49a365ffed?w=800&q=80',
      content: 'يُعدّ اكتئاب ما بعد الولادة من أكثر مضاعفات الحمل والولادة شيوعاً وأقلّها تشخيصاً وعلاجاً، حيث يصيب ما بين عشرة إلى عشرين بالمائة من الأمهات الجدد ويمكن أن يظهر في أي وقت خلال السنة الأولى بعد الولادة. من المهم التمييز بين الكآبة النفاسية التي تصيب ثمانين بالمائة من الأمهات وتتضمّن تقلّبات مزاجية وبكاء وقلق خفيف يبدأ في الأيام الأولى ويختفي خلال أسبوعين، وبين اكتئاب ما بعد الولادة الذي يكون أشدّ وأطول مدّةً ويتطلّب علاجاً متخصّصاً. تشمل أعراض اكتئاب ما بعد الولادة الحزن المستمر والعميق وفقدان الاهتمام بالأنشطة المعتادة والشعور بالذنب والعجز واضطرابات النوم غير المرتبطة بإيقاظ الطفل وتغيّرات في الشهية وصعوبة التركيز والتفكير في إيذاء النفس أو الطفل. ومن الأعراض التي قد لا تُربط بالاكتئاب الغضب المفرط والانسحاب الاجتماعي والشعور بعدم القدرة على رعاية الطفل والخوف المستمرّ من حدوث شيء سيّئ. وتتعدّد عوامل الخطر لتشمل تاريخاً سابقاً للاكتئاب ومضاعفات الولادة وقلّة الدعم الاجتماعي والمشكلات الزوجية والصعوبات المالية وصعوبات الرضاعة الطبيعية. ويتضمّن العلاج عدّة محاور تشمل العلاج النفسي وخاصةً العلاج السلوكي المعرفي والعلاج الشخصي، والعلاج الدوائي بمضادّات الاكتئاب التي يمكن استخدام بعضها بأمان أثناء الرضاعة الطبيعية. وقد أُطلقت مؤخراً أدوية جديدة مخصّصة تحديداً لعلاج اكتئاب ما بعد الولادة تعمل على مستقبلات حمض الغاما أمينوبيوتيريك وتُظهر نتائج سريعة في غضون أيام. ومن الضروري كسر حاجز الصمت والخجل المحيط بهذا الموضوع وتشجيع الأمهات على طلب المساعدة دون شعور بالعار.',
    ),
    _DiscoverArt(
      title: 'تأهيل قاع الحوض بعد الولادة',
      emoji: '💪',
      color1: const Color(0xFF558B2F),
      image: 'assets/images/pregnancy_news/images.jpg',
      content: 'تتعرّض عضلات قاع الحوض لضغط هائل خلال الحمل والولادة، مما يجعل تأهيلها وتقويتها أمراً بالغ الأهمية لصحة المرأة على المدى البعيد. يتكوّن قاع الحوض من مجموعة من العضلات والأربطة التي تمتد كالأرجوحة بين عظم العانة في الأمام وعظم العصعص في الخلف، وهي تدعم المثانة والرحم والمستقيم وتتحكّم في عمليات التبوّل والتبرّز. خلال الحمل يُضعف وزن الرحم المتزايد وهرمون الريلاكسين هذه العضلات، وأثناء الولادة الطبيعية تتمدّد بشكل كبير وقد تتعرّض لتمزّقات. تشمل مشكلات ضعف قاع الحوض سلس البول الإجهادي الذي يتميّز بتسرّب البول عند العطس أو السعال أو الضحك أو ممارسة الرياضة، وسلس البراز وهبوط أعضاء الحوض والألم أثناء العلاقة الزوجية. وتشير الإحصاءات إلى أن ثلث النساء يعانين من سلس البول بعد الولادة، لكنّ الكثيرات يخجلن من الحديث عن هذه المشكلة رغم أنها قابلة للعلاج في معظم الحالات. يبدأ تأهيل قاع الحوض بتمارين كيجل التي تتضمّن انقباض عضلات قاع الحوض وإرخائها بشكل متكرّر، وينصح بأدائها عشر مرّات ثلاث مجموعات يومياً مع الحرص على عدم شدّ عضلات البطن أو الأرداف أثناء التمرين. ومع تقدّم التعافي يمكن إضافة تمارين أكثر تحدّياً مثل تمارين الجسر والقرفصاء والبيلاتيس المعدّلة. وفي الحالات الشديدة قد يُوصي أخصائي العلاج الطبيعي باستخدام أجهزة التحفيز الكهربائي لعضلات قاع الحوض أو أقماع مهبلية ذات أوزان متدرّجة. ومن التقنيات الحديثة استخدام الارتجاع البيولوجي الذي يساعد المرأة على تحديد العضلات الصحيحة والتحكّم فيها بدقّة. ولا ينبغي إهمال هذه المشكلة أو اعتبارها أمراً طبيعياً لا يمكن علاجه.',
    ),
    _DiscoverArt(
      title: 'صورة الجسم والتقبّل الذاتي بعد الولادة',
      emoji: '🪞',
      color1: const Color(0xFF4527A0),
      image: 'https://images.unsplash.com/photo-1515621061946-eff1c2a352bd?w=800&q=80',
      content: 'تواجه الكثير من الأمهات الجدد صراعاً حقيقياً مع صورة الجسم بعد الولادة، حيث تجدن أنفسهنّ في مواجهة تغيّرات جسدية كبيرة وسط ضغوط اجتماعية هائلة للعودة السريعة إلى وزن وشكل ما قبل الحمل. أظهرت الأبحاث أن أكثر من سبعين بالمائة من الأمهات الجدد يعبّرن عن عدم رضاهنّ عن أجسامهنّ بعد الولادة، وأن هذا الشعور يرتبط بزيادة خطر الإصابة باكتئاب ما بعد الولادة واضطرابات الأكل وتدنّي احترام الذات. ومن التغيّرات الجسدية الطبيعية بعد الولادة ترهّل البطن بسبب تمدّد عضلات البطن والجلد، وظهور علامات التمدّد على البطن والصدر والأرداف، وتغيّر حجم وشكل الثديين، وتغيّرات في توزيع الدهون في الجسم، وتساقط الشعر الذي يبلغ ذروته عادةً بعد ثلاثة إلى ستة أشهر من الولادة. من المهم أن تدرك الأم أن هذه التغيّرات طبيعية وأن جسمها أنجز عملاً خارقاً بإنماء إنسان كامل وإنجابه. وتنصح المتخصّصات في الصحة النفسية بعدّة استراتيجيات لتحسين صورة الجسم بعد الولادة تشمل التركيز على ما يستطيع الجسم فعله بدلاً من شكله، وتجنّب المقارنة مع الآخرين خاصةً صور المشاهير على وسائل التواصل الاجتماعي التي غالباً ما تكون غير واقعية، والابتعاد عن الحميات القاسية التي قد تؤثّر على إنتاج الحليب وعلى الطاقة اللازمة لرعاية الطفل. كما يُنصح بممارسة النشاط البدني المعتدل ليس بهدف فقدان الوزن بل لتحسين المزاج والطاقة وتقوية الجسم. ومن الضروري إحاطة النفس ببيئة داعمة تتقبّل التغيّرات الطبيعية وتحتفي بإنجاز الأمومة. وفي حال تأثّر الحالة النفسية بشكل كبير بمسألة صورة الجسم يُنصح بالتحدّث مع متخصّص في الصحة النفسية.',
    ),
    _DiscoverArt(
      title: 'العودة إلى العمل بعد إجازة الأمومة',
      emoji: '💼',
      color1: const Color(0xFF795548),
      image: 'https://images.unsplash.com/photo-1573497620053-ea5300f94f21?w=800&q=80',
      content: 'تُمثّل العودة إلى العمل بعد إجازة الأمومة تحدّياً كبيراً للكثير من الأمهات الجدد، حيث تتضافر المشاعر المتناقضة بين الرغبة في الاستمرار المهني والشعور بالذنب تجاه ترك الطفل. أظهرت الدراسات أن التخطيط المسبق والدعم المناسب يُسهمان بشكل كبير في تسهيل هذا الانتقال وتقليل التوتّر المصاحب له. من أهمّ الخطوات التحضيرية البدء في التعامل تدريجياً مع فكرة العودة قبل عدّة أسابيع من الموعد المحدّد، والتحدّث مع المدير أو قسم الموارد البشرية حول خيارات العمل المرنة مثل العمل عن بُعد جزئياً أو تقليل ساعات العمل في الفترة الأولى. ومن القضايا المهمة التي يجب التحضير لها موضوع الرضاعة الطبيعية في مكان العمل، حيث يحقّ للأم قانونياً في كثير من البلدان الحصول على استراحات لضخّ الحليب وتوفير مكان خاص لذلك. ويُنصح بالبدء في تكوين مخزون من الحليب المضخوخ قبل العودة للعمل بعدّة أسابيع وتعويد الطفل على الرضاعة من الزجاجة بشكل تدريجي. كما يجب اختيار ترتيبات رعاية الطفل المناسبة قبل وقت كافٍ، سواء كانت حضانة أو مربّية أو مساعدة من أفراد العائلة، مع تخصيص فترة تجريبية قبل العودة الفعلية للعمل. ومن التحدّيات الشائعة بعد العودة إدارة الوقت والطاقة بين متطلّبات العمل ورعاية الطفل والمسؤوليات المنزلية، ولذلك يُنصح بوضع توقّعات واقعية وعدم السعي إلى الكمال في كل شيء وطلب المساعدة عند الحاجة. كما أظهرت الأبحاث أن التواصل مع أمهات أخريات يمررن بالتجربة نفسها يوفّر دعماً عاطفياً مهمّاً. وأخيراً من الضروري الاعتناء بالصحة النفسية والجسدية والحصول على قدر كافٍ من النوم والتغذية والنشاط البدني لمواجهة تحدّيات هذه المرحلة الانتقالية المهمة.',
    ),
  ]),

];

// ─── Discover Article Detail Screen ───
class _DiscoverDetailScreen extends StatelessWidget {
  final _DiscoverArt article;
  final String categoryName;
  const _DiscoverDetailScreen({Key? key, required this.article, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: _teal,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(categoryName, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                centerTitle: true,
                background: article.image.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        article.image.startsWith('http')
                          ? ArticleImage(title: article.title, section: 'pregnancy', networkUrl: article.image, fit: BoxFit.cover)
                          : Image.asset(article.image, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: article.color1.withOpacity(0.1),
                                child: Center(child: Text(article.emoji, style: const TextStyle(fontSize: 48))))),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.white.withOpacity(0.3), Colors.white],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [article.color1.withOpacity(0.2), article.color1.withOpacity(0.05), Colors.white],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              width: 95,
                              height: 95,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: article.color1.withOpacity(0.15), blurRadius: 20, spreadRadius: 5)],
                              ),
                              child: Center(child: Text(article.emoji, style: const TextStyle(fontSize: 48))),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: article.color1.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(categoryName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: article.color1)),
                    ),
                    const SizedBox(height: 14),
                    Text(article.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textPrimary, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.access_time, size: 14, color: _textSecondary.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text('3 دقائق قراءة', style: TextStyle(fontSize: 12, color: _textSecondary.withOpacity(0.6))),
                    ]),
                    const SizedBox(height: 20),
                    Container(height: 1, color: const Color(0xFFEEEEEE)),
                    const SizedBox(height: 20),
                    // Content with paragraphs + ad space
                    ..._buildDiscoverParagraphs(article.content, article.color1),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lightTeal,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _teal.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: _teal.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.lightbulb_outline, color: _teal, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('نصيحة مهمة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _teal)),
                                SizedBox(height: 4),
                                Text('استشيري طبيبتك دائماً قبل اتخاذ أي قرارات صحية. كل حمل مختلف.',
                                  style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.6)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Products carousel (dynamic + static)
                    const SizedBox(height: 24),
                    Row(children: [
                      Icon(Icons.shopping_bag_outlined, color: _teal, size: 22),
                      const SizedBox(width: 8),
                      const Text('منتجات قد تهمك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                    ]),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: DynamicContentService.getProducts(section: 'pregnancy'),
                      builder: (context, prodSnap) {
                        final dynamicProducts = (prodSnap.data?.docs ?? [])
                            .map((doc) => DynamicContentService.docToProduct(doc))
                            .toList();
                        final allProducts = [...dynamicProducts, ..._pregnancyProducts];
                        return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allProducts.length,
                        itemBuilder: (_, i) {
                          final p = allProducts[i];
                          return Container(
                            width: 150,
                            margin: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                child: Image.network(p['image']!, height: 100, width: 150, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(height: 100, width: 150, color: _teal.withOpacity(0.1),
                                    child: const Icon(Icons.shopping_bag, color: _teal))),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(p['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text(p['category']!, style: const TextStyle(fontSize: 9, color: _teal)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(p['price']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _teal)),
                                ]),
                              ),
                            ]),
                          );
                        },
                      ),
                    );
                      },
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

  static const _pregnancyProducts = <Map<String, String>>[
    {'name': 'وسادة الحمل المريحة', 'image': 'https://images.unsplash.com/photo-1584839404210-0a5d92ea4861?w=300&q=80', 'price': '3500 د.ج', 'category': 'راحة الحامل'},
    {'name': 'كريم علامات التمدد', 'image': 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=300&q=80', 'price': '1800 د.ج', 'category': 'العناية بالبشرة'},
    {'name': 'حمض الفوليك 400mcg', 'image': 'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300&q=80', 'price': '950 د.ج', 'category': 'مكملات غذائية'},
    {'name': 'حزام دعم البطن', 'image': 'https://images.unsplash.com/photo-1584839404210-0a5d92ea4861?w=300&q=80', 'price': '2200 د.ج', 'category': 'راحة الحامل'},
    {'name': 'زيت اللوز للتدليك', 'image': 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=300&q=80', 'price': '1200 د.ج', 'category': 'العناية بالبشرة'},
    {'name': 'فيتامينات ما قبل الولادة', 'image': 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=300&q=80', 'price': '2800 د.ج', 'category': 'مكملات غذائية'},
  ];

  static List<Widget> _buildDiscoverParagraphs(String body, Color accentColor) {
    List<String> paragraphs;
    if (body.contains('\n\n')) {
      paragraphs = body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    } else {
      paragraphs = [];
      String current = '';
      final sentences = body.trim().split(RegExp(r'(?<=[\.!\?:،])\s+'));
      int sentCount = 0;
      for (final s in sentences) {
        current += (current.isEmpty ? '' : ' ') + s;
        sentCount++;
        if (sentCount >= 3 && current.length > 100) {
          paragraphs.add(current.trim());
          current = '';
          sentCount = 0;
        }
      }
      if (current.trim().isNotEmpty) paragraphs.add(current.trim());
    }
    final widgets = <Widget>[];
    final midPoint = (paragraphs.length / 2).floor();
    for (int i = 0; i < paragraphs.length; i++) {
      widgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: EdgeInsets.only(bottom: i < paragraphs.length - 1 ? 12 : 0),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Text(paragraphs[i].trim(), textAlign: TextAlign.justify,
          style: const TextStyle(fontSize: 16.5, height: 1.9, color: _textPrimary)),
      ));
      if (i == midPoint && paragraphs.length > 3) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: NabdaAd(slot: 0, groupId: 'pwk2', place: 'pregnancy', color: Color(0xFFE91E63)),
        ));
      }
    }
    return widgets;
  }
}

// ─── Category All Articles Screen ───
class _CategoryArticlesScreen extends StatelessWidget {
  final _DiscoverCat category;
  const _CategoryArticlesScreen({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          title: Text(
            '${category.emoji} ${category.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: _textPrimary, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          foregroundColor: _teal,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _divider),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: category.articles.length,
          itemBuilder: (context, index) {
            final art = category.articles[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _DiscoverDetailScreen(article: art, categoryName: category.name),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    // Image or Emoji section
                    Container(
                      width: 100,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: art.image.isEmpty ? LinearGradient(
                          colors: [art.color1.withOpacity(0.2), art.color1.withOpacity(0.08)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ) : null,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: art.image.isNotEmpty
                        ? (art.image.startsWith('http')
                          ? Image.network(art.image, fit: BoxFit.cover, width: 100, height: 110,
                              errorBuilder: (_, __, ___) => Center(child: Text(art.emoji, style: const TextStyle(fontSize: 40))))
                          : Image.asset(art.image, fit: BoxFit.cover, width: 100, height: 110,
                              errorBuilder: (_, __, ___) => Center(child: Text(art.emoji, style: const TextStyle(fontSize: 40)))))
                        : Center(child: Text(art.emoji, style: const TextStyle(fontSize: 40))),
                    ),
                    // Text section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: art.color1.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category.name,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: art.color1),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              art.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: _textSecondary.withOpacity(0.6)),
                                const SizedBox(width: 4),
                                Text('3 دقائق قراءة', style: TextStyle(fontSize: 11, color: _textSecondary.withOpacity(0.6))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Icon(Icons.arrow_back_ios, size: 14, color: _textSecondary.withOpacity(0.4)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Progress ring painter
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _ProgressRingPainter({required this.progress, required this.color, this.bgColor = const Color(0xFFFFE8EC)});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final strokeWidth = 7.0;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}

class RealisticFetusIllustration extends CustomPainter {
  final int week;
  final bool isSmall;
  final bool isOnDark;
  RealisticFetusIllustration({required this.week, this.isSmall = false, this.isOnDark = false});

  static const Color _skinBase = Color(0xFFE8A090);
  static const Color _skinLight = Color(0xFFF2C4B6);
  static const Color _skinDark = Color(0xFFC47A6C);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy) * 0.85;
    // Background glow
    if (!isSmall) {
      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(Offset(cx, cy), r * 1.3,
            [const Color(0xFFE8B4B8).withOpacity(0.12), Colors.transparent],
            [0.0, 1.0]);
      canvas.drawCircle(Offset(cx, cy), r * 1.3, glowPaint);
    }
    canvas.save();
    canvas.translate(cx, cy);
    if (week <= 4) {
      _drawEarly(canvas, r);
    } else if (week <= 8) {
      _drawEmbryo(canvas, r);
    } else if (week <= 14) {
      _drawEarlyFetus(canvas, r, _skinLight);
    } else if (week <= 26) {
      _drawMidFetus(canvas, r, _skinLight);
    } else {
      _drawLateFetus(canvas, r, _skinLight);
    }
    canvas.restore();
  }

  void _drawEarly(Canvas canvas, double r) {
    final rng = Random(42);
    for (int i = 0; i < 12; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * r * 0.35;
      final cr = r * (0.1 + rng.nextDouble() * 0.12);
      final p = Paint()
        ..shader = ui.Gradient.radial(
            Offset(cos(angle) * dist - cr * 0.2, sin(angle) * dist - cr * 0.2),
            cr,
            [_skinLight.withOpacity(0.9), _skinBase.withOpacity(0.7)],
            [0.0, 1.0]);
      canvas.drawCircle(Offset(cos(angle) * dist, sin(angle) * dist), cr, p);
    }
    final memb = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _skinDark.withOpacity(0.3);
    canvas.drawCircle(Offset.zero, r * 0.55, memb);
  }

  void _drawEmbryo(Canvas canvas, double r) {
    final bodyPath = Path();
    final s = r * 0.6;
    bodyPath.moveTo(0, -s * 0.8);
    bodyPath.cubicTo(s * 0.7, -s * 0.6, s * 0.7, s * 0.3, s * 0.2, s * 0.7);
    bodyPath.cubicTo(s * 0.1, s * 0.8, -s * 0.1, s * 0.8, -s * 0.15, s * 0.6);
    bodyPath.cubicTo(-s * 0.3, s * 0.2, -s * 0.4, -s * 0.3, 0, -s * 0.8);
    bodyPath.close();

    final bodyPaint = Paint()
      ..shader = ui.Gradient.radial(
          Offset(s * 0.1, -s * 0.1), s,
          [_skinLight, _skinBase, _skinDark],
          [0.0, 0.6, 1.0]);
    canvas.drawPath(bodyPath, bodyPaint);

    final headPaint = Paint()
      ..shader = ui.Gradient.radial(
          Offset(-s * 0.05, -s * 0.7), s * 0.4,
          [_skinLight, _skinBase],
          [0.0, 1.0]);
    canvas.drawCircle(Offset(s * 0.05, -s * 0.65), s * 0.3, headPaint);

    final eye = Paint()..color = const Color(0xFF3A2520).withOpacity(0.6);
    canvas.drawCircle(Offset(s * 0.15, -s * 0.7), s * 0.04, eye);
  }

  void _drawEarlyFetus(Canvas canvas, double r, Color light) {
    final s = r * 0.7;
    _head(canvas, Offset(0, -s * 0.4), s * 0.35, light);
    final bodyPath = Path();
    bodyPath.moveTo(-s * 0.2, -s * 0.1);
    bodyPath.cubicTo(-s * 0.35, s * 0.3, -s * 0.15, s * 0.7, s * 0.05, s * 0.6);
    bodyPath.cubicTo(s * 0.25, s * 0.5, s * 0.35, s * 0.1, s * 0.2, -s * 0.1);
    bodyPath.close();
    final bp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, s * 0.2), s * 0.7,
          [light, _skinBase, _skinDark],
          [0.0, 0.5, 1.0]);
    canvas.drawPath(bodyPath, bp);
    final limb = Paint()..color = _skinBase.withOpacity(0.8);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-s * 0.35, s * 0.15), width: s * 0.12, height: s * 0.3), const Radius.circular(6)), limb);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(s * 0.3, s * 0.15), width: s * 0.12, height: s * 0.3), const Radius.circular(6)), limb);
    canvas.drawCircle(Offset(s * 0.08, -s * 0.45), s * 0.035, Paint()..color = const Color(0xFF3A2520).withOpacity(0.7));
    _cord(canvas, Offset(s * 0.05, s * 0.55), s);
  }

  void _drawMidFetus(Canvas canvas, double r, Color light) {
    final s = r * 0.8;
    canvas.save();
    canvas.rotate(-0.3);
    _head(canvas, Offset(s * 0.05, -s * 0.45), s * 0.32, light);
    final body = Path();
    body.moveTo(-s * 0.15, -s * 0.15);
    body.cubicTo(-s * 0.3, s * 0.15, -s * 0.25, s * 0.55, 0, s * 0.5);
    body.cubicTo(s * 0.2, s * 0.45, s * 0.3, s * 0.1, s * 0.15, -s * 0.15);
    body.close();
    final bp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, s * 0.1), s * 0.6,
          [light, _skinBase, _skinDark],
          [0.0, 0.5, 1.0]);
    canvas.drawPath(body, bp);
    final armP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(-s * 0.3, 0), Offset(-s * 0.5, s * 0.2),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-s * 0.2, s * 0.0), Offset(-s * 0.35, s * 0.25), armP);
    canvas.drawCircle(Offset(-s * 0.36, s * 0.26), s * 0.05, Paint()..color = _skinBase);
    final legP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(0, s * 0.4), Offset(-s * 0.15, s * 0.65),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leg = Path();
    leg.moveTo(-s * 0.05, s * 0.45);
    leg.cubicTo(-s * 0.2, s * 0.6, -s * 0.3, s * 0.5, -s * 0.25, s * 0.35);
    canvas.drawPath(leg, legP);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.25, s * 0.34), width: s * 0.1, height: s * 0.06),
        Paint()..color = _skinBase);
    canvas.drawCircle(Offset(s * 0.15, -s * 0.5), s * 0.03, Paint()..color = const Color(0xFF3A2520).withOpacity(0.8));
    canvas.drawArc(Rect.fromCenter(center: Offset(-s * 0.08, -s * 0.42), width: s * 0.1, height: s * 0.12),
        0.5, 2.5, false, Paint()..color = _skinDark.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(Offset(s * 0.2, -s * 0.43), s * 0.025, Paint()..color = _skinDark.withOpacity(0.5));
    _cord(canvas, Offset(s * 0.05, s * 0.5), s);
    canvas.restore();
  }

  void _drawLateFetus(Canvas canvas, double r, Color light) {
    final s = r * 0.85;
    canvas.save();
    canvas.rotate(-0.25);
    _head(canvas, Offset(s * 0.05, -s * 0.42), s * 0.35, light);
    final body = Path();
    body.moveTo(-s * 0.18, -s * 0.1);
    body.cubicTo(-s * 0.35, s * 0.2, -s * 0.3, s * 0.55, 0, s * 0.52);
    body.cubicTo(s * 0.25, s * 0.48, s * 0.35, s * 0.15, s * 0.18, -s * 0.1);
    body.close();
    final bp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(0, s * 0.15), s * 0.6,
          [light, _skinBase, _skinDark],
          [0.0, 0.45, 1.0]);
    canvas.drawPath(body, bp);
    final bellyGlow = Paint()
      ..shader = ui.Gradient.radial(
          Offset(s * 0.05, s * 0.2), s * 0.2,
          [light.withOpacity(0.5), Colors.transparent],
          [0.0, 1.0]);
    canvas.drawCircle(Offset(s * 0.05, s * 0.2), s * 0.2, bellyGlow);
    final armP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(-s * 0.2, s * 0.05), Offset(s * 0.1, s * 0.15),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final arm1 = Path();
    arm1.moveTo(-s * 0.2, s * 0.05);
    arm1.cubicTo(-s * 0.15, s * 0.15, -s * 0.05, s * 0.18, s * 0.05, s * 0.1);
    canvas.drawPath(arm1, armP);
    canvas.drawCircle(Offset(s * 0.06, s * 0.09), s * 0.05, Paint()..color = _skinBase);
    for (int i = 0; i < 4; i++) {
      final fa = -0.4 + i * 0.25;
      canvas.drawLine(
          Offset(s * 0.06 + cos(fa) * s * 0.05, s * 0.09 + sin(fa) * s * 0.05),
          Offset(s * 0.06 + cos(fa) * s * 0.08, s * 0.09 + sin(fa) * s * 0.08),
          Paint()..color = _skinDark.withOpacity(0.3)..strokeWidth = 1.0..strokeCap = StrokeCap.round);
    }
    final legP = Paint()
      ..shader = ui.Gradient.linear(
          Offset(-s * 0.05, s * 0.45), Offset(-s * 0.25, s * 0.2),
          [_skinBase, _skinDark],
          [0.0, 1.0])
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leg1 = Path();
    leg1.moveTo(-s * 0.05, s * 0.48);
    leg1.cubicTo(-s * 0.2, s * 0.55, -s * 0.35, s * 0.45, -s * 0.3, s * 0.3);
    canvas.drawPath(leg1, legP);
    final leg2 = Path();
    leg2.moveTo(s * 0.1, s * 0.48);
    leg2.cubicTo(-s * 0.05, s * 0.6, -s * 0.2, s * 0.55, -s * 0.2, s * 0.4);
    canvas.drawPath(leg2, legP);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.3, s * 0.29), width: s * 0.11, height: s * 0.07),
        Paint()..color = _skinBase);
    canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.2, s * 0.39), width: s * 0.11, height: s * 0.07),
        Paint()..color = _skinBase);
    final eyeP = Paint()..color = const Color(0xFF3A2520).withOpacity(0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(s * 0.14, -s * 0.47), width: s * 0.08, height: s * 0.04), 0, pi, false, eyeP);
    final nosePath = Path();
    nosePath.moveTo(s * 0.2, -s * 0.44);
    nosePath.cubicTo(s * 0.24, -s * 0.42, s * 0.24, -s * 0.38, s * 0.2, -s * 0.37);
    canvas.drawPath(nosePath, Paint()..color = _skinDark.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawArc(Rect.fromCenter(center: Offset(s * 0.16, -s * 0.33), width: s * 0.08, height: s * 0.04),
        0.2, 2.2, false, Paint()..color = const Color(0xFFBF7E7E).withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    final earPath = Path();
    earPath.moveTo(-s * 0.05, -s * 0.42);
    earPath.cubicTo(-s * 0.12, -s * 0.48, -s * 0.14, -s * 0.38, -s * 0.08, -s * 0.35);
    canvas.drawPath(earPath, Paint()..color = _skinDark.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.8);
    if (week >= 32) {
      final hairP = Paint()..color = const Color(0xFF5D4037).withOpacity(0.3)..strokeWidth = 1.0..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final a = -1.8 + i * 0.3;
        canvas.drawLine(
            Offset(s * 0.05 + cos(a) * s * 0.33, -s * 0.42 + sin(a) * s * 0.33),
            Offset(s * 0.05 + cos(a) * s * 0.4, -s * 0.42 + sin(a) * s * 0.4),
            hairP);
      }
    }
    _cord(canvas, Offset(s * 0.05, s * 0.52), s);
    canvas.restore();
  }

  void _head(Canvas canvas, Offset center, double radius, Color light) {
    final hp = Paint()
      ..shader = ui.Gradient.radial(
          Offset(center.dx - radius * 0.15, center.dy - radius * 0.15), radius,
          [light, _skinBase, _skinDark],
          [0.0, 0.6, 1.0]);
    canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 2.15), hp);
    final hl = Paint()
      ..shader = ui.Gradient.radial(
          Offset(center.dx - radius * 0.2, center.dy - radius * 0.3), radius * 0.5,
          [light.withOpacity(0.6), Colors.transparent],
          [0.0, 1.0]);
    canvas.drawCircle(Offset(center.dx - radius * 0.15, center.dy - radius * 0.2), radius * 0.5, hl);
  }

  void _cord(Canvas canvas, Offset start, double s) {
    final cordPath = Path();
    cordPath.moveTo(start.dx, start.dy);
    cordPath.cubicTo(start.dx + s * 0.15, start.dy + s * 0.15, start.dx - s * 0.1, start.dy + s * 0.3,
        start.dx + s * 0.2, start.dy + s * 0.35);
    final cordPaint = Paint()
      ..shader = ui.Gradient.linear(
          start, Offset(start.dx + s * 0.2, start.dy + s * 0.35),
          [_skinDark.withOpacity(0.6), const Color(0xFF8B6F6F).withOpacity(0.3)],
          [0.0, 1.0])
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(cordPath, cordPaint);
  }

  @override
  bool shouldRepaint(covariant RealisticFetusIllustration old) => old.week != week;
}

/// بطاقة خطّة الولادة — تظهر في الشهر الثامن لتسجيل نوع الولادة المتوقّع
/// بعد استشارة الطبيبة. تُخفى تلقائيًا متى سُجّل النوع، ويمكن تعديله لاحقًا.
class _BirthPlanPrompt extends StatelessWidget {
  const _BirthPlanPrompt();

  static const Color _indigo = Color(0xFF5C6BC0);

  Future<void> _set(BuildContext context, String type) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'birthType': type},
      SetOptions(merge: true),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(type == 'cesarean'
            ? 'سجّلنا خطّة ولادة قيصرية — ستجدين محتوى الاستعداد بالأسفل 🤍'
            : 'سجّلنا خطّة ولادة طبيعية 🤍'),
        backgroundColor: const Color(0xFF00897B),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final d = snap.data!.data() as Map<String, dynamic>? ?? {};
        // إن سُجّل النوع مسبقًا لا نُظهر البطاقة (المحتوى المشروط يظهر بدلًا منها)
        if (d['birthType'] == 'vaginal' || d['birthType'] == 'cesarean') {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _indigo.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _indigo.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Text('🏥', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Expanded(
                  child: Text('خطّة الولادة',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF2D2D3A))),
                ),
              ]),
              const SizedBox(height: 8),
              const Text(
                'مع اقتراب موعدك، هل تحدّثتِ مع طبيبتكِ عن نوع الولادة المتوقّع؟ تسجيله يتيح لنا تقديم محتوى استعداد مناسب لكِ. (اختياري ويمكن تغييره لاحقًا.)',
                style: TextStyle(fontSize: 14, height: 1.7, color: Color(0xFF555B66)),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _set(context, 'vaginal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _indigo,
                      side: const BorderSide(color: _indigo),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('طبيعية', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _set(context, 'cesarean'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _indigo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('قيصرية', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}
