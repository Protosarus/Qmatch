import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/debug/qmatch_perf.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/firestore_paths.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../iap/domain/resonance_paywall_feature.dart';
import '../../iap/screens/resonance_paywall_screen.dart';
import '../../iap/services/entitlement_repository.dart';
import '../../iap/services/ios_iap_session.dart';
import '../../matching/services/like_match_outcome.dart';
import '../../matching/services/swipe_service.dart';
import '../../messages/screens/chat_detail_screen.dart';
import '../../messages/services/chat_service.dart';
import '../../settings/services/account_deletion_request_service.dart';
import '../../who_liked_you/navigation/who_liked_you_entry.dart';
import '../models/discover_user_model.dart';
import '../domain/discover_eligible_query_plan.dart';
import '../domain/discover_passport_snapshot.dart';
import '../domain/super_resonance_availability.dart';
import '../domain/super_resonance_send_result.dart';
import '../services/discover_gesture_onboarding_store.dart';
import '../services/discover_passport_client.dart';
import '../services/discover_service.dart';
import '../services/discover_super_resonance_controller.dart';
import '../widgets/discover_widgets.dart';
import 'passport_destination_picker_screen.dart';

/// Whether Discover should precache this photo URL.
///
/// Skips empty values and disposable Stage B2 `example.com` seed URLs.
/// Production `http`/`https` photo URLs still precache. Presentation-only.
@visibleForTesting
bool shouldPrecacheDiscoverPhotoUrl(String? raw) {
  final url = raw?.trim();
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return false;
  final host = uri.host.toLowerCase();
  if (host == 'example.com' || host.endsWith('.example.com')) return false;
  return true;
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.animateBackground,
    this.gestureOnboardingStore,
    this.whoLikedYouEntry,
    this.superResonance,
    this.uidProvider,
    this.discoverService,
    this.passportClient,
    this.openPaywall,
  });

  /// Goldens / reduced-motion: freeze cosmic breathing when false.
  final bool? animateBackground;

  /// Test injection for gesture tutorial persistence.
  final DiscoverGestureOnboardingStore? gestureOnboardingStore;

  /// UX routing for the header Who Liked You control. Tests inject a fake.
  final WhoLikedYouEntry? whoLikedYouEntry;

  /// Trusted Super Resonance send + consumable purchase. Tests inject a fake.
  final DiscoverSuperResonanceController? superResonance;

  /// Test injection for entitlement reads.
  final String? Function()? uidProvider;

  /// Test injection for Discover loading.
  final DiscoverService? discoverService;

  /// Shared Passport client (picker + optional DiscoverService).
  final DiscoverPassportClient? passportClient;

  /// Test injection for Resonance paywall from Passport.
  final Future<bool> Function(
    BuildContext context,
    ResonancePaywallFeature feature,
  )? openPaywall;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final DiscoverService _discoverService;
  late final DiscoverPassportClient _passportClient;
  final SwipeService _swipeService = SwipeService();
  final AccountDeletionRequestService _deletionService =
      AccountDeletionRequestService();

  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _deletionPending = false;
  bool _hasError = false;
  bool _lastCardCommitted = false;
  bool _showGestureOnboarding = false;
  int _committedSwipeCount = 0;
  double _swipeFeedback = 0;
  int _superResonanceBalance = 0;
  int _superResonanceDailyRemaining = 0;
  int _superResonanceDailyLimit = 0;
  int _superResonancePurchased = 0;
  bool _superResonanceBusy = false;
  bool _superResonanceSheetOpen = false;
  List<DiscoverUserModel> _candidates = [];
  int _currentIndex = 0;
  DiscoverPassportSnapshot _passportSnapshot =
      DiscoverPassportSnapshot.worldwide;
  DiscoverEligibleQueryPlan _queryPlan =
      const DiscoverEligibleQueryPlan.worldwide();
  final Set<String> _likeDispatchedUids = <String>{};
  late final DiscoverGestureOnboardingStore _gestureOnboardingStore;
  late final DiscoverSuperResonanceController _superResonance;

  DiscoverUserModel? get _currentCandidate {
    if (_currentIndex < 0 || _currentIndex >= _candidates.length) {
      return null;
    }
    return _candidates[_currentIndex];
  }

  bool get _isLastCandidate =>
      _candidates.isNotEmpty && _currentIndex == _candidates.length - 1;

  @override
  void initState() {
    super.initState();
    _passportClient = widget.passportClient ?? DiscoverPassportClient();
    _discoverService = widget.discoverService ??
        (widget.passportClient == null
            ? DiscoverService()
            : DiscoverService(passportClient: widget.passportClient));
    _gestureOnboardingStore = widget.gestureOnboardingStore ??
        DiscoverGestureOnboardingStore(
          viewerUid: FirebaseAuth.instance.currentUser?.uid,
        );
    _superResonance = widget.superResonance ??
        DiscoverSuperResonanceController(
          entitlements: EntitlementRepository(),
          uidProvider: widget.uidProvider ??
              () => FirebaseAuth.instance.currentUser?.uid,
          iapClient: IosIapSession.instance.client,
        );
    DiscoverGestureOnboardingStore.guidanceRevision
        .addListener(_onGuidanceRevision);
    _loadDeletionPending();
    _loadCandidates();
    _refreshSuperResonanceBalance();
  }

  @override
  void dispose() {
    DiscoverGestureOnboardingStore.guidanceRevision
        .removeListener(_onGuidanceRevision);
    super.dispose();
  }

  void _onGuidanceRevision() {
    _syncFirstUseGuidanceFromStore();
  }

  void _onGestureOnboardingShowChanged(bool _) {
    _syncFirstUseGuidanceFromStore();
  }

  Future<void> _syncFirstUseGuidanceFromStore() async {
    try {
      final seen = await _gestureOnboardingStore.hasSeen();
      final count = await _gestureOnboardingStore.committedSwipeCount();
      if (!mounted) return;
      final show =
          !seen && !_isLoading && !_hasError && _currentCandidate != null;
      if (_showGestureOnboarding == show && _committedSwipeCount == count) {
        return;
      }
      setState(() {
        _committedSwipeCount = count;
        _showGestureOnboarding = show;
      });
    } catch (e, st) {
      debugPrint('Discover first-use guidance sync skipped: $e\n$st');
    }
  }

  Future<void> _completeGestureOnboarding() async {
    try {
      await _gestureOnboardingStore.markSeen();
    } catch (e, st) {
      debugPrint('Discover gesture onboarding persist failed: $e\n$st');
    }
    if (!mounted) return;
    setState(() => _showGestureOnboarding = false);
  }

  Future<void> _debugReplayGestureOnboarding() async {
    if (!kDebugMode) return;
    try {
      await _gestureOnboardingStore.resetFirstUseGuidance();
    } catch (e, st) {
      debugPrint('Discover gesture onboarding debug reset failed: $e\n$st');
    }
    await _syncFirstUseGuidanceFromStore();
  }

  Future<void> _loadDeletionPending() async {
    final pending = await _deletionService.isAccountDeletionPending();
    if (!mounted) return;
    setState(() => _deletionPending = pending);
  }

  Future<void> _loadCandidates() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _likeDispatchedUids.clear();
    });
    try {
      final list = await QmatchPerf.trace(
        'discover.deck_ready',
        () => _discoverService.getCandidates(limit: 30),
      );
      if (!mounted) return;
      setState(() {
        _candidates = list;
        _currentIndex = 0;
        _swipeFeedback = 0;
        _lastCardCommitted = false;
        _isLoading = false;
        _hasError = false;
        _passportSnapshot = _discoverService.lastPassportSnapshot;
        _queryPlan = _discoverService.lastQueryPlan;
      });
      _precacheUpcomingCandidatePhotos();
      await _syncFirstUseGuidanceFromStore();
    } catch (e, st) {
      debugPrint('Discover load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _candidates = [];
        _currentIndex = 0;
        _swipeFeedback = 0;
        _lastCardCommitted = false;
        _isLoading = false;
      });
      await _syncFirstUseGuidanceFromStore();
    }
  }

  Future<void> _noteCommittedSwipe() async {
    try {
      final next = await _gestureOnboardingStore.recordCommittedSwipe();
      if (!mounted) return;
      setState(() => _committedSwipeCount = next);
    } catch (e, st) {
      debugPrint('Discover swipe-stamp count persist skipped: $e\n$st');
    }
  }

  void _advance() {
    setState(() {
      _currentIndex++;
      _swipeFeedback = 0;
    });
    _precacheUpcomingCandidatePhotos();
  }

  /// Warm the next 1–2 card photos only. Never the whole deck.
  /// Never awaited on deck-ready. Fake example.com seed URLs are skipped.
  void _precacheUpcomingCandidatePhotos() {
    if (!mounted) return;
    QmatchPerf.traceSync('discover.photo_precache', () {
      if (!mounted) return;
      final ctx = context;
      for (var i = 1; i <= 2; i++) {
        final idx = _currentIndex + i;
        if (idx < 0 || idx >= _candidates.length) break;
        final url = _candidates[idx].primaryPhotoUrl?.trim();
        if (!shouldPrecacheDiscoverPhotoUrl(url)) continue;
        precacheImage(NetworkImage(url!), ctx).ignore();
      }
    });
  }

  void _onSwipeFeedback(double value) {
    if (_swipeFeedback == value) return;
    setState(() => _swipeFeedback = value);
  }

  Future<void> _refreshSuperResonanceBalance() async {
    final availability = await _superResonance.readTrustedAvailability();
    if (!mounted) return;
    _applyAvailability(availability);
  }

  void _applyAvailability(SuperResonanceAvailability availability) {
    setState(() {
      _superResonanceDailyRemaining = availability.dailyRemaining;
      _superResonanceDailyLimit = availability.dailyLimit;
      _superResonancePurchased = availability.purchasedBalance;
      _superResonanceBalance = availability.totalAvailable;
    });
  }

  void _applySendResult(SuperResonanceSendResult result) {
    setState(() {
      _superResonanceDailyRemaining = result.dailyRemaining;
      _superResonancePurchased = result.purchasedBalance;
      _superResonanceBalance = result.totalAvailable;
    });
  }

  void _showSuperResonanceError(String message) {
    if (!mounted) return;
    final sanitized = message.toLowerCase().contains('block')
        ? AppLocalizations.of(context)!.discoverSuperResonanceSendFailed
        : message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sanitized),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _onSuperResonance() async {
    final c = _currentCandidate;
    if (c == null || _superResonanceBusy || _superResonanceSheetOpen) return;
    if (_isActionLoading) return;
    if (_likeDispatchedUids.contains(c.uid)) return;

    final tapSw = Stopwatch()..start();
    QmatchPerf.mark('super_resonance.tap_received');
    _superResonanceSheetOpen = true;
    try {
      final SuperResonanceAvailability availability;
      final cached = _superResonance.peekTrustedAvailability();
      if (cached != null) {
        QmatchPerf.mark(
          'super_resonance.availability_cache_hit',
          tapSw.elapsed,
        );
        availability = cached;
      } else {
        QmatchPerf.mark(
          'super_resonance.availability_refresh_start',
          tapSw.elapsed,
        );
        availability = await QmatchPerf.trace(
          'super_resonance.tap.availability',
          () => _superResonance.readTrustedAvailability(),
        );
        QmatchPerf.mark(
          'super_resonance.availability_refresh_end',
          tapSw.elapsed,
        );
        if (!mounted) return;
        _applyAvailability(availability);
      }

      if (availability.totalAvailable > 0) {
        QmatchPerf.mark('super_resonance.confirm_sheet_open', tapSw.elapsed);
        final confirmSw = Stopwatch()..start();
        final confirmed = await showQMatchSuperResonanceConfirmSheet(
          context,
          candidateName: c.name,
          purchasedBalance: availability.purchasedBalance,
          dailyRemaining: availability.dailyRemaining,
          dailyLimit: availability.dailyLimit,
        );
        QmatchPerf.log('super_resonance.tap.confirm_open', confirmSw.elapsed);
        if (!confirmed || !mounted) return;
        setState(() => _superResonanceBusy = true);
        var sendSucceeded = false;
        try {
          QmatchPerf.mark(
            'super_resonance.send_callable_start',
            tapSw.elapsed,
          );
          final result = await QmatchPerf.trace(
            'super_resonance.tap.send',
            () => _superResonance.send(targetUid: c.uid),
          );
          QmatchPerf.mark(
            'super_resonance.send_callable_end',
            tapSw.elapsed,
          );
          if (!mounted) return;
          _applySendResult(result);
          _superResonance.applyTrustedSendResult(result);
          sendSucceeded = true;
        } catch (e, st) {
          debugPrint('Discover Super Resonance send failed: $e\n$st');
          if (!mounted) return;
          _showSuperResonanceError(
            AppLocalizations.of(context)!.discoverSuperResonanceSendFailed,
          );
          QmatchPerf.mark(
            'super_resonance.balance_refresh_start',
            tapSw.elapsed,
          );
          await QmatchPerf.trace(
            'super_resonance.tap.balance_refresh',
            _refreshSuperResonanceBalance,
          );
          QmatchPerf.mark(
            'super_resonance.balance_refresh_end',
            tapSw.elapsed,
          );
        } finally {
          if (mounted) setState(() => _superResonanceBusy = false);
        }
        if (!mounted || !sendSucceeded) return;
        QmatchPerf.mark(
          'super_resonance.balance_refresh_start',
          tapSw.elapsed,
        );
        await QmatchPerf.trace(
          'super_resonance.tap.balance_refresh',
          _refreshSuperResonanceBalance,
        );
        QmatchPerf.mark(
          'super_resonance.balance_refresh_end',
          tapSw.elapsed,
        );
        return;
      }

      QmatchPerf.mark('super_resonance.purchase_sheet_open', tapSw.elapsed);
      await showQMatchSuperResonancePurchaseSheet(
        context,
        trustedBalance: availability.purchasedBalance,
        purchaseThenReadBalance: _superResonance.purchaseThenReadBalance,
        loadLocalizedPrice: _superResonance.loadLocalizedPrice,
      );
      if (!mounted) return;
      QmatchPerf.mark(
        'super_resonance.balance_refresh_start',
        tapSw.elapsed,
      );
      await QmatchPerf.trace(
        'super_resonance.tap.balance_refresh',
        _refreshSuperResonanceBalance,
      );
      QmatchPerf.mark(
        'super_resonance.balance_refresh_end',
        tapSw.elapsed,
      );
    } catch (e, st) {
      debugPrint('Discover Super Resonance failed: $e\n$st');
      if (!mounted) return;
      _showSuperResonanceError(
        AppLocalizations.of(context)!.discoverSuperResonanceSendFailed,
      );
      QmatchPerf.mark(
        'super_resonance.balance_refresh_start',
        tapSw.elapsed,
      );
      await QmatchPerf.trace(
        'super_resonance.tap.balance_refresh',
        _refreshSuperResonanceBalance,
      );
      QmatchPerf.mark(
        'super_resonance.balance_refresh_end',
        tapSw.elapsed,
      );
    } finally {
      _superResonanceSheetOpen = false;
      QmatchPerf.mark('super_resonance.ui_idle_again', tapSw.elapsed);
      QmatchPerf.log('super_resonance.tap.total', tapSw.elapsed);
    }
  }

  Future<void> _onPass() async {
    final c = _currentCandidate;
    if (c == null || _isActionLoading) return;
    if (_likeDispatchedUids.contains(c.uid)) return;
    final isLast = _isLastCandidate;
    setState(() {
      _isActionLoading = true;
      if (isLast) _lastCardCommitted = true;
    });
    try {
      if (isLast) {
        await Future.wait<void>([
          _swipeService.passUser(c.uid),
          Future<void>.delayed(QMatchDiscoverSwipeableCard.flyOffDuration),
        ]);
      } else {
        await _swipeService.passUser(c.uid);
      }
      if (!mounted) return;
      await _noteCommittedSwipe();
      if (!mounted) return;
      _advance();
    } catch (e, st) {
      debugPrint('Discover pass failed: $e\n$st');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.discoverActionFailed),
            backgroundColor: AppColors.error,
          ),
        );
        if (isLast) setState(() => _lastCardCommitted = false);
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _onLike() async {
    final c = _currentCandidate;
    if (c == null) return;
    if (!_likeDispatchedUids.add(c.uid)) return;

    final isLast = _isLastCandidate;
    if (isLast) setState(() => _lastCardCommitted = true);

    final likeTapSw = Stopwatch()..start();
    QmatchPerf.mark('match.like_tap');

    // Trusted callable — dialog waits only on this, never on fly-off / push.
    QmatchPerf.mark('match.callable_start', likeTapSw.elapsed);
    final likeFuture = _swipeService.likeUser(c.uid).then((outcome) {
      QmatchPerf.mark('match.callable_response', likeTapSw.elapsed);
      return outcome;
    });

    // Card fly-off + stamp bookkeeping run in parallel; must not gate dialog.
    unawaited(() async {
      await _noteCommittedSwipe();
      await Future<void>.delayed(QMatchDiscoverSwipeableCard.flyOffDuration);
      if (mounted) _advance();
    }());

    try {
      final outcome = await likeFuture;
      if (!mounted) return;
      if (outcome == LikeMatchOutcome.createdNewMatch) {
        QmatchPerf.mark('match.created_new_match', likeTapSw.elapsed);
        QmatchPerf.mark('match.dialog_show', likeTapSw.elapsed);
        final l10n = AppLocalizations.of(context)!;
        final me = FirebaseAuth.instance.currentUser;
        final threadId = me == null
            ? null
            : FirestorePaths.deterministicThreadId(me.uid, c.uid);
        final action = await showQMatchDiscoverMatchDialog(
          context: context,
          title: l10n.discoverItsAMatch,
          body: l10n.discoverMatchDialogBody,
          openChatLabel: l10n.discoverMatchOpenChat,
          continueLabel: l10n.continueAction,
          quickGreetings: [
            l10n.discoverMatchGreetingHi,
            l10n.discoverMatchGreetingHello,
            l10n.discoverMatchGreetingHowsItGoing,
          ],
          sendFailedLabel: l10n.discoverMatchGreetingSendFailed,
          onSendGreeting: (text) async {
            final id = threadId;
            if (id == null || id.isEmpty) {
              throw StateError('Missing thread for quick greeting.');
            }
            await ChatService().sendTextMessage(id, text);
          },
        );
        if (!mounted) return;
        if (action == DiscoverMatchDialogAction.openChat) {
          if (me != null && threadId != null) {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatDetailScreen(
                  threadId: threadId,
                  otherUserId: c.uid,
                  otherUserName: c.name,
                ),
              ),
            );
          }
        }
      }
    } catch (e, st) {
      debugPrint('Discover like failed: $e\n$st');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.discoverActionFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onLikeFromActionBar() {
    _onLike();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DiscoverGestureOnboardingTabSync(
      store: _gestureOnboardingStore,
      onShowChanged: _onGestureOnboardingShowChanged,
      child: Scaffold(
        key: const Key('qmatch-discover-screen'),
        backgroundColor: Colors.transparent,
        body: QMatchCosmicBackground(
          key: const Key('qmatch-discover-cosmic'),
          seed: 21,
          starCount: 18,
          animate: widget.animateBackground,
          showAccentHalos: false,
          starfieldOpacity: 0.38,
          child: SafeArea(
            child: Column(
              children: [
                if (_deletionPending) _buildDeletionPendingBanner(context),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWhoLikedYou() async {
    final entry = widget.whoLikedYouEntry ?? WhoLikedYouEntry();
    await entry.openFromDiscover(context);
  }

  Future<bool> _openPassportPaywall(
    BuildContext context,
    ResonancePaywallFeature feature,
  ) {
    final custom = widget.openPaywall;
    if (custom != null) {
      return custom(context, feature);
    }
    return ResonancePaywallScreen.open(
      context,
      feature: feature,
    );
  }

  Future<void> _openPassportPicker() async {
    final changed = await PassportDestinationPickerScreen.open(
      context,
      client: _passportClient,
      initial: _passportSnapshot,
      openPaywall: _openPassportPaywall,
      animateBackground: widget.animateBackground != false,
    );
    if (!mounted) return;
    if (changed) {
      await _loadCandidates();
    } else {
      try {
        final snap = await _passportClient.get();
        if (!mounted) return;
        setState(() => _passportSnapshot = snap);
      } catch (_) {}
    }
  }

  Future<void> _turnPassportOff() async {
    try {
      await _passportClient.disable();
      if (!mounted) return;
      await _loadCandidates();
    } catch (e, st) {
      debugPrint('Passport disable failed: $e\n$st');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.discoverActionFailed)),
      );
    }
  }

  Widget _buildHeader(
    AppLocalizations l10n, {
    bool debugReplay = false,
  }) {
    final header = QMatchDiscoverHeader(
      title: l10n.discoverTitle,
      chip: QMatchDiscoverPassportChip(
        snapshot: _passportSnapshot,
        onPressed: _openPassportPicker,
      ),
      trailing: QMatchGlassIconButton(
        key: const Key('qmatch-discover-who-liked-you'),
        icon: Icons.favorite_border,
        tooltip: l10n.whoLikedYouTitle,
        semanticLabel: l10n.whoLikedYouTitle,
        onPressed: _openWhoLikedYou,
      ),
    );
    if (debugReplay && kDebugMode) {
      return GestureDetector(
        key: const Key('qmatch-discover-debug-replay-tutorial'),
        onLongPress: _debugReplayGestureOnboarding,
        child: header,
      );
    }
    return header;
  }

  Widget _buildDeletionPendingBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.glassSurfaceStrong,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderSubtle.withValues(alpha: 0.8),
            ),
          ),
        ),
        child: Text(
          l10n.discoverAccountDeletionPendingBanner,
          style: const TextStyle(
            color: AppColors.softGold,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(l10n),
          Expanded(
            child: QMatchDiscoverLoadingState(message: l10n.discoverLoading),
          ),
        ],
      );
    }

    if (_hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(l10n),
          Expanded(
            child: QMatchDiscoverErrorState(
              title: l10n.discoverErrorTitle,
              body: l10n.discoverErrorBody,
              retryLabel: l10n.retry,
              onRetry: _loadCandidates,
            ),
          ),
        ],
      );
    }

    final c = _currentCandidate;
    if (c == null) {
      final passportEmpty = _queryPlan.passportActive;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(l10n),
          Expanded(
            child: QMatchDiscoverEmptyState(
              emptyKey: passportEmpty
                  ? const Key('qmatch-discover-passport-empty')
                  : const Key('qmatch-discover-empty'),
              title: passportEmpty
                  ? l10n.discoverPassportEmptyTitle
                  : l10n.discoverEmptyTitle,
              body: passportEmpty
                  ? l10n.discoverPassportEmptyBody
                  : l10n.discoverEmptySubtitle,
              retryLabel: passportEmpty
                  ? l10n.discoverPassportChangeDestination
                  : l10n.discoverEmptyRetry,
              onRetry: passportEmpty ? _openPassportPicker : _loadCandidates,
              secondaryLabel:
                  passportEmpty ? l10n.discoverPassportUseWorldwide : null,
              onSecondary: passportEmpty ? _turnPassportOff : null,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(l10n, debugReplay: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Stack(
              fit: StackFit.expand,
              children: [
                QMatchDiscoverSwipeableCard(
                  candidateId: c.uid,
                  enabled: !_isActionLoading && !_showGestureOnboarding,
                  showSwipeStamps:
                      DiscoverGestureOnboardingStore.showSwipeStamps(
                    _committedSwipeCount,
                  ),
                  likeLabel: l10n.discoverLike,
                  passLabel: l10n.discoverPass,
                  onLike: _onLike,
                  onPass: _onPass,
                  onSwipeFeedback: _onSwipeFeedback,
                  child: QMatchCandidateCard(
                    candidate: c,
                    showLegacyCompatibilityUi: _discoverService
                        .rankingMode.usesLegacyCompatibilityScoring,
                  ),
                ),
                if (_showGestureOnboarding)
                  QMatchDiscoverGestureOnboarding(
                    swipeRightText: l10n.discoverGestureOnboardingSwipeRight,
                    swipeLeftText: l10n.discoverGestureOnboardingSwipeLeft,
                    gotItLabel: l10n.discoverGestureOnboardingGotIt,
                    onCompleted: _completeGestureOnboarding,
                    animate: widget.animateBackground != false,
                  ),
              ],
            ),
          ),
        ),
        if (!_lastCardCommitted)
          QMatchDiscoverActionBar(
            passLabel: l10n.discoverPass,
            likeLabel: l10n.discoverLike,
            onPass: (_isActionLoading ||
                    _showGestureOnboarding ||
                    _likeDispatchedUids.contains(c.uid))
                ? null
                : _onPass,
            onLike: (_isActionLoading ||
                    _showGestureOnboarding ||
                    _likeDispatchedUids.contains(c.uid))
                ? null
                : _onLikeFromActionBar,
            isActionLoading: _isActionLoading,
            subdued: _showGestureOnboarding,
            swipeFeedback: _swipeFeedback,
            showSuperResonance: true,
            superResonanceLabel: l10n.discoverSuperResonance,
            isSuperResonanceLoading: _superResonanceBusy,
            superResonanceBalance: _superResonanceBalance,
            onSuperResonance: (_isActionLoading ||
                    _showGestureOnboarding ||
                    _superResonanceBusy ||
                    _likeDispatchedUids.contains(c.uid))
                ? null
                : _onSuperResonance,
          ),
      ],
    );
  }
}
