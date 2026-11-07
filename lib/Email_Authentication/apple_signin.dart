import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    if (appleCredential.identityToken == null) {
      throw StateError('Apple did not return an identity token.');
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );
    final userCredential = await _auth.signInWithCredential(oauthCredential);
    final user = userCredential.user;

    if (user == null) {
      throw StateError('Firebase did not return a signed-in Apple user.');
    }

    final providedName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');

    return AppleSignInResult(
      user: user,
      email: appleCredential.email?.trim().isNotEmpty == true
          ? appleCredential.email!.trim()
          : user.email?.trim() ?? '',
      displayName: providedName.isNotEmpty
          ? providedName
          : user.displayName?.trim() ?? '',
    );
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
