import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/dukani_theme.dart';
import '../widgets/widgets.dart';
import 'charge_controller.dart';
import 'charge_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The WebView never actually loads this URL — createCharge.ts sets it as
/// the gateway's redirect target, and onNavigationRequest below intercepts
/// any navigation to it before the request goes out, so it's really just a
/// marker the app watches for, not a page anyone renders.
const _redirectPrefix = 'https://al-sharqawi-tech.web.app/dukani-payment-return';

/// Opens the connected gateway's hosted checkout page and waits for the
/// *server* (not the WebView redirect, which proves nothing on its own) to
/// confirm the charge succeeded. Returns true only on a confirmed success.
Future<bool> showGatewayCheckoutScreen(
  BuildContext context, {
  required double amount,
  required String currencyCode,
  required String methodId,
}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => _GatewayCheckoutScreen(amount: amount, currencyCode: currencyCode, methodId: methodId),
      fullscreenDialog: true,
    ),
  );
  return result ?? false;
}

enum _Stage { creating, awaitingCustomer, verifying, succeeded, failed }

class _GatewayCheckoutScreen extends ConsumerStatefulWidget {
  const _GatewayCheckoutScreen({required this.amount, required this.currencyCode, required this.methodId});
  final double amount;
  final String currencyCode;
  final String methodId;

  @override
  ConsumerState<_GatewayCheckoutScreen> createState() => _GatewayCheckoutScreenState();
}

class _GatewayCheckoutScreenState extends ConsumerState<_GatewayCheckoutScreen> {
  _Stage _stage = _Stage.creating;
  String? _error;
  WebViewController? _webController;
  String? _chargeId;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final repo = ref.read(chargeRepositoryProvider);
      final session = await repo.createCharge(
        amount: widget.amount,
        currencyCode: widget.currencyCode,
        methodId: widget.methodId,
      );
      _chargeId = session.chargeId;
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              if (request.url.startsWith(_redirectPrefix)) {
                _verify();
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
    } on ChargeException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _stage = _Stage.failed;
      });
    }
  }

  Future<void> _verify() async {
    if (_chargeId == null) return;
    setState(() => _stage = _Stage.verifying);
    final repo = ref.read(chargeRepositoryProvider);
    try {
      // The gateway can take a moment to settle the charge on its side
      // after redirecting back, so re-check a few times before giving up.
      for (var attempt = 0; attempt < 5; attempt++) {
        final status = await repo.getStatus(_chargeId!);
        if (status == ChargeStatus.succeeded) {
          if (!mounted) return;
          setState(() => _stage = _Stage.succeeded);
          await Future.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;
          Navigator.of(context).pop(true);
          return;
        }
        if (status == ChargeStatus.failed) break;
        await Future.delayed(const Duration(seconds: 2));
      }
      if (!mounted) return;
      setState(() {
        _error = 'لم يتم تأكيد الدفع — حاول مرة أخرى أو اختر طريقة دفع تانية.';
        _stage = _Stage.failed;
      });
    } on ChargeException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _stage = _Stage.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DukaniAppBar(title: 'الدفع'),
      body: switch (_stage) {
        _Stage.creating => const Center(child: CircularProgressIndicator()),
        _Stage.awaitingCustomer when _webController != null => WebViewWidget(controller: _webController!),
        _Stage.awaitingCustomer => const Center(child: CircularProgressIndicator()),
        _Stage.verifying => const _StatusView(icon: LucideIcons.hourglass, message: 'جاري التحقق من الدفع...', spinning: true),
        _Stage.succeeded => const _StatusView(icon: LucideIcons.checkCircle2, message: 'تم الدفع بنجاح', color: DukaniColors.success),
        _Stage.failed => DukaniErrorState(message: _error ?? 'تعذّر إتمام الدفع', onRetry: () => Navigator.of(context).pop(false)),
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
