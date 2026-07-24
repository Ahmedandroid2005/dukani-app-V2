import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/connectivity_service.dart';
import '../offline/sync_queue.dart';
import '../theme/dukani_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Slim banner that turns up whenever the device drops offline, and again
/// briefly while queued actions (sales made offline, etc.) sync back once
/// the connection returns — so "offline" is always visible, never silent.
class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  bool? _wasOnline;
  bool _syncing = false;

  Future<void> _handleReconnect() async {
    setState(() => _syncing = true);
    await ref.read(syncQueueProvider.notifier).flush();
    if (!mounted) return;
    setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final onlineAsync = ref.watch(isOnlineProvider);
    final pendingCount = ref.watch(syncQueueProvider).length;

    return onlineAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (online) {
        if (online && _wasOnline == false && pendingCount > 0 && !_syncing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleReconnect());
        }
        _wasOnline = online;

        final showOffline = !online;
        final showSyncing = online && _syncing;
        final showQueued = online && !_syncing && pendingCount > 0;

        if (!showOffline && !showSyncing && !showQueued) return const SizedBox.shrink();

        final (bg, fg, icon, label) = showOffline
            ? (DukaniColors.warningBg, DukaniColors.gold700, LucideIcons.cloudOff, 'غير متصل بالإنترنت — يعمل التطبيق بدون اتصال وسيُزامن تلقائيًا لاحقًا')
            : showSyncing
                ? (DukaniColors.infoBg, DukaniColors.info, LucideIcons.refreshCw, 'جارٍ مزامنة $pendingCount عملية...')
                : (DukaniColors.successBg, DukaniColors.success, LucideIcons.cloudCheck, 'تمت المزامنة بنجاح');

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      },
    );
  }
}
