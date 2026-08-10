import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Discover/Messages/PhotoEdit loading+focus accents use lavender', () {
    const lavender = '0xFFDAC8ED';
    final loadingFiles = [
      'lib/features/discover/widgets/qmatch_candidate_photo.dart',
      'lib/features/discover/widgets/qmatch_discover_loading_state.dart',
      'lib/features/messages/widgets/qmatch_messages_loading_state.dart',
      'lib/features/messages/widgets/qmatch_conversation_avatar.dart',
      'lib/features/messages/widgets/qmatch_chat_states.dart',
      'lib/features/messages/widgets/qmatch_message_composer.dart',
      'lib/features/profile/screens/profile_photo_edit_screen.dart',
    ];
    for (final path in loadingFiles) {
      final src = File(path).readAsStringSync();
      expect(src.contains(lavender), isTrue, reason: path);
    }

    // Loading spinners no longer softGold.
    for (final path in [
      'lib/features/discover/widgets/qmatch_candidate_photo.dart',
      'lib/features/discover/widgets/qmatch_discover_loading_state.dart',
      'lib/features/messages/widgets/qmatch_messages_loading_state.dart',
      'lib/features/messages/widgets/qmatch_conversation_avatar.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(
        src.contains('AlwaysStoppedAnimation<Color>(AppColors.softGold)'),
        isFalse,
        reason: path,
      );
    }

    final composer =
        File('lib/features/messages/widgets/qmatch_message_composer.dart')
            .readAsStringSync();
    expect(
      composer.contains('AppColors.softGold.withValues(alpha: 0.55)'),
      isFalse,
    );

    final photoEdit =
        File('lib/features/profile/screens/profile_photo_edit_screen.dart')
            .readAsStringSync();
    expect(photoEdit.contains('color: AppColors.softGold,'), isTrue,
        reason: 'primary badge/star brand gold kept');
    expect(
      photoEdit.contains('CircularProgressIndicator(\n                        strokeWidth: 2,\n                        color: Color(0xFFDAC8ED)'),
      isTrue,
    );
  });
}
