import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A Riverpod container reachable outside the widget tree — [appRouter]'s
/// redirect callback runs before a route's widgets (and their
/// BuildContext/ref) exist, so it can't use `ref.watch`/`ref.read` the
/// normal way. `main.dart` mounts the real widget tree on top of this same
/// container (via `UncontrolledProviderScope`) so both see identical state.
final rootContainer = ProviderContainer();
