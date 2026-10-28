import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class dummyPageToTestNoti extends StatefulWidget {
  const dummyPageToTestNoti({super.key});

  @override
  State<dummyPageToTestNoti> createState() => _dummyPageToTestNotiState();
}

class _dummyPageToTestNotiState extends State<dummyPageToTestNoti> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Column(
        children: [

          SizedBox(height: 25,),
          ElevatedButton(onPressed: ()
          {



          }, child: Text("Send Notification"))
        ],
      ),
      
      
    );
  }
}
