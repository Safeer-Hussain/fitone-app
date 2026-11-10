import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/theme_store.dart';
import '../stores/dashboard_store.dart';
import '../widgets/device_manager_sheet.dart';
import '../widgets/ecg_waveform_card.dart';
import '../widgets/hrv_trend_card.dart';
import '../widgets/readiness_ring.dart';
import '../widgets/sleep_architecture_card.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardStore _store;
  late final ThemeStore _themeStore;

  @override
  void initState() {
    super.initState();
    _store = sl<DashboardStore>();
    _themeStore = sl<ThemeStore>();
    _store.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final _ = _themeStore.themeMode;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        final telemetry = _store.activeTelemetry;
        final connected = _store.connectedDevice;
        final hr = telemetry?.heartRate ?? 72;
        final spo2 = telemetry?.spo2 ?? 98;
        final hrv = telemetry?.hrv ?? 64;
        final tempDelta = telemetry?.skinTempDelta ?? 0.1;
        final signal = telemetry?.signalQuality ?? 99;
        final battery = telemetry?.batteryLevel ?? 88;
        final buffer = _store.ecgBuffer;
        final readiness = _store.readinessScore;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;

              if (isLandscape) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 35,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildDeviceHeader(
                                context,
                                connected,
                                colorScheme,
                                battery: battery,
                                isCompact: true,
                              ),
                              const SizedBox(height: 8),
                              ReadinessRing(
                                score: readiness,
                                hrvMs: hrv,
                                restingHr: hr,
                                isCompact: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 65,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              EcgWaveformCard(
                                ecgBuffer: buffer,
                                heartRate: hr,
                                spo2: spo2,
                                skinTempDelta: tempDelta,
                                signalQuality: signal,
                                isCompact: true,
                              ),
                              const SizedBox(height: 8),
                              const SleepArchitectureCard(isCompact: true),
                              const SizedBox(height: 8),
                              const HrvTrendCard(isCompact: true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  _buildDeviceHeader(
                    context,
                    connected,
                    colorScheme,
                    battery: battery,
                  ),
                  const SizedBox(height: 14),
                  ReadinessRing(score: readiness, hrvMs: hrv, restingHr: hr),
                  const SizedBox(height: 14),
                  EcgWaveformCard(
                    ecgBuffer: buffer,
                    heartRate: hr,
                    spo2: spo2,
                    skinTempDelta: tempDelta,
                    signalQuality: signal,
                  ),
                  const SizedBox(height: 14),
                  const SleepArchitectureCard(),
                  const SizedBox(height: 14),
                  const HrvTrendCard(),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDeviceHeader(
    BuildContext context,
    dynamic connected,
    ColorScheme colorScheme, {
    int battery = 88,
    bool isCompact = false,
  }) {
    return GestureDetector(
      onTap: () => DeviceManagerSheet.show(context, _store),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 16,
          vertical: isCompact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connected != null ? connected.name : 'AuraRing Pro v2',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isCompact ? 12 : 14,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    connected != null
                        ? 'Connected • 99% fidelity'
                        : 'Connected via SDK_A • 99% fidelity',
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.battery_charging_full_rounded,
                    size: 12,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$battery%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.tune_rounded, size: 16, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
