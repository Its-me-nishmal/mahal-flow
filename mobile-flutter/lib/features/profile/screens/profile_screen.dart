import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import 'edit_personal_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  String _memberName = ApiService.cachedMemberName;
  String _phone = ApiService.cachedPhone;
  String _email = ApiService.cachedEmail;
  String _address1 = ApiService.cachedAddress;
  String _address2 = "";
  String _city = "Calicut";
  String _state = "Kerala";
  String _pincode = "673001";
  String _mahalName = "Central Juma Masjid Mahal";
  String _memberId = "MEM_001_9910";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _apiService.getMemberProfile();
    if (profile != null && mounted) {
      setState(() {
        _memberName = profile["name"]?.toString() ?? _memberName;
        _phone = profile["phone"]?.toString() ?? _phone;
        _email = profile["email"]?.toString() ?? _email;
        _address1 = profile["house_name"]?.toString() ??
            profile["address"]?.toString() ??
            _address1;
        _memberId = profile["member_id"]?.toString() ?? _memberId;
        _mahalName = profile["mahal_name"]?.toString() ?? _mahalName;
      });
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPersonalDetailsScreen(
          name: _memberName,
          email: _email,
          phone: _phone,
          address1: _address1,
          address2: _address2,
          city: _city,
          state: _state,
          pincode: _pincode,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _memberName = updated['name'] ?? _memberName;
        _email = updated['email'] ?? _email;
        _phone = updated['phone'] ?? _phone;
        _address1 = updated['address1'] ?? _address1;
        _address2 = updated['address2'] ?? _address2;
        _city = updated['city'] ?? _city;
        _state = updated['state'] ?? _state;
        _pincode = updated['pincode'] ?? _pincode;
      });

      _apiService.updateMemberProfile(
        name: _memberName,
        email: _email,
        address: _address1,
        city: _city,
        state: _state,
        pincode: _pincode,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your details were updated.')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await AppBottomSheet.showConfirmation(
      context: context,
      title: 'Log out?',
      message: 'You will need your mobile number to sign in again.',
      confirmLabel: 'Log Out',
      confirmColor: AppColors.error,
      icon: Icons.logout_rounded,
    );
    if (confirmed == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _replayWelcome() async {
    await AppPrefs.resetOnboarding();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
  }

  String get _fullAddress {
    final parts = [
      _address1,
      if (_address2.isNotEmpty) _address2,
      _city,
      _state,
      _pincode,
    ].where((p) => p.trim().isNotEmpty);
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Profile',
      eyebrow: 'Your account',
      showBack: false,
      onRefresh: _loadProfile,
      actions: [
        AppHeaderIconButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit your details',
          onTap: _openEditProfile,
        ),
      ],
      headerChild: _identityBlock(),
      floatingChild: _detailsCard(),
      content: [
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'Payments'),
        _settingsCard([
          _SettingsItem(
            icon: Icons.sync_rounded,
            iconColor: AppColors.info,
            iconBackground: AppColors.infoBg,
            title: 'AutoPay',
            subtitle: 'UPI mandate for your monthly dues',
            onTap: () => Navigator.pushNamed(context, '/member/autopay-setup'),
          ),
          _SettingsItem(
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.primary,
            iconBackground: AppColors.primaryLight,
            title: 'Receipts',
            subtitle: 'Every payment you have made',
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/member/receipts'),
          ),
          _SettingsItem(
            icon: Icons.payments_outlined,
            iconColor: AppColors.warning,
            iconBackground: AppColors.warningBg,
            title: 'Pay dues',
            subtitle: 'Clear pending months',
            onTap: () => Navigator.pushNamed(context, '/member/pay'),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'App'),
        _settingsCard([
          _SettingsItem(
            icon: Icons.campaign_outlined,
            iconColor: AppColors.success,
            iconBackground: AppColors.successBg,
            title: 'Notices',
            subtitle: 'Announcements from the committee',
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/member/alerts'),
          ),
          _SettingsItem(
            icon: Icons.help_outline_rounded,
            iconColor: AppColors.textSecondary,
            iconBackground: AppColors.neutralBg,
            title: 'Help & support',
            subtitle: 'Contact your Mahal committee office',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Call the Mahal office for help with your dues.'),
              ),
            ),
          ),
          _SettingsItem(
            icon: Icons.slideshow_outlined,
            iconColor: AppColors.textSecondary,
            iconBackground: AppColors.neutralBg,
            title: 'Replay welcome',
            subtitle: 'Show the introduction again',
            onTap: _replayWelcome,
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        AppSecondaryButton(
          label: 'Log Out',
          icon: Icons.logout_rounded,
          color: AppColors.error,
          onPressed: _logout,
        ),
        const SizedBox(height: AppSpacing.ms),
        Center(
          child: Text(
            'MahalFlow · v1.0.0',
            style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 4),
    );
  }

  Widget _identityBlock() {
    final initial =
        _memberName.trim().isNotEmpty ? _memberName.trim()[0].toUpperCase() : 'M';

    return Row(
      children: [
        Container(
          width: 66,
          height: 66,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: Text(
            initial,
            style: AppTextStyles.display.copyWith(
              color: Colors.white,
              fontSize: 27,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _memberName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: Colors.white,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _phone,
                style: AppTextStyles.small.copyWith(
                  color: Colors.white.withValues(alpha: 0.74),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.ms,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.26),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 13, color: Colors.white),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Verified member',
                      style: AppTextStyles.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailsCard() {
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionLabel(
            'Membership',
            trailing: StatusPill(
              label: 'Active',
              foreground: AppColors.success,
              background: AppColors.successBg,
              icon: Icons.check_circle_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDetailRow(label: 'Member ID', value: _memberId, emphasize: true),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(label: 'Mahal', value: _mahalName),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(label: 'Email', value: _email),
          const Divider(height: 1, color: AppColors.border),
          AppDetailRow(label: 'Address', value: _fullAddress),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: 'Edit details',
            icon: Icons.edit_outlined,
            height: 46,
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
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            InkWell(
              onTap: items[i].onTap,
              borderRadius: BorderRadius.circular(
                i == 0 || i == items.length - 1 ? AppRadius.card : 0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md - 2,
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
                          Text(
                            items[i].title,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(items[i].subtitle, style: AppTextStyles.small),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ],
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
