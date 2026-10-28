import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';

import '../ProposalModule/profile_view_page.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage>
    with TickerProviderStateMixin {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  Future<Map<String, dynamic>?> fetchProposalData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching proposal data: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<T?> handleFirestoreOperation<T>(Future<T> operation) async {
    try {
      return await operation;
    } catch (e) {
      debugPrint('Firestore operation failed: $e');
      return null;
    }
  }

  Future<List<String>> getFriendsList() async {
    if (currentUserId.isEmpty) return [];

    final userDoc = await handleFirestoreOperation(FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get());

    return List<String>.from(userDoc?['friends'] ?? []);
  }

  Future<Map<String, dynamic>> getOnlineStatus(String friendUid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .get();

      if (!userDoc.exists) {
        return {'status': 'offline'};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final profileImages = userData['ProfileImageUrls'] as List?;

      final img = (profileImages?.length ?? 0) > 1 ? profileImages![1] : "";
      final name = userData['name'] ?? "Unknown";

      final userStatusRef = FirebaseDatabase.instance.ref('users/$friendUid');
      final statusSnapshot = await userStatusRef.get();

      if (!statusSnapshot.exists) {
        return {
          'id': friendUid,
          'img': img,
          'name': name,
          'status': 'offline',
          'lastOnline': 0,
        };
      }

      return {
        'id': friendUid,
        'img': img,
        'name': name,
        'status': statusSnapshot.child('status').value ?? 'offline',
        'lastOnline': statusSnapshot.child('lastOnline').value ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching online status: $e');
      return {
        'id': friendUid,
        'status': 'offline',
        'lastOnline': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> fetchFriendRequests(
      List<dynamic> friendRequests) async {
    List<Map<String, dynamic>> friendsData = [];

    for (String userId in friendRequests) {
      if (userId == currentUserId) continue;

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (snapshot.exists) {
          friendsData.add(snapshot.data()!);
        }
      } catch (e) {
        debugPrint("Error fetching data for user $userId: $e");
      }
    }

    return friendsData;
  }

  Future<void> handleAcceptRequest(String requesterId) async {
    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final currentUserRef =
      FirebaseFirestore.instance.collection('users').doc(currentUserId);
      final requesterRef =
      FirebaseFirestore.instance.collection('users').doc(requesterId);

      final currentUserDoc = await currentUserRef.get();
      final requesterDoc = await requesterRef.get();

      if (!currentUserDoc.exists || !requesterDoc.exists) {
        throw Exception('User document not found');
      }

      final currentUserData = currentUserDoc.data()!;
      final friends = List<String>.from(currentUserData['friends'] ?? []);
      final friendRequests = List<String>.from(currentUserData['friendsRequests'] ?? []);

      friends.add(requesterId);
      friendRequests.remove(requesterId);

      batch.update(currentUserRef, {
        'friends': friends,
        'friendsRequests': friendRequests,
      });

      final requesterFriends = List<String>.from(requesterDoc.data()!['friends'] ?? []);
      requesterFriends.add(currentUserId);

      batch.update(requesterRef, {
        'friends': requesterFriends,
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Friend request accepted!'),
                ],
                  ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to accept friend request. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> handleRemoveRequest(String requesterId) async {
    setState(() => _isLoading = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      final friendRequests = List<String>.from(userDoc.data()!['friendsRequests'] ?? []);
      friendRequests.remove(requesterId);

      await userRef.update({
        'friendsRequests': friendRequests,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.person_remove, color: Colors.white),
                SizedBox(width: 8),
                Text('Friend request removed'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error removing friend request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to remove friend request. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFriendAvatar(Map<String, dynamic> statusData) {
    final status = statusData['status'] ?? 'offline';
    final img = statusData['img'] ?? '';
    final name = statusData['name'] ?? 'Unknown';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: status == 'online' ? _pulseAnimation : _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: status == 'online' ? _pulseAnimation.value : 1.0,
                child: Stack(
                  children: [
                    Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: status == 'online'
                              ? [Colors.green.shade300, Colors.green.shade600]
                              : [Colors.grey.shade300, Colors.grey.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: status == 'online'
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.all(2),
                        child: CircleAvatar(
                          backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint('Error loading profile image: $exception');
                          },
                          child: img.isEmpty
                              ? Icon(Icons.person, size: 30, color: Colors.grey.shade600)
                              : null,
                          radius: 38,
                        ),
                      ),
                    ),
                    if (status == 'online')
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.5),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestCard(Map<String, dynamic> friendData, int index) {
    final name = friendData['name'] ?? 'Unknown';
    final country = friendData['NationalityCountry'] ?? 'Unknown location';
    final city = friendData['NationalityCity'] ?? 'Unknown location';
    final profileImages = friendData['ProfileImageUrls'] as List?;
    final profileImageUrl = profileImages?.isNotEmpty == true
        ? profileImages![0]
        : "https://i.pinimg.com/736x/31/a0/80/31a0803ac2746823c4a97d4f02596850.jpg";

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // HapticFeedback.selectionClick();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade300, Colors.purple.shade300],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: EdgeInsets.all(3),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: profileImageUrl,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade100,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.blue.shade300),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey.shade100,
                                      child: Icon(
                                        Icons.person,
                                        size: 35,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.person_add,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontFamily: 'serif',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'icons/currency/pkr.png',
                                          package: 'currency_icons',
                                          width: 16,
                                          height: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'PKR',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "$city, $country",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 42,
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : () => handleAcceptRequest(friendData['uid']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade600,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        label: Text(
                                          'Accept',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      height: 42,
                                      child: OutlinedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : () => handleRemoveRequest(friendData['uid']),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade600,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        label: Text(
                                          'Decline',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'Please sign in to view friend requests',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/QAbg.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.people,
                            color: Colors.red.shade600,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Friendship',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, size: 64, color: Colors.red.shade300),
                                SizedBox(height: 16),
                                Text('Something went wrong',
                                    style: TextStyle(fontSize: 18, color: Colors.red.shade600)),
                              ],
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                                ),
                                SizedBox(height: 16),
                                Text('Loading...', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                                SizedBox(height: 16),
                                Text('No data available',
                                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                              ],
                            ),
                          );
                        }

                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                        final blockUsers = List<String>.from(userData['blockUsers'] ?? []);
                        final friendRequests = List<String>.from(userData['friendsRequests'] ?? []);
                        final filteredFriendRequests = friendRequests
                            .where((uid) => !blockUsers.contains(uid))
                            .toList();




                        List<dynamic> myFriends = List<dynamic>.from(userData['friends'] ?? []);
                        myFriends = myFriends
                            .where((friend) => friend != UserData.userID)
                            .where((friend) => !blockUsers.contains(friend))
                            .toList();

                        return RefreshIndicator(
                          onRefresh: () async => setState(() {}),
                          color: Colors.blue.shade600,
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.group,
                                              color: Colors.green.shade600,
                                              size: 20,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            "My Friends",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          Spacer(),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Text(
                                              '${myFriends.length}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      if (myFriends.isEmpty)
                                        Container(
                                          height: 100,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.people_outline,
                                                    size: 40, color: Colors.grey.shade400),
                                                SizedBox(height: 8),
                                                Text(
                                                  'No friends yet',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          height: 130,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: myFriends.length,
                                            itemBuilder: (context, index) {
                                              final friendUid = myFriends[index];
                                              return FutureBuilder<Map<String, dynamic>>(
                                                future: getOnlineStatus(friendUid),
                                                builder: (context, statusSnapshot) {
                                                  if (statusSnapshot.hasError) {
                                                    return Container(
                                                      width: 100,
                                                      child: Center(
                                                        child: Icon(Icons.error, color: Colors.red.shade300),
                                                      ),
                                                    );
                                                  }
                                                  if (!statusSnapshot.hasData) {
                                                    return Container(
                                                      width: 100,
                                                      child: Center(
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation(Colors.blue.shade300),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return InkWell(
                                                    onTap: () async {
                                                      showDialog(
                                                        context: context,
                                                        barrierDismissible: false,
                                                        builder: (context) => Center(child: CircularProgressIndicator()),
                                                      );
                                                      final proposalData = await fetchProposalData(friendUid);
                                                      Navigator.pop(context);
                                                      if (proposalData != null) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => profile_view_page(
                                                              proposalData: proposalData,
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text('Failed to load proposal data')),
                                                        );
                                                      }
                                                    },
                                                    child: _buildFriendAvatar(statusSnapshot.data!),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.person_add,
                                          color: Colors.orange.shade600,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Friend Requests",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      Spacer(),
                                      if (filteredFriendRequests.isNotEmpty)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: Text(
                                            '${filteredFriendRequests.length}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: FutureBuilder<List<Map<String, dynamic>>>(
                                  future: fetchFriendRequests(filteredFriendRequests),
                                  builder: (context, futureSnapshot) {
                                    if (futureSnapshot.hasError) {
                                      return Container(
                                        height: 200,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error, size: 64, color: Colors.red.shade300),
                                              SizedBox(height: 16),
                                              Text(
                                                'Error loading friend requests',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.red.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    if (!futureSnapshot.hasData) {
                                      return Container(
                                        height: 200,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'Loading friend requests...',
                                                style: TextStyle(color: Colors.grey.shade600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    final friendsData = futureSnapshot.data!;

                                    if (friendsData.isEmpty) {
                                      return Container(
                                        height: 300,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  CupertinoIcons.person_2,
                                                  size: 60,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                              SizedBox(height: 24),
                                              Text(
                                                'No pending friend requests',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'When someone sends you a friend request,\nit will appear here.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: List.generate(
                                        friendsData.length,
                                            (index) => _buildFriendRequestCard(friendsData[index], index),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: SizedBox(height: 20),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}