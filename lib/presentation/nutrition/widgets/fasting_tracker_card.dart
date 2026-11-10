import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/fasting_session.dart';
import '../stores/fasting_store.dart';
import 'fasting_detail_sheet.dart';

class FastingTrackerCard extends StatelessWidget {
  final FastingStore store;
  final bool isCompact;

  const FastingTrackerCard({
    super.key,
    required this.store,
    this.isCompact = false,
  });

  void _showEndFastDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: const Text(
            'Complete Fasting Window',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elapsed time: ${store.formattedElapsed}. Would you like to end your fast and record this session to history?',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Session Notes (Optional)',
                  hintText: 'e.g. Broke fast with bone broth & eggs',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
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
              key: const ValueKey('confirm_end_fast_dialog_button'),
              onPressed: () async {
                final notes = controller.text.trim();
                Navigator.of(dialogContext).pop();
                await store.endFast(notes: notes.isNotEmpty ? notes : null);
                if (context.mounted) {
                  AppFeedback.showSuccess(
                    context,
                    'Fasting session recorded to history',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('End Fast'),
            ),
          ],
        );
      },
    );
  }

  void _showAdjustStartTimeDialog(BuildContext context) async {
    final currentStart = store.activeSession?.startTime ?? DateTime.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentStart.toLocal()),
    );

    if (pickedTime != null && context.mounted) {
      final now = DateTime.now();
      var adjusted = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      if (adjusted.isAfter(now)) {
        adjusted = adjusted.subtract(const Duration(days: 1));
      }
      await store.adjustStartTime(adjusted);
      if (context.mounted) {
        AppFeedback.showSuccess(context, 'Fast start time adjusted');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Observer(
      builder: (_) {
        // Read observables to trigger reactivity
        final _ = store.liveElapsedSeconds;
        final isFasting = store.isFastingActive;
        final protocol = store.selectedProtocol;
        final currentPhase = store.currentPhase;
        final progress = store.progress;
        final notifOn = store.notificationsEnabled;
        final targetHours =
            store.activeSession?.targetHours ?? protocol.fastingHours;

        final ringSize = isCompact ? 140.0 : 180.0;

        return Card(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      color: isFasting
                          ? currentPhase.color
                          : colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Intermittent Fasting Tracker',
                        style: TextStyle(
                          fontSize: isCompact ? 13 : 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('fasting_notification_toggle'),
                      onPressed: () {
                        store.toggleNotifications();
                        AppFeedback.showInfo(
                          context,
                          store.notificationsEnabled
                              ? 'Fasting phase notifications enabled'
                              : 'Fasting notifications muted',
                        );
                      },
                      icon: Icon(
                        notifOn
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        size: 18,
                        color: notifOn
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      tooltip: notifOn
                          ? 'Notifications Active'
                          : 'Notifications Muted',
                    ),
                    IconButton(
                      key: const ValueKey('fasting_detail_button'),
                      onPressed: () => FastingDetailSheet.show(context, store),
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      tooltip: 'Metabolic Phase Details',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Center Live Countdown Progress Ring
                Center(
                  child: SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(ringSize, ringSize),
                          painter: _FastingRadialRingPainter(
                            progress: progress,
                            activeColor: isFasting
                                ? currentPhase.color
                                : colorScheme.primary,
                            trackColor: colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isFasting
                                  ? (progress >= 1.0
                                        ? 'GOAL REACHED'
                                        : 'FASTING')
                                  : 'EATING WINDOW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: isFasting
                                    ? currentPhase.color
                                    : colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFasting ? store.formattedElapsed : 'Idle',
                              style: TextStyle(
                                fontSize: isCompact ? 20 : 24,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isFasting
                                            ? currentPhase.color
                                            : colorScheme.primary)
                                        .withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isFasting
                                    ? currentPhase.name.toUpperCase()
                                    : protocol.label,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isFasting
                                      ? currentPhase.color
                                      : colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFasting
                                  ? '${targetHours.toStringAsFixed(1)}h Target'
                                  : '${protocol.eatingHours.toInt()}h window open',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ketone Phase Marker Timeline
                Text(
                  'METABOLIC KETONE PHASE MARKERS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _FastingPhaseTimeline(
                  currentPhase: currentPhase,
                  isFastingActive: isFasting,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 14),

                // Controls
                if (isFasting) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('adjust_fast_start_time_button'),
                          onPressed: () => _showAdjustStartTimeDialog(context),
                          icon: const Icon(
                            Icons.edit_calendar_rounded,
                            size: 16,
                          ),
                          label: const Text('Adjust Start'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          key: const ValueKey('end_fast_button'),
                          onPressed: () => _showEndFastDialog(context),
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            size: 16,
                          ),
                          label: const Text('End Fast'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Protocol Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: FastingProtocol.values
                          .where((p) => p != FastingProtocol.custom)
                          .map((p) {
                            final isSelected = protocol == p;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(
                                  p.label,
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
                                onSelected: (_) => store.setProtocol(p),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const ValueKey('start_fast_button'),
                      onPressed: () async {
                        await store.startFast();
                        if (context.mounted) {
                          AppFeedback.showSuccess(
                            context,
                            'Fasting window started (${store.selectedProtocol.label})',
                          );
                        }
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(
                        'Start Fasting Window (${protocol.label})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FastingRadialRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  const _FastingRadialRingPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 10.0;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active Arc
    if (progress > 0) {
      final sweepAngle = (progress.clamp(0.0, 1.0)) * 2 * pi;
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FastingRadialRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}

class _FastingPhaseTimeline extends StatelessWidget {
  final FastingPhaseType currentPhase;
  final bool isFastingActive;
  final ColorScheme colorScheme;

  const _FastingPhaseTimeline({
    required this.currentPhase,
    required this.isFastingActive,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    const phases = FastingPhaseType.values;

    return Row(
      children: phases.map((phase) {
        final isCurrent = isFastingActive && phase == currentPhase;
        final isCompleted = isFastingActive && currentPhase.index > phase.index;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isCurrent
                  ? phase.color.withOpacity(0.22)
                  : (isCompleted
                        ? phase.color.withOpacity(0.12)
                        : colorScheme.surfaceContainerHighest.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCurrent
                    ? phase.color
                    : (isCompleted
                          ? phase.color.withOpacity(0.4)
                          : Colors.transparent),
                width: isCurrent ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCurrent || isCompleted
                        ? phase.color
                        : colorScheme.onSurfaceVariant.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  phase.name.split(' ').first,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent
                        ? phase.color
                        : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
