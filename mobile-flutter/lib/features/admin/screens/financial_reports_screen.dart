import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_filter_chip_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../widgets/admin_bottom_nav_bar.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final ApiService _apiService = ApiService();
  String _paymentStatusFilter = "All";
  String _paymentTypeFilter = "All";

  bool _isLoading = true;
  double _totalCollected = 0;
  double _totalPending = 0;
  double _totalDonations = 0;
  String _period = "";
  List<Map<String, dynamic>> _monthlyBreakdown = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final report = await _apiService.getFinancialReport();
    final receipts = await _apiService.getRecentReceipts();

    if (mounted) {
      setState(() {
        if (report != null) {
          final summary = report["summary"] as Map<String, dynamic>? ?? {};
          _totalCollected = (summary["total_collected"] as num?)?.toDouble() ?? 0;
          _totalPending = (summary["pending_dues"] as num?)?.toDouble() ?? 0;
          _totalDonations = (summary["donations"] as num?)?.toDouble() ?? 0;
          _period = report["period"]?.toString() ?? "2026-08";
        }

        // Group receipts by month
        final Map<String, Map<String, dynamic>> grouped = {};
        for (final r in receipts) {
          if (r is Map<String, dynamic>) {
            final pType = r["payment_type"]?.toString() ?? "MONTHLY_DUES";
            if (_paymentTypeFilter == "Dues" && !pType.contains("DUES")) continue;
            if (_paymentTypeFilter == "Contribution" && !pType.contains("CONTRIBUTION") && !pType.contains("DONATION")) continue;

            final createdAt = r["created_at"]?.toString() ?? r["paid_at"]?.toString() ?? "";
            String monthKey = "2026-08";
            if (createdAt.length >= 7) {
              monthKey = createdAt.substring(0, 7);
            }
            if (!grouped.containsKey(monthKey)) {
              grouped[monthKey] = {
                "month": monthKey,
                "collected": 0.0,
                "members": 0,
                "receipts": <dynamic>[],
              };
            }
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
  }

  String _formatMonth(String ym) {
    final months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final parts = ym.split("-");
    if (parts.length == 2) {
      final year = parts[0];
      final mi = int.tryParse(parts[1]) ?? 0;
      if (mi >= 1 && mi <= 12) return "${months[mi]} $year";
    }
    return ym;
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return "₹${(amount / 1000).toStringAsFixed(1)}K";
    }
    return "₹${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/admin/dashboard');
            }
          },
        ),
        title: Text(
          "Financial Reports",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: "Refresh Data",
            onPressed: _loadData,
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      body: _isLoading
          ? ShimmerLoading(
              isLoading: true,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  ShimmerCardSkeleton(height: 140),
                  SizedBox(height: 12),
                  ShimmerCardSkeleton(height: 100),
                  SizedBox(height: 12),
                  ShimmerCardSkeleton(height: 80),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(),
                    const SizedBox(height: 14),
                    _buildSummaryGrid(),
                    const SizedBox(height: 14),
                    _buildMonthlyBreakdownCard(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Accounting Filters",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_period.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatMonth(_period),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Payment Status",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          AppFilterChipBar(
            options: const ["All", "Paid", "Pending"],
            selectedOption: _paymentStatusFilter,
            onSelected: (val) {
              setState(() => _paymentStatusFilter = val);
              _loadData();
            },
          ),
          const SizedBox(height: 12),
          Text(
            "Category",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          AppFilterChipBar(
            options: const ["All", "Dues", "Contribution"],
            selectedOption: _paymentTypeFilter,
            onSelected: (val) {
              setState(() => _paymentTypeFilter = val);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            _buildMiniMetric("Collected", _formatAmount(_totalCollected), AppColors.success, AppColors.successBg),
            _buildMiniMetric("Pending", _formatAmount(_totalPending), AppColors.warning, AppColors.warningBg),
            _buildMiniMetric("Donations", _formatAmount(_totalDonations), AppColors.info, AppColors.infoBg),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("📄 Financial Statement for $_period generated!"),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
            label: Text(
              "Export Statement PDF",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Breakdown",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (_monthlyBreakdown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "No transactions matching selected filters",
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ..._monthlyBreakdown.map((t) {
              final monthKey = t["month"]?.toString() ?? "";
              final collected = (t["collected"] as num?)?.toDouble() ?? 0;
              final members = (t["members"] as num?)?.toInt() ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatMonth(monthKey),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$members payments recorded",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatAmount(collected),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
