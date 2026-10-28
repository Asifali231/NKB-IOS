import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:select_searchable_list/select_searchable_list.dart';

import '../DataClass/UserData.dart';

class Any_Disability_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Any_Disability_Page({required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<Any_Disability_Page> createState() => _Any_Disability_PageState();
}

class _Any_Disability_PageState extends State<Any_Disability_Page> {


  TextEditingController DisabilityTextEditorController =
  new TextEditingController();
  String _sharewith = '2';
  
  TextEditingController DisabilityDisTextEDitorController =new TextEditingController();

  String SelectedDisablity ="";
  String SelectedDisablity_Error ="";
  String SelectedDisablityDis ="";
  String SelectedDisablityDis_Error ="";


  void validateAndNavigate()
  {
    setState(() {

      SelectedDisablity_Error ="";
      SelectedDisablityDis_Error ="";

      if (DisabilityTextEditorController.text.toString() == "") {
        SelectedDisablity_Error = 'Please select an option if none select none';
      }

      if (DisabilityDisTextEDitorController.text.toString() == "") {
        SelectedDisablityDis_Error = 'Please add some description';
      }

      if(DisabilityTextEditorController.text.toString() != "" && DisabilityDisTextEDitorController.text.toString() != "")
        {

          UserData.Disability = DisabilityTextEditorController.text.toString();
          UserData.DisabilityDis = DisabilityDisTextEDitorController.text.toString();
          UserData.DisabilityShareWith = _sharewith.toString();
          widget.navigateToNextPage();

        }


    });
  }

  String UserName = UserData.Name;


  final Map<int, String> disabilities = {
    0: 'None',
    1: 'Low Vision with glasses',
    2: 'Color Blind',
    3: 'Deafness',
    4: 'Hearing Impairment',
    5: 'Mobility Impairment',
    6: 'Wheelchair Use',
    7: 'Amputation',
    8: 'Cognitive Impairment',
    9: 'Learning Disability',
    10: 'Autism Spectrum Disorder',
    11: 'Epilepsy',
    12: 'Chronic Illness',
    13: 'Mental Health Conditions',
    14: 'Speech Impairment',
    15: 'Neurological Disorder',
    16: 'Intellectual Disability',
    17: 'Muscular Dystrophy',
    18: 'Multiple Sclerosis',
    19: 'Parkinson\'s Disease',
    20: 'Stroke',
    21: 'Traumatic Brain Injury',
    22: 'Spinal Cord Injury',
    23: 'Chronic Pain',
    24: 'Fibromyalgia',
    25: 'Rheumatoid Arthritis',
    26: 'Hearing Loss',
    27: 'Sensory Processing Disorder',
    28: 'Dyslexia',
    29: 'Dyscalculia',
    30: 'Dysgraphia',
    31: 'Attention Deficit Hyperactivity Disorder (ADHD)',
    32: 'Post-Traumatic Stress Disorder (PTSD)',
    33: 'Bipolar Disorder',
    34: 'Schizophrenia',
    35: 'Obsessive-Compulsive Disorder (OCD)',
    36: 'Anxiety Disorder',
    37: 'Asthma',
    38: 'Diabetes',
    39: 'Chronic Fatigue Syndrome',
    40: 'Kidney Disease',
    41: 'Multiple Chemical Sensitivity',
    42: 'Obesity',
    43: 'Chronic Back Pain',
    44: 'Arthritis',
    45: 'Sickle Cell Disease',
    46: 'Hemophilia',
    47: 'Lupus',
    48: 'Cystic Fibrosis',
    49: 'Tuberculosis',
    50: 'Cancer',
    51: 'HIV/AIDS',
    52: 'Gastrointestinal Disorders',
    53: 'Endometriosis',
    54: 'Ehlers-Danlos Syndrome',
    55: 'Cerebral Palsy',
    56: 'Rett Syndrome',
    57: 'Prader-Willi Syndrome',
    58: 'Williams Syndrome',
    59: 'Angelman Syndrome',
    60: 'Charcot-Marie-Tooth Disease',
    61: 'Neurofibromatosis',
    62: 'Albinism',
    63: 'Marfan Syndrome',
    64: 'Turner Syndrome',
    65: 'Klinefelter Syndrome',
    66: 'Wilm’s Tumor',
    67: 'Sturge-Weber Syndrome',
    68: 'Apert Syndrome',
    69: 'Craniofacial Disorders',
    70: 'Scoliosis',
    71: 'Hemiplegia',
    72: 'Diplegia',
    73: 'Quadriplegia',
    74: 'Myotonic Dystrophy',
  };


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
                  padding: EdgeInsets.only(right: 20, left: 20),
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
                              color: Colors.transparent,
                              width: 0.0,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: Image.asset("assets/health.png"),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "$UserName ! ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: "it's good to be honest at start of relation",
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
                      DropDownTextField(
                        textEditingController: DisabilityTextEditorController,
                        title: 'Any Disability',
                        hint: 'Select your disability or medical condition',
                        options: disabilities,
                        multiple: true,
                        backgroundColor: Colors.white,
                        onChanged: (selectedValue) {
                          setState(() {
                            SelectedDisablity =
                                DisabilityTextEditorController.text.toString();
                          });
                        },
                      ),
                      if (SelectedDisablity_Error.isNotEmpty)
                        Text(
                          SelectedDisablity_Error,
                          style: TextStyle(color: Colors.red),
                        ),
                      SizedBox(height: 10),
                      TextField(
                        controller: DisabilityDisTextEDitorController,
                        maxLines: 6,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText:
                          'I live with my mother and my siblings i.e one brother two sisters .......',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      if (SelectedDisablityDis_Error.isNotEmpty)
                        Text(
                          SelectedDisablityDis_Error,
                          style: TextStyle(color: Colors.red),
                        ),
                      SizedBox(height: 10),
                      Text(
                        "Share this info with",
                        style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: '1',
                                      groupValue: _sharewith,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _sharewith = value!;
                                        });
                                      },
                                    ),
                                    Text('Only with friends'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: '2',
                                      groupValue: _sharewith,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _sharewith = value!;
                                        });
                                      },
                                    ),
                                    Text('Only to myself'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio<String>(
                                      value: '3',
                                      groupValue: _sharewith,
                                      onChanged: (String? value) {
                                        setState(() {
                                          _sharewith = value!;
                                        });
                                      },
                                    ),
                                    Text('With everyone'),
                                  ],
                                ),
                              ),
                            ],
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
