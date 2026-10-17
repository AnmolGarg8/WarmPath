/// Models for subscription plans in WarmPath.
/// Owner: M4
library;

class PlanModel {
  final String id;
  final String code; // campus, standard, high, premium
  final String name;
  final int priceInr;
  final int creditsPerMonth;
  final List<String> reachBands;
  final int bookingHorizonDays;
  final int priority;
  final List<String> features;
  final bool active;

  const PlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.priceInr,
    required this.creditsPerMonth,
    required this.reachBands,
    required this.bookingHorizonDays,
    required this.priority,
    required this.features,
    this.active = true,
  });

  bool get isFree => priceInr == 0;

  String get plainReach {
    switch (code.toLowerCase()) {
      case 'campus':
        return 'Own college alumni only (100% Free)';
      case 'standard':
        return 'Rising alumni mentors across all colleges';
      case 'high':
        return 'Rising & Trusted alumni mentors across colleges';
      case 'premium':
        return 'All alumni mentors, recruiters, founders, faculty & experts';
      default:
        return reachBands.join(', ');
    }
  }

  String get plainBookingHorizon {
    if (bookingHorizonDays <= 0) return 'Instant connect';
    return '$bookingHorizonDays days in advance';
  }

  String get plainPriority {
    switch (priority) {
      case 3:
        return 'VIP Priority (3x faster responses)';
      case 2:
        return 'High Priority (2x faster responses)';
      default:
        return 'Standard Priority';
    }
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id']?.toString() ?? json['code']?.toString() ?? '',
      code: json['code']?.toString().toLowerCase() ?? 'standard',
      name: json['name']?.toString() ?? 'Plan',
      priceInr: (json['price_inr'] as num?)?.toInt() ?? 0,
      creditsPerMonth: (json['credits_per_month'] as num?)?.toInt() ?? (json['credits'] as num?)?.toInt() ?? 0,
      reachBands: (json['reach_bands'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      bookingHorizonDays: (json['booking_horizon_days'] as num?)?.toInt() ?? 7,
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      active: json['active'] as bool? ?? true,
    );
  }

  static List<PlanModel> defaultPlans() {
    return const [
      PlanModel(
        id: 'plan_campus',
        code: 'campus',
        name: 'Campus',
        priceInr: 0,
        creditsPerMonth: 0,
        reachBands: ['Rising'],
        bookingHorizonDays: 0,
        priority: 1,
        features: [
          'Unlimited own-college alumni mentorship',
          'Instant messaging & slot booking',
          'Always 100% Free on campus',
        ],
      ),
      PlanModel(
        id: 'plan_standard',
        code: 'standard',
        name: 'Standard',
        priceInr: 299,
        creditsPerMonth: 1,
        reachBands: ['Rising'],
        bookingHorizonDays: 3,
        priority: 1,
        features: [
          '1 Cross-College Credit per month',
          'Reach Rising alumni mentors anywhere',
          '3-day advance booking window',
          'Own-college access remains 100% free',
        ],
      ),
      PlanModel(
        id: 'plan_high',
        code: 'high',
        name: 'High',
        priceInr: 499,
        creditsPerMonth: 2,
        reachBands: ['Rising', 'Trusted'],
        bookingHorizonDays: 14,
        priority: 2,
        features: [
          '2 Cross-College Credits per month',
          'Reach Rising & Trusted rating bands',
          '14-day advance booking window',
          'High priority queue placement',
          'Own-college access remains 100% free',
        ],
      ),
      PlanModel(
        id: 'plan_premium',
        code: 'premium',
        name: 'Premium',
        priceInr: 899,
        creditsPerMonth: 4,
        reachBands: ['Rising', 'Trusted', 'Top Rated'],
        bookingHorizonDays: 30,
        priority: 3,
        features: [
          '4 Cross-College Credits per month',
          'Reach Top-Rated alumni, Recruiters, Founders & Experts',
          '30-day advance booking window',
          'VIP Priority inbox delivery',
          'Dedicated dispute protection',
          'Own-college access remains 100% free',
        ],
      ),
    ];
  }
}
