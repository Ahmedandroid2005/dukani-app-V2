import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/dukani_theme.dart';

/// A gentle contrast/saturation boost applied to every merchant photo so
/// low-quality phone shots (dim, flat, slightly washed out) still look
/// crisp and consistent next to each other in the grid — without needing
/// a heavyweight image-processing pipeline.
const _enhanceMatrix = <double>[
  1.12, 0, 0, 0, -8,
  0, 1.12, 0, 0, -8,
  0, 0, 1.12, 0, -8,
  0, 0, 0, 1, 0,
];

/// Renders a product's real photo when the merchant has attached one,
/// falling back to its category icon otherwise. Used everywhere a product
/// appears (POS grid, cart, products list, inventory, transfers…) so a
/// photographed product looks the same across the whole app.
class DukaniProductImage extends StatelessWidget {
  const DukaniProductImage({
    super.key,
    required this.icon,
    this.photoBytes,
    this.size = 48,
    this.radius = DukaniRadii.sm,
  });

  final IconData icon;
  final Uint8List? photoBytes;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = photoBytes;
    // Merchant photos are captured at up to 1200x1200 (see
    // product_photo_picker.dart) but rendered here anywhere from a 24px
    // list icon up to a POS grid card — decoding the full source
    // resolution for a thumbnail wastes CPU and memory on every one of
    // potentially dozens visible in a grid or list at once. cacheWidth/
    // cacheHeight tell the decoder to downscale during decode instead of
    // after, which is the actual expensive step.
    final cachePixels = (size * MediaQuery.of(context).devicePixelRatio).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: DukaniColors.forest50,
        child: bytes == null
            ? Icon(icon, size: size * 0.5, color: DukaniColors.forest600)
            : ColorFiltered(
                colorFilter: const ColorFilter.matrix(_enhanceMatrix),
                child: Image.memory(
                  bytes,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  cacheWidth: cachePixels,
                  cacheHeight: cachePixels,
                ),
              ),
      ),
    );
  }
}
