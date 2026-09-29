import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/l10n.dart';
import '../data/admin_context.dart';
import '../utils/admin_format.dart';

/// Edits a member (PUT /members/profile/:id). Pops with the updated member map
/// when a save or a status change succeeded, so the caller can refresh.
class EditMemberDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const EditMemberDetailsScreen({super.key, required this.member});

  @override
  State<EditMemberDetailsScreen> createState() =>
      _EditMemberDetailsScreenState();
}

class _EditMemberDetailsScreenState extends State<EditMemberDetailsScreen> {
  final ApiService _api = ApiService();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _houseController;
  late final TextEditingController _emailController;
  late final TextEditingController _amountController;

  late String _initialName;
  late String _initialPhone;
  late String _initialHouse;
  late String _initialEmail;
  late String _initialAmount;
  late String _initialStatus;

  /// The status currently saved on the server.
  late String _savedStatus;
  String _selectedStatus = 'ACTIVE';

  bool _isSaving = false;
  int _statusFieldEpoch = 0;
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _amountError;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// The latest server-confirmed member, returned to the caller on pop.
  late Map<String, dynamic> _current = Map<String, dynamic>.from(widget.member);
  bool _changedOnServer = false;

  String get _memberId => AdminFormat.memberId(widget.member);

  static String _normalizeStatus(String? raw) {
    final upper = (raw ?? '').toUpperCase();
    if (upper.contains('GRACE') || upper.contains('OVERDUE')) {
      return 'GRACE_PERIOD';
    }
    if (upper.contains('SUSPEND') || upper.contains('INACTIVE')) {
      return 'SUSPENDED';
    }
    return 'ACTIVE';
  }

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _initialName = m['name']?.toString() ?? '';
    final phone = m['phone']?.toString() ?? '';
    _initialPhone = phone.isEmpty ? '' : PhoneFormat.nationalDigits(phone);
    _initialHouse = m['house_name']?.toString() ?? '';
    _initialEmail = m['email']?.toString() ?? '';
    final dues = AdminFormat.monthlyDues(m);
    _initialAmount = dues == null ? '' : dues.round().toString();
    _initialStatus = _normalizeStatus(m['status']?.toString());
    _savedStatus = _initialStatus;
    _selectedStatus = _initialStatus;

    _nameController = TextEditingController(text: _initialName);
    _phoneController = TextEditingController(text: _initialPhone);
    _houseController = TextEditingController(text: _initialHouse);
    _emailController = TextEditingController(text: _initialEmail);
    _amountController = TextEditingController(text: _initialAmount);
    for (final c in [
      _nameController,
      _phoneController,
      _houseController,
      _emailController,
      _amountController,
    ]) {
      c.addListener(_onEdited);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onEdited() => setState(() {});

  bool get _isDirty =>
      _nameController.text.trim() != _initialName.trim() ||
      _phoneController.text.replaceAll(' ', '') != _initialPhone ||
      _houseController.text.trim() != _initialHouse.trim() ||
      _emailController.text.trim() != _initialEmail.trim() ||
      _amountController.text.trim() != _initialAmount ||
      _selectedStatus != _savedStatus;

  bool _validate() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final amount = int.tryParse(_amountController.text.trim());
    final email = _emailController.text.trim();
    final l10n = context.l10n;
    setState(() {
      _nameError = name.isEmpty ? l10n.editMemberNameRequired : null;
      _phoneError = phone.isEmpty
          ? l10n.editMemberPhoneRequired
          : PhoneFormat.isValidIndianMobile(phone)
              ? null
              : l10n.adminPhoneInvalid;
      _emailError = email.isNotEmpty && !_emailPattern.hasMatch(email)
          ? l10n.editProfileEmailInvalid
          : null;
      _amountError =
          (amount == null || amount < 1) ? l10n.editMemberDuesInvalid : null;
    });
    return _nameError == null &&
        _phoneError == null &&
        _emailError == null &&
        _amountError == null;
  }

  void _showError(ApiException e, String Function(String reason) message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message(e.userMessage)),
        backgroundColor: context.colors.error,
      ),
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (_memberId.isEmpty) return;
    if (!_validate()) return;

    final name = _nameController.text.trim();
    final phone = '+91${PhoneFormat.nationalDigits(_phoneController.text)}';
    final house = _houseController.text.trim();
    final email = _emailController.text.trim();
    final emailChanged = email != _initialEmail.trim();
    final dues = double.parse(_amountController.text.trim());

    setState(() => _isSaving = true);
    try {
      await _api.updateMemberDetailsOrThrow(
        memberId: _memberId,
        name: name,
        phone: phone,
        houseName: house,
        email: emailChanged ? email : null,
        duesAmount: dues,
        status: _selectedStatus,
      );
      if (!mounted) return;
      _current = {
        ..._current,
        'name': name,
        'phone': phone,
        if (house.isNotEmpty) 'house_name': house,
        'email': email,
        'monthly_dues_custom_amount': dues,
        'status': _selectedStatus,
      };
      _changedOnServer = true;
      AdminContext.invalidateMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.editMemberUpdated),
          backgroundColor: context.colors.primary,
        ),
      );
      Navigator.of(context).pop(_current);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(e, context.l10n.editMemberSaveFailed);
    }
  }

  Future<bool> _confirmSuspend() async {
    final confirmed = await AppBottomSheet.showConfirmation(
      context: context,
      title: context.l10n.editMemberSuspendTitle,
      message:
          context.l10n.editMemberSuspendMessage(_nameController.text.trim()),
      confirmLabel: context.l10n.editMemberSuspend,
      icon: Icons.person_off_rounded,
      destructive: true,
    );
    return confirmed == true;
  }

  /// Suspend or reactivate straight away (status only).
  Future<void> _toggleSuspension() async {
    final suspending = _savedStatus != 'SUSPENDED';
    if (suspending) {
      if (!await _confirmSuspend() || !mounted) return;
    } else {
      final ok = await AppBottomSheet.showConfirmation(
        context: context,
        title: context.l10n.editMemberReactivateTitle,
        message: context.l10n
            .editMemberReactivateMessage(_nameController.text.trim()),
        confirmLabel: context.l10n.editMemberReactivate,
        icon: Icons.person_add_alt_1_rounded,
      );
      if (ok != true || !mounted) return;
    }

    final target = suspending ? 'SUSPENDED' : 'ACTIVE';
    setState(() => _isSaving = true);
    try {
      await _api.updateMemberDetailsOrThrow(
        memberId: _memberId,
        status: target,
      );
      if (!mounted) return;
      _current = {..._current, 'status': target};
      _changedOnServer = true;
      AdminContext.invalidateMembers();
      setState(() {
        _isSaving = false;
        _savedStatus = target;
        _selectedStatus = target;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(suspending
              ? context.l10n.editMemberNowSuspended
              : context.l10n.editMemberActiveAgain),
          backgroundColor: suspending ? context.colors.error : context.colors.primary,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(
          e,
          suspending
              ? context.l10n.editMemberSuspendFailed
              : context.l10n.editMemberReactivateFailed);
    }
  }

  Future<void> _onStatusChanged(String? value) async {
    if (value == null || value == _selectedStatus) return;
    if (value == 'SUSPENDED' && _savedStatus != 'SUSPENDED') {
      // Ask now, so the choice is deliberate; the change is saved with the
      // rest of the form.
      final ok = await _confirmSuspend();
      if (!mounted) return;
      if (!ok) {
        // The dropdown already shows the new value internally; remount it so
        // it snaps back to the saved choice.
        setState(() => _statusFieldEpoch++);
        return;
      }
    }
    setState(() => _selectedStatus = value);
  }

  Future<void> _handlePop() async {
    if (_isSaving) return;
    if (!_isDirty) {
      Navigator.of(context).pop(_changedOnServer ? _current : null);
      return;
    }
    final discard = await AppBottomSheet.showConfirmation(
      context: context,
      title: context.l10n.editMemberDiscardTitle,
      message: context.l10n.editMemberDiscardMessage,
      confirmLabel: context.l10n.editMemberDiscard,
      cancelLabel: context.l10n.editMemberKeepEditing,
      destructive: true,
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop(_changedOnServer ? _current : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suspended = _savedStatus == 'SUSPENDED';
    final l10n = context.l10n;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handlePop();
      },
      child: AppPageScaffold(
        title: l10n.adminEditMember,
        eyebrow: _initialName.isEmpty ? l10n.commonMember : _initialName,
        subtitle: l10n.editMemberSubtitle,
        onBack: _handlePop,
        floatingChild: AppCard.floating(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionLabel(l10n.editMemberHousehold),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _nameController,
                label: l10n.adminFullName,
                icon: Icons.person_outline_rounded,
                errorText: _nameError,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phoneController,
                label: l10n.adminMobileNumber,
                icon: Icons.phone_iphone_rounded,
                prefixText: '+91 ',
                keyboardType: TextInputType.phone,
                errorText: _phoneError,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _houseController,
                label: l10n.editMemberHouseLabel,
                icon: Icons.home_outlined,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _emailController,
                label: l10n.editProfileEmail,
                hint: l10n.editProfileEmailHint,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
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
                AppSectionLabel(l10n.editMemberMembership),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _amountController,
                  label: l10n.adminMonthlyDuesRupees,
                  prefixText: '₹ ',
                  keyboardType: TextInputType.number,
                  errorText: _amountError,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  helper: l10n.editMemberDuesHelper,
                  onChanged: (_) {
                    if (_amountError != null) {
                      setState(() => _amountError = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                KeyedSubtree(
                  key: ValueKey(_statusFieldEpoch),
                  child: AppDropdownField<String>(
                    label: l10n.editMemberStatusLabel,
                    value: _selectedStatus,
                    items: [
                      for (final (value, label) in [
                        ('ACTIVE', l10n.adminFormatStatusActive),
                        ('GRACE_PERIOD', l10n.adminFormatStatusGrace),
                        ('SUSPENDED', l10n.adminFormatStatusSuspended),
                      ])
                        DropdownMenuItem(
                          value: value,
                          child: Text(label,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: _isSaving ? (_) {} : _onStatusChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppNoticeCard(
            icon: Icons.info_outline_rounded,
            title: l10n.editMemberReversibleTitle,
            message: l10n.editMemberReversibleBody,
            color: context.colors.info,
            background: context.colors.infoBg,
          ),
        ],
        bottomBar: AppBottomActionBar(
          children: [
            AppPrimaryButton(
              label: l10n.editMemberSaveChanges,
              icon: Icons.check_rounded,
              isLoading: _isSaving,
              onPressed: (_isSaving || !_isDirty) ? null : _handleSave,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: suspended
                  ? l10n.editMemberReactivateMember
                  : l10n.editMemberSuspendMember,
              icon: suspended
                  ? Icons.person_add_alt_1_outlined
                  : Icons.person_off_outlined,
              color: suspended ? context.colors.primary : context.colors.error,
              onPressed: _isSaving ? null : _toggleSuspension,
            ),
          ],
        ),
      ),
    );
  }
}
