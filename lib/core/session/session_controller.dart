import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';

/// Whoever is currently signed in on this device — set on a successful
/// login (owner or employee) and read by the audit log so every entry can
/// attribute a real name, photo, and branch instead of a hardcoded string.
class SessionController extends StateNotifier<MockEmployee?> {
  SessionController() : super(null);

  void login(MockEmployee employee) => state = employee;

  void logout() => state = null;
}

final sessionProvider = StateNotifierProvider<SessionController, MockEmployee?>(
  (ref) => SessionController(),
);
