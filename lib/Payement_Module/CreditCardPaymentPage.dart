import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:u_credit_card/u_credit_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Admin_Module/AdminUpdateUserPackage.dart';
import '../JazzCash_PayementModules/jazz_cash_payment_screen.dart';
import '../JazzCash_PayementModules/jazz_cash_service.dart';



class CreditCardPaymentPage extends StatefulWidget {
  final String packageName;
  final String uid;
  final double packagePrice;
  final int chatCredit;
  final int noProposalsView;

  const CreditCardPaymentPage({
    Key? key,
    required this.packageName,
    required this.uid,
    required this.packagePrice,
    required this.chatCredit,
    required this.noProposalsView,
  }) : super(key: key);

  @override
  State<CreditCardPaymentPage> createState() => _CreditCardPaymentPageState();
}

class _CreditCardPaymentPageState extends State<CreditCardPaymentPage> {
  final String cardHolderName = "John Doe";
  final String cardNumber = "1234 5678 9012 3456";
  final TextEditingController CVV_TextEditingController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  bool _isApplyingPromo = false;
  String? _promoMessage;

  // Payment details
  double baseAmount = 5000.0;
  double vat = 250.0;
  double discount = 0.0;
  double totalAmount = 5250.0;


  String? _packageName;
  String? _uid;
  late UserPackage userPackage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    userPackage =new UserPackage();

    setState(() {
      baseAmount = widget.packagePrice;
      totalAmount = widget.packagePrice + vat;
      _packageName= widget.packageName;
      _uid = widget.uid;
    });
  }

  Future<void> _validatePromoCode() async {
    if (_promoController.text.isEmpty) {
      setState(() {
        _promoMessage = 'Please enter a promo code';
      });
      return;
    }

    setState(() {
      _isApplyingPromo = true;
      _promoMessage = null;
    });

    try {
      final promoDoc = await FirebaseFirestore.instance
          .collection('promocodes')
          .doc(_promoController.text)
          .get();

      if (!promoDoc.exists) {
        setState(() {
          _promoMessage = 'Invalid promo code';
          discount = 0;
          totalAmount = baseAmount + vat;
        });
        return;
      }

      final promoData = promoDoc.data();
      if (promoData == null || !promoData.containsKey('discount')) {
        setState(() {
          _promoMessage = 'Invalid promo code format';
          discount = 0;
          totalAmount = baseAmount + vat;
        });
        return;
      }

      // Calculate discount
      setState(() {
        discount = (baseAmount * promoData['discount'] / 100);
        totalAmount = baseAmount + vat - discount;
        _promoMessage = 'Promo code applied successfully!';
      });

    } catch (e) {
      setState(() {
        _promoMessage = 'Error validating promo code';
        discount = 0;
        totalAmount = baseAmount + vat;
      });
    } finally {
      setState(() {
        _isApplyingPromo = false;
      });
    }
  }

  void _initiateJazzCashPayment(BuildContext context) async {


    final service = JazzCashService();



    final params = service.prepareSubmissionData(totalAmount, "MPAY" , widget.uid.toString() ,  widget.packageName.toString() );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JazzCashPaymentScreen(paymentParams: params),
      ),
    );



    if (result != null) {
      if (result['success'])
      {
          // Package is updated server-side via Firebase Cloud Functions webhook/callback
          // await userPackage.updateUserPackage(_uid.toString(), _packageName.toString());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment successful!')),
          );

        print('Transaction Reference: ${result['transactionRef']}');
        print('Amount: ${result['amount']}');
      } else {

        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Text('Payment failed: ${result['responseMessage']}'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.only(left: 14, right: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 56,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Pay using your Credit Card"
                          " \nEnsure that your card details are correct.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Container(
              width: MediaQuery.of(context).size.width - 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Payment Details:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black
                    ),
                  ),
                  SizedBox(height: 15),
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
                                    color: Colors.grey[700]
                                ),
                              ),
                              Text(
                                "Premium",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Subscription fee:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[700]
                                ),
                              ),
                              Text(
                                "PKR ${baseAmount.toStringAsFixed(0)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "VAT:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey[700]
                                ),
                              ),
                              Text(
                                "PKR ${vat.toStringAsFixed(0)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black
                                ),
                              ),
                            ],
                          ),
                          if (discount > 0) ...[
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Discount:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey[700]
                                  ),
                                ),
                                Text(
                                  "- PKR ${discount.toStringAsFixed(0)}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Divider(
                            color: Colors.grey[300],
                            thickness: 1,
                            height: 20,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Amount:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black
                                ),
                              ),
                              Text(
                                "PKR ${totalAmount.toStringAsFixed(0)}",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Have a Promo Code?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _promoController,
                          decoration: InputDecoration(
                            labelText: "Enter Promo Code",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isApplyingPromo ? null : _validatePromoCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                        child: _isApplyingPromo
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                            : Text("Apply" ,style: TextStyle(color: Colors.white),),
                      ),
                    ],
                  ),
                  if (_promoMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _promoMessage!,
                        style: TextStyle(
                          color: _promoMessage!.contains('successfully')
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                  Text(
                    "Note:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    "1. Ensure your credit card is valid and active.",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "2. Verify your available credit limit before proceeding.",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "3. Do not close the application while the transaction is in progress.",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () => _initiateJazzCashPayment(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Proceed",
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
    );
  }
}