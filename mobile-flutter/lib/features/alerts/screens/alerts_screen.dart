import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import 'alert_details_screen.dart';

class _AlertData {
  final String id;
  final String title;
  final String body;
  final String time;
  bool unread;
  final _AlertType type;

  _AlertData({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
    this.type = _AlertType.system,
  });
}

enum _AlertType { payment, overdue, success, system, default_ }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _apiService = ApiService();
  String _selectedFilter = 'All';
  List<_AlertData> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final rawList = await _apiService.getAlerts();

    List<_AlertData> loaded = [];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final id = item["id"]?.toString() ?? item["_id"]?.toString() ?? "ALT_00";
        final title = item["title"]?.toString() ?? "Notice";
        final body = item["description"]?.toString() ?? item["message"]?.toString() ?? item["details"]?.toString() ?? "";
        final status = item["status"]?.toString() ?? "ACTIVE";
        final severity = item["severity"]?.toString() ?? "INFO";

        String timeStr = "Recent";
        final rawDate = item["created_at"]?.toString();
        if (rawDate != null) {
          final parsed = DateTime.tryParse(rawDate);
          if (parsed != null) {
            final diff = DateTime.now().difference(parsed);
            if (diff.inMinutes < 60) {
              timeStr = "${diff.inMinutes}m ago";
            } else if (diff.inHours < 24) {
              timeStr = "${diff.inHours}h ago";
            } else {
              timeStr = "${diff.inDays}d ago";
            }
          }
        }

        _AlertType aType = _AlertType.system;
        if (severity == "WARNING" || severity == "ERROR") {
          aType = _AlertType.overdue;
        } else if (severity == "SUCCESS") {
          aType = _AlertType.success;
        } else if (title.toLowerCase().contains("payment") || title.toLowerCase().contains("due")) {
          aType = _AlertType.payment;
        }

        loaded.add(
          _AlertData(
            id: id,
            title: title,
            body: body,
            time: timeStr,
            unread: status == "ACTIVE",
            type: aType,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _alerts = loaded;
        _isLoading = false;
      });
    }
  }

  List<_AlertData> get _filteredAlerts {
    switch (_selectedFilter) {
      case 'Unread':
        return _alerts.where((a) => a.unread).toList();
      case 'Payment':
        return _alerts
            .where((a) => a.type == _AlertType.payment || a.type == _AlertType.overdue)
            .toList();
      case 'System':
        return _alerts
            .where((a) => a.type == _AlertType.system || a.type == _AlertType.default_)
            .toList();
      default:
        return _alerts;
    }
  }

  Future<void> _markAsRead(_AlertData alert) async {
    if (mounted) {
      setState(() {
        alert.unread = false;
      });
    }
    await _apiService.acknowledgeAlert(alert.id);
  }

  Future<void> _markAllAsRead() async {
    if (mounted) {
      setState(() {
        for (var a in _alerts) {
          a.unread = false;
        }
      });
    }
    await _apiService.markAllAlertsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All alerts marked as read")),
      );
    }
  }

  void _clearAllAlerts() async {
    final confirmed = await AppBottomSheet.showConfirmation(
      context: context,
      title: "Clear All Alerts?",
      message: "This will permanently remove all notification notices from your inbox.",
      confirmLabel: "Clear All",
      confirmColor: AppColors.error,
      icon: Icons.delete_sweep_rounded,
    );

    if (confirmed == true) {
      if (mounted) {
        setState(() {
          _alerts.clear();
        });
      }
      await _apiService.clearAllAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All alerts cleared")),
        );
      }
    }
  }

  Future<void> _removeAlert(int index, _AlertData alert) async {
    if (mounted) {
      setState(() {
        _alerts.removeWhere((item) => item.id == alert.id);
      });
    }

    await _apiService.dismissAlert(alert.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cleared: ${alert.title}"),
          action: SnackBarAction(
            label: "Undo",
            textColor: Colors.white,
            onPressed: () {
              if (mounted) {
                setState(() {
                  _alerts.insert(index < _alerts.length ? index : _alerts.length, alert);
                });
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedAlerts = _filteredAlerts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/member/dashboard');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Alerts',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: [
          if (_alerts.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.done_all, color: AppColors.primary, size: 22),
              tooltip: "Mark all as read",
              onPressed: _markAllAsRead,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error, size: 22),
              tooltip: "Clear all alerts",
              onPressed: _clearAllAlerts,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : displayedAlerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              "No alerts found",
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAlerts,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: displayedAlerts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final alert = displayedAlerts[index];
                            return Dismissible(
                              key: Key(alert.id),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (direction) => _removeAlert(index, alert),
                              child: _buildAlertItem(alert),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildFilterRow() {
    final filters = ['All', 'Unread', 'Payment', 'System'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: filters.map((f) {
          final selected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  f,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _borderColor(_AlertType type) {
    switch (type) {
      case _AlertType.payment:
        return AppColors.primary;
      case _AlertType.overdue:
        return AppColors.error;
      case _AlertType.success:
        return AppColors.success;
      case _AlertType.system:
        return AppColors.warning;
      case _AlertType.default_:
        return AppColors.primary;
    }
  }

  AlertType _mapType(_AlertType type) {
    switch (type) {
      case _AlertType.payment:
        return AlertType.payment;
      case _AlertType.overdue:
        return AlertType.overdue;
      case _AlertType.success:
        return AlertType.success;
      case _AlertType.system:
        return AlertType.system;
      case _AlertType.default_:
        return AlertType.default_;
    }
  }

  Widget _buildAlertItem(_AlertData alert) {
    final barColor = _borderColor(alert.type);

    return GestureDetector(
      onTap: () {
        _markAsRead(alert);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlertDetailsScreen(
              title: alert.title,
              body: alert.body,
              time: alert.time,
              type: _mapType(alert.type),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: alert.unread ? const Color(0xFFF7FAF8) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.unread ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(23, 32, 29, 0.03),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: barColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (alert.unread) ...[
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    alert.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: alert.unread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  alert.time,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alert.body,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
