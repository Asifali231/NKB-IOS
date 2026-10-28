import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nikah_blessing/DataClass/MyData_Class.dart';
import 'package:nikah_blessing/Notifications/NotificationPage.dart';

class Chat_Screen extends StatefulWidget {
  final String chatRoomId;

  const Chat_Screen({Key? key, required this.chatRoomId}) : super(key: key);

  @override
  State<Chat_Screen> createState() => _Chat_ScreenState();
}

class _Chat_ScreenState extends State<Chat_Screen> with WidgetsBindingObserver {
  String personId = "";
  String name = "";
  String img = "";
  String myUserId = "";
  String status = "offline";

  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController chatMessageController = TextEditingController();

  bool _isKeyboardOpen = false;
  bool _send = false;
  Stream<QuerySnapshot>? _chatMessageStream;

  @override
  void initState() {
    super.initState();
    myUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _initializeChat();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_onFocusChange);
  }

  void _initializeChat() async {
    _chatMessageStream = FirebaseFirestore.instance
        .collection("Chats")
        .doc(widget.chatRoomId)
        .collection("chats")
        .orderBy("time", descending: false)
        .snapshots();

    await fetchChatDetails();
    makeMessagesRead();

    if (mounted) setState(() {});
  }

  Future<void> fetchChatDetails() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection("Chats")
          .doc(widget.chatRoomId)
          .get();

      if (!chatDoc.exists) {
        debugPrint('Chat document does not exist');
        return;
      }

      final data = chatDoc.data()!;
      final List<dynamic> userIds = data['users'] ?? [];

      personId = userIds.firstWhere((id) => id != myUserId, orElse: () => '');

      if (personId.isNotEmpty) {
        var onlineStatusData = await getOnlineStatus(personId);
        if (mounted) {
          setState(() {
            name = onlineStatusData['name'] ?? 'Unknown';
            img = onlineStatusData['img'] ?? '';
            status = onlineStatusData['status'] ?? 'offline';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching chat details: $e');
    }
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
      final img = (profileImages?.isNotEmpty ?? false) ? profileImages![0] : "";
      final name = userData['name'] ?? "Unknown";

      final userStatusRef =
          FirebaseDatabase.instance.ref('users/$friendUid/status');
      final statusSnapshot = await userStatusRef.get();

      return {
        'id': friendUid,
        'img': img,
        'name': name,
        'status': statusSnapshot.value ?? 'offline',
      };
    } catch (e) {
      debugPrint('Error fetching online status: $e');
      return {'status': 'offline'};
    }
  }

  String getDateDividerText(DateTime messageDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDay =
        DateTime(messageDate.year, messageDate.month, messageDate.day);

    if (messageDay == today) {
      return "Today";
    } else if (messageDay == yesterday) {
      return "Yesterday";
    } else {
      return "${messageDate.day} ${_getMonthName(messageDate.month)} ${messageDate.year}";
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildDateDivider(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.transparent,
              thickness: 1,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.transparent,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/QAbg.png'),  // Or NetworkImage() for remote images
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,  // Make scaffold transparent to show background
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: _chatMessageStream == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMessageList(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(

      elevation: 1,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          if (img.isNotEmpty)
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(img),
              onBackgroundImageError: (_, __) {
                setState(() => img = '');
              },
            ),
          if (img.isEmpty)
            const CircleAvatar(
              radius: 25,
              child: Icon(Icons.person),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status == 'online' ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: status == 'online' ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatMessageStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No messages yet'));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        String? currentDate;
        List<Widget> messageWidgets = [];

        for (var doc in snapshot.data!.docs) {
          var message = doc;
          int timestamp = (message['time'] / 1000)
              .round(); // Convert microseconds to milliseconds
          DateTime messageDateTime =
              DateTime.fromMillisecondsSinceEpoch(timestamp);
          String messageDate = getDateDividerText(messageDateTime);

          if (currentDate != messageDate) {
            messageWidgets.add(_buildDateDivider(messageDate));
            currentDate = messageDate;
          }

          String sentBy = message['sentBy'];
          bool isSentByMe = sentBy == myUserId;

          messageWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChatBubble(
                alignment:
                    isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                backGroundColor:
                    isSentByMe ? Colors.pinkAccent : Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 4),
                clipper: ChatBubbleClipper3(
                  type: isSentByMe
                      ? BubbleType.sendBubble
                      : BubbleType.receiverBubble,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['message'] ?? '',
                        style: TextStyle(
                          color: isSentByMe ? Colors.white : Colors.pink,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatTime((message['time'] / 1000).round()),
                        // Convert microseconds to milliseconds
                        style: TextStyle(
                          color: isSentByMe ? Colors.white70 : Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          children: messageWidgets,
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        // boxShadow: [
        //   BoxShadow(
        //     offset: const Offset(0, -2),
        //     blurRadius: 6,
        //     color: Colors.black.withOpacity(0.06),
        //   ),
        // ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.pinkAccent, // Change to your desired border color
                    width: 1, // Adjust the width as needed
                  ),
                ),
                child: TextField(
                  focusNode: _focusNode,
                  controller: chatMessageController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.pinkAccent),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() => _send = value.isNotEmpty);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _send ? Colors.pinkAccent : Colors.grey.shade400,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _send ? Colors.pinkAccent : Colors.pink.shade200, // Border color
                  width: 1, // Adjust border width
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                    color: (_send ? Colors.pink : Colors.grey).withOpacity(0.4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _send ? sendMessage : null,
              ),
            ),

          ],
        ),
      ),
    );
  }

  void _onFocusChange() {
    setState(() => _isKeyboardOpen = _focusNode.hasFocus);
  }

  Future<void> sendMessage() async {
    if (chatMessageController.text.isEmpty) return;

    NotificationPage notificationPage = NotificationPage();

    final message = chatMessageController.text.trim();
    chatMessageController.clear();
    setState(() => _send = false);

    try {
      int timestamp = Timestamp.now().microsecondsSinceEpoch;

      await FirebaseFirestore.instance
          .collection("Chats")
          .doc(widget.chatRoomId)
          .collection("chats")
          .add({
        "message": message,
        "sentBy": myUserId,
        "time": timestamp,
      });

      await FirebaseFirestore.instance
          .collection("Chats")
          .doc(widget.chatRoomId)
          .update({
        'lastChat': message,
        'lastChatTime': timestamp,
        'UnreadMsg.$personId': FieldValue.increment(1),
      });

      notificationPage.sendNotification(
          "${MyData_Class.MyMapData["name"]} sent you a message",
          message.toString(),
          "https://firebasestorage.googleapis.com/v0/b/nikahblessingapp-org.appspot.com/o/chat.png?alt=media&token=9497fad0-d5f1-4219-b47a-ec96e0d20116",
          personId);

      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void makeMessagesRead() async {
    try {
      await FirebaseFirestore.instance
          .collection("Chats")
          .doc(widget.chatRoomId)
          .update({
        'UnreadMsg.$myUserId': 0,
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String formatTime(int timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
            ? 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    chatMessageController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
