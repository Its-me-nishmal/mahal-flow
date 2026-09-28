import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../l10n/l10n.dart';

/// Help & support for members. Offers Call / WhatsApp when the API gives us
/// the Mahal office number; otherwise explains who to contact. Never shows a
/// made-up number.
class MemberHelpSheet {
  MemberHelpSheet._();

  /// Picks an office phone from any of the shapes the API may send it in
  /// (`mahal_phone`, `contact_phone`, `mahal_contact.phone`, `contact.phone`).
  static String? contactPhoneFrom(Map<String, dynamic>? data) {
    if (data == null) return null;
    String? read(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final direct = read(data['mahal_phone']) ??
        read(data['office_phone']) ??
        read(data['contact_phone']);
    if (direct != null) return direct;
    for (final key in ['mahal_contact', 'contact']) {
      final nested = data[key];
      if (nested is Map) {
        final p = read(nested['phone']);
        if (p != null) return p;
      }
    }
    return null;
  }

  static Future<void> show(
    BuildContext context, {
    String? mahalName,
    String? officePhone,
    String? extraNote,
  }) {
    final l10n = context.l10n;
    final digits =
        officePhone == null ? '' : PhoneFormat.nationalDigits(officePhone);
    final hasPhone = digits.length >= 10;

    Future<void> launch(Uri uri) async {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.helpOpenFailed)),
        );
      }
    }

    final named = mahalName?.trim() ?? '';
    final contactText = named.isEmpty
        ? (hasPhone ? l10n.helpContactGeneric : l10n.helpContactGenericNoPhone)
        : (hasPhone
            ? l10n.helpContactNamed(named)
            : l10n.helpContactNamedNoPhone(named));

    return AppBottomSheet.show(
      context: context,
      title: l10n.helpTitle,
      subtitle: hasPhone ? PhoneFormat.display(officePhone!) : null,
      icon: Icons.support_agent_rounded,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            contactText,
            style:
                context.text.body.copyWith(color: context.colors.textSecondary),
          ),
          if (extraNote != null) ...[
            const SizedBox(height: AppSpacing.ms),
            Text(extraNote, style: context.text.body),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final tip in [
            l10n.helpTipPending,
            l10n.helpTipReceipts,
            l10n.helpTipOffice,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: context.colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(tip, style: context.text.small)),
                ],
              ),
            ),
        ],
      ),
      actions: hasPhone
          ? [
              AppSecondaryButton(
                label: l10n.helpWhatsApp,
                icon: Icons.chat_outlined,
                height: AppSizes.buttonHeightCompact,
                onPressed: () => launch(Uri.parse('https://wa.me/91$digits')),
              ),
              AppPrimaryButton(
                label: l10n.helpCall,
                icon: Icons.call_rounded,
                height: AppSizes.buttonHeightCompact,
                onPressed: () => launch(Uri(scheme: 'tel', path: '+91$digits')),
              ),
            ]
          : null,
    );
  }
}
