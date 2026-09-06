import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/debug/qmatch_perf.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/firestore_paths.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_feedback.dart';
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
import '../../messages/services/chat_service.dart';
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

  /// Temporary audit: wall clock from screen open → first content.
  final Stopwatch _loadSw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _loadSw.start();
    QmatchPerf.mark('alignment_signals.screen_open');
    _client = widget.client ?? WhoLikedYouClient();
    _inbox = widget.superResonanceInbox ?? SuperResonanceInboxClient();
    _likeUser = widget.likeUser ?? _productionLike;
    _passUser = widget.passUser ?? _productionPass;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    });
    _fetch();
  }

  static Future<LikeMatchOutcome> _productionLike(String uid) async {
    final result = await SwipeService().likeUser(uid);
    return result.outcome;
  }

  static Future<void> _productionPass(String uid) =>
      SwipeService().passUser(uid);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    _loadSw
      ..reset()
      ..start();
    QmatchPerf.mark('alignment_signals.screen_open');
    await _fetch();
  }

  Future<void> _fetch() async {
    WhoLikedYouResult? ordinary;
    Object? ordinaryError;
    List<WhoLikedYouCard>? superItems;
    Object? superError;

    await QmatchPerf.trace('alignment_signals', () async {
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
    });

    if (!mounted) return;

    final superList = superItems ?? const <WhoLikedYouCard>[];
    final access = ordinary?.resonanceAccess == true;
    final ordinaryItems = access
        ? List<WhoLikedYouCard>.from(ordinary!.items)
        : const <WhoLikedYouCard>[];
    final merged = QmatchPerf.traceSync(
      'alignment_signals.local_filter_sort',
      () => mergeAlignmentSignals(
        superResonance: superList,
        ordinary: ordinaryItems,
      ),
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
      _markFirstContentReady(const []);
      return;
    }

    setState(() {
      _resonanceAccess = access;
      _items = merged;
      _loading = false;
      _hasError = false;
    });
    _markFirstContentReady(merged);
  }

  void _markFirstContentReady(List<WhoLikedYouCard> items) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      QmatchPerf.mark(
        'alignment_signals.first_content_ready',
        _loadSw.elapsed,
      );
      QmatchPerf.mark('alignment_signals.total', _loadSw.elapsed);
      _probeFirstImageCache(items);
    });
  }

  /// Debug-only: time first photo decode/cache hit. Does not gate UI.
  void _probeFirstImageCache(List<WhoLikedYouCard> items) {
    if (!QmatchPerf.enabled) return;
    String? url;
    for (final card in items) {
      final candidate = card.primaryPhotoUrl?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        url = candidate;
        break;
      }
    }
    if (url == null) {
      QmatchPerf.mark('alignment_signals.image_cache_work', Duration.zero);
      return;
    }
    final sw = Stopwatch()..start();
    final provider = NetworkImage(url);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        sw.stop();
        QmatchPerf.log('alignment_signals.image_cache_work', sw.elapsed);
        stream.removeListener(listener);
      },
      onError: (Object _, StackTrace? __) {
        sw.stop();
        QmatchPerf.log('alignment_signals.image_cache_work', sw.elapsed);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
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
      QMatchFeedback.show(
        context,
        message: l10n.discoverActionFailed,
        type: QMatchFeedbackType.error,
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
      QMatchFeedback.show(
        context,
        message: l10n.discoverActionFailed,
        type: QMatchFeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleMatchSuccess(WhoLikedYouCard card) async {
    final l10n = AppLocalizations.of(context)!;
    final me = widget.currentUidProvider?.call() ??
        FirebaseAuth.instance.currentUser?.uid;
    final threadId = (me == null || me.isEmpty)
        ? null
        : FirestorePaths.deterministicThreadId(me, card.uid);
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
    if (action != DiscoverMatchDialogAction.openChat) return;
    if (me == null || me.isEmpty || threadId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailScreen(
          threadId: threadId,
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
      return _AlignmentSignalsLoadingState(
        message: l10n.whoLikedYouLoading,
      );
    }
    if (_hasError) {
      return _MessageState(
        key: const Key('qmatch-who-liked-you-error'),
        icon: Icons.cloud_off_rounded,
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
        itemCount: _items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                key: const Key('qmatch-who-liked-you-list-caption'),
                l10n.whoLikedYouListCaption,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            );
          }
          final card = _items[index - 1];
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
        icon: Icons.auto_awesome_rounded,
        title: l10n.whoLikedYouFreeDiscoveryTitle,
        body: l10n.whoLikedYouFreeDiscoveryBody,
        actionLabel: l10n.resonanceUnlockCta,
        actionKey: const Key('qmatch-who-liked-you-unlock'),
        onAction: _unlock,
      );
    }
    return _MessageState(
      key: const Key('qmatch-who-liked-you-empty'),
      icon: Icons.bolt_rounded,
      title: l10n.whoLikedYouEmptyTitle,
      body: l10n.whoLikedYouEmptyBody,
    );
  }
}

class _AlignmentSignalsLoadingState extends StatelessWidget {
  const _AlignmentSignalsLoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Semantics(
          label: message,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  key: Key('qmatch-who-liked-you-loading'),
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDAC8ED)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.actionLabel,
    this.actionKey,
    this.onAction,
  });

  final String title;
  final String body;
  final IconData? icon;
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
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.textGold,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
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
    final short = MediaQuery.sizeOf(context).height < 700;
    final photoHeight = short ? 180.0 : 220.0;

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
            height: photoHeight,
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
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x66060A10),
                          Color(0xAA060A10),
                        ],
                        stops: [0.5, 0.78, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Text(
                      identity ?? card.name,
                      key: Key('qmatch-who-liked-you-name-${card.uid}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.textPrimary,
                        fontSize: short ? 20 : 22,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
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
                  key: Key('qmatch-who-liked-you-cue-${card.uid}'),
                  card.superResonance
                      ? l10n.whoLikedYouSuperCue
                      : l10n.whoLikedYouAlignedCue,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFDAC8ED),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (card.bio.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    card.bio,
                    key: Key('qmatch-who-liked-you-bio-${card.uid}'),
                    maxLines: short ? 3 : 5,
                    overflow: TextOverflow.ellipsis,
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
                      for (final interest in card.interests.take(8))
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
