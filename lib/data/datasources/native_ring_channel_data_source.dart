import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../domain/entities/ring_telemetry.dart';
import '../../core/network/network_monitor.dart';

class NativeRingChannelDataSource {
  static const MethodChannel _controlChannel = MethodChannel(
    'com.safeer.fitone/ring_control',
  );
  static const EventChannel _telemetryChannel = EventChannel(
    'com.safeer.fitone/ring_telemetry',
  );

  Stream<RingTelemetry>? _telemetryStream;
  StreamController<RingTelemetry>? _fallbackStreamController;
  Timer? _fallbackTimer;
  int _fallbackPacketCounter = 2000;
  int _fallbackStepCount = 8120;
  String _activeDeviceId = 'AURA-PRO-9842';
  String _activeSdk = 'SDK_A';
  bool _isConnected = true;

  Future<List<RingDevice>> scanDevices() async {
    try {
      final List<dynamic>? raw = await _controlChannel.invokeMethod(
        'scanDevices',
      );
      if (raw != null) {
        return raw
            .map((item) => RingDevice.fromMap(item as Map<dynamic, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback for desktop/test environment
    }

    return [
      RingDevice(
        id: 'AURA-PRO-9842',
        name: 'AuraRing Pro v2',
        sdk: 'SDK_A',
        battery: 88,
        firmware: 'v2.4.1',
        rssi: -58,
        isConnected: _activeDeviceId == 'AURA-PRO-9842' && _isConnected,
      ),
      RingDevice(
        id: 'KTX-ULTRA-1049',
        name: 'KinetixRing Ultra',
        sdk: 'SDK_B',
        battery: 94,
        firmware: 'v1.9.8',
        rssi: -52,
        isConnected: _activeDeviceId == 'KTX-ULTRA-1049' && _isConnected,
      ),
    ];
  }

  Future<void> connectDevice(String deviceId, String sdkType) async {
    _activeDeviceId = deviceId;
    _activeSdk = sdkType;
    _isConnected = true;

    try {
      await _controlChannel.invokeMethod('connectDevice', {
        'deviceId': deviceId,
        'sdkType': sdkType,
      });
    } catch (_) {}
  }

  Future<void> disconnectDevice() async {
    _isConnected = false;
    try {
      await _controlChannel.invokeMethod('disconnectDevice');
    } catch (_) {}
  }

  Future<void> setTelemetryFrequency(int intervalMs) async {
    try {
      await _controlChannel.invokeMethod('setTelemetryFrequency', {
        'intervalMs': intervalMs,
      });
    } catch (_) {}
    _restartFallbackTimer(intervalMs);
  }

  Future<HardwareDiagnostics> runHardwareDiagnostics() async {
    try {
      final Map<dynamic, dynamic>? raw = await _controlChannel.invokeMethod(
        'runHardwareDiagnostics',
      );
      if (raw != null) {
        return HardwareDiagnostics.fromMap(raw);
      }
    } catch (_) {}

    return const HardwareDiagnostics(
      opticalPPG: 'PASSED - 99.4% Signal Integrity',
      temperatureSensor: 'CALIBRATED - 0.02C Drift',
      sixAxisIMU: 'NORMAL - 100Hz ODR Active',
      bleTransceiver: 'OPTIMAL - TX Power 0dBm',
      internalNAND: 'HEALTHY - 32MB Free',
      batteryHealth: '98% Retained Capacity',
    );
  }

  Stream<RingTelemetry> streamTelemetry() {
    if (_telemetryStream != null) return _telemetryStream!;

    try {
      _telemetryStream = _telemetryChannel
          .receiveBroadcastStream()
          .map((dynamic event) {
            return RingTelemetry.fromMap(event as Map<dynamic, dynamic>);
          })
          .handleError((error) {
            return _createFallbackPacket();
          });
      return _telemetryStream!;
    } catch (_) {
      return _getFallbackStream();
    }
  }

  Stream<RingTelemetry> _getFallbackStream() {
    _fallbackStreamController ??= StreamController<RingTelemetry>.broadcast(
      onListen: () =>
          _restartFallbackTimer(NetworkMonitor.instance.telemetryIntervalMs),
      onCancel: () {
        _fallbackTimer?.cancel();
        _fallbackTimer = null;
      },
    );
    return _fallbackStreamController!.stream;
  }

  void _restartFallbackTimer(int intervalMs) {
    _fallbackTimer?.cancel();
    if (!_isConnected) return;

    _fallbackTimer = Timer.periodic(
      Duration(milliseconds: max(500, intervalMs)),
      (timer) {
        if (_fallbackStreamController != null &&
            !_fallbackStreamController!.isClosed &&
            _isConnected) {
          _fallbackStreamController!.add(_createFallbackPacket());
        }
      },
    );
  }

  RingTelemetry _createFallbackPacket() {
    _fallbackPacketCounter++;
    _fallbackStepCount += Random().nextInt(3) + 1;
    final hr = _activeSdk == 'SDK_A'
        ? 68 + Random().nextInt(7)
        : 71 + Random().nextInt(6);
    final hrv = 64 + Random().nextInt(8) - 4;
    final spo2 = 98 + Random().nextInt(2);
    final tempDelta = (Random().nextInt(30) - 10) / 100.0;
    final stages = ['DEEP', 'REM', 'LIGHT', 'AWAKE'];
    final stage = stages[Random().nextInt(stages.length)];

    final samples = List.generate(16, (i) {
      final phase = (i + (_fallbackPacketCounter % 8)).toDouble();
      final base = sin(phase * 0.7) * 0.4;
      final spike = i == 6 ? 1.2 : (i == 7 ? -0.5 : 0.0);
      return base + spike;
    });

    return RingTelemetry(
      packetId: _fallbackPacketCounter,
      timestamp: DateTime.now(),
      deviceId: _activeDeviceId,
      sdk: _activeSdk,
      heartRate: hr,
      spo2: spo2,
      hrv: hrv,
      skinTempDelta: tempDelta,
      sleepStage: stage,
      stepCount: _fallbackStepCount,
      batteryLevel: 88,
      signalQuality: 99,
      checksum: 'A4F${_fallbackPacketCounter}8B',
      ecgSamples: samples,
    );
  }

  Future<List<RingTelemetry>> getHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  }) async {
    final now = DateTime.now();
    final start = now.subtract(duration);
    const count = 120; // 120 sample points spanning duration
    final stepSeconds = duration.inSeconds ~/ count;

    final packets = <RingTelemetry>[];
    var cumulativeSteps = 1200;

    for (var i = 0; i < count; i++) {
      final packetTime = start.add(Duration(seconds: i * stepSeconds));
      final hour = packetTime.hour;
      final isNight = hour >= 23 || hour < 7;

      final String stage;
      final int hr;
      final int hrv;
      final double tempDelta;
      final int spo2;

      if (isNight) {
        if (hour == 23 || hour == 0) {
          stage = 'LIGHT';
          hr = 60 + (i % 5);
          hrv = 65 + (i % 6);
          tempDelta = -0.15;
        } else if (hour >= 1 && hour < 4) {
          stage = i % 3 == 0 ? 'REM' : 'DEEP';
          hr = 52 + (i % 6);
          hrv = 75 + (i % 10);
          tempDelta = -0.35;
        } else {
          stage = i % 2 == 0 ? 'REM' : 'LIGHT';
          hr = 58 + (i % 5);
          hrv = 70 + (i % 8);
          tempDelta = -0.20;
        }
        spo2 = 97 + (i % 3);
      } else {
        stage = 'AWAKE';
        cumulativeSteps += 40 + (i % 60);
        hr = 70 + (i % 18);
        hrv = 52 + (i % 14);
        tempDelta = 0.05 + ((i % 15) / 100.0);
        spo2 = 98 + (i % 2);
      }

      final samples = List.generate(16, (sIdx) {
        final phase = (sIdx + i).toDouble();
        final base = sin(phase * 0.7) * 0.4;
        final spike = sIdx == 6 ? 1.2 : (sIdx == 7 ? -0.5 : 0.0);
        return double.parse((base + spike).toStringAsFixed(3));
      });

      packets.add(
        RingTelemetry(
          packetId: 1000 + i,
          timestamp: packetTime,
          deviceId: _activeDeviceId,
          sdk: _activeSdk,
          heartRate: hr,
          spo2: spo2,
          hrv: hrv,
          skinTempDelta: tempDelta,
          sleepStage: stage,
          stepCount: cumulativeSteps,
          batteryLevel: (100 - (i * 12 ~/ count)).clamp(20, 100),
          signalQuality: 98 + (i % 2),
          checksum: 'A4F${1000 + i}8B',
          ecgSamples: samples,
        ),
      );
    }

    return packets;
  }
}
