import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sessions_api_service.dart';

class PushNotificationService {
  final SessionsApiService _api;

  PushNotificationService(this._api);

  Future<void> registerDevice(String fcmToken, [String platform = 'android']) async {
    try {
      await _api.registerDeviceToken(fcmToken, platform);
    } catch (_) {}
  }

  void handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final requestId = data['request_id']?.toString();
    final sessionId = data['session_id']?.toString();

    if (type == 'new_request' || type == 'request_accepted' || type == 'request_declined') {
      // route to inbox or request detail
    } else if (type == 'session_starting' && sessionId != null) {
      // route to session call
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final api = ref.watch(sessionsApiServiceProvider);
  return PushNotificationService(api);
});
