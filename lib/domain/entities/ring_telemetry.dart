class RingTelemetry {
  final int packetId;
  final DateTime timestamp;
  final String deviceId;
  final String sdk;
  final int heartRate;
  final int spo2;
  final int hrv;
  final double skinTempDelta;
  final String sleepStage;
  final int stepCount;
  final int batteryLevel;
  final int signalQuality;
  final String checksum;
  final List<double> ecgSamples;

  const RingTelemetry({
    required this.packetId,
    required this.timestamp,
    required this.deviceId,
    required this.sdk,
    required this.heartRate,
    required this.spo2,
    required this.hrv,
    required this.skinTempDelta,
    required this.sleepStage,
    required this.stepCount,
    required this.batteryLevel,
    required this.signalQuality,
    required this.checksum,
    required this.ecgSamples,
  });

  factory RingTelemetry.fromMap(Map<dynamic, dynamic> map) {
    final rawSamples = map['ecgSamples'] as List<dynamic>? ?? [];
    final samples = rawSamples.map((e) => (e as num).toDouble()).toList();

    return RingTelemetry(
      packetId: (map['packetId'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      deviceId: map['deviceId'] as String? ?? 'UNKNOWN',
      sdk: map['sdk'] as String? ?? 'SDK_A',
      heartRate: (map['heartRate'] as num?)?.toInt() ?? 72,
      spo2: (map['spo2'] as num?)?.toInt() ?? 98,
      hrv: (map['hrv'] as num?)?.toInt() ?? 65,
      skinTempDelta: (map['skinTempDelta'] as num?)?.toDouble() ?? 0.0,
      sleepStage: map['sleepStage'] as String? ?? 'AWAKE',
      stepCount: (map['stepCount'] as num?)?.toInt() ?? 7800,
      batteryLevel: (map['batteryLevel'] as num?)?.toInt() ?? 88,
      signalQuality: (map['signalQuality'] as num?)?.toInt() ?? 99,
      checksum: map['checksum'] as String? ?? '',
      ecgSamples: samples,
    );
  }
}

class RingDevice {
  final String id;
  final String name;
  final String sdk;
  final int battery;
  final String firmware;
  final int rssi;
  final bool isConnected;

  const RingDevice({
    required this.id,
    required this.name,
    required this.sdk,
    required this.battery,
    required this.firmware,
    required this.rssi,
    required this.isConnected,
  });

  factory RingDevice.fromMap(Map<dynamic, dynamic> map) {
    return RingDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      sdk: map['sdk'] as String? ?? 'SDK_A',
      battery: (map['battery'] as num?)?.toInt() ?? 100,
      firmware: map['firmware'] as String? ?? 'v1.0.0',
      rssi: (map['rssi'] as num?)?.toInt() ?? -60,
      isConnected: map['connected'] as bool? ?? false,
    );
  }
}

class HardwareDiagnostics {
  final String opticalPPG;
  final String temperatureSensor;
  final String sixAxisIMU;
  final String bleTransceiver;
  final String internalNAND;
  final String batteryHealth;

  const HardwareDiagnostics({
    required this.opticalPPG,
    required this.temperatureSensor,
    required this.sixAxisIMU,
    required this.bleTransceiver,
    required this.internalNAND,
    required this.batteryHealth,
  });

  factory HardwareDiagnostics.fromMap(Map<dynamic, dynamic> map) {
    return HardwareDiagnostics(
      opticalPPG: map['opticalPPG'] as String? ?? 'Normal',
      temperatureSensor: map['temperatureSensor'] as String? ?? 'Normal',
      sixAxisIMU: map['sixAxisIMU'] as String? ?? 'Normal',
      bleTransceiver: map['bleTransceiver'] as String? ?? 'Normal',
      internalNAND: map['internalNAND'] as String? ?? 'Normal',
      batteryHealth: map['batteryHealth'] as String? ?? 'Optimal',
    );
  }
}
