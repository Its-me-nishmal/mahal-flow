import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_text_field.dart';
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
  static const List<String> _filters = [
    'All',
    'Active',
    'Grace Period',
    'Suspended',
  ];

  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    if (mounted) setState(() => _isLoading = true);
    final rawList = await _apiService.getAdminMembers();

    List<Map<String, dynamic>> loaded = [];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final name = item["name"]?.toString() ?? "Member";
        final phone = item["phone"]?.toString() ?? "";
        final dues = (item["monthly_dues_custom_amount"] ??
                item["monthly_dues"] as num?)
            ?.toInt() ??
            500;
        final rawStatus = item["status"]?.toString() ?? "ACTIVE";
        final id = item["id"]?.toString() ?? item["_id"]?.toString() ?? "";
        final house = item["house_name"]?.toString() ??
            item["address"]?.toString() ??
            "";
        final email = item["email"]?.toString() ?? "";

        String displayStatus = "Active";
        if (rawStatus == "GRACE_PERIOD" ||
            rawStatus == "OVERDUE" ||
            rawStatus == "PENDING") {
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

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          phone.contains(query) ||
          house.contains(query);
      final matchesStatus =
          _selectedStatusFilter == "All" || status == _selectedStatusFilter;

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
      title: 'Register a member',
      subtitle: 'Adds a household to the Mahal directory',
      icon: Icons.person_add_rounded,
      builder: (ctx, setDialogState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: nameCtrl,
              label: 'Full name',
              hint: 'e.g. Usman Ali',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: phoneCtrl,
              label: 'Phone number',
              hint: '+91 98471 33445',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: houseCtrl,
              label: 'House name (optional)',
              hint: 'e.g. Bismillah House',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: duesCtrl,
              label: 'Monthly dues (₹)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Register Member',
              isLoading: isSaving,
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and phone number are required'),
                    ),
                  );
                  return;
                }

                setDialogState(() => isSaving = true);
                final dues = double.tryParse(duesCtrl.text) ?? 500.0;
                final res = await _apiService.createMember(
                  name: name,
                  phone: phone,
                  houseName: houseCtrl.text.trim().isNotEmpty
                      ? houseCtrl.text.trim()
                      : null,
                  duesAmount: dues,
                );

                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  if (mounted && res != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name was registered.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    _loadMembers();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredMembers;

    return AppPageScaffold(
      title: 'Members',
      eyebrow: 'Directory',
      subtitle: _isLoading
          ? 'Loading the directory…'
          : 'Showing ${displayed.length} of ${_members.length} households',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        }
      },
      actions: [
        AppHeaderIconButton(
          icon: Icons.upload_file_rounded,
          tooltip: 'Bulk import',
          onTap: () => Navigator.of(context).pushNamed('/admin/import-step1'),
        ),
      ],
      headerChild: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search name, phone or house…',
            suffixAction: IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.primary, size: 20),
              tooltip: 'Refresh',
              onPressed: _loadMembers,
            ),
          ),
          const SizedBox(height: AppSpacing.ms),
          AppHeroFilterChips(
            options: _filters,
            selected: _selectedStatusFilter,
            counts: _isLoading ? null : _statusCounts,
            onSelected: (val) => setState(() => _selectedStatusFilter = val),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMemberModal,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text(
          'Add Member',
          style: AppTextStyles.button.copyWith(fontSize: 13, color: Colors.white),
        ),
      ),
      expandedChild: RefreshIndicator(
        onRefresh: _loadMembers,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _isLoading
            ? _skeleton()
            : displayed.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.md,
                      AppSpacing.screenH,
                      AppSpacing.xxl + AppSpacing.lg,
                    ),
                    itemCount: displayed.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _memberCard(displayed[index]),
                  ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 1),
    );
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final status = member["status"] as String? ?? 'Active';
    final name = member["name"] as String? ?? 'Member';
    final phone = member["phone"] as String? ?? '';
    final amount = member["amount"] as String? ?? '₹500';
    final house = member["house_name"] as String? ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    late final Color statusColor;
    late final Color statusBg;
    if (status == 'Active') {
      statusColor = AppColors.success;
      statusBg = AppColors.successBg;
    } else if (status == 'Grace Period') {
      statusColor = AppColors.warning;
      statusBg = AppColors.warningBg;
    } else {
      statusColor = AppColors.error;
      statusBg = AppColors.errorBg;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MemberDetailsScreen(member: member),
          ),
        );
        _loadMembers();
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  house.isNotEmpty ? '$phone · $house' : phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.xs),
              StatusPill(
                label: status,
                foreground: statusColor,
                background: statusBg,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    final hasQuery = _searchController.text.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.06),
        EmptyStateView(
          icon: Icons.person_search_rounded,
          title: 'No members found',
          description: hasQuery
              ? "Nothing matches '${_searchController.text}'. Check the spelling."
              : "No households are in '$_selectedStatusFilter' status.",
          actionLabel: hasQuery ? 'Clear search' : 'Register a member',
          onAction: hasQuery
              ? () {
                  _searchController.clear();
                  setState(() {});
                }
              : _openAddMemberModal,
        ),
      ],
    );
  }

  Widget _skeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: [
        for (var i = 0; i < 6; i++)
          const ShimmerLoading(child: ShimmerCardSkeleton(height: 76)),
      ],
    );
  }
}
