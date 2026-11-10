import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../database/app_database.dart';
import '../network/network_monitor.dart';
import '../utils/app_feedback.dart';

class DeveloperDebugDrawer extends StatelessWidget {
  const DeveloperDebugDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final monitor = NetworkMonitor.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.terminal_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Developer & Recruiter Hub',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Telemetry, Latency & Error Injection',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'NETWORK SIMULATION',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Observer(
                    builder: (_) => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Force API Error (503)',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Tests Dio interceptor error handling & retry UI',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: monitor.forceApiError,
                      activeThumbColor: colorScheme.error,
                      onChanged: (val) {
                        monitor.setForceApiError(val);
                        AppFeedback.showWarning(
                          context,
                          val
                              ? 'API 503 error injection activated'
                              : 'API 503 error injection deactivated',
                        );
                      },
                    ),
                  ),
                  Divider(color: colorScheme.outlineVariant),
                  Observer(
                    builder: (_) => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Simulate Offline Mode',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Forces local SQLite database cache usage',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: !monitor.isOnline,
                      activeThumbColor: const Color(0xFFF59E0B),
                      onChanged: (val) {
                        monitor.setManualOnlineState(!val);
                        AppFeedback.showInfo(
                          context,
                          val
                              ? 'Simulating offline SQLite mode'
                              : 'Simulating online network connection',
                        );
                      },
                    ),
                  ),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Observer(
                    builder: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Simulated Network Latency',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${monitor.simulatedLatencyMs} ms',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: monitor.simulatedLatencyMs.toDouble(),
                          min: 0,
                          max: 2000,
                          divisions: 20,
                          activeColor: colorScheme.primary,
                          inactiveColor: colorScheme.surfaceContainer,
                          onChanged: (val) =>
                              monitor.setSimulatedLatency(val.toInt()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'WEARABLE TELEMETRY RATE',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Observer(
                    builder: (_) => Row(
                      children: [
                        _TelemetryChip(
                          label: '500ms (High)',
                          isSelected: monitor.telemetryIntervalMs == 500,
                          onTap: () {
                            monitor.setTelemetryInterval(500);
                            AppFeedback.showSuccess(
                              context,
                              'Telemetry rate set to 500ms (High Fidelity)',
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _TelemetryChip(
                          label: '2000ms (Std)',
                          isSelected: monitor.telemetryIntervalMs == 2000,
                          onTap: () {
                            monitor.setTelemetryInterval(2000);
                            AppFeedback.showSuccess(
                              context,
                              'Telemetry rate set to 2000ms (Standard)',
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _TelemetryChip(
                          label: '5000ms (Eco)',
                          isSelected: monitor.telemetryIntervalMs == 5000,
                          onTap: () {
                            monitor.setTelemetryInterval(5000);
                            AppFeedback.showSuccess(
                              context,
                              'Telemetry rate set to 5000ms (Eco Battery)',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'BLE HARDWARE SIMULATION',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('simulate_ble_timeout_button'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      AppFeedback.showError(
                        context,
                        'BLE channel timeout: Check device battery.',
                      );
                    },
                    icon: Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    label: const Text('Simulate BLE Diagnostic Timeout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'DATABASE OPERATIONS',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final db = await AppDatabase.instance.database;
                      await db.delete('workouts');
                      await db.delete('workout_sets');
                      await db.delete('running_routes');
                      if (context.mounted) {
                        AppFeedback.showInfo(
                          context,
                          'Transient logs cleared. Seed tables retained.',
                        );
                      }
                    },
                    icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                    label: const Text('Reset Temporary Run & Workout Logs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TelemetryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
