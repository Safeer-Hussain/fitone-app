import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobx/mobx.dart';

class NetworkMonitor {
  static final NetworkMonitor instance = NetworkMonitor._internal();
  NetworkMonitor._internal();

  final _isOnline = Observable<bool>(true);
  bool get isOnline => _isOnline.value;

  final _simulatedLatencyMs = Observable<int>(850);
  int get simulatedLatencyMs => _simulatedLatencyMs.value;

  final _forceApiError = Observable<bool>(false);
  bool get forceApiError => _forceApiError.value;

  final _telemetryIntervalMs = Observable<int>(2000);
  int get telemetryIntervalMs => _telemetryIntervalMs.value;

  final _pendingMutationCount = Observable<int>(0);
  int get pendingMutationCount => _pendingMutationCount.value;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void initialize() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      runInAction(() {
        _isOnline.value = connected;
      });
    });
  }

  void setSimulatedLatency(int ms) {
    runInAction(() {
      _simulatedLatencyMs.value = ms;
    });
  }

  void setForceApiError(bool force) {
    runInAction(() {
      _forceApiError.value = force;
    });
  }

  void setTelemetryInterval(int ms) {
    runInAction(() {
      _telemetryIntervalMs.value = ms;
    });
  }

  void setManualOnlineState(bool online) {
    runInAction(() {
      _isOnline.value = online;
    });
  }

  void incrementPendingMutations() {
    runInAction(() {
      _pendingMutationCount.value++;
    });
  }

  void clearPendingMutations() {
    runInAction(() {
      _pendingMutationCount.value = 0;
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
