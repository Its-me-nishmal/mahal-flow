import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../../l10n/l10n.dart';

/// Labelled text input. One field style across every form in the app.
///
/// The visible label above the box is merged into the field's semantics, so a
/// screen reader announces "Mobile number, edit box" rather than an
/// unlabelled field. Set [obscureText] for secrets; an eye toggle is added
/// automatically unless [suffix] is supplied.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;

  /// Helper line under the field. [helperText] wins over the older [helper].
  final String? helperText;
  final String? helper;
  final String? errorText;
  final IconData? icon;

  /// Fixed text before the input, e.g. "+91 ".
  final String? prefixText;
  final Widget? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;

  /// Starting text when no [controller] is given.
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Overrides the label announced by screen readers.
  final String? semanticsLabel;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.helper,
    this.errorText,
    this.icon,
    this.prefixText,
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
    this.obscureText = false,
    this.autofillHints,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.onSubmitted,
    this.semanticsLabel,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;
  TextEditingController? _ownController;

  TextEditingController? get _controller => widget.controller ?? _ownController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null && widget.initialValue != null) {
      _ownController = TextEditingController(text: widget.initialValue);
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final enabled = widget.enabled;
    Widget? suffix = widget.suffix;
    if (suffix == null && widget.obscureText) {
      suffix = IconButton(
        tooltip: _obscured
            ? context.l10n.commonShowLabel(widget.label)
            : context.l10n.commonHideLabel(widget.label),
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 19,
          color: context.colors.textMuted,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }

    final field = TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      onSubmitted: widget.onSubmitted,
      enabled: enabled,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      // Obscured fields must be single line.
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      textCapitalization: widget.textCapitalization,
      obscureText: _obscured,
      enableSuggestions: !widget.obscureText,
      autocorrect: !widget.obscureText,
      autofillHints: enabled ? widget.autofillHints : null,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      style: context.text.body.copyWith(
        fontWeight: FontWeight.w500,
        color: enabled ? context.colors.textPrimary : context.colors.textMuted,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        counterText: '',
        helperText: widget.helperText ?? widget.helper,
        helperMaxLines: 3,
        helperStyle: context.text.caption,
        errorText: widget.errorText,
        errorMaxLines: 3,
        errorStyle: context.text.caption.copyWith(color: context.colors.error),
        hintStyle: context.text.body.copyWith(color: context.colors.textMuted),
        prefixIcon: widget.icon == null
            ? null
            : Icon(widget.icon, size: 19, color: context.colors.textMuted),
        prefixText: widget.prefixText,
        prefixStyle: context.text.body.copyWith(
          fontWeight: FontWeight.w500,
          color: context.colors.textSecondary,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: enabled ? context.colors.surface : context.colors.background,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 2,
          vertical: AppSpacing.ms + 2,
        ),
        border: border(context.colors.border),
        enabledBorder: border(context.colors.border),
        disabledBorder: border(context.colors.border),
        focusedBorder: border(context.colors.primary, width: 1.6),
        errorBorder: border(context.colors.error),
        focusedErrorBorder: border(context.colors.error, width: 1.6),
      ),
    );

    final labelText = Text(
      widget.label,
      style: context.text.small.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colors.textSecondary,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The visible label is decoration; the field carries it semantically.
        ExcludeSemantics(child: labelText),
        const SizedBox(height: AppSpacing.sm - 2),
        Semantics(
          label: widget.semanticsLabel ?? widget.label,
          textField: true,
          child: field,
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
          style: context.text.small.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
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
            color: context.colors.background,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: context.colors.textMuted),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  value,
                  style: context.text.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              Icon(Icons.lock_outline_rounded,
                  size: 15, color: context.colors.textMuted),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Text(note!, style: context.text.caption),
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
          style: context.text.small.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm - 2),
        DropdownButtonFormField<T>(
          // initialValue is only read on first build; keying on the value
          // rebuilds the field when the parent changes it.
          key: ValueKey<T>(value),
          initialValue: value,
          isExpanded: true,
          dropdownColor: context.colors.surfaceRaised,
          style: context.text.body.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.colors.surface,
            isDense: true,
            helperText: helper,
            helperStyle: context.text.caption,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - 2,
              vertical: AppSpacing.ms + 2,
            ),
            border: border(context.colors.border),
            enabledBorder: border(context.colors.border),
            focusedBorder: border(context.colors.primary, width: 1.6),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
