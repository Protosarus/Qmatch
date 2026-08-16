import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/services/discover_ranking_mode.dart';
import 'package:qmatch/features/discover/widgets/qmatch_candidate_card.dart';
import 'package:qmatch/l10n/app_localizations.dart';

DiscoverUserModel _l2CandidateWithLegacyIdentity() {
  return const DiscoverUserModel(
    uid: 'l2-ui-candidate',
    name: 'Ada',
    age: 29,
    bio: 'Enjoys quiet evenings.',
    interests: ['music'],
    profilePhotoUrl: 'https://example.com/ada.jpg',
    category: 'HH',
    archetype: 'The Mastermind',
    iqNormalized: 80,
    eqNormalized: 80,
  );
}

DiscoverUserModel _legacyRollbackCandidate() {
  return _l2CandidateWithLegacyIdentity().copyWith(
    compatibilityScore: 0.82,
    compatibilityLabel: 'strong',
    compatibilityReasons: const ['thinking', 'emotional'],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('legacy cleanup 4A — hydration gate', () {
    test('viewer Frequency hydrate runs only when needLegacyCompat is true', () {
      final service = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();

      expect(
        service.contains(
          'final needLegacyCompat = attachLegacyUi || _stageB2Collector.enabled;',
        ),
        isTrue,
      );
      expect(
        service.contains('if (needLegacyCompat) {\n      await _hydrateViewerLegacyFrequencyMirrors('),
        isTrue,
      );
      expect(
        service.contains('_hydrateViewerLegacyFrequencyMirrors'),
        isTrue,
      );
      expect(
        service.indexOf('collection(\'assessments\')'),
        greaterThan(service.indexOf('_hydrateViewerLegacyFrequencyMirrors({')),
      );
      expect(service.contains('rankL1Batch'), isTrue);
      expect(service.contains('usesTrustedStructuralL2'), isTrue);
    });

    test('active mode stays L2; legacy_v1 remains rollback', () {
      expect(DiscoverRankingMode.active, DiscoverRankingMode.structuralL2V1);
      expect(
        DiscoverRankingMode.active.usesLegacyCompatibilityScoring,
        isFalse,
      );
      expect(
        DiscoverRankingMode.legacyV1.usesLegacyCompatibilityScoring,
        isTrue,
      );
    });
  });

  group('legacy cleanup 4A — candidate card', () {
    testWidgets('structural_l2_v1 hides category/archetype chips and hint',
        (tester) async {
      await tester.pumpWidget(
        _wrapCard(
          QMatchCandidateCard(
            candidate: _l2CandidateWithLegacyIdentity(),
          ),
        ),
      );

      expect(find.byKey(const Key('qmatch-candidate-card')), findsOneWidget);
      expect(find.text('Ada, 29'), findsOneWidget);
      expect(
        find.byKey(const Key('qmatch-candidate-legacy-archetype-chips')),
        findsNothing,
      );
      expect(find.byKey(const Key('qmatch-candidate-hint')), findsNothing);
      expect(find.text('The Mastermind'), findsNothing);
      expect(find.text('Compatible profile'), findsNothing);
      expect(find.text('Mindset-aligned'), findsNothing);
      expect(find.text('Enjoys quiet evenings.'), findsOneWidget);
      expect(find.byKey(const Key('qmatch-candidate-compat-score')),
          findsNothing);
      expect(find.byKey(const Key('qmatch-candidate-compat-label')),
          findsNothing);
    });

    testWidgets('legacy_v1 keeps category/archetype chips, hint, and %',
        (tester) async {
      await tester.pumpWidget(
        _wrapCard(
          QMatchCandidateCard(
            candidate: _legacyRollbackCandidate(),
            showLegacyCompatibilityUi: true,
          ),
        ),
      );

      expect(
        find.byKey(const Key('qmatch-candidate-legacy-archetype-chips')),
        findsOneWidget,
      );
      expect(find.text('The Mastermind'), findsWidgets);
      expect(find.byKey(const Key('qmatch-candidate-hint')), findsOneWidget);
      expect(find.byKey(const Key('qmatch-candidate-compat-label')),
          findsOneWidget);
      expect(find.byKey(const Key('qmatch-candidate-compat-score')),
          findsOneWidget);
      expect(find.text('Enjoys quiet evenings.'), findsOneWidget);
    });
  });
}

Widget _wrapCard(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: SizedBox(
        width: 375,
        height: 640,
        child: child,
      ),
    ),
  );
}
