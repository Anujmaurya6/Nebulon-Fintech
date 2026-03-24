import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { isConnected, isDisconnected }

class ConnectivityService extends Notifier<ConnectivityStatus> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ConnectivityStatus build() {
    // Note: build() should be synchronous, use ref.onDispose for cleanup
    _init();
    ref.onDispose(() => _subscription?.cancel());
    return ConnectivityStatus.isConnected; // Initial state
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      state = ConnectivityStatus.isDisconnected;
    } else {
      state = ConnectivityStatus.isConnected;
    }
  }

  bool get isConnected => state == ConnectivityStatus.isConnected;
}

final connectivityProvider = NotifierProvider<ConnectivityService, ConnectivityStatus>(ConnectivityService.new);
