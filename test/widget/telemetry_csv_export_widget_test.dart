import 'dart:io';

import 'package:fitone/core/di/injection.dart';
import 'package:fitone/core/theme/theme_store.dart';
import 'package:fitone/core/utils/telemetry_csv_exporter.dart';
import 'package:fitone/domain/entities/ring_telemetry.dart';
import 'package:fitone/domain/repositories/ring_repository.dart';
import 'package:fitone/presentation/dashboard/stores/dashboard_store.dart';
import 'package:fitone/presentation/dashboard/views/dashboard_view.dart';
import 'package:fitone/presentation/dashboard/widgets/telemetry_csv_export_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRingRepo implements RingRepository {
  @override
  Stream<RingTelemetry> watchTelemetry() => const Stream.empty();

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
        opticalPPG: 'OK (99.8%)',
        temperatureSensor: 'OK (36.6°C)',
        sixAxisIMU: 'CALIBRATED',
        bleTransceiver: 'CONNECTED (LE 2M PHY)',
        internalNAND: 'HEALTHY',
        batteryHealth: '98% (4.18V)',
      );

  @override
  Future<void> updateTelemetryRate(int intervalMs) async {}

  @override
  Future<List<RingTelemetry>> getHistoricalTelemetry({
    Duration duration = const Duration(hours: 24),
  }) async => [
    RingTelemetry(
      packetId: 2001,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      deviceId: 'AURA-PRO-9842',
      sdk: 'SDK_A',
      heartRate: 54,
      spo2: 98,
      hrv: 76,
      skinTempDelta: -0.28,
      sleepStage: 'DEEP',
      stepCount: 2100,
      batteryLevel: 92,
      signalQuality: 99,
      checksum: 'A4F20018B',
      ecgSamples: const [0.1, 0.4, 1.2, -0.4, 0.1],
    ),
    RingTelemetry(
      packetId: 2002,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      deviceId: 'AURA-PRO-9842',
      sdk: 'SDK_A',
      heartRate: 72,
      spo2: 99,
      hrv: 58,
      skinTempDelta: 0.12,
      sleepStage: 'AWAKE',
      stepCount: 6800,
      batteryLevel: 86,
      signalQuality: 99,
      checksum: 'A4F20028B',
      ecgSamples: const [0.2, 0.5, 0.9, -0.3, 0.0],
    ),
  ];
}

void main() {
  late DashboardStore store;
  late _FakeRingRepo ringRepo;
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fitone_widget_csv_');
    TelemetryCsvExporter.overrideExportDirectory = tempDir;

    ringRepo = _FakeRingRepo();
    store = DashboardStore(ringRepository: ringRepo);

    if (!sl.isRegistered<ThemeStore>()) {
      sl.registerSingleton<ThemeStore>(ThemeStore());
    }
    if (!sl.isRegistered<DashboardStore>()) {
      sl.registerSingleton<DashboardStore>(store);
    } else {
      sl.unregister<DashboardStore>();
      sl.registerSingleton<DashboardStore>(store);
    }
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
    TelemetryCsvExporter.overrideExportDirectory = null;
  });

  Widget buildTestApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('TelemetryCsvExportDialog renders metrics, chips, and actions', (
    tester,
  ) async {
    await store.loadHistoricalTelemetry();

    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => TelemetryCsvExportDialog.show(context, store),
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Export Biometric Telemetry'), findsOneWidget);
    expect(find.text('Sports Science RFC-4180 Dataset'), findsOneWidget);
    expect(find.text('DATASET METRICS'), findsOneWidget);
    expect(find.text('Total Packets'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(
      find.byKey(const ValueKey('copy_csv_clipboard_button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('save_csv_file_button')), findsOneWidget);

    // Toggle switch
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // Tap Copy CSV button
    await tester.ensureVisible(
      find.byKey(const ValueKey('copy_csv_clipboard_button')),
    );
    await tester.tap(find.byKey(const ValueKey('copy_csv_clipboard_button')));
    await tester.pump();
    expect(find.textContaining('copied to clipboard'), findsOneWidget);
  });

  testWidgets('TelemetryCsvExportDialog saves file and shows feedback', (
    tester,
  ) async {
    await store.loadHistoricalTelemetry();

    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => TelemetryCsvExportDialog.show(context, store),
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Tap Save File button
    final saveButton = find.byKey(const ValueKey('save_csv_file_button'));
    await tester.ensureVisible(saveButton);

    await tester.runAsync(() async {
      await tester.tap(saveButton);
      await Future.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();

    expect(
      find.textContaining('Telemetry exported to fitone_telemetry_'),
      findsOneWidget,
    );
  });

  testWidgets(
    'DashboardView device header button triggers TelemetryCsvExportDialog',
    (tester) async {
      await tester.pumpWidget(buildTestApp(const DashboardView()));
      await tester.pumpAndSettle();

      final exportButton = find.byKey(
        const ValueKey('dashboard_export_csv_icon_button'),
      );
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(find.text('Export Biometric Telemetry'), findsOneWidget);
    },
  );

  testWidgets('TelemetryCsvExportDialog 360dp landscape zero overflow check', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await store.loadHistoricalTelemetry();

    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => TelemetryCsvExportDialog.show(context, store),
              child: const Text('Open Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog renders with zero layout overflow exceptions
    expect(find.text('Export Biometric Telemetry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
