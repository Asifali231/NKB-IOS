// Working Fine
// Gender selected successfully

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';

class Ask_Gender extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Ask_Gender(
      {required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<Ask_Gender> createState() => _Ask_GenderState();
}

class _Ask_GenderState extends State<Ask_Gender>

{

  static bool isMale = false;
  static bool isfemale = false;


  @override
  Widget build(BuildContext context) {
    return Container(

      color: Colors.transparent,
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.only(top: 68),

      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,

      child: Column(

        children: [

          Container(
            margin: EdgeInsets.only(left: 5),
            child: Row(
              children: [
                Text(
                  "Congratulations! 🎉",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: EdgeInsets.only(left: 5),
            child: Row(
              children: [
                Text(
                  "You choesed the right place \n    ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: EdgeInsets.only(left: 5),
            child: Row(
              children: [
                Text(
                  "Lets us find best soul for you",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    height: 1.5,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              Container(
                margin: EdgeInsets.only(left: 5),
                child: Row(
                  children: [
                    Text(
                      "What is your gender? \n    ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 25,),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isMale = true;
                    isfemale = false;

                    UserData.Gender = "Male";
                    widget.navigateToNextPage();

                    print("The User gender is " + UserData.Gender);

                  });
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Container(
                            width: 158.0, // Radius * 2
                            height: 158.0, // Radius * 2
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isMale ? Colors.green : Colors.white,
                                width: 3.0,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              child: Image.asset("assets/male.png"),
                            ),
                          ),
                        ),
                        Text(
                          "Male",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Visibility(
                      visible: isMale,
                      child: Positioned(
                        child: Image.asset(
                          "assets/green_tick.png",
                          width: 25,
                          height: 25,
                        ),
                        bottom: 35,
                        left: 115,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isfemale = true;
                    isMale = false;


                    UserData.Gender = "Female";

                    print("The User gender is " + UserData.Gender);


                    widget.navigateToNextPage();
                  });
                },
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Container(
                            width: 158.0, // Radius * 2
                            height: 158.0, // Radius * 2
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isfemale ? Colors.green : Colors.white,
                                width: 3.0,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 64,
                              child: Image.asset("assets/female.png"),
                            ),
                          ),
                        ),
                        Text(
                          "Female",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Visibility(
                      visible: isfemale,
                      child: Positioned(
                        child: Image.asset(
                          "assets/green_tick.png",
                          width: 25,
                          height: 25,
                        ),
                        bottom: 35,
                        left: 115,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),


        ],
      ),
    );
  }

}
