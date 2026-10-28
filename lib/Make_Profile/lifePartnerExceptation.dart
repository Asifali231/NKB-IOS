import 'package:country_picker/country_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:nikah_blessing/Make_Profile/saveProposalToFireStore.dart';
import 'package:nikah_blessing/User_Home_Pages/AccountModule/PrivacyPolicyPage.dart';
import 'package:nikah_blessing/User_Home_Pages/AccountModule/PolicyPage.dart';
import 'package:select_searchable_list/select_searchable_list.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

class lifePartnerExceptation extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  const lifePartnerExceptation({
    required this.navigateToNextPage,
    required this.navigateToPrevPage,
    super.key,
  });

  @override
  State<lifePartnerExceptation> createState() => _lifePartnerExceptationState();
}

class _lifePartnerExceptationState extends State<lifePartnerExceptation> {
  final List<String> _martialStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Widower',
  ];

  final List<String> _selectedMartialStatuses = [];
  final List<String> _selectedPartnerCountries = [];
  final TextEditingController ethnicGrpTextEditorController =
      TextEditingController();

  SfRangeValues _values = const SfRangeValues(20, 28);
  double minAge = 20;
  double maxAge = 28;
  String partnerSect = '';
  String partnerCountryError = '';
  String partnerSectError = '';
  String partnerMartialStatusError = '';
  bool _isTermsAccepted = false;
  String termsError = '';

  final Map<int, String> sects = {
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
    23: "GÃ¼len Movement (Hizmet)",
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

  void _addCountry(Country country) {
    if (_selectedPartnerCountries.contains(country.name)) return;
    setState(() {
      _selectedPartnerCountries.add(country.name);
      partnerCountryError = '';
    });
  }

  void _removeCountry(String country) {
    setState(() {
      _selectedPartnerCountries.remove(country);
    });
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      useSafeArea: true,
      showPhoneCode: false,
      onSelect: _addCountry,
    );
  }

  Future<void> validateAndNavigate() async {
    setState(() {
      partnerCountryError = '';
      partnerSectError = '';
      partnerMartialStatusError = '';
      termsError = '';
    });

    if (_selectedPartnerCountries.isEmpty) {
      setState(() {
        partnerCountryError = 'Please select at least one partner country';
      });
    }

    if (_selectedMartialStatuses.isEmpty) {
      setState(() {
        partnerMartialStatusError =
            'Please select at least one partner martial status';
      });
    }

    if (partnerSect.isEmpty) {
      setState(() {
        partnerSectError = 'Please select partner sect';
      });
    }

    if (!_isTermsAccepted) {
      setState(() {
        termsError =
            'Please accept the privacy policy and terms and conditions';
      });
    }

    if (_selectedPartnerCountries.isEmpty ||
        _selectedMartialStatuses.isEmpty ||
        partnerSect.isEmpty ||
        !_isTermsAccepted) {
      return;
    }

    UserData.partnerAgeMin = minAge.toInt();
    UserData.partnerAgeMax = maxAge.toInt();
    UserData.partnerSect = partnerSect;
    UserData.partnerCountries = List<String>.from(_selectedPartnerCountries);
    UserData.partnerCast = '';
    UserData.partnerMartialStatus = List<String>.from(_selectedMartialStatuses);

    final saveDataToDatabase = saveProposalToFireStore();
    await saveDataToDatabase.uploadUserData(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 78),
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 25),
            Container(
              margin: const EdgeInsets.only(left: 20, bottom: 5),
              child: Row(
                children: [
                  Image.asset("assets/age.png", height: 30),
                  Container(
                    margin: const EdgeInsets.only(left: 5),
                    child: const Text(
                      "Partner age",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAgeBox(minAge.toInt()),
                const Text("To"),
                _buildAgeBox(maxAge.toInt()),
              ],
            ),
            SizedBox(
              height: 45,
              child: SfRangeSlider(
                min: 18,
                max: 58,
                values: _values,
                interval: 5,
                stepSize: 1,
                showTicks: true,
                showLabels: true,
                enableTooltip: false,
                activeColor: Colors.pink,
                minorTicksPerInterval: 5,
                onChanged: (SfRangeValues values) {
                  setState(() {
                    _values = values;
                    minAge = values.start;
                    maxAge = values.end;
                  });
                },
              ),
            ),
            _buildDivider(),
            Container(
              margin: const EdgeInsets.only(left: 20, bottom: 0),
              child: Row(
                children: [
                  Image.asset("assets/Profile_View_Icons/rings.png",
                      height: 30),
                  Container(
                    margin: const EdgeInsets.only(left: 5),
                    child: const Text(
                      "Partner Martial Status",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Wrap(
                spacing: 5.0,
                runSpacing: 5.0,
                children: _martialStatuses.map((status) {
                  final isSelected = _selectedMartialStatuses.contains(status);
                  return ChoiceChip(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      side: const BorderSide(color: Colors.pink),
                    ),
                    label: Text(
                      status,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.pink,
                    backgroundColor: Colors.white,
                    onSelected: (selected) {
                      setState(() {
                        if (isSelected) {
                          _selectedMartialStatuses.remove(status);
                        } else {
                          _selectedMartialStatuses.add(status);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            if (partnerMartialStatusError.isNotEmpty)
              _buildErrorText(partnerMartialStatusError),
            _buildDivider(),
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Row(
                    children: [
                      Image.asset("assets/countries.png", height: 28),
                      Container(
                        margin: const EdgeInsets.only(left: 5),
                        child: const Text(
                          "Partner Countries",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width - 40,
                  margin:
                      const EdgeInsets.only(left: 20, bottom: 10, right: 20),
                  child: OutlinedButton.icon(
                    onPressed: _openCountryPicker,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Add Country'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.pink,
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width - 40,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: _selectedPartnerCountries.isEmpty
                      ? const Text(
                          'No countries selected yet',
                          style: TextStyle(color: Colors.grey),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedPartnerCountries.map((country) {
                            return Chip(
                              label: Text(country),
                              onDeleted: () => _removeCountry(country),
                              backgroundColor: Colors.pink.shade50,
                              deleteIconColor: Colors.pink,
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
            if (partnerCountryError.isNotEmpty)
              _buildErrorText(partnerCountryError),
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 20, bottom: 0, top: 10),
                  child: Row(
                    children: [
                      Image.asset("assets/sect.png", height: 30),
                      Container(
                        margin: const EdgeInsets.only(left: 5),
                        child: const Text(
                          "Partner Sect",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20, right: 20, left: 20),
                  height: 65,
                  width: double.maxFinite,
                  child: DropDownTextField(
                    textEditingController: ethnicGrpTextEditorController,
                    title: 'Partner Sect',
                    hint: 'Select partner sect',
                    options: sects,
                    onChanged: (selectedValue) {
                      setState(() {
                        final int? selectedIndex = selectedValue?.first;
                        partnerSect = sects[selectedIndex] ?? 'Unknown';
                      });
                    },
                  ),
                ),
              ],
            ),
            if (partnerSectError.isNotEmpty) _buildErrorText(partnerSectError),
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isTermsAccepted,
                    onChanged: (bool? value) {
                      setState(() {
                        _isTermsAccepted = value ?? false;
                        if (_isTermsAccepted) {
                          termsError = "";
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'I accept the ',
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'privacy policy',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PrivacyPolicyPage(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(
                            text: ' and ',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'terms and conditions',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PolicyPage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (termsError.isNotEmpty) _buildErrorText(termsError),
            const SizedBox(height: 25),
            InkWell(
              onTap: validateAndNavigate,
              child: Container(
                height: 45,
                width: MediaQuery.of(context).size.width - 40,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: Colors.pink,
                  border: Border.all(color: Colors.transparent),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ' Create Account ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeBox(int age) {
    return Container(
      margin: const EdgeInsets.all(5),
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$age',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      padding: const EdgeInsets.all(30),
      child: const Divider(color: Colors.pink),
    );
  }

  Widget _buildErrorText(String error) {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      height: 18,
      width: MediaQuery.of(context).size.width,
      child: Text(
        error,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
