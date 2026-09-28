import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_buttons.dart';
import '../../l10n/l10n.dart';

/// Centers a state view in the space it is given and makes it scrollable, so
/// it (a) never overflows on a short screen or with large text and (b) works
/// as the child of a RefreshIndicator (pull-to-refresh needs a scrollable).
/// In unbounded height (inside another scroll view) it lays out as a plain
/// column instead.
class _StateViewFrame extends StatelessWidget {
  final Widget child;
  const _StateViewFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: child,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return padded;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: padded),
          ),
        );
      },
    );
  }
}

/// "Nothing here yet" state. Pairs with [AppErrorStateView]: same shape, same
/// spacing, different meaning — empty is normal, an error is not.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _StateViewFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: context.colors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.sectionTitle,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: context.text.body.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: actionLabel!,
              expand: false,
              height: AppSizes.minTouch,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

/// Network / API failure state (docs/design.md section 16). Mirrors the API of
/// [EmptyStateView] so the two read as one family. Pass
/// `ApiException.userMessage` as [description].
class AppErrorStateView extends StatelessWidget {
  /// Defaults to the localized "Something went wrong".
  final String? title;
  final String description;

  /// Defaults to the localized "Try Again".
  final String? actionLabel;
  final VoidCallback onRetry;
  final IconData icon;

  const AppErrorStateView({
    super.key,
    this.title,
    required this.description,
    this.actionLabel,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return _StateViewFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.errorBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: context.colors.error),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(title ?? context.l10n.commonSomethingWentWrong,
                textAlign: TextAlign.center, style: context.text.sectionTitle),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: context.text.body.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: actionLabel ?? context.l10n.commonTryAgain,
            icon: Icons.refresh_rounded,
            expand: false,
            height: AppSizes.minTouch,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
