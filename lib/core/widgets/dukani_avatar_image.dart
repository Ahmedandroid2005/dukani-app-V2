import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/dukani_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A gentle contrast/saturation boost so a merchant's own low-quality photo
/// still looks crisp and consistent — same treatment as [DukaniProductImage].
const _enhanceMatrix = <double>[
  1.12, 0, 0, 0, -8,
  0, 1.12, 0, 0, -8,
  0, 0, 1.12, 0, -8,
  0, 0, 0, 1, 0,
];

/// Circular person avatar: shows the employee's real photo when the store
/// owner has attached one, falling back to a plain person icon otherwise.
/// Used on the employee-login identity check, the employees list, and
/// audit-log entries.
class DukaniAvatarImage extends StatelessWidget {
  const DukaniAvatarImage({super.key, this.photoBytes, this.size = 48});

  final Uint8List? photoBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bytes = photoBytes;
    // Same reasoning as DukaniProductImage: decode straight to the size
    // this avatar is actually rendered at instead of the full captured
    // resolution, so a list of employees/audit entries doesn't pay for
    // decoding a full-size photo per row.
    final cachePixels = (size * MediaQuery.of(context).devicePixelRatio).round();
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: DukaniColors.forest50,
        child: bytes == null
            ? Icon(LucideIcons.user, size: size * 0.55, color: DukaniColors.forest600)
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
