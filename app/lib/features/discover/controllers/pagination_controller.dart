import 'package:flutter/foundation.dart';
import '../models/discover_models.dart';
import '../services/discover_service.dart';

class PaginationController extends ChangeNotifier {
  final DiscoverService service;
  final String scope;

  List<RecommendationItemData> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? error;
  String? nextCursor;
  bool isLocked = false;
  String? lockReason;

  PaginationController({
    required this.service,
    required this.scope,
  });

  Future<void> loadInitial({String? filterDomain, String? filterHelpType}) async {
    isLoading = true;
    error = null;
    items = [];
    nextCursor = null;
    hasMore = true;
    notifyListeners();

    try {
      final res = await service.getRecommendations(
        scope: scope,
        limit: 10,
        filterDomain: filterDomain,
        filterHelpType: filterHelpType,
      );

      items = res.items;
      nextCursor = res.nextCursor;
      hasMore = res.nextCursor != null;
      isLocked = res.locked;
      lockReason = res.lockReason;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMore({String? filterDomain, String? filterHelpType}) async {
    if (isLoadingMore || !hasMore || nextCursor == null) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final res = await service.getRecommendations(
        scope: scope,
        limit: 10,
        cursor: nextCursor,
        filterDomain: filterDomain,
        filterHelpType: filterHelpType,
      );

      items.addAll(res.items);
      nextCursor = res.nextCursor;
      hasMore = res.nextCursor != null;
      isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      isLoadingMore = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh({String? filterDomain, String? filterHelpType}) async {
    await loadInitial(filterDomain: filterDomain, filterHelpType: filterHelpType);
  }
}
