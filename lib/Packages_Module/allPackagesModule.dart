import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nikah_blessing/FirebaseOperation/payment_visibility_service.dart';
import 'package:nikah_blessing/Payement_Module/PaymentPagesController.dart';

class PackagesPage extends StatelessWidget {
  final String? entryMessage;

  const PackagesPage({Key? key, this.entryMessage}) : super(key: key);

  int _safeInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(',', '').trim()) ?? fallback;
    }
    return fallback;
  }

  double _safeDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim()) ?? fallback;
    }
    return fallback;
  }

  String _normalizedName(String packageName) {
    return packageName.trim().toLowerCase();
  }

  // Helper method to determine package icon (Physical Services)
  IconData _getPackageIcon(String packageName) {
    switch (_normalizedName(packageName)) {
      case 'free':
        return Icons.card_giftcard;
      case 'rehmat':
        return Icons.favorite;
      case 'barakah':
        return Icons.workspace_premium;
      case 'noor':
      case 'premium':
      case 'pro':
        return Icons.star;
      case 'disablepackage':
        return Icons.lock_open;
      default:
        return Icons.inventory_2;
    }
  }

  // Helper method to determine package color
  Color _getPackageColor(String packageName) {
    switch (_normalizedName(packageName)) {
      case 'free':
        return const Color(0xFF5E81F4);
      case 'rehmat':
        return const Color(0xFF1B8F5A);
      case 'barakah':
        return const Color(0xFFF4A62A);
      case 'noor':
      case 'premium':
      case 'pro':
        return const Color(0xFF8C52FF);
      case 'disablepackage':
        return const Color(0xFFE16063);
      default:
        return const Color(0xFF5E35B1);
    }
  }

  String _getPackageTagline(String packageName) {
    switch (_normalizedName(packageName)) {
      case 'free':
        return 'Start exploring with the free plan';
      case 'rehmat':
        return 'A gentle upgrade for more discovery';
      case 'barakah':
        return 'Balanced access for serious matching';
      case 'noor':
      case 'premium':
      case 'pro':
        return 'Full messaging and premium reach';
      default:
        return 'Upgrade your matchmaking experience';
    }
  }

  List<String> _getPackageFeatures(Map<String, dynamic> packageData) {
    final dailyProfiles = _safeInt(packageData['DailyProfiles'], fallback: 0);
    final chatCredits = _safeInt(packageData['ChatCredit'], fallback: 0);
    final duration = (packageData['days'] ?? 'Not specified').toString();

    return [
      dailyProfiles > 0
          ? '$dailyProfiles daily profile views'
          : 'Daily profile limit managed by admin',
      chatCredits > 0
          ? '$chatCredits chat credits included'
          : 'Messaging upgrade available on paid plans',
      duration.toLowerCase() == 'unlimited'
          ? 'Unlimited duration'
          : '$duration day access period',
      'Secure payment verification and package approval',
    ];
  }

  int _sortRank(String packageName) {
    switch (_normalizedName(packageName)) {
      case 'noor':
      case 'premium':
      case 'pro':
        return 0;
      case 'barakah':
        return 1;
      case 'rehmat':
        return 2;
      case 'disablepackage':
        return 3;
      case 'free':
        return 4;
      default:
        return 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Our Packages',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 56,
                  color: Color(0xFF5E35B1),
                ),
                SizedBox(height: 16),
                Text(
                  'Upgrades are not available in this iOS version.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'You can continue using the free features of Nikah Blessing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Our Packages',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<bool>(
        stream: PaymentVisibilityService.paymentsHiddenStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isHidden = snapshot.data ?? true;
          if (isHidden) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.visibility_off_rounded,
                      size: 56,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Package upgrades are currently hidden.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please check back later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('packages').snapshots(),
            builder: (context, packageSnapshot) {
              if (packageSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${packageSnapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                );
              }

              if (!packageSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final packages = packageSnapshot.data!.docs;
              final sortedPackages = List.from(packages)
                ..sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final nameA = (dataA['name'] ?? a.id).toString();
                  final nameB = (dataB['name'] ?? b.id).toString();
                  return _sortRank(nameA).compareTo(_sortRank(nameB));
                });

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (entryMessage != null &&
                        entryMessage!.trim().isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFF4A62A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFFF4A62A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entryMessage!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6A4A00),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Text(
                      'Choose Your Package',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ...sortedPackages.map((package) {
                      final data = package.data() as Map<String, dynamic>;
                      final packageName = (data['name'] ?? package.id).toString();
                      final priceValue = _safeDouble(data['price']);
                      final chatCredit = _safeInt(data['ChatCredit']);
                      final dailyProfiles = _safeInt(data['DailyProfiles']);

                      return _buildPackageCard(
                        context: context,
                        title: packageName,
                        price: priceValue,
                        features: _getPackageFeatures(data),
                        color: _getPackageColor(packageName),
                        icon: _getPackageIcon(packageName),
                        tagline: _getPackageTagline(packageName),
                        popular: _sortRank(packageName) == 0,
                        packageData: data,
                        chatCredit: chatCredit,
                        dailyProfiles: dailyProfiles,
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPackageCard({
    required BuildContext context,
    required String title,
    required double price,
    required List<String> features,
    required Color color,
    required IconData icon,
    required String tagline,
    required bool popular,
    required Map<String, dynamic> packageData,
    required int chatCredit,
    required int dailyProfiles,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            if (popular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (tagline.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        tagline,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PKR ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        price.toStringAsFixed(
                            price.truncateToDouble() == price ? 0 : 2),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (price > 0)
                        const Text(
                          ' +tax',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...features.map((feature) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPagesController(
                            packageName:
                                (packageData['name'] ?? title).toString(),
                            packagePrice: price,
                            chatCredit: chatCredit,
                            noProposalsView: dailyProfiles,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
}
