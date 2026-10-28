import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInResult {
  final User user;
  final String email;
  final String displayName;

  GoogleSignInResult({
    required this.user,
    required this.email,
    required this.displayName,
  });
}

class GoogleSignInService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In cancelled by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Sign in failed: User is null');
      }

      try {
        await user.reload();
      } catch (_) {}
      final refreshed = _auth.currentUser ?? user;

      String email = (refreshed.email ?? '').trim();
      if (email.isEmpty) email = googleUser.email.trim();

      String name = (refreshed.displayName ?? '').trim();
      if (name.isEmpty) name = (googleUser.displayName ?? '').trim();
      if (name.isEmpty && email.isNotEmpty) name = email.split('@').first;
      if (name.isEmpty) name = 'User';

      if (email.isEmpty) throw Exception('Could not read email from Google account');

      return GoogleSignInResult(user: refreshed, email: email, displayName: name);

    } on FirebaseAuthException catch (e) {
      throw Exception('Error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
