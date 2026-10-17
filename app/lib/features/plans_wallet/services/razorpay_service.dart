/// Safe wrapper for Razorpay Flutter checkout in test mode.
/// Owner: M4
library;

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef PaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef PaymentFailureCallback = void Function(PaymentFailureResponse response);
typedef ExternalWalletCallback = void Function(ExternalWalletResponse response);

class WarmPathRazorpayService {
  Razorpay? _razorpay;
  bool _initialized = false;

  PaymentSuccessCallback? onSuccess;
  PaymentFailureCallback? onFailure;
  ExternalWalletCallback? onExternalWallet;

  void initialize({
    required PaymentSuccessCallback onSuccess,
    required PaymentFailureCallback onFailure,
    ExternalWalletCallback? onExternalWallet,
  }) {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;

    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _initialized = true;
    } catch (e) {
      debugPrint('Razorpay init notice (platform channels not available): $e');
      _initialized = false;
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('Razorpay checkout success callback received: ${response.paymentId}');
    // IMPORTANT: In WarmPath, client success is NEVER trusted to activate plans.
    // The Polling Controller will verify via GET /me/subscription signed webhook activation.
    onSuccess?.call(response);
  }

  void _handleError(PaymentFailureResponse response) {
    debugPrint('Razorpay checkout error: [${response.code}] ${response.message}');
    onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('Razorpay external wallet selected: ${response.walletName}');
    onExternalWallet?.call(response);
  }

  /// Opens the Razorpay checkout overlay.
  /// If native platform channels are unavailable (e.g. desktop/web or tests),
  /// triggers simulated success so testing can proceed smoothly.
  Future<void> openCheckout({
    required String subscriptionId,
    required String keyId,
    required int amountInr,
    required String planName,
    String? userEmail,
    String? userContact,
  }) async {
    final options = {
      'key': keyId.isNotEmpty ? keyId : 'rzp_test_WarmPathDev',
      'subscription_id': subscriptionId,
      'name': 'WarmPath ($planName)',
      'description': 'WarmPath Mentorship Subscription (Test Mode)',
      'timeout': 180, // 3 minutes
      'prefill': {
        'contact': userContact ?? '9999999999',
        'email': userEmail ?? 'student@vips.edu',
      },
      'theme': {
        'color': '#FF6B4A', // WarmPath Coral
      },
      'modal': {
        'confirm_close': true,
      },
      'notes': {
        'test_mode': 'true',
        'platform': 'warmpath_flutter',
      },
    };

    if (!_initialized || _razorpay == null) {
      debugPrint('Razorpay running in fallback simulation mode.');
      // Simulate successful checkout response for web/desktop/testing
      await Future.delayed(const Duration(milliseconds: 600));
      _handleSuccess(
        PaymentSuccessResponse(
          'pay_simulated_${DateTime.now().millisecondsSinceEpoch}',
          'order_simulated_${DateTime.now().millisecondsSinceEpoch}',
          'sig_simulated_${DateTime.now().millisecondsSinceEpoch}',
          null,
        ),
      );
      return;
    }

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error invoking Razorpay native checkout: $e');
      // Graceful fallback for non-mobile platforms
      await Future.delayed(const Duration(milliseconds: 600));
      _handleSuccess(
        PaymentSuccessResponse(
          'pay_fallback_${DateTime.now().millisecondsSinceEpoch}',
          'order_fallback_${DateTime.now().millisecondsSinceEpoch}',
          'sig_fallback_${DateTime.now().millisecondsSinceEpoch}',
          null,
        ),
      );
    }
  }

  void dispose() {
    try {
      _razorpay?.clear();
    } catch (_) {}
    _razorpay = null;
    _initialized = false;
  }
}
