import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nikah_blessing/Admin_Module/AdminUpdateUserPackage.dart';
import 'package:nikah_blessing/JazzCash_PayementModules/jazz_cash_payement_restApi.dart';

class JazzCashPaymentPage extends StatefulWidget {

  final String packageName;
  final String uid;
  final double packagePrice;
  final int chatCredit;
  final int noProposalsView;

  const JazzCashPaymentPage({
    Key? key,
    required this.packageName,
    required this.uid,
    required this.packagePrice,
    required this.chatCredit,
    required this.noProposalsView,
  }) : super(key: key);

  @override
  State<JazzCashPaymentPage> createState() => _JazzCashPaymentPageState();
}



class _JazzCashPaymentPageState extends State<JazzCashPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _cnicController = TextEditingController();
  final _promoController = TextEditingController();
  bool _isLoading = false;
  bool _isApplyingPromo = false;
  String? _transactionMessage;
  String? _promoMessage;


  String? _packageName;
  String? _uid;
  late UserPackage userPackage;

  // Payment details
  double baseAmount = 5000;
  double vat = 250.0;
  double discount = 0.0;
  double totalAmount = 5250.0;



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
        });
        return;
      }

      final promoData = promoDoc.data();
      if (promoData == null || !promoData.containsKey('discount')) {
        setState(() {
          _promoMessage = 'Invalid promo code format';
          discount = 0;
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
      });
    } finally {
      setState(() {
        _isApplyingPromo = false;
      });
    }
  }

  Future<void> _initiateJazzCashPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _transactionMessage = null;
    });

    try {

      final response = await JazzCashApiService.initiatePaymentOnServer(
        mobileNumber: _mobileController.text,
        cnic: _cnicController.text,
        amount: totalAmount.toInt(),
        description: "Premium Package Subscription",
        uid : _uid.toString(),
        pkgName: _packageName.toString(),
      );

      setState(() {
        _transactionMessage = response['pp_ResponseMessage'] ??
            'Transaction failed. Please try again.';
      });

      if (response['pp_ResponseCode'] == '000')
      {

        // Package is updated server-side via Firebase Cloud Functions (index.js -> updateUserPackage)
        // await userPackage.updateUserPackage(_uid.toString(), _packageName.toString());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment successful!')),
        );



      }
    } catch (e) {
      setState(() {
        _transactionMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: 850,
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.only(left: 14, right: 14),
              child: Row(
                children: [
                  Image.asset(
                    "assets/jazz.png",
                    width: 56,
                    height: 56,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Pay with your JazzCash mobile account"
                          " \nMake sure you have enough balance in your account.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Expanded(
              child: Container(
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
                      "Enter Payment Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 42,
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _mobileController,
                              decoration: InputDecoration(
                                labelText: "Mobile Number",
                                hintText: "03XXXXXXXXX",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter mobile number';
                                }
                                if (!RegExp(r'^03\d{9}$').hasMatch(value!)) {
                                  return 'Please enter valid mobile number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _cnicController,
                              decoration: InputDecoration(
                                labelText: "CNIC (Last 6 digits)",
                                hintText: "XXXXXX",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter CNIC';
                                }
                                if (value!.length != 6) {
                                  return 'Please enter last 6 digits of CNIC';
                                }
                                return null;
                              },
                            ),
                            if (_transactionMessage != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(
                                  _transactionMessage!,
                                  style: TextStyle(
                                    color: _transactionMessage!.contains('successful')
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
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
                          "1. Make sure that your JazzCash account is active.",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "2. Ensure you have sufficient balance.",
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _initiateJazzCashPayment,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                              : Text(
                            "Proceed to Payment",
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
            ),
          ],
        ),
      ),
    );
  }
}