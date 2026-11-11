import '../entities/ring_telemetry.dart';

abstract class RingRepository {
  Future<List<RingDevice>> getDiscoveredDevices();
  Future<void> connectRing(String deviceId, String sdkType);
  Future<void> disconnectRing();
  Future<void> updateTelemetryRate(int intervalMs);
  Future<HardwareDiagnostics> getHardwareDiagnostics();
  Stream<RingTelemetry> watchTelemetry();
  Future<List<RingTelemetry>> getHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  });
}
