import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// Button text for adding photos
  ///
  /// In en, this message translates to:
  /// **'ADD PHOTOS'**
  String get addPhotos;

  /// Message shown after photos are uploaded
  ///
  /// In en, this message translates to:
  /// **'{count} photos uploaded'**
  String photosUploaded(int count);

  /// No description provided for @setAsMain.
  ///
  /// In en, this message translates to:
  /// **'Set as Main Photo'**
  String get setAsMain;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @mainPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'⭐ Main photo updated'**
  String get mainPhotoUpdated;

  /// No description provided for @photoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Photo deleted'**
  String get photoDeleted;

  /// No description provided for @myPhotos.
  ///
  /// In en, this message translates to:
  /// **'My Photos'**
  String get myPhotos;

  /// No description provided for @maxPhotos.
  ///
  /// In en, this message translates to:
  /// **'Maximum 9 photos allowed'**
  String get maxPhotos;

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'{current}/9 photos'**
  String photoCount(int current);

  /// No description provided for @longPressHint.
  ///
  /// In en, this message translates to:
  /// **'Long press photo for options'**
  String get longPressHint;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(String message);

  /// No description provided for @assessmentContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get assessmentContinue;

  /// No description provided for @assessmentBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get assessmentBack;

  /// No description provided for @assessmentNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get assessmentNext;

  /// No description provided for @assessmentFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get assessmentFinish;

  /// No description provided for @assessmentComplete.
  ///
  /// In en, this message translates to:
  /// **'Assessment Complete!'**
  String get assessmentComplete;

  /// No description provided for @assessmentPleaseSelectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please select an answer'**
  String get assessmentPleaseSelectAnswer;

  /// No description provided for @assessmentStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get assessmentStart;

  /// No description provided for @assessmentNoQuestionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No questions available'**
  String get assessmentNoQuestionsAvailable;

  /// No description provided for @iqTestTitle.
  ///
  /// In en, this message translates to:
  /// **'IQ Test'**
  String get iqTestTitle;

  /// No description provided for @startIqTest.
  ///
  /// In en, this message translates to:
  /// **'Start IQ Test'**
  String get startIqTest;

  /// No description provided for @iqTestCompleted.
  ///
  /// In en, this message translates to:
  /// **'IQ Test Completed!'**
  String get iqTestCompleted;

  /// No description provided for @iqToEqMessage.
  ///
  /// In en, this message translates to:
  /// **'Great! Now let\'s test your emotional intelligence.'**
  String get iqToEqMessage;

  /// No description provided for @eqTestTitle.
  ///
  /// In en, this message translates to:
  /// **'EQ Test'**
  String get eqTestTitle;

  /// No description provided for @eqIntroHeadline.
  ///
  /// In en, this message translates to:
  /// **'Emotional Intelligence'**
  String get eqIntroHeadline;

  /// No description provided for @eqIntroDescription.
  ///
  /// In en, this message translates to:
  /// **'Your emotional quotient (EQ) measures your ability to understand and manage emotions - both yours and others\'.'**
  String get eqIntroDescription;

  /// No description provided for @eqBulletQuestions.
  ///
  /// In en, this message translates to:
  /// **'10 scenario-based questions'**
  String get eqBulletQuestions;

  /// No description provided for @eqBulletEmpathy.
  ///
  /// In en, this message translates to:
  /// **'Measures empathy & self-awareness'**
  String get eqBulletEmpathy;

  /// No description provided for @eqBulletDuration.
  ///
  /// In en, this message translates to:
  /// **'Takes about 5 minutes'**
  String get eqBulletDuration;

  /// No description provided for @startEqTest.
  ///
  /// In en, this message translates to:
  /// **'Start EQ Test'**
  String get startEqTest;

  /// No description provided for @eqTestCompleted.
  ///
  /// In en, this message translates to:
  /// **'EQ Test Completed!'**
  String get eqTestCompleted;

  /// No description provided for @frequencyIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover your frequency'**
  String get frequencyIntroTitle;

  /// No description provided for @frequencyIntroDescription.
  ///
  /// In en, this message translates to:
  /// **'Frequency is not about intelligence. It is about how you connect, communicate, and build trust.'**
  String get frequencyIntroDescription;

  /// No description provided for @frequencyBulletConnect.
  ///
  /// In en, this message translates to:
  /// **'How deeply you prefer to connect'**
  String get frequencyBulletConnect;

  /// No description provided for @frequencyBulletTrust.
  ///
  /// In en, this message translates to:
  /// **'How fast you build trust'**
  String get frequencyBulletTrust;

  /// No description provided for @frequencyBulletOpenness.
  ///
  /// In en, this message translates to:
  /// **'How much emotional openness you bring'**
  String get frequencyBulletOpenness;

  /// No description provided for @frequencyBulletRhythm.
  ///
  /// In en, this message translates to:
  /// **'What kind of conversation rhythm fits you'**
  String get frequencyBulletRhythm;

  /// No description provided for @startFrequencyTest.
  ///
  /// In en, this message translates to:
  /// **'Start Frequency Test'**
  String get startFrequencyTest;

  /// No description provided for @frequencyTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequency Test'**
  String get frequencyTestTitle;

  /// No description provided for @yourFrequency.
  ///
  /// In en, this message translates to:
  /// **'Your frequency'**
  String get yourFrequency;

  /// No description provided for @balancedFrequency.
  ///
  /// In en, this message translates to:
  /// **'Balanced Frequency'**
  String get balancedFrequency;

  /// No description provided for @frequencyScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get frequencyScore;

  /// No description provided for @seeMyFrequency.
  ///
  /// In en, this message translates to:
  /// **'See My Frequency'**
  String get seeMyFrequency;

  /// No description provided for @stronglyDisagree.
  ///
  /// In en, this message translates to:
  /// **'Strongly disagree'**
  String get stronglyDisagree;

  /// No description provided for @disagree.
  ///
  /// In en, this message translates to:
  /// **'Disagree'**
  String get disagree;

  /// No description provided for @neutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get neutral;

  /// No description provided for @agree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get agree;

  /// No description provided for @stronglyAgree.
  ///
  /// In en, this message translates to:
  /// **'Strongly agree'**
  String get stronglyAgree;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @welcomeMatchMinds.
  ///
  /// In en, this message translates to:
  /// **'Match minds.'**
  String get welcomeMatchMinds;

  /// No description provided for @welcomeFeelTheFrequency.
  ///
  /// In en, this message translates to:
  /// **'Feel the frequency.'**
  String get welcomeFeelTheFrequency;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meet people through personality, emotion, and real compatibility.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeContinueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone'**
  String get welcomeContinueWithPhone;

  /// No description provided for @welcomeSecureSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Secure sign-in. No email required.'**
  String get welcomeSecureSignInHint;

  /// No description provided for @welcomeAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get welcomeAlreadyHaveAccount;

  /// No description provided for @welcomeLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get welcomeLogIn;

  /// No description provided for @welcomeTermsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to Qmatch\'s Terms and Privacy Policy.'**
  String get welcomeTermsPrivacy;

  /// No description provided for @phoneSignupTitleAskNumber.
  ///
  /// In en, this message translates to:
  /// **'What\'s your number?'**
  String get phoneSignupTitleAskNumber;

  /// No description provided for @phoneSignupTitleEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get phoneSignupTitleEnterCode;

  /// No description provided for @phoneSignupSubtitleSendCode.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to confirm it\'s you.'**
  String get phoneSignupSubtitleSendCode;

  /// No description provided for @phoneSignupSubtitleCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to your phone.'**
  String get phoneSignupSubtitleCodeSent;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @mobileNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumberHint;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country'**
  String get searchCountry;

  /// No description provided for @phoneSignupCountryHint.
  ///
  /// In en, this message translates to:
  /// **'Select your country code, then enter your mobile number.'**
  String get phoneSignupCountryHint;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @phoneSignupSmsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you may receive an SMS for verification. Message and data rates may apply.'**
  String get phoneSignupSmsDisclaimer;

  /// No description provided for @phoneSignupErrorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get phoneSignupErrorInvalidPhone;

  /// No description provided for @phoneSignupErrorSmsFailed.
  ///
  /// In en, this message translates to:
  /// **'SMS could not be sent. Please try again.'**
  String get phoneSignupErrorSmsFailed;

  /// No description provided for @phoneSignupErrorPhoneLooksInvalid.
  ///
  /// In en, this message translates to:
  /// **'This phone number looks invalid.'**
  String get phoneSignupErrorPhoneLooksInvalid;

  /// No description provided for @phoneSignupErrorVerificationExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification expired. Please request a new code.'**
  String get phoneSignupErrorVerificationExpired;

  /// No description provided for @phoneSignupErrorEnterSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the SMS code.'**
  String get phoneSignupErrorEnterSmsCode;

  /// No description provided for @phoneSignupErrorIncorrectCode.
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect. Please try again.'**
  String get phoneSignupErrorIncorrectCode;

  /// No description provided for @phoneSignupErrorVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get phoneSignupErrorVerificationFailed;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email to continue.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @loginPreferPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Prefer phone? Go back and continue with phone.'**
  String get loginPreferPhoneHint;

  /// No description provided for @loginErrorEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get loginErrorEnterEmail;

  /// No description provided for @loginErrorValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get loginErrorValidEmail;

  /// No description provided for @loginErrorEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get loginErrorEnterPassword;

  /// No description provided for @loginErrorPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get loginErrorPasswordMinLength;

  /// No description provided for @loginErrorIncorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get loginErrorIncorrectCredentials;

  /// No description provided for @loginErrorValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get loginErrorValidEmailAddress;

  /// No description provided for @loginErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginErrorFailed;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverItsAMatch.
  ///
  /// In en, this message translates to:
  /// **'It\'s a match'**
  String get discoverItsAMatch;

  /// No description provided for @discoverMatchDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You can now start a conversation.'**
  String get discoverMatchDialogBody;

  /// No description provided for @discoverEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No compatible profiles yet.'**
  String get discoverEmptyTitle;

  /// No description provided for @discoverEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try again later as more people join Qmatch.'**
  String get discoverEmptySubtitle;

  /// No description provided for @discoverPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get discoverPass;

  /// No description provided for @discoverLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get discoverLike;

  /// No description provided for @discoverPercentCompatibility.
  ///
  /// In en, this message translates to:
  /// **'{percent}% compatibility'**
  String discoverPercentCompatibility(int percent);

  /// No description provided for @discoverInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get discoverInterests;

  /// No description provided for @compatibilityLabelExceptional.
  ///
  /// In en, this message translates to:
  /// **'Exceptional match'**
  String get compatibilityLabelExceptional;

  /// No description provided for @compatibilityLabelStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong match'**
  String get compatibilityLabelStrong;

  /// No description provided for @compatibilityLabelGood.
  ///
  /// In en, this message translates to:
  /// **'Good match'**
  String get compatibilityLabelGood;

  /// No description provided for @compatibilityLabelPotential.
  ///
  /// In en, this message translates to:
  /// **'Potential match'**
  String get compatibilityLabelPotential;

  /// No description provided for @compatibilityLabelLowSignal.
  ///
  /// In en, this message translates to:
  /// **'Low signal'**
  String get compatibilityLabelLowSignal;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @messagesLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load conversations.'**
  String get messagesLoadErrorTitle;

  /// No description provided for @messagesLoadErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get messagesLoadErrorSubtitle;

  /// No description provided for @messagesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get messagesEmptyTitle;

  /// No description provided for @messagesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you match with someone, your conversation will appear here.'**
  String get messagesEmptySubtitle;

  /// No description provided for @messagesConversationFallback.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get messagesConversationFallback;

  /// No description provided for @messagesSayHi.
  ///
  /// In en, this message translates to:
  /// **'Say hi 👋'**
  String get messagesSayHi;

  /// No description provided for @chatMenuReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get chatMenuReport;

  /// No description provided for @chatMenuUnmatch.
  ///
  /// In en, this message translates to:
  /// **'Unmatch'**
  String get chatMenuUnmatch;

  /// No description provided for @chatMenuBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatMenuBlock;

  /// No description provided for @chatReportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get chatReportDialogTitle;

  /// No description provided for @chatReportDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened.'**
  String get chatReportDialogSubtitle;

  /// No description provided for @chatReportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get chatReportReasonHarassment;

  /// No description provided for @chatReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get chatReportReasonSpam;

  /// No description provided for @chatReportReasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get chatReportReasonImpersonation;

  /// No description provided for @chatReportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get chatReportReasonInappropriate;

  /// No description provided for @chatReportReasonScam.
  ///
  /// In en, this message translates to:
  /// **'Scam'**
  String get chatReportReasonScam;

  /// No description provided for @chatReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chatReportReasonOther;

  /// No description provided for @chatReportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get chatReportDetailsHint;

  /// No description provided for @chatReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted.'**
  String get chatReportSubmitted;

  /// No description provided for @chatMatchNotFound.
  ///
  /// In en, this message translates to:
  /// **'Match not found.'**
  String get chatMatchNotFound;

  /// No description provided for @chatUnmatchDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unmatch?'**
  String get chatUnmatchDialogTitle;

  /// No description provided for @chatUnmatchDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This will close the conversation. You will not be able to continue chatting.'**
  String get chatUnmatchDialogBody;

  /// No description provided for @chatMatchRemoved.
  ///
  /// In en, this message translates to:
  /// **'Match removed.'**
  String get chatMatchRemoved;

  /// No description provided for @chatBlockDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get chatBlockDialogTitle;

  /// No description provided for @chatBlockDialogBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to message you in this conversation.'**
  String get chatBlockDialogBody;

  /// No description provided for @chatUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get chatUserBlocked;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get chatMessageHint;

  /// No description provided for @chatStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation.'**
  String get chatStartConversation;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get settingsBlocked;

  /// No description provided for @settingsBlockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'People you\'ve blocked'**
  String get settingsBlockedSubtitle;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsHelpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get settingsHelpSupportSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get settingsLogoutSubtitle;

  /// No description provided for @settingsLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogoutConfirmTitle;

  /// No description provided for @settingsLogoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out of your account.'**
  String get settingsLogoutConfirmBody;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get aboutVersion;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Minds First'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Qmatch helps people discover compatible connections based on how they think, feel, and connect—not looks alone. Compatibility insights are meant to support discovery; they do not guarantee a relationship.'**
  String get aboutDescription;

  /// No description provided for @aboutLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get aboutLegal;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @termsOfUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUseTitle;

  /// No description provided for @privacyPolicyBody.
  ///
  /// In en, this message translates to:
  /// **'Last updated: July 2026\n\nThis Privacy Policy explains how Qmatch (“we”) handles information when you use the app. It is a product launch draft and may be updated. It is not formal legal advice.\n\nWhat Qmatch is\nQmatch is a connection and compatibility discovery app. IQ, EQ, and Frequency results are app-specific signals used for matching—not medical, clinical, or official intelligence tests, and not a guarantee of relationship success.\n\nAge\nQmatch is intended for adults. Profiles use an age of at least 18.\n\nInformation we may process\n• Account and authentication data (for example phone number or email when you sign in)\n• Profile details you provide (name, age, photos, bio, interests, preferences, approximate location if you enable it)\n• Assessment answers and results (IQ, EQ, Frequency) used for compatibility\n• Matching and messaging activity if you use Discover, Matches, or chat\n• Safety actions such as reports and blocks\n• Basic device and app usage data needed to run and improve the service\n\nHow we use information\nWe use this information to create your account, show profiles, calculate compatibility suggestions, enable messaging, improve safety, and operate the app.\n\nSharing\nWe do not sell your personal information. We may share data with service providers that help us run the app (for example authentication, hosting, or analytics), when required by law, or to protect users and the platform.\n\nYour choices\nYou can update profile information in the app, adjust some privacy toggles in Settings, block or report other users, and request account deletion in Settings → Delete account (or email support@qmatch.app). We aim to process deletion requests within 30 days. Some safety or legal records may be retained for a limited time when required.\n\nSafety offline\nIf you meet someone offline, meet in public, tell a friend, and never share financial information with people you do not know well.\n\nContact\nQuestions about privacy: support@qmatch.app'**
  String get privacyPolicyBody;

  /// No description provided for @termsOfUseBody.
  ///
  /// In en, this message translates to:
  /// **'Last updated: July 2026\n\nWelcome to Qmatch. These Terms of Use are a product launch draft for using the app. They are not a substitute for formal legal review.\n\nEligibility\nYou must be at least 18 years old and able to form a binding agreement to use Qmatch.\n\nThe service\nQmatch offers compatibility-oriented discovery using assessments (IQ, EQ, Frequency), profiles, and optional messaging. Results are app-specific compatibility signals—not medical or clinical diagnoses, not official IQ/EQ certifications, and not a promise that any match will succeed.\n\nYour responsibilities\nYou are responsible for how you interact with others. Be respectful, provide accurate profile information, and follow applicable laws. Do not harass, scam, impersonate others, or post harmful content.\n\nSafety tools\nYou can report and block users. We may review reports and take action, including limiting or ending accounts that misuse the service.\n\nAccount\nYou are responsible for your sign-in method (such as phone verification). You can request permanent account deletion in Settings → Delete account, or by emailing support@qmatch.app. We aim to process requests within 30 days. This is not temporary deactivation.\n\nDisclaimer\nQmatch is provided “as is.” We do not guarantee uninterrupted service, perfect matching, or outcomes of any connection.\n\nChanges\nWe may update these Terms. Continued use after updates means you accept the revised Terms.\n\nContact\nsupport@qmatch.app'**
  String get termsOfUseBody;

  /// No description provided for @helpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportTitle;

  /// No description provided for @helpSupportContact.
  ///
  /// In en, this message translates to:
  /// **'Need more help?\n\nEmail us at support@qmatch.app\n\nWe read every message. To delete your account, use Settings → Delete account (processed within 30 days), or email support with the phone or email on your account.'**
  String get helpSupportContact;

  /// No description provided for @supportEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'support@qmatch.app'**
  String get supportEmailLabel;

  /// No description provided for @openPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read Privacy Policy'**
  String get openPrivacyPolicy;

  /// No description provided for @openTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Read Terms of Use'**
  String get openTermsOfUse;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request permanent account deletion'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @settingsDeleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get settingsDeleteAccountDialogTitle;

  /// No description provided for @settingsDeleteAccountDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Use Settings → Delete account to submit an in-app request. You can also email support@qmatch.app.'**
  String get settingsDeleteAccountDialogBody;

  /// No description provided for @settingsDeleteAccountDialogAction.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get settingsDeleteAccountDialogAction;

  /// No description provided for @accountDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeletionTitle;

  /// No description provided for @accountDeletionWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'This starts a permanent deletion request'**
  String get accountDeletionWarningTitle;

  /// No description provided for @accountDeletionIntro.
  ///
  /// In en, this message translates to:
  /// **'You can request permanent deletion of your Qmatch account from inside the app. Submitting this form does not delete everything instantly—it creates a deletion request that we process.'**
  String get accountDeletionIntro;

  /// No description provided for @accountDeletionWillDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'What we plan to delete'**
  String get accountDeletionWillDeleteTitle;

  /// No description provided for @accountDeletionWillDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'• Your profile information\n• Photos and profile media references\n• Assessment answers and results (IQ, EQ, Frequency)\n• Account-linked compatibility and Discover visibility data\n• Your access to matches and chats tied to this account (as part of account closure)'**
  String get accountDeletionWillDeleteBody;

  /// No description provided for @accountDeletionMayRetainTitle.
  ///
  /// In en, this message translates to:
  /// **'What may be kept for a limited time'**
  String get accountDeletionMayRetainTitle;

  /// No description provided for @accountDeletionMayRetainBody.
  ///
  /// In en, this message translates to:
  /// **'• Safety reports and abuse-prevention records\n• Limited logs needed for legal or compliance reasons\nThese are not used to keep your dating profile active.'**
  String get accountDeletionMayRetainBody;

  /// No description provided for @accountDeletionTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing timeline'**
  String get accountDeletionTimelineTitle;

  /// No description provided for @accountDeletionTimelineBody.
  ///
  /// In en, this message translates to:
  /// **'We will process your request within 30 days. This is not temporary deactivation—the goal is permanent account deletion once processing is complete.'**
  String get accountDeletionTimelineBody;

  /// No description provided for @accountDeletionSupportHint.
  ///
  /// In en, this message translates to:
  /// **'Questions? Contact {email}'**
  String accountDeletionSupportHint(String email);

  /// No description provided for @accountDeletionAckIrreversible.
  ///
  /// In en, this message translates to:
  /// **'I understand this request is for permanent deletion, not temporary deactivation.'**
  String get accountDeletionAckIrreversible;

  /// No description provided for @accountDeletionAckTimeline.
  ///
  /// In en, this message translates to:
  /// **'I understand processing can take up to 30 days.'**
  String get accountDeletionAckTimeline;

  /// No description provided for @accountDeletionTypeDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Type {token} to confirm'**
  String accountDeletionTypeDeleteHint(String token);

  /// No description provided for @accountDeletionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit deletion request'**
  String get accountDeletionSubmit;

  /// No description provided for @accountDeletionNotImmediateNote.
  ///
  /// In en, this message translates to:
  /// **'Submitting does not immediately erase your data. We confirm when processing is complete.'**
  String get accountDeletionNotImmediateNote;

  /// No description provided for @accountDeletionAlreadyRequested.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending deletion request. If you need help, email support@qmatch.app.'**
  String get accountDeletionAlreadyRequested;

  /// No description provided for @accountDeletionRequestError.
  ///
  /// In en, this message translates to:
  /// **'We could not submit your request. Check your connection and try again, or email support@qmatch.app.'**
  String get accountDeletionRequestError;

  /// No description provided for @accountDeletionSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Request received'**
  String get accountDeletionSuccessTitle;

  /// No description provided for @accountDeletionSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your deletion request has been received. We will process it within 30 days. You can contact {email} if you have questions.'**
  String accountDeletionSuccessBody(String email);

  /// No description provided for @accountDeletionSuccessAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get accountDeletionSuccessAction;

  /// No description provided for @privacyPolicyTodo.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTodo;

  /// No description provided for @termsOfUseTodo.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUseTodo;

  /// No description provided for @helpSupportContactTodo.
  ///
  /// In en, this message translates to:
  /// **'Need more help?\n\nEmail us at support@qmatch.app\n\nWe read every message. To delete your account, use Settings → Delete account (processed within 30 days), or email support with the phone or email on your account.'**
  String get helpSupportContactTodo;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @profileAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get profileAboutMe;

  /// No description provided for @profileNoBioYet.
  ///
  /// In en, this message translates to:
  /// **'No bio yet'**
  String get profileNoBioYet;

  /// No description provided for @profileInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get profileInterests;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get profileSetupContinue;

  /// No description provided for @profileSetupComplete.
  ///
  /// In en, this message translates to:
  /// **'FINISH'**
  String get profileSetupComplete;

  /// No description provided for @profileSetupReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile ready!'**
  String get profileSetupReadyTitle;

  /// No description provided for @profileSetupReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Great! You can start discovering matches.'**
  String get profileSetupReadyMessage;

  /// No description provided for @nameSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get nameSelectionTitle;

  /// No description provided for @nameSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the name that will appear on QMatch'**
  String get nameSelectionSubtitle;

  /// No description provided for @nameSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameSelectionHint;

  /// No description provided for @nameSelectionTip.
  ///
  /// In en, this message translates to:
  /// **'We recommend using your real name'**
  String get nameSelectionTip;

  /// No description provided for @nameSelectionErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get nameSelectionErrorEmpty;

  /// No description provided for @nameSelectionErrorMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameSelectionErrorMinLength;

  /// No description provided for @privacySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySettingsTitle;

  /// No description provided for @notificationsSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSettingsTitle;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersTitle;

  /// No description provided for @showProfileInDiscover.
  ///
  /// In en, this message translates to:
  /// **'Show my profile in Discover'**
  String get showProfileInDiscover;

  /// No description provided for @showProfileInDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appear on the Discover screen'**
  String get showProfileInDiscoverSubtitle;

  /// No description provided for @showApproximateLocation.
  ///
  /// In en, this message translates to:
  /// **'Show approximate location'**
  String get showApproximateLocation;

  /// No description provided for @showApproximateLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your location approximately'**
  String get showApproximateLocationSubtitle;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn push notifications on or off'**
  String get pushNotificationsSubtitle;

  /// No description provided for @newMatchNotifications.
  ///
  /// In en, this message translates to:
  /// **'New match notifications'**
  String get newMatchNotifications;

  /// No description provided for @newMatchNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify me when I get a new match'**
  String get newMatchNotificationsSubtitle;

  /// No description provided for @newMessageNotifications.
  ///
  /// In en, this message translates to:
  /// **'New message notifications'**
  String get newMessageNotifications;

  /// No description provided for @newMessageNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify me when I get a new message'**
  String get newMessageNotificationsSubtitle;

  /// No description provided for @frequencyDailySuggestions.
  ///
  /// In en, this message translates to:
  /// **'Frequency / daily suggestions'**
  String get frequencyDailySuggestions;

  /// No description provided for @frequencyDailySuggestionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified about daily suggestions'**
  String get frequencyDailySuggestionsSubtitle;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign-in required.'**
  String get loginRequired;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @helpFaqHowWorksQ.
  ///
  /// In en, this message translates to:
  /// **'How does Qmatch work?'**
  String get helpFaqHowWorksQ;

  /// No description provided for @helpFaqHowWorksA.
  ///
  /// In en, this message translates to:
  /// **'Qmatch suggests people based on how you think (IQ), feel (EQ), and connect (Frequency), plus your profile. It is for discovering compatible connections—not a guarantee that any relationship will work out.'**
  String get helpFaqHowWorksA;

  /// No description provided for @helpFaqRankingQ.
  ///
  /// In en, this message translates to:
  /// **'How are matches ranked?'**
  String get helpFaqRankingQ;

  /// No description provided for @helpFaqRankingA.
  ///
  /// In en, this message translates to:
  /// **'Discover suggestions use compatibility signals (including Frequency patterns, archetype, interests, and supporting IQ/EQ bands). Rankings are app suggestions, not absolute truth.'**
  String get helpFaqRankingA;

  /// No description provided for @helpFaqFrequencyQ.
  ///
  /// In en, this message translates to:
  /// **'What does Frequency mean?'**
  String get helpFaqFrequencyQ;

  /// No description provided for @helpFaqFrequencyA.
  ///
  /// In en, this message translates to:
  /// **'Frequency describes how someone builds connection and communication rhythm—things like depth, social energy, and pace. It is an in-app style signal, not a clinical label.'**
  String get helpFaqFrequencyA;

  /// No description provided for @helpFaqScoresQ.
  ///
  /// In en, this message translates to:
  /// **'Are IQ and EQ real medical or official tests?'**
  String get helpFaqScoresQ;

  /// No description provided for @helpFaqScoresA.
  ///
  /// In en, this message translates to:
  /// **'No. Qmatch IQ, EQ, and Frequency scores are app-specific compatibility signals for matching. They are not medical, clinical, or official intelligence certifications.'**
  String get helpFaqScoresA;

  /// No description provided for @helpFaqPhotosQ.
  ///
  /// In en, this message translates to:
  /// **'Are photos visible on Qmatch?'**
  String get helpFaqPhotosQ;

  /// No description provided for @helpFaqPhotosA.
  ///
  /// In en, this message translates to:
  /// **'Yes. Photos and profile details you add can appear to others when you are discoverable. Only share what you are comfortable showing.'**
  String get helpFaqPhotosA;

  /// No description provided for @helpFaqBlockQ.
  ///
  /// In en, this message translates to:
  /// **'How do I block someone?'**
  String get helpFaqBlockQ;

  /// No description provided for @helpFaqBlockA.
  ///
  /// In en, this message translates to:
  /// **'Open a chat → menu → Block. Blocked people appear under Settings → Blocked users. Blocking helps stop further contact in the app.'**
  String get helpFaqBlockA;

  /// No description provided for @helpFaqReportQ.
  ///
  /// In en, this message translates to:
  /// **'How do I report someone?'**
  String get helpFaqReportQ;

  /// No description provided for @helpFaqReportA.
  ///
  /// In en, this message translates to:
  /// **'Open a chat → menu → Report and choose a reason. Reports are saved for review so we can help keep the community safer.'**
  String get helpFaqReportA;

  /// No description provided for @helpFaqSafetyQ.
  ///
  /// In en, this message translates to:
  /// **'Any tips for meeting offline?'**
  String get helpFaqSafetyQ;

  /// No description provided for @helpFaqSafetyA.
  ///
  /// In en, this message translates to:
  /// **'Meet in a public place, tell a friend where you are, arrange your own transport, and never send money or sensitive documents to someone you only know through the app.'**
  String get helpFaqSafetyA;

  /// No description provided for @helpFaqAgeQ.
  ///
  /// In en, this message translates to:
  /// **'What is the minimum age?'**
  String get helpFaqAgeQ;

  /// No description provided for @helpFaqAgeA.
  ///
  /// In en, this message translates to:
  /// **'Qmatch is for adults. Profiles use an age of at least 18.'**
  String get helpFaqAgeA;

  /// No description provided for @helpFaqDeleteAccountQ.
  ///
  /// In en, this message translates to:
  /// **'How do I delete my account?'**
  String get helpFaqDeleteAccountQ;

  /// No description provided for @helpFaqDeleteAccountA.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings → Delete account, read the notices, confirm both checkboxes, type DELETE, and submit. We process requests within 30 days. You can also email support@qmatch.app.'**
  String get helpFaqDeleteAccountA;

  /// No description provided for @helpFaqDataQ.
  ///
  /// In en, this message translates to:
  /// **'What data does Qmatch use?'**
  String get helpFaqDataQ;

  /// No description provided for @helpFaqDataA.
  ///
  /// In en, this message translates to:
  /// **'Depending on what you use: sign-in details, profile and photos, assessment answers and results, matches/messages, and safety actions like reports and blocks. See the Privacy Policy for more detail.'**
  String get helpFaqDataA;

  /// No description provided for @profileFieldAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get profileFieldAge;

  /// No description provided for @profileFieldGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileFieldGender;

  /// No description provided for @profileFieldEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get profileFieldEducation;

  /// No description provided for @profileFieldBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileFieldBio;

  /// No description provided for @profileFieldLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Relationship type'**
  String get profileFieldLookingFor;

  /// No description provided for @profileSetupPleaseComplete.
  ///
  /// In en, this message translates to:
  /// **'Please complete: {fields}'**
  String profileSetupPleaseComplete(String fields);

  /// No description provided for @profileSetupErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {message}'**
  String profileSetupErrorGeneric(String message);

  /// No description provided for @compatReasonArchetype.
  ///
  /// In en, this message translates to:
  /// **'Strong archetype alignment'**
  String get compatReasonArchetype;

  /// No description provided for @compatReasonThinking.
  ///
  /// In en, this message translates to:
  /// **'Compatible thinking style'**
  String get compatReasonThinking;

  /// No description provided for @compatReasonEmotional.
  ///
  /// In en, this message translates to:
  /// **'Similar emotional rhythm'**
  String get compatReasonEmotional;

  /// No description provided for @compatReasonFrequency.
  ///
  /// In en, this message translates to:
  /// **'Shared frequency tags'**
  String get compatReasonFrequency;

  /// No description provided for @compatReasonInterests.
  ///
  /// In en, this message translates to:
  /// **'Similar interests'**
  String get compatReasonInterests;

  /// No description provided for @compatReasonRecency.
  ///
  /// In en, this message translates to:
  /// **'Recently active'**
  String get compatReasonRecency;

  /// No description provided for @profileBasicInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get profileBasicInfoTitle;

  /// No description provided for @profileBasicInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get profileBasicInfoSubtitle;

  /// No description provided for @profileBioTitle.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get profileBioTitle;

  /// No description provided for @profileInterestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get profileInterestsTitle;

  /// No description provided for @profileLifestyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get profileLifestyleTitle;

  /// No description provided for @profileLifestyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — fill in what you want to share'**
  String get profileLifestyleSubtitle;

  /// No description provided for @profilePreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get profilePreferencesTitle;

  /// No description provided for @profilePreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your preferences shape your matches'**
  String get profilePreferencesSubtitle;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfile;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @profileBioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share what makes you you.'**
  String get profileBioSubtitle;

  /// No description provided for @profileInterestsMaxSelect.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 interests ({count}/5)'**
  String profileInterestsMaxSelect(int count);

  /// No description provided for @profileFieldLookingForLabel.
  ///
  /// In en, this message translates to:
  /// **'Relationship type *'**
  String get profileFieldLookingForLabel;

  /// No description provided for @profileFieldAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age *'**
  String get profileFieldAgeLabel;

  /// No description provided for @profileFieldGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender *'**
  String get profileFieldGenderLabel;

  /// No description provided for @profileFieldLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location *'**
  String get profileFieldLocationLabel;

  /// No description provided for @profileFieldEducationLabel.
  ///
  /// In en, this message translates to:
  /// **'Education *'**
  String get profileFieldEducationLabel;

  /// No description provided for @optGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get optGenderMale;

  /// No description provided for @optGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get optGenderFemale;

  /// No description provided for @optGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get optGenderOther;

  /// No description provided for @optEduHighSchool.
  ///
  /// In en, this message translates to:
  /// **'High school'**
  String get optEduHighSchool;

  /// No description provided for @optEduAssociate.
  ///
  /// In en, this message translates to:
  /// **'Associate degree'**
  String get optEduAssociate;

  /// No description provided for @optEduBachelor.
  ///
  /// In en, this message translates to:
  /// **'Bachelor\'s degree'**
  String get optEduBachelor;

  /// No description provided for @optEduMaster.
  ///
  /// In en, this message translates to:
  /// **'Master\'s degree'**
  String get optEduMaster;

  /// No description provided for @optEduDoctorate.
  ///
  /// In en, this message translates to:
  /// **'Doctorate'**
  String get optEduDoctorate;

  /// No description provided for @optLookingSerious.
  ///
  /// In en, this message translates to:
  /// **'Serious relationship'**
  String get optLookingSerious;

  /// No description provided for @optLookingLongTerm.
  ///
  /// In en, this message translates to:
  /// **'Long-term relationship'**
  String get optLookingLongTerm;

  /// No description provided for @optLookingMarriage.
  ///
  /// In en, this message translates to:
  /// **'Marriage'**
  String get optLookingMarriage;

  /// No description provided for @optLookingFriendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship'**
  String get optLookingFriendship;

  /// No description provided for @optLookingCloseFriendship.
  ///
  /// In en, this message translates to:
  /// **'Close friendship'**
  String get optLookingCloseFriendship;

  /// No description provided for @optLookingCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual / chatting'**
  String get optLookingCasual;

  /// No description provided for @optLookingUnsure.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet'**
  String get optLookingUnsure;

  /// No description provided for @optLookingGoWithFlow.
  ///
  /// In en, this message translates to:
  /// **'Going with the flow'**
  String get optLookingGoWithFlow;

  /// No description provided for @optNever.
  ///
  /// In en, this message translates to:
  /// **'I don\'t'**
  String get optNever;

  /// No description provided for @optDrinkingSocial.
  ///
  /// In en, this message translates to:
  /// **'Social drinker'**
  String get optDrinkingSocial;

  /// No description provided for @optDrinkingOften.
  ///
  /// In en, this message translates to:
  /// **'Often'**
  String get optDrinkingOften;

  /// No description provided for @optDrinkingSpecial.
  ///
  /// In en, this message translates to:
  /// **'Only on special occasions'**
  String get optDrinkingSpecial;

  /// No description provided for @optSmokingSometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get optSmokingSometimes;

  /// No description provided for @optSmokingRegular.
  ///
  /// In en, this message translates to:
  /// **'Regularly'**
  String get optSmokingRegular;

  /// No description provided for @optSmokingQuitting.
  ///
  /// In en, this message translates to:
  /// **'Trying to quit'**
  String get optSmokingQuitting;

  /// No description provided for @optYesHave.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get optYesHave;

  /// No description provided for @optNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get optNo;

  /// No description provided for @optPetsWant.
  ///
  /// In en, this message translates to:
  /// **'I want a pet'**
  String get optPetsWant;

  /// No description provided for @optPetsAllergy.
  ///
  /// In en, this message translates to:
  /// **'Allergic'**
  String get optPetsAllergy;

  /// No description provided for @optAnimalLoveHigh.
  ///
  /// In en, this message translates to:
  /// **'Animal lover'**
  String get optAnimalLoveHigh;

  /// No description provided for @optAnimalLoveYes.
  ///
  /// In en, this message translates to:
  /// **'I like animals'**
  String get optAnimalLoveYes;

  /// No description provided for @optAnimalLoveNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get optAnimalLoveNeutral;

  /// No description provided for @optAnimalLoveLow.
  ///
  /// In en, this message translates to:
  /// **'Not really'**
  String get optAnimalLoveLow;

  /// No description provided for @optChildrenWant.
  ///
  /// In en, this message translates to:
  /// **'No, but I want kids'**
  String get optChildrenWant;

  /// No description provided for @optChildrenNo.
  ///
  /// In en, this message translates to:
  /// **'Don\'t want kids'**
  String get optChildrenNo;

  /// No description provided for @optChildrenUnsure.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet'**
  String get optChildrenUnsure;

  /// No description provided for @optChildrenMaybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get optChildrenMaybe;

  /// No description provided for @optReligionMuslim.
  ///
  /// In en, this message translates to:
  /// **'Muslim'**
  String get optReligionMuslim;

  /// No description provided for @optReligionChristian.
  ///
  /// In en, this message translates to:
  /// **'Christian'**
  String get optReligionChristian;

  /// No description provided for @optReligionJewish.
  ///
  /// In en, this message translates to:
  /// **'Jewish'**
  String get optReligionJewish;

  /// No description provided for @optReligionBuddhist.
  ///
  /// In en, this message translates to:
  /// **'Buddhist'**
  String get optReligionBuddhist;

  /// No description provided for @optReligionHindu.
  ///
  /// In en, this message translates to:
  /// **'Hindu'**
  String get optReligionHindu;

  /// No description provided for @optReligionAgnostic.
  ///
  /// In en, this message translates to:
  /// **'Agnostic'**
  String get optReligionAgnostic;

  /// No description provided for @optReligionAtheist.
  ///
  /// In en, this message translates to:
  /// **'Atheist'**
  String get optReligionAtheist;

  /// No description provided for @optReligionSpiritual.
  ///
  /// In en, this message translates to:
  /// **'Spiritual (non-religious)'**
  String get optReligionSpiritual;

  /// No description provided for @optPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get optPreferNotToSay;

  /// No description provided for @optPetsHave.
  ///
  /// In en, this message translates to:
  /// **'I have a pet'**
  String get optPetsHave;

  /// No description provided for @optPetsNone.
  ///
  /// In en, this message translates to:
  /// **'No pets'**
  String get optPetsNone;

  /// No description provided for @optChildrenHave.
  ///
  /// In en, this message translates to:
  /// **'I have children'**
  String get optChildrenHave;

  /// No description provided for @profileSelectAge.
  ///
  /// In en, this message translates to:
  /// **'Select your age'**
  String get profileSelectAge;

  /// No description provided for @profileSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get profileSelectGender;

  /// No description provided for @profileSelectEducation.
  ///
  /// In en, this message translates to:
  /// **'Select education level'**
  String get profileSelectEducation;

  /// No description provided for @profileShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share your location'**
  String get profileShareLocation;

  /// No description provided for @profileLocationLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting location…'**
  String get profileLocationLoading;

  /// No description provided for @profileLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Location is only used to calculate distance'**
  String get profileLocationHint;

  /// No description provided for @profileLocationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Location: {location}'**
  String profileLocationSuccess(String location);

  /// No description provided for @profileLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get location: {message}'**
  String profileLocationError(String message);

  /// No description provided for @profileLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get profileLocationPermissionDenied;

  /// No description provided for @profileLocationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Enable it in Settings.'**
  String get profileLocationPermissionPermanentlyDenied;

  /// No description provided for @profileOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get profileOccupation;

  /// No description provided for @profileOccupationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Software engineer'**
  String get profileOccupationHint;

  /// No description provided for @profileDrinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get profileDrinking;

  /// No description provided for @profileSmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get profileSmoking;

  /// No description provided for @profilePets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get profilePets;

  /// No description provided for @profileAnimalLove.
  ///
  /// In en, this message translates to:
  /// **'Love of animals'**
  String get profileAnimalLove;

  /// No description provided for @profileChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get profileChildren;

  /// No description provided for @profileReligion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get profileReligion;

  /// No description provided for @profileSelectOption.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get profileSelectOption;

  /// No description provided for @profileLookingForHint.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get profileLookingForHint;

  /// No description provided for @profileAgeRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age range: {min} – {max}'**
  String profileAgeRangeLabel(int min, int max);

  /// No description provided for @profileMaxDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum distance: {km} km'**
  String profileMaxDistanceLabel(int km);

  /// No description provided for @profilePreferencesEditableHint.
  ///
  /// In en, this message translates to:
  /// **'You can change these preferences anytime'**
  String get profilePreferencesEditableHint;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Introduce yourself… hobbies, passions, dreams.'**
  String get profileBioHint;

  /// No description provided for @settingsMvpPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Some privacy toggles on this screen are stored on this device for now. Core profile, assessments, matches, and messages sync with your account. For full details, read the Privacy Policy in About.'**
  String get settingsMvpPrivacyNote;

  /// No description provided for @settingsMvpNotificationsNote.
  ///
  /// In en, this message translates to:
  /// **'Notification preferences on this screen are stored on this device for now. Push delivery also depends on your phone settings.'**
  String get settingsMvpNotificationsNote;

  /// No description provided for @blockedUsersError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {message}'**
  String blockedUsersError(String message);

  /// No description provided for @blockedUsersBlockedAt.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedUsersBlockedAt;

  /// No description provided for @mainAppWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to QMatch!'**
  String get mainAppWelcome;

  /// No description provided for @mainAppComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Main app coming soon…'**
  String get mainAppComingSoon;

  /// No description provided for @emailSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get emailSignupTitle;

  /// No description provided for @emailSignupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'with email'**
  String get emailSignupSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @signupJoinToday.
  ///
  /// In en, this message translates to:
  /// **'Join QMatch today'**
  String get signupJoinToday;

  /// No description provided for @signupCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signupCreateAccount;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get signupErrorWeakPassword;

  /// No description provided for @signupErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email'**
  String get signupErrorEmailInUse;

  /// No description provided for @signupErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get signupErrorInvalidEmail;

  /// No description provided for @signupErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed. Please try again.'**
  String get signupErrorFailed;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameRequired;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinLength;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyEmailTitle;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent!'**
  String get verificationEmailSent;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationTitle;

  /// No description provided for @verificationCodeSentEmail.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to email'**
  String get verificationCodeSentEmail;

  /// No description provided for @verificationCodeSentSms.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent via SMS'**
  String get verificationCodeSentSms;

  /// No description provided for @verificationEnterEmailCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to\n{contact}'**
  String verificationEnterEmailCode(String contact);

  /// No description provided for @verificationEnterSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the SMS code sent to\n{contact}'**
  String verificationEnterSmsCode(String contact);

  /// No description provided for @resendCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCodeAction;

  /// No description provided for @socialContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get socialContinueGoogle;

  /// No description provided for @socialContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get socialContinueApple;

  /// No description provided for @socialOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Or continue with email'**
  String get socialOrEmail;

  /// No description provided for @interestCatSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get interestCatSports;

  /// No description provided for @interestCatArts.
  ///
  /// In en, this message translates to:
  /// **'Arts'**
  String get interestCatArts;

  /// No description provided for @interestCatTech.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get interestCatTech;

  /// No description provided for @interestCatTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get interestCatTravel;

  /// No description provided for @interestFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get interestFootball;

  /// No description provided for @interestBasketball.
  ///
  /// In en, this message translates to:
  /// **'Basketball'**
  String get interestBasketball;

  /// No description provided for @interestTennis.
  ///
  /// In en, this message translates to:
  /// **'Tennis'**
  String get interestTennis;

  /// No description provided for @interestSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get interestSwimming;

  /// No description provided for @interestYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get interestYoga;

  /// No description provided for @interestFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get interestFitness;

  /// No description provided for @interestVolleyball.
  ///
  /// In en, this message translates to:
  /// **'Volleyball'**
  String get interestVolleyball;

  /// No description provided for @interestPilates.
  ///
  /// In en, this message translates to:
  /// **'Pilates'**
  String get interestPilates;

  /// No description provided for @interestRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get interestRunning;

  /// No description provided for @interestCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get interestCycling;

  /// No description provided for @interestHiking.
  ///
  /// In en, this message translates to:
  /// **'Hiking / mountaineering'**
  String get interestHiking;

  /// No description provided for @interestGymnastics.
  ///
  /// In en, this message translates to:
  /// **'Gymnastics'**
  String get interestGymnastics;

  /// No description provided for @interestBoxing.
  ///
  /// In en, this message translates to:
  /// **'Boxing'**
  String get interestBoxing;

  /// No description provided for @interestSailing.
  ///
  /// In en, this message translates to:
  /// **'Sailing'**
  String get interestSailing;

  /// No description provided for @interestGolf.
  ///
  /// In en, this message translates to:
  /// **'Golf'**
  String get interestGolf;

  /// No description provided for @interestMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get interestMusic;

  /// No description provided for @interestPainting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get interestPainting;

  /// No description provided for @interestCinema.
  ///
  /// In en, this message translates to:
  /// **'Cinema'**
  String get interestCinema;

  /// No description provided for @interestTheatre.
  ///
  /// In en, this message translates to:
  /// **'Theatre'**
  String get interestTheatre;

  /// No description provided for @interestDance.
  ///
  /// In en, this message translates to:
  /// **'Dance'**
  String get interestDance;

  /// No description provided for @interestLiterature.
  ///
  /// In en, this message translates to:
  /// **'Literature'**
  String get interestLiterature;

  /// No description provided for @interestPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get interestPhotography;

  /// No description provided for @interestSculpture.
  ///
  /// In en, this message translates to:
  /// **'Sculpture'**
  String get interestSculpture;

  /// No description provided for @interestGraphicDesign.
  ///
  /// In en, this message translates to:
  /// **'Graphic design'**
  String get interestGraphicDesign;

  /// No description provided for @interestPoetry.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get interestPoetry;

  /// No description provided for @interestWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get interestWriting;

  /// No description provided for @interestStandup.
  ///
  /// In en, this message translates to:
  /// **'Stand-up'**
  String get interestStandup;

  /// No description provided for @interestInstrument.
  ///
  /// In en, this message translates to:
  /// **'Playing an instrument'**
  String get interestInstrument;

  /// No description provided for @interestOpera.
  ///
  /// In en, this message translates to:
  /// **'Opera'**
  String get interestOpera;

  /// No description provided for @interestBallet.
  ///
  /// In en, this message translates to:
  /// **'Ballet'**
  String get interestBallet;

  /// No description provided for @interestCoding.
  ///
  /// In en, this message translates to:
  /// **'Coding'**
  String get interestCoding;

  /// No description provided for @interestGaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get interestGaming;

  /// No description provided for @interestAiml.
  ///
  /// In en, this message translates to:
  /// **'AI/ML'**
  String get interestAiml;

  /// No description provided for @interestCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get interestCrypto;

  /// No description provided for @interestWeb3.
  ///
  /// In en, this message translates to:
  /// **'Web3'**
  String get interestWeb3;

  /// No description provided for @interestRobotics.
  ///
  /// In en, this message translates to:
  /// **'Robotics'**
  String get interestRobotics;

  /// No description provided for @interestCybersecurity.
  ///
  /// In en, this message translates to:
  /// **'Cybersecurity'**
  String get interestCybersecurity;

  /// No description provided for @interestDataScience.
  ///
  /// In en, this message translates to:
  /// **'Data science'**
  String get interestDataScience;

  /// No description provided for @interestMobileApps.
  ///
  /// In en, this message translates to:
  /// **'Mobile apps'**
  String get interestMobileApps;

  /// No description provided for @interestBlockchain.
  ///
  /// In en, this message translates to:
  /// **'Blockchain'**
  String get interestBlockchain;

  /// No description provided for @interestIot.
  ///
  /// In en, this message translates to:
  /// **'IoT'**
  String get interestIot;

  /// No description provided for @interestCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud computing'**
  String get interestCloud;

  /// No description provided for @interestCamping.
  ///
  /// In en, this message translates to:
  /// **'Camping'**
  String get interestCamping;

  /// No description provided for @interestNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get interestNature;

  /// No description provided for @interestAbroad.
  ///
  /// In en, this message translates to:
  /// **'Travel abroad'**
  String get interestAbroad;

  /// No description provided for @interestCultureTours.
  ///
  /// In en, this message translates to:
  /// **'Culture tours'**
  String get interestCultureTours;

  /// No description provided for @interestSafari.
  ///
  /// In en, this message translates to:
  /// **'Safari'**
  String get interestSafari;

  /// No description provided for @interestFoodTours.
  ///
  /// In en, this message translates to:
  /// **'Food tours'**
  String get interestFoodTours;

  /// No description provided for @interestExtremeSports.
  ///
  /// In en, this message translates to:
  /// **'Extreme sports'**
  String get interestExtremeSports;

  /// No description provided for @interestBackpacking.
  ///
  /// In en, this message translates to:
  /// **'Backpacking'**
  String get interestBackpacking;

  /// No description provided for @interestLuxuryTravel.
  ///
  /// In en, this message translates to:
  /// **'Luxury travel'**
  String get interestLuxuryTravel;

  /// No description provided for @interestHistoricSites.
  ///
  /// In en, this message translates to:
  /// **'Historic sites'**
  String get interestHistoricSites;

  /// No description provided for @interestBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach holiday'**
  String get interestBeach;

  /// No description provided for @interestSoloTravel.
  ///
  /// In en, this message translates to:
  /// **'Solo travel'**
  String get interestSoloTravel;

  /// No description provided for @emailVerificationSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to:\n{email}'**
  String emailVerificationSentTo(String email);

  /// No description provided for @emailVerificationNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next steps:'**
  String get emailVerificationNextSteps;

  /// No description provided for @emailVerificationStepInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your email inbox'**
  String get emailVerificationStepInbox;

  /// No description provided for @emailVerificationStepClick.
  ///
  /// In en, this message translates to:
  /// **'Click the verification link'**
  String get emailVerificationStepClick;

  /// No description provided for @emailVerificationStepReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to this app'**
  String get emailVerificationStepReturn;

  /// No description provided for @emailVerificationWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification…'**
  String get emailVerificationWaiting;

  /// No description provided for @emailVerificationResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String emailVerificationResendIn(int seconds);

  /// No description provided for @emailVerificationResend.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get emailVerificationResend;

  /// No description provided for @emailVerificationSpamHint.
  ///
  /// In en, this message translates to:
  /// **'Check your spam folder if you don\'t see it.'**
  String get emailVerificationSpamHint;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @socialContinueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get socialContinueWithEmail;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @privacyVisibilitySection.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get privacyVisibilitySection;

  /// No description provided for @privacyDataSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Data & security'**
  String get privacyDataSecuritySection;

  /// No description provided for @socialCreateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your QMatch account'**
  String get socialCreateAccountSubtitle;

  /// No description provided for @socialAlreadyHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get socialAlreadyHaveAccountLogin;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
