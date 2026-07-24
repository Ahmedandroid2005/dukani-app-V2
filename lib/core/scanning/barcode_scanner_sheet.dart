import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/dukani_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Full-screen camera barcode scanner. Push it and await the result:
/// the decoded string (or null if the cashier backed out).
///
/// Works alongside — not instead of — HID wired/wireless scanners: those
/// simply type into whatever text field has focus and need no special
/// code here, so this screen only covers the camera path.
Future<String?> showBarcodeScannerScreen(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const _BarcodeScannerScreen(), fullscreenDialog: true),
  );
}

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
    ],
  );
  bool _handled = false;
  double _zoom = 0;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const _ScannerFrameOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DukaniSpacing.md),
              child: Row(
                children: [
                  _RoundControl(icon: LucideIcons.x, onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  _RoundControl(
                    icon: LucideIcons.zap,
                    onTap: () => _controller.toggleTorch(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: DukaniSpacing.xl,
            right: DukaniSpacing.xl,
            bottom: DukaniSpacing.xl,
            child: Column(
              children: [
                const Text(
                  'وجّه الكاميرا نحو الباركود — قرّب الكاميرا إذا كان الباركود صغيرًا أو تالفًا',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: DukaniSpacing.sm),
                Row(
                  children: [
                    const Icon(LucideIcons.zoomOut, color: Colors.white70, size: 18),
                    Expanded(
                      child: Slider(
                        value: _zoom,
                        onChanged: (v) {
                          setState(() => _zoom = v);
                          _controller.setZoomScale(v);
                        },
                      ),
                    ),
                    const Icon(LucideIcons.zoomIn, color: Colors.white70, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrameOverlay extends StatelessWidget {
  const _ScannerFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 170,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 2),
            borderRadius: BorderRadius.circular(DukaniRadii.md),
          ),
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: Colors.white, size: 22)),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
