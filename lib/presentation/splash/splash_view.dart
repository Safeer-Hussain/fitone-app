import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart';

/// Sleek animated branded splash screen for the Fitone Wearable Ecosystem.
/// Displays an obsidian canvas, an electric emerald breathing smart-ring emblem,
/// sequential telemetry initialization statuses, and smoothly transitions to the navigation shell.
class SplashView extends StatefulWidget {
  final Duration totalDuration;
  final Widget? targetDestination;

  const SplashView({
    super.key,
    this.totalDuration = const Duration(milliseconds: 1800),
    this.targetDestination,
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  String _statusMessage = 'Initializing SQLite telemetry cache...';
  Timer? _phaseTimer1;
  Timer? _phaseTimer2;
  Timer? _completionTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeIn));

    _pulseController.repeat(reverse: true);

    _startSequentialInitialization();
  }

  void _startSequentialInitialization() {
    final stepDurationMs = widget.totalDuration.inMilliseconds ~/ 3;

    _phaseTimer1 = Timer(Duration(milliseconds: stepDurationMs), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Mounting native BLE platform channels...';
        });
      }
    });

    _phaseTimer2 = Timer(Duration(milliseconds: stepDurationMs * 2), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Fitone Ecosystem Ready.';
        });
      }
    });

    _completionTimer = Timer(widget.totalDuration, () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    final destination = widget.targetDestination ?? const MainNavigationShell();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _phaseTimer1?.cancel();
    _phaseTimer2?.cancel();
    _completionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.emeraldPrimary.withValues(alpha: 0.85),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emeraldPrimary.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: AppColors.emeraldPrimary.withValues(alpha: 0.15),
                        blurRadius: 48,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      AppAssets.appIcon,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 56,
                          color: AppColors.emeraldPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'FITONE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.2,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'BIOMETRIC SMART-RING ECOSYSTEM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.emeraldPrimary,
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: 140,
                height: 2.5,
                child: LinearProgressIndicator(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: AppColors.emeraldPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _statusMessage,
                  key: ValueKey<String>(_statusMessage),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
