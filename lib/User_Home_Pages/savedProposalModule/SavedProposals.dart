import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../FirebaseOperation/FirebaseOperations.dart';
import '../ProposalModule/profile_view_page.dart';

class SavedProposals extends StatefulWidget {
  const SavedProposals({super.key});

  @override
  _SavedProposalsState createState() => _SavedProposalsState();
}

class _SavedProposalsState extends State<SavedProposals>
    with TickerProviderStateMixin {
  String? currentUserId;
  late AnimationController _animationController;
  late AnimationController _staggerController;
  late Animation<double> _headerAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _getCurrentUserId() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchSavedProfiles(
      List<dynamic> savedProfiles) async {
    List<Map<String, dynamic>> friendsData = [];
    for (String userId in savedProfiles) {
      try {
        DocumentSnapshot<Map<String, dynamic>> snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
        if (snapshot.exists) {
          friendsData.add(snapshot.data()!);
        }
      } catch (e) {
        print("Error fetching data for user $userId: $e");
      }
    }
    return friendsData;
  }

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

  // Determines if the profile image should be blurred based on privacy settings
  bool _shouldBlurImage(Map<String, dynamic> proposalData) {
    String shareSetting = proposalData["ProfileImageShare"] ?? "0";
    if (shareSetting == "1") {
      List<dynamic> friends = proposalData["friends"] ?? [];
      return !friends.contains(currentUserId);
    } else if (shareSetting == "2") {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width - 12.6;
    double cardHeight = 320;
    double aspectRatio = screenWidth / (cardHeight * 2);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/QAbg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 0),
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        color: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                CupertinoIcons.heart_fill,
                                color: Color(0xFFFF6B6B),
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saved Proposals',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3436),
                                    ),
                                  ),
                                  Text(
                                    'Your favorite connections',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF636E72),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              Expanded(
                child: currentUserId == null
                    ? _buildLoadingState()
                    : StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUserId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingState();
                          }
                          if (snapshot.hasError) {
                            return _buildErrorState();
                          }
                          if (snapshot.hasData && snapshot.data!.exists) {
                            var userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            List<dynamic> savedProfiles =
                                userData['savedProposals'] ?? [];
                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future: fetchSavedProfiles(savedProfiles),
                              builder: (context, futureSnapshot) {
                                if (futureSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return _buildLoadingState();
                                }
                                if (futureSnapshot.hasError) {
                                  return _buildErrorState();
                                }
                                if (!futureSnapshot.hasData ||
                                    futureSnapshot.data!.isEmpty) {
                                  return _buildEmptyState();
                                }
                                List<Map<String, dynamic>> friendsData =
                                    futureSnapshot.data!;
                                _staggerController.forward();
                                return _buildGridView(friendsData, aspectRatio);
                              },
                            );
                          }
                          return _buildEmptyState();
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading your saved proposals...',
            style: TextStyle(
              color: Color(0xFF636E72),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 60,
              color: Color(0xFFFFB347),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              color: Color(0xFF636E72),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF6B6B).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.heart,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'No Saved Proposals Yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Start saving profiles to keep track of your favorite connections and never miss out on amazing proposals!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF636E72),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(
      List<Map<String, dynamic>> friendsData, double aspectRatio) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: GridView.builder(
        physics: BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15.0,
          mainAxisSpacing: 15.0,
          childAspectRatio: aspectRatio,
        ),
        itemCount: friendsData.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _staggerController,
            builder: (context, child) {
              double animationValue = Curves.easeOutBack.transform(
                (_staggerController.value - (index * 0.1)).clamp(0.0, 1.0),
              );
              final double safeOpacity = animationValue.clamp(0.0, 1.0);
              return Transform.scale(
                scale: animationValue,
                child: Opacity(
                  opacity: safeOpacity,
                  child: _buildProposalCard(friendsData[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProposalCard(Map<String, dynamic> savedProposalData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                profile_view_page(proposalData: savedProposalData),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          ),
        );
      },
      child: Hero(
        tag: savedProposalData["uid"] ?? DateTime.now().millisecondsSinceEpoch,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Profile image with optional blur
                savedProposalData != null &&
                        savedProposalData['ProfileImageUrls'] != null &&
                        savedProposalData['ProfileImageUrls'].isNotEmpty
                    ? Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: savedProposalData['ProfileImageUrls'][0],
                            fit: BoxFit.fitHeight,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF6B6B)),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(Icons.person,
                                    size: 50, color: Colors.grey[600]),
                              ),
                            ),
                          ),
                          if (_shouldBlurImage(savedProposalData))
                            Positioned.fill(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.person,
                              size: 50, color: Colors.grey[600]),
                        ),
                      ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Remove button
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildRemoveButton(context, savedProposalData["uid"]),
                ),
                // Profile information
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                savedProposalData['name'] ?? 'Unknown',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (countriesCurrencies[
                                    savedProposalData["NationalityCountry"]
                                        .toString()] !=
                                null)
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.asset(
                                  'icons/currency/${countriesCurrencies[savedProposalData["NationalityCountry"].toString()]}.png',
                                  package: 'currency_icons',
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.location_solid,
                              color: Colors.white70,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${savedProposalData["NationalityCity"] ?? "Unknown"}, ${savedProposalData["NationalityCountry"] ?? "Unknown"}",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context, String uid) {
    return GestureDetector(
      onTap: () async {
        bool? shouldRemove = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: Text('Remove Proposal'),
              content:
                  Text('Are you sure you want to remove this saved proposal?'),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('Remove', style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );

        if (shouldRemove == true) {
          FirebaseOperations firebaseOperations = FirebaseOperations();
          if (await firebaseOperations.removeSavedProposal(uid)) {
            Fluttertoast.showToast(
              msg: "Proposal removed successfully",
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          } else {
            Fluttertoast.showToast(
              msg: "Failed to remove proposal",
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Icon(
                CupertinoIcons.delete,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
