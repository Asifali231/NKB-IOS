import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:nikah_blessing/Make_Profile/profile_media_upload_service.dart';

class Profile_Pictures_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  const Profile_Pictures_Page({
    super.key,
    required this.navigateToNextPage,
    required this.navigateToPrevPage,
  });

  @override
  State<Profile_Pictures_Page> createState() => _Profile_Pictures_PageState();
}

class _Profile_Pictures_PageState extends State<Profile_Pictures_Page> {
  static List<String> imagesPath = List.filled(5, '');
  static String _sharewith = '';

  final ImagePicker _picker = ImagePicker();
  late List<String> _uploadedImageUrls;
  late List<bool> _uploadingSlots;
  String imageError = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusManager.instance.primaryFocus?.unfocus();
    });
    final existingUploaded =
        List<String>.from(UserData.UploadedProfileImageUrls);
    if (existingUploaded.length < 5) {
      existingUploaded.addAll(List.filled(5 - existingUploaded.length, ''));
    }
    _uploadedImageUrls = existingUploaded.take(5).toList();
    _uploadingSlots = List<bool>.filled(5, false);

    if (UserData.ProfileImgs.isNotEmpty) {
      final existingLocal = List<String>.from(UserData.ProfileImgs);
      if (existingLocal.length < 5) {
        existingLocal.addAll(List.filled(5 - existingLocal.length, ''));
      }
      imagesPath = existingLocal.take(5).toList();
    }

    if (UserData.ProfileImgsShareWith.isNotEmpty) {
      _sharewith = UserData.ProfileImgsShareWith;
    }
  }

  bool get _hasPendingUploads =>
      _uploadingSlots.any((isUploading) => isUploading);

  void _syncUserMedia() {
    UserData.ProfileImgs = List<String>.from(imagesPath);
    UserData.UploadedProfileImageUrls = List<String>.from(_uploadedImageUrls);
    UserData.ProfileImgsShareWith = _sharewith;
  }

  Future<void> _pickAndUploadImage(int index) async {
    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    } on PlatformException catch (error) {
      if (!mounted) return;
      final permissionDenied = error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('restricted');
      setState(() {
        imageError = permissionDenied
            ? 'Photo access is disabled. Allow Photos access in Settings and try again.'
            : 'Could not open your photos. Please try again.';
      });
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() => imageError = 'Could not open your photos: $error');
      return;
    }
    final imageFile = pickedFile;
    if (imageFile == null) return;

    final previousUrl = _uploadedImageUrls[index];
    setState(() {
      imageError = '';
      imagesPath[index] = imageFile.path;
      _uploadedImageUrls[index] = '';
      _uploadingSlots[index] = true;
    });
    _syncUserMedia();

    try {
      if (previousUrl.isNotEmpty) {
        await ProfileMediaUploadService.deleteUploadedFile(previousUrl);
      }
      final uploadedUrl = await ProfileMediaUploadService.uploadImageFile(
        file: File(imageFile.path),
        folderName: 'ProfileImages',
        slotId: 'profile_${index}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;
      setState(() {
        _uploadedImageUrls[index] = uploadedUrl;
        _uploadingSlots[index] = false;
      });
      _syncUserMedia();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        imagesPath[index] = '';
        _uploadedImageUrls[index] = '';
        _uploadingSlots[index] = false;
        imageError = 'Image upload failed. Please try again.';
      });
      _syncUserMedia();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to upload image ${index + 1}: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeImage(int index) async {
    final uploadedUrl = _uploadedImageUrls[index];

    setState(() {
      imagesPath[index] = '';
      _uploadedImageUrls[index] = '';
      _uploadingSlots[index] = false;
      imageError = '';
    });
    _syncUserMedia();

    if (uploadedUrl.isNotEmpty) {
      await ProfileMediaUploadService.deleteUploadedFile(uploadedUrl);
    }
  }

  void validateAndNavigate() {
    setState(() {
      imageError = '';
    });

    if (_uploadedImageUrls[0].isEmpty) {
      setState(() {
        imageError = 'Please upload and wait for your cover image first.';
      });
      return;
    }

    if (_hasPendingUploads) {
      setState(() {
        imageError = 'Please wait until your images finish uploading.';
      });
      return;
    }

    final selectedImageCount =
        _uploadedImageUrls.where((url) => url.isNotEmpty).length;

    if (selectedImageCount >= 3) {
      _syncUserMedia();
      widget.navigateToNextPage();
    } else {
      setState(() {
        imageError = 'Please upload at least 3 pictures';
      });
    }
  }

  Widget _buildImageTile(int index) {
    final hasImage = imagesPath[index].isNotEmpty;
    final isUploading = _uploadingSlots[index];
    final isUploaded = _uploadedImageUrls[index].isNotEmpty;

    return DottedBorder(
      color: Colors.black,
      strokeWidth: 1,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(imagesPath[index]),
                  fit: BoxFit.cover,
                ),
                if (index == 0)
                  Positioned(
                    top: 3,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const Text(
                        'Cover Image',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isUploading)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                        backgroundColor: Colors.black45,
                      ),
                    ),
                  ),
                if (isUploaded && !isUploading)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
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
                  bottom: 2,
                  right: 2,
                  child: Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        CupertinoIcons.delete,
                        color: Colors.white,
                        size: 15,
                      ),
                      onPressed: isUploading ? null : () => _removeImage(index),
                    ),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: () => _pickAndUploadImage(index),
              child: Stack(
                children: [
                  if (index == 0)
                    Positioned(
                      top: 3,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: const Text(
                          'Cover Image',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const Center(
                    child: Icon(
                      Icons.add_a_photo_sharp,
                      color: Colors.grey,
                      size: 60,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  bool get _canContinue =>
      _uploadedImageUrls[0].isNotEmpty && !_hasPendingUploads;

  @override
  Widget build(BuildContext context) {
    final uploadedCount =
        _uploadedImageUrls.where((url) => url.isNotEmpty).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Let's make your profile charming \nwith your beautiful clicks!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _hasPendingUploads
                    ? 'Uploading your images in the background...'
                    : _uploadedImageUrls[0].isEmpty
                        ? 'Upload your cover image and at least 2 more pictures'
                        : 'Please upload at least 3 pictures',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.5,
                  color: _hasPendingUploads
                      ? const Color(0xFF5E35B1)
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
                      Icons.cloud_done_outlined,
                      color: Color(0xFF5E35B1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$uploadedCount of 5 images uploaded',
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
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(5, _buildImageTile),
              ),
              const SizedBox(height: 5),
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blueGrey,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We respect your hijab and let you control who can view your pictures',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Share this info with',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Radio<String>(
                          value: '1',
                          groupValue: _sharewith,
                          onChanged: (String? value) {
                            setState(() {
                              _sharewith = value ?? '';
                            });
                            _syncUserMedia();
                          },
                        ),
                        const Flexible(child: Text('Only with friends')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Radio<String>(
                          value: '3',
                          groupValue: _sharewith,
                          onChanged: (String? value) {
                            setState(() {
                              _sharewith = value ?? '';
                            });
                            _syncUserMedia();
                          },
                        ),
                        const Flexible(child: Text('With everyone')),
                      ],
                    ),
                  ),
                ],
              ),
              if (imageError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  imageError,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 45,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue ? validateAndNavigate : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    disabledForegroundColor: Colors.black38,
                    disabledBackgroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.black54),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
