import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/activity/models/activity_event_model.dart';
import 'package:qmatch/features/activity/screens/activity_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

Widget appWith(Stream<List<ActivityEventModel>> stream) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ActivityScreen(activityStream: stream),
  );
}

ActivityEventModel event({
  String id = 'event-1',
  ActivityEventType type = ActivityEventType.bioUpdated,
  String actorName = 'Ada',
}) {
  return ActivityEventModel(
    id: id,
    type: type,
    actorUid: 'userA',
    actorName: actorName,
    actorPhotoUrl: null,
    createdAt: Timestamp.fromDate(
      DateTime.utc(2026, 8, 23, 8),
    ),
  );
}

void main() {
  testWidgets('shows loading state while stream waits', (tester) async {
    final controller = StreamController<List<ActivityEventModel>>();

    await tester.pumpWidget(appWith(controller.stream));

    expect(find.byKey(const Key('activity-loading-state')), findsOneWidget);
    expect(find.text('Loading activity...'), findsOneWidget);

    await controller.close();
  });

  testWidgets('shows empty state for empty feed', (tester) async {
    await tester.pumpWidget(
      appWith(Stream.value(const <ActivityEventModel>[])),
    );
    await tester.pump();

    expect(find.byKey(const Key('activity-empty-state')), findsOneWidget);
    expect(find.text('Nothing new yet'), findsOneWidget);
  });

  testWidgets('shows error state when feed stream fails', (tester) async {
    await tester.pumpWidget(
      appWith(
        Stream<List<ActivityEventModel>>.error(
          StateError('boom'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('activity-error-state')), findsOneWidget);
    expect(find.text('Activity could not be loaded'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('renders a bio activity event', (tester) async {
    await tester.pumpWidget(
      appWith(
        Stream.value(
          <ActivityEventModel>[
            event(),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('qmatch-activity-list')), findsOneWidget);
    expect(find.byKey(const Key('activity-event-event-1')), findsOneWidget);
    expect(find.text('Ada updated their bio.'), findsOneWidget);
  });

  testWidgets('renders match and Super Resonance copy', (tester) async {
    await tester.pumpWidget(
      appWith(
        Stream.value(
          <ActivityEventModel>[
            event(
              id: 'match-1',
              type: ActivityEventType.matchCreated,
              actorName: 'Bora',
            ),
            event(
              id: 'sr-1',
              type: ActivityEventType.superResonanceReceived,
              actorName: 'Ada',
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You matched with Bora.'), findsOneWidget);
    expect(
      find.text('Ada sent you a Super Resonance.'),
      findsOneWidget,
    );
  });
}
