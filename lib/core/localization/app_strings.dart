import 'dart:ui';

class AppStrings {
  static Locale get deviceLocale => PlatformDispatcher.instance.locale;
  static bool get isTurkish => deviceLocale.languageCode == 'tr';

  static String get addPhotos => isTurkish ? 'FOTOĞRAF EKLE' : 'ADD PHOTOS';
  static String photosUploaded(int count) => isTurkish
    ? '$count fotoğraf yüklendi'
    : '$count photos uploaded';
  static String get setAsMain => isTurkish ? 'Ana Fotoğraf Yap' : 'Set as Main Photo';
  static String get delete => isTurkish ? 'Sil' : 'Delete';
  static String get mainPhotoUpdated => isTurkish ? '⭐ Ana fotoğraf güncellendi' : '⭐ Main photo updated';
  static String get photoDeleted => isTurkish ? 'Fotoğraf silindi' : 'Photo deleted';
  static String get myPhotos => isTurkish ? 'Fotoğraflarım' : 'My Photos';
  static String get maxPhotos => isTurkish ? 'En fazla 9 fotoğraf ekleyebilirsiniz' : 'Maximum 9 photos allowed';
  static String photoCount(int current) => isTurkish
    ? '$current/9 fotoğraf'
    : '$current/9 photos';
  static String get longPressHint => isTurkish
    ? 'Fotoğrafa uzun basarak seçenekleri görebilirsiniz'
    : 'Long press photo for options';
  static String error(String message) => isTurkish
    ? 'Hata: $message'
    : 'Error: $message';
}
