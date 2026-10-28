import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nikah_blessing/Admin_Module/AdminPackagesMangment.dart';
import 'package:nikah_blessing/Admin_Module/InAppPromotion.dart';
import 'package:nikah_blessing/Admin_Module/PackageManagment.dart';
import 'package:nikah_blessing/Admin_Module/sendNotification_Admin.dart';
import 'package:nikah_blessing/Admin_Module/transactionRecords.dart';
import 'package:nikah_blessing/Payement_Module/TransactionData.dart';
import 'package:nikah_blessing/User_Home_Pages/AccountModule/editProfile_Page.dart';

import '../Payement_Module/manualPayement_Page.dart';
import 'AdminPaymentVerificationPage.dart';
import 'ProfileVerfication_Module/ProfileVerfication.dart';
import 'UserManagementPage.dart';

class Admin_HomePage extends StatefulWidget {
  Admin_HomePage({Key? key}) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<Admin_HomePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<AdminCard> cards = [
    AdminCard(
      title: 'Users Management',
      subtitle: 'Manage user accounts and permissions',
      icon: Icons.people_rounded,
      primaryColor: Color(0xFF6C5CE7),
      secondaryColor: Color(0xFF74B9FF),
      status: 'Active',
      statusColor: Colors.green,
    ),
    AdminCard(
      title: 'Manual Payments',
      subtitle: 'Verify pending payment requests',
      icon: Icons.payment_rounded,
      primaryColor: Color(0xFF00CEC9),
      secondaryColor: Color(0xFF55A3FF),
      status: 'Pending',
      statusColor: Colors.orange,
    ),
    AdminCard(
      title: 'Package Management',
      subtitle: 'Edit and update service packages',
      icon: Icons.inventory_2_rounded,
      primaryColor: Color(0xFFE17055),
      secondaryColor: Color(0xFFFF7675),
      status: 'Updated',
      statusColor: Colors.blue,
    ),
    AdminCard(
      title: 'Profile Verification',
      subtitle: 'Review and verify user profiles',
      icon: Icons.verified_user_rounded,
      primaryColor: Color(0xFF00B894),
      secondaryColor: Color(0xFF55EFC4),
      status: 'Review',
      statusColor: Colors.amber,
    ),
    AdminCard(
      title: 'Transactions',
      subtitle: 'Monitor all financial transactions',
      icon: CupertinoIcons.money_dollar_circle_fill,
      primaryColor: Color(0xFF2D3436),
      secondaryColor: Color(0xFF636E72),
      status: 'Live',
      statusColor: Colors.green,
    ),
    AdminCard(
      title: 'App Promotion',
      subtitle: 'Add images to promote application',
      icon: CupertinoIcons.sparkles,
      primaryColor: Color(0xFFE84393),
      secondaryColor: Color(0xFFFF6B95),
      status: 'Campaign',
      statusColor: Colors.purple,
    ),

    AdminCard(
      title: 'Send Notification',
      subtitle: 'Send notification to users',
      icon: Icons.notifications_active_outlined,
      primaryColor: Color(0xFF00B894),
      secondaryColor: Color(0xFF55EFC4),
      status: 'notification',
      statusColor: Colors.amber,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: _buildModernAppBar(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(),
                // SizedBox(height: 32),
                // _buildQuickStats(),
                SizedBox(height: 32),
                _buildSectionHeader(),
                SizedBox(height: 20),
                _buildModernGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            'Admin Portal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
      ),
      elevation: 0,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_outlined, color: Colors.white),
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              Fluttertoast.showToast(msg: "Notifications");
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Admin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your platform efficiently',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF636E72),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard("Total Users", "2,453", Icons.people_rounded, Color(0xFF00B894)),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard("Pending", "18", Icons.pending_actions, Color(0xFFE17055)),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard("Revenue", "\$12.5K", Icons.trending_up, Color(0xFF6C5CE7)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF636E72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Management Tools',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF6C5CE7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '7 Tools',
            style: TextStyle(
              color: Color(0xFF6C5CE7),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 800 + (index * 100)),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: _buildModernCard(cards[index], context),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModernCard(AdminCard card, BuildContext context) {
    return Container(

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: card.primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              _handleCardTap(card, context);
            },
            splashColor: card.primaryColor.withOpacity(0.1),
            highlightColor: card.primaryColor.withOpacity(0.05),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [card.primaryColor, card.secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: card.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          card.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: card.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: card.statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              card.status,
                              style: TextStyle(
                                color: card.statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    card.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    card.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF636E72),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Manage',
                        style: TextStyle(
                          color: card.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: card.primaryColor,
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleCardTap(AdminCard card, BuildContext context) {
    switch (card.title) {
      case 'Users Management':
        Fluttertoast.showToast(msg: "Navigating to Users Management");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserManagementPage()),
        );
        break;
      case 'Manual Payments':
        Fluttertoast.showToast(msg: "Navigating to Manual Payments");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminPaymentVerificationPage()),
        );
        break;
      case 'Package Management':
        Fluttertoast.showToast(msg: "Navigating to Package Management");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminPackagesManagement()),
        );
        break;
      case 'Profile Verification':
        Fluttertoast.showToast(msg: "Navigating to Profile Verification");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileVerificationList()),
        );
        break;
      case 'Transactions':
        Fluttertoast.showToast(msg: "Navigating to Transactions");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TransactionsRecord()),
        );
        break;
      case 'App Promotion':
        Fluttertoast.showToast(msg: "Navigating to App Promotion");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => InAppPromotion()),
        );
        break;

      case 'Send Notification':
        Fluttertoast.showToast(msg: "Navigating to App Promotion");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminNotificationPage()),
        );
        break;
      default:
        Fluttertoast.showToast(msg: "No action assigned to this card");
        break;
    }
  }
}

class AdminCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final String status;
  final Color statusColor;

  AdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.status,
    required this.statusColor,
  });
}