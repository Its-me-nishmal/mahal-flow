import 'package:flutter/material.dart';

import '../widgets/app_page_scaffold.dart';
import '../widgets/empty_state_view.dart';
import 'app_routes.dart';
import '../../l10n/l10n.dart';

/// Shown by `onUnknownRoute` for a route name nobody registered (a stale
/// push-notification deep link, a typo). Offers a way back instead of a red
/// error screen.
class RouteNotFoundScreen extends StatelessWidget {
  final String? routeName;

  const RouteNotFoundScreen({super.key, this.routeName});

  void _leave(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      // Nothing underneath: restart from the splash, which routes a signed-in
      // user to their dashboard and everyone else to sign-in.
      nav.pushNamedAndRemoveUntil(AppRoutes.splash, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.l10n.routeNotFoundTitle,
      onBack: () => _leave(context),
      expandedChild: EmptyStateView(
        icon: Icons.explore_off_outlined,
        title: context.l10n.routeNotFoundHeading,
        description: context.l10n.routeNotFoundBody,
        actionLabel: context.l10n.commonGoBack,
        onAction: () => _leave(context),
      ),
    );
  }
}
