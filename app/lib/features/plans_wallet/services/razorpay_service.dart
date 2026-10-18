/// Safe wrapper for Razorpay Flutter checkout in test mode.
/// WarmPath uses real Razorpay TEST checkout; simulated payment shortcuts are prohibited.
/// Plan activations occur ONLY via backend signed webhook verification.
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
    // Client-side checkout callback: WarmPath waits for signed webhook verification.
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

  /// Opens the real Razorpay native checkout in test mode.
  Future<void> openCheckout({
    required String subscriptionId,
    required String keyId,
    required int amountInr,
    required String planName,
    String? userEmail,
    String? userContact,
  }) async {
    if (keyId.isEmpty) {
      _handleError(
        PaymentFailureResponse(
          Razorpay.INVALID_OPTIONS,
          'Payment gateway key missing from checkout response.',
          null,
        ),
      );
      return;
    }

    final options = {
      'key': keyId,
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
      debugPrint('Razorpay native plugin not initialized on this platform.');
      _handleError(
        PaymentFailureResponse(
          Razorpay.UNKNOWN_ERROR,
          'Razorpay checkout requires Android/iOS device support in test mode.',
          null,
        ),
      );
      return;
    }

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error invoking Razorpay native checkout: $e');
      _handleError(
        PaymentFailureResponse(
          Razorpay.UNKNOWN_ERROR,
          'Failed to open checkout: $e',
          null,
        ),
      );
    }
  }

  void dispose() {
    try {
      _razorpay?.clear();
    } catch (_) {}
    _initialized = false;
  }
}
