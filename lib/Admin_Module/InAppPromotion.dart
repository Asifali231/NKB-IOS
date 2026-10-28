import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class InAppPromotion extends StatefulWidget {
  const InAppPromotion({super.key});

  @override
  _InAppPromotionState createState() => _InAppPromotionState();
}

class _InAppPromotionState extends State<InAppPromotion>
    with TickerProviderStateMixin {
  String? url1;
  String? url2;
  String? url3;

  bool isLoading = false;
  Map<String, bool> uploadingStates = {
    'url1': false,
    'url2': false,
    'url3': false,
  };

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    fetchCurrentUrls();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> fetchCurrentUrls() async {
    setState(() => isLoading = true);

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('InAppPromotion')
          .doc('imgs')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          url1 = data['url1'];
          url2 = data['url2'];
          url3 = data['url3'];
        });
      }
    } catch (e) {
      _showSnackBar('Failed to fetch current images: ${e.toString()}', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> uploadImage(String field) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => uploadingStates[field] = true);

      File file = File(pickedFile.path);
      String fileName = '${field}_${DateTime.now().millisecondsSinceEpoch}';
      Reference storageRef = FirebaseStorage.instance.ref().child('promotions/$fileName');

      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('InAppPromotion')
          .doc('imgs')
          .set(
        {field: downloadUrl},
        SetOptions(merge: true),
      );

      setState(() {
        switch (field) {
          case 'url1':
            url1 = downloadUrl;
            break;
          case 'url2':
            url2 = downloadUrl;
            break;
          case 'url3':
            url3 = downloadUrl;
            break;
        }
      });

      _showSnackBar('Image uploaded successfully!');
    } catch (e) {
      _showSnackBar('Failed to upload image: ${e.toString()}', isError: true);
    } finally {
      setState(() => uploadingStates[field] = false);
    }
  }

  Future<void> deleteImage(String field, String? imageUrl) async {
    if (imageUrl == null) return;

    // Show confirmation dialog
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Confirm Delete'),
            ],
          ),
          content: const Text('Are you sure you want to delete this image? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() => uploadingStates[field] = true);

    try {
      // Delete from Storage
      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();

      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('InAppPromotion')
          .doc('imgs')
          .update({field: FieldValue.delete()});

      setState(() {
        switch (field) {
          case 'url1':
            url1 = null;
            break;
          case 'url2':
            url2 = null;
            break;
          case 'url3':
            url3 = null;
            break;
        }
      });

      _showSnackBar('Image deleted successfully!');
    } catch (e) {
      _showSnackBar('Failed to delete image: ${e.toString()}', isError: true);
    } finally {
      setState(() => uploadingStates[field] = false);
    }
  }

  Widget _buildImageCard(String field, String? imageUrl, String displayName) {
    bool isUploading = uploadingStates[field] ?? false;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 8,
            shadowColor: Colors.blue.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.purple.shade400],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (imageUrl != null && !isUploading)
                          IconButton(
                            onPressed: () => deleteImage(field, imageUrl),
                            icon: const Icon(Icons.delete_outline),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red.shade700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isUploading)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey.shade100,
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Uploading...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.grey.shade100,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.red.shade50,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        color: Colors.red.shade400, size: 40),
                                    const SizedBox(height: 8),
                                    Text('Failed to load image',
                                        style: TextStyle(color: Colors.red.shade600)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          color: Colors.grey.shade50,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 50, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('No image uploaded',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isUploading ? null : () => uploadImage(field),
                        icon: isUploading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.cloud_upload_outlined),
                        label: Text(isUploading ? 'Uploading...' : 'Upload Image'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Promotion Manager',
          style: TextStyle(fontWeight: FontWeight.bold ,color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: fetchCurrentUrls,
            icon: const Icon(Icons.refresh,color: Colors.white,),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Loading promotions...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload up to 3 promotional images. Recommended size: 1920x1080px',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildImageCard('url1', url1, 'Promotion 1'),
              const SizedBox(height: 20),

              _buildImageCard('url2', url2, 'Promotion 2'),
              const SizedBox(height: 20),

              _buildImageCard('url3', url3, 'Promotion 3'),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}