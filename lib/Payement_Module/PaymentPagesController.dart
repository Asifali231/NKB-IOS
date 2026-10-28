import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/Payement_Module/JazzCashPaymentPage.dart';
import 'CreditCardPaymentPage.dart';
import 'manualPayement_Page.dart';

class PaymentPagesController extends StatefulWidget {
  final String packageName;
  final double packagePrice;
  final int chatCredit;
  final int noProposalsView;

  const PaymentPagesController({
    super.key,
    required this.packageName,
    required this.packagePrice,
    required this.chatCredit,
    required this.noProposalsView,
  });

  @override
  _PaymentPagesControllerState createState() => _PaymentPagesControllerState();
}

class _PaymentPagesControllerState extends State<PaymentPagesController> {
  int _selectedIndex = 1;
  String _uid = ""; // Store Firebase User UID

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      _getCurrentUser();
    }
  }

  // Fetch current user from FirebaseAuth
  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      setState(() {
        _uid = user.uid;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _buildPages() {
    return [
      CreditCardPaymentPage(
        packageName: widget.packageName,
        uid: _uid,
        packagePrice: widget.packagePrice,
        chatCredit: widget.chatCredit,
        noProposalsView: widget.noProposalsView,
      ),
      JazzCashPaymentPage(
        packageName: widget.packageName,
        uid: _uid,
        packagePrice: widget.packagePrice,
        chatCredit: widget.chatCredit,
        noProposalsView: widget.noProposalsView,
      ),
      ManualPaymentPage(
        packageName: widget.packageName,
        uid: _uid,
        packagePrice: widget.packagePrice,
        chatCredit: widget.chatCredit,
        noProposalsView: widget.noProposalsView,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return Scaffold(
        appBar: AppBar(title: const Text('Purchases unavailable')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Purchases are not available in this iOS version. '
              'You can continue using the free features.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final pages = _buildPages();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: 80,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Container(
                  margin: const EdgeInsets.only(left: 14, top: 30),
                  width: MediaQuery.of(context).size.width,
                  child: const Text(
                    'Purchase Service',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  )),
            ),
          ),

          // The 3 buttons at the top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  _onItemTapped(0);
                },
                child: Container(
                  height: 34,
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedIndex == 0
                          ? Colors.black
                          : Colors.grey, // Border color
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/credit.png",
                        width: 24,
                        height: 24,
                      ),
                      Center(
                        child: Text(
                          "  Card ",
                          style: TextStyle(
                            fontWeight: _selectedIndex == 0
                                ? FontWeight.bold
                                : FontWeight.normal, // Text weight
                            fontSize: 16,
                            color: _selectedIndex == 0
                                ? Colors.black
                                : Colors.grey, // Text color
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _onItemTapped(1);
                },
                child: Container(
                  height: 34,
                  width: 115,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedIndex == 1
                          ? Colors.black
                          : Colors.grey, // Border color
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/jazz.png",
                        width: 24,
                        height: 24,
                      ),
                      Center(
                        child: Text(
                          " Jazzcash ",
                          style: TextStyle(
                            fontWeight: _selectedIndex == 1
                                ? FontWeight.bold
                                : FontWeight.normal, // Text weight
                            fontSize: 16,
                            color: _selectedIndex == 1
                                ? Colors.black
                                : Colors.grey, // Text color
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _onItemTapped(2);
                },
                child: Container(
                  height: 34,
                  width: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedIndex == 2
                          ? Colors.black
                          : Colors.grey, // Border color
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/dollar.png",
                        width: 24,
                        height: 24,
                      ),
                      Center(
                        child: Text(
                          " Cash ",
                          style: TextStyle(
                            fontWeight: _selectedIndex == 2
                                ? FontWeight.bold
                                : FontWeight.normal, // Text weight
                            fontSize: 16,
                            color: _selectedIndex == 2
                                ? Colors.black
                                : Colors.grey, // Text color
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Display the selected page

          const SizedBox(
            height: 15,
          ),

          Expanded(
            child: pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
