import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/connectivity_service.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// There's no discrete "backup snapshot" to trigger or restore in this
/// app — every module (products, customers, sales, employees...) already
/// pushes to Firestore on every change (see FirestoreSyncedListNotifier),
/// so the honest thing to show here is that continuous state, not a fake
/// manual backup/restore action with nothing real behind it.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const DukaniAppBar(title: 'النسخ الاحتياطي'),
      body: FutureBuilder<bool>(
        future: checkIsOnline(),
        builder: (context, snapshot) {
          final online = snapshot.data ?? true;
          return ListView(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            children: [
              DukaniCard(
                color: online ? DukaniColors.forest700 : DukaniColors.gold600,
                child: Column(
                  children: [
                    Icon(online ? LucideIcons.cloudCheck : LucideIcons.cloudOff, color: Colors.white, size: 32),
                    const SizedBox(height: DukaniSpacing.sm),
                    Text(
                      online ? 'بياناتك محفوظة تلقائيًا' : 'غير متصل بالإنترنت حاليًا',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
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
                        const Icon(LucideIcons.shieldCheck, size: 18, color: DukaniColors.forest600),
                        const SizedBox(width: DukaniSpacing.sm),
                        Expanded(child: Text('كيف يعمل حفظ بياناتك', style: Theme.of(context).textTheme.titleSmall)),
                      ],
                    ),
                    const SizedBox(height: DukaniSpacing.md),
                    Text(
                      'كل عملية تسجّلها في دُكاني — منتج، عملية بيع، عميل، موظف — تُحفظ فورًا على السحابة، بدون أي إجراء يدوي منك. '
                      'لو غيّرت جهازك أو حذفت التطبيق وأعدت تثبيته، كل بياناتك هتكون جاهزة فور تسجيل الدخول بنفس الحساب.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500),
                    ),
                    if (!online) ...[
                      const SizedBox(height: DukaniSpacing.md),
                      Row(
                        children: [
                          const Icon(LucideIcons.info, size: 14, color: DukaniColors.gold700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'إنت شغّال حاليًا بدون إنترنت — بياناتك محفوظة على جهازك وهتترفع على السحابة تلقائيًا فور عودة الاتصال.',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.gold700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
