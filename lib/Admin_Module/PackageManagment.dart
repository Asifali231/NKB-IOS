import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class PackageManagementScreen extends StatefulWidget {
  const PackageManagementScreen({Key? key}) : super(key: key);

  @override
  _PackageManagementScreenState createState() => _PackageManagementScreenState();
}

class _PackageManagementScreenState extends State<PackageManagementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String selectedPackage = 'Premium';
  final currencyFormat = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);

  bool isLoading = false;
  bool isDirty = false; // Track if form has unsaved changes

  final priceController = TextEditingController();
  final discountedPriceController = TextEditingController();
  final durationController = TextEditingController();

  // Currency input formatter
  final currencyFormatter = FilteringTextInputFormatter.digitsOnly;

  @override
  void initState() {
    super.initState();
    _loadPackageData();

    // Add listeners to track changes
    priceController.addListener(_markAsDirty);
    discountedPriceController.addListener(_markAsDirty);
    durationController.addListener(_markAsDirty);
  }

  void _markAsDirty() {
    if (!isDirty) {
      setState(() => isDirty = true);
    }
  }

  Future<void> _showLoadingOverlay() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Package updated successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadPackageData() async {
    setState(() => isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('packages')
          .doc(selectedPackage.toLowerCase())
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          priceController.text = data['price'].toString();
          discountedPriceController.text = data['discountedPrice'].toString();
          durationController.text = data['duration'].toString();
          isDirty = false;
        });
      }
    } catch (e) {
      _showError('Error loading package data');
    }

    setState(() => isLoading = false);
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;

    await _showLoadingOverlay();

    try {
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(selectedPackage.toLowerCase())
          .update({
        'price': int.parse(priceController.text),
        'discountedPrice': int.parse(discountedPriceController.text),
        'duration': int.parse(durationController.text),
        'lastUpdated': DateTime.now(),
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close loading overlay
        _showSuccessMessage();
        setState(() => isDirty = false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading overlay
        _showError('Error updating package');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPackageSelector() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Select Package',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPackage,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                DropdownMenuItem(value: 'Disable Package', child: Text('Disable Package')),
                DropdownMenuItem(value: 'Female Card Package', child: Text('Female Card Package')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  // Show confirmation if there are unsaved changes
                  if (isDirty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Unsaved Changes'),
                        content: const Text('You have unsaved changes. Do you want to discard them?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() => selectedPackage = newValue);
                              _loadPackageData();
                            },
                            child: const Text('DISCARD'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    setState(() => selectedPackage = newValue);
                    _loadPackageData();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16 , right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Price Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Regular Price',
                prefixText: 'PKR ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [currencyFormatter],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the price';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: discountedPriceController,
              decoration: InputDecoration(
                labelText: 'Discounted Price',
                prefixText: 'PKR ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [currencyFormatter],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the discounted price';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                final regular = int.parse(priceController.text);
                final discounted = int.parse(value);
                if (discounted >= regular) {
                  return 'Discounted price must be less than regular price';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSection() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Duration Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: 'Duration (days)',
                suffixText: 'days',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the duration';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (int.parse(value) < 1) {
                  return 'Duration must be at least 1 day';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: (isLoading || !isDirty) ? null : _savePackage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.save),
              label: Text(
                isLoading ? 'Saving...' : 'Save Changes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isDirty) ...[
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _loadPackageData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Reset',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    priceController.dispose();
    discountedPriceController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Package Management'),
        elevation: 0,
        actions: [
          if (isDirty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: const Text('Unsaved Changes'),
                backgroundColor: Colors.orange[100],
                labelStyle: TextStyle(color: Colors.orange[900]),
              ),
            ),
        ],
      ),
      body: SafeArea(

        child: Container(
          color: Colors.white,
          child: Form(

            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 0),
                _buildPackageSelector(),
                const SizedBox(height: 0),
                _buildPriceSection(),
                const SizedBox(height: 0),
                _buildDurationSection(),


                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}