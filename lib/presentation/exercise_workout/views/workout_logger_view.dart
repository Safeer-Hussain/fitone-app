import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/theme_store.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/exercise.dart';
import '../stores/exercise_store.dart';
import '../stores/workout_logger_store.dart';
import '../widgets/barbell_plate_calculator_sheet.dart';
import '../widgets/one_rm_calculator_sheet.dart';
import '../widgets/rest_timer_dialog.dart';
import '../widgets/superset_drop_set_dialog.dart';

class WorkoutLoggerView extends StatefulWidget {
  final String? initialExerciseId;

  const WorkoutLoggerView({super.key, this.initialExerciseId});

  @override
  State<WorkoutLoggerView> createState() => _WorkoutLoggerViewState();
}

class _WorkoutLoggerViewState extends State<WorkoutLoggerView> {
  late final WorkoutLoggerStore _loggerStore;
  late final ExerciseStore _exerciseStore;
  final ThemeStore _themeStore = sl<ThemeStore>();

  double _inputWeight = 80.0;
  int _inputReps = 8;
  final double _inputRpe = 8.0;
  String _selectedExerciseId = 'ex_01';

  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  final _weightFocus = FocusNode();
  final _repsFocus = FocusNode();
  String? _weightErrorText;
  String? _repsErrorText;

  @override
  void initState() {
    super.initState();
    _loggerStore = sl<WorkoutLoggerStore>();
    _exerciseStore = sl<ExerciseStore>();
    if (widget.initialExerciseId != null) {
      _selectedExerciseId = widget.initialExerciseId!;
    }
    if (!_loggerStore.isSessionActive) {
      _loggerStore.startWorkout(title: 'Upper Hypertrophy Session');
    }

    _weightController = TextEditingController(
      text: _inputWeight.toStringAsFixed(1),
    );
    _repsController = TextEditingController(text: _inputReps.toString());

    _attachFocusAutoScroll(_weightFocus);
    _attachFocusAutoScroll(_repsFocus);
  }

  void _attachFocusAutoScroll(FocusNode node) {
    node.addListener(() {
      if (node.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && node.hasFocus) {
            Scrollable.ensureVisible(
              context,
              alignment: 0.5,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  void _logSet() {
    final repsStr = _repsController.text.trim();
    final weightStr = _weightController.text.trim();

    String? repsErr;
    String? weightErr;

    final reps = int.tryParse(repsStr);
    if (repsStr.isEmpty || reps == null || reps <= 0) {
      repsErr = 'Reps must be at least 1.';
    }

    final weight = double.tryParse(weightStr);
    if (weightStr.isEmpty || weight == null || weight < 0) {
      weightErr = 'Weight cannot be negative.';
    }

    if (repsErr != null || weightErr != null) {
      setState(() {
        _repsErrorText = repsErr;
        _weightErrorText = weightErr;
      });
      return;
    }

    setState(() {
      _repsErrorText = null;
      _weightErrorText = null;
    });

    _loggerStore.addSet(
      exerciseId: _selectedExerciseId,
      weight: weight!,
      reps: reps!,
      rpe: _inputRpe,
    );

    AppFeedback.showSuccess(
      context,
      'Set recorded: ${weight.toStringAsFixed(1)}kg x $reps reps',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final _ = _themeStore.themeMode;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final session = _loggerStore.activeSession;
        final unit = _loggerStore.unit;
        final isRestRunning = _loggerStore.isRestTimerRunning;
        final restRemaining = _loggerStore.restTimeRemaining;
        final exercises = _exerciseStore.exercises;

        final currentExercise = exercises
            .where((e) => e.id == _selectedExerciseId)
            .firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text(session?.title ?? 'Active Workout Logger'),
            actions: [
              TextButton(
                onPressed: () => _loggerStore.toggleUnit(),
                child: Text(
                  unit.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('plate_calculator_appbar_button'),
                onPressed: () => BarbellPlateCalculatorSheet.show(
                  context,
                  initialWeight:
                      double.tryParse(_weightController.text) ?? _inputWeight,
                  unit: unit,
                  onWeightApplied: (weight) {
                    setState(() {
                      _inputWeight = weight.clamp(0, 300);
                      _weightController.text = weight.toStringAsFixed(1);
                      _weightErrorText = null;
                    });
                  },
                ),
                icon: Icon(
                  Icons.fitness_center_rounded,
                  color: colorScheme.primary,
                ),
                tooltip: 'Barbell Plate Calculator',
              ),
              IconButton(
                key: const ValueKey('workout_open_superset_builder_button'),
                onPressed: () => SupersetDropSetDialog.show(
                  context,
                  loggerStore: _loggerStore,
                  exercises: exercises,
                  initialExerciseId: _selectedExerciseId,
                ),
                icon: Icon(Icons.layers_outlined, color: colorScheme.tertiary),
                tooltip: 'Superset & Drop Set Builder',
              ),
              IconButton(
                onPressed: () => OneRmCalculatorSheet.show(context),
                icon: Icon(
                  Icons.calculate_outlined,
                  color: colorScheme.secondary,
                ),
                tooltip: '1RM Calculator',
              ),
            ],
          ),
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;

                if (isLandscape) {
                  return SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                _buildSummaryCard(session, colorScheme),
                                const SizedBox(height: 8),
                                _buildInputCard(
                                  currentExercise,
                                  exercises,
                                  unit,
                                  colorScheme,
                                ),
                                const SizedBox(height: 8),
                                _buildBottomBar(
                                  context,
                                  isRestRunning,
                                  restRemaining,
                                  colorScheme,
                                ),
                              ],
                            ),
                          ),
                        ),
                        VerticalDivider(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                        Expanded(
                          flex: 5,
                          child: _buildSetsList(session, colorScheme),
                        ),
                      ],
                    ),
                  );
                }

                return SafeArea(
                  child: Column(
                    children: [
                      _buildSummaryCard(session, colorScheme),
                      _buildInputCard(
                        currentExercise,
                        exercises,
                        unit,
                        colorScheme,
                      ),
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      Expanded(child: _buildSetsList(session, colorScheme)),
                      _buildBottomBar(
                        context,
                        isRestRunning,
                        restRemaining,
                        colorScheme,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(dynamic session, ColorScheme colorScheme) {
    final volume = session?.totalVolumeKg ?? 0.0;
    final setsCount = session?.completedSets ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: 'Total Volume',
              value: '${volume.toStringAsFixed(0)} kg',
              colorScheme: colorScheme,
            ),
          ),
          Container(width: 1, height: 28, color: colorScheme.outlineVariant),
          Expanded(
            child: _Stat(
              label: 'Sets Done',
              value: '$setsCount',
              colorScheme: colorScheme,
            ),
          ),
          Container(width: 1, height: 28, color: colorScheme.outlineVariant),
          Expanded(
            child: _Stat(
              label: 'Est. Cal',
              value: '380 kcal',
              colorScheme: colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(
    dynamic currentExercise,
    List<Exercise> exercises,
    String unit,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: colorScheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: exercises.any((e) => e.id == _selectedExerciseId)
                ? _selectedExerciseId
                : (exercises.isNotEmpty ? exercises.first.id : null),
            isExpanded: true,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            dropdownColor: colorScheme.surface,
            items: exercises.map((e) {
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
            onChanged: (val) {
              if (val != null) setState(() => _selectedExerciseId = val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const ValueKey('workout_weight_field'),
                      controller: _weightController,
                      focusNode: _weightFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Weight ($unit)',
                        errorText: _weightErrorText,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        suffixIcon: IconButton(
                          key: const ValueKey('quick_plate_calc_suffix_button'),
                          icon: Icon(
                            Icons.view_column_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          tooltip: 'Calculate Plates',
                          onPressed: () => BarbellPlateCalculatorSheet.show(
                            context,
                            initialWeight:
                                double.tryParse(_weightController.text) ??
                                _inputWeight,
                            unit: unit,
                            onWeightApplied: (weight) {
                              setState(() {
                                _inputWeight = weight.clamp(0, 300);
                                _weightController.text = weight.toStringAsFixed(
                                  1,
                                );
                                _weightErrorText = null;
                              });
                            },
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        final v = double.tryParse(val);
                        if (v != null && v >= 0) {
                          setState(() {
                            _inputWeight = v.clamp(0, 300);
                            _weightErrorText = null;
                          });
                        }
                      },
                    ),
                    Slider(
                      value: _inputWeight.clamp(10, 200),
                      min: 10,
                      max: 200,
                      divisions: 38,
                      activeColor: colorScheme.primary,
                      inactiveColor: colorScheme.surfaceContainerHighest,
                      onChanged: (v) {
                        setState(() {
                          _inputWeight = v;
                          _weightController.text = v.toStringAsFixed(1);
                          _weightErrorText = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const ValueKey('workout_reps_field'),
                      controller: _repsController,
                      focusNode: _repsFocus,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Reps',
                        errorText: _repsErrorText,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (val) {
                        final v = int.tryParse(val);
                        if (v != null && v > 0) {
                          setState(() {
                            _inputReps = v.clamp(1, 50);
                            _repsErrorText = null;
                          });
                        }
                      },
                    ),
                    Slider(
                      value: _inputReps.clamp(1, 20).toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      activeColor: colorScheme.secondary,
                      inactiveColor: colorScheme.surfaceContainerHighest,
                      onChanged: (v) {
                        setState(() {
                          _inputReps = v.toInt();
                          _repsController.text = v.toInt().toString();
                          _repsErrorText = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('workout_superset_inline_launcher'),
                  onPressed: () => SupersetDropSetDialog.show(
                    context,
                    loggerStore: _loggerStore,
                    exercises: exercises,
                    initialExerciseId: _selectedExerciseId,
                  ),
                  icon: const Icon(Icons.layers_outlined, size: 16),
                  label: const Text(
                    'Superset / Drop Set',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  key: const ValueKey('workout_log_set_button'),
                  onPressed: _logSet,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Log Set',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetsList(dynamic session, ColorScheme colorScheme) {
    final sets = session?.sets ?? [];
    if (sets.isEmpty) {
      return Center(
        child: Text(
          'No sets logged yet. Adjust weight and tap Log Set.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: sets.length,
      itemBuilder: (context, index) {
        final set = sets[index];
        final ex = _exerciseStore.exercises
            .where((e) => e.id == set.exerciseId)
            .firstOrNull;

        return Dismissible(
          key: ValueKey(set.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: colorScheme.error.withValues(alpha: 0.3),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_outline, color: colorScheme.error),
          ),
          onDismissed: (_) => _loggerStore.removeSet(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: set.isCompleted
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : set.setType == SetType.superset
                    ? colorScheme.primary.withValues(alpha: 0.4)
                    : set.setType == SetType.dropSet
                    ? colorScheme.secondary.withValues(alpha: 0.4)
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: set.setType == SetType.superset
                        ? colorScheme.primaryContainer
                        : set.setType == SetType.dropSet
                        ? colorScheme.secondaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${set.setNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: set.setType == SetType.superset
                          ? colorScheme.onPrimaryContainer
                          : set.setType == SetType.dropSet
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ex?.name ?? 'Compound Lift',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (set.tagLabel != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: set.setType == SetType.superset
                                    ? colorScheme.primaryContainer
                                    : colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                set.tagLabel!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: set.setType == SetType.superset
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${set.weightKg.toStringAsFixed(1)} kg × ${set.reps} reps • RPE ${set.rpe.toStringAsFixed(1)} • 1RM: ${set.oneRepMaxEpley.toStringAsFixed(0)}kg',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _loggerStore.toggleSetCompletion(index),
                  icon: Icon(
                    set.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: set.isCompleted
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    bool isRestRunning,
    int restRemaining,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (isRestRunning)
            Expanded(
              child: GestureDetector(
                onTap: () => RestTimerDialog.show(context, _loggerStore),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _loggerStore.isTransitionTimer
                        ? colorScheme.tertiaryContainer
                        : colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _loggerStore.isTransitionTimer
                          ? colorScheme.tertiary
                          : colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _loggerStore.isTransitionTimer
                            ? Icons.bolt_rounded
                            : Icons.timer_outlined,
                        size: 15,
                        color: _loggerStore.isTransitionTimer
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _loggerStore.isTransitionTimer
                              ? 'Switch: ${restRemaining}s • ${_loggerStore.transitionTargetName ?? 'Next Stage'}'
                              : 'Rest: ${restRemaining}s',
                          style: TextStyle(
                            color: _loggerStore.isTransitionTimer
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => RestTimerDialog.show(context, _loggerStore),
                icon: const Icon(Icons.timer_outlined, size: 15),
                label: const Text(
                  'Rest Timer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _loggerStore.finishWorkout();
                if (context.mounted) {
                  AppFeedback.showSuccess(
                    context,
                    'Workout session saved to local SQLite database.',
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text(
                'Finish Workout',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _Stat({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
