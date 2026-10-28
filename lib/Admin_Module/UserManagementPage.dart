import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> allUsers = [];
  List<DocumentSnapshot> filteredUsers = [];
  bool isLoading = true;
  String searchQuery = '';
  String filterBy = 'Name'; // Default filter

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);
    try {
      final QuerySnapshot snapshot = await _firestore.collection('users').get();
      setState(() {
        allUsers = snapshot.docs;
        filteredUsers = allUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load users: ${e.toString()}');
    }
  }

  void filterUsers(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          switch (filterBy) {
            case 'UserID':
              return doc.id.toLowerCase().contains(query.toLowerCase());
            case 'Name':
              return data['name'].toString().toLowerCase().contains(query.toLowerCase());

            case 'Phone':
              return data['PhoneNumber'].toString().toLowerCase().contains(query.toLowerCase());
            case 'Email':
              return data['email'].toString().toLowerCase().contains(query.toLowerCase());

            case 'Country':
              return data['JobCountry'].toString().toLowerCase().contains(query.toLowerCase());
            case 'Gender':
              return data['Gender'].toString().toLowerCase().contains(query.toLowerCase());

            default:
              return false;
          }
        }).toList();
      }
    });
  }

  Future<void> deleteUser(String userId, Map<String, dynamic> userData) async {
    try {
      setState(() => isLoading = true);

      // Delete from users collection
      await _firestore.collection('users').doc(userId).delete();

      if(userData['JobCountry'] != null)
      {
        // Delete from proposals collection
        await _firestore
            .collection('proposals')
            .doc(userData['JobCountry'])
            .collection(userData['Gender'])
            .doc(userId)
            .delete();
      }


      setState(() {
        allUsers.removeWhere((doc) => doc.id == userId);
        filteredUsers.removeWhere((doc) => doc.id == userId);
        isLoading = false;
      });

      _showSuccessSnackBar('User deleted successfully');
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to delete user: ${e.toString()}');
    }
  }

  void _showUserDetails(DocumentSnapshot doc) {
    final userData = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'User Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('UserID', doc.id),
                      _buildDetailRow('Name', userData['name']),
                      _buildDetailRow('Phone', userData['PhoneNumber']),
                      _buildDetailRow('Email', userData['email']),
                      _buildDetailRow('Age', userData['Age']),
                      _buildDetailRow('Gender', userData['Gender']),
                      _buildDetailRow('Country', userData['JobCountry']),
                      _buildDetailRow('Profession', userData['Profession']),
                      _buildDetailRow('Education', userData['Degree']),
                      if (userData['ProfileImageUrls'] != null) ...[
                        SizedBox(height: 16),
                        Text('Profile Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: (userData['ProfileImageUrls'] as List).length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Image.network(
                                  userData['ProfileImageUrls'][index],
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  icon: Icon(Icons.delete , color: Colors.white,),
                  label: Text('Delete User' , style: TextStyle(color: Colors.white),),
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Confirm Deletion'),
                        content: Text('Are you sure you want to delete this user? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              Navigator.pop(context);
                              deleteUser(doc.id, userData);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('User Management'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      onChanged: filterUsers,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Name',
                          'UserID',
                          'Phone',
                          'Email',
                          'Country',
                          'Gender',

                        ].map((filter) {
                          return Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: filterBy == filter,
                              onSelected: (selected) {
                                setState(() {
                                  filterBy = filter;
                                  filterUsers(searchQuery);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredUsers.isEmpty
                    ? Center(child: Text('No users found'))
                    : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final doc = filteredUsers[index];
                    final userData = doc.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () => _showUserDetails(doc),
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                (userData['ProfileImageUrls'] != null && userData['ProfileImageUrls']!.isNotEmpty)
                                    ? userData['ProfileImageUrls']![0]
                                    : 'https://via.placeholder.com/150',
                              ),
                            ),

                            title: Text(
                              userData['name'] ?? 'N/A',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userData['PhoneNumber'] ?? 'N/A'),
                                Text('${userData['JobCountry']} • ${userData['Gender']}'),
                              ],
                            ),
                            trailing: Icon(Icons.chevron_right),
                          ),
                          Divider()
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),


      floatingActionButton: FloatingActionButton(
        onPressed: loadUsers,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Users',
      ),


    );
  }
}