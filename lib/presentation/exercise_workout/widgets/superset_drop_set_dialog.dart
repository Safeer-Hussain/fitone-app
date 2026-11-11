import 'package:flutter/material.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/superset_config.dart';
import '../stores/workout_logger_store.dart';

enum SetBuilderMode { superset, dropSet }

class SupersetDropSetDialog extends StatefulWidget {
  final WorkoutLoggerStore loggerStore;
  final List<Exercise> exercises;
  final String? initialExerciseId;

  const SupersetDropSetDialog({
    super.key,
    required this.loggerStore,
    required this.exercises,
    this.initialExerciseId,
  });

  static void show(
    BuildContext context, {
    required WorkoutLoggerStore loggerStore,
    required List<Exercise> exercises,
    String? initialExerciseId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SupersetDropSetDialog(
        loggerStore: loggerStore,
        exercises: exercises,
        initialExerciseId: initialExerciseId,
      ),
    );
  }

  @override
  State<SupersetDropSetDialog> createState() => _SupersetDropSetDialogState();
}

class _SupersetDropSetDialogState extends State<SupersetDropSetDialog> {
  SetBuilderMode _mode = SetBuilderMode.superset;

  // Superset fields
  late String _exerciseAId;
  late String _exerciseBId;
  double _weightA = 80.0;
  int _repsA = 10;
  double _weightB = 30.0;
  int _repsB = 12;
  int _transitionSeconds = 10;
  int _supersetRestSeconds = 90;

  // Drop set fields
  late String _dropExerciseId;
  double _dropStartingWeight = 100.0;
  int _dropStartingReps = 8;
  int _dropStageCount = 3;
  double _dropPercent = 20.0;
  int _intraDropRestSeconds = 5;
  int _dropPostRestSeconds = 90;

  @override
  void initState() {
    super.initState();
    final firstId = widget.exercises.isNotEmpty
        ? widget.exercises.first.id
        : 'ex_01';
    final secondId = widget.exercises.length > 1
        ? widget.exercises[1].id
        : firstId;

    _exerciseAId =
        (widget.initialExerciseId != null &&
            widget.exercises.any((e) => e.id == widget.initialExerciseId))
        ? widget.initialExerciseId!
        : firstId;
    _exerciseBId = secondId;
    _dropExerciseId = _exerciseAId;
  }

  void _onAddSuperset() {
    final config = SupersetPairConfig(
      primaryExerciseId: _exerciseAId,
      primaryWeight: _weightA,
      primaryReps: _repsA,
      secondaryExerciseId: _exerciseBId,
      secondaryWeight: _weightB,
      secondaryReps: _repsB,
      transitionRestSeconds: _transitionSeconds,
      roundRestSeconds: _supersetRestSeconds,
      rpe: 8.5,
    );

    widget.loggerStore.addSupersetPair(config);
    AppFeedback.showSuccess(
      context,
      'Antagonist superset pair added to active session.',
    );
    Navigator.of(context).pop();
  }

  void _onAddDropSet() {
    final config = DropSetSequenceConfig.fromPercentageDrops(
      exerciseId: _dropExerciseId,
      startingWeight: _dropStartingWeight,
      startingReps: _dropStartingReps,
      stageCount: _dropStageCount,
      dropPercentPerStage: _dropPercent,
      intraDropRestSeconds: _intraDropRestSeconds,
      postDropRestSeconds: _dropPostRestSeconds,
      rpe: 9.0,
    );

    widget.loggerStore.addDropSetSequence(config);
    AppFeedback.showSuccess(
      context,
      '$_dropStageCount-stage drop set sequence added to active session.',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                (isLandscape ? 0.96 : 0.88),
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Superset & Drop Set Builder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: SegmentedButton<SetBuilderMode>(
                  segments: const [
                    ButtonSegment(
                      value: SetBuilderMode.superset,
                      label: Text('Antagonist Superset'),
                      icon: Icon(Icons.compare_arrows_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: SetBuilderMode.dropSet,
                      label: Text('Multi-Stage Drop Set'),
                      icon: Icon(Icons.trending_down_rounded, size: 16),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _mode = selected.first;
                    });
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _mode == SetBuilderMode.superset
                      ? _buildSupersetSection(colorScheme)
                      : _buildDropSetSection(colorScheme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupersetSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          colorScheme: colorScheme,
          title: 'Exercise 1 (Agonist / Primary)',
          badgeText: 'Stage 1A',
          badgeColor: colorScheme.primary,
          child: Column(
            children: [
              _buildExerciseDropdown(
                value: _exerciseAId,
                onChanged: (val) {
                  if (val != null) setState(() => _exerciseAId = val);
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberAdjuster(
                      label: 'Weight (${widget.loggerStore.unit})',
                      value: _weightA,
                      step: 2.5,
                      min: 0,
                      max: 300,
                      colorScheme: colorScheme,
                      onChanged: (v) => setState(() => _weightA = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildIntAdjuster(
                      label: 'Target Reps',
                      value: _repsA,
                      min: 1,
                      max: 50,
                      colorScheme: colorScheme,
                      onChanged: (v) => setState(() => _repsA = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 16, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Auto Transition: ${_transitionSeconds}s back-to-back',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          colorScheme: colorScheme,
          title: 'Exercise 2 (Antagonist / Secondary)',
          badgeText: 'Stage 1B',
          badgeColor: colorScheme.secondary,
          child: Column(
            children: [
              _buildExerciseDropdown(
                value: _exerciseBId,
                onChanged: (val) {
                  if (val != null) setState(() => _exerciseBId = val);
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberAdjuster(
                      label: 'Weight (${widget.loggerStore.unit})',
                      value: _weightB,
                      step: 2.5,
                      min: 0,
                      max: 300,
                      colorScheme: colorScheme,
                      onChanged: (v) => setState(() => _weightB = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildIntAdjuster(
                      label: 'Target Reps',
                      value: _repsB,
                      min: 1,
                      max: 50,
                      colorScheme: colorScheme,
                      onChanged: (v) => setState(() => _repsB = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTimerSettingsCard(
          colorScheme: colorScheme,
          transitionSeconds: _transitionSeconds,
          postRestSeconds: _supersetRestSeconds,
          onTransitionChanged: (s) => setState(() => _transitionSeconds = s),
          onPostRestChanged: (s) => setState(() => _supersetRestSeconds = s),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            key: const ValueKey('add_superset_pair_button'),
            onPressed: _onAddSuperset,
            icon: const Icon(Icons.add_link_rounded, size: 18),
            label: const Text(
              'Add Antagonist Superset Pair',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropSetSection(ColorScheme colorScheme) {
    // Generate preview stages
    final previewConfig = DropSetSequenceConfig.fromPercentageDrops(
      exerciseId: _dropExerciseId,
      startingWeight: _dropStartingWeight,
      startingReps: _dropStartingReps,
      stageCount: _dropStageCount,
      dropPercentPerStage: _dropPercent,
      intraDropRestSeconds: _intraDropRestSeconds,
      postDropRestSeconds: _dropPostRestSeconds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          colorScheme: colorScheme,
          title: 'Target Exercise & Initial Weight',
          badgeText: 'Drop Sequence',
          badgeColor: colorScheme.tertiary,
          child: Column(
            children: [
              _buildExerciseDropdown(
                value: _dropExerciseId,
                onChanged: (val) {
                  if (val != null) setState(() => _dropExerciseId = val);
                },
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberAdjuster(
                      label: 'Starting Weight (${widget.loggerStore.unit})',
                      value: _dropStartingWeight,
                      step: 2.5,
                      min: 5,
                      max: 300,
                      colorScheme: colorScheme,
                      onChanged: (v) => setState(() => _dropStartingWeight = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildIntAdjuster(
                      label: 'Starting Reps',
                      value: _dropStartingReps,
                      min: 1,
                      max: 30,
                      colorScheme: colorScheme,
                      onChanged: (v) => setState(() => _dropStartingReps = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          colorScheme: colorScheme,
          title: 'Drop Progression Parameters',
          badgeText: '${_dropPercent.toStringAsFixed(0)}% Drop',
          badgeColor: colorScheme.secondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Number of Stages',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2 Stages')),
                    ButtonSegment(value: 3, label: Text('3 Stages')),
                    ButtonSegment(value: 4, label: Text('4 Stages')),
                  ],
                  selected: {_dropStageCount},
                  onSelectionChanged: (s) {
                    setState(() => _dropStageCount = s.first);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Drop % per Stage',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 15.0, label: Text('15% Drop')),
                    ButtonSegment(value: 20.0, label: Text('20% Drop')),
                    ButtonSegment(value: 25.0, label: Text('25% Drop')),
                  ],
                  selected: {_dropPercent},
                  onSelectionChanged: (s) {
                    setState(() => _dropPercent = s.first);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Sequence Preview Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sequence Preview (Back-to-Back)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...previewConfig.stages.map((st) {
                final isLast = st.stageNumber == previewConfig.stages.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: st.stageNumber == 1
                              ? colorScheme.primary
                              : colorScheme.secondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Stage ${st.stageNumber}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: st.stageNumber == 1
                                ? colorScheme.onPrimary
                                : colorScheme.onSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${st.weight.toStringAsFixed(1)} ${widget.loggerStore.unit} x ${st.reps} reps',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isLast
                            ? '${_dropPostRestSeconds}s rest'
                            : '${_intraDropRestSeconds}s drop',
                        style: TextStyle(
                          fontSize: 11,
                          color: isLast
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTimerSettingsCard(
          colorScheme: colorScheme,
          transitionSeconds: _intraDropRestSeconds,
          postRestSeconds: _dropPostRestSeconds,
          transitionLabel: 'Intra-Drop Rest',
          onTransitionChanged: (s) => setState(() => _intraDropRestSeconds = s),
          onPostRestChanged: (s) => setState(() => _dropPostRestSeconds = s),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            key: const ValueKey('add_drop_set_sequence_button'),
            onPressed: _onAddDropSet,
            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
            label: Text(
              'Add $_dropStageCount-Stage Drop Set',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionCard({
    required ColorScheme colorScheme,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildExerciseDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
    required ColorScheme colorScheme,
  }) {
    final validValue = widget.exercises.any((e) => e.id == value)
        ? value
        : (widget.exercises.isNotEmpty ? widget.exercises.first.id : null);

    return DropdownButtonFormField<String>(
      value: validValue,
      isExpanded: true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      dropdownColor: colorScheme.surface,
      items: widget.exercises.map((e) {
        return DropdownMenuItem<String>(
          value: e.id,
          child: Text(
            e.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberAdjuster({
    required String label,
    required double value,
    required double step,
    required double min,
    required double max,
    required ColorScheme colorScheme,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () {
                  final next = (value - step).clamp(min, max);
                  onChanged(next);
                },
              ),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 16),
                onPressed: () {
                  final next = (value + step).clamp(min, max);
                  onChanged(next);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntAdjuster({
    required String label,
    required int value,
    required int min,
    required int max,
    required ColorScheme colorScheme,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () {
                  final next = (value - 1).clamp(min, max);
                  onChanged(next);
                },
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add, size: 16),
                onPressed: () {
                  final next = (value + 1).clamp(min, max);
                  onChanged(next);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSettingsCard({
    required ColorScheme colorScheme,
    required int transitionSeconds,
    required int postRestSeconds,
    required ValueChanged<int> onTransitionChanged,
    required ValueChanged<int> onPostRestChanged,
    String transitionLabel = 'Transition Rest',
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automated Timer Tracking',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            transitionLabel,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 5, label: Text('5s')),
                ButtonSegment(value: 10, label: Text('10s')),
                ButtonSegment(value: 15, label: Text('15s')),
              ],
              selected: {transitionSeconds},
              onSelectionChanged: (s) => onTransitionChanged(s.first),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Post-Round Rest',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 60, label: Text('60s')),
                ButtonSegment(value: 90, label: Text('90s')),
                ButtonSegment(value: 120, label: Text('120s')),
              ],
              selected: {postRestSeconds},
              onSelectionChanged: (s) => onPostRestChanged(s.first),
            ),
          ),
        ],
      ),
    );
  }
}
