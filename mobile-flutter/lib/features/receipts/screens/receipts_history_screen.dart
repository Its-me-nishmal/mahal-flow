import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'receipt_details_screen.dart';

class _ReceiptItem {
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final String receiptNumber;
  final String memberName;
  final String date;
  final String paymentMethod;
  final String rawType;

  const _ReceiptItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.receiptNumber,
    required this.memberName,
    required this.date,
    required this.paymentMethod,
    required this.rawType,
  });

  bool get isDues => rawType == 'MONTHLY_DUES' || title.contains('Monthly');
}

class ReceiptsHistoryScreen extends StatefulWidget {
  const ReceiptsHistoryScreen({super.key});

  @override
  State<ReceiptsHistoryScreen> createState() => _ReceiptsHistoryScreenState();
}

class _ReceiptsHistoryScreenState extends State<ReceiptsHistoryScreen> {
  final ApiService _apiService = ApiService();
  static const List<String> _filters = ['All', 'Monthly', 'Contribution'];

  String _selectedFilter = 'All';
  List<_ReceiptItem> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    if (mounted) setState(() => _isLoading = true);
    final rawList = await _apiService.getMemberReceipts();

    const monthsNames = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    List<_ReceiptItem> loaded = [];

    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final amount = (item["amount"] as num?)?.toInt() ?? 0;
        final pType = item["payment_type"]?.toString() ?? "MONTHLY_DUES";
        final paidMonths =
            (item["paid_months"] as List?)?.map((e) => e.toString()).toList() ??
                [];
        final paidMonthsStr =
            paidMonths.isNotEmpty ? paidMonths.join(", ") : "Contribution";
        final rNum = item["receipt_number"]?.toString() ?? "RCPT_LIVE";
        final mName = item["member_name"]?.toString() ?? "Muhammed Ameen";

        String formattedDate = "Recent";
        final rawDate = item["created_at"]?.toString();
        if (rawDate != null) {
          final parsed = DateTime.tryParse(rawDate);
          if (parsed != null) {
            formattedDate =
                "${parsed.day} ${monthsNames[parsed.month - 1]} ${parsed.year}";
          }
        }

        loaded.add(
          _ReceiptItem(
            title:
                pType == "MONTHLY_DUES" ? "Monthly Dues" : "Mahal Contribution",
            subtitle: pType == "MONTHLY_DUES" ? paidMonthsStr : "General Fund",
            amount: "₹$amount",
            status: "SUCCESS",
            receiptNumber: rNum,
            memberName: mName,
            date: formattedDate,
            paymentMethod: "UPI / Online",
            rawType: pType,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _receipts = loaded;
        _isLoading = false;
      });
    }
  }

  List<_ReceiptItem> get _filteredReceipts {
    switch (_selectedFilter) {
      case 'Monthly':
        return _receipts.where((r) => r.isDues).toList();
      case 'Contribution':
        return _receipts.where((r) => !r.isDues).toList();
      default:
        return _receipts;
    }
  }

  Map<String, int> get _counts => {
        'All': _receipts.length,
        'Monthly': _receipts.where((r) => r.isDues).length,
        'Contribution': _receipts.where((r) => !r.isDues).length,
      };

  void _openReceipt(_ReceiptItem receipt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptDetailsScreen(
          title: receipt.title,
          subtitle: receipt.subtitle,
          amount: receipt.amount,
          status: receipt.status,
          receiptNumber: receipt.receiptNumber,
          memberName: receipt.memberName,
          date: receipt.date,
          paymentMethod: receipt.paymentMethod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final receipts = _filteredReceipts;

    return AppPageScaffold(
      title: 'Receipts',
      eyebrow: 'History',
      subtitle: 'Every payment you have made, with a receipt for each.',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/member/dashboard');
        }
      },
      headerChild: AppHeroFilterChips(
        options: _filters,
        selected: _selectedFilter,
        counts: _isLoading ? null : _counts,
        onSelected: (f) => setState(() => _selectedFilter = f),
      ),
      expandedChild: RefreshIndicator(
        onRefresh: _loadReceipts,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _isLoading
            ? _skeleton()
            : receipts.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.md,
                      AppSpacing.screenH,
                      AppSpacing.xl,
                    ),
                    itemCount: receipts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final receipt = receipts[index];
                      return AppListRow(
                        icon: receipt.isDues
                            ? Icons.receipt_long_outlined
                            : Icons.volunteer_activism_outlined,
                        iconColor: receipt.isDues
                            ? AppColors.primary
                            : AppColors.warning,
                        iconBackground: receipt.isDues
                            ? AppColors.primaryLight
                            : AppColors.warningBg,
                        title: receipt.title,
                        caption: '${receipt.subtitle} · ${receipt.date}',
                        trailingText: receipt.amount,
                        trailingCaption: 'Paid',
                        onTap: () => _openReceipt(receipt),
                        showChevron: true,
                      );
                    },
                  ),
      ),
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 2),
    );
  }

  Widget _empty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),
        EmptyStateView(
          icon: Icons.receipt_long_outlined,
          title: _selectedFilter == 'All'
              ? 'No receipts yet'
              : 'No $_selectedFilter receipts',
          description: _selectedFilter == 'All'
              ? 'Once you pay your dues or contribute, every receipt lands here.'
              : 'Try a different filter, or pull down to refresh.',
          actionLabel: _selectedFilter == 'All' ? 'Pay Dues' : null,
          onAction: _selectedFilter == 'All'
              ? () => Navigator.of(context).pushNamed('/member/pay')
              : null,
        ),
      ],
    );
  }

  Widget _skeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: [
        for (var i = 0; i < 6; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: ShimmerLoading(child: ShimmerCardSkeleton(height: 72)),
          ),
      ],
    );
  }
}
