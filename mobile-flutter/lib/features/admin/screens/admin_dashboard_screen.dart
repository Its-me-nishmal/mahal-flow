import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../widgets/admin_bottom_nav_bar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();

  double _totalCollected = 0;
  double _pendingDues = 0;
  int _paidMembers = 0;
  int _pendingMembers = 0;
  int _totalMembers = 0;
  String _subscriptionStatus = "ACTIVE";
  List<dynamic> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.markSessionReady();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final data = await _apiService.getAdminDashboard();
    final receipts = await _apiService.getRecentReceipts();
    if (mounted) {
      setState(() {
        if (data != null) {
          _totalCollected =
              (data["total_collected_mtd"] as num?)?.toDouble() ?? 0;
          _pendingDues = (data["total_pending_dues"] as num?)?.toDouble() ?? 0;
          _paidMembers = (data["paid_members"] as num?)?.toInt() ?? 0;
          _pendingMembers = (data["pending_members"] as num?)?.toInt() ?? 0;
          _totalMembers = (data["total_members"] as num?)?.toInt() ?? 0;
          _subscriptionStatus =
              data["subscription_status"]?.toString() ?? "ACTIVE";
        }
        if (receipts.isNotEmpty) {
          _recentTransactions = receipts;
        }
        _isLoading = false;
      });
    }
  }

  double get _collectionRate =>
      _totalMembers > 0 ? (_paidMembers / _totalMembers) : 0.0;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: _buildAdminDrawer(context),
      title: 'Dashboard',
      eyebrow: 'Committee',
      subtitle: 'Central Juma Masjid Mahal · live ledger',
      leading: AppHeaderIconButton(
        icon: Icons.menu_rounded,
        tooltip: 'Menu',
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        AppHeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: () {
            setState(() => _isLoading = true);
            _loadAdminData();
          },
        ),
      ],
      onRefresh: _loadAdminData,
      floatingChild: _collectionCard(),
      content: [
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                label: 'Add member',
                icon: Icons.person_add_alt_outlined,
                height: 46,
                onPressed: () => _openAddMemberDialog(context),
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: AppPrimaryButton(
                label: 'Record payment',
                height: 46,
                onPressed: () => _openRecordDuesDialog(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.ms),
        AppSecondaryButton(
          label: 'Pending approvals',
          icon: Icons.how_to_reg_outlined,
          height: 46,
          onPressed: () => Navigator.of(context).pushNamed('/admin/pending-approvals'),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'This month'),
        if (_isLoading) _statSkeleton() else _statGrid(),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(
          title: 'Recent transactions',
          actionLabel: 'View all',
          onAction: () => Navigator.of(context).pushNamed('/admin/reports'),
        ),
        _recentTransactionsCard(),
        const SizedBox(height: AppSpacing.lg),
        _broadcastCard(),
      ],
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
    );
  }

  // -----------------------------------------------------------------------
  // Cards
  // -----------------------------------------------------------------------

  Widget _collectionCard() {
    final pct = (_collectionRate * 100).toInt();
    final healthy = _collectionRate >= 0.7;

    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('COLLECTED THIS MONTH', style: AppTextStyles.label),
              ),
              StatusPill(
                label: _subscriptionStatus == 'ACTIVE'
                    ? 'Subscription active'
                    : _subscriptionStatus,
                foreground: _subscriptionStatus == 'ACTIVE'
                    ? AppColors.success
                    : AppColors.warning,
                background: _subscriptionStatus == 'ACTIVE'
                    ? AppColors.successBg
                    : AppColors.warningBg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Inr.format(_totalCollected),
              semanticsLabel: 'Collected ${Inr.spoken(_totalCollected)}',
              style: AppTextStyles.amount.copyWith(color: AppColors.success),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${Inr.format(_pendingDues)} still outstanding across the Mahal.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text('Collection rate', style: AppTextStyles.small),
              ),
              Text(
                '$_paidMembers of $_totalMembers members · $pct%',
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: healthy ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: _collectionRate.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                healthy ? AppColors.success : AppColors.warning,
              ),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppStatTile(
                  label: 'Collected (MTD)',
                  value: Inr.format(_totalCollected),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  background: AppColors.successBg,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/admin/reports'),
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: AppStatTile(
                  label: 'Pending dues',
                  value: Inr.format(_pendingDues < 0 ? 0 : _pendingDues),
                  icon: Icons.schedule_rounded,
                  color: AppColors.warning,
                  background: AppColors.warningBg,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/admin/reports'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.ms),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppStatTile(
                  label: 'Members paid',
                  value: '$_paidMembers',
                  caption: 'of $_totalMembers families',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.info,
                  background: AppColors.infoBg,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/admin/members'),
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: AppStatTile(
                  label: 'Members pending',
                  value: '$_pendingMembers',
                  caption: 'need a reminder',
                  icon: Icons.pending_outlined,
                  color: AppColors.error,
                  background: AppColors.errorBg,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/admin/members'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statSkeleton() {
    Widget block() => Container(
          height: 116,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        );

    return ShimmerLoading(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: block()),
              const SizedBox(width: AppSpacing.ms),
              Expanded(child: block()),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          Row(
            children: [
              Expanded(child: block()),
              const SizedBox(width: AppSpacing.ms),
              Expanded(child: block()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentTransactionsCard() {
    final list = _recentTransactions.take(5).toList();

    if (list.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const AppIconChip(
              icon: Icons.receipt_long_outlined,
              color: AppColors.textMuted,
              background: AppColors.neutralBg,
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No transactions yet',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Recorded payments appear here as they are issued.',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _transactionRow(list[i]),
          ],
        ],
      ),
    );
  }

  Widget _transactionRow(dynamic t) {
    final name = t["member_name"]?.toString() ?? 'Member';
    final receiptTail =
        (t["receipt_number"] ?? '').toString().split('_').last;
    final type = t["payment_type"]?.toString() ?? 'Payment';
    final amount = (t["amount"] as num?)?.toDouble() ?? 0;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    return InkWell(
      onTap: () => _showReceiptDetailsModal(context, t),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 2,
          vertical: AppSpacing.ms,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$type · $receiptTail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Inr.format(amount),
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 3),
                const StatusPill(
                  label: 'Paid',
                  foreground: AppColors.success,
                  background: AppColors.successBg,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _broadcastCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Broadcast a notice',
                style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Send an announcement or a dues reminder to every member, or only '
            'to those with pending dues.',
            style: AppTextStyles.small.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: () => _openBroadcastComposer(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Text(
                'Compose Notice',
                style: AppTextStyles.button.copyWith(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Sheets
  // -----------------------------------------------------------------------

  void _openAddMemberDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final houseCtrl = TextEditingController();
    final duesCtrl = TextEditingController(text: "500");
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      title: 'Register a member',
      subtitle: 'Adds a family to the Mahal directory',
      icon: Icons.person_add_rounded,
      builder: (ctx, setDialogState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: nameCtrl,
              label: 'Full name',
              hint: 'e.g. Abdul Kareem',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: phoneCtrl,
              label: 'Phone number',
              hint: '+91 98471 11222',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: houseCtrl,
              label: 'House name (optional)',
              hint: 'e.g. Darussalam',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: duesCtrl,
              label: 'Monthly dues (₹)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Save Member',
              isLoading: isSaving,
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and phone number are required'),
                    ),
                  );
                  return;
                }

                setDialogState(() => isSaving = true);
                final dues = double.tryParse(duesCtrl.text) ?? 500.0;
                final res = await _apiService.createMember(
                  name: name,
                  phone: phone,
                  houseName: houseCtrl.text.trim().isNotEmpty
                      ? houseCtrl.text.trim()
                      : null,
                  duesAmount: dues,
                );

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  if (mounted && res != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name was registered.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    _loadAdminData();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _openRecordDuesDialog(BuildContext context) async {
    final members = await _apiService.getAdminMembers();
    if (!context.mounted) return;

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members in the directory yet')),
      );
      return;
    }

    String selectedMemberId =
        (members.first as Map<String, dynamic>)["id"]?.toString() ?? "";
    String selectedMemberName =
        (members.first as Map<String, dynamic>)["name"]?.toString() ?? "Member";
    String selectedMode = "CASH";
    bool isRecording = false;

    AppBottomSheet.show(
      context: context,
      title: 'Record a payment',
      subtitle: 'Issues a signed receipt in the member\'s name',
      icon: Icons.receipt_long_rounded,
      builder: (ctx, setDialogState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'MEMBER',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: AppSpacing.sm - 2),
            _dropdown<String>(
              value: selectedMemberId,
              items: members.map((m) {
                final item = m as Map<String, dynamic>;
                final mId = item["id"]?.toString() ?? "";
                final mName = item["name"]?.toString() ?? "Member";
                final house = item["house_name"]?.toString() ?? "";
                return DropdownMenuItem<String>(
                  value: mId,
                  child: Text(
                    house.isEmpty ? mName : '$mName ($house)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setDialogState(() {
                  selectedMemberId = val;
                  final match = members.firstWhere(
                    (m) => (m as Map<String, dynamic>)["id"] == val,
                    orElse: () => null,
                  );
                  if (match != null) {
                    selectedMemberName =
                        (match as Map<String, dynamic>)["name"]?.toString() ??
                            "Member";
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text('PAYMENT METHOD', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm - 2),
            _dropdown<String>(
              value: selectedMode,
              items: const [
                DropdownMenuItem(value: "CASH", child: Text("Cash (collected offline)")),
                DropdownMenuItem(value: "BANK_TRANSFER", child: Text("Bank transfer")),
                DropdownMenuItem(value: "UPI", child: Text("UPI / QR code")),
              ],
              onChanged: (val) {
                if (val != null) setDialogState(() => selectedMode = val);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.ms + 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Dues amount',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    Inr.format(500),
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Confirm & Issue Receipt',
              isLoading: isRecording,
              onPressed: () async {
                setDialogState(() => isRecording = true);
                final now = DateTime.now();
                final currentMonth =
                    "${now.year}-${now.month.toString().padLeft(2, '0')}";
                final idemp =
                    "ADMIN_PAY_${DateTime.now().millisecondsSinceEpoch}";

                final res = await _apiService.initializeDuesPayment(
                  memberId: selectedMemberId,
                  selectedMonths: [currentMonth],
                  gateway: selectedMode,
                  idempotencyKey: idemp,
                );

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    final receipt = res?["receipt"] as Map<String, dynamic>?;
                    final receiptNo = receipt?["receipt_number"] ??
                        res?["transaction_id"] ??
                        "Verified";
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Recorded for $selectedMemberName · receipt $receiptNo',
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    _loadAdminData();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 2,
          vertical: AppSpacing.ms + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  void _showReceiptDetailsModal(BuildContext context, dynamic transaction) {
    if (transaction is! Map<String, dynamic>) return;
    final rNo = transaction["receipt_number"]?.toString() ?? "N/A";
    final amt = (transaction["amount"] as num?)?.toDouble() ?? 0;
    final mName = transaction["member_name"]?.toString() ?? "Member";
    final date = transaction["created_at"]?.toString() ?? "Recent";
    final hash = transaction["receipt_hash"]?.toString() ?? "3f82a9...c4b2";

    AppBottomSheet.show(
      context: context,
      title: 'Receipt',
      subtitle: 'Signed entry in the Mahal ledger',
      icon: Icons.verified_outlined,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDetailRow(label: 'Receipt number', value: rNo, emphasize: true),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(label: 'Payer', value: mName),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(label: 'Amount', value: Inr.format(amt)),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(label: 'Date', value: date.split('T').first),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(
            label: 'Ledger hash',
            value: hash.length > 18 ? '${hash.substring(0, 18)}…' : hash,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Verify on ledger',
            icon: Icons.verified_rounded,
            onPressed: () async {
              final verify = await _apiService.verifyReceiptCryptographic(rNo);
              if (!context.mounted) return;
              final valid = verify?["cryptographic_valid"] == true;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    valid
                        ? 'Signature valid — this receipt has not been altered.'
                        : 'Receipt found in the database.',
                  ),
                  backgroundColor:
                      valid ? AppColors.success : AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openBroadcastComposer(BuildContext context) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String severity = "INFO";
    String targetAudience = "ALL";
    bool isSending = false;

    AppBottomSheet.show(
      context: context,
      title: 'Broadcast a notice',
      subtitle: 'Goes to member phones as an in-app notice',
      icon: Icons.campaign_rounded,
      builder: (ctx, setModalState) {
        Widget audienceChip(String value, String label, bool warning) {
          final selected = targetAudience == value;
          return Expanded(
            child: InkWell(
              onTap: () => setModalState(() {
                targetAudience = value;
                if (value == 'OVERDUE_ONLY') {
                  severity = 'WARNING';
                  titleCtrl.text = 'Monthly dues reminder';
                  msgCtrl.text =
                      'Respected member, our records show pending dues for '
                      'your household. You can pay in the MahalFlow app.';
                } else {
                  severity = 'INFO';
                  titleCtrl.text = 'Mahal announcement';
                  msgCtrl.text = '';
                }
              }),
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.ms,
                  vertical: AppSpacing.ms,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? (warning ? AppColors.warningBg : AppColors.primaryLight)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: selected
                        ? (warning ? AppColors.warning : AppColors.primary)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? (warning ? AppColors.warning : AppColors.primary)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('WHO SHOULD GET THIS', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                audienceChip('ALL', 'All members\n($_totalMembers families)', false),
                const SizedBox(width: AppSpacing.sm),
                audienceChip('OVERDUE_ONLY', 'Pending dues only', true),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: titleCtrl,
              label: 'Notice title',
              hint: 'e.g. Monthly dues reminder',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: msgCtrl,
              label: 'Message',
              hint: 'Write the full announcement…',
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('PRIORITY', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm - 2),
            _dropdown<String>(
              value: severity,
              items: const [
                DropdownMenuItem(value: "INFO", child: Text("Informational")),
                DropdownMenuItem(value: "WARNING", child: Text("Dues reminder")),
                DropdownMenuItem(value: "CRITICAL", child: Text("Critical")),
              ],
              onChanged: (val) {
                if (val != null) setModalState(() => severity = val);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Send to members',
              icon: Icons.send_rounded,
              isLoading: isSending,
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final desc = msgCtrl.text.trim();
                if (title.isEmpty || desc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('A title and a message are both required'),
                    ),
                  );
                  return;
                }

                setModalState(() => isSending = true);
                final res = await _apiService.createAlert(
                  title: title,
                  description: desc,
                  severity: severity,
                  audience: targetAudience,
                );

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  if (res != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notice sent to members.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Drawer
  // -----------------------------------------------------------------------

  Widget _buildAdminDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppGradients.hero),
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: MediaQuery.paddingOf(context).top + AppSpacing.lg,
              bottom: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(Icons.mosque_rounded,
                      size: 26, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.ms),
                Text(
                  'Central Juma Masjid Mahal',
                  style: AppTextStyles.cardTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Committee portal · REG/KL/2024/0912',
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _drawerTile(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                _drawerTile(
                  icon: Icons.people_outline_rounded,
                  title: 'Members',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/members');
                  },
                ),
                _drawerTile(
                  icon: Icons.assessment_outlined,
                  title: 'Financial reports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/reports');
                  },
                ),
                _drawerTile(
                  icon: Icons.campaign_outlined,
                  title: 'Broadcast a notice',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _openBroadcastComposer(context);
                  },
                ),
                _drawerTile(
                  icon: Icons.upload_file_outlined,
                  title: 'Bulk import',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/import-step1');
                  },
                ),
                _drawerTile(
                  icon: Icons.account_balance_outlined,
                  title: 'Payment gateways',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/gateways');
                  },
                ),
                _drawerTile(
                  icon: Icons.history_rounded,
                  title: 'Audit logs',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/audit-logs');
                  },
                ),
                const Divider(color: AppColors.border, height: AppSpacing.lg),
                _drawerTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Switch to member view',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/member/dashboard',
                      (route) => false,
                    );
                  },
                ),
                _drawerTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  color: AppColors.error,
                  onTap: () async {
                    Navigator.pop(context);
                    await PushNotificationService.instance.onSignOut();
                    await ApiService.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 21),
      title: Text(
        title,
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w500,
          color: itemColor,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }
}
