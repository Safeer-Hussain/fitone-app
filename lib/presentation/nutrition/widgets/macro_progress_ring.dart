import 'package:flutter/material.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/nutrition_day.dart';

class MacroProgressRing extends StatelessWidget {
  final DailyNutritionSummary summary;
  final bool isCompact;

  const MacroProgressRing({super.key, required this.summary, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final caloriesRemaining = (summary.targetCalories - summary.consumedCalories).clamp(0.0, 9999.0);

    final ringSize = isCompact ? 80.0 : 120.0;
    final strokeWidth = isCompact ? 7.0 : 10.0;

    return Card(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showMacroBreakdownSheet(context, colorScheme, caloriesRemaining),
        child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 20),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'DAILY ENERGY & MACROS',
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${caloriesRemaining.toStringAsFixed(0)} kcal left',
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 20),
            Row(
              children: [
                SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: summary.calorieProgress,
                        strokeWidth: strokeWidth,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            summary.consumedCalories.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: isCompact ? 16 : 22,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'KCAL',
                            style: TextStyle(
                              fontSize: isCompact ? 8 : 9,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 24),
                Expanded(
                  child: Column(
                    children: [
                      _MacroBar(
                        label: 'Protein',
                        consumed: summary.consumedProteinG,
                        target: summary.targetProteinG,
                        color: colorScheme.secondary,
                        isCompact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 6 : 10),
                      _MacroBar(
                        label: 'Carbs',
                        consumed: summary.consumedCarbsG,
                        target: summary.targetCarbsG,
                        color: colorScheme.tertiary,
                        isCompact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 6 : 10),
                      _MacroBar(
                        label: 'Fats',
                        consumed: summary.consumedFatG,
                        target: summary.targetFatG,
                        color: Colors.purpleAccent,
                        isCompact: isCompact,
                      ),
                    ],
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

  void _showMacroBreakdownSheet(BuildContext context, ColorScheme colorScheme, double caloriesRemaining) {
    AppFeedback.showInfo(
      context,
      'Macro Target: ${summary.consumedCalories.toStringAsFixed(0)} / ${summary.targetCalories.toStringAsFixed(0)} kcal (${caloriesRemaining.toStringAsFixed(0)} kcal left)',
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
                      Icon(Icons.pie_chart_outline_rounded, color: colorScheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Macronutrient Distribution',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        _buildMacroRow('Daily Caloric Target', '${summary.consumedCalories.toStringAsFixed(0)} / ${summary.targetCalories.toStringAsFixed(0)} kcal', colorScheme.primary, colorScheme),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildMacroRow('Protein (4 kcal/g)', '${summary.consumedProteinG.toStringAsFixed(0)} / ${summary.targetProteinG.toStringAsFixed(0)}g (${(summary.proteinProgress * 100).toInt()}%)', colorScheme.primary, colorScheme),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildMacroRow('Carbohydrates (4 kcal/g)', '${summary.consumedCarbsG.toStringAsFixed(0)} / ${summary.targetCarbsG.toStringAsFixed(0)}g (${(summary.carbsProgress * 100).toInt()}%)', colorScheme.secondary, colorScheme),
                        Divider(color: colorScheme.outlineVariant, height: 16),
                        _buildMacroRow('Dietary Fats (9 kcal/g)', '${summary.consumedFatG.toStringAsFixed(0)} / ${summary.targetFatG.toStringAsFixed(0)}g (${(summary.fatProgress * 100).toInt()}%)', const Color(0xFFFFB74D), colorScheme),
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

  Widget _buildMacroRow(String title, String val, Color dotColor, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 12, color: colorScheme.onSurface)),
          ],
        ),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
      ],
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final Color color;
  final bool isCompact;

  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
            ),
            Text(
              '${consumed.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}g',
              style: TextStyle(fontSize: isCompact ? 9 : 11, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: isCompact ? 4 : 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
