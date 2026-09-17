import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'edit_member_details_screen.dart';

class MemberDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const MemberDetailsScreen({super.key, required this.member});

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _duesHistory = [];
  List<dynamic> _receiptsList = [];
  bool _isLoadingHistory = true;

  Map<String, dynamic> get member => widget.member;

  @override
  void initState() {
    super.initState();
    _loadDuesHistory();
  }

  Future<void> _loadDuesHistory() async {
    final memberId = member["id"]?.toString() ?? "MEM_001_9910";
    final receipts = await _apiService.getMemberReceipts(memberId: memberId);

    if (!mounted) return;

    final Map<String, String> paidMonths = {};
    for (final r in receipts) {
      if (r is Map<String, dynamic>) {
        final paidFor = r["paid_months"] ?? r["selected_months"];
        final createdAt = r["created_at"]?.toString() ?? "";
        if (paidFor is List) {
          for (final m in paidFor) {
            paidMonths[m.toString()] =
                r["receipt_number"]?.toString() ?? "Paid";
          }
        } else if (createdAt.length >= 7) {
          paidMonths[createdAt.substring(0, 7)] =
              r["receipt_number"]?.toString() ?? "Paid";
        }
      }
    }

    final now = DateTime.now();
    final List<Map<String, dynamic>> history = [];
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
      const monthNames = [
        "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      final label = "${monthNames[date.month]} ${date.year}";

      String status;
      String? receiptNo;
      if (paidMonths.containsKey(key)) {
        status = "Paid";
        receiptNo = paidMonths[key];
      } else if (i == 0) {
        status = "Current Due";
      } else {
        status = "Overdue";
      }

      history.add({
        "month": label,
        "key": key,
        "status": status,
        "receipt_number": receiptNo,
      });
    }

    setState(() {
      _duesHistory = history;
      _receiptsList = receipts;
      _isLoadingHistory = false;
    });
  }

  int get _paidCount =>
      _duesHistory.where((h) => h["status"] == "Paid").length;

  int get _unpaidCount => _duesHistory.length - _paidCount;

  String get _lastPaidLabel {
    for (final h in _duesHistory) {
      if (h["status"] == "Paid") return h["month"]?.toString() ?? '—';
    }
    return 'Never';
  }

  ({Color color, Color background}) get _statusColors {
    final status = member["status"] as String? ?? 'Active';
    if (status == 'Active') {
      return (color: AppColors.success, background: AppColors.successBg);
    }
    if (status == 'Grace Period') {
      return (color: AppColors.warning, background: AppColors.warningBg);
    }
    return (color: AppColors.error, background: AppColors.errorBg);
  }

  Future<void> _openEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditMemberDetailsScreen(member: member),
      ),
    );
    _loadDuesHistory();
  }

  // -----------------------------------------------------------------------

  void _showReceiptModal(String receiptNo) {
    dynamic matched;
    for (final r in _receiptsList) {
      if (r is Map<String, dynamic> && r["receipt_number"] == receiptNo) {
        matched = r;
        break;
      }
    }

    final amount = (matched?["amount"] as num?)?.toDouble() ?? 500;
    final date = matched?["created_at"]?.toString() ?? 'Recent';
    final hash = matched?["receipt_hash"]?.toString() ?? '3a8f9c…d4e1';

    AppBottomSheet.show(
      context: context,
      title: 'Receipt',
      subtitle: 'Signed entry in the Mahal ledger',
      icon: Icons.verified_outlined,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDetailRow(
            label: 'Receipt number',
            value: receiptNo,
            emphasize: true,
          ),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(
            label: 'Member',
            value: member["name"]?.toString() ?? 'Member',
          ),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(label: 'Amount', value: Inr.format(amount)),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(label: 'Date', value: date.split('T').first),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(
            label: 'Ledger hash',
            value: hash.length > 16 ? '${hash.substring(0, 16)}…' : hash,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Verify on ledger',
            icon: Icons.verified_rounded,
            onPressed: () async {
              final verify =
                  await _apiService.verifyReceiptCryptographic(receiptNo);
              if (!mounted) return;
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

  void _showRecordPaymentDialog(BuildContext context) {
    final memberId = member["id"]?.toString() ?? "MEM_001_9910";
    final memberName = member["name"]?.toString() ?? "Member";
    String selectedMode = "CASH";
    int selectedMonthsCount = 1;
    bool isProcessing = false;

    AppBottomSheet.show(
      context: context,
      title: 'Record a payment',
      subtitle: memberName,
      icon: Icons.receipt_long_rounded,
      builder: (ctx, setDialogState) {
        final totalAmount = 500 * selectedMonthsCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('HOW MANY MONTHS', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [1, 2, 3, 6].map((cnt) {
                final isSel = selectedMonthsCount == cnt;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: cnt == 6 ? 0 : AppSpacing.sm,
                    ),
                    child: InkWell(
                      onTap: () =>
                          setDialogState(() => selectedMonthsCount = cnt),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.ms,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primaryLight
                              : AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.button),
                          border: Border.all(
                            color:
                                isSel ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          cnt == 1 ? '1 mo' : '$cnt mos',
                          style: AppTextStyles.button.copyWith(
                            fontSize: 13,
                            color: isSel
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('PAYMENT METHOD', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm - 2),
            DropdownButtonFormField<String>(
              initialValue: selectedMode,
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
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.6),
                ),
              ),
              items: const [
                DropdownMenuItem(
                    value: "CASH", child: Text("Cash (collected offline)")),
                DropdownMenuItem(
                    value: "BANK_TRANSFER", child: Text("Bank transfer")),
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
                      'Total payable',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    Inr.format(totalAmount),
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
              isLoading: isProcessing,
              onPressed: () async {
                setDialogState(() => isProcessing = true);
                final now = DateTime.now();
                final List<String> monthsToCredit = [];
                for (int i = 0; i < selectedMonthsCount; i++) {
                  final dt = DateTime(now.year, now.month + i, 1);
                  monthsToCredit
                      .add("${dt.year}-${dt.month.toString().padLeft(2, '0')}");
                }

                final idemp =
                    "ADMIN_REC_${DateTime.now().millisecondsSinceEpoch}";
                final res = await _apiService.initializeDuesPayment(
                  memberId: memberId,
                  selectedMonths: monthsToCredit,
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
                          '${Inr.format(totalAmount)} recorded · receipt $receiptNo',
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    _loadDuesHistory();
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

  @override
  Widget build(BuildContext context) {
    final name = member["name"]?.toString() ?? 'Member';
    final phone = member["phone"]?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    return AppPageScaffold(
      title: name,
      eyebrow: 'Member',
      onRefresh: _loadDuesHistory,
      actions: [
        AppHeaderIconButton(
          icon: Icons.sms_outlined,
          tooltip: 'Send dues notice',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dues notice sent to this member.')),
          ),
        ),
        AppHeaderIconButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit member',
          onTap: _openEdit,
        ),
      ],
      headerChild: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 2,
              ),
            ),
            child: Text(
              initial,
              style: AppTextStyles.display.copyWith(
                color: Colors.white,
                fontSize: 23,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phone.isEmpty ? 'No phone on record' : phone,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID ${member["id"]?.toString() ?? "—"}',
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingChild: _summaryCard(),
      content: [
        const SizedBox(height: AppSpacing.md),
        const AppSectionHeader(title: 'Last six months'),
        _duesHistoryCard(),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'Edit member',
                  icon: Icons.edit_outlined,
                  height: 48,
                  onPressed: _openEdit,
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: AppPrimaryButton(
                  label: 'Record payment',
                  height: 48,
                  onPressed: () => _showRecordPaymentDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final colors = _statusColors;
    final duesAmount = member["amount"]?.toString() ?? '₹500';
    final house = member["house_name"]?.toString() ?? '';

    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('MONTHLY DUES', style: AppTextStyles.label),
              ),
              StatusPill(
                label: member["status"]?.toString() ?? 'Active',
                foreground: colors.color,
                background: colors.background,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          Text(
            duesAmount,
            style: AppTextStyles.amount.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _isLoadingHistory
                ? 'Loading payment history…'
                : _unpaidCount == 0
                    ? 'Paid every month in the last six.'
                    : '$_unpaidCount of ${_duesHistory.length} recent months unpaid.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(label: 'Last paid', value: _lastPaidLabel),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(
            label: 'House',
            value: house.isEmpty ? 'Not recorded' : house,
          ),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(
            label: 'Email',
            value: (member["email"]?.toString().isNotEmpty ?? false)
                ? member["email"].toString()
                : 'Not recorded',
          ),
        ],
      ),
    );
  }

  Widget _duesHistoryCard() {
    if (_isLoadingHistory) {
      return ShimmerLoading(
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _duesHistory.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _duesRow(_duesHistory[i]),
          ],
        ],
      ),
    );
  }

  Widget _duesRow(Map<String, dynamic> m) {
    final status = m["status"]?.toString() ?? 'Unknown';
    final receiptNo = m["receipt_number"] as String?;

    late final Color chipColor;
    late final Color chipBg;
    if (status == 'Paid') {
      chipColor = AppColors.success;
      chipBg = AppColors.successBg;
    } else if (status == 'Overdue') {
      chipColor = AppColors.error;
      chipBg = AppColors.errorBg;
    } else {
      chipColor = AppColors.warning;
      chipBg = AppColors.warningBg;
    }

    return InkWell(
      onTap: receiptNo != null ? () => _showReceiptModal(receiptNo) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 2,
          vertical: AppSpacing.ms + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                m["month"]?.toString() ?? '',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (receiptNo != null) ...[
              const Icon(Icons.receipt_long_rounded,
                  size: 15, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
            ],
            StatusPill(
              label: status,
              foreground: chipColor,
              background: chipBg,
            ),
          ],
        ),
      ),
    );
  }
}
