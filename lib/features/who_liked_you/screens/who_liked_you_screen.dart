import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/firestore_paths.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../discover/utils/discover_identity_format.dart';
import '../../discover/widgets/qmatch_candidate_photo.dart';
import '../../discover/widgets/qmatch_discover_match_dialog.dart';
import '../../iap/domain/resonance_paywall_feature.dart';
import '../../iap/screens/resonance_paywall_screen.dart';
import '../../matching/services/like_match_outcome.dart';
import '../../matching/services/swipe_service.dart';
import '../../messages/screens/chat_detail_screen.dart';
import '../../profile/utils/profile_option_labels.dart';
import '../domain/alignment_signal_merge.dart';
import '../domain/who_liked_you_card.dart';
import '../services/super_resonance_inbox_client.dart';
import '../services/who_liked_you_client.dart';

/// Who Liked You inbox. Identities only from trusted `listWhoLikedYou`.
class WhoLikedYouScreen extends StatefulWidget {
  const WhoLikedYouScreen({
    super.key,
    this.client,
    this.superResonanceInbox,
    this.likeUser,
    this.passUser,
    this.onUnlock,
    this.currentUidProvider,
    this.animateBackground,
  });

  final WhoLikedYouClient? client;

  /// Trusted Super Resonance inbox. Tests inject a fake.
  final SuperResonanceInboxClient? superResonanceInbox;

  /// Production uses [SwipeService.likeUser]. Tests inject a fake.
  final Future<LikeMatchOutcome> Function(String uid)? likeUser;

  /// Production uses [SwipeService.passUser]. Tests inject a fake.
  final Future<void> Function(String uid)? passUser;

  /// Production opens the existing Resonance paywall, then reloads.
  final Future<void> Function()? onUnlock;

  final String? Function()? currentUidProvider;

  final bool? animateBackground;

  @override
  State<WhoLikedYouScreen> createState() => _WhoLikedYouScreenState();
}

class _WhoLikedYouScreenState extends State<WhoLikedYouScreen> {
  late final WhoLikedYouClient _client;
  late final SuperResonanceInboxClient _inbox;
  late final Future<LikeMatchOutcome> Function(String uid) _likeUser;
  late final Future<void> Function(String uid) _passUser;

  bool _loading = true;
  bool _hasError = false;
  bool _busy = false;
  bool _resonanceAccess = false;
  List<WhoLikedYouCard> _items = const [];

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? WhoLikedYouClient();
    _inbox = widget.superResonanceInbox ?? SuperResonanceInboxClient();
    _likeUser = widget.likeUser ?? _productionLike;
    _passUser = widget.passUser ?? _productionPass;
    _fetch();
  }

  static Future<LikeMatchOutcome> _productionLike(String uid) =>
      SwipeService().likeUser(uid);

  static Future<void> _productionPass(String uid) =>
      SwipeService().passUser(uid);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    await _fetch();
  }

  Future<void> _fetch() async {
    WhoLikedYouResult? ordinary;
    Object? ordinaryError;
    List<WhoLikedYouCard>? superItems;
    Object? superError;

    await Future.wait<void>([
      () async {
        try {
          ordinary = await _client.list();
        } catch (e) {
          ordinaryError = e;
        }
      }(),
      () async {
        try {
          superItems = await _inbox.list();
        } catch (e) {
          superError = e;
        }
      }(),
    ]);

    if (!mounted) return;

    final superList = superItems ?? const <WhoLikedYouCard>[];
    final access = ordinary?.resonanceAccess == true;
    final ordinaryItems =
        access ? List<WhoLikedYouCard>.from(ordinary!.items) : const <WhoLikedYouCard>[];
    final merged = mergeAlignmentSignals(
      superResonance: superList,
      ordinary: ordinaryItems,
    );

    final bothFailed = ordinaryError != null && superError != null;
    final ordinaryFailedEmpty = ordinaryError != null && merged.isEmpty;
    if (bothFailed || ordinaryFailedEmpty) {
      setState(() {
        _hasError = true;
        _resonanceAccess = false;
        _items = const [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _resonanceAccess = access;
      _items = merged;
      _loading = false;
      _hasError = false;
    });
  }

  void _removeLocal(String uid) {
    setState(() {
      _items = _items.where((c) => c.uid != uid).toList(growable: false);
    });
  }

  Future<void> _onPass(WhoLikedYouCard card) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _passUser(card.uid);
      if (!mounted) return;
      _removeLocal(card.uid);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.discoverActionFailed),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onLike(WhoLikedYouCard card) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final outcome = await _likeUser(card.uid);
      if (!mounted) return;
      _removeLocal(card.uid);
      if (outcome == LikeMatchOutcome.createdNewMatch) {
        await _handleMatchSuccess(card);
      }
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.discoverActionFailed),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleMatchSuccess(WhoLikedYouCard card) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showQMatchDiscoverMatchDialog(
      context: context,
      title: l10n.discoverItsAMatch,
      body: l10n.discoverMatchDialogBody,
      openChatLabel: l10n.discoverMatchOpenChat,
      continueLabel: l10n.continueAction,
    );
    if (!mounted) return;
    if (action != DiscoverMatchDialogAction.openChat) return;
    final me = widget.currentUidProvider?.call() ??
        FirebaseAuth.instance.currentUser?.uid;
    if (me == null || me.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailScreen(
          threadId: FirestorePaths.deterministicThreadId(me, card.uid),
          otherUserId: card.uid,
          otherUserName: card.name,
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    final custom = widget.onUnlock;
    if (custom != null) {
      await custom();
      if (mounted) await _load();
      return;
    }
    await ResonancePaywallScreen.open(
      context,
      feature: ResonancePaywallFeature.whoLikedYou,
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      key: const Key('qmatch-who-liked-you-screen'),
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 83,
        animate: widget.animateBackground,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                title: l10n.whoLikedYouTitle,
                backButtonKey: const Key('qmatch-who-liked-you-back'),
                titleKey: const Key('qmatch-who-liked-you-title'),
              ),
              Expanded(child: _buildBody(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return Center(
        child: Semantics(
          label: l10n.whoLikedYouLoading,
          child: const CircularProgressIndicator(
            key: Key('qmatch-who-liked-you-loading'),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDAC8ED)),
          ),
        ),
      );
    }
    if (_hasError) {
      return _MessageState(
        key: const Key('qmatch-who-liked-you-error'),
        title: l10n.whoLikedYouErrorTitle,
        body: l10n.whoLikedYouErrorBody,
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }
    if (_items.isNotEmpty) {
      return ListView.separated(
        key: const Key('qmatch-who-liked-you-list'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final card = _items[index];
          return _WhoLikedYouCardView(
            card: card,
            busy: _busy,
            onLike: () => _onLike(card),
            onPass: () => _onPass(card),
          );
        },
      );
    }
    if (!_resonanceAccess) {
      return _MessageState(
        key: const Key('qmatch-who-liked-you-free-discovery'),
        title: l10n.whoLikedYouFreeDiscoveryTitle,
        body: l10n.whoLikedYouFreeDiscoveryBody,
        actionLabel: l10n.resonanceUnlockCta,
        actionKey: const Key('qmatch-who-liked-you-unlock'),
        onAction: _unlock,
      );
    }
    return _MessageState(
      key: const Key('qmatch-who-liked-you-empty'),
      title: l10n.whoLikedYouEmptyTitle,
      body: l10n.whoLikedYouEmptyBody,
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.actionKey,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: QGlassCard(
          emphasized: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                QCosmicButton(
                  key: actionKey,
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: QCosmicButtonVariant.cosmic,
                  pill: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WhoLikedYouCardView extends StatelessWidget {
  const _WhoLikedYouCardView({
    required this.card,
    required this.busy,
    required this.onLike,
    required this.onPass,
  });

  final WhoLikedYouCard card;
  final bool busy;
  final VoidCallback onLike;
  final VoidCallback onPass;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final identity = formatDiscoverIdentity(name: card.name, age: card.age);

    return QGlassCard(
      key: Key('qmatch-who-liked-you-card-${card.uid}'),
      emphasized: true,
      padding: EdgeInsets.zero,
      color: card.superResonance
          ? AppColors.cosmicPurple.withValues(alpha: 0.22)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.card),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  QMatchCandidatePhoto(
                    photoUrl: card.primaryPhotoUrl,
                    semanticLabel: l10n.discoverPhotoSemanticLabel(
                      identity ?? card.name,
                    ),
                    missingPhotoLabel: l10n.discoverMissingPhotoLabel,
                  ),
                  if (card.superResonance)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: _SuperResonanceMarker(
                        uid: card.uid,
                        label: l10n.discoverSuperResonance,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  identity ?? card.name,
                  key: Key('qmatch-who-liked-you-name-${card.uid}'),
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (card.superResonance) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    key: Key('qmatch-who-liked-you-super-label-${card.uid}'),
                    l10n.discoverSuperResonance,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFDAC8ED),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (card.bio.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    card.bio,
                    key: Key('qmatch-who-liked-you-bio-${card.uid}'),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
                if (card.interests.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final interest in card.interests.take(12))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.glassSurface,
                            borderRadius: AppRadii.pillBorder,
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Text(
                            ProfileOptionLabels.interest(l10n, interest),
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: QCosmicButton(
                        key: Key('qmatch-who-liked-you-pass-${card.uid}'),
                        label: l10n.discoverPass,
                        onPressed: busy ? null : onPass,
                        variant: QCosmicButtonVariant.ghost,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: QCosmicButton(
                        key: Key('qmatch-who-liked-you-like-${card.uid}'),
                        label: l10n.discoverLike,
                        onPressed: busy ? null : onLike,
                        variant: QCosmicButtonVariant.cosmic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _lilac = Color(0xFFDAC8ED);

class _SuperResonanceMarker extends StatelessWidget {
  const _SuperResonanceMarker({
    required this.uid,
    required this.label,
  });

  final String uid;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: DecoratedBox(
        key: Key('qmatch-who-liked-you-super-marker-$uid'),
        decoration: BoxDecoration(
          color: AppColors.cosmicPurple.withValues(alpha: 0.86),
          borderRadius: AppRadii.pillBorder,
          border: Border.all(color: _lilac.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: AppColors.resonanceViolet.withValues(alpha: 0.35),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 16,
            color: _lilac,
          ),
        ),
      ),
    );
  }
}
