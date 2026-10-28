import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:select_searchable_list/select_searchable_list.dart';

class Apperance extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Apperance({required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<Apperance> createState() => _ApperanceState();
}

class _ApperanceState extends State<Apperance> {

  TextEditingController HeightTextEditorController = new TextEditingController();
  TextEditingController WeightTextEditingController = new TextEditingController();

// Define a variable to keep track of the selected skin tone
  String _selectedSkinTone = ""; // Allow null values
  String _selectedBodyType = "";
  String _selectedDisplayHeight = "";
  double _selectedHeight = 0.0; // Or initialize as needed

  String skinError = "";
  String heightError = "";
  String bodyTypeError = "";
  String weightError = "";

// Define your skin tones list
  Map<int, String> heights = {
    0: "3 feet",
    1: "3 feet 1 inch",
    2: "3 feet 2 inches",
    3: "3 feet 3 inches",
    4: "3 feet 4 inches",
    5: "3 feet 5 inches",
    6: "3 feet 6 inches",
    7: "3 feet 7 inches",
    8: "3 feet 8 inches",
    9: "3 feet 9 inches",
    10: "3 feet 10 inches",
    11: "3 feet 11 inches",
    12: "4 feet",
    13: "4 feet 1 inch",
    14: "4 feet 2 inches",
    15: "4 feet 3 inches",
    16: "4 feet 4 inches",
    17: "4 feet 5 inches",
    18: "4 feet 6 inches",
    19: "4 feet 7 inches",
    20: "4 feet 8 inches",
    21: "4 feet 9 inches",
    22: "4 feet 10 inches",
    23: "4 feet 11 inches",
    24: "5 feet",
    25: "5 feet 1 inch",
    26: "5 feet 2 inches",
    27: "5 feet 3 inches",
    28: "5 feet 4 inches",
    29: "5 feet 5 inches",
    30: "5 feet 6 inches",
    31: "5 feet 7 inches",
    32: "5 feet 8 inches",
    33: "5 feet 9 inches",
    34: "5 feet 10 inches",
    35: "5 feet 11 inches",
    36: "6 feet",
    37: "6 feet 1 inch",
    38: "6 feet 2 inches",
    39: "6 feet 3 inches",
    40: "6 feet 4 inches",
    41: "6 feet 5 inches",
    42: "6 feet 6 inches",
    43: "6 feet 7 inches",
    44: "6 feet 8 inches",
    45: "6 feet 9 inches",
    46: "6 feet 10 inches",
    47: "6 feet 11 inches",
    48: "7 feet",
    49: "7 feet 1 inch",
    50: "7 feet 2 inches",
    51: "7 feet 3 inches",
    52: "7 feet 4 inches",
    53: "7 feet 5 inches",
    54: "7 feet 6 inches",
    55: "7 feet 7 inches",
    56: "7 feet 8 inches",
    57: "7 feet 9 inches",
    58: "7 feet 10 inches",
    59: "7 feet 11 inches",
    60: "8 feet",
    61: "8 feet 1 inch",
    62: "8 feet 2 inches",
    63: "8 feet 3 inches",
    64: "8 feet 4 inches",
    65: "8 feet 5 inches",
    66: "8 feet 6 inches",
    67: "8 feet 7 inches",
    68: "8 feet 8 inches",
    69: "8 feet 9 inches",
    70: "8 feet 10 inches",
    71: "8 feet 11 inches",
  };
  final List<String> skinTones = [
    'Fair',
    'Light',
    'Medium',
    'Olive',
    'Tan',
    'Brown',
    'Dark',
  ];
  final List<String> BodyType = [
    'Chubby',
    'Lean',
    'Skinny',
    'Average',
    'Muscular',
    'Athlete',
    'Fit',
  ];




  double parseHeight(String height) {
    final regex = RegExp(r'(\d+) feet(?: (\d+) inch(?:es)?)?');
    final match = regex.firstMatch(height);

    if (match != null) {
      final feet = double.parse(match.group(1)!);
      final inches = match.group(2) != null ? double.parse(match.group(2)!) : 0;

      // Convert inches to feet (1 inch = 0.0833 feet)
      return feet + (inches * 0.0833);
    }

    // Return 0 if the string format is not recognized
    return 0.0;
  }


  void validateAndNavigate ()
  {

    if(_selectedHeight == 0.0)
      {
        setState(() {
          heightError = "Please Select Your Height";
        });

        print("Please Select Your Height");
      }

    if(_selectedBodyType == "")
    {
      setState(() {
        bodyTypeError = "Please Select Your BodyType";
      });

      print("Please Select Your BodyType");

    }

    if(_selectedSkinTone == "")
    {
      setState(() {
        skinError = "Please Select Your SkinTone";
      });

      print("Please Select Your SkinTone");
    }

    if(WeightTextEditingController.text.toString() == "")
    {
      setState(() {
        weightError = "Please Select Your Weight";
      });

      print("Please Select Your Weight");
    }


    if(_selectedHeight != 0.0 && _selectedSkinTone != "" && _selectedBodyType != "")
      {
        setState(() {
          UserData.Height = _selectedHeight;
          UserData.skinTone =_selectedSkinTone;
          UserData.bodyType = _selectedBodyType;
          UserData.Weight = WeightTextEditingController.text.toString();
          UserData.displayHeight = _selectedDisplayHeight;
        });


        print( "navigating .....");
        widget.navigateToNextPage();
      }

    widget.navigateToNextPage();

  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 78),

      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(right: 20, left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select your height",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      height: 65,
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.only(top: 1),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.only(right: 0),
                                      child: DropDownTextField(
                                        textEditingController: HeightTextEditorController,
                                        title: 'Your Height',
                                        hint: '5 feet 6 inch',

                                        options: heights,
                                        onChanged: (selectedValue) {
                                          if (selectedValue != null) {
                                            final double heightInFeet =
                                            parseHeight(heights[selectedValue.first].toString());

                                            print("Selected Value is " + heights[selectedValue.first].toString());

                                            setState(() {
                                              _selectedHeight = heightInFeet;
                                              _selectedDisplayHeight = heights[selectedValue.first].toString();
                                            });
                                          }
                                        },
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
                    Visibility(
                      visible: HeightTextEditorController.text.toString() == "",
                      child: Text(
                        heightError,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Select your weight",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: WeightTextEditingController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(left: 10),
                        border: OutlineInputBorder(),
                        hintText: "56 Kilogram",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your weight";
                        }
                        return null;
                      },
                    ),
                    Visibility(
                      visible: WeightTextEditingController.text.toString() == "",
                      child: Text(
                        weightError,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Select your body type",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Wrap(
                        spacing: 5.0,
                        runSpacing: 5.0,
                        children: BodyType.map((tone) {
                          final isSelected = _selectedBodyType == tone;
                          return ChoiceChip(
                            label: Text(
                              tone,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.pink, // Text color
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.pink, // Background color when selected
                            backgroundColor: Colors.white, // Background color when not selected
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              side: BorderSide(color: Colors.pink), // Border color
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedBodyType = (selected ? tone : null)!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    Visibility(
                      visible: _selectedBodyType == "",
                      child: Text(
                        bodyTypeError,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Select your skin tone",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Wrap(
                        spacing: 5.0,
                        runSpacing: 5.0,
                        children: skinTones.map((tone) {
                          final isSelected = _selectedSkinTone == tone;
                          return ChoiceChip(
                            label: Text(
                              tone,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.pink, // Text color
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.pink, // Background color when selected
                            backgroundColor: Colors.white, // Background color when not selected
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              side: BorderSide(color: Colors.pink), // Border color
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedSkinTone = (selected ? tone : null)!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    Visibility(
                      visible: _selectedSkinTone == "",
                      child: Text(
                        skinError,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: InkWell(
                onTap: validateAndNavigate,
                child: Container(
                  height: 45,
                  width: MediaQuery.of(context).size.width - 40,
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
          ),
        ],
      ),
    );
  }

}
