import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nikah_blessing/Notifications/NotificationPage.dart';

class ManualPaymentPage extends StatefulWidget {
  final String packageName;
  final String uid;
  final double packagePrice;
  final int chatCredit;
  final int noProposalsView;

  const ManualPaymentPage({
    Key? key,
    required this.packageName,
    required this.uid,
    required this.packagePrice,
    required this.chatCredit,
    required this.noProposalsView,
  }) : super(key: key);

  @override
  _ManualPaymentPageState createState() => _ManualPaymentPageState();
}

class _ManualPaymentPageState extends State<ManualPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _promoCodeController = TextEditingController();
  String _selectedPaymentType = 'Bank';
  File? _image;
  bool _isLoading = false;
  bool _isValidatingPromo = false;
  double? _discountedAmount;
  String? _promoError;

  final List<String> _paymentTypes = [
    'Bank',
    'EasyPaisa',
    'JazzCash',
    'Other'
  ];

  // Payment details based on selected method
  Map<String, Map<String, String>> paymentDetails = {
    'Bank': {
      'title': 'Company Bank Account',
      'bankName': 'UBL UNITED BANK LIMITED',
      'swiftCode': 'UNILPKKA028',
      'accountNo': '1706315484416',
      'ibanNo': 'PK78UNIL0109000315484416',
      'companyName': 'NIKAH BLESSING',
    },
    'JazzCash': {
      'title': 'JazzCash Account',
      'accountNo': '03092299734',
      'accountTitle': 'Asif Ali',
    },
    'EasyPaisa': {
      'title': 'EasyPaisa Account',
      'accountNo': '03342342933',
      'accountTitle': 'Asif Ali',
    },
  };

  @override
  void dispose() {
    _accountNameController.dispose();
    _phoneNumberController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldName copied to clipboard'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    if (_selectedPaymentType == 'Other') {
      return const SizedBox.shrink();
    }

    final details = paymentDetails[_selectedPaymentType];
    if (details == null) return const SizedBox.shrink();

    return Card(

      margin: const EdgeInsets.symmetric(vertical: 16),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _selectedPaymentType == 'Bank'
                      ? Icons.account_balance
                      : Icons.phone_android,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  details['title']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedPaymentType == 'Bank') ...[
              _buildDetailRow('Bank Name', details['bankName']!),
              _buildDetailRow('Swift Code', details['swiftCode']!),
              _buildDetailRow('Account No', details['accountNo']!),
              _buildDetailRow('IBAN No', details['ibanNo']!),
              _buildDetailRow('Company Name', details['companyName']!),
            ] else ...[
              _buildDetailRow('Account No', details['accountNo']!),
              _buildDetailRow('Account Title', details['accountTitle']!),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transfer PKR ${(_discountedAmount ?? widget.packagePrice).toStringAsFixed(0)} to the above account and upload payment proof.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(value, label),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _validatePromoCode() async {
    if (_promoCodeController.text.isEmpty) {
      setState(() {
        _promoError = 'Please enter a promo code';
        _discountedAmount = null;
      });
      return;
    }

    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    try {
      final promoDoc = await FirebaseFirestore.instance
          .collection('promocodes')
          .doc(_promoCodeController.text)
          .get();

      if (!promoDoc.exists) {
        setState(() {
          _promoError = 'Invalid promo code';
          _discountedAmount = null;
        });
        return;
      }

      final promoData = promoDoc.data();
      if (promoData == null || !promoData.containsKey('discount')) {
        setState(() {
          _promoError = 'Invalid promo code format';
          _discountedAmount = null;
        });
        return;
      }

      setState(() {
        _discountedAmount = widget.packagePrice * (1 - promoData['discount'] / 100);
        _promoError = 'Promo code applied successfully!';
      });
    } catch (e) {
      setState(() {
        _promoError = 'Error validating promo code';
        _discountedAmount = null;
      });
    } finally {
      setState(() {
        _isValidatingPromo = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate() || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and upload payment proof')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'payment_proofs/${widget.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_image!);
      final imageUrl = await storageRef.getDownloadURL();

      // Generate a unique transaction ID (e.g., "NKB-12345678")
      String transactionId = "";
      int timestamp = DateTime.now().millisecondsSinceEpoch; // Current timestamp
      int randomNum = Random().nextInt(9000) + 1000; // 4-digit random number
      transactionId = "NKB$timestamp$randomNum"; // Example: NKB170748593412345

      await FirebaseFirestore.instance.collection('payments').add({
        'name': _accountNameController.text,
        'phoneNumber': _phoneNumberController.text,
        'imageUrl': imageUrl,
        'paymentType': _selectedPaymentType,
        'packageSubscribed': widget.packageName,
        'originalAmount': widget.packagePrice,
        'finalAmount': _discountedAmount ?? widget.packagePrice,
        'promoCode': _promoCodeController.text.isEmpty
            ? null
            : _promoCodeController.text,
        'userId': widget.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'transactionId': transactionId,
      });

      setState(() => _isLoading = false);

      NotificationPage notificationPage = new NotificationPage();
      notificationPage.sendNotification(
          "Request Received",
          "Your transaction ${transactionId} is in verification stage soon your package will be upgraded",
          "imageUrl",
          widget.uid.toString());

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: const Text('Manual Payment'),
      //   backgroundColor: Colors.white,
      //   elevation: 1,
      // ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(left: 14, right: 14),
              child: Row(
                children: [
                  Image.asset(
                    "assets/dollar.png",
                    width: 56,
                    height: 56,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Manual Payment\nMake sure to upload clear payment proof.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: MediaQuery.of(context).size.width - 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Payment Details:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 15),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Package:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[700]),
                              ),
                              Text(
                                widget.packageName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Amount:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[700]),
                              ),
                              Text(
                                "PKR ${widget.packagePrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                          if (_discountedAmount != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Discount:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey[700]),
                                ),
                                Text(
                                  "- PKR ${(widget.packagePrice - _discountedAmount!).toStringAsFixed(0)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Amount:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black),
                              ),
                              Text(
                                "PKR ${(_discountedAmount ?? widget.packagePrice).toStringAsFixed(0)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Have a Promo Code?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _promoCodeController,
                          decoration: const InputDecoration(
                            labelText: "Enter Promo Code",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isValidatingPromo ? null : _validatePromoCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                        child: _isValidatingPromo
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white),
                        )
                            : const Text(
                          "Apply",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (_promoError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _promoError!,
                        style: TextStyle(
                          color: _promoError!.contains('successfully')
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    "Select Payment Method",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedPaymentType,
                    decoration: const InputDecoration(
                      labelText: "Payment Method",
                      border: OutlineInputBorder(),
                    ),
                    items: _paymentTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentType = value!;
                      });
                    },
                  ),
                  _buildPaymentInstructions(),
                  const Text(
                    "Enter Payment Details",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width - 42,
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _accountNameController,
                            decoration: const InputDecoration(
                              labelText: "Account Holder Name",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter account holder name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneNumberController,
                            decoration: const InputDecoration(
                              labelText: "Phone Number",
                              hintText: "03XXXXXXXXX",
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter phone number';
                              }
                              if (!RegExp(r'^03\d{9}$').hasMatch(value!)) {
                                return 'Please enter valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _image == null
                                  ? const Center(
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file, size: 50),
                                    Text("Upload Payment Proof"),
                                  ],
                                ),
                              )
                                  : Image.file(_image!, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        "Note:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "1. Make sure to select the correct payment method.",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "2. Upload a clear screenshot of your payment proof.",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "3. Double check all details before submitting.",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "4. Keep your payment proof until verification.",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitPayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white),
                        )
                            : const Text(
                          "Submit Payment",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize any required data or state
  }
}

// Loading Overlay Widget
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Processing Payment...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}