import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nikah_blessing/Email_Authentication/EmailAuth_Main.dart';
import 'package:nikah_blessing/Payement_Module/CC_PayementPage.dart';
import 'package:nikah_blessing/size_config.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class onBoardingScreens extends StatefulWidget {
  const onBoardingScreens({super.key});

  @override
  State<onBoardingScreens> createState() => _onBoardingScreensState();
}

class _onBoardingScreensState extends State<onBoardingScreens> {
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    size_config().init(context);

    double sizeH = size_config.blockSizeH!;
    double sizeV = size_config.blockSizeV!;



    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/onBoardingScreens_assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Container(
                  width: MediaQuery.sizeOf(context).width - 100,
                  alignment: Alignment.topRight,
                  child: Image(
                    height: 100,
                    width: sizeV * 25,
                    image:
                    AssetImage('assets/onBoardingScreens_assets/ayat.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 0, right: 0),
                  width: 100,
                  alignment: Alignment.topRight,
                  child: Image(
                    width: sizeV * 15,
                    image:
                    AssetImage('assets/onBoardingScreens_assets/bells.png'),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: <Widget>[
                  Page1(),
                  Page2(),
                  Page3(),
                  Page4(),

                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Image.asset(
                      "assets/onBoardingScreens_assets/flower.png",
                      width: 80,
                      fit: BoxFit.fitHeight,
                    ),
                  ],
                ),
                Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.all(16),
                  child: SmoothPageIndicator(
                    controller: _pageController, // PageController
                    count: 4,
                    effect: SlideEffect(
                      spacing: 15,
                      dotHeight: 18.0,
                      dotWidth: 18.0,
                      dotColor: Colors.red,
                      activeDotColor: Colors.red,
                      paintStyle: PaintingStyle.stroke,
                      strokeWidth: 5.0,
                      // Width of the border
                    ),

                    onDotClicked: (index) {
                      _pageController.animateToPage(index,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.ease);
                    },
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Get the current page index
                        int nextPage = _pageController.page!.toInt() + 1;
                        // Navigate to the next page if it exists
                        if (nextPage < 4) {
                          _pageController.animateToPage(nextPage,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.ease);
                        } else if (nextPage == 4) {


                          Navigator.of(context).push(PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                  EmailAuth_Main(),


                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(0.0, 1.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOut;

                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              }));




                        }


                      },
                      child: Container(
                        child: Image.asset(
                          "assets/onBoardingScreens_assets/next_btn_img.png",
                          width: 58,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Page1 extends StatelessWidget {



  @override
  Widget build(BuildContext context) {
    size_config().init(context);

    double sizeH = size_config.blockSizeH!;
    double sizeV = size_config.blockSizeV!;

    double screenHeight = MediaQuery.of(context).size.height;
    double imageHeight = screenHeight * 0.5; // 80% of screen width


    return Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.transparent,
        child: Column(mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Container(
                margin: EdgeInsets.only(left: 5),
                child: Row(
                  children: [
                    Text(
                      "Welcome to \nNikah Blessing",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: sizeH * 8.0,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 5),
                child: Row(
                  children: [
                    Text(
                      "Hurry up! don't kept your partner waiting ...",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: sizeH * 3.8,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),


              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Image.asset(
                          "assets/onBoardingScreens_assets/copule.png",
                          height: imageHeight,
                          width: MediaQuery.sizeOf(context).width - 10,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(left: 5, top: 5),
                child: Row(
                  children: [
                    Text(
                      "Congratulations you made your  \nfirst step toward beautiful life.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: sizeH * 5.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ]));
  }
}

class Page2 extends StatelessWidget {
  final bulletPoints = [
    'Here your data is end-to-end\nencrypted making it more secure.',
    'You can control who can see your\nprofile data.',
    'We provide secure transactions.',
    'No Screen Shots policy',
  ];
  @override
  Widget build(BuildContext context) {
    size_config().init(context);
    double sizeH = size_config.blockSizeH!;
    double sizeV = size_config.blockSizeV!;

    return Container(
      color: Colors.transparent,
      child: Container(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      Text(
                        "We respects ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: sizeH * 8.0,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      Text(
                        "Your Privacy",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: sizeH * 9.0,
                          height: 0.1,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Image.asset(
                            "assets/onBoardingScreens_assets/privacy.png",
                            height: sizeV * 35,
                            width: MediaQuery.sizeOf(context).width - 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(left: 5, top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: bulletPoints.map((point) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height:34,

                            child: Center(
                              child: Image.asset(
                                'assets/onBoardingScreens_assets/ok_symbol.png',
                                // Replace with your custom image path
                                width: 20,
                                height: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: sizeH * 4.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ])),
    );
  }
}

class Page3 extends StatelessWidget {




  final bulletPoints = [
    'Al Powered Face Recognition.',
    'Legal Document Verification.',
    'Quick Action Over Complaints',
  ];
  @override
  Widget build(BuildContext context) {
    size_config().init(context);
    double sizeH = size_config.blockSizeH!;
    double sizeV = size_config.blockSizeV!;

    return Container(
      color: Colors.transparent,
      child: Container(
          child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      Text(
                        "We got 99.9 % ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: sizeH * 8.0,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: EdgeInsets.only(left: 5),
                  child: Row(
                    children: [
                      Text(
                        "Verified Profiles",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: sizeH * 9.0,
                          height: 0.1,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Image.asset(
                            "assets/onBoardingScreens_assets/CustomerCare.png",
                            height: sizeV * 36,
                            width: MediaQuery.sizeOf(context).width - 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Container(

                  width: MediaQuery.of(context).size.width -10,
                  child: Text(
                    "Our 24/7 Customer Care \nVerifies the new profiles through",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: sizeH * 5.0,
                      height: 1,
                    ),
                  ),
                ),


                Container(
                  margin: EdgeInsets.only(left: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: bulletPoints.map((point) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height:26,
                            width: 10,
                            child: Center(
                              child: Text(
                                "✅",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: sizeH * 2.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 10,),
                          Expanded(
                            child: Text(
                              point,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: sizeH * 4.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ])),
    );
  }
}

class Page4 extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    size_config().init(context);
    double sizeH = size_config.blockSizeH!;
    double sizeV = size_config.blockSizeV!;

    return Container(
      color: Colors.transparent,
      child: Container(
          child: Column(mainAxisSize: MainAxisSize.max, children: [
            Container(
              margin: EdgeInsets.only(left: 5),
              child: Row(
                children: [
                  Text(
                    "So, what are you waiting for ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: sizeH * 4.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10,),

            Container(
              margin: EdgeInsets.only(left: 5),
              child: Row(
                children: [
                  Text(
                    "let's connects you \nwith your soulmate",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: sizeH * 8.0,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Image.asset(
                        "assets/onBoardingScreens_assets/Chatting.png",
                        height: sizeH * 85,
                        width: MediaQuery.sizeOf(context).width - 10,
                      ),
                    ),
                  ],
                ),

                Container(
                  margin: EdgeInsets.only(left: 5 , top: 5),
                  child: Row(
                    children: [
                      Text(
                        "We provide seamless \nplatform to interact you with \nyour soul mate.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: sizeH * 6.0,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

              ],



            ),
          ])),
    );
  }
}