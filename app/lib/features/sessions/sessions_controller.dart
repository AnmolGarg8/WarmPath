import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sessions_api_service.dart';
import 'session_models.dart';

final sessionsApiServiceProvider = Provider<SessionsApiService>((ref) {
  return SessionsApiService();
});

class RequestsState {
  final bool isLoading;
  final List<MentorshipRequest> incoming;
  final List<MentorshipRequest> outgoing;
  final String? errorMessage;

  const RequestsState({
    this.isLoading = false,
    this.incoming = const [],
    this.outgoing = const [],
    this.errorMessage,
  });

  RequestsState copyWith({
    bool? isLoading,
    List<MentorshipRequest>? incoming,
    List<MentorshipRequest>? outgoing,
    String? errorMessage,
  }) {
    return RequestsState(
      isLoading: isLoading ?? this.isLoading,
      incoming: incoming ?? this.incoming,
      outgoing: outgoing ?? this.outgoing,
      errorMessage: errorMessage,
    );
  }
}

class RequestsNotifier extends StateNotifier<RequestsState> {
  final SessionsApiService _api;

  RequestsNotifier(this._api) : super(const RequestsState()) {
    loadRequests();
  }

  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final inc = await _api.listRequests(box: 'incoming');
      final out = await _api.listRequests(box: 'outgoing');
      state = state.copyWith(
        isLoading: false,
        incoming: inc,
        outgoing: out,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<CallSession?> acceptRequest(String id) async {
    try {
      final session = await _api.acceptRequest(id);
      await loadRequests();
      return session;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<void> declineRequest(String id, [String? reason]) async {
    try {
      await _api.declineRequest(id, reason);
      await loadRequests();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final requestsProvider = StateNotifierProvider<RequestsNotifier, RequestsState>((ref) {
  final api = ref.watch(sessionsApiServiceProvider);
  return RequestsNotifier(api);
});
