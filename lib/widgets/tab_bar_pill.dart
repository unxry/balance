import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import 'common.dart';

abstract final class BalanceRootMetrics {
  static const navigationHeight = 64.0;
  static const navigationBottomMargin = 10.0;

  static double contentBottomInset(
    BuildContext context, {
    double breathingRoom = 20,
  }) =>
      navigationHeight +
      navigationBottomMargin +
      MediaQuery.paddingOf(context).bottom +
      breathingRoom;
}

enum AppTab { home, weight, diary, profile }

/// One frosted surface whose glass lens tracks the root PageView continuously.
class TabBarPill extends StatelessWidget {
  final int selectedIndex;
  final PageController controller;
  final ValueChanged<AppTab> onTap;
  final AppLang lang;

  const TabBarPill({
    super.key,
    required this.selectedIndex,
    required this.controller,
    required this.onTap,
    this.lang = AppLang.ru,
  });

  static const _tabs = <(AppTab, IconData)>[
    (AppTab.home, Icons.home_rounded),
    (AppTab.weight, Icons.show_chart_rounded),
    (AppTab.diary, Icons.menu_book_rounded),
    (AppTab.profile, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: c.fg.withValues(alpha: .10),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SizedBox(
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    key: const ValueKey('balanceGlassNavigation'),
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: c.brightness == Brightness.dark
                                  ? [
                                      c.card,
                                      Color.alphaBlend(
                                        c.accent.withValues(alpha: .06),
                                        c.surface,
                                      ),
                                      Color.alphaBlend(
                                        c.accent.withValues(alpha: .10),
                                        c.surface,
                                      ),
                                    ]
                                  : [
                                      Colors.white,
                                      c.card,
                                      Color.alphaBlend(
                                        c.accent.withValues(alpha: .05),
                                        c.card,
                                      ),
                                    ],
                              stops: const [0, .58, 1],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: c.brightness == Brightness.dark
                                  ? c.fg.withValues(alpha: .13)
                                  : Colors.white.withValues(alpha: .36),
                              width: .8,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 20,
                            margin: const EdgeInsets.fromLTRB(12, 1, 12, 0),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: c.brightness == Brightness.dark
                                        ? .10
                                        : .30,
                                  ),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final page = _page.clamp(0.0, _tabs.length - 1.0);
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          const diameter = 50.0;
                          final slot = constraints.maxWidth / _tabs.length;
                          final fraction = page - page.floor();
                          final stretch = reduceMotion
                              ? 0.0
                              : math.sin(fraction * math.pi).clamp(0.0, 1.0);
                          final lensWidth = diameter + slot * .76 * stretch;
                          final direction = (selectedIndex - page).sign;
                          final leadingBias = direction * slot * .045 * stretch;
                          final center = slot * page + slot / 2 + leadingBias;
                          return Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              Positioned(
                                key: const ValueKey('balanceGlassIndicator'),
                                left: center - lensWidth / 2,
                                top: 7,
                                width: lensWidth,
                                height: diameter,
                                child: _GlassLens(
                                  colors: c,
                                  reflectionPhase: Curves.easeInOutCubic
                                      .transform(fraction),
                                  stretch: stretch,
                                ),
                              ),
                              Row(
                                children: [
                                  for (
                                    var index = 0;
                                    index < _tabs.length;
                                    index++
                                  )
                                    Expanded(
                                      child: _item(
                                        context,
                                        index,
                                        page,
                                        _tabs[index].$1,
                                        _tabs[index].$2,
                                        reduceMotion,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double get _page {
    if (!controller.hasClients) return selectedIndex.toDouble();
    return controller.page ?? selectedIndex.toDouble();
  }

  Widget _item(
    BuildContext context,
    int index,
    double page,
    AppTab tab,
    IconData icon,
    bool reduceMotion,
  ) {
    final c = context.colors;
    final proximity = (1 - (page - index).abs()).clamp(0.0, 1.0);
    final selected = index == selectedIndex;
    return Semantics(
      button: true,
      selected: selected,
      label: _label(tab),
      child: ExcludeSemantics(
        child: GestureDetector(
          key: ValueKey('rootTab-${tab.name}'),
          onTap: () => onTap(tab),
          behavior: HitTestBehavior.opaque,
          child: SizedBox.expand(
            child: Center(
              child: Transform.scale(
                scale: reduceMotion ? 1 : 1 + .035 * proximity,
                child: Icon(
                  icon,
                  size: 23,
                  color: Color.lerp(c.muted, c.fg, proximity),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _label(AppTab tab) => switch ((lang, tab)) {
    (AppLang.ru, AppTab.home) => 'Главная',
    (AppLang.ru, AppTab.weight) => 'Вес',
    (AppLang.ru, AppTab.diary) => 'Дневник',
    (AppLang.ru, AppTab.profile) => 'Профиль',
    (AppLang.en, AppTab.home) => 'Home',
    (AppLang.en, AppTab.weight) => 'Weight',
    (AppLang.en, AppTab.diary) => 'Diary',
    (AppLang.en, AppTab.profile) => 'Profile',
  };
}

class _GlassLens extends StatelessWidget {
  const _GlassLens({
    required this.colors,
    required this.reflectionPhase,
    required this.stretch,
  });

  final AppColors colors;
  final double reflectionPhase;
  final double stretch;

  @override
  Widget build(BuildContext context) {
    final dark = colors.brightness == Brightness.dark;
    return DecoratedBox(
      key: const ValueKey('balanceGlassLensSurface'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: dark
              ? colors.fg.withValues(alpha: .22)
              : Colors.white.withValues(alpha: .48),
          width: .75,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  colors.fg.withValues(alpha: .18),
                  colors.card.withValues(alpha: .54),
                  colors.accent.withValues(alpha: .12),
                ]
              : [
                  Colors.white.withValues(alpha: .68),
                  colors.card.withValues(alpha: .42),
                  colors.accentSoft.withValues(alpha: .34),
                ],
          stops: const [0, .52, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: .24)
                : colors.fg.withValues(alpha: .11),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: colors.accent.withValues(alpha: dark ? .08 : .10),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: const Alignment(-.38, -.55),
              child: FractionallySizedBox(
                widthFactor: .64 + .18 * stretch,
                heightFactor: .42,
                child: DecoratedBox(
                  key: const ValueKey('balanceGlassLensHighlight'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: .9,
                      colors: [
                        Colors.white.withValues(alpha: dark ? .24 : .58),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -18 + reflectionPhase * 68,
              top: -10,
              bottom: -10,
              child: Transform.rotate(
                angle: -.32,
                child: Container(
                  width: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: dark ? .14 : .34),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: .07)
                      : colors.card.withValues(alpha: .44),
                  width: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
