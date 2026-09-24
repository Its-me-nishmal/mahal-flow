import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/services/phone_auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';

/// Waiting room for a member whose registration is pending committee approval.
/// They can re-check (which re-resolves their phone) or sign out.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  final ApiService _apiService = ApiService();
  String _name = '';
  bool _argsLoaded = false;
  bool _isChecking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _name = (ModalRoute.of(context)?.settings.arguments as String?) ?? '';
      _argsLoaded = true;
    }
  }

  Future<void> _recheck() async {
    final phone = PhoneAuthService.instance.currentPhone;
    if (phone == null) {
      _goToLogin();
      return;
    }
    setState(() => _isChecking = true);
    final resolved = await _apiService.resolveLogin(phone);
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (resolved?['status'] == 'ALLOWED') {
      final isAdmin = resolved?['role'] == 'MAHAL_ADMIN';
      Navigator.of(context).pushNamedAndRemoveUntil(
        isAdmin ? '/admin/dashboard' : '/member/dashboard',
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still awaiting approval.')),
      );
    }
  }

  Future<void> _goToLogin() async {
    await PhoneAuthService.instance.signOut();
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Waiting for approval',
      eyebrow: 'MahalFlow',
      subtitle: _name.isEmpty ? 'Your request has been sent.' : 'Thanks, $_name.',
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top_rounded,
                size: 44, color: AppColors.warning),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The Mahal committee needs to approve your account before you can '
              'view dues and pay.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      content: const [
        SizedBox(height: AppSpacing.md),
        AppNoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Almost there',
          message:
              'You’ll get access as soon as the committee approves you. Tap '
              'refresh to check, or come back later.',
          color: AppColors.info,
          background: AppColors.infoBg,
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: _isChecking ? 'Checking…' : 'Check again',
            icon: Icons.refresh_rounded,
            isLoading: _isChecking,
            onPressed: _isChecking ? null : _recheck,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Sign out',
            color: AppColors.textSecondary,
            onPressed: _goToLogin,
          ),
        ],
      ),
    );
  }
}
