import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
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
}

class ReceiptsHistoryScreen extends StatefulWidget {
  const ReceiptsHistoryScreen({super.key});

  @override
  State<ReceiptsHistoryScreen> createState() => _ReceiptsHistoryScreenState();
}

class _ReceiptsHistoryScreenState extends State<ReceiptsHistoryScreen> {
  final ApiService _apiService = ApiService();
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Monthly", "Contribution"];
  List<_ReceiptItem> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    final rawList = await _apiService.getMemberReceipts();

    const monthsNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    List<_ReceiptItem> loaded = [];

    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final amount = (item["amount"] as num?)?.toInt() ?? 0;
        final pType = item["payment_type"]?.toString() ?? "MONTHLY_DUES";
        final paidMonths = (item["paid_months"] as List?)?.map((e) => e.toString()).toList() ?? [];
        final paidMonthsStr = paidMonths.isNotEmpty ? paidMonths.join(", ") : "Contribution";
        final rNum = item["receipt_number"]?.toString() ?? "RCPT_LIVE";
        final mName = item["member_name"]?.toString() ?? "Muhammed Ameen";

        String formattedDate = "Recent";
        final rawDate = item["created_at"]?.toString();
        if (rawDate != null) {
          final parsed = DateTime.tryParse(rawDate);
          if (parsed != null) {
            formattedDate = "${parsed.day} ${monthsNames[parsed.month - 1]} ${parsed.year}";
          }
        }

        loaded.add(
          _ReceiptItem(
            title: pType == "MONTHLY_DUES" ? "Monthly Dues" : "Mahal Contribution",
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
    if (_selectedFilter == "All") return _receipts;
    if (_selectedFilter == "Monthly") {
      return _receipts.where((r) => r.rawType == "MONTHLY_DUES" || r.title.contains("Monthly")).toList();
    }
    if (_selectedFilter == "Contribution") {
      return _receipts.where((r) => r.rawType == "CONTRIBUTION" || r.title.contains("Contribution")).toList();
    }
    return _receipts;
  }

  @override
  Widget build(BuildContext context) {
    final displayedReceipts = _filteredReceipts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/member/dashboard');
            }
          },
        ),
        title: Text(
          "Receipts History",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = filter),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Receipts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : displayedReceipts.isEmpty
                    ? Center(
                        child: Text(
                          "No receipts found for '$_selectedFilter'",
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReceipts,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: displayedReceipts.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final receipt = displayedReceipts[index];
                            return InkWell(
                              onTap: () {
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
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Title & Subtitle
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            receipt.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            receipt.subtitle,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Amount & Status
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          receipt.amount,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _buildStatusBadge(receipt.status),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.success,
        ),
      ),
    );
  }
}
