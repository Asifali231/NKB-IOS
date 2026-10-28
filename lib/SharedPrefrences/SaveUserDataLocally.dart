import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaveUserDataLocally {

  Future<void> saveData(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Convert Timestamp to a serializable format
    Map<String, dynamic> serializableData = _convertTimestamps(data);

    String jsonString = json.encode(serializableData); // Convert map to JSON string
    await prefs.setString('myMapData', jsonString);
    print("Data saved: $jsonString");
  }

  // Retrieve the Map from SharedPreferences
  Future<Map<String, dynamic>?> retrieveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('myMapData');

    if (jsonString != null) {
      Map<String, dynamic> data = json.decode(jsonString); // Convert JSON string back to Map
      print("Data retrieved: $data");

      return data;
    } else {
      print("Not found");
      return null;
    }
  }

  // Convert Firestore Timestamps to a serializable format
// Convert Firestore Timestamps to a serializable format
  Map<String, dynamic> _convertTimestamps(Map<dynamic, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key as String, value.toDate().toIso8601String()); // Convert to ISO string
      } else if (value is Map) {
        return MapEntry(key as String, _convertTimestamps(value as Map<dynamic, dynamic>)); // Recursively convert nested maps
      } else if (value is List) {
        // Handle lists by converting their elements if they are maps
        List<dynamic> convertedList = value.map((item) {
          if (item is Map) {
            return _convertTimestamps(item as Map<dynamic, dynamic>);
          }
          return item; // Leave other types as is
        }).toList();
        return MapEntry(key as String, convertedList);
      }
      return MapEntry(key as String, value); // Leave other types as is
    });
  }


  // Get the current userId from Firebase Authentication
  Future<String?> getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("User ID: ${user.uid}");
      return user.uid;  // Return the current user's UID
    } else {
      print("No user signed in");
      return null;  // Return null if no user is signed in
    }
  }

  // Retrieve data from Firestore for the current user
  Future<Map<String, dynamic>?> getUserDataFromFirestoreAndSave() async {
    String? userId = await getCurrentUserId();

    if (userId != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          print("User data from Firestore: $userData");
          saveData(userData);
          return userData;  // Return the user data from Firestore
        } else {
          print("User data not found in Firestore");
          return null;  // Return null if no data found
        }
      } catch (e) {
        print("Error getting user data from Firestore: $e");
        return null;  // Return null if there's an error
      }
    } else {
      print("No user ID available");
      return null;  // Return null if no user is signed in
    }
  }

}
