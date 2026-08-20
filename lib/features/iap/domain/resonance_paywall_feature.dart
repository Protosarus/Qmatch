/// Paywall / unlock surface ids from `qmatch_resonance_paywall_tease_ux_v1`.
enum ResonancePaywallFeature {
  settingsResonance('settings_resonance'),
  whoLikedYou('who_liked_you'),
  rewind('rewind'),
  deeperCompatibility('deeper_compatibility'),
  advancedFilters('advanced_filters'),
  likeLimit('like_limit'),
  passport('passport');

  const ResonancePaywallFeature(this.analyticsValue);
  final String analyticsValue;
}
