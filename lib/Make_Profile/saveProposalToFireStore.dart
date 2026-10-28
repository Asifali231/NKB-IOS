import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart'; // Ensure this is imported for 'BuildContext'
import 'package:nikah_blessing/SharedPrefrences/SaveUserDataLocally.dart';
import 'dart:io';
import 'package:quickalert/quickalert.dart'; // Ensure QuickAlert is imported

import '../DataClass/UserData.dart';
import '../User_Home_Pages/user_main.dart';

class saveProposalToFireStore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> uploadUserData(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final String userId = UserData.userID.isNotEmpty
        ? UserData.userID
        : (auth.currentUser?.uid ?? '');

    if (userId.isEmpty) {
      throw Exception('Unable to resolve user id for profile creation');
    }

    UserData.userID = userId;

    // Show loading alert
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: "Creating Profile",
      text: "Please wait for a while .....",
      barrierDismissible: false,
    );

    try {
      final documentImageUrls =
          await _resolveDocumentImageUrls(userId, context);
      final personalLiveImageUrl =
          await _resolvePersonalLiveImageUrl(userId, context);
      final profileImageUrls = await _resolveProfileImageUrls(userId, context);

      QuickAlert.show(
        context: context,
        type: QuickAlertType.loading,
        title: "Saving Data",
        text: "Please wait for a while .....",
        barrierDismissible: false,
      );

      String profileEmail = UserData.Email.trim();
      final authEmail = auth.currentUser?.email?.trim();
      if (authEmail != null &&
          authEmail.isNotEmpty &&
          (profileEmail.isEmpty ||
              profileEmail == 'Not Mentioned' ||
              profileEmail == 'null')) {
        profileEmail = authEmail;
        UserData.Email = authEmail;
      }

      // Prepare user data to upload to Firestore
      Map<String, dynamic> userDataMap = {
        'FindingFor': UserData.FindingFor,
        'Gender': UserData.Gender,

        // ------------------------------------------------

        'PhoneNumber': UserData.PhoneNumber,
        'name': UserData.Name,
        'email': profileEmail,
        'uid': userId,

        // ------------------------------------------------

        'Age': UserData.Age,
        'DateOfBirth': UserData.DateOfBirth,

        // ------------------------------------------------

        'NationalityCountry': UserData.NationalityCountry,
        'NationalityCity': UserData.NationalityCity,
        'NationalityState': UserData.NationalityState,

        'AbroadCountry': UserData.AbroadCountry,
        'AbroadCity': UserData.AbroadCity,
        'AbroadState': UserData.AbroadState,

        'Residence': UserData.Residence,
        'ResidenceDis': UserData.ResidenceDis,

        // ------------------------------------------------

        'MartialStatus': UserData.MartialStatus,
        'HasChildren': UserData.HasChilderen,
        'NoOfChildren': UserData.NoOfChilderens,
        'MartialStatusShare': UserData.MartialStatus,

        // ------------------------------------------------

        'Degree': UserData.Degree,
        'Field': UserData.Field,
        'EducationDescription': UserData.EducationDiscription,

        // ------------------------------------------------

        'Profession': UserData.Profession,
        'JobCountry': UserData.JobCountry,
        'JobTitle': UserData.JobTitle,
        'JobDesc': UserData.JobDesc,
        'Income': UserData.Income,

        // ------------------------------------------------
        'Ethnicity': UserData.Ethicity,
        'Tribe': UserData.Tribe,
        'FamilyDescription': UserData.FamilyDis,

        // ------------------------------------------------

        'Disability': UserData.Disability,
        'DisabilityDes': UserData.DisabilityDis,
        'DisabilityShare': UserData.DisabilityShareWith,

        // ------------------------------------------------

        'Religion': UserData.Religon,
        'Sect': UserData.Sect,

        // ------------------------------------------------

        'ProfileImageUrls': profileImageUrls,
        'ProfileImageShare': UserData.ProfileImgsShareWith,

        'DocumentImageUrls': documentImageUrls,
        'PersonalLiveImageUrl': personalLiveImageUrl,

        // ------------------------------------------------

        'Height': UserData.Height,
        'Weight': UserData.Weight,
        'skinTone': UserData.skinTone,
        'BodyType': UserData.bodyType,

        // ------------------------------------------------

        'Hobbies': UserData.hobbies,

        // ------------------------------------------------

        'PartnerMinAge ': UserData.partnerAgeMin,
        'PartnerMaxAge ': UserData.partnerAgeMax,
        'PartnerCountry ': UserData.partnerCountries,
        'PartnerSect ': UserData.partnerSect,

        'PartnerMartialStatus ': UserData.partnerMartialStatus,

        // ------------------------------------------------

        'ProposalCreatedOn':
            DateTime.now().toIso8601String(), // Current timestamp

        'VerificationStatus': "UnVerified",
        'PackageSubscribed': "Free",
        'ChatCredit': 1,
        'DailyProfiles': 5,
        'PackageExpiry': DateTime(2039, 12, 31)
            .toIso8601String(), // Expiry set to Dec 31, 2039
      };

      // Upload data to Firestore
      await _firestore
          .collection('proposals')
          .doc(UserData.JobCountry)
          .collection(UserData.Gender)
          .doc(userId)
          .set(userDataMap);
      await _firestore.collection('users').doc(userId).update(userDataMap);

      SaveUserDataLocally saveUserDataLocally = SaveUserDataLocally();
      await saveUserDataLocally.saveData(userDataMap);

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: "Profile Created",
        text: "You are good to go.",
        barrierDismissible: true,
        onConfirmBtnTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => UserMain()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        },
      );
    } catch (e) {
      //print('Error uploading user data: $e');

      // Dismiss loading alert and show error alert
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: "Error",
        text: "Error uploading user data: $e",
        barrierDismissible: true,
      );
    }
  }

  Future<List<String>> _uploadFilesToStorage(String userId, String folderName,
      List<String> filePaths, BuildContext context) async {
    List<String> downloadUrls = [];

    try {
      for (String filePath in filePaths) {
        if (filePath == "") {
        } else {
          File file = File(filePath);
          String downloadUrl =
              await _uploadFileToStorage(userId, folderName, file, context);
          downloadUrls.add(downloadUrl);
        }
      }
    } catch (e) {
      //print('Error uploading files to storage: $e');

      // Dismiss loading alert and show error alert
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: "Error",
        text: "Error uploading files to storage: $e",
        barrierDismissible: true,
      );
    }
    return downloadUrls;
  }

  Future<List<String>> _resolveProfileImageUrls(
      String userId, BuildContext context) async {
    final existingUrls =
        UserData.UploadedProfileImageUrls.where((url) => url.trim().isNotEmpty)
            .toList();

    if (existingUrls.isNotEmpty) {
      return existingUrls;
    }

    return _uploadFilesToStorage(
      userId,
      "ProfileImages",
      UserData.ProfileImgs,
      context,
    );
  }

  Future<List<String>> _resolveDocumentImageUrls(
      String userId, BuildContext context) async {
    final existingUrls =
        UserData.UploadedDocumentImageUrls.where((url) => url.trim().isNotEmpty)
            .toList();

    if (existingUrls.isNotEmpty) {
      return existingUrls;
    }

    return _uploadFilesToStorage(
      userId,
      "DocumentImages",
      UserData.DocumentImgs,
      context,
    );
  }

  Future<String> _resolvePersonalLiveImageUrl(
      String userId, BuildContext context) async {
    if (UserData.UploadedPersonalLiveImageUrl.trim().isNotEmpty) {
      return UserData.UploadedPersonalLiveImageUrl.trim();
    }

    final personalLiveImage = UserData.PersonalLiveImgUrl;
    if (personalLiveImage == null) {
      return '';
    }

    final uploadedUrl = await _uploadFileToStorage(
      userId,
      "LiveImage",
      personalLiveImage,
      context,
    );

    if (uploadedUrl.isNotEmpty) {
      UserData.UploadedPersonalLiveImageUrl = uploadedUrl;
    }
    return uploadedUrl;
  }

  Future<String> _uploadFileToStorage(
      String userId, String folderName, File file, BuildContext context) async {
    try {
      String fileName = file.path.split('/').last;
      Reference ref = _storage.ref().child('$userId/$folderName/$fileName');
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      //print('Error uploading file to storage: $e');

      // Dismiss loading alert and show error alert
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: "Error",
        text: "Error uploading file to storage: $e",
        barrierDismissible: true,
      );
      return ''; // Return an empty string if an error occurs
    }
  }
}
