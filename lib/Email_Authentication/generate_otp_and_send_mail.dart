import 'dart:core';
import 'dart:math';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GenerateOtpAndSendMail {
  static const Duration _otpValidity = Duration(minutes: 10);
  String _otp = '';
  DateTime? _otpExpiresAt;

  String generateOtp() {
    final random = Random.secure();
    int otp = random.nextInt(900000) + 100000; // Ensures a 6-digit OTP
    _otp = otp.toString();
    _otpExpiresAt = DateTime.now().add(_otpValidity);
    return _otp;
  }

  bool verifyOtp(String candidate) {
    final expiresAt = _otpExpiresAt;
    if (_otp.isEmpty ||
        expiresAt == null ||
        DateTime.now().isAfter(expiresAt)) {
      _otp = '';
      _otpExpiresAt = null;
      return false;
    }

    if (candidate.trim() != _otp) {
      return false;
    }

    _otp = '';
    _otpExpiresAt = null;
    return true;
  }

  String getHtmlTemplate(String name) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Nikah Blessing OTP Verification</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f4f4f4;
                color: #333;
                margin: 0;
                padding: 0;
            }
            .container {
                width: 100%;
                padding: 20px;
                background-color: #ffffff;
                border-radius: 10px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                max-width: 600px;
                margin: 40px auto;
            }
            .header {
                background-color: #8e44ad;
                padding: 20px;
                border-radius: 10px 10px 0 0;
                text-align: center;
                color: #ffffff;
            }
            .header h1 {
                margin: 0;
                font-size: 24px;
            }
            .content {
                padding: 20px;
                text-align: center;
            }
            .copy-btn {
                padding: 10px 20px;
                font-size: 16px;
                color: #ffffff;
                background-color: #8e44ad;
                border: none;
                border-radius: 5px;
                cursor: pointer;
            }
            .copy-btn:hover {
                background-color: #732d91;
            }
            .otp {
                font-size: 36px;
                font-weight: bold;
                color: #8e44ad;
                margin: 20px 0;
            }
            .footer {
                text-align: center;
                padding: 20px;
                background-color: #f8f8f8;
                border-radius: 0 0 10px 10px;
                font-size: 14px;
                color: #999;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Nikah Blessing</h1>
            </div>
            <div class="content">
                <p>Dear $name,</p>
                <p>Thank you for choosing Nikah Blessing. Your OTP for verification is:</p>
                <div class="otp">$_otp</div>
                <p>Please use this OTP to complete your verification process. This OTP is valid for 10 minutes.</p>
            </div>
            <div class="footer">
                <p>© 2024 Nikah Blessing. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  Future<String?> getPasswordFromFirestore() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('email_credential')
          .doc('credential') // Replace with your document ID
          .get();

      if (doc.exists) {
        return doc.get('password') as String?;
      } else {
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      print('Error retrieving password: $e');
      return null;
    }
  }

  Future<String> sendMail(String recipientEmail) async {
    String? password = await getPasswordFromFirestore();
    if (password == null) {
      return 'Failed to retrieve password from Firestore';
    }

    generateOtp();

    final smtpServer = SmtpServer(
      'smtp.titan.email',
      port: 465,
      ssl: true,
      username: 'contact@nikahblessing.com', // Hardcoded for now
      password: password,
    );

    final message = Message()
      ..from = Address('contact@nikahblessing.com', 'Nikah Blessing')
      ..recipients.add(recipientEmail)
      ..subject = 'Your OTP Verification Code'
      ..headers = {
        'Message-ID':
            '<${DateTime.now().millisecondsSinceEpoch}.${recipientEmail.split('@')[0]}@nikahblessing.com>'
      }
      ..html = getHtmlTemplate('User');

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
      return "true";
    } on MailerException catch (e) {
      print('Message not sent. ${e.toString()}');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return 'Message not sent. ${e.toString()}';
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }
}
