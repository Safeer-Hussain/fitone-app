import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Unified notification and feedback engine for Fitone.
/// Provides semantic floating SnackBars with consistent branding, elevation, and typography.
class AppFeedback {
  AppFeedback._();

  /// Displays an Emerald success notification with a check icon.
  static void showSuccess(
    BuildContext context,
    String message, {
    String actionLabel = 'DISMISS',
    VoidCallback? onAction,
  }) {
    _showToast(
      context: context,
      message: message,
      accentColor: AppColors.emeraldPrimary,
      icon: Icons.check_circle_outline_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Displays an Amber warning notification with an alert triangle icon.
  static void showWarning(
    BuildContext context,
    String message, {
    String actionLabel = 'DISMISS',
    VoidCallback? onAction,
  }) {
    _showToast(
      context: context,
      message: message,
      accentColor: AppColors.orangeAccent,
      icon: Icons.warning_amber_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Displays a Crimson error notification with a circle-x icon.
  static void showError(
    BuildContext context,
    String message, {
    String actionLabel = 'DISMISS',
    VoidCallback? onAction,
  }) {
    _showToast(
      context: context,
      message: message,
      accentColor: AppColors.redAccent,
      icon: Icons.error_outline_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Displays an Electric Blue informative notification with an info icon.
  static void showInfo(
    BuildContext context,
    String message, {
    String actionLabel = 'DISMISS',
    VoidCallback? onAction,
  }) {
    _showToast(
      context: context,
      message: message,
      accentColor: AppColors.cyanAccent,
      icon: Icons.info_outline_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void _showToast({
    required BuildContext context,
    required String message,
    required Color accentColor,
    required IconData icon,
    required String actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.45),
            width: 1.0,
          ),
        ),
        duration: const Duration(milliseconds: 3200),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: actionLabel,
          textColor: accentColor,
          onPressed: () {
            if (onAction != null) {
              onAction();
            } else {
              messenger.hideCurrentSnackBar();
            }
          },
        ),
      ),
    );
  }
}
