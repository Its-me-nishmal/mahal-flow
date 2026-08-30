import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_filter_chip_bar.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../widgets/admin_bottom_nav_bar.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = "All";
  bool _isLoading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getAuditLogs();
    if (mounted) {
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(dynamic rawDate) {
    if (rawDate == null) return "Just now";
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      if (dt.year < 2000) return "Recent";
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return DateFormat('MMM d • h:mm a').format(dt);
    } catch (_) {
      return "Recent";
    }
  }

  String _deriveType(dynamic action) {
    final act = action?.toString().toUpperCase() ?? "";
    if (act.contains("PAYMENT") || act.contains("DUES") || act.contains("RECEIPT") || act.contains("DONATION")) return "Payment";
    if (act.contains("MEMBER") || act.contains("PROFILE")) return "Member";
    if (act.contains("ALERT") || act.contains("BROADCAST")) return "Alerts";
    return "System";
  }

  List<Map<String, dynamic>> get _filteredLogs {
    final query = _searchController.text.trim().toLowerCase();
    return _logs.whereType<Map>().map((raw) => Map<String, dynamic>.from(raw)).where((l) {
      final type = _deriveType(l["action"]);
      final action = (l["action"] ?? "").toString().toLowerCase();
      final details = (l["details"] ?? "").toString().toLowerCase();
      final actor = (l["actor"] ?? "").toString().toLowerCase();

      final matchesType = _activeFilter == "All" || type == _activeFilter;
      final matchesQuery = query.isEmpty || action.contains(query) || details.contains(query) || actor.contains(query);

      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredLogs;

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
          "Audit Logs",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: "Refresh Logs",
            onPressed: _loadLogs,
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
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
                  hintText: "Search action, actor, details...",
                ),
                const SizedBox(height: 10),
                AppFilterChipBar(
                  options: const ["All", "Payment", "Member", "Alerts", "System"],
                  selectedOption: _activeFilter,
                  onSelected: (val) => setState(() => _activeFilter = val),
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
                      itemBuilder: (context, index) => const ShimmerCardSkeleton(height: 75),
                    ),
                  )
                : displayed.isEmpty
                    ? EmptyStateView(
                        icon: Icons.history_rounded,
                        title: "No Logs Found",
                        description: _searchController.text.isNotEmpty
                            ? "No audit records matching '${_searchController.text}'."
                            : "No logs found under '$_activeFilter' category.",
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: displayed.length,
                          itemBuilder: (context, index) {
                            final log = displayed[index];
                            final type = _deriveType(log["action"]);
                            return _buildLogEntry(log, type);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log, String type) {
    Color typeColor;
    Color typeBg;
    IconData typeIcon;

    if (type == "Payment") {
      typeColor = AppColors.success;
      typeBg = AppColors.successBg;
      typeIcon = Icons.payment_rounded;
    } else if (type == "Member") {
      typeColor = AppColors.info;
      typeBg = AppColors.infoBg;
      typeIcon = Icons.person_rounded;
    } else if (type == "Alerts") {
      typeColor = AppColors.warning;
      typeBg = AppColors.warningBg;
      typeIcon = Icons.campaign_rounded;
    } else {
      typeColor = AppColors.textSecondary;
      typeBg = AppColors.background;
      typeIcon = Icons.settings_rounded;
    }

    final action = log["action"]?.toString() ?? "SYSTEM_ACTION";
    final details = log["details"]?.toString() ?? action;
    final actor = log["actor"]?.toString() ?? "System";
    final timeStr = _formatTimestamp(log["created_at"] ?? log["timestamp"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: typeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(typeIcon, size: 16, color: typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  details,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "By $actor",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
