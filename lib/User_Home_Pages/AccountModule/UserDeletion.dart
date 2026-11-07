import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/theme/app_alert.dart';
import 'package:quickalert/models/quickalert_type.dart';

import '../../Email_Authentication/EmailAuth_Main.dart';

class UserDeletion {
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  Future<void> deleteUser(
      BuildContext context,
      String userId,
      String jobCountry,
      String gender,
      ) async

  {

    showAppAlert(
      context: context,
      type: QuickAlertType.loading,
      title: "Deleting Account",
      text: "Please wait...",
      barrierDismissible: false,
    );

    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      User? currentUser = auth.currentUser;

      // Check if current user matches the ID to delete
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception("Current user does not match the user to be deleted.");
      }

      final reauthentication =
          await _reauthenticateUser(context, auth, currentUser);
      if (_isIOS &&
          currentUser.providerData
              .any((provider) => provider.providerId == 'apple.com')) {
        await _revokeAppleToken(auth, reauthentication);
      }

      // Delete Firestore documents first
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(jobCountry)
          .collection(gender)
          .doc(userId)
          .delete();

      // Retry the delete after refreshing credentials if the session expired.
      try {
        await currentUser.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          final refreshedReauthentication =
              await _reauthenticateUser(context, auth, currentUser);
          if (_isIOS &&
              currentUser.providerData
                  .any((provider) => provider.providerId == 'apple.com')) {
            await _revokeAppleToken(auth, refreshedReauthentication);
          }
          await currentUser.delete();
        } else {
          rethrow;
        }
      }

      if (!context.mounted) return;
      Navigator.pop(context);
      _showSuccess(context);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (e.code == 'web-context-cancelled' || e.code == 'canceled') {
        return;
      }
      _showError(context, "Failed to delete account: ${e.message ?? e.code}");
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showError(context, "Failed to delete account: $e");
    }
  }

  Future<UserCredential?> _reauthenticateUser(
    BuildContext context,
    FirebaseAuth auth,
    User user,
  ) async {
    final providerIds = user.providerData.map((provider) => provider.providerId);

    if (providerIds.contains(EmailAuthProvider.PROVIDER_ID)) {
      final passwordController = TextEditingController();
      try {
        final password = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Confirm your password"),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: "Password"),
              onSubmitted: (value) =>
                  Navigator.of(dialogContext).pop(value),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(passwordController.text),
                child: const Text("Continue"),
              ),
            ],
          ),
        );

        if (password == null || password.isEmpty) {
          throw Exception("Reauthentication was cancelled.");
        }

        final email = user.email;
        if (email == null || email.isEmpty) {
          throw Exception("Your account email is unavailable.");
        }

        return await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
      } finally {
        passwordController.dispose();
      }
    }

    if (providerIds.contains("apple.com")) {
      return user.reauthenticateWithProvider(AppleAuthProvider());
    }

    if (providerIds.contains("google.com")) {
      return user.reauthenticateWithProvider(GoogleAuthProvider());
    }

    throw Exception(
      "Sign out and sign in again before deleting your account.",
    );
  }

  Future<void> _revokeAppleToken(
    FirebaseAuth auth,
    UserCredential? reauthentication,
  ) async {
    final authorizationCode =
        reauthentication?.additionalUserInfo?.authorizationCode;
    if (authorizationCode == null || authorizationCode.isEmpty) {
      throw StateError('Apple did not provide an authorization code to revoke.');
    }
    await auth.revokeTokenWithAuthorizationCode(authorizationCode);
  }

  void _showSuccess(BuildContext context) {
    showAppAlert(
      context: context,
      type: QuickAlertType.success,
      title: "Account Deleted",
      text: "Your account has been successfully deleted.",
      onConfirmBtnTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => EmailAuth_Main()),
              (Route<dynamic> route) => false,
        );
      },
    );
  }

  void _showError(BuildContext context, String message) {
    showAppAlert(
      context: context,
      type: QuickAlertType.error,
      title: "Error",
      text: message,
    );
  }
}
