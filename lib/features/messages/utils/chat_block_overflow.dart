import '../../../l10n/app_localizations.dart';

/// Exactly one block-related overflow action.
enum ChatBlockOverflowAction { block, unblock }

ChatBlockOverflowAction chatBlockOverflowAction({required bool blockedByMe}) {
  return blockedByMe
      ? ChatBlockOverflowAction.unblock
      : ChatBlockOverflowAction.block;
}

String chatBlockOverflowValue({required bool blockedByMe}) {
  return chatBlockOverflowAction(blockedByMe: blockedByMe).name;
}

String chatBlockOverflowLabel(
  AppLocalizations l10n, {
  required bool blockedByMe,
}) {
  return blockedByMe ? l10n.unblock : l10n.chatMenuBlock;
}
