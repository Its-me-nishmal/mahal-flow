import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../../l10n/l10n.dart';

/// Animated placeholder sweep over skeleton boxes. Announced once as
/// [semanticsLabel] (the skeleton itself is hidden from screen readers) and
/// held still when the system asks for reduced motion.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  /// Defaults to the localized "Loading".
  final String? semanticsLabel;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.semanticsLabel,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant ShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _syncAnimation() {
    final shouldRun = widget.isLoading && !_reduceMotion;
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final skeleton = ExcludeSemantics(child: widget.child);
    final semanticsLabel = widget.semanticsLabel ?? context.l10n.commonLoading;
    if (_reduceMotion) {
      return Semantics(label: semanticsLabel, child: skeleton);
    }

    return Semantics(
      label: semanticsLabel,
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [
                  (_animation.value - 0.3).clamp(0.0, 1.0),
                  _animation.value.clamp(0.0, 1.0),
                  (_animation.value + 0.3).clamp(0.0, 1.0),
                ],
                colors: [
                  context.colors.border.withValues(alpha: 0.5),
                  context.colors.shimmerHighlight,
                  context.colors.border.withValues(alpha: 0.5),
                ],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: skeleton,
      ),
    );
  }
}

class ShimmerSkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.border.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerCardSkeleton extends StatelessWidget {
  final double height;

  const ShimmerCardSkeleton({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: AppSpacing.ms),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.colors.border),
      ),
      child: const Row(
        children: [
          ShimmerSkeletonBox(width: 44, height: 44, borderRadius: 22),
          SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerSkeletonBox(width: 140, height: 14, borderRadius: 4),
                SizedBox(height: AppSpacing.sm),
                ShimmerSkeletonBox(width: 90, height: 10, borderRadius: 4),
              ],
            ),
          ),
          ShimmerSkeletonBox(
              width: 60, height: 24, borderRadius: AppRadius.button),
        ],
      ),
    );
  }
}
