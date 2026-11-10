import 'package:flutter/material.dart';

import '../../../core/utils/app_feedback.dart';
import '../stores/nutrition_store.dart';

class QuickAddFoodDialog extends StatefulWidget {
  final NutritionStore store;
  final String defaultMealSlot;

  const QuickAddFoodDialog({
    super.key,
    required this.store,
    this.defaultMealSlot = 'Breakfast',
  });

  static void show(
    BuildContext context,
    NutritionStore store, {
    String defaultMealSlot = 'Breakfast',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          QuickAddFoodDialog(store: store, defaultMealSlot: defaultMealSlot),
    );
  }

  @override
  State<QuickAddFoodDialog> createState() => _QuickAddFoodDialogState();
}

class _QuickAddFoodDialogState extends State<QuickAddFoodDialog> {
  late String _mealSlot;
  final _foodNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  final _foodNameFocus = FocusNode();
  final _caloriesFocus = FocusNode();
  final _proteinFocus = FocusNode();
  final _carbsFocus = FocusNode();
  final _fatFocus = FocusNode();

  String? _foodNameError;
  String? _caloriesError;
  String? _proteinError;
  String? _carbsError;
  String? _fatError;

  final List<Map<String, dynamic>> _quickTemplates = const [
    {'name': 'Chicken Breast (200g)', 'cal': 330, 'p': 62, 'c': 0, 'f': 7},
    {'name': 'Eggs (3 Large)', 'cal': 215, 'p': 19, 'c': 1, 'f': 15},
    {'name': 'Whey Protein Scoop (30g)', 'cal': 120, 'p': 25, 'c': 2, 'f': 1.5},
    {
      'name': 'Jasmine Rice Cooked (200g)',
      'cal': 260,
      'p': 5,
      'c': 57,
      'f': 0.5,
    },
    {'name': 'Greek Yogurt 0% (250g)', 'cal': 140, 'p': 25, 'c': 9, 'f': 0},
    {'name': 'Avocado (100g)', 'cal': 160, 'p': 2, 'c': 9, 'f': 15},
  ];

  @override
  void initState() {
    super.initState();
    _mealSlot = widget.defaultMealSlot;
    _attachAutoScroll(_foodNameFocus);
    _attachAutoScroll(_caloriesFocus);
    _attachAutoScroll(_proteinFocus);
    _attachAutoScroll(_carbsFocus);
    _attachAutoScroll(_fatFocus);
  }

  void _attachAutoScroll(FocusNode node) {
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
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();

    _foodNameFocus.dispose();
    _caloriesFocus.dispose();
    _proteinFocus.dispose();
    _carbsFocus.dispose();
    _fatFocus.dispose();

    super.dispose();
  }

  void _applyTemplate(Map<String, dynamic> t) {
    setState(() {
      _foodNameController.text = t['name'] as String;
      _caloriesController.text = (t['cal'] as num).toString();
      _proteinController.text = (t['p'] as num).toString();
      _carbsController.text = (t['c'] as num).toString();
      _fatController.text = (t['f'] as num).toString();

      _foodNameError = null;
      _caloriesError = null;
      _proteinError = null;
      _carbsError = null;
      _fatError = null;
    });
    AppFeedback.showInfo(context, 'Autofilled preset: ${t['name']}');
  }

  Future<void> _submitFoodLog() async {
    final name = _foodNameController.text.trim();
    final calText = _caloriesController.text.trim();
    final pText = _proteinController.text.trim();
    final cText = _carbsController.text.trim();
    final fText = _fatController.text.trim();

    bool hasError = false;
    String? nameErr;
    String? calErr;
    String? pErr;
    String? cErr;
    String? fErr;

    if (name.isEmpty) {
      nameErr = 'Food or item name is required.';
      hasError = true;
    }

    final cal = double.tryParse(calText);
    if (calText.isEmpty || cal == null || cal <= 0) {
      calErr = 'Enter a calorie value greater than 0.';
      hasError = true;
    }

    double protein = 0.0;
    if (pText.isNotEmpty) {
      final parsedP = double.tryParse(pText);
      if (parsedP == null || parsedP < 0) {
        pErr = 'Invalid protein value';
        hasError = true;
      } else {
        protein = parsedP;
      }
    }

    double carbs = 0.0;
    if (cText.isNotEmpty) {
      final parsedC = double.tryParse(cText);
      if (parsedC == null || parsedC < 0) {
        cErr = 'Invalid carbs value';
        hasError = true;
      } else {
        carbs = parsedC;
      }
    }

    double fat = 0.0;
    if (fText.isNotEmpty) {
      final parsedF = double.tryParse(fText);
      if (parsedF == null || parsedF < 0) {
        fErr = 'Invalid fat value';
        hasError = true;
      } else {
        fat = parsedF;
      }
    }

    if (hasError) {
      setState(() {
        _foodNameError = nameErr;
        _caloriesError = calErr;
        _proteinError = pErr;
        _carbsError = cErr;
        _fatError = fErr;
      });
      return;
    }

    await widget.store.addFood(
      mealType: _mealSlot,
      foodName: name,
      calories: cal!,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    );

    if (mounted) {
      AppFeedback.showSuccess(
        context,
        'Logged $name (+${cal.toStringAsFixed(0)} kcal) to $_mealSlot',
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Log Nutritional Macro Intake',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.restaurant_menu_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'POPULAR MACRO PRESETS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _quickTemplates.map((t) {
                      return ActionChip(
                        label: Text(
                          t['name'] as String,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () => _applyTemplate(t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _mealSlot,
                    decoration: const InputDecoration(
                      labelText: 'Meal Category',
                    ),
                    dropdownColor: colorScheme.surface,
                    items: const [
                      DropdownMenuItem(
                        value: 'Breakfast',
                        child: Text('Breakfast'),
                      ),
                      DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                      DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                      DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _mealSlot = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('food_name_field'),
                    controller: _foodNameController,
                    focusNode: _foodNameFocus,
                    decoration: InputDecoration(
                      labelText: 'Food Name / Description',
                      errorText: _foodNameError,
                    ),
                    onChanged: (_) {
                      if (_foodNameError != null) {
                        setState(() => _foodNameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('calories_field'),
                          controller: _caloriesController,
                          focusNode: _caloriesFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Calories (kcal)',
                            errorText: _caloriesError,
                          ),
                          onChanged: (_) {
                            if (_caloriesError != null) {
                              setState(() => _caloriesError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          key: const ValueKey('protein_field'),
                          controller: _proteinController,
                          focusNode: _proteinFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Protein (g)',
                            errorText: _proteinError,
                          ),
                          onChanged: (_) {
                            if (_proteinError != null) {
                              setState(() => _proteinError = null);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('carbs_field'),
                          controller: _carbsController,
                          focusNode: _carbsFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Carbs (g)',
                            errorText: _carbsError,
                          ),
                          onChanged: (_) {
                            if (_carbsError != null) {
                              setState(() => _carbsError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          key: const ValueKey('fat_field'),
                          controller: _fatController,
                          focusNode: _fatFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Fats (g)',
                            errorText: _fatError,
                          ),
                          onChanged: (_) {
                            if (_fatError != null) {
                              setState(() => _fatError = null);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const ValueKey('add_food_submit_button'),
                      onPressed: _submitFoodLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Add to Food Log',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
