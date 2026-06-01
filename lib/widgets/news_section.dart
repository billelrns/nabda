import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/dynamic_content_service.dart';

/// Shared news section widget used across multiple pages (pregnancy, etc.)
/// Now loads Firestore overrides to reflect admin edits.
class NewsSection extends StatelessWidget {
  final Color accentColor;
  final String sectionTitle;
  const NewsSection({Key? key, this.accentColor = const Color(0xFFE91E63), this.sectionTitle = 'آخر الأخبار'}) : super(key: key);

  static const news = <Map<String, String>>[
    {'title': 'أم رباعية التوائم تنجب 5 توائم دفعة واحدة', 'tag': 'أرقام قياسية',
     'image': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=400&q=80',
     'content': 'في واحدة من أغرب المصادفات الطبية أنجبت تيريزا ترويا وهي ممرضة أمريكية تبلغ من العمر ستة وثلاثين عاماً من مدينة إل باسو في تكساس خمسة توائم في يونيو 2025 دون استخدام أي أدوية خصوبة. المدهش أن تيريزا نفسها ولدت كرباعية توائم مما يجعل قصتها فريدة من نوعها في التاريخ الطبي.\n\nتحدث ولادة التوائم الخماسية بمعدل واحدة فقط من كل ستين مليون حالة ولادة طبيعية مما يجعلها من أندر الظواهر في عالم الطب. وُلد الأطفال الخمسة بعملية قيصرية وكانوا جميعاً بصحة جيدة رغم ولادتهم المبكرة.'},
    {'title': 'أصغر توائم رباعية خدّج في التاريخ ينجون', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1504151932400-72d4384f04b3?w=400&q=80',
     'content': 'حطمت عائلة براينت الأمريكية رقماً قياسياً عمره ثلاثون عاماً في موسوعة غينيس عندما وُلد توائمهم الأربعة في الأسبوع الثالث والعشرين فقط من الحمل أي قبل موعدهم بمائة وخمسة عشر يوماً. وُلد الأطفال الأربعة بأوزان لا تتجاوز ستمائة غرام لكل منهم.\n\nبفضل الرعاية المكثفة في وحدة العناية بحديثي الولادة استعاد التوائم الأربعة عافيتهم تدريجياً وخرجوا جميعاً من المستشفى بصحة ممتازة.'},
    {'title': 'امرأة ألمانية تنجب طفلها العاشر في سن 66 عاماً', 'tag': 'حول العالم',
     'image': 'https://images.unsplash.com/photo-1492725764893-90b379c2b6e7?w=400&q=80',
     'content': 'أذهلت ألكسندرا هيلدبراندت الألمانية العالم عندما أنجبت طفلها العاشر فيليب في مارس 2025 وهي في سن السادسة والستين دون أي أدوية خصوبة أو تلقيح صناعي. وُلد الطفل بعملية قيصرية في مستشفى شاريتيه في برلين بوزن ثلاثة كيلوغرامات ونصف وبصحة ممتازة.\n\nأثار الخبر جدلاً واسعاً في ألمانيا وأوروبا حول أخلاقيات الإنجاب في سن متقدمة لكن ألكسندرا أكدت أنها تتمتع بصحة جيدة.'},
    {'title': 'طفل ينمو خارج الرحم وينجو بأعجوبة', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=400&q=80',
     'content': 'في حالة طبية نادرة للغاية لا تحدث إلا مرة واحدة من كل ثلاثين ألف حالة حمل اكتشف أطباء في مدينة بيكرزفيلد بكاليفورنيا أن طفل الممرضة سوز لوبيز نما في بطنها خارج الرحم مخفياً خلف كيس مبيضي بحجم كرة السلة.\n\nنجا الطفل بأعجوبة رغم أن حالات الحمل البطني التي تصل لاكتمال النمو نادرة جداً بنسبة أقل من واحد في المليون.'},
    {'title': 'تسعة توائم من مالي يحتفلون بعيد ميلادهم الأول', 'tag': 'أرقام قياسية',
     'image': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=400&q=80',
     'content': 'احتفلت السيدة المالية حليمة سيسيه بعيد الميلاد الأول لتوائمها التسعة الذين سجلوا رقماً قياسياً في موسوعة غينيس كأكبر عدد مواليد أحياء من ولادة واحدة. وُلد الأطفال التسعة خمسة ذكور وأربع إناث بعملية قيصرية.\n\nتحتاج الأسرة يومياً لأكثر من مائة حفاضة وكميات هائلة من الحليب. رغم التحديات أعربت حليمة عن سعادتها الغامرة.'},
    {'title': 'أم تلد في مطعم بعد أن أعادها المستشفى للمنزل', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&q=80',
     'content': 'في أبريل 2024 عاشت أليس سباركمان الأمريكية تجربة لا تُنسى عندما أعادها المستشفى للمنزل رغم شعورها بانقباضات منتظمة. قررت مع زوجها التوقف لتناول العشاء في مطعم قريب وما إن قضمت أول لقمة حتى نزل ماء الولادة.\n\nاستدعى طاقم المطعم الإسعاف فوراً وساعد المسعفون في توليدها في المطعم نفسه. وُلد الطفل بصحة تامة.'},
    {'title': 'أول طفل في بريطانيا من رحم مزروع', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1531983412531-1f49a365ffed?w=400&q=80',
     'content': 'في إنجاز طبي تاريخي رحبت غريس وزوجها أنغوس من بريطانيا بطفلتهما إيمي إيزابيل وهي أول طفلة تولد في المملكة المتحدة من رحم مزروع بعد عشر سنوات من الانتظار والمحاولات.\n\nهذا الإنجاز يفتح الباب لآلاف النساء اللواتي فقدن قدرتهن على الحمل.'},
    {'title': 'توأمان يولدان في سنتين مختلفتين بفارق 15 دقيقة', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1578922746465-3a80a228f223?w=400&q=80',
     'content': 'في ليلة رأس السنة 2024 شهد مستشفى في نيويورك ولادة فريدة حيث وُلد التوأم الأول قبل منتصف الليل في 31 ديسمبر والتوأم الثاني بعد منتصف الليل في الأول من يناير 2025.\n\nقالت الأم إنها سعيدة لأن أطفالها سيكون لديهم قصة مميزة يروونها طوال حياتهم.'},
    {'title': 'سيدة أفريقية تنجب 10 توائم في ولادة واحدة', 'tag': 'أرقام قياسية',
     'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80',
     'content': 'أذهلت غوسيامي تاماراسيتومبي من جنوب أفريقيا العالم عندما أنجبت عشرة توائم سبعة ذكور وثلاث إناث بعملية قيصرية في مستشفى بريتوريا بعد تسعة وعشرين أسبوعاً فقط من الحمل.\n\nأثارت الحالة نقاشاً طبياً واسعاً حول حدود الحمل المتعدد والمخاطر الصحية المرتبطة به.'},
    {'title': 'طفل يولد بسنّين كاملتين يثير دهشة الأطباء', 'tag': 'حالات نادرة',
     'image': 'https://images.unsplash.com/photo-1519340241574-2cec6aef0c01?w=400&q=80',
     'content': 'في حالة طبية نادرة للغاية وُلد طفل في مستشفى بالهند بسنّين أماميتين كاملتين وهو ما يُعرف طبياً بأسنان الولادة. يحدث هذا في واحدة من كل ألفين إلى ثلاثة آلاف ولادة تقريباً.\n\nقرر الأطباء إزالة الأسنان لأنها كانت تسبب صعوبة في الرضاعة وخطر اختناق في حال سقوطها.'},
    {'title': 'أم تكتشف حملها قبل الولادة بساعات فقط', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1457342813143-a1ae27a5e890?w=400&q=80',
     'content': 'تتكرر حالات الحمل الخفي أكثر مما يتوقع الكثيرون. في عام 2024 ذهبت سيدة بريطانية إلى المستشفى بسبب آلام شديدة في البطن ظنتها التهاب الزائدة الدودية ليتفاجأ الأطباء بأنها في المخاض.\n\nيحدث الحمل الخفي في واحدة من كل خمسمائة حالة حمل تقريباً حيث لا تظهر على الأم أعراض الحمل المعتادة.'},
    {'title': 'توأمان متطابقان يولدان بلونَي بشرة مختلفين', 'tag': 'حالات نادرة',
     'image': 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400&q=80',
     'content': 'في حالة وراثية مذهلة وُلد توأمان لأبوين من عرقين مختلفين في بريطانيا بلونَي بشرة متناقضين تماماً. المظهر الخارجي لا يوحي بأي صلة قرابة بينهما.\n\nهذه الحالة تحدث بنسبة واحدة من كل مليون ولادة توائم وتثبت التنوع المذهل في الجينات البشرية.'},
    {'title': 'أصغر طفل خديج في العالم يحتفل بعيده الخامس', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1566004100631-35d015d6a491?w=400&q=80',
     'content': 'احتفل كورتيس مينز من ولاية ألاباما بعيد ميلاده الخامس بعد أن وُلد في الأسبوع الحادي والعشرين فقط بوزن أقل من ثلاثمائة غرام. كان أصغر طفل خديج ينجو في التاريخ الطبي.\n\nاليوم يعيش كورتيس حياة طبيعية تماماً. قصته ألهمت آلاف العائلات وأصبح رمزاً لقوة الإرادة والتقدم الطبي.'},
    {'title': 'امرأة تنجب طفلاً أثناء غيبوبة استمرت 3 أشهر', 'tag': 'حالات نادرة',
     'image': 'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?w=400&q=80',
     'content': 'دخلت سيدة في غيبوبة بسبب حادث سير وهي حامل في شهرها السادس. حافظ الأطباء على حياتها واستمرار الحمل طوال ثلاثة أشهر كاملة حتى وُلد الطفل بعملية قيصرية بصحة ممتازة.\n\nالمفاجأة الأكبر كانت عندما استيقظت الأم من غيبوبتها بعد أسبوعين من الولادة لتجد طفلها بجانبها.'},
    {'title': 'دراسة: أطفال يتعرفون على أصوات أمهاتهم من الرحم', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1491013516836-7db643ee125a?w=400&q=80',
     'content': 'كشفت دراسة علمية حديثة أن الأجنة يبدأون بالتعرف على صوت أمهاتهم وتمييزه من الأسبوع الثامن عشر من الحمل. استخدم الباحثون تقنيات تصوير متقدمة لقياس استجابة دماغ الجنين.\n\nالأطفال حديثي الولادة يفضلون صوت أمهاتهم على أي صوت آخر ويهدأون فوراً عند سماعه.'},
    {'title': 'طفلة تولد بخصلة شعر بيضاء وراثية نادرة', 'tag': 'حالات نادرة',
     'image': 'https://images.unsplash.com/photo-1519689373023-dd07c7988603?w=400&q=80',
     'content': 'أذهلت طفلة حديثة الولادة الأطباء عندما وُلدت بخصلة شعر بيضاء لامعة في مقدمة رأسها بينما باقي شعرها أسود. تبين أن الحالة وراثية تُعرف بالبهق الجزئي.\n\nالمدهش أن والدتها وجدتها وجدة جدتها جميعهن يحملن نفس الخصلة البيضاء.'},
    {'title': 'الرضاعة الطبيعية تحمي من 800 ألف وفاة سنوياً', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1609220136736-443140cffec6?w=400&q=80',
     'content': 'أكدت دراسة واسعة النطاق أجرتها منظمة الصحة العالمية أن الرضاعة الطبيعية تمنع وفاة أكثر من ثمانمائة ألف طفل سنوياً حول العالم. حليب الأم يحتوي على أكثر من ألف مركب نشط بيولوجياً.\n\nكشفت الدراسة أيضاً أن الرضاعة الطبيعية تقلل خطر إصابة الأم بسرطان الثدي والمبيض بنسبة عشرين بالمائة.'},
    {'title': 'أب يحضر ولادة ابنته عبر الفيديو من الفضاء', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400&q=80',
     'content': 'تابع رائد فضاء روسي ولادة ابنته عبر مكالمة فيديو من محطة الفضاء الدولية على ارتفاع أربعمائة كيلومتر فوق سطح الأرض. كان في مهمة مدتها ستة أشهر.\n\nبكى من الفرح عندما سمع صرخة طفلته الأولى. القصة لامست قلوب الملايين حول العالم.'},
    {'title': 'اكتشاف أن حليب الأم يتغير حسب جنس المولود', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=400&q=80',
     'content': 'توصل باحثون في جامعة هارفارد لاكتشاف مذهل وهو أن تركيبة حليب الأم تختلف تلقائياً حسب جنس المولود. حليب أمهات الذكور يحتوي على نسبة أعلى من الدهون.\n\nيعتقد العلماء أن هذا التكيف التلقائي تطور عبر ملايين السنين ليلبي الاحتياجات البيولوجية المختلفة لكل جنس.'},
    {'title': 'مستشفى يعزف الموسيقى للأجنة ويحسن نموهم', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1485546246426-74dc88dec4d9?w=400&q=80',
     'content': 'بدأ مستشفى في برشلونة برنامجاً مبتكراً يقوم على عزف موسيقى كلاسيكية للأجنة باستخدام جهاز صغير يوضع على البطن. أظهرت النتائج تطوراً عصبياً أفضل.\n\nالبرنامج يستخدم موسيقى موتسارت وباخ بتردد منخفض يمكن للجنين سماعه من الأسبوع السادس عشر.'},
    {'title': 'أم تنجب طفلتها في سيارة إسعاف على الطريق السريع', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?w=400&q=80',
     'content': 'لم تنتظر الطفلة ليلى وصول أمها للمستشفى فقررت القدوم للعالم في سيارة الإسعاف على الطريق السريع في القاهرة أثناء ساعة الذروة.\n\nوُلدت الطفلة بصحة ممتازة. أصبحت القصة حديث وسائل التواصل الاجتماعي وأطلق المتابعون على الطفلة لقب بنت الطريق.'},
    {'title': 'تقنية جديدة تتيح للأجنة التنفس خارج الرحم', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400&q=80',
     'content': 'يعمل فريق من العلماء في جامعة فيلادلفيا على تطوير رحم صناعي يشبه كيساً مملوءاً بسائل يحاكي السائل الأمنيوسي ويمكنه احتضان الأجنة الخدّج.\n\nإذا نجحت التجارب البشرية فإن هذه التقنية قد تنقذ حياة آلاف الأطفال الخدج المولودين قبل الأسبوع الرابع والعشرين.'},
    {'title': 'ممرضة تكتشف أنها أنجبت التوأم الذي تعتني به', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1578307985320-34b61a66c195?w=400&q=80',
     'content': 'اكتشفت ممرضة أن الطفلة الخديجة التي كانت تعتني بها قبل خمسة وعشرين عاماً هي نفس الممرضة الشابة التي انضمت للعمل معها. جمعتهما صورة قديمة معلقة على جدار القسم.\n\nالممرضة الشابة قالت إن هذه المصادفة هي السبب الذي دفعها لدراسة التمريض.'},
    {'title': 'الأطفال الذين يسمعون لغتين يتطور دماغهم أسرع', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400&q=80',
     'content': 'أثبتت دراسة حديثة أن أدمغة الأطفال ثنائيي اللغة تتطور بشكل أسرع وتظهر مرونة عصبية أعلى. التصوير بالرنين المغناطيسي أظهر نشاطاً أكبر في مناطق حل المشكلات.\n\nالأطفال ثنائيو اللغة يتفوقون في المهارات المعرفية والتركيز والذاكرة العاملة.'},
    {'title': 'توأمان ملتصقان يُفصلان بنجاح بعد عملية 36 ساعة', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=400&q=80',
     'content': 'نجح فريق طبي مكون من ستين طبيباً في لندن في فصل توأمين ملتصقين من الرأس في عملية استغرقت ستاً وثلاثين ساعة. كان التوأمان يتشاركان أوعية دموية في الدماغ.\n\nبعد أشهر من التعافي يعيش التوأمان حياة طبيعية ويمارسان نشاطاتهما بشكل مستقل.'},
    {'title': 'أم تتبرع بحليبها لإنقاذ مائة طفل خديج', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1544126592-807ade215a0b?w=400&q=80',
     'content': 'تبرعت سارة من الأردن بأكثر من مائتي لتر من حليبها لبنك الحليب مما ساعد في إنقاذ حياة أكثر من مائة طفل خديج خلال عامين.\n\nبنوك حليب الأم توفر حليباً بشرياً مبستراً للأطفال الخدج الذين يحتاجون لحليب بشري بدلاً من الصناعي.'},
    {'title': 'طفل يولد في طائرة على ارتفاع 10 آلاف متر', 'tag': 'حول العالم',
     'image': 'https://images.unsplash.com/photo-1436491865332-7a61a109db05?w=400&q=80',
     'content': 'على متن رحلة بين إسطنبول ونيويورك فاجأت سيدة تركية ركاب الطائرة عندما بدأت أعراض المخاض على ارتفاع عشرة آلاف متر فوق المحيط الأطلسي.\n\nمنحت شركة الطيران الطفل تذكرة سفر مجانية مدى الحياة وسمّاه والداه إيلان أي المسافر بالتركية.'},
    {'title': 'علماء يطورون حفاضاً ذكياً ينبه الوالدين صحياً', 'tag': 'اكتشافات علمية',
     'image': 'https://images.unsplash.com/photo-1587616211892-f743fcca64f9?w=400&q=80',
     'content': 'طور فريق في معهد ماساتشوستس للتكنولوجيا حفاضاً ذكياً مزوداً بمستشعرات يمكنه تحليل بول الرضيع واكتشاف علامات مبكرة لالتهابات المسالك البولية والجفاف.\n\nفي التجارب الأولية اكتشف الحفاض الذكي حالات التهاب قبل ظهور الأعراض بيومين.'},
    {'title': 'سيدة مصرية تنجب بعد 25 سنة من العقم', 'tag': 'معجزة طبية',
     'image': 'https://images.unsplash.com/photo-1492725764893-90b379c2b6e7?w=400&q=80',
     'content': 'بعد خمسة وعشرين عاماً من الانتظار رُزقت سيدة مصرية بتوأم ذكور بعد عملية حقن مجهري ناجحة في عامها الخمسين. قالت إنها لم تفقد الأمل يوماً.\n\nقصتها أعطت أملاً لآلاف النساء اللواتي يعانين من تأخر الإنجاب.'},
    {'title': 'مولود يبتسم ابتسامة عريضة لحظة ولادته', 'tag': 'قصص مدهشة',
     'image': 'https://images.unsplash.com/photo-1519340241574-2cec6aef0c01?w=400&q=80',
     'content': 'انتشرت صورة مولود برازيلي بعد أن التقط المصور لحظة نادرة وهي ابتسامة المولود فور خروجه من رحم أمه. حصدت الصورة أكثر من خمسين مليون مشاهدة.\n\nيقول أطباء الأطفال إن ما يبدو كابتسامة عند حديثي الولادة هو رد فعل عضلي لا إرادي لكن توقيتها جعلها مميزة.'},
    {'title': 'مدينة يابانية تقدم مكافأة مليون ين لكل مولود جديد', 'tag': 'حول العالم',
     'image': 'https://images.unsplash.com/photo-1480796927426-f609979314bd?w=400&q=80',
     'content': 'في محاولة لمكافحة انخفاض معدلات الولادة أعلنت مدينة نايغي اليابانية عن تقديم مكافأة مالية قدرها مليون ين لكل مولود جديد أي حوالي سبعة آلاف دولار.\n\nبعد عام من تطبيق البرنامج ارتفعت معدلات الولادة بنسبة خمسة عشر بالمائة وانتقلت عائلات جديدة للمدينة.'},
  ];

  /// Apply Firestore overrides to the static news list
  static List<Map<String, String>> _applyOverrides(List<Map<String, String>> original, List<QueryDocumentSnapshot> overrideDocs) {
    if (overrideDocs.isEmpty) return original;
    final overrideMap = <String, Map<String, dynamic>>{};
    for (final doc in overrideDocs) {
      overrideMap[doc.id] = doc.data() as Map<String, dynamic>;
    }
    return original.map((n) {
      final docId = n['title'].hashCode.toString();
      if (overrideMap.containsKey(docId)) {
        final o = overrideMap[docId]!;
        return <String, String>{
          'title': (o['title'] as String?) ?? n['title']!,
          'tag': (o['tag'] as String?) ?? n['tag']!,
          'image': (o['imageUrl'] as String?)?.isNotEmpty == true ? o['imageUrl'] as String : n['image']!,
          'content': (o['body'] as String?) ?? n['content']!,
          'originalTitle': n['title']!,
        };
      }
      return {...n, 'originalTitle': n['title']!};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('article_overrides')
        .where('section', isEqualTo: 'news')
        .snapshots(),
      builder: (context, overrideSnap) {
        final overrideDocs = overrideSnap.data?.docs ?? [];
        final mergedNews = _applyOverrides(news, overrideDocs);

        // Load dynamic news articles from Firestore
        return StreamBuilder<QuerySnapshot>(
          stream: DynamicContentService.getArticles(section: 'news'),
          builder: (context, dynamicSnap) {
            final dynamicNews = (dynamicSnap.data?.docs ?? [])
                .map((doc) {
                  final a = DynamicContentService.docToArticle(doc);
                  return <String, String>{
                    'title': a['title'] ?? '',
                    'tag': a['category'] ?? 'جديد',
                    'image': a['image'] ?? '',
                    'content': a['content'] ?? '',
                    'originalTitle': a['title'] ?? '',
                    'isDynamic': 'true',
                  };
                }).toList();

            // Dynamic articles first, then static
            final allNews = [...dynamicNews, ...mergedNews];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.newspaper, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(sectionTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F1A20)))),
                ]),
                const SizedBox(height: 4),
                const Text('أخبار غريبة ومدهشة من عالم الأمومة', style: TextStyle(fontSize: 13, color: Color(0xFF8B8190))),
                const SizedBox(height: 14),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allNews.length > 6 ? 6 : allNews.length,
                  itemBuilder: (context, i) {
                    final n = allNews[i];
                    return _newsCard(context, n, i);
                  },
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AllNewsScreen(accentColor: accentColor))),
                    icon: const Text('عرض جميع الأخبار', style: TextStyle(fontWeight: FontWeight.w600)),
                    label: const Icon(Icons.arrow_back_ios, size: 14),
                    style: TextButton.styleFrom(foregroundColor: accentColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _newsCard(BuildContext context, Map<String, String> n, int i) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => _NewsDetailPage(
          title: n['title']!,
          body: n['content']!,
          color: accentColor,
          imageUrl: n['image']!,
          originalTitle: n['originalTitle'] ?? n['title']!,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
            child: Image.network(n['image']!, width: 100, height: 90, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 100, height: 90, color: accentColor.withOpacity(0.1), child: Icon(Icons.newspaper, color: accentColor))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(n['tag']!, style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                Text(n['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class AllNewsScreen extends StatelessWidget {
  final Color accentColor;
  const AllNewsScreen({Key? key, this.accentColor = const Color(0xFFE91E63)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FB),
        appBar: AppBar(title: const Text('آخر الأخبار'), backgroundColor: accentColor, foregroundColor: Colors.white),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('article_overrides')
            .where('section', isEqualTo: 'news')
            .snapshots(),
          builder: (context, overrideSnap) {
            final overrideDocs = overrideSnap.data?.docs ?? [];
            final mergedNews = NewsSection._applyOverrides(NewsSection.news, overrideDocs);
            return StreamBuilder<QuerySnapshot>(
              stream: DynamicContentService.getArticles(section: 'news'),
              builder: (context, dynamicSnap) {
                final dynamicNews = (dynamicSnap.data?.docs ?? [])
                    .map((doc) {
                      final a = DynamicContentService.docToArticle(doc);
                      return <String, String>{
                        'title': a['title'] ?? '',
                        'tag': a['category'] ?? 'جديد',
                        'image': a['image'] ?? '',
                        'content': a['content'] ?? '',
                        'originalTitle': a['title'] ?? '',
                        'isDynamic': 'true',
                      };
                    }).toList();
                final allNews = [...dynamicNews, ...mergedNews];
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allNews.length,
              itemBuilder: (context, i) {
                final n = allNews[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => _NewsDetailPage(
                      title: n['title']!,
                      body: n['content']!,
                      color: accentColor,
                      imageUrl: n['image']!,
                      originalTitle: n['originalTitle'] ?? n['title']!,
                    ),
                  )),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Image.network(n['image']!, height: 160, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 160, color: accentColor.withOpacity(0.1), child: Icon(Icons.newspaper, color: accentColor, size: 50))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(n['tag']!, style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 8),
                          Text(n['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
                          const SizedBox(height: 6),
                          Text(n['content']!.substring(0, n['content']!.length > 100 ? 100 : n['content']!.length) + '...',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF8B8190), height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            );
              },
            );
          },
        ),
      ),
    );
  }
}

/// News detail page with Firestore override support and products carousel
class _NewsDetailPage extends StatefulWidget {
  final String title;
  final String body;
  final Color color;
  final String imageUrl;
  final String originalTitle;
  const _NewsDetailPage({required this.title, required this.body, required this.color, this.imageUrl = '', this.originalTitle = ''});

  @override
  State<_NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<_NewsDetailPage> {
  String _title = '';
  String _body = '';
  String _imageUrl = '';

  static const _products = <Map<String, String>>[
    {'name': 'كتاب أمومة سعيدة', 'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=300&q=80', 'price': '1500 د.ج', 'category': 'كتب ومراجع'},
    {'name': 'مفكرة تتبع الحمل', 'image': 'https://images.unsplash.com/photo-1517842645767-c639042777db?w=300&q=80', 'price': '950 د.ج', 'category': 'تنظيم'},
    {'name': 'حقيبة الأمومة الشاملة', 'image': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=300&q=80', 'price': '4500 د.ج', 'category': 'حقائب'},
    {'name': 'ألبوم ذكريات الطفل', 'image': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=300&q=80', 'price': '1800 د.ج', 'category': 'ذكريات'},
    {'name': 'تطبيق متابعة الحمل Pro', 'image': 'https://images.unsplash.com/photo-1517842645767-c639042777db?w=300&q=80', 'price': '500 د.ج', 'category': 'رقمي'},
    {'name': 'مجموعة العناية بالأم', 'image': 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=300&q=80', 'price': '3200 د.ج', 'category': 'هدايا'},
  ];

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _body = widget.body;
    _imageUrl = widget.imageUrl;
    _loadOverride();
  }

  Future<void> _loadOverride() async {
    final lookupTitle = widget.originalTitle.isNotEmpty ? widget.originalTitle : widget.title;
    final docId = lookupTitle.hashCode.toString();
    try {
      final doc = await FirebaseFirestore.instance.collection('article_overrides').doc(docId).get();
      if (doc.exists && mounted) {
        final d = doc.data()!;
        setState(() {
          if (d['title'] != null) _title = d['title'];
          if (d['body'] != null) _body = d['body'];
          if (d['imageUrl'] != null && (d['imageUrl'] as String).isNotEmpty) _imageUrl = d['imageUrl'];
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final paragraphs = _body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    final staticProducts = _products;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: _imageUrl.isNotEmpty ? 220 : 0,
              pinned: true,
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              flexibleSpace: _imageUrl.isNotEmpty
                ? FlexibleSpaceBar(
                    background: Image.network(_imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: widget.color.withOpacity(0.2))),
                  )
                : null,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F1A20), height: 1.5)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < paragraphs.length; i++) ...[
                    Text(paragraphs[i].trim(), style: const TextStyle(fontSize: 16, height: 1.8, color: Color(0xFF333333))),
                    if (i < paragraphs.length - 1) const SizedBox(height: 16),
                    if (i == paragraphs.length ~/ 2) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Center(child: Text('مساحة إعلانية', style: TextStyle(color: Colors.grey, fontSize: 13))),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Row(children: [
                    Icon(Icons.shopping_bag_outlined, color: widget.color, size: 22),
                    const SizedBox(width: 8),
                    const Text('منتجات قد تهمك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1A20))),
                  ]),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: DynamicContentService.getProducts(section: 'news'),
                    builder: (context, prodSnap) {
                      final dynamicProducts = (prodSnap.data?.docs ?? [])
                          .map((doc) => DynamicContentService.docToProduct(doc))
                          .toList();
                      final products = [...dynamicProducts, ...staticProducts];
                      return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (_, i) {
                        final p = products[i];
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
                                errorBuilder: (_, __, ___) => Container(height: 100, width: 150, color: widget.color.withOpacity(0.1),
                                  child: Icon(Icons.shopping_bag, color: widget.color))),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(p['category']!, style: TextStyle(fontSize: 9, color: widget.color)),
                                ),
                                const SizedBox(height: 4),
                                Text(p['price']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: widget.color)),
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
