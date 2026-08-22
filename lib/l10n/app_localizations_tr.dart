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

  @override
  String get assessmentContinue => 'Devam';

  @override
  String get assessmentFinish => 'Bitir';

  @override
  String get iqPleaseSelectAnswerToContinue => 'Devam etmek için bir cevap seç';

  @override
  String get assessmentStart => 'Başla';

  @override
  String get assessmentNoQuestionsAvailable => 'Soru bulunamadı';

  @override
  String get iqIntroHeadline => 'Zihinsel profilini oluştur';

  @override
  String get iqIntroLabel => 'IQ Değerlendirmesi';

  @override
  String get iqIntroMeta => '25 soru · Yaklaşık 8 dakika';

  @override
  String get iqIntroStart => 'Değerlendirmeye Başla';

  @override
  String iqQuestionProgress(int current, int total) {
    return 'IQ · $current / $total';
  }

  @override
  String get iqCanonicalSessionError =>
      'Değerlendirme oturumu yüklenemedi. Lütfen tekrar dene.';

  @override
  String get iqCanonicalAnswerError =>
      'Yanıtın kaydedilemedi. Lütfen tekrar dene.';

  @override
  String get iqCanonicalPersistError =>
      'Sonucun kaydedilemedi. Yanıtların güvende; tekrar deneyebilirsin.';

  @override
  String get iqCanonicalFinalizeRetry => 'Sonucu kaydet';

  @override
  String get assessmentPrerequisiteRepairError =>
      'Devam etmeden önce önceki bir değerlendirmenin onarılması gerekiyor. Lütfen o değerlendirmeyi yeniden dene veya yeniden başlat.';

  @override
  String get eqIntroLabel => 'EQ Değerlendirmesi';

  @override
  String get eqIntroMeta => '30 soru · Yaklaşık 15 dakika';

  @override
  String get eqIntroStart => 'EQ değerlendirmesine başla';

  @override
  String get eqIntroHeadlineLead => 'Duygusal';

  @override
  String get eqIntroHeadlineEmphasis => 'zekâ';

  @override
  String eqQuestionProgress(int current, int total) {
    return 'EQ · $current / $total';
  }

  @override
  String frequencyQuestionProgress(int current, int total) {
    return 'Frekans · $current / $total';
  }

  @override
  String get eqCategoryEmpathy => 'Empati';

  @override
  String get eqCategorySelfAwareness => 'Öz Farkındalık';

  @override
  String get eqCategoryEmotionalBalance => 'Duygusal Denge';

  @override
  String get eqCategorySocialAwareness => 'Sosyal Farkındalık';

  @override
  String get eqCategoryRelationshipManagement => 'İlişki Yönetimi';

  @override
  String get assessmentStageFrequency => 'Frekans';

  @override
  String get frequencyIntroTitle => 'Frekansını keşfet';

  @override
  String get frequencyIntroDescription =>
      'Frekans zeka ile ilgili değildir. Nasıl bağ kurduğun, iletişim kurduğun ve güven inşa ettiğinle ilgilidir.';

  @override
  String get frequencyBulletConnect =>
      'Ne kadar derin bağ kurmayı tercih ettiğin';

  @override
  String get frequencyBulletTrust => 'Güveni ne kadar hızlı kurduğun';

  @override
  String get frequencyBulletOpenness => 'Ne kadar duygusal açıklık gösterdiğin';

  @override
  String get frequencyBulletRhythm => 'Sana nasıl bir konuşma ritminin uyduğu';

  @override
  String get startFrequencyTest => 'Frekans Testine Başla';

  @override
  String get continueAction => 'Devam';

  @override
  String get cancel => 'İptal';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get error => 'Hata';

  @override
  String get submit => 'Gönder';

  @override
  String get deleteAction => 'Sil';

  @override
  String get navDiscover => 'Keşfet';

  @override
  String get navMessages => 'Mesajlar';

  @override
  String get navProfile => 'Profil';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get welcomeContinueWithPhone => 'Telefon ile devam et';

  @override
  String get welcomeLogInWithEmail => 'E-posta ile giriş yap';

  @override
  String get welcomeTagline => 'ZEKA. DUYGU. FREKANS.';

  @override
  String get welcomeCueIntelligent => 'Akıllı\neşleşme';

  @override
  String get welcomeCueEmotional => 'Duygusal\nbağ';

  @override
  String get welcomeCueVibrational => 'Frekans\nuyumu';

  @override
  String get welcomeTrustPrivateTitle => 'Sana göre';

  @override
  String get welcomeTrustPrivateBody => 'Seni gerçekten anlayan eşleşmeler.';

  @override
  String get welcomeTrustScienceTitle => 'Derin uyum';

  @override
  String get welcomeTrustScienceBody => 'Zihin, duygu ve frekans birlikte.';

  @override
  String get welcomeTrustMatchesTitle => 'Gerçek bağlantılar';

  @override
  String get welcomeTrustMatchesBody => 'Rastgele değil, anlamlı.';

  @override
  String get welcomeTermsOfService => 'Kullanım Şartları';

  @override
  String get welcomePrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get welcomeLegalPrefix => 'Devam ederek ';

  @override
  String get welcomeLegalAnd => ' ve ';

  @override
  String get welcomeLegalSuffix => '\'nı kabul etmiş olursun.';

  @override
  String get phoneSignupTitleAskNumber => 'Dünyana bağlan';

  @override
  String get phoneSignupTitleEnterCode => 'Kodu gir';

  @override
  String get phoneSignupSubtitleSendCode =>
      'Güvenli erişim için telefon numaranı doğrula.';

  @override
  String get phoneSignupSubtitleCodeSent =>
      'Telefonuna bir doğrulama kodu gönderdik.';

  @override
  String get phoneNumber => 'Telefon numarası';

  @override
  String get mobileNumberHint => 'Cep numarası';

  @override
  String get searchCountry => 'Ülke ara';

  @override
  String get phoneSignupCountryHint =>
      'Ülke kodunu seç, ardından cep numaranı gir.';

  @override
  String get verificationCode => 'Doğrulama kodu';

  @override
  String get changeNumber => 'Numarayı değiştir';

  @override
  String get resendCode => 'Kodu yeniden gönder';

  @override
  String get sendCode => 'Kod gönder';

  @override
  String get verify => 'Doğrula';

  @override
  String get phoneSignupSmsDisclaimer =>
      'Devam ederek doğrulama için SMS alabilirsin. Mesaj ve veri ücretleri uygulanabilir.';

  @override
  String get phoneSignupErrorInvalidPhone =>
      'Lütfen geçerli bir telefon numarası gir.';

  @override
  String get phoneSignupErrorSmsFailed =>
      'SMS gönderilemedi. Lütfen tekrar dene.';

  @override
  String get phoneSignupErrorPhoneLooksInvalid =>
      'Bu telefon numarası geçersiz görünüyor.';

  @override
  String get phoneSignupErrorVerificationExpired =>
      'Doğrulama süresi doldu. Lütfen yeni kod iste.';

  @override
  String get phoneSignupErrorEnterSmsCode => 'Lütfen SMS kodunu gir.';

  @override
  String get phoneSignupErrorIncorrectCode => 'Kod hatalı. Lütfen tekrar dene.';

  @override
  String get phoneSignupErrorVerificationFailed =>
      'Doğrulama başarısız. Lütfen tekrar dene.';

  @override
  String get loginWelcomeBack => 'Hoş geldin';

  @override
  String get loginSubtitle => 'Devam etmek için e-postanla giriş yap.';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get logIn => 'Giriş yap';

  @override
  String get loginPreferPhoneHint =>
      'Telefon mu tercih edersin? Geri dönüp telefon ile devam et.';

  @override
  String get loginErrorEnterEmail => 'Lütfen e-postanı gir';

  @override
  String get loginErrorValidEmail => 'Lütfen geçerli bir e-posta gir';

  @override
  String get loginErrorEnterPassword => 'Lütfen şifreni gir';

  @override
  String get loginErrorPasswordMinLength => 'Şifre en az 6 karakter olmalı';

  @override
  String get loginErrorIncorrectCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get loginErrorValidEmailAddress =>
      'Lütfen geçerli bir e-posta adresi gir.';

  @override
  String get loginErrorFailed => 'Giriş başarısız. Lütfen tekrar dene.';

  @override
  String get discoverTitle => 'Keşfet';

  @override
  String get discoverItsAMatch => 'Eşleşme!';

  @override
  String get discoverMatchDialogBody => 'Artık sohbete başlayabilirsiniz.';

  @override
  String get discoverMatchOpenChat => 'Sohbete git';

  @override
  String get discoverMatchGreetingHi => 'Merhaba 👋';

  @override
  String get discoverMatchGreetingHello => 'Selam 😊';

  @override
  String get discoverMatchGreetingHowsItGoing => 'Nasılsın?';

  @override
  String get discoverMatchGreetingSendFailed => 'Gönderilemedi. Tekrar dene.';

  @override
  String get discoverEmptyTitle => 'Şimdilik yeni profil yok';

  @override
  String get discoverEmptySubtitle =>
      'Yeni eşleşme adayları geldikçe burada görünecek.';

  @override
  String get discoverEmptyRetry => 'Tekrar kontrol et';

  @override
  String get discoverPassportWorldwide => 'Worldwide';

  @override
  String discoverPassportChipActive(String city) {
    return '$city · Passport';
  }

  @override
  String get discoverPassportPickerTitle => 'Passport';

  @override
  String get discoverPassportPickerSearch => 'Şehir veya ülke ara';

  @override
  String get discoverPassportUseWorldwide => 'Worldwide\'a dön';

  @override
  String get discoverPassportChangeDestination => 'Konumu değiştir';

  @override
  String get discoverPassportEmptyTitle =>
      'Bu şehirde yeni profiller bekleniyor';

  @override
  String get discoverPassportEmptyBody =>
      'Passport konumunu değiştirebilir veya Worldwide\'a dönebilirsin.';

  @override
  String get discoverPass => 'Geç';

  @override
  String get discoverLike => 'Beğen';

  @override
  String get discoverSuperResonance => 'Super Resonance';

  @override
  String discoverSuperResonanceConfirmTitle(String name) {
    return '$name kişisine Super Resonance gönderilsin mi?';
  }

  @override
  String discoverSuperResonanceBalance(int count) {
    return 'Bakiye: $count';
  }

  @override
  String get discoverSuperResonanceUsesOne => '1 Super Resonance kullanır';

  @override
  String discoverSuperResonanceDailyAllowance(int remaining, int limit) {
    return 'Bugünkü Resonance hakkı: $remaining / $limit';
  }

  @override
  String discoverSuperResonancePurchased(int count) {
    return 'Satın alınan: $count';
  }

  @override
  String membershipSuperResonanceDaily(int remaining, int limit) {
    return 'Bugünkü dahil kullanımlar: $remaining / $limit';
  }

  @override
  String membershipSuperResonancePurchased(int count) {
    return 'Satın alınan: $count';
  }

  @override
  String get discoverSuperResonanceQuantity => '1 Super Resonance';

  @override
  String get discoverSuperResonanceConfirmBody =>
      'Bu daha güçlü bir uyum sinyali gönderir. Onları beğenmez ve eşleşme oluşturmaz.';

  @override
  String get discoverSuperResonanceConfirm => 'Gönder';

  @override
  String get discoverSuperResonanceCancel => 'Vazgeç';

  @override
  String get discoverSuperResonancePurchaseTitle => 'Super Resonance al';

  @override
  String get discoverSuperResonancePurchaseBody =>
      'Super Resonance ile daha güçlü ve özel bir uyum sinyali gönder. Super Resonance ayrı bir özelliktir ve Resonance üyeliğini etkinleştirmez.';

  @override
  String get discoverSuperResonancePurchaseCta => 'Super Resonance al';

  @override
  String get discoverSuperResonancePurchaseNotNow => 'Şimdi değil';

  @override
  String get discoverSuperResonanceSendFailed =>
      'Super Resonance gönderilemedi. Lütfen tekrar dene.';

  @override
  String get discoverSuperResonancePurchaseFailed =>
      'Satın alma tamamlanamadı. Lütfen tekrar dene.';

  @override
  String get superResonancePurchaseFailedTitle => 'Super Resonance alınamadı';

  @override
  String get superResonancePurchaseFailedBody =>
      'İşlem tamamlanamadı. Biraz sonra yeniden deneyebilirsin.';

  @override
  String get resonancePurchaseFailedTitle => 'Resonance etkinleştirilemedi';

  @override
  String get resonancePurchaseFailedBody =>
      'Satın alma işlemi tamamlanamadı. Lütfen biraz sonra yeniden dene.';

  @override
  String get iapVerificationFailedTitle => 'İşlem tamamlanamadı';

  @override
  String get iapVerificationFailedBody =>
      'Ödeme doğrulanırken bir sorun oluştu. Satın alımın varsa yeniden yüklemeyi deneyebilirsin.';

  @override
  String get iapAlreadyOwnedTitle => 'Bu satın alım zaten mevcut';

  @override
  String get iapAlreadyOwnedBody =>
      'Erişimini yenilemek için Satın Alımları Geri Yükle\'yi kullanabilirsin.';

  @override
  String get discoverGestureOnboardingSwipeRight =>
      'Beğenmek için sağa kaydır.';

  @override
  String get discoverGestureOnboardingSwipeLeft => 'Geçmek için sola kaydır.';

  @override
  String get discoverGestureOnboardingGotIt => 'Anladım';

  @override
  String discoverPercentCompatibility(int percent) {
    return '%$percent uyum';
  }

  @override
  String get discoverInterests => 'İlgi alanları';

  @override
  String get discoverLoading => 'Senin için kişiler aranıyor…';

  @override
  String get discoverErrorTitle => 'Profiller yüklenemedi';

  @override
  String get discoverErrorBody =>
      'Keşfet yüklenirken bir sorun oluştu. Lütfen tekrar dene.';

  @override
  String get discoverActionFailed =>
      'Bu işlem tamamlanamadı. Lütfen tekrar dene.';

  @override
  String get discoverMissingPhotoLabel => 'Profil fotoğrafı yok';

  @override
  String discoverPhotoSemanticLabel(String name) {
    return '$name fotoğrafı';
  }

  @override
  String get compatibilityLabelExceptional => 'Olağanüstü uyum';

  @override
  String get compatibilityLabelStrong => 'Güçlü uyum';

  @override
  String get compatibilityLabelGood => 'İyi uyum';

  @override
  String get compatibilityLabelPotential => 'Potansiyel uyum';

  @override
  String get compatibilityLabelLowSignal => 'Düşük sinyal';

  @override
  String get messagesTitle => 'Mesajlar';

  @override
  String get messagesLoadErrorTitle => 'Sohbetler yüklenemedi.';

  @override
  String get messagesLoadErrorSubtitle => 'Lütfen biraz sonra tekrar dene.';

  @override
  String get messagesEmptyTitle => 'Henüz sohbet yok';

  @override
  String get messagesEmptySubtitle =>
      'Birisiyle eşleştiğinde sohbetin burada görünür.';

  @override
  String get messagesConversationFallback => 'Sohbet';

  @override
  String get messagesLoading => 'Sohbetler yükleniyor…';

  @override
  String messagesAvatarSemanticLabel(String name) {
    return '$name fotoğrafı';
  }

  @override
  String messagesUnreadSemanticLabel(int count) {
    return '$count okunmamış mesaj';
  }

  @override
  String messagesConversationSemanticLabel(String name) {
    return '$name ile sohbet';
  }

  @override
  String get messagesSayHi => 'Merhaba de 👋';

  @override
  String get chatMenuReport => 'Şikayet et';

  @override
  String get chatMenuUnmatch => 'Eşleşmeyi kaldır';

  @override
  String get chatMenuBlock => 'Engelle';

  @override
  String get chatReportDialogTitle => 'Kullanıcıyı şikayet et';

  @override
  String get chatReportDialogSubtitle => 'Ne olduğunu anlat.';

  @override
  String get chatReportReasonHarassment => 'Taciz';

  @override
  String get chatReportReasonSpam => 'Spam';

  @override
  String get chatReportReasonImpersonation => 'Kimliğe bürünme';

  @override
  String get chatReportReasonInappropriate => 'Uygunsuz içerik';

  @override
  String get chatReportReasonScam => 'Dolandırıcılık';

  @override
  String get chatReportReasonOther => 'Diğer';

  @override
  String get chatReportDetailsHint => 'Detay (isteğe bağlı)';

  @override
  String get chatReportSubmitted => 'Şikayet gönderildi.';

  @override
  String get chatMatchNotFound => 'Eşleşme bulunamadı.';

  @override
  String get chatUnmatchDialogTitle => 'Eşleşme kaldırılsın mı?';

  @override
  String get chatUnmatchDialogBody =>
      'Bu sohbet kapanır. Konuşmaya devam edemezsiniz.';

  @override
  String get chatMatchRemoved => 'Eşleşme kaldırıldı.';

  @override
  String get chatBlockDialogTitle => 'Bu kullanıcı engellensin mi?';

  @override
  String get chatBlockDialogBody =>
      'Bu sohbette artık sana mesaj gönderemezler.';

  @override
  String get chatUserBlocked => 'Kullanıcı engellendi.';

  @override
  String get chatUnblockDialogTitle => 'Bu kullanıcının engeli kaldırılsın mı?';

  @override
  String get chatUnblockDialogBody =>
      'Engel kalkar. Kapalı bir sohbet yeniden açılmaz.';

  @override
  String get chatUserUnblocked => 'Engel kaldırıldı.';

  @override
  String get chatMessageHint => 'Mesaj…';

  @override
  String get chatStartConversation => 'Sohbete başla.';

  @override
  String get chatEmptySubtitle =>
      'Hazır olduğunda merhaba diyebilirsin. Acele yok.';

  @override
  String get chatLoadingMessages => 'Mesajlar yükleniyor…';

  @override
  String get chatMessagesLoadErrorTitle => 'Mesajlar yüklenemedi.';

  @override
  String get chatMessagesLoadErrorSubtitle => 'Lütfen biraz sonra tekrar dene.';

  @override
  String get chatProfileLoadErrorSubtitle =>
      'Profil bilgileri şu an kullanılamıyor.';

  @override
  String get chatSendFailed => 'Mesaj gönderilemedi. Lütfen tekrar dene.';

  @override
  String get chatConversationNoLongerActive => 'Bu sohbet artık aktif değil.';

  @override
  String get chatUnavailablePeerTitle => 'Kullanılamayan hesap';

  @override
  String get chatActionFailed => 'Bir şeyler ters gitti. Lütfen tekrar dene.';

  @override
  String get chatDateToday => 'Bugün';

  @override
  String get chatSendSemanticLabel => 'Mesaj gönder';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsGroupPreferences => 'Tercihler';

  @override
  String get settingsGroupPrivacySafety => 'Gizlilik ve güvenlik';

  @override
  String get settingsGroupHelp => 'Yardım ve bilgi';

  @override
  String get settingsGroupAccount => 'Hesap';

  @override
  String get settingsGroupDeveloper => 'Geliştirici';

  @override
  String get settingsNotificationsHonestSubtitle =>
      'Hesabınla senkron — bildirim teslimi telefon ayarlarına da bağlıdır';

  @override
  String get settingsPrivacyHonestSubtitle =>
      'Görünürlük seçenekleri şimdilik bu cihazda — ayrıntılar için Gizlilik Politikası';

  @override
  String get settingsDebug => 'Hata ayıklama';

  @override
  String get settingsDebugSubtitle =>
      'Değerlendirme yönetimi ve araçlar (yalnızca debug)';

  @override
  String get profilePhotosEmptyTitle => 'İlk fotoğrafını ekle';

  @override
  String get profilePhotosEmptyBody =>
      'Fotoğraflar seni tanımayı kolaylaştırır. En fazla 9 fotoğraf ekleyebilirsin.';

  @override
  String get profilePhotosEmptyHint =>
      'Uygun olduğunda fotoğrafların profilinde ve Keşfet’te görünür.';

  @override
  String get profilePhotosAddFirst => 'Fotoğraf ekle';

  @override
  String get profilePhotosAddTile => 'Ekle';

  @override
  String get profilePhotosUploading => 'Yükleniyor…';

  @override
  String get profilePhotosUploadFailed =>
      'Fotoğraflar yüklenemedi. Lütfen tekrar dene.';

  @override
  String get profilePhotosDeleteFailed =>
      'Fotoğraf silinemedi. Lütfen tekrar dene.';

  @override
  String get profilePhotosAtCapacity => '9 fotoğraf sınırına ulaştın.';

  @override
  String get profilePhotosPrimaryBadge => 'Ana fotoğraf';

  @override
  String get settingsNotifications => 'Bildirimler';

  @override
  String get settingsPrivacy => 'Gizlilik';

  @override
  String get settingsBlocked => 'Engellenenler';

  @override
  String get settingsBlockedSubtitle => 'Engellenen kullanıcılar';

  @override
  String get settingsHelpSupport => 'Yardım & Destek';

  @override
  String get settingsHelpSupportSubtitle => 'Sıkça sorulan sorular';

  @override
  String get settingsAbout => 'Hakkında';

  @override
  String get settingsAboutSubtitle => 'Uygulama bilgileri';

  @override
  String get settingsLogout => 'Çıkış Yap';

  @override
  String get settingsLogoutSubtitle => 'Hesabından çıkış yap';

  @override
  String get settingsLogoutConfirmTitle => 'Çıkış yapılsın mı?';

  @override
  String get settingsLogoutConfirmBody => 'Hesabından çıkış yapacaksın.';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get aboutVersion => 'Sürüm 1.0.0';

  @override
  String get aboutTagline => 'Minds First';

  @override
  String get aboutDescription =>
      'QMatch; düşünme, hissetme ve bağ kurma biçimine göre anlamlı bağlantılar keşfetmene yardımcı olur — yalnızca görünüşe göre değil. Uyumluluk içgörüleri keşfi desteklemek içindir; herhangi bir ilişkinin başarısını garanti etmez.';

  @override
  String get aboutLegal => 'Yasal';

  @override
  String get privacyPolicyTitle => 'Gizlilik Politikası';

  @override
  String get termsOfUseTitle => 'Kullanım Şartları';

  @override
  String get privacyPolicyBody =>
      'Son güncelleme: Temmuz 2026\n\nBu Gizlilik Politikası, Qmatch’i kullanırken bilgilerinin nasıl işlenebileceğini açıklar. Ürün lansmanı için hazırlanmış bir taslaktır; güncellenebilir. Resmi hukuki tavsiye yerine geçmez.\n\nQmatch nedir?\nQmatch bir bağlantı ve uyumluluk keşif uygulamasıdır. IQ, EQ ve Frequency sonuçları eşleştirme için uygulama içi sinyallerdir—tıbbi/klinik veya resmi zekâ testleri değildir ve ilişki başarısı garantisi vermez.\n\nYaş\nQmatch yetişkinler içindir. Profillerde yaş en az 18’dir.\n\nİşleyebileceğimiz bilgiler\n• Hesap ve doğrulama verileri (ör. telefon veya e-posta ile giriş)\n• Sağladığın profil bilgileri (ad, yaş, fotoğraflar, bio, ilgi alanları, tercihler, etkinleştirdiysen yaklaşık konum)\n• Değerlendirme cevapları ve sonuçları (IQ, EQ, Frequency)\n• Keşfet, eşleşme ve sohbet kullanıyorsan eşleşme/mesajlaşma etkinliği\n• Şikayet ve engelleme gibi güvenlik aksiyonları\n• Hizmeti çalıştırmak için gereken temel cihaz/uygulama kullanım verileri\n\nNasıl kullanırız?\nHesabını oluşturmak, profilleri göstermek, uyumluluk önerileri sunmak, mesajlaşmayı sağlamak, güvenliği artırmak ve uygulamayı işletmek için kullanırız.\n\nPaylaşım\nKişisel bilgilerini satmayız. Uygulamayı çalıştırmamıza yardımcı olan hizmet sağlayıcılarla, yasal zorunluluk halinde veya kullanıcıları ve platformu korumak için paylaşım olabilir.\n\nSeçimlerin\nProfilini güncelleyebilir, bazı gizlilik ayarlarını değiştirebilir, engelleme/şikayet kullanabilir ve Ayarlar → Hesabı sil üzerinden (veya support@qmatch.site adresine yazarak) hesap silme talebi oluşturabilirsin. Silme taleplerini 30 gün içinde işlemeyi hedefleriz. Gerekli olduğunda bazı güvenlik veya yasal kayıtlar sınırlı süre saklanabilir.\n\nÇevrimdışı güvenlik\nBiriyle yüz yüze görüşürsen kamuya açık yerde buluş, birine haber ver ve iyi tanımadığın kişilere para veya hassas belge gönderme.\n\nİletişim\nGizlilik soruları: support@qmatch.site';

  @override
  String get termsOfUseBody =>
      'Son güncelleme: Temmuz 2026\n\nQmatch’e hoş geldin. Bu Kullanım Şartları, uygulamayı kullanmak için ürün lansmanı taslağıdır; resmi hukuki incelemenin yerine geçmez.\n\nUygunluk\nQmatch’i kullanmak için en az 18 yaşında olmalı ve geçerli bir sözleşme yapabilmelisin.\n\nHizmet\nQmatch; değerlendirmeler (IQ, EQ, Frequency), profiller ve isteğe bağlı mesajlaşma ile uyumluluk odaklı keşif sunar. Sonuçlar uygulama içi uyumluluk sinyalleridir—tıbbi/klinik tanı veya resmi IQ/EQ sertifikası değildir ve bir eşleşmenin sonuç garantisi değildir.\n\nSorumlulukların\nDiğerleriyle nasıl etkileşim kurduğundan sen sorumlusun. Saygılı ol, doğru profil bilgisi ver ve yasalara uy. Taciz, dolandırıcılık, kimliğe bürünme veya zararlı içerik yasaktır.\n\nGüvenlik araçları\nKullanıcıları şikayet edebilir ve engelleyebilirsin. Şikayetleri inceleyebilir, kötüye kullanımda hesapları kısıtlayabilir veya sonlandırabiliriz.\n\nHesap\nGiriş yöntemin (ör. telefon doğrulama) senden sorumludur. Kalıcı hesap silme talebini Ayarlar → Hesabı sil üzerinden veya support@qmatch.site adresine yazarak oluşturabilirsin. Talepleri 30 gün içinde işlemeyi hedefleriz. Bu geçici deaktivasyon değildir.\n\nSorumluluk reddi\nQmatch “olduğu gibi” sunulur. Kesintisiz hizmet, kusursuz eşleşme veya herhangi bir bağlantının sonucunu garanti etmeyiz.\n\nDeğişiklikler\nBu Şartları güncelleyebiliriz. Güncellemeden sonra kullanmaya devam etmek, yeni şartları kabul ettiğin anlamına gelir.\n\nİletişim\nsupport@qmatch.site';

  @override
  String get helpSupportTitle => 'Yardım & Destek';

  @override
  String get helpSupportContact =>
      'Daha fazla yardıma mı ihtiyacın var?\n\nBize support@qmatch.site adresinden yaz.\n\nHer mesajı okuruz. Hesabı silmek için Ayarlar → Hesabı sil yolunu kullan (30 gün içinde işlenir) veya hesabına bağlı telefon/e-posta ile destekle iletişime geç.';

  @override
  String get supportEmailLabel => 'support@qmatch.site';

  @override
  String get openPrivacyPolicy => 'Gizlilik Politikasını oku';

  @override
  String get openTermsOfUse => 'Kullanım Şartlarını oku';

  @override
  String get settingsDeleteAccount => 'Hesabı sil';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Kalıcı hesap silme talebi oluştur';

  @override
  String get settingsDeleteAccountPendingStatus => 'Hesap silme talep edildi';

  @override
  String get settingsDeleteAccountPendingSubtitle =>
      'Talep durumunu ve süreyi görüntüle';

  @override
  String get settingsDeleteAccountPendingBanner =>
      'Hesap silme talebin beklemede. 30 gün içinde işleyeceğiz. Yardım için support@qmatch.site adresine yaz.';

  @override
  String get accountDeletionTitle => 'Hesabı sil';

  @override
  String get accountDeletionWarningTitle =>
      'Bu işlem kalıcı silme talebi başlatır';

  @override
  String get accountDeletionIntro =>
      'Qmatch hesabının kalıcı silinmesini uygulama içinden talep edebilirsin. Bu formu göndermek her şeyi anında silmez—işleyeceğimiz bir silme talebi oluşturur.';

  @override
  String get accountDeletionWillDeleteTitle => 'Silmeyi planladığımız veriler';

  @override
  String get accountDeletionWillDeleteBody =>
      '• Profil bilgilerin\n• Fotoğraflar ve profil medya referansları\n• Değerlendirme cevapları ve sonuçları (IQ, EQ, Frequency)\n• Hesaba bağlı uyumluluk ve Keşfet görünürlük verileri\n• Bu hesaba bağlı eşleşme ve sohbet erişimin (hesap kapanmasının parçası olarak)';

  @override
  String get accountDeletionMayRetainTitle => 'Sınırlı süre saklanabilecekler';

  @override
  String get accountDeletionMayRetainBody =>
      '• Güvenlik şikayetleri ve kötüye kullanım önleme kayıtları\n• Yasal veya uyum için gereken sınırlı loglar\nBunlar dating profilini aktif tutmak için kullanılmaz.';

  @override
  String get accountDeletionTimelineTitle => 'İşlem süresi';

  @override
  String get accountDeletionTimelineBody =>
      'Talebini 30 gün içinde işleyeceğiz. Bu geçici deaktivasyon değildir—işlem tamamlandığında hedef kalıcı hesap silmedir.';

  @override
  String accountDeletionSupportHint(String email) {
    return 'Soruların mı var? $email ile iletişime geç';
  }

  @override
  String get accountDeletionAckIrreversible =>
      'Bu talebin geçici deaktivasyon değil, kalıcı silme için olduğunu anlıyorum.';

  @override
  String get accountDeletionAckTimeline =>
      'İşlemin 30 güne kadar sürebileceğini anlıyorum.';

  @override
  String accountDeletionTypeDeleteHint(String token) {
    return 'Onaylamak için $token yaz';
  }

  @override
  String get accountDeletionSubmit => 'Silme talebini gönder';

  @override
  String get accountDeletionNotImmediateNote =>
      'Göndermek verilerini anında silmez. İşlem tamamlandığında bilgilendiririz.';

  @override
  String get accountDeletionPendingTitle => 'Talep zaten alındı';

  @override
  String accountDeletionPendingBody(String email) {
    return 'Silme talebin alındı ve beklemede. 30 gün içinde işleyeceğiz. Soruların için $email ile iletişime geçebilirsin.';
  }

  @override
  String get accountDeletionPendingNoResubmit =>
      'Yeniden talep göndermene gerek yok. Bu talep beklerken tekrar gönderim kapalıdır.';

  @override
  String get accountDeletionRequestError =>
      'Talebin gönderilemedi. Bağlantını kontrol edip tekrar dene veya support@qmatch.site adresine yaz.';

  @override
  String get discoverAccountDeletionPendingBanner =>
      'Hesap silme talebin beklemede.';

  @override
  String get accountDeletionSuccessTitle => 'Talep alındı';

  @override
  String accountDeletionSuccessBody(String email) {
    return 'Silme talebin alındı. 30 gün içinde işleyeceğiz. Soruların için $email ile iletişime geçebilirsin.';
  }

  @override
  String get accountDeletionSuccessAction => 'Tamam';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileNotFound => 'Profil bulunamadı';

  @override
  String get profileAboutMe => 'Hakkımda';

  @override
  String get profileNoBioYet => 'Henüz bio eklenmedi';

  @override
  String get profileInterests => 'İlgi Alanları';

  @override
  String get profileNoInterestsYet => 'Henüz ilgi alanı eklenmedi';

  @override
  String get profileDetailsSection => 'Detaylar';

  @override
  String get profileLoading => 'Profil yükleniyor…';

  @override
  String get profileLoadFailed => 'Profilin yüklenemedi. Lütfen tekrar dene.';

  @override
  String get profileMissingPhoto => 'Fotoğraf ekle';

  @override
  String get profileEditPhotoSemantic => 'Profil fotoğrafını düzenle';

  @override
  String get profileFieldOccupation => 'Meslek';

  @override
  String get profileFieldDrinking => 'Alkol';

  @override
  String get profileFieldSmoking => 'Sigara';

  @override
  String get profileSetupTitle => 'Profil Oluştur';

  @override
  String get profileSetupComplete => 'TAMAMLA';

  @override
  String get profileSetupReadyTitle => 'Profil Hazır!';

  @override
  String get profileSetupReadyMessage =>
      'Harika! Artık eşleşmeleri keşfetmeye başlayabilirsin.';

  @override
  String get nameSelectionTitle => 'Nasıl çağıralım?';

  @override
  String get nameSelectionSubtitle => 'QMatch\'te görünecek ismini seç';

  @override
  String get nameSelectionHint => 'İsmin';

  @override
  String get nameSelectionTip => 'Gerçek ismini kullanmanı öneririz';

  @override
  String get nameSelectionErrorEmpty => 'Lütfen bir isim girin';

  @override
  String get nameSelectionErrorMinLength => 'İsim en az 2 karakter olmalı';

  @override
  String get displayNameTitle => 'Sana nasıl hitap edelim?';

  @override
  String get displayNameSubtitle =>
      'Bu ad profilinde diğer kullanıcılara görünecek.';

  @override
  String get displayNameLabel => 'Görünen ad';

  @override
  String get displayNameHint => 'Adın';

  @override
  String get displayNamePublicExplanation =>
      'Benzersiz kullanıcı adı değildir. Daha sonra değiştirebilirsin.';

  @override
  String get displayNameSaving => 'Kaydediliyor…';

  @override
  String get displayNameErrorEmpty => 'Lütfen bir görünen ad gir.';

  @override
  String get displayNameErrorTooShort => 'En az 2 karakter kullan.';

  @override
  String get displayNameErrorTooLong => 'En fazla 24 karakter kullan.';

  @override
  String get displayNameErrorLetterOrNumber =>
      'En az bir harf veya rakam ekle.';

  @override
  String get displayNameErrorInvalid => 'Bu ad geçersiz karakterler içeriyor.';

  @override
  String get displayNameErrorEmailLike =>
      'Lütfen e-posta değil, bir ad kullan.';

  @override
  String get displayNameErrorPhoneLike =>
      'Lütfen telefon numarası değil, bir ad kullan.';

  @override
  String get displayNameErrorUrlLike =>
      'Lütfen web sitesi değil, bir ad kullan.';

  @override
  String get displayNameErrorSaveFailed =>
      'Adın kaydedilemedi. Lütfen tekrar dene.';

  @override
  String get privacySettingsTitle => 'Gizlilik';

  @override
  String get notificationsSettingsTitle => 'Bildirimler';

  @override
  String get blockedUsersTitle => 'Engellenenler';

  @override
  String get showProfileInDiscover => 'Profilimi keşfette göster';

  @override
  String get showProfileInDiscoverSubtitle => 'Keşfet ekranında görünür ol';

  @override
  String get showApproximateLocation => 'Yaklaşık konumu göster';

  @override
  String get showApproximateLocationSubtitle =>
      'Konumunu yaklaşık olarak paylaş';

  @override
  String get pushNotifications => 'Push bildirimleri';

  @override
  String get pushNotificationsSubtitle => 'Genel push bildirimlerini aç/kapat';

  @override
  String get newMatchNotifications => 'Yeni eşleşme bildirimleri';

  @override
  String get newMatchNotificationsSubtitle =>
      'Yeni bir eşleşme olduğunda bildir';

  @override
  String get newMessageNotifications => 'Yeni mesaj bildirimleri';

  @override
  String get newMessageNotificationsSubtitle => 'Yeni mesaj aldığında bildir';

  @override
  String get superResonanceNotifications => 'Süper Rezonans bildirimleri';

  @override
  String get superResonanceNotificationsSubtitle =>
      'Süper Rezonans etkinlikleri için bildir';

  @override
  String get notificationPrefsLoadFailed =>
      'Bildirim tercihleri yüklenemedi. Daha sonra tekrar dene.';

  @override
  String get notificationPrefsSaveFailed =>
      'Bildirim tercihleri kaydedilemedi. Tekrar dene.';

  @override
  String get frequencyDailySuggestions => 'Frequency / günlük öneriler';

  @override
  String get frequencyDailySuggestionsSubtitle =>
      'Günlük öneriler için bildirim al';

  @override
  String get unblock => 'Engeli kaldır';

  @override
  String get loginRequired => 'Giriş gerekli.';

  @override
  String get noBlockedUsers => 'Engellenen kullanıcı yok';

  @override
  String get helpFaqHowWorksQ => 'Qmatch nasıl çalışır?';

  @override
  String get helpFaqHowWorksA =>
      'Qmatch; düşünme (IQ), hissetme (EQ), bağ kurma tarzı (Frequency) ve profiline göre kişi önerir. Amaç uyumlu bağlantılar keşfetmektir—herhangi bir ilişkinin başarı garantisi değildir.';

  @override
  String get helpFaqRankingQ => 'Eşleşmeler nasıl sıralanır?';

  @override
  String get helpFaqRankingA =>
      'Keşfet, kişileri ölçülen IQ, EQ ve Frequency profillerinin yakınlığına göre sıralar (kanonik 20D yapısal uzaklık). Bu bir sıralamadır; uyumluluk yüzdesi değildir. Persona ve arketip eşleştirme anahtarı değildir. Sıralama uygulama önerisidir; ilişki garantisi değildir.';

  @override
  String get helpFaqFrequencyQ => 'Frequency ne anlama gelir?';

  @override
  String get helpFaqFrequencyA =>
      'Frequency; derinlik, sosyal enerji ve tempo gibi bağ kurma ritmini anlatır. Klinik bir etiket değil, uygulama içi bir stil sinyalidir.';

  @override
  String get helpFaqScoresQ => 'IQ ve EQ tıbbi veya resmi test midir?';

  @override
  String get helpFaqScoresA =>
      'Hayır. Qmatch IQ, EQ ve Frequency skorları eşleştirme için uygulama içi uyumluluk sinyalleridir. Tıbbi/klinik veya resmi zekâ sertifikası değildir.';

  @override
  String get helpFaqPhotosQ => 'Qmatch’te fotoğraflar görünür mü?';

  @override
  String get helpFaqPhotosA =>
      'Evet. Keşfedilebilir olduğunda eklediğin fotoğraflar ve profil bilgileri başkalarına görünebilir. Rahat ettiğin kadarını paylaş.';

  @override
  String get helpFaqBlockQ => 'Bir kullanıcıyı nasıl engellerim?';

  @override
  String get helpFaqBlockA =>
      'Sohbet → menü → Engelle. Engellenenler Ayarlar → Engellenenler’de görünür. Engelleme, uygulamada daha fazla iletişimi kesmeye yardımcı olur.';

  @override
  String get helpFaqReportQ => 'Birini nasıl şikayet ederim?';

  @override
  String get helpFaqReportA =>
      'Sohbet → menü → Şikayet et ve bir gerekçe seç. Şikayetler incelenmek üzere kaydedilir.';

  @override
  String get helpFaqSafetyQ => 'Yüz yüze buluşma için ipuçları?';

  @override
  String get helpFaqSafetyA =>
      'Kamuya açık yerde buluş, birine nerede olduğunu söyle, kendi ulaşımını ayarla ve yalnızca uygulamadan tanıdığın kişilere para veya hassas belge gönderme.';

  @override
  String get helpFaqAgeQ => 'Minimum yaş nedir?';

  @override
  String get helpFaqAgeA =>
      'Qmatch yetişkinler içindir. Profillerde yaş en az 18’dir.';

  @override
  String get helpFaqDeleteAccountQ => 'Hesabımı nasıl silerim?';

  @override
  String get helpFaqDeleteAccountA =>
      'Ayarlar → Hesabı sil’e git, uyarıları oku, iki onay kutusunu işaretle, DELETE yaz ve gönder. Talepleri 30 gün içinde işleriz. İstersen support@qmatch.site adresine de yazabilirsin.';

  @override
  String get helpFaqDataQ => 'Qmatch hangi verileri kullanır?';

  @override
  String get helpFaqDataA =>
      'Kullanımına göre: giriş bilgileri, profil ve fotoğraflar, değerlendirme cevapları/sonuçları, eşleşme/mesajlar ve şikayet-engelleme gibi güvenlik aksiyonları. Ayrıntılar için Gizlilik Politikası’na bak.';

  @override
  String get profileFieldAge => 'Yaş';

  @override
  String get profileFieldGender => 'Cinsiyet';

  @override
  String get profileFieldEducation => 'Eğitim';

  @override
  String get profileFieldBio => 'Bio';

  @override
  String get profileFieldLookingFor => 'İlişki tipi';

  @override
  String profileSetupPleaseComplete(String fields) {
    return 'Lütfen tamamla: $fields';
  }

  @override
  String profileSetupErrorGeneric(String message) {
    return 'Bir hata oluştu: $message';
  }

  @override
  String get compatReasonArchetype => 'Güçlü arketip uyumu';

  @override
  String get compatReasonThinking => 'Uyumlu düşünme tarzı';

  @override
  String get compatReasonEmotional => 'Benzer duygusal ritim';

  @override
  String get compatReasonFrequency => 'Ortak frequency etiketleri';

  @override
  String get compatReasonInterests => 'Benzer ilgi alanları';

  @override
  String get compatReasonRecency => 'Yakın zamanda aktif';

  @override
  String get profileBasicInfoTitle => 'Temel bilgiler';

  @override
  String get profileBasicInfoSubtitle => 'Kendini tanıtalım';

  @override
  String get profileBioTitle => 'Hakkında';

  @override
  String get profileInterestsTitle => 'İlgi alanları';

  @override
  String get profileLifestyleTitle => 'Yaşam tarzı';

  @override
  String get profileLifestyleSubtitle =>
      'Opsiyonel — paylaşmak istediklerini doldur';

  @override
  String get profilePreferencesTitle => 'Ne arıyorsun?';

  @override
  String get profilePreferencesSubtitle => 'Tercihlerin eşleşmeni etkiler';

  @override
  String get photos => 'Fotoğraflar';

  @override
  String get profileBioSubtitle => 'Kendini ifade et, dikkat çek!';

  @override
  String profileInterestsMaxSelect(int count) {
    return 'En fazla 5 ilgi alanı seç ($count/5)';
  }

  @override
  String get profileFieldLookingForLabel => 'İlişki tipi *';

  @override
  String get profileFieldAgeLabel => 'Yaş *';

  @override
  String get profileFieldGenderLabel => 'Cinsiyet *';

  @override
  String get profileFieldLocationLabel => 'Konum *';

  @override
  String get profileFieldEducationLabel => 'Eğitim *';

  @override
  String get optGenderMale => 'Erkek';

  @override
  String get optGenderFemale => 'Kadın';

  @override
  String get optGenderOther => 'Diğer';

  @override
  String get optEduHighSchool => 'Lise';

  @override
  String get optEduAssociate => 'Ön Lisans';

  @override
  String get optEduBachelor => 'Lisans';

  @override
  String get optEduMaster => 'Yüksek Lisans';

  @override
  String get optEduDoctorate => 'Doktora';

  @override
  String get optLookingSerious => 'Ciddi ilişki';

  @override
  String get optLookingLongTerm => 'Uzun vadeli ilişki';

  @override
  String get optLookingMarriage => 'Evlilik';

  @override
  String get optLookingFriendship => 'Arkadaşlık';

  @override
  String get optLookingCloseFriendship => 'Yakın arkadaşlık';

  @override
  String get optLookingCasual => 'Tanışma / sohbet';

  @override
  String get optLookingUnsure => 'Henüz emin değilim';

  @override
  String get optLookingGoWithFlow => 'Akışına bırakıyorum';

  @override
  String get optNever => 'Kullanmıyorum';

  @override
  String get optDrinkingSocial => 'Sosyal içiciyim';

  @override
  String get optDrinkingOften => 'Sık içerim';

  @override
  String get optDrinkingSpecial => 'Sadece özel günlerde';

  @override
  String get optSmokingSometimes => 'Sosyal içiyorum';

  @override
  String get optSmokingRegular => 'Düzenli içiyorum';

  @override
  String get optSmokingQuitting => 'Bırakmaya çalışıyorum';

  @override
  String get optYesHave => 'Var';

  @override
  String get optNo => 'Yok';

  @override
  String get optPetsWant => 'Hayvan sahibi olmak istiyorum';

  @override
  String get optPetsAllergy => 'Alerjim var';

  @override
  String get optAnimalLoveHigh => 'Hayvan delisiyim';

  @override
  String get optAnimalLoveYes => 'Seviyorum';

  @override
  String get optAnimalLoveNeutral => 'Normal karşılıyorum';

  @override
  String get optAnimalLoveLow => 'Pek sevmem';

  @override
  String get optChildrenWant => 'Yok ama istiyorum';

  @override
  String get optChildrenNo => 'İstemiyorum';

  @override
  String get optChildrenUnsure => 'Henüz kararsızım';

  @override
  String get optChildrenMaybe => 'Belki ileride';

  @override
  String get optReligionMuslim => 'Müslüman';

  @override
  String get optReligionChristian => 'Hristiyan';

  @override
  String get optReligionJewish => 'Yahudi';

  @override
  String get optReligionBuddhist => 'Budist';

  @override
  String get optReligionHindu => 'Hindu';

  @override
  String get optReligionAgnostic => 'Agnostik';

  @override
  String get optReligionAtheist => 'Ateist';

  @override
  String get optReligionSpiritual => 'Manevi (dini olmayan)';

  @override
  String get optReligionOther => 'Diğer';

  @override
  String get optPreferNotToSay => 'Belirtmek istemiyorum';

  @override
  String get optPetsHave => 'Evcil hayvanım var';

  @override
  String get optPetsNone => 'Hayvanım yok';

  @override
  String get optChildrenHave => 'Çocuğum var';

  @override
  String get profileSelectAge => 'Yaşınızı seçin';

  @override
  String get profileSelectGender => 'Cinsiyetinizi seçin';

  @override
  String get profileSelectEducation => 'Eğitim seviyenizi seçin';

  @override
  String get profileShareLocation => 'Konumunuzu paylaşın';

  @override
  String get profileLocationLoading => 'Konum alınıyor…';

  @override
  String get profileLocationHint =>
      'Konumunuz sadece mesafe hesaplaması için kullanılır';

  @override
  String profileLocationSuccess(String location) {
    return 'Konum: $location';
  }

  @override
  String profileLocationError(String message) {
    return 'Konum alınamadı: $message';
  }

  @override
  String get profileLocationPermissionDenied => 'Konum izni reddedildi';

  @override
  String get profileLocationPermissionPermanentlyDenied =>
      'Konum izni kalıcı olarak reddedildi. Ayarlardan açın.';

  @override
  String get profileOccupation => 'Meslek';

  @override
  String get profileOccupationHint => 'Örn: Yazılım geliştirici';

  @override
  String get profileDrinking => 'İçki';

  @override
  String get profileSmoking => 'Sigara';

  @override
  String get profilePets => 'Evcil hayvan';

  @override
  String get profileAnimalLove => 'Hayvan sevgisi';

  @override
  String get profileChildren => 'Çocuk isteği';

  @override
  String get profileReligion => 'Din';

  @override
  String get profileSelectOption => 'Seçiniz';

  @override
  String get profileLookingForHint => 'Ne arıyorsun?';

  @override
  String profileAgeRangeLabel(int min, int max) {
    return 'Yaş aralığı: $min - $max';
  }

  @override
  String profileMaxDistanceLabel(int km) {
    return 'Maksimum mesafe: $km km';
  }

  @override
  String get profilePreferencesEditableHint =>
      'Bu tercihler istediğin zaman değiştirilebilir';

  @override
  String get profileBioHint =>
      'Kendini tanıt… Hobilerinden, tutkularından, hayallerinden bahset.';

  @override
  String get settingsMvpPrivacyNote =>
      'Bu ekrandaki bazı gizlilik anahtarları şimdilik bu cihazda tutulur. Profil, değerlendirmeler, eşleşmeler ve mesajlar hesabınla senkronize olur. Ayrıntılar için Hakkında → Gizlilik Politikası’na bak.';

  @override
  String get settingsMvpNotificationsNote =>
      'Bu tercihler Qmatch hesabınla senkronlanır. Anlık bildirimler ayrıca telefon ayarlarına da bağlıdır.';

  @override
  String get blockedUsersLoadFailed =>
      'Engellenen kullanıcılar şu anda yüklenemedi. Lütfen daha sonra tekrar dene.';

  @override
  String get blockedUsersBlockedAt => 'Engellendi';

  @override
  String get debugModeUnavailable =>
      'Hata ayıklama modu yalnızca debug derlemelerinde kullanılabilir.';

  @override
  String get debugHomeTitle => 'Hata ayıklama araçları';

  @override
  String get debugHomeSubtitle =>
      'Yalnızca geliştirme için. Bu yollar release ve profile derlemelerinde kapalı kalır.';

  @override
  String get debugAssessmentAdmin => 'Değerlendirme Yönetimi';

  @override
  String get debugPersonaPreview => 'Persona Sonucu Önizleme';

  @override
  String get debugFrequencyPreview => 'Frequency Soru Önizleme';

  @override
  String get debugProfileSetupPreview => 'Profil Oluşturma Önizleme';

  @override
  String get debugReplayDiscoverTutorial =>
      'Keşfet kaydırma eğitimini tekrar göster';

  @override
  String get debugReplayDiscoverTutorialHint =>
      'Eğitim sıfırlandı. Keşfet sekmesini aç.';

  @override
  String get debugGoToAuthWrapper => 'Auth Wrapper\'a git';

  @override
  String get mainAppWelcome => 'QMatch\'e hoş geldin!';

  @override
  String get mainAppComingSoon => 'Ana uygulama yakında…';

  @override
  String get interestCatSports => 'Spor';

  @override
  String get interestCatArts => 'Sanat';

  @override
  String get interestCatTech => 'Teknoloji';

  @override
  String get interestCatTravel => 'Seyahat';

  @override
  String get interestFootball => 'Futbol';

  @override
  String get interestBasketball => 'Basketbol';

  @override
  String get interestTennis => 'Tenis';

  @override
  String get interestSwimming => 'Yüzme';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestVolleyball => 'Voleybol';

  @override
  String get interestPilates => 'Pilates';

  @override
  String get interestRunning => 'Koşu';

  @override
  String get interestCycling => 'Bisiklet';

  @override
  String get interestHiking => 'Dağcılık';

  @override
  String get interestGymnastics => 'Jimnastik';

  @override
  String get interestBoxing => 'Boks';

  @override
  String get interestSailing => 'Yelken';

  @override
  String get interestGolf => 'Golf';

  @override
  String get interestMusic => 'Müzik';

  @override
  String get interestPainting => 'Resim';

  @override
  String get interestCinema => 'Sinema';

  @override
  String get interestTheatre => 'Tiyatro';

  @override
  String get interestDance => 'Dans';

  @override
  String get interestLiterature => 'Edebiyat';

  @override
  String get interestPhotography => 'Fotoğrafçılık';

  @override
  String get interestSculpture => 'Heykel';

  @override
  String get interestGraphicDesign => 'Grafik tasarım';

  @override
  String get interestPoetry => 'Şiir';

  @override
  String get interestWriting => 'Yazarlık';

  @override
  String get interestStandup => 'Stand-up';

  @override
  String get interestInstrument => 'Enstrüman çalmak';

  @override
  String get interestOpera => 'Opera';

  @override
  String get interestBallet => 'Bale';

  @override
  String get interestCoding => 'Kodlama';

  @override
  String get interestGaming => 'Oyun';

  @override
  String get interestAiml => 'AI/ML';

  @override
  String get interestCrypto => 'Kripto';

  @override
  String get interestWeb3 => 'Web3';

  @override
  String get interestRobotics => 'Robotik';

  @override
  String get interestCybersecurity => 'Siber güvenlik';

  @override
  String get interestDataScience => 'Veri bilimi';

  @override
  String get interestMobileApps => 'Mobil uygulama';

  @override
  String get interestBlockchain => 'Blockchain';

  @override
  String get interestIot => 'IoT';

  @override
  String get interestCloud => 'Cloud computing';

  @override
  String get interestCamping => 'Kamp';

  @override
  String get interestNature => 'Doğa';

  @override
  String get interestAbroad => 'Yurt dışı';

  @override
  String get interestCultureTours => 'Kültür turları';

  @override
  String get interestSafari => 'Safari';

  @override
  String get interestFoodTours => 'Gastro turlar';

  @override
  String get interestExtremeSports => 'Extreme sporlar';

  @override
  String get interestBackpacking => 'Backpacking';

  @override
  String get interestLuxuryTravel => 'Lüks tatil';

  @override
  String get interestHistoricSites => 'Tarihi yerler';

  @override
  String get interestBeach => 'Plaj tatili';

  @override
  String get interestSoloTravel => 'Solo seyahat';

  @override
  String get privacyVisibilitySection => 'Görünürlük';

  @override
  String get privacyDataSecuritySection => 'Veri ve güvenlik';

  @override
  String get settingsResonance => 'Resonance';

  @override
  String get settingsResonanceSubtitle =>
      'Kim beğendi, Rewind ve daha derin uyum';

  @override
  String get settingsPassport => 'Passport';

  @override
  String get settingsPassportSubtitleLocked => 'Resonance ile aç';

  @override
  String get settingsPassportSubtitleWorldwide => 'Worldwide';

  @override
  String settingsPassportSubtitleActive(String city) {
    return '$city';
  }

  @override
  String get resonancePaywallTitle => 'Resonance';

  @override
  String get resonancePaywallHeadline => 'Resonance\'ı aç';

  @override
  String get resonancePaywallBody =>
      'Seni beğenenler Resonance ile şimdi dahil. Resonance kimi eşleştireceğini veya sıralamayı değiştirmez.';

  @override
  String get resonancePaywallIncludedNow => 'Şimdi dahil';

  @override
  String get resonancePaywallComingLater => 'Daha sonra gelecek — henüz yok';

  @override
  String get resonancePaywallBenefitWhoLikedYou => 'Seni beğenenler';

  @override
  String get resonancePaywallBenefitRewind => 'Rewind';

  @override
  String get resonancePaywallBenefitDeeper =>
      'Daha derin uyumluluk açıklamaları';

  @override
  String get resonancePaywallActive => 'Resonance bu hesapta aktif.';

  @override
  String get resonancePaywallPlansUnavailable =>
      'Resonance planları şu an kullanılamıyor. Lütfen daha sonra tekrar dene.';

  @override
  String get resonancePaywallAndroidDisabled =>
      'Resonance satın alma Android\'de henüz yok. iOS App Store satın almaları hazır olduğunda hesabını açacak.';

  @override
  String get resonancePlanMonthly => 'Resonance Aylık';

  @override
  String get resonancePlanAnnual => 'Resonance Yıllık';

  @override
  String get resonancePlanAnnualBadge => 'En avantajlı';

  @override
  String get resonancePaywallPurchase => 'Resonance\'ı aç';

  @override
  String get resonancePaywallPurchasing => 'Satın alınıyor…';

  @override
  String get resonancePaywallRestore => 'Satın alımları geri yükle';

  @override
  String get resonancePaywallRestoring => 'Geri yükleniyor…';

  @override
  String get resonancePaywallLegalNote =>
      'Ödeme Apple ID\'ne yansıtılır. Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik yenilenir. Yetki, mağaza doğrulamasından sonra QMatch tarafından onaylanır — yalnızca StoreKit başarısı Resonance açmaz.';

  @override
  String get resonanceUnlockCta => 'Resonance ile aç';

  @override
  String get resonanceUnlockNotNow => 'Şimdi değil';

  @override
  String get whoLikedYouTitle => 'Uyum Sinyalleri';

  @override
  String get whoLikedYouLoading => 'Uyum sinyalleri aranıyor…';

  @override
  String get whoLikedYouEmptyTitle => 'Yeni uyum sinyalleri burada görünecek';

  @override
  String get whoLikedYouEmptyBody =>
      'Sana yönelik yeni bir uyum oluştuğunda burada keşfedebilirsin.';

  @override
  String get whoLikedYouLockedTitle => 'Uyum Sinyallerini gör';

  @override
  String get whoLikedYouLockedBody =>
      'Sana yönelik yeni bir uyum oluştuğunda Resonance onları görmeni sağlar — kimi eşleştireceğini değiştirmeden.';

  @override
  String get whoLikedYouErrorTitle => 'Uyum sinyalleri yüklenemedi';

  @override
  String get whoLikedYouErrorBody => 'Bir sorun oluştu. Lütfen tekrar dene.';

  @override
  String get whoLikedYouFreeDiscoveryTitle =>
      'Özel bir uyum sinyali burada görünebilir';

  @override
  String get whoLikedYouFreeDiscoveryBody =>
      'Biri sana Super Resonance gönderdiğinde burada görebilirsin. Resonance üyeliği, diğer Uyum Sinyallerini de keşfetmeni sağlar.';

  @override
  String get profileMembershipResonanceActive => 'Resonance aktif';

  @override
  String get profileMembershipFree => 'QMatch Free';

  @override
  String get profileResonanceBadgeSemantic => 'Resonance aktif';

  @override
  String get membershipTitle => 'Üyelik';

  @override
  String get membershipFreeName => 'QMatch Free';

  @override
  String get membershipFreeIncluded =>
      'Değerlendirmeler, Keşfet, eşleşme ve sohbet dahil';

  @override
  String get membershipUpgradeCta => 'Resonance\'a yükselt';

  @override
  String get membershipResonanceName => 'Resonance';

  @override
  String get membershipStatusActive => 'Aktif';

  @override
  String get membershipPlanMonthly => 'Aylık';

  @override
  String get membershipPlanAnnual => 'Yıllık';

  @override
  String get membershipComingLater => 'Daha sonra gelecek';

  @override
  String get membershipManageSubscription => 'Aboneliği yönet';
}
