import '../../data/mock/mock_models.dart';
import 'business_type_controller.dart';

/// What a business type actually needs to see, in one place.
///
/// Before this existed, "is this grocery-specific?" was answered by
/// scattering `type == BusinessType.grocery` checks across the shell, the
/// home dashboard, and settings — each screen re-deciding the same policy
/// on its own. Every one of those call sites now reads from here instead,
/// so a merchant only ever sees screens and options that apply to their
/// actual activity, and a new business type (or a new gated feature) is one
/// edit here, not a hunt through the UI layer.
extension BusinessCapabilities on BusinessType {
  /// Unit-sale modes worth offering when adding a product, in display
  /// order. A clothing shop never weighs a t-shirt — showing that option
  /// anyway is exactly the clutter a merchant shouldn't have to wade
  /// through.
  List<ProductUnitMode> get availableUnitModes => switch (this) {
        BusinessType.grocery => ProductUnitMode.values,
        BusinessType.clothing || BusinessType.electronics || BusinessType.generalRetail => const [ProductUnitMode.each],
      };

  /// Whether warehouse/multi-location stock tooling ("إدارة المخازن") is
  /// worth surfacing. Every current business type sells retail stock it
  /// needs to track — kept as its own capability rather than assumed true
  /// everywhere, since that's exactly the kind of one-line change a future
  /// business type without physical stock would need.
  bool get tracksWarehouseInventory => true;

  /// Whether per-item serial number / IMEI + warranty tracking is worth
  /// surfacing on the product form. A real need for phones/laptops/
  /// appliances (returns and warranty claims live and die by this), and
  /// pure clutter for a bag of rice or a t-shirt — so it's opt-in per type
  /// rather than a field every merchant has to scroll past.
  bool get tracksSerialWarranty => this == BusinessType.electronics;

  /// Whether size/color variants are the expected default when adding a
  /// product — clothing is built around this, so its form nudges the
  /// merchant toward it instead of leaving "بدون خيارات" selected by
  /// default like every other type.
  bool get variantsEmphasized => this == BusinessType.clothing;

  /// Starter category list a brand-new store's category box is seeded
  /// with, including the "الكل" filter entry. A clothing or electronics
  /// merchant getting grocery sections like "لحوم ودواجن" out of the box
  /// was exactly the kind of cross-business-type bleed this exists to
  /// stop — every type gets its own real taxonomy instead of sharing one.
  List<String> get defaultCategories => switch (this) {
        BusinessType.grocery => mockPosCategories,
        BusinessType.clothing => mockClothingCategories,
        BusinessType.electronics => mockElectronicsCategories,
        BusinessType.generalRetail => mockGeneralRetailCategories,
      };
}
