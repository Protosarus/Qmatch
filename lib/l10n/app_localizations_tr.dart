// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get addPhotos => 'FOTOĞRAF EKLE';

  @override
  String photosUploaded(int count) {
    return '$count fotoğraf yüklendi';
  }

  @override
  String get setAsMain => 'Ana Fotoğraf Yap';

  @override
  String get delete => 'Sil';

  @override
  String get mainPhotoUpdated => '⭐ Ana fotoğraf güncellendi';

  @override
  String get photoDeleted => 'Fotoğraf silindi';

  @override
  String get myPhotos => 'Fotoğraflarım';

  @override
  String get maxPhotos => 'En fazla 9 fotoğraf ekleyebilirsiniz';

  @override
  String photoCount(int current) {
    return '$current/9 fotoğraf';
  }

  @override
  String get longPressHint =>
      'Fotoğrafa uzun basarak seçenekleri görebilirsiniz';

  @override
  String errorMessage(String message) {
    return 'Hata: $message';
  }
}
