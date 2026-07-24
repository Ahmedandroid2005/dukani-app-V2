import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/customers/customers_controller.dart';
import '../../core/customers/debt_statement_share.dart';
import '../../core/pos/sales_log_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  void _collectPayment(BuildContext context, WidgetRef ref, MockCustomer customer) {
    final controller = TextEditingController(text: customer.debt.toStringAsFixed(0));
    showDukaniSheet(
      context,
      title: 'تحصيل دفعة — ${customer.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('الدين الحالي: ${customer.debt.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'المبلغ المحصّل', hint: '0.00', controller: controller, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniButton(
            label: 'تأكيد التحصيل',
            icon: LucideIcons.checkCircle2,
            onPressed: () {
              final amount = double.tryParse(controller.text.trim()) ?? 0;
              if (amount > 0) ref.read(customersProvider.notifier).settleDebt(customer.id, amount);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _redeemPoints(BuildContext context, WidgetRef ref, MockCustomer customer) {
    final controller = TextEditingController();
    showDukaniSheet(
      context,
      title: 'استبدال نقاط — ${customer.name}',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final points = int.tryParse(controller.text.trim());
          final value = points == null ? null : points / 10;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('الرصيد الحالي: ${customer.loyaltyPoints} نقطة (10 نقاط = 1 ${currentCurrencySymbol()})', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
              const SizedBox(height: DukaniSpacing.lg),
              DukaniTextField(label: 'عدد النقاط المستبدلة', hint: '0', controller: controller, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, onChanged: (_) => setSheetState(() {})),
              if (value != null) ...[
                const SizedBox(height: DukaniSpacing.sm),
                Text('= ${value.toStringAsFixed(2)} ${currentCurrencySymbol()} خصم', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
              ],
              const SizedBox(height: DukaniSpacing.xl),
              DukaniButton(
                label: 'تأكيد الاستبدال',
                onPressed: points == null || points <= 0 || points > customer.loyaltyPoints
                    ? null
                    : () {
                        ref.read(customersProvider.notifier).redeemPoints(customer.id, points);
                        Navigator.pop(context);
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  void _addPoints(BuildContext context, WidgetRef ref, MockCustomer customer) {
    final controller = TextEditingController();
    showDukaniSheet(
      context,
      title: 'إضافة نقاط — ${customer.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('نقطة واحدة لكل 10 ${currentCurrencySymbol()} من قيمة الشراء', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'عدد النقاط', hint: '0', controller: controller, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, autofocus: true),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(
            label: 'إضافة',
            onPressed: () {
              final points = int.tryParse(controller.text.trim());
              if (points == null || points <= 0) return;
              ref.read(customersProvider.notifier).addPoints(customer.id, points);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customersProvider).where((c) => c.id == customerId).toList();

    if (customer.isEmpty) {
      return const Scaffold(
        appBar: DukaniAppBar(title: 'العميل'),
        body: DukaniEmptyState(title: 'العميل غير موجود', icon: LucideIcons.searchX),
      );
    }

    final c = customer.first;
    final purchases = ref.watch(salesLogProvider).where((inv) => inv.customerName == c.name).toList();
    final referrer = c.referredBy.isEmpty ? null : ref.read(customersProvider.notifier).byId(c.referredBy);

    return Scaffold(
      appBar: DukaniAppBar(
        title: c.name,
        actions: [DukaniIconAction(icon: LucideIcons.pencil, onTap: () => context.pushNamed(R.customerEdit, pathParameters: {'id': c.id}))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: DukaniColors.forest50, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.user, size: 32, color: DukaniColors.forest600),
                ),
                const SizedBox(height: DukaniSpacing.md),
                Text(c.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                DukaniAmountText(c.phone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
                if (c.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(c.notes, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            color: c.debt > 0 ? DukaniColors.dangerBg : DukaniColors.successBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رصيد الدين', style: Theme.of(context).textTheme.titleSmall),
                    Text('آخر عملية شراء: ${c.lastPurchase}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
                DukaniAmountText(
                  '${c.debt.toStringAsFixed(2)} ${currentCurrencySymbol()}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: c.debt > 0 ? DukaniColors.danger : DukaniColors.success),
                ),
              ],
            ),
          ),
          if (c.debt > 0) ...[
            const SizedBox(height: DukaniSpacing.md),
            DukaniButton(label: 'تحصيل دفعة', icon: LucideIcons.wallet, onPressed: () => _collectPayment(context, ref, c)),
            const SizedBox(height: DukaniSpacing.sm),
            DukaniOutlineButton(
              label: 'إرسال كشف حساب للعميل',
              icon: LucideIcons.share2,
              onPressed: () => shareDebtStatement(context, c, purchases),
            ),
          ],
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            color: DukaniColors.gold100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.award, color: DukaniColors.gold700, size: 20),
                        const SizedBox(width: 8),
                        Text('نقاط الولاء', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.gold700)),
                      ],
                    ),
                    DukaniAmountText('${c.loyaltyPoints}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: DukaniColors.gold700)),
                  ],
                ),
                const SizedBox(height: DukaniSpacing.md),
                Row(
                  children: [
                    Expanded(child: DukaniOutlineButton(label: 'إضافة نقاط', icon: LucideIcons.plus, onPressed: () => _addPoints(context, ref, c))),
                    const SizedBox(width: DukaniSpacing.md),
                    Expanded(
                      child: DukaniOutlineButton(
                        label: 'استبدال',
                        icon: LucideIcons.gift,
                        onPressed: c.loyaltyPoints > 0 ? () => _redeemPoints(context, ref, c) : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.userPlus, color: DukaniColors.forest600, size: 20),
                    const SizedBox(width: 8),
                    Text('برنامج الإحالة', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: DukaniSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('كود الإحالة الخاص به', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                        const SizedBox(height: 2),
                        DukaniAmountText(c.referralCode.isEmpty ? '—' : c.referralCode, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (c.referralCode.isNotEmpty)
                      DukaniIconAction(
                        icon: LucideIcons.copy,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: c.referralCode));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ كود الإحالة')));
                        },
                      ),
                  ],
                ),
                if (referrer != null) ...[
                  const SizedBox(height: DukaniSpacing.sm),
                  Text('أُحيل بواسطة: ${referrer.name}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                ],
                const SizedBox(height: DukaniSpacing.sm),
                Text(
                  'يحصل كل من العميل الجديد والمُحيل على $referralBonusPoints نقطة عند استخدام هذا الكود.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
                ),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          Text('سجل المشتريات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DukaniSpacing.md),
          if (purchases.isEmpty)
            const DukaniEmptyState(title: 'لا توجد مشتريات سابقة', icon: LucideIcons.receipt)
          else
            for (final inv in purchases) ...[
              DukaniCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(inv.id, style: Theme.of(context).textTheme.titleSmall),
                          Text('${inv.itemCount} منتجات · ${inv.methodLabel}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                        ],
                      ),
                    ),
                    DukaniAmountText('${inv.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
                  ],
                ),
              ),
              const SizedBox(height: DukaniSpacing.md),
            ],
        ],
      ),
    );
  }
}
