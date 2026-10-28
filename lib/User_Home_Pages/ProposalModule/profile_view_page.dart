import 'dart:ui';
import 'package:blur/blur.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nikah_blessing/Email_Authentication/EmailAuth_Main.dart';
import 'package:nikah_blessing/FirebaseOperation/FirebaseOperations.dart';
import 'package:nikah_blessing/FirebaseOperation/payment_visibility_service.dart';
import 'package:nikah_blessing/Packages_Module/allPackagesModule.dart';
import 'package:nikah_blessing/User_Home_Pages/user_main.dart';
import 'package:quickalert/quickalert.dart';
import 'package:vibration/vibration.dart';
import '../../Chat_Module/Chat_Screen.dart';

class profile_view_page extends StatefulWidget {
  final Map<String, dynamic> proposalData;

  const profile_view_page({super.key, required this.proposalData});

  @override
  State<profile_view_page> createState() => _profile_view_pageState();
}

class _profile_view_pageState extends State<profile_view_page>
    with TickerProviderStateMixin {
  var userData;
  bool isVerified = false;
  late AnimationController _heartController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _heartAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  final PageController _pageController = PageController();
  List<dynamic> imageUrls = [];

  Map<String, String> countriesCurrencies = {
    'Afghanistan': 'afn',
    'Albania': 'all',
    'Algeria': 'dzd',
    'Andorra': 'eur',
    'Angola': 'aoa',
    'Antigua and Barbuda': 'xcd',
    'Argentina': 'ars',
    'Armenia': 'amd',
    'Australia': 'aud',
    'Austria': 'eur',
    'Azerbaijan': 'azn',
    'Bahamas': 'bsd',
    'Bahrain': 'bhd',
    'Bangladesh': 'bdt',
    'Barbados': 'bbd',
    'Belarus': 'byn',
    'Belgium': 'eur',
    'Belize': 'bzd',
    'Benin': 'xof',
    'Bhutan': 'inr',
    'Bolivia': 'bob',
    'Bosnia and Herzegovina': 'bam',
    'Botswana': 'bwp',
    'Brazil': 'brl',
    'Brunei': 'bnd',
    'Bulgaria': 'bgn',
    'Burkina Faso': 'xof',
    'Burundi': 'bif',
    'Cabo Verde': 'cve',
    'Cambodia': 'KHR',
    'Cameroon': 'xaf',
    'Canada': 'cad',
    'Central African Republic': 'xaf',
    'Chad': 'xaf',
    'Chile': 'clp',
    'China': 'cny',
    'Colombia': 'cop',
    'Comoros': 'kmf',
    'Congo, Democratic Republic of the': 'cdf',
    'Congo, Republic of the': 'xaf',
    'Costa Rica': 'crc',
    'Croatia': 'hrk',
    'Cuba': 'cup',
    'Cyprus': 'eur',
    'Czech Republic': 'czk',
    'Denmark': 'dkk',
    'Djibouti': 'djf',
    'Dominica': 'xcd',
    'Dominican Republic': 'dop',
    'Ecuador': 'usd',
    'Egypt': 'egp',
    'El Salvador': 'usd',
    'Equatorial Guinea': 'xaf',
    'Eritrea': 'ern',
    'Estonia': 'eur',
    'Eswatini': 'szl',
    'Ethiopia': 'etb',
    'Fiji': 'fjd',
    'Finland': 'eur',
    'France': 'eur',
    'Gabon': 'xaf',
    'Gambia': 'gmd',
    'Georgia': 'gel',
    'Germany': 'eur',
    'Ghana': 'ghs',
    'Greece': 'eur',
    'Grenada': 'xcd',
    'Guatemala': 'gtq',
    'Guinea': 'gnf',
    'Guinea-Bissau': 'xof',
    'Guyana': 'gyd',
    'Haiti': 'htg',
    'Honduras': 'hnl',
    'Hungary': 'huf',
    'Iceland': 'isk',
    'India': 'inr',
    'Indonesia': 'idr',
    'Iran': 'irr',
    'Iraq': 'iqd',
    'Ireland': 'eur',
    'Israel': 'ils',
    'Italy': 'eur',
    'Jamaica': 'jmd',
    'Japan': 'jpy',
    'Jordan': 'jod',
    'Kazakhstan': 'kzt',
    'Kenya': 'kes',
    'Kiribati': 'aud',
    'Korea, North': 'kpw',
    'Korea, South': 'krw',
    'Kuwait': 'kwd',
    'Kyrgyzstan': 'kgs',
    'Laos': 'lak',
    'Latvia': 'eur',
    'Lebanon': 'lbp',
    'Lesotho': 'lsl',
    'Liberia': 'lrd',
    'Libya': 'lyd',
    'Liechtenstein': 'chf',
    'Lithuania': 'eur',
    'Luxembourg': 'eur',
    'Madagascar': 'mga',
    'Malawi': 'mwk',
    'Malaysia': 'myr',
    'Maldives': 'mvr',
    'Mali': 'xof',
    'Malta': 'eur',
    'Marshall Islands': 'usd',
    'Mauritania': 'mru',
    'Mauritius': 'mur',
    'Mexico': 'mxn',
    'Micronesia': 'usd',
    'Moldova': 'mdl',
    'Monaco': 'eur',
    'Mongolia': 'mnt',
    'Montenegro': 'eur',
    'Morocco': 'mad',
    'Mozambique': 'mzn',
    'Myanmar': 'mmk',
    'Namibia': 'nad',
    'Nauru': 'aud',
    'Nepal': 'npr',
    'Netherlands': 'eur',
    'New Zealand': 'nzd',
    'Nicaragua': 'nio',
    'Niger': 'xof',
    'Nigeria': 'ngn',
    'North Macedonia': 'mkd',
    'Norway': 'nok',
    'Oman': 'omr',
    'Pakistan': 'pkr',
    'Palau': 'usd',
    'Panama': 'pab',
    'Papua New Guinea': 'pgk',
    'Paraguay': 'pyg',
    'Peru': 'pen',
    'Philippines': 'php',
    'Poland': 'pln',
    'Portugal': 'eur',
    'Qatar': 'qar',
    'Romania': 'ron',
    'Russia': 'rub',
    'Rwanda': 'rwf',
    'Saint Kitts and Nevis': 'xcd',
    'Saint Lucia': 'xcd',
    'Saint Vincent and the Grenadines': 'xcd',
    'Samoa': 'wst',
    'San Marino': 'eur',
    'Sao Tome and Principe': 'stn',
    'Saudi Arabia': 'sar',
    'Senegal': 'xof',
    'Serbia': 'rsd',
    'Seychelles': 'scr',
    'Sierra Leone': 'sll',
    'Singapore': 'sgd',
    'Slovakia': 'eur',
    'Slovenia': 'eur',
    'Solomon Islands': 'sbd',
    'Somalia': 'sos',
    'South Africa': 'zar',
    'South Sudan': 'ssp',
    'Spain': 'eur',
    'Sri Lanka': 'lkr',
    'Sudan': 'sdg',
    'Suriname': 'srd',
    'Sweden': 'sek',
    'Switzerland': 'chf',
    'Syria': 'syp',
    'Taiwan': 'twd',
    'Tajikistan': 'tjs',
    'Tanzania': 'tzs',
    'Thailand': 'thb',
    'Timor-Leste': 'usd',
    'Togo': 'xof',
    'Tonga': 'top',
    'Trinidad and Tobago': 'ttd',
    'Tunisia': 'tnd',
    'Turkey': 'try',
    'Turkmenistan': 'tmt',
    'Tuvalu': 'aud',
    'Uganda': 'ugx',
    'Ukraine': 'uah',
    'United Arab Emirates': 'aed',
    'United Kingdom': 'gbp',
    'United States': 'usd',
    'Uruguay': 'uyu',
    'Uzbekistan': 'uzs',
    'Vanuatu': 'vuv',
    'Vatican City': 'eur',
    'Venezuela': 'ves',
    'Vietnam': 'vnd',
    'Yemen': 'yer',
    'Zambia': 'zmw',
    'Zimbabwe': 'zwl',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    getUserData();
    _loadImages();
  }

  void _initializeAnimations() {
    _heartController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _heartAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _heartController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _heartController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildHeartLoading() {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_heartAnimation, _pulseAnimation, _fadeAnimation]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _heartAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.pink.withOpacity(0.8),
                            Colors.red.withOpacity(0.6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink
                                .withOpacity(_pulseAnimation.value * 0.5),
                            blurRadius: _pulseAnimation.value * 20,
                            spreadRadius: _pulseAnimation.value * 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Loading Profile...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: 100,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [Colors.pink, Colors.red],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  getUserData() async {
    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    if (user == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: "Network Error",
        text: "Unable to load user data try again later",
        onConfirmBtnTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => EmailAuth_Main()));
        },
        barrierDismissible: false,
      );
      return;
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference docRef = db.collection('users').doc(user.uid);
    DocumentSnapshot docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      setState(() {
        userData = docSnapshot.data() as Map<String, dynamic>?;
        isVerified = userData?["VerificationStatus"] == "Verified";
      });
    } else {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: "Network Error",
        text: "Unable to load user data try again later",
        onConfirmBtnTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => EmailAuth_Main()));
        },
        barrierDismissible: false,
      );
    }
  }

  CreateChatRoom(String seller_id, String userId, String SellerName,
      String BuyerName, String SellerImg, String BuyerImg) {
    List<String> users = [seller_id, userId];
    Map<String, String> usersName = {seller_id: SellerName, userId: BuyerName};
    Map<String, String> usersImg = {seller_id: SellerImg, userId: BuyerImg};
    Map<String, int> UnreadMsg = {seller_id: 0, userId: 0};
    String chatRomID = seller_id + "" + userId;

    Map<String, dynamic> chatData = {
      'users': users,
      'UnreadMsg': UnreadMsg,
      'usersName': usersName,
      'usersImg': usersImg,
      'chatRoomID': chatRomID,
      'lastChat': null,
      'lastChatTime': DateTime.now().microsecondsSinceEpoch,
    };

    final db = FirebaseFirestore.instance;
    db.collection("Chats").doc(chatRomID).set(chatData).then((_) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Chat_Screen(chatRoomId: chatRomID)));
    }).catchError((e) {
      print("Error While Opening Chats: $e");
    });
  }

  Future<void> _loadImages() async {
    setState(() {
      imageUrls = widget.proposalData["ProfileImageUrls"] ?? [];
    });
  }

  bool _isFriend() {
    return widget.proposalData["friends"]?.contains(userData?["uid"]) ?? false;
  }

  bool _isProfileImgBlur() {
    if (widget.proposalData["ProfileImageShare"] == "1") {
      return !_isFriend();
    } else if (widget.proposalData["ProfileImageShare"] == "2") {
      return true;
    } else {
      return false;
    }
  }

  String _currentPackageName() {
    return (userData?["PackageSubscribed"] ?? "Free")
        .toString()
        .trim()
        .toLowerCase();
  }

  String _partnerCountryDisplay() {
    final countries = widget.proposalData["PartnerCountry "];
    if (countries is List) {
      final values = countries
          .where((country) =>
              country != null && country.toString().trim().isNotEmpty)
          .map((country) => country.toString())
          .toList();
      return values.isEmpty ? 'Not specified' : values.join(', ');
    }

    if (countries is String && countries.trim().isNotEmpty) {
      return countries;
    }

    return 'Not specified';
  }

  bool _isPaidPlan() {
    final packageName = _currentPackageName();
    return packageName.isNotEmpty &&
        packageName != "free" &&
        packageName != "disablepackage";
  }

  Future<bool> _hasUnlockedPremiumAccess() async {
    if (_isPaidPlan()) {
      return true;
    }

    return PaymentVisibilityService.arePremiumFeaturesUnlocked();
  }

  String _proposalImageAt(int index) {
    final images =
        (widget.proposalData["ProfileImageUrls"] as List?) ?? const [];
    if (images.isEmpty) {
      return "";
    }
    if (index < images.length && images[index] != null) {
      return images[index].toString();
    }
    return images.first.toString();
  }

  String _userImageAt(int index) {
    final images = (userData?["ProfileImageUrls"] as List?) ?? const [];
    if (images.isEmpty) {
      return "";
    }
    if (index < images.length && images[index] != null) {
      return images[index].toString();
    }
    return images.first.toString();
  }

  void _showInlineMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildUpgradePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF6F9C)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeFeature({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF93B8), Color(0xFFFF5E8D)],
              ),
            ),
            child: Icon(icon, color: const Color(0xFF411024), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showMessagingUpgradeDialog() async {
    if (!mounted) return false;
    final isHidden = await PaymentVisibilityService.arePaymentsHidden();
    if (!mounted) return false;

    if (isHidden) {
      _showInlineMessage('Package upgrades are currently hidden.');
      return false;
    }

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Messaging upgrade',
      barrierColor: Colors.black.withOpacity(0.72),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF311423),
                              Color(0xFF25152A),
                              Color(0xFF17131F),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 36,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -30,
                              right: -10,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFFFF6F9C).withOpacity(0.18),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -40,
                              left: -20,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFFFF4F79).withOpacity(0.14),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 24, 24, 22),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFF98BD),
                                              Color(0xFFFF5B89),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF5B89)
                                                  .withOpacity(0.30),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.chat_bubble_rounded,
                                          color: Color(0xFF451126),
                                          size: 30,
                                        ),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () => Navigator.of(dialogContext)
                                            .pop(false),
                                        child: Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFA0C1)
                                          .withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: const Color(0xFFFFA0C1)
                                            .withOpacity(0.22),
                                      ),
                                    ),
                                    child: const Text(
                                      'Premium Messaging',
                                      style: TextStyle(
                                        color: Color(0xFFFFA9C8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Upgrade to start meaningful conversations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Unlock chat access, connect faster with serious matches, and move from browsing to real conversations.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.74),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _buildUpgradePill(
                                        Icons.lock_open_rounded,
                                        'Direct messaging',
                                      ),
                                      _buildUpgradePill(
                                        Icons.workspace_premium_rounded,
                                        'Premium plans',
                                      ),
                                      _buildUpgradePill(
                                        Icons.verified_user_rounded,
                                        'Secure checkout',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),
                                  _buildUpgradeFeature(
                                    icon: Icons.mark_chat_read_rounded,
                                    title: 'Chat without the paywall feeling',
                                    subtitle:
                                        'Open conversations instantly from profiles and respond while the interest is fresh.',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildUpgradeFeature(
                                    icon: Icons.favorite_rounded,
                                    title: 'Reach more serious matches',
                                    subtitle:
                                        'Paid plans are designed for users who are ready to connect, reply, and move forward.',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildUpgradeFeature(
                                    icon: Icons.auto_awesome_rounded,
                                    title: 'A cleaner premium experience',
                                    subtitle:
                                        'Explore packages built for better visibility, stronger engagement, and smoother matchmaking.',
                                  ),
                                  const SizedBox(height: 22),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: BorderSide(
                                              color: Colors.white
                                                  .withOpacity(0.18),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(false),
                                          child: const Text(
                                            'Maybe later',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFFF7DAA),
                                                Color(0xFFFF4E7B),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF4E7B)
                                                    .withOpacity(0.28),
                                                blurRadius: 18,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                            onPressed: () => Navigator.of(
                                              dialogContext,
                                            ).pop(true),
                                            child: const Text(
                                              'See Upgrade Plans',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Choose the plan that fits your journey and unlock messaging right away.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.56),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<void> _openPackagesForMessaging() async {
    if (!mounted) return;
    final isHidden = await PaymentVisibilityService.arePaymentsHidden();
    if (!mounted) return;

    if (isHidden) {
      _showInlineMessage('Package upgrades are currently hidden.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PackagesPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: SafeArea(
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/QAbg.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: userData == null
                ? _buildHeartLoading()
                : Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: PageView.builder(
                          controller: _pageController,
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      width: MediaQuery.of(context).size.width,
                                      height: double.infinity,
                                      imageUrl: imageUrls[index],
                                      placeholder: (context, url) => Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.pink.withOpacity(0.3),
                                              Colors.purple.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                        child:
                                            Center(child: _buildHeartLoading()),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.grey[300]!,
                                              Colors.grey[500]!
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.error,
                                              color: Colors.white, size: 50),
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                    if (_isProfileImgBlur())
                                      Positioned.fill(
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 8, sigmaY: 8),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.1),
                                                  Colors.black.withOpacity(0.3),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.4),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        bottom: 25,
                                        left: 20,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.pink.withOpacity(0.9),
                                                Colors.purple.withOpacity(0.9),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 10,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.search,
                                                  color: Colors.white,
                                                  size: 18),
                                              SizedBox(width: 8),
                                              Text(
                                                'Finding For: ${widget.proposalData["FindingFor"] ?? "Self"}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 0.0,
                        right: 5.0,
                        child: buttonArrow(context),
                      ),
                      Positioned(
                        top: 70.0,
                        right: 5.0,
                        child: sendRequest(context),
                      ),
                      Positioned(
                        top: 140.0,
                        right: 5.0,
                        child: chat(context),
                      ),
                      Positioned(
                        top: 0.0,
                        left: 0.0,
                        child: block(context),
                      ),
                      scroll(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  buttonArrow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        splashColor: Colors.white.withOpacity(0.5),
        onTap: () async {
          if (await Vibration.hasVibrator() != null) {
            Vibration.vibrate(duration: 50);
          }
          FirebaseOperations firebaseOperations = new FirebaseOperations();
          if (await firebaseOperations
              .saveProposal(widget.proposalData["uid"])) {
            Fluttertoast.showToast(msg: "Add To Saved Proposal");
          } else {
            Fluttertoast.showToast(msg: "An error occurred");
          }
        },
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.save,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  sendRequest(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        splashColor: Colors.white.withOpacity(0.5),
        onTap: () async {
          if (await Vibration.hasVibrator() != null) {
            Vibration.vibrate(duration: 50);
          }

          if (!isVerified) {
            _showInlineMessage(
              "You can't send request. Your account is not verified yet.",
            );
            return;
          }

          if (!await _hasUnlockedPremiumAccess()) {
            final shouldOpenPackages = await _showMessagingUpgradeDialog();
            if (shouldOpenPackages) {
              await _openPackagesForMessaging();
            }
            return;
          }

          if (_isFriend()) {
            Fluttertoast.showToast(msg: "Already in your friends list");
            return;
          }

          final firebaseOperations = FirebaseOperations();
          if (await firebaseOperations.sendFriendRequest(
              widget.proposalData["uid"],
              widget.proposalData["JobCountry"],
              widget.proposalData["Gender"])) {
            Fluttertoast.showToast(msg: "Friend Request Sent");
          } else {
            Fluttertoast.showToast(msg: "An error occurred");
          }
        },
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Image.asset(
                "assets/Profile_View_Icons/requests.png",
                height: 16,
                width: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  chat(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        splashColor: Colors.white.withOpacity(0.5),
        onTap: () async {
          if (await Vibration.hasVibrator() != null) {
            Vibration.vibrate(duration: 50);
          }
          if (!await _hasUnlockedPremiumAccess()) {
            final shouldOpenPackages = await _showMessagingUpgradeDialog();
            if (shouldOpenPackages) {
              await _openPackagesForMessaging();
            }
            return;
          }
          CreateChatRoom(
            widget.proposalData["uid"],
            userData["uid"],
            widget.proposalData["name"],
            userData["name"],
            _proposalImageAt(1),
            _userImageAt(1),
          );
        },
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(8),
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Image.asset(
                "assets/Profile_View_Icons/chat.png",
                height: 16,
                width: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  block(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        splashColor: Colors.white.withOpacity(0.5),
        onTap: () async {
          if (await Vibration.hasVibrator() != null) {
            Vibration.vibrate(duration: 50);
          }
          FirebaseOperations firebaseOperations = new FirebaseOperations();
          if (await firebaseOperations.blockUser(widget.proposalData["uid"])) {
            Fluttertoast.showToast(msg: "The User Blocked");
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => UserMain()));
          } else {
            Fluttertoast.showToast(msg: "An error occurred");
          }
        },
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(14),
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Image.asset(
                "assets/block.png",
                height: 16,
                width: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  scroll() {
    return DraggableScrollableSheet(
        initialChildSize: 0.33,
        maxChildSize: 1.0,
        minChildSize: 0.33,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 5,
                          width: 35,
                          color: Colors.black12,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.proposalData['name'] ?? 'Unknown',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'serif',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (countriesCurrencies[widget
                                        .proposalData["JobCountry"]
                                        .toString()] !=
                                    null) ...[
                                  SizedBox(width: 10),
                                  Image.asset(
                                    'icons/currency/${countriesCurrencies[widget.proposalData["JobCountry"].toString()]}.png',
                                    package: 'currency_icons',
                                    width: 32,
                                    height: 32,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "from ${widget.proposalData["NationalityCity"]}, ${widget.proposalData["NationalityCountry"]}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade900),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/Profile_View_Icons/rings.png",
                              width: 28,
                              height: 28,
                            ),
                            Flexible(
                              child: Text(
                                "  ${widget.proposalData["MartialStatus"]}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/Profile_View_Icons/education.png",
                            width: 25,
                            height: 25,
                          ),
                          Container(
                            width: 135,
                            child: Text(
                              " ${widget.proposalData["Field"]}",
                              style: TextStyle(color: Colors.grey.shade900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/Profile_View_Icons/suitcase.png",
                            width: 25,
                            height: 25,
                          ),
                          Container(
                            width: 125,
                            child: Text(
                              " ${widget.proposalData["Profession"]}",
                              style: TextStyle(color: Colors.grey.shade900),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(height: 4),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        (widget.proposalData["Gender"] ?? "")
                                    .toString()
                                    .toLowerCase() ==
                                "male"
                            ? "assets/brother.png"
                            : "assets/sister.png",
                        width: 25,
                        height: 25,
                      ),
                      Text(
                        " Personal Info",
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Age:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(' ${widget.proposalData["Age"]} years old'),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Religion:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(' Islam'),
                            ],
                          ),
                          Row(
                            children: [
                              Text('Sect:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(' ${widget.proposalData["Sect"]}'),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Ethnicity:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(' ${widget.proposalData["Ethnicity"]}'),
                            ],
                          ),
                          Row(
                            children: [
                              Text('Cast:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(' ${widget.proposalData["Tribe"]}    '),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(height: 4),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        "assets/Profile_View_Icons/face.png",
                        width: 25,
                        height: 25,
                      ),
                      Text(
                        " Appearance",
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Weight:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(' ${widget.proposalData["Weight"]} Kg'),
                            ],
                          ),
                          Row(
                            children: [
                              Text('Height:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(' 5 feet 4 inch'),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Skin Tone:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(' ${widget.proposalData["skinTone"]}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text('Body Type:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Blur(blur: 5, child: Text(' #####    ')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(height: 4),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        "assets/Profile_View_Icons/education.png",
                        width: 25,
                        height: 25,
                      ),
                      Text(
                        " Education",
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Higest Qualification:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${widget.proposalData["Field"]}'),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('${widget.proposalData["EducationDescription"]}'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(height: 4),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        "assets/Profile_View_Icons/suitcase.png",
                        width: 25,
                        height: 25,
                      ),
                      Text(
                        " Profession",
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Working as a:  ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${widget.proposalData["Profession"]}'),
                        ],
                      ),
                      Visibility(
                        visible: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monthly Income:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Blur(
                              blur: 5,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('###### /- PKR'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('${widget.proposalData["JobDesc"]}'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(height: 4),
                  ),
                  Row(
                    children: [
                      Image.asset(
                        "assets/Profile_View_Icons/pattner.png",
                        width: 25,
                        height: 25,
                      ),
                      Text(
                        " In Search of ",
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Partner Age',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              "${widget.proposalData["PartnerMinAge "].toString()} - ${widget.proposalData["PartnerMaxAge "]} "),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Partner Country',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_partnerCountryDisplay()),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                ],
              ),
            ),
          );
        });
  }
}
