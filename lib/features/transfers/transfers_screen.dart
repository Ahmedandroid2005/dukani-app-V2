import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/transfers/transfers_controller.dart';
import '../../core/widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  void _markReceived(WidgetRef ref, MockBranchTransfer transfer) {
    ref.read(transfersProvider.notifier).markReceived(transfer.id);
    ref.read(activityLogProvider.notifier).log(
          'استلام تحويل مخزون من ${transfer.fromBranchName} إلى ${transfer.toBranchName}',
          employeeName: ref.read(sessionProvider)?.name ?? 'صاحب المتجر',
          category: 'مخزون',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transfers = ref.watch(transfersProvider);

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'التحويل بين الفروع',
        actions: [DukaniIconAction(icon: LucideIcons.plus, onTap: () => context.pushNamed(R.transferNew))],
      ),
      body: transfers.isEmpty
          ? DukaniEmptyState(
              title: 'لا توجد تحويلات',
              message: 'أنشئ طلب تحويل مخزون بين الفروع',
              icon: LucideIcons.arrowLeftRight,
              actionLabel: 'تحويل جديد',
              onAction: () => context.pushNamed(R.transferNew),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              itemCount: transfers.length,
              separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
              itemBuilder: (context, i) {
                final t = transfers[i];
                return DukaniCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(child: Text(t.fromBranchName, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(LucideIcons.arrowRight, size: 14, color: DukaniColors.ink500)),
                                Flexible(child: Text(t.toBranchName, style: Theme.of(context).textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: t.received ? DukaniColors.successBg : DukaniColors.warningBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                            child: Text(t.received ? 'مستلم' : 'قيد النقل', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.received ? DukaniColors.success : DukaniColors.warning)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${t.items.length} منتجات · ${t.date}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                      if (!t.received) ...[
                        const SizedBox(height: DukaniSpacing.sm),
                        DukaniButton(label: 'تأكيد الاستلام', icon: LucideIcons.package, size: DukaniButtonSize.small, expand: false, onPressed: () => _markReceived(ref, t)),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}
