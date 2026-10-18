/// API service for Plans, Subscriptions, Wallet ledger, and Earnings.
/// Owner: M4
library;

import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/plan_model.dart';
import '../models/subscription_model.dart';
import '../models/wallet_model.dart';
import '../models/earnings_model.dart';
import '../models/sponsored_seat_model.dart';

class PlansWalletApiService {
  final Dio _dio;

  PlansWalletApiService({Dio? dio}) : _dio = dio ?? createDioClient();

  /// Fetches available subscription plans from /plans
  Future<List<PlanModel>> getPlans() async {
    final response = await _dio.get('/plans');
    if (response.data is List) {
      return (response.data as List)
          .map((p) => PlanModel.fromJson(p as Map<String, dynamic>))
          .toList();
    } else if (response.data is Map && response.data['plans'] is List) {
      return (response.data['plans'] as List)
          .map((p) => PlanModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches current authenticated user active subscription from /me/subscription
  Future<UserSubscriptionModel> getSubscription() async {
    final response = await _dio.get('/me/subscription');
    if (response.data is Map<String, dynamic>) {
      return UserSubscriptionModel.fromJson(response.data as Map<String, dynamic>);
    } else if (response.data is Map) {
      return UserSubscriptionModel.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    }
    return UserSubscriptionModel.defaultCampus();
  }

  /// Creates a Razorpay checkout subscription in test mode via POST /subscriptions
  Future<SubscriptionCheckoutResponse> createSubscription(String planCode) async {
    final idempotencyKey =
        'sub_${planCode}_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';

    final response = await _dio.post(
      '/subscriptions',
      data: {'plan_code': planCode},
      options: Options(
        headers: {'Idempotency-Key': idempotencyKey},
      ),
    );

    if (response.data is Map<String, dynamic>) {
      return SubscriptionCheckoutResponse.fromJson(
          response.data as Map<String, dynamic>);
    } else if (response.data is Map) {
      return SubscriptionCheckoutResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map));
    }
    throw Exception('Invalid subscription checkout response from server');
  }

  /// Cancels subscription at cycle end via POST /subscriptions/cancel
  Future<Map<String, dynamic>> cancelSubscription({bool atPeriodEnd = true}) async {
    final response = await _dio.post(
      '/subscriptions/cancel',
      data: {'at_period_end': atPeriodEnd},
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    } else if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return {'status': 'cancelled'};
  }

  /// Fetches credit wallet balances and ledger transactions from /me/wallet
  Future<WalletModel> getWallet({String? cursor, int limit = 20}) async {
    final response = await _dio.get(
      '/me/wallet',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );

    if (response.data is Map<String, dynamic>) {
      return WalletModel.fromJson(response.data as Map<String, dynamic>);
    } else if (response.data is Map) {
      return WalletModel.fromJson(Map<String, dynamic>.from(response.data as Map));
    }
    return WalletModel.empty();
  }

  /// Fetches giver earnings, rating band share, and dispute hold metrics from /me/earnings
  Future<EarningsModel> getEarnings() async {
    final response = await _dio.get('/me/earnings');
    if (response.data is Map<String, dynamic>) {
      return EarningsModel.fromJson(response.data as Map<String, dynamic>);
    } else if (response.data is Map) {
      return EarningsModel.fromJson(Map<String, dynamic>.from(response.data as Map));
    }
    return EarningsModel.empty();
  }

  /// Submits cash-out request via POST /me/cashout
  Future<Map<String, dynamic>> requestCashout(num amountInr, {String upiId = 'giver@upi'}) async {
    final response = await _dio.post(
      '/me/cashout',
      data: {
        'amount_inr': amountInr,
        'upi_id': upiId,
      },
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    } else if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return {'status': 'requested', 'amount_inr': amountInr};
  }

  /// Donates credits to the student scholarship pool via POST /me/donate-credits
  Future<Map<String, dynamic>> donateCredits(int credits) async {
    final response = await _dio.post(
      '/me/donate-credits',
      data: {'credits': credits},
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    } else if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return {'donated_credits': credits, 'status': 'donated'};
  }

  /// Fetches sponsored seats available or granted from /sponsored-seats
  Future<List<SponsoredSeatModel>> getSponsoredSeats() async {
    final response = await _dio.get('/sponsored-seats');
    if (response.data is List) {
      return (response.data as List)
          .map((s) => SponsoredSeatModel.fromJson(s as Map<String, dynamic>))
          .toList();
    } else if (response.data is Map && response.data['seats'] is List) {
      return (response.data['seats'] as List)
          .map((s) => SponsoredSeatModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Claims an available sponsored seat via POST /sponsored-seats/{id}/claim
  Future<Map<String, dynamic>> claimSponsoredSeat(String seatId) async {
    final response = await _dio.post('/sponsored-seats/$seatId/claim');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    } else if (response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    return {'success': true};
  }

  /// Fetches giver band details and progression requirements from /me/band
  Future<Map<String, dynamic>?> getMeBand() async {
    try {
      final response = await _dio.get('/me/band');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (_) {
      // If user is not yet a verified giver or band not created, returns null gracefully
    }
    return null;
  }

  /// Fetches public configuration parameters including test_mode and dispute_minutes
  Future<Map<String, dynamic>> getPublicConfig() async {
    try {
      final response = await _dio.get('/config/public');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (_) {
      // Fallback
    }
    return {'test_mode': true, 'windows': {'dispute_minutes': 2880}};
  }
}

