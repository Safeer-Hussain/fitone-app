import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/database/app_database.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/theme_store.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/developer_debug_drawer.dart';
import '../../exercise_workout/stores/workout_logger_store.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeStore = sl<ThemeStore>();

    return Observer(
      builder: (_) {
        final _ = themeStore.themeMode;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        final loggerStore = sl<WorkoutLoggerStore>();

        return Scaffold(
          appBar: AppBar(title: const Text('Settings & Wearable System')),
          endDrawer: const DeveloperDebugDrawer(),
          body: Builder(
            builder: (scaffoldContext) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'SYSTEM & APPEARANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          title: Text(
                            'Dark Mode Palette',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'High-contrast obsidian and emerald green UI',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          value: themeStore.isDarkMode,
                          activeColor: colorScheme.primary,
                          onChanged: (_) {
                            themeStore.toggleTheme();
                            AppFeedback.showSuccess(
                              context,
                              themeStore.isDarkMode
                                  ? 'Dark obsidian theme activated'
                                  : 'Light high-contrast theme activated',
                            );
                          },
                        ),
                        Divider(color: colorScheme.outlineVariant),
                        ListTile(
                          title: Text(
                            'Biometric Unit Standard',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            loggerStore.unit == 'kg'
                                ? 'Metric (kg, km, Celsius)'
                                : 'Imperial (lbs, miles, Fahrenheit)',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              loggerStore.unit.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          onTap: () {
                            loggerStore.toggleUnit();
                            AppFeedback.showSuccess(
                              context,
                              'Biometric units switched to ${loggerStore.unit == 'kg' ? 'Metric (kg, km)' : 'Imperial (lbs, miles)'}',
                            );
                          },
                        ),
                        Divider(color: colorScheme.outlineVariant),
                        ListTile(
                          leading: Icon(
                            Icons.cleaning_services_rounded,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            'Purge Telemetry & Cache',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Clear transient workout and run logs, keep seed data',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onTap: () async {
                            final db = await AppDatabase.instance.database;
                            await db.delete('workouts');
                            await db.delete('workout_sets');
                            await db.delete('running_routes');
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                'Local telemetry and session cache purged',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'WEARABLE HARDWARE INTEGRATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.cable_rounded,
                            color: colorScheme.secondary,
                          ),
                          title: Text(
                            'Dual Native Hardware Bridges',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'Kotlin MethodChannel + Swift EventChannel',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Divider(color: colorScheme.outlineVariant),
                        ListTile(
                          leading: Icon(
                            Icons.storage_rounded,
                            color: colorScheme.tertiary,
                          ),
                          title: Text(
                            'Offline-First Architecture',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            'SQLite cache + Dio mock latency interceptor',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            'SYNCED',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'RECRUITER & DEVELOPER TOOLS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.developer_mode_rounded,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        'Open Recruiter Debug Drawer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Toggle 503 errors, simulated latency, & telemetry rate',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onTap: () {
                        Scaffold.of(scaffoldContext).openEndDrawer();
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: GestureDetector(
                      onLongPress: () {
                        Scaffold.of(scaffoldContext).openEndDrawer();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Fitone Ecosystem v1.0.0 (Production Build 100)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Long press to open Developer & Recruiter Drawer',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
