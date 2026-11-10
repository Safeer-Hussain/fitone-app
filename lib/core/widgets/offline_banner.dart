import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../network/network_monitor.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final warningColor = theme.brightness == Brightness.dark
        ? const Color(0xFFF59E0B)
        : const Color(0xFFD97706);

    return Observer(
      builder: (_) {
        final isOnline = NetworkMonitor.instance.isOnline;
        final pendingCount = NetworkMonitor.instance.pendingMutationCount;

        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isOnline
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: warningColor, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: warningColor, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Offline Mode - Serving cached SQLite local data',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: warningColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pendingCount Queued',
                      style: TextStyle(
                        color: warningColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
