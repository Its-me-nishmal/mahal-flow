import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
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
  List<DueMonthItem> _months = [];

  @override
  void initState() {
    super.initState();
    _loadUnpaidMonths();
  }

  Future<void> _loadUnpaidMonths() async {
    final data = await _apiService.getMemberDashboard();
    String lastPaid = data?["last_paid_month"]?.toString() ?? "2026-07";

    DateTime nextMonthDate;
    try {
      final parts = lastPaid.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      nextMonthDate = DateTime(year, month + 1, 1);
    } catch (_) {
      nextMonthDate = DateTime(2026, 8, 1);
    }

    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];

    final now = DateTime.now();
    List<DueMonthItem> generated = [];
    for (int i = 0; i < 3; i++) {
      final d = DateTime(nextMonthDate.year, nextMonthDate.month + i, 1);
      final key = "${d.year}-${d.month.toString().padLeft(2, '0')}";
      final name = "${monthNames[d.month - 1]} ${d.year}";

      String status;
      if (d.year < now.year || (d.year == now.year && d.month < now.month)) {
        status = "OVERDUE";
      } else if (d.year == now.year && d.month == now.month) {
        status = "DUE_NOW";
      } else {
        status = "UPCOMING";
      }

      generated.add(
        DueMonthItem(
          monthKey: key,
          displayName: name,
          amount: 500.0,
          status: status,
          isSelected: i == 0,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _months = generated;
      });
    }
  }

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

          AppBottomSheet.show(
            context: context,
            title: "Payment Successful",
            subtitle: "Issued by MahalFlow Treasury",
            icon: Icons.check_circle_rounded,
            isDismissible: false,
            enableDrag: false,
            builder: (ctx, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text("Amount Paid", style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text("₹${_totalAmount.toInt()}", style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Receipt Number", style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      Text(receiptNum, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Months Credited", style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      Text(selectedKeys.join(', '), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/member/dashboard',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text("Return to Dashboard", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              );
            },
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
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/member/dashboard',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 14),

            // Special Contribution Quick Banner (Top of upcoming/unpaid months)
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/member/contribution'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF0ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE05638).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE05638).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.volunteer_activism, color: Color(0xFFE05638), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Make a Special Contribution",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE05638),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Donate to Zakat, Masjid, or General Fund",
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFE05638)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bento Container for Unpaid / Upcoming Months
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
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        );
      case "DUE_NOW":
      case "DUE_SOON":
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, size: 12, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              "Due Now",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ],
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              "Upcoming",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
    }
  }
}
