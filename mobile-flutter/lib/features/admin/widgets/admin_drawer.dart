import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../data/admin_context.dart';
import '../utils/admin_format.dart';
import '../../../core/widgets/app_settings_sheet.dart';
import '../../../l10n/l10n.dart';

/// Committee navigation drawer. Header shows the tenant's Mahal record from
/// GET /admin/mahals/:id ("—" until it loads).
class AdminDrawer extends StatelessWidget {
  /// Opens the broadcast composer on the host screen.
  final VoidCallback onBroadcast;

  /// Runs on the host screen (the drawer's own context is gone once it
  /// closes); usually `() => AdminDrawer.confirmSignOut(context)`.
  final VoidCallback onSignOut;

  const AdminDrawer({
    super.key,
    required this.onBroadcast,
    required this.onSignOut,
  });

  /// Admin identities carry no member id, so the member view would have no
  /// data to show; only offer it when a member session exists.
  static bool get canSwitchToMemberView =>
      ApiService.hasSession && (ApiService.currentMemberId ?? '').isNotEmpty;

  static Future<void> confirmSignOut(BuildContext context) async {
    final ok = await AppBottomSheet.showConfirmation(
      context: context,
      title: 'Sign out?',
      message: 'You will need to verify your phone number again to open the '
          'committee portal.',
      confirmLabel: 'Sign out',
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (ok != true || !context.mounted) return;
    await PushNotificationService.instance.onSignOut();
    await ApiService.logout();
    AdminContext.reset();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    void go(String route, {bool tab = false}) {
      Navigator.pop(context);
      if (tab) {
        AppNav.switchAdminTab(context, route);
      } else {
        Navigator.of(context).pushNamed(route);
      }
    }

    return Drawer(
      backgroundColor: context.colors.surface,
      child: Column(
        children: [
          _header(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _tile(context, 
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                ),
                _tile(context, 
                  icon: Icons.people_outline_rounded,
                  title: 'Members',
                  onTap: () => go(AppRoutes.adminMembers, tab: true),
                ),
                ValueListenableBuilder<int?>(
                  valueListenable: AdminContext.pendingCount,
                  builder: (context, count, _) => _tile(context, 
                    icon: Icons.how_to_reg_outlined,
                    title: 'Pending approvals',
                    badge: count,
                    onTap: () => go(AppRoutes.adminPendingApprovals),
                  ),
                ),
                _tile(context, 
                  icon: Icons.assessment_outlined,
                  title: 'Financial reports',
                  onTap: () => go(AppRoutes.adminReports, tab: true),
                ),
                _tile(context, 
                  icon: Icons.campaign_outlined,
                  title: 'Broadcast a notice',
                  color: context.colors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    onBroadcast();
                  },
                ),
                _tile(context, 
                  icon: Icons.upload_file_outlined,
                  title: 'Bulk import',
                  onTap: () => go(AppRoutes.adminImportStep1),
                ),
                _tile(context, 
                  icon: Icons.account_balance_outlined,
                  title: 'Payment gateways',
                  onTap: () => go(AppRoutes.adminGateways),
                ),
                _tile(context, 
                  icon: Icons.history_rounded,
                  title: 'Audit log',
                  onTap: () => go(AppRoutes.adminAuditLogs, tab: true),
                ),
                Divider(color: context.colors.border, height: AppSpacing.lg),
                _tile(
                  context,
                  icon: Icons.tune_rounded,
                  title: context.l10n.settingsRowTitle,
                  onTap: () {
                    // The drawer's context goes away as it closes; open the
                    // sheet from the navigator's instead.
                    final host = Navigator.of(context).context;
                    Navigator.pop(context);
                    AppSettingsSheet.show(host);
                  },
                ),
                if (canSwitchToMemberView)
                  _tile(context, 
                    icon: Icons.swap_horiz_rounded,
                    title: 'Switch to member view',
                    color: context.colors.info,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.memberDashboard,
                        (route) => false,
                      );
                    },
                  ),
                _tile(context, 
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  color: context.colors.error,
                  onTap: () {
                    Navigator.pop(context);
                    onSignOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: context.colors.heroGradient),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: MediaQuery.paddingOf(context).top + AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      child: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: AdminContext.mahal,
        builder: (context, _, __) {
          final name = AdminContext.mahalName ?? '—';
          final reg = AdminContext.registrationNumber;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSizes.minTouch + AppSpacing.xs,
                height: AppSizes.minTouch + AppSpacing.xs,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AdminHeroColors.fill,
                  shape: BoxShape.circle,
                  border: Border.all(color: AdminHeroColors.faint),
                ),
                child: const Icon(Icons.mosque_rounded,
                    size: 26, color: AdminHeroColors.text),
              ),
              const SizedBox(height: AppSpacing.ms),
              Text(
                name,
                style: context.text.cardTitle
                    .copyWith(color: AdminHeroColors.text),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                reg == null ? 'Committee portal' : 'Committee portal · $reg',
                style:
                    context.text.small.copyWith(color: AdminHeroColors.muted),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    int? badge,
  }) {
    final itemColor = color ?? context.colors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 22),
      title: Text(
        title,
        style: context.text.body.copyWith(
          fontWeight: FontWeight.w500,
          color: itemColor,
        ),
      ),
      trailing: (badge != null && badge > 0)
          ? Semantics(
              label: '$badge waiting',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs / 2),
                decoration: BoxDecoration(
                  color: context.colors.error,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: context.text.label.copyWith(color: context.colors.onPrimary),
                ),
              ),
            )
          : null,
      onTap: onTap,
      minTileHeight: AppSizes.minTouch + AppSpacing.xs,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }
}
