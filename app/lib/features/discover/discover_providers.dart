import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import 'discover_models.dart';
import 'discover_service.dart';

final discoverDioProvider = Provider<Dio>((ref) {
  return createDioClient();
});

final discoverServiceProvider = Provider<DiscoverService>((ref) {
  final dio = ref.watch(discoverDioProvider);
  return DiscoverService(dio: dio);
});

final recommendationsScopeProvider = StateProvider<String>((ref) => 'own_college');

final recommendationsProvider = FutureProvider.autoDispose<RecommendationsResponse>((ref) async {
  final service = ref.watch(discoverServiceProvider);
  final scope = ref.watch(recommendationsScopeProvider);
  return service.getRecommendations(scope: scope);
});
