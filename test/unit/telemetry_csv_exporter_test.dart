import 'dart:io';

import 'package:fitone/core/utils/telemetry_csv_exporter.dart';
import 'package:fitone/domain/entities/ring_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelemetryCsvExporter Unit Tests', () {
    late Directory tempDir;
    late List<RingTelemetry> samplePackets;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fitone_csv_test_');
      TelemetryCsvExporter.overrideExportDirectory = tempDir;

      final baseTime = DateTime.utc(2026, 11, 11, 0, 0, 0);
      samplePackets = [
        RingTelemetry(
          packetId: 1001,
          timestamp: baseTime,
          deviceId: 'AURA-PRO-9842',
          sdk: 'SDK_A',
          heartRate: 54,
          spo2: 98,
          hrv: 78,
          skinTempDelta: -0.32,
          sleepStage: 'DEEP',
          stepCount: 3000,
          batteryLevel: 90,
          signalQuality: 99,
          checksum: 'A4F10018B',
          ecgSamples: const [0.12, 0.45, 1.25, -0.50, 0.05],
        ),
        RingTelemetry(
          packetId: 1002,
          timestamp: baseTime.add(const Duration(minutes: 30)),
          deviceId: 'AURA-PRO-9842',
          sdk: 'SDK_A',
          heartRate: 60,
          spo2: 97,
          hrv: 70,
          skinTempDelta: -0.20,
          sleepStage: 'REM',
          stepCount: 3000,
          batteryLevel: 89,
          signalQuality: 98,
          checksum: 'A4F10028B',
          ecgSamples: const [0.10, 0.40, 1.10, -0.45, 0.02],
        ),
        RingTelemetry(
          packetId: 1003,
          timestamp: baseTime.add(const Duration(hours: 2)),
          deviceId: 'AURA, "Special" Ring',
          sdk: 'SDK_B',
          heartRate: 72,
          spo2: 99,
          hrv: 56,
          skinTempDelta: 0.15,
          sleepStage: 'AWAKE',
          stepCount: 4500,
          batteryLevel: 88,
          signalQuality: 99,
          checksum: 'A4F10038B',
          ecgSamples: const [0.05, 0.20, 0.90, -0.30, 0.00],
        ),
      ];
    });

    tearDown(() {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
      TelemetryCsvExporter.overrideExportDirectory = null;
    });

    test('RFC-4180 CSV Header and Value Generation', () {
      final csv = TelemetryCsvExporter.generateCsv(
        samplePackets,
        includeEcgSamples: true,
      );
      expect(TelemetryCsvExporter.validateCsv(csv), isTrue);

      final lines = csv.trim().split(RegExp(r'\r?\n'));
      expect(lines.length, equals(4)); // Header + 3 rows

      // Check header columns
      final header = lines[0];
      expect(header, contains('packet_id'));
      expect(header, contains('timestamp_utc'));
      expect(header, contains('heart_rate_bpm'));
      expect(header, contains('spo2_pct'));
      expect(header, contains('hrv_rmssd_ms'));
      expect(header, contains('skin_temp_delta_c'));
      expect(header, contains('sleep_stage'));
      expect(header, contains('ecg_samples'));

      // Check escaping on deviceId containing comma and quotes
      expect(lines[3], contains('"AURA, ""Special"" Ring"'));

      // Check packet row 1 values
      final row1 = lines[1];
      expect(row1, contains('1001'));
      expect(row1, contains('54'));
      expect(row1, contains('98'));
      expect(row1, contains('78'));
      expect(row1, contains('-0.32'));
      expect(row1, contains('DEEP'));
      expect(row1, contains('0.120;0.450;1.250;-0.500;0.050'));
    });

    test('Exclusion of raw ECG waveform samples', () {
      final csv = TelemetryCsvExporter.generateCsv(
        samplePackets,
        includeEcgSamples: false,
      );
      final lines = csv.trim().split(RegExp(r'\r?\n'));
      expect(lines.length, equals(4));

      // Semicolon sample arrays should not be present in the last column
      for (var i = 1; i < lines.length; i++) {
        expect(lines[i].endsWith(','), isTrue);
      }
    });

    test('Metadata summary calculation', () {
      final summary = TelemetryCsvExporter.getExportMetadataSummary(
        samplePackets,
      );

      expect(summary['totalPackets'], equals(3));
      expect(summary['minHeartRate'], equals(54));
      expect(summary['maxHeartRate'], equals(72));
      expect(summary['avgHeartRate'], equals(62)); // (54 + 60 + 72) / 3 = 62
      expect(summary['avgSpo2'], equals(98.0)); // (98 + 97 + 99) / 3 = 98.0
      expect(summary['avgHrv'], equals(68)); // (78 + 70 + 56) / 3 = 68
      expect(summary['timeSpanFormatted'], equals('2h 0m'));
      expect(summary['fileName'], contains('fitone_telemetry_'));
    });

    test('Empty packet list metadata handling', () {
      final summary = TelemetryCsvExporter.getExportMetadataSummary([]);
      expect(summary['totalPackets'], equals(0));
      expect(summary['avgHeartRate'], equals(0));
      expect(summary['dominantSleepStage'], equals('N/A'));
    });

    test('File export writes valid CSV to disk', () async {
      final file = await TelemetryCsvExporter.writeCsvToFile(
        samplePackets,
        customFileName: 'test_telemetry_export.csv',
        includeEcgSamples: true,
      );

      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('test_telemetry_export.csv'), isTrue);

      final content = await file.readAsString();
      expect(TelemetryCsvExporter.validateCsv(content), isTrue);
      expect(content, contains('1001'));
      expect(content, contains('AURA-PRO-9842'));
    });

    test('validateCsv correctly identifies valid and invalid CSV content', () {
      expect(TelemetryCsvExporter.validateCsv(''), isFalse);
      expect(TelemetryCsvExporter.validateCsv('random,text,here'), isFalse);

      final validCsv = TelemetryCsvExporter.generateCsv(samplePackets);
      expect(TelemetryCsvExporter.validateCsv(validCsv), isTrue);
    });
  });
}
