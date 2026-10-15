import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/balance_support_config.dart';
import '../providers/settings_provider.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../widgets/common.dart';

enum LegalDoc { privacy, terms }

/// Displays bundled legal text without loading a remote page or adding a
/// WebView dependency.
class LegalScreen extends StatelessWidget {
  final LegalDoc doc;
  final VoidCallback onBack;
  final Uri? supportUri;
  final Future<bool> Function(Uri uri)? supportLauncher;
  const LegalScreen({
    super.key,
    required this.doc,
    required this.onBack,
    this.supportUri,
    this.supportLauncher,
  });

  static const _contactNoticeRu =
      'По вопросам конфиденциальности и работы приложения используйте действие «Поддержка» ниже.';
  static const _contactNoticeEn =
      'For privacy and app support requests, use the Support action below.';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final lang = context.watch<SettingsProvider>().lang;
    final s = S(lang);
    final isPrivacy = doc == LegalDoc.privacy;

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GhostBackButton(onTap: onBack),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPrivacy ? s.privacyPolicy : s.termsOfService,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.fraunces(size: 20, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: SectionCard(
                    radius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: isPrivacy
                          ? _privacyBody(context, c, t, s)
                          : _termsBody(context, c, t, s),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _h(AppText t, String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(text, style: t.inter(size: 14, weight: FontWeight.w800)),
  );

  Widget _p(dynamic c, AppText t, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: t.inter(size: 13, color: c.muted, height: 1.5)),
  );

  List<Widget> _privacyBody(BuildContext context, dynamic c, AppText t, S s) {
    final ru = s.isRu;
    return [
      Text(s.updatedOn, style: t.mono(size: 9, color: c.muted)),
      const SizedBox(height: 10),
      _p(
        c,
        t,
        ru
            ? 'Balance — приложение для учёта питания и веса. Мы уважаем вашу конфиденциальность и собираем только те данные, которые нужны для работы приложения.'
            : 'Balance is a nutrition and weight tracking app. We respect your privacy and only collect data that is necessary for the app to function.',
      ),
      _h(t, ru ? '1. Какие данные мы собираем' : '1. What data we collect'),
      _p(
        c,
        t,
        ru
            ? '• Профиль (имя, фото, пол, возраст, рост, вес, цель) и дневник питания хранятся локально в контейнере приложения.\n• С вашего разрешения Balance читает количество шагов за текущий день из Apple Health.'
            : '• Your profile (name, photo, gender, age, height, weight, and goal) and food diary are stored locally in the app container.\n• With your permission, Balance reads the current day\'s step count from Apple Health.',
      ),
      _h(t, ru ? '2. Как используются данные' : '2. How data is used'),
      _p(
        c,
        t,
        ru
            ? 'Профиль, фото профиля, дневник и шаги используются только для отображения и расчётов внутри приложения. Эти данные не отправляются на сервер.'
            : 'Your profile, profile photo, diary, and steps are used only for in-app display and calculations. This data is not sent to a server.',
      ),
      _h(t, ru ? '3. Галерея' : '3. Photo library'),
      _p(
        c,
        t,
        ru
            ? 'Доступ запрашивается только тогда, когда вы выбираете фото профиля. Выбранное изображение сохраняется локально.'
            : 'Access is requested only when you choose a profile photo. The selected image is stored locally.',
      ),
      _h(t, ru ? '4. Передача третьим лицам' : '4. Third-party sharing'),
      _p(
        c,
        t,
        ru
            ? 'Приложение не содержит рекламы или tracking SDK и не передаёт данные профиля и дневника третьим лицам.'
            : 'The app contains no advertising or tracking SDK and does not share profile or diary data with third parties.',
      ),
      _h(t, ru ? '5. Хранение и удаление' : '5. Storage and deletion'),
      _p(
        c,
        t,
        ru
            ? 'Локальные данные удаляются при удалении приложения. Отдельная функция удаления данных внутри приложения пока не реализована.'
            : 'Local data is removed when the app is uninstalled. An in-app delete-data function is not currently implemented.',
      ),
      _h(t, ru ? '6. Дети' : '6. Children'),
      _p(
        c,
        t,
        ru
            ? 'Приложение не предназначено для лиц младше 16 лет.'
            : 'This app is not intended for users under 16.',
      ),
      _h(t, ru ? '7. Контакты' : '7. Contact'),
      _p(c, t, ru ? _contactNoticeRu : _contactNoticeEn),
      _supportAction(context, c, t, s),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _termsBody(BuildContext context, dynamic c, AppText t, S s) {
    final ru = s.isRu;
    return [
      Text(s.updatedOn, style: t.mono(size: 9, color: c.muted)),
      const SizedBox(height: 10),
      _p(
        c,
        t,
        ru
            ? 'Используя приложение Balance, вы соглашаетесь с настоящими условиями.'
            : 'By using the Balance app, you agree to these Terms of Service.',
      ),
      _h(t, ru ? '1. Не медицинская консультация' : '1. Not medical advice'),
      _p(
        c,
        t,
        ru
            ? 'Расчёты калорийности, БЖУ и рекомендации носят справочный характер и не являются медицинской консультацией. Проконсультируйтесь с врачом перед изменением рациона.'
            : 'Calorie/macro calculations and recommendations are informational only and are not medical advice. Consult a doctor before changing your diet.',
      ),
      _h(t, ru ? '2. Точность расчётов' : '2. Calculation accuracy'),
      _p(
        c,
        t,
        ru
            ? 'Пищевая ценность в каталоге и рассчитанные порции являются приблизительными и могут отличаться от фактического состава продукта.'
            : 'Catalog nutrition values and serving calculations are estimates and may differ from a product\'s actual composition.',
      ),
      _h(
        t,
        ru ? '3. Ограничение ответственности' : '3. Limitation of liability',
      ),
      _p(
        c,
        t,
        ru
            ? 'Приложение предоставляется "как есть", без гарантий абсолютной точности расчётов.'
            : 'The app is provided "as is", without guarantees of absolute calculation accuracy.',
      ),
      _h(t, ru ? '4. Возрастные ограничения' : '4. Age restriction'),
      _p(
        c,
        t,
        ru
            ? 'Приложением могут пользоваться лица от 16 лет.'
            : 'The app may be used by individuals aged 16+.',
      ),
      _h(t, ru ? '5. Контакты' : '5. Contact'),
      _p(c, t, ru ? _contactNoticeRu : _contactNoticeEn),
      _supportAction(context, c, t, s),
      const SizedBox(height: 8),
    ];
  }

  Widget _supportAction(BuildContext context, dynamic c, AppText t, S s) {
    return Semantics(
      button: true,
      label: s.supportHint,
      child: ExcludeSemantics(
        child: InkWell(
          key: const ValueKey('legalSupportAction'),
          onTap: () => _openSupport(context, s),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(Icons.support_agent_rounded, color: c.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.support,
                    style: t.inter(size: 14, weight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.open_in_new_rounded, color: c.muted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSupport(BuildContext context, S s) async {
    final destination = supportUri ?? BalanceSupportConfig.uri;
    var launched = false;
    if (destination != null) {
      try {
        launched =
            await (supportLauncher?.call(destination) ??
                launchUrl(destination, mode: LaunchMode.externalApplication));
      } on Exception {
        launched = false;
      }
    }
    if (launched || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.supportUnavailableTitle),
        content: Text(s.supportUnavailableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
  }
}
