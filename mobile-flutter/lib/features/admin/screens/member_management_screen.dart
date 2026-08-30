import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_filter_chip_bar.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import 'member_details_screen.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String _selectedStatusFilter = "All";

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final rawList = await _apiService.getAdminMembers();

    List<Map<String, dynamic>> loaded = [];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final name = item["name"]?.toString() ?? "Member";
        final phone = item["phone"]?.toString() ?? "";
        final dues = (item["monthly_dues_custom_amount"] ?? item["monthly_dues"] as num?)?.toInt() ?? 500;
        final rawStatus = item["status"]?.toString() ?? "ACTIVE";
        final id = item["id"]?.toString() ?? item["_id"]?.toString() ?? "";
        final house = item["house_name"]?.toString() ?? item["address"]?.toString() ?? "";
        final email = item["email"]?.toString() ?? "";

        String displayStatus = "Active";
        if (rawStatus == "GRACE_PERIOD" || rawStatus == "OVERDUE" || rawStatus == "PENDING") {
          displayStatus = "Grace Period";
        } else if (rawStatus == "SUSPENDED" || rawStatus == "INACTIVE") {
          displayStatus = "Suspended";
        }

        loaded.add({
          "id": id,
          "name": name,
          "phone": phone,
          "email": email,
          "house_name": house,
          "amount": "₹$dues",
          "status": displayStatus,
          "raw_status": rawStatus,
        });
      }
    }

    if (mounted) {
      setState(() {
        _members = loaded;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    final query = _searchController.text.trim().toLowerCase();
    return _members.where((m) {
      final name = (m["name"] as String? ?? "").toLowerCase();
      final phone = (m["phone"] as String? ?? "").toLowerCase();
      final house = (m["house_name"] as String? ?? "").toLowerCase();
      final status = m["status"] as String? ?? "Active";

      final matchesQuery = query.isEmpty || name.contains(query) || phone.contains(query) || house.contains(query);
      final matchesStatus = _selectedStatusFilter == "All" || status == _selectedStatusFilter;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  Map<String, int> get _statusCounts {
    int active = 0, grace = 0, suspended = 0;
    for (final m in _members) {
      final st = m["status"]?.toString();
      if (st == "Active") active++;
      if (st == "Grace Period") grace++;
      if (st == "Suspended") suspended++;
    }
    return {
      "All": _members.length,
      "Active": active,
      "Grace Period": grace,
      "Suspended": suspended,
    };
  }

  void _openAddMemberModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final houseCtrl = TextEditingController();
    final duesCtrl = TextEditingController(text: "500");
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      title: "Register Member",
      subtitle: "Add new family household to Mahal directory",
      icon: Icons.person_add_rounded,
      builder: (ctx, setDialogState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Full Name *",
                hintText: "e.g. Usman Ali",
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
                hintText: "+91 98471 33445",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: houseCtrl,
              decoration: InputDecoration(
                labelText: "House Name",
                hintText: "e.g. Bismillah House",
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
                            _loadMembers();
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
                    : Text("Register Member", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredMembers;

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
          "Members Directory",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
            tooltip: "Bulk Excel Import",
            onPressed: () => Navigator.of(context).pushNamed('/admin/import-step1'),
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMemberModal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
        label: Text("Add Member", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.surface,
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hintText: "Search name, phone, house...",
                  suffixAction: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                    tooltip: "Refresh Directory",
                    onPressed: _loadMembers,
                  ),
                ),
                const SizedBox(height: 10),
                AppFilterChipBar(
                  options: const ["All", "Active", "Grace Period", "Suspended"],
                  selectedOption: _selectedStatusFilter,
                  counts: _statusCounts,
                  onSelected: (val) => setState(() => _selectedStatusFilter = val),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.background,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${displayed.length} of ${_members.length} members",
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? ShimmerLoading(
                    isLoading: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 6,
                      itemBuilder: (context, index) => const ShimmerCardSkeleton(),
                    ),
                  )
                : displayed.isEmpty
                    ? EmptyStateView(
                        icon: Icons.person_search_rounded,
                        title: "No Members Found",
                        description: _searchController.text.isNotEmpty
                            ? "No results matching '${_searchController.text}'. Try checking the spelling."
                            : "No members in '$_selectedStatusFilter' status.",
                        actionLabel: _searchController.text.isNotEmpty ? "Clear Search" : "Register Member",
                        onAction: _searchController.text.isNotEmpty
                            ? () {
                                _searchController.clear();
                                setState(() {});
                              }
                            : _openAddMemberModal,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMembers,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: displayed.length,
                          itemBuilder: (context, index) {
                            final member = displayed[index];
                            return _buildMemberCard(member);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final status = member["status"] as String? ?? "Active";
    final name = member["name"] as String? ?? "Member";
    final phone = member["phone"] as String? ?? "";
    final amount = member["amount"] as String? ?? "₹500";
    final house = member["house_name"] as String? ?? "";
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 29, 0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MemberDetailsScreen(member: member),
              ),
            );
            _loadMembers();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontSize: 15,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        house.isNotEmpty ? "$phone • $house" : phone,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
