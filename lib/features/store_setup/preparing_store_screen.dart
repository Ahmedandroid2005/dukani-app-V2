import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/dukani_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PreparingStoreScreen extends StatefulWidget {
  const PreparingStoreScreen({super.key});

  @override
  State<PreparingStoreScreen> createState() => _PreparingStoreScreenState();
}

class _PreparingStoreScreenState extends State<PreparingStoreScreen> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _finished = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) context.goNamed('home');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = DukaniTypography.textTheme(DukaniColors.forest900);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProgressRing(finished: _finished),
            const SizedBox(height: DukaniSpacing.xxxl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                _finished ? 'متجرك جاهز الآن' : 'جارٍ تجهيز متجرك...',
                key: ValueKey(_finished),
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bare brand mark with a thin ring rotating around it — a single,
/// unambiguous "still working" signal instead of a step-by-step checklist,
/// since the actual wait here is only a couple of seconds.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.finished});

  final bool finished;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!finished)
            const SizedBox(
              width: 132,
              height: 132,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: DukaniColors.gold500),
            ),
          AnimatedScale(
            scale: finished ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            child: Image.asset('assets/images/logo.png', width: 80, height: 80, fit: BoxFit.contain),
          ),
          if (finished)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: DukaniColors.success, shape: BoxShape.circle),
                child: const Icon(LucideIcons.check, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
