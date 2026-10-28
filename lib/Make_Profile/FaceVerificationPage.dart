import 'dart:io';

import 'package:face_camera/face_camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:nikah_blessing/Make_Profile/profile_media_upload_service.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceVerificationPage extends StatefulWidget {
  final VoidCallback navigateToNextPage;
  final VoidCallback navigateToPrevPage;

  const FaceVerificationPage({
    super.key,
    required this.navigateToNextPage,
    required this.navigateToPrevPage,
  });

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  File? _capturedImage;
  bool _isCaptured = false;
  bool _isUploadingImage = false;
  bool _isInitializingCamera = true;
  bool _showCameraSettingsButton = false;
  String _uploadedImageUrl = '';
  int _captureUploadToken = 0;
  String _customMessage = 'Center your face in the square';
  String _errorMessage = '';
  late FaceCameraController controller;

  void validateAndNavigate() {
    _errorMessage = '';

    if (!_isCaptured) {
      setState(() {
        _errorMessage = 'Please Capture Your Face For Verification';
      });
      return;
    }

    if (_isUploadingImage || _uploadedImageUrl.isEmpty) {
      setState(() {
        _errorMessage =
            'Please wait. Your verification image is still uploading.';
      });
      return;
    }

    setState(() {
      UserData.PersonalLiveImgUrl = _capturedImage!;
      UserData.UploadedPersonalLiveImageUrl = _uploadedImageUrl;
      widget.navigateToNextPage();
    });
  }

  @override
  void initState() {
    super.initState();
    _uploadedImageUrl = UserData.UploadedPersonalLiveImageUrl;
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      var cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        cameraStatus = await Permission.camera.request();
      }

      if (!cameraStatus.isGranted) {
        if (!mounted) return;
        setState(() {
          _isInitializingCamera = false;
          _showCameraSettingsButton = true;
          _errorMessage =
              'Camera permission is required for face verification.';
        });
        return;
      }

      await FaceCamera.initialize();
      if (!mounted) return;

      controller = FaceCameraController(
        autoCapture: true,
        enableAudio: false,
        imageResolution: ImageResolution.ultraHigh,
        performanceMode: FaceDetectorMode.fast,
        defaultCameraLens: CameraLens.front,
        onCapture: captured,
      );
      setState(() {
        _isInitializingCamera = false;
        _showCameraSettingsButton = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize face camera: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isInitializingCamera = false;
        _showCameraSettingsButton = false;
        _errorMessage =
            'Unable to start the camera. Check camera access and try again.';
      });
    }
  }

  Future<void> _openCameraSettings() async {
    final openedSettings = await openAppSettings();
    if (!openedSettings && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open app settings.')),
      );
    }
  }

  void _retryCameraInitialization() {
    setState(() {
      _isInitializingCamera = true;
      _showCameraSettingsButton = false;
      _errorMessage = '';
    });
    _initializeCamera();
  }

  Future<void> _retakeImage() async {
    final previousUrl = _uploadedImageUrl;
    _captureUploadToken++;

    setState(() {
      _capturedImage = null;
      _isCaptured = false;
      _isUploadingImage = false;
      _uploadedImageUrl = '';
      _errorMessage = '';
      _customMessage = 'Center your face in the square';
    });

    UserData.PersonalLiveImgUrl = null;
    UserData.UploadedPersonalLiveImageUrl = '';

    if (previousUrl.isNotEmpty) {
      await ProfileMediaUploadService.deleteUploadedFile(previousUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(right: 20, left: 20, top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 68),
              Text(
                '${UserData.Name}! We have a strict policy against fake profiles!',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                _isUploadingImage
                    ? 'Uploading your verification image securely...'
                    : 'Our AI Powered Camera will capture your face and verify it with your uploaded pictures.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.5,
                  letterSpacing: 0,
                  color: _isUploadingImage ? const Color(0xFF5E35B1) : null,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: _isCaptured
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.file(_capturedImage!, width: 300, height: 350),
                          if (_isUploadingImage)
                            Container(
                              width: 300,
                              height: 350,
                              color: Colors.black38,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      )
                    : SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 350,
                        child: _isInitializingCamera
                            ? const Center(child: CircularProgressIndicator())
                            : _errorMessage.isNotEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _errorMessage,
                                          textAlign: TextAlign.center,
                                        ),
                                        if (_showCameraSettingsButton)
                                          TextButton(
                                            onPressed: _openCameraSettings,
                                            child: const Text('Open Settings'),
                                          ),
                                        TextButton(
                                          onPressed: _retryCameraInitialization,
                                          child: const Text('Try Again'),
                                        ),
                                      ],
                                    ),
                                  )
                                : SmartFaceCamera(
                                    controller: controller,
                                    showControls: true,
                                    message: _customMessage,
                                  ),
                      ),
              ),
              const SizedBox(height: 14),
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
                    Icon(
                      _uploadedImageUrl.isNotEmpty
                          ? Icons.check_circle
                          : Icons.cloud_upload_outlined,
                      color: const Color(0xFF5E35B1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _uploadedImageUrl.isNotEmpty
                            ? 'Verification image uploaded'
                            : 'Verification image will upload as soon as it is captured',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF45227A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Disclaimer: This image will not be shown on profile and will be discarded after verification.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: InkWell(
                onTap: validateAndNavigate,
                child: Container(
                  height: 45,
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
            const SizedBox(width: 10),
            InkWell(
              onTap: _retakeImage,
              child: Container(
                height: 45,
                width: 110,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: Colors.transparent,
                  border: Border.all(color: Colors.pink),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.refresh_thick,
                      color: Colors.pink,
                    ),
                    Text(
                      'Retake',
                      style: TextStyle(
                        color: Colors.pink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> captured(File? image) async {
    if (image == null) {
      setState(() {
        _errorMessage = 'Failed to capture image. Please try again.';
      });
      return;
    }

    final previousUrl = _uploadedImageUrl;
    final uploadToken = ++_captureUploadToken;

    setState(() {
      _capturedImage = image;
      _isCaptured = true;
      _isUploadingImage = true;
      _errorMessage = '';
      _uploadedImageUrl = '';
    });

    try {
      final uploadedUrl = await ProfileMediaUploadService.uploadImageFile(
        file: image,
        folderName: 'LiveImage',
        slotId: 'live_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (uploadToken != _captureUploadToken) {
        await ProfileMediaUploadService.deleteUploadedFile(uploadedUrl);
        return;
      }

      if (previousUrl.isNotEmpty) {
        await ProfileMediaUploadService.deleteUploadedFile(previousUrl);
      }

      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = uploadedUrl;
        _isUploadingImage = false;
      });
      UserData.PersonalLiveImgUrl = image;
      UserData.UploadedPersonalLiveImageUrl = uploadedUrl;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingImage = false;
        _errorMessage =
            'Verification image upload failed. Please retake and try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to upload verification image: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
