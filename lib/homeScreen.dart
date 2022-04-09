import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_chat_app/chatScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _usernamecontroller = TextEditingController();
  final _channelcontroller = TextEditingController();

  final String channel = "abc";
  final String name = "Gautham";

  void _submit() async {
    bool? exist;

    await FirebaseFirestore.instance
        .collection('channels')
        .doc(_channelcontroller.text)
        .get()
        .then((doc) => exist = doc.exists);

    if (exist == false) {
      await FirebaseFirestore.instance
          .collection('channels')
          .doc(_channelcontroller.text)
          .set({"created": Timestamp.now()});
    }

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(
                channel: _channelcontroller.text,
                name: _usernamecontroller.text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter Chat App')),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'User Name',
              hintText: 'Enter the name that yous like to display',
            ),
            controller: _usernamecontroller,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Channel',
              hintText: 'Enter the channel youd like to join',
            ),
            controller: _channelcontroller,
          ),
        ),
        ButtonBar(
          children: [
            ElevatedButton(onPressed: _submit, child: const Text("Join"))
          ],
        )
      ]),
    );
  }
}
