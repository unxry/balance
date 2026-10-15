import 'package:flutter/material.dart';

enum AppThemeMode { wellness, dark, system }

/// Design tokens ported 1:1 from the HTML/CSS design handoff.
class AppColors {
  final Color page;
  final Color stageA;
  final Color stageB;
  final Color surface;
  final Color card;
  final Color card2;
  final Color line;
  final Color line2;
  final Color fg;
  final Color fg2;
  final Color muted;
  final Color track;
  final Color accent; // forest green — do / lose
  final Color accent2; // tangerine — avoid / gain
  final Color accent3; // honey — carbs / warm secondary
  final Color macroCarb; // dusty teal — carbohydrate energy
  final Color bronze;
  final Color silver;
  final Color champagne;
  final Color accentSoft;
  final Color accent2Soft;
  final Brightness brightness;

  const AppColors({
    required this.page,
    required this.stageA,
    required this.stageB,
    required this.surface,
    required this.card,
    required this.card2,
    required this.line,
    required this.line2,
    required this.fg,
    required this.fg2,
    required this.muted,
    required this.track,
    required this.accent,
    required this.accent2,
    required this.accent3,
    required this.macroCarb,
    required this.bronze,
    required this.silver,
    required this.champagne,
    required this.accentSoft,
    required this.accent2Soft,
    required this.brightness,
  });

  static const wellness = AppColors(
    page: Color(0xFFECE4D3),
    stageA: Color(0xFFF0E8D7),
    stageB: Color(0xFFE5DCC5),
    surface: Color(0xFFF8F2E3),
    card: Color(0xFFFFFAEB),
    card2: Color(0xFFEEE5D0),
    line: Color(0xFFD9CFB6),
    line2: Color(0xFFC8BC9D),
    fg: Color(0xFF1C1A17),
    fg2: Color(0xFF3A352D),
    muted: Color(0xFF8A8272),
    track: Color(0xFFE2D8C1),
    accent: Color(0xFF4F7D3E),
    accent2: Color(0xFFD97A3E),
    accent3: Color(0xFFB8933A),
    macroCarb: Color(0xFF5F8981),
    bronze: Color(0xFFA87348),
    silver: Color(0xFFA7A59D),
    champagne: Color(0xFFD8BE79),
    accentSoft: Color(0xFFE8F0DD),
    accent2Soft: Color(0xFFF7E4D1),
    brightness: Brightness.light,
  );

  static const darkTheme = AppColors(
    page: Color(0xFF11130F),
    stageA: Color(0xFF1A1D17),
    stageB: Color(0xFF0D0F0C),
    surface: Color(0xFF171A15),
    card: Color(0xFF20231D),
    card2: Color(0xFF292C25),
    line: Color(0xFF34382F),
    line2: Color(0xFF484D41),
    fg: Color(0xFFF2EAD6),
    fg2: Color(0xFFD4CBB2),
    muted: Color(0xFF8A8272),
    track: Color(0xFF2A2620),
    accent: Color(0xFFB8D67A),
    accent2: Color(0xFFEBA86A),
    accent3: Color(0xFFDCC47A),
    macroCarb: Color(0xFF79A9A0),
    bronze: Color(0xFFC48759),
    silver: Color(0xFFB8B8AE),
    champagne: Color(0xFFE0C985),
    accentSoft: Color(0xFF2C3520),
    accent2Soft: Color(0xFF3A2C1E),
    brightness: Brightness.dark,
  );

  /// A deliberately neutral platform palette. System mode follows the device
  /// brightness without becoming a second name for the branded Wellness/Dark
  /// themes.
  static const systemLight = AppColors(
    page: Color(0xFFECE9E1),
    stageA: Color(0xFFF5F2EB),
    stageB: Color(0xFFE3E0D8),
    surface: Color(0xFFF8F6F0),
    card: Color(0xFFFDFBF6),
    card2: Color(0xFFEFEBE3),
    line: Color(0xFFDDD7CC),
    line2: Color(0xFFC8C1B5),
    fg: Color(0xFF23241F),
    fg2: Color(0xFF45463F),
    muted: Color(0xFF7D796F),
    track: Color(0xFFE4DFD5),
    accent: Color(0xFF58745F),
    accent2: Color(0xFFB87348),
    accent3: Color(0xFFA38645),
    macroCarb: Color(0xFF5E817C),
    bronze: Color(0xFF9D704D),
    silver: Color(0xFFA4A8A3),
    champagne: Color(0xFFC9B376),
    accentSoft: Color(0xFFE3EBE1),
    accent2Soft: Color(0xFFF2E4D9),
    brightness: Brightness.light,
  );

  static const systemDark = AppColors(
    page: Color(0xFF111312),
    stageA: Color(0xFF1B1E1C),
    stageB: Color(0xFF0C0E0D),
    surface: Color(0xFF171A18),
    card: Color(0xFF212522),
    card2: Color(0xFF2A2F2B),
    line: Color(0xFF373D38),
    line2: Color(0xFF4C544D),
    fg: Color(0xFFF0F2ED),
    fg2: Color(0xFFD0D5CE),
    muted: Color(0xFF90978F),
    track: Color(0xFF2B302C),
    accent: Color(0xFF9FC5A5),
    accent2: Color(0xFFE3A174),
    accent3: Color(0xFFD4BE7D),
    macroCarb: Color(0xFF83AAA5),
    bronze: Color(0xFFC18B64),
    silver: Color(0xFFB5BAB4),
    champagne: Color(0xFFDDC987),
    accentSoft: Color(0xFF27342A),
    accent2Soft: Color(0xFF392C24),
    brightness: Brightness.dark,
  );

  static AppColors of(
    AppThemeMode mode, {
    Brightness platformBrightness = Brightness.light,
  }) {
    switch (mode) {
      case AppThemeMode.wellness:
        return wellness;
      case AppThemeMode.dark:
        return darkTheme;
      case AppThemeMode.system:
        return platformBrightness == Brightness.dark ? systemDark : systemLight;
    }
  }
}
