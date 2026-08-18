import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/features/discover/domain/super_resonance_availability.dart';
import 'package:qmatch/features/discover/domain/super_resonance_send_result.dart';
import 'package:qmatch/features/discover/services/discover_super_resonance_controller.dart';
import 'package:qmatch/features/discover/services/super_resonance_send_client.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';
import 'package:qmatch/features/iap/domain/qmatch_iap_product_ids.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const likeButton = Key('qmatch-discover-like');
  const passButton = Key('qmatch-discover-pass');
  const superButton = Key('qmatch-discover-super-resonance');

  group('SuperResonanceSendClient / result', () {
    test('parses public payload and drops extra fields', () {
      final parsed = SuperResonanceSendResult.fromPublicMap({
        'ok': true,
        'already_sent': true,
        'super_resonance_balance': 3,
        'purchased_balance': 3,
        'daily_remaining': 2,
        'total_available': 5,
        'signal_id': 'a_b',
        'block_reason': 'secret',
        'email': 'x@y.z',
      });
      expect(parsed, isNotNull);
      expect(parsed!.ok, isTrue);
      expect(parsed.alreadySent, isTrue);
      expect(parsed.superResonanceBalance, 3);
      expect(parsed.purchasedBalance, 3);
      expect(parsed.dailyRemaining, 2);
      expect(parsed.totalAvailable, 5);
      expect(parsed.signalId, 'a_b');
    });

    test('invalid payload is rejected', () {
      expect(SuperResonanceSendResult.fromPublicMap({'ok': false}), isNull);
      expect(SuperResonanceSendResult.fromPublicMap({'ok': true}), isNull);
    });

    test('sends once with fresh request_id', () async {
      String? seenName;
      Map<String, dynamic>? seenData;
      final client = SuperResonanceSendClient(
        requestIdFactory: () => 'req-1',
        call: (name, data) async {
          seenName = name;
          seenData = data;
          return {
            'ok': true,
            'already_sent': false,
            'super_resonance_balance': 1,
            'signal_id': 'from_to',
          };
        },
      );
      final result = await client.send(targetUid: 'cand-1');
      expect(seenName, SuperResonanceSendClient.callableName);
      expect(seenData, {
        'target_uid': 'cand-1',
        'request_id': 'req-1',
      });
      expect(result.superResonanceBalance, 1);
      expect(result.alreadySent, isFalse);
    });

    test('request id is UUID-shaped', () {
      final id = createSuperResonanceRequestId();
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
      );
    });
  });

  group('DiscoverSuperResonanceController', () {
    test('unreadable balance fails closed to 0', () async {
      final c = DiscoverSuperResonanceController(
        readBalanceOverride: () async => throw StateError('denied'),
      );
      expect(await c.readTrustedBalance(), 0);
    });

    test('purchase uses Super Resonance SKU and re-reads trusted balance',
        () async {
      var reads = 0;
      var purchases = 0;
      final c = DiscoverSuperResonanceController(
        readBalanceOverride: () async {
          reads += 1;
          return purchases > 0 ? 1 : 0;
        },
        purchaseOverride: () async {
          purchases += 1;
          expect(
            DiscoverSuperResonanceController.productId,
            QmatchIapProductIds.superResonanceX1,
          );
          return 1;
        },
      );
      expect(await c.readTrustedBalance(), 0);
      expect(await c.purchaseThenReadBalance(), 1);
      expect(purchases, 1);
      expect(await c.readTrustedBalance(), 1);
      expect(reads, 3);
    });

    test('localized price uses StoreKit string and never the product id',
        () async {
      final priced = DiscoverSuperResonanceController(
        localizedPriceOverride: () async => '\$2.99',
      );
      expect(await priced.loadLocalizedPrice(), '\$2.99');

      final sku = DiscoverSuperResonanceController(
        localizedPriceOverride: () async =>
            QmatchIapProductIds.superResonanceX1,
      );
      expect(await sku.loadLocalizedPrice(), isNull);

      final failed = DiscoverSuperResonanceController(
        localizedPriceOverride: () async => throw StateError('store'),
      );
      expect(await failed.loadLocalizedPrice(), isNull);
    });
  });

  group('Discover Super Resonance send UI', () {
    testWidgets('balance > 0 opens confirm', (tester) async {
      final harness = _Harness(balance: 2);
      await _pump(tester, harness);
      expect(
        find.byKey(const Key('qmatch-discover-super-resonance-balance')),
        findsOneWidget,
      );
      expect(find.text('2'), findsWidgets);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qmatch-super-resonance-confirm-sheet')),
          findsOneWidget);
      expect(find.text('Send Super Resonance to Ada?'), findsOneWidget);
      expect(find.text('Purchased: 2'), findsOneWidget);
      expect(find.text('Today\'s Resonance allowance: 2 / 2'), findsNothing);
      expect(find.text('Uses 1 Super Resonance'), findsOneWidget);
      expect(
        find.text(
          'This sends a stronger alignment signal. It does not Like them and does not create a match.',
        ),
        findsOneWidget,
      );
      expect(harness.sendCount, 0);
      expect(find.byKey(const Key('qmatch-super-resonance-purchase-sheet')),
          findsNothing);
    });

    testWidgets('badge shows total usable and confirm splits daily/purchased',
        (tester) async {
      final harness = _Harness(
        balance: 3,
        dailyRemaining: 2,
        dailyLimit: 2,
      );
      await _pump(tester, harness);
      expect(find.text('5'), findsWidgets);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      expect(
        find.text('Today\'s Resonance allowance: 2 / 2'),
        findsOneWidget,
      );
      expect(find.text('Purchased: 3'), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-super-resonance-confirm')));
      await tester.pumpAndSettle();
      expect(harness.sendCount, 1);
      expect(harness.displayedBalance, 4);
    });

    testWidgets('Free confirm does not invent a daily allowance',
        (tester) async {
      final harness = _Harness(balance: 2);
      await _pump(tester, harness);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('Today\'s Resonance allowance'), findsNothing);
      expect(find.text('Purchased: 2'), findsOneWidget);
    });

    testWidgets('confirm sends once and card stays', (tester) async {
      final harness = _Harness(balance: 2);
      await _pump(tester, harness);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('qmatch-super-resonance-confirm')));
      await tester.pumpAndSettle();
      expect(harness.sendCount, 1);
      expect(harness.lastRequestId, isNotEmpty);
      expect(harness.cardIndex, 0);
      expect(find.text('Ada'), findsOneWidget);
      expect(harness.displayedBalance, 1);
      expect(find.byKey(const Key('qmatch-super-resonance-confirm-sheet')),
          findsNothing);
    });

    testWidgets('cancel sends nothing', (tester) async {
      final harness = _Harness(balance: 2);
      await _pump(tester, harness);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('qmatch-super-resonance-cancel')));
      await tester.pumpAndSettle();
      expect(harness.sendCount, 0);
      expect(harness.cardIndex, 0);
      expect(harness.displayedBalance, 2);
    });

    testWidgets('balance 0 opens purchase sheet and does not send',
        (tester) async {
      final harness = _Harness(balance: 0, localizedPrice: '₺129,99');
      await _pump(tester, harness);
      expect(find.text('0'), findsWidgets);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('qmatch-super-resonance-purchase-sheet')),
          findsOneWidget);
      expect(find.text('Get Super Resonance'), findsWidgets);
      expect(find.text('Balance: 0'), findsOneWidget);
      expect(find.text('1 Super Resonance'), findsOneWidget);
      expect(find.text('₺129,99'), findsOneWidget);
      expect(
        find.text(QmatchIapProductIds.superResonanceX1),
        findsNothing,
      );
      expect(find.byKey(const Key('qmatch-super-resonance-purchase-sku')),
          findsNothing);
      expect(
          find.byKey(const Key('qmatch-resonance-unlock-title')), findsNothing);
      expect(harness.sendCount, 0);
    });

    testWidgets('missing StoreKit price hides product id', (tester) async {
      final harness = _Harness(balance: 0);
      await _pump(tester, harness);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      expect(find.text('1 Super Resonance'), findsOneWidget);
      expect(find.byKey(const Key('qmatch-super-resonance-purchase-price')),
          findsNothing);
      expect(find.text(QmatchIapProductIds.superResonanceX1), findsNothing);
    });

    testWidgets(
        'successful purchase re-reads trusted balance and does not send',
        (tester) async {
      final harness = _Harness(balance: 0);
      await _pump(tester, harness);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('qmatch-super-resonance-purchase-cta')));
      await tester.pumpAndSettle();
      expect(harness.purchaseCount, 1);
      expect(harness.sendCount, 0);
      expect(harness.displayedBalance, 1);
      expect(harness.cardIndex, 0);
    });

    testWidgets('send failure keeps card and fail-closed balance',
        (tester) async {
      final harness = _Harness(balance: 2, sendShouldFail: true);
      await _pump(tester, harness);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('qmatch-super-resonance-confirm')));
      await tester.pumpAndSettle();
      expect(harness.sendCount, 1);
      expect(harness.cardIndex, 0);
      expect(find.text('Ada'), findsOneWidget);
      expect(harness.displayedBalance, 2);
      expect(
        find.text('Super Resonance couldn\'t be sent. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('block'), findsNothing);
    });

    testWidgets('Like/Pass still work unchanged', (tester) async {
      final harness = _Harness(balance: 2);
      await _pump(tester, harness);
      await tester.tap(find.byKey(superButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('qmatch-super-resonance-confirm')));
      await tester.pumpAndSettle();
      expect(harness.cardIndex, 0);

      await tester.tap(find.byKey(likeButton));
      await tester.pump();
      expect(harness.likes, 1);
      expect(harness.passes, 0);

      await tester.tap(find.byKey(passButton));
      await tester.pump();
      expect(harness.passes, 1);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.replay), findsNothing);
      expect(find.byIcon(Icons.bolt), findsNothing);
    });

    testWidgets('without Super Resonance, action bar stays two buttons',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QMatchDiscoverActionBar(
              passLabel: 'Pass',
              likeLabel: 'Like',
              onPass: _noop,
              onLike: _noop,
              isActionLoading: false,
            ),
          ),
        ),
      );
      expect(find.byKey(superButton), findsNothing);
      expect(find.byKey(likeButton), findsOneWidget);
      expect(find.byKey(passButton), findsOneWidget);
    });
  });

  group('DiscoverScreen Super Resonance wiring', () {
    late String src;
    late String superBody;
    late String likeBody;
    late String passBody;

    setUpAll(() {
      src = File(
        'lib/features/discover/screens/discover_screen.dart',
      ).readAsStringSync();
      final superIdx = src.indexOf('Future<void> _onSuperResonance() async {');
      final passIdx = src.indexOf('Future<void> _onPass() async {');
      final likeIdx = src.indexOf('Future<void> _onLike() async {');
      final buildIdx = src.indexOf('Widget build(BuildContext context)');
      expect(superIdx, greaterThanOrEqualTo(0));
      expect(passIdx, greaterThan(superIdx));
      expect(likeIdx, greaterThan(passIdx));
      expect(buildIdx, greaterThan(likeIdx));
      superBody = src.substring(superIdx, passIdx);
      passBody = src.substring(passIdx, likeIdx);
      likeBody = src.substring(likeIdx, buildIdx);
    });

    test('send does not advance the deck or write Like/Pass', () {
      expect(superBody.contains('_advance()'), isFalse);
      expect(superBody.contains('likeUser'), isFalse);
      expect(superBody.contains('passUser'), isFalse);
      expect(superBody.contains('_likeDispatchedUids.add'), isFalse);
      expect(superBody.contains('compareStageB2Structural'), isFalse);
      expect(superBody.contains('ResonancePaywallScreen'), isFalse);
      expect(superBody.contains('send(targetUid: c.uid)'), isTrue);
      expect(
        superBody.contains('showQMatchSuperResonanceConfirmSheet'),
        isTrue,
      );
      expect(
        superBody.contains('showQMatchSuperResonancePurchaseSheet'),
        isTrue,
      );
    });

    test('Like/Pass bodies stay unchanged', () {
      expect(likeBody.contains('likeUser(c.uid)'), isTrue);
      expect(likeBody.contains('_advance()'), isTrue);
      expect(likeBody.contains('sendSuperResonance'), isFalse);
      expect(passBody.contains('passUser(c.uid)'), isTrue);
      expect(passBody.contains('_advance()'), isTrue);
      expect(passBody.contains('sendSuperResonance'), isFalse);
    });

    test('purchase SKU is Super Resonance consumable', () {
      expect(
        File(
          'lib/features/discover/services/discover_super_resonance_controller.dart',
        ).readAsStringSync().contains('QmatchIapProductIds.superResonanceX1'),
        isTrue,
      );
      expect(
        File(
          'lib/features/discover/widgets/qmatch_super_resonance_purchase_sheet.dart',
        ).readAsStringSync().contains('resonance_paywall_screen'),
        isFalse,
      );
      expect(
        File(
          'lib/features/discover/widgets/qmatch_super_resonance_purchase_sheet.dart',
        ).readAsStringSync().contains('qmatch.super_resonance.x1'),
        isFalse,
      );
      expect(
        File(
          'lib/features/discover/services/super_resonance_send_client.dart',
        ).readAsStringSync().contains('getSuperResonanceAvailability'),
        isTrue,
      );
      expect(
        File(
          'lib/features/discover/services/discover_super_resonance_controller.dart',
        ).readAsStringSync().contains('readTrustedAvailability'),
        isTrue,
      );
      expect(
        File(
          'lib/features/discover/screens/discover_screen.dart',
        ).readAsStringSync().contains('DateTime.now()'),
        isFalse,
      );
    });
  });
}

void _noop() {}

Future<void> _pump(WidgetTester tester, _Harness harness) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: harness),
    ),
  );
  await tester.pump();
}

class _Harness extends StatefulWidget {
  _Harness({
    required this.balance,
    this.dailyRemaining = 0,
    this.dailyLimit = 0,
    this.sendShouldFail = false,
    this.localizedPrice,
  });

  final int balance;
  final int dailyRemaining;
  final int dailyLimit;
  final bool sendShouldFail;
  final String? localizedPrice;
  int sendCount = 0;
  int purchaseCount = 0;
  int likes = 0;
  int passes = 0;
  int cardIndex = 0;
  int displayedBalance = 0;
  String lastRequestId = '';

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late int _purchased;
  late int _dailyRemaining;
  late int _dailyLimit;
  late final DiscoverSuperResonanceController _controller;
  bool _busy = false;

  int get _total => _dailyRemaining + _purchased;

  SuperResonanceAvailability get _availability => SuperResonanceAvailability(
        dailyRemaining: _dailyRemaining,
        dailyLimit: _dailyLimit,
        purchasedBalance: _purchased,
        totalAvailable: _total,
      );

  @override
  void initState() {
    super.initState();
    _purchased = widget.balance;
    _dailyRemaining = widget.dailyRemaining;
    _dailyLimit = widget.dailyLimit;
    widget.displayedBalance = _total;
    _controller = DiscoverSuperResonanceController(
      readAvailabilityOverride: () async => _availability,
      sendOverride: (targetUid, requestId) async {
        widget.sendCount += 1;
        widget.lastRequestId = requestId;
        expect(targetUid, 'cand-1');
        if (widget.sendShouldFail) {
          throw StateError('unavailable');
        }
        if (_dailyRemaining > 0) {
          _dailyRemaining -= 1;
        } else {
          _purchased -= 1;
        }
        return SuperResonanceSendResult(
          ok: true,
          alreadySent: false,
          superResonanceBalance: _purchased,
          signalId: 'cand-from_$targetUid',
          dailyRemaining: _dailyRemaining,
          purchasedBalance: _purchased,
          totalAvailable: _total,
        );
      },
      purchaseOverride: () async {
        widget.purchaseCount += 1;
        _purchased = 1;
        return 1;
      },
      localizedPriceOverride: widget.localizedPrice == null
          ? null
          : () async => widget.localizedPrice,
    );
  }

  Future<void> _onSuperResonance() async {
    if (_busy) return;
    try {
      final availability = await _controller.readTrustedAvailability();
      if (!mounted) return;
      setState(() {
        widget.displayedBalance = availability.totalAvailable;
      });
      if (availability.totalAvailable > 0) {
        final confirmed = await showQMatchSuperResonanceConfirmSheet(
          context,
          candidateName: 'Ada',
          purchasedBalance: availability.purchasedBalance,
          dailyRemaining: availability.dailyRemaining,
          dailyLimit: availability.dailyLimit,
        );
        if (!confirmed || !mounted) return;
        setState(() => _busy = true);
        try {
          final result = await _controller.send(targetUid: 'cand-1');
          if (!mounted) return;
          setState(() => widget.displayedBalance = result.totalAvailable);
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.discoverSuperResonanceSendFailed,
              ),
            ),
          );
          final next = await _controller.readTrustedAvailability();
          if (mounted) {
            setState(() => widget.displayedBalance = next.totalAvailable);
          }
        } finally {
          if (mounted) setState(() => _busy = false);
        }
        return;
      }
      await showQMatchSuperResonancePurchaseSheet(
        context,
        trustedBalance: availability.purchasedBalance,
        purchaseThenReadBalance: _controller.purchaseThenReadBalance,
        loadLocalizedPrice: _controller.loadLocalizedPrice,
      );
      if (!mounted) return;
      final next = await _controller.readTrustedAvailability();
      setState(() => widget.displayedBalance = next.totalAvailable);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              widget.cardIndex == 0 ? 'Ada' : 'Next',
              key: const Key('qmatch-discover-super-resonance-card'),
            ),
          ),
        ),
        QMatchDiscoverActionBar(
          passLabel: l10n.discoverPass,
          likeLabel: l10n.discoverLike,
          onPass: () => setState(() => widget.passes += 1),
          onLike: () => setState(() => widget.likes += 1),
          isActionLoading: false,
          showSuperResonance: true,
          superResonanceLabel: l10n.discoverSuperResonance,
          superResonanceBalance: widget.displayedBalance,
          isSuperResonanceLoading: _busy,
          onSuperResonance: _busy ? null : _onSuperResonance,
        ),
      ],
    );
  }
}
