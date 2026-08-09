import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/identity/identity.dart';
import '../../../core/navigation/auth_routing_refresh.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../assessment/widgets/frequency_question_chrome.dart';
import '../../assessment/widgets/q_assessment_scaffold.dart';
import '../services/display_name_service.dart';
import '../widgets/profile_setup_chrome.dart';

/// Gate screen: collect and persist canonical `users/{uid}.name`.
class DisplayNameCompletionScreen extends StatefulWidget {
  const DisplayNameCompletionScreen({
    super.key,
    this.displayNameService,
    this.onCompleted,
    this.overrideUid,
  });

  final DisplayNameStore? displayNameService;

  /// Tests: invoked after a successful save instead of remounting AuthWrapper.
  final VoidCallback? onCompleted;

  /// Test/override uid when Firebase Auth is unavailable.
  final String? overrideUid;

  @override
  State<DisplayNameCompletionScreen> createState() =>
      _DisplayNameCompletionScreenState();
}

class _DisplayNameCompletionScreenState
    extends State<DisplayNameCompletionScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  late final DisplayNameStore _service =
      widget.displayNameService ?? DisplayNameService();

  bool _loadingPrefill = true;
  bool _saving = false;
  DisplayNameValidationError? _error;
  String? _saveError;

  String? get _uid => widget.overrideUid ?? AuthService().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {
          _error = null;
          _saveError = null;
        }));
    _loadPrefill();
  }

  Future<void> _loadPrefill() async {
    final uid = _uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingPrefill = false);
      return;
    }
    try {
      final prefill = await _service.prefillCandidate(uid);
      if (!mounted) return;
      _controller.text = prefill;
    } finally {
      if (mounted) setState(() => _loadingPrefill = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _messageFor(DisplayNameValidationError error, AppLocalizations l10n) {
    switch (error) {
      case DisplayNameValidationError.empty:
        return l10n.displayNameErrorEmpty;
      case DisplayNameValidationError.tooShort:
        return l10n.displayNameErrorTooShort;
      case DisplayNameValidationError.tooLong:
        return l10n.displayNameErrorTooLong;
      case DisplayNameValidationError.missingLetterOrNumber:
        return l10n.displayNameErrorLetterOrNumber;
      case DisplayNameValidationError.controlCharacters:
        return l10n.displayNameErrorInvalid;
      case DisplayNameValidationError.emailLike:
        return l10n.displayNameErrorEmailLike;
      case DisplayNameValidationError.phoneLike:
        return l10n.displayNameErrorPhoneLike;
      case DisplayNameValidationError.urlLike:
        return l10n.displayNameErrorUrlLike;
    }
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context)!;
    final uid = _uid;
    if (uid == null) return;

    final result = DisplayNameValidator.validate(_controller.text);
    if (!result.isValid) {
      setState(() => _error = result.error);
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
      _error = null;
    });

    try {
      await _service.saveCanonicalDisplayName(
        uid: uid,
        rawInput: _controller.text,
      );
      if (!mounted) return;
      if (widget.onCompleted != null) {
        widget.onCompleted!();
        return;
      }
      AuthRoutingRefresh.bump();
      setState(() => _saving = false);
    } catch (e) {
      debugPrint('DisplayNameCompletion save failed: $e');
      if (mounted) {
        setState(() {
          _saveError = l10n.displayNameErrorSaveFailed;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count =
        DisplayNameValidator.normalize(_controller.text).characters.length;
    final max = DisplayNameContract.maxGraphemes;

    return QAssessmentScaffold(
      key: const Key('qmatch-display-name-completion'),
      richBackdrop: true,
      backgroundImageAsset: ProfileSetupChrome.cosmicBackgroundAsset,
      child: _loadingPrefill
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.softGold),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom:
                        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AppSpacing.md,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(flex: 2),
                          Text(
                            l10n.displayNameTitle,
                            style: ProfileSetupChrome.stepTitleStyle(
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.displayNameSubtitle,
                            style: ProfileSetupChrome.stepSubtitleStyle(),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ProfileSetupChrome.label(l10n.displayNameLabel),
                          TextField(
                            key: const Key('qmatch-display-name-field'),
                            controller: _controller,
                            focusNode: _focus,
                            enabled: !_saving,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [],
                            enableSuggestions: false,
                            autocorrect: false,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(
                                RegExp(r'[\r\n\t]'),
                              ),
                            ],
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                            ),
                            cursorColor: AppColors.softGold,
                            decoration: ProfileSetupChrome.fieldDecoration(
                              l10n.displayNameHint,
                            ).copyWith(counterText: ''),
                            onSubmitted: (_) => _continue(),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.displayNamePublicExplanation,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              Text(
                                key: const Key('qmatch-display-name-count'),
                                '$count / $max',
                                style: GoogleFonts.inter(
                                  color: count > max
                                      ? AppColors.danger
                                      : AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              key: const Key('qmatch-display-name-error'),
                              _messageFor(_error!, l10n),
                              style: GoogleFonts.inter(
                                color: AppColors.danger,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (_saveError != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _saveError!,
                              style: GoogleFonts.inter(
                                color: AppColors.danger,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const Spacer(flex: 3),
                          FrequencyContinueButton(
                            key: const Key('qmatch-display-name-continue'),
                            label: _saving
                                ? l10n.displayNameSaving
                                : l10n.assessmentContinue,
                            onPressed: _saving ? () {} : _continue,
                            active: !_saving,
                            saving: _saving,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
