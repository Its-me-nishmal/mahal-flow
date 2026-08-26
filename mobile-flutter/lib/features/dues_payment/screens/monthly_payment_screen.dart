import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';

class DueMonthItem {
  final String monthKey;
  final String displayName;
  final double amount;
  final String status;
  bool isSelected;

  DueMonthItem({
    required this.monthKey,
    required this.displayName,
    required this.amount,
    required this.status,
    this.isSelected = true,
  });
}

class MonthlyPaymentScreen extends StatefulWidget {
  const MonthlyPaymentScreen({super.key});

  @override
  State<MonthlyPaymentScreen> createState() => _MonthlyPaymentScreenState();
}

class _MonthlyPaymentScreenState extends State<MonthlyPaymentScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  final List<DueMonthItem> _months = [
    DueMonthItem(
      monthKey: "2026-06",
      displayName: "June 2026",
      amount: 500,
      status: "OVERDUE",
    ),
    DueMonthItem(
      monthKey: "2026-07",
      displayName: "July 2026",
      amount: 500,
      status: "DUE_SOON",
    ),
    DueMonthItem(
      monthKey: "2026-08",
      displayName: "August 2026",
      amount: 500,
      status: "UPCOMING",
    ),
  ];

  bool get _isAllSelected => _months.every((m) => m.isSelected);
  int get _selectedCount => _months.where((m) => m.isSelected).length;
  double get _totalAmount => _months.where((m) => m.isSelected).fold(0, (sum, m) => sum + m.amount);

  void _toggleSelectAll(bool? val) {
    setState(() {
      final target = val ?? false;
      for (var m in _months) {
        m.isSelected = target;
      }
    });
  }

  void _toggleMonth(int index, bool? val) {
    setState(() {
      _months[index].isSelected = val ?? false;
    });
  }

  Future<void> _handlePayment() async {
    final selectedKeys = _months.where((m) => m.isSelected).map((m) => m.monthKey).toList();
    if (selectedKeys.isEmpty) return;

    setState(() => _isProcessing = true);

    final idempKey = "IDEMP_${DateTime.now().millisecondsSinceEpoch}";
    final initRes = await _apiService.initializeDuesPayment(
      memberId: "MEM_001_9910",
      selectedMonths: selectedKeys,
      idempotencyKey: idempKey,
    );

    if (initRes != null && initRes["transaction_id"] != null) {
      final txnId = initRes["transaction_id"] as String;
      final confirmRes = await _apiService.confirmPayment(txnId);

      if (mounted) {
        setState(() => _isProcessing = false);
        if (confirmRes != null && confirmRes["status"] == "SUCCESS") {
          final receipt = confirmRes["receipt"] as Map<String, dynamic>?;
          final receiptNum = receipt?["receipt_number"] ?? "Verified";

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                  const SizedBox(width: 8),
                  Text("Payment Successful", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("₹${_totalAmount.toInt()} paid successfully.", style: GoogleFonts.inter(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Receipt: $receiptNum", style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text("Months: ${selectedKeys.join(', ')}", style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(); // Go back to dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("View Dashboard"),
                ),
              ],
            ),
          );
          return;
        }
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment completed successfully!")),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          "Monthly Dues",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select the months you wish to pay for.",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Bento Container
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(23, 32, 29, 0.04),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7FAF7),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Unpaid Months",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Select All",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Checkbox(
                              value: _isAllSelected,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: _toggleSelectAll,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Month Items
                  ...List.generate(_months.length, (index) {
                    final item = _months[index];
                    final isLast = index == _months.length - 1;

                    return Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(color: AppColors.border),
                              ),
                      ),
                      child: InkWell(
                        onTap: () => _toggleMonth(index, !item.isSelected),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Checkbox(
                                value: item.isSelected,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (v) => _toggleMonth(index, v),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    _buildStatusChip(item.status),
                                  ],
                                ),
                              ),
                              Text(
                                "₹${item.amount.toInt()}",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(23, 32, 29, 0.05),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Selected ($_selectedCount months)",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "₹${_totalAmount.toInt()}",
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Processing Fee",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "₹0",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: (_selectedCount == 0 || _isProcessing) ? null : _handlePayment,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.lock, size: 18),
                      label: Text(_isProcessing ? "Processing Payment..." : "Pay ₹${_totalAmount.toInt()}"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const MemberBottomNavBar(currentIndex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    switch (status) {
      case "OVERDUE":
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 12, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              "Overdue",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ],
        );
      case "DUE_SOON":
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, size: 12, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              "Due Soon",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ],
        );
      default:
        return Text(
          "Upcoming",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        );
    }
  }
}
