import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isNew;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.isNew = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? isNew,
    Map<String, dynamic>? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isNew: isNew ?? this.isNew,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
        return;
      }

      final cachedUser = await SecureStorageService.getUser();
      if (cachedUser != null) {
        state = state.copyWith(isAuthenticated: true, user: cachedUser);
      }

      final freshUser = await _repository.getMe();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: freshUser,
        errorMessage: null,
      );
    } catch (_) {
      // If fetching me fails, check if refresh worked or token invalid
      final token = await SecureStorageService.getAccessToken();
      if (token == null) {
        state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> requestOtp(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.requestOtp(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.verifyOtp(email, code);
      final isNew = result['is_new'] == true;
      final user = result['user'] as Map<String, dynamic>;

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isNew: isNew,
        user: user,
      );
      return isNew;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile({String? displayName, String? headline, String? avatarUrl}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.updateProfile(
        displayName: displayName,
        headline: headline,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(isLoading: false, user: updated, isNew: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = const AuthState(isLoading: false, isAuthenticated: false, user: null);
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteAccount();
      state = const AuthState(isLoading: false, isAuthenticated: false, user: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final verificationStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getVerificationStatus();
});
