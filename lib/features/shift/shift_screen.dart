import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_controller.dart';
import '../../core/shift/shift_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String _formatTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}';
}

class ShiftScreen extends ConsumerWidget {
  const ShiftScreen({super.key});

  void _openShift(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: ref.read(sessionProvider)?.name ?? '');
    final amountController = TextEditingController(text: '0');
    showDukaniSheet(
      context,
      title: 'فتح الوردية',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DukaniTextField(label: 'اسم الكاشير', controller: nameController),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'رصيد افتتاحي (نقدًا)', hint: '0.00', controller: amountController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniButton(
            label: 'فتح الوردية',
            icon: LucideIcons.unlock,
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (nameController.text.trim().isEmpty) return;
              ref.read(shiftProvider.notifier).openShift(nameController.text.trim(), amount);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _addMovement(BuildContext context, WidgetRef ref, CashMovementType type) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    showDukaniSheet(
      context,
      title: type == CashMovementType.cashIn ? 'إضافة نقدية' : 'سحب نقدي',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DukaniTextField(label: 'المبلغ', hint: '0.00', controller: amountController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, autofocus: true),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'السبب', hint: 'مثال: تزويد الصندوق', controller: noteController),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniButton(
            label: 'تأكيد',
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;
              ref.read(shiftProvider.notifier).addMovement(type, amount, noteController.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _closeShift(BuildContext context, WidgetRef ref, ShiftRecord shift) {
    final countedController = TextEditingController(text: shift.expectedCash.toStringAsFixed(2));
    showDukaniSheet(
      context,
      title: 'إغلاق الوردية',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final counted = double.tryParse(countedController.text.trim());
          final variance = counted == null ? null : counted - shift.expectedCash;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('المبلغ المتوقع: ${shift.expectedCash.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
              const SizedBox(height: DukaniSpacing.lg),
              DukaniTextField(
                label: 'المبلغ الفعلي بالصندوق',
                hint: '0.00',
                controller: countedController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                onChanged: (_) => setSheetState(() {}),
              ),
              if (variance != null && variance != 0) ...[
                const SizedBox(height: DukaniSpacing.md),
                DukaniCard(
                  color: variance > 0 ? DukaniColors.successBg : DukaniColors.dangerBg,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(variance > 0 ? 'زيادة' : 'عجز', style: Theme.of(context).textTheme.titleSmall),
                      DukaniAmountText('${variance.abs().toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: variance > 0 ? DukaniColors.success : DukaniColors.danger)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: DukaniSpacing.xl),
              DukaniButton(
                label: 'تأكيد إغلاق الوردية',
                icon: LucideIcons.lock,
                onPressed: counted == null
                    ? null
                    : () {
                        ref.read(shiftProvider.notifier).closeShift(counted);
                        Navigator.pop(context);
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(currentShiftProvider);

    return Scaffold(
      appBar: const DukaniAppBar(title: 'الوردية وإدارة النقد'),
      body: shift == null
          ? Center(
              child: DukaniEmptyState(
                title: 'لا توجد وردية مفتوحة',
                message: 'افتح وردية جديدة لبدء تسجيل المبيعات والحركات النقدية',
                icon: LucideIcons.clock,
                actionLabel: 'فتح الوردية',
                onAction: () => _openShift(context, ref),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              children: [
                DukaniCard(
                  color: DukaniColors.forest700,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الكاشير', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                          Text(shift.cashierName, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: DukaniSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الرصيد المتوقع', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                          DukaniAmountText('${shift.expectedCash.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DukaniSpacing.lg),
                Row(
                  children: [
                    Expanded(child: DukaniOutlineButton(label: 'سحب نقدي', icon: LucideIcons.minusCircle, onPressed: () => _addMovement(context, ref, CashMovementType.cashOut))),
                    const SizedBox(width: DukaniSpacing.md),
                    Expanded(child: DukaniOutlineButton(label: 'إضافة نقدية', icon: LucideIcons.plusCircle, onPressed: () => _addMovement(context, ref, CashMovementType.cashIn))),
                  ],
                ),
                const SizedBox(height: DukaniSpacing.xl),
                Text('حركات النقد', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: DukaniSpacing.md),
                if (shift.movements.isEmpty)
                  const DukaniEmptyState(title: 'لا توجد حركات نقدية بعد', icon: LucideIcons.wallet)
                else
                  for (final m in shift.movements.reversed) ...[
                    DukaniCard(
                      padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg, vertical: DukaniSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            m.type == CashMovementType.cashIn ? LucideIcons.plusCircle : LucideIcons.minusCircle,
                            color: m.type == CashMovementType.cashIn ? DukaniColors.success : DukaniColors.danger,
                          ),
                          const SizedBox(width: DukaniSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.note.isEmpty ? (m.type == CashMovementType.cashIn ? 'إضافة نقدية' : 'سحب نقدي') : m.note, style: Theme.of(context).textTheme.titleSmall),
                                Text(_formatTime(m.time), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                              ],
                            ),
                          ),
                          DukaniAmountText(
                            '${m.type == CashMovementType.cashIn ? '+' : '-'}${m.amount.toStringAsFixed(2)} ${currentCurrencySymbol()}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: m.type == CashMovementType.cashIn ? DukaniColors.success : DukaniColors.danger),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DukaniSpacing.sm),
                  ],
                const SizedBox(height: DukaniSpacing.xl),
                DukaniButton(label: 'إغلاق الوردية', icon: LucideIcons.lock, onPressed: () => _closeShift(context, ref, shift)),
              ],
            ),
    );
  }
}
