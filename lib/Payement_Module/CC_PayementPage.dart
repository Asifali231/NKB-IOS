import 'package:credit_card_type_detector/credit_card_type_detector.dart';
import 'package:credit_card_validator/credit_card_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import 'package:u_credit_card/u_credit_card.dart';

class CC_PayementPage extends StatefulWidget {
  const CC_PayementPage({super.key});

  @override
  State<CC_PayementPage> createState() => _CC_PayementPageState();
}

class _CC_PayementPageState extends State<CC_PayementPage> {

  String cardHolderName = "Muhammad Dawood Maqbool";
  String cardNumber = "34567567812345678";
  String cvv = "";

  int InitMonth = 0;
  int InitYear = 0;

  int EndMonth = 0;
  int EndYear = 0;

  TextEditingController NameTextEditingController = new TextEditingController();
  TextEditingController CardNumTextEditingController = new TextEditingController();
  TextEditingController MonthNumTextEditingController = new TextEditingController();
  TextEditingController YearNumTextEditingController = new TextEditingController();
  TextEditingController CVV_TextEditingController = new TextEditingController();



  CreditCardValidator _ccValidator = new CreditCardValidator();

  bool validateCreditCardInfo(String ccNum, String expDate, String cvv)
  {
      var ccNumResults = _ccValidator.validateCCNum(ccNum);
      var expDateResults = _ccValidator.validateExpDate(expDate);
      var cvvResults = _ccValidator.validateCVV(cvv, ccNumResults.ccType);


      if(ccNumResults.isPotentiallyValid) {

      }

      return true;
  }




  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: Container(

        child: Column(
          children:
          [
      
            Container(
              margin: EdgeInsets.only(left: 14,right: 14),
              width: MediaQuery.of(context).size.width,
              child: CreditCardUi(
      
                cardHolderFullName: cardHolderName,
                cardNumber: cardNumber,
                validFrom: '01/23',
                validThru: '01/28',
                topLeftColor: Colors.blue,
                doesSupportNfc: true,
                placeNfcIconAtTheEnd: true,
                cardType: CardType.credit,
                creditCardType: CreditCardType.visa,
                cardProviderLogo: FlutterLogo(),
                cardProviderLogoPosition: CardProviderLogoPosition.right,
                enableFlipping: true,
                autoHideBalance: true,
      
                cvvNumber: CVV_TextEditingController.text,
              ),
            ),
      
      
            Container(
              margin: EdgeInsets.all(14),
              child:  Column(
                  children:
                  [
                    Column(
                      children:
                      [
      
                        Container(
                          width: MediaQuery.of(context).size.width,
                          child: Text(
                            ' Card Number',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        SizedBox(height: 5,),
                        Container(
                          padding: EdgeInsets.all(5),
                          child: TextFormField(
      
      
                            controller: NameTextEditingController,
      
                            decoration: InputDecoration(
      
                              prefixIcon: Icon(Icons.credit_card),
                              contentPadding: EdgeInsets.only(left: 10),
                              border: OutlineInputBorder(),
                              hintText: "3456 **** **** 4567",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your name";
                              }
                              return null;
                            },
                            onChanged: (Value)
                            {
                              setState(() {
                                cardNumber = Value;
                              });
      
                            },
                          ),
      
                        ),
      
                        SizedBox(height: 5,),
      
      
                        Container(
                          width: MediaQuery.of(context).size.width,
                          child: Text(
                            ' Card Holder Name',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        SizedBox(height: 5,),
                        Container(
                          padding: EdgeInsets.all(5),
                          child: TextFormField(
      
                            controller: CardNumTextEditingController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person),
      
                              contentPadding: EdgeInsets.only(left: 10),
                              border: OutlineInputBorder(),
                              hintText: "Muhammad Dawood Maqbool",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your name";
                              }
                              return null;
                            },
                          ),
                        ),
      
                        SizedBox(height: 5,),
      
                        Container(
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children:
                            [
      
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    child: Text(
                                      ' Expiry Date',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  SizedBox(height: 5,),
                                  Row(
                                    children: [
                                      Container(
                                        height: 50,
                                        width: 125,
                                        padding: EdgeInsets.all(5),
                                        child: TextFormField(
      
                                          controller: MonthNumTextEditingController,
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(Icons.calendar_month),
      
                                            contentPadding: EdgeInsets.only(left: 10),
                                            border: OutlineInputBorder(),
                                            hintText: "08 MM  ",
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "Please enter your name";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      Container(
                                        height: 50,
                                        width: 90,
                                        padding: EdgeInsets.all(5),
                                        child: TextFormField(
                                          controller: YearNumTextEditingController,
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.only(left: 10),
                                            border: OutlineInputBorder(),
                                            hintText: "2025 YY",
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "Please enter your name";
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
      
                                    ],
                                  ),
                              ],),
      
                              Column(
                                children: [
                                  Container(
                                    child: Text(
                                      ' CVV Number',
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  SizedBox(height: 5,),
                                  Row(
                                    children: [
                                      Container(
                                        height: 50,
                                        width: 100,
                                        padding: EdgeInsets.all(5),
                                        child: TextFormField(
      
                                          controller: CVV_TextEditingController,
                                          decoration: InputDecoration(
                                            suffixIcon: Icon(Icons.lock,size: 18,
                                            ),
                                            contentPadding: EdgeInsets.only(left: 10),
                                            border: OutlineInputBorder(),
                                            hintText: "334",
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return "Please enter your name";
                                            }
                                            return null;
                                          },
                                          onChanged: (value)
                                          {
      
                                            setState(() {
                                              cvv = value;
                                            });
                                          },
      
                                        ),
                                      ),
      
                                    ],
                                  ),
                                ],),
      
                            ],
                          ),
                        ),
      
      
                        InkWell(
                          onTap: (){},
                          child: Container(
                            height: 45,
                            width: MediaQuery.of(context).size.width - 20,
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                color: Colors.transparent,
                                border: Border.all(color: Colors.black54)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Validate & Proceed',
                                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
      
                      ],
                    )
                  ],
              ),
            ),
      
      
          ]
        )
      ),
    );
  }
}
