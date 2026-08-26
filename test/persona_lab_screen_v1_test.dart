import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/l10n/app_localizations.dart';
import 'package:qmatch/features/assessment/screens/persona_lab_screen.dart';
import 'package:qmatch/features/assessment/utils/assessment_persona_reference_catalog.dart';

void main() {
  test('all 18 Personas have complete narrative and signature copy', () {
    expect(assessmentPersonaReferenceCatalog, hasLength(18));

    for (final persona in assessmentPersonaReferenceCatalog.values) {
      expect(persona.titleTr.trim(), isNotEmpty, reason: persona.id);
      expect(persona.titleEn.trim(), isNotEmpty, reason: persona.id);
      expect(persona.descriptionTr.trim(), isNotEmpty, reason: persona.id);
      expect(persona.descriptionEn.trim(), isNotEmpty, reason: persona.id);
      expect(persona.signatureTr.trim(), isNotEmpty, reason: persona.id);
      expect(persona.signatureEn.trim(), isNotEmpty, reason: persona.id);
      expect(persona.asset.trim(), isNotEmpty, reason: persona.id);
    }
  });

  testWidgets('production Persona Lab opens only assigned primary Persona',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: PersonaLabScreen(
          primaryPersonaId: 'stratejist',
          secondaryPersonaId: 'analist',
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('persona-lab-screen')), findsOneWidget);
    expect(find.text('STRATEGIST'), findsOneWidget);
    expect(find.text('Strategic Foresight'), findsNothing);
    expect(find.text('STRATEGIC FORESIGHT'), findsOneWidget);
  });

  testWidgets('production Persona Lab exposes no Persona browsing controls',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        home: PersonaLabScreen(
          primaryPersonaId: 'uygulayici',
          secondaryPersonaId: 'stratejist',
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('persona-lab-previous')), findsNothing);
    expect(find.byKey(const Key('persona-lab-next')), findsNothing);
    expect(find.byKey(const Key('persona-lab-close')), findsOneWidget);
    expect(find.text('RESULTS DRIVEN'), findsOneWidget);
  });

  testWidgets('Turkish Persona uses Turkish description and signature',
      (tester) async {
    final persona = assessmentPersonaReferenceCatalog['uygulayici']!;

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PersonaLabScreen(
          primaryPersonaId: 'uygulayici',
          secondaryPersonaId: 'stratejist',
        ),
      ),
    );

    await tester.pump();

    expect(find.text('UYGULAYICI'), findsOneWidget);
    expect(find.text(persona.descriptionTr), findsOneWidget);
    expect(find.text(persona.signatureTr.toUpperCase()), findsOneWidget);
  });
}
