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
import '../../../l10n/l10n.dart';
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
      final index = _removeRow(id);
      AdminContext.invalidateMembers();
      _showUndo(
        m,
        index,
        context.l10n.approvalsApproved(
            m['name']?.toString() ?? context.l10n.commonMember),
        background: context.colors.primary,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _failed(id, context.l10n.approvalsApproveFailed(e.userMessage));
    }
  }

  Future<void> _reject(Map<String, dynamic> m) async {
    final id = AdminFormat.memberId(m);
    if (id.isEmpty || _busy.contains(id)) return;
    final name = m['name']?.toString() ?? context.l10n.approvalsThisPerson;
    final ok = await AppBottomSheet.showConfirmation(
      context: context,
      title: context.l10n.approvalsRejectTitle,
      message: context.l10n.approvalsRejectMessage(name),
      confirmLabel: context.l10n.approvalsRejectRequest,
      destructive: true,
    );
    if (ok != true || !mounted) return;

    setState(() => _busy.add(id));
    try {
      await _api.rejectMemberOrThrow(id);
      if (!mounted) return;
      final index = _removeRow(id);
      _showUndo(m, index, context.l10n.approvalsRejected(name));
    } on ApiException catch (e) {
      if (!mounted) return;
      _failed(id, context.l10n.approvalsRejectFailed(e.userMessage));
    }
  }

  /// Removes the row and returns where it was, so an undo can put it back.
  int _removeRow(String id) {
    final index = _pending.indexWhere((p) => AdminFormat.memberId(p) == id);
    setState(() {
      _busy.remove(id);
      _pending.removeWhere((p) => AdminFormat.memberId(p) == id);
    });
    AdminContext.pendingCount.value = _pending.length;
    return index;
  }

  /// Snackbar after an approve or reject, with Undo. The server allows the
  /// revert for 10 minutes and only while the member has made no payment.
  void _showUndo(
    Map<String, dynamic> m,
    int index,
    String message, {
    Color? background,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: context.l10n.commonUndo,
          textColor: background == null ? null : context.colors.onPrimary,
          onPressed: () => _undo(m, index),
        ),
      ),
    );
  }

  /// POST /admin/members/:id/revert-approval → back to PENDING_APPROVAL.
  Future<void> _undo(Map<String, dynamic> m, int index) async {
    final id = AdminFormat.memberId(m);
    if (id.isEmpty || _busy.contains(id)) return;
    try {
      await _api.revertApprovalOrThrow(id);
      if (!mounted) return;
      AdminContext.invalidateMembers();
      setState(() {
        if (!_pending.any((p) => AdminFormat.memberId(p) == id)) {
          final at = (index < 0 || index > _pending.length)
              ? _pending.length
              : index;
          _pending.insert(at, {...m, 'status': 'PENDING_APPROVAL'});
        }
      });
      AdminContext.pendingCount.value = _pending.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.approvalsUndone(
              m['name']?.toString() ?? context.l10n.commonMember)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409: too late, already paid, or not decided here — the server says
      // which.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.approvalsUndoFailed(e.userMessage)),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  void _failed(String id, String message) {
    if (!mounted) return;
    setState(() => _busy.remove(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: context.colors.error),
    );
  }

  String get _subtitle {
    final l10n = context.l10n;
    if (_isLoading || _error != null) return l10n.approvalsSubtitleDefault;
    if (_pending.isEmpty) return l10n.approvalsSubtitleNone;
    return l10n.approvalsSubtitleCount(_pending.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPageScaffold(
      title: l10n.adminPendingApprovals,
      eyebrow: l10n.adminCommitteeEyebrow,
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
            semanticsLabel: l10n.approvalsLoading,
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  const ShimmerCardSkeleton(height: 132),
              ],
            ),
          )
        else if (_error != null)
          AppErrorStateView(
            title: l10n.approvalsLoadError,
            description: _error!.userMessage,
            onRetry: () {
              setState(() => _isLoading = true);
              _load();
            },
          )
        else if (_pending.isEmpty)
          EmptyStateView(
            icon: Icons.verified_user_outlined,
            title: l10n.approvalsEmptyTitle,
            description: l10n.approvalsEmptyBody,
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
                        Text(context.l10n.approvalsRequested(requested),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.caption),
                    ],
                  ),
                ),
              ],
            ),
            if (id.isEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.approvalsNoId,
                style: context.text.caption.copyWith(color: context.colors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.ms),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: context.l10n.approvalsReject,
                    color: context.colors.error,
                    height: AppSizes.minTouch,
                    onPressed: disabled ? null : () => _reject(m),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppPrimaryButton(
                    label: context.l10n.approvalsApprove,
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
