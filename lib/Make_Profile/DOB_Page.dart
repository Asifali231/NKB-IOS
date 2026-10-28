import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:numberpicker/numberpicker.dart';

class DOB_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  DOB_Page(
      {required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<DOB_Page> createState() => _DOB_PageState();
}

class _DOB_PageState extends State<DOB_Page> {
  final List<String> months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  String errorMessage = "";

  late FixedExtentScrollController _controllers;
  int age = 0;

  static int _selectedMonthIndex = 0;
  static int _selectedDateIndex = 12;
  static int _selectedYearIndex = 2000;

  static String assest = "";

  String DateOfBirth = "";

  @override
  void initState() {
    super.initState();
    if (UserData.Gender == "Male") {
      assest = "assets/boy_birthday.png";
    } else {
      assest = "assets/girl_birthday.png";
    }

    age = getSpecificAgeOrElse(
        _selectedMonthIndex + 1, _selectedDateIndex, _selectedYearIndex);
    _controllers = FixedExtentScrollController(initialItem: 10000);
  }

  void _onSelectedItemChanged(int index) {
    setState(() {
      _selectedMonthIndex = index;
      age = getSpecificAgeOrElse(
          _selectedMonthIndex + 1, _selectedDateIndex, _selectedYearIndex);
    });
  }

  int getSpecificAgeOrElse(int month, int day, int year) {
    DateTime birthdate = DateTime(year, month, day);
    DateTime today = DateTime.now();
    int age = today.year - birthdate.year;

    setState(() {
      DateOfBirth = "$day/$month/$year";
    });

    return age;
  }

  void _validateAndContinue() {
    if (age >= 18 && age <= 54) {
      setState(() {

        UserData.Age = age;
        UserData.DateOfBirth = DateOfBirth;
        widget.navigateToNextPage();

      });
    } else {
      setState(() {
        errorMessage = "Sorry, your age group isn't matching our policy.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SizedBox(
            height: 68,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 158.0,
                      height: 158.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 0.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 64,
                        child: Image.asset(assest),
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  Text(
                    "  Okay ${UserData.Name}! Tell us your birthdate  ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                height: 40,
                                width: 120,
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.pink, width: 1),
                                    bottom: BorderSide(color: Colors.pink, width: 1),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              child: ListWheelScrollView.useDelegate(
                                itemExtent: 38,
                                useMagnifier: true,
                                magnification: 1.0,
                                onSelectedItemChanged: _onSelectedItemChanged,
                                childDelegate: ListWheelChildLoopingListDelegate(
                                  children: List<Widget>.generate(
                                    months.length,
                                        (index) => Center(
                                      child: Text(
                                        months[index],
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: _selectedMonthIndex == index
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                physics: FixedExtentScrollPhysics(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      NumberPicker(
                        minValue: 1,
                        maxValue: 31,
                        value: _selectedDateIndex,
                        zeroPad: true,
                        infiniteLoop: true,
                        itemWidth: 80,
                        itemHeight: 40,
                        onChanged: (value) {
                          setState(() {
                            _selectedDateIndex = value;
                            age = getSpecificAgeOrElse(_selectedMonthIndex + 1,
                                _selectedDateIndex, _selectedYearIndex);
                          });
                        },
                        textStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                        selectedTextStyle:
                        const TextStyle(color: Colors.black, fontSize: 20),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.pink, width: 1),
                            bottom: BorderSide(color: Colors.pink, width: 1),
                          ),
                        ),
                      ),
                      NumberPicker(
                        minValue: 1970,
                        maxValue: 2022,
                        value: _selectedYearIndex,
                        zeroPad: true,
                        infiniteLoop: true,
                        itemWidth: 80,
                        itemHeight: 40,
                        onChanged: (value) {
                          setState(() {
                            _selectedYearIndex = value;
                            age = getSpecificAgeOrElse(_selectedMonthIndex + 1,
                                _selectedDateIndex, _selectedYearIndex);
                          });
                        },
                        textStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                        selectedTextStyle:
                        const TextStyle(color: Colors.black, fontSize: 20),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.pink, width: 1),
                            bottom: BorderSide(color: Colors.pink, width: 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                  Text(
                    "You are about $age years old",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: age >= 18 && age < 80
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontSize: 18,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
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
                            'We respect your privacy. We will not disclose your birth date; we will only use your age to find the best match for you.',
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
                  SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width - 20,
                    height: 16,
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.transparent,

            ),
            child: InkWell(
              onTap: _validateAndContinue,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.pinkAccent,
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
    );
  }

}
