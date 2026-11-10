import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/theme_store.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/nutrition_day.dart';
import '../stores/fasting_store.dart';
import '../stores/nutrition_store.dart';
import '../widgets/fasting_tracker_card.dart';
import '../widgets/hydration_tracker_card.dart';
import '../widgets/macro_progress_ring.dart';
import '../widgets/quick_add_food_dialog.dart';

class NutritionView extends StatefulWidget {
  const NutritionView({super.key});

  @override
  State<NutritionView> createState() => _NutritionViewState();
}

class _NutritionViewState extends State<NutritionView> {
  late final NutritionStore _store;
  late final FastingStore _fastingStore;
  final ThemeStore _themeStore = sl<ThemeStore>();

  @override
  void initState() {
    super.initState();
    _store = sl<NutritionStore>();
    _store.initialize();
    _fastingStore = sl<FastingStore>();
    _fastingStore.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final _ = _themeStore.themeMode;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final summary = _store.dailySummary;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: isLandscape ? 36 : null,
            title: Text(
              'Nutrition & Hydration Tracker',
              style: TextStyle(
                fontSize: isLandscape ? 13 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => QuickAddFoodDialog.show(context, _store),
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: colorScheme.primary,
                  size: isLandscape ? 18 : 22,
                ),
                tooltip: 'Log Food',
              ),
            ],
          ),
          body: OrientationBuilder(
            builder: (context, orientation) {
              final landscape = orientation == Orientation.landscape;

              if (summary == null) {
                return Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                );
              }

              if (landscape) {
                return SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Pane (35% width): Scrollable compact Macro Progress Rings + one-tap Hydration logger
                      Expanded(
                        flex: 35,
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              MacroProgressRing(
                                summary: summary,
                                isCompact: true,
                              ),
                              const SizedBox(height: 8),
                              HydrationTrackerCard(
                                store: _store,
                                isCompact: true,
                              ),
                              const SizedBox(height: 8),
                              FastingTrackerCard(
                                store: _fastingStore,
                                isCompact: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      VerticalDivider(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                      // Right Pane (65% width): Scrollable list of Meal slots with quick-add actions
                      Expanded(
                        flex: 65,
                        child: ListView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          children: _buildMealSlots(
                            summary.mealItems,
                            colorScheme,
                            isCompact: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SafeArea(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    MacroProgressRing(summary: summary),
                    const SizedBox(height: 14),
                    HydrationTrackerCard(store: _store),
                    const SizedBox(height: 14),
                    FastingTrackerCard(store: _fastingStore),
                    const SizedBox(height: 20),
                    Text(
                      'MEAL CATEGORIES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._buildMealSlots(summary.mealItems, colorScheme),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: isLandscape
              ? FloatingActionButton.small(
                  heroTag: 'fab_nutrition_add_small',
                  onPressed: () => QuickAddFoodDialog.show(context, _store),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  tooltip: 'Log Meal',
                  child: const Icon(Icons.add_rounded),
                )
              : FloatingActionButton.extended(
                  heroTag: 'fab_nutrition_add',
                  onPressed: () => QuickAddFoodDialog.show(context, _store),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Log Meal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
        );
      },
    );
  }

  List<Widget> _buildMealSlots(
    List<NutritionLogItem> items,
    ColorScheme colorScheme, {
    bool isCompact = false,
  }) {
    const categories = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];

    return categories.map((cat) {
      final slotItems = items.where((i) => i.mealType == cat).toList();
      final slotCalories = slotItems.fold(
        0.0,
        (acc, item) => acc + item.calories,
      );
      final slotProtein = slotItems.fold(
        0.0,
        (acc, item) => acc + item.proteinG,
      );

      return Card(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 10 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        cat,
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${slotCalories.toStringAsFixed(0)} kcal • ${slotProtein.toStringAsFixed(0)}g P',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => QuickAddFoodDialog.show(
                      context,
                      _store,
                      defaultMealSlot: cat,
                    ),
                    icon: Icon(
                      Icons.add_rounded,
                      size: isCompact ? 18 : 20,
                      color: colorScheme.primary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (slotItems.isNotEmpty) ...[
                const SizedBox(height: 6),
                Divider(color: colorScheme.outlineVariant),
                const SizedBox(height: 6),
                Column(
                  children: slotItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.foodName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${item.calories.toStringAsFixed(0)} kcal • ${item.proteinG.toStringAsFixed(0)}g P • ${item.carbsG.toStringAsFixed(0)}g C • ${item.fatG.toStringAsFixed(0)}g F',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _store.deleteFood(item.id);
                              AppFeedback.showInfo(
                                context,
                                '${item.foodName} removed from log',
                              );
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }
}
