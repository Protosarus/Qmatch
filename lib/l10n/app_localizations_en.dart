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

  @override
  String get assessmentContinue => 'Continue';

  @override
  String get assessmentBack => 'Back';

  @override
  String get assessmentNext => 'Next';

  @override
  String get assessmentFinish => 'Finish';

  @override
  String get assessmentComplete => 'Assessment Complete!';

  @override
  String get assessmentPleaseSelectAnswer => 'Please select an answer';

  @override
  String get assessmentStart => 'Start';

  @override
  String get assessmentNoQuestionsAvailable => 'No questions available';

  @override
  String get iqTestTitle => 'IQ Test';

  @override
  String get startIqTest => 'Start IQ Test';

  @override
  String get iqTestCompleted => 'IQ Test Completed!';

  @override
  String get iqToEqMessage =>
      'Great! Now let\'s test your emotional intelligence.';

  @override
  String get eqTestTitle => 'EQ Test';

  @override
  String get eqIntroHeadline => 'Emotional Intelligence';

  @override
  String get eqIntroDescription =>
      'Your emotional quotient (EQ) measures your ability to understand and manage emotions - both yours and others\'.';

  @override
  String get eqBulletQuestions => '10 scenario-based questions';

  @override
  String get eqBulletEmpathy => 'Measures empathy & self-awareness';

  @override
  String get eqBulletDuration => 'Takes about 5 minutes';

  @override
  String get startEqTest => 'Start EQ Test';

  @override
  String get eqTestCompleted => 'EQ Test Completed!';

  @override
  String get frequencyIntroTitle => 'Discover your frequency';

  @override
  String get frequencyIntroDescription =>
      'Frequency is not about intelligence. It is about how you connect, communicate, and build trust.';

  @override
  String get frequencyBulletConnect => 'How deeply you prefer to connect';

  @override
  String get frequencyBulletTrust => 'How fast you build trust';

  @override
  String get frequencyBulletOpenness => 'How much emotional openness you bring';

  @override
  String get frequencyBulletRhythm =>
      'What kind of conversation rhythm fits you';

  @override
  String get startFrequencyTest => 'Start Frequency Test';

  @override
  String get frequencyTestTitle => 'Frequency Test';

  @override
  String get yourFrequency => 'Your frequency';

  @override
  String get balancedFrequency => 'Balanced Frequency';

  @override
  String get frequencyScore => 'Score';

  @override
  String get seeMyFrequency => 'See My Frequency';

  @override
  String get stronglyDisagree => 'Strongly disagree';

  @override
  String get disagree => 'Disagree';

  @override
  String get neutral => 'Neutral';

  @override
  String get agree => 'Agree';

  @override
  String get stronglyAgree => 'Strongly agree';

  @override
  String get continueAction => 'Continue';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get finish => 'Finish';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get start => 'Start';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Error';

  @override
  String get submit => 'Submit';

  @override
  String get send => 'Send';

  @override
  String get deleteAction => 'Delete';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get welcomeMatchMinds => 'Match minds.';

  @override
  String get welcomeFeelTheFrequency => 'Feel the frequency.';

  @override
  String get welcomeSubtitle =>
      'Meet people through personality, emotion, and real compatibility.';

  @override
  String get welcomeContinueWithPhone => 'Continue with phone';

  @override
  String get welcomeSecureSignInHint => 'Secure sign-in. No email required.';

  @override
  String get welcomeAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get welcomeLogIn => 'Log in';

  @override
  String get welcomeTermsPrivacy =>
      'By continuing, you agree to Qmatch\'s Terms and Privacy Policy.';

  @override
  String get phoneSignupTitleAskNumber => 'What\'s your number?';

  @override
  String get phoneSignupTitleEnterCode => 'Enter the code';

  @override
  String get phoneSignupSubtitleSendCode =>
      'We\'ll send a verification code to confirm it\'s you.';

  @override
  String get phoneSignupSubtitleCodeSent =>
      'We sent a verification code to your phone.';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get mobileNumberHint => 'Mobile number';

  @override
  String get searchCountry => 'Search country';

  @override
  String get phoneSignupCountryHint =>
      'Select your country code, then enter your mobile number.';

  @override
  String get verificationCode => 'Verification code';

  @override
  String get changeNumber => 'Change number';

  @override
  String get resendCode => 'Resend code';

  @override
  String get sendCode => 'Send code';

  @override
  String get verify => 'Verify';

  @override
  String get phoneSignupSmsDisclaimer =>
      'By continuing, you may receive an SMS for verification. Message and data rates may apply.';

  @override
  String get phoneSignupErrorInvalidPhone =>
      'Please enter a valid phone number.';

  @override
  String get phoneSignupErrorSmsFailed =>
      'SMS could not be sent. Please try again.';

  @override
  String get phoneSignupErrorPhoneLooksInvalid =>
      'This phone number looks invalid.';

  @override
  String get phoneSignupErrorVerificationExpired =>
      'Verification expired. Please request a new code.';

  @override
  String get phoneSignupErrorEnterSmsCode => 'Please enter the SMS code.';

  @override
  String get phoneSignupErrorIncorrectCode =>
      'That code is incorrect. Please try again.';

  @override
  String get phoneSignupErrorVerificationFailed =>
      'Verification failed. Please try again.';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in with your email to continue.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get logIn => 'Log in';

  @override
  String get loginPreferPhoneHint =>
      'Prefer phone? Go back and continue with phone.';

  @override
  String get loginErrorEnterEmail => 'Please enter your email';

  @override
  String get loginErrorValidEmail => 'Please enter a valid email';

  @override
  String get loginErrorEnterPassword => 'Please enter your password';

  @override
  String get loginErrorPasswordMinLength =>
      'Password must be at least 6 characters';

  @override
  String get loginErrorIncorrectCredentials =>
      'Email or password is incorrect.';

  @override
  String get loginErrorValidEmailAddress =>
      'Please enter a valid email address.';

  @override
  String get loginErrorFailed => 'Login failed. Please try again.';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverItsAMatch => 'It\'s a match';

  @override
  String get discoverMatchDialogBody => 'You can now start a conversation.';

  @override
  String get discoverEmptyTitle => 'No compatible profiles yet.';

  @override
  String get discoverEmptySubtitle =>
      'Try again later as more people join Qmatch.';

  @override
  String get discoverPass => 'Pass';

  @override
  String get discoverLike => 'Like';

  @override
  String discoverPercentCompatibility(int percent) {
    return '$percent% compatibility';
  }

  @override
  String get discoverInterests => 'Interests';

  @override
  String get compatibilityLabelExceptional => 'Exceptional match';

  @override
  String get compatibilityLabelStrong => 'Strong match';

  @override
  String get compatibilityLabelGood => 'Good match';

  @override
  String get compatibilityLabelPotential => 'Potential match';

  @override
  String get compatibilityLabelLowSignal => 'Low signal';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesLoadErrorTitle => 'Could not load conversations.';

  @override
  String get messagesLoadErrorSubtitle => 'Please try again in a moment.';

  @override
  String get messagesEmptyTitle => 'No conversations yet';

  @override
  String get messagesEmptySubtitle =>
      'When you match with someone, your conversation will appear here.';

  @override
  String get messagesConversationFallback => 'Conversation';

  @override
  String get messagesSayHi => 'Say hi 👋';

  @override
  String get chatMenuReport => 'Report';

  @override
  String get chatMenuUnmatch => 'Unmatch';

  @override
  String get chatMenuBlock => 'Block';

  @override
  String get chatReportDialogTitle => 'Report user';

  @override
  String get chatReportDialogSubtitle => 'Tell us what happened.';

  @override
  String get chatReportReasonHarassment => 'Harassment';

  @override
  String get chatReportReasonSpam => 'Spam';

  @override
  String get chatReportReasonImpersonation => 'Impersonation';

  @override
  String get chatReportReasonInappropriate => 'Inappropriate content';

  @override
  String get chatReportReasonScam => 'Scam';

  @override
  String get chatReportReasonOther => 'Other';

  @override
  String get chatReportDetailsHint => 'Details (optional)';

  @override
  String get chatReportSubmitted => 'Report submitted.';

  @override
  String get chatMatchNotFound => 'Match not found.';

  @override
  String get chatUnmatchDialogTitle => 'Unmatch?';

  @override
  String get chatUnmatchDialogBody =>
      'This will close the conversation. You will not be able to continue chatting.';

  @override
  String get chatMatchRemoved => 'Match removed.';

  @override
  String get chatBlockDialogTitle => 'Block this user?';

  @override
  String get chatBlockDialogBody =>
      'They will no longer be able to message you in this conversation.';

  @override
  String get chatUserBlocked => 'User blocked.';

  @override
  String get chatMessageHint => 'Message…';

  @override
  String get chatStartConversation => 'Start the conversation.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle => 'Manage notification preferences';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacySubtitle => 'Privacy settings';

  @override
  String get settingsBlocked => 'Blocked users';

  @override
  String get settingsBlockedSubtitle => 'People you\'ve blocked';

  @override
  String get settingsHelpSupport => 'Help & Support';

  @override
  String get settingsHelpSupportSubtitle => 'Frequently asked questions';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutSubtitle => 'App information';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutSubtitle => 'Sign out of your account';

  @override
  String get settingsLogoutConfirmTitle => 'Log out?';

  @override
  String get settingsLogoutConfirmBody =>
      'You will be signed out of your account.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutVersion => 'Version 1.0.0';

  @override
  String get aboutTagline => 'Minds First';

  @override
  String get aboutDescription =>
      'Qmatch matches people not only on looks, but on how they think, feel, and connect.';

  @override
  String get aboutLegal => 'Legal';

  @override
  String get privacyPolicyTodo => 'Privacy Policy (TODO)';

  @override
  String get termsOfUseTodo => 'Terms of Use (TODO)';

  @override
  String get helpSupportTitle => 'Help & Support';

  @override
  String get helpSupportContactTodo =>
      'Contact support (MVP):\n\nTODO: Add in-app support request or email link.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get profileAboutMe => 'About me';

  @override
  String get profileNoBioYet => 'No bio yet';

  @override
  String get profileInterests => 'Interests';

  @override
  String get profileSetupTitle => 'Create Profile';

  @override
  String get profileSetupContinue => 'CONTINUE';

  @override
  String get profileSetupComplete => 'FINISH';

  @override
  String get profileSetupReadyTitle => 'Profile ready!';

  @override
  String get profileSetupReadyMessage =>
      'Great! You can start discovering matches.';

  @override
  String get nameSelectionTitle => 'What should we call you?';

  @override
  String get nameSelectionSubtitle =>
      'Choose the name that will appear on QMatch';

  @override
  String get nameSelectionHint => 'Your name';

  @override
  String get nameSelectionTip => 'We recommend using your real name';

  @override
  String get nameSelectionErrorEmpty => 'Please enter a name';

  @override
  String get nameSelectionErrorMinLength =>
      'Name must be at least 2 characters';

  @override
  String get privacySettingsTitle => 'Privacy';

  @override
  String get notificationsSettingsTitle => 'Notifications';

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get showProfileInDiscover => 'Show my profile in Discover';

  @override
  String get showProfileInDiscoverSubtitle => 'Appear on the Discover screen';

  @override
  String get showApproximateLocation => 'Show approximate location';

  @override
  String get showApproximateLocationSubtitle =>
      'Share your location approximately';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsSubtitle => 'Turn push notifications on or off';

  @override
  String get newMatchNotifications => 'New match notifications';

  @override
  String get newMatchNotificationsSubtitle =>
      'Notify me when I get a new match';

  @override
  String get newMessageNotifications => 'New message notifications';

  @override
  String get newMessageNotificationsSubtitle =>
      'Notify me when I get a new message';

  @override
  String get frequencyDailySuggestions => 'Frequency / daily suggestions';

  @override
  String get frequencyDailySuggestionsSubtitle =>
      'Get notified about daily suggestions';

  @override
  String get unblock => 'Unblock';

  @override
  String get loginRequired => 'Sign-in required.';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get helpFaqHowWorksQ => 'How does Qmatch work?';

  @override
  String get helpFaqHowWorksA =>
      'Qmatch suggests matches based on how you think (IQ), feel (EQ), and connect (Frequency). The goal is compatibility—not looks alone.';

  @override
  String get helpFaqRankingQ => 'How are matches ranked?';

  @override
  String get helpFaqRankingA =>
      'Discover suggestions are ranked by compatibility (IQ/EQ/Frequency), archetype, and shared interests.';

  @override
  String get helpFaqFrequencyQ => 'What does Frequency mean?';

  @override
  String get helpFaqFrequencyA =>
      'Frequency describes how someone builds connection and communication rhythm—depth, social energy, and how quickly trust forms.';

  @override
  String get helpFaqPhotosQ => 'Are photos visible on Qmatch?';

  @override
  String get helpFaqPhotosA =>
      'Yes. Qmatch aims for more meaningful connections through compatibility layers; photos are shown normally.';

  @override
  String get helpFaqBlockQ => 'How do I block someone?';

  @override
  String get helpFaqBlockA =>
      'Use Block in the chat menu. Blocked users appear under Settings → Blocked users.';

  @override
  String get helpFaqReportQ => 'How do I report someone?';

  @override
  String get helpFaqReportA =>
      'Use Report in the chat menu and choose a reason. Reports are saved for review.';

  @override
  String get profileFieldAge => 'Age';

  @override
  String get profileFieldGender => 'Gender';

  @override
  String get profileFieldEducation => 'Education';

  @override
  String get profileFieldBio => 'Bio';

  @override
  String get profileFieldLookingFor => 'Relationship type';

  @override
  String profileSetupPleaseComplete(String fields) {
    return 'Please complete: $fields';
  }

  @override
  String profileSetupErrorGeneric(String message) {
    return 'Something went wrong: $message';
  }

  @override
  String get compatReasonArchetype => 'Strong archetype alignment';

  @override
  String get compatReasonThinking => 'Compatible thinking style';

  @override
  String get compatReasonEmotional => 'Similar emotional rhythm';

  @override
  String get compatReasonFrequency => 'Shared frequency tags';

  @override
  String get compatReasonInterests => 'Similar interests';

  @override
  String get compatReasonRecency => 'Recently active';

  @override
  String get profileBasicInfoTitle => 'Basic info';

  @override
  String get profileBasicInfoSubtitle => 'Tell us about yourself';

  @override
  String get profileBioTitle => 'About you';

  @override
  String get profileInterestsTitle => 'Interests';

  @override
  String get profileLifestyleTitle => 'Lifestyle';

  @override
  String get profileLifestyleSubtitle =>
      'Optional — fill in what you want to share';

  @override
  String get profilePreferencesTitle => 'What are you looking for?';

  @override
  String get profilePreferencesSubtitle =>
      'Your preferences shape your matches';

  @override
  String get photos => 'Photos';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get completeProfile => 'Complete profile';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get profileBioSubtitle => 'Share what makes you you.';

  @override
  String profileInterestsMaxSelect(int count) {
    return 'Choose up to 5 interests ($count/5)';
  }

  @override
  String get profileFieldLookingForLabel => 'Relationship type *';

  @override
  String get profileFieldAgeLabel => 'Age *';

  @override
  String get profileFieldGenderLabel => 'Gender *';

  @override
  String get profileFieldLocationLabel => 'Location *';

  @override
  String get profileFieldEducationLabel => 'Education *';

  @override
  String get optGenderMale => 'Male';

  @override
  String get optGenderFemale => 'Female';

  @override
  String get optGenderOther => 'Other';

  @override
  String get optEduHighSchool => 'High school';

  @override
  String get optEduAssociate => 'Associate degree';

  @override
  String get optEduBachelor => 'Bachelor\'s degree';

  @override
  String get optEduMaster => 'Master\'s degree';

  @override
  String get optEduDoctorate => 'Doctorate';

  @override
  String get optLookingSerious => 'Serious relationship';

  @override
  String get optLookingLongTerm => 'Long-term relationship';

  @override
  String get optLookingMarriage => 'Marriage';

  @override
  String get optLookingFriendship => 'Friendship';

  @override
  String get optLookingCloseFriendship => 'Close friendship';

  @override
  String get optLookingCasual => 'Casual / chatting';

  @override
  String get optLookingUnsure => 'Not sure yet';

  @override
  String get optLookingGoWithFlow => 'Going with the flow';

  @override
  String get optNever => 'I don\'t';

  @override
  String get optDrinkingSocial => 'Social drinker';

  @override
  String get optDrinkingOften => 'Often';

  @override
  String get optDrinkingSpecial => 'Only on special occasions';

  @override
  String get optSmokingSometimes => 'Sometimes';

  @override
  String get optSmokingRegular => 'Regularly';

  @override
  String get optSmokingQuitting => 'Trying to quit';

  @override
  String get optYesHave => 'Yes';

  @override
  String get optNo => 'No';

  @override
  String get optPetsWant => 'I want a pet';

  @override
  String get optPetsAllergy => 'Allergic';

  @override
  String get optAnimalLoveHigh => 'Animal lover';

  @override
  String get optAnimalLoveYes => 'I like animals';

  @override
  String get optAnimalLoveNeutral => 'Neutral';

  @override
  String get optAnimalLoveLow => 'Not really';

  @override
  String get optChildrenWant => 'No, but I want kids';

  @override
  String get optChildrenNo => 'Don\'t want kids';

  @override
  String get optChildrenUnsure => 'Not sure yet';

  @override
  String get optChildrenMaybe => 'Maybe later';

  @override
  String get optReligionMuslim => 'Muslim';

  @override
  String get optReligionChristian => 'Christian';

  @override
  String get optReligionJewish => 'Jewish';

  @override
  String get optReligionBuddhist => 'Buddhist';

  @override
  String get optReligionHindu => 'Hindu';

  @override
  String get optReligionAgnostic => 'Agnostic';

  @override
  String get optReligionAtheist => 'Atheist';

  @override
  String get optReligionSpiritual => 'Spiritual (non-religious)';

  @override
  String get optPreferNotToSay => 'Prefer not to say';

  @override
  String get optPetsHave => 'I have a pet';

  @override
  String get optPetsNone => 'No pets';

  @override
  String get optChildrenHave => 'I have children';

  @override
  String get profileSelectAge => 'Select your age';

  @override
  String get profileSelectGender => 'Select your gender';

  @override
  String get profileSelectEducation => 'Select education level';

  @override
  String get profileShareLocation => 'Share your location';

  @override
  String get profileLocationLoading => 'Getting location…';

  @override
  String get profileLocationHint =>
      'Location is only used to calculate distance';

  @override
  String profileLocationSuccess(String location) {
    return 'Location: $location';
  }

  @override
  String profileLocationError(String message) {
    return 'Could not get location: $message';
  }

  @override
  String get profileLocationPermissionDenied => 'Location permission denied';

  @override
  String get profileLocationPermissionPermanentlyDenied =>
      'Location permission permanently denied. Enable it in Settings.';

  @override
  String get profileOccupation => 'Occupation';

  @override
  String get profileOccupationHint => 'e.g. Software engineer';

  @override
  String get profileDrinking => 'Drinking';

  @override
  String get profileSmoking => 'Smoking';

  @override
  String get profilePets => 'Pets';

  @override
  String get profileAnimalLove => 'Love of animals';

  @override
  String get profileChildren => 'Children';

  @override
  String get profileReligion => 'Religion';

  @override
  String get profileSelectOption => 'Select';

  @override
  String get profileLookingForHint => 'What are you looking for?';

  @override
  String profileAgeRangeLabel(int min, int max) {
    return 'Age range: $min – $max';
  }

  @override
  String profileMaxDistanceLabel(int km) {
    return 'Maximum distance: $km km';
  }

  @override
  String get profilePreferencesEditableHint =>
      'You can change these preferences anytime';

  @override
  String get profileBioHint => 'Introduce yourself… hobbies, passions, dreams.';

  @override
  String get settingsMvpPrivacyNote =>
      'Privacy settings are stored locally in this MVP.\n\nTODO: Persist these preferences to Firestore or device storage.';

  @override
  String get settingsMvpNotificationsNote =>
      'TODO: Persist notification preferences to Firestore or device storage.';

  @override
  String blockedUsersError(String message) {
    return 'Something went wrong: $message';
  }

  @override
  String get blockedUsersBlockedAt => 'Blocked';

  @override
  String get mainAppWelcome => 'Welcome to QMatch!';

  @override
  String get mainAppComingSoon => 'Main app coming soon…';

  @override
  String get emailSignupTitle => 'Create account';

  @override
  String get emailSignupSubtitle => 'with email';

  @override
  String get fullName => 'Full name';

  @override
  String get signUp => 'Sign up';

  @override
  String get signupJoinToday => 'Join QMatch today';

  @override
  String get signupCreateAccount => 'Create account';

  @override
  String get signupAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get signupErrorWeakPassword => 'Password is too weak';

  @override
  String get signupErrorEmailInUse =>
      'An account already exists with this email';

  @override
  String get signupErrorInvalidEmail => 'Invalid email address';

  @override
  String get signupErrorFailed => 'Signup failed. Please try again.';

  @override
  String get nameRequired => 'Please enter your name';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get verifyEmailTitle => 'Verify email';

  @override
  String get verificationEmailSent => 'Verification email sent!';

  @override
  String get verificationTitle => 'Verification';

  @override
  String get verificationCodeSentEmail => 'Verification code sent to email';

  @override
  String get verificationCodeSentSms => 'Verification code sent via SMS';

  @override
  String verificationEnterEmailCode(String contact) {
    return 'Enter the code sent to\n$contact';
  }

  @override
  String verificationEnterSmsCode(String contact) {
    return 'Enter the SMS code sent to\n$contact';
  }

  @override
  String get resendCodeAction => 'Resend code';

  @override
  String get socialContinueGoogle => 'Continue with Google';

  @override
  String get socialContinueApple => 'Continue with Apple';

  @override
  String get socialOrEmail => 'Or continue with email';

  @override
  String get interestCatSports => 'Sports';

  @override
  String get interestCatArts => 'Arts';

  @override
  String get interestCatTech => 'Technology';

  @override
  String get interestCatTravel => 'Travel';

  @override
  String get interestFootball => 'Football';

  @override
  String get interestBasketball => 'Basketball';

  @override
  String get interestTennis => 'Tennis';

  @override
  String get interestSwimming => 'Swimming';

  @override
  String get interestYoga => 'Yoga';

  @override
  String get interestFitness => 'Fitness';

  @override
  String get interestVolleyball => 'Volleyball';

  @override
  String get interestPilates => 'Pilates';

  @override
  String get interestRunning => 'Running';

  @override
  String get interestCycling => 'Cycling';

  @override
  String get interestHiking => 'Hiking / mountaineering';

  @override
  String get interestGymnastics => 'Gymnastics';

  @override
  String get interestBoxing => 'Boxing';

  @override
  String get interestSailing => 'Sailing';

  @override
  String get interestGolf => 'Golf';

  @override
  String get interestMusic => 'Music';

  @override
  String get interestPainting => 'Painting';

  @override
  String get interestCinema => 'Cinema';

  @override
  String get interestTheatre => 'Theatre';

  @override
  String get interestDance => 'Dance';

  @override
  String get interestLiterature => 'Literature';

  @override
  String get interestPhotography => 'Photography';

  @override
  String get interestSculpture => 'Sculpture';

  @override
  String get interestGraphicDesign => 'Graphic design';

  @override
  String get interestPoetry => 'Poetry';

  @override
  String get interestWriting => 'Writing';

  @override
  String get interestStandup => 'Stand-up';

  @override
  String get interestInstrument => 'Playing an instrument';

  @override
  String get interestOpera => 'Opera';

  @override
  String get interestBallet => 'Ballet';

  @override
  String get interestCoding => 'Coding';

  @override
  String get interestGaming => 'Gaming';

  @override
  String get interestAiml => 'AI/ML';

  @override
  String get interestCrypto => 'Crypto';

  @override
  String get interestWeb3 => 'Web3';

  @override
  String get interestRobotics => 'Robotics';

  @override
  String get interestCybersecurity => 'Cybersecurity';

  @override
  String get interestDataScience => 'Data science';

  @override
  String get interestMobileApps => 'Mobile apps';

  @override
  String get interestBlockchain => 'Blockchain';

  @override
  String get interestIot => 'IoT';

  @override
  String get interestCloud => 'Cloud computing';

  @override
  String get interestCamping => 'Camping';

  @override
  String get interestNature => 'Nature';

  @override
  String get interestAbroad => 'Travel abroad';

  @override
  String get interestCultureTours => 'Culture tours';

  @override
  String get interestSafari => 'Safari';

  @override
  String get interestFoodTours => 'Food tours';

  @override
  String get interestExtremeSports => 'Extreme sports';

  @override
  String get interestBackpacking => 'Backpacking';

  @override
  String get interestLuxuryTravel => 'Luxury travel';

  @override
  String get interestHistoricSites => 'Historic sites';

  @override
  String get interestBeach => 'Beach holiday';

  @override
  String get interestSoloTravel => 'Solo travel';

  @override
  String emailVerificationSentTo(String email) {
    return 'We sent a verification link to:\n$email';
  }

  @override
  String get emailVerificationNextSteps => 'Next steps:';

  @override
  String get emailVerificationStepInbox => 'Check your email inbox';

  @override
  String get emailVerificationStepClick => 'Click the verification link';

  @override
  String get emailVerificationStepReturn => 'Return to this app';

  @override
  String get emailVerificationWaiting => 'Waiting for verification…';

  @override
  String emailVerificationResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get emailVerificationResend => 'Resend email';

  @override
  String get emailVerificationSpamHint =>
      'Check your spam folder if you don\'t see it.';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get socialContinueWithEmail => 'Continue with email';

  @override
  String get orDivider => 'or';

  @override
  String get privacyVisibilitySection => 'Visibility';

  @override
  String get privacyDataSecuritySection => 'Data & security';

  @override
  String get socialCreateAccountSubtitle => 'Create your QMatch account';

  @override
  String get socialAlreadyHaveAccountLogin => 'Already have an account? Log in';
}
