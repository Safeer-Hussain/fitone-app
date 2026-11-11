import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/ring_telemetry.dart';

/// RFC-4180 Compliant CSV Telemetry Exporter for Sports Science & Biometric Analysis
class TelemetryCsvExporter {
  /// Test hook to override document storage directory during unit/widget testing
  static Directory? overrideExportDirectory;

  /// Standard CSV header definition
  static const List<String> csvHeaders = [
    'packet_id',
    'timestamp_utc',
    'timestamp_local',
    'device_id',
    'sdk',
    'heart_rate_bpm',
    'spo2_pct',
    'hrv_rmssd_ms',
    'skin_temp_delta_c',
    'sleep_stage',
    'step_count',
    'battery_pct',
    'signal_quality_pct',
    'checksum',
    'ecg_sample_count',
    'ecg_mean_mv',
    'ecg_samples',
  ];

  /// Escapes CSV values according to RFC-4180
  static String escapeCsvValue(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }

  /// Generates standard CSV formatted string from historical telemetry packets
  static String generateCsv(
    List<RingTelemetry> packets, {
    bool includeEcgSamples = true,
  }) {
    final buffer = StringBuffer();
    final localDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Header row
    buffer.writeln(csvHeaders.join(','));

    // Data rows
    for (final packet in packets) {
      final utcIso = packet.timestamp.toUtc().toIso8601String();
      final localFormatted = localDateFormat.format(packet.timestamp.toLocal());

      final samples = packet.ecgSamples;
      final sampleCount = samples.length;
      final meanMv = sampleCount > 0
          ? samples.reduce((a, b) => a + b) / sampleCount
          : 0.0;

      final ecgSamplesField = includeEcgSamples && sampleCount > 0
          ? samples.map((s) => s.toStringAsFixed(3)).join(';')
          : '';

      final row = [
        packet.packetId.toString(),
        escapeCsvValue(utcIso),
        escapeCsvValue(localFormatted),
        escapeCsvValue(packet.deviceId),
        escapeCsvValue(packet.sdk),
        packet.heartRate.toString(),
        packet.spo2.toString(),
        packet.hrv.toString(),
        packet.skinTempDelta.toStringAsFixed(2),
        escapeCsvValue(packet.sleepStage),
        packet.stepCount.toString(),
        packet.batteryLevel.toString(),
        packet.signalQuality.toString(),
        escapeCsvValue(packet.checksum),
        sampleCount.toString(),
        meanMv.toStringAsFixed(4),
        escapeCsvValue(ecgSamplesField),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Writes generated CSV string to device local document storage
  static Future<File> writeCsvToFile(
    List<RingTelemetry> packets, {
    String? customFileName,
    bool includeEcgSamples = true,
  }) async {
    final Directory directory;
    if (overrideExportDirectory != null) {
      directory = overrideExportDirectory!;
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    final timestampStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = customFileName ?? 'fitone_telemetry_$timestampStr.csv';
    final filePath = p.join(directory.path, fileName);
    final file = File(filePath);

    final csvContent = generateCsv(
      packets,
      includeEcgSamples: includeEcgSamples,
    );
    return await file.writeAsString(csvContent, flush: true);
  }

  /// Calculates statistical metadata summary for UI presentation
  static Map<String, dynamic> getExportMetadataSummary(
    List<RingTelemetry> packets,
  ) {
    if (packets.isEmpty) {
      return {
        'totalPackets': 0,
        'startTime': null,
        'endTime': null,
        'timeSpanFormatted': '0m',
        'avgHeartRate': 0,
        'minHeartRate': 0,
        'maxHeartRate': 0,
        'avgSpo2': 0.0,
        'avgHrv': 0,
        'avgSkinTempDelta': 0.0,
        'dominantSleepStage': 'N/A',
        'estimatedSizeBytes': 0,
        'fileName': 'fitone_telemetry_empty.csv',
      };
    }

    // Sort to determine true timeline bounds
    final sorted = List<RingTelemetry>.from(packets)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final start = sorted.first.timestamp;
    final end = sorted.last.timestamp;
    final duration = end.difference(start);

    final String timeSpanFormatted;
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final mins = duration.inMinutes % 60;
      timeSpanFormatted = '${hours}h ${mins}m';
    } else {
      timeSpanFormatted = '${duration.inMinutes}m';
    }

    var sumHr = 0;
    var minHr = sorted.first.heartRate;
    var maxHr = sorted.first.heartRate;
    var sumSpo2 = 0;
    var sumHrv = 0;
    var sumTempDelta = 0.0;
    final stageCounts = <String, int>{};

    for (final p in sorted) {
      sumHr += p.heartRate;
      if (p.heartRate < minHr) minHr = p.heartRate;
      if (p.heartRate > maxHr) maxHr = p.heartRate;
      sumSpo2 += p.spo2;
      sumHrv += p.hrv;
      sumTempDelta += p.skinTempDelta;

      stageCounts[p.sleepStage] = (stageCounts[p.sleepStage] ?? 0) + 1;
    }

    final n = sorted.length;
    final avgHr = (sumHr / n).round();
    final avgSpo2 = double.parse((sumSpo2 / n).toStringAsFixed(1));
    final avgHrv = (sumHrv / n).round();
    final avgTempDelta = double.parse((sumTempDelta / n).toStringAsFixed(2));

    var dominantStage = 'AWAKE';
    var maxCount = 0;
    stageCounts.forEach((stage, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantStage = stage;
      }
    });

    final timestampStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final defaultFileName = 'fitone_telemetry_$timestampStr.csv';

    // Estimate file size (~180 bytes per row without full ECG, ~320 with ECG)
    final estimatedSizeBytes = n * 240;

    return {
      'totalPackets': n,
      'startTime': start,
      'endTime': end,
      'timeSpanFormatted': timeSpanFormatted,
      'avgHeartRate': avgHr,
      'minHeartRate': minHr,
      'maxHeartRate': maxHr,
      'avgSpo2': avgSpo2,
      'avgHrv': avgHrv,
      'avgSkinTempDelta': avgTempDelta,
      'dominantSleepStage': dominantStage,
      'estimatedSizeBytes': estimatedSizeBytes,
      'fileName': defaultFileName,
    };
  }

  /// Verifies CSV string validity
  static bool validateCsv(String csvContent) {
    if (csvContent.trim().isEmpty) return false;
    final lines = csvContent.trim().split(RegExp(r'\r?\n'));
    if (lines.isEmpty) return false;

    // First line must match header
    final headerRow = lines.first.split(',');
    if (headerRow.length < csvHeaders.length) return false;

    for (var i = 0; i < csvHeaders.length; i++) {
      if (headerRow[i] != csvHeaders[i]) return false;
    }

    return true;
  }
}
