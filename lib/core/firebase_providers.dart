import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single [FirebaseFirestore] instance every repository provider
/// depends on — kept in its own file (no other core import) so modules
/// that both need it (store profile, org membership) never end up
/// importing each other just to reach it.
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
