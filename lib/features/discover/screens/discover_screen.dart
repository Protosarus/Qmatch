import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../matching/services/swipe_service.dart';
import '../../settings/services/account_deletion_request_service.dart';
import '../models/discover_user_model.dart';
import '../services/discover_service.dart';
import '../widgets/discover_widgets.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    this.animateBackground,
  });

  /// Goldens / reduced-motion: freeze cosmic breathing when false.
  final bool? animateBackground;

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
  List<DiscoverUserModel> _candidates = [];
  int _currentIndex = 0;

  DiscoverUserModel? get _currentCandidate {
    if (_currentIndex < 0 || _currentIndex >= _candidates.length) {
      return null;
    }
    return _candidates[_currentIndex];
  }

  @override
  void initState() {
    super.initState();
    _loadDeletionPending();
    _loadCandidates();
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
    });
    try {
      final list = await _discoverService.getCandidates(limit: 30);
      if (!mounted) return;
      setState(() {
        _candidates = list;
        _currentIndex = 0;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e, st) {
      debugPrint('Discover load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _candidates = [];
        _currentIndex = 0;
        _isLoading = false;
      });
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
    setState(() => _isActionLoading = true);
    try {
      await _swipeService.passUser(c.uid);
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
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _onLike() async {
    final c = _currentCandidate;
    if (c == null || _isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      final matched = await _swipeService.likeUser(c.uid);
      if (!mounted) return;
      if (matched) {
        final l10n = AppLocalizations.of(context)!;
        await showQMatchDiscoverMatchDialog(
          context: context,
          title: l10n.discoverItsAMatch,
          body: l10n.discoverMatchDialogBody,
          continueLabel: l10n.continueAction,
        );
      }
      if (mounted) _advance();
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
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('qmatch-discover-screen'),
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        key: const Key('qmatch-discover-cosmic'),
        seed: 21,
        starCount: 18,
        animate: widget.animateBackground,
        showAccentHalos: false,
        starfieldOpacity: 0.22,
        child: SafeArea(
          child: Column(
            children: [
              if (_deletionPending) _buildDeletionPendingBanner(context),
              Expanded(child: _buildBody()),
            ],
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
              retryLabel: l10n.retry,
              onRetry: _loadCandidates,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QMatchDiscoverHeader(title: l10n.discoverTitle),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: QMatchCandidateCard(candidate: c),
          ),
        ),
        QMatchDiscoverActionBar(
          passLabel: l10n.discoverPass,
          likeLabel: l10n.discoverLike,
          onPass: _isActionLoading ? null : _onPass,
          onLike: _isActionLoading ? null : _onLike,
          isActionLoading: _isActionLoading,
        ),
      ],
    );
  }
}
