import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/widgets/frequency_question_chrome.dart';
import 'package:qmatch/features/assessment/widgets/q_assessment_scaffold.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in const [Size(320, 568), Size(390, 844), Size(430, 932)]) {
    for (final locale in const [Locale('tr'), Locale('en')]) {
      testWidgets(
        'frequency chrome fits ${size.width}x${size.height} $locale',
        (tester) async {
          final errors = <FlutterErrorDetails>[];
          final oldHandler = FlutterError.onError;
          FlutterError.onError = errors.add;
          addTearDown(() => FlutterError.onError = oldHandler);

          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MaterialApp(
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: QAssessmentScaffold(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 700;
                    final labels = locale.languageCode == 'tr'
                        ? const [
                            'Kesinlikle katılmıyorum',
                            'Katılmıyorum',
                            'Kararsızım',
                            'Katılıyorum',
                            'Kesinlikle katılıyorum',
                          ]
                        : const [
                            'Strongly disagree',
                            'Disagree',
                            'Neutral',
                            'Agree',
                            'Strongly agree',
                          ];
                    return Column(
                      children: [
                        FrequencyQuestionTopBar(onBack: () {}),
                        const FrequencyProgressHeader(
                          label: 'Frequency • 2 / 12',
                          progress: 2 / 12,
                        ),
                        SizedBox(
                          height: compact ? 82 : 170,
                          child: const FrequencyWaveHero(),
                        ),
                        Expanded(
                          child: FrequencyQuestionPanel(
                            eyebrow: 'Vibrational alignment',
                            question: locale.languageCode == 'tr'
                                ? 'Kendini en çok hangi ortamda kendin gibi hissedersin?'
                                : 'Which environment makes you feel most like yourself?',
                            labels: labels,
                            selectedValue: null,
                            compact: compact,
                            onSelected: (_) {},
                          ),
                        ),
                        const SizedBox(height: 6),
                        FrequencyContinueButton(
                          label: locale.languageCode == 'tr'
                              ? 'Devam'
                              : 'Continue',
                          active: false,
                          onPressed: () {},
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 80));

          expect(
            errors.any((error) => error.toString().contains('overflowed')),
            isFalse,
            reason: 'overflow at $size $locale',
          );
          expect(find.byType(FrequencyWaveHero), findsOneWidget);
          expect(find.byType(FrequencyAnswerOptionRow), findsNWidgets(5));
          expect(find.text('Qmatch'), findsNothing);
        },
      );
    }
  }
}
