import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qmatch/core/navigation/qmatch_main_shell.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/core/widgets/cosmic/qmatch_cosmic_background.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';
import 'package:qmatch/features/discover/widgets/discover_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';

/// Test-only Discover scene composer for goldens (no production routes).
class DiscoverGoldenScene extends StatelessWidget {
  const DiscoverGoldenScene({
    super.key,
    required this.variant,
    this.candidate,
    this.photoImageProvider,
    this.includeShell = false,
    this.isActionLoading = false,
  });

  final DiscoverGoldenVariant variant;
  final DiscoverUserModel? candidate;
  final ImageProvider? photoImageProvider;
  final bool includeShell;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    final body = Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: QMatchCosmicBackground(
            seed: 21,
            starCount: 18,
            animate: false,
            child: SafeArea(
              child: switch (variant) {
                DiscoverGoldenVariant.loading => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QMatchDiscoverHeader(title: l10n.discoverTitle),
                      Expanded(
                        child: QMatchDiscoverLoadingState(
                          message: l10n.discoverLoading,
                        ),
                      ),
                    ],
                  ),
                DiscoverGoldenVariant.empty => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QMatchDiscoverHeader(title: l10n.discoverTitle),
                      Expanded(
                        child: QMatchDiscoverEmptyState(
                          title: l10n.discoverEmptyTitle,
                          body: l10n.discoverEmptySubtitle,
                          retryLabel: l10n.retry,
                          onRetry: () {},
                        ),
                      ),
                    ],
                  ),
                DiscoverGoldenVariant.error => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QMatchDiscoverHeader(title: l10n.discoverTitle),
                      Expanded(
                        child: QMatchDiscoverErrorState(
                          title: l10n.discoverErrorTitle,
                          body: l10n.discoverErrorBody,
                          retryLabel: l10n.retry,
                          onRetry: () {},
                        ),
                      ),
                    ],
                  ),
                DiscoverGoldenVariant.candidate => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QMatchDiscoverHeader(title: l10n.discoverTitle),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: QMatchCandidateCard(
                            candidate: candidate!,
                            photoImageProvider: photoImageProvider,
                          ),
                        ),
                      ),
                      QMatchDiscoverActionBar(
                        passLabel: l10n.discoverPass,
                        likeLabel: l10n.discoverLike,
                        onPass: isActionLoading ? null : () {},
                        onLike: isActionLoading ? null : () {},
                        isActionLoading: isActionLoading,
                      ),
                    ],
                  ),
                DiscoverGoldenVariant.matchDialog => Stack(
                    children: [
                      Column(
                        children: [
                          QMatchDiscoverHeader(title: l10n.discoverTitle),
                          const Spacer(),
                        ],
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: QMatchDiscoverMatchDialogContent(
                            title: l10n.discoverItsAMatch,
                            body: l10n.discoverMatchDialogBody,
                            openChatLabel: l10n.discoverMatchOpenChat,
                            continueLabel: l10n.continueAction,
                            onOpenChat: () {},
                            onContinue: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
              },
            ),
          ),
        );
      },
    );

    if (!includeShell) {
      return body;
    }

    return QMatchMainShell(
      currentIndex: 0,
      onTabSelected: (_) {},
      pages: [
        body,
        const SizedBox.shrink(),
        const SizedBox.shrink(),
      ],
      items: const [
        QMatchBottomNavigationItem(
          icon: Icons.explore_rounded,
          label: 'Discover',
        ),
        QMatchBottomNavigationItem(
          icon: Icons.chat_bubble_rounded,
          label: 'Messages',
        ),
        QMatchBottomNavigationItem(
          icon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
    );
  }
}

enum DiscoverGoldenVariant {
  loading,
  empty,
  error,
  candidate,
  matchDialog,
}

Widget wrapDiscoverGolden({
  required Widget child,
  required Size surfaceSize,
  double textScale = 1.0,
  EdgeInsets padding = const EdgeInsets.only(bottom: 34),
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: MediaQuery(
      data: MediaQueryData(
        size: surfaceSize,
        padding: padding,
        viewPadding: padding,
        textScaler: TextScaler.linear(textScale),
        devicePixelRatio: 1.0,
      ),
      child: SizedBox(
        width: surfaceSize.width,
        height: surfaceSize.height,
        child: child,
      ),
    ),
  );
}
