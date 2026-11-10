import 'package:flutter/material.dart';

import '../../../domain/entities/exercise.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback? onAddSet;
  final bool isCompact;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.onAddSet,
    this.isCompact = false,
  });

  IconData _getEquipmentIcon(String eq) {
    final lower = eq.toLowerCase();
    if (lower.contains('dumbbell')) return Icons.fitness_center_rounded;
    if (lower.contains('barbell')) return Icons.sports_gymnastics_rounded;
    if (lower.contains('machine')) return Icons.precision_manufacturing_rounded;
    if (lower.contains('bodyweight')) return Icons.accessibility_new_rounded;
    if (lower.contains('cable')) return Icons.cable_rounded;
    return Icons.fitness_center_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: isCompact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 8 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 44,
                      maxHeight: 44,
                    ),
                    child: Container(
                      width: isCompact ? 36 : 42,
                      height: isCompact ? 36 : 42,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _getEquipmentIcon(exercise.equipment),
                        size: isCompact ? 20 : 24,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          exercise.targetMuscles,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onAddSet != null)
                    IconButton(
                      onPressed: onAddSet,
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'Log Set',
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              SizedBox(height: isCompact ? 6 : 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _Badge(
                    label: exercise.bodyPart,
                    color: colorScheme.secondary,
                    isCompact: isCompact,
                  ),
                  _Badge(
                    label: exercise.equipment,
                    color: colorScheme.primary,
                    isCompact: isCompact,
                  ),
                  _Badge(
                    label: exercise.difficulty,
                    color: const Color(0xFFFF9100),
                    isCompact: isCompact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isCompact;

  const _Badge({
    required this.label,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: isCompact ? 9 : 10,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
