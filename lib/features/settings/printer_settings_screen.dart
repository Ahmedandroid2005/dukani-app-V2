import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../core/printing/receipt_print_service.dart';
import '../../core/printing/thermal_printer_service.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  late PrinterMode _mode = ReceiptPrintService.mode;
  late PaperSize _paperSize = ReceiptPrintService.paperSize;
  late bool _autoprint = ReceiptPrintService.autoprint;
  SavedPrinter? _saved = ThermalPrinterService.savedPrinter;

  bool _scanning = false;
  bool _testing = false;
  List<SavedPrinter> _found = [];
  String? _scanError;

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _scanError = null;
      _found = [];
    });
    final granted = await ThermalPrinterService.ensurePermission();
    if (!granted) {
      setState(() {
        _scanning = false;
        _scanError = 'التطبيق يحتاج صلاحية البلوتوث عشان يشوف الطابعات المقترنة';
      });
      return;
    }
    final enabled = await ThermalPrinterService.bluetoothEnabled;
    if (!enabled) {
      setState(() {
        _scanning = false;
        _scanError = 'شغّل البلوتوث في جهازك أولاً';
      });
      return;
    }
    final devices = await ThermalPrinterService.pairedDevices();
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _found = devices;
      if (devices.isEmpty) _scanError = 'لا يوجد طابعات مقترنة — قرن الطابعة من إعدادات البلوتوث في الجهاز أولاً';
    });
  }

  Future<void> _select(SavedPrinter printer) async {
    await ThermalPrinterService.savePrinter(printer);
    await ReceiptPrintService.setMode(PrinterMode.bluetooth);
    if (!mounted) return;
    setState(() {
      _saved = printer;
      _mode = PrinterMode.bluetooth;
    });
  }

  Future<void> _testPrint() async {
    setState(() => _testing = true);
    final outcome = await ReceiptPrintService.testPrint();
    if (!mounted) return;
    setState(() => _testing = false);
    if (outcome.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(outcome.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DukaniAppBar(title: 'الطابعة والباركود'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          Text('طريقة الطباعة', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.sm),
          DukaniCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                RadioListTile<PrinterMode>(
                  value: PrinterMode.bluetooth,
                  groupValue: _mode,
                  onChanged: (v) {
                    setState(() => _mode = v!);
                    ReceiptPrintService.setMode(v!);
                  },
                  title: const Text('طابعة حرارية Bluetooth'),
                  subtitle: Text(_saved != null ? _saved!.name : 'لم تُختر طابعة بعد', style: Theme.of(context).textTheme.labelSmall),
                ),
                const Divider(height: 1, indent: 16),
                RadioListTile<PrinterMode>(
                  value: PrinterMode.systemOrPdf,
                  groupValue: _mode,
                  onChanged: (v) {
                    setState(() => _mode = v!);
                    ReceiptPrintService.setMode(v!);
                  },
                  title: const Text('شاشة الطباعة العامة / PDF'),
                  subtitle: const Text('يفتح خيارات الطباعة في الجهاز — يشمل أي طابعة شبكة أو USB مضافة له', style: TextStyle()),
                ),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('طابعات Bluetooth المقترنة', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
              TextButton.icon(
                onPressed: _scanning ? null : _scan,
                icon: _scanning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('بحث'),
              ),
            ],
          ),
          const SizedBox(height: DukaniSpacing.sm),
          if (_scanError != null)
            DukaniCard(
              color: DukaniColors.warningBg,
              child: Text(_scanError!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.warning)),
            )
          else if (_found.isEmpty)
            DukaniCard(
              child: Text('اضغط "بحث" لعرض الطابعات المقترنة ببلوتوث الجهاز', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
            )
          else
            DukaniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final p in _found) ...[
                    RadioListTile<String>(
                      value: p.macAddress,
                      groupValue: _saved?.macAddress,
                      onChanged: (_) => _select(p),
                      title: Text(p.name, style: Theme.of(context).textTheme.titleSmall),
                      subtitle: Text(p.macAddress, style: Theme.of(context).textTheme.labelSmall, textDirection: TextDirection.ltr),
                    ),
                    if (p != _found.last) const Divider(height: 1, indent: 16),
                  ],
                ],
              ),
            ),
          const SizedBox(height: DukaniSpacing.xxl),
          Text('حجم الورق', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.sm),
          Row(
            children: [
              for (final size in [PaperSize.mm58, PaperSize.mm80]) ...[
                DukaniChoiceChip(
                  label: size == PaperSize.mm58 ? '58 مم' : '80 مم',
                  selected: size == _paperSize,
                  onTap: () {
                    setState(() => _paperSize = size);
                    ReceiptPrintService.setPaperSize(size);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: DukaniSpacing.xxl),
          DukaniCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('طباعة تلقائية بعد كل عملية بيع', style: Theme.of(context).textTheme.titleSmall),
                      Text('يمكن دائمًا الطباعة يدويًا من شاشة نجاح البيع', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                    ],
                  ),
                ),
                Switch(
                  value: _autoprint,
                  onChanged: (v) {
                    setState(() => _autoprint = v);
                    ReceiptPrintService.setAutoprint(v);
                  },
                  activeColor: DukaniColors.forest600,
                ),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniOutlineButton(
            label: _testing ? 'جاري الإرسال...' : 'طباعة تجريبية',
            icon: LucideIcons.printer,
            onPressed: _testing ? null : _testPrint,
          ),
        ],
      ),
    );
  }
}
