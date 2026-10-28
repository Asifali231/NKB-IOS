import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:nikah_blessing/User_Home_Pages/ProposalModule/profile_view_page.dart';
import 'Chat_Screen.dart';

class User_Chat_Page extends StatefulWidget {
  const User_Chat_Page({Key? key}) : super(key: key);

  @override
  State<User_Chat_Page> createState() => _User_Chat_PageState();
}

class _User_Chat_PageState extends State<User_Chat_Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Placeholder function from original code
  getProductDetail() {}

  @override
  void initState() {
    getProductDetail();
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String userId = FirebaseAuth.instance.currentUser!.uid;

  // Chat stream definition
  Stream<QuerySnapshot> chatMessageStream = FirebaseFirestore.instance
      .collection('Chats')
      .where('users', arrayContains: FirebaseAuth.instance.currentUser?.uid)
      .orderBy("lastChatTime", descending: true)
      .snapshots();

  // Fetch friends list (unchanged from original)
  Future<List<String>> getFriendsList() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final userData = userDoc.data() as Map<String, dynamic>?;
    final friendsList =
        List<String>.from((userData?['friends'] as List?) ?? const []);
    return friendsList;
  }

  // Other utility functions remain unchanged but are included for completeness
  Future<Map<String, dynamic>> getOnlineStatus(String friendUid) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendUid)
        .get();
    String img = userDoc['ProfileImageUrls'][1] ?? "";
    String name = userDoc['name'] ?? "Devil";
    DatabaseReference userStatusRef =
        FirebaseDatabase.instance.ref('users/$friendUid');
    DataSnapshot statusSnapshot = await userStatusRef.get();
    Map<String, dynamic> statusData = {};
    if (statusSnapshot.exists) {
      statusData = {
        'id': friendUid,
        'img': img,
        'name': name,
        'status': statusSnapshot.child('status').value ?? 'offline',
        'lastOnline': statusSnapshot.child('lastOnline').value ?? 0,
      };
    }
    return statusData;
  }

  Future<Map<String, dynamic>> getFreindData(String friendUid) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendUid)
        .get();
    Map<String, dynamic> us = userDoc.data() as Map<String, dynamic>;
    return us;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/QAbg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // AppBar (unchanged)
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.white.withOpacity(0.95)],
                ),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Messages",
                          style: TextStyle(
                            color: Color(0xFF2D3748),
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Stay connected with your matches",
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        color: Color(0xFF667EEA),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Section header (unchanged)
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "My Chats",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Chat list with block filtering
            Expanded(
              child: FutureBuilder<List<String>>(
                future: getFriendsList(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<String>> friendsSnapshot) {
                  if (friendsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  }
                  if (friendsSnapshot.hasError) {
                    return Center(
                      child: Container(
                        margin: EdgeInsets.all(20),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Error loading friends',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    );
                  }
                  if (friendsSnapshot.data!.isEmpty &&
                      friendsSnapshot.connectionState == ConnectionState.none) {
                    return Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: EdgeInsets.all(20),
                          padding: EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA).withOpacity(0.2),
                                      Color(0xFF764BA2).withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Icon(
                                  CupertinoIcons.chat_bubble_2,
                                  size: 80,
                                  color: Color(0xFF667EEA),
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                'No chats yet, start exploring',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Don't be shy 😉",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.hasError) {
                        return Center(
                          child: Container(
                            margin: EdgeInsets.all(20),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Text(
                              'Error loading user data',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        );
                      }
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF667EEA)),
                              strokeWidth: 3,
                            ),
                          ),
                        );
                      }

                      Map<String, dynamic> userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      List<String> blockUsers =
                          List.from(userData['blockUsers'] ?? []);

                      return StreamBuilder<QuerySnapshot>(
                        stream: chatMessageStream,
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Container(
                                margin: EdgeInsets.all(20),
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Something went wrong',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF667EEA)),
                                  strokeWidth: 3,
                                ),
                              ),
                            );
                          }

                          // Filter chats to exclude blocked users
                          List<DocumentSnapshot> filteredDocs =
                              snapshot.data!.docs.where((doc) {
                            Map<String, dynamic> data =
                                doc.data()! as Map<String, dynamic>;
                            List<String> users = List.from(data['users']);
                            String otherUser =
                                users.firstWhere((uid) => uid != userId);
                            return !blockUsers.contains(otherUser);
                          }).toList();

                          if (filteredDocs.isEmpty) {
                            return Center(
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  margin: EdgeInsets.all(20),
                                  padding: EdgeInsets.all(30),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF667EEA)
                                                  .withOpacity(0.2),
                                              Color(0xFF764BA2)
                                                  .withOpacity(0.2),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Icon(
                                          CupertinoIcons.chat_bubble_2,
                                          size: 80,
                                          color: Color(0xFF667EEA),
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      Text(
                                        'No chats yet, start exploring',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Don't be shy 😉",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF718096),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot document = filteredDocs[index];
                              Map<String, dynamic> data =
                                  document.data()! as Map<String, dynamic>;
                              String personID = data['users']
                                  .firstWhere((uid) => uid != userId);
                              String name =
                                  data['usersName'][personID] ?? "waiting ...";
                              String img =
                                  data['usersImg'][personID] ?? "waiting ...";
                              int unreadMsg = data['UnreadMsg'][userId] ?? 0;
                              String lastMsg =
                                  data['lastChat'] ?? "waiting ...";
                              int unixTimestamp = data['lastChatTime'] ?? 0;
                              if (unixTimestamp > 10000000000000) {
                                unixTimestamp = (unixTimestamp / 1000).round();
                              }
                              DateTime lastChatDateTime =
                                  DateTime.fromMillisecondsSinceEpoch(
                                      unixTimestamp);
                              DateTime now = DateTime.now();
                              String lastMsgTime =
                                  _formatLastMessageTime(lastChatDateTime, now);

                              return AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                margin: EdgeInsets.only(bottom: 12),
                                child: Material(
                                  elevation: 0,
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Chat_Screen(
                                            chatRoomId: data["chatRoomID"],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.03),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Stack(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: CircleAvatar(
                                                  radius: 28,
                                                  backgroundImage:
                                                      NetworkImage(img),
                                                  backgroundColor:
                                                      Color(0xFF667EEA)
                                                          .withOpacity(0.1),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 2,
                                                right: 2,
                                                child: Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.white,
                                                        width: 2),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: Color(0xFF2D3748),
                                                    letterSpacing: 0.2,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  lastMsg,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF718096),
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                lastMsgTime,
                                                style: TextStyle(
                                                  color: Color(0xFF718096),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (unreadMsg > 0) ...[
                                                SizedBox(height: 8),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        LinearGradient(colors: [
                                                      Color(0xFFFF6B6B),
                                                      Color(0xFFEE5A52),
                                                    ]),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Color(0xFFFF6B6B)
                                                            .withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    unreadMsg > 99
                                                        ? '99+'
                                                        : unreadMsg.toString(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastMessageTime(DateTime lastChatDateTime, DateTime now) {
    if (lastChatDateTime.year == now.year &&
        lastChatDateTime.month == now.month &&
        lastChatDateTime.day == now.day) {
      return lastChatDateTime.hour > 12
          ? "${lastChatDateTime.hour - 12}:${lastChatDateTime.minute.toString().padLeft(2, '0')} PM"
          : "${lastChatDateTime.hour}:${lastChatDateTime.minute.toString().padLeft(2, '0')} AM";
    } else if (lastChatDateTime.year == now.year &&
        lastChatDateTime.month == now.month &&
        lastChatDateTime.day == now.day - 1) {
      return "Yesterday";
    } else {
      return "${lastChatDateTime.day}/${lastChatDateTime.month}/${lastChatDateTime.year}";
    }
  }
}
