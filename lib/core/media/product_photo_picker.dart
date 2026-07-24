import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Opens a camera/gallery action sheet and returns the picked photo's bytes,
/// or null if cancelled. Bytes (not a file path) so the result renders
/// identically on web and native — see [MockProduct.photoBytes] and
/// [MockEmployee.photoBytes]. Used for both product photos and employee
/// photos (set by the store owner when creating the employee's account).
Future<Uint8List?> pickPhoto(BuildContext context, {String title = 'الصورة'}) async {
  final source = await showDukaniSheet<ImageSource>(
    context,
    title: title,
    child: Column(
      children: [
        DukaniSheetAction(
          icon: LucideIcons.camera,
          label: 'التقاط صورة',
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        DukaniSheetAction(
          icon: LucideIcons.images,
          label: 'اختيار من المعرض',
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
      ],
    ),
  );
  if (source == null) return null;

  final picked = await ImagePicker().pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
  if (picked == null) return null;
  return picked.readAsBytes();
}
