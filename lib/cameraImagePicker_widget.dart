

import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class cameraImagePicker_widget extends StatefulWidget
{
  final Function(List<String>) onSaveImagePath;

  cameraImagePicker_widget({required this.onSaveImagePath});

  @override
  State<cameraImagePicker_widget> createState() => _cameraImagePicker_widgetState();
}

class _cameraImagePicker_widgetState extends State<cameraImagePicker_widget> {

  File ? _image;
  List<String> _imagePaths = [];


  @override
  Widget build(BuildContext context)
  {


    final picker = ImagePicker();

    Future getImage() async {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      setState(() {
        if (pickedFile != null) {
          // Directly add the picked file path to the list
          _imagePaths.add(pickedFile.path);

          // Display a toast message
          // Fluttertoast.showToast(
          //   msg: _imagePaths[0],
          //   toastLength: Toast.LENGTH_SHORT,
          //   gravity: ToastGravity.BOTTOM,
          //   backgroundColor: Colors.black54,
          //   textColor: Colors.white,
          // );
        } else {
          print('No images selected');
        }
      });
    }




    return Dialog(

      child: Container(
        margin: EdgeInsets.only(left: 5,right: 5),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              title: Text(
                'Upload Images',
                style: TextStyle(color:  Colors.black),

              ),
            ),
            Column(
              children: [
                Stack(
                  children: [
                    if(_image != null)
                      Positioned(
                          right: 0,

                          child: IconButton(
                            icon: Icon(Icons.close_outlined,
                              color: Colors.grey,),
                            onPressed: ()
                            {
                              setState(() {
                                _image=null;
                              });
                            },)),

                    Container(
                      margin: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4)
                      ),
                      child: _imagePaths.isNotEmpty
                          ? Container(
                        height: 135,


                        child: ListView.builder
                          (
                          scrollDirection: Axis.horizontal,
                          itemCount: _imagePaths.length,
                          itemBuilder: (BuildContext context, int index) {

                            return Padding(
                              padding: EdgeInsets.all(4),
                              child: Stack(
                                // alignment: Alignment.topRight,
                                children: [
                                  Card(

                                    child: Image.file(
                                      File(_imagePaths[index]),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: -15,
                                    top: -15,
                                    child: IconButton(
                                      icon: Icon(CupertinoIcons.clear_circled_solid,
                                        color: Colors.white70,
                                        size: 20,),
                                      onPressed: () {
                                        // Remove the image at the corresponding index from the list
                                        setState(() {
                                          _imagePaths.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )

                          :
                      DottedBorder(
                        color: Colors.black,
                        strokeWidth: 1,
                        child: Container(
                          // Set the width of your container as desired
                          height: 135, // Set the height of your container as desired

                          child: Center(
                            child: Icon(CupertinoIcons.photo_on_rectangle,
                              color: Colors.grey,
                              size: 80,),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),


                SizedBox(height: 10,),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(onPressed:()
                      {
                        if (_imagePaths != null) {
                          widget.onSaveImagePath(_imagePaths);
                          Navigator.of(context).pop(); // Close the dialog
                        } else {
                          Fluttertoast.showToast(
                            msg: 'Please Provide An Image',
                            toastLength: Toast.LENGTH_SHORT, // Duration for which the toast is visible
                            gravity: ToastGravity.BOTTOM, // Position of the toast on the screen
                            backgroundColor: Colors.black54, // Background color of the toast
                            textColor: Colors.white, // Text color of the toast
                          );
                        }
                      },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                              ),
                            ),
                          ),
                          child: Text('Save',textAlign: TextAlign.center,style: TextStyle(color: Colors.white),)),
                    ),
                    SizedBox(width: 10,),
                    Expanded(
                      child: ElevatedButton(onPressed:()
                      {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                          style:  ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                              ),
                            ),
                          ),
                          child: Text('Cancel',textAlign: TextAlign.center,style: TextStyle(color: Colors.white),)),
                    )
                  ],
                ),
                SizedBox(height: 10,),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style:  ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                            ),
                          ),
                        ),
                        onPressed: getImage,
                        child: Text(
                          'Upload Image',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}