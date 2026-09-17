import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';

class EditMemberDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const EditMemberDetailsScreen({super.key, required this.member});

  @override
  State<EditMemberDetailsScreen> createState() =>
      _EditMemberDetailsScreenState();
}

class _EditMemberDetailsScreenState extends State<EditMemberDetailsScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _houseController;
  late TextEditingController _amountController;
  String _selectedStatus = "ACTIVE";
  bool _isSaving = false;
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.member["name"]?.toString() ?? "");
    _phoneController =
        TextEditingController(text: widget.member["phone"]?.toString() ?? "");
    _houseController = TextEditingController(
        text: widget.member["house_name"]?.toString() ?? "");
    final rawAmount = widget.member["amount"]
            ?.toString()
            .replaceAll(RegExp(r'[^0-9]'), '') ??
        "500";
    _amountController =
        TextEditingController(text: rawAmount.isEmpty ? "500" : rawAmount);

    final rawStatus = widget.member["raw_status"]?.toString() ??
        widget.member["status"]?.toString() ??
        "ACTIVE";
    final upper = rawStatus.toUpperCase();
    if (upper.contains("GRACE") ||
        upper.contains("OVERDUE") ||
        upper.contains("PENDING")) {
      _selectedStatus = "GRACE_PERIOD";
    } else if (upper.contains("SUSPEND") || upper.contains("INACTIVE")) {
      _selectedStatus = "SUSPENDED";
    } else {
      _selectedStatus = "ACTIVE";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final house = _houseController.text.trim();
    final dues = double.tryParse(_amountController.text.trim()) ?? 500.0;
    final memberId = widget.member["id"]?.toString() ?? "";

    setState(() {
      _nameError = name.isEmpty ? 'A name is required' : null;
      _phoneError = phone.isEmpty ? 'A phone number is required' : null;
    });
    if (_nameError != null || _phoneError != null) return;

    setState(() => _isSaving = true);
    final success = await _apiService.updateMemberDetails(
      memberId: memberId,
      name: name,
      phone: phone,
      houseName: house,
      duesAmount: dues,
      status: _selectedStatus,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member details updated.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save the changes. Try again.")),
      );
    }
  }

  Future<void> _handleDeactivate() async {
    final memberId = widget.member["id"]?.toString() ?? "";
    setState(() => _isSaving = true);

    final success = await _apiService.updateMemberDetails(
      memberId: memberId,
      name: _nameController.text.trim(),
      status: "SUSPENDED",
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This member is now suspended.'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmSuspend() async {
    final confirmed = await AppBottomSheet.showConfirmation(
      context: context,
      title: 'Suspend this member?',
      message:
          'Dues collection for ${_nameController.text.trim()} will be put on '
          'hold until you make them active again.',
      confirmLabel: 'Suspend',
      confirmColor: AppColors.error,
      icon: Icons.person_off_rounded,
    );
    if (confirmed == true) _handleDeactivate();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Edit member',
      eyebrow: widget.member["name"]?.toString() ?? 'Member',
      subtitle: 'Changes take effect for the next dues cycle.',
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionLabel('Household'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _nameController,
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              errorText: _nameError,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _phoneController,
              label: 'Phone number',
              icon: Icons.phone_iphone_rounded,
              keyboardType: TextInputType.phone,
              errorText: _phoneError,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _houseController,
              label: 'House or family name',
              icon: Icons.home_outlined,
              textCapitalization: TextCapitalization.words,
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
              const AppSectionLabel('Membership'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _amountController,
                label: 'Monthly dues (₹)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                helper: 'Leave at 500 unless the committee agreed otherwise.',
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdownField<String>(
                label: 'Membership status',
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(
                      value: 'GRACE_PERIOD', child: Text('Grace period')),
                  DropdownMenuItem(
                      value: 'SUSPENDED', child: Text('Suspended')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppNoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Suspending is reversible',
          message:
              'A suspended household keeps its history and can be reactivated '
              'from this screen.',
          color: AppColors.info,
          background: AppColors.infoBg,
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: 'Save Changes',
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _handleSave,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Suspend Member',
            icon: Icons.person_off_outlined,
            color: AppColors.error,
            onPressed: _isSaving ? null : _confirmSuspend,
          ),
        ],
      ),
    );
  }
}
