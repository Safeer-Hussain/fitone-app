import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitone/core/utils/gpx_exporter.dart';
import 'package:fitone/domain/entities/run_record.dart';

void main() {
  group('GpxExporter Unit Tests', () {
    final testStartTime = DateTime.utc(2026, 11, 6, 14, 30, 0);

    final standardRun = RunRecord(
      id: 'run_test_01',
      title: 'Lahore Canal Tempo Run',
      startTime: testStartTime,
      durationSeconds: 1200,
      distanceKm: 5.0,
      avgPaceSecPerKm: 240,
      elevationGainM: 18.5,
      caloriesBurned: 350.0,
      avgHeartRate: 156,
      coordinates: const [
        RunCoordinate(31.5204, 74.3587, elevation: 215.0, heartRate: 145),
        RunCoordinate(31.5248, 74.3628, elevation: 222.0, heartRate: 155),
        RunCoordinate(31.5302, 74.3680, elevation: 233.5, heartRate: 162),
      ],
      splits: const [
        RunSplit(km: 1, paceSec: 240, elevationDelta: 4.0, avgHeartRate: 148),
      ],
    );

    test('Generates valid GPX 1.1 XML root and namespaces', () {
      final gpx = GpxExporter.generateGpx(standardRun);

      expect(gpx, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpx, contains('<gpx version="1.1"'));
      expect(gpx, contains('creator="Fitone Mobile Wearable Ecosystem"'));
      expect(gpx, contains('xmlns="http://www.topografix.com/GPX/1/1"'));
      expect(
        gpx,
        contains(
          'xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1"',
        ),
      );
      expect(gpx, endsWith('</gpx>\n'));
    });

    test('Contains metadata with title, description, and UTC timestamp', () {
      final gpx = GpxExporter.generateGpx(standardRun);

      expect(gpx, contains('<metadata>'));
      expect(gpx, contains('<name>Lahore Canal Tempo Run</name>'));
      expect(
        gpx,
        contains(
          '<desc>Fitone GPS Outdoor Run: 5.00 km, 20:00, 4:00 /km avg pace, 156 BPM avg HR, +18.5m elevation</desc>',
        ),
      );
      expect(gpx, contains('<time>2026-11-06T14:30:00.000Z</time>'));
      expect(gpx, contains('</metadata>'));
    });

    test('Contains track, type, track segment, and exact trackpoints', () {
      final gpx = GpxExporter.generateGpx(standardRun);

      expect(gpx, contains('<trk>'));
      expect(gpx, contains('<type>running</type>'));
      expect(gpx, contains('<trkseg>'));
      expect(gpx, contains('<trkpt lat="31.520400" lon="74.358700">'));
      expect(gpx, contains('<ele>215.0</ele>'));
      expect(gpx, contains('<trkpt lat="31.524800" lon="74.362800">'));
      expect(gpx, contains('<ele>222.0</ele>'));
      expect(gpx, contains('<trkpt lat="31.530200" lon="74.368000">'));
      expect(gpx, contains('<ele>233.5</ele>'));
      expect(gpx, contains('</trkseg>'));
      expect(gpx, contains('</trk>'));
    });

    test('Includes Garmin TrackPointExtension with heart rate telemetry', () {
      final gpx = GpxExporter.generateGpx(standardRun);

      expect(gpx, contains('<extensions>'));
      expect(gpx, contains('<gpxtpx:TrackPointExtension>'));
      expect(gpx, contains('<gpxtpx:hr>145</gpxtpx:hr>'));
      expect(gpx, contains('<gpxtpx:hr>155</gpxtpx:hr>'));
      expect(gpx, contains('<gpxtpx:hr>162</gpxtpx:hr>'));
      expect(gpx, contains('</gpxtpx:TrackPointExtension>'));
      expect(gpx, contains('</extensions>'));
    });

    test('Escapes special XML characters in title', () {
      final runWithSpecialChars = RunRecord(
        id: 'run_special_02',
        title: 'Morning <Intervals> & "Sprints" @ 5\' pace',
        startTime: testStartTime,
        durationSeconds: 600,
        distanceKm: 2.5,
        avgPaceSecPerKm: 240,
        elevationGainM: 5.0,
        caloriesBurned: 180.0,
        avgHeartRate: 160,
        coordinates: const [RunCoordinate(31.5204, 74.3587)],
        splits: const [],
      );

      final gpx = GpxExporter.generateGpx(runWithSpecialChars);
      expect(
        gpx,
        contains(
          '<name>Morning &lt;Intervals&gt; &amp; &quot;Sprints&quot; @ 5&apos; pace</name>',
        ),
      );
      expect(gpx, isNot(contains('<Intervals>')));
    });

    test('Interpolates elevation and timestamp when coordinates lack them', () {
      final runWithBareCoords = RunRecord(
        id: 'run_bare_03',
        title: 'Base Interpolation Run',
        startTime: testStartTime,
        durationSeconds: 600, // 10 minutes
        distanceKm: 2.0,
        avgPaceSecPerKm: 300,
        elevationGainM: 20.0,
        caloriesBurned: 150.0,
        avgHeartRate: 150,
        coordinates: const [
          RunCoordinate(31.5000, 74.3000),
          RunCoordinate(31.5100, 74.3100),
          RunCoordinate(31.5200, 74.3200),
        ],
        splits: const [],
      );

      final gpx = GpxExporter.generateGpx(runWithBareCoords);

      // Coordinate 0: ele 215.0m, time 14:30:00
      expect(gpx, contains('<trkpt lat="31.500000" lon="74.300000">'));
      expect(gpx, contains('<ele>215.0</ele>'));
      expect(gpx, contains('<time>2026-11-06T14:30:00.000Z</time>'));

      // Coordinate 1: ele 225.0m (215 + 10), time 14:35:00 (+300s)
      expect(gpx, contains('<trkpt lat="31.510000" lon="74.310000">'));
      expect(gpx, contains('<ele>225.0</ele>'));
      expect(gpx, contains('<time>2026-11-06T14:35:00.000Z</time>'));

      // Coordinate 2: ele 235.0m (215 + 20), time 14:40:00 (+600s)
      expect(gpx, contains('<trkpt lat="31.520000" lon="74.320000">'));
      expect(gpx, contains('<ele>235.0</ele>'));
      expect(gpx, contains('<time>2026-11-06T14:40:00.000Z</time>'));
    });

    test('Handles empty coordinates cleanly without throwing', () {
      final emptyRun = RunRecord(
        id: 'run_empty_04',
        title: 'Empty Route Run',
        startTime: testStartTime,
        durationSeconds: 0,
        distanceKm: 0.0,
        avgPaceSecPerKm: 0,
        elevationGainM: 0.0,
        caloriesBurned: 0.0,
        avgHeartRate: 0,
        coordinates: const [],
        splits: const [],
      );

      final gpx = GpxExporter.generateGpx(emptyRun);
      expect(gpx, contains('<trkseg>'));
      expect(gpx, contains('</trkseg>'));
      expect(gpx, isNot(contains('<trkpt')));
    });

    test('Generates clean, standardized file name', () {
      final fileName = GpxExporter.getCleanFileName(standardRun);
      expect(fileName, startsWith('fitone_lahore_canal_tempo_run_'));
      expect(fileName, endsWith('.gpx'));
    });

    test('Writes GPX file to directory successfully', () async {
      final tempDir = Directory.systemTemp.createTempSync('fitone_gpx_test_');
      try {
        final file = await GpxExporter.writeGpxToFile(
          standardRun,
          directory: tempDir,
        );
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        expect(content, contains('<gpx version="1.1"'));
        expect(content, contains('Lahore Canal Tempo Run'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Returns comprehensive metadata summary', () {
      final summary = GpxExporter.getGpxMetadataSummary(standardRun);
      expect(summary['fileName'], contains('.gpx'));
      expect(summary['trackpoints'], 3);
      expect(summary['distanceKm'], 5.0);
      expect(summary['duration'], '20:00');
      expect(summary['elevationGainM'], 18.5);
      expect(summary['fileSizeBytes'], greaterThan(100));
    });
  });
}
