import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../data/admin_context.dart';
import '../utils/admin_format.dart';

/// Committee screen to approve or reject members who self-registered.
class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _pending = [];
  bool _isLoading = true;
  ApiException? _error;

  /// Ids with a request in flight — per row, so two rows never share a
  /// spinner.
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await _api.getPendingMembersOrThrow();
      if (!mounted) return;
      setState(() {
        _pending =
            list.whereType<Map>().map(Map<String, dynamic>.from).toList();
        _isLoading = false;
      });
      AdminContext.pendingCount.value = _pending.length;
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(Map<String, dynamic> m) async {
    final id = AdminFormat.memberId(m);
    if (id.isEmpty || _busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      await _api.approveMemberOrThrow(id);
      if (!mounted) return;
      _removeRow(id);
      AdminContext.invalidateMembers();
      final approved = {...m, 'status': 'ACTIVE'};
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${m['name'] ?? 'Member'} approved.'),
          backgroundColor: context.colors.primary,
          action: SnackBarAction(
            label: 'View member',
            textColor: context.colors.onPrimary,
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRoutes.adminMemberDetails, arguments: approved),
          ),
        ),
      );
    } on ApiException catch (e) {
      _failed(id, "Couldn't approve. ${e.userMessage}");
    }
  }

  Future<void> _reject(Map<String, dynamic> m) async {
    final id = AdminFormat.memberId(m);
    if (id.isEmpty || _busy.contains(id)) return;
    final name = m['name']?.toString() ?? 'this person';
    final ok = await AppBottomSheet.showConfirmation(
      context: context,
      title: 'Reject this request?',
      message: '$name will not be added to the Mahal. They would need to '
          'register again to be reconsidered.',
      confirmLabel: 'Reject request',
      destructive: true,
    );
    if (ok != true || !mounted) return;

    setState(() => _busy.add(id));
    try {
      await _api.rejectMemberOrThrow(id);
      if (!mounted) return;
      _removeRow(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request from $name rejected.')),
      );
    } on ApiException catch (e) {
      _failed(id, "Couldn't reject. ${e.userMessage}");
    }
  }

  void _removeRow(String id) {
    setState(() {
      _busy.remove(id);
      _pending.removeWhere((p) => AdminFormat.memberId(p) == id);
    });
    AdminContext.pendingCount.value = _pending.length;
  }

  void _failed(String id, String message) {
    if (!mounted) return;
    setState(() => _busy.remove(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: context.colors.error),
    );
  }

  String get _subtitle {
    if (_isLoading || _error != null) {
      return 'New members waiting to join your Mahal.';
    }
    if (_pending.isEmpty) return 'Nobody is waiting right now.';
    final n = _pending.length;
    return n == 1
        ? '1 person is waiting to join.'
        : '$n people are waiting to join.';
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Pending approvals',
      eyebrow: 'Committee',
      subtitle: _subtitle,
      onBack: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          AppNav.adminHome(context);
        }
      },
      onRefresh: _load,
      content: [
        const SizedBox(height: AppSpacing.md),
        if (_isLoading)
          ShimmerLoading(
            semanticsLabel: 'Loading requests',
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  const ShimmerCardSkeleton(height: 132),
              ],
            ),
          )
        else if (_error != null)
          AppErrorStateView(
            title: "Couldn't load requests",
            description: _error!.userMessage,
            onRetry: () {
              setState(() => _isLoading = true);
              _load();
            },
          )
        else if (_pending.isEmpty)
          const EmptyStateView(
            icon: Icons.verified_user_outlined,
            title: 'No pending requests',
            description: 'Everyone who asked to join has been reviewed.',
          )
        else
          for (final m in _pending) _row(m),
      ],
    );
  }

  Widget _row(Map<String, dynamic> m) {
    final id = AdminFormat.memberId(m);
    final name = m['name']?.toString() ?? '—';
    final rawPhone = m['phone']?.toString() ?? '';
    final house = m['house_name']?.toString() ?? '';
    final requested = AppDate.relative(m['created_at'], fallback: '');
    final busy = _busy.contains(id);
    final disabled = busy || id.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(name: name, excludeFromSemantics: true),
                const SizedBox(width: AppSpacing.ms),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.cardTitle),
                      Text(
                        [
                          if (rawPhone.isNotEmpty)
                            PhoneFormat.display(rawPhone),
                          if (house.isNotEmpty) house,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.small,
                      ),
                      if (requested.isNotEmpty)
                        Text('Requested $requested',
                            style: context.text.caption),
                    ],
                  ),
                ),
              ],
            ),
            if (id.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This request has no member ID and cannot be actioned here.',
                style: context.text.caption.copyWith(color: context.colors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.ms),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Reject',
                    color: context.colors.error,
                    height: AppSizes.minTouch,
                    onPressed: disabled ? null : () => _reject(m),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    height: AppSizes.minTouch,
                    isLoading: busy,
                    onPressed: disabled ? null : () => _approve(m),
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
