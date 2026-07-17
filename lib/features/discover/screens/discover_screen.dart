import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../assessment/utils/assessment_language.dart';
import '../../assessment/utils/assessment_result_display_resolver.dart';
import '../models/discover_user_model.dart';
import '../services/discover_service.dart';
import '../../matching/services/swipe_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/utils/profile_option_labels.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final DiscoverService _discoverService = DiscoverService();
  final SwipeService _swipeService = SwipeService();

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;
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
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _discoverService.getCandidates(limit: 30);
      if (!mounted) return;
      setState(() {
        _candidates = list;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
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
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.discoverItsAMatch,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              l10n.discoverMatchDialogBody,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  l10n.continueAction,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      if (mounted) _advance();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadCandidates,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final c = _currentCandidate;
    if (c == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.discoverEmptyTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.discoverEmptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: _loadCandidates,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.discoverTitle,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _CandidateCard(candidate: c)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isActionLoading ? null : _onPass,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.discoverPass, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isActionLoading ? null : _onLike,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isActionLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(l10n.discoverLike, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final DiscoverUserModel candidate;

  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final url = candidate.primaryPhotoUrl;
    final compatibilityLabel = candidate.compatibilityLabel == null
        ? null
        : _localizeCompatibilityLabel(l10n, candidate.compatibilityLabel!);
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 280,
              child: url == null
                  ? Container(
                      color: Colors.grey.shade900,
                      child: Icon(Icons.person, size: 100, color: AppColors.primary.withValues(alpha: 0.5)),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 280,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${candidate.displayName}, ${candidate.age}',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (candidate.compatibilityLabel != null ||
                      candidate.compatibilityScore != null ||
                      (candidate.compatibilityReasons?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (compatibilityLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              compatibilityLabel,
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (candidate.compatibilityScore != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Text(
                              l10n.discoverPercentCompatibility(
                                ((candidate.compatibilityScore!.clamp(0.0, 1.0)) * 100)
                                    .round(),
                              ),
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (candidate.compatibilityReasons != null &&
                        candidate.compatibilityReasons!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: candidate.compatibilityReasons!
                            .take(3)
                            .map(
                              (r) => Chip(
                                label: Text(
                                  _localizeCompatibilityReason(l10n, r),
                                  style: GoogleFonts.inter(color: Colors.black, fontSize: 11),
                                ),
                                backgroundColor: AppColors.primary.withValues(alpha: 0.35),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                  if (candidate.archetype != null || candidate.category != null) ...[
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final languageCode = AssessmentLanguage.languageUsed(
                          languageCode:
                              Localizations.maybeLocaleOf(context)?.languageCode,
                        );
                        final fromCategory = (candidate.category != null &&
                                candidate.category!.isNotEmpty)
                            ? AssessmentResultDisplayResolver.resolveIqEqLevel(
                                candidate.category!,
                                languageCode: languageCode,
                              )
                            : null;
                        final fromName = (candidate.archetype != null &&
                                candidate.archetype!.isNotEmpty)
                            ? AssessmentResultDisplayResolver
                                .resolveArchetypeLabel(
                                candidate.archetype!,
                                languageCode: languageCode,
                              )
                            : null;
                        final primary = fromCategory ?? fromName;
                        if (primary == null) {
                          return const SizedBox.shrink();
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                primary.title,
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                            if (primary.tags.isNotEmpty)
                              Chip(
                                label: Text(
                                  primary.tags.first,
                                  style: GoogleFonts.inter(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.7),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                  if (candidate.bio.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      candidate.bio,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (candidate.interests.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      l10n.discoverInterests,
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: candidate.interests.take(12).map((i) {
                        return Chip(
                          label: Text(
                            ProfileOptionLabels.interest(l10n, i),
                            style: GoogleFonts.inter(color: Colors.black, fontSize: 11),
                          ),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.35),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    candidate.compatibilityHintLocalized(
                      AssessmentLanguage.languageUsed(
                        languageCode:
                            Localizations.maybeLocaleOf(context)?.languageCode,
                      ),
                    ),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _localizeCompatibilityLabel(AppLocalizations l10n, String labelKey) {
  switch (labelKey) {
    case 'exceptional':
      return l10n.compatibilityLabelExceptional;
    case 'strong':
      return l10n.compatibilityLabelStrong;
    case 'good':
      return l10n.compatibilityLabelGood;
    case 'potential':
      return l10n.compatibilityLabelPotential;
    case 'low_signal':
      return l10n.compatibilityLabelLowSignal;
    default:
      return labelKey;
  }
}

String _localizeCompatibilityReason(AppLocalizations l10n, String reasonKey) {
  switch (reasonKey) {
    case 'archetype':
      return l10n.compatReasonArchetype;
    case 'thinking':
      return l10n.compatReasonThinking;
    case 'emotional':
      return l10n.compatReasonEmotional;
    case 'frequency':
      return l10n.compatReasonFrequency;
    case 'interests':
      return l10n.compatReasonInterests;
    case 'recency':
      return l10n.compatReasonRecency;
    default:
      return reasonKey;
  }
}
