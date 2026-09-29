import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../../receipts/receipt_view.dart';

/// Read-only view of the tenant's payment gateways (GET /admin/gateways).
///
/// Gateways are managed from the server configuration (`managed_by:
/// SERVER_CONFIG`): there is no endpoint to change, test or re-route one, so
/// this screen only reports what the server says. Secrets are never sent —
/// the server masks the merchant key itself (`merchant_key_masked`).
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

  bool get _anySimulated => _gateways.any((gw) => gw['simulated'] == true);

  static String _name(Map<String, dynamic> gw) {
    final display = gw['display_name']?.toString().trim() ?? '';
    if (display.isNotEmpty) return display;
    return gw['provider']?.toString() ?? '—';
  }

  static String _maskedKey(dynamic raw) {
    final key = raw?.toString().trim() ?? '';
    return key.isEmpty ? L10n.current.gatewayKeyNotShown : key;
  }

  static List<String> _methods(dynamic raw) => raw is List
      ? raw.map((m) => '$m'.trim()).where((m) => m.isNotEmpty).toList()
      : const [];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPageScaffold(
      title: l10n.gatewayTitle,
      eyebrow: l10n.gatewayEyebrow,
      subtitle: l10n.gatewaySubtitle,
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
          title: l10n.gatewayManagedTitle,
          message: l10n.gatewayManagedDesc,
          color: context.colors.info,
          background: context.colors.infoBg,
        ),
        if (!_isLoading && _error == null && _anySimulated) ...[
          const SizedBox(height: AppSpacing.sm),
          AppNoticeCard(
            icon: Icons.science_outlined,
            title: l10n.gatewaySimulatedTitle,
            message: l10n.gatewaySimulatedDesc,
            color: context.colors.warning,
            background: context.colors.warningBg,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(title: l10n.gatewayConfigured),
        if (_isLoading)
          ShimmerLoading(
            semanticsLabel: l10n.gatewayLoading,
            child: Column(
              children: [
                for (var i = 0; i < 2; i++)
                  const ShimmerCardSkeleton(height: 120),
              ],
            ),
          )
        else if (_error != null)
          AppErrorStateView(
            title: l10n.gatewayLoadError,
            description: _error!.userMessage,
            onRetry: () {
              setState(() => _isLoading = true);
              _loadGateways();
            },
          )
        else if (_gateways.isEmpty)
          EmptyStateView(
            icon: Icons.account_balance_outlined,
            title: l10n.gatewayEmptyTitle,
            description: l10n.gatewayEmptyDesc,
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
    final l10n = context.l10n;
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.gatewayPrimaryHeading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label),
              ),
              if (!_isLoading)
                Flexible(
                  child: StatusPill(
                    label:
                        l10n.gatewayActiveCount(_activeCount, _gateways.length),
                    foreground: _activeCount > 0
                        ? context.colors.success
                        : context.colors.warning,
                    background: _activeCount > 0
                        ? context.colors.successBg
                        : context.colors.warningBg,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          Text(
            _isLoading
                ? l10n.gatewayLoadingShort
                : (primary == null ? l10n.gatewayNoneSet : _name(primary)),
            style: context.text.pageTitle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.gatewayRoutedHere,
            style:
                context.text.body.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _gatewayCard(Map<String, dynamic> gw) {
    final l10n = context.l10n;
    final provider = (gw['provider']?.toString() ?? '').toUpperCase();
    final isCash = provider == 'CASH';
    final rawStatus = gw['status']?.toString() ?? '';
    final isPrimary = gw['is_primary'] == true;
    final active = rawStatus.toUpperCase() == 'ACTIVE';
    final mode = (gw['mode']?.toString() ?? '').toUpperCase();
    final simulated = gw['simulated'] == true;
    final methods = _methods(gw['supported_methods']);
    final autopay = gw['autopay_enabled'] == true;

    final modeLabel = switch (mode) {
      'LIVE' => l10n.gatewayModeLive,
      'TEST' => l10n.gatewayModeTest,
      '' => '—',
      _ => mode,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconChip(
                icon: isCash
                    ? Icons.payments_outlined
                    : Icons.account_balance_outlined,
                color:
                    active ? context.colors.primary : context.colors.textMuted,
                background: active
                    ? context.colors.primaryLight
                    : context.colors.neutralBg,
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name(gw),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.listTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      isCash
                          ? l10n.gatewayCashRoute
                          : isPrimary
                              ? l10n.gatewayPrimaryRoute
                              : l10n.gatewayFallbackRoute,
                      style: context.text.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: StatusPill.forStatus(
                    context, rawStatus.isEmpty ? 'UNKNOWN' : rawStatus),
              ),
            ],
          ),
          const AppCardDivider(),
          if (!isCash) ...[
            AppDetailRow(
              label: l10n.gatewayMode,
              value: simulated
                  ? l10n.gatewayModeSimulated(modeLabel)
                  : modeLabel,
            ),
            AppDetailRow(
              label: l10n.gatewayKeyId,
              value: _maskedKey(gw['merchant_key_masked']),
            ),
          ],
          AppDetailRow(
            label: l10n.gatewayMethods,
            value: methods.isEmpty
                ? '—'
                : methods.map(ReceiptView.methodName).join(', '),
          ),
          if (!isCash)
            AppDetailRow(
              label: l10n.gatewayAutoPay,
              value: autopay ? l10n.gatewayAutoPayOn : l10n.gatewayAutoPayOff,
            ),
          AppDetailRow(
            label: l10n.gatewayId,
            value: gw['id']?.toString() ?? '—',
          ),
        ],
      ),
    );
  }
}
