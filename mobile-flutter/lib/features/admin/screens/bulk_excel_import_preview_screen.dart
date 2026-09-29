import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../l10n/l10n.dart';
import '../data/admin_context.dart';
import 'bulk_excel_import_step1_screen.dart';

/// Review (step 3) and result (step 4) of a spreadsheet import. Everything
/// shown comes from the server: the preview from
/// POST /admin/excel/upload-preview, the result from
/// POST /admin/excel/commit-import.
class BulkExcelImportPreviewScreen extends StatefulWidget {
  /// Optional; otherwise read from the route arguments.
  final ImportPreviewArgs? args;

  const BulkExcelImportPreviewScreen({super.key, this.args});

  @override
  State<BulkExcelImportPreviewScreen> createState() =>
      _BulkExcelImportPreviewScreenState();
}

class _BulkExcelImportPreviewScreenState
    extends State<BulkExcelImportPreviewScreen> {
  final ApiService _api = ApiService();
  ImportPreviewArgs? _args;
  bool _committing = false;
  String? _commitError;
  Map<String, dynamic>? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args != null) return;
    final a = widget.args ?? ModalRoute.of(context)?.settings.arguments;
    if (a is ImportPreviewArgs) _args = a;
  }

  Map<String, dynamic> get _preview => _args?.preview ?? const {};

  static int? _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}');

  int? get _total => _int(_preview['total_rows']);
  int? get _valid => _int(_preview['valid_rows']);
  int? get _duplicate => _int(_preview['duplicate_rows']);
  int? get _invalid {
    final explicit = _int(_preview['invalid_rows']);
    if (explicit != null) return explicit;
    final t = _total, v = _valid, d = _duplicate;
    if (t == null || v == null) return null;
    final rest = t - v - (d ?? 0);
    return rest < 0 ? 0 : rest;
  }

  List<Map<String, dynamic>> get _rows {
    final raw = _preview['preview_rows'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  /// The server's id for the parsed batch; commit sends it back.
  String get _batchId =>
      (_preview['batch_id'] ?? _preview['upload_id'] ?? '').toString();

  String get _fileName {
    final server = _preview['filename']?.toString() ?? '';
    return server.isNotEmpty ? server : (_args?.fileName ?? '—');
  }

  Future<void> _commit() async {
    final valid = _valid ?? 0;
    final ok = await AppBottomSheet.showConfirmation(
      context: context,
      title: context.l10n.importConfirmTitle(valid),
      message: context.l10n.importConfirmMessage,
      confirmLabel: context.l10n.importConfirm,
      icon: Icons.group_add_rounded,
    );
    if (ok != true || !mounted) return;

    if (_batchId.isEmpty) {
      setState(() => _commitError = context.l10n.importNoBatch);
      return;
    }
    setState(() {
      _committing = true;
      _commitError = null;
    });
    try {
      final res = await _api.commitExcelImportOrThrow(batchId: _batchId);
      if (!mounted) return;
      final status = (res['status'] ?? '').toString().toUpperCase();
      if (status != 'COMPLETED' && status != 'ALREADY_COMMITTED') {
        setState(() {
          _committing = false;
          _commitError = context.l10n.importServerStatus('${res['status']}');
        });
        return;
      }
      AdminContext.invalidateMembers();
      setState(() {
        _committing = false;
        _result = res;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _committing = false;
        _commitError = e.userMessage;
      });
    }
  }

  void _finish() {
    AppNav.switchAdminTab(context, AppRoutes.adminMembers);
  }

  @override
  Widget build(BuildContext context) {
    if (_args == null) {
      return AppPageScaffold(
        title: context.l10n.importCheckRows,
        eyebrow: context.l10n.importEyebrow,
        content: [
          const SizedBox(height: AppSpacing.lg),
          EmptyStateView(
            icon: Icons.upload_file_outlined,
            title: context.l10n.importNothingToReview,
            description: context.l10n.importNothingToReviewDesc,
            actionLabel: context.l10n.importChooseFile,
            onAction: () => Navigator.of(context)
                .pushReplacementNamed(AppRoutes.adminImportStep1),
          ),
        ],
      );
    }
    return _result == null ? _reviewPage() : _donePage();
  }

  // -------------------------------------------------------------------------
  // Step 3: review
  // -------------------------------------------------------------------------

  Widget _reviewPage() {
    final rows = _rows;
    final valid = _valid ?? 0;
    final skipped = (_invalid ?? 0) + (_duplicate ?? 0);
    final l10n = context.l10n;

    return PopScope(
      canPop: !_committing,
      child: AppPageScaffold(
        title: l10n.importCheckRows,
        eyebrow: l10n.importStepOf(3, kImportStepCount),
        subtitle: l10n.importOnlyValid,
        floatingChild: AppCard.floating(
          child: Column(
            children: [
              AppStepIndicator(steps: importSteps(context), currentIndex: 2),
              const AppCardDivider(spacing: AppSpacing.md),
              Text(_fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.small),
              const SizedBox(height: AppSpacing.ms),
              Row(
                children: [
                  _stat(l10n.importStatTotal, _total,
                      context.colors.textPrimary),
                  _stat(l10n.importStatValid, _valid, context.colors.success),
                  _stat(l10n.importStatInvalid, _invalid, context.colors.error),
                  _stat(l10n.importStatDuplicate, _duplicate,
                      context.colors.warning),
                ],
              ),
            ],
          ),
        ),
        content: [
          const SizedBox(height: AppSpacing.md),
          if (skipped > 0) ...[
            AppNoticeCard(
              icon: Icons.report_problem_outlined,
              title: l10n.importRowsSkipped(skipped),
              message: l10n.importFixRows,
              color: context.colors.warning,
              background: context.colors.warningBg,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_commitError != null) ...[
            AppNoticeCard(
              icon: Icons.error_outline_rounded,
              title: l10n.importNotCompleted,
              message: _commitError!,
              color: context.colors.error,
              background: context.colors.errorBg,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppSectionHeader(
            title: rows.isEmpty
                ? l10n.importRowsInFile
                : (_total != null && _total! > rows.length)
                    ? l10n.importSample(rows.length, _total!)
                    : l10n.importRowsInFile,
          ),
          if (rows.isEmpty)
            AppCard(
              child: EmptyStateView(
                icon: Icons.table_rows_outlined,
                title: l10n.importNoPreview,
                description: l10n.importNoPreviewDesc,
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: context.colors.border),
                    _row(rows[i]),
                  ],
                ],
              ),
            ),
        ],
        bottomBar: AppBottomActionBar(
          children: [
            AppPrimaryButton(
              label: valid == 0
                  ? l10n.importNoValidRows
                  : l10n.importButton(valid),
              icon: Icons.check_rounded,
              isLoading: _committing,
              onPressed: (valid == 0 || _committing) ? null : _commit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: l10n.importChooseAnother,
              color: context.colors.textSecondary,
              onPressed:
                  _committing ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int? value, Color color) {
    return Expanded(
      child: Semantics(
        label: context.l10n.importStatSemantics(
            label, value == null ? context.l10n.importStatUnknown : '$value'),
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              value == null ? '—' : '$value',
              style: context.text.statValue.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.xs / 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.text.caption),
          ],
        ),
      ),
    );
  }

  Widget _row(Map<String, dynamic> row) {
    final status = (row['status'] ?? '').toString().toUpperCase();
    final rawErrors = row['errors'];
    final errors = rawErrors is List
        ? rawErrors
            .map((e) => '$e'.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    if (errors.isEmpty) {
      final single =
          (row['error'] ?? row['reason'] ?? row['message'])?.toString() ?? '';
      if (single.trim().isNotEmpty) errors.add(single.trim());
    }
    final rowNumber = _int(row['row']);
    final name = row['name']?.toString() ?? '—';
    final phone = row['phone']?.toString() ?? '';
    final code = (row['member_code'] ?? row['code'])?.toString() ?? '';
    final house = (row['house_name'] ?? row['house'])?.toString() ?? '';
    final dues = row['monthly_dues'] ?? row['monthly_dues_custom_amount'];
    final duesText = dues == null || '$dues'.isEmpty
        ? null
        : Inr.formatAny(dues);

    late final Color fg;
    late final Color bg;
    late final String label;
    final l10n = context.l10n;
    if (status == 'VALID') {
      fg = context.colors.success;
      bg = context.colors.successBg;
      label = l10n.importStatValid;
    } else if (status == 'DUPLICATE') {
      fg = context.colors.warning;
      bg = context.colors.warningBg;
      label = l10n.importStatDuplicate;
    } else if (status.isEmpty) {
      fg = context.colors.textSecondary;
      bg = context.colors.neutralBg;
      label = '—';
    } else {
      fg = context.colors.error;
      bg = context.colors.errorBg;
      label = status == 'INVALID'
          ? l10n.importStatInvalid
          : statusLabel(context, status) ??
              status[0] + status.substring(1).toLowerCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rowNumber != null)
                  Text(l10n.importRowNumber(rowNumber),
                      style: context.text.caption),
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.listTitle),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  [
                    if (code.isNotEmpty) code,
                    phone.isEmpty
                        ? l10n.importNoPhone
                        : PhoneFormat.display(phone),
                    if (duesText != null) l10n.importDuesPerMonth(duesText),
                  ].join(' · '),
                  style: context.text.small,
                ),
                if (house.isNotEmpty)
                  Text(house,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.small),
                for (final error in errors) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(error, style: context.text.small.copyWith(color: fg)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: StatusPill(
              label: label,
              foreground: fg,
              background: bg,
              icon: status == 'VALID'
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Step 4: done
  // -------------------------------------------------------------------------

  Widget _donePage() {
    final r = _result!;
    final imported = _int(r['imported'] ?? r['imported_count']);
    final skipped = _int(r['skipped'] ?? r['skipped_count']);
    final batch =
        (r['batch_id'] ?? r['ingestion_batch'] ?? _batchId).toString();
    final l10n = context.l10n;
    final rawStatus = (r['status'] ?? '').toString().toUpperCase();
    final alreadyCommitted = rawStatus == 'ALREADY_COMMITTED';
    final statusText = rawStatus.isEmpty
        ? '—'
        : alreadyCommitted
            ? l10n.importStatusAlreadyCommitted
            : statusLabel(context, rawStatus) ?? rawStatus;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: AppPageScaffold(
        title: l10n.importFinished,
        eyebrow: l10n.importStepOf(4, kImportStepCount),
        subtitle: l10n.importServerConfirmed,
        showBack: false,
        floatingChild: AppCard.floating(
          child: Column(
            children: [
              AppStepIndicator(steps: importSteps(context), currentIndex: 3),
              const AppCardDivider(spacing: AppSpacing.md),
              Row(
                children: [
                  _stat(l10n.importStatImported, imported,
                      context.colors.success),
                  _stat(l10n.importStatSkipped, skipped,
                      context.colors.warning),
                ],
              ),
            ],
          ),
        ),
        content: [
          const SizedBox(height: AppSpacing.md),
          if (alreadyCommitted) ...[
            AppNoticeCard(
              icon: Icons.info_outline_rounded,
              title: l10n.importAlreadyCommittedTitle,
              message: l10n.importAlreadyCommittedBody,
              color: context.colors.info,
              background: context.colors.infoBg,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDetailRow(label: l10n.importDetailFile, value: _fileName),
                Divider(height: 1, color: context.colors.border),
                AppDetailRow(
                  label: l10n.importDetailStatus,
                  value: statusText,
                ),
                Divider(height: 1, color: context.colors.border),
                AppDetailRow(
                  label: l10n.importDetailBatch,
                  value: batch.isEmpty ? '—' : batch,
                ),
              ],
            ),
          ),
        ],
        bottomBar: AppBottomActionBar(
          children: [
            AppPrimaryButton(
              label: l10n.importGoToMembers,
              icon: Icons.people_rounded,
              onPressed: _finish,
            ),
          ],
        ),
      ),
    );
  }
}
