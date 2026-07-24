import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/offline/settings_controller.dart';
import '../../core/organizations/org_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/store/store_profile.dart';
import '../../core/store/store_profile_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  StoreProfile? _profile;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _populate(StoreProfile? profile) {
    if (_loaded) return;
    _loaded = true;
    _profile = profile;
    _nameController.text = profile?.ownerName ?? '';
    _phoneController.text = profile?.ownerPhone ?? '';
    _emailController.text = profile?.ownerEmail ?? '';
  }

  Future<void> _save() async {
    final orgId = await ref.read(currentOrgIdProvider.future);
    final current = _profile;
    if (orgId == null || current == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(storeRepositoryProvider).save(
            orgId,
            StoreProfile(
              storeName: current.storeName,
              ownerName: _nameController.text.trim(),
              ownerEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
              ownerPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
              businessType: current.businessType,
              countryCode: current.countryCode,
              taxEnabled: current.taxEnabled,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر الحفظ — تأكد من الاتصال بالإنترنت')));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _logout() async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'تسجيل الخروج؟',
      message: 'سيتم إنهاء الجلسة الحالية وستحتاج لتسجيل الدخول مجددًا.',
      confirmLabel: 'تسجيل الخروج',
      destructive: true,
      icon: LucideIcons.logOut,
    );
    if (!ok || !mounted) return;
    // Employees log in locally against sessionProvider without a Firebase
    // account of their own — only the owner's own logout should also end
    // the underlying Firebase session that keeps the store's data syncing.
    final isOwner = ref.read(sessionProvider)?.role == 'مالك';
    ref.read(sessionProvider.notifier).logout();
    if (isOwner) await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.goNamed(R.login);
  }

  Future<void> _deleteAccount() async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'حذف الحساب نهائيًا؟',
      message: 'هيتم حذف حسابك وتسجيل دخولك نهائيًا، ومش هتقدر تدخل بيه تاني. الإجراء ده لا يمكن التراجع عنه.',
      confirmLabel: 'حذف الحساب',
      destructive: true,
      icon: LucideIcons.userX,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (!mounted) return;
      context.goNamed(R.login);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر حذف الحساب — تأكد من الاتصال بالإنترنت وحاول تاني')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(storeProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(appBar: DukaniAppBar(title: 'الملف الشخصي'), body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(appBar: DukaniAppBar(title: 'الملف الشخصي'), body: DukaniEmptyState(title: 'تعذّر تحميل البيانات', icon: LucideIcons.wifiOff)),
      data: (profile) {
        _populate(profile);
        return Scaffold(
          appBar: const DukaniAppBar(title: 'الملف الشخصي'),
          body: ListView(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: DukaniColors.forest50, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.user, size: 44, color: DukaniColors.forest600),
                    ),
                    const SizedBox(height: DukaniSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: DukaniColors.gold100, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                      child: Text('مالك', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.gold700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DukaniSpacing.xxl),
              DukaniTextField(label: 'الاسم', controller: _nameController),
              const SizedBox(height: DukaniSpacing.lg),
              DukaniTextField(label: 'رقم الجوال', controller: _phoneController, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr),
              const SizedBox(height: DukaniSpacing.lg),
              DukaniTextField(label: 'البريد الإلكتروني', controller: _emailController, keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr, enabled: false),
              const SizedBox(height: DukaniSpacing.xl),
              DukaniButton(label: 'حفظ التعديلات', icon: LucideIcons.checkCircle2, loading: _saving, onPressed: _save),
              const SizedBox(height: DukaniSpacing.xxl),
              Text('عام', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
              const SizedBox(height: DukaniSpacing.sm),
              DukaniCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(LucideIcons.globe, size: 20, color: DukaniColors.forest600),
                      title: Text('اللغة', style: Theme.of(context).textTheme.titleSmall),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('العربية', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
                        ],
                      ),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('اللغة'),
                          content: const Text('يدعم دُكاني اللغة العربية حاليًا. دعم لغات إضافية (الإنجليزية، الفرنسية...) قادم في تحديث لاحق.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا'))],
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 60),
                    ListTile(
                      leading: const Icon(LucideIcons.wallet, size: 20, color: DukaniColors.forest600),
                      title: Text('العملة والضريبة', style: Theme.of(context).textTheme.titleSmall),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currentCurrencySymbol(), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
                        ],
                      ),
                      onTap: () => context.pushNamed(R.taxes),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DukaniSpacing.xxl),
              Text('الخصوصية', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
              const SizedBox(height: DukaniSpacing.sm),
              Consumer(
                builder: (context, ref, _) {
                  final settings = ref.watch(settingsProvider);
                  final ctrl = ref.read(settingsProvider.notifier);
                  return DukaniCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _PrivacySwitchTile(
                          icon: LucideIcons.scanFace,
                          title: 'التقاط صورة Selfie عند العمليات الحساسة',
                          subtitle: 'حذف فاتورة، تعديل، أو فتح درج الكاش. عطّلها لو مقيَّدة قانونيًا في دولتك.',
                          value: settings.selfieCaptureEnabled,
                          onChanged: ctrl.setSelfieCapture,
                        ),
                        const Divider(height: 1, indent: 60),
                        _PrivacySwitchTile(
                          icon: LucideIcons.mapPin,
                          title: 'تسجيل الموقع الجغرافي',
                          subtitle: 'يُرفق مع التنبيهات الحساسة لتحديد مكان حدوث العملية.',
                          value: settings.locationCaptureEnabled,
                          onChanged: ctrl.setLocationCapture,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: DukaniSpacing.md),
              DukaniOutlineButton(label: 'تسجيل الخروج', icon: LucideIcons.logOut, onPressed: _logout),
              const SizedBox(height: DukaniSpacing.md),
              TextButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(LucideIcons.userX, size: 18, color: DukaniColors.danger),
                label: Text('حذف الحساب نهائيًا', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.danger)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrivacySwitchTile extends StatelessWidget {
  const _PrivacySwitchTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});
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
