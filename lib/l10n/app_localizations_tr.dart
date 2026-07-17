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
  String get assessmentPleaseSelectAnswer => 'Lütfen bir cevap seçin';

  @override
  String get assessmentStart => 'Başla';

  @override
  String get assessmentNoQuestionsAvailable => 'Soru bulunamadı';

  @override
  String get iqTestTitle => 'IQ Testi';

  @override
  String get startIqTest => 'IQ Testine Başla';

  @override
  String get iqTestCompleted => 'IQ testi tamamlandı!';

  @override
  String get iqToEqMessage => 'Harika! Şimdi duygusal zekanı test edelim.';

  @override
  String get eqTestTitle => 'EQ Testi';

  @override
  String get eqIntroHeadline => 'Duygusal Zeka';

  @override
  String get eqIntroDescription =>
      'Duygusal zeka (EQ), hem kendi duygularını hem de başkalarınınkini anlama ve yönetme becerini ölçer.';

  @override
  String get eqBulletQuestions => '10 senaryo tabanlı soru';

  @override
  String get eqBulletEmpathy => 'Empati ve öz farkındalığı ölçer';

  @override
  String get eqBulletDuration => 'Yaklaşık 5 dakika sürer';

  @override
  String get startEqTest => 'EQ Testine Başla';

  @override
  String get eqTestCompleted => 'EQ testi tamamlandı!';

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
  String get welcomeTermsPrivacy =>
      'Devam ederek Qmatch Kullanım Şartları ve Gizlilik Politikası\'nı kabul etmiş olursun.';

  @override
  String get phoneSignupTitleAskNumber => 'Numaran nedir?';

  @override
  String get phoneSignupTitleEnterCode => 'Kodu gir';

  @override
  String get phoneSignupSubtitleSendCode =>
      'Seni doğrulamak için bir doğrulama kodu göndereceğiz.';

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
  String get loginWelcomeBack => 'Tekrar hoş geldin';

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
  String get discoverEmptyTitle => 'Henüz uyumlu profil yok.';

  @override
  String get discoverEmptySubtitle =>
      'Qmatch\'e daha fazla kişi katıldıkça tekrar dene.';

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
  String get settingsTitle => 'Ayarlar';

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
      'Qmatch, insanları yalnızca görünüşe göre değil; düşünme, hissetme ve bağ kurma tarzlarına göre eşleştirir.';

  @override
  String get aboutLegal => 'Yasal';

  @override
  String get privacyPolicyTodo => 'Gizlilik Politikası (TODO)';

  @override
  String get termsOfUseTodo => 'Kullanım Şartları (TODO)';

  @override
  String get helpSupportTitle => 'Yardım & Destek';

  @override
  String get helpSupportContactTodo =>
      'Destek ile iletişim (MVP):\n\nTODO: Uygulama içi destek talebi veya e-posta bağlantısı ekle.';

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
      'Qmatch; düşünme (IQ), hissetme (EQ) ve bağ kurma tarzını (Frequency) temel alarak eşleşmeler önerir. Amaç, sadece görünüşe değil uyuma odaklanmaktır.';

  @override
  String get helpFaqRankingQ => 'Eşleşmeler nasıl sıralanır?';

  @override
  String get helpFaqRankingA =>
      'Keşfet ekranında öneriler; uyumluluk (IQ/EQ/Frequency), arketip ve ortak ilgi alanlarına göre sıralanır.';

  @override
  String get helpFaqFrequencyQ => 'Frequency ne anlama gelir?';

  @override
  String get helpFaqFrequencyA =>
      'Frequency, birinin nasıl bağ kurduğunu ve iletişim ritmini anlatır. Derinlik, sosyal enerji ve güven hızı gibi boyutlardan oluşur.';

  @override
  String get helpFaqPhotosQ => 'Qmatch’te fotoğraflar görünür mü?';

  @override
  String get helpFaqPhotosA =>
      'Evet. Qmatch, uyumluluk katmanlarıyla daha anlamlı bağlantılar kurmayı hedefler; fotoğraflar normal şekilde görüntülenir.';

  @override
  String get helpFaqBlockQ => 'Bir kullanıcıyı nasıl engellerim?';

  @override
  String get helpFaqBlockA =>
      'Sohbet ekranındaki menüden engelleme seçeneğini kullanabilirsin. Engellenen kullanıcılar ayarlardaki “Engellenenler” bölümünde görünür.';

  @override
  String get helpFaqReportQ => 'Birini nasıl şikayet ederim?';

  @override
  String get helpFaqReportA =>
      'Sohbet ekranındaki menüden şikayet seçeneğini kullanarak gerekçeni seçebilirsin. Şikayetler incelenmek üzere kaydedilir.';

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
      'Gizlilik ayarları MVP sürümünde yerel olarak tutulur.\n\nTODO: Bu tercihleri Firestore veya cihaz depolamasına kaydet.';

  @override
  String get settingsMvpNotificationsNote =>
      'TODO: Bildirim tercihlerini Firestore veya cihaz depolamasına kaydet.';

  @override
  String blockedUsersError(String message) {
    return 'Bir hata oluştu: $message';
  }

  @override
  String get blockedUsersBlockedAt => 'Engellendi';

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
