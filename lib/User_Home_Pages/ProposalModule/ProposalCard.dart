import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nikah_blessing/FirebaseOperation/FirebaseOperations.dart';
import 'package:nikah_blessing/User_Home_Pages/ProposalModule/profile_view_page.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';

import '../../Make_Profile/Profile_Questionnaire_main.dart';

class ProposalCard extends StatelessWidget {
  final Map<String, dynamic> proposalData;

  ProposalCard({required this.proposalData});

  Map<String, String> countriesCurrencies = {
    'Afghanistan': 'afn',
    'Albania': 'all',
    'Algeria': 'dzd',
    'Andorra': 'eur',
    'Angola': 'aoa',
    'Antigua and Barbuda': 'xcd',
    'Argentina': 'ars',
    'Armenia': 'amd',
    'Australia': 'aud',
    'Austria': 'eur',
    'Azerbaijan': 'azn',
    'Bahamas': 'bsd',
    'Bahrain': 'bhd',
    'Bangladesh': 'bdt',
    'Barbados': 'bbd',
    'Belarus': 'byn',
    'Belgium': 'eur',
    'Belize': 'bzd',
    'Benin': 'xof',
    'Bhutan': 'inr',
    'Bolivia': 'bob',
    'Bosnia and Herzegovina': 'bam',
    'Botswana': 'bwp',
    'Brazil': 'brl',
    'Brunei': 'bnd',
    'Bulgaria': 'bgn',
    'Burkina Faso': 'xof',
    'Burundi': 'bif',
    'Cabo Verde': 'cve',
    'Cambodia': 'KHR',
    'Cameroon': 'xaf',
    'Canada': 'cad',
    'Central African Republic': 'xaf',
    'Chad': 'xaf',
    'Chile': 'clp',
    'China': 'cny',
    'Colombia': 'cop',
    'Comoros': 'kmf',
    'Congo, Democratic Republic of the': 'cdf',
    'Congo, Republic of the': 'xaf',
    'Costa Rica': 'crc',
    'Croatia': 'hrk',
    'Cuba': 'cup',
    'Cyprus': 'eur',
    'Czech Republic': 'czk',
    'Denmark': 'dkk',
    'Djibouti': 'djf',
    'Dominica': 'xcd',
    'Dominican Republic': 'dop',
    'Ecuador': 'usd',
    'Egypt': 'egp',
    'El Salvador': 'usd',
    'Equatorial Guinea': 'xaf',
    'Eritrea': 'ern',
    'Estonia': 'eur',
    'Eswatini': 'szl',
    'Ethiopia': 'etb',
    'Fiji': 'fjd',
    'Finland': 'eur',
    'France': 'eur',
    'Gabon': 'xaf',
    'Gambia': 'gmd',
    'Georgia': 'gel',
    'Germany': 'eur',
    'Ghana': 'ghs',
    'Greece': 'eur',
    'Grenada': 'xcd',
    'Guatemala': 'gtq',
    'Guinea': 'gnf',
    'Guinea-Bissau': 'xof',
    'Guyana': 'gyd',
    'Haiti': 'htg',
    'Honduras': 'hnl',
    'Hungary': 'huf',
    'Iceland': 'isk',
    'India': 'inr',
    'Indonesia': 'idr',
    'Iran': 'irr',
    'Iraq': 'iqd',
    'Ireland': 'eur',
    'Israel': 'ils',
    'Italy': 'eur',
    'Jamaica': 'jmd',
    'Japan': 'jpy',
    'Jordan': 'jod',
    'Kazakhstan': 'kzt',
    'Kenya': 'kes',
    'Kiribati': 'aud',
    'Korea, North': 'kpw',
    'Korea, South': 'krw',
    'Kuwait': 'kwd',
    'Kyrgyzstan': 'kgs',
    'Laos': 'lak',
    'Latvia': 'eur',
    'Lebanon': 'lbp',
    'Lesotho': 'lsl',
    'Liberia': 'l outrd',
    'Libya': 'lyd',
    'Liechtenstein': 'chf',
    'Lithuania': 'eur',
    'Luxembourg': 'eur',
    'Madagascar': 'mga',
    'Malawi': 'mwk',
    'Malaysia': 'myr',
    'Maldives': 'mvr',
    'Mali': 'xof',
    'Malta': 'eur',
    'Marshall Islands': 'usd',
    'Mauritania': 'mru',
    'Mauritius': 'mur',
    'Mexico': 'mxn',
    'Micronesia': 'usd',
    'Moldova': 'mdl',
    'Monaco': 'eur',
    'Mongolia': 'mnt',
    'Montenegro': 'eur',
    'Morocco': 'mad',
    'Mozambique': 'mzn',
    'Myanmar': 'mmk',
    'Namibia': 'nad',
    'Nauru': 'aud',
    'Nepal': 'npr',
    'Netherlands': 'eur',
    'New Zealand': 'nzd',
    'Nicaragua': 'nio',
    'Niger': 'xof',
    'Nigeria': 'ngn',
    'North Macedonia': 'mkd',
    'Norway': 'nok',
    'Oman': 'omr',
    'Pakistan': 'pkr',
    'Palau': 'usd',
    'Panama': 'pab',
    'Papua New Guinea': 'pgk',
    'Paraguay': 'pyg',
    'Peru': 'pen',
    'Philippines': 'php',
    'Poland': 'pln',
    'Portugal': 'eur',
    'Qatar': 'qar',
    'Romania': 'ron',
    'Russia': 'rub',
    'Rwanda': 'rwf',
    'Saint Kitts and Nevis': 'xcd',
    'Saint Lucia': 'xcd',
    'Saint Vincent and the Grenadines': 'xcd',
    'Samoa': 'wst',
    'San Marino': 'eur',
    'Sao Tome and Principe': 'stn',
    'Saudi Arabia': 'sar',
    'Senegal': 'xof',
    'Serbia': 'rsd',
    'Seychelles': 'scr',
    'Sierra Leone': 'sll',
    'Singapore': 'sgd',
    'Slovakia': 'eur',
    'Slovenia': 'eur',
    'Solomon Islands': 'sbd',
    'Somalia': 'sos',
    'South Africa': 'zar',
    'South Sudan': 'ssp',
    'Spain': 'eur',
    'Sri Lanka': 'lkr',
    'Sudan': 'sdg',
    'Suriname': 'srd',
    'Sweden': 'sek',
    'Switzerland': 'chf',
    'Syria': 'syp',
    'Taiwan': 'twd',
    'Tajikistan': 'tjs',
    'Tanzania': 'tzs',
    'Thailand': 'thb',
    'Timor-Leste': 'usd',
    'Togo': 'xof',
    'Tonga': 'top',
    'Trinidad and Tobago': 'ttd',
    'Tunisia': 'tnd',
    'Turkey': 'try',
    'Turkmenistan': 'tmt',
    'Tuvalu': 'aud',
    'Uganda': 'ugx',
    'Ukraine': 'uah',
    'United Arab Emirates': 'aed',
    'United Kingdom': 'gbp',
    'United States': 'usd',
    'Uruguay': 'uyu',
    'Uzbekistan': 'uzs',
    'Vanuatu': 'vuv',
    'Vatican City': 'eur',
    'Venezuela': 'ves',
    'Vietnam': 'vnd',
    'Yemen': 'yer',
    'Zambia': 'zmw',
    'Zimbabwe': 'zwl',
  };

  var userData;

  getUserData() async {
    final auth = FirebaseAuth.instance;

    User? user = auth.currentUser;

    if (user != null) {
      // User is signed in
      String uid = user.uid;
      // ...
    } else {
      // No user is signed in.
    }

    FirebaseFirestore db = FirebaseFirestore.instance;
    // Reference the specific user document in the "users" collection
    DocumentReference docRef = db.collection('users').doc(user?.uid);

    DocumentSnapshot docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // Retrieve the document data as a Map
      userData = docSnapshot.data() as Map<String, dynamic>?;
    } else {
      print("Failed to load data");
    }

    print("userData");
    print(userData);
  }

  bool _isFriend() {
    if (proposalData["friends"].contains(userData?["uid"])) {
      // User is a friend
      print("The User is friend");
      return true;
    } else {
      // User is not a friend
      print("The User is not a friend");
      return false;
    }
  }

  bool _isProfileImgBlur() {
    if (proposalData["ProfileImageShare"] == "1") {
      // only with friends
      print("The User Share with friend");
      if (_isFriend()) {
        return false;
      } else {
        return true;
      }
    } else if (proposalData["ProfileImageShare"] == "2") {
      // only with me
      print("The User Share with only withe");
      return true;
    } else {
      print("The User Share with only with everyone");
      // with everyOne
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => profile_view_page(
                      proposalData: proposalData,
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: proposalData != null &&
                            proposalData['ProfileImageUrls'] != null &&
                            proposalData['ProfileImageUrls'].length > 1
                        ? Stack(
                            children: [
                              Image.network(
                                proposalData['ProfileImageUrls'][0],
                                height: 420,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              if (_isProfileImgBlur())
                                Positioned.fill(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Container(
                            height: 420,
                            width: double.infinity,
                            color: Colors.grey,
                            child: Center(child: Text('No Image Available')),
                          ),
                  ),
                  Positioned(
                    top: 0.0,
                    right: 10.0,
                    child: buttonArrow(context),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Stack(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  proposalData['name'] ??
                                                      'Unknown',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'serif',
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              if ((proposalData[
                                                              "PackageSubscribed"] ??
                                                          "free")
                                                      .toLowerCase() !=
                                                  "free") ...[
                                                SizedBox(width: 5),
                                                Image.asset(
                                                  'assets/verify.png',
                                                  width: 20,
                                                  height: 20,
                                                ),
                                              ],
                                              if (countriesCurrencies[proposalData[
                                                      "NationalityCountry"]] !=
                                                  null) ...[
                                                SizedBox(width: 10),
                                                Image.asset(
                                                  'icons/currency/${countriesCurrencies[proposalData["NationalityCountry"]]}.png',
                                                  package: 'currency_icons',
                                                  width: 32,
                                                  height: 32,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            "from ${proposalData["NationalityCity"]}, ${proposalData["NationalityCountry"]}",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            "assets/Profile_View_Icons/rings.png",
                                            width: 28,
                                            height: 28,
                                          ),
                                          Flexible(
                                            child: Text(
                                              "  ${proposalData["MartialStatus"]}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          "assets/Profile_View_Icons/education.png",
                                          width: 25,
                                          height: 25,
                                        ),
                                        Container(
                                          width: 135,
                                          child: Text(
                                            " ${proposalData["Field"]}",
                                            style:
                                                TextStyle(color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Image.asset(
                                          "assets/Profile_View_Icons/suitcase.png",
                                          width: 25,
                                          height: 25,
                                        ),
                                        Container(
                                          width: 120,
                                          child: Text(
                                            " ${proposalData["Profession"]}",
                                            style:
                                                TextStyle(color: Colors.white),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  buttonArrow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: InkWell(
        onTap: () async {
          FirebaseOperations firebaseOperations = new FirebaseOperations();
          if (await firebaseOperations.saveProposal(proposalData["uid"])) {
            Fluttertoast.showToast(msg: "Saved");
          } else {
            Fluttertoast.showToast(msg: "An Error Occurred");
          }
        },
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.save_outlined,
                size: 25,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
