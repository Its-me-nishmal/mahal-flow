import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/l10n.dart';

/// Edits the signed-in member's contact details (PUT /members/profile/:id:
/// name, house_name, email, address2, city, state, pincode — all stored by
/// the server). Saving only closes (returning the saved values) once the
/// server accepted them; on failure the member stays here with their edits
/// intact and sees the server's reason (e.g. an invalid email or PIN code).
class EditPersonalDetailsScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String pincode;

  const EditPersonalDetailsScreen({
    super.key,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address1 = '',
    this.address2 = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
  });

  @override
  State<EditPersonalDetailsScreen> createState() =>
      _EditPersonalDetailsScreenState();
}

class _EditPersonalDetailsScreenState extends State<EditPersonalDetailsScreen> {
  final ApiService _api = ApiService();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _address1Controller;
  late final TextEditingController _address2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  String? _nameError;
  String? _emailError;
  String? _pincodeError;
  bool _saving = false;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name)
      ..addListener(_onChanged);
    _emailController = TextEditingController(text: widget.email)
      ..addListener(_onChanged);
    _address1Controller = TextEditingController(text: widget.address1)
      ..addListener(_onChanged);
    _address2Controller = TextEditingController(text: widget.address2)
      ..addListener(_onChanged);
    _cityController = TextEditingController(text: widget.city)
      ..addListener(_onChanged);
    _stateController = TextEditingController(text: widget.state)
      ..addListener(_onChanged);
    _pincodeController = TextEditingController(text: widget.pincode)
      ..addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _emailController,
      _address1Controller,
      _address2Controller,
      _cityController,
      _stateController,
      _pincodeController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _values => {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': widget.phone,
        'address1': _address1Controller.text.trim(),
        'address2': _address2Controller.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
      };

  bool get _isDirty {
    final v = _values;
    return v['name'] != widget.name.trim() ||
        v['email'] != widget.email.trim() ||
        v['address1'] != widget.address1.trim() ||
        v['address2'] != widget.address2.trim() ||
        v['city'] != widget.city.trim() ||
        v['state'] != widget.state.trim() ||
        v['pincode'] != widget.pincode.trim();
  }

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  Future<void> _saveChanges() async {
    if (_saving) return;
    _unfocus();
    final v = _values;
    final email = v['email']!;
    final pincode = v['pincode']!;

    final l10n = context.l10n;
    setState(() {
      _nameError = v['name']!.isEmpty ? l10n.editProfileNameRequired : null;
      // An empty email is allowed; a malformed one is not, because the
      // committee uses it to send receipts.
      _emailError = email.isNotEmpty && !_emailPattern.hasMatch(email)
          ? l10n.editProfileEmailInvalid
          : null;
      _pincodeError = pincode.isNotEmpty && pincode.length != 6
          ? l10n.editProfilePincodeInvalid
          : null;
    });
    if (_nameError != null || _emailError != null || _pincodeError != null) {
      return;
    }
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      // Empty strings are sent on purpose: they clear the optional fields.
      await _api.updateMemberProfileOrThrow(
        name: v['name']!,
        houseName: v['address1']!.isEmpty ? null : v['address1'],
        email: email,
        address2: v['address2'],
        city: v['city'],
        state: v['state'],
        pincode: pincode,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.pop(context, v);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      // A 400 carries the server's validation reason; show it verbatim.
      final reason = e.kind == ApiErrorKind.badRequest &&
              (e.serverMessage?.trim().isNotEmpty ?? false)
          ? e.serverMessage!.trim()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason == null
              ? l10n.editProfileSaveFailed
              : l10n.editProfileSaveRejected(reason)),
        ),
      );
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await AppBottomSheet.showConfirmation(
      context: context,
      title: context.l10n.editProfileDiscardTitle,
      message: context.l10n.editProfileDiscardMessage,
      confirmLabel: context.l10n.editProfileDiscard,
      cancelLabel: context.l10n.editProfileKeepEditing,
      destructive: true,
    );
    return discard == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_isDirty && !_saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _saving) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _unfocus,
        child: AppPageScaffold(
          title: l10n.editProfileTitle,
          eyebrow: l10n.commonProfile,
          subtitle: l10n.editProfileSubtitle,
          headerChild: Row(
            children: [
              AppAvatar(
                name: _nameController.text,
                size: 58,
                onHero: true,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Text(
                  l10n.editProfileManagedNote,
                  style: context.text.small.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                  ),
                ),
              ),
            ],
          ),
          floatingChild: AppCard.floating(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSectionLabel(l10n.editProfilePersonal),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _nameController,
                  label: l10n.authFullName,
                  icon: Icons.person_outline_rounded,
                  errorText: _nameError,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _emailController,
                  label: l10n.editProfileEmail,
                  hint: l10n.editProfileEmailHint,
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.md),
                AppReadOnlyField(
                  label: l10n.authMobileNumber,
                  value: widget.phone.isEmpty
                      ? '—'
                      : PhoneFormat.display(widget.phone),
                  icon: Icons.phone_iphone_rounded,
                  note: l10n.editProfileMobileNote,
                ),
              ],
            ),
          ),
          content: [
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSectionLabel(l10n.editProfileAddress),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _address1Controller,
                    label: l10n.editProfileHouse,
                    icon: Icons.home_outlined,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _address2Controller,
                    label: l10n.editProfileStreet,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _cityController,
                          label: l10n.editProfileCity,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.ms),
                      Expanded(
                        child: AppTextField(
                          controller: _stateController,
                          label: l10n.editProfileState,
                          enabled: !_saving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _pincodeController,
                    label: l10n.editProfilePincode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    errorText: _pincodeError,
                    enabled: !_saving,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveChanges(),
                  ),
                ],
              ),
            ),
          ],
          bottomBar: AppBottomActionBar(
            children: [
              AppPrimaryButton(
                label: _saving ? l10n.editProfileSaving : l10n.editProfileSave,
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _saving ? null : _saveChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
