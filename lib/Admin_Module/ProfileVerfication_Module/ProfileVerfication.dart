// profile_verification_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nikah_blessing/Notifications/NotificationPage.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:quickalert/quickalert.dart';

class ProfileVerificationList extends StatefulWidget {
  @override
  _ProfileVerificationListState createState() => _ProfileVerificationListState();
}

class _ProfileVerificationListState extends State<ProfileVerificationList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Profile Verification',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone',
                prefixIcon: Icon(Icons.search, color: Colors.indigo),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('VerificationStatus', isEqualTo: 'UnVerified')

                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var profiles = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final searchString =
                  '${data['name'] ?? ''} ${data['email'] ?? ''} ${data['PhoneNumber'] ?? ''}'
                      .toLowerCase();
                  return searchString.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (context, index) {
                    final data = profiles[index].data() as Map<String, dynamic>;
                    return _buildProfileCard(data, profiles[index].reference);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> data, DocumentReference ref) {
    return Card(

      color: Colors.white,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),

      child: Column(
        children: [
          ListTile(

            contentPadding: EdgeInsets.all(8),

            leading: CircleAvatar(

              radius: 30,

              backgroundImage: data['ProfileImageUrls']?.isNotEmpty == true
                  ? NetworkImage(data['ProfileImageUrls'][0])
                  : null,

              child: data['ProfileImageUrls']?.isEmpty ?? true
                  ? Icon(Icons.person)
                  : null,
            ),
            title: Text(
              data['name'] ?? 'N/A',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(data['email'] ?? 'No email'),
                Text(data['PhoneNumber'] ?? 'No phone'),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileDetailPage(
                    profileData: data,
                    documentRef: ref,
                  ),
                ),
              );
            },
          ),
          Divider(),
        ],
      ),
    );
  }
}

// profile_detail_page.dart
class ProfileDetailPage extends StatefulWidget {

  final Map<String, dynamic> profileData;
  final DocumentReference documentRef;

  ProfileDetailPage({
    required this.profileData,
    required this.documentRef,
  });

  @override
  _ProfileDetailPageState createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  bool _isLoading = false;

  /// Finds the proposal doc and updates [VerificationStatus]. Returns true if updated.
  Future<bool> _syncProposalVerificationStatus(String status) async {
    final fs = FirebaseFirestore.instance;
    final uidRaw = widget.profileData['uid']?.toString() ?? '';
    final uid = uidRaw.isNotEmpty ? uidRaw : widget.documentRef.id;

    final jobCountry = (widget.profileData['JobCountry'] ?? widget.profileData['jobCountry'])?.toString() ?? '';
    final nationality = (widget.profileData['NationalityCountry'])?.toString() ?? '';
    final gender = (widget.profileData['Gender'] ?? widget.profileData['gender'])?.toString() ?? '';

    final countries = <String>[];
    if (jobCountry.isNotEmpty) countries.add(jobCountry);
    if (nationality.isNotEmpty && nationality != jobCountry) {
      countries.add(nationality);
    }

    final genders = <String>[];
    if (gender.isNotEmpty) {
      genders.add(gender);
      for (final og in ['Male', 'Female']) {
        if (og != gender) genders.add(og);
      }
    } else {
      genders.addAll(['Male', 'Female']);
    }

    if (countries.isEmpty) {
      print('Proposal sync skipped: no JobCountry / jobCountry / NationalityCountry on user');
      return false;
    }

    for (final c in countries) {
      for (final g in genders) {
        final ref = fs.collection('proposals').doc(c).collection(g).doc(uid);
        final snap = await ref.get();
        if (snap.exists) {
          await ref.update({'VerificationStatus': status});
          print('Updated proposal at proposals/$c/$g/$uid');
          return true;
        }
      }
    }
    print('No proposal document found for uid=$uid (tried countries=$countries, genders=$genders)');
    return false;
  }

  Future<void> _verifyProfile() async {
    try {
      setState(() => _isLoading = true);


      // Update both documents
      await widget.documentRef.update({'VerificationStatus': 'Verified'});

      print("Updated the user data");

      final proposalOk = await _syncProposalVerificationStatus('Verified');
      if (!proposalOk) {
        print("Proposal VerificationStatus not updated — path mismatch or missing doc");
      }

      NotificationPage notificationPage = new NotificationPage();
      notificationPage.sendNotification("Profile Verified", "Dear ${widget.profileData['name']}  your profile has been successfully verified ", "https://th.bing.com/th/id/OIP.odKDxcjwIWSoA4fLV3P1VQHaHa?rs=1&pid=ImgDetMain" ,widget.profileData["uid"] ?? widget.documentRef.id);

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: proposalOk
            ? 'Profile verified successfully!'
            : 'User record verified. No matching proposal document was found under proposals (check Job Country and Gender match how the profile was saved). Listing may stay out of sync until the proposal path is fixed.',
        onConfirmBtnTap: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      );
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Error verifying profile: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeProfile() async {
    try {
      setState(() => _isLoading = true);

      // Update both documents
      await widget.documentRef.update({'VerificationStatus': 'Rejected'});

      print("Updated the user data");

      final proposalOk = await _syncProposalVerificationStatus('Rejected');
      if (!proposalOk) {
        print("Proposal VerificationStatus not updated — path mismatch or missing doc");
      }

      NotificationPage notificationPage = new NotificationPage();
      notificationPage.sendNotification("Profile Verified", "Dear ${widget.profileData['name']}  your profile has been rejected ", "" ,widget.profileData["uid"] ?? widget.documentRef.id);

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: proposalOk
            ? 'Profile successfully rejected!'
            : 'User record updated. Proposal document was not found under the expected path.',
        onConfirmBtnTap: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      );
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Error verifying profile: $e',
      );


    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Details'),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageComparison(),
            SizedBox(height: 24),
            _buildProfileDetails(),
            SizedBox(height: 24),
            _buildDocImgView(),
            SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageComparison() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image Verification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile Images',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Container(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (widget.profileData['ProfileImageUrls']
                        as List<dynamic>?)
                            ?.length ??
                            0,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: GestureDetector(
                                onTap: ()
                                {
                                  _showFullScreenImage(
                                    context,
                                    widget.profileData['ProfileImageUrls'],
                                    index,
                                  );
                                },
                                child: Image.network(
                                  widget.profileData['ProfileImageUrls'][index],
                                  width: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Image',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    widget.profileData['PersonalLiveImageUrl'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GestureDetector(
                        onTap: ()
                        {

                          List<dynamic> imageList = widget.profileData['PersonalLiveImageUrl'] is List
                              ? List<dynamic>.from(widget.profileData['PersonalLiveImageUrl'])
                              : [widget.profileData['PersonalLiveImageUrl']];

                          _showFullScreenImage(
                            context,
                            imageList,
                            0,
                          );
                        },
                        child: Image.network(
                          widget.profileData['PersonalLiveImageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                        : Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('No live image available'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDocImgView() {
    return Container(
      height: 300,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Verification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (widget.profileData['DocumentImageUrls'] as List<dynamic>?)?.length ?? 0,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _showFullScreenImage(
                              context,
                              widget.profileData['DocumentImageUrls'],
                              index,
                            );
                          },
                          child: Hero(
                            tag: 'profile_image_$index',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.profileData['DocumentImageUrls'][index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, List<dynamic> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(imageUrls[index]),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    heroAttributes: PhotoViewHeroAttributes(tag: 'profile_image_$index'),
                  );
                },
                itemCount: imageUrls.length,
                loadingBuilder: (context, event) => Center(
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                  ),
                ),
                pageController: PageController(initialPage: initialIndex),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetails() {
    final details = [
      {'icon': Icons.person, 'title': 'Name', 'value': 'name'},
      {'icon': Icons.email, 'title': 'Email', 'value': 'email'},
      {'icon': Icons.phone, 'title': 'Phone', 'value': 'PhoneNumber'},
      {'icon': Icons.cake, 'title': 'Age', 'value': 'Age'},
      {'icon': Icons.calendar_today, 'title': 'DOB', 'value': 'DateOfBirth'},
      {'icon': Icons.location_city, 'title': 'City', 'value': 'NationalityCity'},
      {'icon': Icons.work, 'title': 'Profession', 'value': 'Profession'},
      {'icon': Icons.school, 'title': 'Education', 'value': 'Degree'},
      {'icon': Icons.public, 'title': 'Country', 'value': 'NationalityCountry'},
      {'icon': Icons.map, 'title': 'State', 'value': 'NationalityState'},
      {'icon': Icons.flight, 'title': 'Abroad Country', 'value': 'AbroadCountry'},
      {'icon': Icons.location_city, 'title': 'Abroad City', 'value': 'AbroadCity'},
      {'icon': Icons.map, 'title': 'Abroad State', 'value': 'AbroadState'},
      {'icon': Icons.home, 'title': 'Residence', 'value': 'Residence'},
      {'icon': Icons.location_on, 'title': 'Residence District', 'value': 'ResidenceDis'},
      {'icon': Icons.family_restroom, 'title': 'Marital Status', 'value': 'MartialStatus'},
      {'icon': Icons.child_friendly, 'title': 'Has Children', 'value': 'HasChildren'},
      {'icon': Icons.group, 'title': 'Number of Children', 'value': 'NoOfChildren'},
      {'icon': Icons.height, 'title': 'Height', 'value': 'Height'},
      {'icon': Icons.fitness_center, 'title': 'Weight', 'value': 'Weight'},
      {'icon': Icons.color_lens, 'title': 'Skin Tone', 'value': 'skinTone'},
      {'icon': Icons.person_outline, 'title': 'Gender', 'value': 'Gender'},
      {'icon': Icons.handshake, 'title': 'Religion', 'value': 'Religion'},
      {'icon': Icons.group_work, 'title': 'Sect', 'value': 'Sect'},
      {'icon': Icons.accessibility, 'title': 'Disability', 'value': 'Disability'},
      {'icon': Icons.language, 'title': 'Ethnicity', 'value': 'Ethnicity'},
      {'icon': Icons.family_restroom, 'title': 'Tribe', 'value': 'Tribe'},
      {'icon': Icons.business_center, 'title': 'Job Country', 'value': 'JobCountry'},
      {'icon': Icons.work, 'title': 'Job Title', 'value': 'JobTitle'},
      {'icon': Icons.description, 'title': 'Job Description', 'value': 'JobDesc'},
      // {'icon': Icons.attach_money, 'title': 'Income', 'value': 'Income'},
      {'icon': Icons.book, 'title': 'Field', 'value': 'Field'},
      {'icon': Icons.description, 'title': 'Education Description', 'value': 'EducationDescription'},
    ];


    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...details.map((detail) => _buildDetailItem(
            icon: detail['icon'] as IconData,
            title: detail['title'] as String,
            value: widget.profileData[detail['value']]?.toString() ?? 'N/A',
          )),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns items at the top
        children: [
          Icon(icon, color: Colors.indigo),
          SizedBox(width: 16),
          Expanded( // This allows text to wrap inside available space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 12,
                  overflow: TextOverflow.ellipsis, // Shows "..." if text exceeds max lines
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _verifyProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Verify Profile' , style: TextStyle(color: Colors.white)),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _removeProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:  Text('Remove Profile' , style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}