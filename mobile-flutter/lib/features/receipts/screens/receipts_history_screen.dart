import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import 'receipt_details_screen.dart';

class _ReceiptItem {
  final String title;
  final String subtitle;
  final String amount;
  final String status;

  const _ReceiptItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
  });
}

class ReceiptsHistoryScreen extends StatefulWidget {
  const ReceiptsHistoryScreen({super.key});

  @override
  State<ReceiptsHistoryScreen> createState() => _ReceiptsHistoryScreenState();
}

class _ReceiptsHistoryScreenState extends State<ReceiptsHistoryScreen> {
  String _selectedFilter = "All";

  final List<String> _filters = ["All", "Monthly", "Contribution"];

  final List<_ReceiptItem> _receipts = [
    const _ReceiptItem(
      title: "Monthly Dues",
      subtitle: "Jun-Aug 2026",
      amount: "₹1,500",
      status: "SUCCESS",
    ),
    const _ReceiptItem(
      title: "Contribution",
      subtitle: "Zakat Fund",
      amount: "₹2,000",
      status: "SUCCESS",
    ),
    const _ReceiptItem(
      title: "Monthly Dues",
      subtitle: "Mar-May 2026",
      amount: "₹1,500",
      status: "SUCCESS",
    ),
    const _ReceiptItem(
      title: "Monthly Dues",
      subtitle: "Sep 2026",
      amount: "₹500",
      status: "PENDING",
    ),
  ];

  List<_ReceiptItem> get _filteredReceipts {
    if (_selectedFilter == "All") return _receipts;
    if (_selectedFilter == "Monthly") {
      return _receipts.where((r) => r.title.contains("Monthly")).toList();
    }
    if (_selectedFilter == "Contribution") {
      return _receipts.where((r) => r.title.contains("Contribution")).toList();
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
          "Receipts",
          style: GoogleFonts.inter(
            fontSize: 22,
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
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                );
              },
            ),
          ),

          // Receipts List
          Expanded(
            child: displayedReceipts.isEmpty
                ? Center(
                    child: Text(
                      "No receipts found for '$_selectedFilter'",
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
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
        ],
      ),
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case "SUCCESS":
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "SUCCESS",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        );
      case "PENDING":
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "PENDING",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
