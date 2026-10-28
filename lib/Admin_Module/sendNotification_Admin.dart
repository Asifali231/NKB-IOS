import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({Key? key}) : super(key: key);

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String? selectedCountry;
  String? selectedGender;
  String? selectedPackage;
  String? selectedVerificationStatus;

  final Map<String, String> activeFilters = {};
  bool isLoading = false;
  int estimatedUsers = 0;

  final List<String> countries = ['Pakistan', 'India', 'USA', 'UK', 'Canada'];
  final List<String> packages = ['Free', 'Premium', 'Pro'];
  final List<String> genders = ['Male', 'Female'];
  final List<String> verificationStatuses = ['Verified', 'UnVerified'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _updateEstimatedUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateEstimatedUsers() async {
    try {
      final firestore = FirebaseFirestore.instance;
      Query query = firestore.collection('users');

      // Apply filters to get count
      activeFilters.forEach((key, value) {
        switch (key) {
          case 'Country':
            query = query.where('NationalityCountry', isEqualTo: value);
            break;
          case 'Gender':
            query = query.where('Gender', isEqualTo: value);
            break;
          case 'Package':
            query = query.where('PackageSubscribed', isEqualTo: value);
            break;
          case 'Verification':
            query = query.where('VerificationStatus', isEqualTo: value);
            break;
        }
      });

      final querySnapshot = await query.limit(1000).get();
      setState(() {
        estimatedUsers = querySnapshot.docs.length;
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> sendNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      _showCustomSnackBar('Please fill in title and body', Colors.orange);
      return;
    }

    setState(() => isLoading = true);
    bool didShowSendingDialog = false;

    try {
      final firestore = FirebaseFirestore.instance;
      final callable =
          FirebaseFunctions.instance.httpsCallable('sendBulkNotification');
      Query query = firestore.collection('users');

      // Apply filters
      activeFilters.forEach((key, value) {
        switch (key) {
          case 'Country':
            query = query.where('NationalityCountry', isEqualTo: value);
            break;
          case 'Gender':
            query = query.where('Gender', isEqualTo: value);
            break;
          case 'Package':
            query = query.where('PackageSubscribed', isEqualTo: value);
            break;
          case 'Verification':
            query = query.where('VerificationStatus', isEqualTo: value);
            break;
        }
      });

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        _showCustomSnackBar(
            'No users found matching the selected filters', Colors.red);
        setState(() => isLoading = false);
        return;
      }

      _showSendingDialog();
      didShowSendingDialog = true;

      final response = await callable.call({
        'title': _titleController.text,
        'body': _bodyController.text,
        'imageUrl': _imageUrlController.text,
        'filters': Map<String, String>.from(activeFilters),
      });

      final result = Map<String, dynamic>.from(response.data ?? {});
      final matchedUsers = result['matchedUsers'] ?? 0;
      final usersWithTokens = result['usersWithTokens'] ?? 0;
      final successCount = result['successCount'] ?? 0;
      final failureCount = result['failureCount'] ?? 0;
      debugPrint(
        'Bulk notification summary - matched: $matchedUsers, tokens: $usersWithTokens, success: $successCount, failed: $failureCount',
      );

      _showCustomSnackBar('Notifications sent successfully! 🎉', Colors.green);

      _titleController.clear();
      _bodyController.clear();
      _imageUrlController.clear();
      setState(() {
        activeFilters.clear();
        selectedCountry = null;
        selectedGender = null;
        selectedPackage = null;
        selectedVerificationStatus = null;
        estimatedUsers = 0;
      });
    } catch (e) {
      _showCustomSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (didShowSendingDialog && mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      setState(() => isLoading = false);
    }
  }

  void _showCustomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.orange
                      ? Icons.warning
                      : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sending Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Processing matched users and sending in server-side batches...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: Chip(
        label: Text('$label: $value'),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        backgroundColor: Colors.blue.shade50,
        deleteIcon: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 14, color: Colors.red),
        ),
        onDeleted: () {
          setState(() {
            activeFilters.remove(label);
            switch (label) {
              case 'Country':
                selectedCountry = null;
                break;
              case 'Gender':
                selectedGender = null;
                break;
              case 'Package':
                selectedPackage = null;
                break;
              case 'Verification':
                selectedVerificationStatus = null;
                break;
            }
            _updateEstimatedUsers();
          });
        },
      ),
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Admin Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.purple.shade50,
              ],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with statistics
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade600,
                              Colors.purple.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Push Notification Center',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Estimated Recipients: $estimatedUsers users',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Filter Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.filter_alt,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Target Audience',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _buildModernDropdown(
                                  label: 'Country',
                                  value: selectedCountry,
                                  items: countries,
                                  icon: Icons.flag,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedCountry = value;
                                        activeFilters['Country'] = value;
                                        _updateEstimatedUsers();
                                      });
                                    }
                                  },
                                ),
                                _buildModernDropdown(
                                  label: 'Gender',
                                  value: selectedGender,
                                  items: genders,
                                  icon: Icons.person,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedGender = value;
                                        activeFilters['Gender'] = value;
                                        _updateEstimatedUsers();
                                      });
                                    }
                                  },
                                ),
                                _buildModernDropdown(
                                  label: 'Package',
                                  value: selectedPackage,
                                  items: packages,
                                  icon: Icons.card_membership,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedPackage = value;
                                        activeFilters['Package'] = value;
                                        _updateEstimatedUsers();
                                      });
                                    }
                                  },
                                ),
                                _buildModernDropdown(
                                  label: 'Verification',
                                  value: selectedVerificationStatus,
                                  items: verificationStatuses,
                                  icon: Icons.verified,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedVerificationStatus = value;
                                        activeFilters['Verification'] = value;
                                        _updateEstimatedUsers();
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            if (activeFilters.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Active Filters:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                children: activeFilters.entries
                                    .map(
                                        (e) => _buildFilterChip(e.key, e.value))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Notification Content Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Notification Content',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildModernTextField(
                              controller: _titleController,
                              label: 'Notification Title',
                              icon: Icons.title,
                              hint: 'Enter a compelling title...',
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _bodyController,
                              label: 'Notification Body',
                              icon: Icons.message,
                              maxLines: 4,
                              hint: 'Write your notification message...',
                            ),
                            const SizedBox(height: 16),
                            _buildModernTextField(
                              controller: _imageUrlController,
                              label: 'Image URL (Optional)',
                              icon: Icons.image,
                              hint: 'https://example.com/image.jpg',
                            ),
                            const SizedBox(height: 32),
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade600,
                                    Colors.purple.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : sendNotification,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Sending...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.rocket_launch,
                                              color: Colors.white),
                                          SizedBox(width: 12),
                                          Text(
                                            'Send Notification',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
