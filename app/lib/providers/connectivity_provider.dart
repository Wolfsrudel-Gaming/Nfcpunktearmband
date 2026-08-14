import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_queue.dart';

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) => ConnectivityNotifier(),
);

class ConnectivityState {
  final bool isOnline;
  final int pendingActions;

  const ConnectivityState({this.isOnline = true, this.pendingActions = 0});

  ConnectivityState copyWith({bool? isOnline, int? pendingActions}) =>
      ConnectivityState(
        isOnline: isOnline ?? this.isOnline,
        pendingActions: pendingActions ?? this.pendingActions,
      );
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier() : super(const ConnectivityState()) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    state = state.copyWith(
      isOnline: online,
      pendingActions: OfflineQueue().length,
    );

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      state = state.copyWith(isOnline: online);
      if (online) {
        OfflineQueue().processQueue().then((_) {
          state = state.copyWith(pendingActions: OfflineQueue().length);
        });
      }
    });
  }

  void refreshPendingCount() {
    state = state.copyWith(pendingActions: OfflineQueue().length);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
