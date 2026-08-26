import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class BulkExcelImportPreviewScreen extends StatelessWidget {
  const BulkExcelImportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          "Import Preview",
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
            const SizedBox(height: 24),
            _buildSummaryStats(),
            const SizedBox(height: 16),
            _buildPreviewTable(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Confirm Import (15 members)",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
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
        _buildStep(1, true),
        Expanded(child: Container(height: 2, color: AppColors.primary)),
        _buildStep(2, true),
        Expanded(child: Container(height: 2, color: AppColors.primary)),
        _buildStep(3, true),
        Expanded(child: Container(height: 2, color: AppColors.border)),
        _buildStep(4, false),
      ],
    );
  }

  Widget _buildStep(int number, bool isCompleted) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.primary : AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted ? AppColors.primary : AppColors.border,
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
                  color: AppColors.textMuted,
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 29, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem("Total", "20", AppColors.textPrimary),
          _buildStatItem("Valid", "15", AppColors.success),
          _buildStatItem("Invalid", "3", AppColors.error),
          _buildStatItem("Duplicates", "2", AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTable() {
    final rows = [
      {"name": "Ahmed Khan", "phone": "98765 12345", "amount": "₹500", "status": "Valid", "valid": true},
      {"name": "Yusuf Ali", "phone": "98765 67890", "amount": "₹500", "status": "Valid", "valid": true},
      {"name": "Omar Farooq", "phone": "98765 11111", "amount": "₹500", "status": "Valid", "valid": true},
      {"name": "Hassan Mir", "phone": "", "amount": "₹500", "status": "Invalid", "valid": false, "error": "Missing phone"},
      {"name": "Irfan Sheikh", "phone": "98765 22222", "amount": "abc", "status": "Invalid", "valid": false, "error": "Invalid amount"},
      {"name": "Khalid Noor", "phone": "98765 33333", "amount": "₹500", "status": "Duplicate", "valid": false, "error": "Duplicate phone"},
      {"name": "Rafiq Ahmed", "phone": "98765 44444", "amount": "₹500", "status": "Valid", "valid": true},
      {"name": "Suleman Patil", "phone": "98765 55555", "amount": "₹500", "status": "Valid", "valid": true},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 29, 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Preview",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              headingRowColor: WidgetStateProperty.all(AppColors.background),
              columns: [
                DataColumn(label: Text("Name", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                DataColumn(label: Text("Phone", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                DataColumn(label: Text("Amount", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                DataColumn(label: Text("Status", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
              ],
              rows: rows.map((row) {
                final isValid = row["valid"] as bool;
                final status = row["status"] as String;

                Color chipColor;
                Color chipBg;
                if (status == "Valid") {
                  chipColor = AppColors.success;
                  chipBg = AppColors.successBg;
                } else if (status == "Invalid") {
                  chipColor = AppColors.error;
                  chipBg = AppColors.errorBg;
                } else {
                  chipColor = AppColors.warning;
                  chipBg = AppColors.warningBg;
                }

                return DataRow(
                  color: WidgetStateProperty.all(
                    isValid ? null : AppColors.errorBg,
                  ),
                  cells: [
                    DataCell(Text(
                      row["name"] as String,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                    )),
                    DataCell(Text(
                      (row["phone"] as String).isEmpty ? "—" : row["phone"] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: (row["phone"] as String).isEmpty ? AppColors.error : AppColors.textPrimary,
                      ),
                    )),
                    DataCell(Text(
                      row["amount"] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: (row["amount"] as String) == "abc" ? AppColors.error : AppColors.textPrimary,
                      ),
                    )),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: chipColor,
                              ),
                            ),
                          ),
                          if (row["error"] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              row["error"] as String,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
