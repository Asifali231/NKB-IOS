// lib/config/safepay_config.dart

class SafePayConfig {
  final String publicKey;
  final String secretKey;
  final bool isSandbox;

  const SafePayConfig({
    required this.publicKey,
    required this.secretKey,
    this.isSandbox = true,
  });

  String get baseUrl => isSandbox
      ? 'https://sandbox.api.getsafepay.com'
      : 'https://api.getsafepay.com';
}