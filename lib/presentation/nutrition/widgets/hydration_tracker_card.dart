import 'package:flutter/material.dart';

import '../../../core/utils/app_feedback.dart';
import '../stores/nutrition_store.dart';

class HydrationTrackerCard extends StatelessWidget {
  final NutritionStore store;
  final bool isCompact;

  const HydrationTrackerCard({
    super.key,
    required this.store,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = store.dailySummary;
    final consumedMl = summary?.consumedWaterMl ?? 0;
    final targetMl = summary?.targetWaterMl ?? 3000;
    final progress = summary?.waterProgress ?? 0.0;
    final streak = store.waterStreakDays;

    return Card(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      size: isCompact ? 14 : 16,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'HYDRATION ENGINE',
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 6 : 8,
                    vertical: isCompact ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$streak Day Streak',
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: isCompact ? 9 : 11,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$consumedMl ml',
                      style: TextStyle(
                        fontSize: isCompact ? 18 : 24,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Target $targetMl ml per day',
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 8 : 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: isCompact ? 6 : 10,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
              ),
            ),
            SizedBox(height: isCompact ? 10 : 18),
            Row(
              children: [
                _WaterButton(
                  label: '+250ml',
                  onTap: () {
                    store.logWater(250);
                    AppFeedback.showSuccess(
                      context,
                      'Logged 250ml water (+0.25L)',
                    );
                  },
                  colorScheme: colorScheme,
                  isCompact: isCompact,
                ),
                const SizedBox(width: 6),
                _WaterButton(
                  label: '+500ml',
                  onTap: () {
                    store.logWater(500);
                    AppFeedback.showSuccess(
                      context,
                      'Logged 500ml water (+0.50L)',
                    );
                  },
                  colorScheme: colorScheme,
                  isCompact: isCompact,
                ),
                const SizedBox(width: 6),
                _WaterButton(
                  label: '+750ml',
                  onTap: () {
                    store.logWater(750);
                    AppFeedback.showSuccess(
                      context,
                      'Logged 750ml water (+0.75L)',
                    );
                  },
                  colorScheme: colorScheme,
                  isCompact: isCompact,
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () {
                    store.resetHydration();
                    AppFeedback.showInfo(
                      context,
                      'Hydration reset to 0ml for today',
                    );
                  },
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: isCompact ? 16 : 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Reset Day Hydration',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isCompact;

  const _WaterButton({
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
