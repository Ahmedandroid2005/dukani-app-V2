import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/alerts/product_alerts.dart';
import '../../core/business/country_controller.dart';
import '../../core/notifications/broadcast_notifications.dart';
import '../../core/offline/settings_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/subscription/subscription_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

final _broadcastsProvider = FutureProvider<List<BroadcastNotification>>((ref) => fetchBroadcastNotifications());

DukaniBadgeTone _tone(String severity) => switch (severity) {
      'danger' => DukaniBadgeTone.danger,
      'warning' => DukaniBadgeTone.warning,
      _ => DukaniBadgeTone.info,
    };

IconData _icon(String title) {
  if (title.contains('حذف')) return LucideIcons.trash2;
  if (title.contains('خصم')) return LucideIcons.percent;
  if (title.contains('كاش')) return LucideIcons.store;
  if (title.contains('سينفد')) return LucideIcons.packageX;
  return LucideIcons.bellRing;
}

IconData _productAlertIcon(ProductAlertKind kind) =>
    kind == ProductAlertKind.expiry ? LucideIcons.calendarX : LucideIcons.hourglass;

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final productAlerts = ref.watch(productAlertsProvider);
    final sensitiveEntries = ref.watch(activityLogProvider).where((e) => e.sensitive).toList();
    final plan = ref.watch(currentPlanProvider).valueOrNull ?? 'free';
    final countryCode = ref.watch(countryProvider);
    final broadcasts = ref.watch(_broadcastsProvider).valueOrNull?.where((b) => b.matches(plan: plan, countryCode: countryCode)).toList() ?? const [];

    return Scaffold(
      appBar: const DukaniAppBar(title: 'التنبيهات'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          if (broadcasts.isNotEmpty) ...[
            Text('من فريق دُكاني', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
            const SizedBox(height: DukaniSpacing.sm),
            for (final b in broadcasts) ...[
              DukaniCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: DukaniColors.gold100, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
                      child: const Icon(LucideIcons.megaphone, size: 18, color: DukaniColors.gold700),
                    ),
                    const SizedBox(width: DukaniSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.title, style: Theme.of(context).textTheme.titleSmall),
                          Text(b.message, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DukaniSpacing.md),
            ],
            const SizedBox(height: DukaniSpacing.sm),
          ],
          Text('تفضيلات الإشعارات', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.sm),
          DukaniCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _NotifyTile(icon: LucideIcons.store, title: 'إتمام عمليات البيع', value: settings.notifySales, onChanged: settingsCtrl.setNotifySales),
                const Divider(height: 1, indent: 60),
                _NotifyTile(icon: LucideIcons.trendingDown, title: 'مخزون منخفض أو نافد', value: settings.notifyLowStock, onChanged: settingsCtrl.setNotifyLowStock),
                const Divider(height: 1, indent: 60),
                _NotifyTile(icon: LucideIcons.fileText, title: 'استحقاق ديون العملاء', value: settings.notifyDebts, onChanged: settingsCtrl.setNotifyDebts),
                const Divider(height: 1, indent: 60),
                _NotifyTile(icon: LucideIcons.clock, title: 'إغلاق الوردية', value: settings.notifyShiftClose, onChanged: settingsCtrl.setNotifyShiftClose),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xxl),
          if (productAlerts.isEmpty && sensitiveEntries.isEmpty)
            const DukaniEmptyState(title: 'لا توجد تنبيهات', message: 'ستظهر هنا أي حركة تستدعي انتباهك', icon: LucideIcons.bellOff),
          if (productAlerts.isNotEmpty) ...[
            Text('تنبيهات استباقية — الصلاحية والركود', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: DukaniSpacing.sm),
            for (final alert in productAlerts) ...[
              DukaniCard(
                onTap: () => context.pushNamed(R.productEdit, pathParameters: {'id': alert.product.id}),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DukaniProductImage(icon: alert.product.icon, photoBytes: alert.product.photoBytes, size: 40),
                    const SizedBox(width: DukaniSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_productAlertIcon(alert.kind), size: 14, color: DukaniColors.ink500),
                              const SizedBox(width: 4),
                              Expanded(child: Text(alert.title, style: Theme.of(context).textTheme.titleSmall)),
                              DukaniBadge(label: alert.severity == 'danger' ? 'عاجل' : (alert.severity == 'warning' ? 'تنبيه' : 'ملاحظة'), tone: _tone(alert.severity)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(alert.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DukaniSpacing.md),
            ],
            const SizedBox(height: DukaniSpacing.md),
            Text('سجل الأنشطة', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: DukaniSpacing.sm),
          ],
          for (final entry in sensitiveEntries) ...[
            DukaniCard(
              onTap: () => _openDetail(context, entry, settings),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: DukaniColors.dangerBg.withOpacity(0.6), borderRadius: BorderRadius.circular(DukaniRadii.sm)),
                    child: Icon(_icon(entry.action), size: 18, color: DukaniColors.danger),
                  ),
                  const SizedBox(width: DukaniSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(entry.action, style: Theme.of(context).textTheme.titleSmall)),
                            DukaniBadge(label: entry.time, tone: DukaniBadgeTone.neutral),
                          ],
                        ),
                        if (entry.reason.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('السبب: ${entry.reason}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const DukaniSeverityDot(tone: DukaniBadgeTone.danger),
                            const SizedBox(width: 6),
                            Text('${entry.employeeName} — ${entry.branch}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DukaniSpacing.md),
          ],
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, MockActivityEntry entry, AppSettings settings) {
    final showSelfie = entry.employeePhoto != null && settings.selfieCaptureEnabled;

    showDukaniSheet(
      context,
      title: entry.action,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entry.reason.isNotEmpty) Text(entry.reason, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: DukaniSpacing.xl),
          _DetailRow(icon: LucideIcons.user, label: 'الموظف', value: entry.employeeName),
          _DetailRow(icon: LucideIcons.clock, label: 'الوقت', value: entry.time),
          _DetailRow(icon: LucideIcons.calendar, label: 'التاريخ', value: entry.date),
          _DetailRow(icon: LucideIcons.store, label: 'الفرع', value: entry.branch),
          _DetailRow(icon: LucideIcons.smartphone, label: 'الجهاز', value: entry.device),
          if (showSelfie) const _DetailRow(icon: LucideIcons.scanFace, label: 'صورة Selfie', value: 'مرفقة'),
          if (entry.employeePhoto != null && !showSelfie) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.shieldAlert, size: 14, color: DukaniColors.ink500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'تم تعطيل التقاط Selfie من إعدادات الخصوصية',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DukaniColors.ink500),
          const SizedBox(width: DukaniSpacing.md),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          const Spacer(),
          Text(value, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _NotifyTile extends StatelessWidget {
  const _NotifyTile({required this.icon, required this.title, required this.value, required this.onChanged});
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 20, color: DukaniColors.forest600),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: DukaniColors.forest600),
    );
  }
}
