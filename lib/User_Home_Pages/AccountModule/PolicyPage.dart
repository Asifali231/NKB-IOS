import 'package:flutter/material.dart';

class PolicyPage extends StatefulWidget {
  @override
  _PolicyPageState createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildContent(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFFDC2626),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Terms & Conditions',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Color(0xFFDC2626),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.description_outlined,
              color: Color(0xFFDC2626),
              size: 40,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Nikah Blessing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Legal Terms & Service Agreement',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'Effective Date: January 2025',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntroduction(),
          SizedBox(height: 32),
          _buildPolicySection(
            '1. Service Overview',
            [
              'Nikah Blessing operates as a matrimonial platform connecting individuals seeking marriage.',
              'We provide access to user profiles and facilitate initial contact between potential matches.',
              'Our services are limited to profile access and contact facilitation only.',
              'We do not provide matchmaking consultation, relationship counseling, or legal advice.',
              'Services may be modified or discontinued at our discretion with appropriate notice.',
            ],
            Icons.business_center_outlined,
          ),
          SizedBox(height: 24),
          _buildPolicySection(
            '2. User Responsibilities',
            [
              'Users must verify the authenticity and background of all potential matches independently.',
              'We do not conduct background checks or verify user-provided information.',
              'All interactions and meetings between users are conducted at their own risk.',
              'Users must provide accurate and truthful information during registration.',
              'False information may result in immediate account suspension or termination.',
              'Users are responsible for their personal safety during all interactions.',
            ],
            Icons.person_outline,
          ),
          SizedBox(height: 24),
          _buildPolicySection(
            '3. Liability Limitations',
            [
              'Nikah Blessing is not responsible for user misrepresentation or fraudulent activity.',
              'We are not liable for disputes, conflicts, or misunderstandings between users.',
              'No guarantee is provided for relationship success or marriage outcomes.',
              'We are not responsible for financial losses or emotional distress.',
              'Users should report fraudulent activity to appropriate law enforcement.',
              'Our liability is limited to the maximum extent permitted by law.',
            ],
            Icons.shield_outlined,
          ),
          SizedBox(height: 24),
          _buildPolicySection(
            '4. Payment & Refund Policy',
            [
              'All payments are processed securely through authorized payment gateways.',
              'Refund handling depends on the payment method and platform used for the purchase.',
              'If you later enable Apple in-app purchases, refund and subscription handling must follow Apple App Store rules.',
              'If you collect payment outside the app for eligible services, the payment terms must be clearly disclosed before purchase.',
              'Refunds, where applicable, should be returned to the original payment method.',
              'Pricing and payment terms should be clearly disclosed during the purchase process.',
              'By completing payment, users acknowledge acceptance of this policy.',
            ],
            Icons.payment_outlined,
          ),
          SizedBox(height: 24),
          _buildPolicySection(
            '5. Privacy & Data Protection',
            [
              'User privacy and data protection are governed by our Privacy Policy.',
              'Personal information is handled in accordance with applicable laws.',
              'We implement appropriate security measures to protect user data.',
              'Users control the visibility of their profile information.',
              'Data retention policies are outlined in our Privacy Policy.',
            ],
            Icons.privacy_tip_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildIntroduction() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFDC2626).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFFDC2626),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Important Notice',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Please read these terms and conditions carefully before using our services. By accessing or using Nikah Blessing, you agree to be bound by these terms. If you do not agree with any part of these terms, you should not use our services.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF4B5563),
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, List<String> points, IconData icon) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...points.asMap().entries.map((entry) {
            int index = entry.key;
            String point = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Terms Acceptance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'By using Nikah Blessing services, you acknowledge that you have read, understood, and agree to be bound by these terms and conditions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFDC2626)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Last Updated: January 2025',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
