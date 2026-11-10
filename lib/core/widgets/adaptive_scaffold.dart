import 'package:flutter/material.dart';

import 'offline_banner.dart';

class AdaptiveScaffoldDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AdaptiveScaffoldDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AdaptiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationIndexChanged;
  final List<AdaptiveScaffoldDestination> destinations;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? endDrawer;

  const AdaptiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationIndexChanged,
    required this.destinations,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.endDrawer,
  });

  PreferredSizeWidget? _buildLandscapeAppBar(
    BuildContext context,
    PreferredSizeWidget? original,
  ) {
    if (original == null) return null;
    if (original is AppBar) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: AppBar(
          toolbarHeight: 36,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 8,
          leadingWidth: original.leading != null ? 36 : null,
          leading: original.leading,
          title: DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            child: original.title ?? const SizedBox.shrink(),
          ),
          actions: original.actions?.map((action) {
            if (action is IconButton) {
              return IconButton(
                onPressed: action.onPressed,
                icon: action.icon,
                tooltip: action.tooltip,
                iconSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              );
            }
            return action;
          }).toList(),
        ),
      );
    }
    return original;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape =
                orientation == Orientation.landscape ||
                constraints.maxWidth > 720;
            final safeBody = GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: body,
            );

            if (isLandscape) {
              return Scaffold(
                appBar: _buildLandscapeAppBar(context, appBar),
                endDrawer: endDrawer,
                floatingActionButton: floatingActionButton,
                body: GestureDetector(
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: Column(
                    children: [
                      const OfflineBanner(),
                      Expanded(
                        child: Row(
                          children: [
                            SizedBox(
                              width: 56,
                              child: LayoutBuilder(
                                builder: (context, railConstraints) {
                                  return SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: railConstraints.maxHeight,
                                      ),
                                      child: IntrinsicHeight(
                                        child: NavigationRail(
                                          minWidth: 56,
                                          selectedIndex: currentIndex,
                                          onDestinationSelected:
                                              onNavigationIndexChanged,
                                          labelType:
                                              NavigationRailLabelType.none,
                                          backgroundColor: colorScheme.surface,
                                          indicatorColor: colorScheme.primary
                                              .withValues(alpha: 0.18),
                                          destinations: destinations.map((d) {
                                            return NavigationRailDestination(
                                              icon: Icon(d.icon, size: 22),
                                              selectedIcon: Icon(
                                                d.selectedIcon,
                                                size: 22,
                                                color: colorScheme.primary,
                                              ),
                                              label: Text(d.label),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: colorScheme.outlineVariant,
                            ),
                            Expanded(child: safeBody),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Scaffold(
              appBar: appBar,
              endDrawer: endDrawer,
              floatingActionButton: floatingActionButton,
              body: GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.translucent,
                child: Column(
                  children: [
                    const OfflineBanner(),
                    Expanded(child: safeBody),
                  ],
                ),
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: onNavigationIndexChanged,
                destinations: destinations.map((d) {
                  return NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}
