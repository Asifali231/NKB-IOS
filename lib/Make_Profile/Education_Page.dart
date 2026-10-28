import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:select_searchable_list/select_searchable_list.dart';

class Education_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Education_Page({required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<Education_Page> createState() => _Education_PageState();
}

class _Education_PageState extends State<Education_Page> {
  static TextEditingController LevelTextEditingController = TextEditingController();
  static TextEditingController FieldTextEditingController = TextEditingController();
  static TextEditingController DescriptionTextEditingController = TextEditingController();

  String? SelectedDegree = "";
  String? SelectedField = "";

  String educationError = "";
  String fieldError = "";
  String descriptionError = "";

  Map<int, String> highSchool = {
    0: "General Education",
    1: "Technical Education",
    2: "Vocational Education",
    3: "STEM Education",
    4: "Arts Education",
    5: "Business Education",
    6: "Agricultural Education",
    7: "Health Education",
    8: "Foreign Languages"
  };
  Map<int, String> intermediate = {
    0: "Pre-Medical",
    1: "Pre-Engineering",
    2: "Commerce",
    3: "Arts",
    4: "Computer Science",
    5: "Humanities",
    6: "Home Economics",
    7: "Social Sciences",
    8: "Physical Education",
    9: "Environmental Science",
    10: "Business Studies",
    11: "Agricultural Science",
    12: "Fine Arts",
    13: "Performing Arts"
  };
  Map<int, String> diploma = {
    0: "Engineering Technology",
    1: "Information Technology",
    2: "Medical Technology",
    3: "Business Administration",
    4: "Hospitality Management",
    5: "Graphic Design",
    6: "Automotive Technology",
    7: "Culinary Arts",
    8: "Early Childhood Education",
    9: "Fashion Design",
    10: "Construction Management",
    11: "Health Information Management",
    12: "Welding Technology",
    13: "Carpentry",
    14: "Electrician",
    15: "Plumbing",
    16: "HVAC Technology",
    17: "Machining Technology",
    18: "Pharmacy Technician",
    19: "Dental Assisting",
    20: "Paralegal Studies"
  };
  Map<int, String> associateDegree = {
    0: "Associate of Arts",
    1: "Associate of Science",
    2: "Associate of Applied Science",
    3: "Associate of Business",
    4: "Associate of Engineering",
    5: "Associate of Nursing",
    6: "Associate of Criminal Justice",
    7: "Associate of Social Work",
    8: "Associate of Information Technology",
    9: "Associate of Graphic Design",
    10: "Associate of Environmental Science",
    11: "Associate of Health Science",
    12: "Associate of Education",
    13: "Associate of Culinary Arts",
    14: "Associate of Hospitality Management",
    15: "Associate of Marketing",
    16: "Associate of Accounting",
    17: "Associate of Biotechnology"
  };
  Map<int, String> bachelor = {
    0: "Bachelor of Science",
    1: "Bachelor of Arts",
    2: "Bachelor of Commerce",
    3: "Bachelor of Business Administration",
    4: "Bachelor of Computer Science",
    5: "Bachelor of Engineering",
    6: "Bachelor of Medicine",
    7: "Bachelor of Law",
    8: "Bachelor of Education",
    9: "Bachelor of Fine Arts",
    10: "Bachelor of Social Work",
    11: "Bachelor of Architecture",
    12: "Bachelor of Nursing",
    13: "Bachelor of Environmental Science",
    14: "Bachelor of Public Health",
    15: "Bachelor of Pharmacy",
    16: "Bachelor of Communication",
    17: "Bachelor of Journalism",
    18: "Bachelor of Political Science",
    19: "Bachelor of Psychology",
    20: "Bachelor of Sociology",
    21: "Bachelor of History",
    22: "Bachelor of Anthropology",
    23: "Bachelor of International Relations",
    24: "Bachelor of Data Science",
    25: "Bachelor of Cybersecurity",
    26: "Bachelor of Music",
    27: "Bachelor of Performing Arts",
    28: "Bachelor of Film Studies",
    29: "Bachelor of Agricultural Science",
    30: "Bachelor of Sports Management",
    31: "Bachelor of Tourism Management",
    32: "Bachelor of Aviation",
    33: "Bachelor of Marine Biology",
    34: "Bachelor of Urban Planning",
    35: "Bachelor of Veterinary Science",
    36: "Bachelor of Occupational Therapy",
    37: "Bachelor of Physical Therapy",
    38: "Bachelor of Civil Engineering",
    39: "Bachelor of Mechanical Engineering",
    40: "Bachelor of Electrical Engineering",
    41: "Bachelor of Chemical Engineering",
    42: "Bachelor of Biomedical Engineering",
    43: "Bachelor of Software Engineering",
    44: "Bachelor of Aerospace Engineering",
    45: "Bachelor of Environmental Engineering",
    46: "Bachelor of Industrial Engineering",
    47: "Bachelor of Materials Engineering",
    48: "Bachelor of Mechatronics Engineering",
    49: "Bachelor of Petroleum Engineering",
    50: "Bachelor of Mining Engineering",
    51: "Bachelor of Geological Engineering",
    52: "Bachelor of Agricultural Engineering",
    53: "Bachelor of Systems Engineering",
    54: "Bachelor of Nuclear Engineering",
    55: "Bachelor of Marine Engineering",
    56: "Bachelor of Structural Engineering",
    57: "Bachelor of Transportation Engineering"
  };
  Map<int, String> master = {
    0: "Master of Science",
    1: "Master of Arts",
    2: "Master of Commerce",
    3: "Master of Business Administration",
    4: "Master of Computer Science",
    5: "Master of Engineering",
    6: "Master of Medicine",
    7: "Master of Law",
    8: "Master of Education",
    9: "Master of Fine Arts",
    10: "Master of Social Work",
    11: "Master of Public Administration",
    12: "Master of Public Health",
    13: "Master of Environmental Science",
    14: "Master of Pharmacy",
    15: "Master of Communication",
    16: "Master of Journalism",
    17: "Master of Political Science",
    18: "Master of Psychology",
    19: "Master of Sociology",
    20: "Master of History",
    21: "Master of Anthropology",
    22: "Master of International Relations",
    23: "Master of Data Science",
    24: "Master of Cybersecurity",
    25: "Master of Music",
    26: "Master of Performing Arts",
    27: "Master of Film Studies",
    28: "Master of Agricultural Science",
    29: "Master of Sports Management",
    30: "Master of Tourism Management",
    31: "Master of Aviation",
    32: "Master of Marine Biology",
    33: "Master of Urban Planning",
    34: "Master of Veterinary Science",
    35: "Master of Occupational Therapy",
    36: "Master of Physical Therapy",
    37: "Master of Biotechnology",
    38: "Master of Information Systems",
    39: "Master of Supply Chain Management",
    40: "Master of Human Resources",
    41: "Master of Finance",
    42: "Master of Marketing",
    43: "Master of International Business",
    44: "Master of Industrial Design",
    45: "Master of Architecture",
    46: "Master of Chemical Engineering",
    47: "Master of Civil Engineering",
    48: "Master of Mechanical Engineering",
    49: "Master of Electrical Engineering",
    50: "Master of Biomedical Engineering",
    51: "Master of Software Engineering",
    52: "Master of Aerospace Engineering",
    53: "Master of Environmental Engineering",
    54: "Master of Industrial Engineering",
    55: "Master of Materials Engineering",
    56: "Master of Mechatronics Engineering",
    57: "Master of Petroleum Engineering",
    58: "Master of Mining Engineering",
    59: "Master of Geological Engineering",
    60: "Master of Agricultural Engineering",
    61: "Master of Systems Engineering",
    62: "Master of Nuclear Engineering",
    63: "Master of Marine Engineering",
    64: "Master of Structural Engineering",
    65: "Master of Transportation Engineering",
    66: "Master of Robotics Engineering",
    67: "Master of Energy Engineering",
    68: "Master of Telecommunication Engineering",
    69: "Master of Optical Engineering",
    70: "Master of Nanotechnology Engineering",
    71: "Master of Automotive Engineering"
  };
  Map<int, String> doctorate = {
    0: "Doctor of Philosophy",
    1: "Doctor of Medicine",
    2: "Doctor of Engineering",
    3: "Doctor of Law",
    4: "Doctor of Education",
    5: "Doctor of Business Administration",
    6: "Doctor of Public Health",
    7: "Doctor of Pharmacy",
    8: "Doctor of Psychology",
    9: "Doctor of Social Work",
    10: "Doctor of Environmental Science",
    11: "Doctor of Computer Science",
    12: "Doctor of Political Science",
    13: "Doctor of International Relations",
    14: "Doctor of Data Science",
    15: "Doctor of Cybersecurity",
    16: "Doctor of Music",
    17: "Doctor of Performing Arts",
    18: "Doctor of Film Studies",
    19: "Doctor of Agricultural Science",
    20: "Doctor of Sports Management",
    21: "Doctor of Tourism Management",
    22: "Doctor of Aviation",
    23: "Doctor of Marine Biology",
    24: "Doctor of Urban Planning",
    25: "Doctor of Veterinary Science",
    26: "Doctor of Occupational Therapy",
    27: "Doctor of Physical Therapy",
    28: "Doctor of Biotechnology",
    29: "Doctor of Information Systems",
    30: "Doctor of Supply Chain Management",
    31: "Doctor of Human Resources",
    32: "Doctor of Finance",
    33: "Doctor of Marketing",
    34: "Doctor of International Business",
    35: "Doctor of Industrial Design",
    36: "Doctor of Architecture",
    37: "Doctor of Chemical Engineering",
    38: "Doctor of Civil Engineering",
    39: "Doctor of Mechanical Engineering",
    40: "Doctor of Electrical Engineering",
    41: "Doctor of Biomedical Engineering",
    42: "Doctor of Software Engineering",
    43: "Doctor of Aerospace Engineering",
    44: "Doctor of Environmental Engineering",
    45: "Doctor of Industrial Engineering",
    46: "Doctor of Materials Engineering",
    47: "Doctor of Mechatronics Engineering",
    48: "Doctor of Petroleum Engineering",
    49: "Doctor of Mining Engineering",
    50: "Doctor of Geological Engineering",
    51: "Doctor of Agricultural Engineering",
    52: "Doctor of Systems Engineering",
    53: "Doctor of Nuclear Engineering",
    54: "Doctor of Marine Engineering",
    55: "Doctor of Structural Engineering",
    56: "Doctor of Transportation Engineering",
    57: "Doctor of Robotics Engineering",
    58: "Doctor of Energy Engineering",
    59: "Doctor of Telecommunication Engineering",
    60: "Doctor of Optical Engineering",
    61: "Doctor of Nanotechnology Engineering",
    62: "Doctor of Automotive Engineering"
  };
  Map<int, String> postDoctorate = {
    0: "Research Fellowship",
    1: "Clinical Fellowship",
    2: "Visiting Scholar",
    3: "Teaching Fellowship",
    4: "Industry Fellowship",
    5: "Policy Fellowship",
    6: "Postdoctoral Research in Science",
    7: "Postdoctoral Research in Engineering",
    8: "Postdoctoral Research in Humanities",
    9: "Postdoctoral Research in Social Sciences",
    10: "Postdoctoral Research in Medicine",
    11: "Postdoctoral Research in Business"
  };
  Map<int, String> professionalCertification = {
    0: "Project Management",
    1: "Certified Public Accountant",
    2: "Certified Information Systems Security Professional",
    3: "Six Sigma",
    4: "Certified Financial Planner",
    5: "Human Resources Certification",
    6: "Certified Ethical Hacker",
    7: "Certified Data Analyst",
    8: "Certified Network Associate",
    9: "Certified Cloud Practitioner",
    10: "Certified ScrumMaster",
    11: "Certified Supply Chain Professional",
    12: "Certified Healthcare Professional",
    13: "Certified Information Systems Auditor",
    14: "Certified Internal Auditor",
    15: "Certified Management Accountant",
    16: "Certified Fraud Examiner",
    17: "Certified Marketing Professional",
    18: "Certified Sales Professional",
    19: "Certified Project Management Professional",
    20: "Certified Risk Management Professional",
    21: "Certified Quality Engineer",
    22: "Certified Safety Professional",
    23: "Certified Industrial Hygienist",
    24: "Certified Welding Inspector",
    25: "Certified Financial Analyst",
    26: "Certified Investment Management Analyst",
    27: "Certified Information Technology Professional"
  };
  Map<int, String> levelOfDegree = {0: "Please Select Degree First"};
  Map<int, String> Degree = {
    0: "Un educated",
    1: "High School",
    2: "Intermediate",
    3: "Diploma",
    4: "Associate Degree",
    5: "Bachelor",
    6: "Master",
    7: "Doctorate",
    8: "Professional Certification",
  };

  Map<int, String> getLevelMap(String selectedDegree) {
    switch (selectedDegree) {
      case "Un educated":
        return {0: "Not Applicable"};
      case "High School":
        return highSchool;
      case "Intermediate":
        return intermediate;
      case "Diploma":
        return diploma;
      case "Associate Degree":
        return associateDegree;
      case "Bachelor":
        return bachelor;
      case "Master":
        return master;
      case "Doctorate":
        return doctorate;
      case "Post-Doctorate":
        return postDoctorate;
      case "Professional Certification":
        return professionalCertification;
      default:
        return {0: "Not Applicable"};
    }
  }

  void validateAndNavigate() {

    print("continuing ....");

    setState(() {
      educationError = "";
      fieldError = "";
      descriptionError = "";
    });

      // Validate Degree Level
      if (SelectedDegree == "") {
        educationError = 'Please select a degree level';
        print("Please select a degree level");
      }

      // Validate Field
      if (SelectedField == "") {
        fieldError = 'Please select a field of study';
        print('Please select a field of study');
      }

      // Validate Description
      // No longer required

      if (educationError == "" && fieldError == "") {

        UserData.Degree = SelectedDegree!;
        UserData.Field = SelectedField!;
        UserData.EducationDiscription = DescriptionTextEditingController.text.toString();

        widget.navigateToNextPage();
      }else
      {
        print('Cant save');
      }

  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 68),

      color: Colors.transparent,
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
                              ? Image.asset("assets/boy_edu.png")
                              : Image.asset("assets/girl_edu.png"),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Let's talk about your qualification",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      "Please Mention Your Highest Degree Obtained",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 35),
                      height: 65,
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: DropDownTextField(
                              textEditingController: LevelTextEditingController,
                              title: 'Education',
                              hint: 'Select your highest level of degree',
                              options: Degree,
                              onChanged: (selectedValue) {
                                setState(() {
                                  educationError = "";
                                  int? selectedIndex = selectedValue?.first;
                                  String? selectedDegree = Degree[selectedIndex] ?? 'Unknown';
                                  levelOfDegree = getLevelMap(selectedDegree);
                                  SelectedDegree = selectedDegree; // Update selectedDegree
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: educationError.isNotEmpty,
                      child: Text(
                        educationError,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15),
                      height: 65,
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: DropDownTextField(
                              textEditingController: FieldTextEditingController,
                              title: 'Field',
                              hint: 'Select your field',
                              options: levelOfDegree,
                              onChanged: (selectedValue) {
                                setState(() {
                                  fieldError = "";
                                  int? selectedIndex = selectedValue?.first;
                                  SelectedField = levelOfDegree[selectedIndex] ?? 'Unknown';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: fieldError.isNotEmpty,
                      child: Text(
                        fieldError,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "We love to hear more about your education to impress our community",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      maxLines: 6,
                      minLines: 3,
                      controller: DescriptionTextEditingController,
                      decoration: InputDecoration(
                        hintText: 'I completed my BS-Software in 2024 and I am pursuing Masters in Cybersecurity ...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
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
    );
  }

}

