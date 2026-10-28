import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/Email_Authentication/EmailAuth_Main.dart';
import 'package:nikah_blessing/FirebaseOperation/payment_visibility_service.dart';
import 'package:nikah_blessing/Packages_Module/allPackagesModule.dart';
import 'package:nikah_blessing/UpdateProfile/UpdateFilters.dart';
import 'package:nikah_blessing/User_Home_Pages/AccountModule/PrivacyPolicyPage.dart';
import 'package:nikah_blessing/User_Home_Pages/AccountModule/PolicyPage.dart';
import 'package:quickalert/quickalert.dart';

import 'UserDeletion.dart';
import 'editProfile_Page.dart';

class Account_Setting extends StatefulWidget {
  const Account_Setting({Key? key}) : super(key: key);

  @override
  State<Account_Setting> createState() => _Account_SettingState();
}

class _Account_SettingState extends State<Account_Setting> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EmailAuth_Main()),
      );
      return;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;
      setState(() {
        userData = docSnapshot.data();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load account details right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _verificationStatusValue() {
    return (userData?['VerificationStatus'] ?? 'UnVerified').toString();
  }

  String _verificationStatusLabel() {
    switch (_verificationStatusValue().toLowerCase()) {
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending Review';
      case 'unverified':
      default:
        return 'Pending Review';
    }
  }

  String _verificationDescription() {
    switch (_verificationStatusValue().toLowerCase()) {
      case 'verified':
        return 'Your profile is active and fully approved for requests.';
      case 'rejected':
        return 'Your profile is rejected. Please update your account details and submit again.';
      case 'pending':
      case 'unverified':
      default:
        return 'Your profile is under review. You can update your details while verification is pending.';
    }
  }

  Color _verificationColor() {
    switch (_verificationStatusValue().toLowerCase()) {
      case 'verified':
        return const Color(0xFF1B8F5A);
      case 'rejected':
        return const Color(0xFFD64545);
      case 'pending':
      case 'unverified':
      default:
        return const Color(0xFFE4A11B);
    }
  }

  IconData _verificationIcon() {
    switch (_verificationStatusValue().toLowerCase()) {
      case 'verified':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
      case 'unverified':
      default:
        return Icons.pending_actions_rounded;
    }
  }

  String _packageName() {
    return (userData?['PackageSubscribed'] ?? 'Free').toString();
  }

  String _subscriptionPackageLabel(bool premiumUnlocked) {
    if (premiumUnlocked) {
      return 'Unlocked';
    }

    return _packageName();
  }

  String _dailyProfilesLabel(bool premiumUnlocked) {
    if (premiumUnlocked) {
      return 'Unlocked while payments are disabled';
    }

    return '${(userData?['DailyProfiles'] ?? 0).toString()} profiles';
  }

  String _chatCreditsLabel(bool premiumUnlocked) {
    if (premiumUnlocked) {
      return 'Unlocked while payments are disabled';
    }

    return (userData?['ChatCredit'] ?? 0).toString();
  }

  String _phoneDisplay() {
    final rawValue = userData?['PhoneNumber'];
    if (rawValue == null || rawValue.toString().trim().isEmpty) {
      return 'Not available';
    }
    final phone = rawValue.toString().trim();
    return phone.startsWith('0') ? phone : '0$phone';
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilePage()),
    );

    if (!mounted) return;
    if (updated == true) {
      await getUserData();
    }
  }

  Future<void> _confirmLogout() async {
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmLogout != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Logged Out',
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => EmailAuth_Main()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _confirmDelete() async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete != true || userData == null) return;
    if (!mounted) return;

    final userDeletion = UserDeletion();
    await userDeletion.deleteUser(
      context,
      FirebaseAuth.instance.currentUser!.uid,
      userData!['JobCountry'],
      userData!['Gender'],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF7B3FE4).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF7B3FE4), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDestructive ? color : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD8DDE8), Color(0xFFB5C0D0)],
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 64,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrls = (userData?['ProfileImageUrls'] as List?) ?? const [];
    final avatarUrl =
        avatarUrls.isNotEmpty ? avatarUrls.first.toString() : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/QAbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: getUserData,
                child: ListView(
                  padding: const EdgeInsets.only(top: 14, bottom: 30),
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF5724C5).withOpacity(0.95),
                            const Color(0xFF9B51E0).withOpacity(0.92),
                            const Color(0xFFE66BA6).withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 126,
                            height: 126,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(63),
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildFallbackAvatar(),
                                    )
                                  : _buildFallbackAvatar(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Hi there!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (userData?['name'] ?? 'Guest').toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your profile, verification, and package in one place.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildSection(
                      title: 'Verification Status',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _verificationColor().withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _verificationColor().withOpacity(0.24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color:
                                        _verificationColor().withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _verificationIcon(),
                                    color: _verificationColor(),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _verificationStatusLabel(),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: _verificationColor(),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _verificationDescription(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.4,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _openEditProfile,
                                icon: const Icon(Icons.edit_outlined),
                                label: Text(
                                  _verificationStatusValue().toLowerCase() ==
                                          'rejected'
                                      ? 'Update Account Details'
                                      : 'Edit Profile',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _verificationColor(),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Personal Information',
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: 'Name',
                            value: (userData?['name'] ?? 'Not available')
                                .toString(),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: _phoneDisplay(),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: (userData?['email'] ?? 'Not available')
                                .toString(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Subscription Details',
                      child: StreamBuilder<bool>(
                        stream:
                            PaymentVisibilityService.premiumFeaturesUnlockedStream(),
                        builder: (context, snapshot) {
                          final premiumUnlocked = snapshot.data ?? false;

                          return Column(
                            children: [
                              _buildSubscriptionItem(
                                icon: Icons.workspace_premium_rounded,
                                title: 'Package Subscribed',
                                value:
                                    _subscriptionPackageLabel(premiumUnlocked),
                                color: const Color(0xFFF4A62A),
                              ),
                              const SizedBox(height: 16),
                              _buildSubscriptionItem(
                                icon: Icons.people_outline_rounded,
                                title: 'Daily Profiles',
                                value:
                                    _dailyProfilesLabel(premiumUnlocked),
                                color: const Color(0xFF2D8CFF),
                              ),
                              const SizedBox(height: 16),
                              _buildSubscriptionItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                title: 'Chat Credits',
                                value: _chatCreditsLabel(premiumUnlocked),
                                color: const Color(0xFF1B8F5A),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Actions',
                      child: Column(
                        children: [
                          _buildActionItem(
                            icon: Icons.edit_note_rounded,
                            title: 'Edit Profile',
                            subtitle:
                                'Update your profile details and verification information',
                            onTap: _openEditProfile,
                            color: const Color(0xFF5B3FD0),
                          ),
                          _buildActionItem(
                            icon: Icons.tune_rounded,
                            title: 'Change Preferences',
                            subtitle: 'Update your matching preferences',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpdateFilters(),
                                ),
                              );
                            },
                            color: const Color(0xFF6D4CFF),
                          ),
                          StreamBuilder<bool>(
                            stream:
                                PaymentVisibilityService.paymentsHiddenStream(),
                            builder: (context, snapshot) {
                              final isHidden = snapshot.data ?? true;
                              if (isHidden) {
                                return const SizedBox.shrink();
                              }

                              return _buildActionItem(
                                icon: Icons.star_rounded,
                                title: 'Upgrade Package',
                                subtitle:
                                    'Unlock messaging and more daily profile access',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PackagesPage(),
                                    ),
                                  );
                                },
                                color: const Color(0xFFF2A531),
                              );
                            },
                          ),
                          _buildActionItem(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle:
                                'Review how your data and permissions are used',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyPage(),
                                ),
                              );
                            },
                            color: const Color(0xFF0F8B8D),
                          ),
                          _buildActionItem(
                            icon: CupertinoIcons.doc_text,
                            title: 'Terms & Conditions',
                            subtitle:
                                'Review the Nikah Blessing terms of service',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PolicyPage(),
                                ),
                              );
                            },
                            color: const Color(0xFF1E9E62),
                          ),
                          _buildActionItem(
                            icon: Icons.logout_rounded,
                            title: 'Log Out',
                            subtitle: 'Sign out of your account',
                            onTap: _confirmLogout,
                            color: const Color(0xFFDE5A5A),
                          ),
                          _buildActionItem(
                            icon: Icons.delete_forever_rounded,
                            title: 'Delete Account',
                            subtitle: 'Remove your account permanently',
                            onTap: _confirmDelete,
                            color: const Color(0xFFC62828),
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
