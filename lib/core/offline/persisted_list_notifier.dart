import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Base for a `StateNotifier<List<T>>` whose list should survive an app
/// restart. Subclasses just call `state = ...` exactly like a plain
/// [StateNotifier] — overriding the [state] setter here means every
/// existing mutation (`add`, `update`, `remove`, ...) persists automatically
/// without each method needing to know storage exists.
///
/// The box holds one Hive entry per item, keyed by list index, each entry a
/// plain `Map<String, dynamic>` of primitives (Hive needs no generated
/// adapter for those) produced by [toJson]/[fromJson].
abstract class PersistedListNotifier<T> extends StateNotifier<List<T>> {
  PersistedListNotifier({
    required this.box,
    required List<T> seed,
    required this.toJson,
    required this.fromJson,
  }) : super(_load(box, seed, fromJson)) {
    if (box.isEmpty && seed.isNotEmpty) _write(box, seed, toJson);
  }

  final Box box;
  final Map<String, dynamic> Function(T) toJson;
  final T Function(Map<String, dynamic>) fromJson;

  static List<T> _load<T>(Box box, List<T> seed, T Function(Map<String, dynamic>) fromJson) {
    if (box.isEmpty) return seed;
    try {
      return box.values.map((raw) => fromJson(Map<String, dynamic>.from(raw as Map))).toList();
    } catch (_) {
      // A shape mismatch from an older app version shouldn't brick the
      // screen — fall back to the seed rather than crash on launch.
      return seed;
    }
  }

  static void _write<T>(Box box, List<T> items, Map<String, dynamic> Function(T) toJson) {
    box.clear();
    box.addAll(items.map(toJson));
  }

  @override
  set state(List<T> value) {
    super.state = value;
    _write(box, value, toJson);
  }
}
