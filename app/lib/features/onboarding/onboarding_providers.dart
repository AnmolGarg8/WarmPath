import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import 'onboarding_models.dart';
import 'onboarding_service.dart';

final onboardingDioProvider = Provider<Dio>((ref) {
  return createDioClient();
});

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final dio = ref.watch(onboardingDioProvider);
  return OnboardingService(dio: dio);
});

final resumeProfileProvider = FutureProvider.autoDispose<ResumeProfile>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  return service.getProfile();
});

final studentIntentProvider = FutureProvider.autoDispose<StudentIntent>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  return service.getIntent();
});
