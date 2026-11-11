import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/app_feedback.dart';
import '../stores/dashboard_store.dart';
import 'telemetry_csv_export_dialog.dart';

class EcgWaveformCard extends StatelessWidget {
  final List<double> ecgBuffer;
  final int heartRate;
  final int spo2;
  final double skinTempDelta;
  final int signalQuality;
  final bool isCompact;

  const EcgWaveformCard({
    super.key,
    required this.ecgBuffer,
    required this.heartRate,
    required this.spo2,
    required this.skinTempDelta,
    required this.signalQuality,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final spots = List<FlSpot>.generate(
      ecgBuffer.length,
      (index) => FlSpot(index.toDouble(), ecgBuffer[index]),
    );

    final maxX = ecgBuffer.length > 1 ? (ecgBuffer.length - 1).toDouble() : 1.0;

    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showEcgDiagnosticsSheet(context, colorScheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 12 : 16,
                  isCompact ? 10 : 16,
                  isCompact ? 12 : 16,
                  isCompact ? 6 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                            Text(
                              'LIVE PPG TELEMETRY',
                              style: TextStyle(
                                fontSize: isCompact ? 10 : 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Signal $signalQuality%',
                          style: TextStyle(
                            fontSize: isCompact ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isCompact ? 6 : 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$heartRate',
                          style: isCompact
                              ? TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                )
                              : AppTypography.metricLarge.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: isCompact ? 4.0 : 8.0,
                            left: 6,
                          ),
                          child: Text(
                            'BPM',
                            style: TextStyle(
                              fontSize: isCompact ? 11 : 13,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _TelemetryTag(
                          label: 'SpO2',
                          value: '$spo2%',
                          isCompact: isCompact,
                        ),
                        const SizedBox(width: 8),
                        _TelemetryTag(
                          label: 'Skin Temp',
                          value:
                              '${skinTempDelta >= 0 ? "+" : ""}${skinTempDelta.toStringAsFixed(1)}C',
                          isCompact: isCompact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: isCompact ? 75 : 95,
                child: spots.isEmpty
                    ? Center(
                        child: Text(
                          'Synchronizing waveform stream...',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: maxX,
                          minY: -1.0,
                          maxY: 1.8,
                          clipData: const FlClipData.all(),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(
                            show: false,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                reservedSize: 0,
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                reservedSize: 0,
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                reservedSize: 0,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: false,
                                reservedSize: 0,
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: colorScheme.primary,
                              barWidth: 2.2,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    colorScheme.primary.withValues(alpha: 0.25),
                                    colorScheme.primary.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEcgDiagnosticsSheet(BuildContext context, ColorScheme colorScheme) {
    AppFeedback.showInfo(
      context,
      'PPG / ECG Telemetry: $heartRate BPM • $spo2% SpO2 • $signalQuality% Signal',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.monitor_heart_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Optical PPG & ECG Telemetry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        _buildDiagRow(
                          'Heart Rate',
                          '$heartRate BPM',
                          Icons.favorite_rounded,
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildDiagRow(
                          'Blood Oxygen (SpO2)',
                          '$spo2%',
                          Icons.water_drop_rounded,
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildDiagRow(
                          'Optical Signal Fidelity',
                          '$signalQuality%',
                          Icons.wifi_rounded,
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildDiagRow(
                          'Skin Temp Differential',
                          '${skinTempDelta >= 0 ? '+' : ''}${skinTempDelta.toStringAsFixed(1)}°C',
                          Icons.thermostat_rounded,
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildDiagRow(
                          'Active Telemetry Lead',
                          'Dual Ring Transceiver Lead I',
                          Icons.cable_rounded,
                          colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('ecg_sheet_export_csv_button'),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            if (sl.isRegistered<DashboardStore>()) {
                              TelemetryCsvExportDialog.show(
                                context,
                                sl<DashboardStore>(),
                              );
                            }
                          },
                          icon: const Icon(Icons.table_chart_rounded, size: 16),
                          label: const Text('Export CSV'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagRow(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _TelemetryTag extends StatelessWidget {
  final String label;
  final String value;
  final bool isCompact;

  const _TelemetryTag({
    required this.label,
    required this.value,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 9 : 10,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
