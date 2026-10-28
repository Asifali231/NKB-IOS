import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';

import '../../Email_Authentication/EmailAuth_Main.dart';

class UserDeletion {
  Future<void> deleteUser(
      BuildContext context,
      String userId,
      String jobCountry,
      String gender,
      ) async

  {

    QuickAlert.show(
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

      await _reauthenticateUser(context, auth, currentUser);

      // Delete Firestore documents first
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      await FirebaseFirestore.instance
          .collection('proposals')
          .doc(jobCountry)
          .collection(gender)
          .doc(userId)
          .delete();

      // Try deleting Firebase Auth user
      try {
        await currentUser.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          if (context.mounted) Navigator.pop(context);

          // Sign out and navigate to login
          await auth.signOut();
          throw Exception(
            "Your session expired. Sign in again and retry account deletion.",
          );
        } else {
          throw Exception("Auth error: ${e.message}");
        }
      }

      if (!context.mounted) return;
      Navigator.pop(context);
      _showSuccess(context);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showError(context, "Failed to delete account: $e");
    }
  }

  Future<void> _reauthenticateUser(
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

        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
        return;
      } finally {
        passwordController.dispose();
      }
    }

    if (providerIds.contains("apple.com")) {
      await user.reauthenticateWithProvider(AppleAuthProvider());
      return;
    }

    if (providerIds.contains("google.com")) {
      await user.reauthenticateWithProvider(GoogleAuthProvider());
      return;
    }

    throw Exception(
      "Sign out and sign in again before deleting your account.",
    );
  }

  void _showSuccess(BuildContext context) {
    QuickAlert.show(
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
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: "Error",
      text: message,
    );
  }
}
