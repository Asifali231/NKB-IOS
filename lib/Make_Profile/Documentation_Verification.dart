import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:nikah_blessing/Make_Profile/profile_media_upload_service.dart';

import '../cameraImagePicker_widget.dart';

class Documentation_Verification extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  const Documentation_Verification({
    super.key,
    required this.navigateToNextPage,
    required this.navigateToPrevPage,
  });

  @override
  State<Documentation_Verification> createState() =>
      _Documentation_VerificationState();
}

class _Documentation_VerificationState
    extends State<Documentation_Verification> {
  String _errorMessage = '';
  List<String> imagesPath = [];
  List<String> uploadedDocumentUrls = [];
  int _pendingUploads = 0;

  @override
  void initState() {
    super.initState();
    imagesPath = List<String>.from(UserData.DocumentImgs);
    uploadedDocumentUrls =
        List<String>.from(UserData.UploadedDocumentImageUrls);
  }

  bool get _isUploadingDocuments => _pendingUploads > 0;

  void _syncUserData() {
    UserData.DocumentImgs = List<String>.from(imagesPath);
    UserData.UploadedDocumentImageUrls =
        List<String>.from(uploadedDocumentUrls);
  }

  Future<void> _addDocuments(List<String> selectedImagePaths) async {
    final newPaths = selectedImagePaths
        .where((path) => path.isNotEmpty && !imagesPath.contains(path))
        .toList();

    if (newPaths.isEmpty) return;

    setState(() {
      _errorMessage = '';
      imagesPath.addAll(newPaths);
      uploadedDocumentUrls.addAll(List<String>.filled(newPaths.length, ''));
      _pendingUploads += newPaths.length;
    });
    _syncUserData();

    for (final path in newPaths) {
      final index = imagesPath.indexOf(path);
      if (index == -1) {
        setState(() {
          _pendingUploads = (_pendingUploads - 1).clamp(0, 999);
        });
        continue;
      }

      try {
        final url = await ProfileMediaUploadService.uploadImageFile(
          file: File(path),
          folderName: 'DocumentImages',
          slotId: 'document_${index}_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (!mounted) return;
        setState(() {
          uploadedDocumentUrls[index] = url;
          _pendingUploads = (_pendingUploads - 1).clamp(0, 999);
        });
        _syncUserData();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          if (index < imagesPath.length) {
            imagesPath.removeAt(index);
          }
          if (index < uploadedDocumentUrls.length) {
            uploadedDocumentUrls.removeAt(index);
          }
          _pendingUploads = (_pendingUploads - 1).clamp(0, 999);
          _errorMessage = 'Document upload failed. Please try again.';
        });
        _syncUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to upload document: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _removeDocument(int index) async {
    final uploadedUrl =
        index < uploadedDocumentUrls.length ? uploadedDocumentUrls[index] : '';

    setState(() {
      if (index < imagesPath.length) {
        imagesPath.removeAt(index);
      }
      if (index < uploadedDocumentUrls.length) {
        uploadedDocumentUrls.removeAt(index);
      }
      _errorMessage = '';
    });
    _syncUserData();

    if (uploadedUrl.isNotEmpty) {
      await ProfileMediaUploadService.deleteUploadedFile(uploadedUrl);
    }
  }

  void validateAndNavigate() {
    setState(() {
      _errorMessage = '';
    });

    if (_isUploadingDocuments) {
      setState(() {
        _errorMessage = 'Please wait until your documents finish uploading.';
      });
      return;
    }

    if (uploadedDocumentUrls.where((url) => url.trim().isNotEmpty).isEmpty) {
      setState(() {
        _errorMessage = 'Please upload your document';
      });
      return;
    }

    _syncUserData();
    widget.navigateToNextPage();
  }

  @override
  Widget build(BuildContext context) {
    final uploadedDocumentCount =
        uploadedDocumentUrls.where((url) => url.trim().isNotEmpty).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(right: 20, left: 20, top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 68),
              const Text(
                'Stand Out Your Profile By Uploading All Required Documents',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isUploadingDocuments
                    ? 'Uploading your documents in the background...'
                    : 'Please upload your identification card/Driving License/Passport',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1.5,
                  letterSpacing: 0,
                  color: _isUploadingDocuments ? const Color(0xFF5E35B1) : null,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F1FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF8E5CE6).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF5E35B1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$uploadedDocumentCount document(s) uploaded',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF45227A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 225,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: imagesPath.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imagesPath.length,
                        itemBuilder: (BuildContext context, int index) {
                          final isUploaded =
                              index < uploadedDocumentUrls.length &&
                                  uploadedDocumentUrls[index].isNotEmpty;

                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: Stack(
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  color: Colors.pink.shade50,
                                  elevation: 5,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Stack(
                                      children: [
                                        Image.file(
                                          File(imagesPath[index]),
                                          width: 260,
                                          height: 260,
                                          fit: BoxFit.cover,
                                        ),
                                        if (!isUploaded)
                                          Container(
                                            width: 260,
                                            height: 260,
                                            color: Colors.black38,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isUploaded)
                                  Positioned(
                                    left: 14,
                                    top: 14,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1B8F5A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: -10,
                                  top: -10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        CupertinoIcons.clear_circled_solid,
                                        color: Colors.pink,
                                        size: 22,
                                      ),
                                      onPressed: _isUploadingDocuments
                                          ? null
                                          : () => _removeDocument(index),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.transparent,
                        child: Image.asset(
                          'assets/Id_doc.png',
                          height: 580,
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
              ),
              const SizedBox(height: 25),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return cameraImagePicker_widget(
                        onSaveImagePath: (selectedImagePath) {
                          _addDocuments(selectedImagePath);
                        },
                      );
                    },
                  );
                },
                child: Container(
                  height: 35,
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: Colors.white54,
                    border: Border.all(color: Colors.pink),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.camera, color: Colors.pink),
                      SizedBox(width: 5),
                      Text(
                        'Upload Images',
                        style: TextStyle(color: Colors.pink),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blueGrey,
                      size: 16.0,
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Please upload your documents to complete the authentication process and help us ensure a secure and scam-free experience. \n\nWe got female staff for female profiles and vice versa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.blueGrey,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: InkWell(
          onTap: validateAndNavigate,
          child: Container(
            height: 45,
            width: MediaQuery.of(context).size.width - 40,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Colors.pink,
            ),
            child: const Center(
              child: Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
