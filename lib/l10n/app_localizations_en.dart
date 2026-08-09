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
  String get assessmentProfileCreated => 'Your mental profile is ready.';

  @override
  String get assessmentViewProfile => 'View My Profile';

  @override
  String get assessmentPleaseSelectAnswer => 'Please select an answer';

  @override
  String get iqPleaseSelectAnswerToContinue => 'Select an answer to continue';

  @override
  String get assessmentStart => 'Start';

  @override
  String get assessmentNoQuestionsAvailable => 'No questions available';

  @override
  String get iqTestTitle => 'IQ Test';

  @override
  String get startIqTest => 'Start IQ Test';

  @override
  String get iqIntroHeadline => 'Build your cognitive profile';

  @override
  String get iqIntroLabel => 'IQ Assessment';

  @override
  String get iqIntroMeta => '25 questions · About 8 minutes';

  @override
  String get iqIntroStart => 'Begin assessment';

  @override
  String iqQuestionProgress(int current, int total) {
    return 'IQ · $current / $total';
  }

  @override
  String get iqQuestionLabel => 'IQ Question';

  @override
  String get iqTestCompleted => 'IQ assessment complete';

  @override
  String get iqToEqMessage =>
      'The first part of your cognitive profile is ready. Now let\'s continue with your emotional profile.';

  @override
  String get continueToEqAssessment => 'Continue to EQ assessment';

  @override
  String get iqReasoningProfileTitle => 'Reasoning Profile';

  @override
  String get iqReasoningProfileSubtitle =>
      'Your uncalibrated multidimensional reasoning performance on this session.';

  @override
  String get iqUncalibratedDisclaimer =>
      'Not a standardized IQ score · Not a population percentile';

  @override
  String get iqCanonicalSessionError =>
      'We couldn\'t load your assessment session. Please try again.';

  @override
  String get iqCanonicalAnswerError =>
      'We couldn\'t save your answer. Please try again.';

  @override
  String get iqCanonicalPersistError =>
      'We couldn\'t save your result. Your answers are safe; you can try again.';

  @override
  String get iqCanonicalFinalizeRetry => 'Save result';

  @override
  String get assessmentPrerequisiteRepairError =>
      'A previous assessment needs to be repaired before you can continue. Please retry or restart that assessment.';

  @override
  String get iqDimLogicalReasoning => 'Logical Reasoning';

  @override
  String get iqDimPatternReasoning => 'Pattern Reasoning';

  @override
  String get iqDimVerbalReasoning => 'Verbal Reasoning';

  @override
  String get iqDimSpatialReasoning => 'Spatial Reasoning';

  @override
  String get eqTestTitle => 'EQ Test';

  @override
  String get eqIntroLabel => 'EQ Assessment';

  @override
  String get eqIntroMeta => '10 questions · About 5 minutes';

  @override
  String get eqIntroStart => 'Begin EQ assessment';

  @override
  String get eqIntroHeadlineLead => 'Emotional';

  @override
  String get eqIntroHeadlineEmphasis => 'Intelligence';

  @override
  String get eqPillarSelfAwareness => 'Self-awareness';

  @override
  String get eqPillarEmpathy => 'Empathy';

  @override
  String get eqPillarBalance => 'Emotional Balance';

  @override
  String get eqPillarHarmony => 'Inner Harmony';

  @override
  String eqQuestionProgress(int current, int total) {
    return 'EQ · $current / $total';
  }

  @override
  String get eqQuestionInsightLabel => 'EQ';

  @override
  String get eqCategoryEmpathy => 'Empathy';

  @override
  String get eqCategorySelfAwareness => 'Self-Awareness';

  @override
  String get eqCategoryEmotionalBalance => 'Emotional Balance';

  @override
  String get eqCategorySocialAwareness => 'Social Awareness';

  @override
  String get eqCategoryRelationshipManagement => 'Relationship Management';

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
  String get assessmentStageIq => 'IQ';

  @override
  String get assessmentStageEq => 'EQ';

  @override
  String get assessmentStageFrequency => 'Frequency';

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
  String get welcomeContinueWithPhone => 'Continue with Phone';

  @override
  String get welcomeSecureSignInHint => 'Secure sign-in. No email required.';

  @override
  String get welcomeAlreadyHaveAccount => 'Already have an account? ';

  @override
  String get welcomeLogIn => 'Log in';

  @override
  String get welcomeLogInWithEmail => 'Log in with email';

  @override
  String get welcomeTagline => 'INTELLIGENCE. EMOTION. FREQUENCY.';

  @override
  String get welcomeHeadlinePrefix => 'Find your';

  @override
  String get welcomeHeadlineEmphasis => 'frequency';

  @override
  String get welcomeCueIntelligent => 'Intelligent\nmatching';

  @override
  String get welcomeCueEmotional => 'Emotional\nconnection';

  @override
  String get welcomeCueVibrational => 'Vibrational\nalignment';

  @override
  String get welcomeTrustPrivateTitle => 'Made for you';

  @override
  String get welcomeTrustPrivateBody => 'Matches that truly understand you.';

  @override
  String get welcomeTrustScienceTitle => 'Deeper compatibility';

  @override
  String get welcomeTrustScienceBody => 'Mind, emotion, and frequency.';

  @override
  String get welcomeTrustMatchesTitle => 'Real connections';

  @override
  String get welcomeTrustMatchesBody => 'Meaningful, not random.';

  @override
  String get welcomeTermsOfService => 'Terms of Service';

  @override
  String get welcomePrivacyPolicy => 'Privacy Policy';

  @override
  String get welcomeLegalPrefix => 'By continuing, you agree to our ';

  @override
  String get welcomeLegalAnd => ' and ';

  @override
  String get welcomeLegalSuffix => '.';

  @override
  String get welcomeTermsPrivacy =>
      'By continuing, you agree to our Terms of Service and Privacy Policy.';

  @override
  String get phoneSignupTitleAskNumber => 'Connect to your world';

  @override
  String get phoneSignupTitleEnterCode => 'Enter the code';

  @override
  String get phoneSignupSubtitleSendCode =>
      'Verify your phone number for secure access.';

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
  String get loginWelcomeBack => 'Welcome';

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
  String get discoverEmptyTitle => 'No new profiles to show right now.';

  @override
  String get discoverEmptySubtitle => 'You can check again in a little while.';

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
  String get discoverLoading => 'Finding people for you…';

  @override
  String get discoverErrorTitle => 'Couldn\'t load profiles';

  @override
  String get discoverErrorBody =>
      'Something went wrong while loading Discover. Please try again.';

  @override
  String get discoverActionFailed =>
      'That action couldn\'t be completed. Please try again.';

  @override
  String get discoverMissingPhotoLabel => 'Profile photo unavailable';

  @override
  String discoverPhotoSemanticLabel(String name) {
    return 'Photo of $name';
  }

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
  String get messagesLoading => 'Loading conversations…';

  @override
  String messagesAvatarSemanticLabel(String name) {
    return 'Photo of $name';
  }

  @override
  String messagesUnreadSemanticLabel(int count) {
    return '$count unread messages';
  }

  @override
  String messagesConversationSemanticLabel(String name) {
    return 'Conversation with $name';
  }

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
  String get chatEmptySubtitle =>
      'Say hello when you are ready. There is no rush.';

  @override
  String get chatLoadingMessages => 'Loading messages…';

  @override
  String get chatMessagesLoadErrorTitle => 'Could not load messages.';

  @override
  String get chatMessagesLoadErrorSubtitle => 'Please try again in a moment.';

  @override
  String get chatProfileLoadErrorTitle => 'Could not load profile.';

  @override
  String get chatProfileLoadErrorSubtitle =>
      'Profile details are unavailable right now.';

  @override
  String get chatSendFailed => 'Message could not be sent. Please try again.';

  @override
  String get chatActionFailed => 'Something went wrong. Please try again.';

  @override
  String get chatDateToday => 'Today';

  @override
  String get chatSendSemanticLabel => 'Send message';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGroupPreferences => 'Preferences';

  @override
  String get settingsGroupPrivacySafety => 'Privacy & safety';

  @override
  String get settingsGroupHelp => 'Help & information';

  @override
  String get settingsGroupAccount => 'Account';

  @override
  String get settingsGroupDeveloper => 'Developer';

  @override
  String get settingsNotificationsHonestSubtitle =>
      'Device preferences for now — push delivery depends on your phone settings';

  @override
  String get settingsPrivacyHonestSubtitle =>
      'Visibility options on this device for now — see Privacy Policy for details';

  @override
  String get settingsDebug => 'Debug';

  @override
  String get settingsDebugSubtitle =>
      'Assessment admin and tools (debug builds only)';

  @override
  String get profilePhotosEmptyTitle => 'Add your first photo';

  @override
  String get profilePhotosEmptyBody =>
      'Photos help people recognize you. You can add up to 9.';

  @override
  String get profilePhotosEmptyHint =>
      'Your photos appear on your profile and in Discover when you are eligible.';

  @override
  String get profilePhotosAddFirst => 'Add photo';

  @override
  String get profilePhotosAddTile => 'Add';

  @override
  String get profilePhotosUploading => 'Uploading…';

  @override
  String get profilePhotosUploadFailed =>
      'Couldn\'t upload photos. Please try again.';

  @override
  String get profilePhotosDeleteFailed =>
      'Couldn\'t delete that photo. Please try again.';

  @override
  String get profilePhotosAtCapacity => 'You\'ve reached the 9-photo maximum.';

  @override
  String get profilePhotosPrimaryBadge => 'Main photo';

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
      'Qmatch helps people discover compatible connections based on how they think, feel, and connect—not looks alone. Compatibility insights are meant to support discovery; they do not guarantee a relationship.';

  @override
  String get aboutLegal => 'Legal';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get termsOfUseTitle => 'Terms of Use';

  @override
  String get privacyPolicyBody =>
      'Last updated: July 2026\n\nThis Privacy Policy explains how Qmatch (“we”) handles information when you use the app. It is a product launch draft and may be updated. It is not formal legal advice.\n\nWhat Qmatch is\nQmatch is a connection and compatibility discovery app. IQ, EQ, and Frequency results are app-specific signals used for matching—not medical, clinical, or official intelligence tests, and not a guarantee of relationship success.\n\nAge\nQmatch is intended for adults. Profiles use an age of at least 18.\n\nInformation we may process\n• Account and authentication data (for example phone number or email when you sign in)\n• Profile details you provide (name, age, photos, bio, interests, preferences, approximate location if you enable it)\n• Assessment answers and results (IQ, EQ, Frequency) used for compatibility\n• Matching and messaging activity if you use Discover, Matches, or chat\n• Safety actions such as reports and blocks\n• Basic device and app usage data needed to run and improve the service\n\nHow we use information\nWe use this information to create your account, show profiles, calculate compatibility suggestions, enable messaging, improve safety, and operate the app.\n\nSharing\nWe do not sell your personal information. We may share data with service providers that help us run the app (for example authentication, hosting, or analytics), when required by law, or to protect users and the platform.\n\nYour choices\nYou can update profile information in the app, adjust some privacy toggles in Settings, block or report other users, and request account deletion in Settings → Delete account (or email support@qmatch.site). We aim to process deletion requests within 30 days. Some safety or legal records may be retained for a limited time when required.\n\nSafety offline\nIf you meet someone offline, meet in public, tell a friend, and never share financial information with people you do not know well.\n\nContact\nQuestions about privacy: support@qmatch.site';

  @override
  String get termsOfUseBody =>
      'Last updated: July 2026\n\nWelcome to Qmatch. These Terms of Use are a product launch draft for using the app. They are not a substitute for formal legal review.\n\nEligibility\nYou must be at least 18 years old and able to form a binding agreement to use Qmatch.\n\nThe service\nQmatch offers compatibility-oriented discovery using assessments (IQ, EQ, Frequency), profiles, and optional messaging. Results are app-specific compatibility signals—not medical or clinical diagnoses, not official IQ/EQ certifications, and not a promise that any match will succeed.\n\nYour responsibilities\nYou are responsible for how you interact with others. Be respectful, provide accurate profile information, and follow applicable laws. Do not harass, scam, impersonate others, or post harmful content.\n\nSafety tools\nYou can report and block users. We may review reports and take action, including limiting or ending accounts that misuse the service.\n\nAccount\nYou are responsible for your sign-in method (such as phone verification). You can request permanent account deletion in Settings → Delete account, or by emailing support@qmatch.site. We aim to process requests within 30 days. This is not temporary deactivation.\n\nDisclaimer\nQmatch is provided “as is.” We do not guarantee uninterrupted service, perfect matching, or outcomes of any connection.\n\nChanges\nWe may update these Terms. Continued use after updates means you accept the revised Terms.\n\nContact\nsupport@qmatch.site';

  @override
  String get helpSupportTitle => 'Help & Support';

  @override
  String get helpSupportContact =>
      'Need more help?\n\nEmail us at support@qmatch.site\n\nWe read every message. To delete your account, use Settings → Delete account (processed within 30 days), or email support with the phone or email on your account.';

  @override
  String get supportEmailLabel => 'support@qmatch.site';

  @override
  String get openPrivacyPolicy => 'Read Privacy Policy';

  @override
  String get openTermsOfUse => 'Read Terms of Use';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Request permanent account deletion';

  @override
  String get settingsDeleteAccountPendingStatus => 'Account deletion requested';

  @override
  String get settingsDeleteAccountPendingSubtitle =>
      'View request status and timeline';

  @override
  String get settingsDeleteAccountPendingBanner =>
      'Your account deletion request is pending. We will process it within 30 days. Contact support@qmatch.site if you need help.';

  @override
  String get settingsDeleteAccountDialogTitle => 'Request account deletion';

  @override
  String get settingsDeleteAccountDialogBody =>
      'Use Settings → Delete account to submit an in-app request. You can also email support@qmatch.site.';

  @override
  String get settingsDeleteAccountDialogAction => 'Got it';

  @override
  String get accountDeletionTitle => 'Delete account';

  @override
  String get accountDeletionWarningTitle =>
      'This starts a permanent deletion request';

  @override
  String get accountDeletionIntro =>
      'You can request permanent deletion of your Qmatch account from inside the app. Submitting this form does not delete everything instantly—it creates a deletion request that we process.';

  @override
  String get accountDeletionWillDeleteTitle => 'What we plan to delete';

  @override
  String get accountDeletionWillDeleteBody =>
      '• Your profile information\n• Photos and profile media references\n• Assessment answers and results (IQ, EQ, Frequency)\n• Account-linked compatibility and Discover visibility data\n• Your access to matches and chats tied to this account (as part of account closure)';

  @override
  String get accountDeletionMayRetainTitle =>
      'What may be kept for a limited time';

  @override
  String get accountDeletionMayRetainBody =>
      '• Safety reports and abuse-prevention records\n• Limited logs needed for legal or compliance reasons\nThese are not used to keep your dating profile active.';

  @override
  String get accountDeletionTimelineTitle => 'Processing timeline';

  @override
  String get accountDeletionTimelineBody =>
      'We will process your request within 30 days. This is not temporary deactivation—the goal is permanent account deletion once processing is complete.';

  @override
  String accountDeletionSupportHint(String email) {
    return 'Questions? Contact $email';
  }

  @override
  String get accountDeletionAckIrreversible =>
      'I understand this request is for permanent deletion, not temporary deactivation.';

  @override
  String get accountDeletionAckTimeline =>
      'I understand processing can take up to 30 days.';

  @override
  String accountDeletionTypeDeleteHint(String token) {
    return 'Type $token to confirm';
  }

  @override
  String get accountDeletionSubmit => 'Submit deletion request';

  @override
  String get accountDeletionNotImmediateNote =>
      'Submitting does not immediately erase your data. We confirm when processing is complete.';

  @override
  String get accountDeletionAlreadyRequested =>
      'You already have a pending deletion request. If you need help, email support@qmatch.site.';

  @override
  String get accountDeletionPendingTitle => 'Request already received';

  @override
  String accountDeletionPendingBody(String email) {
    return 'Your deletion request has been received and is pending. We will process it within 30 days. You can contact $email if you have questions.';
  }

  @override
  String get accountDeletionPendingNoResubmit =>
      'You do not need to submit another request. Duplicate submissions are disabled while this request is pending.';

  @override
  String get accountDeletionRequestError =>
      'We could not submit your request. Check your connection and try again, or email support@qmatch.site.';

  @override
  String get discoverAccountDeletionPendingBanner =>
      'Your account deletion request is pending.';

  @override
  String get accountDeletionSuccessTitle => 'Request received';

  @override
  String accountDeletionSuccessBody(String email) {
    return 'Your deletion request has been received. We will process it within 30 days. You can contact $email if you have questions.';
  }

  @override
  String get accountDeletionSuccessAction => 'Done';

  @override
  String get privacyPolicyTodo => 'Privacy Policy';

  @override
  String get termsOfUseTodo => 'Terms of Use';

  @override
  String get helpSupportContactTodo =>
      'Need more help?\n\nEmail us at support@qmatch.site\n\nWe read every message. To delete your account, use Settings → Delete account (processed within 30 days), or email support with the phone or email on your account.';

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
  String get profileNoInterestsYet => 'No interests added yet';

  @override
  String get profileDetailsSection => 'Details';

  @override
  String get profileLoading => 'Loading profile…';

  @override
  String get profileLoadFailed =>
      'Couldn\'t load your profile. Please try again.';

  @override
  String get profileMissingPhoto => 'Add a photo';

  @override
  String get profileEditPhotoSemantic => 'Edit profile photo';

  @override
  String get profileFieldOccupation => 'Occupation';

  @override
  String get profileFieldDrinking => 'Drinking';

  @override
  String get profileFieldSmoking => 'Smoking';

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
  String get displayNameTitle => 'What should we call you?';

  @override
  String get displayNameSubtitle =>
      'This name will appear on your profile to other people.';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get displayNameHint => 'Your name';

  @override
  String get displayNamePublicExplanation =>
      'Not a unique username. You can change it later.';

  @override
  String get displayNameContinue => 'Continue';

  @override
  String get displayNameSaving => 'Saving…';

  @override
  String get displayNameErrorEmpty => 'Please enter a display name.';

  @override
  String get displayNameErrorTooShort => 'Use at least 2 characters.';

  @override
  String get displayNameErrorTooLong => 'Use at most 24 characters.';

  @override
  String get displayNameErrorLetterOrNumber =>
      'Include at least one letter or number.';

  @override
  String get displayNameErrorInvalid =>
      'That name contains invalid characters.';

  @override
  String get displayNameErrorEmailLike =>
      'Please use a name, not an email address.';

  @override
  String get displayNameErrorPhoneLike =>
      'Please use a name, not a phone number.';

  @override
  String get displayNameErrorUrlLike => 'Please use a name, not a website.';

  @override
  String get displayNameErrorSaveFailed =>
      'Could not save your name. Please try again.';

  @override
  String get displayNameMissingPeerLabel => 'Member';

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
      'Qmatch suggests people based on how you think (IQ), feel (EQ), and connect (Frequency), plus your profile. It is for discovering compatible connections—not a guarantee that any relationship will work out.';

  @override
  String get helpFaqRankingQ => 'How are matches ranked?';

  @override
  String get helpFaqRankingA =>
      'Discover suggestions use compatibility signals (including Frequency patterns, archetype, interests, and supporting IQ/EQ bands). Rankings are app suggestions, not absolute truth.';

  @override
  String get helpFaqFrequencyQ => 'What does Frequency mean?';

  @override
  String get helpFaqFrequencyA =>
      'Frequency describes how someone builds connection and communication rhythm—things like depth, social energy, and pace. It is an in-app style signal, not a clinical label.';

  @override
  String get helpFaqScoresQ => 'Are IQ and EQ real medical or official tests?';

  @override
  String get helpFaqScoresA =>
      'No. Qmatch IQ, EQ, and Frequency scores are app-specific compatibility signals for matching. They are not medical, clinical, or official intelligence certifications.';

  @override
  String get helpFaqPhotosQ => 'Are photos visible on Qmatch?';

  @override
  String get helpFaqPhotosA =>
      'Yes. Photos and profile details you add can appear to others when you are discoverable. Only share what you are comfortable showing.';

  @override
  String get helpFaqBlockQ => 'How do I block someone?';

  @override
  String get helpFaqBlockA =>
      'Open a chat → menu → Block. Blocked people appear under Settings → Blocked users. Blocking helps stop further contact in the app.';

  @override
  String get helpFaqReportQ => 'How do I report someone?';

  @override
  String get helpFaqReportA =>
      'Open a chat → menu → Report and choose a reason. Reports are saved for review so we can help keep the community safer.';

  @override
  String get helpFaqSafetyQ => 'Any tips for meeting offline?';

  @override
  String get helpFaqSafetyA =>
      'Meet in a public place, tell a friend where you are, arrange your own transport, and never send money or sensitive documents to someone you only know through the app.';

  @override
  String get helpFaqAgeQ => 'What is the minimum age?';

  @override
  String get helpFaqAgeA =>
      'Qmatch is for adults. Profiles use an age of at least 18.';

  @override
  String get helpFaqDeleteAccountQ => 'How do I delete my account?';

  @override
  String get helpFaqDeleteAccountA =>
      'Go to Settings → Delete account, read the notices, confirm both checkboxes, type DELETE, and submit. We process requests within 30 days. You can also email support@qmatch.site.';

  @override
  String get helpFaqDataQ => 'What data does Qmatch use?';

  @override
  String get helpFaqDataA =>
      'Depending on what you use: sign-in details, profile and photos, assessment answers and results, matches/messages, and safety actions like reports and blocks. See the Privacy Policy for more detail.';

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
      'Some privacy toggles on this screen are stored on this device for now. Core profile, assessments, matches, and messages sync with your account. For full details, read the Privacy Policy in About.';

  @override
  String get settingsMvpNotificationsNote =>
      'Notification preferences on this screen are stored on this device for now. Push delivery also depends on your phone settings.';

  @override
  String get blockedUsersLoadFailed =>
      'We couldn\'t load blocked users right now. Please try again later.';

  @override
  String blockedUsersError(String message) {
    return 'Something went wrong: $message';
  }

  @override
  String get blockedUsersBlockedAt => 'Blocked';

  @override
  String get debugModeUnavailable =>
      'Debug Mode is available only in debug builds.';

  @override
  String get debugHomeTitle => 'Debug tools';

  @override
  String get debugHomeSubtitle =>
      'Development-only tools. These routes stay unavailable in release and profile builds.';

  @override
  String get debugAssessmentAdmin => 'Assessment Admin';

  @override
  String get debugPersonaPreview => 'Persona Result Preview';

  @override
  String get debugFrequencyPreview => 'Frequency Question Preview';

  @override
  String get debugProfileSetupPreview => 'Profile Setup Preview';

  @override
  String get debugGoToAuthWrapper => 'Go to Auth Wrapper';

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
