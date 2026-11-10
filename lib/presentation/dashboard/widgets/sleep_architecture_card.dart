import 'package:flutter/material.dart';

import '../../../core/utils/app_feedback.dart';

class SleepArchitectureCard extends StatelessWidget {
  final int sleepScore;
  final String currentStage;
  final bool isCompact;

  const SleepArchitectureCard({
    super.key,
    this.sleepScore = 88,
    this.currentStage = 'DEEP',
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const purpleAccent = Color(0xFFB388FF);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showSleepBreakdownSheet(context, colorScheme),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SLEEP ARCHITECTURE',
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 8,
                      vertical: isCompact ? 2 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: purpleAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: purpleAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Score $sleepScore',
                      style: const TextStyle(
                        color: purpleAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 8 : 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Duration',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: isCompact ? 11 : 13,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '7h 48m (91% Efficiency)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: isCompact ? 11 : 13,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 8 : 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: isCompact ? 12 : 18,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 24,
                        child: Container(color: const Color(0xFF6366F1)),
                      ),
                      Expanded(
                        flex: 22,
                        child: Container(color: const Color(0xFF8B5CF6)),
                      ),
                      Expanded(
                        flex: 46,
                        child: Container(color: const Color(0xFF38BDF8)),
                      ),
                      Expanded(
                        flex: 8,
                        child: Container(color: const Color(0xFFF43F5E)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 8 : 14),
              const Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _SleepStageLegend(
                    color: Color(0xFF6366F1),
                    label: 'Deep (1h 52m)',
                  ),
                  _SleepStageLegend(
                    color: Color(0xFF8B5CF6),
                    label: 'REM (1h 43m)',
                  ),
                  _SleepStageLegend(
                    color: Color(0xFF38BDF8),
                    label: 'Light (3h 35m)',
                  ),
                  _SleepStageLegend(
                    color: Color(0xFFF43F5E),
                    label: 'Awake (38m)',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepBreakdownSheet(BuildContext context, ColorScheme colorScheme) {
    AppFeedback.showInfo(
      context,
      'Sleep Performance: Score $sleepScore • 7h 48m Total Rest',
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
                      const Icon(
                        Icons.bedtime_rounded,
                        color: Color(0xFFB388FF),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sleep Architecture & Hypnogram',
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
                        _buildSleepRow(
                          'Total Sleep Time',
                          '7 hours 48 minutes',
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildSleepRow(
                          'Deep Restorative Sleep',
                          '1h 52m (24% of night)',
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildSleepRow(
                          'REM Cognitive Phase',
                          '1h 43m (22% of night)',
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildSleepRow(
                          'Light Sleep Phase',
                          '3h 35m (48% of night)',
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildSleepRow(
                          'Sleep Efficiency',
                          '94% time asleep in bed',
                          colorScheme,
                        ),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildSleepRow(
                          'Circadian Regularity',
                          'Optimal 23:15 -> 07:05 window',
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

  Widget _buildSleepRow(String label, String value, ColorScheme colorScheme) {
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

class _SleepStageLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _SleepStageLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
