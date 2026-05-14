import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ──────────────────────────────────────────────────────────
//  Nabda Onboarding — Inspired by Healofy & WeMoms
//  7-step flow: Welcome → Life Stage → Method → Date →
//  Weeks (fallback) → Name → Terms acceptance
// ──────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ── Palette ──
  static const _bg = Color(0xFFFFF8FB);
  static const _pink = Color(0xFFE91E63);
  static const _pinkLight = Color(0xFFFCE4EC);
  static const _teal = Color(0xFF00897B);
  static const _dark = Color(0xFF1F1A20);
  static const _sub = Color(0xFF4A434B);

  // ── State ──
  int _step = 0; // 0-6
  String? _lifeStage; // 'pregnant','baby','planning','cycle'
  String? _calcMethod; // 'lastPeriod','dueDate','dontKnow'
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 90));
  int _selectedWeeks = 20;
  int _selectedDays = 0;
  final _nameController = TextEditingController();
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _saving = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goNext() {
    _fadeCtrl.reverse().then((_) {
      setState(() {
        if (_step == 1 && _lifeStage != 'pregnant') {
          _step = 5; // skip pregnancy steps, go to name
        } else if (_step == 2 && _calcMethod == 'dontKnow') {
          _step = 4; // go to weeks picker
        } else if (_step == 3) {
          _step = 5; // skip weeks picker, go to name
        } else if (_step == 4) {
          _step = 5; // from weeks picker to name
        } else {
          _step++;
        }
      });
      _fadeCtrl.forward();
    });
  }

  void _goBack() {
    if (_step == 0) return;
    _fadeCtrl.reverse().then((_) {
      setState(() {
        if (_step == 5 && _lifeStage != 'pregnant') {
          _step = 1; // back to life stage
        } else if (_step == 4 && _calcMethod == 'dontKnow') {
          _step = 2;
        } else if (_step == 5 && _calcMethod == 'dontKnow') {
          _step = 4;
        } else if (_step == 5) {
          _step = 3;
        } else {
          _step--;
        }
      });
      _fadeCtrl.forward();
    });
  }

  // ── Save & navigate ──
  Future<void> _finishOnboarding() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);

      // Calculate pregnancy start date if applicable
      DateTime? pregnancyStart;
      if (_lifeStage == 'pregnant') {
        if (_calcMethod == 'lastPeriod') {
          pregnancyStart = _selectedDate;
        } else if (_calcMethod == 'dueDate') {
          pregnancyStart =
              _selectedDate.subtract(const Duration(days: 280));
        } else {
          // from weeks
          pregnancyStart = DateTime.now()
              .subtract(Duration(days: _selectedWeeks * 7 + _selectedDays));
        }
      }

      // Save locally
      await prefs.setString('life_stage', _lifeStage ?? 'cycle');
      await prefs.setString('user_name', _nameController.text.trim());
      if (pregnancyStart != null) {
        await prefs.setString(
            'pregnancy_start', pregnancyStart.toIso8601String());
      }

      // Save to Firestore if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = <String, dynamic>{
          'displayName': _nameController.text.trim(),
          'lifeStage': _lifeStage,
          'onboardingDone': true,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (pregnancyStart != null) {
          data['pregnancyStartDate'] = Timestamp.fromDate(pregnancyStart);
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(data, SetOptions(merge: true));
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _saving = false);
    context.go('/login');
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _welcomeStep();
      case 1:
        return _lifeStageStep();
      case 2:
        return _calcMethodStep();
      case 3:
        return _datePickerStep();
      case 4:
        return _weeksPickerStep();
      case 5:
        return _nameStep();
      case 6:
        return _termsStep();
      default:
        return _welcomeStep();
    }
  }

  // ─── Shared widgets ───
  Widget _backButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: IconButton(
        onPressed: _goBack,
        icon: const Icon(Icons.arrow_forward_ios, color: _dark),
      ),
    );
  }

  Widget _progressBar() {
    // Calculate effective step out of total
    int totalSteps = _lifeStage == 'pregnant' ? 7 : 4;
    int currentStep;
    if (_lifeStage != 'pregnant') {
      currentStep = _step <= 1 ? _step + 1 : (_step == 5 ? 3 : 4);
    } else {
      currentStep = _step + 1;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: currentStep / totalSteps,
          minHeight: 6,
          backgroundColor: _pinkLight,
          valueColor: const AlwaysStoppedAnimation<Color>(_pink),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isGradient = true,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: isGradient && onPressed != null
          ? BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFFF5252)],
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: _pink.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : BoxDecoration(
              color: onPressed != null
                  ? _pink.withValues(alpha: 0.15)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
      child: MaterialButton(
        onPressed: onPressed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isGradient && onPressed != null ? Colors.white : _dark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 0 — WELCOME
  // ══════════════════════════════════════════════════════════
  Widget _welcomeStep() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFCE4EC), _bg, Color(0xFFE0F2F1)],
        ),
      ),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_pink, Color(0xFFFF8A80)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _pink.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.favorite, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 30),
          const Text(
            'نبضة',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: _dark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'رفيقتك في رحلة الأمومة',
            style: TextStyle(
              fontSize: 18,
              color: _sub,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 50),
          _featurePill(Icons.pregnant_woman, 'متابعة الحمل'),
          const SizedBox(height: 12),
          _featurePill(Icons.calendar_today, 'تتبع الدورة'),
          const SizedBox(height: 12),
          _featurePill(Icons.child_care, 'صحة الطفل'),
          const SizedBox(height: 12),
          _featurePill(Icons.people, 'مجتمع الأمهات'),
          const Spacer(flex: 2),
          _primaryButton(text: 'ابدأي الآن', onPressed: _goNext),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'بالمتابعة، أنتِ توافقين على سياسة الخصوصية وشروط الاستخدام',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _featurePill(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: _pink.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _teal, size: 22),
          const SizedBox(width: 10),
          Text(text,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _dark)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 1 — LIFE STAGE (like Healofy "Choose your Life Stage")
  // ══════════════════════════════════════════════════════════
  Widget _lifeStageStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _backButton(),
        _progressBar(),
        const SizedBox(height: 30),
        const Text(
          'ما هي مرحلتك الحالية؟',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'سنخصص المحتوى بناءً على احتياجاتك',
          style: TextStyle(fontSize: 15, color: _sub),
        ),
        const SizedBox(height: 40),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _stageCard(
                  emoji: '🤰',
                  title: 'أنا حامل',
                  subtitle: 'متابعة الحمل أسبوعاً بأسبوع',
                  value: 'pregnant',
                  color: const Color(0xFFE91E63),
                ),
                const SizedBox(height: 16),
                _stageCard(
                  emoji: '👶',
                  title: 'عندي طفل',
                  subtitle: 'متابعة نمو وصحة طفلك (0-3 سنوات)',
                  value: 'baby',
                  color: const Color(0xFF7E57C2),
                ),
                const SizedBox(height: 16),
                _stageCard(
                  emoji: '💕',
                  title: 'أخطط للحمل',
                  subtitle: 'نصائح وتحضيرات قبل الحمل',
                  value: 'planning',
                  color: const Color(0xFFFF7043),
                ),
                const SizedBox(height: 16),
                _stageCard(
                  emoji: '📅',
                  title: 'تتبع الدورة الشهرية',
                  subtitle: 'متابعة دورتك والأعراض',
                  value: 'cycle',
                  color: _teal,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _primaryButton(
          text: 'التالي',
          onPressed: _lifeStage != null ? _goNext : null,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _stageCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    final selected = _lifeStage == value;
    return GestureDetector(
      onTap: () => setState(() => _lifeStage = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : [
                  BoxShadow(
                      color: _pink.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: selected ? color : _dark,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 13, color: _sub)),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check, color: Colors.white, size: 18),
              )
            else
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 2 — CALC METHOD (like WeMoms "Choisis une méthode")
  // ══════════════════════════════════════════════════════════
  Widget _calcMethodStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _backButton(),
        _progressBar(),
        const SizedBox(height: 50),
        const Text(
          'اختاري طريقة حساب\nمرحلة حملك',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _dark,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 50),
        _methodCard(
          title: 'تاريخ آخر دورة شهرية',
          icon: Icons.calendar_month,
          value: 'lastPeriod',
        ),
        const SizedBox(height: 16),
        _methodCard(
          title: 'تاريخ الولادة المتوقع',
          icon: Icons.child_friendly,
          value: 'dueDate',
        ),
        const SizedBox(height: 16),
        _methodCard(
          title: 'لا أعرف التاريخ',
          icon: Icons.help_outline,
          value: 'dontKnow',
        ),
        const Spacer(),
        _primaryButton(
          text: 'التالي',
          onPressed: _calcMethod != null ? _goNext : null,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _methodCard({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final selected = _calcMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _calcMethod = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: selected ? _pink.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _pink : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _pink : _teal, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: selected ? _pink : _dark,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: _pink, size: 26),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 3 — DATE PICKER (like WeMoms & Healofy scroll wheels)
  // ══════════════════════════════════════════════════════════
  Widget _datePickerStep() {
    final isLastPeriod = _calcMethod == 'lastPeriod';
    final title = isLastPeriod
        ? 'متى كان تاريخ\nآخر دورة شهرية؟'
        : 'ما هو تاريخ\nالولادة المتوقع؟';

    final now = DateTime.now();
    final minDate =
        isLastPeriod ? now.subtract(const Duration(days: 300)) : now;
    final maxDate =
        isLastPeriod ? now : now.add(const Duration(days: 300));

    // Ensure _selectedDate is within range
    DateTime initial = _selectedDate;
    if (initial.isBefore(minDate) || initial.isAfter(maxDate)) {
      initial = isLastPeriod
          ? now.subtract(const Duration(days: 90))
          : now.add(const Duration(days: 180));
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        _backButton(),
        _progressBar(),
        const SizedBox(height: 40),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _dark,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _pinkLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLastPeriod ? '🤰 أنا حامل' : '👶 تاريخ الولادة',
                style: const TextStyle(fontSize: 14, color: _pink),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _goBack,
                child: const Text(
                  'تغيير',
                  style: TextStyle(
                    fontSize: 13,
                    color: _pink,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 220,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: initial,
            minimumDate: minDate,
            maximumDate: maxDate,
            onDateTimeChanged: (d) => setState(() => _selectedDate = d),
          ),
        ),
        const Spacer(),
        _primaryButton(text: 'التالي', onPressed: _goNext),
        const SizedBox(height: 30),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 4 — WEEKS PICKER (like WeMoms "De combien de semaines")
  // ══════════════════════════════════════════════════════════
  Widget _weeksPickerStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _backButton(),
        _progressBar(),
        const SizedBox(height: 40),
        const Text(
          'كم أسبوع من الحمل؟',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'اختاري عدد الأسابيع والأيام',
          style: TextStyle(fontSize: 15, color: _sub),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Weeks
            Column(
              children: [
                const Text('أسابيع',
                    style: TextStyle(
                        fontSize: 16,
                        color: _sub,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  width: 100,
                  height: 180,
                  child: CupertinoPicker(
                    itemExtent: 50,
                    scrollController: FixedExtentScrollController(
                        initialItem: _selectedWeeks),
                    onSelectedItemChanged: (i) =>
                        setState(() => _selectedWeeks = i),
                    children: List.generate(
                        43,
                        (i) => Center(
                            child: Text('$i',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)))),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 40),
            // Days
            Column(
              children: [
                const Text('أيام',
                    style: TextStyle(
                        fontSize: 16,
                        color: _sub,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                SizedBox(
                  width: 100,
                  height: 180,
                  child: CupertinoPicker(
                    itemExtent: 50,
                    scrollController: FixedExtentScrollController(
                        initialItem: _selectedDays),
                    onSelectedItemChanged: (i) =>
                        setState(() => _selectedDays = i),
                    children: List.generate(
                        7,
                        (i) => Center(
                            child: Text('$i',
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)))),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _primaryButton(
          text: 'التالي',
          onPressed: _selectedWeeks > 0 || _selectedDays > 0 ? _goNext : null,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 5 — NAME (like WeMoms "Comment t'appelles-tu?")
  // ══════════════════════════════════════════════════════════
  Widget _nameStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _backButton(),
        _progressBar(),
        const SizedBox(height: 60),
        const Text(
          'ما اسمك؟',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'سنستخدمه لتخصيص تجربتك',
          style: TextStyle(fontSize: 15, color: _sub),
        ),
        const SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'الاسم الأول',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const Spacer(),
        _primaryButton(
          text: 'التالي',
          onPressed:
              _nameController.text.trim().isNotEmpty ? _goNext : null,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  STEP 6 — TERMS & PRIVACY
  // ══════════════════════════════════════════════════════════
  Widget _termsStep() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _backButton(),
        _progressBar(),
        const Spacer(),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _teal.withValues(alpha: 0.1),
          ),
          child: const Icon(Icons.verified_user, size: 40, color: _teal),
        ),
        const SizedBox(height: 24),
        const Text(
          'الموافقة على السياسات',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            'لاستخدام نبضة، يرجى قراءة والموافقة على السياسات التالية',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: _sub),
          ),
        ),
        const SizedBox(height: 40),
        _policyCheckbox(
          title: 'شروط الاستخدام',
          checked: _termsAccepted,
          onChanged: (v) => setState(() => _termsAccepted = v ?? false),
          onTapLink: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
          ),
        ),
        const SizedBox(height: 16),
        _policyCheckbox(
          title: 'سياسة الخصوصية',
          checked: _privacyAccepted,
          onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
          onTapLink: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
          ),
        ),
        const Spacer(),
        if (_saving)
          const CircularProgressIndicator(color: _pink)
        else
          _primaryButton(
            text: 'ابدأي استخدام نبضة',
            onPressed: _termsAccepted && _privacyAccepted
                ? _finishOnboarding
                : null,
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _policyCheckbox({
    required String title,
    required bool checked,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onTapLink,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: checked ? _teal : Colors.grey.shade200,
          width: checked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: checked,
              onChanged: onChanged,
              activeColor: _teal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const Text(
                  'أوافق على ',
                  style: TextStyle(fontSize: 15, color: _dark),
                ),
                GestureDetector(
                  onTap: onTapLink,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _pink,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTapLink,
            child: const Icon(Icons.open_in_new, color: _pink, size: 20),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TERMS OF SERVICE PAGE
// ══════════════════════════════════════════════════════════════
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),
      appBar: AppBar(
        title: const Text('شروط الاستخدام'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('1. مقدمة'),
            _SectionBody(
              'مرحباً بكِ في تطبيق "نبضة". باستخدامك لهذا التطبيق، فإنكِ توافقين على الالتزام بهذه الشروط والأحكام. يرجى قراءتها بعناية قبل استخدام التطبيق. إذا كنتِ لا توافقين على هذه الشروط، يرجى عدم استخدام التطبيق.',
            ),
            _SectionTitle('2. وصف الخدمة'),
            _SectionBody(
              'نبضة هو تطبيق صحي مخصص للمرأة يوفر أدوات لمتابعة الحمل أسبوعاً بأسبوع، تتبع الدورة الشهرية، متابعة صحة الطفل، مجتمع تفاعلي للأمهات، محتوى تثقيفي صحي، ومتجر لمستلزمات الأمومة والطفولة. جميع المعلومات الطبية المقدمة هي لأغراض تثقيفية فقط ولا تغني عن استشارة الطبيب المختص.',
            ),
            _SectionTitle('3. أهلية الاستخدام'),
            _SectionBody(
              'يجب أن يكون عمرك 16 سنة على الأقل لاستخدام هذا التطبيق. باستخدامك للتطبيق، فإنكِ تؤكدين أنك تستوفين هذا الشرط. إذا كنتِ تحت 18 سنة، يجب الحصول على موافقة ولي الأمر.',
            ),
            _SectionTitle('4. الحساب والتسجيل'),
            _SectionBody(
              'عند إنشاء حساب في نبضة:\n'
              '• أنتِ مسؤولة عن الحفاظ على سرية بيانات تسجيل الدخول الخاصة بكِ.\n'
              '• يجب تقديم معلومات صحيحة ودقيقة عند التسجيل.\n'
              '• أنتِ مسؤولة عن جميع الأنشطة التي تتم من خلال حسابك.\n'
              '• يحق لنا تعليق أو حذف حسابك في حالة مخالفة هذه الشروط.',
            ),
            _SectionTitle('5. الاستخدام المقبول'),
            _SectionBody(
              'عند استخدام نبضة، يجب عليكِ:\n'
              '• عدم نشر محتوى مسيء أو غير لائق في المجتمع.\n'
              '• عدم انتحال شخصية الآخرين أو تقديم معلومات مضللة.\n'
              '• عدم استخدام التطبيق لأغراض تجارية غير مصرح بها.\n'
              '• عدم محاولة اختراق أو التلاعب بالتطبيق.\n'
              '• احترام خصوصية المستخدمات الأخريات.',
            ),
            _SectionTitle('6. المحتوى الطبي'),
            _SectionBody(
              'المعلومات الطبية المقدمة في تطبيق نبضة هي لأغراض تثقيفية وتوعوية فقط ولا يمكن اعتبارها بديلاً عن الاستشارة الطبية المتخصصة. ننصح دائماً بمراجعة الطبيب المختص لأي قرارات طبية تتعلق بصحتك أو صحة طفلك.\n\n'
              'التطبيق لا يقدم تشخيصاً طبياً ولا يصف علاجاً. أي حاسبة أو أداة تتبع هي تقديرية وقد تختلف عن التقييم الطبي الفعلي.',
            ),
            _SectionTitle('7. المتجر والمشتريات'),
            _SectionBody(
              '• الأسعار المعروضة قابلة للتغيير دون إشعار مسبق.\n'
              '• نسعى لتقديم صور ووصف دقيق للمنتجات، لكن قد تختلف الألوان قليلاً.\n'
              '• سياسة الاسترجاع والاستبدال تنطبق وفقاً للشروط المحددة لكل منتج.\n'
              '• الدفع يتم بطرق آمنة ومعتمدة حسب البلد.',
            ),
            _SectionTitle('8. المجتمع والمحتوى المنشور'),
            _SectionBody(
              '• أنتِ مسؤولة عن المحتوى الذي تنشرينه في مجتمع نبضة.\n'
              '• نحتفظ بالحق في إزالة أي محتوى يخالف قواعد المجتمع.\n'
              '• يمنع نشر إعلانات أو روابط خارجية بدون إذن.\n'
              '• يجب احترام الرأي الآخر والتعامل بأدب مع جميع الأعضاء.',
            ),
            _SectionTitle('9. حقوق الملكية الفكرية'),
            _SectionBody(
              'جميع المحتويات والتصاميم والعلامات التجارية والشعارات في تطبيق نبضة هي ملكية حصرية للتطبيق أو مرخصة له. لا يجوز نسخ أو استخدام أو توزيع أي جزء من التطبيق دون إذن كتابي مسبق.',
            ),
            _SectionTitle('10. تحديد المسؤولية'),
            _SectionBody(
              'نبضة غير مسؤول عن:\n'
              '• أي ضرر ناتج عن الاعتماد على المعلومات الطبية المقدمة.\n'
              '• أي خسارة مالية من المشتريات عبر المتجر.\n'
              '• أي تفاعلات سلبية بين أعضاء المجتمع.\n'
              '• أي انقطاع أو أخطاء تقنية في الخدمة.',
            ),
            _SectionTitle('11. تعديل الشروط'),
            _SectionBody(
              'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بأي تغييرات جوهرية عبر التطبيق. استمرارك في استخدام التطبيق بعد التعديل يعتبر موافقة على الشروط الجديدة.',
            ),
            _SectionTitle('12. القانون المطبق'),
            _SectionBody(
              'تخضع هذه الشروط للقوانين المعمول بها في بلد إقامتك. في حالة وجود نزاع، يتم حله ودياً أولاً، وفي حالة عدم التوصل لحل، تختص المحاكم المحلية المختصة.',
            ),
            _SectionTitle('13. التواصل معنا'),
            _SectionBody(
              'لأي استفسارات أو ملاحظات حول شروط الاستخدام، يمكنك التواصل معنا عبر:\n'
              '• البريد الإلكتروني: support@nabda-app.com\n'
              '• صفحة "عن نبضة" داخل التطبيق',
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'آخر تحديث: مايو 2026',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PRIVACY POLICY PAGE
// ══════════════════════════════════════════════════════════════
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('1. مقدمة'),
            _SectionBody(
              'نحن في "نبضة" نقدّر خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح هذه السياسة كيف نجمع ونستخدم ونحمي معلوماتك عند استخدام تطبيقنا.',
            ),
            _SectionTitle('2. البيانات التي نجمعها'),
            _SectionBody(
              'عند استخدام نبضة، قد نجمع الأنواع التالية من البيانات:\n\n'
              'بيانات الحساب:\n'
              '• الاسم والبريد الإلكتروني عند التسجيل.\n'
              '• كلمة المرور (مشفّرة ولا يمكننا الاطلاع عليها).\n\n'
              'بيانات صحية:\n'
              '• تاريخ آخر دورة شهرية وبيانات الحمل.\n'
              '• سجلات الأعراض والمزاج.\n'
              '• قياسات الوزن وضغط الدم (إذا أدخلتها).\n'
              '• بيانات صحة الطفل (الوزن، الطول، التطعيمات).\n\n'
              'بيانات الاستخدام:\n'
              '• سجلات التفاعل مع التطبيق.\n'
              '• المحتوى المنشور في المجتمع.',
            ),
            _SectionTitle('3. كيف نستخدم بياناتك'),
            _SectionBody(
              'نستخدم بياناتك لـ:\n'
              '• تقديم خدمات التتبع الصحي المخصصة لكِ.\n'
              '• حساب أسبوع الحمل وتاريخ الولادة المتوقع.\n'
              '• تخصيص المحتوى والنصائح حسب مرحلتك.\n'
              '• تشغيل مجتمع الأمهات وعرض المنشورات.\n'
              '• معالجة طلبات المتجر وتوصيلها.\n'
              '• إرسال إشعارات مهمة ونصائح صحية.\n'
              '• تحسين أداء التطبيق وتجربة المستخدمة.',
            ),
            _SectionTitle('4. مشاركة البيانات'),
            _SectionBody(
              'نحن لا نبيع بياناتك الشخصية لأي طرف ثالث. قد نشارك بياناتك في الحالات التالية فقط:\n\n'
              '• مع مزودي الخدمات الضروريين لتشغيل التطبيق (Firebase من Google لتخزين البيانات).\n'
              '• مع شركات التوصيل لمعالجة طلبات المتجر (الاسم والعنوان فقط).\n'
              '• عندما يقتضي القانون ذلك أو بأمر من السلطات المختصة.\n\n'
              'المحتوى الذي تنشرينه في المجتمع يكون مرئياً للمستخدمات الأخريات حسب إعدادات الخصوصية.',
            ),
            _SectionTitle('5. حماية البيانات'),
            _SectionBody(
              'نتخذ إجراءات أمنية لحماية بياناتك:\n'
              '• تشفير البيانات أثناء النقل باستخدام بروتوكول HTTPS/TLS.\n'
              '• تخزين كلمات المرور بشكل مشفّر.\n'
              '• استخدام Firebase Security Rules للتحكم في الوصول.\n'
              '• لا نخزن بيانات بطاقات الدفع على خوادمنا.',
            ),
            _SectionTitle('6. حقوقك'),
            _SectionBody(
              'لديكِ الحقوق التالية فيما يتعلق ببياناتك الشخصية:\n'
              '• الوصول: يمكنكِ طلب نسخة من بياناتك.\n'
              '• التصحيح: يمكنكِ تعديل بياناتك من ملفك الشخصي.\n'
              '• الحذف: يمكنكِ طلب حذف حسابك وجميع بياناتك.\n'
              '• الاعتراض: يمكنكِ إلغاء الاشتراك في الإشعارات.\n\n'
              'لممارسة هذه الحقوق، تواصلي معنا عبر البريد الإلكتروني.',
            ),
            _SectionTitle('7. بيانات الأطفال'),
            _SectionBody(
              'البيانات المتعلقة بالأطفال (بيانات متابعة صحة الطفل) تُخزن في حساب الأم فقط ولا تُستخدم لأي غرض آخر غير تقديم خدمات المتابعة الصحية. نحن لا نجمع بيانات مباشرة من الأطفال.',
            ),
            _SectionTitle('8. ملفات تعريف الارتباط'),
            _SectionBody(
              'نستخدم تقنيات تخزين محلي لحفظ تفضيلاتك مثل:\n'
              '• اللغة المختارة.\n'
              '• حالة تسجيل الدخول.\n'
              '• إعدادات التطبيق.\n\n'
              'هذه البيانات تُخزن محلياً على جهازك فقط.',
            ),
            _SectionTitle('9. الخدمات الخارجية'),
            _SectionBody(
              'نستخدم خدمات خارجية موثوقة:\n'
              '• Firebase (Google): للمصادقة وتخزين البيانات.\n'
              '• Google Gemini AI: للدردشة الذكية (لا تُخزن المحادثات).\n'
              '• Exchange Rate API: لتحويل العملات (لا تُرسل بيانات شخصية).\n\n'
              'كل خدمة تخضع لسياسة خصوصيتها الخاصة.',
            ),
            _SectionTitle('10. التغييرات على السياسة'),
            _SectionBody(
              'قد نحدّث هذه السياسة من وقت لآخر. سنخطرك بأي تغييرات جوهرية عبر إشعار في التطبيق. ننصح بمراجعة هذه السياسة بشكل دوري.',
            ),
            _SectionTitle('11. التواصل معنا'),
            _SectionBody(
              'لأي أسئلة أو مخاوف حول خصوصيتك، تواصلي معنا:\n'
              '• البريد الإلكتروني: privacy@nabda-app.com\n'
              '• من خلال صفحة "عن نبضة" في التطبيق',
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'آخر تحديث: مايو 2026',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Shared section widgets ──
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00897B),
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.8,
        color: Color(0xFF4A434B),
      ),
    );
  }
}
