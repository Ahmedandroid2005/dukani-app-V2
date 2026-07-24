import 'package:firebase_auth/firebase_auth.dart' as firebase;

import 'auth_repository.dart';

/// The only file in the app that imports `firebase_auth` directly —
/// every other file talks to [AuthRepository] instead, so this stays the
/// single place a Firebase-specific error code or API gets translated.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final firebase.FirebaseAuth _auth;

  AuthUser? _toAuthUser(firebase.User? user) => user == null ? null : AuthUser(uid: user.uid, email: user.email);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_toAuthUser);

  @override
  AuthUser? get currentUser => _toAuthUser(_auth.currentUser);

  @override
  Future<AuthUser> signUp({required String email, required String password}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return _toAuthUser(credential.user)!;
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return _toAuthUser(credential.user)!;
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthException('لأمان حسابك، لازم تسجّل الخروج وتدخل تاني قبل حذف الحساب مباشرة.');
      }
      throw AuthException(_messageFor(e.code));
    }
  }

  /// Firebase's error codes are stable API, not user-facing copy — this
  /// is the one translation table for them instead of every screen
  /// re-guessing what `wrong-password` should say in Arabic.
  String _messageFor(String code) => switch (code) {
        'email-already-in-use' => 'البريد الإلكتروني ده مستخدم بالفعل — جرّب تسجّل الدخول بدل كده',
        'invalid-email' => 'صيغة البريد الإلكتروني غير صحيحة',
        'weak-password' => 'كلمة المرور ضعيفة — لازم تكون 6 أحرف على الأقل',
        'user-not-found' => 'مفيش حساب مسجّل بهذا البريد الإلكتروني',
        'wrong-password' => 'كلمة المرور غير صحيحة',
        'invalid-credential' => 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
        'user-disabled' => 'الحساب ده متوقف مؤقتًا — تواصل مع الدعم الفني',
        'too-many-requests' => 'محاولات كتيرة جدًا في وقت قصير — جرّب تاني بعد شوية',
        'network-request-failed' => 'مفيش اتصال بالإنترنت — تأكد من الشبكة وحاول تاني',
        _ => 'حصل خطأ غير متوقع، حاول تاني',
      };
}
