import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nikah_blessing/DataClass/MyData_Class.dart';
import 'package:nikah_blessing/Notifications/NotificationPage.dart';

class FirebaseOperations

{


  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;




  // Get the current user's UID from Firebase Authentication
  String getCurrentUserId() {
    User? user = _auth.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  // Save proposal to the user's savedProposals array
  Future<bool> saveProposal(String proposalId) async

  {

    try {

      NotificationPage notificationPage = new NotificationPage();

      String userId = getCurrentUserId();
      await _firestore.collection('users').doc(userId).update({
        'savedProposals': FieldValue.arrayUnion([proposalId])
      });


      try {
        String userId = getCurrentUserId();
        await _firestore.collection('proposals').doc(MyData_Class.MyMapData["JobCountry"]).collection(MyData_Class.MyMapData["Gender"]).doc(userId).update({
          'savedProposals': FieldValue.arrayUnion([proposalId])


        });


        return true;
      } catch (e) {
        print("The errror ${userId}");
        print("The errror ${MyData_Class.MyMapData["Gender"]}");
        print("The errror ${MyData_Class.MyMapData["JobCountry"]}");
        print(e);
        return false;
      }

    } catch (e) {
      print("The errror ");
      print(e);
      return false;
    }


  }

  // Send a friend request (add to friendRequests array)
  Future<bool> sendFriendRequest(String friendId,String JobCountry,String Gender) async
  {
     NotificationPage notificationPage = new NotificationPage();

    try {


      print("FreindID is " + friendId);
      String userId = getCurrentUserId();
      await _firestore.collection('users').doc(friendId).update({
        'friendsRequests': FieldValue.arrayUnion([userId])
      });

      try {

        String userId = getCurrentUserId();


        await _firestore.collection('proposals').doc(JobCountry).collection(Gender).doc(friendId).update({
          'friendsRequests': FieldValue.arrayUnion([userId])
        });

        notificationPage.sendNotification("${MyData_Class.MyMapData["name"]}", "Sent you a friend request ", "imageUrl", friendId);

        return true;
      } catch (e) {

        print("Error While Sending Request");
        print(e);
        return false;
      }

    } catch (e) {
      print("Error While Sending Request");

      print(e);
      return false;
    }

  }

  // Block a user (add to blockedUsers array)
  Future<bool> blockUser(String blockedUserId) async {
    try {
      String userId = getCurrentUserId();
      await _firestore.collection('users').doc(userId).update({
        'blockUsers': FieldValue.arrayUnion([blockedUserId])
      });


      try {
        String userId = getCurrentUserId();
        await _firestore.collection('proposals').doc(MyData_Class.MyMapData["JobCountry"]).collection(MyData_Class.MyMapData["Gender"]).doc(userId).update({
          'blockUsers': FieldValue.arrayUnion([blockedUserId])
        });
        return true;
      } catch (e) {
        print(e);
        return false;
      }

    } catch (e) {
      print(e);
      return false;
    }
  }

  // Add a friend (add to friends array)
  Future<bool> addFriend(String friendId) async {
    try {

      NotificationPage notificationPage = new NotificationPage();


      String userId = getCurrentUserId();
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayUnion([friendId])
      });

      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayUnion([userId])
      });

      try {
        String userId = getCurrentUserId();

        await _firestore.collection('proposals').doc(MyData_Class.MyMapData["JobCountry"]).collection(MyData_Class.MyMapData["Gender"]).doc(userId).update({
          'friends': FieldValue.arrayUnion([friendId])
        });


        await _firestore.collection('proposals').doc(MyData_Class.MyMapData["JobCountry"]).collection(MyData_Class.MyMapData["Gender"]).doc(friendId).update({
          'friends': FieldValue.arrayUnion([userId])
        });



        notificationPage.sendNotification("${MyData_Class.MyMapData["name"]}", "Accepted your friend request ", MyData_Class.MyMapData["ProfileImageUrls"][0], friendId);

        return true;
      } catch (e) {
        print(e);
        return false;
      }



    } catch (e) {
      print(e);
      return false;
    }
  }

  // Remove a friend (remove from friends array)
  Future<bool> removeFriend(String friendId) async {
    try {
      String userId = getCurrentUserId();
      await _firestore.collection('users').doc(userId).update({
        'friends': FieldValue.arrayRemove([friendId])
      });

      try {
        String userId = getCurrentUserId();
        await _firestore.collection('proposals').doc(MyData_Class.MyMapData["JobCountry"]).collection(MyData_Class.MyMapData["Gender"]).doc(userId).update({
          'friends': FieldValue.arrayRemove([friendId])
        });
        return true;
      } catch (e) {
        print(e);
        return false;
      }



      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Remove a saved proposal (remove from savedProposals array)
  Future<bool> removeSavedProposal(String proposalId) async {
    try {
      String userId = getCurrentUserId();
      await _firestore.collection('users').doc(userId).update({
        'savedProposals': FieldValue.arrayRemove([proposalId])
      });


      try {
        String userId = getCurrentUserId();
        await _firestore.collection('proposals').doc(MyData_Class.MyMapData["JobCountry"]).collection(MyData_Class.MyMapData["Gender"]).doc(userId).update({
          'savedProposals': FieldValue.arrayRemove([proposalId])
        });
        return true;
      } catch (e) {
        print(e);
        return false;
      }


      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Remove a friend request (remove from friendRequests array)
  Future<bool> removeFriendRequest(String friendId) async {
    try {
      String userId = getCurrentUserId();
      await _firestore.collection('users').doc(userId).update({
        'friendRequests': FieldValue.arrayRemove([friendId])
      });

      try {
        String userId = getCurrentUserId();
        await _firestore.collection('proposals').doc(MyData_Class.MyMapData["JobCountry"]).collection(MyData_Class.MyMapData["Gender"]).doc(userId).update({
          'friendRequests': FieldValue.arrayRemove([friendId])
        });
        return true;
      } catch (e) {
        print(e);
        return false;
      }


      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Unblock a user (remove from blockedUsers array)
  Future<bool> unblockUser(String blockedUserId) async {
    try {
      String userId = getCurrentUserId();
      await _firestore.collection('users').doc(userId).update({
        'blockedUsers': FieldValue.arrayRemove([blockedUserId])
      });

      try {
        String userId = getCurrentUserId();
        await _firestore.collection('proposals').doc(MyData_Class.MyMapData["JobCountry"]).collection(MyData_Class.MyMapData["Gender"]).doc(userId).update({
          'blockedUsers': FieldValue.arrayRemove([blockedUserId])
        });
        return true;
      } catch (e) {
        print(e);
        return false;
      }


      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
