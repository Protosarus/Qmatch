import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/firestore_paths.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../matching/services/like_match_outcome.dart';
import '../../matching/services/swipe_service.dart';
import '../../messages/screens/chat_detail_screen.dart';
import '../../settings/services/account_deletion_request_service.dart';
import '../models/discover_user_model.dart';
import '../services/discover_gesture_onboarding_store.dart';
import '../services/discover_service.dart';
import '../widgets/discover_widgets.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.animateBackground,
    this.gestureOnboardingStore,
  });

  /// Goldens / reduced-motion: freeze cosmic breathing when false.
  final bool? animateBackground;

  /// Test injection for gesture tutorial persistence.
  final DiscoverGestureOnboardingStore? gestureOnboardingStore;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final DiscoverService _discoverService = DiscoverService();
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
  List<DiscoverUserModel> _candidates = [];
  int _currentIndex = 0;
  final Set<String> _likeDispatchedUids = <String>{};
  late final DiscoverGestureOnboardingStore _gestureOnboardingStore;

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
    _gestureOnboardingStore = widget.gestureOnboardingStore ??
        DiscoverGestureOnboardingStore(
          viewerUid: FirebaseAuth.instance.currentUser?.uid,
        );
    DiscoverGestureOnboardingStore.guidanceRevision
        .addListener(_onGuidanceRevision);
    _loadDeletionPending();
    _loadCandidates();
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
      final list = await _discoverService.getCandidates(limit: 30);
      if (!mounted) return;
      setState(() {
        _candidates = list;
        _currentIndex = 0;
        _lastCardCommitted = false;
        _isLoading = false;
        _hasError = false;
      });
      await _syncFirstUseGuidanceFromStore();
    } catch (e, st) {
      debugPrint('Discover load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _candidates = [];
        _currentIndex = 0;
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
    });
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

    final likeFuture = _swipeService.likeUser(c.uid);
    await _noteCommittedSwipe();
    await Future<void>.delayed(QMatchDiscoverSwipeableCard.flyOffDuration);
    if (mounted) _advance();

    try {
      final outcome = await likeFuture;
      if (!mounted) return;
      if (outcome == LikeMatchOutcome.createdNewMatch) {
        final l10n = AppLocalizations.of(context)!;
        final action = await showQMatchDiscoverMatchDialog(
          context: context,
          title: l10n.discoverItsAMatch,
          body: l10n.discoverMatchDialogBody,
          openChatLabel: l10n.discoverMatchOpenChat,
          continueLabel: l10n.continueAction,
        );
        if (!mounted) return;
        if (action == DiscoverMatchDialogAction.openChat) {
          final me = FirebaseAuth.instance.currentUser;
          if (me != null) {
            final threadId =
                FirestorePaths.deterministicThreadId(me.uid, c.uid);
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
          QMatchDiscoverHeader(title: l10n.discoverTitle),
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
          QMatchDiscoverHeader(title: l10n.discoverTitle),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QMatchDiscoverHeader(title: l10n.discoverTitle),
          Expanded(
            child: QMatchDiscoverEmptyState(
              title: l10n.discoverEmptyTitle,
              body: l10n.discoverEmptySubtitle,
              retryLabel: l10n.discoverEmptyRetry,
              onRetry: _loadCandidates,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kDebugMode
            ? GestureDetector(
                key: const Key('qmatch-discover-debug-replay-tutorial'),
                onLongPress: _debugReplayGestureOnboarding,
                child: QMatchDiscoverHeader(title: l10n.discoverTitle),
              )
            : QMatchDiscoverHeader(title: l10n.discoverTitle),
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
            onPass:
                (_isActionLoading || _showGestureOnboarding) ? null : _onPass,
            onLike:
                (_isActionLoading || _showGestureOnboarding) ? null : _onLike,
            isActionLoading: _isActionLoading,
            subdued: _showGestureOnboarding,
          ),
      ],
    );
  }
}
