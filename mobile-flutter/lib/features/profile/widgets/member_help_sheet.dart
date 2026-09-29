import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../l10n/l10n.dart';

/// Help & support for members. Offers Call when the API gives us the Mahal
/// office number (`mahal_contact.phone` on /member/dashboard and the
/// profile) and WhatsApp when it gives a WhatsApp number
/// (`mahal_contact.whatsapp`); otherwise explains who to contact. Never
/// shows a made-up number.
class MemberHelpSheet {
  MemberHelpSheet._();

  /// Picks an office phone from any of the shapes the API may send it in
  /// (`mahal_phone`, `contact_phone`, `mahal_contact.phone`, `contact.phone`).
  static String? contactPhoneFrom(Map<String, dynamic>? data) {
    if (data == null) return null;
    final direct = read(data['mahal_phone']) ??
        read(data['office_phone']) ??
        read(data['contact_phone']);
    if (direct != null) return direct;
    return _nested(data, 'phone');
  }

  /// The office WhatsApp number (`mahal_contact.whatsapp`), or null.
  static String? contactWhatsAppFrom(Map<String, dynamic>? data) {
    if (data == null) return null;
    return read(data['mahal_whatsapp']) ?? _nested(data, 'whatsapp');
  }

  static String? read(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static String? _nested(Map<String, dynamic> data, String field) {
    for (final key in ['mahal_contact', 'contact']) {
      final nested = data[key];
      if (nested is Map) {
        final p = read(nested[field]);
        if (p != null) return p;
      }
    }
    return null;
  }

  /// Digits for tel: / wa.me: a 10-digit Indian number gets +91, anything
  /// longer is taken as already carrying its country code.
  static String _intlDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '91$digits';
    if (digits.length == 11 && digits.startsWith('0')) {
      return '91${digits.substring(1)}';
    }
    return digits;
  }

  static Future<void> show(
    BuildContext context, {
    String? mahalName,
    String? officePhone,
    String? whatsApp,
    String? extraNote,
  }) {
    final l10n = context.l10n;
    final phoneDigits = officePhone == null ? '' : _intlDigits(officePhone);
    final hasPhone = phoneDigits.length >= 10;
    final waDigits = whatsApp == null ? '' : _intlDigits(whatsApp);
    final hasWhatsApp = waDigits.length >= 10;
    final hasContact = hasPhone || hasWhatsApp;

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
        ? (hasContact
            ? l10n.helpContactGeneric
            : l10n.helpContactGenericNoPhone)
        : (hasContact
            ? l10n.helpContactNamed(named)
            : l10n.helpContactNamedNoPhone(named));

    return AppBottomSheet.show(
      context: context,
      title: l10n.helpTitle,
      subtitle: hasPhone
          ? PhoneFormat.display(officePhone!)
          : hasWhatsApp
              ? PhoneFormat.display(whatsApp!)
              : null,
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
      actions: hasContact
          ? [
              if (hasWhatsApp)
                AppSecondaryButton(
                  label: l10n.helpWhatsApp,
                  icon: Icons.chat_outlined,
                  height: AppSizes.buttonHeightCompact,
                  onPressed: () =>
                      launch(Uri.parse('https://wa.me/$waDigits')),
                ),
              if (hasPhone)
                AppPrimaryButton(
                  label: l10n.helpCall,
                  icon: Icons.call_rounded,
                  height: AppSizes.buttonHeightCompact,
                  onPressed: () =>
                      launch(Uri(scheme: 'tel', path: '+$phoneDigits')),
                ),
            ]
          : null,
    );
  }
}
