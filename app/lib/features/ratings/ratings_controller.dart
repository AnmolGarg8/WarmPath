import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ratings_api_service.dart';
import 'rating_models.dart';

final ratingsApiServiceProvider = Provider<RatingsApiService>((ref) {
  return RatingsApiService();
});

class BandState {
  final bool isLoading;
  final GiverBandInfo? bandInfo;
  final String? errorMessage;

  const BandState({
    this.isLoading = false,
    this.bandInfo,
    this.errorMessage,
  });

  BandState copyWith({
    bool? isLoading,
    GiverBandInfo? bandInfo,
    String? errorMessage,
  }) {
    return BandState(
      isLoading: isLoading ?? this.isLoading,
      bandInfo: bandInfo ?? this.bandInfo,
      errorMessage: errorMessage,
    );
  }
}

class BandNotifier extends StateNotifier<BandState> {
  final RatingsApiService _api;

  BandNotifier(this._api) : super(const BandState()) {
    loadBandInfo();
  }

  Future<void> loadBandInfo() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final info = await _api.getMeBand();
      state = state.copyWith(isLoading: false, bandInfo: info);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final bandProvider = StateNotifierProvider<BandNotifier, BandState>((ref) {
  final api = ref.watch(ratingsApiServiceProvider);
  return BandNotifier(api);
});
