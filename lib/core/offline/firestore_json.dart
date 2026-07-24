import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Hive stores a raw [DateTime]/[Uint8List] as-is, but Firestore hands
/// them back as its own [Timestamp]/[Blob] wrapper types on read. Every
/// model's `fromJson` already has to support both sources (whichever one
/// last synced), so these two conversions live in one place instead of
/// being re-guessed at each call site.
DateTime? asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  return null;
}

Uint8List? asBytes(dynamic value) {
  if (value == null) return null;
  if (value is Uint8List) return value;
  if (value is Blob) return value.bytes;
  return null;
}
