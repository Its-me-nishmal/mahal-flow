import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_page_scaffold.dart';

class PayUCheckoutWebViewScreen extends StatefulWidget {
  final String orderId;
  final String checkoutUrl;
  final double amount;

  const PayUCheckoutWebViewScreen({
    super.key,
    required this.orderId,
    required this.checkoutUrl,
    required this.amount,
  });

  @override
  State<PayUCheckoutWebViewScreen> createState() => _PayUCheckoutWebViewScreenState();
}

class _PayUCheckoutWebViewScreenState extends State<PayUCheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
              });
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (request) async {
            final uri = Uri.parse(request.url);

            // 1. Intercept UPI Intents (GPay, PhonePe, Paytm, BHIM)
            if (uri.scheme == "upi" ||
                uri.scheme == "gpay" ||
                uri.scheme == "phonepe" ||
                uri.scheme == "paytm" ||
                request.url.startsWith("intent://")) {
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                debugPrint("[UPI_INTENT_ERROR] $e");
              }
              return NavigationDecision.prevent;
            }

            // 2. Check if returned to webhook / return URL
            if (uri.path.contains("/webhooks/pg") ||
                uri.path.contains("payment-success") ||
                request.url.contains("status=success")) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }

            if (request.url.contains("status=failure") ||
                request.url.contains("status=cancel")) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppOverlayStyles.gradientHeader,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            AppGradientHeader(
              title: 'Secure checkout',
              eyebrow: 'PayU',
              subtitle:
                  '${Inr.format(widget.amount)} · Order ${widget.orderId}',
              bottomPadding: AppSpacing.md,
              onBack: () => Navigator.of(context).pop(false),
            ),
            SizedBox(
              height: 3,
              child: _isLoading
                  ? LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(child: WebViewWidget(controller: _controller)),
          ],
        ),
      ),
    );
  }
}
