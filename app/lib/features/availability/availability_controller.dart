import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'availability_api_service.dart';
import 'availability_models.dart';

class AvailabilityState {
  final bool isLoading;
  final AvailabilityData? data;
  final OnlineStatus? onlineStatus;
  final String? errorMessage;
  final int onlineSecondsRemaining;

  const AvailabilityState({
    this.isLoading = false,
    this.data,
    this.onlineStatus,
    this.errorMessage,
    this.onlineSecondsRemaining = 0,
  });

  AvailabilityState copyWith({
    bool? isLoading,
    AvailabilityData? data,
    OnlineStatus? onlineStatus,
    String? errorMessage,
    int? onlineSecondsRemaining,
  }) {
    return AvailabilityState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      errorMessage: errorMessage,
      onlineSecondsRemaining: onlineSecondsRemaining ?? this.onlineSecondsRemaining,
    );
  }
}

final availabilityApiServiceProvider = Provider<AvailabilityApiService>((ref) {
  return AvailabilityApiService();
});

class AvailabilityNotifier extends StateNotifier<AvailabilityState> {
  final AvailabilityApiService _api;
  Timer? _countdownTimer;

  AvailabilityNotifier(this._api) : super(const AvailabilityState()) {
    loadAvailability();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> loadAvailability() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final avail = await _api.getAvailability();
      state = state.copyWith(isLoading: false, data: avail);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateCapacity(int newCapacity) async {
    if (state.data == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _api.updateAvailability(
        weeklyCapacity: newCapacity,
        timezone: state.data!.timezone,
        windows: state.data!.windows,
      );
      state = state.copyWith(isLoading: false, data: updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addWindow(TimeWindow window) async {
    if (state.data == null) return;
    final newWindows = List<TimeWindow>.from(state.data!.windows)..add(window);
    await _saveWindows(newWindows);
  }

  Future<void> removeWindow(int index) async {
    if (state.data == null) return;
    final newWindows = List<TimeWindow>.from(state.data!.windows)..removeAt(index);
    await _saveWindows(newWindows);
  }

  Future<void> _saveWindows(List<TimeWindow> windows) async {
    if (state.data == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _api.updateAvailability(
        weeklyCapacity: state.data!.weeklyCapacity,
        timezone: state.data!.timezone,
        windows: windows,
      );
      state = state.copyWith(isLoading: false, data: updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> goOnline(int minutes) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final status = await _api.setOnline(minutes);
      _startCountdown(status.remainingSeconds);
      state = state.copyWith(
        isLoading: false,
        onlineStatus: status,
        onlineSecondsRemaining: status.remainingSeconds,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> goOffline() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final status = await _api.setOffline();
      _countdownTimer?.cancel();
      state = state.copyWith(
        isLoading: false,
        onlineStatus: status,
        onlineSecondsRemaining: 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _startCountdown(int initialSeconds) {
    _countdownTimer?.cancel();
    int current = initialSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (current <= 1) {
        timer.cancel();
        state = state.copyWith(
          onlineStatus: OnlineStatus(
            userId: state.data?.userId ?? '',
            onlineNow: false,
            remainingSeconds: 0,
          ),
          onlineSecondsRemaining: 0,
        );
      } else {
        current--;
        state = state.copyWith(onlineSecondsRemaining: current);
      }
    });
  }
}

final availabilityProvider = StateNotifierProvider<AvailabilityNotifier, AvailabilityState>((ref) {
  final api = ref.watch(availabilityApiServiceProvider);
  return AvailabilityNotifier(api);
});
