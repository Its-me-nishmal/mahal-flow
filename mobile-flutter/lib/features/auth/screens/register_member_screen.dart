import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/phone_auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/l10n.dart';

/// Shown when an OTP-verified phone is not yet a member. The person confirms
/// their identity (Mahal ID + name); this creates a PENDING_APPROVAL member an
/// admin must approve before they can transact.
class RegisterMemberScreen extends StatefulWidget {
  /// The OTP-verified phone, E.164.
  final String phone;

  const RegisterMemberScreen({super.key, required this.phone});

  @override
  State<RegisterMemberScreen> createState() => _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends State<RegisterMemberScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _mahalController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _mahalFocus = FocusNode();

  bool _isSubmitting = false;
  String? _nameError;
  String? _mahalError;
  String? _submitError;

  @override
  void dispose() {
    _mahalController.dispose();
    _nameController.dispose();
    _mahalFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final mahalId = _mahalController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    setState(() {
      _nameError = name.isEmpty ? context.l10n.registerNameRequired : null;
      _mahalError =
          mahalId.isEmpty ? context.l10n.registerMahalIdRequired : null;
      _submitError = null;
    });
    if (_nameError != null || _mahalError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final res = await _apiService.registerSelf(
      phone: widget.phone,
      mahalId: mahalId,
      name: name,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res == null) {
      setState(() => _submitError = context.l10n.authServerUnreachable);
      return;
    }
    if (res['error'] != null) {
      setState(() => _mahalError = res['error'].toString());
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.pendingApproval,
      (route) => false,
      arguments: name,
    );
  }

  /// Leaving registration abandons this verified phone: sign it out of
  /// Firebase too, or the splash would keep resolving it on next launch.
  Future<void> _backToLogin() async {
    await PhoneAuthService.instance.signOut();
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isSubmitting) _backToLogin();
      },
      child: AppPageScaffold(
        title: l10n.registerTitle,
        eyebrow: 'MahalFlow',
        subtitle: l10n.registerSubtitle,
        onBack: _isSubmitting ? null : _backToLogin,
        floatingChild: AppCard.floating(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionLabel(l10n.registerDetailsLabel),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _nameController,
                label: l10n.authFullName,
                hint: l10n.registerNameHint,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                enabled: !_isSubmitting,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                onSubmitted: (_) => _mahalFocus.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.ms),
              AppTextField(
                controller: _mahalController,
                focusNode: _mahalFocus,
                label: l10n.registerMahalIdLabel,
                hint: l10n.registerMahalIdHint,
                helperText: l10n.registerMahalIdHelper,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                enabled: !_isSubmitting,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-]')),
                  _UpperCaseFormatter(),
                ],
                errorText: _mahalError,
                onChanged: (_) {
                  if (_mahalError != null) setState(() => _mahalError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.ms),
              AppReadOnlyField(
                label: l10n.authMobileNumber,
                value: PhoneFormat.display(widget.phone),
                icon: Icons.phone_iphone_rounded,
                note: l10n.registerVerifiedByOtp,
              ),
              if (_submitError != null) ...[
                const SizedBox(height: AppSpacing.ms),
                AppNoticeCard(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.registerNotSent,
                  message: _submitError!,
                  color: context.colors.error,
                  background: context.colors.errorBg,
                ),
              ],
            ],
          ),
        ),
        content: [
          const SizedBox(height: AppSpacing.md),
          AppNoticeCard(
            icon: Icons.info_outline_rounded,
            title: l10n.registerNextTitle,
            message: l10n.registerNextBody,
            color: context.colors.info,
            background: context.colors.infoBg,
          ),
        ],
        bottomBar: AppBottomActionBar(
          children: [
            AppPrimaryButton(
              label: _isSubmitting
                  ? l10n.registerSubmitting
                  : l10n.registerRequestJoin,
              icon: Icons.how_to_reg_rounded,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: l10n.registerDifferentNumber,
              color: context.colors.textSecondary,
              onPressed: _isSubmitting ? null : _backToLogin,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
