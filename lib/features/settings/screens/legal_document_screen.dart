import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';

/// Simple scrollable legal / policy document viewer.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 47,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-legal-header'),
                title: title,
                backButtonKey: const Key('qmatch-legal-back'),
                titleKey: const Key('qmatch-legal-title'),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    QGlassCard(
                      child: Text(
                        body,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
