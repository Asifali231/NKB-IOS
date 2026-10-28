import 'dart:ui';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nikah_blessing/FirebaseOperation/payment_visibility_service.dart';
import 'package:nikah_blessing/Packages_Module/allPackagesModule.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import '../../DataClass/MyData_Class.dart';
import '../../Email_Authentication/EmailAuth_Main.dart';
import '../../Make_Profile/Profile_Questionnaire_main.dart';
import '../../UpdateProfile/UpdateFilters.dart';
import 'ProposalCard.dart';

class ProposalMainController extends StatefulWidget {
  const ProposalMainController({super.key});

  @override
  State<ProposalMainController> createState() => _ProposalMainControllerState();
}

class _ProposalMainControllerState extends State<ProposalMainController>
    with TickerProviderStateMixin {
  static const int _unlockedDailyProfilesLimit = 2000;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> proposals = [];
  List<String> adUrls = [];
  bool isLoading = true;
  bool hasError = false;

  final ScrollController _scrollController = ScrollController();
  double _headerOpacity = 1.0;
  double _headerOffset = 0.0;

  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scrollController.addListener(_onScroll);

    fetchProposalsWithClientSideFiltering();
    fetchAdUrls();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _headerOpacity = (1.0 - (offset / 100)).clamp(0.0, 1.0);
      _headerOffset = offset * 0.5;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openPackagesPage() async {
    final isHidden = await PaymentVisibilityService.arePaymentsHidden();
    if (!mounted) return;

    if (isHidden) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package upgrades are currently hidden.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PackagesPage()),
    );
  }

  var userData;

  List<String> _normalizeCountryFilters(dynamic rawValue) {
    if (rawValue is List) {
      return rawValue
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .map((item) => item.toString())
          .toList();
    }

    if (rawValue is String && rawValue.trim().isNotEmpty) {
      if (rawValue.contains(',')) {
        return rawValue
            .split(',')
            .map((country) => country.trim())
            .where((country) => country.isNotEmpty)
            .toList();
      }
      return [rawValue.trim()];
    }

    return [];
  }

  int _safeInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9-]'), '').trim();
      return int.tryParse(cleaned) ?? fallback;
    }
    return fallback;
  }

  String _normalizeString(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  bool _matchesUserFilters(
    Map<String, dynamic> candidateData,
    Set<String> selectedCountries,
    Set<String> selectedMartialStatuses,
    String selectedSect,
    int minAge,
    int maxAge,
    String currentUserGender,
    String currentUserId,
    Set<String> blockedUserIds,
  ) {
    final candidateUserId = candidateData['uid']?.toString() ?? '';
    if (candidateUserId.isEmpty || candidateUserId == currentUserId) {
      return false;
    }

    if (blockedUserIds.contains(candidateUserId)) {
      return false;
    }

    final candidateGender = _normalizeString(candidateData['Gender']);
    if (candidateGender.isEmpty || candidateGender == currentUserGender) {
      return false;
    }

    final candidateAge = _safeInt(candidateData['Age'], fallback: -1);
    if (candidateAge < minAge || candidateAge > maxAge) {
      return false;
    }

    if (selectedCountries.isNotEmpty) {
      final candidateCountry =
          _normalizeString(candidateData['NationalityCountry']);
      if (!selectedCountries.contains(candidateCountry)) {
        return false;
      }
    }

    if (selectedSect.isNotEmpty) {
      final candidateSect = _normalizeString(candidateData['Sect']);
      if (candidateSect != selectedSect) {
        return false;
      }
    }

    if (selectedMartialStatuses.isNotEmpty) {
      final candidateMartialStatus =
          _normalizeString(candidateData['MartialStatus']);
      if (!selectedMartialStatuses.contains(candidateMartialStatus)) {
        return false;
      }
    }

    return true;
  }

  Future<List<DocumentSnapshot>> _fetchFilteredCandidates({
    required int desiredDailyProfiles,
    required Set<String> selectedCountries,
    required Set<String> selectedMartialStatuses,
    required String selectedSect,
    required int minAge,
    required int maxAge,
    required String currentUserGender,
    required String currentUserId,
    required Set<String> blockedUserIds,
  }) async {
    const int pageSize = 200;
    const int maxScannedDocuments = 2000;

    final List<DocumentSnapshot> matchedProfiles = [];
    DocumentSnapshot? lastDoc;
    int scannedDocuments = 0;

    while (scannedDocuments < maxScannedDocuments) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .where('VerificationStatus', isEqualTo: 'Verified')
          .orderBy(FieldPath.documentId)
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        break;
      }

      for (final doc in snapshot.docs) {
        scannedDocuments++;
        if (_matchesUserFilters(
          doc.data(),
          selectedCountries,
          selectedMartialStatuses,
          selectedSect,
          minAge,
          maxAge,
          currentUserGender,
          currentUserId,
          blockedUserIds,
        )) {
          matchedProfiles.add(doc);
        }
      }

      lastDoc = snapshot.docs.last;

      final reachedEnd = snapshot.docs.length < pageSize;
      final hasEnoughForRandomPool =
          matchedProfiles.length >= (desiredDailyProfiles * 3);

      if (reachedEnd || hasEnoughForRandomPool) {
        break;
      }
    }

    return matchedProfiles;
  }

  Future<void> getUserData() async {
    final auth = FirebaseAuth.instance;
    User? user = await auth.currentUser;

    if (user == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => EmailAuth_Main()));
      return;
    }

    DocumentSnapshot docSnapshot =
        await _firestore.collection('users').doc(user.uid).get();

    if (docSnapshot.exists) {
      setState(() {
        userData = docSnapshot.data() as Map<String, dynamic>?;
        MyData_Class.MyMapData = userData;
      });

      if (userData["VerificationStatus"] == "Rejected") {
        QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: "Unverified Profile",
            text: "Your profile has been rejected. Please update your profile.",
            barrierDismissible: false,
            onConfirmBtnTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Profile_Questionnaire_main())),
            confirmBtnText: "Update Profile",
            onCancelBtnTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => Profile_Questionnaire_main())));
      }

      if (!userData.containsKey("VerificationStatus")) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Profile_Questionnaire_main()),
        );
      }
    }
  }

  Future<void> fetchProposalsWithClientSideFiltering(
      {bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }

    try {
      await getUserData();
      if (userData == null) {
        setState(() {
          proposals = [];
          isLoading = false;
        });
        return;
      }

      final premiumFeaturesUnlocked =
          await PaymentVisibilityService.arePremiumFeaturesUnlocked();
      final int dailyProfilesLimit = premiumFeaturesUnlocked
          ? _unlockedDailyProfilesLimit
          : _safeInt(userData["DailyProfiles"], fallback: 5).clamp(0, 500);
      if (dailyProfilesLimit <= 0) {
        setState(() {
          proposals = [];
          isLoading = false;
          hasError = false;
        });
        return;
      }

      final selectedCountries = _normalizeCountryFilters(
        userData['PartnerCountry '],
      ).map(_normalizeString).where((value) => value.isNotEmpty).toSet();

      final selectedMartialStatuses =
          ((userData['PartnerMartialStatus '] as List?) ?? const [])
              .map(_normalizeString)
              .where((value) => value.isNotEmpty)
              .toSet();

      final selectedSect = _normalizeString(userData['PartnerSect ']);
      final rawMinAge = _safeInt(userData['PartnerMinAge '], fallback: 18);
      final rawMaxAge = _safeInt(userData['PartnerMaxAge '], fallback: 99);
      final minAge = min(rawMinAge, rawMaxAge);
      final maxAge = max(rawMinAge, rawMaxAge);
      final currentUserGender = _normalizeString(userData['Gender']);
      final currentUserId = userData['uid']?.toString() ?? '';
      final blockedUserIds = ((userData['blockUsers'] as List?) ?? const [])
          .map((item) => item.toString())
          .where((value) => value.isNotEmpty)
          .toSet();

      final matchedProfiles = await _fetchFilteredCandidates(
        desiredDailyProfiles: dailyProfilesLimit,
        selectedCountries: selectedCountries,
        selectedMartialStatuses: selectedMartialStatuses,
        selectedSect: selectedSect,
        minAge: minAge,
        maxAge: maxAge,
        currentUserGender: currentUserGender,
        currentUserId: currentUserId,
        blockedUserIds: blockedUserIds,
      );

      final randomizedProfiles = List<DocumentSnapshot>.from(matchedProfiles)
        ..shuffle(Random());
      final filteredProposals =
          randomizedProfiles.take(dailyProfilesLimit).toList();

      setState(() {
        proposals = filteredProposals;
        isLoading = false;
        hasError = false;
      });

      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Error fetching proposals");
    }
  }

  Future<void> fetchAdUrls() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('InAppPromotion')
          .doc('imgs')
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          adUrls = [
            data['url1'] as String? ?? '',
            data['url2'] as String? ?? '',
          ].where((url) => url.isNotEmpty).toList();
        });
      }
    } catch (e) {
      print('Error fetching ad URLs: $e');
    }
  }

  List<dynamic> buildItems(List<DocumentSnapshot> proposals) {
    List<dynamic> items = [];
    int count = 0;
    int adStep = 2;
    int adIndex = 0;

    for (int i = 0; i < proposals.length; i++) {
      items.add(proposals[i]);
      count++;
      if (count == adStep && adUrls.isNotEmpty) {
        items.add(adUrls[adIndex % adUrls.length]);
        adIndex++;
        count = 0;
        adStep += 1;
      }
    }
    return items;
  }

  Widget _buildShimmerCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin:
                            Alignment(-1.0 + _shimmerController.value * 2, 0.0),
                        end: Alignment(1.0 + _shimmerController.value * 2, 0.0),
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin:
                            Alignment(-1.0 + _shimmerController.value * 2, 0.0),
                        end: Alignment(1.0 + _shimmerController.value * 2, 0.0),
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin:
                            Alignment(-1.0 + _shimmerController.value * 2, 0.0),
                        end: Alignment(1.0 + _shimmerController.value * 2, 0.0),
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin:
                            Alignment(-1.0 + _shimmerController.value * 2, 0.0),
                        end: Alignment(1.0 + _shimmerController.value * 2, 0.0),
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[100]!,
                          Colors.grey[300]!
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment(
                                -1.0 + _shimmerController.value * 2, 0.0),
                            end: Alignment(
                                1.0 + _shimmerController.value * 2, 0.0),
                            colors: [
                              Colors.grey[300]!,
                              Colors.grey[100]!,
                              Colors.grey[300]!
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment(
                                -1.0 + _shimmerController.value * 2, 0.0),
                            end: Alignment(
                                1.0 + _shimmerController.value * 2, 0.0),
                            colors: [
                              Colors.grey[300]!,
                              Colors.grey[100]!,
                              Colors.grey[300]!
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.pink.shade50, Colors.white, Colors.purple.shade50],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1000),
            tween: Tween<double>(begin: 0.5, end: 1.2),
            builder: (context, double scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.pink.shade200, Colors.purple.shade200],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.heart_fill,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Finding Perfect Matches...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => _buildShimmerCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade100,
              ),
              child: Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Unable to load proposals',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                fetchProposalsWithClientSideFiltering();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple.shade50, Colors.white, Colors.pink.shade50],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1500),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.4 * value),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade200, Colors.pink.shade200],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.heart_circle_fill,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'No Matches Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Your search criteria might be too specific.\nTry adjusting your preferences to find more matches.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              margin: EdgeInsets.only(top: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.pink.shade400],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UpdateFilters()),
                  );
                },
                icon: const Icon(Icons.tune, color: Colors.white),
                label: const Text(
                  'Adjust Preferences',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Transform.translate(
      offset: Offset(0, -_headerOffset),
      child: Opacity(
        opacity: _headerOpacity,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 0, right: 0, left: 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFAFBFC)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.8),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE17055).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Perfect Matches',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D3436),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFFE17055)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00B894).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${proposals.length} profiles',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00B894),
                                  ),
                                ),
                              ),
                              StreamBuilder<bool>(
                                stream: PaymentVisibilityService
                                    .paymentsHiddenStream(),
                                builder: (context, snapshot) {
                                  final isHidden = snapshot.data ?? true;
                                  if (isHidden) {
                                    return const SizedBox.shrink();
                                  }

                                  return Row(
                                    children: [
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 14,
                                        color: Color(0xFF636E72),
                                      ),
                                      SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: _openPackagesPage,
                                        child: Text(
                                          'Upgrade for more',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF636E72),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UpdateFilters()),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFF8F9FA)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFFE17055).withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF6B6B).withOpacity(0.1),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Icon(
                              Icons.tune,
                              color: Color(0xFFE17055),
                              size: 22,
                            ),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Color(0xFF00B894),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF00B894).withOpacity(0.4),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
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
        ),
      ),
    );
  }

  Widget _buildProposalsList() {
    List<dynamic> items = buildItems(proposals);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/QAbg.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () => fetchProposalsWithClientSideFiltering(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildStickyHeader(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  if (item is DocumentSnapshot) {
                    final proposalData = item.data() as Map<String, dynamic>;
                    return AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: TweenAnimationBuilder(
                              duration:
                                  Duration(milliseconds: 600 + (index * 100)),
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 50 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child:
                                        _buildProposalItem(index, proposalData),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  } else if (item is String) {
                    return AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: TweenAnimationBuilder(
                              duration:
                                  Duration(milliseconds: 600 + (index * 100)),
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, double value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 50 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: _buildAdWidget(item),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount: items.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProposalItem(int index, Map<String, dynamic> proposalData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      child: ProposalCard(proposalData: proposalData),
    );
  }

  Widget _buildAdWidget(String url) {
    return StreamBuilder<bool>(
      stream: PaymentVisibilityService.paymentsHiddenStream(),
      builder: (context, snapshot) {
        final isHidden = snapshot.data ?? true;
        if (isHidden) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
          child: GestureDetector(
            onTap: _openPackagesPage,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.pink.shade400],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  height: 380,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Failed to load ad'));
                  },
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✨ Premium',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingState();
    if (hasError) return _buildErrorState();
    if (proposals.isEmpty) return _buildEmptyState();
    return _buildProposalsList();
  }
}
