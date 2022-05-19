import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_chat_app/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: appTheme(),
      home: const HomeScreen(),
      //home: ChatScreen(channel: channel, name: name),
    );
  }
}

const Color primaryColor = Color.fromARGB(255, 245, 229, 86);
const Color primaryColorLight = Color.fromARGB(195, 233, 220, 106);
const Color primaryColorDark = Color.fromARGB(255, 255, 217, 0);
const Color appBarColor = Color.fromARGB(255, 245, 229, 86);
const Color textColor = Colors.black;

ThemeData appTheme() {
  return ThemeData(
      primaryColor: primaryColor,
      primaryColorLight: primaryColorLight,
      primaryColorDark: primaryColorDark,
      appBarTheme: const AppBarTheme(
          backgroundColor: appBarColor,
          iconTheme: IconThemeData(color: textColor, size: 30),
          titleTextStyle: TextStyle(
              color: textColor, fontSize: 25.0, fontWeight: FontWeight.bold)),
      //secondaryHeaderColor: Colors.black,
      textTheme: const TextTheme(
          bodyText1: TextStyle(color: textColor),
          bodyText2: TextStyle(color: textColor),
          // bodyMedium: TextStyle(color: textColor),
          headline1: TextStyle(
              //color: textColor,
              fontSize: 40.0,
              fontWeight: FontWeight.bold),
          headline2: TextStyle(
              //color: textColor,
              fontSize: 30.0,
              fontWeight: FontWeight.bold),
          headline3: TextStyle(
              //color: textColor,
              fontSize: 25.0,
              fontWeight: FontWeight.bold)),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.black))));
}
