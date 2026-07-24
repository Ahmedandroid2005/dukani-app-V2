import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/products/categories_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Lets the merchant curate their own category list — remove the ones a
/// grocery store never uses, add their own. Reachable from the product
/// form's category picker and the products list.
void showManageCategoriesSheet(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  showDukaniSheet(
    context,
    title: 'إدارة الفئات',
    child: StatefulBuilder(
      builder: (context, setSheetState) {
        final categories = ref.watch(categoriesProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DukaniTextField(
                    hint: 'اسم فئة جديدة',
                    controller: controller,
                    onSubmitted: (v) {
                      ref.read(categoriesProvider.notifier).add(v);
                      controller.clear();
                      setSheetState(() {});
                    },
                  ),
                ),
                const SizedBox(width: DukaniSpacing.sm),
                DukaniIconAction(
                  icon: LucideIcons.plus,
                  onTap: () {
                    ref.read(categoriesProvider.notifier).add(controller.text);
                    controller.clear();
                    setSheetState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: DukaniSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in categories)
                      Chip(
                        label: Text(category),
                        onDeleted: () {
                          ref.read(categoriesProvider.notifier).remove(category);
                          setSheetState(() {});
                        },
                        deleteIcon: const Icon(LucideIcons.x, size: 16),
                        backgroundColor: DukaniColors.forest50,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
