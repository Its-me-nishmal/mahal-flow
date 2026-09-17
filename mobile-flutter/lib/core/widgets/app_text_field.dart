import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Labelled text input. One field style across every form in the app.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.icon,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.initialValue,
    this.onChanged,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm - 2),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onTap: onTap,
          enabled: enabled,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            helperText: helper,
            helperStyle: AppTextStyles.small.copyWith(fontSize: 11.5),
            errorText: errorText,
            errorStyle: AppTextStyles.small.copyWith(
              fontSize: 11.5,
              color: AppColors.error,
            ),
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 19, color: AppColors.textMuted),
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.background,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2,
              vertical: AppSpacing.ms + 2,
            ),
            border: border(AppColors.border),
            enabledBorder: border(AppColors.border),
            disabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.primary, width: 1.6),
            errorBorder: border(AppColors.error),
            focusedErrorBorder: border(AppColors.error, width: 1.6),
          ),
        ),
      ],
    );
  }
}

/// Non-editable field used to show a value the member cannot change
/// (member ID, mahal, registration date).
class AppReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final String? note;

  const AppReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm - 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - 2,
            vertical: AppSpacing.ms + 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Icon(Icons.lock_outline_rounded,
                  size: 15, color: AppColors.textMuted),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Text(note!, style: AppTextStyles.small.copyWith(fontSize: 11.5)),
        ],
      ],
    );
  }
}

/// Labelled dropdown that matches [AppTextField] exactly.
class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? helper;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm - 2),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            isDense: true,
            helperText: helper,
            helperStyle: AppTextStyles.small.copyWith(fontSize: 11.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2,
              vertical: AppSpacing.ms + 2,
            ),
            border: border(AppColors.border),
            enabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.primary, width: 1.6),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
