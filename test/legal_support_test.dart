import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/providers/settings_provider.dart';
import 'package:flutter_app/screens/legal_screen.dart';

void main() {
  Widget subject({
    Uri? supportUri,
    Future<bool> Function(Uri uri)? supportLauncher,
  }) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: MaterialApp(
        home: LegalScreen(
          doc: LegalDoc.privacy,
          onBack: () {},
          supportUri: supportUri,
          supportLauncher: supportLauncher,
        ),
      ),
    );
  }

  testWidgets('legal Support action launches the configured destination', (
    tester,
  ) async {
    final destination = Uri.parse('mailto:support@example.com');
    Uri? opened;
    await tester.pumpWidget(
      subject(
        supportUri: destination,
        supportLauncher: (uri) async {
          opened = uri;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('legalSupportAction')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('legalSupportAction')));
    await tester.pumpAndSettle();

    expect(opened, destination);
    expect(find.text('Поддержка недоступна'), findsNothing);
  });

  testWidgets('legal Support action has an accessible local fallback', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Связаться с поддержкой Balance'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('legalSupportAction')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('legalSupportAction')));
    await tester.pumpAndSettle();

    expect(find.text('Поддержка недоступна'), findsOneWidget);
    expect(find.textContaining('Попробуйте позже'), findsOneWidget);
  });
}
