import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../utils/share_file.dart';

/// Steps shared by the import flow so the indicator reads the same on every
/// screen: choose → upload & validate → review → done.
const List<String> kImportSteps = ['Choose', 'Validate', 'Review', 'Done'];

/// Arguments for [AppRoutes.adminImportPreview].
class ImportPreviewArgs {
  final String fileName;
  final Map<String, dynamic> preview;
  const ImportPreviewArgs({required this.fileName, required this.preview});
}

class BulkExcelImportStep1Screen extends StatefulWidget {
  const BulkExcelImportStep1Screen({super.key});

  @override
  State<BulkExcelImportStep1Screen> createState() =>
      _BulkExcelImportStep1ScreenState();
}

class _BulkExcelImportStep1ScreenState
    extends State<BulkExcelImportStep1Screen> {
  static const List<String> _extensions = ['xlsx', 'xls', 'csv'];
  static const String _templateHeader = 'name,phone,house_name,monthly_dues';

  final ApiService _api = ApiService();
  PlatformFile? _file;
  bool _picking = false;
  bool _uploading = false;
  double? _progress;
  String? _error;
  bool _sharingTemplate = false;

  Future<void> _pickFile() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _extensions,
        withData: false,
      );
      if (!mounted) return;
      final f = result?.files.single;
      if (f != null) {
        final ext = f.name.split('.').last.toLowerCase();
        if (!_extensions.contains(ext)) {
          setState(() => _error = 'Choose an .xlsx, .xls or .csv file.');
        } else if (f.size == 0) {
          setState(() => _error = 'That file is empty.');
        } else {
          setState(() => _file = f);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = "Couldn't open the file picker. $e");
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _upload() async {
    final f = _file;
    if (f == null) return;
    setState(() {
      _uploading = true;
      _progress = null;
      _error = null;
    });
    try {
      final preview = await _api.uploadExcelPreviewOrThrow(
        fileName: f.name,
        path: f.path,
        bytes: f.path == null ? f.bytes : null,
        onSendProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => _progress = (sent / total).clamp(0.0, 1.0));
        },
      );
      if (!mounted) return;
      setState(() => _uploading = false);
      Navigator.of(context).pushNamed(
        AppRoutes.adminImportPreview,
        arguments: ImportPreviewArgs(fileName: f.name, preview: preview),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = e.userMessage;
      });
    }
  }

  Future<void> _shareTemplate() async {
    setState(() => _sharingTemplate = true);
    try {
      await shareGeneratedFile(
        context,
        bytes: utf8.encode('$_templateHeader\n'),
        fileName: 'mahalflow_members_template.csv',
        mimeType: 'text/csv',
        subject: 'MahalFlow member import template',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't create the template. $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingTemplate = false);
    }
  }

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final step = _uploading ? 1 : 0;
    return AppPageScaffold(
      title: 'Import members',
      eyebrow: 'Step ${step + 1} of ${kImportSteps.length}',
      subtitle: 'Bring a whole directory in from a spreadsheet.',
      onBack: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          AppNav.adminHome(context);
        }
      },
      floatingChild: AppCard.floating(
        child: Column(
          children: [
            AppStepIndicator(steps: kImportSteps, currentIndex: step),
            const SizedBox(height: AppSpacing.lg),
            _uploadArea(),
            if (_uploading) ...[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: AppSpacing.sm,
                  semanticsLabel: 'Upload progress',
                  backgroundColor: context.colors.border,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(context.colors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _progress == null || _progress! >= 1
                    ? 'Validating on the server…'
                    : 'Uploading ${(_progress! * 100).round()}%',
                style: context.text.caption,
              ),
            ],
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        if (_error != null) ...[
          AppNoticeCard(
            icon: Icons.error_outline_rounded,
            title: "Couldn't use this file",
            message: _error!,
            color: context.colors.error,
            background: context.colors.errorBg,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          onTap: _sharingTemplate ? null : _shareTemplate,
          child: Row(
            children: [
              AppIconChip(
                icon: Icons.download_rounded,
                color: context.colors.info,
                background: context.colors.infoBg,
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Get the template', style: context.text.listTitle),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      'A CSV with name, phone, house_name and monthly_dues '
                      'columns. Save or send it from the share sheet.',
                      style: context.text.small,
                    ),
                  ],
                ),
              ),
              if (_sharingTemplate)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                Icon(Icons.ios_share_rounded,
                    size: 20, color: context.colors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppNoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'Nothing is saved yet',
          message:
              'The server checks the file first. You review its results before '
              'anything is written to the directory.',
          color: context.colors.info,
          background: context.colors.infoBg,
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: 'Upload & validate',
            icon: Icons.arrow_forward_rounded,
            isLoading: _uploading,
            onPressed: (_file != null && !_uploading) ? _upload : null,
          ),
        ],
      ),
    );
  }

  Widget _uploadArea() {
    final f = _file;
    final selected = f != null;
    return Semantics(
      button: true,
      label: selected
          ? 'Selected file ${f.name}. Tap to choose a different file.'
          : 'Choose a spreadsheet',
      excludeSemantics: true,
      child: InkWell(
        onTap: (_picking || _uploading) ? null : _pickFile,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: selected ? context.colors.primaryLight : context.colors.background,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? context.colors.primary : context.colors.border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: AppSizes.minTouch + AppSpacing.ms,
                height: AppSizes.minTouch + AppSpacing.ms,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  shape: BoxShape.circle,
                ),
                child: _picking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Icon(
                        selected
                            ? Icons.description_rounded
                            : Icons.cloud_upload_outlined,
                        size: 32,
                        color:
                            selected ? context.colors.primary : context.colors.textMuted,
                      ),
              ),
              const SizedBox(height: AppSpacing.ms),
              Text(
                selected ? f.name : 'Choose a spreadsheet',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.cardTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                selected ? _size(f.size) : 'Accepts .xlsx, .xls and .csv files',
                style: context.text.small,
              ),
              if (selected && !_uploading) ...[
                const SizedBox(height: AppSpacing.ms),
                Text(
                  'Tap to choose a different file',
                  style: context.text.buttonSmall
                      .copyWith(color: context.colors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
