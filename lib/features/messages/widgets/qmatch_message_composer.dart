import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Modern multi-line message composer (presentation only — send via callback).
class QMatchMessageComposer extends StatelessWidget {
  const QMatchMessageComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onSend,
    this.onAttachment,
    this.sending = false,
    this.enabled = true,
    this.sendSemanticLabel,
    this.attachmentSemanticLabel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;
  final bool sending;

  /// When false, field and send are disabled (no send action).
  final bool enabled;
  final String? sendSemanticLabel;
  final String? attachmentSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('qmatch-chat-composer'),
      color: AppColors.glassSurfaceStrong,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onAttachment != null) ...[
                Semantics(
                  button: true,
                  label: attachmentSemanticLabel ?? 'Add attachment',
                  child: IconButton(
                    key: const Key('qmatch-chat-composer-attachment'),
                    onPressed: (!enabled || sending) ? null : onAttachment,
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFFDAC8ED),
                      minimumSize: const Size(44, 48),
                    ),
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    key: const Key('qmatch-chat-composer-field'),
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled && !sending,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    cursorColor: const Color(0xFFDAC8ED),
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceElevated.withValues(
                        alpha: 0.92,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color:
                              const Color(0xFFDAC8ED).withValues(alpha: 0.55),
                          width: 1.4,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: AppColors.borderSubtle.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: sendSemanticLabel ?? 'Send',
                child: IconButton.filled(
                  key: const Key('qmatch-chat-composer-send'),
                  onPressed: (!enabled || sending) ? null : onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.resonanceViolet,
                    foregroundColor: AppColors.textPrimary,
                    disabledBackgroundColor:
                        AppColors.resonanceViolet.withValues(alpha: 0.35),
                    minimumSize: const Size(48, 48),
                  ),
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
