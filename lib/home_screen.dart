import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_chat_app/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _usernamecontroller = TextEditingController();
  final _channelcontroller = TextEditingController();
  late final prefs;
  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  void loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _usernamecontroller.text = prefs.getString('lastusername') ?? '';
    _channelcontroller.text = prefs.getString('lastchannel') ?? '';
  }

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

    prefs.setString('lastusername', _usernamecontroller.text);
    prefs.setString('lastchannel', _channelcontroller.text);

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
      //appBar: AppBar(title: Text('Flutter Chat App')),
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            "Flutter Chat App",
            style: Theme.of(context).textTheme.headline1,
          ),
          SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0)),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black)),
                labelText: 'User Name',
                hintText: 'Enter the display name',
                hintStyle: TextStyle(color: Colors.black),
                labelStyle: TextStyle(color: Colors.black),
              ),
              controller: _usernamecontroller,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0)),
                border: OutlineInputBorder(),
                labelText: 'Channel',
                hintText: 'Enter the channel to join',
                hintStyle: TextStyle(color: Colors.black),
                labelStyle: TextStyle(color: Colors.black),
              ),
              controller: _channelcontroller,
            ),
          ),
          ButtonBar(
            children: [
              ElevatedButton(
                onPressed: _submit,
                child: const Text("Join"),
              )
            ],
          )
        ]),
      ),
    );
  }
}
