import 'dart:async';
import 'dart:io';

import 'package:mobx/mobx.dart';

import '../../../core/utils/telemetry_csv_exporter.dart';
import '../../../domain/entities/ring_telemetry.dart';
import '../../../domain/repositories/ring_repository.dart';

class DashboardStore {
  final RingRepository ringRepository;

  DashboardStore({required this.ringRepository});

  final _isLoading = Observable<bool>(false);
  bool get isLoading => _isLoading.value;

  final _activeTelemetry = Observable<RingTelemetry?>(null);
  RingTelemetry? get activeTelemetry => _activeTelemetry.value;

  final _scannedDevices = ObservableList<RingDevice>();
  List<RingDevice> get scannedDevices => _scannedDevices;

  final _connectedDevice = Observable<RingDevice?>(null);
  RingDevice? get connectedDevice => _connectedDevice.value;

  final _diagnostics = Observable<HardwareDiagnostics?>(null);
  HardwareDiagnostics? get diagnostics => _diagnostics.value;

  final _recentPackets = ObservableList<RingTelemetry>();
  List<RingTelemetry> get recentPackets => _recentPackets;

  final _historicalPackets = ObservableList<RingTelemetry>();
  List<RingTelemetry> get historicalPackets => _historicalPackets;

  final _isExportingCsv = Observable<bool>(false);
  bool get isExportingCsv => _isExportingCsv.value;

  final _ecgBuffer = ObservableList<double>();
  List<double> get ecgBuffer => _ecgBuffer;

  final _readinessScore = Observable<int>(89);
  int get readinessScore => _readinessScore.value;

  StreamSubscription<RingTelemetry>? _telemetrySub;

  void initialize() {
    _startTelemetrySubscription();
    scanDevices();
    loadHistoricalTelemetry();
  }

  void _startTelemetrySubscription() {
    _telemetrySub?.cancel();
    _telemetrySub = ringRepository.watchTelemetry().listen((telemetry) {
      runInAction(() {
        _activeTelemetry.value = telemetry;

        // Maintain rolling ECG buffer (max 48 points)
        _ecgBuffer.addAll(telemetry.ecgSamples);
        while (_ecgBuffer.length > 48) {
          _ecgBuffer.removeAt(0);
        }

        // Maintain rolling packet log (max 15 packets)
        _recentPackets.insert(0, telemetry);
        if (_recentPackets.length > 15) {
          _recentPackets.removeLast();
        }

        // Dynamically compute readiness score (0-100)
        // High HRV and normal resting HR yield high readiness
        final hrvBonus = ((telemetry.hrv - 50) * 0.5).clamp(-10.0, 15.0);
        final hrPenalty = telemetry.heartRate > 85
            ? (telemetry.heartRate - 85) * 0.4
            : 0.0;
        final computed = (85.0 + hrvBonus - hrPenalty)
            .clamp(40.0, 99.0)
            .round();
        _readinessScore.value = computed;
      });
    });
  }

  Future<void> scanDevices() async {
    runInAction(() => _isLoading.value = true);
    try {
      final devices = await ringRepository.getDiscoveredDevices();
      runInAction(() {
        _scannedDevices.clear();
        _scannedDevices.addAll(devices);
        final connected = devices.where((d) => d.isConnected).firstOrNull;
        if (connected != null) {
          _connectedDevice.value = connected;
        } else if (devices.isNotEmpty && _connectedDevice.value == null) {
          _connectedDevice.value = devices.first;
        }
      });
    } finally {
      runInAction(() => _isLoading.value = false);
    }
  }

  Future<void> connectDevice(String deviceId, String sdkType) async {
    runInAction(() => _isLoading.value = true);
    try {
      await ringRepository.connectRing(deviceId, sdkType);
      await scanDevices();
    } finally {
      runInAction(() => _isLoading.value = false);
    }
  }

  Future<void> disconnectDevice() async {
    await ringRepository.disconnectRing();
    runInAction(() {
      _connectedDevice.value = null;
    });
    await scanDevices();
  }

  Future<void> runDiagnostics() async {
    runInAction(() => _isLoading.value = true);
    try {
      final result = await ringRepository.getHardwareDiagnostics();
      runInAction(() {
        _diagnostics.value = result;
      });
    } finally {
      runInAction(() => _isLoading.value = false);
    }
  }

  Future<void> setTelemetryInterval(int intervalMs) async {
    await ringRepository.updateTelemetryRate(intervalMs);
  }

  Future<List<RingTelemetry>> loadHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  }) async {
    try {
      final packets = await ringRepository.getHistoricalTelemetry(
        duration: duration,
      );
      runInAction(() {
        _historicalPackets.clear();
        _historicalPackets.addAll(packets);
      });
      return packets;
    } catch (_) {
      return [];
    }
  }

  Future<File> exportTelemetryCsv({
    bool includeEcg = true,
    bool fullHistory = true,
    String? customFileName,
  }) async {
    runInAction(() => _isExportingCsv.value = true);
    try {
      var packetsToExport = fullHistory
          ? List<RingTelemetry>.from(_historicalPackets)
          : List<RingTelemetry>.from(_recentPackets);
      if (packetsToExport.isEmpty) {
        if (_activeTelemetry.value != null) {
          packetsToExport = [_activeTelemetry.value!];
        } else {
          packetsToExport = await loadHistoricalTelemetry();
        }
      }

      return await TelemetryCsvExporter.writeCsvToFile(
        packetsToExport,
        customFileName: customFileName,
        includeEcgSamples: includeEcg,
      );
    } finally {
      runInAction(() => _isExportingCsv.value = false);
    }
  }

  void dispose() {
    _telemetrySub?.cancel();
  }
}
