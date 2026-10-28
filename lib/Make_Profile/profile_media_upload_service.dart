import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';

class ProfileMediaUploadService {
  ProfileMediaUploadService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String resolveUserId() {
    final authUserId = _auth.currentUser?.uid ?? '';
    if (authUserId.isNotEmpty) {
      UserData.userID = authUserId;
      return authUserId;
    }

    final userDataId = UserData.userID.trim();
    if (userDataId.isNotEmpty) {
      return userDataId;
    }

    throw Exception('Unable to resolve user id for media upload');
  }

  static Future<String> uploadImageFile({
    required File file,
    required String folderName,
    String? slotId,
  }) async {
    final userId = resolveUserId();
    final extension =
        file.path.contains('.') ? file.path.split('.').last : 'jpg';
    final fileName =
        '${slotId ?? DateTime.now().microsecondsSinceEpoch}.$extension';

    final reference = _storage.ref().child('$userId/$folderName/$fileName');
    await reference.putFile(file);
    return reference.getDownloadURL();
  }

  static Future<void> deleteUploadedFile(String url) async {
    if (url.trim().isEmpty) return;

    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Ignore cleanup failures to avoid blocking user flow.
    }
  }
}
