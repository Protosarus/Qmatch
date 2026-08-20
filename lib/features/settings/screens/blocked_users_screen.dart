import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/cosmic/qmatch_cosmic_background.dart';
import '../../../core/widgets/qmatch_pushed_screen_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../safety/services/safety_service.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({
    super.key,
    this.unblockUser,
    this.blocksStream,
  });

  /// Tests inject [SafetyService.unblockUser]. Production is null.
  @visibleForTesting
  final Future<void> Function({required String blockedUid})? unblockUser;

  /// Tests inject live blocked-uid list. Production is null.
  @visibleForTesting
  final Stream<List<String>>? blocksStream;

  Stream<List<String>> _blocksStream(String uid) {
    return blocksStream ??
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('blocks')
            .orderBy('created_at', descending: true)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map(
                    (d) => (d.data()['blocked_uid'] as String?) ?? d.id,
                  )
                  .toList(),
            );
  }

  Future<void> _unblock(String blockedUid) {
    final injected = unblockUser;
    if (injected != null) {
      return injected(blockedUid: blockedUid);
    }
    return SafetyService().unblockUser(blockedUid: blockedUid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final injectedBlocks = blocksStream;
    final uid = injectedBlocks != null
        ? 'test'
        : FirebaseAuth.instance.currentUser?.uid;

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
                    : StreamBuilder<List<String>>(
                        stream: _blocksStream(uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData &&
                              !snapshot.hasError) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.resonanceViolet,
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

                          final ids = snapshot.data ?? const <String>[];
                          if (ids.isEmpty) {
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
                            itemCount: ids.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, i) {
                              final blockedUid = ids[i];
                              return QMatchBlockedUserTile(
                                blockedUid: blockedUid,
                                onUnblock: () async {
                                  try {
                                    await _unblock(blockedUid);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.chatActionFailed),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                },
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

class QMatchBlockedUserTile extends StatelessWidget {
  const QMatchBlockedUserTile({
    super.key,
    required this.blockedUid,
    required this.onUnblock,
  });

  final String blockedUid;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return QGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.danger.withValues(alpha: 0.14),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.25),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
            key: Key('qmatch-blocked-unblock-$blockedUid'),
            onPressed: onUnblock,
            child: Text(
              l10n.unblock,
              style: GoogleFonts.inter(
                color: AppColors.resonanceViolet,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
