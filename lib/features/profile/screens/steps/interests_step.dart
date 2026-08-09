import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/profile_option_labels.dart';
import '../../widgets/profile_setup_chrome.dart';

class InterestsStep extends StatelessWidget {
  final List<String> interests;
  final Function(List<String>) onInterestsChanged;

  const InterestsStep({
    super.key,
    required this.interests,
    required this.onInterestsChanged,
  });

  static const Map<String, List<String>> _interestCategories = {
    'Spor': [
      'Futbol',
      'Basketbol',
      'Tenis',
      'Yüzme',
      'Yoga',
      'Fitness',
      'Voleybol',
      'Pilates',
      'Koşu',
      'Bisiklet',
      'Dağcılık',
      'Jimnastik',
      'Boks',
      'Yelken',
      'Golf'
    ],
    'Sanat': [
      'Müzik',
      'Resim',
      'Sinema',
      'Tiyatro',
      'Dans',
      'Edebiyat',
      'Fotoğrafçılık',
      'Heykel',
      'Grafik Tasarım',
      'Şiir',
      'Yazarlık',
      'Stand-up',
      'Enstrüman Çalmak',
      'Opera',
      'Bale'
    ],
    'Teknoloji': [
      'Kodlama',
      'Oyun',
      'AI/ML',
      'Kripto',
      'Web3',
      'Robotik',
      'Siber Güvenlik',
      'Veri Bilimi',
      'Mobil Uygulama',
      'Blockchain',
      'IoT',
      'Cloud Computing'
    ],
    'Seyahat': [
      'Kamp',
      'Doğa',
      'Yurt Dışı',
      'Kültür Turları',
      'Safari',
      'Gastro Turlar',
      'Extreme Sporlar',
      'Backpacking',
      'Lüks Tatil',
      'Tarihi Yerler',
      'Plaj Tatili',
      'Solo Seyahat'
    ],
  };

  void _toggleInterest(String interest) {
    final newInterests = List<String>.from(interests);

    if (newInterests.contains(interest)) {
      newInterests.remove(interest);
    } else {
      if (newInterests.length < 5) {
        newInterests.add(interest);
      }
    }

    onInterestsChanged(newInterests);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileInterestsTitle,
            style: ProfileSetupChrome.stepTitleStyle(),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.profileInterestsMaxSelect(interests.length),
            style: ProfileSetupChrome.stepSubtitleStyle(),
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._interestCategories.entries.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 12),
                  child: Text(
                    ProfileOptionLabels.interest(l10n, category.key),
                    style: GoogleFonts.inter(
                      color: ProfileSetupChrome.accentLabel,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.value.map((interest) {
                    final isSelected = interests.contains(interest);
                    final canSelect = interests.length < 5 || isSelected;

                    return GestureDetector(
                      onTap: canSelect ? () => _toggleInterest(interest) : null,
                      child: Opacity(
                        opacity: canSelect ? 1 : 0.45,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: isSelected
                              ? ProfileSetupChrome.selectedChipDecoration()
                              : ProfileSetupChrome.idleChipDecoration(),
                          child: Text(
                            ProfileOptionLabels.interest(l10n, interest),
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
