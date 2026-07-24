import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/alerts/product_alerts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/store/store_profile_controller.dart';
import '../../../core/theme/dukani_theme.dart';
import '../../../core/widgets/dukani_app_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = DukaniTypography.textTheme(Colors.white);
    final session = ref.watch(sessionProvider);
    final displayName = session?.name ?? ref.watch(storeProfileProvider).valueOrNull?.ownerName ?? 'صاحب المتجر';
    final todayLabel = DateFormat.EEEE('ar').format(DateTime.now());
    // A cashier without manageSettings would otherwise tap this and get
    // silently bounced back here by the route guard — send them somewhere
    // that's actually theirs (Profile, which is never permission-gated)
    // instead of a dead button.
    final canOpenSettings = session == null || session.role == 'مالك' || session.permissions.manageSettings;

    return Container(
      padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, DukaniSpacing.xxxl),
      decoration: const BoxDecoration(gradient: DukaniColors.brandGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Material(
                  color: Colors.white.withOpacity(0.12),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.pushNamed(canOpenSettings ? R.settings : R.profile),
                    child: const Padding(padding: EdgeInsets.all(10), child: Icon(LucideIcons.menu, color: Colors.white, size: 20)),
                  ),
                ),
                const SizedBox(width: DukaniSpacing.md),
                Expanded(
                  child: InkWell(
                    onTap: () => context.pushNamed(R.profile),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مرحبًا بك', style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                        Text(displayName, style: textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                DukaniIconAction(
                  icon: LucideIcons.bell,
                  count: ref.watch(alertsCountProvider),
                  onTap: () => context.pushNamed(R.alerts),
                ),
              ],
            ),
            const SizedBox(height: DukaniSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(DukaniRadii.pill)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.calendar, size: 14, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('اليوم — $todayLabel', style: textTheme.labelMedium?.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
