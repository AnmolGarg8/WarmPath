import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import 'session_models.dart';

final sessionsApiServiceProvider = Provider<SessionsApiService>((ref) {
  return SessionsApiService();
});

class SessionsApiService {
  final Dio _dio;

  // In-memory demo state for seamless emulator presentation
  static final List<CallSession> _demoSessions = [
    CallSession(
      id: 'sess_aarav_live',
      requestId: 'req_demo_aarav',
      studentId: 'usr_student_demo',
      giverId: 'alumnus_aarav',
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      durationMinutes: 20,
      status: 'scheduled',
      roomUrl: 'https://meet.jit.si/warmpath-aarav-sharma-mentorship',
    ),
    CallSession(
      id: 'sess_sneha_done',
      requestId: 'req_demo_sneha',
      studentId: 'usr_student_demo',
      giverId: 'alumnus_sneha',
      scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
      durationMinutes: 20,
      status: 'completed',
      roomUrl: 'https://meet.jit.si/warmpath-sneha-patel-mentorship',
    ),
  ];

  static final List<MentorshipRequest> _demoRequests = [
    MentorshipRequest(
      id: 'req_incoming_aditya',
      studentId: 'usr_student_aditya',
      giverId: 'usr_student_demo',
      kind: 'instant',
      intentText: 'Seeking guidance on backend microservices architecture, FastAPI performance tuning, and campus placement interview advice.',
      priority: 1,
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    MentorshipRequest(
      id: 'req_outgoing_aarav',
      studentId: 'usr_student_demo',
      giverId: 'alumnus_aarav',
      kind: 'instant',
      intentText: 'Hi Aarav, looking for guidance on Azure cloud, systems programming, and referral tips for Microsoft campus placements.',
      priority: 2,
      status: 'accepted',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  static final List<ThreadMessage> _demoMessages = [
    ThreadMessage(
      id: 'msg_1',
      requestId: 'req_outgoing_aarav',
      senderId: 'usr_student_demo',
      content: 'Hello Aarav! Excited to connect regarding systems engineering and Azure roles.',
      safetyAction: 'allow',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ThreadMessage(
      id: 'msg_2',
      requestId: 'req_outgoing_aarav',
      senderId: 'alumnus_aarav',
      content: 'Hey Anmol! Reviewed your resume and projects. Let us hop on the video call to discuss Azure architecture and interview rounds.',
      safetyAction: 'allow',
      createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
  ];

  SessionsApiService([Dio? dio]) : _dio = dio ?? createDioClient();

  Future<MentorshipRequest> createRequest({
    required String giverId,
    required String kind,
    required String intentText,
    DateTime? slotStart,
    String? idempotencyKey,
  }) async {
    try {
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
    } catch (_) {
      final newReq = MentorshipRequest(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        studentId: 'usr_student_demo',
        giverId: giverId,
        kind: kind,
        intentText: intentText,
        priority: 1,
        status: 'pending',
        slotStart: slotStart,
        createdAt: DateTime.now(),
      );
      _demoRequests.insert(0, newReq);
      return newReq;
    }
  }

  Future<List<MentorshipRequest>> listRequests({
    String box = 'incoming',
    String? status,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{'box': box};
      if (status != null) query['status'] = status;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _dio.get('/requests', queryParameters: query);
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => MentorshipRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      if (box == 'incoming') {
        return _demoRequests.where((r) => r.giverId == 'usr_student_demo').toList();
      } else {
        return _demoRequests.where((r) => r.studentId == 'usr_student_demo').toList();
      }
    }
  }

  Future<MentorshipRequest> getRequest(String id) async {
    try {
      final response = await _dio.get('/requests/$id');
      return MentorshipRequest.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return _demoRequests.firstWhere(
        (r) => r.id == id,
        orElse: () => _demoRequests.first,
      );
    }
  }

  Future<CallSession> acceptRequest(String id) async {
    try {
      final response = await _dio.post('/requests/$id/accept');
      return CallSession.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      final idx = _demoRequests.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final req = _demoRequests[idx];
        _demoRequests[idx] = MentorshipRequest(
          id: req.id,
          studentId: req.studentId,
          giverId: req.giverId,
          kind: req.kind,
          intentText: req.intentText,
          priority: req.priority,
          status: 'accepted',
          slotStart: req.slotStart,
          createdAt: req.createdAt,
        );
      }
      final session = CallSession(
        id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
        requestId: id,
        studentId: 'usr_student_aditya',
        giverId: 'usr_student_demo',
        scheduledAt: DateTime.now().add(const Duration(minutes: 5)),
        durationMinutes: 20,
        status: 'scheduled',
        roomUrl: 'https://meet.jit.si/warmpath-session-$id',
      );
      _demoSessions.insert(0, session);
      return session;
    }
  }

  Future<MentorshipRequest> declineRequest(String id, [String? reason]) async {
    try {
      final response = await _dio.post(
        '/requests/$id/decline',
        data: {'reason': reason},
      );
      return MentorshipRequest.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      final idx = _demoRequests.indexWhere((r) => r.id == id);
      if (idx != -1) {
        final req = _demoRequests[idx];
        _demoRequests[idx] = MentorshipRequest(
          id: req.id,
          studentId: req.studentId,
          giverId: req.giverId,
          kind: req.kind,
          intentText: req.intentText,
          priority: req.priority,
          status: 'declined',
          slotStart: req.slotStart,
          createdAt: req.createdAt,
        );
        return _demoRequests[idx];
      }
      throw Exception('Request not found');
    }
  }

  Future<List<SlotItem>> getGiverSlots(String giverId, {String? from, String? to}) async {
    try {
      final query = <String, dynamic>{};
      if (from != null) query['from'] = from;
      if (to != null) query['to'] = to;

      final response = await _dio.get('/givers/$giverId/slots', queryParameters: query);
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => SlotItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      final now = DateTime.now();
      return [
        SlotItem(
          slotStart: DateTime(now.year, now.month, now.day, 16, 0),
          slotEnd: DateTime(now.year, now.month, now.day, 16, 20),
          available: true,
        ),
        SlotItem(
          slotStart: DateTime(now.year, now.month, now.day, 17, 30),
          slotEnd: DateTime(now.year, now.month, now.day, 17, 50),
          available: true,
        ),
        SlotItem(
          slotStart: DateTime(now.year, now.month, now.day + 1, 15, 0),
          slotEnd: DateTime(now.year, now.month, now.day + 1, 15, 20),
          available: true,
        ),
      ];
    }
  }

  Future<ThreadMessage> sendMessage(String requestId, String content) async {
    try {
      final response = await _dio.post(
        '/requests/$requestId/messages',
        data: {'content': content},
      );
      return ThreadMessage.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      final msg = ThreadMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        senderId: 'usr_student_demo',
        content: content,
        safetyAction: 'allow',
        createdAt: DateTime.now(),
      );
      _demoMessages.add(msg);
      return msg;
    }
  }

  Future<List<ThreadMessage>> getMessages(String requestId) async {
    try {
      final response = await _dio.get('/requests/$requestId/messages');
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => ThreadMessage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _demoMessages;
    }
  }

  Future<CallSession> joinSession(String sessionId) async {
    try {
      final response = await _dio.post('/sessions/$sessionId/join');
      return CallSession.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      final s = _demoSessions.firstWhere((e) => e.id == sessionId, orElse: () => _demoSessions.first);
      return s;
    }
  }

  Future<CallSession> leaveSession(String sessionId) async {
    try {
      final response = await _dio.post('/sessions/$sessionId/leave');
      return CallSession.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      final idx = _demoSessions.indexWhere((e) => e.id == sessionId);
      if (idx != -1) {
        final s = _demoSessions[idx];
        _demoSessions[idx] = CallSession(
          id: s.id,
          requestId: s.requestId,
          studentId: s.studentId,
          giverId: s.giverId,
          scheduledAt: s.scheduledAt,
          durationMinutes: s.durationMinutes,
          status: 'completed',
          roomUrl: s.roomUrl,
        );
        return _demoSessions[idx];
      }
      return _demoSessions.first;
    }
  }

  Future<CallSession> getSession(String sessionId) async {
    try {
      final response = await _dio.get('/sessions/$sessionId');
      return CallSession.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return _demoSessions.firstWhere((e) => e.id == sessionId, orElse: () => _demoSessions.first);
    }
  }

  Future<List<CallSession>> listMySessions() async {
    try {
      final response = await _dio.get('/me/sessions');
      final list = response.data as List<dynamic>? ?? [];
      return list.map((e) => CallSession.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _demoSessions;
    }
  }

  Future<void> registerDeviceToken(String fcmToken, [String platform = 'android']) async {
    try {
      await _dio.post(
        '/notifications/devices',
        data: {
          'fcm_token': fcmToken,
          'platform': platform,
        },
      );
    } catch (_) {}
  }
}
