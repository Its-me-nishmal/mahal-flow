import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/l10n.dart';

/// Broadcast composer (POST /admin/alerts). The admin picks the audience and
/// the notice type (ANNOUNCEMENT | DUES_REMINDER | EVENT | GENERAL —
/// PAYMENT_RECEIVED is issued by the server itself). Resolves to true only
/// when the server created the notice.
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
      title: context.l10n.broadcastTitle,
      subtitle: context.l10n.broadcastSubtitle,
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
  final String Function(AppLocalizations l10n) label;
  final bool warning;
  const _Audience(this.value, this.label, this.warning);
}

String _audienceAll(AppLocalizations l) => l.broadcastAudienceAll;
String _audienceOverdue(AppLocalizations l) => l.broadcastAudienceOverdue;
String _audienceFamilyHeads(AppLocalizations l) =>
    l.broadcastAudienceFamilyHeads;

class _BroadcastForm extends StatefulWidget {
  final int? totalMembers;
  final int? pendingMembers;
  const _BroadcastForm({this.totalMembers, this.pendingMembers});

  @override
  State<_BroadcastForm> createState() => _BroadcastFormState();
}

class _BroadcastFormState extends State<_BroadcastForm> {
  static const List<_Audience> _audiences = [
    _Audience('ALL', _audienceAll, false),
    _Audience('OVERDUE_ONLY', _audienceOverdue, true),
    _Audience('FAMILY_HEADS', _audienceFamilyHeads, false),
  ];

  String get _reminderTitle => context.l10n.broadcastReminderTitle;
  String get _reminderBody => context.l10n.broadcastReminderBody;

  final ApiService _api = ApiService();
  final _title = TextEditingController();
  final _message = TextEditingController();
  String _audience = 'ALL';
  String _severity = 'INFO';

  /// Follows the audience (OVERDUE_ONLY → DUES_REMINDER, else ANNOUNCEMENT,
  /// as the server defaults) until the admin picks one.
  String _type = 'ANNOUNCEMENT';
  bool _typePicked = false;
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
      if (!_typePicked) {
        _type = value == 'OVERDUE_ONLY' ? 'DUES_REMINDER' : 'ANNOUNCEMENT';
      }
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
    final l10n = context.l10n;
    switch (_audience) {
      case 'OVERDUE_ONLY':
        final n = widget.pendingMembers;
        return n == null
            ? l10n.broadcastRecipientsOverdueAll
            : l10n.broadcastRecipientsOverdueCount(n);
      case 'FAMILY_HEADS':
        return l10n.broadcastRecipientsFamilyHeads;
      default:
        final n = widget.totalMembers;
        return n == null
            ? l10n.broadcastRecipientsAll
            : l10n.broadcastRecipientsAllCount(n);
    }
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final title = _title.text.trim();
    final body = _message.text.trim();
    final l10n = context.l10n;
    setState(() {
      _titleError = title.isEmpty ? l10n.broadcastTitleRequired : null;
      _messageError = body.isEmpty ? l10n.broadcastMessageRequired : null;
    });
    if (_titleError != null || _messageError != null) return;

    final ok = await AppBottomSheet.showConfirmation(
      context: context,
      title: l10n.broadcastConfirmTitle,
      message: l10n.broadcastConfirmMessage(title, _recipientPhrase),
      confirmLabel: l10n.broadcastSendNotice,
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
        type: _type,
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.broadcastWhoHeading, style: context.text.label),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final a in _audiences) _audienceChip(a)],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.broadcastSendsTo(_recipientPhrase),
            style: context.text.caption),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _title,
          label: l10n.broadcastNoticeTitle,
          hint: l10n.broadcastTitleHint,
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
          label: l10n.broadcastMessage,
          hint: l10n.broadcastMessageHint,
          errorText: _messageError,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_messageError != null) setState(() => _messageError = null);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppDropdownField<String>(
          label: l10n.broadcastType,
          value: _type,
          items: [
            for (final (value, label) in [
              ('ANNOUNCEMENT', l10n.alertTypeAnnouncement),
              ('DUES_REMINDER', l10n.alertTypeDuesReminder),
              ('EVENT', l10n.alertTypeEvent),
              ('GENERAL', l10n.broadcastTypeGeneral),
            ])
              DropdownMenuItem(
                value: value,
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _type = v;
                _typePicked = true;
              });
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppDropdownField<String>(
          label: l10n.broadcastPriority,
          value: _severity,
          items: [
            for (final (value, label) in [
              ('INFO', l10n.broadcastPriorityInfo),
              ('WARNING', l10n.broadcastPriorityReminder),
              ('CRITICAL', l10n.broadcastPriorityCritical),
            ])
              DropdownMenuItem(
                value: value,
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _severity = v);
          },
        ),
        if (_submitError != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppNoticeCard(
            icon: Icons.error_outline_rounded,
            title: l10n.broadcastNotSent,
            message: _submitError!,
            color: context.colors.error,
            background: context.colors.errorBg,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: l10n.broadcastReviewSend,
          icon: Icons.send_rounded,
          isLoading: _sending,
          onPressed: _sending ? null : _send,
        ),
      ],
    );
  }

  Widget _audienceChip(_Audience a) {
    final selected = _audience == a.value;
    final label = a.label(context.l10n);
    final fg = selected
        ? (a.warning ? context.colors.warning : context.colors.primary)
        : context.colors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
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
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.buttonSmall.copyWith(color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
