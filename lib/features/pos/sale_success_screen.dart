import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/printing/receipt_print_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'payment_screen.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SaleSuccessScreen extends StatefulWidget {
  const SaleSuccessScreen({super.key, required this.args});
  final SaleSuccessArgs args;

  @override
  State<SaleSuccessScreen> createState() => _SaleSuccessScreenState();
}

class _SaleSuccessScreenState extends State<SaleSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (ReceiptPrintService.autoprint) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runAction(() => ReceiptPrintService.print(widget.args.receipt)));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runAction(Future<PrintOutcome> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final outcome = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(outcome.message!)));
    }
  }

  void _share() {
    showDukaniSheet(
      context,
      title: 'مشاركة الفاتورة',
      child: Column(
        children: [
          DukaniSheetAction(
            icon: LucideIcons.printer,
            label: 'طباعة',
            onTap: () {
              Navigator.pop(context);
              _runAction(() => ReceiptPrintService.print(widget.args.receipt));
            },
          ),
          DukaniSheetAction(
            icon: LucideIcons.fileText,
            label: 'تصدير / مشاركة PDF',
            color: DukaniColors.danger,
            onTap: () {
              Navigator.pop(context);
              _runAction(() => ReceiptPrintService.share(widget.args.receipt));
            },
          ),
          DukaniSheetAction(
            icon: LucideIcons.share2,
            label: 'مشاركة عبر واتساب',
            color: DukaniColors.success,
            onTap: () {
              Navigator.pop(context);
              _runAction(() => ReceiptPrintService.share(widget.args.receipt));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DukaniSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: DukaniColors.successBg, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.check, color: DukaniColors.success, size: 52),
                ),
              ),
              const SizedBox(height: DukaniSpacing.xl),
              Text('تمت عملية البيع بنجاح', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              DukaniAmountText(args.invoiceId, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
              const SizedBox(height: DukaniSpacing.xxl),
              DukaniCard(
                child: Column(
                  children: [
                    _Row(label: 'عدد المنتجات', value: '${args.itemCount}'),
                    const Divider(height: DukaniSpacing.xl),
                    _Row(label: 'طريقة الدفع', value: args.methodLabel),
                    if (args.change > 0) ...[
                      const Divider(height: DukaniSpacing.xl),
                      _Row(label: 'المتبقي للعميل', value: '${args.change.toStringAsFixed(2)} ${currentCurrencySymbol()}'),
                    ],
                    const Divider(height: DukaniSpacing.xl),
                    _Row(label: 'الإجمالي', value: '${args.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', bold: true),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(child: DukaniOutlineButton(label: 'مشاركة / طباعة', icon: LucideIcons.share2, onPressed: _busy ? null : _share)),
                ],
              ),
              const SizedBox(height: DukaniSpacing.md),
              DukaniButton(
                label: 'بيع جديد',
                icon: LucideIcons.store,
                onPressed: () => context.goNamed(R.pos),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        DukaniAmountText(value, style: bold ? style?.copyWith(color: DukaniColors.forest700) : style),
      ],
    );
  }
}
