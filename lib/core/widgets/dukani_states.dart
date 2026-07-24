import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/dukani_theme.dart';
import 'dukani_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Empty state — used whenever a list/section has no data yet.
class DukaniEmptyState extends StatelessWidget {
  const DukaniEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = LucideIcons.inbox,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DukaniSpacing.xxxl, horizontal: DukaniSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: DukaniColors.forest50, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: DukaniColors.forest500),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, style: textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500), textAlign: TextAlign.center),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: DukaniSpacing.xl),
            DukaniButton(label: actionLabel!, onPressed: onAction, expand: false, size: DukaniButtonSize.medium),
          ],
        ],
      ),
    );
  }
}

/// Full-bleed error state with retry.
class DukaniErrorState extends StatelessWidget {
  const DukaniErrorState({super.key, this.message = 'حدث خطأ غير متوقع', this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DukaniEmptyState(
      title: 'تعذر تحميل البيانات',
      message: message,
      icon: LucideIcons.wifiOff,
      actionLabel: onRetry != null ? 'إعادة المحاولة' : null,
      onAction: onRetry,
    );
  }
}

/// Shimmer skeleton block for loading states — pass a shape via child.
class DukaniSkeleton extends StatelessWidget {
  const DukaniSkeleton({super.key, this.height = 16, this.width = double.infinity, this.radius = 8});

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? DukaniColors.darkSurfaceAlt : DukaniColors.ink100,
      highlightColor: dark ? DukaniColors.darkBorder : DukaniColors.paper,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

class DukaniSkeletonCard extends StatelessWidget {
  const DukaniSkeletonCard({super.key, this.height = 90});
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: dark ? DukaniColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(DukaniRadii.lg),
        border: Border.all(color: dark ? DukaniColors.darkBorder : DukaniColors.ink100),
      ),
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DukaniSkeleton(height: 14, width: 120),
          SizedBox(height: 12),
          DukaniSkeleton(height: 22, width: 160),
        ],
      ),
    );
  }
}

/// Small "coming soon" full-screen filler used for sections not yet built
/// in this phase — still branded and still navigable, never a blank page.
class DukaniComingSoon extends StatelessWidget {
  const DukaniComingSoon({super.key, required this.title, this.message = 'هذا القسم قيد الإنشاء ضمن المرحلة القادمة من تطوير دُكاني.'});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: DukaniEmptyState(title: title, message: message, icon: LucideIcons.construction),
      ),
    );
  }
}
