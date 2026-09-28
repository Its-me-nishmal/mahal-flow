import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';

/// Read-only view of the tenant's payment gateways (GET /admin/gateways).
///
/// The API exposes no endpoint to change, test or re-route a gateway, so this
/// screen only reports what the server says; configuration happens in the web
/// admin. Secrets are never shown — at most the last four characters of a
/// public key id.
class GatewayConfigurationScreen extends StatefulWidget {
  const GatewayConfigurationScreen({super.key});

  @override
  State<GatewayConfigurationScreen> createState() =>
      _GatewayConfigurationScreenState();
}

class _GatewayConfigurationScreenState
    extends State<GatewayConfigurationScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  ApiException? _error;
  List<Map<String, dynamic>> _gateways = [];

  @override
  void initState() {
    super.initState();
    _loadGateways();
  }

  Future<void> _loadGateways() async {
    setState(() => _error = null);
    try {
      final data = await _api.getGatewaysOrThrow();
      if (!mounted) return;
      setState(() {
        _gateways =
            data.whereType<Map>().map(Map<String, dynamic>.from).toList();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? get _primary {
    for (final gw in _gateways) {
      if (gw['is_primary'] == true) return gw;
    }
    return null;
  }

  int get _activeCount => _gateways
      .where((gw) => (gw['status']?.toString() ?? '').toUpperCase() == 'ACTIVE')
      .length;

  static String _maskedKey(dynamic raw) {
    final key = raw?.toString().trim() ?? '';
    if (key.isEmpty) return 'Not shown in the app';
    final tail = key.length > 4 ? key.substring(key.length - 4) : '';
    return tail.isEmpty ? '••••••••' : '••••••••$tail';
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Gateways',
      eyebrow: 'Payments',
      subtitle: 'Where member payments are processed.',
      onBack: () {
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.pop();
        } else {
          AppNav.adminHome(context);
        }
      },
      onRefresh: _loadGateways,
      floatingChild: _error == null ? _summaryCard() : null,
      content: [
        const SizedBox(height: AppSpacing.md),
        AppNoticeCard(
          icon: Icons.desktop_windows_outlined,
          title: 'Managed from web admin',
          message: 'Gateway keys, webhook secrets and routing are set up in '
              'the MahalFlow web admin. This screen is read-only and never '
              'shows secrets.',
          color: context.colors.info,
          background: context.colors.infoBg,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'Configured gateways'),
        if (_isLoading)
          ShimmerLoading(
            semanticsLabel: 'Loading gateways',
            child: Column(
              children: [
                for (var i = 0; i < 2; i++)
                  const ShimmerCardSkeleton(height: 120),
              ],
            ),
          )
        else if (_error != null)
          AppErrorStateView(
            title: "Couldn't load gateways",
            description: _error!.userMessage,
            onRetry: () {
              setState(() => _isLoading = true);
              _loadGateways();
            },
          )
        else if (_gateways.isEmpty)
          const EmptyStateView(
            icon: Icons.account_balance_outlined,
            title: 'No gateways configured',
            description: 'Set one up in the web admin to accept online '
                'payments.',
          )
        else
          for (final gw in _gateways) ...[
            _gatewayCard(gw),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  Widget _summaryCard() {
    final primary = _primary;
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('PRIMARY GATEWAY', style: context.text.label),
              ),
              if (!_isLoading)
                StatusPill(
                  label: '$_activeCount of ${_gateways.length} active',
                  foreground:
                      _activeCount > 0 ? context.colors.success : context.colors.warning,
                  background: _activeCount > 0
                      ? context.colors.successBg
                      : context.colors.warningBg,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          Text(
            _isLoading
                ? 'Loading…'
                : (primary?['provider']?.toString() ?? 'None set'),
            style: context.text.pageTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Member payments are routed here first.',
            style: context.text.body.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _gatewayCard(Map<String, dynamic> gw) {
    final name = gw['provider']?.toString() ?? '—';
    final rawStatus = gw['status']?.toString() ?? '';
    final isPrimary = gw['is_primary'] == true;
    final active = rawStatus.toUpperCase() == 'ACTIVE';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconChip(
                icon: Icons.account_balance_outlined,
                color: active ? context.colors.primary : context.colors.textMuted,
                background:
                    active ? context.colors.primaryLight : context.colors.neutralBg,
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.listTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      isPrimary ? 'Primary route' : 'Fallback route',
                      style: context.text.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill.forStatus(context, rawStatus.isEmpty ? 'UNKNOWN' : rawStatus),
            ],
          ),
          const AppCardDivider(),
          AppDetailRow(label: 'Key ID', value: _maskedKey(gw['key_id'])),
          AppDetailRow(
            label: 'Gateway ID',
            value: gw['id']?.toString() ?? '—',
          ),
        ],
      ),
    );
  }
}
