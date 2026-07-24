import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/branches/branches_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({super.key, this.warehousesOnly = false});
  final bool warehousesOnly;

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> {
  late String _filter = widget.warehousesOnly ? 'مخازن' : 'الكل';

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider);
    final visible = switch (_filter) {
      'مخازن' => branches.where((b) => b.isWarehouse).toList(),
      'فروع بيع' => branches.where((b) => !b.isWarehouse).toList(),
      _ => branches,
    };

    return Scaffold(
      appBar: DukaniAppBar(
        title: widget.warehousesOnly ? 'إدارة المخازن' : 'الفروع',
        actions: [
          DukaniIconAction(icon: LucideIcons.arrowLeftRight, onTap: () => context.pushNamed(R.branchTransfer)),
          DukaniIconAction(icon: LucideIcons.store, onTap: () => context.pushNamed(R.branchNew)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, DukaniSpacing.md),
            child: Row(
              children: [
                for (final f in const ['الكل', 'فروع بيع', 'مخازن']) ...[
                  DukaniChoiceChip(label: f, selected: f == _filter, onTap: () => setState(() => _filter = f)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const DukaniEmptyState(title: 'لا توجد نتائج', icon: LucideIcons.store)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) => _BranchRow(branch: visible[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.branch});
  final MockBranch branch;

  @override
  Widget build(BuildContext context) {
    return DukaniCard(
      onTap: () => context.pushNamed(R.branchEdit, pathParameters: {'id': branch.id}),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: DukaniColors.forest50, shape: BoxShape.circle),
            child: Icon(branch.isWarehouse ? LucideIcons.warehouse : LucideIcons.store, color: DukaniColors.forest600),
          ),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(branch.name, style: Theme.of(context).textTheme.titleSmall),
                    if (branch.isMain) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: DukaniColors.gold100, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                        child: Text('رئيسي', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.gold700)),
                      ),
                    ],
                    if (branch.isWarehouse) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: DukaniColors.forest100, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                        child: Text('مخزن', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.forest700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(branch.address, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: branch.active ? DukaniColors.successBg : DukaniColors.dangerBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
            child: Text(branch.active ? 'نشط' : 'مغلق', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: branch.active ? DukaniColors.success : DukaniColors.danger)),
          ),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
        ],
      ),
    );
  }
}
