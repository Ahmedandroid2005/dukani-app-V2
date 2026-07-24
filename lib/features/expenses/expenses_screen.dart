import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/expenses/expenses_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _categoryIcons = <String, IconData>{
  'إيجار': LucideIcons.building2,
  'رواتب': LucideIcons.idCard,
  'فواتير': LucideIcons.receipt,
  'صيانة': LucideIcons.wrench,
  'تسويق': LucideIcons.megaphone,
  'نقل وشحن': LucideIcons.truck,
  'أخرى': LucideIcons.moreHorizontal,
};

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String _category = 'الكل';

  void _addExpense() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String category = mockExpenseCategories.first;

    showDukaniSheet(
      context,
      title: 'مصروف جديد',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('الفئة', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: DukaniSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in mockExpenseCategories) DukaniChoiceChip(label: c, selected: c == category, onTap: () => setSheetState(() => category = c)),
                ],
              ),
              const SizedBox(height: DukaniSpacing.lg),
              DukaniTextField(label: 'المبلغ', hint: '0.00', controller: amountController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, autofocus: true),
              const SizedBox(height: DukaniSpacing.lg),
              DukaniTextField(label: 'ملاحظة (اختياري)', hint: 'مثال: فاتورة الكهرباء', controller: noteController),
              const SizedBox(height: DukaniSpacing.xl),
              DukaniButton(
                label: 'إضافة المصروف',
                icon: LucideIcons.checkCircle2,
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل مبلغًا صحيحًا')));
                    return;
                  }
                  ref.read(expensesProvider.notifier).add(MockExpense(
                        id: ref.read(expensesProvider.notifier).nextId(),
                        category: category,
                        amount: amount,
                        note: noteController.text.trim(),
                        date: 'اليوم',
                      ));
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(MockExpense expense) async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'حذف المصروف؟',
      message: 'سيتم حذف مصروف "${expense.category}" بقيمة ${expense.amount.toStringAsFixed(0)} ${currentCurrencySymbol()}.',
      confirmLabel: 'حذف',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    if (!mounted) return;
    final logged = await logSensitiveAction(
      context,
      ref,
      action: 'حذف مصروف "${expense.category}" بقيمة ${expense.amount.toStringAsFixed(0)} ${currentCurrencySymbol()}',
      category: 'حذف',
    );
    if (!logged) return;
    ref.read(expensesProvider.notifier).remove(expense.id);
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider);
    final total = expenses.fold<double>(0, (s, e) => s + e.amount);

    final visible = _category == 'الكل' ? expenses : expenses.where((e) => e.category == _category).toList();

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'المصروفات',
        actions: [DukaniIconAction(icon: LucideIcons.plus, onTap: _addExpense)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, DukaniSpacing.md),
            child: DukaniCard(
              color: DukaniColors.forest700,
              child: Column(
                children: [
                  Text('إجمالي المصروفات', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 6),
                  DukaniAmountText('${total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg),
              children: [
                for (final c in ['الكل', ...mockExpenseCategories]) ...[
                  DukaniChoiceChip(label: c, selected: c == _category, onTap: () => setState(() => _category = c)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.md),
          Expanded(
            child: visible.isEmpty
                ? DukaniEmptyState(title: 'لا توجد مصروفات', icon: LucideIcons.receipt, actionLabel: 'إضافة مصروف', onAction: _addExpense)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) {
                      final e = visible[i];
                      return DukaniCard(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: DukaniColors.dangerBg, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
                              child: Icon(_categoryIcons[e.category] ?? LucideIcons.receipt, color: DukaniColors.danger),
                            ),
                            const SizedBox(width: DukaniSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.category, style: Theme.of(context).textTheme.titleSmall),
                                  Text(e.note.isEmpty ? e.date : '${e.note} · ${e.date}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                                ],
                              ),
                            ),
                            DukaniAmountText('${e.amount.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.danger)),
                            IconButton(onPressed: () => _delete(e), icon: const Icon(LucideIcons.x, size: 16, color: DukaniColors.ink300)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
