import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:qmatch/features/assessment/widgets/assessment_result_frame.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sizes = <Size>[
    Size(320, 568),
    Size(375, 667),
    Size(390, 844),
    Size(430, 932),
    Size(412, 915), // large Android-ish
    Size(768, 1024), // tablet
  ];

  for (final locale in const [Locale('tr'), Locale('en')]) {
    for (final size in sizes) {
      testWidgets(
        'result frame fits ${size.width.toInt()}x${size.height.toInt()} ($locale)',
        (tester) async {
          final errors = <FlutterErrorDetails>[];
          final oldHandler = FlutterError.onError;
          FlutterError.onError = (details) {
            errors.add(details);
            oldHandler?.call(details);
          };
          addTearDown(() => FlutterError.onError = oldHandler);

          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(size: size),
              child: MaterialApp(
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: AssessmentResultFrame(
                  title: locale.languageCode == 'tr'
                      ? 'Uygulayıcı'
                      : 'The Executor',
                  tags: locale.languageCode == 'tr'
                      ? const ['Pratik', 'Güvenilir', 'Kararlı']
                      : const ['Practical', 'Reliable', 'Determined'],
                  description: locale.languageCode == 'tr'
                      ? 'Kararlarını mantıkla alır, başladığın işi tamamlamaya odaklanırsın.\n\nİnsanlar seni güven veren, istikrarlı ve çözüm odaklı biri olarak tanımlar.'
                      : 'You make decisions with logic and focus on finishing what you start.\n\nPeople see you as reliable, consistent, and solution-oriented.',
                  statusLabel: locale.languageCode == 'tr'
                      ? 'Zihinsel profilin oluşturuldu.'
                      : 'Your mental profile is ready.',
                  ctaLabel: locale.languageCode == 'tr'
                      ? 'Profilimi Gör'
                      : 'View My Profile',
                  onCta: () {},
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final overflow = errors.any(
            (e) => e.toString().contains('overflowed'),
          );
          expect(overflow, isFalse, reason: 'overflow at $size $locale');
          expect(find.byType(AssessmentResultFrame), findsOneWidget);
          expect(
            find.text(
              locale.languageCode == 'tr'
                  ? 'Profilimi Gör'
                  : 'View My Profile',
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              locale.languageCode == 'tr'
                  ? 'UYGULAYICI'
                  : 'THE EXECUTOR',
            ),
            findsOneWidget,
          );
        },
      );
    }
  }
}
