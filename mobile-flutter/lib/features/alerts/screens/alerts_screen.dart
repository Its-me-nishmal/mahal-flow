import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import 'alert_details_screen.dart';

class _AlertData {
  final String title;
  final String body;
  final String time;
  final bool unread;
  final _AlertType type;

  const _AlertData({
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
  String _selectedFilter = 'All';

  final List<_AlertData> _alerts = [
    const _AlertData(
      title: 'Payment Reminder',
      body: 'Your monthly dues of ₹500 for August 2026 are due in 3 days.',
      time: '2 hours ago',
      unread: true,
      type: _AlertType.payment,
    ),
    const _AlertData(
      title: 'Dues Overdue',
      body:
          'June 2026 dues (₹500) are overdue. Please pay to avoid late fees.',
      time: '1 day ago',
      unread: true,
      type: _AlertType.overdue,
    ),
    const _AlertData(
      title: 'Payment Received',
      body:
          'Your payment of ₹1,500 for Jun-Aug 2026 has been received.',
      time: '3 days ago',
      type: _AlertType.success,
    ),
    const _AlertData(
      title: 'AutoPay Setup',
      body:
          'AutoPay has been enabled for your account. ₹500 will be deducted on the 1st.',
      time: '1 week ago',
      type: _AlertType.system,
    ),
    const _AlertData(
      title: 'Welcome to MahalFlow',
      body: 'Your account has been created. Start by paying your dues.',
      time: '2 weeks ago',
      type: _AlertType.default_,
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'Alerts',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _filteredAlerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _buildAlertItem(_filteredAlerts[index]),
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
        return AppColors.info;
      case _AlertType.overdue:
        return AppColors.error;
      case _AlertType.success:
        return AppColors.success;
      case _AlertType.system:
        return AppColors.warning;
      case _AlertType.default_:
        return AppColors.border;
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
    return GestureDetector(
      onTap: () {
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: _borderColor(alert.type),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
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
                          Text(
                            alert.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: alert.unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
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
                          const SizedBox(height: 4),
                          Text(
                            alert.time,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
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
    );
  }
}
