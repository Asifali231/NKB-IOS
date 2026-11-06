import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nikah_blessing/User_Home_Pages/AccountModule/PolicyPage.dart';
import 'package:nikah_blessing/User_Home_Pages/AccountModule/PrivacyPolicyPage.dart';

const _termsUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
const _privacyUrl = 'https://nikahblessing.com/nkb-app/privacypolicy';

Future<void> _openLegalUrl(
    BuildContext context, String url, String name) async {
  try {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) throw StateError('The link could not be opened.');
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the $name: $error')),
      );
    }
  }
}

Future<bool> showTermsAcceptanceDialog(BuildContext context) async {
  var accepted = false;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            scrollable: true,
            title: const Text('Review our policies'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Before creating your account, please review and accept our Terms of Use and Privacy Policy.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: () {
                        if (Platform.isIOS) {
                          _openLegalUrl(context, _termsUrl, 'Terms of Use');
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PolicyPage()),
                          );
                        }
                      },
                      child: const Text('Terms of Use'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (Platform.isIOS) {
                          _openLegalUrl(context, _privacyUrl, 'Privacy Policy');
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyPage(),
                            ),
                          );
                        }
                      },
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: accepted,
                  title: const Text('I have read and accept these policies.'),
                  onChanged: (value) {
                    setDialogState(() => accepted = value ?? false);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: accepted
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: const Text('Accept and continue'),
              ),
            ],
          ),
        ),
      ) ??
      false;
}
