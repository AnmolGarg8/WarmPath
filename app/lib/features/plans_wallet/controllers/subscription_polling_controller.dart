/// Subscription webhook activation polling controller.
/// WarmPath never trusts client-side payment callbacks: it polls GET /me/subscription
/// until the webhook updates the plan in the database.
/// Owner: M4
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';

enum PollingStatus {
  idle,
  polling,
  active,
  timeout,
  failed,
}

class SubscriptionPollingController extends ChangeNotifier {
  final Duration pollInterval;
  final int maxAttempts;

  PollingStatus _status = PollingStatus.idle;
  int _attempts = 0;
  String _statusMessage = '';
  UserSubscriptionModel? _activatedSubscription;
  Timer? _timer;
  bool _cancelled = false;

  SubscriptionPollingController({
    this.pollInterval = const Duration(seconds: 2),
    this.maxAttempts = 15, // 15 attempts * 2s = 30 seconds
  });

  PollingStatus get status => _status;
  int get attempts => _attempts;
  String get statusMessage => _statusMessage;
  UserSubscriptionModel? get activatedSubscription => _activatedSubscription;
  bool get isPolling => _status == PollingStatus.polling;

  /// Starts polling GET /me/subscription until status becomes 'active'
  /// and plan code matches [targetPlanCode].
  Future<void> startPolling({
    required Future<UserSubscriptionModel?> Function() fetchSubscription,
    required String targetPlanCode,
    VoidCallback? onActivated,
    VoidCallback? onTimeout,
  }) async {
    _timer?.cancel();
    _cancelled = false;
    _attempts = 0;
    _status = PollingStatus.polling;
    _statusMessage = 'Verifying payment with payment gateway...';
    notifyListeners();

    final normalizedTarget = targetPlanCode.toLowerCase();

    for (int i = 1; i <= maxAttempts; i++) {
      if (_cancelled) return;
      _attempts = i;
      _statusMessage = 'Checking plan activation (attempt $i of $maxAttempts)...';
      notifyListeners();

      try {
        final sub = await fetchSubscription();
        if (sub != null) {
          final isTargetPlan = sub.planCode.toLowerCase() == normalizedTarget;
          final isActive = sub.status.toLowerCase() == 'active';

          if (isTargetPlan && isActive) {
            _status = PollingStatus.active;
            _activatedSubscription = sub;
            _statusMessage =
                'Plan activated! You received ${sub.creditsLeft} credits.';
            notifyListeners();
            onActivated?.call();
            return;
          }
        }
      } catch (e) {
        debugPrint('Polling error on attempt $i: $e');
      }

      if (i < maxAttempts) {
        await Future.delayed(pollInterval); // allow-delay: polling interval for subscription activation webhook
      }
    }

    if (_cancelled) return;

    // Polling timed out (payment pending in webhook queue)
    _status = PollingStatus.timeout;
    _statusMessage =
        'Payment pending: Webhook is still processing your payment. Your credits will appear in your wallet shortly.';
    notifyListeners();
    onTimeout?.call();
  }

  void cancel() {
    _cancelled = true;
    _timer?.cancel();
    _status = PollingStatus.idle;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _cancelled = false;
    _status = PollingStatus.idle;
    _attempts = 0;
    _statusMessage = '';
    _activatedSubscription = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cancelled = true;
    super.dispose();
  }
}
