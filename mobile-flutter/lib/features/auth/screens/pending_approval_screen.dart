import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/phone_auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../l10n/l10n.dart';
import '../auth_flow.dart';

/// Waiting room for a member whose registration is pending committee approval
/// — or, with [rejected], the notice that the committee declined it (the
/// server gives a rejected phone no session). Either way they can re-check
/// (button or pull-to-refresh, which re-resolves their phone; a rejection
/// the committee undid shows up as pending again) or sign out.
class PendingApprovalScreen extends StatefulWidget {
  final String? name;
  final bool rejected;

  const PendingApprovalScreen({super.key, this.name, this.rejected = false});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isChecking = false;

  Future<void> _recheck() async {
    if (_isChecking) return;
    final phone = PhoneAuthService.instance.currentPhone;
    if (phone == null) {
      _goToLogin();
      return;
    }
    setState(() => _isChecking = true);
    final result = await AuthFlow.resolve(phone);
    if (!mounted) return;
    setState(() => _isChecking = false);

    switch (result.status) {
      case ResolveStatus.pending when !widget.rejected:
        _snack(context.l10n.pendingApprovalStillWaiting);
      case ResolveStatus.rejected when widget.rejected:
        _snack(context.l10n.registrationRejectedStill);
      case ResolveStatus.networkError:
        _snack(context.l10n.authServerUnreachable);
      case ResolveStatus.signedOut:
        _goToLogin();
      case ResolveStatus.allowed:
      case ResolveStatus.pending:
      case ResolveStatus.rejected:
      case ResolveStatus.unregistered:
        // Approved → dashboard (AuthFlow records the role); declined or
        // undone → the matching screen; removed → back to registration.
        AuthFlow.route(Navigator.of(context), result);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _goToLogin() async {
    await PhoneAuthService.instance.signOut();
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = widget.name?.trim() ?? '';
    final rejected = widget.rejected;
    return AppPageScaffold(
      title: rejected ? l10n.registrationRejectedTitle : l10n.pendingApprovalTitle,
      eyebrow: 'MahalFlow',
      subtitle: rejected
          ? l10n.registrationRejectedSubtitle
          : name.isEmpty
              ? l10n.pendingApprovalRequestSent
              : l10n.pendingApprovalThanks(name),
      showBack: false,
      onRefresh: _recheck,
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                  rejected
                      ? Icons.block_rounded
                      : Icons.hourglass_top_rounded,
                  size: 44,
                  color: rejected
                      ? context.colors.error
                      : context.colors.warning),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              rejected ? l10n.registrationRejectedBody : l10n.pendingApprovalBody,
              textAlign: TextAlign.center,
              style: context.text.body
                  .copyWith(color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        AppNoticeCard(
          icon: Icons.info_outline_rounded,
          title: rejected
              ? l10n.registrationRejectedNoticeTitle
              : l10n.pendingApprovalNoticeTitle,
          message: rejected
              ? l10n.registrationRejectedNoticeBody
              : l10n.pendingApprovalNoticeBody,
          color: context.colors.info,
          background: context.colors.infoBg,
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: _isChecking
                ? l10n.pendingApprovalChecking
                : l10n.pendingApprovalCheckAgain,
            icon: Icons.refresh_rounded,
            isLoading: _isChecking,
            onPressed: _isChecking ? null : _recheck,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: l10n.authSignOut,
            color: context.colors.textSecondary,
            onPressed: _isChecking ? null : _goToLogin,
          ),
        ],
      ),
    );
  }
}
