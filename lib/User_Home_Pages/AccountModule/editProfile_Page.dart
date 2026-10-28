import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final Map<String, TextEditingController> _controllers = {};
  
  final List<String> _fields = [
    'name', 'PhoneNumber', 'FindingFor', 'Gender',
    'NationalityCountry', 'NationalityCity', 'NationalityState',
    'AbroadCountry', 'AbroadCity', 'AbroadState', 'Residence', 'ResidenceDis',
    'Ethnicity', 'Tribe', 'FamilyDescription',
    'Religion', 'Sect',
    'Height', 'Weight', 'skinTone', 'BodyType',
    'Degree', 'Field', 'EducationDescription',
    'Profession', 'JobCountry', 'JobTitle', 'JobDesc', 'Income',
    'MartialStatus', 'HasChildren', 'NoOfChildren',
    'Disability', 'DisabilityDes'
  ];

  bool _isLoading = false;
  bool _isFetchingData = true;
  String _currentVerificationStatus = 'UnVerified';
  String? _jobCountry;
  String? _gender;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    for (var field in _fields) {
      _controllers[field] = TextEditingController();
    }
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isFetchingData = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          for (var field in _fields) {
            _controllers[field]?.text = (userData[field] ?? userData[field == 'EducationDescription' ? 'EducationDiscription' : ''] ?? '').toString();
          }
          _currentVerificationStatus =
              (userData['VerificationStatus'] ?? 'UnVerified').toString();
          _jobCountry = userData['JobCountry']?.toString();
          _gender = userData['Gender']?.toString();
        });
      }
    } catch (e) {
    } finally {
      setState(() {
        _isFetchingData = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final resubmittingRejectedProfile =
          _currentVerificationStatus.toLowerCase() == 'rejected';

      final Map<String, dynamic> updatedData = {};
      for (var field in _fields) {
        updatedData[field] = _controllers[field]?.text.trim() ?? '';
      }
      
      // Keep backward compatibility for education desc
      updatedData['EducationDiscription'] = updatedData['EducationDescription'];

      if (resubmittingRejectedProfile) updatedData['VerificationStatus'] = 'UnVerified';

      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(currentUser.uid);
      batch.update(userRef, updatedData);

      if (_jobCountry != null && _jobCountry!.isNotEmpty &&
          _gender != null && _gender!.isNotEmpty) {
        final proposalRef = _firestore
            .collection('proposals')
            .doc(_jobCountry)
            .collection(_gender!)
            .doc(currentUser.uid);
        batch.update(proposalRef, updatedData);
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resubmittingRejectedProfile
                ? 'Profile updated and sent back for review.'
                : 'Profile updated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text('Failed to update profile: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5E35B1),
            ),
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }

  Widget _buildTextField(String fieldKey, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[fieldKey],
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF5E35B1)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: Color(0xFF5E35B1), width: 1.4),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFFF8F5FF),
        foregroundColor: const Color(0xFF5E35B1),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8F5FF), Colors.white],
              ),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF5E35B1).withOpacity(0.95),
                          const Color(0xFF8E5CE6).withOpacity(0.92),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5E35B1).withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keep your profile fresh',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentVerificationStatus.toLowerCase() == 'rejected'
                              ? 'Update your details and we will send your profile back for review.'
                              : 'Update the key details your matches and reviewers will see.',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSection(context, 'Personal Details', [
                    _buildTextField('name', 'Name', Icons.person_outline),
                    _buildTextField('PhoneNumber', 'Phone Number', Icons.phone_outlined),
                    _buildTextField('FindingFor', 'Finding For', Icons.search),
                    _buildTextField('Gender', 'Gender', Icons.transgender),
                  ]),
                  _buildSection(context, 'Location', [
                    _buildTextField('NationalityCountry', 'Nationality Country', Icons.flag),
                    _buildTextField('NationalityCity', 'Nationality City', Icons.location_city),
                    _buildTextField('NationalityState', 'Nationality State', Icons.map),
                    _buildTextField('AbroadCountry', 'Abroad Country', Icons.flight),
                    _buildTextField('AbroadCity', 'Abroad City', Icons.flight_takeoff),
                    _buildTextField('AbroadState', 'Abroad State', Icons.flight_land),
                    _buildTextField('Residence', 'Residence', Icons.home),
                    _buildTextField('ResidenceDis', 'Residence Description', Icons.home_outlined, maxLines: 3),
                  ]),
                  _buildSection(context, 'Family & Ethnicity', [
                    _buildTextField('Ethnicity', 'Ethnicity', Icons.people),
                    _buildTextField('Tribe', 'Tribe', Icons.group),
                    _buildTextField('FamilyDescription', 'Family Description', Icons.family_restroom, maxLines: 3),
                  ]),
                  _buildSection(context, 'Religion', [
                    _buildTextField('Religion', 'Religion', Icons.mosque),
                    _buildTextField('Sect', 'Sect', Icons.group_work),
                  ]),
                  _buildSection(context, 'Physical Attributes', [
                    _buildTextField('Height', 'Height', Icons.height),
                    _buildTextField('Weight', 'Weight', Icons.monitor_weight),
                    _buildTextField('skinTone', 'Skin Tone', Icons.face),
                    _buildTextField('BodyType', 'Body Type', Icons.accessibility),
                  ]),
                  _buildSection(context, 'Education & Profession', [
                    _buildTextField('Degree', 'Degree', Icons.school),
                    _buildTextField('Field', 'Field', Icons.book),
                    _buildTextField('EducationDescription', 'Education Description', Icons.school_outlined, maxLines: 3),
                    _buildTextField('Profession', 'Profession', Icons.work),
                    _buildTextField('JobCountry', 'Job Country', Icons.public),
                    _buildTextField('JobTitle', 'Job Title', Icons.badge),
                    _buildTextField('JobDesc', 'Job Description', Icons.work_outline, maxLines: 3),
                    _buildTextField('Income', 'Income', Icons.attach_money),
                  ]),
                  _buildSection(context, 'Marital Status', [
                    _buildTextField('MartialStatus', 'Marital Status', Icons.favorite),
                    _buildTextField('HasChildren', 'Has Children', Icons.child_care),
                    _buildTextField('NoOfChildren', 'Number of Children', Icons.format_list_numbered),
                  ]),
                  _buildSection(context, 'Disability', [
                    _buildTextField('Disability', 'Disability Status', Icons.accessible),
                    _buildTextField('DisabilityDes', 'Disability Description', Icons.accessible_forward, maxLines: 3),
                  ]),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_isLoading ? 'Updating...' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      backgroundColor: const Color(0xFF5E35B1),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isLoading || _isFetchingData)
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
