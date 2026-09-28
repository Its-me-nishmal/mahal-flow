import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../../l10n/l10n.dart';

/// -------------------------------------------------------------------------
/// The one page shell every screen in the app uses.
///
/// It reproduces the member home language: a brand gradient header that runs
/// behind the status bar, white cards on the off-white canvas below it, and an
/// optional first card that floats up over the lower edge of the gradient.
/// Screens supply content, never chrome, so every page reads as one product.
/// -------------------------------------------------------------------------

/// Circular translucent icon button used inside the gradient header.
/// Draws a [AppSizes.headerIcon] circle inside a [AppSizes.minTouch] hit area.
class AppHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final int badgeCount;

  const AppHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel =
        badgeCount > 0
            ? context.l10n.commonUnreadCount(tooltip, badgeCount)
            : tooltip;

    // One semantics node: the Tooltip is visual only, so the label is not
    // announced twice.
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: AppSizes.minTouch / 2,
          child: SizedBox(
            width: AppSizes.minTouch,
            height: AppSizes.minTouch,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: AppSizes.headerIcon,
                    height: AppSizes.headerIcon,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.colors.error,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: context.colors.primaryDark, width: 2),
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: context.text.label.copyWith(
                            color: context.colors.onPrimary,
                            fontSize: 10,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Translucent pill with an icon and a short label, for the gradient header
/// (the language toggle on the sign-in screens). Same visual language as
/// [AppHeaderIconButton]; hit area is at least [AppSizes.minTouch] tall.
class AppHeaderPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback? onTap;

  const AppHeaderPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$tooltip, $label',
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
            child: Center(
              widthFactor: 1,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
                decoration: BoxDecoration(
                  color: AppBrand.onBrand.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppBrand.onBrand.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: AppBrand.onBrand),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      label,
                      style: context.text.buttonSmall
                          .copyWith(color: AppBrand.onBrand),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The gradient header block. Used by [AppPageScaffold]; screens that build
/// their own body layout (a full-height list, a form with a sticky footer)
/// can place it directly at the top of a Column.
class AppGradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;

  /// Replaces the back button — a drawer toggle, an avatar, a close button.
  final Widget? leading;

  /// Optional block rendered inside the gradient below the title — a search
  /// bar, filter chips, or a summary strip.
  final Widget? child;

  /// Extra breathing room at the bottom of the gradient, used by
  /// [AppPageScaffold] so the first card can float over the edge.
  final double bottomPadding;

  const AppGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.leading,
    this.child,
    this.bottomPadding = AppSpacing.lg,
  });

  @override
  Widget build(BuildContext context) {
    final onHeroMuted = Colors.white.withValues(alpha: 0.74);
    final canPop = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: context.colors.heroGradient),
      padding: EdgeInsets.only(
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
        bottom: bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.ms),
              ] else if (showBack && (canPop || onBack != null)) ...[
                // The 48dp hit area overhangs the 42dp circle by 3dp, so
                // pull it left to keep the circle on the screen margin.
                Transform.translate(
                  offset: const Offset(-3, 0),
                  child: AppHeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: context.l10n.commonBack,
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.ms - 3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!.toUpperCase(),
                        style: context.text.label.copyWith(
                          color: Colors.white.withValues(alpha: 0.66),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.pageTitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Header buttons carry 3dp of hit-area slack per side, so a
              // 2dp gap reads as the 8dp spacing between the circles.
              for (final action in actions) ...[
                const SizedBox(width: AppSpacing.sm - 6),
                action,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: context.text.body.copyWith(color: onHeroMuted),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: AppSpacing.md),
            child!,
          ],
        ],
      ),
    );
  }
}

/// Scrollable page: gradient header, then a column of content on the canvas.
///
/// [floatingChild] is drawn overlapping the bottom of the gradient, the way
/// the balance card does on the member home.
class AppPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? drawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? headerChild;
  final Widget? floatingChild;

  /// Content below the header. Laid out in a Column with screen padding.
  final List<Widget> content;

  /// Fills the remaining height instead of scrolling — for screens that own
  /// their own ListView.
  final Widget? expandedChild;

  final Future<void> Function()? onRefresh;

  /// Sticky footer (usually [AppBottomActionBar]). It rides above the
  /// keyboard, so a form's primary action stays reachable while typing.
  final Widget? bottomBar;

  /// Tab bar. Unlike [bottomBar] it stays behind the keyboard.
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool padded;

  const AppPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.leading,
    this.drawer,
    this.scaffoldKey,
    this.headerChild,
    this.floatingChild,
    this.content = const [],
    this.expandedChild,
    this.onRefresh,
    this.bottomBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padded = true,
  });

  static const double _overlap = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final hasFloating = floatingChild != null;

    final header = AppGradientHeader(
      title: title,
      subtitle: subtitle,
      eyebrow: eyebrow,
      actions: actions,
      showBack: showBack,
      onBack: onBack,
      leading: leading,
      bottomPadding: hasFloating ? AppSpacing.lg + _overlap : AppSpacing.lg,
      child: headerChild,
    );

    Widget body;
    if (expandedChild != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, Expanded(child: expandedChild!)],
      );
    } else {
      final inner = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasFloating)
            // Pulls the card up over the gradient without disturbing layout;
            // the trailing spacer below gives the scroll extent back.
            Container(
              transform: Matrix4.translationValues(0, -_overlap, 0),
              child: floatingChild,
            ),
          ...content,
          SizedBox(height: hasFloating ? AppSpacing.xxl - _overlap : AppSpacing.xxl),
        ],
      );

      body = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padded ? AppSpacing.screenH : 0,
              ),
              child: inner,
            ),
          ],
        ),
      );

      if (onRefresh != null) {
        body = RefreshIndicator(
          onRefresh: onRefresh!,
          color: context.colors.primary,
          backgroundColor: context.colors.surface,
          edgeOffset: MediaQuery.paddingOf(context).top + 64,
          child: body,
        );
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.colors.gradientHeaderOverlay,
      child: Scaffold(
        key: scaffoldKey,
        drawer: drawer,
        backgroundColor: context.colors.background,
        body: body,
        bottomNavigationBar: bottomBar != null
            ? _KeyboardLift(child: bottomBar!)
            : bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

/// Pads its child by the keyboard height. Scaffold keeps
/// `bottomNavigationBar` pinned to the screen bottom (under the keyboard);
/// lifting it here also shrinks the body by the same amount, so nothing is
/// covered.
class _KeyboardLift extends StatelessWidget {
  final Widget child;
  const _KeyboardLift({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}

/// Sticky footer that holds a screen's primary commitment (Pay, Save, Submit).
/// Sits on the surface colour with a hairline top border so it never floats
/// ambiguously over content.
class AppBottomActionBar extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  /// Set false when a bottom nav bar sits below this one — otherwise both
  /// reserve the system gesture inset and a dead band opens up between them.
  final bool applySafeArea;

  const AppBottomActionBar({
    super.key,
    required this.children,
    this.applySafeArea = true,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.screenH,
      AppSpacing.ms,
      AppSpacing.screenH,
      AppSpacing.ms,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: applySafeArea ? SafeArea(top: false, child: body) : body,
    );
  }
}

/// Filter chips that sit inside the gradient header. Selected reads as a solid
/// white pill; the rest are translucent, so the row never competes with the
/// page title.
class AppHeroFilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, int>? counts;

  const AppHeroFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final option = options[i];
          final isActive = option == selected;
          final count = counts?[option];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(option),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md - 2,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.26),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option,
                      style: context.text.buttonSmall.copyWith(
                        color: isActive ? context.colors.primaryDark : Colors.white,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: AppSpacing.xs + 2),
                      Text(
                        '$count',
                        style: context.text.small.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? context.colors.primary
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
