// ignore_for_file: text_direction_code_point_in_literal
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/business/business_type_controller.dart';
import '../../core/business/country_controller.dart';
import '../../core/constants/dukani_countries.dart';
import '../../core/store/store_profile.dart';
import '../../core/store/store_profile_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/setup_progress.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _businessTypes = ['بقالة / سوبر ماركت', 'ملابس', 'إلكترونيات', 'أخرى'];

class StoreSetupWizard extends ConsumerStatefulWidget {
  const StoreSetupWizard({super.key});

  @override
  ConsumerState<StoreSetupWizard> createState() => _StoreSetupWizardState();
}

class _StoreSetupWizardState extends ConsumerState<StoreSetupWizard> {
  final _pageController = PageController();
  final _storeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  int _step = 0;
  static const _totalSteps = 3;

  String _businessType = _businessTypes.first;
  DukaniCountry _country = dukaniCountries.first;
  bool _taxEnabled = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pageController.dispose();
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // Reads straight off FirebaseAuth's synchronous `currentUser` (via the
    // repository), not authStateProvider's stream — the stream can still be
    // sitting in its initial loading state this soon after sign-up/sign-in
    // (nothing else in the tree has watched it yet to prime it), which was
    // failing this save outright even though the user really was signed in.
    final user = ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid;
    if (uid == null) {
      setState(() => _error = 'حصل خطأ — رجّع سجّل دخولك تاني');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(storeRepositoryProvider).save(
            uid,
            StoreProfile(
              storeName: _storeNameController.text.trim(),
              ownerName: _ownerNameController.text.trim(),
              ownerEmail: user?.email,
              ownerPhone: _ownerPhoneController.text.trim().isEmpty ? null : _ownerPhoneController.text.trim(),
              businessType: businessTypeFromLabel(_businessType).name,
              countryCode: _country.code,
              taxEnabled: _taxEnabled,
            ),
          );
      ref.read(businessTypeProvider.notifier).set(businessTypeFromLabel(_businessType));
      await ref.read(countryProvider.notifier).set(_country.code);
      if (!mounted) return;
      context.goNamed('preparingStore');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر حفظ بيانات متجرك — تأكد من الاتصال بالإنترنت وحاول تاني');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_step == _totalSteps - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
    _pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  void _back() {
    if (_step == 0) {
      context.pop();
      return;
    }
    setState(() => _step--);
    _pageController.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DukaniAppBar(
        title: 'تجهيز متجرك',
        // Steps 1+ go back a wizard step, not off the screen — the shared
        // DukaniAppBar back button always pops the route, so this needs its
        // own leading widget (same circular styling) wired to _back instead.
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: Theme.of(context).brightness == Brightness.dark ? DukaniColors.darkSurfaceAlt : DukaniColors.forest50,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _back,
              child: const Padding(padding: EdgeInsets.all(8), child: Icon(LucideIcons.arrowRight, size: 18)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.xl),
              child: SetupProgress(step: _step, total: _totalSteps),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StoreInfoStep(
                    key: const ValueKey('info'),
                    storeNameController: _storeNameController,
                    ownerNameController: _ownerNameController,
                    ownerPhoneController: _ownerPhoneController,
                  ),
                  _BusinessTypeStep(
                    selected: _businessType,
                    onSelect: (v) => setState(() => _businessType = v),
                  ),
                  _CountryTaxStep(
                    country: _country,
                    taxEnabled: _taxEnabled,
                    onCountry: (c) => setState(() => _country = c),
                    onTaxToggle: (v) => setState(() => _taxEnabled = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(DukaniSpacing.xl, 0, DukaniSpacing.xl, DukaniSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.danger), textAlign: TextAlign.center),
                    const SizedBox(height: DukaniSpacing.sm),
                  ],
                  DukaniButton(
                    label: _step == _totalSteps - 1 ? 'إنهاء الإعداد' : 'التالي',
                    loading: _saving,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreInfoStep extends StatelessWidget {
  const _StoreInfoStep({super.key, required this.storeNameController, required this.ownerNameController, required this.ownerPhoneController});

  final TextEditingController storeNameController;
  final TextEditingController ownerNameController;
  final TextEditingController ownerPhoneController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DukaniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('بيانات متجرك', style: textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('هذه المعلومات ستظهر في فواتيرك وتقاريرك', style: textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.xxl),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: DukaniColors.forest50, shape: BoxShape.circle, border: Border.all(color: DukaniColors.ink100)),
                  child: const Icon(LucideIcons.store, size: 36, color: DukaniColors.forest500),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: DukaniColors.gold500, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xxl),
          DukaniTextField(label: 'اسم المتجر', hint: 'مثال: بقالة الأمانة', controller: storeNameController),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'اسمك الكامل', hint: 'مثال: أحمد محمد', controller: ownerNameController),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'رقم جوالك', hint: '05xxxxxxxx', keyboardType: TextInputType.phone, textDirection: TextDirection.ltr, controller: ownerPhoneController),
        ],
      ),
    );
  }
}

class _BusinessTypeStep extends StatelessWidget {
  const _BusinessTypeStep({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DukaniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ما هو نشاطك التجاري؟', style: textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('سنخصص لك المنتجات والتقارير المناسبة', style: textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.xxl),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _businessTypes
                .map((t) => DukaniChoiceChip(label: t, selected: t == selected, onTap: () => onSelect(t)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CountryTaxStep extends StatelessWidget {
  const _CountryTaxStep({
    required this.country,
    required this.taxEnabled,
    required this.onCountry,
    required this.onTaxToggle,
  });

  final DukaniCountry country;
  final bool taxEnabled;
  final ValueChanged<DukaniCountry> onCountry;
  final ValueChanged<bool> onTaxToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DukaniSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('الدولة والعملة', style: textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('سيتم تحديد العملة والضريبة تلقائيًا حسب دولتك', style: textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.xl),
          Text('الدولة', style: textTheme.titleSmall),
          const SizedBox(height: DukaniSpacing.sm),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: dukaniCountries
                .map((c) => DukaniChoiceChip(label: '${c.flag}  ${c.nameAr}', selected: c.code == country.code, onTap: () => onCountry(c)))
                .toList(),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniCard(
            child: Row(
              children: [
                const Icon(LucideIcons.wallet, color: DukaniColors.forest600),
                const SizedBox(width: DukaniSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('العملة', style: textTheme.titleSmall),
                      Text('${country.currencyNameAr} (${country.currencyCode})', style: textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.receipt, color: DukaniColors.gold600),
                    const SizedBox(width: DukaniSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('متجر مسجّل ضريبيًا؟', style: textTheme.titleSmall),
                          Text(
                            country.defaultTaxRate > 0
                                ? '${country.taxNameAr} في ${country.nameAr}: ⁦${country.defaultTaxRate.toStringAsFixed(0)}%⁩'
                                : 'لا توجد ضريبة افتراضية في ${country.nameAr}',
                            style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: taxEnabled, onChanged: onTaxToggle, activeColor: DukaniColors.forest700),
                  ],
                ),
                if (taxEnabled) ...[
                  const SizedBox(height: DukaniSpacing.md),
                  const Divider(),
                  const SizedBox(height: DukaniSpacing.md),
                  Row(
                    children: [
                      const Icon(LucideIcons.info, size: 16, color: DukaniColors.ink500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'يمكنك إلغاء الضريبة في أي وقت من الإعدادات، لكن لا يمكن تغيير نسبتها إلا بالتواصل مع الدعم الفني.',
                          style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
