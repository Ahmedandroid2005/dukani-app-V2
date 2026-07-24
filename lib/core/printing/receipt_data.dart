/// A frozen snapshot of everything a receipt needs to render — captured at
/// the moment a sale completes, before the cart is cleared, so printing or
/// re-printing later never depends on state that's since moved on.
class ReceiptLine {
  const ReceiptLine({required this.name, required this.qtyLabel, required this.unitPrice, required this.lineTotal});

  final String name;
  final String qtyLabel;
  final double unitPrice;
  final double lineTotal;
}

class ReceiptData {
  const ReceiptData({
    required this.invoiceId,
    required this.createdAt,
    required this.storeName,
    required this.lines,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.methodLabel,
    required this.currencySymbol,
    this.cashierName,
    this.tendered,
    this.change,
  });

  final String invoiceId;
  final DateTime createdAt;
  final String storeName;
  final String? cashierName;
  final List<ReceiptLine> lines;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String methodLabel;
  final String currencySymbol;
  final double? tendered;
  final double? change;

  int get itemCount => lines.length;
}
