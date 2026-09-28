// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get adminCommitteeEyebrow => 'കമ്മിറ്റി';

  @override
  String get adminMenu => 'മെനു';

  @override
  String get adminTryAgain => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get adminViewAll => 'എല്ലാം കാണുക';

  @override
  String get adminAddMember => 'അംഗത്തെ ചേർക്കുക';

  @override
  String get adminRecordPayment => 'പേയ്മെന്റ് രേഖപ്പെടുത്തുക';

  @override
  String get adminPendingApprovals => 'അംഗീകാരം കാത്തിരിക്കുന്നവർ';

  @override
  String get adminBroadcastNotice => 'അറിയിപ്പ് അയയ്ക്കുക';

  @override
  String get adminBulkImport => 'ഒന്നിച്ച് ഇംപോർട്ട് ചെയ്യുക';

  @override
  String get adminReceiptAction => 'രസീത്';

  @override
  String adminMemberRegistered(String name) {
    return '$name രജിസ്റ്റർ ചെയ്തു.';
  }

  @override
  String get adminFullName => 'മുഴുവൻ പേര്';

  @override
  String get adminMobileNumber => 'മൊബൈൽ നമ്പർ';

  @override
  String get adminMonthlyDuesRupees => 'മാസവരി (₹)';

  @override
  String get adminPhoneInvalid => '10 അക്ക മൊബൈൽ നമ്പർ നൽകുക';

  @override
  String get adminEditMember => 'അംഗത്തെ തിരുത്തുക';

  @override
  String get adminNavDashboard => 'ഡാഷ്ബോർഡ്';

  @override
  String get adminNavMembers => 'അംഗങ്ങൾ';

  @override
  String get adminNavReports => 'റിപ്പോർട്ടുകൾ';

  @override
  String get adminNavLogs => 'ലോഗുകൾ';

  @override
  String get adminFormatStatusActive => 'സജീവം';

  @override
  String get adminFormatStatusGrace => 'ഇളവ് കാലാവധി';

  @override
  String get adminFormatStatusAwaiting => 'അംഗീകാരം കാത്തിരിക്കുന്നു';

  @override
  String get adminFormatStatusSuspended => 'താൽക്കാലികമായി നിർത്തി';

  @override
  String get adminFormatStatusInactive => 'നിഷ്ക്രിയം';

  @override
  String get adminFormatStatusRejected => 'നിരസിച്ചു';

  @override
  String adminFormatMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മാസം',
      one: '1 മാസം',
    );
    return '$_temp0';
  }

  @override
  String get adminFormatMonthlyDues => 'മാസവരി';

  @override
  String get adminFormatContribution => 'സംഭാവന';

  @override
  String get adminFormatPayment => 'പേയ്മെന്റ്';

  @override
  String get adminDashSubscriptionActive => 'സബ്സ്ക്രിപ്ഷൻ സജീവം';

  @override
  String get adminDashSubscriptionUnknown => 'സബ്സ്ക്രിപ്ഷൻ —';

  @override
  String adminDashSubscriptionStatus(String status) {
    return 'സബ്സ്ക്രിപ്ഷൻ: $status';
  }

  @override
  String get adminDashLoadingCollection => 'പിരിവ് വിവരങ്ങൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get adminDashTotalCollectedCaps => 'ആകെ പിരിച്ചെടുത്തത്';

  @override
  String get adminDashTotalCollected => 'ആകെ പിരിച്ചെടുത്തത്';

  @override
  String adminDashTotalCollectedSpoken(String amount) {
    return 'ആകെ പിരിച്ചെടുത്തത് $amount';
  }

  @override
  String adminDashOutstandingAcrossMahal(String amount) {
    return 'മഹലിൽ ഇനിയും $amount അടയ്ക്കാനുണ്ട്.';
  }

  @override
  String get adminDashCollectionRate => 'പിരിവ് നിരക്ക്';

  @override
  String adminDashPaidOfTotal(int paid, int total, int pct) {
    return '$total ൽ $paid അംഗങ്ങൾ · $pct%';
  }

  @override
  String adminDashPercentValue(int pct) {
    return '$pct ശതമാനം';
  }

  @override
  String get adminDashPendingDues => 'ബാക്കി വരി';

  @override
  String get adminDashMembersPaid => 'അടച്ച അംഗങ്ങൾ';

  @override
  String adminDashOfHouseholds(int total) {
    return '$total വീടുകളിൽ';
  }

  @override
  String get adminDashMembersPending => 'അടയ്ക്കാത്ത അംഗങ്ങൾ';

  @override
  String get adminDashNeedReminder => 'ഓർമ്മപ്പെടുത്തൽ വേണം';

  @override
  String get adminDashOverview => 'ചുരുക്കത്തിൽ';

  @override
  String get adminDashLoadingOverview => 'വിവരങ്ങൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get adminDashTransactionsError => 'ഇടപാടുകൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get adminDashLoadingTransactions => 'ഇടപാടുകൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get adminDashNoTransactions => 'ഇതുവരെ ഇടപാടുകളൊന്നുമില്ല';

  @override
  String get adminDashNoTransactionsBody =>
      'അംഗങ്ങൾ അടയ്ക്കുമ്പോഴോ നിങ്ങൾ പണം രേഖപ്പെടുത്തുമ്പോഴോ പേയ്മെന്റുകൾ ഇവിടെ കാണാം.';

  @override
  String get adminDashBroadcastBody =>
      'എല്ലാ അംഗങ്ങൾക്കും, വരി ബാക്കിയുള്ളവർക്ക് മാത്രം, അല്ലെങ്കിൽ കുടുംബനാഥന്മാർക്ക് അറിയിപ്പോ വരി ഓർമ്മപ്പെടുത്തലോ അയയ്ക്കുക.';

  @override
  String get adminDashComposeNotice => 'അറിയിപ്പ് എഴുതുക';

  @override
  String get adminDashTitle => 'ഡാഷ്ബോർഡ്';

  @override
  String get adminDashLiveLedger => 'തത്സമയ കണക്ക്';

  @override
  String adminDashMahalLiveLedger(String mahal) {
    return '$mahal · തത്സമയ കണക്ക്';
  }

  @override
  String get adminDashLoadError => 'ഡാഷ്ബോർഡ് ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get adminDashRecentTransactions => 'സമീപകാല ഇടപാടുകൾ';

  @override
  String adminDashPendingApprovalsWaiting(int count) {
    return 'അംഗീകാരം കാത്തിരിക്കുന്നവർ · $count';
  }

  @override
  String adminDashRecordedFor(String amount, String name) {
    return '$name ന് $amount രേഖപ്പെടുത്തി';
  }

  @override
  String get adminDashTheMember => 'അംഗം';

  @override
  String get adminDashNoticeSent => 'അംഗങ്ങൾക്ക് അറിയിപ്പ് അയച്ചു.';

  @override
  String get drawerFinancialReports => 'സാമ്പത്തിക റിപ്പോർട്ടുകൾ';

  @override
  String get drawerPaymentGateways => 'പേയ്മെന്റ് ഗേറ്റ്‌വേകൾ';

  @override
  String get drawerAuditLog => 'പ്രവർത്തന ലോഗ്';

  @override
  String get drawerSwitchToMember => 'അംഗത്തിന്റെ കാഴ്ചയിലേക്ക് മാറുക';

  @override
  String get drawerSignOut => 'സൈൻ ഔട്ട് ചെയ്യുക';

  @override
  String get drawerSignOutTitle => 'സൈൻ ഔട്ട് ചെയ്യണോ?';

  @override
  String get drawerSignOutMessage =>
      'കമ്മിറ്റി പോർട്ടൽ തുറക്കാൻ ഫോൺ നമ്പർ വീണ്ടും സ്ഥിരീകരിക്കേണ്ടി വരും.';

  @override
  String get drawerCommitteePortal => 'കമ്മിറ്റി പോർട്ടൽ';

  @override
  String drawerCommitteePortalReg(String reg) {
    return 'കമ്മിറ്റി പോർട്ടൽ · $reg';
  }

  @override
  String drawerBadgeWaiting(int count) {
    return '$count പേർ കാത്തിരിക്കുന്നു';
  }

  @override
  String get membersTitle => 'അംഗങ്ങൾ';

  @override
  String get membersEyebrow => 'അംഗ പട്ടിക';

  @override
  String get membersFilterAll => 'എല്ലാം';

  @override
  String get membersFilterActive => 'സജീവം';

  @override
  String get membersFilterGrace => 'ഇളവ് കാലാവധി';

  @override
  String get membersFilterSuspended => 'നിർത്തിവച്ചവർ';

  @override
  String get membersFilterPending => 'കാത്തിരിക്കുന്നു';

  @override
  String get membersLoadingDirectory => 'അംഗ പട്ടിക ലോഡ് ചെയ്യുന്നു…';

  @override
  String get membersDirectoryUnavailable => 'അംഗ പട്ടിക ലഭ്യമല്ല';

  @override
  String membersShowingOf(int shown, int total) {
    return '$total വീടുകളിൽ $shown എണ്ണം കാണിക്കുന്നു';
  }

  @override
  String membersMatchesLoaded(int shown, int loaded, int total) {
    return 'ലോഡ് ചെയ്ത $loaded/$total ൽ $shown പൊരുത്തങ്ങൾ';
  }

  @override
  String membersMatchCount(int shown, int total) {
    return '$total വീടുകളിൽ $shown എണ്ണം പൊരുത്തപ്പെടുന്നു';
  }

  @override
  String get membersSearchHint => 'പേര്, ഫോൺ, വീട് അല്ലെങ്കിൽ കോഡ് തിരയുക…';

  @override
  String get membersLoadError => 'അംഗങ്ങളെ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get membersLoadMoreError => 'കൂടുതൽ അംഗങ്ങളെ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String membersNoMatchesYet(int loaded) {
    return 'ഇതുവരെ ലോഡ് ചെയ്ത $loaded ൽ പൊരുത്തമില്ല — ബാക്കി തിരയുന്നു…';
  }

  @override
  String membersAllLoaded(int total) {
    return 'എല്ലാ $total വീടുകളും ലോഡ് ചെയ്തു';
  }

  @override
  String membersDuesPerMonth(String amount) {
    return '$amount/മാസം';
  }

  @override
  String get membersEmptyTitle => 'ഇതുവരെ അംഗങ്ങളില്ല';

  @override
  String get membersEmptyBody =>
      'വീടുകൾ ഓരോന്നായി രജിസ്റ്റർ ചെയ്യുക, അല്ലെങ്കിൽ ഒരു സ്പ്രെഡ്ഷീറ്റ് ഇംപോർട്ട് ചെയ്യുക.';

  @override
  String get membersNotFound => 'അംഗങ്ങളെ കണ്ടെത്തിയില്ല';

  @override
  String membersNothingMatches(String query) {
    return '\'$query\' ന് പൊരുത്തമൊന്നുമില്ല.';
  }

  @override
  String membersNoneInStatus(String status) {
    return '\'$status\' നിലയിൽ വീടുകളൊന്നുമില്ല.';
  }

  @override
  String get membersShowAll => 'എല്ലാം കാണിക്കുക';

  @override
  String get membersLoading => 'അംഗങ്ങളെ ലോഡ് ചെയ്യുന്നു';

  @override
  String get addMemberTitle => 'അംഗത്തെ രജിസ്റ്റർ ചെയ്യുക';

  @override
  String get addMemberSubtitle => 'മഹൽ അംഗ പട്ടികയിൽ ഒരു വീട് ചേർക്കുന്നു';

  @override
  String get addMemberNameRequired => 'അംഗത്തിന്റെ മുഴുവൻ പേര് നൽകുക';

  @override
  String get addMemberPhoneRequired => 'ഫോൺ നമ്പർ നൽകുക';

  @override
  String get addMemberDuesInvalid => 'മാസവരി മുഴുവൻ രൂപയിൽ നൽകുക (കുറഞ്ഞത് ₹1)';

  @override
  String get addMemberNameHint => 'ഉദാ: അബ്ദുൽ കരീം';

  @override
  String get addMemberHouseLabel => 'വീട്ടുപേര് (നിർബന്ധമില്ല)';

  @override
  String get addMemberHouseHint => 'ഉദാ: ദാറുസ്സലാം';

  @override
  String get addMemberDuesHint => 'കമ്മിറ്റി തീരുമാനിച്ച പ്രകാരം';

  @override
  String get addMemberError => 'ഈ അംഗത്തെ രജിസ്റ്റർ ചെയ്യാനായില്ല';

  @override
  String get addMemberSubmit => 'അംഗത്തെ രജിസ്റ്റർ ചെയ്യുക';

  @override
  String get memberDetailsPaid => 'അടച്ചു';

  @override
  String get memberDetailsDue => 'അടയ്ക്കാനുണ്ട്';

  @override
  String get memberDetailsOverdue => 'കുടിശ്ശിക';

  @override
  String memberDetailsRecorded(String amount) {
    return '$amount രേഖപ്പെടുത്തി';
  }

  @override
  String get memberDetailsNoValidPhone =>
      'ഈ അംഗത്തിന് ശരിയായ മൊബൈൽ നമ്പർ രേഖപ്പെടുത്തിയിട്ടില്ല.';

  @override
  String get memberDetailsReminderNameFallback => 'അംഗം';

  @override
  String get memberDetailsReminderMahalFallback => 'മഹൽ കമ്മിറ്റി';

  @override
  String memberDetailsReminderWithAmount(
      String name, String mahal, String amount) {
    return 'അസ്സലാമു അലൈക്കും $name, നിങ്ങളുടെ മാസവരി അടയ്ക്കാനുണ്ടെന്ന് $mahal ഓർമ്മിപ്പിക്കുന്നു. അടയ്ക്കാനുള്ള തുക: $amount. MahalFlow App വഴി അടയ്ക്കാം. നന്ദി.';
  }

  @override
  String memberDetailsReminderNoAmount(String name, String mahal) {
    return 'അസ്സലാമു അലൈക്കും $name, നിങ്ങളുടെ മാസവരി അടയ്ക്കാനുണ്ടെന്ന് $mahal ഓർമ്മിപ്പിക്കുന്നു. MahalFlow App വഴി അടയ്ക്കാം. നന്ദി.';
  }

  @override
  String get memberDetailsReminderTitle => 'വരി ഓർമ്മപ്പെടുത്തൽ അയയ്ക്കുക';

  @override
  String get memberDetailsReminderSubtitle =>
      'സന്ദേശം എഴുതിച്ചേർത്ത് മെസേജിംഗ് App തുറക്കും';

  @override
  String memberDetailsReminderTo(String phone) {
    return '$phone ലേക്ക്. മറ്റേ App ൽ അയയ്ക്കുക അമർത്തുന്നതുവരെ ഒന്നും അയയ്ക്കില്ല.';
  }

  @override
  String get memberDetailsOpenWhatsApp => 'WhatsApp തുറക്കുക';

  @override
  String get memberDetailsOpenSms => 'SMS തുറക്കുക';

  @override
  String get memberDetailsWhatsAppFailed => 'ഈ ഫോണിൽ WhatsApp തുറക്കാനായില്ല.';

  @override
  String get memberDetailsSmsFailed => 'ഈ ഫോണിൽ SMS App തുറക്കാനായില്ല.';

  @override
  String get memberDetailsSendReminderTooltip =>
      'വരി ഓർമ്മപ്പെടുത്തൽ അയയ്ക്കുക';

  @override
  String get memberDetailsNoPhone => 'ഫോൺ നമ്പർ രേഖപ്പെടുത്തിയിട്ടില്ല';

  @override
  String memberDetailsMemberCode(String code) {
    return 'അംഗ കോഡ് $code';
  }

  @override
  String memberDetailsIdLabel(String id) {
    return 'ID $id';
  }

  @override
  String get memberDetailsIncompleteTitle =>
      'ഈ അംഗത്തിന്റെ വിവരങ്ങൾ പൂർണ്ണമല്ല';

  @override
  String get memberDetailsIncompleteBody =>
      'അംഗ ID ഇല്ലാത്തതിനാൽ ചരിത്രം ലോഡ് ചെയ്യാനോ പേയ്മെന്റ് രേഖപ്പെടുത്താനോ കഴിയില്ല. തിരികെ പോയി അംഗ പട്ടികയിൽ നിന്ന് വീണ്ടും തുറക്കുക.';

  @override
  String get memberDetailsBackToMembers => 'അംഗങ്ങളിലേക്ക് മടങ്ങുക';

  @override
  String get memberDetailsSinceJoining => 'ചേർന്നത് മുതൽ';

  @override
  String get memberDetailsLastSixMonths => 'കഴിഞ്ഞ ആറ് മാസം';

  @override
  String get memberDetailsMonthlyDuesCaps => 'മാസവരി';

  @override
  String get memberDetailsLoadingHistory =>
      'പേയ്മെന്റ് ചരിത്രം ലോഡ് ചെയ്യുന്നു…';

  @override
  String get memberDetailsHistoryUnavailable => 'പേയ്മെന്റ് ചരിത്രം ലഭ്യമല്ല.';

  @override
  String get memberDetailsNoDuesMonths => 'ഇതുവരെ വരി മാസങ്ങളില്ല.';

  @override
  String get memberDetailsAllPaid => 'താഴെ കാണിച്ച എല്ലാ മാസവും അടച്ചു.';

  @override
  String memberDetailsUnpaidCount(int unpaid, int total) {
    return 'സമീപകാല $total മാസങ്ങളിൽ $unpaid എണ്ണം അടച്ചിട്ടില്ല.';
  }

  @override
  String get memberDetailsOutstanding => 'അടയ്ക്കാനുള്ള തുക';

  @override
  String get memberDetailsPaidUpTo => 'അടച്ചത് വരെ';

  @override
  String get memberDetailsHouse => 'വീട്';

  @override
  String get memberDetailsNotRecorded => 'രേഖപ്പെടുത്തിയിട്ടില്ല';

  @override
  String get memberDetailsMemberSince => 'അംഗമായത്';

  @override
  String get memberDetailsLoadingDues => 'വരി ചരിത്രം ലോഡ് ചെയ്യുന്നു';

  @override
  String get memberDetailsDuesError => 'വരി ചരിത്രം ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get memberDetailsNoDuesTitle => 'ഇതുവരെ വരിയില്ല';

  @override
  String get memberDetailsNoDuesBody =>
      'അംഗം ചേർന്ന മാസം മുതലാണ് വരി തുടങ്ങുന്നത്.';

  @override
  String memberDetailsReceiptNumber(String number) {
    return 'രസീത് $number';
  }

  @override
  String get memberDetailsOpenReceipt => 'രസീത് തുറക്കുക';

  @override
  String get editMemberNameRequired => 'പേര് നിർബന്ധമാണ്';

  @override
  String get editMemberPhoneRequired => 'ഫോൺ നമ്പർ നിർബന്ധമാണ്';

  @override
  String get editMemberDuesInvalid => 'മാസവരി കുറഞ്ഞത് ₹1 ആയിരിക്കണം';

  @override
  String editMemberSaveFailed(String reason) {
    return 'മാറ്റങ്ങൾ സേവ് ചെയ്യാനായില്ല. $reason';
  }

  @override
  String editMemberSuspendFailed(String reason) {
    return 'ഈ അംഗത്തെ താൽക്കാലികമായി നിർത്താനായില്ല. $reason';
  }

  @override
  String editMemberReactivateFailed(String reason) {
    return 'ഈ അംഗത്തെ വീണ്ടും സജീവമാക്കാനായില്ല. $reason';
  }

  @override
  String get editMemberUpdated => 'അംഗത്തിന്റെ വിവരങ്ങൾ പുതുക്കി.';

  @override
  String get editMemberSuspendTitle => 'ഈ അംഗത്തെ താൽക്കാലികമായി നിർത്തണോ?';

  @override
  String editMemberSuspendMessage(String name) {
    return 'വീണ്ടും സജീവമാക്കുന്നതുവരെ $name ന്റെ വരി പിരിവ് നിർത്തിവയ്ക്കും. മുൻ വിവരങ്ങൾ നിലനിൽക്കും.';
  }

  @override
  String get editMemberSuspend => 'നിർത്തുക';

  @override
  String get editMemberReactivateTitle => 'ഈ അംഗത്തെ വീണ്ടും സജീവമാക്കണോ?';

  @override
  String editMemberReactivateMessage(String name) {
    return '$name വീണ്ടും സജീവമാകും, വരി പിരിവ് പുനരാരംഭിക്കും.';
  }

  @override
  String get editMemberReactivate => 'വീണ്ടും സജീവമാക്കുക';

  @override
  String get editMemberNowSuspended => 'ഈ അംഗത്തെ താൽക്കാലികമായി നിർത്തി.';

  @override
  String get editMemberActiveAgain => 'ഈ അംഗം വീണ്ടും സജീവമാണ്.';

  @override
  String get editMemberDiscardTitle => 'മാറ്റങ്ങൾ ഉപേക്ഷിക്കണോ?';

  @override
  String get editMemberDiscardMessage =>
      'ഈ അംഗത്തിൽ വരുത്തിയ മാറ്റങ്ങൾ സേവ് ചെയ്തിട്ടില്ല.';

  @override
  String get editMemberDiscard => 'ഉപേക്ഷിക്കുക';

  @override
  String get editMemberKeepEditing => 'തിരുത്തൽ തുടരുക';

  @override
  String get editMemberSubtitle =>
      'മാറ്റങ്ങൾ അടുത്ത വരി കാലയളവ് മുതൽ ബാധകമാകും.';

  @override
  String get editMemberHousehold => 'കുടുംബം';

  @override
  String get editMemberHouseLabel => 'വീട്ടുപേര് അല്ലെങ്കിൽ കുടുംബപ്പേര്';

  @override
  String get editMemberMembership => 'അംഗത്വം';

  @override
  String get editMemberDuesHelper =>
      'കമ്മിറ്റി പുതിയ തുക അംഗീകരിച്ചാൽ മാത്രം മാറ്റുക.';

  @override
  String get editMemberStatusLabel => 'അംഗത്വ നില';

  @override
  String get editMemberReversibleTitle => 'നിർത്തിവയ്ക്കൽ പിൻവലിക്കാം';

  @override
  String get editMemberReversibleBody =>
      'നിർത്തിവച്ച വീടിന്റെ മുൻ വിവരങ്ങൾ നിലനിൽക്കും, ഈ സ്ക്രീനിൽ നിന്ന് വീണ്ടും സജീവമാക്കാം.';

  @override
  String get editMemberSaveChanges => 'മാറ്റങ്ങൾ സേവ് ചെയ്യുക';

  @override
  String get editMemberReactivateMember => 'അംഗത്തെ വീണ്ടും സജീവമാക്കുക';

  @override
  String get editMemberSuspendMember => 'അംഗത്തെ താൽക്കാലികമായി നിർത്തുക';

  @override
  String approvalsApproved(String name) {
    return '$name നെ അംഗീകരിച്ചു.';
  }

  @override
  String get approvalsViewMember => 'അംഗത്തെ കാണുക';

  @override
  String approvalsApproveFailed(String reason) {
    return 'അംഗീകരിക്കാനായില്ല. $reason';
  }

  @override
  String approvalsRejectFailed(String reason) {
    return 'നിരസിക്കാനായില്ല. $reason';
  }

  @override
  String get approvalsThisPerson => 'ഈ വ്യക്തി';

  @override
  String get approvalsRejectTitle => 'ഈ അപേക്ഷ നിരസിക്കണോ?';

  @override
  String approvalsRejectMessage(String name) {
    return '$name മഹലിൽ ചേർക്കപ്പെടില്ല. വീണ്ടും പരിഗണിക്കാൻ വീണ്ടും രജിസ്റ്റർ ചെയ്യേണ്ടി വരും.';
  }

  @override
  String get approvalsRejectRequest => 'അപേക്ഷ നിരസിക്കുക';

  @override
  String approvalsRejected(String name) {
    return '$name ന്റെ അപേക്ഷ നിരസിച്ചു.';
  }

  @override
  String get approvalsSubtitleDefault =>
      'നിങ്ങളുടെ മഹലിൽ ചേരാൻ കാത്തിരിക്കുന്ന പുതിയ അംഗങ്ങൾ.';

  @override
  String get approvalsSubtitleNone => 'ഇപ്പോൾ ആരും കാത്തിരിക്കുന്നില്ല.';

  @override
  String approvalsSubtitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count പേർ ചേരാൻ കാത്തിരിക്കുന്നു.',
      one: '1 ആൾ ചേരാൻ കാത്തിരിക്കുന്നു.',
    );
    return '$_temp0';
  }

  @override
  String get approvalsLoading => 'അപേക്ഷകൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get approvalsLoadError => 'അപേക്ഷകൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get approvalsEmptyTitle => 'തീർപ്പാകാത്ത അപേക്ഷകളില്ല';

  @override
  String get approvalsEmptyBody => 'ചേരാൻ അപേക്ഷിച്ച എല്ലാവരെയും പരിശോധിച്ചു.';

  @override
  String approvalsRequested(String when) {
    return 'അപേക്ഷിച്ചത് $when';
  }

  @override
  String get approvalsNoId =>
      'ഈ അപേക്ഷയ്ക്ക് അംഗ ID ഇല്ല, ഇവിടെ നിന്ന് തീരുമാനമെടുക്കാനാവില്ല.';

  @override
  String get approvalsReject => 'നിരസിക്കുക';

  @override
  String get approvalsApprove => 'അംഗീകരിക്കുക';

  @override
  String get auditFilterAll => 'എല്ലാം';

  @override
  String get auditFilterPayment => 'പേയ്മെന്റ്';

  @override
  String get auditFilterMember => 'അംഗം';

  @override
  String get auditFilterAlerts => 'അറിയിപ്പുകൾ';

  @override
  String get auditFilterSystem => 'സിസ്റ്റം';

  @override
  String get auditDateRangeHelp => 'ഈ തീയതികൾക്കിടയിലുള്ളവ കാണിക്കുക';

  @override
  String get auditSubtitleLoading => 'ലോഗ് ലോഡ് ചെയ്യുന്നു…';

  @override
  String get auditSubtitleUnavailable => 'ലോഗ് ലഭ്യമല്ല';

  @override
  String auditSubtitleShowing(int shown, int total) {
    return '$total പ്രവർത്തനങ്ങളിൽ $shown എണ്ണം കാണിക്കുന്നു';
  }

  @override
  String auditSubtitleMatchesLoaded(int count, int loaded, int total) {
    return 'ലോഡ് ചെയ്ത $loaded/$total എണ്ണത്തിൽ $count പൊരുത്തങ്ങൾ';
  }

  @override
  String auditSubtitleMatching(int count) {
    return 'പൊരുത്തപ്പെടുന്ന $count പ്രവർത്തനങ്ങൾ';
  }

  @override
  String get auditTitle => 'ഓഡിറ്റ് ലോഗ്';

  @override
  String get auditEyebrow => 'കമ്മിറ്റി';

  @override
  String get auditFilterByDate => 'തീയതി പ്രകാരം തിരയുക';

  @override
  String get auditClearDateFilter => 'തീയതി ഫിൽട്ടർ മാറ്റുക';

  @override
  String get auditSearchHint =>
      'പ്രവർത്തനം, ചെയ്തയാൾ, വിവരം അല്ലെങ്കിൽ ID തിരയുക…';

  @override
  String get auditLoadError => 'ഓഡിറ്റ് ലോഗ് ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get auditLoadOlderError => 'പഴയ വിവരങ്ങൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get auditTryAgain => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get auditEndOfRange => 'തിരഞ്ഞെടുത്ത തീയതികൾ ഇവിടെ അവസാനിക്കുന്നു';

  @override
  String get auditStartOfLog => 'ലോഗിന്റെ തുടക്കം';

  @override
  String get auditSystemAction => 'സിസ്റ്റം പ്രവർത്തനം';

  @override
  String get auditLogEntry => 'ലോഗ് വിവരം';

  @override
  String get auditDetailAction => 'പ്രവർത്തനം';

  @override
  String get auditDetailBy => 'ചെയ്തത്';

  @override
  String get auditDetailRecord => 'രേഖ';

  @override
  String get auditRecordIdCopied => 'രേഖയുടെ ID പകർത്തി';

  @override
  String get auditDetailIp => 'IP വിലാസം';

  @override
  String get auditDetailsHeading => 'വിവരങ്ങൾ';

  @override
  String auditBy(String actor) {
    return 'ചെയ്തത്: $actor';
  }

  @override
  String get auditEmptyTitle => 'ഇതുവരെ ഒന്നുമില്ല';

  @override
  String get auditEmptyDesc =>
      'കമ്മിറ്റിയും സിസ്റ്റവും ചെയ്യുന്ന പ്രവർത്തനങ്ങൾ ഇവിടെ കാണാം.';

  @override
  String get auditNoMatchTitle => 'പൊരുത്തപ്പെടുന്നവ ഒന്നുമില്ല';

  @override
  String auditNoMatchQuery(String query) {
    return '\'$query\' എന്നതിന് ഒന്നും കണ്ടെത്തിയില്ല.';
  }

  @override
  String get auditNoMatchFilters => 'ഈ ഫിൽട്ടറുകൾക്ക് ഒന്നും കണ്ടെത്തിയില്ല.';

  @override
  String get auditClearFilters => 'ഫിൽട്ടറുകൾ മാറ്റുക';

  @override
  String get auditLoadingSemantics => 'ഓഡിറ്റ് ലോഗ് ലോഡ് ചെയ്യുന്നു';

  @override
  String get reportsFilterAll => 'എല്ലാം';

  @override
  String get reportsFilterDues => 'വരി';

  @override
  String get reportsFilterContribution => 'സംഭാവന';

  @override
  String get reportsAllTime => 'എല്ലാ കാലവും';

  @override
  String get reportsAllTypes => 'എല്ലാ തരവും';

  @override
  String get reportsTitle => 'റിപ്പോർട്ടുകൾ';

  @override
  String get reportsEyebrow => 'സാമ്പത്തികം';

  @override
  String reportsShareSubject(String mahal, String period) {
    return '$mahal സ്റ്റേറ്റ്മെന്റ് — $period';
  }

  @override
  String reportsExportError(String error) {
    return 'സ്റ്റേറ്റ്മെന്റ് തയ്യാറാക്കാനായില്ല. $error';
  }

  @override
  String get reportsLoadError => 'റിപ്പോർട്ടുകൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get reportsPeriod => 'കാലയളവ്';

  @override
  String get reportsPreparing => 'സ്റ്റേറ്റ്മെന്റ് തയ്യാറാക്കുന്നു…';

  @override
  String get reportsExport => 'സ്റ്റേറ്റ്മെന്റ് (PDF) എടുക്കുക';

  @override
  String get reportsMonthByMonth => 'മാസം തിരിച്ച്';

  @override
  String get reportsTransactions => 'ഇടപാടുകൾ';

  @override
  String get reportsTotalCollected => 'ആകെ പിരിച്ചത്';

  @override
  String get reportsAllTimeAllTypes => 'എല്ലാ കാലവും · എല്ലാ തരവും';

  @override
  String get reportsTotalsError => 'ആകെ തുകകൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get reportsTryAgain => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get reportsLoadingTotals => 'ആകെ തുകകൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get reportsDues => 'വരി';

  @override
  String get reportsContributions => 'സംഭാവനകൾ';

  @override
  String get reportsPendingDues => 'ബാക്കി വരി';

  @override
  String get reportsTransactionsError => 'ഇടപാടുകൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get reportsLoadingPeriod => 'കാലയളവിലെ തുകകൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String reportsSuccessfulPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'വിജയിച്ച $count പേയ്മെന്റുകൾ',
      one: 'വിജയിച്ച 1 പേയ്മെന്റ്',
    );
    return '$_temp0';
  }

  @override
  String reportsBasedOnRecent(int count) {
    return 'ഏറ്റവും പുതിയ $count ഇടപാടുകൾ മാത്രം അടിസ്ഥാനമാക്കി.';
  }

  @override
  String get reportsLoadingBreakdown => 'വിശദാംശങ്ങൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get reportsNoPayments => 'പേയ്മെന്റുകളൊന്നുമില്ല';

  @override
  String get reportsNoPaymentsDesc =>
      'ഈ കാലയളവിലും തരത്തിലും വിജയിച്ച പേയ്മെന്റുകളൊന്നുമില്ല.';

  @override
  String reportsShowingOf(int shown, int total) {
    return '$total എണ്ണത്തിൽ $shown കാണിക്കുന്നു. PDF സ്റ്റേറ്റ്മെന്റിൽ എല്ലാം ഉണ്ട്.';
  }

  @override
  String reportsPaymentsRecorded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count പേയ്മെന്റുകൾ രേഖപ്പെടുത്തി',
      one: '1 പേയ്മെന്റ് രേഖപ്പെടുത്തി',
    );
    return '$_temp0';
  }

  @override
  String get importStepChoose => 'തിരഞ്ഞെടുക്കുക';

  @override
  String get importStepValidate => 'പരിശോധന';

  @override
  String get importStepReview => 'അവലോകനം';

  @override
  String get importStepDone => 'പൂർത്തി';

  @override
  String get importErrorExtension =>
      '.xlsx, .xls അല്ലെങ്കിൽ .csv ഫയൽ തിരഞ്ഞെടുക്കുക.';

  @override
  String get importErrorEmpty => 'ആ ഫയൽ ശൂന്യമാണ്.';

  @override
  String importErrorPicker(String error) {
    return 'ഫയൽ തിരഞ്ഞെടുക്കൽ തുറക്കാനായില്ല. $error';
  }

  @override
  String get importTemplateSubject =>
      'MahalFlow അംഗങ്ങളെ ചേർക്കാനുള്ള ടെംപ്ലേറ്റ്';

  @override
  String importTemplateError(String error) {
    return 'ടെംപ്ലേറ്റ് തയ്യാറാക്കാനായില്ല. $error';
  }

  @override
  String get importTitle => 'അംഗങ്ങളെ ചേർക്കുക';

  @override
  String importStepOf(int step, int total) {
    return 'ഘട്ടം $step / $total';
  }

  @override
  String get importSubtitle =>
      'ഒരു സ്പ്രെഡ്ഷീറ്റിൽ നിന്ന് എല്ലാ അംഗങ്ങളെയും ഒന്നിച്ച് ചേർക്കാം.';

  @override
  String get importUploadProgress => 'അപ്‌ലോഡ് പുരോഗതി';

  @override
  String get importValidating => 'സെർവറിൽ പരിശോധിക്കുന്നു…';

  @override
  String importUploading(int percent) {
    return 'അപ്‌ലോഡ് ചെയ്യുന്നു $percent%';
  }

  @override
  String get importFileError => 'ഈ ഫയൽ ഉപയോഗിക്കാനായില്ല';

  @override
  String get importGetTemplate => 'ടെംപ്ലേറ്റ് എടുക്കുക';

  @override
  String get importTemplateDesc =>
      'name, phone, house_name, monthly_dues എന്നീ കോളങ്ങളുള്ള CSV. ഷെയർ ഷീറ്റിൽ നിന്ന് സേവ് ചെയ്യാം അല്ലെങ്കിൽ അയയ്ക്കാം.';

  @override
  String get importNothingSaved => 'ഇതുവരെ ഒന്നും സേവ് ചെയ്തിട്ടില്ല';

  @override
  String get importNothingSavedDesc =>
      'ആദ്യം സെർവർ ഫയൽ പരിശോധിക്കും. അംഗങ്ങളുടെ പട്ടികയിൽ ചേർക്കുന്നതിന് മുമ്പ് ഫലം നിങ്ങൾക്ക് പരിശോധിക്കാം.';

  @override
  String get importUploadValidate => 'അപ്‌ലോഡ് ചെയ്ത് പരിശോധിക്കുക';

  @override
  String importSelectedFileSemantics(String name) {
    return 'തിരഞ്ഞെടുത്ത ഫയൽ $name. മറ്റൊരു ഫയൽ തിരഞ്ഞെടുക്കാൻ ടാപ്പ് ചെയ്യുക.';
  }

  @override
  String get importChooseSpreadsheet => 'സ്പ്രെഡ്ഷീറ്റ് തിരഞ്ഞെടുക്കുക';

  @override
  String get importAccepts => '.xlsx, .xls, .csv ഫയലുകൾ സ്വീകരിക്കും';

  @override
  String get importTapToChange => 'മറ്റൊരു ഫയൽ തിരഞ്ഞെടുക്കാൻ ടാപ്പ് ചെയ്യുക';

  @override
  String importConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count അംഗങ്ങളെ ചേർക്കണോ?',
      one: '1 അംഗത്തെ ചേർക്കണോ?',
    );
    return '$_temp0';
  }

  @override
  String get importConfirmMessage =>
      'ഇവരെ ഉടൻ അംഗങ്ങളുടെ പട്ടികയിൽ ചേർക്കും. പ്രശ്നമുള്ള വരികൾ ഒഴിവാക്കും.';

  @override
  String get importConfirm => 'ചേർക്കുക';

  @override
  String importServerStatus(String status) {
    return 'സെർവർ \"$status\" എന്ന് അറിയിച്ചു — ഒന്നും ചേർത്തതായി ഉറപ്പായിട്ടില്ല.';
  }

  @override
  String get importCheckRows => 'വരികൾ പരിശോധിക്കുക';

  @override
  String get importEyebrow => 'ചേർക്കൽ';

  @override
  String get importNothingToReview => 'പരിശോധിക്കാൻ ഒന്നുമില്ല';

  @override
  String get importNothingToReviewDesc =>
      'വരികൾ ഇവിടെ കാണാൻ ആദ്യം ഒരു സ്പ്രെഡ്ഷീറ്റ് അപ്‌ലോഡ് ചെയ്യുക.';

  @override
  String get importChooseFile => 'ഫയൽ തിരഞ്ഞെടുക്കുക';

  @override
  String get importOnlyValid => 'ശരിയായ വരികൾ മാത്രമേ ചേർക്കൂ.';

  @override
  String get importStatTotal => 'ആകെ';

  @override
  String get importStatValid => 'ശരി';

  @override
  String get importStatInvalid => 'തെറ്റ്';

  @override
  String get importStatDuplicate => 'ആവർത്തനം';

  @override
  String get importStatImported => 'ചേർത്തു';

  @override
  String get importStatSkipped => 'ഒഴിവാക്കി';

  @override
  String get importStatUnknown => 'അറിയില്ല';

  @override
  String importStatSemantics(String label, String value) {
    return '$label $value';
  }

  @override
  String importRowsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count വരികൾ ഒഴിവാക്കും',
      one: '1 വരി ഒഴിവാക്കും',
    );
    return '$_temp0';
  }

  @override
  String get importFixRows =>
      'ഇവ ചേർക്കാൻ സ്പ്രെഡ്ഷീറ്റിൽ തിരുത്തി വീണ്ടും അപ്‌ലോഡ് ചെയ്യുക.';

  @override
  String get importNotCompleted => 'ചേർക്കൽ പൂർത്തിയായില്ല';

  @override
  String get importRowsInFile => 'നിങ്ങളുടെ ഫയലിലെ വരികൾ';

  @override
  String importSample(int shown, int total) {
    return 'മാതൃക: $total വരികളിൽ $shown എണ്ണം';
  }

  @override
  String get importNoPreview => 'വരികളുടെ പ്രിവ്യൂ ഇല്ല';

  @override
  String get importNoPreviewDesc =>
      'പ്രിവ്യൂ കാണിക്കാൻ സെർവർ വരികളൊന്നും നൽകിയില്ല.';

  @override
  String get importNoValidRows => 'ചേർക്കാൻ ശരിയായ വരികളില്ല';

  @override
  String importButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count അംഗങ്ങളെ ചേർക്കുക',
      one: '1 അംഗത്തെ ചേർക്കുക',
    );
    return '$_temp0';
  }

  @override
  String get importChooseAnother => 'മറ്റൊരു ഫയൽ തിരഞ്ഞെടുക്കുക';

  @override
  String get importNoPhone => 'ഫോൺ ഇല്ല';

  @override
  String importDuesPerMonth(String amount) {
    return '₹$amount/മാസം';
  }

  @override
  String get importFinished => 'ചേർക്കൽ പൂർത്തിയായി';

  @override
  String get importServerConfirmed => 'ചേർത്തതായി സെർവർ ഉറപ്പാക്കി.';

  @override
  String get importDetailFile => 'ഫയൽ';

  @override
  String get importDetailStatus => 'നില';

  @override
  String get importDetailBatch => 'ബാച്ച്';

  @override
  String get importGoToMembers => 'അംഗങ്ങളിലേക്ക് പോകുക';

  @override
  String get gatewayKeyNotShown => 'ആപ്പിൽ കാണിക്കില്ല';

  @override
  String get gatewayTitle => 'ഗേറ്റ്‌വേകൾ';

  @override
  String get gatewayEyebrow => 'പേയ്മെന്റുകൾ';

  @override
  String get gatewaySubtitle =>
      'അംഗങ്ങളുടെ പേയ്മെന്റുകൾ നടക്കുന്നത് ഇവിടെയാണ്.';

  @override
  String get gatewayManagedTitle => 'വെബ് അഡ്മിനിൽ നിന്ന് നിയന്ത്രിക്കുന്നു';

  @override
  String get gatewayManagedDesc =>
      'ഗേറ്റ്‌വേ കീകൾ, webhook രഹസ്യങ്ങൾ, റൂട്ടിംഗ് എന്നിവ MahalFlow വെബ് അഡ്മിനിലാണ് ക്രമീകരിക്കുന്നത്. ഈ സ്ക്രീനിൽ കാണാൻ മാത്രം; രഹസ്യങ്ങൾ ഒരിക്കലും കാണിക്കില്ല.';

  @override
  String get gatewayConfigured => 'ക്രമീകരിച്ച ഗേറ്റ്‌വേകൾ';

  @override
  String get gatewayLoading => 'ഗേറ്റ്‌വേകൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get gatewayLoadError => 'ഗേറ്റ്‌വേകൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get gatewayEmptyTitle => 'ഗേറ്റ്‌വേകളൊന്നും ക്രമീകരിച്ചിട്ടില്ല';

  @override
  String get gatewayEmptyDesc =>
      'ഓൺലൈൻ പേയ്മെന്റുകൾ സ്വീകരിക്കാൻ വെബ് അഡ്മിനിൽ ഒന്ന് ക്രമീകരിക്കുക.';

  @override
  String get gatewayPrimaryHeading => 'പ്രധാന ഗേറ്റ്‌വേ';

  @override
  String gatewayActiveCount(int active, int total) {
    return '$total എണ്ണത്തിൽ $active സജീവം';
  }

  @override
  String get gatewayLoadingShort => 'ലോഡ് ചെയ്യുന്നു…';

  @override
  String get gatewayNoneSet => 'ഒന്നും ക്രമീകരിച്ചിട്ടില്ല';

  @override
  String get gatewayRoutedHere =>
      'അംഗങ്ങളുടെ പേയ്മെന്റുകൾ ആദ്യം ഇതിലൂടെയാണ് പോകുന്നത്.';

  @override
  String get gatewayPrimaryRoute => 'പ്രധാന വഴി';

  @override
  String get gatewayFallbackRoute => 'പകരം വഴി';

  @override
  String get gatewayKeyId => 'കീ ID';

  @override
  String get gatewayId => 'ഗേറ്റ്‌വേ ID';

  @override
  String get broadcastTitle => 'അറിയിപ്പ് അയയ്ക്കുക';

  @override
  String get broadcastSubtitle => 'അംഗങ്ങളുടെ ഫോണിൽ ആപ്പ് അറിയിപ്പായി എത്തും';

  @override
  String get broadcastAudienceAll => 'എല്ലാ അംഗങ്ങളും';

  @override
  String get broadcastAudienceOverdue => 'വരി ബാക്കിയുള്ളവർ';

  @override
  String get broadcastAudienceFamilyHeads => 'കുടുംബനാഥന്മാർ';

  @override
  String get broadcastReminderTitle => 'മാസവരി ഓർമ്മപ്പെടുത്തൽ';

  @override
  String get broadcastReminderBody =>
      'ബഹുമാനപ്പെട്ട അംഗമേ, ഞങ്ങളുടെ രേഖകൾ പ്രകാരം നിങ്ങളുടെ കുടുംബത്തിന് മാസവരി ബാക്കിയുണ്ട്. MahalFlow ആപ്പിലൂടെ അടയ്ക്കാവുന്നതാണ്.';

  @override
  String get broadcastRecipientsOverdueAll =>
      'വരി ബാക്കിയുള്ള എല്ലാ കുടുംബങ്ങളും';

  @override
  String broadcastRecipientsOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'വരി ബാക്കിയുള്ള $count കുടുംബങ്ങൾ',
      one: 'വരി ബാക്കിയുള്ള 1 കുടുംബം',
    );
    return '$_temp0';
  }

  @override
  String get broadcastRecipientsFamilyHeads => 'എല്ലാ കുടുംബനാഥന്മാരും';

  @override
  String get broadcastRecipientsAll => 'എല്ലാ അംഗങ്ങളും';

  @override
  String broadcastRecipientsAllCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'എല്ലാ $count കുടുംബങ്ങളും',
      one: '1 കുടുംബം',
    );
    return '$_temp0';
  }

  @override
  String broadcastSendsTo(String recipients) {
    return 'ലഭിക്കുന്നവർ: $recipients.';
  }

  @override
  String get broadcastTitleRequired => 'തലക്കെട്ട് ചേർക്കുക';

  @override
  String get broadcastMessageRequired => 'സന്ദേശം എഴുതുക';

  @override
  String get broadcastConfirmTitle => 'ഈ അറിയിപ്പ് അയയ്ക്കണോ?';

  @override
  String broadcastConfirmMessage(String title, String recipients) {
    return '\"$title\" ആപ്പ് അറിയിപ്പായും പുഷ് നോട്ടിഫിക്കേഷനായും അയയ്ക്കും. ലഭിക്കുന്നവർ: $recipients. അയച്ചാൽ പിൻവലിക്കാനാവില്ല.';
  }

  @override
  String get broadcastSendNotice => 'അറിയിപ്പ് അയയ്ക്കുക';

  @override
  String get broadcastWhoHeading => 'ആർക്കൊക്കെ അയയ്ക്കണം';

  @override
  String get broadcastNoticeTitle => 'അറിയിപ്പിന്റെ തലക്കെട്ട്';

  @override
  String get broadcastTitleHint => 'ഉദാ: ജുമുഅ സമയത്തിൽ മാറ്റം';

  @override
  String get broadcastMessage => 'സന്ദേശം';

  @override
  String get broadcastMessageHint => 'അറിയിപ്പ് മുഴുവനായി എഴുതുക…';

  @override
  String get broadcastPriority => 'പ്രാധാന്യം';

  @override
  String get broadcastPriorityInfo => 'വിവരത്തിന്';

  @override
  String get broadcastPriorityReminder => 'വരി ഓർമ്മപ്പെടുത്തൽ';

  @override
  String get broadcastPriorityCritical => 'അടിയന്തരം';

  @override
  String get broadcastNotSent => 'അറിയിപ്പ് അയച്ചില്ല';

  @override
  String get broadcastReviewSend => 'പരിശോധിച്ച് അയയ്ക്കുക';

  @override
  String get recordPayTitle => 'പണമായുള്ള പേയ്മെന്റ് രേഖപ്പെടുത്തുക';

  @override
  String get recordPaySubtitle => 'അംഗത്തിന്റെ പേരിൽ ഒപ്പിട്ട രസീത് നൽകും';

  @override
  String get recordPayThisMember => 'ഈ അംഗം';

  @override
  String recordPayConfirmTitle(String amount) {
    return '$amount രേഖപ്പെടുത്തണോ?';
  }

  @override
  String recordPayConfirmMessage(
      String amount, String name, String period, String months) {
    return '$name പണമായി നൽകിയ $amount, $period ($months) കാലത്തേക്ക്. ഒപ്പിട്ട രസീത് നൽകും; പിന്നീട് തിരുത്താനാവില്ല.';
  }

  @override
  String get recordPayConfirm => 'പേയ്മെന്റ് രേഖപ്പെടുത്തുക';

  @override
  String get recordPayLoadingMembers => 'അംഗങ്ങളെ ലോഡ് ചെയ്യുന്നു';

  @override
  String get recordPayMembersError => 'അംഗങ്ങളെ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get recordPayTryAgain => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get recordPayNoMembers => 'പട്ടികയിൽ ഇതുവരെ അംഗങ്ങളില്ല.';

  @override
  String recordPayNoMatch(String query) {
    return '\"$query\" എന്നതിന് അംഗങ്ങളെ കണ്ടെത്തിയില്ല.';
  }

  @override
  String recordPayShowing(int shown, int total) {
    return '$total പേരിൽ $shown പേരെ കാണിക്കുന്നു. കൃത്യമാക്കാൻ തിരയുക.';
  }

  @override
  String get recordPayMemberHeading => 'അംഗം';

  @override
  String get recordPaySearchHint => 'പേര്, ഫോൺ അല്ലെങ്കിൽ വീട് തിരയുക…';

  @override
  String get recordPayNoId =>
      'ഈ അംഗത്തിന്റെ രേഖയിൽ ID ഇല്ല, അതിനാൽ പേയ്മെന്റ് രേഖപ്പെടുത്താനാവില്ല.';

  @override
  String get recordPayNoDues =>
      'ഈ അംഗത്തിന് മാസവരി തുക നിശ്ചയിച്ചിട്ടില്ല. ആദ്യം അംഗത്തിന്റെ വിവരം തിരുത്തുക.';

  @override
  String get recordPayNoAnchor =>
      'ഈ അംഗം അവസാനം അടച്ച മാസം രേഖയിലില്ല, അതിനാൽ അടുത്ത വരി മാസം അറിയില്ല.';

  @override
  String get recordPayDuesNotSet => 'മാസവരി നിശ്ചയിച്ചിട്ടില്ല';

  @override
  String recordPayPerMonth(String amount) {
    return 'മാസം $amount';
  }

  @override
  String get recordPayChange => 'മാറ്റുക';

  @override
  String get recordPayCantRecord => 'ഇപ്പോൾ രേഖപ്പെടുത്താനാവില്ല';

  @override
  String get recordPayMonthsHeading => 'എത്ര മാസം';

  @override
  String recordPayCovers(String period) {
    return '$period ഉൾപ്പെടുന്നു — അവസാനം അടച്ച മാസത്തിന് ശേഷം ക്രമത്തിലാണ് വരി അടയ്ക്കുന്നത്.';
  }

  @override
  String get recordPayMethodHeading => 'പേയ്മെന്റ് രീതി';

  @override
  String get recordPayMethodDesc =>
      'കമ്മിറ്റി പിരിച്ച പണം. അംഗങ്ങൾ ആപ്പിലൂടെ അടയ്ക്കുമ്പോൾ ഓൺലൈൻ പേയ്മെന്റുകൾ സ്വയം രേഖപ്പെടുത്തും.';

  @override
  String get recordPayTotal => 'രേഖപ്പെടുത്തേണ്ട ആകെ തുക';

  @override
  String get recordPayNotRecorded => 'പേയ്മെന്റ് രേഖപ്പെടുത്തിയില്ല';

  @override
  String get recordPayReview => 'പരിശോധിച്ച് രേഖപ്പെടുത്തുക';

  @override
  String get receiptSheetTitle => 'രസീത്';

  @override
  String get receiptSheetSubtitle => 'മഹൽ ലെഡ്ജറിലെ ഒപ്പിട്ട രേഖ';

  @override
  String get receiptSheetLoading => 'രസീത് ലോഡ് ചെയ്യുന്നു';

  @override
  String get receiptSheetLoadError => 'ഈ രസീത് ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get receiptSheetTryAgain => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get receiptSheetNumber => 'രസീത് നമ്പർ';

  @override
  String get receiptSheetPayer => 'അടച്ചയാൾ';

  @override
  String get receiptSheetAmount => 'തുക';

  @override
  String get receiptSheetType => 'തരം';

  @override
  String get receiptSheetMonths => 'മാസങ്ങൾ';

  @override
  String get receiptSheetDate => 'തീയതി';

  @override
  String get receiptSheetHash => 'ലെഡ്ജർ ഹാഷ്';

  @override
  String get receiptSheetVerify => 'ലെഡ്ജറിൽ പരിശോധിക്കുക';

  @override
  String get receiptSheetVerifyAgain => 'വീണ്ടും പരിശോധിക്കുക';

  @override
  String get receiptSheetValid => 'ഒപ്പ് ശരിയാണ്';

  @override
  String get receiptSheetValidDesc =>
      'വീണ്ടും കണക്കാക്കിയ ഹാഷ് ഒത്തുവരുന്നു — ഈ രസീതിൽ മാറ്റം വരുത്തിയിട്ടില്ല.';

  @override
  String get receiptSheetMismatch => 'ഒപ്പ് ഒത്തുവരുന്നില്ല';

  @override
  String get receiptSheetMismatchDesc =>
      'സൂക്ഷിച്ച ഹാഷ് രസീതിലെ വിവരങ്ങളുമായി ഒത്തുവരുന്നില്ല. ഇത് ആശ്രയിക്കുന്നതിന് മുമ്പ് കമ്മിറ്റിയെ അറിയിക്കുക.';

  @override
  String get receiptSheetVerifyFailed => 'പരിശോധിക്കാനായില്ല';

  @override
  String get receiptSheetTryAgainDot => 'വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get authMobileNumber => 'മൊബൈൽ നമ്പർ';

  @override
  String get authFullName => 'മുഴുവൻ പേര്';

  @override
  String get authSignOut => 'സൈൻ ഔട്ട് ചെയ്യുക';

  @override
  String get authServerUnreachable =>
      'സെർവറുമായി ബന്ധപ്പെടാനായില്ല. ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get authSignedInServerUnreachable =>
      'സൈൻ ഇൻ ചെയ്തു, പക്ഷേ സെർവറുമായി ബന്ധപ്പെടാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get authInvalidPhone => 'ശരിയായ മൊബൈൽ നമ്പർ നൽകുക';

  @override
  String get authTooManyRequests =>
      'ഒരുപാട് തവണ ശ്രമിച്ചു. കുറച്ച് മിനിറ്റ് കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get authQuotaExceeded =>
      'ഒരുപാട് കോഡുകൾ അയച്ചു. കുറച്ച് കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get authNetworkFailed =>
      'ഇന്റർനെറ്റ് കണക്ഷൻ ഇല്ല. കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get authSessionExpired =>
      'ഈ കോഡിന്റെ സമയം കഴിഞ്ഞു. പുതിയ കോഡിനായി “കോഡ് വീണ്ടും അയയ്ക്കുക” അമർത്തുക.';

  @override
  String get authInvalidCode => 'ആ കോഡ് തെറ്റാണ്. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get authAppNotVerified =>
      'സൈൻ ഇന്നിനായി ഈ App പരിശോധിക്കാനായില്ല. App അപ്ഡേറ്റ് ചെയ്യുക, അല്ലെങ്കിൽ പിന്നീട് ശ്രമിക്കുക.';

  @override
  String get splashTagline => 'നിങ്ങളുടെ മഹലിലെ മാസവരി,\nസംഭാവന, രസീതുകൾ';

  @override
  String get splashFooter => 'സുരക്ഷിത പേയ്മെന്റ് · ഉറപ്പുള്ള രസീത്';

  @override
  String get onboardingSlide1Title => 'അടയ്ക്കാനുള്ളത് കൃത്യമായി അറിയാം';

  @override
  String get onboardingSlide1Body =>
      'മാസവരി, അടയ്ക്കാനുള്ള മാസങ്ങൾ, മുൻകൂർ തുക — എല്ലാം ഒരു സ്ക്രീനിൽ. പേയ്മെന്റ് പൂർത്തിയായാൽ ഉടൻ പുതുക്കും.';

  @override
  String get onboardingSlide1Point1 => 'അടയ്ക്കാനുള്ള തുക ഒറ്റനോട്ടത്തിൽ';

  @override
  String get onboardingSlide1Point2 => 'ഓരോ മാസത്തെയും വിവരം';

  @override
  String get onboardingSlide2Title => 'കുറച്ച് ടാപ്പിൽ അടയ്ക്കാം';

  @override
  String get onboardingSlide2Body =>
      'UPI, കാർഡ്, നെറ്റ് ബാങ്കിംഗ് വഴി മാസവരി അടയ്ക്കാം, മഹൽ ഫണ്ടിലേക്ക് സംഭാവന നൽകാം. മാസവരി AutoPay വഴി സ്വയം അടയ്ക്കാനും കഴിയും.';

  @override
  String get onboardingSlide2Point1 => 'UPI, കാർഡ്, നെറ്റ് ബാങ്കിംഗ്';

  @override
  String get onboardingSlide2Point2 => 'ആവശ്യമെങ്കിൽ AutoPay';

  @override
  String get onboardingSlide3Title => 'ഓരോ പേയ്മെന്റിനും രസീത്';

  @override
  String get onboardingSlide3Body =>
      'ഓരോ ഇടപാടിനും പരിശോധിക്കാനും ഡൗൺലോഡ് ചെയ്യാനും പങ്കിടാനും കഴിയുന്ന രസീത് ലഭിക്കും — നിങ്ങളും കമ്മിറ്റിയും ഒരേ രേഖ കാണും.';

  @override
  String get onboardingSlide3Point1 => 'ഓരോ രസീതും കമ്മിറ്റിക്ക് പരിശോധിക്കാം';

  @override
  String get onboardingSlide3Point2 =>
      'എപ്പോൾ വേണമെങ്കിലും PDF ആയി ഡൗൺലോഡ് ചെയ്യാം';

  @override
  String get onboardingSkipSemantics => 'ആമുഖം ഒഴിവാക്കുക';

  @override
  String get onboardingGetStarted => 'തുടങ്ങാം';

  @override
  String onboardingPageOf(int current, int total) {
    return '$total-ൽ $current-ാം പേജ്';
  }

  @override
  String get loginTitle => 'വീണ്ടും സ്വാഗതം';

  @override
  String get loginSubtitle =>
      'മാസവരി കാണാനും അടയ്ക്കാനും രസീതുകൾ സൂക്ഷിക്കാനും സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get loginPhoneRequired => 'രജിസ്റ്റർ ചെയ്ത മൊബൈൽ നമ്പർ നൽകുക';

  @override
  String get loginPhoneInvalid => 'ശരിയായ 10 അക്ക മൊബൈൽ നമ്പർ നൽകുക';

  @override
  String get loginSendTimeout =>
      'കോഡ് അയയ്ക്കാൻ വൈകുന്നു. കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get loginSendFailed => 'കോഡ് അയയ്ക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get loginDemoServerError =>
      'സെർവറുമായി ബന്ധപ്പെടാനായില്ല. കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get loginLinkOpenFailed => 'പേജ് തുറക്കാനായില്ല.';

  @override
  String get loginSignIn => 'സൈൻ ഇൻ';

  @override
  String get loginPhoneHelper => 'ഈ നമ്പറിലേക്ക് 6 അക്ക കോഡ് അയയ്ക്കും.';

  @override
  String get loginDemoTitle => 'ഡെമോ · debug build';

  @override
  String get loginDemoBody =>
      'OTP ഇല്ലാതെ സാമ്പിൾ ഡാറ്റയുമായി ഡാഷ്ബോർഡ് തുറക്കുക. Release build-ൽ കാണില്ല.';

  @override
  String get loginDemoCommittee => 'കമ്മിറ്റി';

  @override
  String get loginTermsPrefix => 'തുടരുന്നതിലൂടെ, ഞങ്ങളുടെ ';

  @override
  String get loginTermsLink => 'സേവന നിബന്ധനകളും';

  @override
  String get loginTermsAnd => ' ';

  @override
  String get loginPrivacyLink => 'സ്വകാര്യതാ നയവും';

  @override
  String get loginTermsSuffix => ' നിങ്ങൾ അംഗീകരിക്കുന്നു.';

  @override
  String loginLinkSemantics(String label) {
    return '$label, ലിങ്ക്';
  }

  @override
  String get otpTitle => 'നമ്പർ സ്ഥിരീകരിക്കുക';

  @override
  String otpSubtitle(String phone) {
    return '$phone എന്ന നമ്പറിലേക്ക് അയച്ച 6 അക്ക കോഡ് നൽകുക.';
  }

  @override
  String get otpSectionLabel => 'OTP';

  @override
  String get otpCodeLabel => '6 അക്ക കോഡ്';

  @override
  String get otpCodeRequired => '6 അക്ക കോഡ് നൽകുക';

  @override
  String get otpVerificationFailed =>
      'സ്ഥിരീകരിക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get otpNewCodeSent => 'പുതിയ കോഡ് അയച്ചു.';

  @override
  String get otpResendFailed =>
      'കോഡ് വീണ്ടും അയയ്ക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get otpSending => 'അയയ്ക്കുന്നു…';

  @override
  String otpResendIn(int seconds) {
    return '$seconds സെക്കൻഡിനു ശേഷം വീണ്ടും അയയ്ക്കാം';
  }

  @override
  String get otpResend => 'കോഡ് വീണ്ടും അയയ്ക്കുക';

  @override
  String get otpVerifying => 'സ്ഥിരീകരിക്കുന്നു…';

  @override
  String get otpVerifyContinue => 'സ്ഥിരീകരിച്ച് തുടരുക';

  @override
  String get otpChangeNumber => 'നമ്പർ മാറ്റുക';

  @override
  String get pendingApprovalStillWaiting =>
      'അംഗീകാരം ഇതുവരെ ലഭിച്ചിട്ടില്ല. കമ്മിറ്റി അംഗീകരിച്ചാൽ ഉടൻ പ്രവേശിക്കാം.';

  @override
  String get pendingApprovalTitle => 'അംഗീകാരത്തിനായി കാത്തിരിക്കുന്നു';

  @override
  String get pendingApprovalRequestSent => 'നിങ്ങളുടെ അപേക്ഷ അയച്ചു.';

  @override
  String pendingApprovalThanks(String name) {
    return 'നന്ദി, $name.';
  }

  @override
  String get pendingApprovalBody =>
      'മാസവരി കാണാനും അടയ്ക്കാനും മഹൽ കമ്മിറ്റി നിങ്ങളുടെ അക്കൗണ്ട് അംഗീകരിക്കണം.';

  @override
  String get pendingApprovalNoticeTitle => 'ഏതാണ്ട് പൂർത്തിയായി';

  @override
  String get pendingApprovalNoticeBody =>
      'കമ്മിറ്റി അംഗീകരിച്ചാൽ ഉടൻ പ്രവേശനം ലഭിക്കും. “വീണ്ടും പരിശോധിക്കുക” അമർത്തുക, അല്ലെങ്കിൽ താഴേക്ക് വലിച്ച് പുതുക്കുക. പിന്നീട് വന്നാലും മതി.';

  @override
  String get pendingApprovalChecking => 'പരിശോധിക്കുന്നു…';

  @override
  String get pendingApprovalCheckAgain => 'വീണ്ടും പരിശോധിക്കുക';

  @override
  String get registerNameRequired => 'മുഴുവൻ പേര് നൽകുക';

  @override
  String get registerMahalIdRequired => 'മഹൽ ID നൽകുക';

  @override
  String get registerTitle => 'നിങ്ങളാരാണെന്ന് സ്ഥിരീകരിക്കുക';

  @override
  String get registerSubtitle =>
      'ഈ നമ്പർ ഇതുവരെ രജിസ്റ്റർ ചെയ്തിട്ടില്ല. നിങ്ങളുടെ വിവരങ്ങൾ നൽകുക, കമ്മിറ്റി അംഗീകരിക്കും.';

  @override
  String get registerDetailsLabel => 'നിങ്ങളുടെ വിവരങ്ങൾ';

  @override
  String get registerNameHint => 'കമ്മിറ്റിക്ക് അറിയുന്ന പേര്';

  @override
  String get registerMahalIdLabel => 'മഹൽ ID';

  @override
  String get registerMahalIdHint => 'ഉദാ. MH_001_CALICUT';

  @override
  String get registerMahalIdHelper =>
      'ഈ ID ഇല്ലെങ്കിൽ മഹൽ കമ്മിറ്റിയോട് ചോദിക്കുക.';

  @override
  String get registerVerifiedByOtp => 'OTP വഴി സ്ഥിരീകരിച്ചു.';

  @override
  String get registerNotSent => 'അയച്ചില്ല';

  @override
  String get registerNextTitle => 'ഇനി എന്ത്';

  @override
  String get registerNextBody =>
      'നിങ്ങളുടെ അപേക്ഷ മഹൽ കമ്മിറ്റിക്ക് ലഭിക്കും. അവർ അംഗീകരിച്ചാൽ, ഇതേ നമ്പറിൽ വീണ്ടും സൈൻ ഇൻ ചെയ്ത് മാസവരിയും രസീതുകളും കാണാം.';

  @override
  String get registerSubmitting => 'അയയ്ക്കുന്നു…';

  @override
  String get registerRequestJoin => 'ചേരാൻ അപേക്ഷിക്കുക';

  @override
  String get registerDifferentNumber => 'മറ്റൊരു നമ്പർ ഉപയോഗിക്കുക';

  @override
  String profileRefreshFailed(String message) {
    return 'പുതുക്കാനായില്ല. $message';
  }

  @override
  String get profileUpdated => 'നിങ്ങളുടെ വിവരങ്ങൾ പുതുക്കി.';

  @override
  String get profileLogoutTitle => 'സൈൻ ഔട്ട് ചെയ്യണോ?';

  @override
  String get profileLogoutMessage => 'വീണ്ടും സൈൻ ഇൻ ചെയ്യാൻ മൊബൈൽ നമ്പർ വേണം.';

  @override
  String get profileLogout => 'സൈൻ ഔട്ട്';

  @override
  String get profileEyebrow => 'നിങ്ങളുടെ അക്കൗണ്ട്';

  @override
  String get profileEditTooltip => 'വിവരങ്ങൾ തിരുത്തുക';

  @override
  String get profileLoading => 'പ്രൊഫൈൽ ലോഡ് ചെയ്യുന്നു';

  @override
  String get profileLoadError => 'പ്രൊഫൈൽ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get profileLoadErrorFallback => 'അൽപം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get profileSectionPayments => 'പേയ്മെന്റുകൾ';

  @override
  String get profileAutopay => 'AutoPay';

  @override
  String get profileAutopaySubtitle => 'മാസവരിക്കുള്ള UPI AutoPay';

  @override
  String get profileReceipts => 'രസീതുകൾ';

  @override
  String get profileReceiptsSubtitle => 'നിങ്ങൾ നടത്തിയ എല്ലാ പേയ്മെന്റുകളും';

  @override
  String get profilePayDues => 'മാസവരി അടയ്ക്കുക';

  @override
  String get profilePayDuesSubtitle => 'ബാക്കിയുള്ള മാസങ്ങൾ അടയ്ക്കുക';

  @override
  String get profileSectionApp => 'App';

  @override
  String get profileNotices => 'അറിയിപ്പുകൾ';

  @override
  String get profileNoticesSubtitle => 'കമ്മിറ്റിയുടെ അറിയിപ്പുകൾ';

  @override
  String get profileHelpSubtitle => 'മഹൽ കമ്മിറ്റി ഓഫീസുമായി ബന്ധപ്പെടുക';

  @override
  String get profileReplayWelcome => 'ആമുഖം വീണ്ടും കാണുക';

  @override
  String get profileReplayWelcomeSubtitle =>
      'ആദ്യ പരിചയ സ്ക്രീനുകൾ വീണ്ടും കാണിക്കുക';

  @override
  String profileVersion(String version) {
    return 'MahalFlow · v$version';
  }

  @override
  String get profileMembership => 'അംഗത്വം';

  @override
  String get profileMemberId => 'അംഗ ID';

  @override
  String get profileMahal => 'മഹൽ';

  @override
  String get profileEmail => 'ഇമെയിൽ';

  @override
  String get profileAddress => 'വിലാസം';

  @override
  String get profileEditDetails => 'വിവരങ്ങൾ തിരുത്തുക';

  @override
  String get editProfileNameRequired => 'പേര് ഒഴിച്ചിടരുത്';

  @override
  String get editProfileEmailInvalid => 'ഇത് ശരിയായ ഇമെയിൽ വിലാസമല്ല';

  @override
  String get editProfilePincodeInvalid => 'PIN കോഡിൽ 6 അക്കം വേണം';

  @override
  String get editProfileSaveFailed =>
      'വിവരങ്ങൾ സേവ് ചെയ്യാനായില്ല. കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get editProfileDiscardTitle => 'മാറ്റങ്ങൾ ഉപേക്ഷിക്കണോ?';

  @override
  String get editProfileDiscardMessage =>
      'നിങ്ങൾ വരുത്തിയ മാറ്റങ്ങൾ സേവ് ചെയ്തിട്ടില്ല.';

  @override
  String get editProfileDiscard => 'ഉപേക്ഷിക്കുക';

  @override
  String get editProfileKeepEditing => 'തിരുത്തൽ തുടരുക';

  @override
  String get editProfileTitle => 'വിവരങ്ങൾ തിരുത്തുക';

  @override
  String get editProfileSubtitle =>
      'രസീതുകൾ നിങ്ങൾക്ക് ലഭിക്കാൻ ബന്ധപ്പെടാനുള്ള വിവരങ്ങൾ പുതുക്കി വയ്ക്കുക.';

  @override
  String get editProfileManagedNote =>
      'മൊബൈൽ നമ്പറും അംഗ ID-യും കമ്മിറ്റിയാണ് കൈകാര്യം ചെയ്യുന്നത്.';

  @override
  String get editProfilePersonal => 'വ്യക്തിഗത വിവരങ്ങൾ';

  @override
  String get editProfileEmail => 'ഇമെയിൽ';

  @override
  String get editProfileEmailHint => 'you@example.com';

  @override
  String get editProfileMobileNote => 'ഇത് മാറ്റാൻ മഹൽ ഓഫീസുമായി ബന്ധപ്പെടുക.';

  @override
  String get editProfileAddress => 'വിലാസം';

  @override
  String get editProfileHouse => 'വീട്ടുപേര് അല്ലെങ്കിൽ നമ്പർ';

  @override
  String get editProfileStreet => 'തെരുവ് / അടയാളം (ആവശ്യമെങ്കിൽ)';

  @override
  String get editProfileCity => 'നഗരം';

  @override
  String get editProfileState => 'സംസ്ഥാനം';

  @override
  String get editProfilePincode => 'PIN കോഡ്';

  @override
  String get editProfileOfficeKeepsTitle => 'ഓഫീസിൽ സൂക്ഷിക്കുന്നത്';

  @override
  String get editProfileOfficeKeepsBody =>
      'പേരും വീട്ടുപേരും അംഗത്വ രേഖയിൽ സേവ് ചെയ്യും. ഇമെയിൽ, തെരുവ്, നഗരം, PIN കോഡ് എന്നിവ ഓഫീസ് ഇപ്പോൾ സൂക്ഷിക്കുന്നില്ല.';

  @override
  String get editProfileSaving => 'സേവ് ചെയ്യുന്നു…';

  @override
  String get editProfileSave => 'മാറ്റങ്ങൾ സേവ് ചെയ്യുക';

  @override
  String get helpOpenFailed => 'ആ App തുറക്കാനായില്ല.';

  @override
  String get helpTitle => 'സഹായം';

  @override
  String helpContactNamed(String mahalName) {
    return 'മാസവരി, രസീത്, AutoPay എന്നിവയെക്കുറിച്ചുള്ള സംശയങ്ങൾക്ക് $mahalName ഓഫീസുമായി ബന്ധപ്പെടുക.';
  }

  @override
  String get helpContactGeneric =>
      'മാസവരി, രസീത്, AutoPay എന്നിവയെക്കുറിച്ചുള്ള സംശയങ്ങൾക്ക് മഹൽ കമ്മിറ്റി ഓഫീസുമായി ബന്ധപ്പെടുക.';

  @override
  String helpContactNamedNoPhone(String mahalName) {
    return 'മാസവരി, രസീത്, AutoPay എന്നിവയെക്കുറിച്ചുള്ള സംശയങ്ങൾക്ക് $mahalName ഓഫീസിൽ നേരിട്ടോ അവരുടെ പതിവ് നമ്പറിലോ ബന്ധപ്പെടുക.';
  }

  @override
  String get helpContactGenericNoPhone =>
      'മാസവരി, രസീത്, AutoPay എന്നിവയെക്കുറിച്ചുള്ള സംശയങ്ങൾക്ക് മഹൽ കമ്മിറ്റി ഓഫീസിൽ നേരിട്ടോ അവരുടെ പതിവ് നമ്പറിലോ ബന്ധപ്പെടുക.';

  @override
  String get helpTipPending =>
      '\"കാത്തിരിക്കുന്നു\" എന്ന് കാണിക്കുന്ന പേയ്മെന്റ് സാധാരണ കുറച്ച് മിനിറ്റിനുള്ളിൽ പൂർത്തിയാകും. ആ സമയത്ത് വീണ്ടും അടയ്ക്കരുത്.';

  @override
  String get helpTipReceipts =>
      'പൂർത്തിയായ ഓരോ പേയ്മെന്റിന്റെയും രസീത് \'രസീതുകൾ\' എന്ന ഭാഗത്ത് ഉണ്ടാകും.';

  @override
  String get helpTipOffice =>
      'മൊബൈൽ നമ്പറും അംഗ ID-യും ഓഫീസിന് മാത്രമേ മാറ്റാനാകൂ.';

  @override
  String get helpWhatsApp => 'WhatsApp';

  @override
  String get helpCall => 'വിളിക്കുക';

  @override
  String get appName => 'MahalFlow';

  @override
  String get commonCancel => 'റദ്ദാക്കുക';

  @override
  String get commonConfirm => 'സ്ഥിരീകരിക്കുക';

  @override
  String get commonClose => 'അടയ്ക്കുക';

  @override
  String get commonBack => 'തിരികെ';

  @override
  String get commonTryAgain => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get commonSave => 'സേവ് ചെയ്യുക';

  @override
  String get commonContinue => 'തുടരുക';

  @override
  String get commonDone => 'പൂർത്തിയായി';

  @override
  String get commonOk => 'ശരി';

  @override
  String get commonYes => 'അതെ';

  @override
  String get commonNo => 'ഇല്ല';

  @override
  String get commonEdit => 'തിരുത്തുക';

  @override
  String get commonDelete => 'ഇല്ലാതാക്കുക';

  @override
  String get commonRemove => 'നീക്കം ചെയ്യുക';

  @override
  String get commonView => 'കാണുക';

  @override
  String get commonSeeAll => 'എല്ലാം കാണുക';

  @override
  String get commonSearch => 'തിരയുക';

  @override
  String get commonClearSearch => 'തിരയൽ മായ്ക്കുക';

  @override
  String get commonLoading => 'ലോഡ് ചെയ്യുന്നു';

  @override
  String get commonUnavailable => 'ലഭ്യമല്ല';

  @override
  String get commonSomethingWentWrong => 'എന്തോ പിശക് സംഭവിച്ചു';

  @override
  String get commonGoBack => 'തിരികെ പോകുക';

  @override
  String get commonUndo => 'പഴയപടിയാക്കുക';

  @override
  String get commonShare => 'പങ്കിടുക';

  @override
  String get commonDownload => 'ഡൗൺലോഡ് ചെയ്യുക';

  @override
  String get commonSubmit => 'സമർപ്പിക്കുക';

  @override
  String get commonNext => 'അടുത്തത്';

  @override
  String get commonSkip => 'ഒഴിവാക്കുക';

  @override
  String get commonProfile => 'പ്രൊഫൈൽ';

  @override
  String get commonMember => 'അംഗം';

  @override
  String commonCopyLabel(String label) {
    return '$label കോപ്പി ചെയ്യുക';
  }

  @override
  String commonCopiedLabel(String label) {
    return '$label കോപ്പി ചെയ്തു';
  }

  @override
  String commonShowLabel(String label) {
    return '$label കാണിക്കുക';
  }

  @override
  String commonHideLabel(String label) {
    return '$label മറയ്ക്കുക';
  }

  @override
  String commonStatusLabel(String label) {
    return 'നില: $label';
  }

  @override
  String commonUnreadCount(String label, int count) {
    return '$label, വായിക്കാത്തത് $count';
  }

  @override
  String commonNewBadge(String label) {
    return '$label, പുതിയത്';
  }

  @override
  String get navHome => 'ഹോം';

  @override
  String get navPay => 'അടയ്ക്കുക';

  @override
  String get navReceipts => 'രസീതുകൾ';

  @override
  String get navNotices => 'അറിയിപ്പുകൾ';

  @override
  String get navProfile => 'പ്രൊഫൈൽ';

  @override
  String get settingsTitle => 'ക്രമീകരണങ്ങൾ';

  @override
  String get settingsAppearance => 'രൂപഭംഗി';

  @override
  String get settingsTheme => 'തീം';

  @override
  String get themeSystem => 'സിസ്റ്റം അനുസരിച്ച്';

  @override
  String get themeLight => 'ലൈറ്റ്';

  @override
  String get themeDark => 'ഡാർക്ക്';

  @override
  String get settingsLanguage => 'ഭാഷ';

  @override
  String get languageSystem => 'സിസ്റ്റം അനുസരിച്ച്';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalayalam => 'മലയാളം';

  @override
  String get settingsLanguageTooltip => 'ഭാഷ മാറ്റുക';

  @override
  String get errorNetwork =>
      'സെർവറുമായി ബന്ധപ്പെടാനായില്ല. ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get errorSessionExpired =>
      'നിങ്ങളുടെ സെഷൻ കാലഹരണപ്പെട്ടു. തുടരാൻ വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get errorForbidden => 'ഇത് കാണാൻ നിങ്ങൾക്ക് അനുമതിയില്ല.';

  @override
  String get errorNotFound => 'ആ വിവരം കണ്ടെത്താനായില്ല.';

  @override
  String get errorBadRequest => 'ഈ അഭ്യർത്ഥന പൂർത്തിയാക്കാനായില്ല.';

  @override
  String get errorServer =>
      'സെർവറിൽ ഒരു പ്രശ്നമുണ്ടായി. അൽപ്പസമയം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get errorBadResponse =>
      'സെർവറിൽ നിന്ന് അപ്രതീക്ഷിതമായ മറുപടി ലഭിച്ചു. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get dateJustNow => 'ഇപ്പോൾ';

  @override
  String dateMinutesAgo(int count) {
    return '$count മിനിറ്റ് മുമ്പ്';
  }

  @override
  String dateHoursAgo(int count) {
    return '$count മണിക്കൂർ മുമ്പ്';
  }

  @override
  String get dateYesterday => 'ഇന്നലെ';

  @override
  String dateDaysAgo(int count) {
    return '$count ദിവസം മുമ്പ്';
  }

  @override
  String inrSpokenRupees(String amount) {
    return '$amount രൂപ';
  }

  @override
  String inrSpokenRupeesPaise(String rupees, int paise) {
    return '$rupees രൂപ $paise പൈസ';
  }

  @override
  String duesPendingMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മാസം ബാക്കി',
      one: '1 മാസം ബാക്കി',
    );
    return '$_temp0';
  }

  @override
  String get statusPaid => 'അടച്ചു';

  @override
  String get statusActive => 'സജീവം';

  @override
  String get statusCompleted => 'പൂർത്തിയായി';

  @override
  String get statusApproved => 'അംഗീകരിച്ചു';

  @override
  String get statusVerified => 'സ്ഥിരീകരിച്ചു';

  @override
  String get statusSuccess => 'വിജയകരം';

  @override
  String get statusPending => 'കാത്തിരിക്കുന്നു';

  @override
  String get statusProcessing => 'പ്രോസസ്സ് ചെയ്യുന്നു';

  @override
  String get statusInitiated => 'ആരംഭിച്ചു';

  @override
  String get statusPartial => 'ഭാഗികം';

  @override
  String get statusDue => 'അടയ്ക്കാനുണ്ട്';

  @override
  String get statusFailed => 'പരാജയപ്പെട്ടു';

  @override
  String get statusOverdue => 'കുടിശ്ശിക';

  @override
  String get statusInactive => 'നിഷ്ക്രിയം';

  @override
  String get statusCancelled => 'റദ്ദാക്കി';

  @override
  String get statusRejected => 'നിരസിച്ചു';

  @override
  String get statusInfo => 'വിവരം';

  @override
  String get statusDraft => 'ഡ്രാഫ്റ്റ്';

  @override
  String get statusScheduled => 'ഷെഡ്യൂൾ ചെയ്തു';

  @override
  String get statusUnknown => 'അറിയില്ല';

  @override
  String get notifChannelName => 'അറിയിപ്പുകളും പേയ്മെന്റുകളും';

  @override
  String get notifChannelDescription =>
      'കമ്മിറ്റി അറിയിപ്പുകൾ, മാസവരി ഓർമ്മപ്പെടുത്തലുകൾ, പേയ്മെന്റ് വിവരങ്ങൾ';

  @override
  String get notifNoticeTitle => 'അറിയിപ്പ്';

  @override
  String get routeNotFoundTitle => 'പേജ് കണ്ടെത്തിയില്ല';

  @override
  String get routeNotFoundHeading => 'ഈ പേജ് ലഭ്യമല്ല';

  @override
  String get routeNotFoundBody =>
      'നിങ്ങൾ തുറന്ന ലിങ്ക് പഴയതായിരിക്കാം. തിരികെ പോയി വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get settingsRowTitle => 'തീമും ഭാഷയും';

  @override
  String get errorNoFileSelected => 'ഫയൽ ഒന്നും തിരഞ്ഞെടുത്തിട്ടില്ല.';

  @override
  String get homeYourMahal => 'നിങ്ങളുടെ മഹൽ';

  @override
  String get homeLoadingMahal => 'നിങ്ങളുടെ മഹൽ ലോഡ് ചെയ്യുന്നു…';

  @override
  String dashboardRefreshFailed(String message) {
    return 'പുതുക്കാനായില്ല. $message';
  }

  @override
  String get homeLoadErrorTitle => 'നിങ്ങളുടെ വരി വിവരങ്ങൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get homeLoadErrorBody =>
      'ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get homeContribute => 'സംഭാവന';

  @override
  String get homeContributeCaption => 'സകാത്തും പൊതു ഫണ്ടും';

  @override
  String get homeReceipts => 'രസീതുകൾ';

  @override
  String get homeReceiptsCaption => 'മുൻ പേയ്മെന്റുകൾ എല്ലാം';

  @override
  String get homeNotices => 'അറിയിപ്പുകൾ';

  @override
  String get homeNoticesCaption => 'കമ്മിറ്റിയിൽ നിന്ന്';

  @override
  String get homeProfile => 'പ്രൊഫൈൽ';

  @override
  String get homeProfileCaption => 'വിവരങ്ങളും ക്രമീകരണങ്ങളും';

  @override
  String get homeOpenProfile => 'നിങ്ങളുടെ പ്രൊഫൈൽ തുറക്കുക';

  @override
  String get homeHelp => 'സഹായം';

  @override
  String get homeGreeting => 'അസ്സലാമു അലൈക്കും';

  @override
  String get homeMonthlyDuesLabel => 'മാസവരി';

  @override
  String get homeOutstandingDuesLabel => 'അടയ്ക്കാനുള്ള വരി';

  @override
  String get homeUpToDate => 'എല്ലാം അടച്ചു';

  @override
  String get homeActionRequired => 'അടയ്ക്കാനുണ്ട്';

  @override
  String get homeNoOutstandingSemantics => 'അടയ്ക്കാനുള്ള വരി ഇല്ല';

  @override
  String homeOutstandingSemantics(String amount) {
    return 'അടയ്ക്കാനുള്ള വരി $amount';
  }

  @override
  String homeAdvanceCredit(String amount) {
    return 'മുൻകൂർ തുക $amount';
  }

  @override
  String get homeAllDuesPaid => 'എല്ലാ മാസവരിയും പൂർണമായി അടച്ചു.';

  @override
  String homeAllDuesPaidUpTo(String month) {
    return '$month വരെയുള്ള എല്ലാ വരിയും അടച്ചു.';
  }

  @override
  String get homePendingDues => 'അടയ്ക്കാനുള്ള മാസവരി.';

  @override
  String homeMonthOverdueSemantics(String month) {
    return '$month, കുടിശ്ശിക';
  }

  @override
  String homeMonthDueNowSemantics(String month) {
    return '$month, ഇപ്പോൾ അടയ്ക്കേണ്ടത്';
  }

  @override
  String homePayAmount(String amount) {
    return '$amount അടയ്ക്കുക';
  }

  @override
  String get homeMakeContribution => 'സംഭാവന നൽകുക';

  @override
  String homeTileSemantics(String label, String caption) {
    return '$label. $caption';
  }

  @override
  String get homeLatestPayment => 'അവസാന പേയ്മെന്റ്';

  @override
  String get homeNoPaymentsYet => 'ഇതുവരെ പേയ്മെന്റുകളില്ല';

  @override
  String get homeNoPaymentsBody => 'പണം അടച്ചാൽ രസീതുകൾ ഇവിടെ കാണാം.';

  @override
  String get homePayDuesNow => 'ഇപ്പോൾ വരി അടയ്ക്കുക';

  @override
  String homeMonthsDues(String months) {
    return '$months വരി';
  }

  @override
  String get homeLastPaymentUnavailable => 'അവസാന പേയ്മെന്റ് തുക ലഭ്യമല്ല';

  @override
  String homeLastPaymentSemantics(String amount) {
    return 'അവസാന പേയ്മെന്റ് $amount';
  }

  @override
  String homePaidOn(String date) {
    return '$date-ന് അടച്ചു';
  }

  @override
  String get homeAutoPayOff => 'AutoPay ഓഫാണ്';

  @override
  String get homeAutoPayBody =>
      'ഒരു മാസവും മുടങ്ങില്ല. വരി സ്വയം അടയ്ക്കപ്പെടും.';

  @override
  String get homeAutoPaySetUp => 'സജ്ജമാക്കുക';

  @override
  String get alertsFilterAll => 'എല്ലാം';

  @override
  String get alertsFilterUnread => 'വായിക്കാത്തവ';

  @override
  String get alertsFilterPayment => 'പേയ്മെന്റ്';

  @override
  String get alertsFilterSystem => 'പൊതുവായവ';

  @override
  String get alertsUnreadSemantics => 'വായിച്ചിട്ടില്ല';

  @override
  String get alertsAlreadyRead => 'എല്ലാം ഇതിനകം വായിച്ചു';

  @override
  String get alertsMarkedAllRead =>
      'എല്ലാ അറിയിപ്പുകളും വായിച്ചതായി അടയാളപ്പെടുത്തി';

  @override
  String get alertsMarkReadFailed =>
      'അറിയിപ്പുകൾ വായിച്ചതായി അടയാളപ്പെടുത്താനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get alertsClearTitle => 'എല്ലാ അറിയിപ്പുകളും നീക്കണോ?';

  @override
  String get alertsClearMessage =>
      'ഇൻബോക്സിലെ എല്ലാ അറിയിപ്പുകളും നീക്കം ചെയ്യും. ഇത് തിരികെ എടുക്കാനാവില്ല.';

  @override
  String get alertsClearConfirm => 'എല്ലാം നീക്കുക';

  @override
  String get alertsCleared => 'എല്ലാ അറിയിപ്പുകളും നീക്കി';

  @override
  String get alertsClearFailed =>
      'അറിയിപ്പുകൾ നീക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String alertsClearedOne(String title) {
    return 'നീക്കി: $title';
  }

  @override
  String get alertsRemoveFailed => 'ആ അറിയിപ്പ് നീക്കാനായില്ല.';

  @override
  String get alertsLoadError => 'അറിയിപ്പുകൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get alertsTitle => 'അറിയിപ്പുകൾ';

  @override
  String get alertsEyebrow => 'കമ്മിറ്റിയിൽ നിന്ന്';

  @override
  String get alertsLoadingSubtitle => 'അറിയിപ്പുകൾ ലോഡ് ചെയ്യുന്നു…';

  @override
  String get alertsErrorSubtitle => 'അറിയിപ്പുകൾ ലോഡ് ചെയ്യാനായില്ല.';

  @override
  String get alertsCaughtUp => 'പുതിയ അറിയിപ്പുകളൊന്നുമില്ല.';

  @override
  String alertsUnreadCount(int count) {
    return 'വായിക്കാത്തത് $count';
  }

  @override
  String get alertsMarkAllRead => 'എല്ലാം വായിച്ചതായി അടയാളപ്പെടുത്തുക';

  @override
  String get alertsClearAllTooltip => 'എല്ലാ അറിയിപ്പുകളും നീക്കുക';

  @override
  String get alertsEmptyTitle => 'അറിയിപ്പുകളൊന്നുമില്ല';

  @override
  String get alertsEmptyFilteredTitle => 'ഇവിടെ ഒന്നുമില്ല';

  @override
  String get alertsEmptyBody =>
      'കമ്മിറ്റിയുടെ അറിയിപ്പുകളും വരി ഓർമ്മപ്പെടുത്തലുകളും ഇവിടെ കാണാം.';

  @override
  String get alertsEmptyFilteredBody =>
      'മറ്റൊരു ഫിൽട്ടർ നോക്കുക, അല്ലെങ്കിൽ പുതുക്കാൻ താഴേക്ക് വലിക്കുക.';

  @override
  String get alertsLoadingSemantics => 'അറിയിപ്പുകൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get alertNotice => 'അറിയിപ്പ്';

  @override
  String get alertTypePayment => 'പേയ്മെന്റ്';

  @override
  String get alertTypeDuesReminder => 'വരി ഓർമ്മപ്പെടുത്തൽ';

  @override
  String get alertTypeConfirmed => 'സ്ഥിരീകരിച്ചു';

  @override
  String get alertTypeImportant => 'പ്രധാനം';

  @override
  String get alertTypeAnnouncement => 'അറിയിപ്പ്';

  @override
  String get alertTypeNotice => 'അറിയിപ്പ്';

  @override
  String get alertNoDetails => 'കൂടുതൽ വിവരങ്ങളൊന്നും നൽകിയിട്ടില്ല.';

  @override
  String get alertWhyTitle => 'എന്തുകൊണ്ട് ഈ അറിയിപ്പ്';

  @override
  String get alertWhyBody =>
      'നിങ്ങളുടെ അക്കൗണ്ടിൽ ഇനിയും അടയ്ക്കാത്ത വരിയുണ്ട്.';

  @override
  String get receiptsFilterAll => 'എല്ലാം';

  @override
  String get receiptsFilterMonthly => 'മാസവരി';

  @override
  String get receiptsFilterContribution => 'സംഭാവന';

  @override
  String get receiptsLoadError => 'രസീതുകൾ ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get receiptsTitle => 'രസീതുകൾ';

  @override
  String get receiptsEyebrow => 'ചരിത്രം';

  @override
  String get receiptsSubtitle =>
      'നിങ്ങൾ നടത്തിയ എല്ലാ പേയ്മെന്റുകളും, ഓരോന്നിനും രസീതോടെ.';

  @override
  String get receiptsEmptyTitle => 'ഇതുവരെ രസീതുകളില്ല';

  @override
  String get receiptsEmptyMonthlyTitle => 'മാസവരി രസീതുകളില്ല';

  @override
  String get receiptsEmptyContributionTitle => 'സംഭാവന രസീതുകളില്ല';

  @override
  String get receiptsEmptyBody =>
      'വരി അടയ്ക്കുകയോ സംഭാവന നൽകുകയോ ചെയ്താൽ എല്ലാ രസീതുകളും ഇവിടെ കാണാം.';

  @override
  String get receiptsEmptyFilteredBody =>
      'മറ്റൊരു ഫിൽട്ടർ നോക്കുക, അല്ലെങ്കിൽ പുതുക്കാൻ താഴേക്ക് വലിക്കുക.';

  @override
  String get receiptsPayDues => 'വരി അടയ്ക്കുക';

  @override
  String get receiptsLoadingSemantics => 'രസീതുകൾ ലോഡ് ചെയ്യുന്നു';

  @override
  String get receiptMonthlyDues => 'മാസവരി';

  @override
  String get receiptMahalContribution => 'മഹൽ സംഭാവന';

  @override
  String get receiptMonthlyDuesLower => 'മാസവരി';

  @override
  String get receiptContribution => 'സംഭാവന';

  @override
  String receiptMethodOnline(String gateway) {
    return 'ഓൺലൈൻ ($gateway)';
  }

  @override
  String get receiptMethodCash => 'പണമായി';

  @override
  String get receiptStatusRefunded => 'തിരികെ നൽകി';

  @override
  String get receiptTitle => 'രസീത്';

  @override
  String get receiptPdfSavedNoViewer =>
      'രസീത് സേവ് ചെയ്തു. PDF തുറക്കാനുള്ള App ഇല്ല — അയയ്ക്കാൻ ഷെയർ ഉപയോഗിക്കുക.';

  @override
  String get receiptPdfFailed =>
      'രസീത് PDF ഉണ്ടാക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get receiptShareHeading => 'MahalFlow പേയ്മെന്റ് രസീത്';

  @override
  String receiptShareNumber(String number) {
    return 'രസീത് നമ്പർ: $number';
  }

  @override
  String receiptShareMember(String name) {
    return 'അംഗം: $name';
  }

  @override
  String receiptShareAmount(String amount) {
    return 'തുക: $amount';
  }

  @override
  String receiptShareFor(String title, String subtitle) {
    return 'എന്തിന്: $title ($subtitle)';
  }

  @override
  String receiptShareDate(String date) {
    return 'തീയതി: $date';
  }

  @override
  String receiptSharePaidVia(String method) {
    return 'അടച്ച രീതി: $method';
  }

  @override
  String receiptShareStatus(String status) {
    return 'നില: $status';
  }

  @override
  String receiptShareSubject(String number) {
    return 'രസീത് $number';
  }

  @override
  String get receiptShareFailed => 'ഷെയർ ചെയ്യാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get receiptDetailsCopied => 'രസീത് വിവരങ്ങൾ കോപ്പി ചെയ്തു';

  @override
  String get receiptVerifiedTitle => 'സ്ഥിരീകരിച്ച രേഖ';

  @override
  String get receiptVerifiedBody =>
      'MahalFlow വഴി നിങ്ങളുടെ മഹൽ നൽകിയത്. ധൈര്യമായി ഷെയർ ചെയ്യാം.';

  @override
  String receiptPaymentStatus(String status) {
    return 'പേയ്മെന്റ്: $status';
  }

  @override
  String get receiptNotConfirmedBody => 'ഇത് സ്ഥിരീകരിച്ച പേയ്മെന്റ് രസീതല്ല.';

  @override
  String get receiptCopyAsText => 'വിവരങ്ങൾ ടെക്സ്റ്റായി കോപ്പി ചെയ്യുക';

  @override
  String get receiptDownloadPdf => 'PDF ഡൗൺലോഡ് ചെയ്യുക';

  @override
  String get receiptPreparing => 'തയ്യാറാക്കുന്നു…';

  @override
  String get receiptShareReceipt => 'രസീത് ഷെയർ ചെയ്യുക';

  @override
  String get receiptPaymentSuccessful => 'പേയ്മെന്റ് വിജയിച്ചു';

  @override
  String get receiptNumberLabel => 'രസീത് നമ്പർ';

  @override
  String get receiptNumberCopied => 'രസീത് നമ്പർ കോപ്പി ചെയ്തു';

  @override
  String get receiptMemberLabel => 'അംഗം';

  @override
  String get receiptPaymentTypeLabel => 'പേയ്മെന്റ് തരം';

  @override
  String get receiptCoversLabel => 'മാസങ്ങൾ';

  @override
  String get receiptFundLabel => 'ഫണ്ട്';

  @override
  String get receiptPaidViaLabel => 'അടച്ച രീതി';

  @override
  String get receiptFooter =>
      'കമ്പ്യൂട്ടർ തയ്യാറാക്കിയ രസീത്. ഒപ്പ് ആവശ്യമില്ല.';

  @override
  String autopayRefreshFailed(String message) {
    return 'AutoPay പുതുക്കാനായില്ല. $message';
  }

  @override
  String get autopayFrequencyMonthly => 'മാസംതോറും';

  @override
  String get autopayFrequencyWeekly => 'ആഴ്ചതോറും';

  @override
  String get autopayFrequencyDaily => 'ദിവസവും';

  @override
  String get autopayFrequencyHourly => 'മണിക്കൂർതോറും';

  @override
  String get autopayFrequencyMinutely => 'മിനിറ്റുതോറും';

  @override
  String get autopayScheduleMinutely => 'ഓരോ മിനിറ്റിലും (ടെസ്റ്റ്)';

  @override
  String get autopayScheduleHourly => 'ഓരോ മണിക്കൂറിലും (ടെസ്റ്റ്)';

  @override
  String get autopayScheduleDaily => 'എല്ലാ ദിവസവും (ടെസ്റ്റ്)';

  @override
  String get autopayScheduleWeekly => 'എല്ലാ ആഴ്ചയും';

  @override
  String autopayScheduleMonthly(String day) {
    return 'എല്ലാ മാസവും $day-ാം തീയതി';
  }

  @override
  String get autopayConfirmTitle => 'AutoPay സ്ഥിരീകരിക്കുക';

  @override
  String get autopayConfirmSubtitle =>
      'ബാങ്ക് അംഗീകാരം ചോദിക്കുന്നതിന് മുമ്പ് പരിശോധിക്കുക';

  @override
  String get autopayAmountPerDebit => 'ഓരോ തവണയും പിടിക്കുന്ന തുക';

  @override
  String get autopayMaxPerDebit => 'ഒരു തവണ പരമാവധി';

  @override
  String get autopayWhen => 'എപ്പോൾ';

  @override
  String get autopayValidUntil => 'സാധുത വരെ';

  @override
  String get autopayAuthChargeNote =>
      'മാൻഡേറ്റ് രജിസ്റ്റർ ചെയ്യാൻ ബാങ്ക് ഒരു ചെറിയ ഒറ്റത്തവണ സ്ഥിരീകരണ തുക ഈടാക്കും (അടുത്ത സ്ക്രീനിൽ കാണിക്കും). പിന്നീടുള്ള ഒരു തുകയും മുകളിലെ പരമാവധി കവിയില്ല. എപ്പോൾ വേണമെങ്കിലും റദ്ദാക്കാം.';

  @override
  String get autopaySignInAgain =>
      'AutoPay സജ്ജമാക്കാൻ വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String get autopayStartFailed =>
      'AutoPay സജ്ജീകരണം തുടങ്ങാനായില്ല. പണമൊന്നും ഈടാക്കിയിട്ടില്ല — വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get autopayOpenMandateFailed =>
      'മാൻഡേറ്റ് സ്ക്രീൻ തുറക്കാനായില്ല. പണമൊന്നും ഈടാക്കിയിട്ടില്ല — വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get autopayCancelSetupTitle => 'AutoPay സജ്ജീകരണം റദ്ദാക്കണോ?';

  @override
  String get autopayTurnOffTitle => 'AutoPay ഓഫ് ചെയ്യണോ?';

  @override
  String get autopayCancelSetupMessage =>
      'ബാങ്കിന്റെ സ്ഥിരീകരണം കാത്തിരിക്കുന്ന മാൻഡേറ്റ് റദ്ദാകും. പിന്നീട് വീണ്ടും AutoPay സജ്ജമാക്കാം.';

  @override
  String get autopayTurnOffMessage =>
      'ഇനി മാസവരി തനിയെ പിടിക്കില്ല. ഓരോ മാസവും നിങ്ങൾ തന്നെ അടയ്ക്കേണ്ടിവരും.';

  @override
  String get autopayCancelSetupAction => 'സജ്ജീകരണം റദ്ദാക്കുക';

  @override
  String get autopayTurnOffAction => 'ഓഫ് ചെയ്യുക';

  @override
  String get autopayKeep => 'നിലനിർത്തുക';

  @override
  String get autopaySetupCancelled => 'AutoPay സജ്ജീകരണം റദ്ദാക്കി.';

  @override
  String get autopayTurnedOff => 'AutoPay ഓഫ് ചെയ്തു. ഇനി തുക പിടിക്കില്ല.';

  @override
  String get autopayCancelFailed =>
      'AutoPay റദ്ദാക്കാനായില്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get autopayBankApprovedPending =>
      'ബാങ്ക് മാൻഡേറ്റ് അംഗീകരിച്ചു. സജീവമാകാൻ കാത്തിരിക്കുന്നു.';

  @override
  String autopaySetupFailedReason(String reason) {
    return 'മാൻഡേറ്റ് സജ്ജീകരണം പരാജയപ്പെട്ടു: $reason';
  }

  @override
  String get autopaySetupCancelledNoCharge =>
      'മാൻഡേറ്റ് സജ്ജീകരണം റദ്ദാക്കി. പണമൊന്നും ഈടാക്കിയിട്ടില്ല.';

  @override
  String autopayErrorReason(String reason) {
    return 'AutoPay പിശക്: $reason';
  }

  @override
  String get autopayOnTitle => 'AutoPay ഓണാണ്';

  @override
  String get autopayOnSubtitle => 'നിങ്ങളുടെ മാസവരി തനിയെ അടയ്ക്കപ്പെടും';

  @override
  String autopayOnMessage(String amount, String schedule) {
    return 'നിങ്ങളുടെ മാൻഡേറ്റ് രജിസ്റ്റർ ചെയ്തു. $schedule $amount പിടിക്കും. ഓരോ തവണയും രസീത് ലഭിക്കും.';
  }

  @override
  String get autopayYourDues => 'നിങ്ങളുടെ മാസവരി';

  @override
  String get autopayFirstDebit => 'ആദ്യ പിടിക്കൽ';

  @override
  String get autopayMandateId => 'മാൻഡേറ്റ് ID';

  @override
  String get autopayTitle => 'AutoPay';

  @override
  String get autopayEyebrow => 'പേയ്മെന്റുകൾ';

  @override
  String get autopaySubtitle =>
      'ഒരു മാസവും മുടങ്ങില്ല. പ്രൊഫൈലിൽ നിന്ന് എപ്പോൾ വേണമെങ്കിലും റദ്ദാക്കാം.';

  @override
  String get autopayLoadingSemantics => 'AutoPay നില ലോഡ് ചെയ്യുന്നു';

  @override
  String get autopayLoadFailedTitle => 'AutoPay ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get autopayLoadFailedFallback =>
      'അൽപ്പസമയം കഴിഞ്ഞ് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get autopayWaitingBankTitle =>
      'ബാങ്കിന്റെ സ്ഥിരീകരണം കാത്തിരിക്കുന്നു';

  @override
  String get autopayWaitingBankMessage =>
      'ബാങ്ക് ഇതുവരെ മാൻഡേറ്റ് സ്ഥിരീകരിച്ചിട്ടില്ല. പുതുക്കാൻ താഴേക്ക് വലിക്കുക അല്ലെങ്കിൽ ‘നില പരിശോധിക്കുക’ അമർത്തുക. വീണ്ടും സജ്ജമാക്കരുത്.';

  @override
  String get autopayDuesNotSetTitle => 'മാസവരി തുക നിശ്ചയിച്ചിട്ടില്ല';

  @override
  String get autopayDuesNotSetMessage =>
      'നിങ്ങളുടെ മാസവരി തുക ഇതുവരെ രേഖപ്പെടുത്തിയിട്ടില്ല, അതിനാൽ AutoPay സജ്ജമാക്കാനാവില്ല. മഹൽ ഓഫീസുമായി ബന്ധപ്പെടുക.';

  @override
  String get autopayHowItWorksTitle => 'ഇത് എങ്ങനെ പ്രവർത്തിക്കുന്നു';

  @override
  String get autopayHowItWorksMessage =>
      'മാൻഡേറ്റ് ഒരിക്കൽ അംഗീകരിക്കാൻ ബാങ്ക് ആവശ്യപ്പെടും. അതിനുശേഷം ഓരോ തവണയും തുക തനിയെ പിടിക്കുകയും രസീത് ലഭിക്കുകയും ചെയ്യും.';

  @override
  String get autopayStatePendingActivation => 'സജീവമാകാൻ കാത്തിരിക്കുന്നു';

  @override
  String get autopayStateOff => 'ഓഫ്';

  @override
  String get autopayDebitTestCadence => 'പിടിക്കൽ (ടെസ്റ്റ് ഇടവേള)';

  @override
  String get autopayMonthlyDebit => 'പ്രതിമാസ തുക';

  @override
  String autopayDebitedBy(String schedule) {
    return 'UPI e-Mandate വഴി $schedule പിടിക്കും.';
  }

  @override
  String get autopayMandateDetails => 'മാൻഡേറ്റ് വിവരങ്ങൾ';

  @override
  String get autopayPaymentMethod => 'പേയ്മെന്റ് രീതി';

  @override
  String get autopayFrequency => 'ഇടവേള';

  @override
  String get autopayNextDebit => 'അടുത്ത പിടിക്കൽ';

  @override
  String get autopayLastDebit => 'അവസാന പിടിക്കൽ';

  @override
  String get autopayAuthorisation => 'സ്ഥിരീകരണം';

  @override
  String get autopaySmallOneTimeCharge => 'ചെറിയ ഒറ്റത്തവണ തുക';

  @override
  String get autopayTestFrequency => 'ടെസ്റ്റ് ഇടവേള (debug build മാത്രം)';

  @override
  String autopayFrequencySemantics(String frequency) {
    return 'ഇടവേള: $frequency';
  }

  @override
  String get autopayTurningOff => 'ഓഫ് ചെയ്യുന്നു…';

  @override
  String get autopayTurnOffButton => 'AutoPay ഓഫ് ചെയ്യുക';

  @override
  String get autopayCheckStatus => 'നില പരിശോധിക്കുക';

  @override
  String get autopaySettingUp => 'സജ്ജമാക്കുന്നു…';

  @override
  String get autopayNotNow => 'ഇപ്പോൾ വേണ്ട';

  @override
  String duesPayRefreshFailed(String message) {
    return 'പുതുക്കാനായില്ല. $message';
  }

  @override
  String get duesPaySignInAgain => 'മാസവരി അടയ്ക്കാൻ വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String duesPayHelpNote(String amount) {
    return 'നിങ്ങളുടെ മാസവരി മാസം $amount ആണ്. പഴയ മാസം മുതൽ ക്രമത്തിലാണ് അടയ്ക്കേണ്ടത്.';
  }

  @override
  String get duesPayTitle => 'മാസവരി';

  @override
  String get duesPayEyebrow => 'പേയ്മെന്റുകൾ';

  @override
  String get duesPaySubtitle => 'അടയ്ക്കേണ്ട മാസങ്ങൾ തിരഞ്ഞെടുക്കുക.';

  @override
  String get duesPayHelp => 'സഹായം';

  @override
  String get duesPayLoadFailedTitle => 'മാസവരി ലോഡ് ചെയ്യാനായില്ല';

  @override
  String get duesPayLoadFailedFallback =>
      'ഇന്റർനെറ്റ് കണക്ഷൻ പരിശോധിച്ച് വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get duesPayPeriodNotSetTitle => 'മാസവരി കാലയളവ് സജ്ജമാക്കിയിട്ടില്ല';

  @override
  String get duesPayPeriodNotSetMessage =>
      'ഏതൊക്കെ മാസങ്ങൾ അടച്ചെന്ന് മഹൽ ഇതുവരെ രേഖപ്പെടുത്തിയിട്ടില്ല, അതിനാൽ ഇപ്പോൾ ആപ്പിൽ മാസവരി അടയ്ക്കാനാവില്ല. ഇത് ശരിയാക്കാൻ ഓഫീസുമായി ബന്ധപ്പെടുക.';

  @override
  String get duesPayGetHelp => 'സഹായം നേടുക';

  @override
  String get duesPayUpToDateTitle => 'നിങ്ങളുടെ മാസവരി എല്ലാം അടച്ചു';

  @override
  String get duesPayUpToDateMessage =>
      'അടയ്ക്കാനുള്ള മാസങ്ങളില്ല. മുൻകൂറായി അടയ്ക്കാൻ താഴെ കാണുക.';

  @override
  String get duesPayDueNowHeader => 'ഇപ്പോൾ അടയ്ക്കേണ്ടത്';

  @override
  String get duesPayPayAheadHeader => 'മുൻകൂർ അടയ്ക്കുക';

  @override
  String get duesPayContributeTitle => 'സംഭാവന നൽകുക';

  @override
  String get duesPayContributeMessage =>
      'സകാത്ത്, മസ്ജിദ് അല്ലെങ്കിൽ പൊതു ഫണ്ട്.';

  @override
  String get duesPayOpen => 'തുറക്കുക';

  @override
  String duesPayMonthsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മാസം തിരഞ്ഞെടുത്തു',
      one: '1 മാസം തിരഞ്ഞെടുത്തു',
    );
    return '$_temp0';
  }

  @override
  String get duesPayNoFee => 'അധിക ചാർജ് ഇല്ല';

  @override
  String get duesPayProcessing => 'നടക്കുന്നു…';

  @override
  String get duesPayContinueToPay => 'അടയ്ക്കാൻ തുടരുക';

  @override
  String duesPayPayAmount(String amount) {
    return '$amount അടയ്ക്കുക';
  }

  @override
  String get duesPayTotalSelected => 'തിരഞ്ഞെടുത്ത ആകെ തുക';

  @override
  String duesPayMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count മാസം',
      one: '1 മാസം',
    );
    return '$_temp0';
  }

  @override
  String get duesPayTotalUnavailableSemantics => 'ആകെ തുക ലഭ്യമല്ല';

  @override
  String duesPayTotalSemantics(String amount) {
    return 'ആകെ $amount';
  }

  @override
  String get duesPaySelectAtLeastOne =>
      'തുടരാൻ താഴെ ഒരു മാസമെങ്കിലും തിരഞ്ഞെടുക്കുക.';

  @override
  String duesPayPerMonth(String amount) {
    return 'മാസം $amount';
  }

  @override
  String get duesPayExactAmountNote =>
      'കൃത്യമായ തുക പേയ്മെന്റ് സ്ക്രീനിൽ കാണിക്കും.';

  @override
  String get duesPaySelectAll => 'എല്ലാം';

  @override
  String get duesPaySelectAllSemantics =>
      'അടയ്ക്കാനുള്ള എല്ലാ മാസങ്ങളും തിരഞ്ഞെടുക്കുക';

  @override
  String get duesPayStatusDueNow => 'ഇപ്പോൾ അടയ്ക്കണം';

  @override
  String get duesPayStatusUpcoming => 'വരാനിരിക്കുന്നത്';

  @override
  String get duesPayLoadingSemantics => 'മാസവരി ലോഡ് ചെയ്യുന്നു';

  @override
  String get payuStartFailed =>
      'പേയ്മെന്റ് തുടങ്ങാനായില്ല. പണമൊന്നും എടുത്തിട്ടില്ല — വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get payuOpenFailed =>
      'പേയ്മെന്റ് സ്ക്രീൻ തുറക്കാനായില്ല. പണമൊന്നും എടുത്തിട്ടില്ല — വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get payuCouldNotComplete => 'പേയ്മെന്റ് പൂർത്തിയാക്കാനായില്ല.';

  @override
  String get contributionFundZakat => 'സകാത്ത് ഫണ്ട്';

  @override
  String get contributionFundZakatBlurb =>
      'നിർബന്ധ ദാനം, കമ്മിറ്റി വിതരണം ചെയ്യുന്നു';

  @override
  String get contributionFundGeneral => 'പൊതു ഫണ്ട്';

  @override
  String get contributionFundGeneralBlurb => 'മഹലിന്റെ ദൈനംദിന നടത്തിപ്പിന്';

  @override
  String get contributionFundMasjid => 'മസ്ജിദ് നവീകരണം';

  @override
  String get contributionFundMasjidBlurb =>
      'നിർമ്മാണ പ്രവൃത്തികളും അറ്റകുറ്റപ്പണികളും';

  @override
  String get contributionFundEducation => 'വിദ്യാഭ്യാസ സഹായം';

  @override
  String get contributionFundEducationBlurb =>
      'മദ്രസയ്ക്കും വിദ്യാർത്ഥികൾക്കും സഹായം';

  @override
  String get contributionFundMedical => 'ചികിത്സാ സഹായം';

  @override
  String get contributionFundMedicalBlurb =>
      'ആവശ്യമുള്ള കുടുംബങ്ങൾക്ക് അടിയന്തര സഹായം';

  @override
  String contributionMinError(String amount) {
    return 'ഏറ്റവും കുറഞ്ഞ സംഭാവന $amount ആണ്';
  }

  @override
  String contributionMaxError(String amount) {
    return 'ആപ്പിൽ പരമാവധി $amount ആണ്. കൂടുതൽ തുകയ്ക്ക് ഓഫീസുമായി ബന്ധപ്പെടുക.';
  }

  @override
  String get contributionSignInAgain => 'സംഭാവന നൽകാൻ വീണ്ടും സൈൻ ഇൻ ചെയ്യുക.';

  @override
  String contributionConfirmTitle(String amount) {
    return '$amount നൽകണോ?';
  }

  @override
  String contributionConfirmMessage(String amount, String fund) {
    return '$fund-ലേക്ക് $amount സംഭാവന നൽകാൻ പോകുന്നു. തുടരുന്നതിന് മുമ്പ് തുക പരിശോധിക്കുക.';
  }

  @override
  String get contributionTitle => 'സംഭാവന';

  @override
  String get contributionEyebrow => 'നൽകുക';

  @override
  String get contributionSubtitle => 'മാസവരിക്ക് പുറമേ മഹലിനെ പിന്തുണയ്ക്കുക.';

  @override
  String get contributionWhereTitle => 'ഏത് ഫണ്ടിലേക്ക്?';

  @override
  String get contributionNoteLabel => 'കുറിപ്പ് (ഐച്ഛികം)';

  @override
  String get contributionNoteHint =>
      'ഉദാ: കുടുംബത്തിന്റെ ഓർമ്മയ്ക്ക്, പെരുന്നാൾ ദാനം';

  @override
  String contributionGiveAmount(String amount) {
    return '$amount നൽകുക';
  }

  @override
  String get contributionEnterAmount => 'തുക നൽകുക';

  @override
  String get contributionAmountLabel => 'സംഭാവന തുക';

  @override
  String get contributionAmountSemantics => 'സംഭാവന തുക (രൂപയിൽ)';

  @override
  String contributionRange(String min, String max) {
    return '$min മുതൽ $max വരെ';
  }

  @override
  String get payResultAmountLabel => 'തുക';

  @override
  String get payResultCancelledTitle => 'പേയ്മെന്റ് റദ്ദാക്കി';

  @override
  String get payResultFailedTitle => 'പേയ്മെന്റ് പരാജയപ്പെട്ടു';

  @override
  String get payResultCancelledMessage =>
      'പണം അടയ്ക്കുന്നതിന് മുമ്പ് പേയ്മെന്റ് സ്ക്രീൻ വിട്ടു. പണമൊന്നും എടുത്തിട്ടില്ല.';

  @override
  String get payResultFailedMessage =>
      'പേയ്മെന്റ് നടന്നില്ല. ബാങ്കിൽ നിന്ന് പണം പോയതായി കാണുന്നുണ്ടെങ്കിൽ അത് തനിയെ തിരികെ വരും. വീണ്ടും ശ്രമിക്കാം.';

  @override
  String get payResultBackHome => 'ഹോമിലേക്ക് മടങ്ങുക';

  @override
  String get payResultReason => 'കാരണം';

  @override
  String get payResultFor => 'ഏതിന്';

  @override
  String get payResultFund => 'ഫണ്ട്';

  @override
  String get payResultAttempted => 'ശ്രമിച്ചത്';

  @override
  String get payResultAmountDebited => 'പോയ തുക';

  @override
  String get payResultNone => 'ഒന്നുമില്ല';

  @override
  String get payResultPendingTitle => 'പേയ്മെന്റ് തീർപ്പാകാനുണ്ട്';

  @override
  String get payResultPendingMessageDues =>
      'ബാങ്ക് ഇത് ഇപ്പോഴും സ്ഥിരീകരിക്കുകയാണ്. വീണ്ടും അടയ്ക്കരുത് — തീർപ്പായാലുടൻ നിങ്ങളുടെ മാസവരി പുതുക്കും.';

  @override
  String get payResultPendingMessageContribution =>
      'ബാങ്ക് ഇത് ഇപ്പോഴും സ്ഥിരീകരിക്കുകയാണ്. വീണ്ടും അടയ്ക്കരുത് — തീർപ്പായാലുടൻ നിങ്ങളുടെ രസീതുകൾ പുതുക്കും.';

  @override
  String get payResultCheckAgain => 'വീണ്ടും പരിശോധിക്കുക';

  @override
  String get payResultViewReceipts => 'രസീതുകൾ കാണുക';

  @override
  String get payResultCovers => 'മാസങ്ങൾ';

  @override
  String get payResultStarted => 'തുടങ്ങിയത്';

  @override
  String get payResultLastChecked => 'അവസാനം പരിശോധിച്ചത്';

  @override
  String get payResultChecking => 'പരിശോധിക്കുന്നു…';

  @override
  String get payResultCheckFailedTitle => 'നില പരിശോധിക്കാനായില്ല';

  @override
  String get payResultNextTitle => 'ഇനി എന്ത്';

  @override
  String get payResultNextMessage =>
      'മിക്ക പേയ്മെന്റുകളും കുറച്ച് മിനിറ്റിനുള്ളിൽ തീർപ്പാകും. അക്കൗണ്ടിൽ നിന്ന് പണം പോയിട്ടും ഇത് തീർപ്പായില്ലെങ്കിൽ ബാങ്ക് അത് തിരികെ നൽകും, അല്ലെങ്കിൽ ഓഫീസിന് രസീത് പട്ടികയിൽ നിന്ന് സ്ഥിരീകരിക്കാം.';

  @override
  String get payResultSuccessTitle => 'പേയ്മെന്റ് വിജയിച്ചു';

  @override
  String get payResultThankYou => 'നന്ദി';

  @override
  String get payResultDuesClearedMessage =>
      'നിങ്ങളുടെ മാസവരി അടച്ചു. നിങ്ങളുടെ പേരിൽ രസീത് നൽകിയിട്ടുണ്ട്.';

  @override
  String get payResultContributionReceivedMessage =>
      'നിങ്ങളുടെ സംഭാവന ലഭിച്ചു. നിങ്ങളുടെ പേരിൽ രസീത് നൽകിയിട്ടുണ്ട്.';

  @override
  String get payResultViewReceipt => 'രസീത് കാണുക';

  @override
  String get payResultPaidOn => 'അടച്ച തീയതി';

  @override
  String get payResultReceiptNumber => 'രസീത് നമ്പർ';
}
