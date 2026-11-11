import 'dart:async';

import 'package:fitone/domain/entities/ring_telemetry.dart';
import 'package:fitone/domain/repositories/ring_repository.dart';
import 'package:fitone/presentation/dashboard/stores/dashboard_store.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRingRepository implements RingRepository {
  final StreamController<RingTelemetry> controller =
      StreamController<RingTelemetry>.broadcast();

  @override
  Future<List<RingDevice>> getDiscoveredDevices() async => [
    const RingDevice(
      id: 'AURA-PRO-9842',
      name: 'AuraRing Pro v2',
      sdk: 'SDK_A',
      battery: 88,
      firmware: 'v2.4.1',
      rssi: -58,
      isConnected: true,
    ),
  ];

  @override
  Future<void> connectRing(String deviceId, String sdkType) async {}

  @override
  Future<void> disconnectRing() async {}

  @override
  Future<HardwareDiagnostics> getHardwareDiagnostics() async =>
      const HardwareDiagnostics(
        opticalPPG: 'PASSED',
        temperatureSensor: 'PASSED',
        sixAxisIMU: 'NORMAL',
        bleTransceiver: 'OPTIMAL',
        internalNAND: 'HEALTHY',
        batteryHealth: '98%',
      );

  @override
  Future<void> updateTelemetryRate(int intervalMs) async {}

  @override
  Stream<RingTelemetry> watchTelemetry() => controller.stream;

  @override
  Future<List<RingTelemetry>> getHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  }) async => [
    RingTelemetry(
      packetId: 101,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      deviceId: 'AURA-PRO-9842',
      sdk: 'SDK_A',
      heartRate: 58,
      spo2: 98,
      hrv: 72,
      skinTempDelta: -0.2,
      sleepStage: 'DEEP',
      stepCount: 4200,
      batteryLevel: 85,
      signalQuality: 99,
      checksum: 'A4F1018B',
      ecgSamples: const [0.1, 0.2, 0.5, 1.2, -0.4, 0.0],
    ),
    RingTelemetry(
      packetId: 102,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      deviceId: 'AURA-PRO-9842',
      sdk: 'SDK_A',
      heartRate: 64,
      spo2: 99,
      hrv: 68,
      skinTempDelta: 0.1,
      sleepStage: 'AWAKE',
      stepCount: 7800,
      batteryLevel: 82,
      signalQuality: 98,
      checksum: 'A4F1028B',
      ecgSamples: const [0.2, 0.3, 0.6, 1.1, -0.3, 0.1],
    ),
  ];
}

void main() {
  group('MobX DashboardStore State & Telemetry Integration Tests', () {
    late FakeRingRepository repository;
    late DashboardStore store;

    setUp(() {
      repository = FakeRingRepository();
      store = DashboardStore(ringRepository: repository);
      store.initialize();
    });

    tearDown(() {
      store.dispose();
      repository.controller.close();
    });

    test('Initializes with default readiness and scans devices', () async {
      await Future.delayed(const Duration(milliseconds: 50));
      expect(store.readinessScore, equals(89));
      expect(store.scannedDevices.length, equals(1));
      expect(store.connectedDevice?.name, equals('AuraRing Pro v2'));
    });

    test('Receiving telemetry updates activeTelemetry, ECG buffer, and computes dynamic readiness', () async {
      final packet = RingTelemetry(
        packetId: 501,
        timestamp: DateTime.now(),
        deviceId: 'AURA-PRO-9842',
        sdk: 'SDK_A',
        heartRate: 65,
        spo2: 99,
        hrv: 78, // High HRV should trigger high readiness
        skinTempDelta: 0.1,
        sleepStage: 'DEEP',
        stepCount: 9200,
        batteryLevel: 85,
        signalQuality: 99,
        checksum: 'CRC123',
        ecgSamples: [0.2, 0.5, 1.1],
      );

      repository.controller.add(packet);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(store.activeTelemetry?.packetId, equals(501));
      expect(store.activeTelemetry?.heartRate, equals(65));
      expect(store.ecgBuffer.length, equals(3));
      expect(store.recentPackets.first.packetId, equals(501));
      // Readiness computation with high HRV (78ms) should be high (>= 90)
      expect(store.readinessScore, greaterThanOrEqualTo(90));
    });
  });
}
