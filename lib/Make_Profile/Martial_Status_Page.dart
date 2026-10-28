import 'package:flutter/material.dart';
import '../DataClass/UserData.dart';

class MartialStatusPage extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  MartialStatusPage({required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<MartialStatusPage> createState() => _MartialStatusPageState();
}

class _MartialStatusPageState extends State<MartialStatusPage> {
  String _sharewith = '3';
  String userName = UserData.Name;

  String selectedMaritalStatus = "Single";
  String hasChildren = "false";
  String livingWithChildren = "false";

  String howManyChildren = "";
  String shareMaritalStatusWith = "";

  TextEditingController maritalStatusController = TextEditingController();
  TextEditingController numberOfChildrenController = TextEditingController();

  String selectedMaritalStatusError = "";
  String hasChildrenError = "";
  String livingWithChildrenError = "";
  String howManyChildrenError = "";
  String shareMaritalStatusWithError = "";

  Map<int, String> maritalStatusOptions = {
    0: "Single",
    1: "Married",
    2: "Divorced",
    3: "Widowed",
    4: "Separated",
    6: "Engaged",
    7: "Widower",
  };

  void validateAndNavigate() {
    setState(() {
      selectedMaritalStatusError = "";
      hasChildrenError = "";
      livingWithChildrenError = "";
      howManyChildrenError = "";
      shareMaritalStatusWithError = "";
    });

    if (selectedMaritalStatus.isEmpty) {
      selectedMaritalStatusError = 'Please select your marital status';
    }

    // Only validate number of children if user has children
    if (selectedMaritalStatus != "Single" && hasChildren == 'true' && howManyChildren.isEmpty) {
      howManyChildrenError = "Please enter how many children you have";
    }

    // Save data in UserData
    UserData.MartialStatus = selectedMaritalStatus;
    UserData.HasChilderen = hasChildren;
    UserData.liveWithYou = livingWithChildren;
    UserData.NoOfChilderens = int.tryParse(numberOfChildrenController.text) ?? 0;
    UserData.ShareMaritalInfoWith = _sharewith;

    // Navigate to the next page if all validations pass
    if (selectedMaritalStatusError.isEmpty && howManyChildrenError.isEmpty) {
      widget.navigateToNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: EdgeInsets.only(top: 68),

        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 79, // 158 / 2
                          backgroundColor: Colors.transparent,
                          child: Image.asset("assets/engage.png"),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "$userName! ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: "It's good to be honest at the start of a relationship.",
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        style: TextStyle(height: 1.5),
                      ),
                      SizedBox(height: 35),

                      // Marital Status Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedMaritalStatus,
                        decoration: InputDecoration(
                          labelText: 'Marital Status',
                          border: OutlineInputBorder(),
                        ),
                        items: maritalStatusOptions.values.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMaritalStatusError = "";
                            selectedMaritalStatus = value!;
                          });
                        },
                      ),
                      if (selectedMaritalStatusError.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text(
                            selectedMaritalStatusError,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      SizedBox(height: 10),

                      // Do you have children?
                      if (selectedMaritalStatus != "Single") ...[
                        Text(
                          "Do you have children from your first marriage?",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Yes'),
                                value: 'true',
                                groupValue: hasChildren,
                                onChanged: (value) => setState(() => hasChildren = value!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text("No"),
                                value: 'false',
                                groupValue: hasChildren,
                                onChanged: (value) => setState(() => hasChildren = value!),
                              ),
                            ),
                          ],
                        ),
                        if (hasChildrenError.isNotEmpty)
                          Text(hasChildrenError, style: TextStyle(color: Colors.red)),
                      ],

                      // Do your children live with you?
                      if (hasChildren == 'true') ...[
                        Text(
                          "Do your children live with you?",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Yes'),
                                value: 'true',
                                groupValue: livingWithChildren,
                                onChanged: (value) => setState(() => livingWithChildren = value!),
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text("No"),
                                value: 'false',
                                groupValue: livingWithChildren,
                                onChanged: (value) => setState(() => livingWithChildren = value!),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // How many children do you have?
                      if (hasChildren == 'true') ...[
                        Text("How many children do you have?",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 10),
                        TextField(
                          controller: numberOfChildrenController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Enter number of children',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => setState(() => howManyChildren = value),
                        ),
                        if (howManyChildrenError.isNotEmpty)
                          Text(howManyChildrenError, style: TextStyle(color: Colors.red)),
                      ],

                      SizedBox(height: 10),
                      Text(
                        "Share this info with",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Column(
                        children: [
                          RadioListTile<String>(
                            title: Text('Only Friends'),
                            value: 'Only Friends',
                            groupValue: shareMaritalStatusWith,
                            onChanged: (value) => setState(() {
                              shareMaritalStatusWith = value!;
                              _sharewith = "1";
                            }),
                          ),
                          RadioListTile<String>(
                            title: Text('Only Me'),
                            value: 'Only Me',
                            groupValue: shareMaritalStatusWith,
                            onChanged: (value) => setState(() {
                              shareMaritalStatusWith = value!;
                              _sharewith = "2";
                            }),
                          ),
                          RadioListTile<String>(
                            title: Text('Public'),
                            value: 'Public',
                            groupValue: shareMaritalStatusWith,
                            onChanged: (value) => setState(() {
                              shareMaritalStatusWith = value!;
                              _sharewith = "3";
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: InkWell(
                onTap: validateAndNavigate,
                child: Container(
                  height: 45,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.pink,
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
