import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/theme_store.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../stores/exercise_store.dart';
import '../widgets/exercise_card.dart';
import 'exercise_detail_view.dart';
import 'workout_logger_view.dart';

class ExerciseEncyclopediaView extends StatefulWidget {
  const ExerciseEncyclopediaView({super.key});

  @override
  State<ExerciseEncyclopediaView> createState() =>
      _ExerciseEncyclopediaViewState();
}

class _ExerciseEncyclopediaViewState extends State<ExerciseEncyclopediaView> {
  late final ExerciseStore _store;
  final ThemeStore _themeStore = sl<ThemeStore>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _store = sl<ExerciseStore>();
    _store.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final _ = _themeStore.themeMode;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: isLandscape ? 36 : null,
              title: Text(
                'Exercise Encyclopedia & Programs',
                style: TextStyle(
                  fontSize: isLandscape ? 13 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              bottom: TabBar(
                isScrollable: isLandscape,
                tabAlignment: isLandscape ? TabAlignment.start : null,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Encyclopedia (60+)'),
                  Tab(text: 'Routines & Plans'),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WorkoutLoggerView(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.fitness_center_rounded,
                    color: colorScheme.primary,
                    size: isLandscape ? 18 : 22,
                  ),
                  tooltip: 'Launch Active Logger',
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _buildEncyclopediaTab(context, isLandscape),
                _buildWorkoutPlansTab(context, isLandscape),
              ],
            ),
            floatingActionButton: isLandscape
                ? FloatingActionButton.small(
                    heroTag: 'fab_exercise_encyclopedia_small',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WorkoutLoggerView(),
                        ),
                      );
                    },
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    tooltip: 'Start Workout',
                    child: const Icon(Icons.play_arrow_rounded),
                  )
                : FloatingActionButton.extended(
                    heroTag: 'fab_exercise_encyclopedia',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WorkoutLoggerView(),
                        ),
                      );
                    },
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'Start Workout',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEncyclopediaTab(BuildContext context, bool isLandscape) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLandscape) {
      return Row(
        children: [
          // Left Pane (30% width): Scrollable vertical filter sidebar
          Expanded(
            flex: 30,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TARGET MUSCLE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Observer(
                    builder: (_) => Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _store.bodyParts.map((part) {
                        final isSelected = _store.selectedBodyPart == part;
                        return FilterChip(
                          label: Text(
                            part,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                          selected: isSelected,
                          onSelected: (_) => _store.setBodyPart(part),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'EQUIPMENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Observer(
                    builder: (_) => Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _store.equipmentList.map((eq) {
                        final isSelected = _store.selectedEquipment == eq;
                        return ChoiceChip(
                          label: Text(eq, style: const TextStyle(fontSize: 11)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                          selected: isSelected,
                          onSelected: (_) => _store.setEquipment(eq),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          // Right Pane (70% width): Responsive GridView with search pinned at top
          Expanded(
            flex: 70,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _store.onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search 60+ exercises...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _store.onSearchChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Observer(
                    builder: (_) {
                      if (_store.isLoading) {
                        return ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: 4,
                          itemBuilder: (_, __) => const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: ShimmerLoader(
                              width: double.infinity,
                              height: 70,
                            ),
                          ),
                        );
                      }

                      if (_store.hasError) {
                        return ErrorRetryView(
                          message: _store.errorMessage.isNotEmpty
                              ? _store.errorMessage
                              : 'Unable to connect to exercise database.',
                          onRetry: () => _store.loadExercises(),
                        );
                      }

                      final exercises = _store.exercises;
                      if (exercises.isEmpty) {
                        return Center(
                          child: Text(
                            'No exercises found matching criteria.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              mainAxisExtent: 135,
                            ),
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final ex = exercises[index];
                          return ExerciseCard(
                            exercise: ex,
                            isCompact: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExerciseDetailView(exercise: ex),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _store.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search 60+ exercises or target muscles...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _store.onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(
          height: 38,
          child: Observer(
            builder: (_) {
              final selectedPart = _store.selectedBodyPart;
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _store.bodyParts.map((part) {
                  final isSelected = selectedPart == part;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(part),
                      selected: isSelected,
                      onSelected: (_) => _store.setBodyPart(part),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: Observer(
            builder: (_) {
              final selectedEq = _store.selectedEquipment;
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _store.equipmentList.map((eq) {
                  final isSelected = selectedEq == eq;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(eq),
                      selected: isSelected,
                      onSelected: (_) => _store.setEquipment(eq),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Observer(
            builder: (_) {
              if (_store.isLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerLoader(width: double.infinity, height: 90),
                  ),
                );
              }

              if (_store.hasError) {
                return ErrorRetryView(
                  message: _store.errorMessage.isNotEmpty
                      ? _store.errorMessage
                      : 'Unable to connect to exercise database.',
                  onRetry: () => _store.loadExercises(),
                );
              }

              final exercises = _store.exercises;
              if (exercises.isEmpty) {
                return Center(
                  child: Text(
                    'No exercises found matching criteria.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                );
              }

              return ListView.builder(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  return ExerciseCard(
                    exercise: ex,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ExerciseDetailView(exercise: ex),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutPlansTab(BuildContext context, bool isLandscape) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Observer(
      builder: (_) {
        final plans = _store.workoutPlans;
        if (plans.isEmpty) {
          return Center(
            child: Text(
              'No workout plans loaded.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        Widget buildPlanCard(dynamic plan) {
          return Card(
            margin: isLandscape
                ? EdgeInsets.zero
                : const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(isLandscape ? 12 : 18),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isLandscape ? 14 : 17,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${plan.daysPerWeek} Days/Wk',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(color: colorScheme.outlineVariant),
                    const SizedBox(height: 6),
                    Column(
                      children: (plan.schedule as List).map<Widget>((dayMap) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dayMap['day'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${dayMap['focus']} (${dayMap['exerciseCount']} exercises)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (isLandscape) {
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: plans.length,
            itemBuilder: (context, index) => buildPlanCard(plans[index]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (context, index) => buildPlanCard(plans[index]),
        );
      },
    );
  }
}
