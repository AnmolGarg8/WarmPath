import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/api/websocket_service.dart';
import 'auth_repository.dart';

/// Bridge between Riverpod auth state and GoRouter refreshListenable
class AuthNotifierBridge extends ChangeNotifier {
  static final AuthNotifierBridge instance = AuthNotifierBridge._();
  AuthNotifierBridge._();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(bool value) {
    if (_isAuthenticated != value) {
      _isAuthenticated = value;
      notifyListeners();
    }
  }
}

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
  final Ref? _ref;

  AuthNotifier(this._repository, [this._ref]) : super(const AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token == null || token.isEmpty) {
        AuthNotifierBridge.instance.setAuthenticated(false);
        state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
        return;
      }

      final cachedUser = await SecureStorageService.getUser();
      if (cachedUser != null) {
        AuthNotifierBridge.instance.setAuthenticated(true);
        state = state.copyWith(isAuthenticated: true, user: cachedUser);
      }

      final freshUser = await _repository.getMe();
      AuthNotifierBridge.instance.setAuthenticated(true);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: freshUser,
        errorMessage: null,
      );
    } catch (_) {
      final token = await SecureStorageService.getAccessToken();
      if (token == null) {
        AuthNotifierBridge.instance.setAuthenticated(false);
        state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
      } else {
        AuthNotifierBridge.instance.setAuthenticated(true);
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

      AuthNotifierBridge.instance.setAuthenticated(true);
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

  void _invalidateUserData() {
    if (_ref != null) {
      try {
        _ref.invalidate(verificationStatusProvider);
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    WebSocketService().disconnect();
    await _repository.logout();
    AuthNotifierBridge.instance.setAuthenticated(false);
    _invalidateUserData();
    state = const AuthState(isLoading: false, isAuthenticated: false, user: null);
  }

  void onSessionExpired() {
    WebSocketService().disconnect();
    AuthNotifierBridge.instance.setAuthenticated(false);
    _invalidateUserData();
    state = const AuthState(isLoading: false, isAuthenticated: false, user: null);
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    WebSocketService().disconnect();
    try {
      await _repository.deleteAccount();
      AuthNotifierBridge.instance.setAuthenticated(false);
      _invalidateUserData();
      state = const AuthState(isLoading: false, isAuthenticated: false, user: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

final verificationStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getVerificationStatus();
});
