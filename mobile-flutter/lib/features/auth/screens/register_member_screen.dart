import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';

/// Shown when an OTP-verified phone is not yet a member. The person confirms
/// their identity (Mahal ID + name); this creates a PENDING_APPROVAL member an
/// admin must approve before they can transact.
class RegisterMemberScreen extends StatefulWidget {
  const RegisterMemberScreen({super.key});

  @override
  State<RegisterMemberScreen> createState() => _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends State<RegisterMemberScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _mahalController =
      TextEditingController(text: ApiService.defaultTenant);
  final TextEditingController _nameController = TextEditingController();

  String _phone = '';
  bool _argsLoaded = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _phone = (ModalRoute.of(context)?.settings.arguments as String?) ?? '';
      _argsLoaded = true;
    }
  }

  @override
  void dispose() {
    _mahalController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final mahalId = _mahalController.text.trim();
    final name = _nameController.text.trim();
    if (name.isEmpty || mahalId.isEmpty) {
      setState(() => _error = 'Enter your name and Mahal ID');
      return;
    }
    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    final res = await _apiService.registerSelf(
      phone: _phone,
      mahalId: mahalId,
      name: name,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res == null || res['error'] != null) {
      setState(() => _error = res?['error']?.toString() ??
          'Could not register. Check the Mahal ID and try again.');
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/pending-approval',
      (route) => false,
      arguments: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Confirm your identity',
      eyebrow: 'MahalFlow',
      subtitle: 'This number isn’t registered yet. Tell us who you are and '
          'the committee will approve you.',
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionLabel('Your details'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _nameController,
              label: 'Full name',
              hint: 'As known to the committee',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _mahalController,
              label: 'Mahal ID',
              hint: 'e.g. MH_001_CALICUT',
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Phone: $_phone', style: AppTextStyles.small),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: AppTextStyles.small.copyWith(color: AppColors.error)),
            ],
          ],
        ),
      ),
      content: const [
        SizedBox(height: AppSpacing.md),
        AppNoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'What happens next',
          message:
              'Your request goes to the Mahal committee. Once they approve you, '
              'sign in again with this number to see your dues and receipts.',
          color: AppColors.info,
          background: AppColors.infoBg,
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: _isSubmitting ? 'Submitting…' : 'Request to join',
            icon: Icons.how_to_reg_rounded,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Back',
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false),
          ),
        ],
      ),
    );
  }
}
