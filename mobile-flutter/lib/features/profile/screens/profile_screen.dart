import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../widgets/member_help_sheet.dart';
import 'edit_personal_details_screen.dart';
import '../../../core/widgets/app_settings_sheet.dart';
import '../../../l10n/l10n.dart';

enum _LoadState { loading, ready, error }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  _LoadState _loadState = _LoadState.loading;
  ApiException? _error;

  // Everything below comes from GET /members/profile/:id (and the mahal
  // name from the dashboard). Empty = not on record, rendered as "—".
  String _memberName = ApiService.cachedMemberName;
  String _phone = '';
  String _email = '';
  String _address1 = '';
  String _address2 = '';
  String _city = '';
  String _region = ''; // state / province
  String _pincode = '';
  String _memberCode = '';
  String _status = '';
  String? _mahalName;
  Map<String, dynamic>? _rawProfile;
  Map<String, dynamic>? _rawDashboard;
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // No platform info (tests): simply omit the version line.
    }
  }

  static String _str(Map<String, dynamic>? m, List<String> keys) {
    for (final k in keys) {
      final v = m?[k]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  Future<void> _loadProfile() async {
    final firstLoad = _loadState != _LoadState.ready;
    if (firstLoad) {
      setState(() {
        _loadState = _LoadState.loading;
        _error = null;
      });
    }
    try {
      // The dashboard is only needed for the Mahal name; its failure must not
      // hide the profile.
      final dashboardFuture = _apiService.getMemberDashboard();
      final profile = await _apiService.getMemberProfileOrThrow();
      final dashboard = await dashboardFuture;
      if (!mounted) return;
      setState(() {
        _rawProfile = profile;
        _rawDashboard = dashboard;
        _memberName = _str(profile, ['name']);
        _phone = _str(profile, ['phone']);
        _email = _str(profile, ['email']);
        _address1 = _str(profile, ['house_name', 'address']);
        _address2 = _str(profile, ['address2', 'street']);
        _city = _str(profile, ['city']);
        _region = _str(profile, ['state']);
        _pincode = _str(profile, ['pincode', 'pin_code']);
        _memberCode = _str(profile, ['member_code', 'id', 'member_id']);
        _status = _str(profile, ['status']).toUpperCase();
        final mahal = _str(dashboard, ['mahal_name']);
        _mahalName = mahal.isEmpty ? _mahalName : mahal;
        _loadState = _LoadState.ready;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (firstLoad) {
        setState(() {
          _loadState = _LoadState.error;
          _error = e;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileRefreshFailed(e.userMessage)),
          ),
        );
      }
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.memberEditProfile),
        builder: (_) => EditPersonalDetailsScreen(
          name: _memberName,
          email: _email,
          phone: _phone,
          address1: _address1,
          address2: _address2,
          city: _city,
          state: _region,
          pincode: _pincode,
        ),
      ),
    );
    // The edit screen only returns values the server accepted.
    if (updated == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.profileUpdated)),
    );
    // Show what the server actually stored.
    _loadProfile();
  }

  Future<void> _logout() async {
    final confirmed = await AppBottomSheet.showConfirmation(
      context: context,
      title: context.l10n.profileLogoutTitle,
      message: context.l10n.profileLogoutMessage,
      confirmLabel: context.l10n.profileLogout,
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (confirmed == true && mounted) {
      await PushNotificationService.instance.onSignOut();
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.login, (route) => false);
    }
  }

  Future<void> _replayWelcome() async {
    await AppPrefs.resetOnboarding();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.onboarding, (route) => false);
  }

  void _showHelp() {
    MemberHelpSheet.show(
      context,
      mahalName: _mahalName,
      officePhone: MemberHelpSheet.contactPhoneFrom(_rawDashboard) ??
          MemberHelpSheet.contactPhoneFrom(_rawProfile),
      whatsApp: MemberHelpSheet.contactWhatsAppFrom(_rawDashboard) ??
          MemberHelpSheet.contactWhatsAppFrom(_rawProfile),
    );
  }

  String get _fullAddress {
    final parts = [_address1, _address2, _city, _region, _pincode]
        .where((p) => p.trim().isNotEmpty);
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  String _orDash(String v) => v.isEmpty ? '—' : v;

  @override
  Widget build(BuildContext context) {
    final ready = _loadState == _LoadState.ready;
    final l10n = context.l10n;
    return AppPageScaffold(
      title: l10n.commonProfile,
      eyebrow: l10n.profileEyebrow,
      showBack: false,
      onRefresh: _loadState == _LoadState.loading ? null : _loadProfile,
      actions: [
        if (ready)
          AppHeaderIconButton(
            icon: Icons.edit_outlined,
            tooltip: l10n.profileEditTooltip,
            onTap: _openEditProfile,
          ),
      ],
      headerChild: _identityBlock(),
      floatingChild: switch (_loadState) {
        _LoadState.ready => _detailsCard(),
        _LoadState.loading => ShimmerLoading(
            semanticsLabel: l10n.profileLoading,
            child: const ShimmerCardSkeleton(height: 220),
          ),
        _LoadState.error => AppCard.floating(
            child: AppErrorStateView(
              title: l10n.profileLoadError,
              description: _error?.userMessage ?? l10n.profileLoadErrorFallback,
              onRetry: _loadProfile,
            ),
          ),
      },
      content: [
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(title: l10n.profileSectionPayments),
        _settingsCard([
          _SettingsItem(
            icon: Icons.sync_rounded,
            iconColor: context.colors.info,
            iconBackground: context.colors.infoBg,
            title: l10n.profileAutopay,
            subtitle: l10n.profileAutopaySubtitle,
            onTap: () => Navigator.pushNamed(context, AppRoutes.memberAutopay),
          ),
          _SettingsItem(
            icon: Icons.receipt_long_outlined,
            iconColor: context.colors.primary,
            iconBackground: context.colors.primaryLight,
            title: l10n.profileReceipts,
            subtitle: l10n.profileReceiptsSubtitle,
            onTap: () =>
                AppNav.switchMemberTab(context, AppRoutes.memberReceipts),
          ),
          _SettingsItem(
            icon: Icons.payments_outlined,
            iconColor: context.colors.warning,
            iconBackground: context.colors.warningBg,
            title: l10n.profilePayDues,
            subtitle: l10n.profilePayDuesSubtitle,
            onTap: () => AppNav.switchMemberTab(context, AppRoutes.memberPay),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(title: l10n.profileSectionApp),
        _settingsCard([
          _SettingsItem(
            icon: Icons.tune_rounded,
            iconColor: context.colors.primary,
            iconBackground: context.colors.primaryLight,
            title: context.l10n.settingsRowTitle,
            subtitle: AppSettingsSheet.summary(context),
            onTap: () async {
              await AppSettingsSheet.show(context);
              if (mounted) setState(() {});
            },
          ),
          _SettingsItem(
            icon: Icons.campaign_outlined,
            iconColor: context.colors.success,
            iconBackground: context.colors.successBg,
            title: l10n.profileNotices,
            subtitle: l10n.profileNoticesSubtitle,
            onTap: () =>
                AppNav.switchMemberTab(context, AppRoutes.memberAlerts),
          ),
          _SettingsItem(
            icon: Icons.help_outline_rounded,
            iconColor: context.colors.textSecondary,
            iconBackground: context.colors.neutralBg,
            title: l10n.helpTitle,
            subtitle: l10n.profileHelpSubtitle,
            onTap: _showHelp,
          ),
          _SettingsItem(
            icon: Icons.slideshow_outlined,
            iconColor: context.colors.textSecondary,
            iconBackground: context.colors.neutralBg,
            title: l10n.profileReplayWelcome,
            subtitle: l10n.profileReplayWelcomeSubtitle,
            onTap: _replayWelcome,
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        AppSecondaryButton(
          label: l10n.profileLogout,
          icon: Icons.logout_rounded,
          color: context.colors.error,
          onPressed: _logout,
        ),
        if (_version != null) ...[
          const SizedBox(height: AppSpacing.ms),
          Center(
            child: Text(
              l10n.profileVersion(_version!),
              style:
                  context.text.small.copyWith(color: context.colors.textMuted),
            ),
          ),
        ],
      ],
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 4),
    );
  }

  Widget _identityBlock() {
    final name = _memberName.trim();
    return Row(
      children: [
        AppAvatar(
          name: name,
          size: 66,
          onHero: true,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  name.isEmpty ? context.l10n.commonMember : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.sectionTitle.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              if (_phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  PhoneFormat.display(_phone),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.small.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailsCard() {
    final l10n = context.l10n;
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionLabel(
            l10n.profileMembership,
            trailing:
                _status.isEmpty ? null : StatusPill.forStatus(context, _status),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDetailRow(
              label: l10n.profileMemberId,
              value: _orDash(_memberCode),
              emphasize: true),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
              label: l10n.profileMahal, value: _orDash(_mahalName ?? '')),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(label: l10n.profileEmail, value: _orDash(_email)),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(label: l10n.profileAddress, value: _fullAddress),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: l10n.profileEditDetails,
            icon: Icons.edit_outlined,
            height: AppSizes.buttonHeightCompact,
            onPressed: _openEditProfile,
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(List<_SettingsItem> items) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.colors.border),
            Semantics(
              button: true,
              label: '${items[i].title}. ${items[i].subtitle}',
              excludeSemantics: true,
              child: InkWell(
                onTap: items[i].onTap,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(i == 0 ? AppRadius.card : 0),
                  bottom: Radius.circular(
                      i == items.length - 1 ? AppRadius.card : 0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.ms,
                    vertical: AppSpacing.ms,
                  ),
                  child: Row(
                    children: [
                      AppIconChip(
                        icon: items[i].icon,
                        color: items[i].iconColor,
                        background: items[i].iconBackground,
                        size: 38,
                      ),
                      const SizedBox(width: AppSpacing.ms),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(items[i].title, style: context.text.listTitle),
                            const SizedBox(height: 2),
                            Text(items[i].subtitle, style: context.text.small),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: context.colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
