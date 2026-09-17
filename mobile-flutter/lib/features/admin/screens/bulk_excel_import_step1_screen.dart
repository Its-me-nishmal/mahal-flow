import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import 'bulk_excel_import_preview_screen.dart';

class BulkExcelImportStep1Screen extends StatefulWidget {
  const BulkExcelImportStep1Screen({super.key});

  @override
  State<BulkExcelImportStep1Screen> createState() =>
      _BulkExcelImportStep1ScreenState();
}

class _BulkExcelImportStep1ScreenState
    extends State<BulkExcelImportStep1Screen> {
  bool _fileSelected = false;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Import members',
      eyebrow: 'Step 1 of 4',
      subtitle: 'Bring a whole directory in from a spreadsheet.',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        }
      },
      floatingChild: AppCard.floating(
        child: Column(
          children: [
            const AppStepIndicator(
              steps: ['Upload', 'Validate', 'Preview', 'Done'],
              currentIndex: 0,
            ),
            const SizedBox(height: AppSpacing.lg),
            _uploadArea(),
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template downloaded.')),
          ),
          child: Row(
            children: [
              const AppIconChip(
                icon: Icons.download_rounded,
                color: AppColors.info,
                background: AppColors.infoBg,
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download the template',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Name, phone, house name and monthly dues columns.',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppNoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Nothing is saved yet',
          message:
              'You will see every row and any problems with it before anything '
              'is written to the directory.',
          color: AppColors.info,
          background: AppColors.infoBg,
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: 'Next: Validate',
            icon: Icons.arrow_forward_rounded,
            onPressed: _fileSelected
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const BulkExcelImportPreviewScreen(),
                      ),
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _uploadArea() {
    return InkWell(
      onTap: () => setState(() => _fileSelected = !_fileSelected),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: _fileSelected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: _fileSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _fileSelected
                    ? Icons.check_circle_rounded
                    : Icons.cloud_upload_outlined,
                size: 32,
                color: _fileSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.ms),
            Text(
              _fileSelected ? 'File selected' : 'Choose a spreadsheet',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _fileSelected ? 'members.xlsx' : 'Accepts .xlsx and .xls files',
              style: AppTextStyles.small,
            ),
            if (_fileSelected) ...[
              const SizedBox(height: AppSpacing.ms),
              AppTextActionButton(
                label: 'Choose a different file',
                onPressed: () => setState(() => _fileSelected = false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
