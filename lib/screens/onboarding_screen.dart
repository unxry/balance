import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_data_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../widgets/common.dart';
import 'legal_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  final UserProfile? initialProfile;
  const OnboardingScreen({
    super.key,
    required this.onDone,
    this.initialProfile,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step =
      0; // 0..5 => steps 1..6 (name, gender, age, height/weight, goal, summary)
  final TextEditingController nameController = TextEditingController();
  String? nameError;
  Gender gender = Gender.female;
  int age = 28;
  double height = 168;
  double weight = 67;
  ActivityLevel activityLevel = ActivityLevel.light;
  Goal goal = Goal.lose;
  bool acceptedLegal = false;
  String? legalError;

  static const totalSteps = 6;

  bool get _editing => widget.initialProfile != null;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    if (profile != null) {
      nameController.text = profile.name;
      gender = profile.gender;
      age = profile.age;
      height = profile.heightCm;
      weight = profile.weightKg;
      activityLevel = profile.activityLevel;
      goal = profile.goal;
      acceptedLegal = true;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final lang = context.watch<SettingsProvider>().lang;
    final s = S(lang);
    final t = AppText(c);

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(c, t),
              const SizedBox(height: 24),
              Text(
                s.obTitle,
                style: t.fraunces(
                  size: 34,
                  weight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(s.obSub, style: t.inter(size: 13, color: c.muted)),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(child: _buildStepContent(c, t, s)),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                key: const ValueKey('onboardingContinue'),
                label: _editing && step == totalSteps - 1
                    ? (s.isRu ? 'Сохранить' : 'Save')
                    : s.continueLbl,
                onTap: _onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic c, AppText t) {
    return Row(
      children: [
        GhostBackButton(
          onTap: () {
            if (step > 0) {
              setState(() => step--);
            } else if (_editing) {
              Navigator.of(context).maybePop();
            }
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(step + 1).toString().padLeft(2, '0')} / 0$totalSteps',
                style: t.mono(size: 11),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (step + 1) / totalSteps,
                  minHeight: 4,
                  backgroundColor: c.track,
                  valueColor: AlwaysStoppedAnimation(c.accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onNext() async {
    FocusScope.of(context).unfocus();
    if (step == 0) {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        setState(
          () => nameError = S(
            context.read<SettingsProvider>().lang,
          ).nameEmptyError,
        );
        return;
      }
      setState(() {
        nameError = null;
        step++;
      });
      return;
    }
    if (step < totalSteps - 1) {
      setState(() => step++);
      return;
    }
    if (!acceptedLegal) {
      setState(
        () => legalError = S(
          context.read<SettingsProvider>().lang,
        ).mustAcceptLegal,
      );
      return;
    }
    final data = context.read<AppDataProvider>();
    final previous = widget.initialProfile;
    final profile = UserProfile(
      gender: gender,
      age: age,
      heightCm: height,
      weightKg: weight,
      activityLevel: activityLevel,
      goal: goal,
      targetWeightKg: previous != null && previous.goal == goal
          ? previous.targetWeightKg
          : goal == Goal.lose
          ? weight - 7
          : goal == Goal.gain
          ? weight + 5
          : weight,
      calorieGoalMode: previous?.calorieGoalMode ?? CalorieGoalMode.auto,
      manualCalories: previous?.manualCalories,
      name: nameController.text.trim(),
      avatarBytes: previous?.avatarBytes,
      joinedAt: previous?.joinedAt,
      onboarded: true,
    );
    await data.updateProfile(profile);
    if (previous != null && (previous.weightKg - weight).abs() >= .05) {
      await data.addWeightEntry(weight);
    }
    widget.onDone();
  }

  Widget _buildStepContent(dynamic c, AppText t, S s) {
    switch (step) {
      case 0:
        return _nameStep(c, t, s);
      case 1:
        return _genderStep(c, t, s);
      case 2:
        return _ageStep(c, t, s);
      case 3:
        return _heightWeightStep(c, t, s);
      case 4:
        return _goalStep(c, t, s);
      default:
        return _summaryStep(c, t, s);
    }
  }

  Widget _nameStep(dynamic c, AppText t, S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel(s.obName),
        const SizedBox(height: 10),
        Text(s.obNameHint, style: t.inter(size: 13, color: c.muted)),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey('onboardingName'),
          controller: nameController,
          maxLength: 80,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) {
            if (nameError != null) setState(() => nameError = null);
          },
          style: t.fraunces(size: 22, weight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: s.obNamePh,
            hintStyle: t.fraunces(
              size: 22,
              weight: FontWeight.w700,
              color: c.muted,
            ),
            filled: true,
            fillColor: c.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: c.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: c.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: c.accent, width: 1.5),
            ),
            errorText: nameError,
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _genderStep(dynamic c, AppText t, S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel(s.obGender),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _pillChoice(
                c,
                t,
                s.genderF,
                gender == Gender.female,
                () => setState(() => gender = Gender.female),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _pillChoice(
                c,
                t,
                s.genderM,
                gender == Gender.male,
                () => setState(() => gender = Gender.male),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        MonoLabel(s.isRu ? 'УРОВЕНЬ АКТИВНОСТИ' : 'ACTIVITY LEVEL'),
        const SizedBox(height: 8),
        ...[
          (
            ActivityLevel.sedentary,
            s.isRu ? 'Малоподвижный' : 'Sedentary',
            s.isRu
                ? 'Без регулярных тренировок'
                : 'Little or no regular exercise',
          ),
          (
            ActivityLevel.light,
            s.isRu ? 'Лёгкий' : 'Light',
            s.isRu ? '1–3 тренировки в неделю' : 'Exercise 1–3 days a week',
          ),
          (
            ActivityLevel.moderate,
            s.isRu ? 'Средний' : 'Moderate',
            s.isRu ? '3–5 тренировок в неделю' : 'Exercise 3–5 days a week',
          ),
          (
            ActivityLevel.active,
            s.isRu ? 'Высокий' : 'Active',
            s.isRu ? '6–7 тренировок в неделю' : 'Exercise 6–7 days a week',
          ),
        ].map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _activityChoice(c, t, item.$1, item.$2, item.$3),
          ),
        ),
      ],
    );
  }

  Widget _activityChoice(
    dynamic c,
    AppText t,
    ActivityLevel value,
    String title,
    String subtitle,
  ) {
    final selected = activityLevel == value;
    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $subtitle',
      child: InkWell(
        onTap: () => setState(() => activityLevel = value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? c.accent : c.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.inter(size: 13, weight: FontWeight.w700),
                    ),
                    Text(subtitle, style: t.inter(size: 11, color: c.muted)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? c.accent : c.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillChoice(
    dynamic c,
    AppText t,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? c.fg : c.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? c.fg : c.line),
        ),
        child: Text(
          label,
          style: t.inter(
            size: 14,
            weight: FontWeight.w700,
            color: active ? c.surface : c.fg,
          ),
        ),
      ),
    );
  }

  Widget _ageStep(dynamic c, AppText t, S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel(s.obAge),
        const SizedBox(height: 6),
        Text(
          '$age ${s.years}',
          style: t.fraunces(size: 32, weight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: c.accent,
            inactiveTrackColor: c.track,
            thumbColor: Colors.white,
            overlayColor: c.accent.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
          ),
          child: Slider(
            value: age.toDouble(),
            min: 16,
            max: 80,
            onChanged: (v) => setState(() => age = v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            '18',
            '30',
            '45',
            '60',
            '75+',
          ].map((e) => Text(e, style: t.mono(size: 10))).toList(),
        ),
      ],
    );
  }

  Widget _heightWeightStep(dynamic c, AppText t, S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _numberCard(
                c,
                t,
                s.obHeight,
                height,
                'cm',
                (v) => setState(() => height = v),
                120,
                220,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _numberCard(
                c,
                t,
                s.obWeight,
                weight,
                'kg',
                (v) => setState(() => weight = v),
                35,
                180,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberCard(
    dynamic c,
    AppText t,
    String label,
    double value,
    String unit,
    ValueChanged<double> onChanged,
    double min,
    double max,
  ) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonoLabel(label),
          const SizedBox(height: 6),
          Text(
            '${value.round()} $unit',
            style: t.fraunces(size: 30, weight: FontWeight.w800),
          ),
          Row(
            children: [
              _stepBtn(
                c,
                Icons.remove,
                () => onChanged((value - 1).clamp(min, max)),
              ),
              const SizedBox(width: 8),
              _stepBtn(
                c,
                Icons.add,
                () => onChanged((value + 1).clamp(min, max)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(dynamic c, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.card2),
        child: Icon(icon, size: 16, color: c.fg),
      ),
    );
  }

  Widget _goalStep(dynamic c, AppText t, S s) {
    final goals = [
      (Goal.lose, s.goalLose, '↓', '−7 kg'),
      (Goal.hold, s.goalHold, '–', '${weight.round()} kg'),
      (Goal.gain, s.goalGain, '↑', '+5 kg'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MonoLabel(s.obGoal),
        const SizedBox(height: 10),
        Row(
          children: goals.map((g) {
            final active = goal == g.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => setState(() => goal = g.$1),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active ? c.accentSoft : c.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: active ? c.accent : c.line),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.card2,
                          ),
                          child: Text(
                            g.$3,
                            style: t.fraunces(
                              size: 20,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          g.$2,
                          style: t.inter(size: 12, weight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        Text(g.$4, style: t.mono(size: 9)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _summaryStep(dynamic c, AppText t, S s) {
    final tmpProfile = UserProfile(
      gender: gender,
      age: age,
      heightCm: height,
      weightKg: weight,
      activityLevel: activityLevel,
      goal: goal,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          radius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MonoLabel(s.isRu ? 'ТВОЯ НОРМА' : 'YOUR TARGET'),
              const SizedBox(height: 8),
              Text(
                '${tmpProfile.calorieTarget} ${s.kcalLbl}',
                style: t.fraunces(size: 40, weight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _macroChip(
                    c,
                    t,
                    s.isRu ? 'Б' : 'P',
                    '${tmpProfile.proteinTargetG} ${s.isRu ? "г" : "g"}',
                    c.accent,
                  ),
                  const SizedBox(width: 10),
                  _macroChip(
                    c,
                    t,
                    s.isRu ? 'Ж' : 'F',
                    '${tmpProfile.fatTargetG} ${s.isRu ? "г" : "g"}',
                    c.accent2,
                  ),
                  const SizedBox(width: 10),
                  _macroChip(
                    c,
                    t,
                    s.isRu ? 'У' : 'C',
                    '${tmpProfile.carbTargetG} ${s.isRu ? "г" : "g"}',
                    c.accent3,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_editing) _legalConsentRow(c, t, s),
        if (legalError != null) ...[
          const SizedBox(height: 6),
          Text(legalError!, style: t.inter(size: 11, color: Colors.redAccent)),
        ],
      ],
    );
  }

  Widget _legalConsentRow(dynamic c, AppText t, S s) {
    return InkWell(
      key: const ValueKey('legalConsent'),
      onTap: () => setState(() {
        acceptedLegal = !acceptedLegal;
        if (acceptedLegal) legalError = null;
      }),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              key: const ValueKey('legalConsentToggle'),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: acceptedLegal ? c.accent : Colors.transparent,
                border: Border.all(
                  color: acceptedLegal ? c.accent : c.line,
                  width: 1.5,
                ),
              ),
              child: acceptedLegal
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: t.inter(size: 12, color: c.muted, height: 1.4),
                children: [
                  TextSpan(text: s.agreeToLegalPrefix),
                  TextSpan(
                    text: s.termsOfServiceAgreement,
                    style: TextStyle(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openLegal(LegalDoc.terms),
                  ),
                  TextSpan(text: s.legalAnd),
                  TextSpan(
                    text: s.privacyPolicyAgreement,
                    style: TextStyle(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _openLegal(LegalDoc.privacy),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLegal(LegalDoc doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LegalScreen(doc: doc, onBack: () => Navigator.of(context).pop()),
      ),
    );
  }

  Widget _macroChip(
    dynamic c,
    AppText t,
    String letter,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            letter,
            style: t.mono(size: 11, color: color, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(value, style: t.fraunces(size: 16, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
