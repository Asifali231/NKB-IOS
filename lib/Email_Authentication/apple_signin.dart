import 'package:firebase_auth/firebase_auth.dart';

class AppleSignInResult {
  final User user;
  final String email;
  final String displayName;

  AppleSignInResult({
    required this.user,
    required this.email,
    required this.displayName,
  });
}

class AppleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AppleSignInResult> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      final userCredential = await _auth.signInWithProvider(appleProvider);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Sign in failed: User is null');
      }

      try {
        await user.reload();
      } catch (_) {
        // Continue with the cached user if a reload is not available yet.
      }

      final refreshedUser = _auth.currentUser ?? user;
      final profile =
          userCredential.additionalUserInfo?.profile as Map<Object?, Object?>?;

      String email = (refreshedUser.email ?? '').trim();
      if (email.isEmpty) {
        final profileEmail = profile?['email'];
        if (profileEmail is String) {
          email = profileEmail.trim();
        }
      }

      String displayName = (refreshedUser.displayName ?? '').trim();
      if (displayName.isEmpty) {
        final fullName = profile?['name'];
        if (fullName is String) {
          displayName = fullName.trim();
        }
      }
      if (displayName.isEmpty && email.isNotEmpty) {
        displayName = email.split('@').first;
      }
      if (displayName.isEmpty) {
        displayName = 'User';
      }

      if (email.isEmpty) {
        throw Exception(
          'Could not read email from Apple account. Please use the same Apple ID and try again.',
        );
      }

      return AppleSignInResult(
        user: refreshedUser,
        email: email,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('Account exists with different credential');
      }
      if (e.code == 'canceled' || e.code == 'web-context-cancelled') {
        throw Exception('Apple Sign-In cancelled by user');
      }
      throw Exception('Error: ${e.message ?? e.code}');
    } catch (e) {
      rethrow;
    }
  }
}
