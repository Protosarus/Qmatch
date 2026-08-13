import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/core/utils/firestore_paths.dart';
import 'package:qmatch/features/discover/widgets/qmatch_discover_match_dialog.dart';
import 'package:qmatch/features/matching/models/match_model.dart';
import 'package:qmatch/features/matching/services/like_match_atomicity_gate.dart';
import 'package:qmatch/features/matching/services/like_match_outcome.dart';
import 'package:qmatch/features/matching/services/match_create_lifecycle_gate.dart';
import 'package:qmatch/features/messages/models/chat_thread_model.dart';
import 'package:qmatch/features/messages/utils/closed_account_chat_history.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LikeMatchOutcome contract', () {
    test('createNew → created_new_match', () {
      expect(
        LikeMatchOutcomeMapper.fromDecision(
          MatchCreateLifecycleDecision.createNew,
        ),
        LikeMatchOutcome.createdNewMatch,
      );
    });

    test('idempotent active → existing_active_match (no duplicate dialog cue)',
        () {
      expect(
        LikeMatchOutcomeMapper.fromDecision(
          MatchCreateLifecycleDecision.idempotentActiveSuccess,
        ),
        LikeMatchOutcome.existingActiveMatch,
      );
    });

    test('refuse / non-mutual → no_match', () {
      expect(
        LikeMatchOutcomeMapper.fromDecision(
          MatchCreateLifecycleDecision.refuseNonMutualLike,
        ),
        LikeMatchOutcome.noMatch,
      );
      expect(
        LikeMatchOutcomeMapper.fromDecision(
          MatchCreateLifecycleDecision.refuseInvalidLiveUser,
        ),
        LikeMatchOutcome.noMatch,
      );
    });

    test('transaction retry with active match remains idempotent', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: true,
        matchState: MatchState.active.name,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
        viewerLiveEligible: true,
        targetLiveEligible: true,
      );
      expect(plan.writeMatchArtifacts, isFalse);
      expect(plan.outcome, LikeMatchOutcome.existingActiveMatch);
      expect(
        plan.matchDecision,
        MatchCreateLifecycleDecision.idempotentActiveSuccess,
      );
    });

    test('new mutual match plans create artifacts + created_new_match', () {
      final plan = LikeMatchAtomicityGate.planLike(
        matchExists: false,
        matchState: null,
        viewerBlockedCandidate: false,
        candidateBlockedViewer: false,
        viewerLikesCandidatePending: true,
        candidateLikesViewer: true,
        viewerLiveEligible: true,
        targetLiveEligible: true,
      );
      expect(plan.writeMatchArtifacts, isTrue);
      expect(plan.outcome, LikeMatchOutcome.createdNewMatch);
    });
  });

  group('Discover match-success dialog UX', () {
    testWidgets('new mutual match dialog — Open chat returns openChat',
        (tester) async {
      DiscoverMatchDialogAction? action;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    key: const Key('show-match-dialog'),
                    onPressed: () async {
                      final l10n = AppLocalizations.of(context)!;
                      action = await showQMatchDiscoverMatchDialog(
                        context: context,
                        title: l10n.discoverItsAMatch,
                        body: l10n.discoverMatchDialogBody,
                        openChatLabel: l10n.discoverMatchOpenChat,
                        continueLabel: l10n.continueAction,
                      );
                    },
                    child: const Text('show'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('show-match-dialog')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsOneWidget);
      expect(find.text("It's a match"), findsOneWidget);

      await tester.tap(find.byKey(const Key('qmatch-discover-match-open-chat')));
      await tester.pumpAndSettle();
      expect(action, DiscoverMatchDialogAction.openChat);
      expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsNothing);
    });

    testWidgets('Continue dismisses dialog and returns continueDiscover',
        (tester) async {
      DiscoverMatchDialogAction? action;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: TextButton(
                    key: const Key('show-match-dialog'),
                    onPressed: () async {
                      final l10n = AppLocalizations.of(context)!;
                      action = await showQMatchDiscoverMatchDialog(
                        context: context,
                        title: l10n.discoverItsAMatch,
                        body: l10n.discoverMatchDialogBody,
                        openChatLabel: l10n.discoverMatchOpenChat,
                        continueLabel: l10n.continueAction,
                      );
                    },
                    child: const Text('show'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('show-match-dialog')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('qmatch-discover-match-continue')));
      await tester.pumpAndSettle();
      expect(action, DiscoverMatchDialogAction.continueDiscover);
      expect(find.byKey(const Key('qmatch-discover-match-dialog')), findsNothing);
    });

    test('Open chat uses deterministic thread id for peer pair', () {
      const me = 'uid_b';
      const peer = 'uid_a';
      expect(
        FirestorePaths.deterministicThreadId(me, peer),
        'uid_a_uid_b',
      );
      expect(
        FirestorePaths.deterministicThreadId(me, peer),
        FirestorePaths.deterministicMatchId(me, peer),
      );
    });
  });

  group('Discover screen wiring (source)', () {
    test('dialog only for created_new_match; Open chat → ChatDetailScreen',
        () {
      final src = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      expect(src.contains('LikeMatchOutcome.createdNewMatch'), isTrue);
      expect(src.contains('showQMatchDiscoverMatchDialog'), isTrue);
      expect(src.contains('DiscoverMatchDialogAction.openChat'), isTrue);
      expect(src.contains('ChatDetailScreen'), isTrue);
      expect(src.contains('deterministicThreadId'), isTrue);
      // existing active must not reopen success dialog
      expect(src.contains('LikeMatchOutcome.existingActiveMatch'), isFalse);
      // bool matched dialog path removed
      expect(src.contains('if (matched)'), isFalse);
    });

    test('services return LikeMatchOutcome (not bare bool)', () {
      final match = File(
        'lib/features/matching/services/match_service.dart',
      ).readAsStringSync();
      final swipe = File(
        'lib/features/matching/services/swipe_service.dart',
      ).readAsStringSync();
      expect(match.contains('Future<LikeMatchOutcome> likeAndMaybeCreateMatch'),
          isTrue);
      expect(match.contains('LikeMatchOutcome.createdNewMatch'), isTrue);
      expect(match.contains('LikeMatchOutcome.existingActiveMatch'), isTrue);
      expect(match.contains('LikeMatchOutcome.noMatch'), isTrue);
      expect(swipe.contains('Future<LikeMatchOutcome> likeUser'), isTrue);
    });
  });

  group('closed/unavailable chat safeguards remain intact', () {
    test('deletion-closed history still readable; send blocked', () {
      final t = ChatThreadModel(
        threadId: 'a_b',
        participants: const ['a', 'b'],
        matchId: 'a_b',
        status: ThreadStatus.closed,
        closedReason: ClosedAccountChatHistory.closedReasonAccountDeletion,
      );
      expect(ClosedAccountChatHistory.allowMessageHistoryRead(t), isTrue);
      expect(ClosedAccountChatHistory.allowSend(t), isFalse);
      expect(ClosedAccountChatHistory.isAccountDeletionClosed(t), isTrue);
    });

    test('ChatDetailScreen still applies deletion-closed UI path', () {
      final src = File(
        'lib/features/messages/screens/chat_detail_screen.dart',
      ).readAsStringSync();
      expect(src.contains('ClosedAccountChatHistory.isAccountDeletionClosed'),
          isTrue);
      expect(src.contains('QMatchConversationInactiveBanner'), isTrue);
      expect(src.contains('if (_accountDeletionClosed) return;'), isTrue);
    });
  });
}
