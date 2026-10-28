import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nikah_blessing/Admin_Module/AdminUpdateUserPackage.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:quickalert/quickalert.dart';
import 'package:select_searchable_list/select_searchable_list.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../User_Home_Pages/user_main.dart';

class UpdateFilters extends StatefulWidget {
  const UpdateFilters({super.key});

  @override
  State<UpdateFilters> createState() => _UpdateFiltersState();
}

class _UpdateFiltersState extends State<UpdateFilters> {
  final List<String> _martialStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Widower',
  ];

  final List<String> _selectedMartialStatuses = [];
  final List<String> _selectedPartnerCountries = [];
  final TextEditingController _ethnicGroupController = TextEditingController();

  SfRangeValues _values = const SfRangeValues(20, 28);
  double minAge = 20;
  double maxAge = 28;
  String partnerSect = '';

  String partnerMartialStatusError = '';
  String partnerCountryError = '';
  String partnerSectError = '';

  final Map<int, String> ethnicGroups = {
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

  @override
  void initState() {
    super.initState();
    _loadExistingFilters();
  }

  Future<void> _loadExistingFilters() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final data = userDoc.data();
    if (data == null) return;

    final existingMin =
        (data['PartnerMinAge '] ?? UserData.partnerAgeMin) as num;
    final existingMax =
        (data['PartnerMaxAge '] ?? UserData.partnerAgeMax) as num;
    final existingSect = (data['PartnerSect '] ?? '').toString();
    final existingCountries = _normalizeCountryList(data['PartnerCountry ']);
    final existingStatuses =
        List<String>.from((data['PartnerMartialStatus '] as List?) ?? const []);

    setState(() {
      minAge = existingMin.toDouble();
      maxAge = existingMax.toDouble();
      _values = SfRangeValues(minAge, maxAge);
      partnerSect = existingSect;
      _selectedPartnerCountries
        ..clear()
        ..addAll(existingCountries);
      _selectedMartialStatuses
        ..clear()
        ..addAll(existingStatuses);
    });
  }

  List<String> _normalizeCountryList(dynamic rawValue) {
    if (rawValue is List) {
      return rawValue
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .map((item) => item.toString())
          .toList();
    }

    if (rawValue is String && rawValue.trim().isNotEmpty) {
      if (rawValue.contains(',')) {
        return rawValue
            .split(',')
            .map((country) => country.trim())
            .where((country) => country.isNotEmpty)
            .toList();
      }
      return [rawValue.trim()];
    }

    return [];
  }

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

    if (_selectedPartnerCountries.isEmpty ||
        partnerSect.isEmpty ||
        _selectedMartialStatuses.isEmpty) {
      return;
    }

    UserData.partnerAgeMin = minAge.toInt();
    UserData.partnerAgeMax = maxAge.toInt();
    UserData.partnerSect = partnerSect;
    UserData.partnerCountries = List<String>.from(_selectedPartnerCountries);
    UserData.partnerCast = '';
    UserData.partnerMartialStatus = List<String>.from(_selectedMartialStatuses);

    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: "Updating ..",
      text: "Please wait a sec",
    );

    UserPackage userPackage = UserPackage();
    await userPackage.updateUserFilter(
      UserData.partnerAgeMin,
      UserData.partnerAgeMax,
      UserData.partnerSect,
      UserData.partnerCountries,
      UserData.partnerMartialStatus,
    );

    if (!mounted) return;
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preferences Updated");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserMain()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 25),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                    final isSelected =
                        _selectedMartialStatuses.contains(status);
                    return ChoiceChip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      label: Text(status),
                      selected: isSelected,
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
                        const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                    child: OutlinedButton.icon(
                      onPressed: _openCountryPicker,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add Country'),
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
                      textEditingController: _ethnicGroupController,
                      title: 'Partner Sect',
                      hint: 'Select partner sect',
                      options: ethnicGroups,
                      onChanged: (selectedValue) {
                        setState(() {
                          final int? selectedIndex = selectedValue?.first;
                          partnerSect =
                              ethnicGroups[selectedIndex] ?? 'Unknown';
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (partnerSectError.isNotEmpty)
                _buildErrorText(partnerSectError),
              const SizedBox(height: 25),
              InkWell(
                onTap: validateAndNavigate,
                child: Container(
                  height: 45,
                  width: MediaQuery.of(context).size.width - 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: Colors.transparent,
                    border: Border.all(color: Colors.black54),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Apply',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$age',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 25),
      child: const Divider(),
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
