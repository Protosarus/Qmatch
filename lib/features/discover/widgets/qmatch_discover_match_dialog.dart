import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';

/// Result of the mutual-match success dialog.
enum DiscoverMatchDialogAction {
  openChat,
  continueDiscover,
  sentQuickGreeting,
}

/// Match modal surface — opaque dark glass (lilac language, not gold).
const Color _matchLilac = Color(0xFFDAC8ED);
const Color _matchPanelFill = Color(0xEB12182C); // ~92% opaque navy
const Color _matchBarrier = Color(0xB8000000); // ~72% dim
const double _matchBackdropBlur = 18;
const double _matchPanelBlur = 22;

/// Mutual-match dialog body (presentation only).
class QMatchDiscoverMatchDialogContent extends StatefulWidget {
  const QMatchDiscoverMatchDialogContent({
    super.key,
    required this.title,
    required this.body,
    required this.openChatLabel,
    required this.continueLabel,
    required this.quickGreetings,
    required this.sendFailedLabel,
    required this.onSendGreeting,
    required this.onOpenChat,
    required this.onContinue,
    required this.onGreetingSent,
  });

  final String title;
  final String body;
  final String openChatLabel;
  final String continueLabel;
  final List<String> quickGreetings;
  final String sendFailedLabel;
  final Future<void> Function(String text) onSendGreeting;
  final VoidCallback onOpenChat;
  final VoidCallback onContinue;
  final VoidCallback onGreetingSent;

  @override
  State<QMatchDiscoverMatchDialogContent> createState() =>
      _QMatchDiscoverMatchDialogContentState();
}

class _QMatchDiscoverMatchDialogContentState
    extends State<QMatchDiscoverMatchDialogContent> {
  bool _sending = false;
  bool _sendFailed = false;

  Future<void> _onGreetingTap(String text) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _sendFailed = false;
    });
    try {
      await widget.onSendGreeting(text);
      if (!mounted) return;
      widget.onGreetingSent();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const Key('qmatch-discover-match-dialog'),
      borderRadius: AppRadii.cardBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _matchPanelBlur,
          sigmaY: _matchPanelBlur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadii.cardBorder,
            color: _matchPanelFill,
            border: Border.all(
              color: _matchLilac.withValues(alpha: 0.42),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.resonanceViolet.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.cosmicBlack.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingComfortable),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.resonanceViolet.withValues(alpha: 0.28),
                    border: Border.all(
                      color: _matchLilac.withValues(alpha: 0.55),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  // Zoom into brain↔heart; crop corner icons / outer geometry.
                  child: Transform.scale(
                    scale: 1.72,
                    alignment: const Alignment(0, -0.14),
                    child: const Image(
                      image: AssetImage('assets/images/eq_intro_figure.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment(0, -0.06),
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MatchQuickGreetingRow(
                  greetings: widget.quickGreetings,
                  enabled: !_sending,
                  onTap: _onGreetingTap,
                ),
                if (_sendFailed) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    key: const Key('qmatch-discover-match-greeting-error'),
                    widget.sendFailedLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary.withValues(alpha: 0.92),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                QCosmicButton(
                  key: const Key('qmatch-discover-match-open-chat'),
                  label: widget.openChatLabel,
                  onPressed: _sending ? null : widget.onOpenChat,
                  variant: QCosmicButtonVariant.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MatchContinueButton(
                  key: const Key('qmatch-discover-match-continue'),
                  label: widget.continueLabel,
                  onPressed: _sending ? null : widget.onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchQuickGreetingRow extends StatelessWidget {
  const _MatchQuickGreetingRow({
    required this.greetings,
    required this.enabled,
    required this.onTap,
  });

  final List<String> greetings;
  final bool enabled;
  final Future<void> Function(String text) onTap;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('qmatch-discover-match-greetings'),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (var i = 0; i < greetings.length; i++)
            _MatchGreetingChip(
              key: Key('qmatch-discover-match-greeting-$i'),
              label: greetings[i],
              enabled: enabled,
              onTap: () => onTap(greetings[i]),
            ),
        ],
      ),
    );
  }
}

class _MatchGreetingChip extends StatelessWidget {
  const _MatchGreetingChip({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        splashColor: _matchLilac.withValues(alpha: 0.12),
        child: Opacity(
          opacity: enabled ? 1 : AppColors.disabledOpacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColors.glassSurfaceStrong.withValues(alpha: 0.62),
              border: Border.all(
                color: _matchLilac.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: _matchLilac.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary CTA — glass fill + lilac outline (not gold ghost).
class _MatchContinueButton extends StatelessWidget {
  const _MatchContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = AppRadii.buttonBorder;
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      child: Opacity(
        opacity: enabled ? 1 : AppColors.disabledOpacity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            splashColor: _matchLilac.withValues(alpha: 0.14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.buttonHorizontal,
                vertical: AppSpacing.buttonVertical + 2,
              ),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: AppColors.glassSurfaceStrong.withValues(alpha: 0.55),
                border: Border.all(
                  color: _matchLilac.withValues(alpha: 0.72),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _matchLilac.withValues(alpha: 0.95),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.35,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mutual-match confirmation — Open chat, Continue, or quick greeting send.
Future<DiscoverMatchDialogAction?> showQMatchDiscoverMatchDialog({
  required BuildContext context,
  required String title,
  required String body,
  required String openChatLabel,
  required String continueLabel,
  required List<String> quickGreetings,
  required String sendFailedLabel,
  required Future<void> Function(String text) onSendGreeting,
}) {
  return showDialog<DiscoverMatchDialogAction>(
    context: context,
    barrierDismissible: false,
    barrierColor: _matchBarrier,
    builder: (ctx) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _matchBackdropBlur,
          sigmaY: _matchBackdropBlur,
        ),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: QMatchDiscoverMatchDialogContent(
            title: title,
            body: body,
            openChatLabel: openChatLabel,
            continueLabel: continueLabel,
            quickGreetings: quickGreetings,
            sendFailedLabel: sendFailedLabel,
            onSendGreeting: onSendGreeting,
            onOpenChat: () =>
                Navigator.of(ctx).pop(DiscoverMatchDialogAction.openChat),
            onContinue: () =>
                Navigator.of(ctx).pop(DiscoverMatchDialogAction.continueDiscover),
            onGreetingSent: () =>
                Navigator.of(ctx).pop(DiscoverMatchDialogAction.sentQuickGreeting),
          ),
        ),
      );
    },
  );
}
