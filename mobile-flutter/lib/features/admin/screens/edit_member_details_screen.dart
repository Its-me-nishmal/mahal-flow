import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_sheet.dart';

class EditMemberDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const EditMemberDetailsScreen({super.key, required this.member});

  @override
  State<EditMemberDetailsScreen> createState() => _EditMemberDetailsScreenState();
}

class _EditMemberDetailsScreenState extends State<EditMemberDetailsScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _houseController;
  late TextEditingController _amountController;
  String _selectedStatus = "ACTIVE";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member["name"]?.toString() ?? "");
    _phoneController = TextEditingController(text: widget.member["phone"]?.toString() ?? "");
    _houseController = TextEditingController(text: widget.member["house_name"]?.toString() ?? "");
    final rawAmount = widget.member["amount"]?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? "500";
    _amountController = TextEditingController(text: rawAmount.isEmpty ? "500" : rawAmount);

    final rawStatus = widget.member["raw_status"]?.toString() ?? widget.member["status"]?.toString() ?? "ACTIVE";
    if (rawStatus.toUpperCase().contains("GRACE") || rawStatus.toUpperCase().contains("OVERDUE") || rawStatus.toUpperCase().contains("PENDING")) {
      _selectedStatus = "GRACE_PERIOD";
    } else if (rawStatus.toUpperCase().contains("SUSPEND") || rawStatus.toUpperCase().contains("INACTIVE")) {
      _selectedStatus = "SUSPENDED";
    } else {
      _selectedStatus = "ACTIVE";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final house = _houseController.text.trim();
    final dues = double.tryParse(_amountController.text.trim()) ?? 500.0;
    final memberId = widget.member["id"]?.toString() ?? "";

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and phone cannot be empty")),
      );
      return;
    }

    setState(() => _isSaving = true);
    final success = await _apiService.updateMemberDetails(
      memberId: memberId,
      name: name,
      phone: phone,
      houseName: house,
      duesAmount: dues,
      status: _selectedStatus,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Member details updated successfully!"),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update member details")),
        );
      }
    }
  }

  Future<void> _handleDeactivate() async {
    final memberId = widget.member["id"]?.toString() ?? "";
    setState(() => _isSaving = true);

    final success = await _apiService.updateMemberDetails(
      memberId: memberId,
      name: _nameController.text.trim(),
      status: "SUSPENDED",
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Member has been suspended"),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

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
          "Edit Member Profile",
          style: GoogleFonts.inter(
            fontSize: 22,
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
            _buildField("Full Name", _nameController),
            const SizedBox(height: 16),
            _buildField("Phone Number", _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField("House / Family Name", _houseController),
            const SizedBox(height: 16),
            _buildField("Monthly Dues (₹)", _amountController, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildStatusDropdown(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        "Save Changes",
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
                onPressed: () async {
                  final confirmed = await AppBottomSheet.showConfirmation(
                    context: context,
                    title: "Suspend Member?",
                    message: "Are you sure you want to set ${_nameController.text}'s status to Suspended? Their dues collection will be placed on hold.",
                    confirmLabel: "Suspend",
                    confirmColor: AppColors.error,
                    icon: Icons.person_off_rounded,
                  );
                  if (confirmed == true) {
                    _handleDeactivate();
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Suspend Member",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Membership Status",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              items: const [
                DropdownMenuItem(value: "ACTIVE", child: Text("Active")),
                DropdownMenuItem(value: "GRACE_PERIOD", child: Text("Grace Period")),
                DropdownMenuItem(value: "SUSPENDED", child: Text("Suspended")),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
