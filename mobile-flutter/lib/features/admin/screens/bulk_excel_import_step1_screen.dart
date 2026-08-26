import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'bulk_excel_import_preview_screen.dart';

class BulkExcelImportStep1Screen extends StatefulWidget {
  const BulkExcelImportStep1Screen({super.key});

  @override
  State<BulkExcelImportStep1Screen> createState() => _BulkExcelImportStep1ScreenState();
}

class _BulkExcelImportStep1ScreenState extends State<BulkExcelImportStep1Screen> {
  bool _fileSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/admin/dashboard');
            }
          },
        ),
        title: Text(
          "Import Members",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 32),
            _buildUploadArea(),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "Download template file",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _fileSelected
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const BulkExcelImportPreviewScreen(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Next: Validate",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStep(1, "Upload", true, true),
        Expanded(child: Container(height: 2, color: AppColors.border)),
        _buildStep(2, "Validate", false, false),
        Expanded(child: Container(height: 2, color: AppColors.border)),
        _buildStep(3, "Preview", false, false),
        Expanded(child: Container(height: 2, color: AppColors.border)),
        _buildStep(4, "Complete", false, false),
      ],
    );
  }

  Widget _buildStep(int number, String label, bool isActive, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : (isCompleted ? AppColors.primary : AppColors.background),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    "$number",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: () {
        setState(() => _fileSelected = !_fileSelected);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: _fileSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _fileSelected ? AppColors.primary : AppColors.border,
            width: 2,
            style: _fileSelected ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _fileSelected ? Icons.check_circle : Icons.cloud_upload,
                size: 48,
                color: _fileSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _fileSelected ? "File Selected" : "Upload Excel File",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _fileSelected ? "members.xlsx" : "Supports .xlsx and .xls formats",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            if (!_fileSelected) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() => _fileSelected = true);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Choose File",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
