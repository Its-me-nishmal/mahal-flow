// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get adminCommitteeEyebrow => 'Committee';

  @override
  String get adminMenu => 'Menu';

  @override
  String get adminTryAgain => 'Try again';

  @override
  String get adminViewAll => 'View all';

  @override
  String get adminAddMember => 'Add member';

  @override
  String get adminRecordPayment => 'Record payment';

  @override
  String get adminPendingApprovals => 'Pending approvals';

  @override
  String get adminBroadcastNotice => 'Broadcast a notice';

  @override
  String get adminBulkImport => 'Bulk import';

  @override
  String get adminReceiptAction => 'Receipt';

  @override
  String adminMemberRegistered(String name) {
    return '$name was registered.';
  }

  @override
  String get adminFullName => 'Full name';

  @override
  String get adminMobileNumber => 'Mobile number';

  @override
  String get adminMonthlyDuesRupees => 'Monthly dues (₹)';

  @override
  String get adminPhoneInvalid => 'Enter a 10-digit mobile number';

  @override
  String get adminEditMember => 'Edit member';

  @override
  String get adminNavDashboard => 'Dashboard';

  @override
  String get adminNavMembers => 'Members';

  @override
  String get adminNavReports => 'Reports';

  @override
  String get adminNavLogs => 'Logs';

  @override
  String get adminFormatStatusActive => 'Active';

  @override
  String get adminFormatStatusGrace => 'Grace period';

  @override
  String get adminFormatStatusAwaiting => 'Awaiting approval';

  @override
  String get adminFormatStatusSuspended => 'Suspended';

  @override
  String get adminFormatStatusInactive => 'Inactive';

  @override
  String get adminFormatStatusRejected => 'Rejected';

  @override
  String adminFormatMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get adminFormatMonthlyDues => 'Monthly dues';

  @override
  String get adminFormatContribution => 'Contribution';

  @override
  String get adminFormatPayment => 'Payment';

  @override
  String get adminDashSubscriptionActive => 'Subscription active';

  @override
  String get adminDashSubscriptionUnknown => 'Subscription —';

  @override
  String adminDashSubscriptionStatus(String status) {
    return 'Subscription: $status';
  }

  @override
  String get adminDashLoadingCollection => 'Loading collection summary';

  @override
  String adminDashOutstandingAcrossMahal(String amount) {
    return '$amount still outstanding across the Mahal.';
  }

  @override
  String get adminDashCollectionRate => 'Collection rate';

  @override
  String adminDashPaidOfTotal(int paid, int total, int pct) {
    return '$paid of $total members · $pct%';
  }

  @override
  String adminDashPercentValue(int pct) {
    return '$pct percent';
  }

  @override
  String get adminDashPendingDues => 'Pending dues';

  @override
  String get adminDashMembersPaid => 'Members paid';

  @override
  String adminDashOfHouseholds(int total) {
    return 'of $total households';
  }

  @override
  String get adminDashMembersPending => 'Members pending';

  @override
  String get adminDashNeedReminder => 'need a reminder';

  @override
  String get adminDashOverview => 'Overview';

  @override
  String get adminDashLoadingOverview => 'Loading overview';

  @override
  String get adminDashTransactionsError => 'Couldn\'t load transactions';

  @override
  String get adminDashLoadingTransactions => 'Loading transactions';

  @override
  String get adminDashNoTransactions => 'No transactions yet';

  @override
  String get adminDashNoTransactionsBody =>
      'Payments appear here as members pay or you record cash.';

  @override
  String get adminDashBroadcastBody =>
      'Send an announcement or a dues reminder to every member, only those with pending dues, or family heads.';

  @override
  String get adminDashComposeNotice => 'Compose notice';

  @override
  String get adminDashTitle => 'Dashboard';

  @override
  String get adminDashLiveLedger => 'Live ledger';

  @override
  String adminDashMahalLiveLedger(String mahal) {
    return '$mahal · live ledger';
  }

  @override
  String get adminDashLoadError => 'Couldn\'t load the dashboard';

  @override
  String get adminDashRecentTransactions => 'Recent transactions';

  @override
  String adminDashPendingApprovalsWaiting(int count) {
    return 'Pending approvals · $count waiting';
  }

  @override
  String adminDashRecordedFor(String amount, String name) {
    return '$amount recorded for $name';
  }

  @override
  String get adminDashTheMember => 'the member';

  @override
  String get adminDashNoticeSent => 'Notice sent to members.';

  @override
  String get drawerFinancialReports => 'Financial reports';

  @override
  String get drawerPaymentGateways => 'Payment gateways';

  @override
  String get drawerAuditLog => 'Audit log';

  @override
  String get drawerSwitchToMember => 'Switch to member view';

  @override
  String get drawerSignOut => 'Sign out';

  @override
  String get drawerSignOutTitle => 'Sign out?';

  @override
  String get drawerSignOutMessage =>
      'You will need to verify your phone number again to open the committee portal.';

  @override
  String get drawerCommitteePortal => 'Committee portal';

  @override
  String drawerCommitteePortalReg(String reg) {
    return 'Committee portal · $reg';
  }

  @override
  String drawerBadgeWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get membersTitle => 'Members';

  @override
  String get membersEyebrow => 'Directory';

  @override
  String get membersFilterAll => 'All';

  @override
  String get membersFilterActive => 'Active';

  @override
  String get membersFilterGrace => 'Grace Period';

  @override
  String get membersFilterSuspended => 'Suspended';

  @override
  String get membersFilterPending => 'Pending';

  @override
  String get membersLoadingDirectory => 'Loading the directory…';

  @override
  String get membersDirectoryUnavailable => 'Directory unavailable';

  @override
  String membersShowingOf(int shown, int total) {
    return 'Showing $shown of $total households';
  }

  @override
  String membersMatchesLoaded(int shown, int loaded, int total) {
    return '$shown matches in $loaded of $total loaded';
  }

  @override
  String membersMatchCount(int shown, int total) {
    return '$shown of $total households match';
  }

  @override
  String get membersSearchHint => 'Search name, phone, house or code…';

  @override
  String get membersLoadError => 'Couldn\'t load members';

  @override
  String get membersLoadMoreError => 'Couldn\'t load more members';

  @override
  String membersNoMatchesYet(int loaded) {
    return 'No matches in the $loaded loaded so far — searching the rest…';
  }

  @override
  String membersAllLoaded(int total) {
    return 'All $total households loaded';
  }

  @override
  String membersDuesPerMonth(String amount) {
    return '$amount/mo';
  }

  @override
  String get membersEmptyTitle => 'No members yet';

  @override
  String get membersEmptyBody =>
      'Register households one by one or import a spreadsheet.';

  @override
  String get membersNotFound => 'No members found';

  @override
  String membersNothingMatches(String query) {
    return 'Nothing matches \'$query\'.';
  }

  @override
  String membersNoneInStatus(String status) {
    return 'No households are in \'$status\' status.';
  }

  @override
  String get membersShowAll => 'Show all';

  @override
  String get membersLoading => 'Loading members';

  @override
  String get addMemberTitle => 'Register a member';

  @override
  String get addMemberSubtitle => 'Adds a household to the Mahal directory';

  @override
  String get addMemberNameRequired => 'Enter the member\'s full name';

  @override
  String get addMemberPhoneRequired => 'Enter a phone number';

  @override
  String get addMemberDuesInvalid =>
      'Enter the monthly dues in whole rupees (at least ₹1)';

  @override
  String get addMemberNameHint => 'e.g. Abdul Kareem';

  @override
  String get addMemberHouseLabel => 'House name (optional)';

  @override
  String get addMemberHouseHint => 'e.g. Darussalam';

  @override
  String get addMemberDuesHint => 'As agreed by the committee';

  @override
  String get addMemberError => 'Couldn\'t register this member';

  @override
  String get addMemberSubmit => 'Register member';

  @override
  String get memberDetailsPaid => 'Paid';

  @override
  String get memberDetailsDue => 'Due';

  @override
  String get memberDetailsOverdue => 'Overdue';

  @override
  String memberDetailsRecorded(String amount) {
    return '$amount recorded';
  }

  @override
  String get memberDetailsNoValidPhone =>
      'This member has no valid mobile number on record.';

  @override
  String get memberDetailsReminderNameFallback => 'member';

  @override
  String get memberDetailsReminderMahalFallback => 'the Mahal committee';

  @override
  String memberDetailsReminderWithAmount(
      String name, String mahal, String amount) {
    return 'Assalamu alaikum $name, this is a reminder from $mahal that your monthly dues are pending. Pending amount: $amount. You can pay in the MahalFlow app. Thank you.';
  }

  @override
  String memberDetailsReminderNoAmount(String name, String mahal) {
    return 'Assalamu alaikum $name, this is a reminder from $mahal that your monthly dues are pending. You can pay in the MahalFlow app. Thank you.';
  }

  @override
  String get memberDetailsReminderTitle => 'Send a dues reminder';

  @override
  String get memberDetailsReminderSubtitle =>
      'Opens your messaging app with the text filled in';

  @override
  String memberDetailsReminderTo(String phone) {
    return 'To $phone. Nothing is sent until you press send in the other app.';
  }

  @override
  String get memberDetailsOpenWhatsApp => 'Open WhatsApp';

  @override
  String get memberDetailsOpenSms => 'Open SMS';

  @override
  String get memberDetailsWhatsAppFailed =>
      'Couldn\'t open WhatsApp on this phone.';

  @override
  String get memberDetailsSmsFailed =>
      'Couldn\'t open the SMS app on this phone.';

  @override
  String get memberDetailsSendReminderTooltip => 'Send dues reminder';

  @override
  String get memberDetailsNoPhone => 'No phone on record';

  @override
  String memberDetailsMemberCode(String code) {
    return 'Member code $code';
  }

  @override
  String memberDetailsIdLabel(String id) {
    return 'ID $id';
  }

  @override
  String get memberDetailsIncompleteTitle => 'This member record is incomplete';

  @override
  String get memberDetailsIncompleteBody =>
      'It has no member ID, so its history cannot be loaded and no payment can be recorded. Go back and open the member again from the directory.';

  @override
  String get memberDetailsBackToMembers => 'Back to members';

  @override
  String get memberDetailsSinceJoining => 'Since joining';

  @override
  String get memberDetailsLastSixMonths => 'Last six months';

  @override
  String get memberDetailsMonthlyDuesCaps => 'MONTHLY DUES';

  @override
  String get memberDetailsLoadingHistory => 'Loading payment history…';

  @override
  String get memberDetailsHistoryUnavailable => 'Payment history unavailable.';

  @override
  String get memberDetailsNoDuesMonths => 'No dues months yet.';

  @override
  String get memberDetailsAllPaid => 'Paid every month shown below.';

  @override
  String memberDetailsUnpaidCount(int unpaid, int total) {
    return '$unpaid of $total recent months unpaid.';
  }

  @override
  String get memberDetailsOutstanding => 'Outstanding';

  @override
  String get memberDetailsPaidUpTo => 'Paid up to';

  @override
  String get memberDetailsHouse => 'House';

  @override
  String get memberDetailsNotRecorded => 'Not recorded';

  @override
  String get memberDetailsMemberSince => 'Member since';

  @override
  String get memberDetailsLoadingDues => 'Loading dues history';

  @override
  String get memberDetailsDuesError => 'Couldn\'t load dues history';

  @override
  String get memberDetailsNoDuesTitle => 'No dues yet';

  @override
  String get memberDetailsNoDuesBody =>
      'Dues start from the month the member joined.';

  @override
  String memberDetailsReceiptNumber(String number) {
    return 'Receipt $number';
  }

  @override
  String get memberDetailsOpenReceipt => 'Open receipt';

  @override
  String get editMemberNameRequired => 'A name is required';

  @override
  String get editMemberPhoneRequired => 'A phone number is required';

  @override
  String get editMemberDuesInvalid => 'Monthly dues must be at least ₹1';

  @override
  String editMemberSaveFailed(String reason) {
    return 'Couldn\'t save the changes. $reason';
  }

  @override
  String editMemberSuspendFailed(String reason) {
    return 'Couldn\'t suspend this member. $reason';
  }

  @override
  String editMemberReactivateFailed(String reason) {
    return 'Couldn\'t reactivate this member. $reason';
  }

  @override
  String get editMemberUpdated => 'Member details updated.';

  @override
  String get editMemberSuspendTitle => 'Suspend this member?';

  @override
  String editMemberSuspendMessage(String name) {
    return 'Dues collection for $name will be put on hold until you reactivate them. Their history is kept.';
  }

  @override
  String get editMemberSuspend => 'Suspend';

  @override
  String get editMemberReactivateTitle => 'Reactivate this member?';

  @override
  String editMemberReactivateMessage(String name) {
    return '$name becomes active again and dues collection resumes.';
  }

  @override
  String get editMemberReactivate => 'Reactivate';

  @override
  String get editMemberNowSuspended => 'This member is now suspended.';

  @override
  String get editMemberActiveAgain => 'This member is active again.';

  @override
  String get editMemberDiscardTitle => 'Discard changes?';

  @override
  String get editMemberDiscardMessage =>
      'Your edits to this member have not been saved.';

  @override
  String get editMemberDiscard => 'Discard';

  @override
  String get editMemberKeepEditing => 'Keep editing';

  @override
  String get editMemberSubtitle =>
      'Changes take effect for the next dues cycle.';

  @override
  String get editMemberHousehold => 'Household';

  @override
  String get editMemberHouseLabel => 'House or family name';

  @override
  String get editMemberMembership => 'Membership';

  @override
  String get editMemberDuesHelper =>
      'Change only when the committee agreed a new amount.';

  @override
  String get editMemberStatusLabel => 'Membership status';

  @override
  String get editMemberReversibleTitle => 'Suspending is reversible';

  @override
  String get editMemberReversibleBody =>
      'A suspended household keeps its history and can be reactivated from this screen.';

  @override
  String get editMemberSaveChanges => 'Save changes';

  @override
  String get editMemberReactivateMember => 'Reactivate member';

  @override
  String get editMemberSuspendMember => 'Suspend member';

  @override
  String approvalsApproved(String name) {
    return '$name approved.';
  }

  @override
  String get approvalsViewMember => 'View member';

  @override
  String approvalsApproveFailed(String reason) {
    return 'Couldn\'t approve. $reason';
  }

  @override
  String approvalsRejectFailed(String reason) {
    return 'Couldn\'t reject. $reason';
  }

  @override
  String get approvalsThisPerson => 'this person';

  @override
  String get approvalsRejectTitle => 'Reject this request?';

  @override
  String approvalsRejectMessage(String name) {
    return '$name will not be added to the Mahal and cannot sign in. You can undo this for 10 minutes.';
  }

  @override
  String get approvalsRejectRequest => 'Reject request';

  @override
  String approvalsRejected(String name) {
    return 'Request from $name rejected.';
  }

  @override
  String get approvalsSubtitleDefault =>
      'New members waiting to join your Mahal.';

  @override
  String get approvalsSubtitleNone => 'Nobody is waiting right now.';

  @override
  String approvalsSubtitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people are waiting to join.',
      one: '1 person is waiting to join.',
    );
    return '$_temp0';
  }

  @override
  String get approvalsLoading => 'Loading requests';

  @override
  String get approvalsLoadError => 'Couldn\'t load requests';

  @override
  String get approvalsEmptyTitle => 'No pending requests';

  @override
  String get approvalsEmptyBody =>
      'Everyone who asked to join has been reviewed.';

  @override
  String approvalsRequested(String when) {
    return 'Requested $when';
  }

  @override
  String get approvalsNoId =>
      'This request has no member ID and cannot be actioned here.';

  @override
  String get approvalsReject => 'Reject';

  @override
  String get approvalsApprove => 'Approve';

  @override
  String get auditFilterAll => 'All';

  @override
  String get auditFilterPayment => 'Payment';

  @override
  String get auditFilterMember => 'Member';

  @override
  String get auditFilterAlerts => 'Alerts';

  @override
  String get auditFilterSystem => 'System';

  @override
  String get auditDateRangeHelp => 'Show entries between';

  @override
  String get auditSubtitleLoading => 'Loading the log…';

  @override
  String get auditSubtitleUnavailable => 'Log unavailable';

  @override
  String auditSubtitleShowing(int shown, int total) {
    return 'Showing $shown of $total actions';
  }

  @override
  String auditSubtitleMatchesLoaded(int count, int loaded, int total) {
    return '$count matches in $loaded of $total loaded';
  }

  @override
  String auditSubtitleMatching(int count) {
    return '$count matching actions';
  }

  @override
  String get auditTitle => 'Audit log';

  @override
  String get auditEyebrow => 'Committee';

  @override
  String get auditFilterByDate => 'Filter by date';

  @override
  String get auditClearDateFilter => 'Clear date filter';

  @override
  String get auditSearchHint => 'Search action, actor, details or ID…';

  @override
  String get auditLoadError => 'Couldn\'t load the audit log';

  @override
  String get auditLoadOlderError => 'Couldn\'t load older entries';

  @override
  String get auditTryAgain => 'Try again';

  @override
  String get auditEndOfRange => 'End of the selected dates';

  @override
  String get auditStartOfLog => 'Start of the log';

  @override
  String get auditSystemAction => 'System action';

  @override
  String get auditLogEntry => 'Log entry';

  @override
  String get auditDetailAction => 'Action';

  @override
  String get auditDetailBy => 'By';

  @override
  String get auditDetailRecord => 'Record';

  @override
  String get auditRecordIdCopied => 'Record ID copied';

  @override
  String get auditDetailIp => 'IP address';

  @override
  String get auditDetailsHeading => 'DETAILS';

  @override
  String auditBy(String actor) {
    return 'By $actor';
  }

  @override
  String get auditEmptyTitle => 'No entries yet';

  @override
  String get auditEmptyDesc =>
      'Actions by the committee and the system appear here.';

  @override
  String get auditNoMatchTitle => 'No matching entries';

  @override
  String auditNoMatchQuery(String query) {
    return 'Nothing matches \'$query\'.';
  }

  @override
  String get auditNoMatchFilters => 'Nothing matches these filters.';

  @override
  String get auditClearFilters => 'Clear filters';

  @override
  String get auditLoadingSemantics => 'Loading the audit log';

  @override
  String get reportsFilterAll => 'All';

  @override
  String get reportsFilterDues => 'Dues';

  @override
  String get reportsFilterContribution => 'Contribution';

  @override
  String get reportsAllTime => 'All time';

  @override
  String get reportsAllTypes => 'All types';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsEyebrow => 'Finance';

  @override
  String reportsShareSubject(String mahal, String period) {
    return '$mahal statement — $period';
  }

  @override
  String reportsExportError(String error) {
    return 'Couldn\'t create the statement. $error';
  }

  @override
  String get reportsLoadError => 'Couldn\'t load reports';

  @override
  String get reportsPeriod => 'Period';

  @override
  String get reportsPreparing => 'Preparing statement…';

  @override
  String get reportsExport => 'Export statement (PDF)';

  @override
  String get reportsMonthByMonth => 'Month by month';

  @override
  String get reportsTransactions => 'Transactions';

  @override
  String get reportsTotalCollected => 'TOTAL COLLECTED';

  @override
  String get reportsAllTimeAllTypes => 'All time · all types';

  @override
  String get reportsTotalsError => 'Couldn\'t load totals';

  @override
  String get reportsTryAgain => 'Try again';

  @override
  String get reportsLoadingTotals => 'Loading totals';

  @override
  String get reportsDues => 'Dues';

  @override
  String get reportsContributions => 'Contributions';

  @override
  String get reportsTransactionsError => 'Couldn\'t load transactions';

  @override
  String get reportsLoadingPeriod => 'Loading period totals';

  @override
  String reportsSuccessfulPayments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count successful payments',
      one: '1 successful payment',
    );
    return '$_temp0';
  }

  @override
  String reportsBasedOnRecent(int count) {
    return 'Based on the $count most recent transactions.';
  }

  @override
  String get reportsLoadingBreakdown => 'Loading breakdown';

  @override
  String get reportsNoPayments => 'No payments';

  @override
  String get reportsNoPaymentsDesc =>
      'No successful payments match this period and type.';

  @override
  String reportsShowingOf(int shown, int total) {
    return 'Showing $shown of $total. The PDF statement lists all of them.';
  }

  @override
  String reportsPaymentsRecorded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments recorded',
      one: '1 payment recorded',
    );
    return '$_temp0';
  }

  @override
  String get importStepChoose => 'Choose';

  @override
  String get importStepValidate => 'Validate';

  @override
  String get importStepReview => 'Review';

  @override
  String get importStepDone => 'Done';

  @override
  String get importErrorExtension =>
      'Choose an .xlsx or .csv file. Save older .xls files as .xlsx first.';

  @override
  String get importErrorEmpty => 'That file is empty.';

  @override
  String importErrorPicker(String error) {
    return 'Couldn\'t open the file picker. $error';
  }

  @override
  String get importTemplateSubject => 'MahalFlow member import template';

  @override
  String importTemplateError(String error) {
    return 'Couldn\'t create the template. $error';
  }

  @override
  String get importTitle => 'Import members';

  @override
  String importStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get importSubtitle => 'Bring a whole directory in from a spreadsheet.';

  @override
  String get importUploadProgress => 'Upload progress';

  @override
  String get importValidating => 'Validating on the server…';

  @override
  String importUploading(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get importFileError => 'Couldn\'t use this file';

  @override
  String get importGetTemplate => 'Get the template';

  @override
  String get importTemplateDesc =>
      'A CSV with name, phone, house_name, monthly_dues, family_head, family_members_count and email columns. Save or send it from the share sheet.';

  @override
  String get importNothingSaved => 'Nothing is saved yet';

  @override
  String get importNothingSavedDesc =>
      'The server checks the file first. You review its results before anything is written to the directory.';

  @override
  String get importUploadValidate => 'Upload & validate';

  @override
  String importSelectedFileSemantics(String name) {
    return 'Selected file $name. Tap to choose a different file.';
  }

  @override
  String get importChooseSpreadsheet => 'Choose a spreadsheet';

  @override
  String get importAccepts => 'Accepts .xlsx and .csv files';

  @override
  String get importTapToChange => 'Tap to choose a different file';

  @override
  String importConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count members?',
      one: 'Import 1 member?',
    );
    return '$_temp0';
  }

  @override
  String get importConfirmMessage =>
      'They are added to the directory straight away. Rows with problems are skipped.';

  @override
  String get importConfirm => 'Import';

  @override
  String importServerStatus(String status) {
    return 'The server reported \"$status\" — nothing was confirmed as imported.';
  }

  @override
  String get importCheckRows => 'Check the rows';

  @override
  String get importEyebrow => 'Import';

  @override
  String get importNothingToReview => 'Nothing to review';

  @override
  String get importNothingToReviewDesc =>
      'Upload a spreadsheet first to see its rows here.';

  @override
  String get importChooseFile => 'Choose a file';

  @override
  String get importOnlyValid => 'Only valid rows will be imported.';

  @override
  String get importStatTotal => 'Total';

  @override
  String get importStatValid => 'Valid';

  @override
  String get importStatInvalid => 'Invalid';

  @override
  String get importStatDuplicate => 'Duplicate';

  @override
  String get importStatImported => 'Imported';

  @override
  String get importStatSkipped => 'Skipped';

  @override
  String get importStatUnknown => 'unknown';

  @override
  String importStatSemantics(String label, String value) {
    return '$label $value';
  }

  @override
  String importRowsSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows will be skipped',
      one: '1 row will be skipped',
    );
    return '$_temp0';
  }

  @override
  String get importFixRows =>
      'Fix them in the spreadsheet and import again to add them.';

  @override
  String get importNotCompleted => 'Import not completed';

  @override
  String get importRowsInFile => 'Rows in your file';

  @override
  String importSample(int shown, int total) {
    return 'Sample: $shown of $total rows';
  }

  @override
  String get importNoPreview => 'No row preview';

  @override
  String get importNoPreviewDesc =>
      'The server did not return any rows to preview.';

  @override
  String get importNoValidRows => 'No valid rows to import';

  @override
  String importButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Import $count members',
      one: 'Import 1 member',
    );
    return '$_temp0';
  }

  @override
  String get importChooseAnother => 'Choose another file';

  @override
  String get importNoPhone => 'No phone';

  @override
  String importDuesPerMonth(String amount) {
    return '$amount/mo';
  }

  @override
  String get importFinished => 'Import finished';

  @override
  String get importServerConfirmed => 'The server confirmed the import.';

  @override
  String get importDetailFile => 'File';

  @override
  String get importDetailStatus => 'Status';

  @override
  String get importDetailBatch => 'Batch';

  @override
  String get importGoToMembers => 'Go to members';

  @override
  String get gatewayKeyNotShown => 'Not set';

  @override
  String get gatewayTitle => 'Gateways';

  @override
  String get gatewayEyebrow => 'Payments';

  @override
  String get gatewaySubtitle => 'Where member payments are processed.';

  @override
  String get gatewayManagedTitle => 'Managed from server config';

  @override
  String get gatewayManagedDesc =>
      'Gateway credentials and routing are set in the MahalFlow server configuration. This screen is read-only and never shows secrets.';

  @override
  String get gatewayConfigured => 'Configured gateways';

  @override
  String get gatewayLoading => 'Loading gateways';

  @override
  String get gatewayLoadError => 'Couldn\'t load gateways';

  @override
  String get gatewayEmptyTitle => 'No gateways configured';

  @override
  String get gatewayEmptyDesc =>
      'Add gateway credentials to the server configuration to accept online payments.';

  @override
  String get gatewayPrimaryHeading => 'PRIMARY GATEWAY';

  @override
  String gatewayActiveCount(int active, int total) {
    return '$active of $total active';
  }

  @override
  String get gatewayLoadingShort => 'Loading…';

  @override
  String get gatewayNoneSet => 'None set';

  @override
  String get gatewayRoutedHere => 'Member payments are routed here first.';

  @override
  String get gatewayPrimaryRoute => 'Primary route';

  @override
  String get gatewayFallbackRoute => 'Fallback route';

  @override
  String get gatewayKeyId => 'Merchant key';

  @override
  String get gatewayId => 'Gateway ID';

  @override
  String get broadcastTitle => 'Broadcast a notice';

  @override
  String get broadcastSubtitle => 'Goes to member phones as an in-app notice';

  @override
  String get broadcastAudienceAll => 'All members';

  @override
  String get broadcastAudienceOverdue => 'Pending dues';

  @override
  String get broadcastAudienceFamilyHeads => 'Family heads';

  @override
  String get broadcastReminderTitle => 'Monthly dues reminder';

  @override
  String get broadcastReminderBody =>
      'Respected member, our records show pending dues for your household. You can pay in the MahalFlow app.';

  @override
  String get broadcastRecipientsOverdueAll =>
      'every household with pending dues';

  @override
  String broadcastRecipientsOverdueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count households with pending dues',
      one: '1 household with pending dues',
    );
    return '$_temp0';
  }

  @override
  String get broadcastRecipientsFamilyHeads => 'every family head';

  @override
  String get broadcastRecipientsAll => 'every member';

  @override
  String broadcastRecipientsAllCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'all $count households',
      one: 'all 1 household',
    );
    return '$_temp0';
  }

  @override
  String broadcastSendsTo(String recipients) {
    return 'Sends to $recipients.';
  }

  @override
  String get broadcastTitleRequired => 'Add a title';

  @override
  String get broadcastMessageRequired => 'Write the message';

  @override
  String get broadcastConfirmTitle => 'Send this notice?';

  @override
  String broadcastConfirmMessage(String title, String recipients) {
    return '\"$title\" goes to $recipients as an in-app notice and a push notification. It cannot be unsent.';
  }

  @override
  String get broadcastSendNotice => 'Send notice';

  @override
  String get broadcastWhoHeading => 'WHO SHOULD GET THIS';

  @override
  String get broadcastNoticeTitle => 'Notice title';

  @override
  String get broadcastTitleHint => 'e.g. Friday prayer timing change';

  @override
  String get broadcastMessage => 'Message';

  @override
  String get broadcastMessageHint => 'Write the full announcement…';

  @override
  String get broadcastPriority => 'Priority';

  @override
  String get broadcastPriorityInfo => 'Informational';

  @override
  String get broadcastPriorityReminder => 'Dues reminder';

  @override
  String get broadcastPriorityCritical => 'Critical';

  @override
  String get broadcastNotSent => 'Notice not sent';

  @override
  String get broadcastReviewSend => 'Review & send';

  @override
  String get recordPayTitle => 'Record a cash payment';

  @override
  String get recordPaySubtitle =>
      'Issues a signed receipt in the member\'s name';

  @override
  String get recordPayThisMember => 'this member';

  @override
  String recordPayConfirmTitle(String amount) {
    return 'Record $amount?';
  }

  @override
  String recordPayConfirmMessage(
      String amount, String name, String period, String months) {
    return '$amount in cash from $name for $period ($months). A signed receipt is issued and cannot be edited afterwards.';
  }

  @override
  String get recordPayConfirm => 'Record payment';

  @override
  String get recordPayLoadingMembers => 'Loading members';

  @override
  String get recordPayMembersError => 'Couldn\'t load members';

  @override
  String get recordPayTryAgain => 'Try again';

  @override
  String get recordPayNoMembers => 'No members in the directory yet.';

  @override
  String recordPayNoMatch(String query) {
    return 'No member matches \"$query\".';
  }

  @override
  String recordPayShowing(int shown, int total) {
    return 'Showing $shown of $total. Search to narrow down.';
  }

  @override
  String get recordPayMemberHeading => 'MEMBER';

  @override
  String get recordPaySearchHint => 'Search name, phone or house…';

  @override
  String get recordPayNoId =>
      'This member record has no ID, so a payment cannot be recorded.';

  @override
  String get recordPayNoDues =>
      'No monthly dues amount is set for this member. Edit the member first.';

  @override
  String get recordPayNoAnchor =>
      'This member has no last-paid month on record, so the next due month is unknown.';

  @override
  String get recordPayDuesNotSet => 'Monthly dues not set';

  @override
  String recordPayPerMonth(String amount) {
    return '$amount a month';
  }

  @override
  String get recordPayChange => 'Change';

  @override
  String get recordPayCantRecord => 'Can\'t record yet';

  @override
  String get recordPayMonthsHeading => 'HOW MANY MONTHS';

  @override
  String recordPayCovers(String period) {
    return 'Covers $period — dues are paid in order, starting after the last paid month.';
  }

  @override
  String get recordPayMethodHeading => 'PAYMENT METHOD';

  @override
  String get recordPayMethodDesc =>
      'Cash collected by the committee. Online payments are recorded automatically when members pay in the app.';

  @override
  String get recordPayTotal => 'Total to record';

  @override
  String get recordPayNotRecorded => 'Payment not recorded';

  @override
  String get recordPayReview => 'Review & record';

  @override
  String get receiptSheetTitle => 'Receipt';

  @override
  String get receiptSheetSubtitle => 'Signed entry in the Mahal ledger';

  @override
  String get receiptSheetLoading => 'Loading receipt';

  @override
  String get receiptSheetLoadError => 'Couldn\'t load this receipt';

  @override
  String get receiptSheetTryAgain => 'Try again';

  @override
  String get receiptSheetNumber => 'Receipt number';

  @override
  String get receiptSheetPayer => 'Payer';

  @override
  String get receiptSheetAmount => 'Amount';

  @override
  String get receiptSheetType => 'Type';

  @override
  String get receiptSheetMonths => 'Months';

  @override
  String get receiptSheetDate => 'Date';

  @override
  String get receiptSheetHash => 'Ledger hash';

  @override
  String get receiptSheetVerify => 'Verify on ledger';

  @override
  String get receiptSheetVerifyAgain => 'Verify again';

  @override
  String get receiptSheetValid => 'Signature valid';

  @override
  String get receiptSheetValidDesc =>
      'The recomputed hash matches — this receipt has not been altered.';

  @override
  String get receiptSheetMismatch => 'Signature mismatch';

  @override
  String get receiptSheetMismatchDesc =>
      'The stored hash does not match the receipt contents. Report this to the committee before relying on it.';

  @override
  String get receiptSheetVerifyFailed => 'Couldn\'t verify';

  @override
  String get receiptSheetTryAgainDot => 'Try again.';

  @override
  String get authMobileNumber => 'Mobile number';

  @override
  String get authFullName => 'Full name';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authServerUnreachable =>
      'Couldn\'t reach the server. Check your connection and try again.';

  @override
  String get authSignedInServerUnreachable =>
      'Signed in, but could not reach the server. Try again.';

  @override
  String get authInvalidPhone => 'Enter a valid mobile number';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get authQuotaExceeded => 'Too many codes were sent. Try again later.';

  @override
  String get authNetworkFailed =>
      'No internet connection. Check your connection and try again.';

  @override
  String get authSessionExpired =>
      'This code has expired. Tap “Resend code” for a new one.';

  @override
  String get authInvalidCode => 'That code is incorrect. Try again.';

  @override
  String get authAppNotVerified =>
      'This app could not be verified for sign-in. Update the app or try again later.';

  @override
  String get splashTagline =>
      'Dues, contributions and receipts\nfor your Mahal';

  @override
  String get splashFooter => 'Secure payments · Verified receipts';

  @override
  String get onboardingSlide1Title => 'Know exactly what you owe';

  @override
  String get onboardingSlide1Body =>
      'Your monthly dues, pending months and advance credit — all on one screen, updated the moment a payment clears.';

  @override
  String get onboardingSlide1Point1 => 'Outstanding balance at a glance';

  @override
  String get onboardingSlide1Point2 => 'Month-by-month breakdown';

  @override
  String get onboardingSlide2Title => 'Give in a few taps';

  @override
  String get onboardingSlide2Body =>
      'Pay dues or contribute to the Mahal fund with UPI, cards or net banking. AutoPay can handle the monthly dues for you.';

  @override
  String get onboardingSlide2Point1 => 'UPI, card and net banking';

  @override
  String get onboardingSlide2Point2 => 'Optional AutoPay mandate';

  @override
  String get onboardingSlide3Title => 'Every payment has a receipt';

  @override
  String get onboardingSlide3Body =>
      'Each transaction produces a receipt you can verify, download and share — so the committee and you always see the same record.';

  @override
  String get onboardingSlide3Point1 =>
      'Each receipt can be verified by the committee';

  @override
  String get onboardingSlide3Point2 => 'Download as PDF anytime';

  @override
  String get onboardingSkipSemantics => 'Skip introduction';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String onboardingPageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle =>
      'Sign in to see your dues, pay them and keep your receipts.';

  @override
  String get loginPhoneRequired => 'Enter your registered mobile number';

  @override
  String get loginPhoneInvalid => 'Enter a valid 10-digit mobile number';

  @override
  String get loginSendTimeout =>
      'Sending the code is taking too long. Check your connection and try again.';

  @override
  String get loginSendFailed => 'Could not send the code. Try again.';

  @override
  String get loginDemoServerError =>
      'Could not reach the server. Check the connection and retry.';

  @override
  String get loginLinkOpenFailed => 'Could not open the page.';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginPhoneHelper => 'We’ll send a 6-digit code to this number.';

  @override
  String get loginDemoTitle => 'Demo access · debug build';

  @override
  String get loginDemoBody =>
      'Skip OTP and open a dashboard with local seed data. Hidden in release builds.';

  @override
  String get loginDemoCommittee => 'Committee';

  @override
  String get loginTermsPrefix => 'By continuing you agree to our ';

  @override
  String get loginTermsLink => 'Terms of Service';

  @override
  String get loginTermsAnd => ' and ';

  @override
  String get loginPrivacyLink => 'Privacy Policy';

  @override
  String get loginTermsSuffix => '.';

  @override
  String loginLinkSemantics(String label) {
    return '$label, link';
  }

  @override
  String get otpTitle => 'Verify your number';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the 6-digit code sent to $phone.';
  }

  @override
  String get otpSectionLabel => 'One-time password';

  @override
  String get otpCodeLabel => '6-digit code';

  @override
  String get otpCodeRequired => 'Enter the 6-digit code';

  @override
  String get otpVerificationFailed => 'Verification failed. Try again.';

  @override
  String get otpNewCodeSent => 'A new code has been sent.';

  @override
  String get otpResendFailed => 'Could not resend the code. Try again.';

  @override
  String get otpSending => 'Sending…';

  @override
  String otpResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpVerifying => 'Verifying…';

  @override
  String get otpVerifyContinue => 'Verify & continue';

  @override
  String get otpChangeNumber => 'Change number';

  @override
  String get pendingApprovalStillWaiting =>
      'Still awaiting approval. We’ll let you in as soon as the committee approves.';

  @override
  String get pendingApprovalTitle => 'Waiting for approval';

  @override
  String get pendingApprovalRequestSent => 'Your request has been sent.';

  @override
  String pendingApprovalThanks(String name) {
    return 'Thanks, $name.';
  }

  @override
  String get pendingApprovalBody =>
      'The Mahal committee needs to approve your account before you can view dues and pay.';

  @override
  String get pendingApprovalNoticeTitle => 'Almost there';

  @override
  String get pendingApprovalNoticeBody =>
      'You’ll get access as soon as the committee approves you. Tap “Check again” or pull down to refresh, or come back later.';

  @override
  String get pendingApprovalChecking => 'Checking…';

  @override
  String get pendingApprovalCheckAgain => 'Check again';

  @override
  String get registerNameRequired => 'Enter your full name';

  @override
  String get registerMahalIdRequired => 'Enter your Mahal ID';

  @override
  String get registerTitle => 'Confirm your identity';

  @override
  String get registerSubtitle =>
      'This number isn’t registered yet. Tell us who you are and the committee will approve you.';

  @override
  String get registerDetailsLabel => 'Your details';

  @override
  String get registerNameHint => 'As known to the committee';

  @override
  String get registerMahalIdLabel => 'Mahal ID';

  @override
  String get registerMahalIdHint => 'e.g. MH_001_CALICUT';

  @override
  String get registerMahalIdHelper =>
      'Your Mahal committee can give you this ID if you don’t have it.';

  @override
  String get registerVerifiedByOtp => 'Verified by OTP.';

  @override
  String get registerNotSent => 'Not sent';

  @override
  String get registerNextTitle => 'What happens next';

  @override
  String get registerNextBody =>
      'Your request goes to the Mahal committee. Once they approve you, sign in again with this number to see your dues and receipts.';

  @override
  String get registerSubmitting => 'Submitting…';

  @override
  String get registerRequestJoin => 'Request to join';

  @override
  String get registerDifferentNumber => 'Use a different number';

  @override
  String profileRefreshFailed(String message) {
    return 'Couldn\'t refresh. $message';
  }

  @override
  String get profileUpdated => 'Your details were updated.';

  @override
  String get profileLogoutTitle => 'Log out?';

  @override
  String get profileLogoutMessage =>
      'You will need your mobile number to sign in again.';

  @override
  String get profileLogout => 'Log Out';

  @override
  String get profileEyebrow => 'Your account';

  @override
  String get profileEditTooltip => 'Edit your details';

  @override
  String get profileLoading => 'Loading your profile';

  @override
  String get profileLoadError => 'Couldn\'t load your profile';

  @override
  String get profileLoadErrorFallback => 'Try again in a moment.';

  @override
  String get profileSectionPayments => 'Payments';

  @override
  String get profileAutopay => 'AutoPay';

  @override
  String get profileAutopaySubtitle => 'UPI mandate for your monthly dues';

  @override
  String get profileReceipts => 'Receipts';

  @override
  String get profileReceiptsSubtitle => 'Every payment you have made';

  @override
  String get profilePayDues => 'Pay dues';

  @override
  String get profilePayDuesSubtitle => 'Clear pending months';

  @override
  String get profileSectionApp => 'App';

  @override
  String get profileNotices => 'Notices';

  @override
  String get profileNoticesSubtitle => 'Announcements from the committee';

  @override
  String get profileHelpSubtitle => 'Contact your Mahal committee office';

  @override
  String get profileReplayWelcome => 'Replay welcome';

  @override
  String get profileReplayWelcomeSubtitle => 'Show the introduction again';

  @override
  String profileVersion(String version) {
    return 'MahalFlow · v$version';
  }

  @override
  String get profileMembership => 'Membership';

  @override
  String get profileMemberId => 'Member ID';

  @override
  String get profileMahal => 'Mahal';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileAddress => 'Address';

  @override
  String get profileEditDetails => 'Edit details';

  @override
  String get editProfileNameRequired => 'Your name cannot be empty';

  @override
  String get editProfileEmailInvalid =>
      'That does not look like an email address';

  @override
  String get editProfilePincodeInvalid => 'A PIN code has 6 digits';

  @override
  String get editProfileSaveFailed =>
      'Couldn\'t save your details. Check your connection and try again.';

  @override
  String get editProfileDiscardTitle => 'Discard changes?';

  @override
  String get editProfileDiscardMessage => 'Your edits have not been saved.';

  @override
  String get editProfileDiscard => 'Discard';

  @override
  String get editProfileKeepEditing => 'Keep Editing';

  @override
  String get editProfileTitle => 'Edit details';

  @override
  String get editProfileSubtitle =>
      'Keep your contact details current so receipts reach you.';

  @override
  String get editProfileManagedNote =>
      'Your mobile number and member ID are managed by the committee.';

  @override
  String get editProfilePersonal => 'Personal';

  @override
  String get editProfileEmail => 'Email';

  @override
  String get editProfileEmailHint => 'you@example.com';

  @override
  String get editProfileMobileNote =>
      'Contact the Mahal office to change this.';

  @override
  String get editProfileAddress => 'Address';

  @override
  String get editProfileHouse => 'House name or number';

  @override
  String get editProfileStreet => 'Street or landmark (optional)';

  @override
  String get editProfileCity => 'City';

  @override
  String get editProfileState => 'State';

  @override
  String get editProfilePincode => 'PIN code';

  @override
  String get editProfileSaving => 'Saving…';

  @override
  String get editProfileSave => 'Save Changes';

  @override
  String get helpOpenFailed => 'Couldn\'t open that app.';

  @override
  String get helpTitle => 'Help & support';

  @override
  String helpContactNamed(String mahalName) {
    return 'For questions about your dues, receipts or AutoPay, contact the $mahalName office.';
  }

  @override
  String get helpContactGeneric =>
      'For questions about your dues, receipts or AutoPay, contact your Mahal committee office.';

  @override
  String helpContactNamedNoPhone(String mahalName) {
    return 'For questions about your dues, receipts or AutoPay, contact the $mahalName office in person or at their usual number.';
  }

  @override
  String get helpContactGenericNoPhone =>
      'For questions about your dues, receipts or AutoPay, contact your Mahal committee office in person or at their usual number.';

  @override
  String get helpTipPending =>
      'A payment that shows \"Pending\" usually clears in a few minutes. Do not pay again while it is pending.';

  @override
  String get helpTipReceipts =>
      'Every confirmed payment has a receipt under Receipts.';

  @override
  String get helpTipOffice =>
      'Your mobile number and member ID can only be changed by the office.';

  @override
  String get helpWhatsApp => 'WhatsApp';

  @override
  String get helpCall => 'Call';

  @override
  String get appName => 'MahalFlow';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonTryAgain => 'Try Again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDone => 'Done';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonView => 'View';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonClearSearch => 'Clear search';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonUnavailable => 'Unavailable';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonGoBack => 'Go back';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonShare => 'Share';

  @override
  String get commonDownload => 'Download';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonNext => 'Next';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonProfile => 'Profile';

  @override
  String get commonMember => 'Member';

  @override
  String commonCopyLabel(String label) {
    return 'Copy $label';
  }

  @override
  String commonCopiedLabel(String label) {
    return '$label copied';
  }

  @override
  String commonShowLabel(String label) {
    return 'Show $label';
  }

  @override
  String commonHideLabel(String label) {
    return 'Hide $label';
  }

  @override
  String commonStatusLabel(String label) {
    return 'Status: $label';
  }

  @override
  String commonUnreadCount(String label, int count) {
    return '$label, $count unread';
  }

  @override
  String commonNewBadge(String label) {
    return '$label, new';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navPay => 'Pay';

  @override
  String get navReceipts => 'Receipts';

  @override
  String get navNotices => 'Notices';

  @override
  String get navProfile => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageMalayalam => 'മലയാളം';

  @override
  String get settingsLanguageTooltip => 'Change language';

  @override
  String get errorNetwork =>
      'Couldn\'t reach the server. Check your connection and try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Sign in again to continue.';

  @override
  String get errorForbidden => 'You don\'t have access to this.';

  @override
  String get errorNotFound => 'We couldn\'t find that record.';

  @override
  String get errorBadRequest => 'That request could not be completed.';

  @override
  String get errorServer => 'The server had a problem. Try again in a moment.';

  @override
  String get errorBadResponse =>
      'The server sent an unexpected response. Try again.';

  @override
  String get dateJustNow => 'Just now';

  @override
  String dateMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String dateHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String inrSpokenRupees(String amount) {
    return '$amount rupees';
  }

  @override
  String inrSpokenRupeesPaise(String rupees, int paise) {
    return '$rupees rupees $paise paise';
  }

  @override
  String duesPendingMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending months',
      one: '1 pending month',
    );
    return '$_temp0';
  }

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusActive => 'Active';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusSuccess => 'Success';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusProcessing => 'Processing';

  @override
  String get statusInitiated => 'Initiated';

  @override
  String get statusPartial => 'Partial';

  @override
  String get statusDue => 'Due';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusOverdue => 'Overdue';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusInfo => 'Info';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get notifChannelName => 'Notices & payments';

  @override
  String get notifChannelDescription =>
      'Committee notices, dues reminders and payment updates';

  @override
  String get notifNoticeTitle => 'Notice';

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String get routeNotFoundHeading => 'This page isn’t available';

  @override
  String get routeNotFoundBody =>
      'The link you followed may be out of date. Head back and try again.';

  @override
  String get settingsRowTitle => 'Appearance & language';

  @override
  String get errorNoFileSelected => 'No file was selected.';

  @override
  String get homeYourMahal => 'Your Mahal';

  @override
  String get homeLoadingMahal => 'Loading your Mahal…';

  @override
  String dashboardRefreshFailed(String message) {
    return 'Couldn\'t refresh. $message';
  }

  @override
  String get homeLoadErrorTitle => 'Couldn\'t load your dues';

  @override
  String get homeLoadErrorBody => 'Check your connection and try again.';

  @override
  String get homeContribute => 'Contribute';

  @override
  String get homeContributeCaption => 'Zakat and general fund';

  @override
  String get homeReceipts => 'Receipts';

  @override
  String get homeReceiptsCaption => 'All past payments';

  @override
  String get homeNotices => 'Notices';

  @override
  String get homeNoticesCaption => 'From the committee';

  @override
  String get homeProfile => 'Profile';

  @override
  String get homeProfileCaption => 'Details and settings';

  @override
  String get homeOpenProfile => 'Open your profile';

  @override
  String get homeHelp => 'Help';

  @override
  String get homeGreeting => 'Assalamu Alaikum';

  @override
  String get homeMonthlyDuesLabel => 'MONTHLY DUES';

  @override
  String get homeOutstandingDuesLabel => 'OUTSTANDING DUES';

  @override
  String get homeUpToDate => 'Up to Date';

  @override
  String get homeActionRequired => 'Action Required';

  @override
  String get homeNoOutstandingSemantics => 'No outstanding dues';

  @override
  String homeOutstandingSemantics(String amount) {
    return 'Outstanding dues $amount';
  }

  @override
  String homeAdvanceCredit(String amount) {
    return 'Advance credit $amount';
  }

  @override
  String get homeAllDuesPaid => 'All monthly dues paid in full.';

  @override
  String homeAllDuesPaidUpTo(String month) {
    return 'All dues paid up to $month.';
  }

  @override
  String get homePendingDues => 'Pending monthly dues.';

  @override
  String homeMonthOverdueSemantics(String month) {
    return '$month, overdue';
  }

  @override
  String homeMonthDueNowSemantics(String month) {
    return '$month, due now';
  }

  @override
  String homePayAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get homeMakeContribution => 'Make a Contribution';

  @override
  String homeTileSemantics(String label, String caption) {
    return '$label. $caption';
  }

  @override
  String get homeLatestPayment => 'LATEST PAYMENT';

  @override
  String get homeNoPaymentsYet => 'No payments yet';

  @override
  String get homeNoPaymentsBody =>
      'Your receipts will appear here once you pay.';

  @override
  String get homePayDuesNow => 'Pay Dues Now';

  @override
  String homeMonthsDues(String months) {
    return '$months Dues';
  }

  @override
  String get homeLastPaymentUnavailable => 'Last payment amount not available';

  @override
  String homeLastPaymentSemantics(String amount) {
    return 'Last payment $amount';
  }

  @override
  String homePaidOn(String date) {
    return 'Paid on $date';
  }

  @override
  String get homeAutoPayOff => 'AutoPay is off';

  @override
  String get homeAutoPayBody => 'Never miss a month. Pay dues automatically.';

  @override
  String get homeAutoPaySetUp => 'Set up';

  @override
  String get alertsFilterAll => 'All';

  @override
  String get alertsFilterUnread => 'Unread';

  @override
  String get alertsFilterPayment => 'Payment';

  @override
  String get alertsFilterSystem => 'System';

  @override
  String get alertsUnreadSemantics => 'Unread';

  @override
  String get alertsAlreadyRead => 'Everything is already read';

  @override
  String get alertsMarkedAllRead => 'All notices marked as read';

  @override
  String get alertsMarkReadFailed =>
      'Couldn\'t mark notices as read. Try again.';

  @override
  String get alertsClearTitle => 'Clear all notices?';

  @override
  String get alertsClearMessage =>
      'This removes every notice from your inbox. It cannot be undone.';

  @override
  String get alertsClearConfirm => 'Clear All';

  @override
  String get alertsCleared => 'All notices cleared';

  @override
  String get alertsClearFailed => 'Couldn\'t clear notices. Try again.';

  @override
  String alertsClearedOne(String title) {
    return 'Cleared: $title';
  }

  @override
  String get alertsRemoveFailed => 'Couldn\'t remove that notice.';

  @override
  String get alertsLoadError => 'Couldn\'t load notices';

  @override
  String get alertsTitle => 'Notices';

  @override
  String get alertsEyebrow => 'From the committee';

  @override
  String get alertsLoadingSubtitle => 'Loading your notices…';

  @override
  String get alertsErrorSubtitle => 'Notices could not be loaded.';

  @override
  String get alertsCaughtUp => 'You are all caught up.';

  @override
  String alertsUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get alertsMarkAllRead => 'Mark all as read';

  @override
  String get alertsClearAllTooltip => 'Clear all notices';

  @override
  String get alertsEmptyTitle => 'No notices';

  @override
  String get alertsEmptyFilteredTitle => 'Nothing here';

  @override
  String get alertsEmptyBody =>
      'Announcements and dues reminders from the committee appear here.';

  @override
  String get alertsEmptyFilteredBody =>
      'Try another filter, or pull down to refresh.';

  @override
  String get alertsLoadingSemantics => 'Loading notices';

  @override
  String get alertNotice => 'Notice';

  @override
  String get alertTypePayment => 'Payment';

  @override
  String get alertTypeDuesReminder => 'Dues reminder';

  @override
  String get alertTypeConfirmed => 'Confirmed';

  @override
  String get alertTypeImportant => 'Important';

  @override
  String get alertTypeAnnouncement => 'Announcement';

  @override
  String get alertTypeNotice => 'Notice';

  @override
  String get alertNoDetails => 'No further details were provided.';

  @override
  String get alertWhyTitle => 'Why you got this';

  @override
  String get alertWhyBody =>
      'Your account shows dues that are not yet cleared.';

  @override
  String get receiptsFilterAll => 'All';

  @override
  String get receiptsFilterMonthly => 'Monthly';

  @override
  String get receiptsFilterContribution => 'Contribution';

  @override
  String get receiptsLoadError => 'Couldn\'t load receipts';

  @override
  String get receiptsTitle => 'Receipts';

  @override
  String get receiptsEyebrow => 'History';

  @override
  String get receiptsSubtitle =>
      'Every payment you have made, with a receipt for each.';

  @override
  String get receiptsEmptyTitle => 'No receipts yet';

  @override
  String get receiptsEmptyMonthlyTitle => 'No Monthly receipts';

  @override
  String get receiptsEmptyContributionTitle => 'No Contribution receipts';

  @override
  String get receiptsEmptyBody =>
      'Once you pay your dues or contribute, every receipt lands here.';

  @override
  String get receiptsEmptyFilteredBody =>
      'Try a different filter, or pull down to refresh.';

  @override
  String get receiptsPayDues => 'Pay Dues';

  @override
  String get receiptsLoadingSemantics => 'Loading receipts';

  @override
  String get receiptMonthlyDues => 'Monthly Dues';

  @override
  String get receiptMahalContribution => 'Mahal Contribution';

  @override
  String get receiptMonthlyDuesLower => 'Monthly dues';

  @override
  String get receiptContribution => 'Contribution';

  @override
  String receiptMethodOnline(String gateway) {
    return 'Online ($gateway)';
  }

  @override
  String get receiptMethodCash => 'Cash';

  @override
  String get receiptStatusRefunded => 'Refunded';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptPdfSavedNoViewer =>
      'Receipt saved. No PDF viewer found — use Share to send it.';

  @override
  String get receiptPdfFailed => 'Couldn\'t create the receipt PDF. Try again.';

  @override
  String get receiptShareHeading => 'MahalFlow payment receipt';

  @override
  String receiptShareNumber(String number) {
    return 'Receipt no: $number';
  }

  @override
  String receiptShareMember(String name) {
    return 'Member: $name';
  }

  @override
  String receiptShareAmount(String amount) {
    return 'Amount: $amount';
  }

  @override
  String receiptShareFor(String title, String subtitle) {
    return 'For: $title ($subtitle)';
  }

  @override
  String receiptShareDate(String date) {
    return 'Date: $date';
  }

  @override
  String receiptSharePaidVia(String method) {
    return 'Paid via: $method';
  }

  @override
  String receiptShareStatus(String status) {
    return 'Status: $status';
  }

  @override
  String receiptShareSubject(String number) {
    return 'Receipt $number';
  }

  @override
  String get receiptShareFailed => 'Couldn\'t open the share sheet. Try again.';

  @override
  String get receiptDetailsCopied => 'Receipt details copied';

  @override
  String get receiptVerifiedTitle => 'Verified record';

  @override
  String get receiptVerifiedBody =>
      'Issued by your Mahal through MahalFlow. Safe to share.';

  @override
  String receiptPaymentStatus(String status) {
    return 'Payment $status';
  }

  @override
  String get receiptNotConfirmedBody =>
      'This record is not a confirmed payment receipt.';

  @override
  String get receiptCopyAsText => 'Copy details as text';

  @override
  String get receiptDownloadPdf => 'Download PDF';

  @override
  String get receiptPreparing => 'Preparing…';

  @override
  String get receiptShareReceipt => 'Share Receipt';

  @override
  String get receiptPaymentSuccessful => 'Payment successful';

  @override
  String get receiptNumberLabel => 'Receipt number';

  @override
  String get receiptNumberCopied => 'Receipt number copied';

  @override
  String get receiptMemberLabel => 'Member';

  @override
  String get receiptPaymentTypeLabel => 'Payment type';

  @override
  String get receiptCoversLabel => 'Covers';

  @override
  String get receiptFundLabel => 'Fund';

  @override
  String get receiptPaidViaLabel => 'Paid via';

  @override
  String get receiptFooter =>
      'Computer-generated receipt. No signature required.';

  @override
  String autopayRefreshFailed(String message) {
    return 'Couldn\'t refresh AutoPay. $message';
  }

  @override
  String get autopayFrequencyMonthly => 'Monthly';

  @override
  String get autopayFrequencyWeekly => 'Weekly';

  @override
  String get autopayFrequencyDaily => 'Daily';

  @override
  String get autopayFrequencyHourly => 'Hourly';

  @override
  String get autopayFrequencyMinutely => 'Minutely';

  @override
  String get autopayScheduleMinutely => 'every minute (test)';

  @override
  String get autopayScheduleHourly => 'every hour (test)';

  @override
  String get autopayScheduleDaily => 'every day (test)';

  @override
  String get autopayScheduleWeekly => 'every week';

  @override
  String autopayScheduleMonthly(String day) {
    return 'on the $day of every month';
  }

  @override
  String get autopayConfirmTitle => 'Confirm AutoPay';

  @override
  String get autopayConfirmSubtitle =>
      'Review before your bank asks you to approve';

  @override
  String get autopayAmountPerDebit => 'Amount per debit';

  @override
  String get autopayMaxPerDebit => 'Maximum per debit';

  @override
  String get autopayWhen => 'When';

  @override
  String get autopayValidUntil => 'Valid until';

  @override
  String get autopayAuthChargeNote =>
      'To register the mandate your bank makes a small one-time authorisation charge (shown on the next screen). Future debits never exceed the maximum above, and you can cancel any time.';

  @override
  String get autopaySignInAgain => 'Sign in again to set up AutoPay.';

  @override
  String get autopayStartFailed =>
      'Couldn\'t start AutoPay setup. Nothing was charged — try again.';

  @override
  String get autopayOpenMandateFailed =>
      'Couldn\'t open the mandate screen. Nothing was charged — try again.';

  @override
  String get autopayCancelSetupTitle => 'Cancel AutoPay setup?';

  @override
  String get autopayTurnOffTitle => 'Turn off AutoPay?';

  @override
  String get autopayCancelSetupMessage =>
      'The mandate that is waiting for your bank will be cancelled. You can set up AutoPay again later.';

  @override
  String get autopayTurnOffMessage =>
      'No further dues will be debited automatically. You will need to pay each month yourself.';

  @override
  String get autopayCancelSetupAction => 'Cancel Setup';

  @override
  String get autopayTurnOffAction => 'Turn Off';

  @override
  String get autopayKeep => 'Keep';

  @override
  String get autopaySetupCancelled => 'AutoPay setup cancelled.';

  @override
  String get autopayTurnedOff => 'AutoPay turned off. No further debits.';

  @override
  String get autopayCancelFailed => 'Couldn\'t cancel AutoPay. Try again.';

  @override
  String get autopayBankApprovedPending =>
      'Your bank approved the mandate. Activation is pending.';

  @override
  String autopaySetupFailedReason(String reason) {
    return 'Mandate setup failed: $reason';
  }

  @override
  String get autopaySetupCancelledNoCharge =>
      'Mandate setup was cancelled. Nothing was charged.';

  @override
  String autopayErrorReason(String reason) {
    return 'AutoPay error: $reason';
  }

  @override
  String get autopayOnTitle => 'AutoPay is on';

  @override
  String get autopayOnSubtitle => 'Your dues will be paid automatically';

  @override
  String autopayOnMessage(String amount, String schedule) {
    return 'Your mandate is registered. $amount will be debited $schedule, and a receipt is issued every time it runs.';
  }

  @override
  String get autopayYourDues => 'Your dues';

  @override
  String get autopayFirstDebit => 'First debit';

  @override
  String get autopayMandateId => 'Mandate ID';

  @override
  String get autopayTitle => 'AutoPay';

  @override
  String get autopayEyebrow => 'Payments';

  @override
  String get autopaySubtitle =>
      'Never miss a month. Cancel any time from your profile.';

  @override
  String get autopayLoadingSemantics => 'Loading AutoPay status';

  @override
  String get autopayLoadFailedTitle => 'Couldn\'t load AutoPay';

  @override
  String get autopayLoadFailedFallback => 'Try again in a moment.';

  @override
  String get autopayWaitingBankTitle => 'Waiting for your bank';

  @override
  String get autopayWaitingBankMessage =>
      'Your bank has not confirmed the mandate yet. Pull down or tap Check Status to refresh. Do not set it up again.';

  @override
  String get autopayDuesNotSetTitle => 'Dues amount not set';

  @override
  String get autopayDuesNotSetMessage =>
      'Your monthly dues amount is not recorded yet, so AutoPay cannot be set up. Contact the Mahal office.';

  @override
  String get autopayHowItWorksTitle => 'How it works';

  @override
  String get autopayHowItWorksMessage =>
      'Your bank asks you to approve the mandate once. After that each debit runs on its own and issues a receipt.';

  @override
  String get autopayStatePendingActivation => 'Pending activation';

  @override
  String get autopayStateOff => 'Off';

  @override
  String get autopayDebitTestCadence => 'DEBIT (TEST CADENCE)';

  @override
  String get autopayMonthlyDebit => 'MONTHLY DEBIT';

  @override
  String autopayDebitedBy(String schedule) {
    return 'Debited $schedule by UPI e-Mandate.';
  }

  @override
  String get autopayMandateDetails => 'Mandate details';

  @override
  String get autopayPaymentMethod => 'Payment method';

  @override
  String get autopayFrequency => 'Frequency';

  @override
  String get autopayNextDebit => 'Next debit';

  @override
  String get autopayLastDebit => 'Last debit';

  @override
  String get autopayAuthorisation => 'Authorisation';

  @override
  String get autopaySmallOneTimeCharge => 'Small one-time charge';

  @override
  String get autopayTestFrequency => 'Test frequency (debug build only)';

  @override
  String autopayFrequencySemantics(String frequency) {
    return '$frequency frequency';
  }

  @override
  String get autopayTurningOff => 'Turning off…';

  @override
  String get autopayTurnOffButton => 'Turn Off AutoPay';

  @override
  String get autopayCheckStatus => 'Check Status';

  @override
  String get autopaySettingUp => 'Setting up…';

  @override
  String get autopayNotNow => 'Not now';

  @override
  String duesPayRefreshFailed(String message) {
    return 'Couldn\'t refresh. $message';
  }

  @override
  String get duesPaySignInAgain => 'Sign in again to pay your dues.';

  @override
  String duesPayHelpNote(String amount) {
    return 'Your dues are $amount per month. Months are paid in order, oldest first.';
  }

  @override
  String get duesPayTitle => 'Monthly Dues';

  @override
  String get duesPayEyebrow => 'Payments';

  @override
  String get duesPaySubtitle => 'Choose the months you want to clear.';

  @override
  String get duesPayHelp => 'Help';

  @override
  String get duesPayLoadFailedTitle => 'Couldn\'t load your dues';

  @override
  String get duesPayLoadFailedFallback =>
      'Check your connection and try again.';

  @override
  String get duesPayPeriodNotSetTitle => 'Dues period not set up';

  @override
  String get duesPayPeriodNotSetMessage =>
      'Your Mahal has not recorded which months you have paid, so dues cannot be paid in the app yet. Contact the office to set this up.';

  @override
  String get duesPayGetHelp => 'Get Help';

  @override
  String get duesPayUpToDateTitle => 'You are up to date';

  @override
  String get duesPayUpToDateMessage =>
      'No months are due. You can pay ahead below.';

  @override
  String get duesPayDueNowHeader => 'DUE NOW';

  @override
  String get duesPayPayAheadHeader => 'PAY AHEAD';

  @override
  String get duesPayContributeTitle => 'Make a contribution';

  @override
  String get duesPayContributeMessage => 'Zakat, Masjid or the general fund.';

  @override
  String get duesPayOpen => 'Open';

  @override
  String duesPayMonthsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months selected',
      one: '1 month selected',
    );
    return '$_temp0';
  }

  @override
  String get duesPayNoFee => 'No processing fee';

  @override
  String get duesPayProcessing => 'Processing…';

  @override
  String get duesPayContinueToPay => 'Continue to Pay';

  @override
  String duesPayPayAmount(String amount) {
    return 'Pay $amount';
  }

  @override
  String get duesPayTotalSelected => 'TOTAL SELECTED';

  @override
  String duesPayMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get duesPayTotalUnavailableSemantics => 'Total not available';

  @override
  String duesPayTotalSemantics(String amount) {
    return 'Total $amount';
  }

  @override
  String get duesPaySelectAtLeastOne =>
      'Select at least one month below to continue.';

  @override
  String duesPayPerMonth(String amount) {
    return '$amount per month';
  }

  @override
  String get duesPayExactAmountNote =>
      'The exact amount is shown on the payment screen.';

  @override
  String get duesPaySelectAll => 'Select all';

  @override
  String get duesPaySelectAllSemantics => 'Select all due months';

  @override
  String get duesPayStatusDueNow => 'Due now';

  @override
  String get duesPayStatusUpcoming => 'Upcoming';

  @override
  String get duesPayLoadingSemantics => 'Loading your dues';

  @override
  String get payuStartFailed =>
      'Couldn\'t start the payment. No money was taken — try again.';

  @override
  String get payuOpenFailed =>
      'Couldn\'t open the payment screen. No money was taken — try again.';

  @override
  String get payuCouldNotComplete => 'The payment could not be completed.';

  @override
  String get contributionFundZakat => 'Zakat Fund';

  @override
  String get contributionFundZakatBlurb =>
      'Obligatory charity, distributed by the committee';

  @override
  String get contributionFundGeneral => 'General Fund';

  @override
  String get contributionFundGeneralBlurb => 'Day-to-day running of the Mahal';

  @override
  String get contributionFundMasjid => 'Masjid Renovation';

  @override
  String get contributionFundMasjidBlurb => 'Building works and maintenance';

  @override
  String get contributionFundEducation => 'Education Help';

  @override
  String get contributionFundEducationBlurb => 'Madrasa and student support';

  @override
  String get contributionFundMedical => 'Medical Aid';

  @override
  String get contributionFundMedicalBlurb =>
      'Emergency help for families in need';

  @override
  String contributionMinError(String amount) {
    return 'The minimum contribution is $amount';
  }

  @override
  String contributionMaxError(String amount) {
    return 'The maximum in the app is $amount. Contact the office for larger amounts.';
  }

  @override
  String get contributionSignInAgain => 'Sign in again to contribute.';

  @override
  String contributionConfirmTitle(String amount) {
    return 'Give $amount?';
  }

  @override
  String contributionConfirmMessage(String amount, String fund) {
    return 'You are about to contribute $amount to $fund. Please check the amount before you continue.';
  }

  @override
  String get contributionTitle => 'Contribute';

  @override
  String get contributionEyebrow => 'Give';

  @override
  String get contributionSubtitle =>
      'Support the Mahal beyond your monthly dues.';

  @override
  String get contributionWhereTitle => 'Where should it go?';

  @override
  String get contributionNoteLabel => 'Note (optional)';

  @override
  String get contributionNoteHint => 'e.g. In memory of family, Eid charity';

  @override
  String contributionGiveAmount(String amount) {
    return 'Give $amount';
  }

  @override
  String get contributionEnterAmount => 'Enter an amount';

  @override
  String get contributionAmountLabel => 'Contribution amount';

  @override
  String get contributionAmountSemantics => 'Contribution amount in rupees';

  @override
  String contributionRange(String min, String max) {
    return 'Between $min and $max';
  }

  @override
  String get payResultAmountLabel => 'AMOUNT';

  @override
  String get payResultCancelledTitle => 'Payment cancelled';

  @override
  String get payResultFailedTitle => 'Payment failed';

  @override
  String get payResultCancelledMessage =>
      'You left the payment screen before paying. No money was taken.';

  @override
  String get payResultFailedMessage =>
      'The payment did not go through. If your bank shows a debit, it is reversed automatically. You can try again.';

  @override
  String get payResultBackHome => 'Back to Home';

  @override
  String get payResultReason => 'Reason';

  @override
  String get payResultFor => 'For';

  @override
  String get payResultFund => 'Fund';

  @override
  String get payResultAttempted => 'Attempted';

  @override
  String get payResultAmountDebited => 'Amount debited';

  @override
  String get payResultNone => 'None';

  @override
  String get payResultPendingTitle => 'Payment pending';

  @override
  String get payResultPendingMessageDues =>
      'Your bank is still confirming this. Do not pay again — we will update your dues as soon as it clears.';

  @override
  String get payResultPendingMessageContribution =>
      'Your bank is still confirming this. Do not pay again — we will update your receipts as soon as it clears.';

  @override
  String get payResultCheckAgain => 'Check Again';

  @override
  String get payResultViewReceipts => 'View Receipts';

  @override
  String get payResultCovers => 'Covers';

  @override
  String get payResultStarted => 'Started';

  @override
  String get payResultLastChecked => 'Last checked';

  @override
  String get payResultChecking => 'Checking…';

  @override
  String get payResultCheckFailedTitle => 'Couldn\'t check the status';

  @override
  String get payResultNextTitle => 'What happens next';

  @override
  String get payResultNextMessage =>
      'Most payments clear within a few minutes. If money left your account and this does not clear, your bank reverses it or the office can confirm it from the receipt list.';

  @override
  String get payResultSuccessTitle => 'Payment successful';

  @override
  String get payResultThankYou => 'Thank you';

  @override
  String get payResultDuesClearedMessage =>
      'Your dues are cleared. A receipt has been issued in your name.';

  @override
  String get payResultContributionReceivedMessage =>
      'Your contribution was received. A receipt has been issued in your name.';

  @override
  String get payResultViewReceipt => 'View Receipt';

  @override
  String get payResultPaidOn => 'Paid on';

  @override
  String get payResultReceiptNumber => 'Receipt number';

  @override
  String get statusNotConfigured => 'Not configured';

  @override
  String importRowNumber(int row) {
    return 'Row $row';
  }

  @override
  String get importNoBatch =>
      'This preview has no batch ID from the server. Upload the file again.';

  @override
  String get importStatusAlreadyCommitted => 'Already imported';

  @override
  String get importAlreadyCommittedTitle => 'This file was already imported';

  @override
  String get importAlreadyCommittedBody =>
      'No new members were added. The counts below are from the first import.';

  @override
  String get gatewayMode => 'Mode';

  @override
  String get gatewayModeLive => 'Live';

  @override
  String get gatewayModeTest => 'Test';

  @override
  String gatewayModeSimulated(String mode) {
    return '$mode · simulated';
  }

  @override
  String get gatewaySimulatedTitle => 'Payments are simulated';

  @override
  String get gatewaySimulatedDesc =>
      'The server is in payment test mode: no real gateway calls are made and no money moves.';

  @override
  String get gatewayMethods => 'Methods';

  @override
  String get gatewayAutoPay => 'AutoPay';

  @override
  String get gatewayAutoPayOn => 'Enabled';

  @override
  String get gatewayAutoPayOff => 'Not enabled';

  @override
  String get gatewayCashRoute => 'Recorded by the committee';

  @override
  String get paymentMethodUpi => 'UPI';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodNetbanking => 'Net banking';

  @override
  String get paymentMethodWallet => 'Wallet';

  @override
  String get receiptMethodAutoPay => 'AutoPay';

  @override
  String receiptMethodAutoPayVia(String method) {
    return 'AutoPay ($method)';
  }

  @override
  String get receiptRefundedTitle => 'This payment was refunded';

  @override
  String get receiptRefundedBody =>
      'The amount was returned to the payer. This receipt is kept as a record and no longer counts as paid.';

  @override
  String receiptRefundedOnBody(String date) {
    return 'Refunded on $date. This receipt is kept as a record and no longer counts as paid.';
  }

  @override
  String get receiptRefundedOnLabel => 'Refunded on';

  @override
  String get receiptNoteLabel => 'Note';

  @override
  String receiptShareNote(String note) {
    return 'Note: $note';
  }

  @override
  String get receiptSheetStatus => 'Status';

  @override
  String editProfileSaveRejected(String reason) {
    return 'Couldn\'t save: $reason';
  }

  @override
  String get memberDetailsReminderChooseSubtitle =>
      'Send it in the app, or open WhatsApp or SMS with the text filled in';

  @override
  String get memberDetailsSendInAppNotice => 'Send in-app notice';

  @override
  String get memberDetailsInAppNoticeHint =>
      'Only this member sees it, in their alerts and as a notification.';

  @override
  String get memberDetailsNoticeTitle => 'Dues reminder';

  @override
  String get memberDetailsNoticeSent => 'Reminder sent in the app';

  @override
  String memberDetailsNoticeFailed(String reason) {
    return 'Couldn\'t send the reminder: $reason';
  }

  @override
  String approvalsUndone(String name) {
    return '$name is back in pending requests.';
  }

  @override
  String approvalsUndoFailed(String reason) {
    return 'Couldn\'t undo. $reason';
  }

  @override
  String get registrationRejectedTitle => 'Registration not approved';

  @override
  String get registrationRejectedSubtitle =>
      'The committee did not approve this request.';

  @override
  String get registrationRejectedBody =>
      'You cannot sign in with this number right now. No payments or member details are available.';

  @override
  String get registrationRejectedNoticeTitle => 'Think this is a mistake?';

  @override
  String get registrationRejectedNoticeBody =>
      'Contact the Mahal office. If the committee changes its decision, check again here.';

  @override
  String get registrationRejectedStill => 'Still not approved.';

  @override
  String get adminDashCollectedMonthCaps => 'COLLECTED THIS MONTH';

  @override
  String get adminDashCollectedMonth => 'Collected this month';

  @override
  String adminDashCollectedMonthSpoken(String amount) {
    return 'Collected this month $amount';
  }

  @override
  String adminDashAllTime(String amount) {
    return 'All time: $amount';
  }

  @override
  String get reportsPendingDuesNow => 'Pending dues (now)';

  @override
  String reportsPeriodAllTypes(String period) {
    return '$period · all types';
  }

  @override
  String get alertTypeEvent => 'Event';

  @override
  String get broadcastType => 'Type';

  @override
  String get broadcastTypeGeneral => 'General notice';
}
