import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

class UserDataEncryptor {


  final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1'); // 32 chars
  final _iv = encrypt.IV.fromLength(16);

  final encrypt.Encrypter _encrypter;

  UserDataEncryptor() : _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1')));

  // Encrypt method
  Map<String, dynamic> encryptUserData(Map<String, dynamic> userData) {
    Map<String, dynamic> encryptedData = {};

    userData.forEach((key, value) {
      // Only encrypt non-null values
      if (value != null) {
        encryptedData[key] = _encrypter.encrypt(jsonEncode(value), iv: _iv).base64;
      }


    });

    return encryptedData;
  }

  // Decrypt method
  Map<String, dynamic> decryptUserData(Map<String, dynamic> encryptedData) {
    Map<String, dynamic> decryptedData = {};

    encryptedData.forEach((key, value) {
      if (value != null) {
        decryptedData[key] = jsonDecode(_encrypter.decrypt64(value, iv: _iv));
      }
    });

    return decryptedData;
  }
}
