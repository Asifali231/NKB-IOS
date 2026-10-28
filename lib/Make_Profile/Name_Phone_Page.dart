// The page is to get the user phone number and display name
// testing .....
// Is Getting ?
// Is saving  ?


import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:select_searchable_list/select_searchable_list.dart';

class Name_Phone_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Name_Phone_Page({required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<Name_Phone_Page> createState() => _Name_Phone_PageState();
}

class _Name_Phone_PageState extends State<Name_Phone_Page> {
  final _formKey = GlobalKey<FormState>();

  static TextEditingController nameTextEditingController = TextEditingController();
  static TextEditingController phoneTextEditingController = TextEditingController();

  String? phoneNumber;

  void validateAndNavigate() {
    if (_formKey.currentState!.validate()) {


      setState(() {
        UserData.Name = nameTextEditingController.text.toString();
        UserData.PhoneNumber = phoneTextEditingController.text.toString();

      });

      print("The User Display Name IS " + UserData.Name);
      print("The User Phone Number IS " + UserData.PhoneNumber);

      widget.navigateToNextPage();

    } else {

    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.transparent,
        margin: EdgeInsets.only(top: 68),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 158.0, // Radius * 2
                                height: 158.0, // Radius * 2
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 0.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 64,
                                  child: UserData.Gender == "Male"
                                      ? Image.asset("assets/male.png")
                                      : Image.asset("assets/female.png"),
                                ),
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              "We are happy to serve you 💞",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                height: 1.5,
                                letterSpacing: 0,
                              ),
                            ),
                            Text(
                              "Give us some minutes to make your profile appealing",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 1.5,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Display Name',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            TextFormField(
                              controller: nameTextEditingController,
                              decoration: InputDecoration(
                                suffixIcon: Icon(Icons.person_2_outlined),
                                contentPadding: EdgeInsets.only(left: 10),
                                border: OutlineInputBorder(),
                                hintText: "John Doe / Sara John",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your name";
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 18),
                            Text(
                              'Phone Number',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            IntlPhoneField(
                              controller: phoneTextEditingController,
                              decoration: InputDecoration(
                                suffixIcon: Icon(CupertinoIcons.phone),
                                border: OutlineInputBorder(),
                              ),
                              initialCountryCode: 'PK',
                              onChanged: (phone) {
                                setState(() {
                                  phoneNumber = phone.completeNumber;
                                  print(phoneNumber);
                                });
                              },
                              validator: (value) {
                                if (value == null ||
                                    value.completeNumber.isEmpty ||
                                    value.completeNumber.length <= 5) {
                                  return "Please enter a valid phone number";
                                }
                                return null;
                              },
                            ),
                            Padding(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blueGrey,
                                    size: 16.0,
                                  ),
                                  SizedBox(width: 8.0), // Space between icon and text
                                  Expanded(
                                    child: Text(
                                      'Your phone number will remain confidential and will only be used to contact you if we need to address any inquiries or concerns.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.blueGrey,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: InkWell(
                onTap: validateAndNavigate,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.pinkAccent,
                  ),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
