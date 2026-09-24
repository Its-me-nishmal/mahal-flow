import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';

/// Committee screen to approve or reject members who self-registered.
class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _pending = [];
  bool _isLoading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await _apiService.getPendingMembers();
    if (!mounted) return;
    setState(() {
      _pending = list;
      _isLoading = false;
    });
  }

  Future<void> _act(String memberId, bool approve) async {
    setState(() => _busyId = memberId);
    final ok = approve
        ? await _apiService.approveMember(memberId)
        : await _apiService.rejectMember(memberId);
    if (!mounted) return;
    setState(() => _busyId = null);
    if (ok) {
      setState(() => _pending.removeWhere((m) => m['id'] == memberId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Member approved.' : 'Request removed.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Pending approvals',
      eyebrow: 'Committee',
      subtitle: 'New members waiting to join your Mahal.',
      onBack: () => Navigator.of(context).maybePop(),
      content: [
        const SizedBox(height: AppSpacing.md),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_pending.isEmpty)
          const EmptyStateView(
            icon: Icons.verified_user_outlined,
            title: 'No pending requests',
            description: 'Everyone who asked to join has been reviewed.',
          )
        else
          ..._pending.map(_row),
      ],
    );
  }

  Widget _row(dynamic m) {
    final id = m['id']?.toString() ?? '';
    final name = m['name']?.toString() ?? 'Unknown';
    final phone = m['phone']?.toString() ?? '';
    final busy = _busyId == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTextStyles.cardTitle),
            const SizedBox(height: 2),
            Text(phone, style: AppTextStyles.small),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    isLoading: busy,
                    onPressed: busy ? null : () => _act(id, true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Reject',
                    color: AppColors.error,
                    onPressed: busy ? null : () => _act(id, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
