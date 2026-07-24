import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/employees/employees_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final activeCount = employees.where((e) => e.active).length;

    final visible = employees.where((e) => _query.isEmpty || e.name.contains(_query)).toList();

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'الموظفون',
        actions: [DukaniIconAction(icon: LucideIcons.userPlus, onTap: () => context.pushNamed(R.employeeNew))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(child: DukaniStatTile(label: 'إجمالي الموظفين', value: '${employees.length}', icon: LucideIcons.idCard, iconColor: DukaniColors.forest600)),
                const SizedBox(width: DukaniSpacing.md),
                Expanded(child: DukaniStatTile(label: 'نشطون', value: '$activeCount', icon: LucideIcons.checkCircle2, iconColor: DukaniColors.success)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            child: DukaniSearchField(hint: 'بحث بالاسم', onChanged: (v) => setState(() => _query = v)),
          ),
          Expanded(
            child: visible.isEmpty
                ? const DukaniEmptyState(title: 'لا يوجد موظفون', icon: LucideIcons.idCard)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) => _EmployeeRow(employee: visible[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.employee});
  final MockEmployee employee;

  @override
  Widget build(BuildContext context) {
    return DukaniCard(
      onTap: () => context.pushNamed(R.employeeEdit, pathParameters: {'id': employee.id}),
      child: Row(
        children: [
          DukaniAvatarImage(photoBytes: employee.photoBytes, size: 44),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text('${employee.role} · ${employee.branch}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: employee.active ? DukaniColors.successBg : DukaniColors.dangerBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
            child: Text(employee.active ? 'نشط' : 'موقوف', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: employee.active ? DukaniColors.success : DukaniColors.danger)),
          ),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
        ],
      ),
    );
  }
}
