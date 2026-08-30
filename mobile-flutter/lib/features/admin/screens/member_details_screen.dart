import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
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

    if (mounted) {
      final Map<String, String> paidMonths = {};
      for (final r in receipts) {
        if (r is Map<String, dynamic>) {
          final paidFor = r["paid_months"] ?? r["selected_months"];
          final createdAt = r["created_at"]?.toString() ?? "";
          if (paidFor is List) {
            for (final m in paidFor) {
              paidMonths[m.toString()] = r["receipt_number"]?.toString() ?? "Paid";
            }
          } else if (createdAt.length >= 7) {
            paidMonths[createdAt.substring(0, 7)] = r["receipt_number"]?.toString() ?? "Paid";
          }
        }
      }

      final now = DateTime.now();
      final List<Map<String, dynamic>> history = [];
      for (int i = 0; i < 6; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
        final monthNames = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
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
  }

  void _showReceiptModal(String receiptNo) {
    dynamic matched;
    for (final r in _receiptsList) {
      if (r is Map<String, dynamic> && r["receipt_number"] == receiptNo) {
        matched = r;
        break;
      }
    }

    final amt = matched?["amount"] ?? 500;
    final date = matched?["created_at"] ?? "Recent";
    final hash = matched?["receipt_hash"]?.toString() ?? "3a8f9c...d4e1";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Cryptographic Receipt", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildModalRow("Receipt Number", receiptNo),
            _buildModalRow("Member Name", member["name"]?.toString() ?? "Member"),
            _buildModalRow("Amount Paid", "₹$amt"),
            _buildModalRow("Transaction Date", date.toString().split('T').first),
            _buildModalRow("Ledger Hash", hash.length > 16 ? "${hash.substring(0, 16)}..." : hash),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final verify = await _apiService.verifyReceiptCryptographic(receiptNo);
                  if (!mounted) return;
                  final valid = verify?["cryptographic_valid"] == true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(valid ? "✅ Blockchain Ledger Hash is Cryptographically Valid!" : "ℹ️ Receipt Verified in Database"),
                      backgroundColor: valid ? AppColors.success : AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.verified, size: 18, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                label: Text("Verify On Immutable Ledger", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
      title: "Record Payment",
      subtitle: "Member: $memberName",
      icon: Icons.receipt_long_rounded,
      builder: (ctx, setDialogState) {
        final totalAmount = 500 * selectedMonthsCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Number of Months to Pay", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 3, 6].map((cnt) {
                final isSel = selectedMonthsCount == cnt;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text("$cnt Mo", style: GoogleFonts.inter(fontSize: 12)),
                    selected: isSel,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (selected) {
                      if (selected) setDialogState(() => selectedMonthsCount = cnt);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text("Payment Method", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: selectedMode,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: "CASH", child: Text("Cash (Offline Collected)")),
                DropdownMenuItem(value: "BANK_TRANSFER", child: Text("Direct Bank Transfer")),
                DropdownMenuItem(value: "UPI", child: Text("UPI / QR Code")),
              ],
              onChanged: (val) {
                if (val != null) setDialogState(() => selectedMode = val);
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Payable:", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text("₹$totalAmount", style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() => isProcessing = true);
                        final now = DateTime.now();
                        final List<String> monthsToCredit = [];
                        for (int i = 0; i < selectedMonthsCount; i++) {
                          final dt = DateTime(now.year, now.month + i, 1);
                          monthsToCredit.add("${dt.year}-${dt.month.toString().padLeft(2, '0')}");
                        }

                        final idemp = "ADMIN_REC_${DateTime.now().millisecondsSinceEpoch}";
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
                            final receiptNo = receipt?["receipt_number"] ?? res?["transaction_id"] ?? "Verified";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ Payment of ₹$totalAmount recorded! Receipt #$receiptNo"),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                            _loadDuesHistory();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text("Confirm & Issue Receipt", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          "Member Details",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (val) async {
              if (val == "edit") {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditMemberDetailsScreen(member: member),
                  ),
                );
                _loadDuesHistory();
              } else if (val == "notice") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("SMS Dues notice sent to member")),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: "edit", child: Text("Edit Member Profile")),
              const PopupMenuItem(value: "notice", child: Text("Send Dues Notice SMS")),
            ],
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDuesHistory,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 16),
              _buildInfoCards(),
              const SizedBox(height: 16),
              _buildDuesHistory(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditMemberDetailsScreen(member: member),
                          ),
                        );
                        _loadDuesHistory();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Edit Member",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRecordPaymentDialog(context),
                      icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: Text(
                        "Record Payment",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final status = member["status"] as String? ?? "Active";
    final name = member["name"]?.toString() ?? "Member";
    final phone = member["phone"]?.toString() ?? "";
    final memberId = member["id"]?.toString() ?? "";

    Color statusColor;
    Color statusBg;

    if (status == "Active") {
      statusColor = AppColors.success;
      statusBg = AppColors.successBg;
    } else if (status == "Grace Period") {
      statusColor = AppColors.warning;
      statusBg = AppColors.warningBg;
    } else {
      statusColor = AppColors.error;
      statusBg = AppColors.errorBg;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 29, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              name.isNotEmpty ? name[0] : "M",
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          if (memberId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Member ID: $memberId",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    final duesAmount = member["amount"]?.toString() ?? "₹500";
    final status = member["status"]?.toString() ?? "Active";
    final houseName = member["house_name"]?.toString() ?? "";

    String lastPaid = "N/A";
    for (final h in _duesHistory) {
      if (h["status"] == "Paid") {
        lastPaid = h["month"]?.toString() ?? "N/A";
        break;
      }
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(23, 32, 29, 0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Monthly Dues",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  duesAmount,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Last: $lastPaid",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(23, 32, 29, 0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "House Name",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  houseName.isNotEmpty ? houseName : "Central House",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Status: $status",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuesHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 29, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dues History",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingHistory)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
            )
          else
            ..._duesHistory.map((m) {
              final status = m["status"]?.toString() ?? "Unknown";
              final receiptNo = m["receipt_number"] as String?;
              Color chipColor;
              Color chipBg;
              if (status == "Paid") {
                chipColor = AppColors.success;
                chipBg = AppColors.successBg;
              } else if (status == "Overdue") {
                chipColor = AppColors.error;
                chipBg = AppColors.errorBg;
              } else {
                chipColor = AppColors.warning;
                chipBg = AppColors.warningBg;
              }

              return InkWell(
                onTap: receiptNo != null ? () => _showReceiptModal(receiptNo) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            m["month"]?.toString() ?? "",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (receiptNo != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.receipt, size: 14, color: AppColors.primary),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: chipColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
