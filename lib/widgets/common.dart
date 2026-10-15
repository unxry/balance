import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Small monospace uppercase label, used pervasively in the design
/// ("ШАГИ", "СЕГОДНЯ" etc).
class MonoLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double size;
  const MonoLabel(this.text, {super.key, this.color, this.size = 10});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      text.toUpperCase(),
      style: AppText(c).mono(size: size, color: color),
    );
  }
}

class GhostBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const GhostBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.card,
            border: Border.all(color: c.line),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: c.fg),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final EdgeInsets padding;
  final double fontSize;
  final FontWeight weight;
  final bool mono;
  const Pill({
    super.key,
    required this.text,
    required this.bg,
    required this.fg,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.fontSize = 11,
    this.weight = FontWeight.w600,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: mono ? 'JetBrainsMono' : 'Inter',
          fontSize: fontSize,
          fontWeight: weight,
          color: fg,
          letterSpacing: mono ? fontSize * 0.1 : 0,
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.line.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}

class BalanceGlassCard extends StatelessWidget {
  const BalanceGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.minHeight = 116,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = c.brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);
    final base = Color.lerp(c.card, c.card2, dark ? .16 : .11)!;
    return RepaintBoundary(
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: c.line.withValues(alpha: dark ? .82 : .68),
            width: .8,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(base, Colors.white, dark ? .025 : .11)!,
              base,
              Color.lerp(base, c.card2, dark ? .18 : .12)!,
            ],
            stops: const [0, .58, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .2 : .045),
              blurRadius: dark ? 15 : 13,
              offset: const Offset(0, 5),
            ),
            if (!dark)
              BoxShadow(
                color: c.bronze.withValues(alpha: .025),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
          ],
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: Padding(padding: padding, child: child),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: dark ? .055 : .25),
                      width: .65,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: dark ? .035 : .075),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0, .32, 1],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final Uint8List? imageBytes;
  final String fallbackLetter;
  final double size;
  final Widget? badge;

  const ProfileAvatar({
    super.key,
    required this.imageBytes,
    required this.fallbackLetter,
    required this.size,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [c.accent, c.accent2]),
              border: Border.all(color: c.card, width: 2),
            ),
            child: imageBytes == null
                ? Text(
                    fallbackLetter,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: size * 0.34,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: SizedBox.expand(
                        child: Transform.scale(
                          scale: 1.08,
                          child: Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          if (badge != null) Positioned(right: -2, bottom: -2, child: badge!),
        ],
      ),
    );
  }
}

class LabeledNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool autofocus;
  final bool integerOnly;
  final ValueChanged<String>? onSubmitted;

  const LabeledNumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.unit,
    this.onChanged,
    this.errorText,
    this.autofocus = false,
    this.integerOnly = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.inter(size: 12, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: TextInputType.numberWithOptions(decimal: !integerOnly),
          inputFormatters: integerOnly
              ? [
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) =>
                        RegExp(r'^\d*$').hasMatch(newValue.text)
                        ? newValue
                        : oldValue,
                  ),
                ]
              : null,
          textInputAction: TextInputAction.done,
          onSubmitted:
              onSubmitted ??
              (_) => FocusManager.instance.primaryFocus?.unfocus(),
          textAlign: TextAlign.left,
          onChanged: onChanged,
          style: t.inter(size: 15, weight: FontWeight.w600),
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: t.inter(size: 13, color: c.muted),
            errorText: errorText,
            filled: true,
            fillColor: c.card2,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.line.withValues(alpha: 0.45)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.accent, width: 1.3),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.accent2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: c.accent2, width: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}

class PortionPresetRow extends StatelessWidget {
  final List<int> values;
  final int selected;
  final String unit;
  final ValueChanged<int> onSelected;

  const PortionPresetRow({
    super.key,
    required this.values,
    required this.selected,
    required this.unit,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    return Row(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: () => onSelected(values[index]),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == values[index] ? c.accentSoft : c.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == values[index]
                        ? c.accent
                        : Colors.transparent,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${values[index]} $unit',
                    style: t.mono(
                      size: 9,
                      color: selected == values[index] ? c.accent : c.fg,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final double height;
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: height,
      child: Material(
        color: c.fg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.surface,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accent,
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience extension so widgets can read the current theme colors with
/// `context.colors` (wired via InheritedWidget in main.dart).
extension AppColorsContext on BuildContext {
  AppColors get colors => AppColorsScope.of(this);
}

class AppColorsScope extends InheritedWidget {
  final AppColors colors;
  const AppColorsScope({super.key, required this.colors, required super.child});

  static AppColors of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppColorsScope>();
    return scope?.colors ?? AppColors.wellness;
  }

  @override
  bool updateShouldNotify(AppColorsScope oldWidget) =>
      oldWidget.colors != colors;
}
