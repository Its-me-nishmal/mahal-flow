import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';

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
    this.name = 'Muhammed Ameen',
    this.email = 'muhammed@example.com',
    this.phone = '+91 98765 43210',
    this.address1 = '123, Palm Grove',
    this.address2 = '',
    this.city = 'Kochi',
    this.state = 'Kerala',
    this.pincode = '682001',
  });

  @override
  State<EditPersonalDetailsScreen> createState() =>
      _EditPersonalDetailsScreenState();
}

class _EditPersonalDetailsScreenState extends State<EditPersonalDetailsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  String? _nameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name)
      ..addListener(() => setState(() {}));
    _emailController = TextEditingController(text: widget.email);
    _address1Controller = TextEditingController(text: widget.address1);
    _address2Controller = TextEditingController(text: widget.address2);
    _cityController = TextEditingController(text: widget.city);
    _stateController = TextEditingController(text: widget.state);
    _pincodeController = TextEditingController(text: widget.pincode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedName = _nameController.text.trim();
    final email = _emailController.text.trim();

    setState(() {
      _nameError = updatedName.isEmpty ? 'Your name cannot be empty' : null;
      // An empty email is allowed; a malformed one is not, because the
      // committee uses it to send receipts.
      _emailError = email.isNotEmpty && !email.contains('@')
          ? 'That does not look like an email address'
          : null;
    });

    if (_nameError != null || _emailError != null) return;

    Navigator.pop(context, {
      'name': updatedName,
      'email': email,
      'phone': widget.phone,
      'address1': _address1Controller.text.trim(),
      'address2': _address2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final initial = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : 'M';

    return AppPageScaffold(
      title: 'Edit details',
      eyebrow: 'Profile',
      subtitle: 'Keep your contact details current so receipts reach you.',
      headerChild: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Text(
              initial,
              style: AppTextStyles.display.copyWith(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Text(
              'Your mobile number and member ID are managed by the committee.',
              style: AppTextStyles.small.copyWith(
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
            const AppSectionLabel('Personal'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _nameController,
              label: 'Full name',
              icon: Icons.person_outline_rounded,
              errorText: _nameError,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
            ),
            const SizedBox(height: AppSpacing.md),
            AppReadOnlyField(
              label: 'Mobile number',
              value: widget.phone,
              icon: Icons.phone_iphone_rounded,
              note: 'Contact the Mahal office to change this.',
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
              const AppSectionLabel('Address'),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _address1Controller,
                label: 'House name or number',
                icon: Icons.home_outlined,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _address2Controller,
                label: 'Street or landmark (optional)',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _cityController,
                      label: 'City',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.ms),
                  Expanded(
                    child: AppTextField(
                      controller: _stateController,
                      label: 'State',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _pincodeController,
                label: 'PIN code',
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: 'Save Changes',
            icon: Icons.check_rounded,
            onPressed: _saveChanges,
          ),
        ],
      ),
    );
  }
}
