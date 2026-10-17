import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'safety_repository.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository();
});

final meTrustProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(safetyRepositoryProvider);
  return await repo.getMeTrust();
});
