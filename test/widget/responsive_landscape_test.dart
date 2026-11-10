import 'package:fitone/core/widgets/adaptive_scaffold.dart';
import 'package:fitone/domain/entities/exercise.dart';
import 'package:fitone/presentation/dashboard/widgets/readiness_ring.dart';
import 'package:fitone/presentation/exercise_workout/widgets/exercise_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Adaptive Navigation & Responsive Landscape Tests', () {
    const destinations = [
      AdaptiveScaffoldDestination(
        label: 'Hub',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
      ),
      AdaptiveScaffoldDestination(
        label: 'Workouts',
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center_rounded,
      ),
      AdaptiveScaffoldDestination(
        label: 'Macros',
        icon: Icons.restaurant_menu_outlined,
        selectedIcon: Icons.restaurant_menu_rounded,
      ),
      AdaptiveScaffoldDestination(
        label: 'GPS Run',
        icon: Icons.directions_run_outlined,
        selectedIcon: Icons.directions_run_rounded,
      ),
      AdaptiveScaffoldDestination(
        label: 'Athletes',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups_rounded,
      ),
    ];

    testWidgets(
      'Portrait mode displays BottomNavigationBar and hides NavigationRail',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              currentIndex: 0,
              destinations: destinations,
              onNavigationIndexChanged: (_) {},
              body: const Center(child: Text('Portrait Viewport')),
            ),
          ),
        );

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
        expect(find.text('Portrait Viewport'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Landscape mode displays NavigationRail and suppresses NavigationBar without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              currentIndex: 0,
              destinations: destinations,
              onNavigationIndexChanged: (_) {},
              body: const Row(
                children: [
                  Expanded(
                    flex: 35,
                    child: SingleChildScrollView(
                      child: ReadinessRing(
                        score: 88,
                        hrvMs: 65,
                        restingHr: 54,
                        isCompact: true,
                      ),
                    ),
                  ),
                  VerticalDivider(),
                  Expanded(
                    flex: 65,
                    child: Center(child: Text('Landscape Master Detail Pane')),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Landscape Master Detail Pane'), findsOneWidget);
        expect(find.text('RECOVERY & READINESS'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Ultra-short landscape viewport (800x360) renders without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: AdaptiveScaffold(
              currentIndex: 0,
              destinations: destinations,
              appBar: AppBar(
                title: const Text('FITONE ECOSYSTEM'),
                actions: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              onNavigationIndexChanged: (_) {},
              body: Row(
                children: [
                  const Expanded(
                    flex: 35,
                    child: SingleChildScrollView(
                      physics: ClampingScrollPhysics(),
                      child: Column(
                        children: [
                          ReadinessRing(
                            score: 95,
                            hrvMs: 78,
                            restingHr: 50,
                            isCompact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    flex: 65,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        children: List.generate(
                          6,
                          (index) => Container(
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.blueGrey,
                            child: Center(child: Text('Card $index')),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('FITONE ECOSYSTEM'), findsOneWidget);
        expect(find.text('RECOVERY & READINESS'), findsOneWidget);
        expect(find.text('Card 0'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Exercise card grid renders with zero RenderFlex overflow on an 800x360 landscape viewport',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final exercises = [
          const Exercise(
            id: 'ex_1',
            name: 'Barbell Incline Bench Press',
            bodyPart: 'Chest',
            equipment: 'Barbell',
            targetMuscles: 'Upper Pectoralis, Anterior Deltoid',
            instructions: 'Lower bar to clavicle under tension.',
            difficulty: 'Intermediate',
          ),
          const Exercise(
            id: 'ex_2',
            name: 'Romanian Deadlift',
            bodyPart: 'Legs',
            equipment: 'Barbell',
            targetMuscles: 'Hamstrings, Gluteus Maximus',
            instructions:
                'Hinge hips backwards while maintaining neutral spine.',
            difficulty: 'Advanced',
          ),
          const Exercise(
            id: 'ex_3',
            name: 'Seated Cable Row',
            bodyPart: 'Back',
            equipment: 'Machine',
            targetMuscles: 'Latissimus Dorsi, Rhomboids',
            instructions: 'Retract scapulae and pull to lower sternum.',
            difficulty: 'Beginner',
          ),
          const Exercise(
            id: 'ex_4',
            name: 'Dumbbell Lateral Raise',
            bodyPart: 'Shoulders',
            equipment: 'Dumbbell',
            targetMuscles: 'Lateral Deltoid',
            instructions: 'Raise dumbbells in scapular plane.',
            difficulty: 'Beginner',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 135,
                ),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  return ExerciseCard(
                    exercise: exercises[index],
                    isCompact: true,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ExerciseCard), findsNWidgets(4));
        expect(find.text('Barbell Incline Bench Press'), findsOneWidget);
        expect(find.text('Romanian Deadlift'), findsOneWidget);
        expect(find.text('Seated Cable Row'), findsOneWidget);
        expect(find.text('Dumbbell Lateral Raise'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
