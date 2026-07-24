import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/business/business_type_controller.dart';
import '../../core/business/country_controller.dart';
import '../../core/employees/employees_controller.dart';
import '../../core/session/session_controller.dart';
import '../../core/store/store_profile_controller.dart';
import '../../core/theme/dukani_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    // The loader glyph pulses continuously below the wordmark — a small
    // "still working" signal that doesn't touch the static brand mark itself.
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

    _logoFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.35, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.45, curve: Curves.elasticOut)),
    );
    _wordmarkFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.35, 0.6, curve: Curves.easeOut));
    _taglineFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.55, 0.8, curve: Curves.easeOut));

    _entrance.forward();
    Future.delayed(const Duration(milliseconds: 2400), _resolveDestination);
  }

  /// A signed-in owner's Firebase session survives an app restart on its
  /// own — this just has the splash actually act on that instead of always
  /// forcing everyone back through the login screen. Mirrors login_screen's
  /// own post-sign-in routing (session attribution, suspended check,
  /// business type/country sync) so a silent resume behaves identically to
  /// a fresh sign-in.
  Future<void> _resolveDestination() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      if (mounted) context.goNamed('login');
      return;
    }

    final owner = ref.read(employeesProvider).where((e) => e.role == 'مالك').toList();
    if (owner.isNotEmpty) ref.read(sessionProvider.notifier).login(owner.first);

    final profile = await ref.read(storeRepositoryProvider).fetch(user.uid);
    if (!mounted) return;

    if (profile != null && profile.suspended) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      context.goNamed('login');
      return;
    }

    if (profile != null) {
      ref.read(businessTypeProvider.notifier).set(
            BusinessType.values.firstWhere((t) => t.name == profile.businessType, orElse: () => BusinessType.generalRetail),
          );
      await ref.read(countryProvider.notifier).set(profile.countryCode);
      if (!mounted) return;
      context.goNamed('home');
      return;
    }

    context.goNamed('storeSetup');
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DukaniColors.paper,
      body: Center(
        child: AnimatedBuilder(
          animation: _entrance,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(color: DukaniColors.forest50, borderRadius: BorderRadius.circular(DukaniRadii.xl)),
                      child: const Icon(LucideIcons.store, size: 38, color: DukaniColors.forest700),
                    ),
                  ),
                ),
                const SizedBox(height: DukaniSpacing.xl),
                FadeTransition(
                  opacity: _wordmarkFade,
                  child: Text('دُكاني', style: DukaniTypography.textTheme(DukaniColors.ink900).displayMedium),
                ),
                const SizedBox(height: 4),
                FadeTransition(
                  opacity: _wordmarkFade,
                  child: Text(
                    'DUKANI',
                    style: DukaniTypography.textTheme(DukaniColors.forest700).titleSmall?.copyWith(
                          letterSpacing: 4,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: DukaniSpacing.xl),
                FadeTransition(
                  opacity: _taglineFade,
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) => CustomPaint(size: const Size(28, 28), painter: _SparkleLoaderPainter(_pulse.value)),
                  ),
                ),
                const SizedBox(height: DukaniSpacing.xl),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Column(
                    children: [
                      Text('نظام كاشير ذكي لإدارة متجرك بسهولة',
                          style: DukaniTypography.textTheme(DukaniColors.ink700).titleMedium),
                      const SizedBox(height: 4),
                      Text('Smart POS system for easy store management',
                          style: DukaniTypography.textTheme(DukaniColors.ink300).bodySmall),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A radiating dash-burst loader (matches the brand's splash reference) —
/// eight short strokes fading in/out around a center point, read as "still
/// loading" without competing with the static logo above it.
class _SparkleLoaderPainter extends CustomPainter {
  _SparkleLoaderPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerR = size.width / 2;
    final innerR = outerR * 0.45;
    const dashCount = 8;

    for (var i = 0; i < dashCount; i++) {
      final angle = (i / dashCount) * 2 * math.pi;
      // Each dash's opacity cycles on a phase offset so the burst reads as
      // continuous rotating motion rather than a uniform blink.
      final phase = (progress + i / dashCount) % 1.0;
      final double opacity = (0.25 + 0.75 * (0.5 + 0.5 * math.sin(phase * 2 * math.pi))).clamp(0.0, 1.0);

      final start = center + Offset(math.cos(angle), math.sin(angle)) * innerR;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * outerR;

      final paint = Paint()
        ..color = DukaniColors.gold500.withOpacity(opacity)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleLoaderPainter oldDelegate) => oldDelegate.progress != progress;
}
