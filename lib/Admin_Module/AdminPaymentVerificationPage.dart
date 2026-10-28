import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nikah_blessing/Admin_Module/AdminUpdateUserPackage.dart';

class AdminPaymentVerificationPage extends StatefulWidget {
  const AdminPaymentVerificationPage({Key? key}) : super(key: key);

  @override
  State<AdminPaymentVerificationPage> createState() =>
      _AdminPaymentVerificationPageState();
}

class _AdminPaymentVerificationPageState
    extends State<AdminPaymentVerificationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'pending';
  bool _isLoading = false;

  UserPackage userPackage = UserPackage();

  Future<void> _updatePaymentStatus(
      String docId, String status, String uid, String pkgName) async {
    setState(() => _isLoading = true);
    try {
      if (status == 'approved') {
        final packageUpdated =
            await userPackage.updateUserPackage(uid, pkgName);
        if (!packageUpdated) {
          throw Exception(
            'Package could not be applied. Please check the package name and duration in Firestore, then try approval again.',
          );
        }
      }

      final paymentUpdateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'approved') {
        paymentUpdateData['verifiedAt'] = FieldValue.serverTimestamp();
        paymentUpdateData['packageApplied'] = true;
      } else if (status == 'rejected') {
        paymentUpdateData['rejectedAt'] = FieldValue.serverTimestamp();
        paymentUpdateData['packageApplied'] = false;
      }

      await _firestore
          .collection('payments')
          .doc(docId)
          .update(paymentUpdateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Payment ${status == 'approved' ? 'approved' : 'rejected'} successfully'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Payment Verification',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('Approved', 'approved'),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('payments')
            .where('status', isEqualTo: _selectedFilter)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snapshot.data!.docs;

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/no_data.png',
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No $_selectedFilter payments found',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index].data() as Map<String, dynamic>;
              final docId = payments[index].id;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment['name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${docId.substring(0, 8)}...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          // _buildStatusBadge(payment['status']),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Package',
                            payment['packageSubscribed'] ?? 'N/A',
                            Icons.inventory,
                          ),
                          _buildInfoRow(
                            'Amount',
                            'PKR ${payment['finalAmount']?.toString() ?? 'N/A'}',
                            Icons.attach_money,
                          ),
                          _buildInfoRow(
                            'Payment Method',
                            payment['paymentType'] ?? 'N/A',
                            Icons.payment,
                          ),
                          _buildInfoRow(
                            'Phone',
                            payment['phoneNumber'] ?? 'N/A',
                            Icons.phone,
                          ),
                          _buildInfoRow(
                            'Date',
                            DateFormat('MMM dd, yyyy HH:mm').format(
                                (payment['timestamp'] as Timestamp).toDate()),
                            Icons.calendar_today,
                          ),
                          if (payment['promoCode'] != null)
                            _buildInfoRow(
                              'Promo Code',
                              payment['promoCode'],
                              Icons.local_offer,
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            'Payment Proof',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: CachedNetworkImage(
                                    imageUrl: payment['imageUrl'],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: payment['imageUrl'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedFilter == 'pending')
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _updatePaymentStatus(
                                        docId,
                                        'rejected',
                                        payment['userId'],
                                        payment['packageSubscribed']),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _updatePaymentStatus(
                                        docId,
                                        'approved',
                                        payment['userId'],
                                        payment['packageSubscribed']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Approve',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      iconTheme: const IconThemeData(color: Colors.white),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
