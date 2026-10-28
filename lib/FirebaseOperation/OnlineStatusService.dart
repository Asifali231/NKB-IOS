import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class OnlineStatusService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  void setOnlineStatus() async {
    User? user = _auth.currentUser;

    if (user != null) {
      String uid = user.uid;

      // Reference to the user's status in the database
      DatabaseReference userStatusRef = _db.child('users/$uid/status');

      // Create references for tracking connection state and last online time
      DatabaseReference connectedRef = _db.child('.info/connected');
      DatabaseReference lastOnlineRef = _db.child('users/$uid/lastOnline');

      // Listen to changes in connection state
      connectedRef.onValue.listen((event) {
        if (event.snapshot.value == true) {
          // User is online
          userStatusRef.set("online");

          // Ensure they go offline on disconnect
          userStatusRef.onDisconnect().set("offline");

          // Record the last online time when they disconnect
          lastOnlineRef.onDisconnect().set(ServerValue.timestamp);
        } else {
          // User is offline
          userStatusRef.set("offline");
        }
      });
    }
  }
}

