import 'package:flutter/foundation.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';

import '../../core/network/api_service.dart';

/// Shared PayU CheckoutPro plumbing for dues, contributions and AutoPay.
///
/// Every value sent to the SDK comes from the server's checkout payload
/// (`GET /payments/payu-checkout-data/:orderId` or the mandate `payu_checkout`
/// block). The server signs the payment hash over key|txnid|amount|
/// productinfo|firstname|email|udf1..udf5, so the udf values must be exactly
/// the ones it signed: they live under `params` in that payload. When the
/// server omits them we fall back to the same values it uses (txn/mandate id,
/// tenant, signed-in member) — never to a demo id.
class PayUCheckout {
  PayUCheckout._();

  static Map<String, dynamic> _params(Map<String, dynamic> checkout) {
    final raw = checkout['params'];
    if (raw is Map) return raw.cast<String, dynamic>();
    return const {};
  }

  /// The value for [key] from `params`, then the top level.
  static String? _value(Map<String, dynamic> checkout, String key) {
    final v = _params(checkout)[key] ?? checkout[key];
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Builds the SDK payment params, or null when the payload is missing a
  /// field PayU cannot work without (key, txnid, amount, hash inputs).
  ///
  /// [referenceId] is the server transaction / mandate id (udf1 fallback).
  static Map<String, dynamic>? paymentParams({
    required Map<String, dynamic> checkout,
    required String transactionId,
    required String referenceId,
    required String memberId,
    Map<String, dynamic>? siParams,
  }) {
    final key = _value(checkout, 'key');
    final amount = _value(checkout, 'amount');
    final txnId = _value(checkout, 'txnid') ?? transactionId;
    final productInfo = _value(checkout, 'productinfo');
    final firstName = _value(checkout, 'firstname');
    final email = _value(checkout, 'email');
    final phone = _value(checkout, 'phone');
    final surl = _value(checkout, 'surl');
    final furl = _value(checkout, 'furl');

    if (key == null ||
        amount == null ||
        productInfo == null ||
        firstName == null ||
        email == null ||
        phone == null ||
        surl == null ||
        furl == null) {
      debugPrint('[PAYU] checkout payload incomplete: $checkout');
      return null;
    }

    // PayU user_credential is "<merchantKey>:<memberId>".
    final userCredential =
        ApiService.payuUserCredential(key, memberId: memberId);

    return {
      PayUPaymentParamKey.key: key,
      PayUPaymentParamKey.amount: amount,
      PayUPaymentParamKey.productInfo: productInfo,
      PayUPaymentParamKey.firstName: firstName,
      PayUPaymentParamKey.email: email,
      PayUPaymentParamKey.phone: phone,
      PayUPaymentParamKey.ios_surl: surl,
      PayUPaymentParamKey.ios_furl: furl,
      PayUPaymentParamKey.android_surl: surl,
      PayUPaymentParamKey.android_furl: furl,
      PayUPaymentParamKey.environment: "0", // 0 = PRODUCTION, 1 = TEST
      PayUPaymentParamKey.transactionId: txnId,
      if (userCredential != null)
        PayUPaymentParamKey.userCredential: userCredential,
      PayUPaymentParamKey.additionalParam: {
        PayUAdditionalParamKeys.udf1: _value(checkout, 'udf1') ?? referenceId,
        PayUAdditionalParamKeys.udf2:
            _value(checkout, 'udf2') ?? ApiService.defaultTenant,
        PayUAdditionalParamKeys.udf3: _value(checkout, 'udf3') ?? memberId,
      },
      if (siParams != null) PayUPaymentParamKey.payUSIParams: siParams,
    };
  }

  static Map<String, dynamic> config({bool upiIntentOnly = false}) => {
        PayUCheckoutProConfigKeys.primaryColor: "#146C5B",
        PayUCheckoutProConfigKeys.secondaryColor: "#ffffff",
        PayUCheckoutProConfigKeys.merchantName: "MahalFlow Treasury",
        PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: false,
        PayUCheckoutProConfigKeys.showExitConfirmationOnPaymentScreen: false,
        PayUCheckoutProConfigKeys.upiAppsOrder: "gpay|phonepe|paytm",
        if (upiIntentOnly)
          PayUCheckoutProConfigKeys.enforcePaymentList: [
            {"payment_type": "UPI", "payment_option": "INTENT"},
          ],
      };

  /// Answers the SDK's hash request from the backend, falling back to the
  /// pre-signed payment hash in [checkout].
  static Future<void> respondToHashRequest({
    required ApiService api,
    required PayUCheckoutProFlutter checkoutPro,
    required Map response,
    Map<String, dynamic>? checkout,
  }) async {
    final hashName = response[PayUHashConstantsKeys.hashName]?.toString() ?? "";
    final hashString =
        response[PayUHashConstantsKeys.hashString]?.toString() ?? "";
    final hashType = response[PayUHashConstantsKeys.hashType]?.toString();
    final postSalt = response[PayUHashConstantsKeys.postSalt]?.toString();

    if (hashString.isNotEmpty) {
      try {
        final generated = await api.generatePayUHash(
          hashName: hashName,
          hashString: hashString,
          hashType: hashType,
          postSalt: postSalt,
        );
        if (generated != null && generated.isNotEmpty) {
          checkoutPro.hashGenerated(hash: {hashName: generated});
          return;
        }
      } catch (e) {
        debugPrint("[PAYU_HASH_ERROR] $hashName: $e");
      }
    }

    final preSigned = checkout?["hash"] ?? _paramsOrEmpty(checkout)["hash"];
    if (preSigned != null && hashName == "payment_hash") {
      checkoutPro.hashGenerated(hash: {hashName: preSigned.toString()});
    } else {
      checkoutPro.hashGenerated(hash: {});
    }
  }

  static Map<String, dynamic> _paramsOrEmpty(Map<String, dynamic>? c) =>
      c == null ? const {} : _params(c);

  /// A short, member-readable reason from a PayU failure/error payload.
  /// Gateway codes and stack text are never shown.
  static String failureReason(dynamic response) {
    String? pick(dynamic map) {
      if (map is! Map) return null;
      for (final k in ['errorMessage', 'error_Message', 'field9', 'message']) {
        final v = map[k]?.toString().trim();
        if (v != null && v.isNotEmpty && v.length <= 120) return v;
      }
      return null;
    }

    final direct = pick(response);
    if (direct != null) return direct;
    if (response is Map) {
      final nested = pick(response['payuResponse']);
      if (nested != null) return nested;
    }
    return 'The payment could not be completed.';
  }
}
