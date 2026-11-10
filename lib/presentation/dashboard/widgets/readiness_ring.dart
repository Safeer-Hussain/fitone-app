import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_typography.dart';
import '../../../core/utils/app_feedback.dart';

class ReadinessRing extends StatelessWidget {
  final int score;
  final int hrvMs;
  final int restingHr;
  final bool isCompact;

  const ReadinessRing({
    super.key,
    required this.score,
    required this.hrvMs,
    required this.restingHr,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusText = score >= 85
        ? 'Optimal Readiness'
        : (score >= 70 ? 'Moderate Recovery' : 'Rest Advised');

    final statusColor = score >= 85
        ? colorScheme.primary
        : (score >= 70 ? colorScheme.secondary : const Color(0xFFFF9100));

    final gaugeSize = isCompact ? 100.0 : 160.0;
    final strokeWidth = isCompact ? 10.0 : 14.0;
    final paddingValue = isCompact ? 12.0 : 20.0;
    final spacing = isCompact ? 10.0 : 20.0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReadinessBreakdown(context, colorScheme, statusText),
        child: Padding(
          padding: EdgeInsets.all(paddingValue),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'RECOVERY & READINESS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 10,
                      vertical: isCompact ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: isCompact ? 10 : 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
              SizedBox(
                width: gaugeSize,
                height: gaugeSize,
                child: CustomPaint(
                  painter: _ReadinessGaugePainter(
                    score: score,
                    primaryColor: statusColor,
                    trackColor: colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                    strokeWidth: strokeWidth,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
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
                        Text(
                          'SCORE',
                          style: TextStyle(
                            fontSize: isCompact ? 9 : 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _BiometricMetric(
                      label: 'HRV (ms)',
                      value: '$hrvMs',
                      sub: '+4ms vs 30d',
                      icon: Icons.graphic_eq_rounded,
                      accentColor: statusColor,
                      isCompact: isCompact,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: isCompact ? 28 : 36,
                    color: colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: _BiometricMetric(
                      label: 'Resting HR',
                      value: '$restingHr',
                      sub: 'BPM baseline',
                      icon: Icons.favorite_rounded,
                      accentColor: colorScheme.error,
                      isCompact: isCompact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReadinessBreakdown(
    BuildContext context,
    ColorScheme colorScheme,
    String statusText,
  ) {
    AppFeedback.showInfo(
      context,
      'Readiness Index: $score / 100 ($statusText)',
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
                        Icons.bolt_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Readiness & Recovery Intelligence',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Score: $score / 100',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildReadinessRow(
                          'Autonomic Balance (HRV)',
                          '$hrvMs ms RMSSD',
                          Icons.graphic_eq_rounded,
                          colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _buildReadinessRow(
                          'Resting Pulse',
                          '$restingHr BPM',
                          Icons.favorite_rounded,
                          colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _buildReadinessRow(
                          'Circadian Sync',
                          '94% Diurnal Alignment',
                          Icons.bedtime_rounded,
                          colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _buildReadinessRow(
                          'Skin Temp Delta',
                          '+0.1°C Baseline',
                          Icons.thermostat_rounded,
                          colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'RECOVERY ADVICE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    score >= 80
                        ? 'Your nervous system is primed for peak exertion. Progressive overload and intense interval running are recommended.'
                        : 'Moderate strain advised. Prioritize Zone 2 cardio, hydration replenishment, and 8 hours of restorative sleep.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
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

  Widget _buildReadinessRow(
    String title,
    String val,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
            ),
          ],
        ),
        Text(
          val,
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

class _BiometricMetric extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color accentColor;
  final bool isCompact;

  const _BiometricMetric({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.accentColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isCompact ? 12 : 14, color: accentColor),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 9 : 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: isCompact
              ? TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                )
              : AppTypography.metricMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: isCompact ? 9 : 11,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ReadinessGaugePainter extends CustomPainter {
  final int score;
  final Color primaryColor;
  final Color trackColor;
  final double strokeWidth;

  _ReadinessGaugePainter({
    required this.score,
    required this.primaryColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth - 6) / 2;

    const startAngle = 0.75 * pi;
    const sweepAngle = 1.5 * pi;

    final backgroundPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    final progressSweep = (score / 100.0) * sweepAngle;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [primaryColor.withValues(alpha: 0.4), primaryColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressSweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ReadinessGaugePainter oldDelegate) =>
      oldDelegate.score != score ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
