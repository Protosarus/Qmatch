import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: QMatchCosmicBackground(
        seed: 37,
        child: SafeArea(
          child: Column(
            children: [
              QMatchPushedScreenHeader(
                key: const Key('qmatch-blocked-header'),
                title: l10n.blockedUsersTitle,
                backButtonKey: const Key('qmatch-blocked-back'),
                titleKey: const Key('qmatch-blocked-title'),
              ),
              Expanded(
                child: uid == null
                    ? Center(
                        child: Text(
                          l10n.loginRequired,
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                      )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('blocks')
                            .orderBy('created_at', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.softGold,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: QGlassCard(
                                child: Text(
                                  l10n.blockedUsersLoadFailed,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data?.docs ?? const [];
                          if (docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                  l10n.noBlockedUsers,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.xl,
                            ),
                            itemCount: docs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, i) {
                              final doc = docs[i];
                              final data = doc.data();
                              final blockedUid =
                                  (data['blocked_uid'] as String?) ?? doc.id;

                              return QGlassCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.danger
                                            .withValues(alpha: 0.14),
                                        border: Border.all(
                                          color: AppColors.danger
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.block,
                                        color: AppColors.danger,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            blockedUid,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            l10n.blockedUsersBlockedAt,
                                            style: GoogleFonts.inter(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: null,
                                      child: Text(
                                        l10n.unblock,
                                        style: GoogleFonts.inter(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
