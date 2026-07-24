import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'firebase_auth_repository.dart';

final firebaseAuthProvider = Provider<firebase.FirebaseAuth>((ref) => firebase.FirebaseAuth.instance);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(ref.watch(firebaseAuthProvider)),
);

/// The live "who's actually logged in" signal, straight from Firebase —
/// survives app restarts on its own since Firebase persists the session,
/// so this is what route guards should watch instead of re-deriving it.
final authStateProvider = StreamProvider<AuthUser?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// Drives the login/register screens specifically: exposes a loading
/// state while a request is in flight and surfaces [AuthException]
/// through Riverpod's own error channel, so a screen just reads
/// `state.hasError` / `state.error` instead of managing its own
/// try/catch and loading flag.
class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._repository) : super(const AsyncValue.data(null));
  final AuthRepository _repository;

  Future<bool> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signUp(email: email, password: password);
      state = AsyncValue.data(user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signIn(email: email, password: password);
      state = AsyncValue.data(user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>(
  (ref) => AuthController(ref.watch(authRepositoryProvider)),
);
