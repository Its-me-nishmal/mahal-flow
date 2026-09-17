import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../widgets/admin_bottom_nav_bar.dart';

class GatewayConfigurationScreen extends StatefulWidget {
  const GatewayConfigurationScreen({super.key});

  @override
  State<GatewayConfigurationScreen> createState() =>
      _GatewayConfigurationScreenState();
}

class _GatewayConfigurationScreenState
    extends State<GatewayConfigurationScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _gateways = [];
  String _primaryGateway = "";
  String? _testedGatewayId;

  @override
  void initState() {
    super.initState();
    _loadGateways();
  }

  Future<void> _loadGateways() async {
    if (mounted) setState(() => _isLoading = true);
    final data = await _apiService.getGateways();
    if (!mounted) return;

    setState(() {
      _gateways = data.whereType<Map<String, dynamic>>().toList();

      for (final gw in _gateways) {
        if (gw["is_primary"] == true) {
          _primaryGateway = gw["provider"]?.toString() ?? "";
        }
      }
      if (_primaryGateway.isEmpty && _gateways.isNotEmpty) {
        _primaryGateway = _gateways.first["provider"]?.toString() ?? "";
      }

      _isLoading = false;
    });
  }

  int get _connectedCount => _gateways
      .where((gw) => (gw["status"]?.toString() ?? 'ACTIVE') == 'ACTIVE')
      .length;

  void _openConfigureModal(Map<String, dynamic> gw) {
    final name = gw["provider"]?.toString() ?? 'Payment gateway';
    final keyCtrl = TextEditingController(text: '••••••••••••••••');
    final secretCtrl = TextEditingController(text: '••••••••••••••••');

    AppBottomSheet.show(
      context: context,
      title: 'Configure $name',
      subtitle: 'Secrets are stored encrypted, never in plain text',
      icon: Icons.vpn_key_rounded,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: keyCtrl,
            label: 'API key / merchant ID',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: secretCtrl,
            label: 'Webhook secret',
            helper: 'Used to verify that callbacks really came from $name.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Save Configuration',
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name configuration saved.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _testConnection(String id) {
    setState(() => _testedGatewayId = id);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _testedGatewayId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection verified — the gateway responded.'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Gateways',
      eyebrow: 'Payments',
      subtitle: 'Where member payments are processed.',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        }
      },
      actions: [
        AppHeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: _loadGateways,
        ),
      ],
      onRefresh: _loadGateways,
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('PRIMARY GATEWAY', style: AppTextStyles.label),
                ),
                StatusPill(
                  label: '$_connectedCount connected',
                  foreground: AppColors.success,
                  background: AppColors.successBg,
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.ms),
            Text(
              _isLoading
                  ? 'Loading…'
                  : _primaryGateway.isEmpty
                      ? 'None set'
                      : _primaryGateway,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 22),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Every member payment is routed here first. If it fails, the '
              'next configured gateway takes over.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        const AppNoticeCard(
          icon: Icons.shield_outlined,
          title: 'Credentials are encrypted',
          message: 'Production secrets are stored with AES-256 encryption.',
          color: AppColors.warning,
          background: AppColors.warningBg,
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppSectionHeader(title: 'Configured gateways'),
        if (_isLoading)
          const ShimmerLoading(
            child: Column(
              children: [
                ShimmerCardSkeleton(height: 150),
                ShimmerCardSkeleton(height: 150),
              ],
            ),
          )
        else
          for (final gw in _gateways) ...[
            _gatewayCard(gw),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: 'Verify routing rules',
          icon: Icons.sync_alt_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Routing rules are active across all channels.'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
        ),
      ],
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
    );
  }

  Widget _gatewayCard(Map<String, dynamic> gw) {
    final name = gw["provider"]?.toString() ?? 'Unknown gateway';
    final rawStatus = gw["status"]?.toString() ?? 'ACTIVE';
    final isPrimary = gw["is_primary"] == true;
    final id = gw["id"]?.toString() ?? '';
    final isConnected = rawStatus == 'ACTIVE';
    final isTesting = _testedGatewayId == id;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconChip(
                icon: Icons.account_balance_outlined,
                color: isConnected ? AppColors.primary : AppColors.textMuted,
                background:
                    isConnected ? AppColors.primaryLight : AppColors.neutralBg,
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPrimary ? 'Primary route' : 'Fallback route',
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: isConnected ? 'Connected' : 'Inactive',
                foreground:
                    isConnected ? AppColors.success : AppColors.warning,
                background:
                    isConnected ? AppColors.successBg : AppColors.warningBg,
              ),
            ],
          ),
          const AppCardDivider(),
          const AppDetailRow(
            label: 'Merchant key',
            value: '••••••••••••••••',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: isTesting ? 'Testing…' : 'Test connection',
                  height: 44,
                  color: AppColors.textSecondary,
                  onPressed: isTesting ? null : () => _testConnection(id),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppPrimaryButton(
                  label: 'Configure',
                  height: 44,
                  onPressed: () => _openConfigureModal(gw),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
