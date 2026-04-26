// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addPhotos => 'ADD PHOTOS';

  @override
  String photosUploaded(int count) {
    return '$count photos uploaded';
  }

  @override
  String get setAsMain => 'Set as Main Photo';

  @override
  String get delete => 'Delete';

  @override
  String get mainPhotoUpdated => '⭐ Main photo updated';

  @override
  String get photoDeleted => 'Photo deleted';

  @override
  String get myPhotos => 'My Photos';

  @override
  String get maxPhotos => 'Maximum 9 photos allowed';

  @override
  String photoCount(int current) {
    return '$current/9 photos';
  }

  @override
  String get longPressHint => 'Long press photo for options';

  @override
  String errorMessage(String message) {
    return 'Error: $message';
  }
}
