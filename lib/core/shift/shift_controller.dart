import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../organizations/org_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

enum CashMovementType { cashIn, cashOut }

class CashMovement {
  const CashMovement({required this.type, required this.amount, required this.note, required this.time});
  final CashMovementType type;
  final double amount;
  final String note;
  final DateTime time;

  Map<String, dynamic> toJson() => {'type': type.name, 'amount': amount, 'note': note, 'time': time.toIso8601String()};

  factory CashMovement.fromJson(Map<String, dynamic> json) => CashMovement(
        type: CashMovementType.values.firstWhere((t) => t.name == json['type'], orElse: () => CashMovementType.cashIn),
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String? ?? '',
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      );
}

/// A single open-to-close cash register session. Expected cash is
/// tracked from the opening float plus manual cash movements only — this
/// phase doesn't yet reconcile against a persisted sales ledger, so cash
/// sales aren't folded in automatically.
class ShiftRecord {
  const ShiftRecord({
    required this.id,
    required this.cashierName,
    required this.openedAt,
    required this.openingAmount,
    this.movements = const [],
    this.closed = false,
    this.closingCountedAmount,
    this.closedAt,
  });

  final String id;
  final String cashierName;
  final DateTime openedAt;
  final double openingAmount;
  final List<CashMovement> movements;
  final bool closed;
  final double? closingCountedAmount;
  final DateTime? closedAt;

  double get cashIn => movements.where((m) => m.type == CashMovementType.cashIn).fold(0.0, (s, m) => s + m.amount);
  double get cashOut => movements.where((m) => m.type == CashMovementType.cashOut).fold(0.0, (s, m) => s + m.amount);
  double get expectedCash => openingAmount + cashIn - cashOut;
  double? get variance => closingCountedAmount == null ? null : closingCountedAmount! - expectedCash;

  ShiftRecord copyWith({List<CashMovement>? movements, bool? closed, double? closingCountedAmount, DateTime? closedAt}) => ShiftRecord(
        id: id,
        cashierName: cashierName,
        openedAt: openedAt,
        openingAmount: openingAmount,
        movements: movements ?? this.movements,
        closed: closed ?? this.closed,
        closingCountedAmount: closingCountedAmount ?? this.closingCountedAmount,
        closedAt: closedAt ?? this.closedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cashierName': cashierName,
        'openedAt': openedAt.toIso8601String(),
        'openingAmount': openingAmount,
        'movements': movements.map((m) => m.toJson()).toList(),
        'closed': closed,
        if (closingCountedAmount != null) 'closingCountedAmount': closingCountedAmount,
        if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
      };

  factory ShiftRecord.fromJson(Map<String, dynamic> json) => ShiftRecord(
        id: json['id'] as String,
        cashierName: json['cashierName'] as String,
        openedAt: DateTime.tryParse(json['openedAt'] as String? ?? '') ?? DateTime.now(),
        openingAmount: (json['openingAmount'] as num).toDouble(),
        movements: (json['movements'] as List?)?.map((m) => CashMovement.fromJson(Map<String, dynamic>.from(m as Map))).toList() ?? const [],
        closed: json['closed'] as bool? ?? false,
        closingCountedAmount: (json['closingCountedAmount'] as num?)?.toDouble(),
        closedAt: json['closedAt'] == null ? null : DateTime.tryParse(json['closedAt'] as String),
      );
}

/// Every shift the store has ever opened, newest first — synced to
/// Firestore like every other module so a shift survives a reinstall and
/// is visible to the Super Admin panel, not just kept in memory for the
/// current app session.
class ShiftController extends FirestoreSyncedListNotifier<ShiftRecord> {
  ShiftController(String? orgId)
      : super(box: LocalDb.shifts, seed: const [], toJson: (s) => s.toJson(), fromJson: ShiftRecord.fromJson, orgId: orgId, collectionName: 'shifts');

  /// The open shift, if any — always the newest record when it isn't closed.
  ShiftRecord? get current => state.isEmpty || state.first.closed ? null : state.first;

  void openShift(String cashierName, double openingAmount) {
    if (current != null) return;
    state = [
      ShiftRecord(id: DateTime.now().microsecondsSinceEpoch.toString(), cashierName: cashierName, openedAt: DateTime.now(), openingAmount: openingAmount),
      ...state,
    ];
  }

  void addMovement(CashMovementType type, double amount, String note) {
    final open = current;
    if (open == null) return;
    state = [
      for (final s in state) s.id == open.id ? s.copyWith(movements: [...s.movements, CashMovement(type: type, amount: amount, note: note, time: DateTime.now())]) : s,
    ];
  }

  void closeShift(double countedAmount) {
    final open = current;
    if (open == null) return;
    state = [for (final s in state) s.id == open.id ? s.copyWith(closed: true, closingCountedAmount: countedAmount, closedAt: DateTime.now()) : s];
  }
}

final shiftProvider = StateNotifierProvider<ShiftController, List<ShiftRecord>>(
  (ref) => ShiftController(ref.watch(currentOrgIdProvider).valueOrNull),
);

/// The currently open shift, if any — derived so screens can watch a
/// single nullable value instead of re-deriving "first unclosed record"
/// themselves everywhere. Watches the state list directly (not
/// `.notifier`) so it actually rebuilds when a shift opens/closes.
final currentShiftProvider = Provider<ShiftRecord?>((ref) {
  final shifts = ref.watch(shiftProvider);
  return shifts.isEmpty || shifts.first.closed ? null : shifts.first;
});
