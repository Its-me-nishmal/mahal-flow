import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ml.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('ml')
  ];

  /// No description provided for @adminCommitteeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Committee'**
  String get adminCommitteeEyebrow;

  /// No description provided for @adminMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get adminMenu;

  /// No description provided for @adminTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get adminTryAgain;

  /// No description provided for @adminViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get adminViewAll;

  /// No description provided for @adminAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get adminAddMember;

  /// No description provided for @adminRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get adminRecordPayment;

  /// No description provided for @adminPendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending approvals'**
  String get adminPendingApprovals;

  /// No description provided for @adminBroadcastNotice.
  ///
  /// In en, this message translates to:
  /// **'Broadcast a notice'**
  String get adminBroadcastNotice;

  /// No description provided for @adminBulkImport.
  ///
  /// In en, this message translates to:
  /// **'Bulk import'**
  String get adminBulkImport;

  /// No description provided for @adminReceiptAction.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get adminReceiptAction;

  /// No description provided for @adminMemberRegistered.
  ///
  /// In en, this message translates to:
  /// **'{name} was registered.'**
  String adminMemberRegistered(String name);

  /// No description provided for @adminFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get adminFullName;

  /// No description provided for @adminMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get adminMobileNumber;

  /// No description provided for @adminMonthlyDuesRupees.
  ///
  /// In en, this message translates to:
  /// **'Monthly dues (₹)'**
  String get adminMonthlyDuesRupees;

  /// No description provided for @adminPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit mobile number'**
  String get adminPhoneInvalid;

  /// No description provided for @adminEditMember.
  ///
  /// In en, this message translates to:
  /// **'Edit member'**
  String get adminEditMember;

  /// No description provided for @adminNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminNavDashboard;

  /// No description provided for @adminNavMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get adminNavMembers;

  /// No description provided for @adminNavReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminNavReports;

  /// No description provided for @adminNavLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get adminNavLogs;

  /// No description provided for @adminFormatStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminFormatStatusActive;

  /// No description provided for @adminFormatStatusGrace.
  ///
  /// In en, this message translates to:
  /// **'Grace period'**
  String get adminFormatStatusGrace;

  /// No description provided for @adminFormatStatusAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get adminFormatStatusAwaiting;

  /// No description provided for @adminFormatStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get adminFormatStatusSuspended;

  /// No description provided for @adminFormatStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminFormatStatusInactive;

  /// No description provided for @adminFormatStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminFormatStatusRejected;

  /// No description provided for @adminFormatMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String adminFormatMonths(int count);

  /// No description provided for @adminFormatMonthlyDues.
  ///
  /// In en, this message translates to:
  /// **'Monthly dues'**
  String get adminFormatMonthlyDues;

  /// No description provided for @adminFormatContribution.
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get adminFormatContribution;

  /// No description provided for @adminFormatPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get adminFormatPayment;

  /// No description provided for @adminDashSubscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription active'**
  String get adminDashSubscriptionActive;

  /// No description provided for @adminDashSubscriptionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Subscription —'**
  String get adminDashSubscriptionUnknown;

  /// No description provided for @adminDashSubscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Subscription: {status}'**
  String adminDashSubscriptionStatus(String status);

  /// No description provided for @adminDashLoadingCollection.
  ///
  /// In en, this message translates to:
  /// **'Loading collection summary'**
  String get adminDashLoadingCollection;

  /// No description provided for @adminDashTotalCollectedCaps.
  ///
  /// In en, this message translates to:
  /// **'TOTAL COLLECTED'**
  String get adminDashTotalCollectedCaps;

  /// No description provided for @adminDashTotalCollected.
  ///
  /// In en, this message translates to:
  /// **'Total collected'**
  String get adminDashTotalCollected;

  /// No description provided for @adminDashTotalCollectedSpoken.
  ///
  /// In en, this message translates to:
  /// **'Total collected {amount}'**
  String adminDashTotalCollectedSpoken(String amount);

  /// No description provided for @adminDashOutstandingAcrossMahal.
  ///
  /// In en, this message translates to:
  /// **'{amount} still outstanding across the Mahal.'**
  String adminDashOutstandingAcrossMahal(String amount);

  /// No description provided for @adminDashCollectionRate.
  ///
  /// In en, this message translates to:
  /// **'Collection rate'**
  String get adminDashCollectionRate;

  /// No description provided for @adminDashPaidOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total} members · {pct}%'**
  String adminDashPaidOfTotal(int paid, int total, int pct);

  /// No description provided for @adminDashPercentValue.
  ///
  /// In en, this message translates to:
  /// **'{pct} percent'**
  String adminDashPercentValue(int pct);

  /// No description provided for @adminDashPendingDues.
  ///
  /// In en, this message translates to:
  /// **'Pending dues'**
  String get adminDashPendingDues;

  /// No description provided for @adminDashMembersPaid.
  ///
  /// In en, this message translates to:
  /// **'Members paid'**
  String get adminDashMembersPaid;

  /// No description provided for @adminDashOfHouseholds.
  ///
  /// In en, this message translates to:
  /// **'of {total} households'**
  String adminDashOfHouseholds(int total);

  /// No description provided for @adminDashMembersPending.
  ///
  /// In en, this message translates to:
  /// **'Members pending'**
  String get adminDashMembersPending;

  /// No description provided for @adminDashNeedReminder.
  ///
  /// In en, this message translates to:
  /// **'need a reminder'**
  String get adminDashNeedReminder;

  /// No description provided for @adminDashOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminDashOverview;

  /// No description provided for @adminDashLoadingOverview.
  ///
  /// In en, this message translates to:
  /// **'Loading overview'**
  String get adminDashLoadingOverview;

  /// No description provided for @adminDashTransactionsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get adminDashTransactionsError;

  /// No description provided for @adminDashLoadingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Loading transactions'**
  String get adminDashLoadingTransactions;

  /// No description provided for @adminDashNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get adminDashNoTransactions;

  /// No description provided for @adminDashNoTransactionsBody.
  ///
  /// In en, this message translates to:
  /// **'Payments appear here as members pay or you record cash.'**
  String get adminDashNoTransactionsBody;

  /// No description provided for @adminDashBroadcastBody.
  ///
  /// In en, this message translates to:
  /// **'Send an announcement or a dues reminder to every member, only those with pending dues, or family heads.'**
  String get adminDashBroadcastBody;

  /// No description provided for @adminDashComposeNotice.
  ///
  /// In en, this message translates to:
  /// **'Compose notice'**
  String get adminDashComposeNotice;

  /// No description provided for @adminDashTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashTitle;

  /// No description provided for @adminDashLiveLedger.
  ///
  /// In en, this message translates to:
  /// **'Live ledger'**
  String get adminDashLiveLedger;

  /// No description provided for @adminDashMahalLiveLedger.
  ///
  /// In en, this message translates to:
  /// **'{mahal} · live ledger'**
  String adminDashMahalLiveLedger(String mahal);

  /// No description provided for @adminDashLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the dashboard'**
  String get adminDashLoadError;

  /// No description provided for @adminDashRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get adminDashRecentTransactions;

  /// No description provided for @adminDashPendingApprovalsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Pending approvals · {count} waiting'**
  String adminDashPendingApprovalsWaiting(int count);

  /// No description provided for @adminDashRecordedFor.
  ///
  /// In en, this message translates to:
  /// **'{amount} recorded for {name}'**
  String adminDashRecordedFor(String amount, String name);

  /// No description provided for @adminDashTheMember.
  ///
  /// In en, this message translates to:
  /// **'the member'**
  String get adminDashTheMember;

  /// No description provided for @adminDashNoticeSent.
  ///
  /// In en, this message translates to:
  /// **'Notice sent to members.'**
  String get adminDashNoticeSent;

  /// No description provided for @drawerFinancialReports.
  ///
  /// In en, this message translates to:
  /// **'Financial reports'**
  String get drawerFinancialReports;

  /// No description provided for @drawerPaymentGateways.
  ///
  /// In en, this message translates to:
  /// **'Payment gateways'**
  String get drawerPaymentGateways;

  /// No description provided for @drawerAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get drawerAuditLog;

  /// No description provided for @drawerSwitchToMember.
  ///
  /// In en, this message translates to:
  /// **'Switch to member view'**
  String get drawerSwitchToMember;

  /// No description provided for @drawerSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get drawerSignOut;

  /// No description provided for @drawerSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get drawerSignOutTitle;

  /// No description provided for @drawerSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to verify your phone number again to open the committee portal.'**
  String get drawerSignOutMessage;

  /// No description provided for @drawerCommitteePortal.
  ///
  /// In en, this message translates to:
  /// **'Committee portal'**
  String get drawerCommitteePortal;

  /// No description provided for @drawerCommitteePortalReg.
  ///
  /// In en, this message translates to:
  /// **'Committee portal · {reg}'**
  String drawerCommitteePortalReg(String reg);

  /// No description provided for @drawerBadgeWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String drawerBadgeWaiting(int count);

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// No description provided for @membersEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get membersEyebrow;

  /// No description provided for @membersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get membersFilterAll;

  /// No description provided for @membersFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get membersFilterActive;

  /// No description provided for @membersFilterGrace.
  ///
  /// In en, this message translates to:
  /// **'Grace Period'**
  String get membersFilterGrace;

  /// No description provided for @membersFilterSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get membersFilterSuspended;

  /// No description provided for @membersFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get membersFilterPending;

  /// No description provided for @membersLoadingDirectory.
  ///
  /// In en, this message translates to:
  /// **'Loading the directory…'**
  String get membersLoadingDirectory;

  /// No description provided for @membersDirectoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Directory unavailable'**
  String get membersDirectoryUnavailable;

  /// No description provided for @membersShowingOf.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} households'**
  String membersShowingOf(int shown, int total);

  /// No description provided for @membersMatchesLoaded.
  ///
  /// In en, this message translates to:
  /// **'{shown} matches in {loaded} of {total} loaded'**
  String membersMatchesLoaded(int shown, int loaded, int total);

  /// No description provided for @membersMatchCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} households match'**
  String membersMatchCount(int shown, int total);

  /// No description provided for @membersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, phone, house or code…'**
  String get membersSearchHint;

  /// No description provided for @membersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load members'**
  String get membersLoadError;

  /// No description provided for @membersLoadMoreError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more members'**
  String get membersLoadMoreError;

  /// No description provided for @membersNoMatchesYet.
  ///
  /// In en, this message translates to:
  /// **'No matches in the {loaded} loaded so far — searching the rest…'**
  String membersNoMatchesYet(int loaded);

  /// No description provided for @membersAllLoaded.
  ///
  /// In en, this message translates to:
  /// **'All {total} households loaded'**
  String membersAllLoaded(int total);

  /// No description provided for @membersDuesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount}/mo'**
  String membersDuesPerMonth(String amount);

  /// No description provided for @membersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get membersEmptyTitle;

  /// No description provided for @membersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Register households one by one or import a spreadsheet.'**
  String get membersEmptyBody;

  /// No description provided for @membersNotFound.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get membersNotFound;

  /// No description provided for @membersNothingMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \'{query}\'.'**
  String membersNothingMatches(String query);

  /// No description provided for @membersNoneInStatus.
  ///
  /// In en, this message translates to:
  /// **'No households are in \'{status}\' status.'**
  String membersNoneInStatus(String status);

  /// No description provided for @membersShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get membersShowAll;

  /// No description provided for @membersLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading members'**
  String get membersLoading;

  /// No description provided for @addMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Register a member'**
  String get addMemberTitle;

  /// No description provided for @addMemberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds a household to the Mahal directory'**
  String get addMemberSubtitle;

  /// No description provided for @addMemberNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the member\'s full name'**
  String get addMemberNameRequired;

  /// No description provided for @addMemberPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number'**
  String get addMemberPhoneRequired;

  /// No description provided for @addMemberDuesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the monthly dues in whole rupees (at least ₹1)'**
  String get addMemberDuesInvalid;

  /// No description provided for @addMemberNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Abdul Kareem'**
  String get addMemberNameHint;

  /// No description provided for @addMemberHouseLabel.
  ///
  /// In en, this message translates to:
  /// **'House name (optional)'**
  String get addMemberHouseLabel;

  /// No description provided for @addMemberHouseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Darussalam'**
  String get addMemberHouseHint;

  /// No description provided for @addMemberDuesHint.
  ///
  /// In en, this message translates to:
  /// **'As agreed by the committee'**
  String get addMemberDuesHint;

  /// No description provided for @addMemberError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t register this member'**
  String get addMemberError;

  /// No description provided for @addMemberSubmit.
  ///
  /// In en, this message translates to:
  /// **'Register member'**
  String get addMemberSubmit;

  /// No description provided for @memberDetailsPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get memberDetailsPaid;

  /// No description provided for @memberDetailsDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get memberDetailsDue;

  /// No description provided for @memberDetailsOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get memberDetailsOverdue;

  /// No description provided for @memberDetailsRecorded.
  ///
  /// In en, this message translates to:
  /// **'{amount} recorded'**
  String memberDetailsRecorded(String amount);

  /// No description provided for @memberDetailsNoValidPhone.
  ///
  /// In en, this message translates to:
  /// **'This member has no valid mobile number on record.'**
  String get memberDetailsNoValidPhone;

  /// No description provided for @memberDetailsReminderNameFallback.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get memberDetailsReminderNameFallback;

  /// No description provided for @memberDetailsReminderMahalFallback.
  ///
  /// In en, this message translates to:
  /// **'the Mahal committee'**
  String get memberDetailsReminderMahalFallback;

  /// No description provided for @memberDetailsReminderWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum {name}, this is a reminder from {mahal} that your monthly dues are pending. Pending amount: {amount}. You can pay in the MahalFlow app. Thank you.'**
  String memberDetailsReminderWithAmount(
      String name, String mahal, String amount);

  /// No description provided for @memberDetailsReminderNoAmount.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum {name}, this is a reminder from {mahal} that your monthly dues are pending. You can pay in the MahalFlow app. Thank you.'**
  String memberDetailsReminderNoAmount(String name, String mahal);

  /// No description provided for @memberDetailsReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a dues reminder'**
  String get memberDetailsReminderTitle;

  /// No description provided for @memberDetailsReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens your messaging app with the text filled in'**
  String get memberDetailsReminderSubtitle;

  /// No description provided for @memberDetailsReminderTo.
  ///
  /// In en, this message translates to:
  /// **'To {phone}. Nothing is sent until you press send in the other app.'**
  String memberDetailsReminderTo(String phone);

  /// No description provided for @memberDetailsOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get memberDetailsOpenWhatsApp;

  /// No description provided for @memberDetailsOpenSms.
  ///
  /// In en, this message translates to:
  /// **'Open SMS'**
  String get memberDetailsOpenSms;

  /// No description provided for @memberDetailsWhatsAppFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open WhatsApp on this phone.'**
  String get memberDetailsWhatsAppFailed;

  /// No description provided for @memberDetailsSmsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the SMS app on this phone.'**
  String get memberDetailsSmsFailed;

  /// No description provided for @memberDetailsSendReminderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send dues reminder'**
  String get memberDetailsSendReminderTooltip;

  /// No description provided for @memberDetailsNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone on record'**
  String get memberDetailsNoPhone;

  /// No description provided for @memberDetailsMemberCode.
  ///
  /// In en, this message translates to:
  /// **'Member code {code}'**
  String memberDetailsMemberCode(String code);

  /// No description provided for @memberDetailsIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID {id}'**
  String memberDetailsIdLabel(String id);

  /// No description provided for @memberDetailsIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'This member record is incomplete'**
  String get memberDetailsIncompleteTitle;

  /// No description provided for @memberDetailsIncompleteBody.
  ///
  /// In en, this message translates to:
  /// **'It has no member ID, so its history cannot be loaded and no payment can be recorded. Go back and open the member again from the directory.'**
  String get memberDetailsIncompleteBody;

  /// No description provided for @memberDetailsBackToMembers.
  ///
  /// In en, this message translates to:
  /// **'Back to members'**
  String get memberDetailsBackToMembers;

  /// No description provided for @memberDetailsSinceJoining.
  ///
  /// In en, this message translates to:
  /// **'Since joining'**
  String get memberDetailsSinceJoining;

  /// No description provided for @memberDetailsLastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last six months'**
  String get memberDetailsLastSixMonths;

  /// No description provided for @memberDetailsMonthlyDuesCaps.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY DUES'**
  String get memberDetailsMonthlyDuesCaps;

  /// No description provided for @memberDetailsLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading payment history…'**
  String get memberDetailsLoadingHistory;

  /// No description provided for @memberDetailsHistoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Payment history unavailable.'**
  String get memberDetailsHistoryUnavailable;

  /// No description provided for @memberDetailsNoDuesMonths.
  ///
  /// In en, this message translates to:
  /// **'No dues months yet.'**
  String get memberDetailsNoDuesMonths;

  /// No description provided for @memberDetailsAllPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid every month shown below.'**
  String get memberDetailsAllPaid;

  /// No description provided for @memberDetailsUnpaidCount.
  ///
  /// In en, this message translates to:
  /// **'{unpaid} of {total} recent months unpaid.'**
  String memberDetailsUnpaidCount(int unpaid, int total);

  /// No description provided for @memberDetailsOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get memberDetailsOutstanding;

  /// No description provided for @memberDetailsPaidUpTo.
  ///
  /// In en, this message translates to:
  /// **'Paid up to'**
  String get memberDetailsPaidUpTo;

  /// No description provided for @memberDetailsHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get memberDetailsHouse;

  /// No description provided for @memberDetailsNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get memberDetailsNotRecorded;

  /// No description provided for @memberDetailsMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberDetailsMemberSince;

  /// No description provided for @memberDetailsLoadingDues.
  ///
  /// In en, this message translates to:
  /// **'Loading dues history'**
  String get memberDetailsLoadingDues;

  /// No description provided for @memberDetailsDuesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load dues history'**
  String get memberDetailsDuesError;

  /// No description provided for @memberDetailsNoDuesTitle.
  ///
  /// In en, this message translates to:
  /// **'No dues yet'**
  String get memberDetailsNoDuesTitle;

  /// No description provided for @memberDetailsNoDuesBody.
  ///
  /// In en, this message translates to:
  /// **'Dues start from the month the member joined.'**
  String get memberDetailsNoDuesBody;

  /// No description provided for @memberDetailsReceiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt {number}'**
  String memberDetailsReceiptNumber(String number);

  /// No description provided for @memberDetailsOpenReceipt.
  ///
  /// In en, this message translates to:
  /// **'Open receipt'**
  String get memberDetailsOpenReceipt;

  /// No description provided for @editMemberNameRequired.
  ///
  /// In en, this message translates to:
  /// **'A name is required'**
  String get editMemberNameRequired;

  /// No description provided for @editMemberPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'A phone number is required'**
  String get editMemberPhoneRequired;

  /// No description provided for @editMemberDuesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Monthly dues must be at least ₹1'**
  String get editMemberDuesInvalid;

  /// No description provided for @editMemberSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the changes. {reason}'**
  String editMemberSaveFailed(String reason);

  /// No description provided for @editMemberSuspendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t suspend this member. {reason}'**
  String editMemberSuspendFailed(String reason);

  /// No description provided for @editMemberReactivateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reactivate this member. {reason}'**
  String editMemberReactivateFailed(String reason);

  /// No description provided for @editMemberUpdated.
  ///
  /// In en, this message translates to:
  /// **'Member details updated.'**
  String get editMemberUpdated;

  /// No description provided for @editMemberSuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend this member?'**
  String get editMemberSuspendTitle;

  /// No description provided for @editMemberSuspendMessage.
  ///
  /// In en, this message translates to:
  /// **'Dues collection for {name} will be put on hold until you reactivate them. Their history is kept.'**
  String editMemberSuspendMessage(String name);

  /// No description provided for @editMemberSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get editMemberSuspend;

  /// No description provided for @editMemberReactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate this member?'**
  String get editMemberReactivateTitle;

  /// No description provided for @editMemberReactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} becomes active again and dues collection resumes.'**
  String editMemberReactivateMessage(String name);

  /// No description provided for @editMemberReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get editMemberReactivate;

  /// No description provided for @editMemberNowSuspended.
  ///
  /// In en, this message translates to:
  /// **'This member is now suspended.'**
  String get editMemberNowSuspended;

  /// No description provided for @editMemberActiveAgain.
  ///
  /// In en, this message translates to:
  /// **'This member is active again.'**
  String get editMemberActiveAgain;

  /// No description provided for @editMemberDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editMemberDiscardTitle;

  /// No description provided for @editMemberDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'Your edits to this member have not been saved.'**
  String get editMemberDiscardMessage;

  /// No description provided for @editMemberDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editMemberDiscard;

  /// No description provided for @editMemberKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get editMemberKeepEditing;

  /// No description provided for @editMemberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Changes take effect for the next dues cycle.'**
  String get editMemberSubtitle;

  /// No description provided for @editMemberHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get editMemberHousehold;

  /// No description provided for @editMemberHouseLabel.
  ///
  /// In en, this message translates to:
  /// **'House or family name'**
  String get editMemberHouseLabel;

  /// No description provided for @editMemberMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get editMemberMembership;

  /// No description provided for @editMemberDuesHelper.
  ///
  /// In en, this message translates to:
  /// **'Change only when the committee agreed a new amount.'**
  String get editMemberDuesHelper;

  /// No description provided for @editMemberStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Membership status'**
  String get editMemberStatusLabel;

  /// No description provided for @editMemberReversibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspending is reversible'**
  String get editMemberReversibleTitle;

  /// No description provided for @editMemberReversibleBody.
  ///
  /// In en, this message translates to:
  /// **'A suspended household keeps its history and can be reactivated from this screen.'**
  String get editMemberReversibleBody;

  /// No description provided for @editMemberSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editMemberSaveChanges;

  /// No description provided for @editMemberReactivateMember.
  ///
  /// In en, this message translates to:
  /// **'Reactivate member'**
  String get editMemberReactivateMember;

  /// No description provided for @editMemberSuspendMember.
  ///
  /// In en, this message translates to:
  /// **'Suspend member'**
  String get editMemberSuspendMember;

  /// No description provided for @approvalsApproved.
  ///
  /// In en, this message translates to:
  /// **'{name} approved.'**
  String approvalsApproved(String name);

  /// No description provided for @approvalsViewMember.
  ///
  /// In en, this message translates to:
  /// **'View member'**
  String get approvalsViewMember;

  /// No description provided for @approvalsApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t approve. {reason}'**
  String approvalsApproveFailed(String reason);

  /// No description provided for @approvalsRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reject. {reason}'**
  String approvalsRejectFailed(String reason);

  /// No description provided for @approvalsThisPerson.
  ///
  /// In en, this message translates to:
  /// **'this person'**
  String get approvalsThisPerson;

  /// No description provided for @approvalsRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this request?'**
  String get approvalsRejectTitle;

  /// No description provided for @approvalsRejectMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will not be added to the Mahal. They would need to register again to be reconsidered.'**
  String approvalsRejectMessage(String name);

  /// No description provided for @approvalsRejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get approvalsRejectRequest;

  /// No description provided for @approvalsRejected.
  ///
  /// In en, this message translates to:
  /// **'Request from {name} rejected.'**
  String approvalsRejected(String name);

  /// No description provided for @approvalsSubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'New members waiting to join your Mahal.'**
  String get approvalsSubtitleDefault;

  /// No description provided for @approvalsSubtitleNone.
  ///
  /// In en, this message translates to:
  /// **'Nobody is waiting right now.'**
  String get approvalsSubtitleNone;

  /// No description provided for @approvalsSubtitleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person is waiting to join.} other{{count} people are waiting to join.}}'**
  String approvalsSubtitleCount(int count);

  /// No description provided for @approvalsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading requests'**
  String get approvalsLoading;

  /// No description provided for @approvalsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load requests'**
  String get approvalsLoadError;

  /// No description provided for @approvalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get approvalsEmptyTitle;

  /// No description provided for @approvalsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone who asked to join has been reviewed.'**
  String get approvalsEmptyBody;

  /// No description provided for @approvalsRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested {when}'**
  String approvalsRequested(String when);

  /// No description provided for @approvalsNoId.
  ///
  /// In en, this message translates to:
  /// **'This request has no member ID and cannot be actioned here.'**
  String get approvalsNoId;

  /// No description provided for @approvalsReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get approvalsReject;

  /// No description provided for @approvalsApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approvalsApprove;

  /// No description provided for @auditFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get auditFilterAll;

  /// No description provided for @auditFilterPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get auditFilterPayment;

  /// No description provided for @auditFilterMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get auditFilterMember;

  /// No description provided for @auditFilterAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get auditFilterAlerts;

  /// No description provided for @auditFilterSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get auditFilterSystem;

  /// No description provided for @auditDateRangeHelp.
  ///
  /// In en, this message translates to:
  /// **'Show entries between'**
  String get auditDateRangeHelp;

  /// No description provided for @auditSubtitleLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the log…'**
  String get auditSubtitleLoading;

  /// No description provided for @auditSubtitleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Log unavailable'**
  String get auditSubtitleUnavailable;

  /// No description provided for @auditSubtitleShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} actions'**
  String auditSubtitleShowing(int shown, int total);

  /// No description provided for @auditSubtitleMatchesLoaded.
  ///
  /// In en, this message translates to:
  /// **'{count} matches in {loaded} of {total} loaded'**
  String auditSubtitleMatchesLoaded(int count, int loaded, int total);

  /// No description provided for @auditSubtitleMatching.
  ///
  /// In en, this message translates to:
  /// **'{count} matching actions'**
  String auditSubtitleMatching(int count);

  /// No description provided for @auditTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get auditTitle;

  /// No description provided for @auditEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Committee'**
  String get auditEyebrow;

  /// No description provided for @auditFilterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by date'**
  String get auditFilterByDate;

  /// No description provided for @auditClearDateFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear date filter'**
  String get auditClearDateFilter;

  /// No description provided for @auditSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search action, actor, details or ID…'**
  String get auditSearchHint;

  /// No description provided for @auditLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the audit log'**
  String get auditLoadError;

  /// No description provided for @auditLoadOlderError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load older entries'**
  String get auditLoadOlderError;

  /// No description provided for @auditTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get auditTryAgain;

  /// No description provided for @auditEndOfRange.
  ///
  /// In en, this message translates to:
  /// **'End of the selected dates'**
  String get auditEndOfRange;

  /// No description provided for @auditStartOfLog.
  ///
  /// In en, this message translates to:
  /// **'Start of the log'**
  String get auditStartOfLog;

  /// No description provided for @auditSystemAction.
  ///
  /// In en, this message translates to:
  /// **'System action'**
  String get auditSystemAction;

  /// No description provided for @auditLogEntry.
  ///
  /// In en, this message translates to:
  /// **'Log entry'**
  String get auditLogEntry;

  /// No description provided for @auditDetailAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get auditDetailAction;

  /// No description provided for @auditDetailBy.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get auditDetailBy;

  /// No description provided for @auditDetailRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get auditDetailRecord;

  /// No description provided for @auditRecordIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Record ID copied'**
  String get auditRecordIdCopied;

  /// No description provided for @auditDetailIp.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get auditDetailIp;

  /// No description provided for @auditDetailsHeading.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get auditDetailsHeading;

  /// No description provided for @auditBy.
  ///
  /// In en, this message translates to:
  /// **'By {actor}'**
  String auditBy(String actor);

  /// No description provided for @auditEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get auditEmptyTitle;

  /// No description provided for @auditEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Actions by the committee and the system appear here.'**
  String get auditEmptyDesc;

  /// No description provided for @auditNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching entries'**
  String get auditNoMatchTitle;

  /// No description provided for @auditNoMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \'{query}\'.'**
  String auditNoMatchQuery(String query);

  /// No description provided for @auditNoMatchFilters.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters.'**
  String get auditNoMatchFilters;

  /// No description provided for @auditClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get auditClearFilters;

  /// No description provided for @auditLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading the audit log'**
  String get auditLoadingSemantics;

  /// No description provided for @reportsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reportsFilterAll;

  /// No description provided for @reportsFilterDues.
  ///
  /// In en, this message translates to:
  /// **'Dues'**
  String get reportsFilterDues;

  /// No description provided for @reportsFilterContribution.
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get reportsFilterContribution;

  /// No description provided for @reportsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get reportsAllTime;

  /// No description provided for @reportsAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get reportsAllTypes;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get reportsEyebrow;

  /// No description provided for @reportsShareSubject.
  ///
  /// In en, this message translates to:
  /// **'{mahal} statement — {period}'**
  String reportsShareSubject(String mahal, String period);

  /// No description provided for @reportsExportError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the statement. {error}'**
  String reportsExportError(String error);

  /// No description provided for @reportsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load reports'**
  String get reportsLoadError;

  /// No description provided for @reportsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportsPeriod;

  /// No description provided for @reportsPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing statement…'**
  String get reportsPreparing;

  /// No description provided for @reportsExport.
  ///
  /// In en, this message translates to:
  /// **'Export statement (PDF)'**
  String get reportsExport;

  /// No description provided for @reportsMonthByMonth.
  ///
  /// In en, this message translates to:
  /// **'Month by month'**
  String get reportsMonthByMonth;

  /// No description provided for @reportsTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reportsTransactions;

  /// No description provided for @reportsTotalCollected.
  ///
  /// In en, this message translates to:
  /// **'TOTAL COLLECTED'**
  String get reportsTotalCollected;

  /// No description provided for @reportsAllTimeAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All time · all types'**
  String get reportsAllTimeAllTypes;

  /// No description provided for @reportsTotalsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load totals'**
  String get reportsTotalsError;

  /// No description provided for @reportsTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get reportsTryAgain;

  /// No description provided for @reportsLoadingTotals.
  ///
  /// In en, this message translates to:
  /// **'Loading totals'**
  String get reportsLoadingTotals;

  /// No description provided for @reportsDues.
  ///
  /// In en, this message translates to:
  /// **'Dues'**
  String get reportsDues;

  /// No description provided for @reportsContributions.
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get reportsContributions;

  /// No description provided for @reportsPendingDues.
  ///
  /// In en, this message translates to:
  /// **'Pending dues'**
  String get reportsPendingDues;

  /// No description provided for @reportsTransactionsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load transactions'**
  String get reportsTransactionsError;

  /// No description provided for @reportsLoadingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Loading period totals'**
  String get reportsLoadingPeriod;

  /// No description provided for @reportsSuccessfulPayments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 successful payment} other{{count} successful payments}}'**
  String reportsSuccessfulPayments(int count);

  /// No description provided for @reportsBasedOnRecent.
  ///
  /// In en, this message translates to:
  /// **'Based on the {count} most recent transactions.'**
  String reportsBasedOnRecent(int count);

  /// No description provided for @reportsLoadingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Loading breakdown'**
  String get reportsLoadingBreakdown;

  /// No description provided for @reportsNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments'**
  String get reportsNoPayments;

  /// No description provided for @reportsNoPaymentsDesc.
  ///
  /// In en, this message translates to:
  /// **'No successful payments match this period and type.'**
  String get reportsNoPaymentsDesc;

  /// No description provided for @reportsShowingOf.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}. The PDF statement lists all of them.'**
  String reportsShowingOf(int shown, int total);

  /// No description provided for @reportsPaymentsRecorded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment recorded} other{{count} payments recorded}}'**
  String reportsPaymentsRecorded(int count);

  /// No description provided for @importStepChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get importStepChoose;

  /// No description provided for @importStepValidate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get importStepValidate;

  /// No description provided for @importStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get importStepReview;

  /// No description provided for @importStepDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get importStepDone;

  /// No description provided for @importErrorExtension.
  ///
  /// In en, this message translates to:
  /// **'Choose an .xlsx, .xls or .csv file.'**
  String get importErrorExtension;

  /// No description provided for @importErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'That file is empty.'**
  String get importErrorEmpty;

  /// No description provided for @importErrorPicker.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the file picker. {error}'**
  String importErrorPicker(String error);

  /// No description provided for @importTemplateSubject.
  ///
  /// In en, this message translates to:
  /// **'MahalFlow member import template'**
  String get importTemplateSubject;

  /// No description provided for @importTemplateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the template. {error}'**
  String importTemplateError(String error);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import members'**
  String get importTitle;

  /// No description provided for @importStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String importStepOf(int step, int total);

  /// No description provided for @importSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bring a whole directory in from a spreadsheet.'**
  String get importSubtitle;

  /// No description provided for @importUploadProgress.
  ///
  /// In en, this message translates to:
  /// **'Upload progress'**
  String get importUploadProgress;

  /// No description provided for @importValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating on the server…'**
  String get importValidating;

  /// No description provided for @importUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {percent}%'**
  String importUploading(int percent);

  /// No description provided for @importFileError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t use this file'**
  String get importFileError;

  /// No description provided for @importGetTemplate.
  ///
  /// In en, this message translates to:
  /// **'Get the template'**
  String get importGetTemplate;

  /// No description provided for @importTemplateDesc.
  ///
  /// In en, this message translates to:
  /// **'A CSV with name, phone, house_name and monthly_dues columns. Save or send it from the share sheet.'**
  String get importTemplateDesc;

  /// No description provided for @importNothingSaved.
  ///
  /// In en, this message translates to:
  /// **'Nothing is saved yet'**
  String get importNothingSaved;

  /// No description provided for @importNothingSavedDesc.
  ///
  /// In en, this message translates to:
  /// **'The server checks the file first. You review its results before anything is written to the directory.'**
  String get importNothingSavedDesc;

  /// No description provided for @importUploadValidate.
  ///
  /// In en, this message translates to:
  /// **'Upload & validate'**
  String get importUploadValidate;

  /// No description provided for @importSelectedFileSemantics.
  ///
  /// In en, this message translates to:
  /// **'Selected file {name}. Tap to choose a different file.'**
  String importSelectedFileSemantics(String name);

  /// No description provided for @importChooseSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Choose a spreadsheet'**
  String get importChooseSpreadsheet;

  /// No description provided for @importAccepts.
  ///
  /// In en, this message translates to:
  /// **'Accepts .xlsx, .xls and .csv files'**
  String get importAccepts;

  /// No description provided for @importTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a different file'**
  String get importTapToChange;

  /// No description provided for @importConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Import 1 member?} other{Import {count} members?}}'**
  String importConfirmTitle(int count);

  /// No description provided for @importConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'They are added to the directory straight away. Rows with problems are skipped.'**
  String get importConfirmMessage;

  /// No description provided for @importConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importConfirm;

  /// No description provided for @importServerStatus.
  ///
  /// In en, this message translates to:
  /// **'The server reported \"{status}\" — nothing was confirmed as imported.'**
  String importServerStatus(String status);

  /// No description provided for @importCheckRows.
  ///
  /// In en, this message translates to:
  /// **'Check the rows'**
  String get importCheckRows;

  /// No description provided for @importEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importEyebrow;

  /// No description provided for @importNothingToReview.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get importNothingToReview;

  /// No description provided for @importNothingToReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Upload a spreadsheet first to see its rows here.'**
  String get importNothingToReviewDesc;

  /// No description provided for @importChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get importChooseFile;

  /// No description provided for @importOnlyValid.
  ///
  /// In en, this message translates to:
  /// **'Only valid rows will be imported.'**
  String get importOnlyValid;

  /// No description provided for @importStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get importStatTotal;

  /// No description provided for @importStatValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get importStatValid;

  /// No description provided for @importStatInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get importStatInvalid;

  /// No description provided for @importStatDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get importStatDuplicate;

  /// No description provided for @importStatImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get importStatImported;

  /// No description provided for @importStatSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get importStatSkipped;

  /// No description provided for @importStatUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get importStatUnknown;

  /// No description provided for @importStatSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} {value}'**
  String importStatSemantics(String label, String value);

  /// No description provided for @importRowsSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row will be skipped} other{{count} rows will be skipped}}'**
  String importRowsSkipped(int count);

  /// No description provided for @importFixRows.
  ///
  /// In en, this message translates to:
  /// **'Fix them in the spreadsheet and import again to add them.'**
  String get importFixRows;

  /// No description provided for @importNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Import not completed'**
  String get importNotCompleted;

  /// No description provided for @importRowsInFile.
  ///
  /// In en, this message translates to:
  /// **'Rows in your file'**
  String get importRowsInFile;

  /// No description provided for @importSample.
  ///
  /// In en, this message translates to:
  /// **'Sample: {shown} of {total} rows'**
  String importSample(int shown, int total);

  /// No description provided for @importNoPreview.
  ///
  /// In en, this message translates to:
  /// **'No row preview'**
  String get importNoPreview;

  /// No description provided for @importNoPreviewDesc.
  ///
  /// In en, this message translates to:
  /// **'The server did not return any rows to preview.'**
  String get importNoPreviewDesc;

  /// No description provided for @importNoValidRows.
  ///
  /// In en, this message translates to:
  /// **'No valid rows to import'**
  String get importNoValidRows;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Import 1 member} other{Import {count} members}}'**
  String importButton(int count);

  /// No description provided for @importChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get importChooseAnother;

  /// No description provided for @importNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get importNoPhone;

  /// No description provided for @importDuesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'₹{amount}/mo'**
  String importDuesPerMonth(String amount);

  /// No description provided for @importFinished.
  ///
  /// In en, this message translates to:
  /// **'Import finished'**
  String get importFinished;

  /// No description provided for @importServerConfirmed.
  ///
  /// In en, this message translates to:
  /// **'The server confirmed the import.'**
  String get importServerConfirmed;

  /// No description provided for @importDetailFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get importDetailFile;

  /// No description provided for @importDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get importDetailStatus;

  /// No description provided for @importDetailBatch.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get importDetailBatch;

  /// No description provided for @importGoToMembers.
  ///
  /// In en, this message translates to:
  /// **'Go to members'**
  String get importGoToMembers;

  /// No description provided for @gatewayKeyNotShown.
  ///
  /// In en, this message translates to:
  /// **'Not shown in the app'**
  String get gatewayKeyNotShown;

  /// No description provided for @gatewayTitle.
  ///
  /// In en, this message translates to:
  /// **'Gateways'**
  String get gatewayTitle;

  /// No description provided for @gatewayEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get gatewayEyebrow;

  /// No description provided for @gatewaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where member payments are processed.'**
  String get gatewaySubtitle;

  /// No description provided for @gatewayManagedTitle.
  ///
  /// In en, this message translates to:
  /// **'Managed from web admin'**
  String get gatewayManagedTitle;

  /// No description provided for @gatewayManagedDesc.
  ///
  /// In en, this message translates to:
  /// **'Gateway keys, webhook secrets and routing are set up in the MahalFlow web admin. This screen is read-only and never shows secrets.'**
  String get gatewayManagedDesc;

  /// No description provided for @gatewayConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured gateways'**
  String get gatewayConfigured;

  /// No description provided for @gatewayLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading gateways'**
  String get gatewayLoading;

  /// No description provided for @gatewayLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load gateways'**
  String get gatewayLoadError;

  /// No description provided for @gatewayEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No gateways configured'**
  String get gatewayEmptyTitle;

  /// No description provided for @gatewayEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Set one up in the web admin to accept online payments.'**
  String get gatewayEmptyDesc;

  /// No description provided for @gatewayPrimaryHeading.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY GATEWAY'**
  String get gatewayPrimaryHeading;

  /// No description provided for @gatewayActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{active} of {total} active'**
  String gatewayActiveCount(int active, int total);

  /// No description provided for @gatewayLoadingShort.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get gatewayLoadingShort;

  /// No description provided for @gatewayNoneSet.
  ///
  /// In en, this message translates to:
  /// **'None set'**
  String get gatewayNoneSet;

  /// No description provided for @gatewayRoutedHere.
  ///
  /// In en, this message translates to:
  /// **'Member payments are routed here first.'**
  String get gatewayRoutedHere;

  /// No description provided for @gatewayPrimaryRoute.
  ///
  /// In en, this message translates to:
  /// **'Primary route'**
  String get gatewayPrimaryRoute;

  /// No description provided for @gatewayFallbackRoute.
  ///
  /// In en, this message translates to:
  /// **'Fallback route'**
  String get gatewayFallbackRoute;

  /// No description provided for @gatewayKeyId.
  ///
  /// In en, this message translates to:
  /// **'Key ID'**
  String get gatewayKeyId;

  /// No description provided for @gatewayId.
  ///
  /// In en, this message translates to:
  /// **'Gateway ID'**
  String get gatewayId;

  /// No description provided for @broadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast a notice'**
  String get broadcastTitle;

  /// No description provided for @broadcastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Goes to member phones as an in-app notice'**
  String get broadcastSubtitle;

  /// No description provided for @broadcastAudienceAll.
  ///
  /// In en, this message translates to:
  /// **'All members'**
  String get broadcastAudienceAll;

  /// No description provided for @broadcastAudienceOverdue.
  ///
  /// In en, this message translates to:
  /// **'Pending dues'**
  String get broadcastAudienceOverdue;

  /// No description provided for @broadcastAudienceFamilyHeads.
  ///
  /// In en, this message translates to:
  /// **'Family heads'**
  String get broadcastAudienceFamilyHeads;

  /// No description provided for @broadcastReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly dues reminder'**
  String get broadcastReminderTitle;

  /// No description provided for @broadcastReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Respected member, our records show pending dues for your household. You can pay in the MahalFlow app.'**
  String get broadcastReminderBody;

  /// No description provided for @broadcastRecipientsOverdueAll.
  ///
  /// In en, this message translates to:
  /// **'every household with pending dues'**
  String get broadcastRecipientsOverdueAll;

  /// No description provided for @broadcastRecipientsOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 household with pending dues} other{{count} households with pending dues}}'**
  String broadcastRecipientsOverdueCount(int count);

  /// No description provided for @broadcastRecipientsFamilyHeads.
  ///
  /// In en, this message translates to:
  /// **'every family head'**
  String get broadcastRecipientsFamilyHeads;

  /// No description provided for @broadcastRecipientsAll.
  ///
  /// In en, this message translates to:
  /// **'every member'**
  String get broadcastRecipientsAll;

  /// No description provided for @broadcastRecipientsAllCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{all 1 household} other{all {count} households}}'**
  String broadcastRecipientsAllCount(int count);

  /// No description provided for @broadcastSendsTo.
  ///
  /// In en, this message translates to:
  /// **'Sends to {recipients}.'**
  String broadcastSendsTo(String recipients);

  /// No description provided for @broadcastTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get broadcastTitleRequired;

  /// No description provided for @broadcastMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Write the message'**
  String get broadcastMessageRequired;

  /// No description provided for @broadcastConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Send this notice?'**
  String get broadcastConfirmTitle;

  /// No description provided for @broadcastConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" goes to {recipients} as an in-app notice and a push notification. It cannot be unsent.'**
  String broadcastConfirmMessage(String title, String recipients);

  /// No description provided for @broadcastSendNotice.
  ///
  /// In en, this message translates to:
  /// **'Send notice'**
  String get broadcastSendNotice;

  /// No description provided for @broadcastWhoHeading.
  ///
  /// In en, this message translates to:
  /// **'WHO SHOULD GET THIS'**
  String get broadcastWhoHeading;

  /// No description provided for @broadcastNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice title'**
  String get broadcastNoticeTitle;

  /// No description provided for @broadcastTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Friday prayer timing change'**
  String get broadcastTitleHint;

  /// No description provided for @broadcastMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get broadcastMessage;

  /// No description provided for @broadcastMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write the full announcement…'**
  String get broadcastMessageHint;

  /// No description provided for @broadcastPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get broadcastPriority;

  /// No description provided for @broadcastPriorityInfo.
  ///
  /// In en, this message translates to:
  /// **'Informational'**
  String get broadcastPriorityInfo;

  /// No description provided for @broadcastPriorityReminder.
  ///
  /// In en, this message translates to:
  /// **'Dues reminder'**
  String get broadcastPriorityReminder;

  /// No description provided for @broadcastPriorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get broadcastPriorityCritical;

  /// No description provided for @broadcastNotSent.
  ///
  /// In en, this message translates to:
  /// **'Notice not sent'**
  String get broadcastNotSent;

  /// No description provided for @broadcastReviewSend.
  ///
  /// In en, this message translates to:
  /// **'Review & send'**
  String get broadcastReviewSend;

  /// No description provided for @recordPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Record a cash payment'**
  String get recordPayTitle;

  /// No description provided for @recordPaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Issues a signed receipt in the member\'s name'**
  String get recordPaySubtitle;

  /// No description provided for @recordPayThisMember.
  ///
  /// In en, this message translates to:
  /// **'this member'**
  String get recordPayThisMember;

  /// No description provided for @recordPayConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Record {amount}?'**
  String recordPayConfirmTitle(String amount);

  /// No description provided for @recordPayConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{amount} in cash from {name} for {period} ({months}). A signed receipt is issued and cannot be edited afterwards.'**
  String recordPayConfirmMessage(
      String amount, String name, String period, String months);

  /// No description provided for @recordPayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayConfirm;

  /// No description provided for @recordPayLoadingMembers.
  ///
  /// In en, this message translates to:
  /// **'Loading members'**
  String get recordPayLoadingMembers;

  /// No description provided for @recordPayMembersError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load members'**
  String get recordPayMembersError;

  /// No description provided for @recordPayTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get recordPayTryAgain;

  /// No description provided for @recordPayNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members in the directory yet.'**
  String get recordPayNoMembers;

  /// No description provided for @recordPayNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No member matches \"{query}\".'**
  String recordPayNoMatch(String query);

  /// No description provided for @recordPayShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total}. Search to narrow down.'**
  String recordPayShowing(int shown, int total);

  /// No description provided for @recordPayMemberHeading.
  ///
  /// In en, this message translates to:
  /// **'MEMBER'**
  String get recordPayMemberHeading;

  /// No description provided for @recordPaySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, phone or house…'**
  String get recordPaySearchHint;

  /// No description provided for @recordPayNoId.
  ///
  /// In en, this message translates to:
  /// **'This member record has no ID, so a payment cannot be recorded.'**
  String get recordPayNoId;

  /// No description provided for @recordPayNoDues.
  ///
  /// In en, this message translates to:
  /// **'No monthly dues amount is set for this member. Edit the member first.'**
  String get recordPayNoDues;

  /// No description provided for @recordPayNoAnchor.
  ///
  /// In en, this message translates to:
  /// **'This member has no last-paid month on record, so the next due month is unknown.'**
  String get recordPayNoAnchor;

  /// No description provided for @recordPayDuesNotSet.
  ///
  /// In en, this message translates to:
  /// **'Monthly dues not set'**
  String get recordPayDuesNotSet;

  /// No description provided for @recordPayPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} a month'**
  String recordPayPerMonth(String amount);

  /// No description provided for @recordPayChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get recordPayChange;

  /// No description provided for @recordPayCantRecord.
  ///
  /// In en, this message translates to:
  /// **'Can\'t record yet'**
  String get recordPayCantRecord;

  /// No description provided for @recordPayMonthsHeading.
  ///
  /// In en, this message translates to:
  /// **'HOW MANY MONTHS'**
  String get recordPayMonthsHeading;

  /// No description provided for @recordPayCovers.
  ///
  /// In en, this message translates to:
  /// **'Covers {period} — dues are paid in order, starting after the last paid month.'**
  String recordPayCovers(String period);

  /// No description provided for @recordPayMethodHeading.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT METHOD'**
  String get recordPayMethodHeading;

  /// No description provided for @recordPayMethodDesc.
  ///
  /// In en, this message translates to:
  /// **'Cash collected by the committee. Online payments are recorded automatically when members pay in the app.'**
  String get recordPayMethodDesc;

  /// No description provided for @recordPayTotal.
  ///
  /// In en, this message translates to:
  /// **'Total to record'**
  String get recordPayTotal;

  /// No description provided for @recordPayNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment not recorded'**
  String get recordPayNotRecorded;

  /// No description provided for @recordPayReview.
  ///
  /// In en, this message translates to:
  /// **'Review & record'**
  String get recordPayReview;

  /// No description provided for @receiptSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptSheetTitle;

  /// No description provided for @receiptSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Signed entry in the Mahal ledger'**
  String get receiptSheetSubtitle;

  /// No description provided for @receiptSheetLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading receipt'**
  String get receiptSheetLoading;

  /// No description provided for @receiptSheetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this receipt'**
  String get receiptSheetLoadError;

  /// No description provided for @receiptSheetTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get receiptSheetTryAgain;

  /// No description provided for @receiptSheetNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt number'**
  String get receiptSheetNumber;

  /// No description provided for @receiptSheetPayer.
  ///
  /// In en, this message translates to:
  /// **'Payer'**
  String get receiptSheetPayer;

  /// No description provided for @receiptSheetAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get receiptSheetAmount;

  /// No description provided for @receiptSheetType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get receiptSheetType;

  /// No description provided for @receiptSheetMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get receiptSheetMonths;

  /// No description provided for @receiptSheetDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get receiptSheetDate;

  /// No description provided for @receiptSheetHash.
  ///
  /// In en, this message translates to:
  /// **'Ledger hash'**
  String get receiptSheetHash;

  /// No description provided for @receiptSheetVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify on ledger'**
  String get receiptSheetVerify;

  /// No description provided for @receiptSheetVerifyAgain.
  ///
  /// In en, this message translates to:
  /// **'Verify again'**
  String get receiptSheetVerifyAgain;

  /// No description provided for @receiptSheetValid.
  ///
  /// In en, this message translates to:
  /// **'Signature valid'**
  String get receiptSheetValid;

  /// No description provided for @receiptSheetValidDesc.
  ///
  /// In en, this message translates to:
  /// **'The recomputed hash matches — this receipt has not been altered.'**
  String get receiptSheetValidDesc;

  /// No description provided for @receiptSheetMismatch.
  ///
  /// In en, this message translates to:
  /// **'Signature mismatch'**
  String get receiptSheetMismatch;

  /// No description provided for @receiptSheetMismatchDesc.
  ///
  /// In en, this message translates to:
  /// **'The stored hash does not match the receipt contents. Report this to the committee before relying on it.'**
  String get receiptSheetMismatchDesc;

  /// No description provided for @receiptSheetVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify'**
  String get receiptSheetVerifyFailed;

  /// No description provided for @receiptSheetTryAgainDot.
  ///
  /// In en, this message translates to:
  /// **'Try again.'**
  String get receiptSheetTryAgainDot;

  /// No description provided for @authMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get authMobileNumber;

  /// No description provided for @authFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullName;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again.'**
  String get authServerUnreachable;

  /// No description provided for @authSignedInServerUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Signed in, but could not reach the server. Try again.'**
  String get authSignedInServerUnreachable;

  /// No description provided for @authInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number'**
  String get authInvalidPhone;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get authTooManyRequests;

  /// No description provided for @authQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'Too many codes were sent. Try again later.'**
  String get authQuotaExceeded;

  /// No description provided for @authNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get authNetworkFailed;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Tap “Resend code” for a new one.'**
  String get authSessionExpired;

  /// No description provided for @authInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect. Try again.'**
  String get authInvalidCode;

  /// No description provided for @authAppNotVerified.
  ///
  /// In en, this message translates to:
  /// **'This app could not be verified for sign-in. Update the app or try again later.'**
  String get authAppNotVerified;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Dues, contributions and receipts\nfor your Mahal'**
  String get splashTagline;

  /// No description provided for @splashFooter.
  ///
  /// In en, this message translates to:
  /// **'Secure payments · Verified receipts'**
  String get splashFooter;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Know exactly what you owe'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Body.
  ///
  /// In en, this message translates to:
  /// **'Your monthly dues, pending months and advance credit — all on one screen, updated the moment a payment clears.'**
  String get onboardingSlide1Body;

  /// No description provided for @onboardingSlide1Point1.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balance at a glance'**
  String get onboardingSlide1Point1;

  /// No description provided for @onboardingSlide1Point2.
  ///
  /// In en, this message translates to:
  /// **'Month-by-month breakdown'**
  String get onboardingSlide1Point2;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Give in a few taps'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Body.
  ///
  /// In en, this message translates to:
  /// **'Pay dues or contribute to the Mahal fund with UPI, cards or net banking. AutoPay can handle the monthly dues for you.'**
  String get onboardingSlide2Body;

  /// No description provided for @onboardingSlide2Point1.
  ///
  /// In en, this message translates to:
  /// **'UPI, card and net banking'**
  String get onboardingSlide2Point1;

  /// No description provided for @onboardingSlide2Point2.
  ///
  /// In en, this message translates to:
  /// **'Optional AutoPay mandate'**
  String get onboardingSlide2Point2;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Every payment has a receipt'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Body.
  ///
  /// In en, this message translates to:
  /// **'Each transaction produces a receipt you can verify, download and share — so the committee and you always see the same record.'**
  String get onboardingSlide3Body;

  /// No description provided for @onboardingSlide3Point1.
  ///
  /// In en, this message translates to:
  /// **'Each receipt can be verified by the committee'**
  String get onboardingSlide3Point1;

  /// No description provided for @onboardingSlide3Point2.
  ///
  /// In en, this message translates to:
  /// **'Download as PDF anytime'**
  String get onboardingSlide3Point2;

  /// No description provided for @onboardingSkipSemantics.
  ///
  /// In en, this message translates to:
  /// **'Skip introduction'**
  String get onboardingSkipSemantics;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String onboardingPageOf(int current, int total);

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your dues, pay them and keep your receipts.'**
  String get loginSubtitle;

  /// No description provided for @loginPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your registered mobile number'**
  String get loginPhoneRequired;

  /// No description provided for @loginPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get loginPhoneInvalid;

  /// No description provided for @loginSendTimeout.
  ///
  /// In en, this message translates to:
  /// **'Sending the code is taking too long. Check your connection and try again.'**
  String get loginSendTimeout;

  /// No description provided for @loginSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the code. Try again.'**
  String get loginSendFailed;

  /// No description provided for @loginDemoServerError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check the connection and retry.'**
  String get loginDemoServerError;

  /// No description provided for @loginLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the page.'**
  String get loginLinkOpenFailed;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// No description provided for @loginPhoneHelper.
  ///
  /// In en, this message translates to:
  /// **'We’ll send a 6-digit code to this number.'**
  String get loginPhoneHelper;

  /// No description provided for @loginDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo access · debug build'**
  String get loginDemoTitle;

  /// No description provided for @loginDemoBody.
  ///
  /// In en, this message translates to:
  /// **'Skip OTP and open a dashboard with local seed data. Hidden in release builds.'**
  String get loginDemoBody;

  /// No description provided for @loginDemoCommittee.
  ///
  /// In en, this message translates to:
  /// **'Committee'**
  String get loginDemoCommittee;

  /// No description provided for @loginTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our '**
  String get loginTermsPrefix;

  /// No description provided for @loginTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get loginTermsLink;

  /// No description provided for @loginTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get loginTermsAnd;

  /// No description provided for @loginPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get loginPrivacyLink;

  /// No description provided for @loginTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get loginTermsSuffix;

  /// No description provided for @loginLinkSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}, link'**
  String loginLinkSemantics(String label);

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your number'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}.'**
  String otpSubtitle(String phone);

  /// No description provided for @otpSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'One-time password'**
  String get otpSectionLabel;

  /// No description provided for @otpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpCodeLabel;

  /// No description provided for @otpCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get otpCodeRequired;

  /// No description provided for @otpVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Try again.'**
  String get otpVerificationFailed;

  /// No description provided for @otpNewCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent.'**
  String get otpNewCodeSent;

  /// No description provided for @otpResendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not resend the code. Try again.'**
  String get otpResendFailed;

  /// No description provided for @otpSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get otpSending;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String otpResendIn(int seconds);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get otpVerifying;

  /// No description provided for @otpVerifyContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & continue'**
  String get otpVerifyContinue;

  /// No description provided for @otpChangeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get otpChangeNumber;

  /// No description provided for @pendingApprovalStillWaiting.
  ///
  /// In en, this message translates to:
  /// **'Still awaiting approval. We’ll let you in as soon as the committee approves.'**
  String get pendingApprovalStillWaiting;

  /// No description provided for @pendingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get pendingApprovalTitle;

  /// No description provided for @pendingApprovalRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Your request has been sent.'**
  String get pendingApprovalRequestSent;

  /// No description provided for @pendingApprovalThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks, {name}.'**
  String pendingApprovalThanks(String name);

  /// No description provided for @pendingApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'The Mahal committee needs to approve your account before you can view dues and pay.'**
  String get pendingApprovalBody;

  /// No description provided for @pendingApprovalNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get pendingApprovalNoticeTitle;

  /// No description provided for @pendingApprovalNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'You’ll get access as soon as the committee approves you. Tap “Check again” or pull down to refresh, or come back later.'**
  String get pendingApprovalNoticeBody;

  /// No description provided for @pendingApprovalChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get pendingApprovalChecking;

  /// No description provided for @pendingApprovalCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get pendingApprovalCheckAgain;

  /// No description provided for @registerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get registerNameRequired;

  /// No description provided for @registerMahalIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your Mahal ID'**
  String get registerMahalIdRequired;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This number isn’t registered yet. Tell us who you are and the committee will approve you.'**
  String get registerSubtitle;

  /// No description provided for @registerDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get registerDetailsLabel;

  /// No description provided for @registerNameHint.
  ///
  /// In en, this message translates to:
  /// **'As known to the committee'**
  String get registerNameHint;

  /// No description provided for @registerMahalIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Mahal ID'**
  String get registerMahalIdLabel;

  /// No description provided for @registerMahalIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. MH_001_CALICUT'**
  String get registerMahalIdHint;

  /// No description provided for @registerMahalIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Your Mahal committee can give you this ID if you don’t have it.'**
  String get registerMahalIdHelper;

  /// No description provided for @registerVerifiedByOtp.
  ///
  /// In en, this message translates to:
  /// **'Verified by OTP.'**
  String get registerVerifiedByOtp;

  /// No description provided for @registerNotSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get registerNotSent;

  /// No description provided for @registerNextTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get registerNextTitle;

  /// No description provided for @registerNextBody.
  ///
  /// In en, this message translates to:
  /// **'Your request goes to the Mahal committee. Once they approve you, sign in again with this number to see your dues and receipts.'**
  String get registerNextBody;

  /// No description provided for @registerSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get registerSubmitting;

  /// No description provided for @registerRequestJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to join'**
  String get registerRequestJoin;

  /// No description provided for @registerDifferentNumber.
  ///
  /// In en, this message translates to:
  /// **'Use a different number'**
  String get registerDifferentNumber;

  /// No description provided for @profileRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. {message}'**
  String profileRefreshFailed(String message);

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your details were updated.'**
  String get profileUpdated;

  /// No description provided for @profileLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogoutTitle;

  /// No description provided for @profileLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need your mobile number to sign in again.'**
  String get profileLogoutMessage;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogout;

  /// No description provided for @profileEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get profileEyebrow;

  /// No description provided for @profileEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit your details'**
  String get profileEditTooltip;

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile'**
  String get profileLoading;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile'**
  String get profileLoadError;

  /// No description provided for @profileLoadErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment.'**
  String get profileLoadErrorFallback;

  /// No description provided for @profileSectionPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get profileSectionPayments;

  /// No description provided for @profileAutopay.
  ///
  /// In en, this message translates to:
  /// **'AutoPay'**
  String get profileAutopay;

  /// No description provided for @profileAutopaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'UPI mandate for your monthly dues'**
  String get profileAutopaySubtitle;

  /// No description provided for @profileReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get profileReceipts;

  /// No description provided for @profileReceiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every payment you have made'**
  String get profileReceiptsSubtitle;

  /// No description provided for @profilePayDues.
  ///
  /// In en, this message translates to:
  /// **'Pay dues'**
  String get profilePayDues;

  /// No description provided for @profilePayDuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear pending months'**
  String get profilePayDuesSubtitle;

  /// No description provided for @profileSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get profileSectionApp;

  /// No description provided for @profileNotices.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get profileNotices;

  /// No description provided for @profileNoticesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements from the committee'**
  String get profileNoticesSubtitle;

  /// No description provided for @profileHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contact your Mahal committee office'**
  String get profileHelpSubtitle;

  /// No description provided for @profileReplayWelcome.
  ///
  /// In en, this message translates to:
  /// **'Replay welcome'**
  String get profileReplayWelcome;

  /// No description provided for @profileReplayWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show the introduction again'**
  String get profileReplayWelcomeSubtitle;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'MahalFlow · v{version}'**
  String profileVersion(String version);

  /// No description provided for @profileMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get profileMembership;

  /// No description provided for @profileMemberId.
  ///
  /// In en, this message translates to:
  /// **'Member ID'**
  String get profileMemberId;

  /// No description provided for @profileMahal.
  ///
  /// In en, this message translates to:
  /// **'Mahal'**
  String get profileMahal;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profileAddress;

  /// No description provided for @profileEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get profileEditDetails;

  /// No description provided for @editProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Your name cannot be empty'**
  String get editProfileNameRequired;

  /// No description provided for @editProfileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address'**
  String get editProfileEmailInvalid;

  /// No description provided for @editProfilePincodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'A PIN code has 6 digits'**
  String get editProfilePincodeInvalid;

  /// No description provided for @editProfileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your details. Check your connection and try again.'**
  String get editProfileSaveFailed;

  /// No description provided for @editProfileDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editProfileDiscardTitle;

  /// No description provided for @editProfileDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'Your edits have not been saved.'**
  String get editProfileDiscardMessage;

  /// No description provided for @editProfileDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editProfileDiscard;

  /// No description provided for @editProfileKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get editProfileKeepEditing;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get editProfileTitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your contact details current so receipts reach you.'**
  String get editProfileSubtitle;

  /// No description provided for @editProfileManagedNote.
  ///
  /// In en, this message translates to:
  /// **'Your mobile number and member ID are managed by the committee.'**
  String get editProfileManagedNote;

  /// No description provided for @editProfilePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get editProfilePersonal;

  /// No description provided for @editProfileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editProfileEmail;

  /// No description provided for @editProfileEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get editProfileEmailHint;

  /// No description provided for @editProfileMobileNote.
  ///
  /// In en, this message translates to:
  /// **'Contact the Mahal office to change this.'**
  String get editProfileMobileNote;

  /// No description provided for @editProfileAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get editProfileAddress;

  /// No description provided for @editProfileHouse.
  ///
  /// In en, this message translates to:
  /// **'House name or number'**
  String get editProfileHouse;

  /// No description provided for @editProfileStreet.
  ///
  /// In en, this message translates to:
  /// **'Street or landmark (optional)'**
  String get editProfileStreet;

  /// No description provided for @editProfileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get editProfileCity;

  /// No description provided for @editProfileState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get editProfileState;

  /// No description provided for @editProfilePincode.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get editProfilePincode;

  /// No description provided for @editProfileOfficeKeepsTitle.
  ///
  /// In en, this message translates to:
  /// **'What the office keeps'**
  String get editProfileOfficeKeepsTitle;

  /// No description provided for @editProfileOfficeKeepsBody.
  ///
  /// In en, this message translates to:
  /// **'Your name and house name are saved to your membership record. Email, street, city and PIN code are not kept by the office yet.'**
  String get editProfileOfficeKeepsBody;

  /// No description provided for @editProfileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get editProfileSaving;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editProfileSave;

  /// No description provided for @helpOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that app.'**
  String get helpOpenFailed;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpTitle;

  /// No description provided for @helpContactNamed.
  ///
  /// In en, this message translates to:
  /// **'For questions about your dues, receipts or AutoPay, contact the {mahalName} office.'**
  String helpContactNamed(String mahalName);

  /// No description provided for @helpContactGeneric.
  ///
  /// In en, this message translates to:
  /// **'For questions about your dues, receipts or AutoPay, contact your Mahal committee office.'**
  String get helpContactGeneric;

  /// No description provided for @helpContactNamedNoPhone.
  ///
  /// In en, this message translates to:
  /// **'For questions about your dues, receipts or AutoPay, contact the {mahalName} office in person or at their usual number.'**
  String helpContactNamedNoPhone(String mahalName);

  /// No description provided for @helpContactGenericNoPhone.
  ///
  /// In en, this message translates to:
  /// **'For questions about your dues, receipts or AutoPay, contact your Mahal committee office in person or at their usual number.'**
  String get helpContactGenericNoPhone;

  /// No description provided for @helpTipPending.
  ///
  /// In en, this message translates to:
  /// **'A payment that shows \"Pending\" usually clears in a few minutes. Do not pay again while it is pending.'**
  String get helpTipPending;

  /// No description provided for @helpTipReceipts.
  ///
  /// In en, this message translates to:
  /// **'Every confirmed payment has a receipt under Receipts.'**
  String get helpTipReceipts;

  /// No description provided for @helpTipOffice.
  ///
  /// In en, this message translates to:
  /// **'Your mobile number and member ID can only be changed by the office.'**
  String get helpTipOffice;

  /// No description provided for @helpWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get helpWhatsApp;

  /// No description provided for @helpCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get helpCall;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MahalFlow'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgain;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get commonClearSearch;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @commonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get commonUnavailable;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get commonGoBack;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get commonDownload;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get commonProfile;

  /// No description provided for @commonMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get commonMember;

  /// No description provided for @commonCopyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy {label}'**
  String commonCopyLabel(String label);

  /// No description provided for @commonCopiedLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String commonCopiedLabel(String label);

  /// No description provided for @commonShowLabel.
  ///
  /// In en, this message translates to:
  /// **'Show {label}'**
  String commonShowLabel(String label);

  /// No description provided for @commonHideLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide {label}'**
  String commonHideLabel(String label);

  /// No description provided for @commonStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {label}'**
  String commonStatusLabel(String label);

  /// Screen-reader label for a badge.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count} unread'**
  String commonUnreadCount(String label, int count);

  /// No description provided for @commonNewBadge.
  ///
  /// In en, this message translates to:
  /// **'{label}, new'**
  String commonNewBadge(String label);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get navPay;

  /// No description provided for @navReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get navReceipts;

  /// No description provided for @navNotices.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get navNotices;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageMalayalam.
  ///
  /// In en, this message translates to:
  /// **'മലയാളം'**
  String get languageMalayalam;

  /// No description provided for @settingsLanguageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get settingsLanguageTooltip;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again to continue.'**
  String get errorSessionExpired;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this.'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that record.'**
  String get errorNotFound;

  /// No description provided for @errorBadRequest.
  ///
  /// In en, this message translates to:
  /// **'That request could not be completed.'**
  String get errorBadRequest;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'The server had a problem. Try again in a moment.'**
  String get errorServer;

  /// No description provided for @errorBadResponse.
  ///
  /// In en, this message translates to:
  /// **'The server sent an unexpected response. Try again.'**
  String get errorBadResponse;

  /// No description provided for @dateJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get dateJustNow;

  /// No description provided for @dateMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String dateMinutesAgo(int count);

  /// No description provided for @dateHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String dateHoursAgo(int count);

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @dateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String dateDaysAgo(int count);

  /// No description provided for @inrSpokenRupees.
  ///
  /// In en, this message translates to:
  /// **'{amount} rupees'**
  String inrSpokenRupees(String amount);

  /// No description provided for @inrSpokenRupeesPaise.
  ///
  /// In en, this message translates to:
  /// **'{rupees} rupees {paise} paise'**
  String inrSpokenRupeesPaise(String rupees, int paise);

  /// No description provided for @duesPendingMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pending month} other{{count} pending months}}'**
  String duesPendingMonths(int count);

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// No description provided for @statusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get statusSuccess;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusInitiated.
  ///
  /// In en, this message translates to:
  /// **'Initiated'**
  String get statusInitiated;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get statusPartial;

  /// No description provided for @statusDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get statusDue;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get statusOverdue;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get statusInfo;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Notices & payments'**
  String get notifChannelName;

  /// No description provided for @notifChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Committee notices, dues reminders and payment updates'**
  String get notifChannelDescription;

  /// No description provided for @notifNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get notifNoticeTitle;

  /// No description provided for @routeNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routeNotFoundTitle;

  /// No description provided for @routeNotFoundHeading.
  ///
  /// In en, this message translates to:
  /// **'This page isn’t available'**
  String get routeNotFoundHeading;

  /// No description provided for @routeNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'The link you followed may be out of date. Head back and try again.'**
  String get routeNotFoundBody;

  /// No description provided for @settingsRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance & language'**
  String get settingsRowTitle;

  /// No description provided for @errorNoFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file was selected.'**
  String get errorNoFileSelected;

  /// No description provided for @homeYourMahal.
  ///
  /// In en, this message translates to:
  /// **'Your Mahal'**
  String get homeYourMahal;

  /// No description provided for @homeLoadingMahal.
  ///
  /// In en, this message translates to:
  /// **'Loading your Mahal…'**
  String get homeLoadingMahal;

  /// No description provided for @dashboardRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. {message}'**
  String dashboardRefreshFailed(String message);

  /// No description provided for @homeLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your dues'**
  String get homeLoadErrorTitle;

  /// No description provided for @homeLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get homeLoadErrorBody;

  /// No description provided for @homeContribute.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get homeContribute;

  /// No description provided for @homeContributeCaption.
  ///
  /// In en, this message translates to:
  /// **'Zakat and general fund'**
  String get homeContributeCaption;

  /// No description provided for @homeReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get homeReceipts;

  /// No description provided for @homeReceiptsCaption.
  ///
  /// In en, this message translates to:
  /// **'All past payments'**
  String get homeReceiptsCaption;

  /// No description provided for @homeNotices.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get homeNotices;

  /// No description provided for @homeNoticesCaption.
  ///
  /// In en, this message translates to:
  /// **'From the committee'**
  String get homeNoticesCaption;

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfile;

  /// No description provided for @homeProfileCaption.
  ///
  /// In en, this message translates to:
  /// **'Details and settings'**
  String get homeProfileCaption;

  /// No description provided for @homeOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open your profile'**
  String get homeOpenProfile;

  /// No description provided for @homeHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get homeHelp;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Assalamu Alaikum'**
  String get homeGreeting;

  /// No description provided for @homeMonthlyDuesLabel.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY DUES'**
  String get homeMonthlyDuesLabel;

  /// No description provided for @homeOutstandingDuesLabel.
  ///
  /// In en, this message translates to:
  /// **'OUTSTANDING DUES'**
  String get homeOutstandingDuesLabel;

  /// No description provided for @homeUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to Date'**
  String get homeUpToDate;

  /// No description provided for @homeActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get homeActionRequired;

  /// No description provided for @homeNoOutstandingSemantics.
  ///
  /// In en, this message translates to:
  /// **'No outstanding dues'**
  String get homeNoOutstandingSemantics;

  /// No description provided for @homeOutstandingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Outstanding dues {amount}'**
  String homeOutstandingSemantics(String amount);

  /// No description provided for @homeAdvanceCredit.
  ///
  /// In en, this message translates to:
  /// **'Advance credit {amount}'**
  String homeAdvanceCredit(String amount);

  /// No description provided for @homeAllDuesPaid.
  ///
  /// In en, this message translates to:
  /// **'All monthly dues paid in full.'**
  String get homeAllDuesPaid;

  /// No description provided for @homeAllDuesPaidUpTo.
  ///
  /// In en, this message translates to:
  /// **'All dues paid up to {month}.'**
  String homeAllDuesPaidUpTo(String month);

  /// No description provided for @homePendingDues.
  ///
  /// In en, this message translates to:
  /// **'Pending monthly dues.'**
  String get homePendingDues;

  /// No description provided for @homeMonthOverdueSemantics.
  ///
  /// In en, this message translates to:
  /// **'{month}, overdue'**
  String homeMonthOverdueSemantics(String month);

  /// No description provided for @homeMonthDueNowSemantics.
  ///
  /// In en, this message translates to:
  /// **'{month}, due now'**
  String homeMonthDueNowSemantics(String month);

  /// No description provided for @homePayAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String homePayAmount(String amount);

  /// No description provided for @homeMakeContribution.
  ///
  /// In en, this message translates to:
  /// **'Make a Contribution'**
  String get homeMakeContribution;

  /// No description provided for @homeTileSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}. {caption}'**
  String homeTileSemantics(String label, String caption);

  /// No description provided for @homeLatestPayment.
  ///
  /// In en, this message translates to:
  /// **'LATEST PAYMENT'**
  String get homeLatestPayment;

  /// No description provided for @homeNoPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get homeNoPaymentsYet;

  /// No description provided for @homeNoPaymentsBody.
  ///
  /// In en, this message translates to:
  /// **'Your receipts will appear here once you pay.'**
  String get homeNoPaymentsBody;

  /// No description provided for @homePayDuesNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Dues Now'**
  String get homePayDuesNow;

  /// No description provided for @homeMonthsDues.
  ///
  /// In en, this message translates to:
  /// **'{months} Dues'**
  String homeMonthsDues(String months);

  /// No description provided for @homeLastPaymentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Last payment amount not available'**
  String get homeLastPaymentUnavailable;

  /// No description provided for @homeLastPaymentSemantics.
  ///
  /// In en, this message translates to:
  /// **'Last payment {amount}'**
  String homeLastPaymentSemantics(String amount);

  /// No description provided for @homePaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on {date}'**
  String homePaidOn(String date);

  /// No description provided for @homeAutoPayOff.
  ///
  /// In en, this message translates to:
  /// **'AutoPay is off'**
  String get homeAutoPayOff;

  /// No description provided for @homeAutoPayBody.
  ///
  /// In en, this message translates to:
  /// **'Never miss a month. Pay dues automatically.'**
  String get homeAutoPayBody;

  /// No description provided for @homeAutoPaySetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get homeAutoPaySetUp;

  /// No description provided for @alertsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get alertsFilterAll;

  /// No description provided for @alertsFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get alertsFilterUnread;

  /// No description provided for @alertsFilterPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get alertsFilterPayment;

  /// No description provided for @alertsFilterSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get alertsFilterSystem;

  /// No description provided for @alertsUnreadSemantics.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get alertsUnreadSemantics;

  /// No description provided for @alertsAlreadyRead.
  ///
  /// In en, this message translates to:
  /// **'Everything is already read'**
  String get alertsAlreadyRead;

  /// No description provided for @alertsMarkedAllRead.
  ///
  /// In en, this message translates to:
  /// **'All notices marked as read'**
  String get alertsMarkedAllRead;

  /// No description provided for @alertsMarkReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t mark notices as read. Try again.'**
  String get alertsMarkReadFailed;

  /// No description provided for @alertsClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all notices?'**
  String get alertsClearTitle;

  /// No description provided for @alertsClearMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes every notice from your inbox. It cannot be undone.'**
  String get alertsClearMessage;

  /// No description provided for @alertsClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get alertsClearConfirm;

  /// No description provided for @alertsCleared.
  ///
  /// In en, this message translates to:
  /// **'All notices cleared'**
  String get alertsCleared;

  /// No description provided for @alertsClearFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clear notices. Try again.'**
  String get alertsClearFailed;

  /// No description provided for @alertsClearedOne.
  ///
  /// In en, this message translates to:
  /// **'Cleared: {title}'**
  String alertsClearedOne(String title);

  /// No description provided for @alertsRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove that notice.'**
  String get alertsRemoveFailed;

  /// No description provided for @alertsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notices'**
  String get alertsLoadError;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notices'**
  String get alertsTitle;

  /// No description provided for @alertsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'From the committee'**
  String get alertsEyebrow;

  /// No description provided for @alertsLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Loading your notices…'**
  String get alertsLoadingSubtitle;

  /// No description provided for @alertsErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notices could not be loaded.'**
  String get alertsErrorSubtitle;

  /// No description provided for @alertsCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up.'**
  String get alertsCaughtUp;

  /// No description provided for @alertsUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String alertsUnreadCount(int count);

  /// No description provided for @alertsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get alertsMarkAllRead;

  /// No description provided for @alertsClearAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear all notices'**
  String get alertsClearAllTooltip;

  /// No description provided for @alertsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notices'**
  String get alertsEmptyTitle;

  /// No description provided for @alertsEmptyFilteredTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get alertsEmptyFilteredTitle;

  /// No description provided for @alertsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Announcements and dues reminders from the committee appear here.'**
  String get alertsEmptyBody;

  /// No description provided for @alertsEmptyFilteredBody.
  ///
  /// In en, this message translates to:
  /// **'Try another filter, or pull down to refresh.'**
  String get alertsEmptyFilteredBody;

  /// No description provided for @alertsLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading notices'**
  String get alertsLoadingSemantics;

  /// No description provided for @alertNotice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get alertNotice;

  /// No description provided for @alertTypePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get alertTypePayment;

  /// No description provided for @alertTypeDuesReminder.
  ///
  /// In en, this message translates to:
  /// **'Dues reminder'**
  String get alertTypeDuesReminder;

  /// No description provided for @alertTypeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get alertTypeConfirmed;

  /// No description provided for @alertTypeImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get alertTypeImportant;

  /// No description provided for @alertTypeAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get alertTypeAnnouncement;

  /// No description provided for @alertTypeNotice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get alertTypeNotice;

  /// No description provided for @alertNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No further details were provided.'**
  String get alertNoDetails;

  /// No description provided for @alertWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why you got this'**
  String get alertWhyTitle;

  /// No description provided for @alertWhyBody.
  ///
  /// In en, this message translates to:
  /// **'Your account shows dues that are not yet cleared.'**
  String get alertWhyBody;

  /// No description provided for @receiptsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get receiptsFilterAll;

  /// No description provided for @receiptsFilterMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get receiptsFilterMonthly;

  /// No description provided for @receiptsFilterContribution.
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get receiptsFilterContribution;

  /// No description provided for @receiptsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load receipts'**
  String get receiptsLoadError;

  /// No description provided for @receiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptsTitle;

  /// No description provided for @receiptsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get receiptsEyebrow;

  /// No description provided for @receiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every payment you have made, with a receipt for each.'**
  String get receiptsSubtitle;

  /// No description provided for @receiptsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No receipts yet'**
  String get receiptsEmptyTitle;

  /// No description provided for @receiptsEmptyMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Monthly receipts'**
  String get receiptsEmptyMonthlyTitle;

  /// No description provided for @receiptsEmptyContributionTitle.
  ///
  /// In en, this message translates to:
  /// **'No Contribution receipts'**
  String get receiptsEmptyContributionTitle;

  /// No description provided for @receiptsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Once you pay your dues or contribute, every receipt lands here.'**
  String get receiptsEmptyBody;

  /// No description provided for @receiptsEmptyFilteredBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter, or pull down to refresh.'**
  String get receiptsEmptyFilteredBody;

  /// No description provided for @receiptsPayDues.
  ///
  /// In en, this message translates to:
  /// **'Pay Dues'**
  String get receiptsPayDues;

  /// No description provided for @receiptsLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading receipts'**
  String get receiptsLoadingSemantics;

  /// No description provided for @receiptMonthlyDues.
  ///
  /// In en, this message translates to:
  /// **'Monthly Dues'**
  String get receiptMonthlyDues;

  /// No description provided for @receiptMahalContribution.
  ///
  /// In en, this message translates to:
  /// **'Mahal Contribution'**
  String get receiptMahalContribution;

  /// No description provided for @receiptMonthlyDuesLower.
  ///
  /// In en, this message translates to:
  /// **'Monthly dues'**
  String get receiptMonthlyDuesLower;

  /// No description provided for @receiptContribution.
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get receiptContribution;

  /// No description provided for @receiptMethodOnline.
  ///
  /// In en, this message translates to:
  /// **'Online ({gateway})'**
  String receiptMethodOnline(String gateway);

  /// No description provided for @receiptMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get receiptMethodCash;

  /// No description provided for @receiptStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get receiptStatusRefunded;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptPdfSavedNoViewer.
  ///
  /// In en, this message translates to:
  /// **'Receipt saved. No PDF viewer found — use Share to send it.'**
  String get receiptPdfSavedNoViewer;

  /// No description provided for @receiptPdfFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the receipt PDF. Try again.'**
  String get receiptPdfFailed;

  /// No description provided for @receiptShareHeading.
  ///
  /// In en, this message translates to:
  /// **'MahalFlow payment receipt'**
  String get receiptShareHeading;

  /// No description provided for @receiptShareNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt no: {number}'**
  String receiptShareNumber(String number);

  /// No description provided for @receiptShareMember.
  ///
  /// In en, this message translates to:
  /// **'Member: {name}'**
  String receiptShareMember(String name);

  /// No description provided for @receiptShareAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String receiptShareAmount(String amount);

  /// No description provided for @receiptShareFor.
  ///
  /// In en, this message translates to:
  /// **'For: {title} ({subtitle})'**
  String receiptShareFor(String title, String subtitle);

  /// No description provided for @receiptShareDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String receiptShareDate(String date);

  /// No description provided for @receiptSharePaidVia.
  ///
  /// In en, this message translates to:
  /// **'Paid via: {method}'**
  String receiptSharePaidVia(String method);

  /// No description provided for @receiptShareStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String receiptShareStatus(String status);

  /// No description provided for @receiptShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Receipt {number}'**
  String receiptShareSubject(String number);

  /// No description provided for @receiptShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the share sheet. Try again.'**
  String get receiptShareFailed;

  /// No description provided for @receiptDetailsCopied.
  ///
  /// In en, this message translates to:
  /// **'Receipt details copied'**
  String get receiptDetailsCopied;

  /// No description provided for @receiptVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified record'**
  String get receiptVerifiedTitle;

  /// No description provided for @receiptVerifiedBody.
  ///
  /// In en, this message translates to:
  /// **'Issued by your Mahal through MahalFlow. Safe to share.'**
  String get receiptVerifiedBody;

  /// No description provided for @receiptPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment {status}'**
  String receiptPaymentStatus(String status);

  /// No description provided for @receiptNotConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'This record is not a confirmed payment receipt.'**
  String get receiptNotConfirmedBody;

  /// No description provided for @receiptCopyAsText.
  ///
  /// In en, this message translates to:
  /// **'Copy details as text'**
  String get receiptCopyAsText;

  /// No description provided for @receiptDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get receiptDownloadPdf;

  /// No description provided for @receiptPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get receiptPreparing;

  /// No description provided for @receiptShareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt'**
  String get receiptShareReceipt;

  /// No description provided for @receiptPaymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get receiptPaymentSuccessful;

  /// No description provided for @receiptNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt number'**
  String get receiptNumberLabel;

  /// No description provided for @receiptNumberCopied.
  ///
  /// In en, this message translates to:
  /// **'Receipt number copied'**
  String get receiptNumberCopied;

  /// No description provided for @receiptMemberLabel.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get receiptMemberLabel;

  /// No description provided for @receiptPaymentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment type'**
  String get receiptPaymentTypeLabel;

  /// No description provided for @receiptCoversLabel.
  ///
  /// In en, this message translates to:
  /// **'Covers'**
  String get receiptCoversLabel;

  /// No description provided for @receiptFundLabel.
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get receiptFundLabel;

  /// No description provided for @receiptPaidViaLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid via'**
  String get receiptPaidViaLabel;

  /// No description provided for @receiptFooter.
  ///
  /// In en, this message translates to:
  /// **'Computer-generated receipt. No signature required.'**
  String get receiptFooter;

  /// No description provided for @autopayRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh AutoPay. {message}'**
  String autopayRefreshFailed(String message);

  /// No description provided for @autopayFrequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get autopayFrequencyMonthly;

  /// No description provided for @autopayFrequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get autopayFrequencyWeekly;

  /// No description provided for @autopayFrequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get autopayFrequencyDaily;

  /// No description provided for @autopayFrequencyHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get autopayFrequencyHourly;

  /// No description provided for @autopayFrequencyMinutely.
  ///
  /// In en, this message translates to:
  /// **'Minutely'**
  String get autopayFrequencyMinutely;

  /// No description provided for @autopayScheduleMinutely.
  ///
  /// In en, this message translates to:
  /// **'every minute (test)'**
  String get autopayScheduleMinutely;

  /// No description provided for @autopayScheduleHourly.
  ///
  /// In en, this message translates to:
  /// **'every hour (test)'**
  String get autopayScheduleHourly;

  /// No description provided for @autopayScheduleDaily.
  ///
  /// In en, this message translates to:
  /// **'every day (test)'**
  String get autopayScheduleDaily;

  /// No description provided for @autopayScheduleWeekly.
  ///
  /// In en, this message translates to:
  /// **'every week'**
  String get autopayScheduleWeekly;

  /// No description provided for @autopayScheduleMonthly.
  ///
  /// In en, this message translates to:
  /// **'on the {day} of every month'**
  String autopayScheduleMonthly(String day);

  /// No description provided for @autopayConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm AutoPay'**
  String get autopayConfirmTitle;

  /// No description provided for @autopayConfirmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review before your bank asks you to approve'**
  String get autopayConfirmSubtitle;

  /// No description provided for @autopayAmountPerDebit.
  ///
  /// In en, this message translates to:
  /// **'Amount per debit'**
  String get autopayAmountPerDebit;

  /// No description provided for @autopayMaxPerDebit.
  ///
  /// In en, this message translates to:
  /// **'Maximum per debit'**
  String get autopayMaxPerDebit;

  /// No description provided for @autopayWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get autopayWhen;

  /// No description provided for @autopayValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get autopayValidUntil;

  /// No description provided for @autopayAuthChargeNote.
  ///
  /// In en, this message translates to:
  /// **'To register the mandate your bank makes a small one-time authorisation charge (shown on the next screen). Future debits never exceed the maximum above, and you can cancel any time.'**
  String get autopayAuthChargeNote;

  /// No description provided for @autopaySignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to set up AutoPay.'**
  String get autopaySignInAgain;

  /// No description provided for @autopayStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start AutoPay setup. Nothing was charged — try again.'**
  String get autopayStartFailed;

  /// No description provided for @autopayOpenMandateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the mandate screen. Nothing was charged — try again.'**
  String get autopayOpenMandateFailed;

  /// No description provided for @autopayCancelSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel AutoPay setup?'**
  String get autopayCancelSetupTitle;

  /// No description provided for @autopayTurnOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off AutoPay?'**
  String get autopayTurnOffTitle;

  /// No description provided for @autopayCancelSetupMessage.
  ///
  /// In en, this message translates to:
  /// **'The mandate that is waiting for your bank will be cancelled. You can set up AutoPay again later.'**
  String get autopayCancelSetupMessage;

  /// No description provided for @autopayTurnOffMessage.
  ///
  /// In en, this message translates to:
  /// **'No further dues will be debited automatically. You will need to pay each month yourself.'**
  String get autopayTurnOffMessage;

  /// No description provided for @autopayCancelSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Setup'**
  String get autopayCancelSetupAction;

  /// No description provided for @autopayTurnOffAction.
  ///
  /// In en, this message translates to:
  /// **'Turn Off'**
  String get autopayTurnOffAction;

  /// No description provided for @autopayKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get autopayKeep;

  /// No description provided for @autopaySetupCancelled.
  ///
  /// In en, this message translates to:
  /// **'AutoPay setup cancelled.'**
  String get autopaySetupCancelled;

  /// No description provided for @autopayTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'AutoPay turned off. No further debits.'**
  String get autopayTurnedOff;

  /// No description provided for @autopayCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel AutoPay. Try again.'**
  String get autopayCancelFailed;

  /// No description provided for @autopayBankApprovedPending.
  ///
  /// In en, this message translates to:
  /// **'Your bank approved the mandate. Activation is pending.'**
  String get autopayBankApprovedPending;

  /// No description provided for @autopaySetupFailedReason.
  ///
  /// In en, this message translates to:
  /// **'Mandate setup failed: {reason}'**
  String autopaySetupFailedReason(String reason);

  /// No description provided for @autopaySetupCancelledNoCharge.
  ///
  /// In en, this message translates to:
  /// **'Mandate setup was cancelled. Nothing was charged.'**
  String get autopaySetupCancelledNoCharge;

  /// No description provided for @autopayErrorReason.
  ///
  /// In en, this message translates to:
  /// **'AutoPay error: {reason}'**
  String autopayErrorReason(String reason);

  /// No description provided for @autopayOnTitle.
  ///
  /// In en, this message translates to:
  /// **'AutoPay is on'**
  String get autopayOnTitle;

  /// No description provided for @autopayOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your dues will be paid automatically'**
  String get autopayOnSubtitle;

  /// No description provided for @autopayOnMessage.
  ///
  /// In en, this message translates to:
  /// **'Your mandate is registered. {amount} will be debited {schedule}, and a receipt is issued every time it runs.'**
  String autopayOnMessage(String amount, String schedule);

  /// No description provided for @autopayYourDues.
  ///
  /// In en, this message translates to:
  /// **'Your dues'**
  String get autopayYourDues;

  /// No description provided for @autopayFirstDebit.
  ///
  /// In en, this message translates to:
  /// **'First debit'**
  String get autopayFirstDebit;

  /// No description provided for @autopayMandateId.
  ///
  /// In en, this message translates to:
  /// **'Mandate ID'**
  String get autopayMandateId;

  /// No description provided for @autopayTitle.
  ///
  /// In en, this message translates to:
  /// **'AutoPay'**
  String get autopayTitle;

  /// No description provided for @autopayEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get autopayEyebrow;

  /// No description provided for @autopaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss a month. Cancel any time from your profile.'**
  String get autopaySubtitle;

  /// No description provided for @autopayLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading AutoPay status'**
  String get autopayLoadingSemantics;

  /// No description provided for @autopayLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load AutoPay'**
  String get autopayLoadFailedTitle;

  /// No description provided for @autopayLoadFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment.'**
  String get autopayLoadFailedFallback;

  /// No description provided for @autopayWaitingBankTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your bank'**
  String get autopayWaitingBankTitle;

  /// No description provided for @autopayWaitingBankMessage.
  ///
  /// In en, this message translates to:
  /// **'Your bank has not confirmed the mandate yet. Pull down or tap Check Status to refresh. Do not set it up again.'**
  String get autopayWaitingBankMessage;

  /// No description provided for @autopayDuesNotSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Dues amount not set'**
  String get autopayDuesNotSetTitle;

  /// No description provided for @autopayDuesNotSetMessage.
  ///
  /// In en, this message translates to:
  /// **'Your monthly dues amount is not recorded yet, so AutoPay cannot be set up. Contact the Mahal office.'**
  String get autopayDuesNotSetMessage;

  /// No description provided for @autopayHowItWorksTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get autopayHowItWorksTitle;

  /// No description provided for @autopayHowItWorksMessage.
  ///
  /// In en, this message translates to:
  /// **'Your bank asks you to approve the mandate once. After that each debit runs on its own and issues a receipt.'**
  String get autopayHowItWorksMessage;

  /// No description provided for @autopayStatePendingActivation.
  ///
  /// In en, this message translates to:
  /// **'Pending activation'**
  String get autopayStatePendingActivation;

  /// No description provided for @autopayStateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autopayStateOff;

  /// No description provided for @autopayDebitTestCadence.
  ///
  /// In en, this message translates to:
  /// **'DEBIT (TEST CADENCE)'**
  String get autopayDebitTestCadence;

  /// No description provided for @autopayMonthlyDebit.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY DEBIT'**
  String get autopayMonthlyDebit;

  /// No description provided for @autopayDebitedBy.
  ///
  /// In en, this message translates to:
  /// **'Debited {schedule} by UPI e-Mandate.'**
  String autopayDebitedBy(String schedule);

  /// No description provided for @autopayMandateDetails.
  ///
  /// In en, this message translates to:
  /// **'Mandate details'**
  String get autopayMandateDetails;

  /// No description provided for @autopayPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get autopayPaymentMethod;

  /// No description provided for @autopayFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get autopayFrequency;

  /// No description provided for @autopayNextDebit.
  ///
  /// In en, this message translates to:
  /// **'Next debit'**
  String get autopayNextDebit;

  /// No description provided for @autopayLastDebit.
  ///
  /// In en, this message translates to:
  /// **'Last debit'**
  String get autopayLastDebit;

  /// No description provided for @autopayAuthorisation.
  ///
  /// In en, this message translates to:
  /// **'Authorisation'**
  String get autopayAuthorisation;

  /// No description provided for @autopaySmallOneTimeCharge.
  ///
  /// In en, this message translates to:
  /// **'Small one-time charge'**
  String get autopaySmallOneTimeCharge;

  /// No description provided for @autopayTestFrequency.
  ///
  /// In en, this message translates to:
  /// **'Test frequency (debug build only)'**
  String get autopayTestFrequency;

  /// No description provided for @autopayFrequencySemantics.
  ///
  /// In en, this message translates to:
  /// **'{frequency} frequency'**
  String autopayFrequencySemantics(String frequency);

  /// No description provided for @autopayTurningOff.
  ///
  /// In en, this message translates to:
  /// **'Turning off…'**
  String get autopayTurningOff;

  /// No description provided for @autopayTurnOffButton.
  ///
  /// In en, this message translates to:
  /// **'Turn Off AutoPay'**
  String get autopayTurnOffButton;

  /// No description provided for @autopayCheckStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get autopayCheckStatus;

  /// No description provided for @autopaySettingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up…'**
  String get autopaySettingUp;

  /// No description provided for @autopayNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get autopayNotNow;

  /// No description provided for @duesPayRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh. {message}'**
  String duesPayRefreshFailed(String message);

  /// No description provided for @duesPaySignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to pay your dues.'**
  String get duesPaySignInAgain;

  /// No description provided for @duesPayHelpNote.
  ///
  /// In en, this message translates to:
  /// **'Your dues are {amount} per month. Months are paid in order, oldest first.'**
  String duesPayHelpNote(String amount);

  /// No description provided for @duesPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Dues'**
  String get duesPayTitle;

  /// No description provided for @duesPayEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get duesPayEyebrow;

  /// No description provided for @duesPaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the months you want to clear.'**
  String get duesPaySubtitle;

  /// No description provided for @duesPayHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get duesPayHelp;

  /// No description provided for @duesPayLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your dues'**
  String get duesPayLoadFailedTitle;

  /// No description provided for @duesPayLoadFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get duesPayLoadFailedFallback;

  /// No description provided for @duesPayPeriodNotSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Dues period not set up'**
  String get duesPayPeriodNotSetTitle;

  /// No description provided for @duesPayPeriodNotSetMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Mahal has not recorded which months you have paid, so dues cannot be paid in the app yet. Contact the office to set this up.'**
  String get duesPayPeriodNotSetMessage;

  /// No description provided for @duesPayGetHelp.
  ///
  /// In en, this message translates to:
  /// **'Get Help'**
  String get duesPayGetHelp;

  /// No description provided for @duesPayUpToDateTitle.
  ///
  /// In en, this message translates to:
  /// **'You are up to date'**
  String get duesPayUpToDateTitle;

  /// No description provided for @duesPayUpToDateMessage.
  ///
  /// In en, this message translates to:
  /// **'No months are due. You can pay ahead below.'**
  String get duesPayUpToDateMessage;

  /// No description provided for @duesPayDueNowHeader.
  ///
  /// In en, this message translates to:
  /// **'DUE NOW'**
  String get duesPayDueNowHeader;

  /// No description provided for @duesPayPayAheadHeader.
  ///
  /// In en, this message translates to:
  /// **'PAY AHEAD'**
  String get duesPayPayAheadHeader;

  /// No description provided for @duesPayContributeTitle.
  ///
  /// In en, this message translates to:
  /// **'Make a contribution'**
  String get duesPayContributeTitle;

  /// No description provided for @duesPayContributeMessage.
  ///
  /// In en, this message translates to:
  /// **'Zakat, Masjid or the general fund.'**
  String get duesPayContributeMessage;

  /// No description provided for @duesPayOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get duesPayOpen;

  /// No description provided for @duesPayMonthsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month selected} other{{count} months selected}}'**
  String duesPayMonthsSelected(int count);

  /// No description provided for @duesPayNoFee.
  ///
  /// In en, this message translates to:
  /// **'No processing fee'**
  String get duesPayNoFee;

  /// No description provided for @duesPayProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get duesPayProcessing;

  /// No description provided for @duesPayContinueToPay.
  ///
  /// In en, this message translates to:
  /// **'Continue to Pay'**
  String get duesPayContinueToPay;

  /// No description provided for @duesPayPayAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String duesPayPayAmount(String amount);

  /// No description provided for @duesPayTotalSelected.
  ///
  /// In en, this message translates to:
  /// **'TOTAL SELECTED'**
  String get duesPayTotalSelected;

  /// No description provided for @duesPayMonthCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String duesPayMonthCount(int count);

  /// No description provided for @duesPayTotalUnavailableSemantics.
  ///
  /// In en, this message translates to:
  /// **'Total not available'**
  String get duesPayTotalUnavailableSemantics;

  /// No description provided for @duesPayTotalSemantics.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String duesPayTotalSemantics(String amount);

  /// No description provided for @duesPaySelectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one month below to continue.'**
  String get duesPaySelectAtLeastOne;

  /// No description provided for @duesPayPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} per month'**
  String duesPayPerMonth(String amount);

  /// No description provided for @duesPayExactAmountNote.
  ///
  /// In en, this message translates to:
  /// **'The exact amount is shown on the payment screen.'**
  String get duesPayExactAmountNote;

  /// No description provided for @duesPaySelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get duesPaySelectAll;

  /// No description provided for @duesPaySelectAllSemantics.
  ///
  /// In en, this message translates to:
  /// **'Select all due months'**
  String get duesPaySelectAllSemantics;

  /// No description provided for @duesPayStatusDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get duesPayStatusDueNow;

  /// No description provided for @duesPayStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get duesPayStatusUpcoming;

  /// No description provided for @duesPayLoadingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Loading your dues'**
  String get duesPayLoadingSemantics;

  /// No description provided for @payuStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the payment. No money was taken — try again.'**
  String get payuStartFailed;

  /// No description provided for @payuOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the payment screen. No money was taken — try again.'**
  String get payuOpenFailed;

  /// No description provided for @payuCouldNotComplete.
  ///
  /// In en, this message translates to:
  /// **'The payment could not be completed.'**
  String get payuCouldNotComplete;

  /// No description provided for @contributionFundZakat.
  ///
  /// In en, this message translates to:
  /// **'Zakat Fund'**
  String get contributionFundZakat;

  /// No description provided for @contributionFundZakatBlurb.
  ///
  /// In en, this message translates to:
  /// **'Obligatory charity, distributed by the committee'**
  String get contributionFundZakatBlurb;

  /// No description provided for @contributionFundGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Fund'**
  String get contributionFundGeneral;

  /// No description provided for @contributionFundGeneralBlurb.
  ///
  /// In en, this message translates to:
  /// **'Day-to-day running of the Mahal'**
  String get contributionFundGeneralBlurb;

  /// No description provided for @contributionFundMasjid.
  ///
  /// In en, this message translates to:
  /// **'Masjid Renovation'**
  String get contributionFundMasjid;

  /// No description provided for @contributionFundMasjidBlurb.
  ///
  /// In en, this message translates to:
  /// **'Building works and maintenance'**
  String get contributionFundMasjidBlurb;

  /// No description provided for @contributionFundEducation.
  ///
  /// In en, this message translates to:
  /// **'Education Help'**
  String get contributionFundEducation;

  /// No description provided for @contributionFundEducationBlurb.
  ///
  /// In en, this message translates to:
  /// **'Madrasa and student support'**
  String get contributionFundEducationBlurb;

  /// No description provided for @contributionFundMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical Aid'**
  String get contributionFundMedical;

  /// No description provided for @contributionFundMedicalBlurb.
  ///
  /// In en, this message translates to:
  /// **'Emergency help for families in need'**
  String get contributionFundMedicalBlurb;

  /// No description provided for @contributionMinError.
  ///
  /// In en, this message translates to:
  /// **'The minimum contribution is {amount}'**
  String contributionMinError(String amount);

  /// No description provided for @contributionMaxError.
  ///
  /// In en, this message translates to:
  /// **'The maximum in the app is {amount}. Contact the office for larger amounts.'**
  String contributionMaxError(String amount);

  /// No description provided for @contributionSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to contribute.'**
  String get contributionSignInAgain;

  /// No description provided for @contributionConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Give {amount}?'**
  String contributionConfirmTitle(String amount);

  /// No description provided for @contributionConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about to contribute {amount} to {fund}. Please check the amount before you continue.'**
  String contributionConfirmMessage(String amount, String fund);

  /// No description provided for @contributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get contributionTitle;

  /// No description provided for @contributionEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Give'**
  String get contributionEyebrow;

  /// No description provided for @contributionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support the Mahal beyond your monthly dues.'**
  String get contributionSubtitle;

  /// No description provided for @contributionWhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should it go?'**
  String get contributionWhereTitle;

  /// No description provided for @contributionNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get contributionNoteLabel;

  /// No description provided for @contributionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. In memory of family, Eid charity'**
  String get contributionNoteHint;

  /// No description provided for @contributionGiveAmount.
  ///
  /// In en, this message translates to:
  /// **'Give {amount}'**
  String contributionGiveAmount(String amount);

  /// No description provided for @contributionEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get contributionEnterAmount;

  /// No description provided for @contributionAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Contribution amount'**
  String get contributionAmountLabel;

  /// No description provided for @contributionAmountSemantics.
  ///
  /// In en, this message translates to:
  /// **'Contribution amount in rupees'**
  String get contributionAmountSemantics;

  /// No description provided for @contributionRange.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max}'**
  String contributionRange(String min, String max);

  /// No description provided for @payResultAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'AMOUNT'**
  String get payResultAmountLabel;

  /// No description provided for @payResultCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get payResultCancelledTitle;

  /// No description provided for @payResultFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get payResultFailedTitle;

  /// No description provided for @payResultCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'You left the payment screen before paying. No money was taken.'**
  String get payResultCancelledMessage;

  /// No description provided for @payResultFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'The payment did not go through. If your bank shows a debit, it is reversed automatically. You can try again.'**
  String get payResultFailedMessage;

  /// No description provided for @payResultBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get payResultBackHome;

  /// No description provided for @payResultReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get payResultReason;

  /// No description provided for @payResultFor.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get payResultFor;

  /// No description provided for @payResultFund.
  ///
  /// In en, this message translates to:
  /// **'Fund'**
  String get payResultFund;

  /// No description provided for @payResultAttempted.
  ///
  /// In en, this message translates to:
  /// **'Attempted'**
  String get payResultAttempted;

  /// No description provided for @payResultAmountDebited.
  ///
  /// In en, this message translates to:
  /// **'Amount debited'**
  String get payResultAmountDebited;

  /// No description provided for @payResultNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get payResultNone;

  /// No description provided for @payResultPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get payResultPendingTitle;

  /// No description provided for @payResultPendingMessageDues.
  ///
  /// In en, this message translates to:
  /// **'Your bank is still confirming this. Do not pay again — we will update your dues as soon as it clears.'**
  String get payResultPendingMessageDues;

  /// No description provided for @payResultPendingMessageContribution.
  ///
  /// In en, this message translates to:
  /// **'Your bank is still confirming this. Do not pay again — we will update your receipts as soon as it clears.'**
  String get payResultPendingMessageContribution;

  /// No description provided for @payResultCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get payResultCheckAgain;

  /// No description provided for @payResultViewReceipts.
  ///
  /// In en, this message translates to:
  /// **'View Receipts'**
  String get payResultViewReceipts;

  /// No description provided for @payResultCovers.
  ///
  /// In en, this message translates to:
  /// **'Covers'**
  String get payResultCovers;

  /// No description provided for @payResultStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get payResultStarted;

  /// No description provided for @payResultLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked'**
  String get payResultLastChecked;

  /// No description provided for @payResultChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get payResultChecking;

  /// No description provided for @payResultCheckFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check the status'**
  String get payResultCheckFailedTitle;

  /// No description provided for @payResultNextTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get payResultNextTitle;

  /// No description provided for @payResultNextMessage.
  ///
  /// In en, this message translates to:
  /// **'Most payments clear within a few minutes. If money left your account and this does not clear, your bank reverses it or the office can confirm it from the receipt list.'**
  String get payResultNextMessage;

  /// No description provided for @payResultSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get payResultSuccessTitle;

  /// No description provided for @payResultThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get payResultThankYou;

  /// No description provided for @payResultDuesClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your dues are cleared. A receipt has been issued in your name.'**
  String get payResultDuesClearedMessage;

  /// No description provided for @payResultContributionReceivedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your contribution was received. A receipt has been issued in your name.'**
  String get payResultContributionReceivedMessage;

  /// No description provided for @payResultViewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get payResultViewReceipt;

  /// No description provided for @payResultPaidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get payResultPaidOn;

  /// No description provided for @payResultReceiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt number'**
  String get payResultReceiptNumber;
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
      <String>['en', 'ml'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ml':
      return AppLocalizationsMl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
