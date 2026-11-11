import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'core/di/injection.dart';
import 'core/network/network_monitor.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_store.dart';
import 'core/widgets/adaptive_scaffold.dart';
import 'core/widgets/developer_debug_drawer.dart';
import 'presentation/ai_coach/views/ai_coach_view.dart';
import 'presentation/dashboard/views/dashboard_view.dart';
import 'presentation/exercise_workout/views/exercise_encyclopedia_view.dart';
import 'presentation/gps_running/views/gps_running_view.dart';
import 'presentation/nutrition/views/nutrition_view.dart';
import 'presentation/settings/views/settings_view.dart';
import 'presentation/social_feed/views/social_feed_view.dart';
import 'presentation/splash/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge transparent navigation & status bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  NetworkMonitor.instance.initialize();
  await configureDependencies();
  await sl<ThemeStore>().initialize();

  runApp(const FitoneApp());
}

class FitoneApp extends StatelessWidget {
  const FitoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeStore = sl<ThemeStore>();

    return Observer(
      builder: (_) {
        return MaterialApp(
          title: 'Fitone',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeStore.themeMode,
          home: const SplashView(),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardView(),
    ExerciseEncyclopediaView(),
    NutritionView(),
    GpsRunningView(),
    SocialFeedView(),
  ];

  final List<AdaptiveScaffoldDestination> _destinations = const [
    AdaptiveScaffoldDestination(
      label: 'Hub.',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onNavigationIndexChanged: (index) {
        setState(() => _currentIndex = index);
      },
      destinations: _destinations,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary, width: 1.5),
              ),
              child: Icon(
                Icons.bolt_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'FITONE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AiCoachView()));
            },
            icon: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
            tooltip: 'On-Device AI Coach',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
            },
            icon: Icon(
              Icons.settings_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Settings & Telemetry',
          ),
        ],
      ),
      endDrawer: const DeveloperDebugDrawer(),
      body: IndexedStack(index: _currentIndex, children: _pages),
    );
  }
}
