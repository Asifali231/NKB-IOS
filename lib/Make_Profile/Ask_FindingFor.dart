import 'package:flutter/material.dart';
import 'package:nikah_blessing/DataClass/UserData.dart';

class Ask_FindingFor extends StatefulWidget {
  final VoidCallback navigateToNextPage, navigateToPrevPage;

  Ask_FindingFor({
    required this.navigateToNextPage,
    required this.navigateToPrevPage
  });

  @override
  State<Ask_FindingFor> createState() => _Ask_FindingForState();
}

class _Ask_FindingForState extends State<Ask_FindingFor> {
  // Options for who the user is finding a match for
  final List<String> options = [
    'Self',
    'Brother',
    'Sister',
    'Cousin',
    'Parents',
    'Other Relative'
  ];

  // List of corresponding icon assets (you would need to create or use appropriate images)
  final List<String> iconAssets = [
    'assets/Self.png',
    'assets/brother.png',
    'assets/sister.png',
    'assets/cousin.png',
    'assets/parents.png',
    'assets/relative.png'
  ];

  // Selected option index (-1 means nothing selected)
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.only(top: 68),
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: 5),
            child: Text(
              "Who are you finding a match for?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                height: 1.2,
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.only(left: 5, top: 0),
            child: Text(
              "Help us understand who this profile is for",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ),

          SizedBox(height: 0),

          // Grid of selectable cards - modified to make boxes square and take available width
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                // Remove childAspectRatio to make it square by default
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;

                      // Store the selection in UserData
                      UserData.FindingFor = options[index];

                      print("Finding match for: " + UserData.FindingFor);

                      // Navigate to next page after short delay to show selection
                      Future.delayed(Duration(milliseconds: 300), () {
                        widget.navigateToNextPage();
                      });
                    });
                  },
                  child: Container(
                    // Take all available width in the grid cell
                    height:double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Make icon container smaller relative to box
                        Container(
                          width: 70.0,
                          height: 70.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.green : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey.shade100,
                            // Use the appropriate image asset or a placeholder
                            child: Image.asset(
                              iconAssets[index],
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if image is not found
                                return Icon(
                                  getIconForOption(options[index]),
                                  size: 35,
                                  color: Colors.grey.shade800,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          options[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),


          SizedBox(height: 20),

        ],
      ),
    );
  }

  // Helper method to get appropriate icons as fallback when image assets are not available
  IconData getIconForOption(String option) {
    switch (option) {
      case 'Self':
        return Icons.person;
      case 'Brother':
        return Icons.man;
      case 'Sister':
        return Icons.woman;
      case 'Cousin':
        return Icons.people;
      case 'Parents':
        return Icons.family_restroom;
      case 'Other Relative':
        return Icons.diversity_3;
      default:
        return Icons.person;
    }
  }
}