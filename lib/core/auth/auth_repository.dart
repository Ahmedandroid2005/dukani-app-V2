/// A signed-in identity — deliberately just the two fields the app's UI
/// actually needs, so nothing here couples to a specific auth provider's
/// SDK type. Swapping Firebase for something else later only means
/// rewriting [AuthRepository]'s implementation, not every screen that
/// reads the current user.
class AuthUser {
  const AuthUser({required this.uid, required this.email});
  final String uid;
  final String? email;
}

/// A failure an end user should actually see, already translated into
/// plain Arabic — the one place provider-specific error codes get turned
/// into words a merchant understands, instead of every call site
/// re-guessing what e.g. Firebase's `wrong-password` should say.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// What the rest of the app needs from "who's logged in" — nothing here
/// mentions Firebase, so screens and controllers depend on this contract
/// instead of a concrete SDK.
abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<AuthUser> signUp({required String email, required String password});

  Future<AuthUser> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  /// Permanently deletes the signed-in user's login — required by App
  /// Store/Play Store review guidelines to offer real, in-app account
  /// deletion. Firebase requires a *recent* sign-in for this; if the
  /// session is stale it throws [AuthException] asking the user to log
  /// back in and retry, rather than silently failing.
  Future<void> deleteAccount();
}
