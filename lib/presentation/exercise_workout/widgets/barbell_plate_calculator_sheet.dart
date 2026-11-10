import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fitone/core/utils/app_feedback.dart';
import 'package:fitone/domain/entities/barbell_plate.dart';

class BarbellPlateCalculatorSheet extends StatefulWidget {
  final double initialWeight;
  final String unit;
  final ValueChanged<double>? onWeightApplied;

  const BarbellPlateCalculatorSheet({
    super.key,
    this.initialWeight = 100.0,
    this.unit = 'kg',
    this.onWeightApplied,
  });

  static void show(
    BuildContext context, {
    double initialWeight = 100.0,
    String unit = 'kg',
    ValueChanged<double>? onWeightApplied,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarbellPlateCalculatorSheet(
        initialWeight: initialWeight,
        unit: unit,
        onWeightApplied: onWeightApplied,
      ),
    );
  }

  @override
  State<BarbellPlateCalculatorSheet> createState() =>
      _BarbellPlateCalculatorSheetState();
}

class _BarbellPlateCalculatorSheetState
    extends State<BarbellPlateCalculatorSheet> {
  late BarbellUnit _unit;
  late double _targetWeight;
  late double _barWeight;

  @override
  void initState() {
    super.initState();
    _unit = widget.unit.toLowerCase() == 'lbs'
        ? BarbellUnit.lbs
        : BarbellUnit.kg;
    _targetWeight = widget.initialWeight > 0
        ? widget.initialWeight
        : (_unit == BarbellUnit.kg ? 100.0 : 225.0);
    _barWeight = _unit == BarbellUnit.kg
        ? BarbellPlateCalculator.defaultBarWeightKg
        : BarbellPlateCalculator.defaultBarWeightLbs;
  }

  void _toggleUnit() {
    setState(() {
      if (_unit == BarbellUnit.kg) {
        _unit = BarbellUnit.lbs;
        _targetWeight = double.parse(
          (_targetWeight * 2.20462).round().toString(),
        );
        _barWeight = 45.0;
      } else {
        _unit = BarbellUnit.kg;
        _targetWeight = double.parse(
          (_targetWeight / 2.20462).round().toString(),
        );
        _barWeight = 20.0;
      }
    });
  }

  void _adjustWeight(double delta) {
    setState(() {
      _targetWeight = double.parse((_targetWeight + delta).toStringAsFixed(2));
      if (_targetWeight < 0) _targetWeight = 0.0;
    });
  }

  void _setBarWeight(double weight) {
    setState(() {
      _barWeight = weight;
    });
  }

  void _setTargetWeight(double weight) {
    setState(() {
      _targetWeight = weight;
    });
  }

  void _showCustomWeightDialog() {
    final controller = TextEditingController(
      text: _targetWeight.toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            'Enter Target Weight (${_unit == BarbellUnit.kg ? 'KG' : 'LBS'})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              suffixText: _unit == BarbellUnit.kg ? 'kg' : 'lbs',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.trim());
                if (parsed != null && parsed >= 0) {
                  setState(() => _targetWeight = parsed);
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Set Weight'),
            ),
          ],
        );
      },
    );
  }

  void _copyBreakdown(BarbellPlateResult result) {
    Clipboard.setData(ClipboardData(text: result.summaryDescription));
    AppFeedback.showSuccess(context, 'Plate configuration copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final result = BarbellPlateCalculator.calculate(
      targetWeight: _targetWeight,
      barWeight: _barWeight,
      unit: _unit,
    );

    final unitStr = _unit == BarbellUnit.kg ? 'kg' : 'lbs';

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
                      Icons.fitness_center_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Plate Loading Calculator',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _toggleUnit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: colorScheme.primary),
                      ),
                      child: Text(
                        _unit == BarbellUnit.kg ? 'KG' : 'LBS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: isLandscape
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  _buildTargetWeightHero(colorScheme, unitStr),
                                  const SizedBox(height: 12),
                                  _buildBarWeightSelector(colorScheme, unitStr),
                                  const SizedBox(height: 12),
                                  _buildQuickStepButtons(colorScheme),
                                  const SizedBox(height: 12),
                                  _buildPresetChips(colorScheme, unitStr),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _buildVisualBarbellCard(
                                    result,
                                    colorScheme,
                                    unitStr,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildBreakdownSummary(
                                    result,
                                    colorScheme,
                                    unitStr,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildActionButtons(result, colorScheme),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildTargetWeightHero(colorScheme, unitStr),
                            const SizedBox(height: 16),
                            _buildVisualBarbellCard(
                              result,
                              colorScheme,
                              unitStr,
                            ),
                            const SizedBox(height: 16),
                            _buildBreakdownSummary(
                              result,
                              colorScheme,
                              unitStr,
                            ),
                            const SizedBox(height: 16),
                            _buildBarWeightSelector(colorScheme, unitStr),
                            const SizedBox(height: 16),
                            _buildQuickStepButtons(colorScheme),
                            const SizedBox(height: 16),
                            _buildPresetChips(colorScheme, unitStr),
                            const SizedBox(height: 20),
                            _buildActionButtons(result, colorScheme),
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

  Widget _buildTargetWeightHero(ColorScheme colorScheme, String unitStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TARGET LOAD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _targetWeight.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    unitStr.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton.filledTonal(
            onPressed: _showCustomWeightDialog,
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Type Exact Weight',
          ),
        ],
      ),
    );
  }

  Widget _buildVisualBarbellCard(
    BarbellPlateResult result,
    ColorScheme colorScheme,
    String unitStr,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'OLYMPIC SLEEVE (ONE SIDE)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                '${result.loadedWeightPerSide.toStringAsFixed(2)} $unitStr per side',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: _OlympicBarbellGraphic(
                  result: result,
                  colorScheme: colorScheme,
                  unitStr: unitStr,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSummary(
    BarbellPlateResult result,
    ColorScheme colorScheme,
    String unitStr,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'PLATE CONFIGURATION (PER SIDE)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${result.totalPlatesPerSide} plates total',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (result.platesPerSide.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Empty sleeve. No plates required.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.platesPerSide.map((lp) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: lp.plate.color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: lp.plate.color),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: lp.plate.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${lp.plate.label} $unitStr × ${lp.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (!result.isExact) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.error.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unachievable Remainder: ${result.remainder.toStringAsFixed(2)} $unitStr. Nearest achievable load with standard plates is ${result.totalWeightLoaded.toStringAsFixed(1)} $unitStr.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarWeightSelector(ColorScheme colorScheme, String unitStr) {
    final barsKg = [20.0, 15.0, 10.0];
    final barsLbs = [45.0, 35.0, 25.0];
    final bars = _unit == BarbellUnit.kg ? barsKg : barsLbs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BARBELL SPECIFICATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: bars.map((b) {
              final isSelected = (_barWeight - b).abs() < 0.1;
              final label = _unit == BarbellUnit.kg
                  ? (b == 20.0
                        ? '20kg Olympic'
                        : (b == 15.0 ? '15kg Women\'s' : '10kg Technique'))
                  : (b == 45.0
                        ? '45lb Olympic'
                        : (b == 35.0 ? '35lb Women\'s' : '25lb Technique'));

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: colorScheme.primary,
                  onSelected: (_) => _setBarWeight(b),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStepButtons(ColorScheme colorScheme) {
    final stepsKg = [
      -20.0,
      -10.0,
      -5.0,
      -2.5,
      -1.25,
      1.25,
      2.5,
      5.0,
      10.0,
      20.0,
    ];
    final stepsLbs = [
      -45.0,
      -25.0,
      -10.0,
      -5.0,
      -2.5,
      2.5,
      5.0,
      10.0,
      25.0,
      45.0,
    ];
    final steps = _unit == BarbellUnit.kg ? stepsKg : stepsLbs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ADJUSTMENTS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: steps.map((s) {
              final isPositive = s > 0;
              final text =
                  '${isPositive ? '+' : ''}${s.toStringAsFixed(s.truncateToDouble() == s ? 0 : 2)}';
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(
                    text,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPositive
                          ? colorScheme.primary
                          : colorScheme.error,
                    ),
                  ),
                  side: BorderSide(
                    color: isPositive
                        ? colorScheme.primary.withOpacity(0.4)
                        : colorScheme.error.withOpacity(0.4),
                  ),
                  onPressed: () => _adjustWeight(s),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChips(ColorScheme colorScheme, String unitStr) {
    final presetsKg = [40.0, 60.0, 80.0, 100.0, 120.0, 140.0, 180.0, 220.0];
    final presetsLbs = [95.0, 135.0, 185.0, 225.0, 275.0, 315.0, 365.0, 405.0];
    final presets = _unit == BarbellUnit.kg ? presetsKg : presetsLbs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BENCHMARK TARGET PRESETS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: presets.map((p) {
              final isSelected = (_targetWeight - p).abs() < 0.1;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(
                    '${p.toInt()} $unitStr',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: colorScheme.primary,
                  onSelected: (_) => _setTargetWeight(p),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BarbellPlateResult result,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _copyBreakdown(result),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Breakdown'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (widget.onWeightApplied != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onWeightApplied!(result.totalWeightLoaded);
                Navigator.of(context).pop();
                AppFeedback.showSuccess(
                  context,
                  'Applied ${result.totalWeightLoaded.toStringAsFixed(1)}${_unit == BarbellUnit.kg ? 'kg' : 'lbs'} to active set',
                );
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Apply Weight'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OlympicBarbellGraphic extends StatelessWidget {
  final BarbellPlateResult result;
  final ColorScheme colorScheme;
  final String unitStr;

  const _OlympicBarbellGraphic({
    required this.result,
    required this.colorScheme,
    required this.unitStr,
  });

  @override
  Widget build(BuildContext context) {
    final flattenedPlates = result.flattenedPlatesInsideOut;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left shaft
        Container(
          width: 32,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade400,
                Colors.grey.shade200,
                Colors.grey.shade500,
              ],
            ),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(4),
            ),
            border: Border.all(color: Colors.grey.shade600, width: 0.5),
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 18,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(color: Colors.grey.shade700, width: 1),
                ),
              ),
            ),
          ),
        ),

        // Inner Collar Stop
        Container(
          width: 12,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade500,
                Colors.grey.shade300,
                Colors.grey.shade700,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.grey.shade800, width: 0.5),
          ),
        ),

        // Loaded Plates
        if (flattenedPlates.isEmpty)
          Container(
            width: 140,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade200,
                  Colors.grey.shade500,
                ],
              ),
              border: Border.all(color: Colors.grey.shade600, width: 0.5),
            ),
            child: const Center(
              child: Text(
                'EMPTY SLEEVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Colors.black54,
                ),
              ),
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: flattenedPlates.map((plate) {
              final height = 110.0 * plate.heightFactor;
              final width = 16.0 * plate.widthFactor;

              return Padding(
                padding: const EdgeInsets.only(right: 1.5),
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: plate.color,
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        plate.color.withOpacity(0.9),
                        plate.color,
                        plate.color.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.black.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        plate.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: plate.textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        // Collar Clamp (Lock-jaw)
        Container(
          width: 10,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: colorScheme.onPrimary.withOpacity(0.4),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Container(
              width: 3,
              height: 18,
              color: colorScheme.onPrimary.withOpacity(0.7),
            ),
          ),
        ),

        // Remaining Sleeve Tip
        Container(
          width: 20,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade400,
                Colors.grey.shade200,
                Colors.grey.shade500,
              ],
            ),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(3),
            ),
            border: Border.all(color: Colors.grey.shade600, width: 0.5),
          ),
        ),
      ],
    );
  }
}
