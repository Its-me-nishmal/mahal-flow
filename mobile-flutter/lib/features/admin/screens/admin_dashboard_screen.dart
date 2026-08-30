import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_metric_card.dart';
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
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final data = await _apiService.getAdminDashboard();
    final receipts = await _apiService.getRecentReceipts();
    if (mounted) {
      setState(() {
        if (data != null) {
          _totalCollected = (data["total_collected_mtd"] as num?)?.toDouble() ?? 0;
          _pendingDues = (data["total_pending_dues"] as num?)?.toDouble() ?? 0;
          _paidMembers = (data["paid_members"] as num?)?.toInt() ?? 0;
          _pendingMembers = (data["pending_members"] as num?)?.toInt() ?? 0;
          _totalMembers = (data["total_members"] as num?)?.toInt() ?? 0;
          _subscriptionStatus = data["subscription_status"]?.toString() ?? "ACTIVE";
        }
        if (receipts.isNotEmpty) {
          _recentTransactions = receipts;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          "MahalFlow Admin",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: "Refresh Dashboard",
            onPressed: () {
              setState(() => _isLoading = true);
              _loadAdminData();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: const Center(
                  child: Text(
                    "A",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      drawer: _buildAdminDrawer(context),
      body: RefreshIndicator(
        onRefresh: _loadAdminData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dashboard Overview",
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Real-time ledger & financial tracking for Calicut Central Mahal",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openAddMemberDialog(context),
                      icon: const Icon(Icons.person_add_outlined, size: 16, color: AppColors.primary),
                      label: Text(
                        "Add Member",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openRecordDuesDialog(context),
                      icon: const Icon(Icons.receipt_long_outlined, size: 16, color: Colors.white),
                      label: Text(
                        "Record Payment",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Metric Cards Grid with Shimmer support
              if (_isLoading)
                ShimmerLoading(
                  isLoading: true,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.65,
                    children: List.generate(
                      4,
                      (_) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: [
                    AppMetricCard(
                      title: "Total Collected",
                      value: "₹${_totalCollected.toInt()}",
                      color: AppColors.success,
                      bgColor: AppColors.successBg,
                      icon: Icons.trending_up_rounded,
                      onTap: () => Navigator.of(context).pushNamed('/admin/reports'),
                    ),
                    AppMetricCard(
                      title: "Pending Dues",
                      value: _pendingDues <= 0 ? "₹0" : "₹${_pendingDues.toInt()}",
                      color: AppColors.warning,
                      bgColor: AppColors.warningBg,
                      icon: Icons.schedule_rounded,
                      onTap: () => Navigator.of(context).pushNamed('/admin/reports'),
                    ),
                    AppMetricCard(
                      title: "Paid Members",
                      value: "$_paidMembers",
                      color: AppColors.info,
                      bgColor: AppColors.infoBg,
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () => Navigator.of(context).pushNamed('/admin/members'),
                    ),
                    AppMetricCard(
                      title: "Pending Members",
                      value: "$_pendingMembers",
                      color: AppColors.error,
                      bgColor: AppColors.errorBg,
                      icon: Icons.pending_outlined,
                      onTap: () => Navigator.of(context).pushNamed('/admin/members'),
                    ),
                  ],
                ),
              const SizedBox(height: 18),

              _buildRecentTransactionsCard(),
              const SizedBox(height: 14),

              _buildSystemStatusCard(),
              const SizedBox(height: 14),

              _buildAnnouncementCard(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
    );
  }

  void _openAddMemberDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final houseCtrl = TextEditingController();
    final duesCtrl = TextEditingController(text: "500");
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      title: "Register Member",
      subtitle: "Add new family record to MahalFlow directory",
      icon: Icons.person_add_rounded,
      builder: (ctx, setDialogState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Full Name *",
                hintText: "e.g. Abdul Kareem",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number *",
                hintText: "+91 98471 11222",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: houseCtrl,
              decoration: InputDecoration(
                labelText: "House Name",
                hintText: "e.g. Darussalam",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: duesCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Monthly Dues (₹)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        if (name.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fill name and phone")),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        final dues = double.tryParse(duesCtrl.text) ?? 500.0;
                        final res = await _apiService.createMember(
                          name: name,
                          phone: phone,
                          houseName: houseCtrl.text.trim().isNotEmpty ? houseCtrl.text.trim() : null,
                          duesAmount: dues,
                        );

                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          if (mounted && res != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ Member $name registered successfully!"),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                            _loadAdminData();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text("Save Member", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
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
        const SnackBar(content: Text("No members available in directory")),
      );
      return;
    }

    String selectedMemberId = (members.first as Map<String, dynamic>)["id"]?.toString() ?? "";
    String selectedMemberName = (members.first as Map<String, dynamic>)["name"]?.toString() ?? "Member";
    String selectedMode = "CASH";
    bool isRecording = false;

    AppBottomSheet.show(
      context: context,
      title: "Record Dues Payment",
      subtitle: "Issue cryptographically signed receipt",
      icon: Icons.receipt_long_rounded,
      builder: (ctx, setDialogState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Member", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: selectedMemberId,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: members.map((m) {
                final item = m as Map<String, dynamic>;
                final mId = item["id"]?.toString() ?? "";
                final mName = item["name"]?.toString() ?? "Member";
                final house = item["house_name"]?.toString() ?? "";
                return DropdownMenuItem<String>(
                  value: mId,
                  child: Text(
                    "$mName ($house)",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setDialogState(() {
                    selectedMemberId = val;
                    final match = members.firstWhere((m) => (m as Map<String, dynamic>)["id"] == val, orElse: () => null);
                    if (match != null) {
                      selectedMemberName = (match as Map<String, dynamic>)["name"]?.toString() ?? "Member";
                    }
                  });
                }
              },
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
                DropdownMenuItem(value: "CASH", child: Text("Cash (Collected Offline)")),
                DropdownMenuItem(value: "BANK_TRANSFER", child: Text("Direct Bank Transfer")),
                DropdownMenuItem(value: "UPI", child: Text("UPI / QR Code")),
              ],
              onChanged: (val) {
                if (val != null) setDialogState(() => selectedMode = val);
              },
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Dues Amount:", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text("₹500", style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isRecording
                    ? null
                    : () async {
                        setDialogState(() => isRecording = true);
                        final now = DateTime.now();
                        final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
                        final idemp = "ADMIN_PAY_${DateTime.now().millisecondsSinceEpoch}";

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
                            final receiptNo = receipt?["receipt_number"] ?? res?["transaction_id"] ?? "Verified";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("✅ Payment recorded for $selectedMemberName! Receipt #$receiptNo"),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                            _loadAdminData();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: isRecording
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text("Confirm & Issue Receipt", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReceiptDetailsModal(BuildContext context, dynamic transaction) {
    if (transaction is! Map<String, dynamic>) return;
    final rNo = transaction["receipt_number"]?.toString() ?? "N/A";
    final amt = transaction["amount"]?.toString() ?? "0";
    final mName = transaction["member_name"]?.toString() ?? "Member";
    final date = transaction["created_at"]?.toString() ?? "Recent";
    final hash = transaction["receipt_hash"]?.toString() ?? "3f82a9...c4b2";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Cryptographic Receipt", style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildModalRow("Receipt Number", rNo),
            _buildModalRow("Payer Name", mName),
            _buildModalRow("Amount Paid", "₹$amt"),
            _buildModalRow("Transaction Date", date.split('T').first),
            _buildModalRow("Ledger Hash", hash.length > 18 ? "${hash.substring(0, 18)}..." : hash),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final verify = await _apiService.verifyReceiptCryptographic(rNo);
                  if (context.mounted) {
                    final valid = verify?["cryptographic_valid"] == true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(valid ? "✅ Blockchain Ledger Hash is Cryptographically Valid!" : "ℹ️ Receipt Verified in Database"),
                        backgroundColor: valid ? AppColors.success : AppColors.primary,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.verified_rounded, size: 17, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                label: Text("Verify On Immutable Ledger", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildAdminDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 22),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Text(
                    "AD",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Central Juma Masjid Mahal",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Admin Portal • Reg #REG/KL/2024/0912",
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _buildDrawerTile(
                  icon: Icons.dashboard_outlined,
                  title: "Dashboard",
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerTile(
                  icon: Icons.people_outline_rounded,
                  title: "Member Management",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/members');
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.assessment_outlined,
                  title: "Financial Reports",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/reports');
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.campaign_outlined,
                  title: "Broadcast Notice to Mahal",
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _openBroadcastComposer(context);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.upload_file_outlined,
                  title: "Bulk Excel Import",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/import-step1');
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.account_balance_outlined,
                  title: "Payment Gateways",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/gateways');
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.history_rounded,
                  title: "Audit Logs",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/admin/audit-logs');
                  },
                ),
                const Divider(color: AppColors.border, height: 20),
                _buildDrawerTile(
                  icon: Icons.swap_horiz_rounded,
                  title: "Switch to Member View",
                  color: AppColors.info,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/member/dashboard',
                      (route) => false,
                    );
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.logout_rounded,
                  title: "Sign Out",
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(context);
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

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 20),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: itemColor,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
    );
  }

  Widget _buildRecentTransactionsCard() {
    final list = _recentTransactions.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 29, 0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Transactions",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/admin/reports'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text(
                  "View All",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text("No transactions recorded yet", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
            ),
          ...list.map((t) {
            final name = t["member_name"]?.toString() ?? "Member";
            final desc = "${t["payment_type"] ?? "Payment"} • ${(t["receipt_number"] ?? "").toString().split('_').last}";
            final amt = (t["amount"] as num?)?.toInt() ?? 0;
            return InkWell(
              onTap: () => _showReceiptDetailsModal(context, t),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "M",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹$amt",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "Paid",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSystemStatusCard() {
    final collectionRate = _totalMembers > 0 ? (_paidMembers / _totalMembers) : 0.0;
    final collectionPct = (collectionRate * 100).toInt();
    final subColor = _subscriptionStatus == "ACTIVE" ? AppColors.success : AppColors.warning;
    final subBg = _subscriptionStatus == "ACTIVE" ? AppColors.successBg : AppColors.warningBg;

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
                "Collection Health",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: subBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _subscriptionStatus,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: subColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MTD Rate",
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                "$_paidMembers / $_totalMembers members ($collectionPct%)",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: collectionRate >= 0.7 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: collectionRate.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                collectionRate >= 0.7 ? AppColors.success : AppColors.warning,
              ),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "Broadcast Notice",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Send announcements or dunning notices directly to member phones.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _openBroadcastComposer(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              "Compose Notice",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 22,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Broadcast Notice",
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text("Target Audience", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text("All Members ($_totalMembers Families)", style: GoogleFonts.inter(fontSize: 12)),
                        selected: targetAudience == "ALL",
                        selectedColor: AppColors.primaryLight,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              targetAudience = "ALL";
                              titleCtrl.text = "Mahal Announcement";
                              msgCtrl.text = "";
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: Text("Pending Dues Only", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFB77900))),
                        selected: targetAudience == "OVERDUE_ONLY",
                        selectedColor: const Color(0xFFFFF5DC),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              targetAudience = "OVERDUE_ONLY";
                              severity = "WARNING";
                              titleCtrl.text = "Monthly Dues Notice - August 2026";
                              msgCtrl.text = "Respected member, our records indicate pending dues for your household. Please pay via the MahalFlow app.";
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text("Notice Title", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: "e.g. Monthly Dues Notice",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Message Content", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter full announcement text...",
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Priority", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: severity,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: "INFO", child: Text("Informational")),
                      DropdownMenuItem(value: "WARNING", child: Text("Warning / Due Reminder")),
                      DropdownMenuItem(value: "CRITICAL", child: Text("Critical")),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => severity = val);
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: isSending
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            final desc = msgCtrl.text.trim();
                            if (title.isEmpty || desc.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please fill title and message")),
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
                                    content: Text("✅ Notice broadcasted successfully!"),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            "Broadcast Notice",
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
