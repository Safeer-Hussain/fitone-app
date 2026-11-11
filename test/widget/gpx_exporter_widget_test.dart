import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/core/utils/gpx_exporter.dart';
import 'package:fitone/domain/entities/ring_telemetry.dart';
import 'package:fitone/domain/entities/run_record.dart';
import 'package:fitone/domain/repositories/ring_repository.dart';
import 'package:fitone/domain/repositories/running_repository.dart';
import 'package:fitone/presentation/gps_running/stores/gps_running_store.dart';
import 'package:fitone/presentation/gps_running/widgets/gpx_export_dialog.dart';
import 'package:fitone/presentation/gps_running/widgets/run_summary_sheet.dart';

class _MockRunningRepository implements RunningRepository {
  final List<RunRecord> runs;
  _MockRunningRepository(this.runs);

  @override
  Future<void> saveRunRecord(RunRecord record) async => runs.add(record);

  @override
  Future<List<RunRecord>> getRunHistory() async => runs;

  @override
  Future<RunRecord?> getRunById(String id) async =>
      runs.where((r) => r.id == id).firstOrNull;
}

class _MockRingRepository implements RingRepository {
  @override
  Stream<RingTelemetry> watchTelemetry() => const Stream.empty();
  @override
  Future<List<RingDevice>> getDiscoveredDevices() async => [];
  @override
  Future<void> connectRing(String deviceId, String sdkType) async {}
  @override
  Future<void> disconnectRing() async {}
  @override
  Future<HardwareDiagnostics> getHardwareDiagnostics() async =>
      const HardwareDiagnostics(
        opticalPPG: 'OK',
        temperatureSensor: 'OK',
        sixAxisIMU: 'OK',
        bleTransceiver: 'OK',
        internalNAND: 'OK',
        batteryHealth: '100%',
      );
  @override
  Future<void> updateTelemetryRate(int intervalMs) async {}
  @override
  Future<List<RingTelemetry>> getHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  }) async => [];
}

void main() {
  final sampleRun = RunRecord(
    id: 'run_gpx_sample_01',
    title: 'Lahore Canal Tempo Run',
    startTime: DateTime.utc(2026, 11, 6, 15, 0, 0),
    durationSeconds: 1500,
    distanceKm: 6.25,
    avgPaceSecPerKm: 240,
    elevationGainM: 22.0,
    caloriesBurned: 440.0,
    avgHeartRate: 154,
    coordinates: const [
      RunCoordinate(31.5204, 74.3587, elevation: 215.0, heartRate: 148),
      RunCoordinate(31.5248, 74.3628, elevation: 220.0, heartRate: 153),
      RunCoordinate(31.5302, 74.3680, elevation: 226.5, heartRate: 158),
      RunCoordinate(31.5358, 74.3735, elevation: 237.0, heartRate: 161),
    ],
    splits: const [
      RunSplit(km: 1, paceSec: 238, elevationDelta: 5.0, avgHeartRate: 150),
      RunSplit(km: 2, paceSec: 242, elevationDelta: 6.5, avgHeartRate: 156),
    ],
  );

  setUp(() async {
    GpxExporter.overrideExportDirectory = Directory.systemTemp;
    await sl.reset();
    sl.registerLazySingleton<ThemeStore>(() => ThemeStore());
    sl.registerLazySingleton<RunningRepository>(
      () => _MockRunningRepository([sampleRun]),
    );
    sl.registerLazySingleton<RingRepository>(() => _MockRingRepository());
    sl.registerLazySingleton<GpsRunningStore>(
      () => GpsRunningStore(
        runningRepository: sl<RunningRepository>(),
        ringRepository: sl<RingRepository>(),
      ),
    );
  });

  tearDown(() async {
    GpxExporter.overrideExportDirectory = null;
    await sl.reset();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: child),
    );
  }

  void setupPortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('GpxExportDialog & RunSummarySheet Widget Tests', () {
    testWidgets(
      'Renders GpxExportDialog with metadata, file name and XML preview',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          createTestWidget(GpxExportDialog(record: sampleRun)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Export GPX 1.1 Route'), findsOneWidget);
        expect(
          find.textContaining('fitone_lahore_canal_tempo_run_'),
          findsOneWidget,
        );
        expect(find.text('GPX 1.1 + HR'), findsOneWidget);
        expect(find.text('6.25 km'), findsOneWidget);
        expect(find.text('25:00'), findsOneWidget);
        expect(find.text('4'), findsWidgets); // 4 points
        expect(find.text('GPX 1.1 XML PREVIEW'), findsOneWidget);
        expect(find.textContaining('<gpx version="1.1"'), findsOneWidget);
        expect(
          find.textContaining('<trkpt lat="31.520400" lon="74.358700">'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('copy_gpx_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('save_gpx_button')), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Copy GPX XML button triggers copy and displays success feedback',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          createTestWidget(GpxExportDialog(record: sampleRun)),
        );
        await tester.pumpAndSettle();

        final copyButton = find.byKey(const ValueKey('copy_gpx_button'));
        expect(copyButton, findsOneWidget);
        await tester.tap(copyButton);
        await tester.pump();

        expect(find.text('GPX 1.1 XML copied to clipboard'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Save GPX File writes file and shows path notification',
      (tester) async {
        setupPortrait(tester);

        await tester.pumpWidget(
          createTestWidget(GpxExportDialog(record: sampleRun)),
        );
        await tester.pumpAndSettle();

        final saveButton = find.byKey(const ValueKey('save_gpx_button'));
        expect(saveButton, findsOneWidget);

        await tester.runAsync(() async {
          await tester.tap(saveButton);
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(
          find.textContaining('GPX exported to fitone_lahore_canal_tempo_run_'),
          findsOneWidget,
        );
      },
    );

    testWidgets('RunSummarySheet opens GpxExportDialog from footer button', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => RunSummarySheet.show(context, sampleRun),
              child: const Text('Open Summary'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Summary'));
      await tester.pumpAndSettle();

      final exportGpxBtn = find.byKey(const ValueKey('export_gpx_button'));
      expect(exportGpxBtn, findsOneWidget);
      await tester.tap(exportGpxBtn);
      await tester.pumpAndSettle();

      expect(find.text('Export GPX 1.1 Route'), findsOneWidget);
    });

    testWidgets('RunSummarySheet opens GpxExportDialog from header button', (
      tester,
    ) async {
      setupPortrait(tester);

      await tester.pumpWidget(
        createTestWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => RunSummarySheet.show(context, sampleRun),
              child: const Text('Open Summary'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Summary'));
      await tester.pumpAndSettle();

      final exportHeaderBtn = find.byKey(
        const ValueKey('export_gpx_header_button'),
      );
      expect(exportHeaderBtn, findsOneWidget);
      await tester.tap(exportHeaderBtn);
      await tester.pumpAndSettle();

      expect(find.text('Export GPX 1.1 Route'), findsOneWidget);
    });
  });
}
