import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../widgets/admin_bottom_nav_bar.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final ApiService _apiService = ApiService();
  static const List<String> _typeFilters = ['All', 'Dues', 'Contribution'];

  String _paymentTypeFilter = 'All';
  bool _isLoading = true;
  double _totalCollected = 0;
  double _totalPending = 0;
  double _totalDonations = 0;
  String _period = '';
  List<Map<String, dynamic>> _monthlyBreakdown = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);

    final report = await _apiService.getFinancialReport();
    final receipts = await _apiService.getRecentReceipts();
    if (!mounted) return;

    setState(() {
      if (report != null) {
        final summary = report["summary"] as Map<String, dynamic>? ?? {};
        _totalCollected =
            (summary["total_collected"] as num?)?.toDouble() ?? 0;
        _totalPending = (summary["pending_dues"] as num?)?.toDouble() ?? 0;
        _totalDonations = (summary["donations"] as num?)?.toDouble() ?? 0;
        _period = report["period"]?.toString() ?? "2026-08";
      }

      // Group receipts by month, honouring the category filter.
      final Map<String, Map<String, dynamic>> grouped = {};
      for (final r in receipts) {
        if (r is Map<String, dynamic>) {
          final pType = r["payment_type"]?.toString() ?? "MONTHLY_DUES";
          if (_paymentTypeFilter == "Dues" && !pType.contains("DUES")) {
            continue;
          }
          if (_paymentTypeFilter == "Contribution" &&
              !pType.contains("CONTRIBUTION") &&
              !pType.contains("DONATION")) {
            continue;
          }

          final createdAt = r["created_at"]?.toString() ??
              r["paid_at"]?.toString() ??
              "";
          String monthKey = "2026-08";
          if (createdAt.length >= 7) {
            monthKey = createdAt.substring(0, 7);
          }
          grouped.putIfAbsent(
            monthKey,
            () => {
              "month": monthKey,
              "collected": 0.0,
              "members": 0,
              "receipts": <dynamic>[],
            },
          );
          grouped[monthKey]!["collected"] =
              (grouped[monthKey]!["collected"] as double) +
                  ((r["amount"] as num?)?.toDouble() ?? 0);
          grouped[monthKey]!["members"] =
              (grouped[monthKey]!["members"] as int) + 1;
          (grouped[monthKey]!["receipts"] as List<dynamic>).add(r);
        }
      }

      final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
      _monthlyBreakdown = sortedKeys.map((k) => grouped[k]!).toList();

      _isLoading = false;
    });
  }

  String _formatMonth(String ym) {
    const months = [
      "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    final parts = ym.split("-");
    if (parts.length == 2) {
      final year = parts[0];
      final mi = int.tryParse(parts[1]) ?? 0;
      if (mi >= 1 && mi <= 12) return "${months[mi]} $year";
    }
    return ym;
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Reports',
      eyebrow: 'Finance',
      subtitle: _period.isEmpty
          ? 'Collection across the Mahal'
          : 'Period ${_formatMonth(_period)}',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        }
      },
      actions: [
        AppHeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: _loadData,
        ),
      ],
      headerChild: AppHeroFilterChips(
        options: _typeFilters,
        selected: _paymentTypeFilter,
        onSelected: (val) {
          setState(() => _paymentTypeFilter = val);
          _loadData();
        },
      ),
      onRefresh: _loadData,
      floatingChild: _summaryCard(),
      content: [
        const SizedBox(height: AppSpacing.md),
        AppSecondaryButton(
          label: 'Export statement (PDF)',
          icon: Icons.picture_as_pdf_outlined,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Statement for ${_formatMonth(_period)} generated.',
                ),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'Month by month'),
        if (_isLoading) _skeleton() else _breakdownCard(),
      ],
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2),
    );
  }

  Widget _summaryCard() {
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('TOTAL COLLECTED', style: AppTextStyles.label),
              ),
              if (_period.isNotEmpty)
                StatusPill(
                  label: _formatMonth(_period),
                  foreground: AppColors.primary,
                  background: AppColors.primaryLight,
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
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.ms),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Pending dues',
                  Inr.format(_totalPending),
                  AppColors.warning,
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.border),
              Expanded(
                child: _miniStat(
                  'Contributions',
                  Inr.format(_totalDonations),
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.small),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 18,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownCard() {
    if (_monthlyBreakdown.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const AppIconChip(
              icon: Icons.bar_chart_rounded,
              color: AppColors.textMuted,
              background: AppColors.neutralBg,
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Text(
                'No transactions match this filter.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
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
          for (var i = 0; i < _monthlyBreakdown.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            _breakdownRow(_monthlyBreakdown[i]),
          ],
        ],
      ),
    );
  }

  Widget _breakdownRow(Map<String, dynamic> t) {
    final monthKey = t["month"]?.toString() ?? '';
    final collected = (t["collected"] as num?)?.toDouble() ?? 0;
    final count = (t["members"] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: AppSpacing.ms + 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatMonth(monthKey),
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  count == 1 ? '1 payment recorded' : '$count payments recorded',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          Text(
            Inr.format(collected),
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 15,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton() {
    return const ShimmerLoading(
      child: Column(
        children: [
          ShimmerCardSkeleton(height: 72),
          ShimmerCardSkeleton(height: 72),
          ShimmerCardSkeleton(height: 72),
        ],
      ),
    );
  }
}
