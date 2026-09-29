import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/l10n.dart';
import '../data/admin_context.dart';

/// "Register a member" sheet, shared by the dashboard and the directory.
/// Resolves to the created member (as returned by POST /admin/members) or
/// null when dismissed. On failure the sheet stays open with the reason.
class AddMemberSheet {
  AddMemberSheet._();

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return AppBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: context.l10n.addMemberTitle,
      subtitle: context.l10n.addMemberSubtitle,
      icon: Icons.person_add_rounded,
      builder: (ctx, _) => const _AddMemberForm(),
    );
  }
}

class _AddMemberForm extends StatefulWidget {
  const _AddMemberForm();

  @override
  State<_AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends State<_AddMemberForm> {
  final ApiService _api = ApiService();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _house = TextEditingController();
  final _dues = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _duesError;
  String? _submitError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _house.dispose();
    _dues.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final dues = int.tryParse(_dues.text.trim());
    final l10n = context.l10n;
    setState(() {
      _nameError = name.isEmpty ? l10n.addMemberNameRequired : null;
      _phoneError = phone.isEmpty
          ? l10n.addMemberPhoneRequired
          : PhoneFormat.isValidIndianMobile(phone)
              ? null
              : l10n.adminPhoneInvalid;
      _duesError = (dues == null || dues < 1) ? l10n.addMemberDuesInvalid : null;
    });
    return _nameError == null && _phoneError == null && _duesError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() {
      _saving = true;
      _submitError = null;
    });
    try {
      final created = await _api.createMemberOrThrow(
        name: _name.text.trim(),
        phone: '+91${PhoneFormat.nationalDigits(_phone.text)}',
        houseName: _house.text.trim().isEmpty ? null : _house.text.trim(),
        duesAmount: double.parse(_dues.text.trim()),
      );
      AdminContext.invalidateMembers();
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = e.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _name,
          label: l10n.adminFullName,
          hint: l10n.addMemberNameHint,
          errorText: _nameError,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phone,
          label: l10n.adminMobileNumber,
          hint: '98471 11222',
          prefixText: '+91 ',
          keyboardType: TextInputType.phone,
          errorText: _phoneError,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
            LengthLimitingTextInputFormatter(12),
          ],
          onChanged: (_) {
            if (_phoneError != null) setState(() => _phoneError = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _house,
          label: l10n.addMemberHouseLabel,
          hint: l10n.addMemberHouseHint,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _dues,
          label: l10n.adminMonthlyDuesRupees,
          hint: l10n.addMemberDuesHint,
          prefixText: '₹ ',
          keyboardType: TextInputType.number,
          errorText: _duesError,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_duesError != null) setState(() => _duesError = null);
          },
        ),
        if (_submitError != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppNoticeCard(
            icon: Icons.error_outline_rounded,
            title: l10n.addMemberError,
            message: _submitError!,
            color: context.colors.error,
            background: context.colors.errorBg,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: l10n.addMemberSubmit,
          icon: Icons.check_rounded,
          isLoading: _saving,
          onPressed: _saving ? null : _submit,
        ),
      ],
    );
  }
}
