import 'package:flutter/material.dart';

import 'barbell_plate_calculator_sheet.dart';

class OneRmCalculatorSheet extends StatefulWidget {
  final double initialWeight;
  final int initialReps;

  const OneRmCalculatorSheet({
    super.key,
    this.initialWeight = 100.0,
    this.initialReps = 5,
  });

  static void show(
    BuildContext context, {
    double initialWeight = 100.0,
    int initialReps = 5,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OneRmCalculatorSheet(
        initialWeight: initialWeight,
        initialReps: initialReps,
      ),
    );
  }

  @override
  State<OneRmCalculatorSheet> createState() => _OneRmCalculatorSheetState();
}

class _OneRmCalculatorSheetState extends State<OneRmCalculatorSheet> {
  late double _weight;
  late int _reps;

  @override
  void initState() {
    super.initState();
    _weight = widget.initialWeight;
    _reps = widget.initialReps;
  }

  double get _epley1Rm => _reps <= 1 ? _weight : _weight * (1.0 + _reps / 30.0);
  double get _brzycki1Rm =>
      _reps >= 37 ? _weight : _weight / (1.0278 - (0.0278 * _reps));
  double get _avg1Rm => (_epley1Rm + _brzycki1Rm) / 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'One-Rep Max (1RM) Engine',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.fitness_center_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weight: ${_weight.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Slider(
                              value: _weight,
                              min: 20,
                              max: 250,
                              divisions: 46,
                              activeColor: colorScheme.primary,
                              inactiveColor: colorScheme.surfaceContainer,
                              onChanged: (val) => setState(() => _weight = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reps: $_reps',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Slider(
                              value: _reps.toDouble(),
                              min: 1,
                              max: 15,
                              divisions: 14,
                              activeColor: colorScheme.secondary,
                              inactiveColor: colorScheme.surfaceContainer,
                              onChanged: (val) =>
                                  setState(() => _reps = val.round()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _CalculationMetric(
                          label: 'Epley Formula',
                          value: '${_epley1Rm.toStringAsFixed(1)} kg',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: colorScheme.outlineVariant,
                        ),
                        _CalculationMetric(
                          label: 'Brzycki Formula',
                          value: '${_brzycki1Rm.toStringAsFixed(1)} kg',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: colorScheme.outlineVariant,
                        ),
                        _CalculationMetric(
                          label: 'Consensus 1RM',
                          value: '${_avg1Rm.toStringAsFixed(1)} kg',
                          isHighlighted: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'PROGRESSIVE OVERLOAD LOADINGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PercentPill(
                        pct: '90%',
                        weight: '${(_avg1Rm * 0.90).toStringAsFixed(1)} kg',
                        rawWeight: _avg1Rm * 0.90,
                        reps: '3-4 reps',
                      ),
                      _PercentPill(
                        pct: '85%',
                        weight: '${(_avg1Rm * 0.85).toStringAsFixed(1)} kg',
                        rawWeight: _avg1Rm * 0.85,
                        reps: '5-6 reps',
                      ),
                      _PercentPill(
                        pct: '80%',
                        weight: '${(_avg1Rm * 0.80).toStringAsFixed(1)} kg',
                        rawWeight: _avg1Rm * 0.80,
                        reps: '7-8 reps',
                      ),
                      _PercentPill(
                        pct: '70%',
                        weight: '${(_avg1Rm * 0.70).toStringAsFixed(1)} kg',
                        rawWeight: _avg1Rm * 0.70,
                        reps: '10-12 reps',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculationMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _CalculationMetric({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isHighlighted ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _PercentPill extends StatelessWidget {
  final String pct;
  final String weight;
  final double rawWeight;
  final String reps;

  const _PercentPill({
    required this.pct,
    required this.weight,
    required this.rawWeight,
    required this.reps,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () =>
            BarbellPlateCalculatorSheet.show(context, initialWeight: rawWeight),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Text(
                pct,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                weight,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                reps,
                style: TextStyle(
                  fontSize: 9,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
