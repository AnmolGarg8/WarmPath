import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import 'session_models.dart';

class SessionsApiService {
  final Dio _dio;

  SessionsApiService([Dio? dio]) : _dio = dio ?? createDioClient();

  Future<MentorshipRequest> createRequest({
    required String giverId,
    required String kind,
    required String intentText,
    DateTime? slotStart,
    String? idempotencyKey,
  }) async {
    final headers = <String, dynamic>{};
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }

    final response = await _dio.post(
      '/requests',
      data: {
        'giver_id': giverId,
        'kind': kind,
        'intent_text': intentText,
        'slot_start': slotStart?.toIso8601String(),
      },
      options: Options(headers: headers),
    );
    return MentorshipRequest.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MentorshipRequest>> listRequests({
    String box = 'incoming',
    String? status,
    String? cursor,
  }) async {
    final query = <String, dynamic>{'box': box};
    if (status != null) query['status'] = status;
    if (cursor != null) query['cursor'] = cursor;

    final response = await _dio.get('/requests', queryParameters: query);
    final list = response.data as List<dynamic>? ?? [];
    return list.map((e) => MentorshipRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MentorshipRequest> getRequest(String id) async {
    final response = await _dio.get('/requests/\$id');
    return MentorshipRequest.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CallSession> acceptRequest(String id) async {
    final response = await _dio.post('/requests/\$id/accept');
    return CallSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MentorshipRequest> declineRequest(String id, [String? reason]) async {
    final response = await _dio.post(
      '/requests/\$id/decline',
      data: {'reason': reason},
    );
    return MentorshipRequest.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<SlotItem>> getGiverSlots(String giverId, {String? from, String? to}) async {
    final query = <String, dynamic>{};
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;

    final response = await _dio.get('/givers/\$giverId/slots', queryParameters: query);
    final list = response.data as List<dynamic>? ?? [];
    return list.map((e) => SlotItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ThreadMessage> sendMessage(String requestId, String content) async {
    final response = await _dio.post(
      '/requests/\$requestId/messages',
      data: {'content': content},
    );
    return ThreadMessage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ThreadMessage>> getMessages(String requestId) async {
    final response = await _dio.get('/requests/\$requestId/messages');
    final list = response.data as List<dynamic>? ?? [];
    return list.map((e) => ThreadMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CallSession> joinSession(String sessionId) async {
    final response = await _dio.post('/sessions/\$sessionId/join');
    return CallSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CallSession> leaveSession(String sessionId) async {
    final response = await _dio.post('/sessions/\$sessionId/leave');
    return CallSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CallSession> getSession(String sessionId) async {
    final response = await _dio.get('/sessions/\$sessionId');
    return CallSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CallSession>> listMySessions() async {
    final response = await _dio.get('/me/sessions');
    final list = response.data as List<dynamic>? ?? [];
    return list.map((e) => CallSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> registerDeviceToken(String fcmToken, [String platform = 'android']) async {
    await _dio.post(
      '/notifications/devices',
      data: {
        'fcm_token': fcmToken,
        'platform': platform,
      },
    );
  }
}
