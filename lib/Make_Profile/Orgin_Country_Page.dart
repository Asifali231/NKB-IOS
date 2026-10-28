import 'package:csc_picker/csc_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart'; // Ensure this import is necessary and correct

class Orgin_Country_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Orgin_Country_Page(
      {required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<Orgin_Country_Page> createState() => _Orgin_Country_PageState();
}

class _Orgin_Country_PageState extends State<Orgin_Country_Page> {
  String countryValue = "";
  String CurrentCountryValue = "";
  String stateValue = "";
  String CurrentStateValue = "";
  String cityValue = "";
  String CurrentCityValue = "";
  String _SameCountry = "";

  String NationalError = "";
  String CurrentError = "";
  String RadioError = "";
  String DiscriptionError = "";

  TextEditingController AddressController = TextEditingController();

  @override
  void dispose() {
    AddressController.dispose();
    super.dispose();
  }

  void validateAndProceed() {
    setState(() {
      NationalError = (countryValue.isEmpty || stateValue.isEmpty)
          ? "Please Select Your National Country & State"
          : "";

      RadioError = _SameCountry.isEmpty ? "Please Select An Option" : "";

      if (_SameCountry == "false") {
        CurrentError =
            (CurrentCountryValue.isEmpty || CurrentStateValue.isEmpty)
                ? "Please Select Your Resident Country & State"
                : "";

        DiscriptionError = AddressController.text.isEmpty
            ? "Please add some detail to make your profile wealthy"
            : "";
      }

      if (NationalError.isEmpty &&
          RadioError.isEmpty &&
          CurrentError.isEmpty &&
          DiscriptionError.isEmpty) {

        UserData.NationalityCountry = countryValue;
        UserData.NationalityState = stateValue;
        UserData.NationalityCity = cityValue;

        UserData.Residence = _SameCountry == "false" ? "Abroad" : "Local";

        if (_SameCountry == "false") {
          UserData.AbroadCountry = CurrentCountryValue;
          UserData.AbroadCity = CurrentCityValue;
          UserData.AbroadState = CurrentStateValue;
          UserData.ResidenceDis = AddressController.text;
        }

        widget.navigateToNextPage();
      }
    });
  }

  void updateCountry(String? value) {
    setState(() {
      countryValue = value ?? "";
      if (countryValue.isNotEmpty && stateValue.isNotEmpty) {
        NationalError = "";
      }
    });
  }

  void updateState(String? value) {
    setState(() {
      stateValue = value ?? "";
      if (countryValue.isNotEmpty && stateValue.isNotEmpty) {
        NationalError = "";
      }
    });
  }

  void updateCity(String? value) {
    setState(() {
      cityValue = value ?? "";
    });
  }

  void updateCurrentCountry(String? value) {
    setState(() {
      CurrentCountryValue = value ?? "";
      if (CurrentCountryValue.isNotEmpty && CurrentStateValue.isNotEmpty) {
        CurrentError = "";
      }
    });
  }

  void updateCurrentState(String? value) {
    setState(() {
      CurrentStateValue = value ?? "";
      if (CurrentCountryValue.isNotEmpty && CurrentStateValue.isNotEmpty) {
        CurrentError = "";
      }
    });
  }

  void updateCurrentCity(String? value) {
    setState(() {
      CurrentCityValue = value ?? "";
    });
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
                        child: Container(
                          width: 158.0,
                          height: 158.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 0.0),
                          ),
                          child: CircleAvatar(
                            radius: 64,
                            child: Image.asset("assets/home.png"),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Well Done ${UserData.Name} !",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          height: 1.5,
                          letterSpacing: 0,
                        ),
                      ),
                      Text(
                        "Tell Us Where are you From",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          height: 1.5,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Please Select Your Country of Nationality",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      CSCPicker(
                        layout: Layout.vertical,
                        onCountryChanged: updateCountry,
                        flagState: CountryFlag.SHOW_IN_DROP_DOWN_ONLY,
                        onStateChanged: updateState,
                        onCityChanged: updateCity,
                      ),
                      SizedBox(height: 5),
                      if (NationalError.isNotEmpty)
                        Text(
                          NationalError,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      SizedBox(height: 10),
                      Text(
                        "Do you currently reside in the same country?",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'true',
                            groupValue: _SameCountry,
                            onChanged: (String? value) {
                              setState(() {
                                _SameCountry = value!;
                                RadioError = "";
                              });
                            },
                          ),
                          Text('Yes, I am local'),
                          Radio<String>(
                            value: 'false',
                            groupValue: _SameCountry,
                            onChanged: (String? value) {
                              setState(() {
                                _SameCountry = value!;
                                RadioError = "";
                              });
                            },
                          ),
                          Text("No, I live abroad"),
                        ],
                      ),
                      if (RadioError.isNotEmpty)
                        Text(
                          RadioError,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      if (_SameCountry == "false") ...[
                        CSCPicker(
                          layout: Layout.vertical,
                          onCountryChanged: updateCurrentCountry,
                          onStateChanged: updateCurrentState,
                          onCityChanged: updateCurrentCity,
                          flagState: CountryFlag.SHOW_IN_DROP_DOWN_ONLY,
                        ),
                        if (CurrentError.isNotEmpty)
                          Text(
                            CurrentError,
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                      SizedBox(height: 10),
                      Text(
                        "Tell us more about your background to impress our community",
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
                        controller: AddressController,
                        decoration: InputDecoration(
                          hintText:
                          'I was born in Pakistan and moved to the UK when I was 12 years old...',
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
                      if (DiscriptionError.isNotEmpty)
                        Text(
                          DiscriptionError,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton(

                onPressed: validateAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
