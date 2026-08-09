import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qmatch/core/navigation/qmatch_main_shell.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/core/theme/app_spacing.dart';
import 'package:qmatch/features/messages/widgets/messages_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';

import 'messages_golden_fixtures.dart';

enum MessagesGoldenVariant {
  loading,
  empty,
  error,
  list,
}

/// Test-only Messages inbox scene (no production routes / Firebase).
class MessagesGoldenScene extends StatelessWidget {
  const MessagesGoldenScene({
    super.key,
    required this.variant,
    this.conversations = const [],
    this.includeShell = false,
  });

  final MessagesGoldenVariant variant;
  final List<MessagesConversationFixture> conversations;
  final bool includeShell;

  @override
  Widget build(BuildContext context) {
    final body = Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QMatchMessagesHeader(title: l10n.messagesTitle),
                Expanded(
                  child: switch (variant) {
                    MessagesGoldenVariant.loading => QMatchMessagesLoadingState(
                        message: l10n.messagesLoading,
                      ),
                    MessagesGoldenVariant.empty => QMatchMessagesEmptyState(
                        title: l10n.messagesEmptyTitle,
                        body: l10n.messagesEmptySubtitle,
                      ),
                    MessagesGoldenVariant.error => QMatchMessagesErrorState(
                        title: l10n.messagesLoadErrorTitle,
                        body: l10n.messagesLoadErrorSubtitle,
                        retryLabel: l10n.retry,
                        onRetry: () {},
                      ),
                    MessagesGoldenVariant.list => ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        itemCount: conversations.length,
                        separatorBuilder: (_, __) =>
                            const QMatchConversationListSeparator(),
                        itemBuilder: (context, index) {
                          final c = conversations[index];
                          return QMatchConversationTile(
                            displayName: c.displayName,
                            age: c.age,
                            photoUrl: c.photoUrl,
                            photoImageProvider: c.photoImageProvider,
                            previewText: c.previewText,
                            timestampText: c.timestampText,
                            unreadCount: c.unreadCount,
                            avatarSemanticLabel:
                                l10n.messagesAvatarSemanticLabel(c.displayName),
                            unreadSemanticLabel: c.unreadCount > 0
                                ? l10n.messagesUnreadSemanticLabel(
                                    c.unreadCount,
                                  )
                                : null,
                            onTap: () {},
                          );
                        },
                      ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!includeShell) {
      return ColoredBox(color: AppColors.background, child: body);
    }

    return QMatchMainShell(
      currentIndex: 1,
      onTabSelected: (_) {},
      pages: [
        const SizedBox.shrink(),
        body,
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

Widget wrapMessagesGolden({
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
