import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/theme/i18n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('confirmation cancel label follows language', () {
    expect(const S(AppLang.ru).cancel, 'Отмена');
    expect(const S(AppLang.en).cancel, 'Cancel');
  });
}
