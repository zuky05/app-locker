class AppTexts {
  final String appName;
  final String navHome;
  final String navDecks;
  final String navSettings;
  final String homeTitle;
  final String homeSubtitle;
  
  final String Function(int) deckCardCount;

  // --- App Selector Screen ---
  final String blockedAppsTitle;
  final String tooltipUnblockAll;
  final String appsToLockTitle;
  final String appsToLockDescription;
  final String searchAppHint;
  final String noAppFound;
  final String dialogUnblockAllTitle;
  final String dialogUnblockAllContent;
  final String buttonCancel;
  final String buttonUnblock;
  final String dialogPremiumTitle;
  final String dialogPremiumContent;
  final String buttonUnlockPremium;

  // --- Block Choice Screen ---
  final String blockChoiceTitle;
  final String blockChoiceStartLearning;
  final String blockChoiceStartTest;
  final String blockChoiceTimeoutLearning;
  final String blockChoiceTimeoutTest;
  final String blockChoiceUnlock1Min;
  final String Function(int) blockChoiceGracePeriod;
  final String blockChoiceGraceExhausted;

  // --- Create Deck Screen ---
  final String createDeckTitle;
  final String createDeckNameHint;
  final String createDeckNameHintCyber;
  final String createDeckCategoryHint;
  final String createDeckCategoryHintCyber;
  final String createDeckBtnAddCards;
  final String createDeckBtnSave;

  // --- Deck Detail Screen ---
  final String deckDetailEmpty;
  final String deckDetailNewCardTitle;
  final String deckDetailPromptHint;
  final String deckDetailAnswerHint;
  final String deckDetailBtnAddCard;
  final String deckDetailQuestionLabel;
  final String deckDetailAnswerLabel;
  final String deckDetailBtnAdd;

  // --- Premade Decks ---
  final String premadeDeckEnglishBasicName;
  final String premadeDeckItTermsName;
  final String premadeDeckGeographyName;
  final String premadeCategoryLanguages;
  final String premadeCategoryIt;
  final String premadeCategoryGeography;

  // --- Deck Manager Screen ---
  final String deckManagerTitle;
  final String tabMyDecks;
  final String tabPremadeDecks;
  final String activeBadge;
  final String btnActive;
  final String btnSelect;
  final String btnView;
  final String btnTest;
  final String btnShare;
  final String btnEditCards;
  final String btnRename;
  final String btnDelete;
  final String emptyMyDecks;
  final String emptyPremadeDecks;
  final String addDeckDialogTitle;
  final String optionCustomDeck;
  final String optionCsvImport;
  final String optionAnkiImport;
  final String renameDeckTitle;
  final String fieldDeckName;
  final String fieldCategory;
  final String btnSave;
  final String deleteDeckTitle;
  final String Function(String) deleteDeckContent;
  final String btnDeleteAction;
  final String errorMinCardsBlock;
  final String errorMinCardsTest;
  final String premiumLimitTitle;
  final String premiumLimitCustomDecks;
  final String premiumSuccessToast;

  // --- Home Screen ---
  final String homeScreenTitle;
  final String tooltipPremium;
  final String tooltipSettings;
  final String goalCardTitle;
  final String goalCompleted;
  final String Function(int) streakDaysFormat;
  final String carouselTapHint;
  final String managePremiumBtn;
  final String unlockPremiumBtn;
  final String storageBankDecks;
  final String decksCardTitle;
  final String Function(int) decksCardSubtitle;
  final String testSetupTitle;
  final String testSetupSubtitle;
  final String blockedAppsSubtitle;
  final String quickImportTitle;
  final String csvImportTitle;
  final String ankiImportTitle;
  final String shipatonFooter;
  final String dailyChallengeTitle;
  final String timeEarnedTitle;
  final String timeEarnedSubtitle;
  final String accuracyMasteryTitle;
  final String accuracyLabel;
  final String masteredLabel;
  final String Function(int) challengeRewardFormat;
  final String Function(int, int) goalCardsProgress;

  // --- Daily Challenges ---
  final String dcQuizzesTitle;
  final String dcQuizzesDesc;
  final String dcEarnMinTitle;
  final String dcEarnMinDesc;
  final String dcLearnCardsTitle;
  final String dcLearnCardsDesc;
  final String dcPerfectTitle;
  final String dcPerfectDesc;
  final String dcMod3OptionsTitle;
  final String dcMod3OptionsDesc;
  final String dcModSwapTitle;
  final String dcModSwapDesc;
  final String dcModSecondChanceTitle;
  final String dcModSecondChanceDesc;
  final String dcModConfusionTitle;
  final String dcModConfusionDesc;
  final String dcModBlindTitle;
  final String dcModBlindDesc;
  final String dcModDoubleTitle;
  final String dcModDoubleDesc;
  final String dcModHardcoreTitle;
  final String dcModHardcoreDesc;
  final String dcModAtLeast3Title;
  final String dcModAtLeast3Desc;
  final String dcComboConfusionBlindTitle;
  final String dcComboConfusionBlindDesc;
  final String dcComboDoubleBlindTitle;
  final String dcComboDoubleBlindDesc;
  final String dcComboSecondSwapTitle;
  final String dcComboSecondSwapDesc;

  // --- Permission Screen ---
  final String permTitle;
  final String permSubtitle;
  final String permOverlay;
  final String permAccessibility;
  final String permNotification;
  final String permBattery;
  final String permBtnContinue;
  final String permBtnOverlay;
  final String permBtnAccessibility;
  final String permBtnNotification;
  final String permBtnBattery;

  // --- Premium Screen ---
  final String premiumScreenTitle;
  final String premiumRestoreSuccess;
  final String premiumRestoreEmpty;
  final String premiumActiveTitle;
  final String premiumFreeTitle;
  final String premiumActiveDesc;
  final String premiumFreeDesc;
  final String premiumRestoreBtn;
  final String premiumManageBtn;

  // --- Settings / Language ---
  final String settingsLanguageTitle;
  final String langEnglishLabel;
  final String langSlovakLabel;

  // --- Stats Detail Screen ---
  final String statsTitle;
  final String statsFilterToday;
  final String statsFilterWeek;
  final String statsFilterAll;
  final String statsActiveStreak;
  final String Function(int) statsStreakFormat;
  final String statsStudyTime;
  final String statsEarnedTime;
  final String statsCardsReviewed;
  final String statsSavedTime;
  final String statsAvgAccuracy;
  final String statsFavoriteDeckTitle;
  final String statsNemesisTitle;
  final String statsNemesisSubtitle;
  final String statsNemesisEmpty;
  final String statsNemesisAnswerLabel;
  final String statsNemesisFlipToAnswer;
  final String statsNemesisFlipToQuestion;
  final String Function(int) statsAccuracyMessage;

  // --- Test Setup Screen ---
  final String testSetupScreenTitle;
  final String noDeckSelectedTitle;
  final String noDeckSelectedSubtitle;
  final String activeDeckLabel;
  final String btnChangeDeck;
  final String learningModeTitle;
  final String learningModeSubOn;
  final String learningModeSubOff;
  final String rewardPerQuestionLabel;
  final String totalMultiplierLabel;
  final String maxPotentialLabel;
  final String sectionBasicSettings;
  final String fieldQuestionCount;
  final String Function(int) questionCountValue;
  final String fieldTimeLimit;
  final String timeLabelNoLimit;
  final String fieldLockoutThreshold;
  final String Function(int, int, int) lockoutLabelFormat;
  final String sectionModifiers;
  final String mod3OptionsTitle;
  final String mod3OptionsSub;
  final String modSwapCardTitle;
  final String modSwapCardSub;
  final String modSecondChanceTitle;
  final String modSecondChanceSub;
  final String modConfusionTitle;
  final String modConfusionSub;
  final String modBlindTestTitle;
  final String modBlindTestSub;
  final String modDoubleTestTitle;
  final String modDoubleTestSub;
  final String modHardcoreTitle;
  final String modHardcoreSub;
  final String sectionLearnSettings;
  final String learnBatchSizeTitle;
  final String Function(int) learnBatchSizeValue;
  final String learnIntervalTitle;
  final String Function(int, int) learnIntervalValue;
  final String learnRepeatTitle;
  final String learnRepeatSub;

  const AppTexts({
    required this.goalCardsProgress,
    required this.appName,
    required this.navHome,
    required this.navDecks,
    required this.navSettings,
    required this.homeTitle,
    required this.homeSubtitle,
    required this.deckCardCount,
    
    required this.blockedAppsTitle,
    required this.tooltipUnblockAll,
    required this.appsToLockTitle,
    required this.appsToLockDescription,
    required this.searchAppHint,
    required this.noAppFound,
    required this.dialogUnblockAllTitle,
    required this.dialogUnblockAllContent,
    required this.buttonCancel,
    required this.buttonUnblock,
    required this.dialogPremiumTitle,
    required this.dialogPremiumContent,
    required this.buttonUnlockPremium,

    required this.blockChoiceTitle,
    required this.blockChoiceStartLearning,
    required this.blockChoiceStartTest,
    required this.blockChoiceTimeoutLearning,
    required this.blockChoiceTimeoutTest,
    required this.blockChoiceUnlock1Min,
    required this.blockChoiceGracePeriod,
    required this.blockChoiceGraceExhausted,

    required this.createDeckTitle,
    required this.createDeckNameHint,
    required this.createDeckNameHintCyber,
    required this.createDeckCategoryHint,
    required this.createDeckCategoryHintCyber,
    required this.createDeckBtnAddCards,
    required this.createDeckBtnSave,

    required this.deckDetailEmpty,
    required this.deckDetailNewCardTitle,
    required this.deckDetailPromptHint,
    required this.deckDetailAnswerHint,
    required this.deckDetailBtnAddCard,
    required this.deckDetailQuestionLabel,
    required this.deckDetailAnswerLabel,
    required this.deckDetailBtnAdd,

    required this.premadeDeckEnglishBasicName,
    required this.premadeDeckItTermsName,
    required this.premadeDeckGeographyName,
    required this.premadeCategoryLanguages,
    required this.premadeCategoryIt,
    required this.premadeCategoryGeography,

    required this.deckManagerTitle,
    required this.tabMyDecks,
    required this.tabPremadeDecks,
    required this.activeBadge,
    required this.btnActive,
    required this.btnSelect,
    required this.btnView,
    required this.btnTest,
    required this.btnShare,
    required this.btnEditCards,
    required this.btnRename,
    required this.btnDelete,
    required this.emptyMyDecks,
    required this.emptyPremadeDecks,
    required this.addDeckDialogTitle,
    required this.optionCustomDeck,
    required this.optionCsvImport,
    required this.optionAnkiImport,
    required this.renameDeckTitle,
    required this.fieldDeckName,
    required this.fieldCategory,
    required this.btnSave,
    required this.deleteDeckTitle,
    required this.deleteDeckContent,
    required this.btnDeleteAction,
    required this.errorMinCardsBlock,
    required this.errorMinCardsTest,
    required this.premiumLimitTitle,
    required this.premiumLimitCustomDecks,
    required this.premiumSuccessToast,

    required this.homeScreenTitle,
    required this.tooltipPremium,
    required this.tooltipSettings,
    required this.goalCardTitle,
    required this.goalCompleted,
    required this.streakDaysFormat,
    required this.carouselTapHint,
    required this.managePremiumBtn,
    required this.unlockPremiumBtn,
    required this.storageBankDecks,
    required this.decksCardTitle,
    required this.decksCardSubtitle,
    required this.testSetupTitle,
    required this.testSetupSubtitle,
    required this.blockedAppsSubtitle,
    required this.quickImportTitle,
    required this.csvImportTitle,
    required this.ankiImportTitle,
    required this.shipatonFooter,
    required this.dailyChallengeTitle,
    required this.timeEarnedTitle,
    required this.timeEarnedSubtitle,
    required this.accuracyMasteryTitle,
    required this.accuracyLabel,
    required this.masteredLabel,
    required this.challengeRewardFormat,

    required this.dcQuizzesTitle,
    required this.dcQuizzesDesc,
    required this.dcEarnMinTitle,
    required this.dcEarnMinDesc,
    required this.dcLearnCardsTitle,
    required this.dcLearnCardsDesc,
    required this.dcPerfectTitle,
    required this.dcPerfectDesc,
    required this.dcMod3OptionsTitle,
    required this.dcMod3OptionsDesc,
    required this.dcModSwapTitle,
    required this.dcModSwapDesc,
    required this.dcModSecondChanceTitle,
    required this.dcModSecondChanceDesc,
    required this.dcModConfusionTitle,
    required this.dcModConfusionDesc,
    required this.dcModBlindTitle,
    required this.dcModBlindDesc,
    required this.dcModDoubleTitle,
    required this.dcModDoubleDesc,
    required this.dcModHardcoreTitle,
    required this.dcModHardcoreDesc,
    required this.dcModAtLeast3Title,
    required this.dcModAtLeast3Desc,
    required this.dcComboConfusionBlindTitle,
    required this.dcComboConfusionBlindDesc,
    required this.dcComboDoubleBlindTitle,
    required this.dcComboDoubleBlindDesc,
    required this.dcComboSecondSwapTitle,
    required this.dcComboSecondSwapDesc,

    required this.permTitle,
    required this.permSubtitle,
    required this.permOverlay,
    required this.permAccessibility,
    required this.permNotification,
    required this.permBattery,
    required this.permBtnContinue,
    required this.permBtnOverlay,
    required this.permBtnAccessibility,
    required this.permBtnNotification,
    required this.permBtnBattery,

    required this.premiumScreenTitle,
    required this.premiumRestoreSuccess,
    required this.premiumRestoreEmpty,
    required this.premiumActiveTitle,
    required this.premiumFreeTitle,
    required this.premiumActiveDesc,
    required this.premiumFreeDesc,
    required this.premiumRestoreBtn,
    required this.premiumManageBtn,

    required this.settingsLanguageTitle,
    required this.langEnglishLabel,
    required this.langSlovakLabel,

    required this.statsTitle,
    required this.statsFilterToday,
    required this.statsFilterWeek,
    required this.statsFilterAll,
    required this.statsActiveStreak,
    required this.statsStreakFormat,
    required this.statsStudyTime,
    required this.statsEarnedTime,
    required this.statsCardsReviewed,
    required this.statsSavedTime,
    required this.statsAvgAccuracy,
    required this.statsFavoriteDeckTitle,
    required this.statsNemesisTitle,
    required this.statsNemesisSubtitle,
    required this.statsNemesisEmpty,
    required this.statsNemesisAnswerLabel,
    required this.statsNemesisFlipToAnswer,
    required this.statsNemesisFlipToQuestion,
    required this.statsAccuracyMessage,

    required this.testSetupScreenTitle,
    required this.noDeckSelectedTitle,
    required this.noDeckSelectedSubtitle,
    required this.activeDeckLabel,
    required this.btnChangeDeck,
    required this.learningModeTitle,
    required this.learningModeSubOn,
    required this.learningModeSubOff,
    required this.rewardPerQuestionLabel,
    required this.totalMultiplierLabel,
    required this.maxPotentialLabel,
    required this.sectionBasicSettings,
    required this.fieldQuestionCount,
    required this.questionCountValue,
    required this.fieldTimeLimit,
    required this.timeLabelNoLimit,
    required this.fieldLockoutThreshold,
    required this.lockoutLabelFormat,
    required this.sectionModifiers,
    required this.mod3OptionsTitle,
    required this.mod3OptionsSub,
    required this.modSwapCardTitle,
    required this.modSwapCardSub,
    required this.modSecondChanceTitle,
    required this.modSecondChanceSub,
    required this.modConfusionTitle,
    required this.modConfusionSub,
    required this.modBlindTestTitle,
    required this.modBlindTestSub,
    required this.modDoubleTestTitle,
    required this.modDoubleTestSub,
    required this.modHardcoreTitle,
    required this.modHardcoreSub,
    required this.sectionLearnSettings,
    required this.learnBatchSizeTitle,
    required this.learnBatchSizeValue,
    required this.learnIntervalTitle,
    required this.learnIntervalValue,
    required this.learnRepeatTitle,
    required this.learnRepeatSub,
  });
}

// ==========================================
// ANGLICKÁ VERZIA (Default)
// ==========================================
const textsEn = AppTexts(
  appName: 'FlashPass',
  navHome: 'Home',
  navDecks: 'Decks',
  navSettings: 'Settings',
  homeTitle: 'FlashPass',
  homeSubtitle: 'Study fast, unlock apps',
  deckCardCount: _deckCardCountEn,
  
  blockedAppsTitle: 'Blocked Apps',
  tooltipUnblockAll: 'Unblock all',
  appsToLockTitle: 'Apps to lock',
  appsToLockDescription: 'Selected apps will be accessible only after solving a knowledge test.',
  searchAppHint: 'Search app...',
  noAppFound: 'No apps found',
  dialogUnblockAllTitle: 'Unblock all?',
  dialogUnblockAllContent: 'Are you sure you want to unblock all locked apps?',
  buttonCancel: 'Cancel',
  buttonUnblock: 'Unblock',
  dialogPremiumTitle: 'Unlock FlashPass Premium!',
  dialogPremiumContent: 'You have reached the limit of 3 free blocked apps.\n\nActivate Premium for unlimited app blocking.',
  buttonUnlockPremium: 'Unlock Premium',
  goalCardsProgress: _goalCardsProgressEn,

  blockChoiceTitle: 'Blocked!',
  blockChoiceStartLearning: 'Start LEARNING',
  blockChoiceStartTest: 'Start TEST',
  blockChoiceTimeoutLearning: 'Time is up! Only learning can save you now.',
  blockChoiceTimeoutTest: 'Time is up! Only the test can save you now.',
  blockChoiceUnlock1Min: 'Unlock for 1 minute',
  blockChoiceGracePeriod: _blockChoiceGracePeriodEn,
  blockChoiceGraceExhausted: 'You have spent all your daily grace periods!',

  createDeckTitle: 'New Deck',
  createDeckNameHint: 'Deck name (e.g. German)',
  createDeckNameHintCyber: '// DECK NAME (E.G. GERMAN)',
  createDeckCategoryHint: 'Category (e.g. Languages)',
  createDeckCategoryHintCyber: '// CATEGORY (E.G. LANGUAGES)',
  createDeckBtnAddCards: 'Add Cards',
  createDeckBtnSave: 'Save Deck',

  deckDetailEmpty: 'This deck is empty.',
  deckDetailNewCardTitle: 'New Card',
  deckDetailPromptHint: 'Question / Term (Front side)',
  deckDetailAnswerHint: 'Correct answer (Back side)',
  deckDetailBtnAddCard: 'Add Card',
  deckDetailQuestionLabel: 'QUESTION',
  deckDetailAnswerLabel: 'ANSWER',
  deckDetailBtnAdd: 'Add',

  premadeDeckEnglishBasicName: 'Basic English',
  premadeDeckItTermsName: 'IT & Programming',
  premadeDeckGeographyName: 'World Capitals',
  premadeCategoryLanguages: 'Languages',
  premadeCategoryIt: 'Computer Science',
  premadeCategoryGeography: 'Geography',

  deckManagerTitle: 'FlashPass Decks',
  tabMyDecks: 'My Decks',
  tabPremadeDecks: 'Premade',
  activeBadge: 'ACTIVE',
  btnActive: 'Active',
  btnSelect: 'Select',
  btnView: 'View',
  btnTest: 'Test',
  btnShare: 'Share',
  btnEditCards: 'Edit cards',
  btnRename: 'Rename',
  btnDelete: 'Delete',
  emptyMyDecks: 'No custom decks found. Try creating one!',
  emptyPremadeDecks: 'No premade decks available.',
  addDeckDialogTitle: 'Add new deck',
  optionCustomDeck: 'Add custom deck',
  optionCsvImport: 'Import from CSV',
  optionAnkiImport: 'Import from Anki',
  renameDeckTitle: 'Edit deck',
  fieldDeckName: 'Deck name',
  fieldCategory: 'Category',
  btnSave: 'Save',
  deleteDeckTitle: 'Delete deck?',
  deleteDeckContent: _deleteDeckContentEn,
  btnDeleteAction: 'Delete',
  errorMinCardsBlock: 'You must have at least 5 cards to block apps.',
  errorMinCardsTest: 'You must have at least 5 cards to start the test.',
  premiumLimitTitle: 'Unlock FlashPass Premium!',
  premiumLimitCustomDecks: 'You have reached the limit of 3 free custom decks.\n\nActivate Premium for unlimited card creation and access to all decks.',
  premiumSuccessToast: 'Welcome to the Premium club! 🎉',

  homeScreenTitle: 'FlashPass Decks',
  tooltipPremium: 'Premium',
  tooltipSettings: 'Settings',
  goalCardTitle: 'DAILY GOAL',
  goalCompleted: 'Completed',
  streakDaysFormat: _streakDaysFormatEn,
  carouselTapHint: 'Tap card for detailed statistics',
  managePremiumBtn: 'MANAGE PREMIUM',
  unlockPremiumBtn: 'PREMIUM',
  storageBankDecks: '// STORAGE_BANK :: DECKS',
  decksCardTitle: 'Decks',
  decksCardSubtitle: _decksCardSubtitleEn,
  testSetupTitle: 'Test Setup',
  testSetupSubtitle: 'Customize your learning',
  blockedAppsSubtitle: 'Select blocked apps',
  quickImportTitle: 'QUICK IMPORT',
  csvImportTitle: 'CSV Import',
  ankiImportTitle: 'Anki',
  shipatonFooter: 'Created for Shipaton 2026 by RevenueCat',
  dailyChallengeTitle: 'DAILY CHALLENGE',
  timeEarnedTitle: 'TIME EARNED TODAY',
  timeEarnedSubtitle: 'Earned time to unlock apps',
  accuracyMasteryTitle: 'ACCURACY & MASTERY',
  accuracyLabel: 'Accuracy',
  masteredLabel: 'Mastered cards',
  challengeRewardFormat: _challengeRewardFormatEn,

  dcQuizzesTitle: 'Quiz Marathon',
  dcQuizzesDesc: 'Successfully complete 2 quizzes',
  dcEarnMinTitle: 'Time Hunter',
  dcEarnMinDesc: 'Earn a total of 10 minutes of unlocked time',
  dcLearnCardsTitle: 'Study Mode',
  dcLearnCardsDesc: 'Go through 15 cards in Learning Mode',
  dcPerfectTitle: 'Perfect Hit',
  dcPerfectDesc: 'Complete 1 quiz with 100% accuracy',
  dcMod3OptionsTitle: 'Easier Choice',
  dcMod3OptionsDesc: 'Pass a quiz with the "3 Options" modifier',
  dcModSwapTitle: 'Tactical Swap',
  dcModSwapDesc: 'Pass a quiz with the "Swap Card" modifier',
  dcModSecondChanceTitle: 'Safe Return',
  dcModSecondChanceDesc: 'Pass a quiz with the "Second Chance" modifier',
  dcModConfusionTitle: 'Stay Focused',
  dcModConfusionDesc: 'Pass a quiz with the "Confusion" modifier',
  dcModBlindTitle: 'Faith in Knowledge',
  dcModBlindDesc: 'Pass a quiz with the "Blind Test" modifier',
  dcModDoubleTitle: 'Double Challenge',
  dcModDoubleDesc: 'Pass a quiz with the "Double Test" modifier',
  dcModHardcoreTitle: 'Hardcore Master',
  dcModHardcoreDesc: 'Pass a quiz in "Hardcore (Write-in)" mode',
  dcModAtLeast3Title: 'Combo Specialist',
  dcModAtLeast3Desc: 'Complete a quiz with AT LEAST 3 active modifiers at once',
  dcComboConfusionBlindTitle: 'Blind Chaotic',
  dcComboConfusionBlindDesc: 'Pass a quiz with "Confusion" + "Blind Test" modifiers',
  dcComboDoubleBlindTitle: 'Double Darkness',
  dcComboDoubleBlindDesc: 'Pass a quiz with "Double Test" + "Blind Test" modifiers',
  dcComboSecondSwapTitle: 'Maximum Safety',
  dcComboSecondSwapDesc: 'Pass a quiz with "Second Chance" + "Swap Card" modifiers',

  permTitle: 'Activation required',
  permSubtitle: 'For correct and uninterrupted blocking, you need to enable the following four functions.',
  permOverlay: 'Display over other apps (Overlay)',
  permAccessibility: 'Accessibility Service',
  permNotification: 'Notifications & time countdown',
  permBattery: 'Disable battery optimization (Unrestricted)',
  permBtnContinue: 'Continue',
  permBtnOverlay: 'Enable Overlay',
  permBtnAccessibility: 'Enable Accessibility',
  permBtnNotification: 'Enable Notifications',
  permBtnBattery: 'Disable Battery Optimization',

  premiumScreenTitle: 'FlashPass Premium',
  premiumRestoreSuccess: 'Purchases successfully restored!',
  premiumRestoreEmpty: 'No previous subscription found.',
  premiumActiveTitle: 'You have active Premium! 👑',
  premiumFreeTitle: 'You are using the Free version',
  premiumActiveDesc: 'Enjoy unlimited decks, additional styles, and all features to the fullest.',
  premiumFreeDesc: 'Unlock unlimited custom decks, premium styles, and other advanced features.',
  premiumRestoreBtn: 'Restore Purchases',
  premiumManageBtn: 'Manage Subscription',

  settingsLanguageTitle: 'Language / Jazyk',
  langEnglishLabel: 'English',
  langSlovakLabel: 'Slovak',

  statsTitle: 'Learning Statistics',
  statsFilterToday: 'Today',
  statsFilterWeek: 'Week',
  statsFilterAll: 'All time',
  statsActiveStreak: 'ACTIVE STREAK',
  statsStreakFormat: _statsStreakFormatEn,
  statsStudyTime: 'Study time',
  statsEarnedTime: 'Time earned',
  statsCardsReviewed: 'Cards reviewed',
  statsSavedTime: 'Saved time',
  statsAvgAccuracy: 'Average accuracy',
  statsFavoriteDeckTitle: 'Favorite deck',
  statsNemesisTitle: 'Nemesis card',
  statsNemesisSubtitle: 'NEMESIS CARD (MOST ERRORS)',
  statsNemesisEmpty: 'No nemesis card yet 🎉',
  statsNemesisAnswerLabel: 'ANSWER',
  statsNemesisFlipToAnswer: 'Tap to reveal answer',
  statsNemesisFlipToQuestion: 'Tap to return to question',
  statsAccuracyMessage: _statsAccuracyMessageEn,

  testSetupScreenTitle: 'Test Setup',
  noDeckSelectedTitle: 'NO DECK SELECTED!',
  noDeckSelectedSubtitle: 'Tap here to select (min. 5 cards)',
  activeDeckLabel: 'ACTIVE DECK',
  btnChangeDeck: 'Change',
  learningModeTitle: 'Learning Mode',
  learningModeSubOn: 'Focused on repetition and practice.',
  learningModeSubOff: 'Focused on performance and earning time.',
  rewardPerQuestionLabel: 'REWARD PER 1 CORRECT ANSWER',
  totalMultiplierLabel: 'Total multiplier',
  maxPotentialLabel: 'Max test potential',
  sectionBasicSettings: 'BASIC QUIZ SETTINGS',
  fieldQuestionCount: 'Number of questions',
  questionCountValue: _questionCountValueEn,
  fieldTimeLimit: 'Time limit per question',
  timeLabelNoLimit: 'No limit',
  fieldLockoutThreshold: 'Lockout Threshold (Min. accuracy)',
  lockoutLabelFormat: _lockoutLabelFormatEn,
  sectionModifiers: 'MODIFIERS',
  mod3OptionsTitle: '3 Options',
  mod3OptionsSub: 'One less incorrect answer option.',
  modSwapCardTitle: 'Swap Card',
  modSwapCardSub: 'Swap a hard question for a new one once per test.',
  modSecondChanceTitle: 'Second Chance',
  modSecondChanceSub: 'One incorrect answer is forgiven per test.',
  modConfusionTitle: 'Confusion',
  modConfusionSub: 'Added "None of the above" option.',
  modBlindTestTitle: 'Blind Test',
  modBlindTestSub: 'Answer correctness is revealed at the end of the test.',
  modDoubleTestTitle: 'Double Test',
  modDoubleTestSub: 'Pass 2 tests in a row to earn the reward.',
  modHardcoreTitle: 'Hardcore (Write-in)',
  modHardcoreSub: 'No options. You must type the answer manually.',
  sectionLearnSettings: 'LEARNING SETTINGS',
  learnBatchSizeTitle: 'Cards per batch',
  learnBatchSizeValue: _learnBatchSizeValueEn,
  learnIntervalTitle: 'Lockout frequency (Pop-up)',
  learnIntervalValue: _learnIntervalValueEn,
  learnRepeatTitle: 'Repeat missed cards',
  learnRepeatSub: 'Cards you missed will be shown again at the end.',
);

String _deckCardCountEn(int count) {
  if (count == 1) return '1 card';
  return '$count cards';
}

String _blockChoiceGracePeriodEn(int count) {
  return 'Grace period for 1 min. ($count/3 today)';
}

String _deleteDeckContentEn(String name) {
  return 'Are you sure you want to delete "$name"? This action is irreversible and will delete all cards inside it.';
}

String _streakDaysFormatEn(int days) {
  return '$days Day${days == 1 ? '' : 's'} Streak';
}

String _decksCardSubtitleEn(int count) {
  return '$count decks · Manage & create';
}

String _challengeRewardFormatEn(int min) {
  return 'Reward: +$min min';
}

String _statsStreakFormatEn(int streak) {
  return '$streak Day${streak == 1 ? '' : 's'}';
}

String _statsAccuracyMessageEn(int accuracy) {
  if (accuracy <= 20) return 'Needs more practice 😅';
  if (accuracy <= 40) return 'Getting somewhere... 📈';
  if (accuracy <= 60) return 'Good job, keep going ⚡';
  if (accuracy <= 80) return 'Doing great! 🧠';
  if (accuracy < 100) return 'Great memory, like a machine! 🔥';
  return 'Perfect score! Absolute master 👑';
}

String _questionCountValueEn(int count) {
  return '$count questions';
}

String _lockoutLabelFormatEn(int pct, int min, int total) {
  return '$pct% (min. $min / $total)';
}

String _learnBatchSizeValueEn(int count) {
  if (count == 1) return '1 card';
  return '$count cards';
}

String _learnIntervalValueEn(int minutes, int seconds) {
  if (seconds == 0) {
    return 'Every $minutes min.';
  } else {
    return 'Every $minutes min. $seconds s.';
  }
}

// ==========================================
// SLOVENSKÁ VERZIA
// ==========================================
const textsSk = AppTexts(
  appName: 'FlashPass',
  navHome: 'Domov',
  navDecks: 'Decks',
  navSettings: 'Nastavenia',
  homeTitle: 'FlashPass',
  homeSubtitle: 'Uč sa rýchlo, odomkni aplikácie',
  deckCardCount: _deckCardCountSk,
  
  blockedAppsTitle: 'Blokované aplikácie',
  tooltipUnblockAll: 'Odblokovať všetko',
  appsToLockTitle: 'Aplikácie na uzamknutie',
  appsToLockDescription: 'Zvolené aplikácie sa sprístupnia až po vyriešení vedomostného testu.',
  searchAppHint: 'Hľadať aplikáciu...',
  noAppFound: 'Žiadna aplikácia sa nenašla',
  dialogUnblockAllTitle: 'Odblokovať všetko?',
  dialogUnblockAllContent: 'Naozaj chceš odblokovať všetky zablokované aplikácie?',
  buttonCancel: 'Zrušiť',
  buttonUnblock: 'Odblokovať',
  dialogPremiumTitle: 'Odomkni FlashPass Premium!',
  dialogPremiumContent: 'Dosiahol si limit 3 zablokovaných aplikácií zadarmo.\n\nPre neobmedzené blokovanie aplikácií si aktivuj Premium.',
  buttonUnlockPremium: 'Odomknúť Premium',
  goalCardsProgress: _goalCardsProgressSk,

  blockChoiceTitle: 'Zablokované!',
  blockChoiceStartLearning: 'Spustiť UČENIE',
  blockChoiceStartTest: 'Spustiť TEST',
  blockChoiceTimeoutLearning: 'Čas vypršal! Teraz ťa zachráni už len učenie.',
  blockChoiceTimeoutTest: 'Čas vypršal! Teraz ťa zachráni už len test.',
  blockChoiceUnlock1Min: 'Odomknúť na 1 minútu',
  blockChoiceGracePeriod: _blockChoiceGracePeriodSk,
  blockChoiceGraceExhausted: 'Dnešné odpustky si už vyčerpal!',

  createDeckTitle: 'Nový balíček',
  createDeckNameHint: 'Názov balíčka (napr. Nemčina)',
  createDeckNameHintCyber: '// NÁZOV BALÍČKA (NAPR. NEMČINA)',
  createDeckCategoryHint: 'Kategória (napr. Jazyky)',
  createDeckCategoryHintCyber: '// KATEGÓRIA (NAPR. JAZYKY)',
  createDeckBtnAddCards: 'Pridať kartičky',
  createDeckBtnSave: 'Uložiť balíček',

  deckDetailEmpty: 'Tento balíček je zatiaľ prázdny.',
  deckDetailNewCardTitle: 'Nová kartička',
  deckDetailPromptHint: 'Otázka / Pojem (Predná strana)',
  deckDetailAnswerHint: 'Správna odpoveď (Zadná strana)',
  deckDetailBtnAddCard: 'Pridať kartičku',
  deckDetailQuestionLabel: 'OTÁZKA',
  deckDetailAnswerLabel: 'ODPOVEĎ',
  deckDetailBtnAdd: 'Pridať',

  premadeDeckEnglishBasicName: 'Základná Angličtina',
  premadeDeckItTermsName: 'IT a Programovanie',
  premadeDeckGeographyName: 'Hlavné mestá sveta',
  premadeCategoryLanguages: 'Cudzie jazyky',
  premadeCategoryIt: 'Informatika',
  premadeCategoryGeography: 'Geografia',

  deckManagerTitle: 'FlashPass Balíčky',
  tabMyDecks: 'Moje balíčky',
  tabPremadeDecks: 'Pripravené',
  activeBadge: 'AKTÍVNY',
  btnActive: 'Aktívny',
  btnSelect: 'Zvoliť',
  btnView: 'Zobraziť',
  btnTest: 'Test',
  btnShare: 'Zdieľať',
  btnEditCards: 'Upraviť karty',
  btnRename: 'Pomenovať',
  btnDelete: 'Vymazať',
  emptyMyDecks: 'Nenašli sa žiadne vlastné balíčky. Skús nejaký vytvoriť!',
  emptyPremadeDecks: 'Žiadne predpripravené balíčky.',
  addDeckDialogTitle: 'Pridať nový balíček',
  optionCustomDeck: 'Pridať vlastný balíček',
  optionCsvImport: 'Import z CSV',
  optionAnkiImport: 'Import z Anki',
  renameDeckTitle: 'Upraviť balíček',
  fieldDeckName: 'Názov balíčka',
  fieldCategory: 'Kategória',
  btnSave: 'Uložiť',
  deleteDeckTitle: 'Vymazať balíček?',
  deleteDeckContent: _deleteDeckContentSk,
  btnDeleteAction: 'Vymazať',
  errorMinCardsBlock: 'Na blokovanie musíte mať aspoň 5 kariet.',
  errorMinCardsTest: 'Na spustenie testu musíte mať aspoň 5 kariet.',
  premiumLimitTitle: 'Odomkni FlashPass Premium!',
  premiumLimitCustomDecks: 'Dosiahol si limit 3 vlastných balíčkov zadarmo.\n\nPre neobmedzené vytváranie kartičiek a prístup ku všetkým balíčkom si aktivuj Premium.',
  premiumSuccessToast: 'Vitaj v Premium klube! 🎉',

  homeScreenTitle: 'FlashPass Balíčky',
  tooltipPremium: 'Premium',
  tooltipSettings: 'Nastavenia',
  goalCardTitle: 'DAILY GOAL',
  goalCompleted: 'Splnené',
  streakDaysFormat: _streakDaysFormatSk,
  carouselTapHint: 'Ťukni na kartu pre detailné štatistiky',
  managePremiumBtn: 'SPRAVOVAŤ PREMIUM',
  unlockPremiumBtn: 'PREMIUM',
  storageBankDecks: '// STORAGE_BANK :: DECKS',
  decksCardTitle: 'Decky',
  decksCardSubtitle: _decksCardSubtitleSk,
  testSetupTitle: 'Nastavenia testu',
  testSetupSubtitle: 'Prispôsob si učenie',
  blockedAppsSubtitle: 'Výber blokovaných appiek',
  quickImportTitle: 'QUICK IMPORT',
  csvImportTitle: 'CSV Import',
  ankiImportTitle: 'Anki',
  shipatonFooter: 'Vytvorené pre Shipaton 2026 by RevenueCat',
  dailyChallengeTitle: 'DENNÁ VÝZVA',
  timeEarnedTitle: 'ZÍSKANÝ ČAS DNES',
  timeEarnedSubtitle: 'Vybojovaný čas na odomknutie aplikácií',
  accuracyMasteryTitle: 'ÚSPEŠNOSŤ & ZVLÁDNUTIE',
  accuracyLabel: 'Úspešnosť',
  masteredLabel: 'Mastered kariet',
  challengeRewardFormat: _challengeRewardFormatSk,

  dcQuizzesTitle: 'Kvízový maratón',
  dcQuizzesDesc: 'Dokonči úspešne 2 testy',
  dcEarnMinTitle: 'Lovec času',
  dcEarnMinDesc: 'Získaj celkovo 10 minút odomknutého času',
  dcLearnCardsTitle: 'Študijný režim',
  dcLearnCardsDesc: 'Prejdi 15 kartičiek v režime učenia (Learning Mode)',
  dcPerfectTitle: 'Perfektný zásah',
  dcPerfectDesc: 'Dokonči 1 test s 100% úspešnosťou',
  dcMod3OptionsTitle: 'Ľahšia voľba',
  dcMod3OptionsDesc: 'Zvládni test s modifikátorom "3 Možnosti"',
  dcModSwapTitle: 'Taktická výmena',
  dcModSwapDesc: 'Zvládni test s modifikátorom "Vymeň kartu"',
  dcModSecondChanceTitle: 'Bezpečný návrat',
  dcModSecondChanceDesc: 'Zvládni test s modifikátorom "Druhá šanca"',
  dcModConfusionTitle: 'Nenechaj sa zmýliť',
  dcModConfusionDesc: 'Zvládni test s modifikátorom "Confusion"',
  dcModBlindTitle: 'Viera vo vedomosti',
  dcModBlindDesc: 'Zvládni test s modifikátorom "Slepý test"',
  dcModDoubleTitle: 'Dvojitá výzva',
  dcModDoubleDesc: 'Zvládni test s modifikátorom "Double Test"',
  dcModHardcoreTitle: 'Hardcore majster',
  dcModHardcoreDesc: 'Zvládni test v "Hardcore (Write-in)" režime',
  dcModAtLeast3Title: 'Kombinačný špecialista',
  dcModAtLeast3Desc: 'Dokonči test so zapnutými MINIMÁLNE 3 modifikátormi naraz',
  dcComboConfusionBlindTitle: 'Slepý chaotik',
  dcComboConfusionBlindDesc: 'Zvládni test s modifikátormi "Confusion" + "Slepý test"',
  dcComboDoubleBlindTitle: 'Dvojitá tma',
  dcComboDoubleBlindDesc: 'Zvládni test s modifikátormi "Double Test" + "Slepý test"',
  dcComboSecondSwapTitle: 'Maximálna poistka',
  dcComboSecondSwapDesc: 'Zvládni test s modifikátormi "Druhá šanca" + "Vymeň kartu"',

  permTitle: 'Vyžaduje sa aktivácia',
  permSubtitle: 'Pre správne a neprerušované fungovanie blokovania je potrebné povoliť nasledujúce štyri funkcie.',
  permOverlay: 'Prekrytie aplikácií (Overlay)',
  permAccessibility: 'Zjednodušenie prístupu (Accessibility)',
  permNotification: 'Upozornenia a odpočet času (Notifications)',
  permBattery: 'Vypnutie šetrenia batérie (Unrestricted)',
  permBtnContinue: 'Pokračovať',
  permBtnOverlay: 'Povoliť prekrytie',
  permBtnAccessibility: 'Povoliť Zjednodušenie',
  permBtnNotification: 'Povoliť Upozornenia',
  permBtnBattery: 'Vypnúť šetrenie',

  premiumScreenTitle: 'FlashPass Premium',
  premiumRestoreSuccess: 'Nákupy boli úspešne obnovené!',
  premiumRestoreEmpty: 'Nenašlo sa žiadne predchádzajúce predplatné.',
  premiumActiveTitle: 'Máš aktívne Premium! 👑',
  premiumFreeTitle: 'Používaš Free verziu',
  premiumActiveDesc: 'Užívaj si neobmedzené balíčky, ďalšie štýly a všetky funkcie naplno.',
  premiumFreeDesc: 'Odomkni si neobmedzené vlastné balíčky, premium štýly a iné pokročilé funkcie.',
  premiumRestoreBtn: 'Obnoviť nákupy (Restore Purchases)',
  premiumManageBtn: 'Spravovať predplatné',

  settingsLanguageTitle: 'Jazyk aplikácie',
  langEnglishLabel: 'Angličtina',
  langSlovakLabel: 'Slovenčina',

  statsTitle: 'Štatistiky učenia',
  statsFilterToday: 'Dnes',
  statsFilterWeek: 'Týždeň',
  statsFilterAll: 'Všetko',
  statsActiveStreak: 'AKTÍVNY STREAK',
  statsStreakFormat: _statsStreakFormatSk,
  statsStudyTime: 'Čas učenia',
  statsEarnedTime: 'Zarobený čas',
  statsCardsReviewed: 'Prebratých kartičiek',
  statsSavedTime: 'Ušetrený čas',
  statsAvgAccuracy: 'Priemerná úspešnosť',
  statsFavoriteDeckTitle: 'Najobľúbenejší balíček',
  statsNemesisTitle: 'Nemesis karta',
  statsNemesisSubtitle: 'NEMESIS KARTA (NAJVIAC CHÝB)',
  statsNemesisEmpty: 'Zatiaľ nemáš žiadnu úhlavnú nepriateľskú kartu 🎉',
  statsNemesisAnswerLabel: 'ODPOVEĎ',
  statsNemesisFlipToAnswer: 'Ťukni pre otočenie a zobrazenie odpovede',
  statsNemesisFlipToQuestion: 'Ťukni pre návrat na otázku',
  statsAccuracyMessage: _statsAccuracyMessageSk,

  testSetupScreenTitle: 'Nastavenie Testu',
  noDeckSelectedTitle: 'NEMÁŠ VYBRANÝ ŽIADEN BALÍČEK!',
  noDeckSelectedSubtitle: 'Klikni sem pre výber (min. 5 kariet)',
  activeDeckLabel: 'AKTÍVNY BALÍČEK',
  btnChangeDeck: 'Zmeniť',
  learningModeTitle: 'Learning Mode',
  learningModeSubOn: 'Zamerané na opakovanie a učenie sa.',
  learningModeSubOff: 'Zamerané na výkon a získavanie času.',
  rewardPerQuestionLabel: 'ODMENA ZA 1 SPRÁVNU ODPOVEĎ',
  totalMultiplierLabel: 'Celkový násobič',
  maxPotentialLabel: 'Max potenciál testu',
  sectionBasicSettings: 'ZÁKLADNÉ NASTAVENIA KVÍZU',
  fieldQuestionCount: 'Počet otázok',
  questionCountValue: _questionCountValueSk,
  fieldTimeLimit: 'Časový limit na otázku',
  timeLabelNoLimit: 'Bez limitu',
  fieldLockoutThreshold: 'Lockout Prah (Min. úspešnosť)',
  lockoutLabelFormat: _lockoutLabelFormatSk,
  sectionModifiers: 'MODIFIKÁTORY',
  mod3OptionsTitle: '3 Možnosti',
  mod3OptionsSub: 'O jednu nesprávnu odpoveď menej.',
  modSwapCardTitle: 'Vymeň kartu',
  modSwapCardSub: '1-krát za test môžeš vymeniť ťažkú otázku za novú.',
  modSecondChanceTitle: 'Druhá šanca',
  modSecondChanceSub: 'Jedna nesprávna odpoveď za celý test sa ti odpustí.',
  modConfusionTitle: 'Confusion',
  modConfusionSub: 'Pridaná možnosť "Žiadna z odpovedí".',
  modBlindTestTitle: 'Slepý test',
  modBlindTestSub: 'Správnosť odpovedí sa dozvieš až na záver testu.',
  modDoubleTestTitle: 'Double Test',
  modDoubleTestSub: 'Musíš zvládnuť 2 testy po sebe. Odmenu dostaneš až po druhom.',
  modHardcoreTitle: 'Hardcore (Write-in)',
  modHardcoreSub: 'Bez možností. Odpoveď musíš ručne napísať.',
  sectionLearnSettings: 'NASTAVENIA UČENIA',
  learnBatchSizeTitle: 'Počet kartičiek v dávke',
  learnBatchSizeValue: _learnBatchSizeValueSk,
  learnIntervalTitle: 'Frekvencia uzamknutia (Pop-up)',
  learnIntervalValue: _learnIntervalValueSk,
  learnRepeatTitle: 'Opakovanie nevedomostí',
  learnRepeatSub: 'Karty, ktoré si nevedel, sa ukážu znovu na konci.',
);

String _deckCardCountSk(int count) {
  if (count == 1) return '1 kartička';
  if (count >= 2 && count <= 4) return '$count kartičky';
  return '$count kartičiek';
}

String _blockChoiceGracePeriodSk(int count) {
  return 'Odpustok na 1 min. ($count/3 dnes)';
}

String _deleteDeckContentSk(String name) {
  return 'Naozaj chceš vymazať balíček "$name"? Táto akcia je nenávratná a vymaže aj všetky kartičky v ňom.';
}

String _streakDaysFormatSk(int days) {
  String dayWord = days == 1 ? 'Deň' : (days >= 2 && days <= 4 ? 'Dni' : 'Dní');
  return '$days $dayWord Streak';
}

String _decksCardSubtitleSk(int count) {
  return '$count balíčkov · Správa & tvorba';
}

String _challengeRewardFormatSk(int min) {
  return 'Odmena: +$min min';
}

String _statsStreakFormatSk(int streak) {
  if (streak == 1) return '1 deň';
  if (streak >= 2 && streak <= 4) return '$streak dni';
  return '$streak dní';
}

String _statsAccuracyMessageSk(int accuracy) {
  if (accuracy <= 20) return 'Treba viac trénovať 😅';
  if (accuracy <= 40) return 'Niekam sa už dostávame... 📈';
  if (accuracy <= 60) return 'Dobrá práca, len tak ďalej ⚡';
  if (accuracy <= 80) return 'Už ti to ide super! 🧠';
  if (accuracy < 100) return 'Skvelá pamäť, ideš ako stroj! 🔥';
  return 'Perfektný výkon! Absolútny master 👑';
}

String _questionCountValueSk(int count) {
  if (count == 1) return '1 otázka';
  if (count >= 2 && count <= 4) return '$count otázky';
  return '$count otázok';
}

String _lockoutLabelFormatSk(int pct, int min, int total) {
  return '$pct% (min. $min / $total)';
}

String _learnBatchSizeValueSk(int count) {
  if (count == 1) return '1 kartička';
  if (count >= 2 && count <= 4) return '$count kartičky';
  return '$count kartičiek';
}

String _learnIntervalValueSk(int minutes, int seconds) {
  if (seconds == 0) {
    return 'Každé $minutes min.';
  } else {
    return 'Každé $minutes min. $seconds s.';
  }
}

String _goalCardsProgressEn(int done, int target) {
  return '$done / $target Cards';
}

String _goalCardsProgressSk(int done, int target) {
  return '$done / $target Kariet';
}