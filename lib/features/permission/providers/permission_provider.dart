import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/permission/models/permission_model.dart';
import 'package:mobile_app/features/permission/services/permission_service.dart';

// --- FILTER STATE ---
class PermissionFilterState {
  final String? search;
  final String? status;
  final String? typeCode;
  final DateTime? startDate;
  final DateTime? endDate;

  const PermissionFilterState({
    this.search,
    this.status,
    this.typeCode,
    this.startDate,
    this.endDate,
  });

  bool get hasFilters =>
      (search != null && search!.isNotEmpty) ||
      status != null ||
      typeCode != null ||
      startDate != null ||
      endDate != null;

  int get activeFilterCount {
    int count = 0;
    if (search != null && search!.isNotEmpty) count++;
    if (status != null) count++;
    if (typeCode != null) count++;
    if (startDate != null || endDate != null) count++;
    return count;
  }

  PermissionFilterState copyWith({
    String? search,
    String? status,
    String? typeCode,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return PermissionFilterState(
      search: search ?? this.search,
      status: status ?? this.status,
      typeCode: typeCode ?? this.typeCode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class PermissionFilterNotifier extends StateNotifier<PermissionFilterState> {
  PermissionFilterNotifier() : super(const PermissionFilterState());

  void setAll({
    String? search,
    String? status,
    String? typeCode,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    state = PermissionFilterState(
      search: search ?? state.search,
      status: status ?? state.status,
      typeCode: typeCode ?? state.typeCode,
      startDate: startDate ?? state.startDate,
      endDate: endDate ?? state.endDate,
    );
  }

  void reset() {
    state = const PermissionFilterState();
  }
}

final permissionFilterProvider =
    StateNotifierProvider<PermissionFilterNotifier, PermissionFilterState>(
        (ref) {
  return PermissionFilterNotifier();
});

// --- LIST STATE ---
class PermissionListState {
  final List<PermissionModel> permissions;

  PermissionListState({
    this.permissions = const [],
  });
}

// Controller
class PermissionListNotifier
    extends StateNotifier<AsyncValue<PermissionListState>> {
  final Ref ref;
  final bool useFilters;

  PermissionListNotifier(this.ref, {this.useFilters = true})
      : super(const AsyncValue.loading()) {
    fetchPermissions();
  }

  Future<void> fetchPermissions() async {
    state = const AsyncValue.loading();
    try {
      final filter = useFilters
          ? ref.read(permissionFilterProvider)
          : const PermissionFilterState();

      // View All (History) needs more items, Home only needs recent few
      final limit = useFilters ? 100 : 10;

      final result = await PermissionService.getPermissions(
        limit: limit,
        search: filter.search,
        status: filter.status,
        type: filter.typeCode,
        startDate: filter.startDate,
        endDate: filter.endDate,
      );

      final listState = PermissionListState(
        permissions: result['data'] as List<PermissionModel>,
      );
      state = AsyncValue.data(listState);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await fetchPermissions();
  }

  Future<void> cancelPermission(String id) async {
    try {
      await PermissionService.deletePermission(id);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
}

// Internal provider for filtered list (History)
final _filteredPermissionListControllerProvider = StateNotifierProvider<
    PermissionListNotifier, AsyncValue<PermissionListState>>((ref) {
  return PermissionListNotifier(ref, useFilters: true);
});

// Internal provider for recent/unfiltered list (Home)
final _recentPermissionListControllerProvider = StateNotifierProvider<
    PermissionListNotifier, AsyncValue<PermissionListState>>((ref) {
  return PermissionListNotifier(ref, useFilters: false);
});

// Public Provider with Filters (For History Screen)
final permissionListProvider = StateNotifierProvider<PermissionListNotifier,
    AsyncValue<PermissionListState>>((ref) {
  // Listen to filter changes and re-fetch automatically
  ref.listen(permissionFilterProvider, (previous, next) {
    if (previous != next) {
      ref
          .read(_filteredPermissionListControllerProvider.notifier)
          .fetchPermissions();
    }
  });
  return ref.read(_filteredPermissionListControllerProvider.notifier);
});

// Public Provider without Filters (For Home Screen / Recent)
final recentPermissionsProvider = StateNotifierProvider<PermissionListNotifier,
    AsyncValue<PermissionListState>>((ref) {
  return ref.read(_recentPermissionListControllerProvider.notifier);
});
