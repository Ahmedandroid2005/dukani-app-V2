import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Real enforcement for the limits each plan card advertises in
/// subscription_screen.dart ("حتى 100 منتج", "فرع واحد"...) — before this,
/// the plan field only drove a badge, never actually blocked anything.
///
/// A store with no confirmed plan yet (new signup, subscription webhook
/// hasn't fired) is treated as unrestricted rather than locked to the
/// cheapest tier's limits — there's no free/trial tier in this app, so
/// refusing to let a brand-new merchant add their first products before
/// they've even seen the subscription screen would be a worse bug than
/// the one being fixed here.
class PlanLimits {
  const PlanLimits({this.maxProducts, this.maxBranches});

  /// null means unlimited.
  final int? maxProducts;
  final int? maxBranches;
}

const Map<String, PlanLimits> _limitsByPlan = {
  'starter': PlanLimits(maxProducts: 100, maxBranches: 1),
  'pro': PlanLimits(maxBranches: 3),
  'business': PlanLimits(),
};

PlanLimits planLimitsFor(String? planId) => _limitsByPlan[planId] ?? const PlanLimits();

Future<void> showUpgradeRequiredDialog(BuildContext context, String message) async {
  final goToSubscription = await DukaniConfirmDialog.show(
    context,
    title: 'وصلت للحد الأقصى في باقتك',
    message: message,
    confirmLabel: 'عرض الباقات',
    icon: LucideIcons.award,
  );
  if (goToSubscription && context.mounted) {
    context.pushNamed(R.subscription);
  }
}
