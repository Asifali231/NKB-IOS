import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _sections = <Map<String, Object>>[
    {
      'title': '1. Introduction',
      'points': [
        'Nikah Blessing is a matrimonial platform for adults seeking marriage.',
        'By using the app, you agree to the collection and use of data described in this policy.',
      ],
    },
    {
      'title': '2. Information We Collect',
      'points': [
        'Account data such as name, email, phone number, date of birth, and gender.',
        'Profile data such as photos, education, profession, family details, sect, and partner preferences.',
        'Communication and safety data such as chats, reports, and moderation records.',
        'Device data such as push notification tokens and basic usage information needed to run the service.',
      ],
    },
    {
      'title': '3. How We Use Data',
      'points': [
        'To create and manage your account and profile.',
        'To match users, enable communication, and support paid package features.',
        'To improve app security, prevent fraud, and review verification submissions.',
        'To send account, safety, and transactional notifications.',
      ],
    },
    {
      'title': '4. Permissions',
      'points': [
        'Camera access is used for face verification, profile photos, and verification documents.',
        'Photo library access is used when you upload profile pictures or payment proof from your device.',
        'Microphone access may be requested by the face verification flow when required by the camera package.',
        'Notification permission is used for alerts about messages, matches, and account activity.',
      ],
    },
    {
      'title': '5. Sharing',
      'points': [
        'Profile information is shared with other users based on your app settings and matching flows.',
        'Service providers such as Firebase and payment-related systems process data needed to operate the app.',
        'We may disclose information when required by law or for user safety.',
      ],
    },
    {
      'title': '6. Retention and Deletion',
      'points': [
        'We retain data for as long as needed to provide the service and meet legal obligations.',
        'You can request account deletion from inside the app settings.',
        'Some records may be retained where required for legal, fraud, or payment compliance reasons.',
      ],
    },
    {
      'title': '7. Children',
      'points': [
        'Nikah Blessing is intended only for users aged 18 and above.',
        'Accounts identified as belonging to minors may be removed.',
      ],
    },
    {
      'title': '8. Contact',
      'points': [
        'Privacy contact: privacy@nikahblessing.com',
        'Support hours and business address should match the details you publish in App Store Connect and on your public privacy policy page.',
      ],
    },
  ];

  Widget _buildSection(BuildContext context, String title, List<String> points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 10),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        height: 1.5,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nikah Blessing',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'This in-app privacy summary should stay aligned with your hosted privacy policy and the App Privacy answers you submit in App Store Connect.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Last updated: May 17, 2026',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._sections.map(
            (section) => _buildSection(
              context,
              section['title']! as String,
              List<String>.from(section['points']! as List),
            ),
          ),
        ],
      ),
    );
  }
}
