import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/screens/assessment_flow_complete_screen.dart';

void main() {
  testWidgets('completion screen has no persona identity', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AssessmentFlowCompleteScreen(profileCompleted: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Mastermind', findRichText: true), findsNothing);
    expect(find.textContaining('HH', findRichText: true), findsNothing);
    expect(find.textContaining('persona', findRichText: true), findsNothing);
    expect(find.textContaining('Persona', findRichText: true), findsNothing);
    expect(find.textContaining('Your assessments', findRichText: true), findsOneWidget);
    expect(find.textContaining('are complete', findRichText: true), findsOneWidget);
    expect(find.text('IQ completed'), findsOneWidget);
    expect(find.text('EQ completed'), findsOneWidget);
    expect(find.text('Frequency completed'), findsOneWidget);
    expect(find.text('Create My Profile'), findsOneWidget);
    // Cosmic CTA (FrequencyContinueButton), not flat Material gold fill.
    expect(find.byType(FilledButton), findsNothing);
  });
}
