import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../../l10n/l10n.dart';

class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    Color? iconBackground,
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
              left: AppSpacing.md + AppSpacing.xs,
              right: AppSpacing.md + AppSpacing.xs,
              top: AppSpacing.ms,
              // The sheet paints under the system navigation bar in edge to
              // edge, so the actions need that inset too. max(), not a sum:
              // when the keyboard is up it already covers the bar.
              bottom:
                  math.max(
                    MediaQuery.viewInsetsOf(context).bottom,
                    MediaQuery.viewPaddingOf(context).bottom,
                  ) +
                  AppSpacing.md + AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: context.colors.surfaceRaised,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sheet)),
              boxShadow: context.colors.sheetShadow,
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
                    margin: const EdgeInsets.only(bottom: AppSpacing.ms),
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
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
                        margin: const EdgeInsets.only(right: AppSpacing.ms),
                        decoration: BoxDecoration(
                          color: iconBackground ?? context.colors.primaryLight,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Icon(icon,
                            color: iconColor ?? context.colors.primary,
                            size: 20),
                      ),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.text.sectionTitle,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: context.text.small,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.commonClose,
                      icon: Icon(Icons.close_rounded, size: 20, color: context.colors.textMuted),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Body Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: builder(context, setState),
                  ),
                ),

                if (actions != null && actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.ms),
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

  /// Yes/no sheet. Resolves true on confirm, false on cancel, null when
  /// dismissed. Set [destructive] for delete / sign-out / irreversible
  /// actions: the confirm button and icon turn red and the icon defaults to a
  /// warning glyph.
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    Color? confirmColor,
    IconData? icon,
    bool destructive = false,
  }) {
    final accent =
        confirmColor ?? (destructive ? context.colors.error : context.colors.primary);
    return show<bool>(
      context: context,
      title: title,
      icon: icon ??
          (destructive
              ? Icons.warning_amber_rounded
              : Icons.help_outline_rounded),
      iconColor: destructive ? context.colors.error : context.colors.primary,
      iconBackground: destructive ? context.colors.errorBg : context.colors.primaryLight,
      builder: (ctx, _) => Text(
        message,
        style: context.text.body.copyWith(
          color: context.colors.textSecondary,
          height: 20 / 14,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSizes.minTouch),
            side: BorderSide(color: context.colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
          ),
          child: Text(
            cancelLabel ?? context.l10n.commonCancel,
            style: context.text.buttonMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: context.colors.onPrimary,
            minimumSize: const Size.fromHeight(AppSizes.minTouch),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            elevation: 0,
          ),
          child: Text(
            confirmLabel ?? context.l10n.commonConfirm,
            style: context.text.buttonMedium.copyWith(
              color: context.colors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
