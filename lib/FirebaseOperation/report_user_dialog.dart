import 'package:flutter/material.dart';
import 'package:nikah_blessing/FirebaseOperation/FirebaseOperations.dart';

const _reportReasons = [
  'Inappropriate profile',
  'Fake or misleading information',
  'Harassment or abusive behavior',
  'Other',
];

Future<void> showReportUserDialog(
  BuildContext context, {
  required String reportedUserId,
}) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Report user'),
      children: _reportReasons
          .map(
            (reason) => SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, reason),
              child: Text(reason),
            ),
          )
          .toList(),
    ),
  );
  if (reason == null || !context.mounted) return;

  try {
    await FirebaseOperations().reportUser(reportedUserId, reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted for review.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit report: $error')),
      );
    }
  }
}
