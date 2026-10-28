import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPackagesManagement extends StatefulWidget {
  const AdminPackagesManagement({Key? key}) : super(key: key);

  @override
  _AdminPackagesManagementState createState() => _AdminPackagesManagementState();
}

class _AdminPackagesManagementState extends State<AdminPackagesManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;

  // Package form controllers - one set for each package
  final Map<String, Map<String, TextEditingController>> packageControllers = {};

  // Promocode form controllers
  final _promocodeController = TextEditingController();
  final _discountController = TextEditingController();

  // Initialize default package data
  final Map<String, Map<String, dynamic>> defaultPackages = {
    "Free": {
      "name": "Free",
      "ChatCredit": 0,
      "DailyProfiles": 0,
      "days": "unlimited",
      "price": 0
    },
    "Rehmat": {
      "name": "Rehmat",
      "ChatCredit": 0,
      "DailyProfiles": 0,
      "days": 0,
      "price": 0
    },
    "Barakah": {
      "name": "Barakah",
      "ChatCredit": 0,
      "DailyProfiles": 0,
      "days": 0,
      "price": 0
    },
    "Noor": {
      "name": "Noor",
      "ChatCredit": 0,
      "DailyProfiles": 0,
      "days": 0,
      "price": 0
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePackages();
  }

  // Initialize controllers for a package
  void _initializeControllersForPackage(String packageId, Map<String, dynamic> data) {
    packageControllers[packageId] = {
      'ChatCredit': TextEditingController(text: data['ChatCredit'].toString()),
      'DailyProfiles': TextEditingController(text: data['DailyProfiles'].toString()),
      'days': TextEditingController(text: data['days'].toString()),
      'price': TextEditingController(text: data['price'].toString()),
    };
  }

  Future<void> _initializePackages() async {
    try {
      setState(() => _isLoading = true);
      final packagesSnapshot = await _firestore.collection('packages').get();

      if (packagesSnapshot.docs.isEmpty) {
        for (var entry in defaultPackages.entries) {
          await _firestore.collection('packages').doc(entry.key).set(entry.value);
          _initializeControllersForPackage(entry.key, entry.value);
        }
      } else {
        for (var doc in packagesSnapshot.docs) {
          _initializeControllersForPackage(doc.id, doc.data());
        }
      }
    } catch (e) {
      _showError('Error initializing packages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promocodeController.dispose();
    _discountController.dispose();
    // Dispose all package controllers
    for (var controllers in packageControllers.values) {
      controllers.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Validate and parse integer input
  int? _parseIntSafely(String value, String fieldName) {
    if (value.isEmpty) {
      throw '$fieldName cannot be empty';
    }
    try {
      return int.parse(value);
    } catch (e) {
      throw '$fieldName must be a valid number';
    }
  }

  Future<void> _updatePackage(String docId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controllers = packageControllers[docId];
      if (controllers == null) throw 'Package controllers not found';

      final chatCredit = _parseIntSafely(controllers['ChatCredit']!.text, 'Chat credits')!;
      final dailyProfiles = _parseIntSafely(controllers['DailyProfiles']!.text, 'Daily profiles')!;
      final price = _parseIntSafely(controllers['price']!.text, 'Price')!;

      if (chatCredit <= 0) throw 'Chat credits must be greater than 0';
      if (dailyProfiles <= 0) throw 'Daily profiles must be greater than 0';
      if (price < 0) throw 'Price cannot be negative';

      final data = {
        'ChatCredit': chatCredit,
        'DailyProfiles': dailyProfiles,
        'days': controllers['days']!.text,
        'price': price,
      };

      await _firestore.collection('packages').doc(docId).update(data);
      _showSuccess('Package updated successfully');
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePackage(String docId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _firestore.collection('packages').doc(docId).delete();
      _showSuccess('Package deleted successfully');
    } catch (e) {
      _showError('Error deleting package: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPackageCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    if (!packageControllers.containsKey(doc.id)) {
      _initializeControllersForPackage(doc.id, data);
    }
    final controllers = packageControllers[doc.id]!;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership, size: 24),
                const SizedBox(width: 8),
                Text(
                  data['name'] ?? 'Unnamed Package',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            const Divider(height: 24),
            TextFormField(
              controller: controllers['ChatCredit'],
              decoration: const InputDecoration(
                labelText: 'Chat Credits',
                icon: Icon(Icons.chat_bubble_outline),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['DailyProfiles'],
              decoration: const InputDecoration(
                labelText: 'Daily Profiles',
                icon: Icon(Icons.people_outline),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['days'],
              decoration: const InputDecoration(
                labelText: 'Package Duration',
                icon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controllers['price'],
              decoration: const InputDecoration(
                labelText: 'Price (PKR)',
                icon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updatePackage(doc.id),
                    icon: const Icon(Icons.save),
                    label: const Text('Update'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Package'),
                          content: Text(
                            'Are you sure you want to delete the package "${data['name']}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deletePackage(doc.id);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPromocode(String code, int discount) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (discount <= 0 || discount > 100) {
        throw 'Discount must be between 1 and 100';
      }
      if (code.isEmpty) {
        throw 'Promocode cannot be empty';
      }

      await _firestore.collection('promocodes').doc(code).set({
        'discount': discount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSuccess('Promocode added successfully');
    } catch (e) {
      _showError('Error adding promocode: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePromocode(String code) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _firestore.collection('promocodes').doc(code).delete();
      _showSuccess('Promocode deleted successfully');
    } catch (e) {
      _showError('Error deleting promocode: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddPackageDialog() {
    final nameController = TextEditingController();
    final chatCreditController = TextEditingController();
    final dailyProfilesController = TextEditingController();
    final daysController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Package'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Package Name'),
              ),
              TextField(
                controller: chatCreditController,
                decoration: const InputDecoration(labelText: 'Chat Credits'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: dailyProfilesController,
                decoration: const InputDecoration(labelText: 'Daily Profiles'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: daysController,
                decoration: const InputDecoration(labelText: 'Duration (days/unlimited)'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (PKR)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final name = nameController.text.trim();
                if (name.isEmpty) throw 'Package name cannot be empty';
                
                final chatCredit = _parseIntSafely(chatCreditController.text, 'Chat credits')!;
                final dailyProfiles = _parseIntSafely(dailyProfilesController.text, 'Daily profiles')!;
                final price = _parseIntSafely(priceController.text, 'Price')!;
                final days = daysController.text.trim();

                if (chatCredit < 0) throw 'Chat credits cannot be negative';
                if (dailyProfiles < 0) throw 'Daily profiles cannot be negative';
                if (price < 0) throw 'Price cannot be negative';
                if (days.isEmpty) throw 'Duration cannot be empty';

                setState(() => _isLoading = true);
                Navigator.pop(context);

                await _firestore.collection('packages').doc(name).set({
                  'name': name,
                  'ChatCredit': chatCredit,
                  'DailyProfiles': dailyProfiles,
                  'days': days,
                  'price': price,
                });
                
                _showSuccess('Package added successfully');
              } catch (e) {
                _showError(e.toString());
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return _isLoading
        ? Container(
      color: Colors.black54,
      child: Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 6,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 28),
            SizedBox(width: 8),
            Text('Admin Dashboard'),
          ],
        ),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Packages'),
            Tab(icon: Icon(Icons.local_offer), text: 'Promocodes'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // Packages Tab
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('packages').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: _showAddPackageDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Package'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        );
                      }
                      return _buildPackageCard(snapshot.data!.docs[index - 1]);
                    },
                  );
                },
              ),

              // Promocodes Tab
              Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _promocodeController,
                            decoration: const InputDecoration(
                              labelText: 'Promocode',
                              icon: Icon(Icons.local_offer),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _discountController,
                            decoration: const InputDecoration(
                              labelText: 'Discount Percentage',
                              icon: Icon(Icons.percent),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_promocodeController.text.isNotEmpty &&
                                  _discountController.text.isNotEmpty) {
                                _addPromocode(
                                  _promocodeController.text,
                                  int.parse(_discountController.text),
                                );
                                _promocodeController.clear();
                                _discountController.clear();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Promocode'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('promocodes').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text('Error: ${snapshot.error}'),
                              ],
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme
                                        .of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.local_offer,
                                    color: Theme
                                        .of(context)
                                        .colorScheme
                                        .secondary,
                                  ),
                                ),
                                title: Text(
                                  doc.id,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.discount,
                                          size: 16,
                                          color: Theme
                                              .of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${data['discount']}% off'),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Theme
                                              .of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(data['createdAt'] as Timestamp?)
                                              ?.toDate().toString()
                                              .split(' ')[0] ?? 'N/A'}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          AlertDialog(
                                            title: const Text('Delete Promocode'),
                                            content: Text(
                                              'Are you sure you want to delete the promocode "${doc
                                                  .id}"?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deletePromocode(doc.id);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                ),
                              ),);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildLoadingOverlay(),
          if (_errorMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: Colors.red,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}