import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';

/// One parsed spreadsheet row, with whatever is wrong with it.
class _ImportRow {
  final String name;
  final String phone;
  final String amount;
  final String status;
  final String? error;

  const _ImportRow({
    required this.name,
    required this.phone,
    required this.amount,
    required this.status,
    this.error,
  });

  bool get isValid => status == 'Valid';
}

class BulkExcelImportPreviewScreen extends StatelessWidget {
  const BulkExcelImportPreviewScreen({super.key});

  static const List<_ImportRow> _rows = [
    _ImportRow(name: 'Ahmed Khan', phone: '98765 12345', amount: '₹500', status: 'Valid'),
    _ImportRow(name: 'Yusuf Ali', phone: '98765 67890', amount: '₹500', status: 'Valid'),
    _ImportRow(name: 'Omar Farooq', phone: '98765 11111', amount: '₹500', status: 'Valid'),
    _ImportRow(name: 'Hassan Mir', phone: '', amount: '₹500', status: 'Invalid', error: 'No phone number'),
    _ImportRow(name: 'Irfan Sheikh', phone: '98765 22222', amount: 'abc', status: 'Invalid', error: 'Amount is not a number'),
    _ImportRow(name: 'Khalid Noor', phone: '98765 33333', amount: '₹500', status: 'Duplicate', error: 'This phone is already registered'),
    _ImportRow(name: 'Rafiq Ahmed', phone: '98765 44444', amount: '₹500', status: 'Valid'),
    _ImportRow(name: 'Suleman Patil', phone: '98765 55555', amount: '₹500', status: 'Valid'),
  ];

  int get _validCount => _rows.where((r) => r.status == 'Valid').length;
  int get _invalidCount => _rows.where((r) => r.status == 'Invalid').length;
  int get _duplicateCount => _rows.where((r) => r.status == 'Duplicate').length;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Check the rows',
      eyebrow: 'Step 3 of 4',
      subtitle: 'Only valid rows will be imported.',
      floatingChild: AppCard.floating(
        child: Column(
          children: [
            const AppStepIndicator(
              steps: ['Upload', 'Validate', 'Preview', 'Done'],
              currentIndex: 2,
            ),
            const AppCardDivider(spacing: AppSpacing.md),
            Row(
              children: [
                _stat('Total', '${_rows.length}', AppColors.textPrimary),
                _stat('Valid', '$_validCount', AppColors.success),
                _stat('Invalid', '$_invalidCount', AppColors.error),
                _stat('Duplicate', '$_duplicateCount', AppColors.warning),
              ],
            ),
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        if (_invalidCount + _duplicateCount > 0)
          AppNoticeCard(
            icon: Icons.report_problem_outlined,
            title: '${_invalidCount + _duplicateCount} rows will be skipped',
            message: 'Fix them in the spreadsheet and import again to add them.',
            color: AppColors.warning,
            background: AppColors.warningBg,
          ),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'Rows in your file'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < _rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                _row(_rows[i]),
              ],
            ],
          ),
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: 'Import $_validCount members',
            icon: Icons.check_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$_validCount members imported.'),
                  backgroundColor: AppColors.primary,
                ),
              );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Cancel',
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.small.copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _row(_ImportRow row) {
    late final Color color;
    late final Color background;
    if (row.status == 'Valid') {
      color = AppColors.success;
      background = AppColors.successBg;
    } else if (row.status == 'Invalid') {
      color = AppColors.error;
      background = AppColors.errorBg;
    } else {
      color = AppColors.warning;
      background = AppColors.warningBg;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: AppSpacing.ms,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.phone.isEmpty ? "No phone" : row.phone} · ${row.amount}',
                  style: AppTextStyles.small,
                ),
                if (row.error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    row.error!,
                    style: AppTextStyles.small.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(
            label: row.status,
            foreground: color,
            background: background,
            icon: row.isValid
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
          ),
        ],
      ),
    );
  }
}
