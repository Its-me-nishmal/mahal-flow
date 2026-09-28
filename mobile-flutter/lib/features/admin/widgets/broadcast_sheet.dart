import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';

/// Broadcast composer (POST /admin/alerts). Resolves to true only when the
/// server created the notice.
class BroadcastSheet {
  BroadcastSheet._();

  /// [totalMembers] / [pendingMembers] come from the dashboard API and are
  /// only used to tell the admin how many households will get the notice;
  /// pass null when unknown.
  static Future<bool?> show(
    BuildContext context, {
    int? totalMembers,
    int? pendingMembers,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      title: 'Broadcast a notice',
      subtitle: 'Goes to member phones as an in-app notice',
      icon: Icons.campaign_rounded,
      builder: (ctx, _) => _BroadcastForm(
        totalMembers: totalMembers,
        pendingMembers: pendingMembers,
      ),
    );
  }
}

class _Audience {
  final String value;
  final String label;
  final bool warning;
  const _Audience(this.value, this.label, this.warning);
}

class _BroadcastForm extends StatefulWidget {
  final int? totalMembers;
  final int? pendingMembers;
  const _BroadcastForm({this.totalMembers, this.pendingMembers});

  @override
  State<_BroadcastForm> createState() => _BroadcastFormState();
}

class _BroadcastFormState extends State<_BroadcastForm> {
  static const List<_Audience> _audiences = [
    _Audience('ALL', 'All members', false),
    _Audience('OVERDUE_ONLY', 'Pending dues', true),
    _Audience('FAMILY_HEADS', 'Family heads', false),
  ];

  static const String _reminderTitle = 'Monthly dues reminder';
  static const String _reminderBody =
      'Respected member, our records show pending dues for your household. '
      'You can pay in the MahalFlow app.';

  final ApiService _api = ApiService();
  final _title = TextEditingController();
  final _message = TextEditingController();
  String _audience = 'ALL';
  String _severity = 'INFO';
  bool _sending = false;
  String? _titleError;
  String? _messageError;
  String? _submitError;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  void _selectAudience(String value) {
    setState(() {
      _audience = value;
      if (value == 'OVERDUE_ONLY') {
        _severity = 'WARNING';
        // Suggest reminder copy only into empty fields — never overwrite
        // what the admin already typed.
        if (_title.text.trim().isEmpty) _title.text = _reminderTitle;
        if (_message.text.trim().isEmpty) _message.text = _reminderBody;
      } else {
        if (_severity == 'WARNING') _severity = 'INFO';
        if (_title.text == _reminderTitle) _title.clear();
        if (_message.text == _reminderBody) _message.clear();
      }
    });
  }

  String get _recipientPhrase {
    switch (_audience) {
      case 'OVERDUE_ONLY':
        final n = widget.pendingMembers;
        return n == null
            ? 'every household with pending dues'
            : '$n ${n == 1 ? 'household' : 'households'} with pending dues';
      case 'FAMILY_HEADS':
        return 'every family head';
      default:
        final n = widget.totalMembers;
        return n == null
            ? 'every member'
            : 'all $n ${n == 1 ? 'household' : 'households'}';
    }
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final title = _title.text.trim();
    final body = _message.text.trim();
    setState(() {
      _titleError = title.isEmpty ? 'Add a title' : null;
      _messageError = body.isEmpty ? 'Write the message' : null;
    });
    if (_titleError != null || _messageError != null) return;

    final ok = await AppBottomSheet.showConfirmation(
      context: context,
      title: 'Send this notice?',
      message: '"$title" goes to $_recipientPhrase as an in-app notice and a '
          'push notification. It cannot be unsent.',
      confirmLabel: 'Send notice',
      icon: Icons.send_rounded,
    );
    if (ok != true || !mounted) return;

    setState(() {
      _sending = true;
      _submitError = null;
    });
    try {
      await _api.createAlertOrThrow(
        title: title,
        description: body,
        severity: _severity,
        audience: _audience,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _submitError = e.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('WHO SHOULD GET THIS', style: context.text.label),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final a in _audiences) _audienceChip(a)],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Sends to $_recipientPhrase.', style: context.text.caption),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _title,
          label: 'Notice title',
          hint: 'e.g. Friday prayer timing change',
          errorText: _titleError,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _message,
          label: 'Message',
          hint: 'Write the full announcement…',
          errorText: _messageError,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_messageError != null) setState(() => _messageError = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppDropdownField<String>(
          label: 'Priority',
          value: _severity,
          items: const [
            DropdownMenuItem(value: 'INFO', child: Text('Informational')),
            DropdownMenuItem(value: 'WARNING', child: Text('Dues reminder')),
            DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _severity = v);
          },
        ),
        if (_submitError != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppNoticeCard(
            icon: Icons.error_outline_rounded,
            title: 'Notice not sent',
            message: _submitError!,
            color: context.colors.error,
            background: context.colors.errorBg,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: 'Review & send',
          icon: Icons.send_rounded,
          isLoading: _sending,
          onPressed: _sending ? null : _send,
        ),
      ],
    );
  }

  Widget _audienceChip(_Audience a) {
    final selected = _audience == a.value;
    final fg = selected
        ? (a.warning ? context.colors.warning : context.colors.primary)
        : context.colors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: a.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: _sending ? null : () => _selectAudience(a.value),
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? (a.warning ? context.colors.warningBg : context.colors.primaryLight)
                : context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected
                  ? (a.warning ? context.colors.warning : context.colors.primary)
                  : context.colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 16, color: fg),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(a.label,
                  style: context.text.buttonSmall.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
