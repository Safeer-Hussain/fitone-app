import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/app_feedback.dart';

class HrvTrendCard extends StatelessWidget {
  final bool isCompact;

  const HrvTrendCard({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cyanAccent = colorScheme.secondary;

    final hrvSpots = [
      const FlSpot(0, 58),
      const FlSpot(1, 62),
      const FlSpot(2, 60),
      const FlSpot(3, 67),
      const FlSpot(4, 65),
      const FlSpot(5, 71),
      const FlSpot(6, 68),
    ];

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showHrvBreakdownSheet(context, colorScheme),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '7-DAY HRV TRAJECTORY',
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Mean 64.4 ms',
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 12,
                      fontWeight: FontWeight.w700,
                      color: cyanAccent,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 8 : 18),
              SizedBox(
                height: isCompact ? 85 : 120,
                child: LineChart(
                  LineChartData(
                    minY: 45,
                    maxY: 80,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colorScheme.outlineVariant,
                        strokeWidth: 0.8,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 20,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < days.length) {
                              return Text(
                                days[idx],
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: hrvSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: cyanAccent,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                                radius: isCompact ? 2.5 : 3.5,
                                color: cyanAccent,
                                strokeWidth: 1.5,
                                strokeColor: colorScheme.surface,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              cyanAccent.withValues(alpha: 0.18),
                              cyanAccent.withValues(alpha: 0.0),
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

  void _showHrvBreakdownSheet(BuildContext context, ColorScheme colorScheme) {
    AppFeedback.showInfo(
      context,
      'HRV Autonomic Baseline: 64.4 ms RMSSD (+4.2 ms 7-day trend)',
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
                        Icons.graphic_eq_rounded,
                        color: colorScheme.secondary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Autonomic HRV Analytics',
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
                        _buildHrvRow(
                          '7-Day Mean RMSSD',
                          '64.4 ms',
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildHrvRow(
                          'SDNN Total Variability',
                          '78.2 ms',
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildHrvRow(
                          'Autonomic Balance',
                          'Parasympathetic Dominant (Recovery)',
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildHrvRow(
                          'Weekly Trajectory',
                          '+4.2 ms vs previous 14d rolling mean',
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildHrvRow(
                          'Stress Response Index',
                          'Low physiological sympathetic tone',
                          colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildHrvRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
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
