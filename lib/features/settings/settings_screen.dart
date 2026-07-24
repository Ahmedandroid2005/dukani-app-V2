import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/business/business_capabilities.dart';
import '../../core/business/business_type_controller.dart';
import '../../core/business/feature_flags.dart';
import '../../core/offline/settings_controller.dart';
import '../../core/offline/sync_queue.dart';
import '../../core/payments/connected_gateway_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void _showAboutDialog(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'دُكاني',
    applicationVersion: 'الإصدار 0.1.0',
    applicationIcon: const Icon(LucideIcons.store, size: 40, color: DukaniColors.forest700),
    applicationLegalese: '© ${DateTime.now().year} Al-Sharqawi Tech, LLC — جميع الحقوق محفوظة',
  );
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final pendingSync = ref.watch(syncQueueProvider).length;
    final tracksWarehouseInventory = ref.watch(businessTypeProvider).tracksWarehouseInventory;

    return Scaffold(
      appBar: const DukaniAppBar(title: 'الإعدادات'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          const _SectionLabel('المخزون والمبيعات'),
          DukaniCard(
            padding: EdgeInsets.zero,
            child: _SettingsSwitchTile(
              icon: LucideIcons.packageX,
              title: 'السماح بالبيع رغم نفاد المخزون',
              subtitle: 'إيقاف هذا الخيار (الوضع الافتراضي) يمنع الكاشير من بيع كمية أكبر من المتوفر فعليًا.',
              value: settings.allowNegativeStock,
              onChanged: settingsCtrl.setAllowNegativeStock,
            ),
          ),
          const SizedBox(height: DukaniSpacing.xxl),
          const _SectionLabel('البيانات والمزامنة'),
          DukaniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: DukaniColors.forest50, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
                      child: Icon(pendingSync == 0 ? LucideIcons.cloudCheck : LucideIcons.cloudCog, color: DukaniColors.forest600, size: 20),
                    ),
                    const SizedBox(width: DukaniSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pendingSync == 0 ? 'كل البيانات مُزامنة' : '$pendingSync عملية بانتظار المزامنة',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'التطبيق يعمل بدون إنترنت ويحفظ عملياتك محليًا حتى تتم المزامنة تلقائيًا.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xxl),
          const _SectionLabel('الحساب'),
          DukaniCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingsLinkTile(icon: LucideIcons.circleUser, title: 'الملف الشخصي', onTap: () => context.pushNamed(R.profile)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.award, title: 'الاشتراك', value: 'الاحترافية', onTap: () => context.pushNamed(R.subscription)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.cloudCog, title: 'النسخ الاحتياطي', onTap: () => context.pushNamed(R.backup)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.headset, title: 'الدعم الفني', onTap: () => context.pushNamed(R.support)),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xxl),
          const _SectionLabel('عام'),
          DukaniCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final connected = ref.watch(connectedGatewayProvider);
                    return _SettingsLinkTile(
                      icon: LucideIcons.link,
                      title: 'ربط بوابة الدفع',
                      value: connected != null ? connected.provider?.displayName ?? connected.gatewayId : 'غير مربوط',
                      onTap: () => context.pushNamed(R.paymentGatewayLink),
                    );
                  },
                ),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.printer, title: 'الطابعة والباركود', onTap: () => context.pushNamed(R.printerSettings)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.idCard, title: 'الموظفون والصلاحيات', onTap: () => context.pushNamed(R.employees)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.truck, title: 'الموردون', onTap: () => context.pushNamed(R.suppliers)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.receipt, title: 'المصروفات', onTap: () => context.pushNamed(R.expenses)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.store, title: 'الفروع', onTap: () => context.pushNamed(R.branches)),
                if (tracksWarehouseInventory) ...[
                  const Divider(height: 1, indent: 60),
                  _SettingsLinkTile(icon: LucideIcons.warehouse, title: 'إدارة المخازن', onTap: () => context.pushNamed(R.warehouses)),
                ],
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.history, title: 'سجل النشاط', onTap: () => context.pushNamed(R.activityLog)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.fingerprint, title: 'سجل التدقيق', onTap: () => context.pushNamed(R.auditLog)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.undo2, title: 'المرتجعات', onTap: () => context.pushNamed(R.returns)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.tag, title: 'العروض والخصومات', onTap: () => context.pushNamed(R.offers)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.ticket, title: 'الكوبونات', onTap: () => context.pushNamed(R.coupons)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.fileText, title: 'طلبات ومشتريات', onTap: () => context.pushNamed(R.purchaseOrders)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.listChecks, title: 'طلبات العملاء', onTap: () => context.pushNamed(R.orders)),
                const Divider(height: 1, indent: 60),
                _SettingsLinkTile(icon: LucideIcons.fileUp, title: 'استيراد البيانات (CSV)', onTap: () => context.pushNamed(R.dataImport)),
                if (isFeatureEnabled('loyalty_program')) ...[
                  const Divider(height: 1, indent: 60),
                  _SettingsLinkTile(icon: LucideIcons.award, title: 'برنامج الولاء', onTap: () => context.pushNamed(R.loyalty)),
                ],
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xxl),
          const _SectionLabel('حول'),
          DukaniCard(
            padding: EdgeInsets.zero,
            child: _SettingsLinkTile(icon: LucideIcons.info, title: 'حول دُكاني', value: 'الإصدار 0.1.0', onTap: () => _showAboutDialog(context)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: DukaniSpacing.sm),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: DukaniColors.forest600),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
              ],
            ),
          ),
          const SizedBox(width: DukaniSpacing.sm),
          Switch(value: value, onChanged: onChanged, activeColor: DukaniColors.forest700),
        ],
      ),
    );
  }
}

class _SettingsLinkTile extends StatelessWidget {
  const _SettingsLinkTile({required this.icon, required this.title, this.value, required this.onTap});
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: DukaniColors.forest600),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null) ...[
            Text(value!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
            const SizedBox(width: 6),
          ],
          const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
        ],
      ),
    );
  }
}
