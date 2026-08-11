import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/screens/persona_reveal_screen.dart';

void main() {
  Future<void> pumpReveal(
    WidgetTester tester, {
    String primary = 'analist',
    String secondary = 'empat',
    VoidCallback? onContinue,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: PersonaRevealScreen(
          primaryPersonaId: primary,
          secondaryPersonaId: secondary,
          onContinue: onContinue,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows primary narrative prominently and secondary subtly',
      (tester) async {
    await pumpReveal(tester);

    expect(find.byKey(const Key('persona-reveal-primary-title')), findsOneWidget);
    expect(find.text('Analyst'), findsOneWidget);
    expect(
      find.byKey(const Key('persona-reveal-primary-description')),
      findsOneWidget,
    );
    expect(
      find.textContaining('deciphers details', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('persona-reveal-prototype-framing')),
      findsOneWidget,
    );
    expect(
      find.text('The narrative prototype closest to your pattern'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('persona-reveal-secondary')), findsOneWidget);
    expect(
      find.textContaining('A close supporting pattern · Empath'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('persona-reveal-primary-art')), findsOneWidget);
    expect(
      find.byKey(const Key('persona-reveal-secondary-art')),
      findsOneWidget,
    );
  });

  testWidgets('Turkish framing uses closest-prototype wording', (tester) async {
    await pumpReveal(tester, locale: const Locale('tr'));

    expect(
      find.text('Profiline en yakın anlatı prototipi'),
      findsOneWidget,
    );
    expect(find.text('Analist'), findsOneWidget);
    expect(
      find.textContaining('Yakın destekleyen örüntü · Empat'),
      findsOneWidget,
    );
  });

  testWidgets('hides CTA when navigation is not wired', (tester) async {
    await pumpReveal(tester, onContinue: null);
    expect(find.byKey(const Key('persona-reveal-continue')), findsNothing);
  });

  testWidgets('shows CTA only when onContinue is provided', (tester) async {
    var tapped = false;
    await pumpReveal(tester, onContinue: () => tapped = true);
    expect(find.byKey(const Key('persona-reveal-continue')), findsOneWidget);
    await tester.tap(find.byKey(const Key('persona-reveal-continue')));
    expect(tapped, isTrue);
  });

  testWidgets('never surfaces scores, confidence, or delta_D', (tester) async {
    await pumpReveal(tester);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('confidence', findRichText: true), findsNothing);
    expect(find.textContaining('Confidence', findRichText: true), findsNothing);
    expect(find.textContaining('delta', findRichText: true), findsNothing);
    expect(find.textContaining('Δ'), findsNothing);
    expect(find.textContaining('score', findRichText: true), findsNothing);
    expect(find.textContaining('RVI', findRichText: true), findsNothing);
    expect(find.textContaining('quantum', findRichText: true), findsNothing);
  });

  testWidgets('unknown primary id fails at build', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PersonaRevealScreen(
          primaryPersonaId: 'not_a_persona',
          secondaryPersonaId: 'empat',
        ),
      ),
    );
    expect(tester.takeException(), isA<ArgumentError>());
  });

  test('does not import PersonaScoringService', () {
    final source = File(
      'lib/features/assessment/screens/persona_reveal_screen.dart',
    ).readAsStringSync();
    expect(source.contains('PersonaScoringService'), isFalse);
    expect(source.contains('persona_scoring_service.dart'), isFalse);
    expect(source.contains('raw_delta'), isFalse);
    expect(source.contains('assessmentPersonaReferenceCatalog'), isTrue);
  });
}
