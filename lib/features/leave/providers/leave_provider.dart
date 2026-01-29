import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:mobile_app/features/leave/services/leave_service.dart';

// --- FILTER STATE ---
class LeaveFilterState {
  final String? search;
  final String? status;
  final String? typeCode;
  final DateTime? startDate;
  final DateTime? endDate;

  const LeaveFilterState({
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

  LeaveFilterState copyWith({
    String? search,
    String? status,
    String? typeCode,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return LeaveFilterState(
      search: search ?? this.search,
      status: status ?? this.status,
      typeCode: typeCode ?? this.typeCode,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class LeaveFilterNotifier extends StateNotifier<LeaveFilterState> {
  LeaveFilterNotifier() : super(const LeaveFilterState());

  void setSearch(String query) {
    state = LeaveFilterState(
      search: query,
      status: state.status,
      typeCode: state.typeCode,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void setStatus(String? status) {
    state = LeaveFilterState(
      search: state.search,
      status: status,
      typeCode: state.typeCode,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void setType(String? typeCode) {
    state = LeaveFilterState(
      search: state.search,
      status: state.status,
      typeCode: typeCode,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = LeaveFilterState(
      search: state.search,
      status: state.status,
      typeCode: state.typeCode,
      startDate: start,
      endDate: end,
    );
  }

  void reset() {
    state = const LeaveFilterState();
  }
}

final leaveFilterProvider =
    StateNotifierProvider<LeaveFilterNotifier, LeaveFilterState>((ref) {
  return LeaveFilterNotifier();
});

// --- LIST STATE ---
class LeaveListState {
  final List<LeaveModel> leaves;
  final List<LeaveBalance> balances;

  LeaveListState({
    this.leaves = const [],
    this.balances = const [],
  });

  LeaveListState copyWith({
    List<LeaveModel>? leaves,
    List<LeaveBalance>? balances,
  }) {
    return LeaveListState(
      leaves: leaves ?? this.leaves,
      balances: balances ?? this.balances,
    );
  }
}

// Controller
class LeaveListNotifier extends StateNotifier<AsyncValue<LeaveListState>> {
  final Ref ref;
  final bool useFilters;

  LeaveListNotifier(this.ref, {this.useFilters = true})
      : super(const AsyncValue.loading()) {
    fetchLeaves();
  }

  Future<void> fetchLeaves() async {
    state = const AsyncValue.loading();
    try {
      final filter =
          useFilters ? ref.read(leaveFilterProvider) : const LeaveFilterState();

      // View All (History) needs more items, Home only needs recent few
      final limit = useFilters ? 100 : 10;

      final result = await LeaveService.getLeaves(
        limit: limit,
        search: filter.search,
        status: filter.status,
        type: filter.typeCode,
        startDate: filter.startDate,
        endDate: filter.endDate,
      );
      final leaveState = LeaveListState(
        leaves: result['data'] as List<LeaveModel>,
        balances: result['balance'] as List<LeaveBalance>,
      );
      state = AsyncValue.data(leaveState);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await fetchLeaves();
  }

  // Optimistic update for cancellation
  Future<void> cancelLeave(String id) async {
    try {
      await LeaveService.deleteLeave(id);
      await refresh();
    } catch (e) {
      rethrow;
    }
  }
}

// Internal provider for filtered list (History)
final _filteredLeaveListControllerProvider =
    StateNotifierProvider<LeaveListNotifier, AsyncValue<LeaveListState>>((ref) {
  return LeaveListNotifier(ref, useFilters: true);
});

// Internal provider for recent/unfiltered list (Home)
final _recentLeaveListControllerProvider =
    StateNotifierProvider<LeaveListNotifier, AsyncValue<LeaveListState>>((ref) {
  return LeaveListNotifier(ref, useFilters: false);
});

// Public Provider with Filters (For History Screen)
final leaveListProvider =
    StateNotifierProvider<LeaveListNotifier, AsyncValue<LeaveListState>>((ref) {
  // Listen to filter changes and re-fetch automatically
  ref.listen(leaveFilterProvider, (previous, next) {
    if (previous != next) {
      ref.read(_filteredLeaveListControllerProvider.notifier).fetchLeaves();
    }
  });
  return ref.read(_filteredLeaveListControllerProvider.notifier);
});

// Public Provider without Filters (For Home Screen / Recent)
final recentLeavesProvider =
    StateNotifierProvider<LeaveListNotifier, AsyncValue<LeaveListState>>((ref) {
  return ref.read(_recentLeaveListControllerProvider.notifier);
});
