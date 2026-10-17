/// User subscription model and checkout response for WarmPath.
/// Owner: M4
library;

class UserSubscriptionModel {
  final String planCode; // campus, standard, high, premium
  final String planName;
  final String status; // active, created, authenticated, charged, cancelled, halted, pending
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final int creditsLeft;
  final DateTime? renewalDate;
  final bool active;
  final bool cancelAtPeriodEnd;

  const UserSubscriptionModel({
    required this.planCode,
    required this.planName,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    required this.creditsLeft,
    this.renewalDate,
    required this.active,
    this.cancelAtPeriodEnd = false,
  });

  bool get isPaidPlan => planCode.toLowerCase() != 'campus';

  String get plainStatus {
    if (cancelAtPeriodEnd) {
      return 'Cancelling at period end';
    }
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'authenticated':
      case 'created':
      case 'pending':
        return 'Payment Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'halted':
        return 'Payment On Hold';
      default:
        return status;
    }
  }

  String get plainRenewal {
    final date = renewalDate ?? currentPeriodEnd;
    if (date == null) return 'No renewal scheduled';
    final dateStr = '${date.day}/${date.month}/${date.year}';
    if (cancelAtPeriodEnd) {
      return 'Expires on $dateStr';
    }
    return 'Renews on $dateStr';
  }

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is int) {
        return DateTime.fromMillisecondsSinceEpoch(val * 1000);
      }
      return DateTime.tryParse(val.toString());
    }

    final code = json['plan_code']?.toString().toLowerCase() ?? 'campus';
    final name = json['plan_name']?.toString() ??
        (code == 'campus' ? 'Campus Free' : code.toUpperCase());

    return UserSubscriptionModel(
      planCode: code,
      planName: name,
      status: json['status']?.toString().toLowerCase() ?? 'active',
      currentPeriodStart: parseDate(json['current_period_start']),
      currentPeriodEnd: parseDate(json['current_period_end']),
      creditsLeft: (json['credits_left'] as num?)?.toInt() ??
          (json['credits_remaining'] as num?)?.toInt() ??
          0,
      renewalDate: parseDate(json['renewal_date'] ?? json['current_period_end']),
      active: json['active'] as bool? ?? (json['status'] == 'active'),
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
    );
  }

  static UserSubscriptionModel defaultCampus() {
    return const UserSubscriptionModel(
      planCode: 'campus',
      planName: 'Campus Free',
      status: 'active',
      creditsLeft: 0,
      active: true,
      cancelAtPeriodEnd: false,
    );
  }
}

class SubscriptionCheckoutResponse {
  final String subscriptionId;
  final String razorpayKeyId;
  final String? razorpaySubscriptionId;
  final String planCode;
  final int amountInr;
  final String status;
  final bool testMode;

  const SubscriptionCheckoutResponse({
    required this.subscriptionId,
    required this.razorpayKeyId,
    this.razorpaySubscriptionId,
    required this.planCode,
    required this.amountInr,
    required this.status,
    this.testMode = true,
  });

  factory SubscriptionCheckoutResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionCheckoutResponse(
      subscriptionId: json['subscription_id']?.toString() ??
          json['id']?.toString() ??
          '',
      razorpayKeyId: json['razorpay_key_id']?.toString() ??
          json['key_id']?.toString() ??
          'rzp_test_stub',
      razorpaySubscriptionId: json['razorpay_subscription_id']?.toString(),
      planCode: json['plan_code']?.toString().toLowerCase() ?? 'standard',
      amountInr: (json['amount_inr'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'created',
      testMode: json['test_mode'] as bool? ?? true,
    );
  }
}
