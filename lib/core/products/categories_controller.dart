import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../business/business_capabilities.dart';
import '../business/business_type_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

/// The merchant's own editable category list — seeded from the taxonomy
/// that matches their chosen business type (grocery/clothing/electronics/
/// general retail all get their own real starter set, not a shared one),
/// but the merchant can delete ones they'll never use and add their own.
/// "الكل" (all) is a fixed filter, never a real category, so it's never
/// stored here.
class CategoriesController extends FirestoreSyncedListNotifier<String> {
  CategoriesController(String? ownerUid, BusinessType businessType)
      : super(
          box: LocalDb.categories,
          seed: businessType.defaultCategories.skip(1).toList(),
          toJson: (c) => {'v': c},
          fromJson: (json) => json['v'] as String,
          ownerUid: ownerUid,
          collectionName: 'categories',
        );

  void add(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) return;
    state = [...state, trimmed];
  }

  void remove(String category) {
    state = state.where((c) => c != category).toList();
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesController, List<String>>(
  (ref) => CategoriesController(ref.watch(authStateProvider).valueOrNull?.uid, ref.watch(businessTypeProvider)),
);
