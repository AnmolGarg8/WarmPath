import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/storage/secure_storage.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository({Dio? dio}) : _dio = dio ?? createDioClient();

  /// Step 1: Request 6-digit email OTP
  Future<void> requestOtp(String email) async {
    try {
      await _dio.post('/auth/request-otp', data: {'email': email.trim().toLowerCase()});
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Step 2: Verify OTP and save token pair
  Future<Map<String, dynamic>> verifyOtp(String email, String code) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      });

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      await SecureStorageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await SecureStorageService.saveUser(user);

      return data;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Retrieve current authenticated user profile
  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/me');
      final data = response.data as Map<String, dynamic>;
      await SecureStorageService.saveUser(data);
      return data;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Update basic profile attributes
  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? headline,
    String? avatarUrl,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (displayName != null) payload['display_name'] = displayName.trim();
      if (headline != null) payload['headline'] = headline.trim();
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl.trim();

      final response = await _dio.patch('/me', data: payload);
      final data = response.data as Map<String, dynamic>;
      await SecureStorageService.saveUser(data);
      return data;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Hard-delete user data under DPDP compliance
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/me');
      await SecureStorageService.clearAll();
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Export user personal data
  Future<Map<String, dynamic>> exportData() async {
    try {
      final response = await _dio.get('/me/data-export');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Query verification status and active badges
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final response = await _dio.get('/verification/status');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Submit a new identity verification request
  Future<Map<String, dynamic>> submitVerification({
    required String kind,
    required String evidenceText,
    List<String>? evidenceUrls,
    String? companyName,
    String? companyRegistration,
  }) async {
    try {
      final payload = <String, dynamic>{
        'kind': kind.toLowerCase(),
        'evidence_text': evidenceText.trim(),
      };
      if (evidenceUrls != null && evidenceUrls.isNotEmpty) {
        payload['evidence_urls'] = evidenceUrls;
      }
      if (companyName != null && companyName.isNotEmpty) {
        payload['company_name'] = companyName.trim();
      }
      if (companyRegistration != null && companyRegistration.isNotEmpty) {
        payload['company_registration'] = companyRegistration.trim();
      }

      final response = await _dio.post('/verification/submit', data: payload);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  /// Logout user and clear credentials
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await SecureStorageService.clearAll();
    }
  }
}
