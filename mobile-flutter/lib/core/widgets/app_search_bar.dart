import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../../l10n/l10n.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  /// Placeholder; defaults to the localized "Search…".
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? suffixAction;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.suffixAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.searchBar,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: context.colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(23, 32, 29, 0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.ms),
          ExcludeSemantics(
            child: Icon(Icons.search, color: context.colors.textMuted, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: context.text.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText ?? '${context.l10n.commonSearch}…',
                hintStyle: context.text.body.copyWith(
                  color: context.colors.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.ms),
              ),
            ),
          ),
          // Rebuilds on every edit so the clear button tracks the text,
          // including text set programmatically.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: context.l10n.commonClearSearch,
                icon: Icon(Icons.close,
                    size: 16, color: context.colors.textSecondary),
                onPressed: () {
                  controller.clear();
                  if (onClear != null) {
                    onClear!();
                  } else if (onChanged != null) {
                    onChanged!("");
                  }
                },
              );
            },
          ),
          if (suffixAction != null) ...[
            Container(height: AppSpacing.lg, width: 1, color: context.colors.border),
            suffixAction!,
          ],
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}
