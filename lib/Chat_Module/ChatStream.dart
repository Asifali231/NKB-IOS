import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatStream extends StatefulWidget {
  final String chatRomID;

  ChatStream(this.chatRomID);

  @override
  State<ChatStream> createState() => _ChatStreamState();
}

class _ChatStreamState extends State<ChatStream> {

  Stream<QuerySnapshot> chatMessageStream = FirebaseFirestore.instance.collection('Chats').snapshots();


  getChat(chatRoomID) async
  {

    final db = FirebaseFirestore.instance;


    return db.collection("Chats")
        .doc(chatRoomID).
    collection('chats').orderBy('time').snapshots();

  }

  @override
  void initState() {
    // TODO: implement initState
    getChat(widget.chatRomID).then((value)
    {
      setState(() {
        chatMessageStream =value;
      });

    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Padding(

      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: chatMessageStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return snapshot.hasData ? ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context,index)
            {
              return Text(snapshot.data?.docs[index]['message']);
            },
          ) :Container();
        },),
    );
  }
}