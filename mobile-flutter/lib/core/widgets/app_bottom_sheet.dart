import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    required Widget Function(BuildContext context, StateSetter setState) builder,
    List<Widget>? actions,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              // The sheet paints under the system navigation bar in edge to
              // edge, so the actions need that inset too. max(), not a sum:
              // when the keyboard is up it already covers the bar.
              bottom:
                  math.max(
                    MediaQuery.viewInsetsOf(context).bottom,
                    MediaQuery.viewPaddingOf(context).bottom,
                  ) +
                  20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.15),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 20),
                      ),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.sectionTitle,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: AppTextStyles.small,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Body Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: builder(context, setState),
                  ),
                ),

                if (actions != null && actions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: actions[i]),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = "Confirm",
    String cancelLabel = "Cancel",
    Color confirmColor = AppColors.primary,
    IconData icon = Icons.help_outline_rounded,
  }) {
    return show<bool>(
      context: context,
      title: title,
      icon: icon,
      builder: (ctx, _) => Text(
        message,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          height: 20 / 14,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          ),
          child: Text(
            cancelLabel,
            style: AppTextStyles.button.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            elevation: 0,
          ),
          child: Text(
            confirmLabel,
            style: AppTextStyles.button.copyWith(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
