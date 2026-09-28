import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
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

  String get _fileName {
    final server = _preview['filename']?.toString() ?? '';
    return server.isNotEmpty ? server : (_args?.fileName ?? '—');
  }

  Future<void> _commit() async {
    final valid = _valid ?? 0;
    final ok = await AppBottomSheet.showConfirmation(
      context: context,
      title: 'Import $valid ${valid == 1 ? 'member' : 'members'}?',
      message: 'They are added to the directory straight away. Rows with '
          'problems are skipped.',
      confirmLabel: 'Import',
      icon: Icons.group_add_rounded,
    );
    if (ok != true || !mounted) return;

    setState(() {
      _committing = true;
      _commitError = null;
    });
    try {
      final res = await _api.commitExcelImportOrThrow(
        fileName: _args?.fileName ?? _fileName,
        uploadId: _preview['upload_id']?.toString(),
      );
      if (!mounted) return;
      final status = (res['status'] ?? '').toString().toUpperCase();
      if (status.isNotEmpty && status != 'COMPLETED' && status != 'SUCCESS') {
        setState(() {
          _committing = false;
          _commitError =
              'The server reported "${res['status']}" — nothing was confirmed '
              'as imported.';
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
        title: 'Check the rows',
        eyebrow: 'Import',
        content: [
          const SizedBox(height: AppSpacing.lg),
          EmptyStateView(
            icon: Icons.upload_file_outlined,
            title: 'Nothing to review',
            description: 'Upload a spreadsheet first to see its rows here.',
            actionLabel: 'Choose a file',
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

    return PopScope(
      canPop: !_committing,
      child: AppPageScaffold(
        title: 'Check the rows',
        eyebrow: 'Step 3 of ${kImportSteps.length}',
        subtitle: 'Only valid rows will be imported.',
        floatingChild: AppCard.floating(
          child: Column(
            children: [
              const AppStepIndicator(steps: kImportSteps, currentIndex: 2),
              const AppCardDivider(spacing: AppSpacing.md),
              Text(_fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.small),
              const SizedBox(height: AppSpacing.ms),
              Row(
                children: [
                  _stat('Total', _total, context.colors.textPrimary),
                  _stat('Valid', _valid, context.colors.success),
                  _stat('Invalid', _invalid, context.colors.error),
                  _stat('Duplicate', _duplicate, context.colors.warning),
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
              title: skipped == 1
                  ? '1 row will be skipped'
                  : '$skipped rows will be skipped',
              message:
                  'Fix them in the spreadsheet and import again to add them.',
              color: context.colors.warning,
              background: context.colors.warningBg,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_commitError != null) ...[
            AppNoticeCard(
              icon: Icons.error_outline_rounded,
              title: 'Import not completed',
              message: _commitError!,
              color: context.colors.error,
              background: context.colors.errorBg,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppSectionHeader(
            title: rows.isEmpty
                ? 'Rows in your file'
                : (_total != null && _total! > rows.length)
                    ? 'Sample: ${rows.length} of $_total rows'
                    : 'Rows in your file',
          ),
          if (rows.isEmpty)
            const AppCard(
              child: EmptyStateView(
                icon: Icons.table_rows_outlined,
                title: 'No row preview',
                description: 'The server did not return any rows to preview.',
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
                  ? 'No valid rows to import'
                  : 'Import $valid ${valid == 1 ? 'member' : 'members'}',
              icon: Icons.check_rounded,
              isLoading: _committing,
              onPressed: (valid == 0 || _committing) ? null : _commit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Choose another file',
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
        label: '$label ${value ?? 'unknown'}',
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              value == null ? '—' : '$value',
              style: context.text.statValue.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.xs / 2),
            Text(label, style: context.text.caption),
          ],
        ),
      ),
    );
  }

  Widget _row(Map<String, dynamic> row) {
    final status = (row['status'] ?? '').toString().toUpperCase();
    final error = (row['error'] ?? row['reason'] ?? row['message'])?.toString();
    final name = row['name']?.toString() ?? '—';
    final phone = row['phone']?.toString() ?? '';
    final code = row['code']?.toString() ?? '';
    final dues = row['monthly_dues'] ?? row['monthly_dues_custom_amount'];

    late final Color fg;
    late final Color bg;
    late final String label;
    if (status == 'VALID') {
      fg = context.colors.success;
      bg = context.colors.successBg;
      label = 'Valid';
    } else if (status == 'DUPLICATE') {
      fg = context.colors.warning;
      bg = context.colors.warningBg;
      label = 'Duplicate';
    } else if (status.isEmpty) {
      fg = context.colors.textSecondary;
      bg = context.colors.neutralBg;
      label = '—';
    } else {
      fg = context.colors.error;
      bg = context.colors.errorBg;
      label = status == 'INVALID'
          ? 'Invalid'
          : status[0] + status.substring(1).toLowerCase();
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
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.listTitle),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  [
                    if (code.isNotEmpty) code,
                    phone.isEmpty ? 'No phone' : PhoneFormat.display(phone),
                    if (dues != null) '₹$dues/mo',
                  ].join(' · '),
                  style: context.text.small,
                ),
                if (error != null && error.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(error, style: context.text.small.copyWith(color: fg)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(
            label: label,
            foreground: fg,
            background: bg,
            icon: status == 'VALID'
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
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
    final imported = _int(r['imported_count']);
    final skipped = _int(r['skipped_count']);
    final batch = r['ingestion_batch']?.toString() ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: AppPageScaffold(
        title: 'Import finished',
        eyebrow: 'Step 4 of ${kImportSteps.length}',
        subtitle: 'The server confirmed the import.',
        showBack: false,
        floatingChild: AppCard.floating(
          child: Column(
            children: [
              const AppStepIndicator(steps: kImportSteps, currentIndex: 3),
              const AppCardDivider(spacing: AppSpacing.md),
              Row(
                children: [
                  _stat('Imported', imported, context.colors.success),
                  _stat('Skipped', skipped, context.colors.warning),
                ],
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
                AppDetailRow(label: 'File', value: _fileName),
                Divider(height: 1, color: context.colors.border),
                AppDetailRow(
                  label: 'Status',
                  value: (r['status'] ?? '—').toString(),
                ),
                Divider(height: 1, color: context.colors.border),
                AppDetailRow(
                  label: 'Batch',
                  value: batch.isEmpty ? '—' : batch,
                ),
              ],
            ),
          ),
        ],
        bottomBar: AppBottomActionBar(
          children: [
            AppPrimaryButton(
              label: 'Go to members',
              icon: Icons.people_rounded,
              onPressed: _finish,
            ),
          ],
        ),
      ),
    );
  }
}
