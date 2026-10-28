import 'package:currency_input_field/currency_input_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:select_searchable_list/select_searchable_list.dart';

class Profession_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Profession_Page({required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<Profession_Page> createState() => _Profession_PageState();
}

class _Profession_PageState extends State<Profession_Page> {

  String SelectedProfession = "";
  String SelectedJobCountry = "";

  String ProfessionError = "";
  String JobCountryError = "";
  String descriptionError = "";


  Map<int ,String > ProfessionMap= {};
  Map<int ,String > IncomeMap= {};

  TextEditingController ProfessionTextEditingController = new TextEditingController();
  TextEditingController JobCountryTextEditingController = new TextEditingController();
  TextEditingController DisTextEditorController = new TextEditingController();

  Map<int, String> CountryMap = {
    0: "Afghanistan",
    1: "Albania",
    2: "Algeria",
    3: "Andorra",
    4: "Angola",
    5: "Antigua and Barbuda",
    6: "Argentina",
    7: "Armenia",
    8: "Australia",
    9: "Austria",
    10: "Azerbaijan",
    11: "Bahamas",
    12: "Bahrain",
    13: "Bangladesh",
    14: "Barbados",
    15: "Belarus",
    16: "Belgium",
    17: "Belize",
    18: "Benin",
    19: "Bhutan",
    20: "Bolivia",
    21: "Bosnia and Herzegovina",
    22: "Botswana",
    23: "Brazil",
    24: "Brunei",
    25: "Bulgaria",
    26: "Burkina Faso",
    27: "Burundi",
    28: "Cabo Verde",
    29: "Cambodia",
    30: "Cameroon",
    31: "Canada",
    32: "Central African Republic",
    33: "Chad",
    34: "Chile",
    35: "China",
    36: "Colombia",
    37: "Comoros",
    38: "Congo, Democratic Republic of the",
    39: "Congo, Republic of the",
    40: "Costa Rica",
    41: "Croatia",
    42: "Cuba",
    43: "Cyprus",
    44: "Czechia",
    45: "Denmark",
    46: "Djibouti",
    47: "Dominica",
    48: "Dominican Republic",
    49: "Ecuador",
    50: "Egypt",
    51: "El Salvador",
    52: "Equatorial Guinea",
    53: "Eritrea",
    54: "Estonia",
    55: "Eswatini",
    56: "Ethiopia",
    57: "Fiji",
    58: "Finland",
    59: "France",
    60: "Gabon",
    61: "Gambia",
    62: "Georgia",
    63: "Germany",
    64: "Ghana",
    65: "Greece",
    66: "Grenada",
    67: "Guatemala",
    68: "Guinea",
    69: "Guinea-Bissau",
    70: "Guyana",
    71: "Haiti",
    72: "Honduras",
    73: "Hungary",
    74: "Iceland",
    75: "India",
    76: "Indonesia",
    77: "Iran",
    78: "Iraq",
    79: "Ireland",
    80: "Israel",
    81: "Italy",
    82: "Jamaica",
    83: "Japan",
    84: "Jordan",
    85: "Kazakhstan",
    86: "Kenya",
    87: "Kiribati",
    88: "Korea, North",
    89: "Korea, South",
    90: "Kosovo",
    91: "Kuwait",
    92: "Kyrgyzstan",
    93: "Laos",
    94: "Latvia",
    95: "Lebanon",
    96: "Lesotho",
    97: "Liberia",
    98: "Libya",
    99: "Liechtenstein",
    100: "Lithuania",
    101: "Luxembourg",
    102: "Madagascar",
    103: "Malawi",
    104: "Malaysia",
    105: "Maldives",
    106: "Mali",
    107: "Malta",
    108: "Marshall Islands",
    109: "Mauritania",
    110: "Mauritius",
    111: "Mexico",
    112: "Micronesia",
    113: "Moldova",
    114: "Monaco",
    115: "Mongolia",
    116: "Montenegro",
    117: "Morocco",
    118: "Mozambique",
    119: "Myanmar",
    120: "Namibia",
    121: "Nauru",
    122: "Nepal",
    123: "Netherlands",
    124: "New Zealand",
    125: "Nicaragua",
    126: "Niger",
    127: "Nigeria",
    128: "North Macedonia",
    129: "Norway",
    130: "Oman",
    131: "Pakistan",
    132: "Palau",
    133: "Panama",
    134: "Papua New Guinea",
    135: "Paraguay",
    136: "Peru",
    137: "Philippines",
    138: "Poland",
    139: "Portugal",
    140: "Qatar",
    141: "Romania",
    142: "Russia",
    143: "Rwanda",
    144: "Saint Kitts and Nevis",
    145: "Saint Lucia",
    146: "Saint Vincent and the Grenadines",
    147: "Samoa",
    148: "San Marino",
    149: "Sao Tome and Principe",
    150: "Saudi Arabia",
    151: "Senegal",
    152: "Serbia",
    153: "Seychelles",
    154: "Sierra Leone",
    155: "Singapore",
    156: "Slovakia",
    157: "Slovenia",
    158: "Solomon Islands",
    159: "Somalia",
    160: "South Africa",
    161: "South Sudan",
    162: "Spain",
    163: "Sri Lanka",
    164: "Sudan",
    165: "Suriname",
    166: "Sweden",
    167: "Switzerland",
    168: "Syria",
    169: "Taiwan",
    170: "Tajikistan",
    171: "Tanzania",
    172: "Thailand",
    173: "Timor-Leste",
    174: "Turkey",
    175: "Turkmenistan",
    176: "Tuvalu",
    177: "Uganda",
    178: "Ukraine",
    179: "United Arab Emirates",
    180: "United Kingdom",
    181: "United States",
    182: "Uruguay",
    183: "Uzbekistan",
    184: "Vanuatu",
    185: "Vatican City",
    186: "Venezuela",
    187: "Vietnam",
    188: "Yemen",
    189: "Zambia",
    190: "Zimbabwe",
  };
  Map<int, String> professions = {
    // Common Professions in Pakistan
    0: "Student",
    1: "Not Working",
    2: "House Lady",
    3: "Doctor",
    4: "Engineer",
    5: "Teacher",
    6: "Accountant",
    7: "Nurse",
    8: "Pharmacist",
    9: "Lawyer",
    10: "Architect",
    11: "IT Support Specialist",
    12: "Software Developer",
    13: "Civil Engineer",
    14: "Electrical Engineer",
    15: "Mechanical Engineer",
    16: "Professor",
    17: "Lecturer",
    18: "Business Manager",
    19: "Banker",
    20: "Journalist",
    21: "Photographer",
    22: "Marketing Manager",
    23: "Sales Representative",
    24: "Research Scientist",
    25: "Social Worker",
    26: "Real Estate Agent",
    27: "Graphic Designer",
    28: "Web Developer",
    29: "Data Scientist",
    30: "Content Writer",
    31: "HR Manager",
    32: "Tourism Manager",
    33: "Hotel Manager",
    34: "Fitness Trainer",
    35: "Lab Technician",
    36: "Biologist",
    37: "Chemist",
    38: "Translator",
    39: "Editor",
    40: "Animator",
    41: "Interior Designer",
    42: "Legal Assistant",
    43: "Security Guard",
    44: "Logistics Coordinator",
    45: "Event Planner",
    46: "Public Relations Specialist",
    47: "Property Manager",
    48: "Insurance Agent",
    49: "Data Analyst",
    50: "Economist",
    51: "Clinical Psychologist",
    52: "School Counselor",
    53: "Craftsman",
    54: "DJ",
    55: "Production Assistant",
    56: "Screenwriter",
    57: "Film Director",
    58: "Art Director",
    59: "Film Editor",
    60: "Producer",
    61: "Voice Actor",
    62: "Sound Designer",
    63: "IT Consultant",
    64: "Database Administrator",
    65: "Systems Analyst",
    66: "Cybersecurity Analyst",
    67: "Network Administrator",
    68: "Cloud Engineer",
    69: "Robotics Engineer",
    70: "Machine Learning Engineer",
    71: "Blockchain Developer",
    72: "User Experience Designer",
    73: "Software Engineer",
    74: "Biomedical Engineer",
    75: "Clinical Laboratory Technologist",
    76: "Genetic Counselor",
    77: "Medical Writer",
    78: "Health Information Technician",
    79: "Environmental Consultant",
    80: "Regulatory Affairs Specialist",
    81: "Quality Assurance Analyst",
    82: "Project Manager",
    83: "Public Administrator",
    84: "Lobbyist",
    85: "Campaign Manager",
    86: "Corporate Trainer",
    87: "Health and Safety Officer",
    88: "Talent Agent",
    89: "Entertainment Manager",
    90: "Voiceover Artist",
    91: "Stage Manager",
    92: "Cinematographer",
    93: "Set Designer",
    94: "Music Producer",
    95: "Lighting Technician",
    96: "Special Effects Artist",
    97: "Gaffer",
    98: "Grip",
    99: "Makeup Artist",
    100: "Storyboard Artist",
    101: "Casting Director",
    102: "Production Designer",
    103: "Script Supervisor",
    104: "Stunt Coordinator",
    105: "Post-production Supervisor",
    106: "Film Critic",
    107: "Publicist",
    108: "Content Creator",
    109: "Web Content Manager",
    110: "SEO Specialist",
    111: "Digital Marketer",
    112: "Affiliate Marketer",
    113: "Online Community Manager",
    114: "Data Privacy Officer",
    115: "Penetration Tester",
    116: "Information Security Manager",
    117: "Business Intelligence Analyst",
    118: "ERP Consultant",
    119: "IT Project Manager",
    120: "IT Auditor",
    121: "Automation Engineer",
    122: "Artificial Intelligence Researcher",
    123: "Toxicologist",
    124: "Forensic Scientist",
    125: "Nanotechnologist",
    126: "Hydrologist",
    127: "Meteorologist",
    128: "Marine Engineer",
    129: "Ethnographer",
    130: "Cultural Advisor",
    131: "Sports Coach",
    132: "Rehabilitation Specialist",
    133: "Agricultural Scientist",
    134: "Dramatist",
    135: "Fisheries Biologist",
    136: "Clinical Research Coordinator",
    137: "Energy Consultant",
    138: "Public Health Analyst",
    139: "Social Media Manager",
    140: "Online Teacher",
    141: "Homeschool Teacher",
    142: "Early Childhood Educator",
    143: "Career and Technical Education Teacher",
    144: "Adult Education Teacher",
    145: "Teaching Assistant",
    146: "Special Education Teacher",
    147: "ESL Teacher",
    148: "Language Teacher",
    149: "Business Education Teacher",
    150: "Technology Teacher",
    151: "Computer Science Teacher",
    152: "Physical Education Teacher",
    153: "Art Teacher",
    154: "Music Teacher",
    155: "Science Teacher",
    156: "Mathematics Teacher",
    157: "History Teacher",
    158: "Social Studies Teacher",
    159: "High School Teacher",
    160: "University Professor",
    161: "Lecturer",
    162: "Professor",
    163: "General Practitioner",
    164: "Pediatrician",
    165: "Surgeon",
    166: "Cardiologist",
    167: "Neurologist",
    168: "Oncologist",
    169: "Orthopedic Surgeon",
    170: "Gynecologist",
    171: "Dermatologist",
    172: "Ophthalmologist",
    173: "ENT Specialist",
    174: "Anesthesiologist",
    175: "Psychiatrist",
    176: "Urologist",
    177: "Endocrinologist",
    178: "Rheumatologist",
    179: "Pulmonologist",
    180: "Gastroenterologist",
    181: "Nephrologist",
    182: "Hematologist",
    183: "Internist",
    184: "Sports Medicine Doctor",
    185: "Emergency Medicine Physician",
    186: "Addiction Specialist",
    187: "Clinical Geneticist",
    188: "Occupational Medicine Specialist",
    189: "Preventive Medicine Specialist",
    190: "Pathologist",
    191: "Civil Engineer",
    192: "Mechanical Engineer",
    193: "Electrical Engineer",
    194: "Chemical Engineer",
    195: "Aerospace Engineer",
    196: "Structural Engineer",
    197: "Environmental Engineer",
    198: "Biomedical Engineer",
    199: "Industrial Engineer",
    200: "Agricultural Engineer",
    201: "Nuclear Engineer",
    202: "Marine Engineer",
    203: "Systems Engineer",
    204: "Automotive Engineer",
    205: "Mining Engineer",
    206: "Petroleum Engineer",
    207: "Geotechnical Engineer",
    208: "Transportation Engineer",
    209: "Robotics Engineer",
    210: "Energy Engineer",
    211: "Materials Engineer",
    212: "Naval Architect",
    213: "Computer Hardware Engineer",
    // Add more professions as needed
  };

  String selectedCurrency = 'PKR';
  double enteredAmount = 0.0;

  void validateAndNavigate()
  {
    setState(() {
      
      ProfessionError = "";
      JobCountryError = "";
      descriptionError = "";

      // Validate Degree Level
      if (SelectedProfession == "") {
        ProfessionError = 'Please select a degree level';
      }

      // Validate Field
      if (SelectedJobCountry == "") {
        JobCountryError = 'Please select a field of study';
      }

      // Validate Description
      if (DisTextEditorController.text.toString() == "") {
        descriptionError = 'Description cannot be empty';

      }


      if(SelectedProfession != null &&  SelectedJobCountry != null && DisTextEditorController.text != "") {

        UserData.Profession = SelectedProfession;
        UserData.JobCountry = SelectedJobCountry;
        UserData.JobDesc = DisTextEditorController.text.toString();

        //
        widget.navigateToNextPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                          border: Border.all(
                            color: Colors.black,
                            width: 0.0,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 64,
                          child: Image.asset("assets/work.png"),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "So ${UserData.Name}, what do you do professionally?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      "Please mention your highest degree obtained",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.5,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 35),
                    DropDownTextField(
                      textEditingController: ProfessionTextEditingController,
                      title: 'Profession',
                      hint: 'Select your profession',
                      options: professions,
                      onChanged: (selectedValue) {
                        setState(() {
                          ProfessionError = "";
                          int? selectedIndex = selectedValue?.first;
                          SelectedProfession = professions[selectedIndex] ?? 'Unknown';
                        });
                      },
                    ),
                    Visibility(
                      visible: ProfessionError.isNotEmpty,
                      child: Text(
                        ProfessionError,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 15),
                    DropDownTextField(
                      textEditingController: JobCountryTextEditingController,
                      title: 'Current Country',
                      hint: 'Mention the country name',
                      options: CountryMap,
                      onChanged: (selectedValue) {
                        setState(() {
                          JobCountryError = "";
                          int? selectedIndex = selectedValue?.first;
                          SelectedJobCountry = CountryMap[selectedIndex] ?? 'Unknown';
                        });
                      },
                    ),
                    Visibility(
                      visible: JobCountryError.isNotEmpty,
                      child: Text(
                        JobCountryError,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Feel free to add anything you want",
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
                      controller: DisTextEditorController,
                      decoration: InputDecoration(
                        hintText: 'I own my own business and also invest in stocks ...',
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
