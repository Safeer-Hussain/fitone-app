import '../../domain/entities/ring_telemetry.dart';
import '../../domain/repositories/ring_repository.dart';
import '../datasources/native_ring_channel_data_source.dart';

class RingRepositoryImpl implements RingRepository {
  final NativeRingChannelDataSource dataSource;

  RingRepositoryImpl({required this.dataSource});

  @override
  Future<List<RingDevice>> getDiscoveredDevices() => dataSource.scanDevices();

  @override
  Future<void> connectRing(String deviceId, String sdkType) =>
      dataSource.connectDevice(deviceId, sdkType);

  @override
  Future<void> disconnectRing() => dataSource.disconnectDevice();

  @override
  Future<void> updateTelemetryRate(int intervalMs) =>
      dataSource.setTelemetryFrequency(intervalMs);

  @override
  Future<HardwareDiagnostics> getHardwareDiagnostics() =>
      dataSource.runHardwareDiagnostics();

  @override
  Stream<RingTelemetry> watchTelemetry() => dataSource.streamTelemetry();

  @override
  Future<List<RingTelemetry>> getHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  }) => dataSource.getHistoricalTelemetry(duration: duration);
}
