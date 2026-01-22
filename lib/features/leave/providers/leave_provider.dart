import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:mobile_app/features/leave/services/leave_service.dart';

// State class for leave list to hold both data and balance
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
  LeaveListNotifier() : super(const AsyncValue.loading()) {
    fetchLeaves();
  }

  Future<void> fetchLeaves() async {
    state = const AsyncValue.loading();
    try {
      final result = await LeaveService.getLeaves();
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
    // Retain previous data while loading if desired, or just load
    // state = const AsyncValue.loading();
    await fetchLeaves();
  }

  // Optimistic update for cancellation
  Future<void> cancelLeave(String id) async {
    final previousState = state;
    if (previousState.hasValue) {
      final current = previousState.value!;
      state = AsyncValue.data(current.copyWith(
        leaves: current.leaves.where((l) => l.id != id).toList(),
      ));
    }

    try {
      await LeaveService.cancelLeave(id);
      await refresh();
    } catch (e) {
      state = previousState; // Revert
      rethrow;
    }
  }
}

// Provider
final leaveListProvider =
    StateNotifierProvider<LeaveListNotifier, AsyncValue<LeaveListState>>((ref) {
  return LeaveListNotifier();
});
