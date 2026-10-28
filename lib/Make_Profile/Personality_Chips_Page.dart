import 'package:chip_list/chip_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nikah_blessing/Make_Profile/saveProposalToFireStore.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';
import 'package:nikah_blessing/User_Home_Pages/user_main.dart';

class Personality_Chips_Page extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Personality_Chips_Page({required this.navigateToNextPage, required this.navigateToPrevPage});

  @override
  State<Personality_Chips_Page> createState() => _Personality_Chips_PageState();
}

class _Personality_Chips_PageState extends State<Personality_Chips_Page> {
  final List<String> Disabilities = [
    'Blindness',
    'Low Vision with glasses',
    'Color Blind',
    'Deafness',
    'Hearing Impairment',
    'Mobility Impairment',
    'Wheelchair Use',
    'Amputation',
    'Cognitive Impairment',
    'Learning Disability',
    'Autism Spectrum Disorder',
    'Epilepsy',
    'Chronic Illness',
    'Mental Health Conditions',
    'Speech Impairment',
    'Neurological Disorder',
    'Intellectual Disability',
    'Muscular Dystrophy',
    'Multiple Sclerosis',
    'Parkinson\'s Disease',
    'Stroke',
    'Traumatic Brain Injury',
    'Spinal Cord Injury',
    'Chronic Pain',
    'Fibromyalgia',
    'Rheumatoid Arthritis',
    'Hearing Loss',
    'Sensory Processing Disorder',
    'Dyslexia',
    'Dyscalculia',
    'Dysgraphia',
    'Attention Deficit Hyperactivity Disorder (ADHD)',
    'Post-Traumatic Stress Disorder (PTSD)',
    'Bipolar Disorder',
    'Schizophrenia',
    'Obsessive-Compulsive Disorder (OCD)',
    'Anxiety Disorder',
    'Asthma',
    'Diabetes',
    'Chronic Fatigue Syndrome',
    'Kidney Disease',
    'Multiple Chemical Sensitivity',
    'Stroke',
    'Epilepsy',
    'Obesity',
    'Chronic Back Pain',
    'Arthritis',
    'Sickle Cell Disease',
    'Hemophilia',
    'Lupus',
    'Fibromyalgia',
    'Cystic Fibrosis',
    'Tuberculosis',
    'Cancer',
    'HIV/AIDS',
    'Gastrointestinal Disorders',
    'Endometriosis',
    'Ehlers-Danlos Syndrome',
    'Cerebral Palsy',
    'Rett Syndrome',
    'Prader-Willi Syndrome',
    'Williams Syndrome',
    'Angelman Syndrome',
    'Charcot-Marie-Tooth Disease',
    'Neurofibromatosis',
    'Albinism',
    'Marfan Syndrome',
    'Turner Syndrome',
    'Klinefelter Syndrome',
    'Wilm’s Tumor',
    'Sturge-Weber Syndrome',
    'Apert Syndrome',
    'Craniofacial Disorders',
    'Scoliosis',
    'Hemiplegia',
    'Diplegia',
    'Quadriplegia',
    'Myotonic Dystrophy',
  ];

  final List<String> _hobbies = [
    'Reading',
    'Traveling',
    'Gaming',
    'Cooking',
    'Photography',
    'Gym',
    'Drawing',
    'Writing',
    'Hiking',
    'Swimming',
    'Cycling',
    'Yoga',
    'Running',
    'Fishing',
    'Chess',
    'Gardening',
    // 'Dancing',
    'Baking',
    'Singing',
    'Crafting',
    'Knitting',
    'Meditation',
    'Astronomy',
    'Travel Blogging',
    'Calligraphy',
    'Coding',
    // 'Hunting',
    // 'Cricket',
    // 'Football',
    // 'Golf',
    // 'Tennis',
    // 'Basketball',
    // 'Volleyball',
    // 'Skating',
    // 'Surfing',
    // 'Skiing',
    // 'Snowboarding',
    // 'Reading Novels',
    // 'Exploring',
  ];

  final List<String> _selectedHobbies = [];
  String hobbiesError = "";

  Future<void> validateAndNavigate() async {
    setState(() {
      hobbiesError = "";
    });

    if (_selectedHobbies.length < 6) {
      setState(() {
        hobbiesError = "Please Select at least 5 hobbies";
      });
    } else {
      UserData.hobbies = _selectedHobbies;
      widget.navigateToNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 78),
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 20, left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select your hobbies",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Wrap(
                      spacing: 5.0,
                      runSpacing: 5.0,
                      children: _hobbies.map((hobby) {
                        final isSelected = _selectedHobbies.contains(hobby);
                        return ChoiceChip(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            side: BorderSide(color: Colors.pink),
                          ),
                          label: Text(
                            hobby,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.pink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.pink,
                          backgroundColor: Colors.white,
                          onSelected: (_) {
                            setState(() {
                              if (_selectedHobbies.contains(hobby)) {
                                _selectedHobbies.remove(hobby);
                              } else {
                                _selectedHobbies.add(hobby);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      validateAndNavigate();
                    },
                    child: Container(
                      height: 45,
                      width: MediaQuery.of(context).size.width - 40,
                      margin: EdgeInsets.only(left: 0, right: 0, bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.transparent,
                        border: Border.all(color: Colors.black54),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
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
                  Visibility(
                    visible: hobbiesError != "",
                    child: Text(
                      hobbiesError.toString(),
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}