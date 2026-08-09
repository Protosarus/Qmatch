import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import 'profile_setup_chrome.dart';

class ProfileSetupSelectOption<T> {
  const ProfileSetupSelectOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

/// Glass field that opens a cosmic bottom-sheet picker (replaces Material dropdown).
class ProfileSetupSelectField<T> extends StatelessWidget {
  const ProfileSetupSelectField({
    super.key,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<ProfileSetupSelectOption<T>> options;
  final ValueChanged<T> onChanged;

  String? get _selectedLabel {
    if (value == null) return null;
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final selected = await showProfileSetupPicker<T>(
      context: context,
      options: options,
      selected: value,
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final label = _selectedLabel;
    final hasValue = label != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: AppRadii.buttonBorder,
        child: Ink(
          decoration: ProfileSetupChrome.glassFieldDecoration(
            emphasized: hasValue,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? label : hint,
                    style: hasValue
                        ? ProfileSetupChrome.fieldTextStyle()
                        : ProfileSetupChrome.hintStyle(),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ProfileSetupChrome.accentIcon,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showProfileSetupPicker<T>({
  required BuildContext context,
  required List<ProfileSetupSelectOption<T>> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    isScrollControlled: true,
    builder: (context) {
      final maxH = MediaQuery.sizeOf(context).height * 0.62;
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: AppRadii.sheetBorder,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.sheetBorder,
                  color: const Color(0xFF141A2E).withValues(alpha: 0.82),
                  border: Border.all(
                    color: ProfileSetupChrome.borderFocus,
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x554D25D2).withValues(alpha: 0.35),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final opt = options[index];
                          final isSelected = opt.value == selected;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context, opt.value),
                              borderRadius: AppRadii.buttonBorder,
                              child: Ink(
                                decoration: isSelected
                                    ? BoxDecoration(
                                        borderRadius: AppRadii.buttonBorder,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xB34C25C9),
                                            Color(0xA06D34DA),
                                            Color(0x99D89C47),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: const Color(0x99F2D08A),
                                        ),
                                      )
                                    : BoxDecoration(
                                        borderRadius: AppRadii.buttonBorder,
                                        color: Colors.white
                                            .withValues(alpha: 0.04),
                                        border: Border.all(
                                          color: ProfileSetupChrome.borderIdle,
                                        ),
                                      ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          opt.label,
                                          style: GoogleFonts.inter(
                                            color: AppColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_rounded,
                                          color: ProfileSetupChrome.accentIcon,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
