import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/organizations/org_controller.dart';
import '../../core/subscription/subscription_controller.dart';
import '../../core/subscription/subscription_repository.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _redirectPrefix = 'https://al-sharqawi-tech.web.app/dukani-subscription-return';

/// Opens Stripe's hosted subscription checkout in a WebView. Unlike the POS
/// gateway checkout (which polls a status endpoint), confirmation here
/// comes from Stripe's webhook writing straight to Firestore — this screen
/// just waits for [currentPlanProvider] to catch up to [planId] after the
/// redirect, since that's the same signal the rest of the app already
/// trusts as "the subscription is real."
Future<bool> showSubscriptionCheckoutScreen(BuildContext context, {required String planId}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => _SubscriptionCheckoutScreen(planId: planId), fullscreenDialog: true),
  );
  return result ?? false;
}

enum _Stage { creating, awaitingCustomer, confirming, succeeded, failed }

class _SubscriptionCheckoutScreen extends ConsumerStatefulWidget {
  const _SubscriptionCheckoutScreen({required this.planId});
  final String planId;

  @override
  ConsumerState<_SubscriptionCheckoutScreen> createState() => _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState extends ConsumerState<_SubscriptionCheckoutScreen> {
  _Stage _stage = _Stage.creating;
  String? _error;
  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final repo = ref.read(subscriptionRepositoryProvider);
      final session = await repo.createCheckout(widget.planId);
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              if (request.url.startsWith(_redirectPrefix)) {
                _waitForConfirmation();
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(session.checkoutUrl));
      if (!mounted) return;
      setState(() {
        _webController = controller;
        _stage = _Stage.awaitingCustomer;
      });
    } on SubscriptionException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _stage = _Stage.failed;
      });
    }
  }

  Future<void> _waitForConfirmation() async {
    setState(() => _stage = _Stage.confirming);
    final orgId = await ref.read(currentOrgIdProvider.future);
    if (orgId == null) {
      setState(() => _stage = _Stage.failed);
      return;
    }
    final repo = ref.read(subscriptionRepositoryProvider);
    // Stripe's webhook usually lands within a couple of seconds of the
    // redirect — this gives it a reasonable window before giving up.
    final confirmed = repo.watchPlan(orgId).firstWhere(
          (plan) => plan == widget.planId,
          orElse: () => null,
        );
    final plan = await confirmed.timeout(const Duration(seconds: 20), onTimeout: () => null);
    if (plan == widget.planId) {
      if (!mounted) return;
      setState(() => _stage = _Stage.succeeded);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }
    if (!mounted) return;
    setState(() {
      _error = 'الدفع يتأكد وقد يستغرق دقيقة — الباقة هتتحدث تلقائيًا فور التأكيد.';
      _stage = _Stage.failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DukaniAppBar(title: 'الترقية'),
      body: switch (_stage) {
        _Stage.creating => const Center(child: CircularProgressIndicator()),
        _Stage.awaitingCustomer when _webController != null => WebViewWidget(controller: _webController!),
        _Stage.awaitingCustomer => const Center(child: CircularProgressIndicator()),
        _Stage.confirming => const _StatusView(icon: LucideIcons.hourglass, message: 'جاري تأكيد الاشتراك...', spinning: true),
        _Stage.succeeded => const _StatusView(icon: LucideIcons.checkCircle2, message: 'تم تفعيل الباقة', color: DukaniColors.success),
        _Stage.failed => DukaniErrorState(message: _error ?? 'تعذّرت الترقية', onRetry: () => Navigator.of(context).pop(false)),
      },
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.icon, required this.message, this.color, this.spinning = false});
  final IconData icon;
  final String message;
  final Color? color;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spinning) const CircularProgressIndicator() else Icon(icon, size: 56, color: color ?? DukaniColors.forest500),
          const SizedBox(height: DukaniSpacing.lg),
          Text(message, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
