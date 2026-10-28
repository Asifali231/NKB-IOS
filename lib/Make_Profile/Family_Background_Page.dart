import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataSets/Cast_Dataset.dart';
import 'package:select_searchable_list/select_searchable_list.dart';
import '../DataClass/UserData.dart';

class Family_Background_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Family_Background_Page({
    required this.navigateToNextPage,
    required this.navigateToPrevPage,
  });

  @override
  State<Family_Background_Page> createState() => _Family_Background_PageState();
}

class _Family_Background_PageState extends State<Family_Background_Page> {
  // State variables for form fields
  String Ethnicity = "";
  String Tribe = "";
  String Sect = "";

  // Error message variables
  String EthnicityError = "";
  String TribeError = "";
  String SectError = "";
  String DescriptionError = "";

  // Text controllers for form inputs
  TextEditingController DisTextEditorController = TextEditingController();
  TextEditingController EthnicityTextEditingController = TextEditingController();
  TextEditingController TribeTextEditingController = TextEditingController();
  TextEditingController SectTextEditingController = TextEditingController();

  // Map of ethnic groups
  Map<int, String> ethnicGroups = {
    0: "Punjabi",
    1: "Sindhi",
    2: "Baloch",
    3: "Saraiki",
    4: "Pashtun",
    5: "Muhajir",
    6: "Local",
    7: "Indian",
    8: "Bangladeshi",
    9: "Saudi Arabian",
    10: "Yemeni",
    11: "Iraqi",
    12: "Syrian",
    13: "Egyptian",
    14: "Moroccan",
    15: "Algerian",
    16: "Tunisian",
    17: "Indonesian",
    18: "Malaysian",
    19: "Afghan",
    20: "Kazakh",
    21: "Uzbek",
    22: "Somali",
    23: "Sudanese",
    24: "Ethiopian",
    25: "Nigerian",
    26: "Malian",
    27: "Senegalese",
    28: "Turkish",
    29: "Bosnian",
    30: "Albanian",
  };
  // Map for tribes (casts), populated based on ethnicity
  Map<int, String> cast = {};

  // Map for sects (static list)
  Map<int, String> sects = {
    0: "Sunni",
    1: "Shia",
    2: "Ismaili",
    3: "Sufi",
    4: "Deobandi",
    5: "Barelvi",
    6: "Salafi/Wahhabi",
    7: "Zaydi",
    8: "Alawi",
    9: "Druze",
    10: "Ibadi",
    11: "Bohra",
    12: "Tijani",
    13: "Qadiri",
    14: "Naqshbandi",
    15: "Chishti",
    16: "Shadhili",
    17: "Mevlevi",
    18: "Nimatullahi",
    19: "Bayani",
    20: "Tablighi Jamaat",
    21: "Mahdavia",
    22: "Nurcu (Nur Movement)",
    23: "Gülen Movement (Hizmet)",
    24: "Shaykhi",
    25: "Bektashi",
    26: "Alevi",
    27: "Twelver (Ithna Ashari)",
    28: "Isna Ashariyyah",
    29: "Zaheeriyah",
    30: "Qarmatian",
    31: "Fatimid",
    32: "Al-Khoei followers",
    33: "Khoja",
    34: "Nizari Ismaili",
    35: "Musta'li Ismaili",
    36: "Progressive Muslim",
    37: "Traditionalist",
    38: "Modernist",
    39: "Quranist (Ahle Quran)",
    40: "Submissionist (United Submitters International)",
    41: "Other",
  };


  Cast_Dataset cast_dataset = Cast_Dataset();
  String UserName = UserData.Name;

  // Validation and navigation logic
  void validateAndNavigate() {
    setState(() {
      EthnicityError = "";
      TribeError = "";
      SectError = "";
      DescriptionError = "";

      // Validate Ethnicity
      if (Ethnicity.isEmpty) {
        EthnicityError = 'Please select an ethnicity';
      }

      // Validate Tribe
      if (Tribe.isEmpty) {
        TribeError = 'Please select a tribe';
      }

      // Validate Sect
      if (Sect.isEmpty) {
        SectError = 'Please select a sect';
      }

      // Validate Family Description
      if (DisTextEditorController.text.isEmpty) {
        DescriptionError = 'Description cannot be empty';
      }

      // Proceed if all fields are valid
      if (Ethnicity.isNotEmpty &&
          Tribe.isNotEmpty &&
          Sect.isNotEmpty &&
          DisTextEditorController.text.isNotEmpty) {
        UserData.Ethicity = Ethnicity; // Corrected from Ethicity
        UserData.Tribe = Tribe;
        UserData.Sect = Sect; // Assuming UserData has a Sect field
        UserData.FamilyDis = DisTextEditorController.text;
        widget.navigateToNextPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const SizedBox(height: 68),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular avatar with family image
                    Center(
                      child: Container(
                        width: 158.0,
                        height: 158.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 0.0),
                        ),
                        child: const CircleAvatar(
                          radius: 64,
                          child: Image(
                            image: AssetImage("assets/family.png"),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Introductory text
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "$UserName! ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const TextSpan(
                            text:
                            "As you know, marriage is not just a union between two individuals, but a beautiful merging of two families into a lasting relationship.",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 25),

                    // Ethnicity dropdown
                    DropDownTextField(
                      textEditingController: EthnicityTextEditingController,
                      title: 'Ethnicity',
                      hint: 'Select your ethnicity',
                      options: ethnicGroups,
                      onChanged: (selectedValue) {
                        setState(() {
                          int? selectedIndex = selectedValue?.first;
                          Ethnicity = ethnicGroups[selectedIndex] ?? 'Unknown';
                          cast = cast_dataset.getCast(Ethnicity);
                        });
                      },
                    ),
                    Visibility(
                      visible: EthnicityError.isNotEmpty,
                      child: Text(
                        EthnicityError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Tribe dropdown
                    DropDownTextField(
                      textEditingController: TribeTextEditingController,
                      title: 'Tribe',
                      hint: 'Select your tribe',
                      options: cast,
                      onChanged: (selectedValue) {
                        setState(() {
                          int? selectedIndex = selectedValue?.first;
                          Tribe = cast[selectedIndex] ?? 'Unknown';
                        });
                      },
                    ),
                    Visibility(
                      visible: TribeError.isNotEmpty,
                      child: Text(
                        TribeError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Sect dropdown (new addition)
                    DropDownTextField(
                      textEditingController: SectTextEditingController,
                      title: 'Sect',
                      hint: 'Select your sect',
                      options: sects,
                      onChanged: (selectedValue) {
                        setState(() {
                          int? selectedIndex = selectedValue?.first;
                          Sect = sects[selectedIndex] ?? 'Unknown';
                        });
                      },
                    ),
                    Visibility(
                      visible: SectError.isNotEmpty,
                      child: Text(
                        SectError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Family description prompt
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: "Tell us about your family dynamics! \n",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const TextSpan(
                            text:
                            "Do you live in a joint family or a nuclear one? \n",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const TextSpan(
                            text:
                            "How many members make up your beloved family?",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 10),

                    // Family description text field
                    TextFormField(
                      maxLines: 6,
                      minLines: 3,
                      controller: DisTextEditorController,
                      decoration: InputDecoration(
                        hintText:
                        'I live with my mother and my siblings i.e one brother two sisters .......',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field cannot be empty';
                        }
                        return null;
                      },
                    ),
                    Visibility(
                      visible: DescriptionError.isNotEmpty,
                      child: Text(
                        DescriptionError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
            child: InkWell(
              onTap: validateAndNavigate,
              child: Container(
                height: 45,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(color: Colors.transparent),
                ),
                child: const Center(
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