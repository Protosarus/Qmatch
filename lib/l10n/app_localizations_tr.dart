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

  @override
  String get assessmentContinue => 'Devam';

  @override
  String get assessmentBack => 'Geri';

  @override
  String get assessmentNext => 'İleri';

  @override
  String get assessmentFinish => 'Bitir';

  @override
  String get assessmentComplete => 'Değerlendirme tamamlandı!';

  @override
  String get assessmentProfileCreated => 'Zihinsel profilin oluşturuldu.';

  @override
  String get assessmentViewProfile => 'Profilimi Gör';

  @override
  String get assessmentPleaseSelectAnswer => 'Lütfen bir cevap seçin';

  @override
  String get iqPleaseSelectAnswerToContinue => 'Devam etmek için bir cevap seç';

  @override
  String get assessmentStart => 'Başla';

  @override
  String get assessmentNoQuestionsAvailable => 'Soru bulunamadı';

  @override
  String get iqTestTitle => 'IQ Testi';

  @override
  String get startIqTest => 'IQ Testine Başla';

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
  String get iqQuestionLabel => 'IQ Sorusu';

  @override
  String get iqTestCompleted => 'IQ değerlendirmesi tamamlandı';

  @override
  String get iqToEqMessage =>
      'Zihinsel profilinin ilk bölümü hazır. Şimdi duygusal profiline geçelim.';

  @override
  String get continueToEqAssessment => 'EQ değerlendirmesine geç';

  @override
  String get iqReasoningProfileTitle => 'Muhakeme Profili';

  @override
  String get iqReasoningProfileSubtitle =>
      'Bu oturumdaki kalibre edilmemiş çok boyutlu muhakeme performansın.';

  @override
  String get iqUncalibratedDisclaimer =>
      'Standart IQ skoru değildir · Nüfus yüzdeliği değildir';

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
  String get iqDimLogicalReasoning => 'Mantıksal Muhakeme';

  @override
  String get iqDimPatternReasoning => 'Örüntü Muhakemesi';

  @override
  String get iqDimVerbalReasoning => 'Sözel Muhakeme';

  @override
  String get iqDimSpatialReasoning => 'Uzamsal Muhakeme';

  @override
  String get eqTestTitle => 'EQ Testi';

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
  String get eqPillarSelfAwareness => 'Öz farkındalık';

  @override
  String get eqPillarEmpathy => 'Empati';

  @override
  String get eqPillarBalance => 'Duygusal Denge';

  @override
  String get eqPillarHarmony => 'İçsel Uyum';

  @override
  String eqQuestionProgress(int current, int total) {
    return 'EQ · $current / $total';
  }

  @override
  String get eqQuestionInsightLabel => 'EQ';

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
  String get eqIntroHeadline => 'Duygusal zekâ';

  @override
  String get eqIntroDescription =>
      'Duygusal zeka (EQ), hem kendi duygularını hem de başkalarınınkini anlama ve yönetme becerini ölçer.';

  @override
  String get eqBulletQuestions => '30 senaryo tabanlı soru';

  @override
  String get eqBulletEmpathy => 'Empati ve öz farkındalığı ölçer';

  @override
  String get eqBulletDuration => 'Yaklaşık 15 dakika sürer';

  @override
  String get startEqTest => 'EQ Testine Başla';

  @override
  String get eqTestCompleted => 'EQ testi tamamlandı!';

  @override
  String get assessmentStageIq => 'IQ';

  @override
  String get assessmentStageEq => 'EQ';

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
  String get frequencyTestTitle => 'Frekans Testi';

  @override
  String get yourFrequency => 'Frekansın';

  @override
  String get balancedFrequency => 'Dengeli Frekans';

  @override
  String get frequencyScore => 'Skor';

  @override
  String get seeMyFrequency => 'Frekansımı Gör';

  @override
  String get stronglyDisagree => 'Kesinlikle katılmıyorum';

  @override
  String get disagree => 'Katılmıyorum';

  @override
  String get neutral => 'Kararsızım';

  @override
  String get agree => 'Katılıyorum';

  @override
  String get stronglyAgree => 'Kesinlikle katılıyorum';

  @override
  String get continueAction => 'Devam';

  @override
  String get next => 'İleri';

  @override
  String get back => 'Geri';

  @override
  String get finish => 'Bitir';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get done => 'Tamam';

  @override
  String get start => 'Başla';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get error => 'Hata';

  @override
  String get submit => 'Gönder';

  @override
  String get send => 'Gönder';

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
  String get welcomeMatchMinds => 'Zihinleri eşleştir.';

  @override
  String get welcomeFeelTheFrequency => 'Frekansı hisset.';

  @override
  String get welcomeSubtitle =>
      'Kişilik, duygu ve gerçek uyum üzerinden insanlarla tanış.';

  @override
  String get welcomeContinueWithPhone => 'Telefon ile devam et';

  @override
  String get welcomeSecureSignInHint => 'Güvenli giriş. E-posta gerekmez.';

  @override
  String get welcomeAlreadyHaveAccount => 'Zaten hesabın var mı? ';

  @override
  String get welcomeLogIn => 'Giriş yap';

  @override
  String get welcomeLogInWithEmail => 'E-posta ile giriş yap';

  @override
  String get welcomeTagline => 'ZEKA. DUYGU. FREKANS.';

  @override
  String get welcomeHeadlinePrefix => 'Frekansını';

  @override
  String get welcomeHeadlineEmphasis => 'bul';

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
  String get welcomeTermsPrivacy =>
      'Devam ederek Qmatch Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmiş olursun.';

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
  String get discoverEmptyTitle =>
      'Şu anda gösterebileceğimiz yeni profil yok.';

  @override
  String get discoverEmptySubtitle =>
      'Biraz sonra yeniden kontrol edebilirsin.';

  @override
  String get discoverPass => 'Geç';

  @override
  String get discoverLike => 'Beğen';

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
  String get chatProfileLoadErrorTitle => 'Profil yüklenemedi.';

  @override
  String get chatProfileLoadErrorSubtitle =>
      'Profil bilgileri şu an kullanılamıyor.';

  @override
  String get chatSendFailed => 'Mesaj gönderilemedi. Lütfen tekrar dene.';

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
      'Şimdilik cihaz tercihi — bildirim teslimi telefon ayarlarına da bağlıdır';

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
  String get settingsNotificationsSubtitle => 'Bildirim tercihlerini yönet';

  @override
  String get settingsPrivacy => 'Gizlilik';

  @override
  String get settingsPrivacySubtitle => 'Gizlilik ayarları';

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
      'Qmatch; düşünme, hissetme ve bağ kurma tarzına göre uyumlu bağlantılar keşfetmene yardımcı olur—yalnızca görünüme göre değil. Uyumluluk içgörüleri keşfi desteklemek içindir; bir ilişkinin başarı garantisi değildir.';

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
  String get settingsDeleteAccountDialogTitle => 'Hesap silme talebi';

  @override
  String get settingsDeleteAccountDialogBody =>
      'Ayarlar → Hesabı sil üzerinden uygulama içi talep gönderebilirsin. İstersen support@qmatch.site adresine de yazabilirsin.';

  @override
  String get settingsDeleteAccountDialogAction => 'Anladım';

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
  String get accountDeletionAlreadyRequested =>
      'Bekleyen bir silme talebin zaten var. Yardım için support@qmatch.site adresine yaz.';

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
  String get privacyPolicyTodo => 'Gizlilik Politikası';

  @override
  String get termsOfUseTodo => 'Kullanım Şartları';

  @override
  String get helpSupportContactTodo =>
      'Daha fazla yardıma mı ihtiyacın var?\n\nBize support@qmatch.site adresinden yaz.\n\nHer mesajı okuruz. Hesabı silmek için Ayarlar → Hesabı sil yolunu kullan (30 gün içinde işlenir) veya hesabına bağlı telefon/e-posta ile destekle iletişime geç.';

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
  String get profileSetupContinue => 'DEVAM';

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
  String get displayNameContinue => 'Devam';

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
  String get displayNameMissingPeerLabel => 'Üye';

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
      'Keşfet önerileri Frequency kalıpları, arketip, ilgi alanları ve destekleyici IQ/EQ bantları gibi uyumluluk sinyallerini kullanır. Sıralama uygulama önerisidir; mutlak doğru değildir.';

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
  String get addPhoto => 'Fotoğraf ekle';

  @override
  String get completeProfile => 'Profili tamamla';

  @override
  String get saveProfile => 'Profili kaydet';

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
      'Bu ekrandaki bildirim tercihleri şimdilik bu cihazda tutulur. Anlık bildirimler ayrıca telefon ayarlarına da bağlıdır.';

  @override
  String get blockedUsersLoadFailed =>
      'Engellenen kullanıcılar şu anda yüklenemedi. Lütfen daha sonra tekrar dene.';

  @override
  String blockedUsersError(String message) {
    return 'Bir hata oluştu: $message';
  }

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
  String get debugGoToAuthWrapper => 'Auth Wrapper\'a git';

  @override
  String get mainAppWelcome => 'QMatch\'e hoş geldin!';

  @override
  String get mainAppComingSoon => 'Ana uygulama yakında…';

  @override
  String get emailSignupTitle => 'Hesap oluştur';

  @override
  String get emailSignupSubtitle => 'e-posta ile';

  @override
  String get fullName => 'Ad soyad';

  @override
  String get signUp => 'Kayıt ol';

  @override
  String get signupJoinToday => 'Bugün QMatch\'e katıl';

  @override
  String get signupCreateAccount => 'Hesap oluştur';

  @override
  String get signupAlreadyHaveAccount => 'Zaten hesabın var mı? ';

  @override
  String get signupErrorWeakPassword => 'Şifre çok zayıf';

  @override
  String get signupErrorEmailInUse => 'Bu e-posta ile zaten bir hesap var';

  @override
  String get signupErrorInvalidEmail => 'Geçersiz e-posta adresi';

  @override
  String get signupErrorFailed => 'Kayıt başarısız. Lütfen tekrar dene.';

  @override
  String get nameRequired => 'Lütfen adını gir';

  @override
  String get nameMinLength => 'Ad en az 2 karakter olmalı';

  @override
  String get verifyEmailTitle => 'E-postayı doğrula';

  @override
  String get verificationEmailSent => 'Doğrulama e-postası gönderildi!';

  @override
  String get verificationTitle => 'Doğrulama';

  @override
  String get verificationCodeSentEmail => 'Doğrulama kodu e-postaya gönderildi';

  @override
  String get verificationCodeSentSms => 'Doğrulama kodu SMS ile gönderildi';

  @override
  String verificationEnterEmailCode(String contact) {
    return 'Şu adrese gönderilen kodu gir:\n$contact';
  }

  @override
  String verificationEnterSmsCode(String contact) {
    return 'Şu numaraya gönderilen SMS kodunu gir:\n$contact';
  }

  @override
  String get resendCodeAction => 'Kodu yeniden gönder';

  @override
  String get socialContinueGoogle => 'Google ile devam et';

  @override
  String get socialContinueApple => 'Apple ile devam et';

  @override
  String get socialOrEmail => 'Veya e-posta ile devam et';

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
  String emailVerificationSentTo(String email) {
    return 'Doğrulama bağlantısını şu adrese gönderdik:\n$email';
  }

  @override
  String get emailVerificationNextSteps => 'Sonraki adımlar:';

  @override
  String get emailVerificationStepInbox => 'E-posta gelen kutunu kontrol et';

  @override
  String get emailVerificationStepClick => 'Doğrulama bağlantısına tıkla';

  @override
  String get emailVerificationStepReturn => 'Bu uygulamaya geri dön';

  @override
  String get emailVerificationWaiting => 'Doğrulama bekleniyor…';

  @override
  String emailVerificationResendIn(int seconds) {
    return '$seconds sn içinde yeniden gönder';
  }

  @override
  String get emailVerificationResend => 'E-postayı yeniden gönder';

  @override
  String get emailVerificationSpamHint =>
      'Görmüyorsan spam klasörünü kontrol et.';

  @override
  String get pleaseEnterPassword => 'Lütfen bir şifre gir';

  @override
  String get welcomeTitle => 'Hoş geldin';

  @override
  String get socialContinueWithEmail => 'E-posta ile devam et';

  @override
  String get orDivider => 'veya';

  @override
  String get privacyVisibilitySection => 'Görünürlük';

  @override
  String get privacyDataSecuritySection => 'Veri ve güvenlik';

  @override
  String get socialCreateAccountSubtitle => 'QMatch hesabını oluştur';

  @override
  String get socialAlreadyHaveAccountLogin => 'Zaten hesabın var mı? Giriş yap';
}
