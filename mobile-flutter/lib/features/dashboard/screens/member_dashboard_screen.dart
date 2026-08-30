import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  String _memberName = "Member";
  String _mahalName = "Central Juma Masjid Mahal";
  double _outstanding = 0.0;
  double _advanceCredit = 0.0;
  Map<String, dynamic>? _latestReceipt;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getMemberDashboard();
    if (mounted) {
      setState(() {
        if (data != null) {
          final fullName = data["member_name"]?.toString() ?? "Member";
          _memberName = fullName.split(' ').first;
          _mahalName = data["mahal_name"]?.toString() ?? "Central Juma Masjid Mahal";
          final rawOut = (data["outstanding_balance"] as num?)?.toDouble() ?? 0.0;
          _outstanding = rawOut > 0 ? rawOut : 0.0;
          _advanceCredit = (data["advance_credit"] as num?)?.toDouble() ?? 0.0;
          _latestReceipt = data["latest_payment"] as Map<String, dynamic>?;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/member/profile'),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                _memberName.isNotEmpty ? _memberName[0] : "M",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          "MahalFlow",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Need help? Contact your Mahal Committee office."),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Welcome Section matching Stitch design
                    Text(
                      "Assalamu Alaikum,\n$_memberName",
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.mosque, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          _mahalName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Outstanding Dues Bento Card
                    _buildOutstandingDuesCard(),
                    const SizedBox(height: 16),

                    // 3. Latest Payment Card
                    _buildLatestPaymentCard(),
                    const SizedBox(height: 16),

                    // 4. Quick Action: Make a Contribution Card
                    _buildQuickActionCard(
                      icon: Icons.volunteer_activism,
                      iconBg: const Color(0xFFFDF0ED),
                      iconColor: const Color(0xFFE05638),
                      title: "Make a Contribution",
                      subtitle: "Donate to Zakat, General Fund, or Masjid Renovation.",
                      onTap: () => Navigator.of(context).pushNamed('/member/contribution'),
                    ),
                    const SizedBox(height: 12),

                    // 5. Quick Action: Payment History Card
                    _buildQuickActionCard(
                      icon: Icons.history,
                      iconBg: const Color(0xFFEAF3FB),
                      iconColor: const Color(0xFF3478B8),
                      title: "Payment History",
                      subtitle: "View all past contributions and receipts.",
                      onTap: () => Navigator.of(context).pushNamed('/member/receipts'),
                    ),
                    const SizedBox(height: 12),

                    // 6. Quick Action: Mahal Announcements Card
                    _buildQuickActionCard(
                      icon: Icons.article_outlined,
                      iconBg: const Color(0xFFE6E9E6),
                      iconColor: AppColors.primary,
                      title: "Mahal Announcements",
                      subtitle: "Important alerts and notices from committee.",
                      onTap: () => Navigator.of(context).pushNamed('/member/alerts'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildOutstandingDuesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _outstanding > 0 ? "Outstanding Dues" : "Monthly Dues",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _outstanding > 0 ? const Color(0xFFFFF5DC) : AppColors.successBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _outstanding > 0 ? "Action Required" : "Up to Date",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _outstanding > 0 ? const Color(0xFFB77900) : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "₹${_outstanding > 0 ? _outstanding.toInt() : 0}",
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: _outstanding > 0 ? const Color(0xFFC93B3B) : AppColors.success,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _outstanding > 0
                ? "Pending monthly dues balance"
                : "All monthly dues paid in full",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          if (_advanceCredit > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    "Advance Credit: ₹${_advanceCredit.toInt()}",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_outstanding > 0)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).pushNamed('/member/pay');
                  _loadDashboardData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Pay Dues Now",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLatestPaymentCard() {
    if (_latestReceipt == null) {
      return const SizedBox.shrink();
    }

    final amount = (_latestReceipt?["amount"] as num?)?.toInt() ?? 0;
    final paymentType = _latestReceipt?["payment_type"]?.toString() ?? "MONTHLY_DUES";
    final paidMonthsList = (_latestReceipt?["paid_months"] as List?)?.map((e) => e.toString()).toList() ?? [];
    final paidMonthsStr = paidMonthsList.isNotEmpty ? paidMonthsList.join(", ") : "Contribution";
    final receiptNum = _latestReceipt?["receipt_number"]?.toString() ?? "Verified";

    String formattedDate = "Recently Paid";
    final rawDate = _latestReceipt?["created_at"]?.toString();
    if (rawDate != null) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        const monthsNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        formattedDate = "Paid on ${monthsNames[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
      }
    }

    final title = paymentType == "MONTHLY_DUES" ? "Monthly Dues ($paidMonthsStr)" : "Mahal Contribution";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            "Latest Payment",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹$amount",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF16834B)),
                    const SizedBox(width: 4),
                    Text(
                      "Paid",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF16834B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pushNamed('/member/receipts'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      receiptNum.length > 18 ? "${receiptNum.substring(0, 16)}..." : receiptNum,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.receipt_long, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
