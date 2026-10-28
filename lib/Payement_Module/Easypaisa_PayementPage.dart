import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Easypaisa_PayementPage extends StatefulWidget {
  const Easypaisa_PayementPage({super.key});

  @override
  State<Easypaisa_PayementPage> createState() => _Easypaisa_PayementPageState();
}

class _Easypaisa_PayementPageState extends State<Easypaisa_PayementPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          SizedBox(
            height: 10,
          ),
          Container(
            margin: EdgeInsets.only(left: 14, right: 14),
            child: Row(
              children: [
                Image.asset(
                  "assets/e-min.png",
                  width: 56,
                  height: 56,
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                                  child: Text(
                "Pay with your Easypaisa mobile account"
                " \nMake Sure you have engough balance in your account. ",
                style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
              ],
            ),
          ),
          SizedBox(
            height: 15,
          ),
          
          
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width - 42,

              child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width - 32,
                    child: Text(
                      "Note:",
                      style: TextStyle(fontWeight: FontWeight.bold , fontSize: 16 , color: Colors.grey),
                    ),
                  ),

                  SizedBox(height: 15,),

                  Container(
                    width: MediaQuery.of(context).size.width - 32,
                    child: Text(
                      " 1. Make sure that your easypaisa account is active.",
                      style: TextStyle(fontWeight: FontWeight.bold , fontSize: 14 , color: Colors.grey),
                    ),
                  ),

                  SizedBox(height: 5,),

                  Container(
                    width: MediaQuery.of(context).size.width - 32,
                    child: Text(
                      " 2. Make Sure you have sufficient balance.",
                      style: TextStyle(fontWeight: FontWeight.bold , fontSize: 14 , color: Colors.grey),
                    ),
                  ),

                  SizedBox(height: 5,),

                  Container(
                    width: MediaQuery.of(context).size.width - 32,
                    child: Text(
                      " 3. Please Don't Cloese Application While Transaction Is In Progress.",
                      style: TextStyle(fontWeight: FontWeight.bold , fontSize: 14 , color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
