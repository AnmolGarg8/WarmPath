import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import 'availability_models.dart';

class AvailabilityApiService {
  final Dio _dio;

  AvailabilityApiService([Dio? dio]) : _dio = dio ?? createDioClient();

  Future<AvailabilityData> getAvailability() async {
    final response = await _dio.get('/me/availability');
    return AvailabilityData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AvailabilityData> updateAvailability({
    required int weeklyCapacity,
    required String timezone,
    required List<TimeWindow> windows,
  }) async {
    final response = await _dio.put(
      '/me/availability',
      data: {
        'weekly_capacity': weeklyCapacity,
        'timezone': timezone,
        'windows': windows.map((w) => w.toJson()).toList(),
      },
    );
    return AvailabilityData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OnlineStatus> setOnline(int minutes) async {
    final response = await _dio.post(
      '/me/online',
      data: {'minutes': minutes},
    );
    return OnlineStatus.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OnlineStatus> setOffline() async {
    final response = await _dio.delete('/me/online');
    return OnlineStatus.fromJson(response.data as Map<String, dynamic>);
  }
}
