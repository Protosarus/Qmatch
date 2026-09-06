import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_feedback.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../iap/domain/resonance_paywall_feature.dart';
import '../../iap/screens/resonance_paywall_screen.dart';
import '../domain/discover_passport_snapshot.dart';
import '../domain/passport_destination_catalog.dart';
import '../services/discover_passport_client.dart';

/// v1 Passport destination picker: country + city search/select only.
///
/// No map, GPS, geohash, or precise coordinates.
class PassportDestinationPickerScreen extends StatefulWidget {
  const PassportDestinationPickerScreen({
    super.key,
    required this.client,
    required this.initial,
    this.openPaywall,
    this.animateBackground = true,
  });

  final DiscoverPassportClient client;
  final DiscoverPassportSnapshot initial;
  final Future<bool> Function(
    BuildContext context,
    ResonancePaywallFeature feature,
  )? openPaywall;
  final bool animateBackground;

  /// Returns true when Discover should reload (destination set or Worldwide).
  static Future<bool> open(
    BuildContext context, {
    required DiscoverPassportClient client,
    required DiscoverPassportSnapshot initial,
    Future<bool> Function(
      BuildContext context,
      ResonancePaywallFeature feature,
    )? openPaywall,
    bool animateBackground = true,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PassportDestinationPickerScreen(
          client: client,
          initial: initial,
          openPaywall: openPaywall,
          animateBackground: animateBackground,
        ),
      ),
    );
    return result == true;
  }

  @override
  State<PassportDestinationPickerScreen> createState() =>
      _PassportDestinationPickerScreenState();
}

class _PassportDestinationPickerScreenState
    extends State<PassportDestinationPickerScreen> {
  final TextEditingController _search = TextEditingController();
  late DiscoverPassportSnapshot _snapshot;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initial;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<bool> _paywall(BuildContext context) {
    final custom = widget.openPaywall;
    if (custom != null) {
      return custom(context, ResonancePaywallFeature.passport);
    }
    return ResonancePaywallScreen.open(
      context,
      feature: ResonancePaywallFeature.passport,
    );
  }

  Future<void> _select(PassportDestination city) async {
    if (_busy) return;
    if (!_snapshot.resonanceAccess) {
      final unlocked = await _paywall(context);
      if (!unlocked || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final next = await widget.client.set(
        country: city.countryCode,
        city: city.citySlug,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      _snapshot = next;
    } on DiscoverPassportResonanceRequiredException {
      if (!mounted) return;
      setState(() => _busy = false);
      await _paywall(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      QMatchFeedback.show(
        context,
        message: AppLocalizations.of(context)!.discoverActionFailed,
        type: QMatchFeedbackType.error,
      );
    }
  }

  Future<void> _useWorldwide() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.client.disable();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      QMatchFeedback.show(
        context,
        message: AppLocalizations.of(context)!.discoverActionFailed,
        type: QMatchFeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final turkish = Localizations.localeOf(context).languageCode == 'tr';
    final results = PassportDestinationCatalog.search(
      _search.text,
      turkish: turkish,
    );
    return Scaffold(
      key: const Key('qmatch-passport-picker'),
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 17,
        starCount: 14,
        animate: widget.animateBackground,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                title: l10n.discoverPassportPickerTitle,
                titleKey: const Key('qmatch-passport-picker-title'),
                backButtonKey: const Key('qmatch-passport-picker-back'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: TextField(
                  key: const Key('qmatch-passport-picker-search'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  cursorColor: AppColors.softGold,
                  decoration: InputDecoration(
                    hintText: l10n.discoverPassportPickerSearch,
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF141A2E).withValues(alpha: 0.45),
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.buttonBorder,
                      borderSide: const BorderSide(
                        color: Color(0x66A8B0D0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadii.buttonBorder,
                      borderSide: const BorderSide(
                        color: Color(0x66A8B0D0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadii.buttonBorder,
                      borderSide: const BorderSide(color: AppColors.softGold),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: QCosmicButton(
                  key: const Key('qmatch-passport-use-worldwide'),
                  label: l10n.discoverPassportUseWorldwide,
                  onPressed: _busy ? null : _useWorldwide,
                  variant: QCosmicButtonVariant.glass,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final city = results[index];
                    final selected = _snapshot.passportEnabled &&
                        _snapshot.passportCountry == city.countryCode &&
                        _snapshot.passportCity == city.citySlug;
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        key: Key(
                          'qmatch-passport-city-${city.countryCode}-${city.citySlug}',
                        ),
                        enabled: !_busy,
                        onTap: () => _select(city),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadii.buttonBorder,
                        ),
                        title: Text(
                          city.cityLabel(turkish),
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          city.countryLabel(turkish),
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check,
                                color: AppColors.softGold,
                              )
                            : (!_snapshot.resonanceAccess
                                ? const Icon(
                                    Icons.lock_outline,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  )
                                : null),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
