import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../../l10n/l10n.dart';

/// Circular person avatar: the photo when [imageUrl] loads, otherwise up to
/// two initials from [name] ("Muhammed Ameen" → "MA"), otherwise a person
/// glyph. Announced as [semanticsLabel] (defaults to [name]); pass
/// `excludeFromSemantics: true` when the name is already read next to it.
class AppAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;

  /// Light variant for use on the gradient header.
  final bool onHero;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final bool excludeFromSemantics;

  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 44,
    this.onHero = false,
    this.onTap,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  });

  /// "Muhammed Ameen" → "MA", "ameen" → "A", "" → "".
  static String initialsOf(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty && RegExp(r'[A-Za-z0-9]').hasMatch(p[0]))
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(name);
    final background =
        onHero ? Colors.white.withValues(alpha: 0.18) : context.colors.primaryLight;
    final foreground = onHero ? Colors.white : context.colors.primary;

    Widget fallback = initials.isEmpty
        ? Icon(Icons.person_rounded, size: size * 0.52, color: foreground)
        : Text(
            initials,
            maxLines: 1,
            style: context.text.cardTitle.copyWith(
              fontSize: size * 0.38,
              height: 1,
              color: foreground,
            ),
          );
    fallback = Center(child: fallback);

    final url = imageUrl?.trim() ?? '';
    final content = url.isEmpty
        ? fallback
        : CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          );

    Widget avatar = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: onHero
            ? Border.all(color: Colors.white.withValues(alpha: 0.28))
            : null,
      ),
      child: content,
    );

    if (onTap != null) {
      avatar = InkResponse(
        onTap: onTap,
        radius: (size < AppSizes.minTouch ? AppSizes.minTouch : size) / 2,
        child: SizedBox(
          width: size < AppSizes.minTouch ? AppSizes.minTouch : size,
          height: size < AppSizes.minTouch ? AppSizes.minTouch : size,
          child: Center(child: avatar),
        ),
      );
    }

    if (excludeFromSemantics) return ExcludeSemantics(child: avatar);
    final label = semanticsLabel ?? name;
    return Semantics(
      label: (label == null || label.trim().isEmpty) ? context.l10n.commonProfile : label,
      image: onTap == null,
      button: onTap != null,
      excludeSemantics: true,
      child: avatar,
    );
  }
}
