import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

abstract class ChatItem extends StatelessWidget {
  ChatItem({
    //required this.text,
    required this.author,
    required this.timestamp,
    required this.id,
    required this.type,
    Key? key,
  }) : super(key: key);

  final String author;
  final Timestamp timestamp;
  final String id;
  final String type;

  Widget _getTimestampText() {
    String txt = timestamp.toDate().hour.toString() +
        ':' +
        timestamp.toDate().minute.toString() +
        ':' +
        timestamp.toDate().second.toString();
    return Text(txt);
  }

  Widget buildItem();
  String getContentText();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).primaryColorDark, width: 2.0),
          borderRadius: BorderRadius.circular(10.0),
          color: Theme.of(context).primaryColorLight),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            decoration: BoxDecoration(
                border: Border.all(width: 2),
                borderRadius: BorderRadius.circular(28)),
            child: CircleAvatar(
              child: Text(
                author[0].toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .headline3, //TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.yellow,
              radius: 25,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(author, style: Theme.of(context).textTheme.headline6),
                    _getTimestampText()
                  ],
                ),
                buildItem(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends ChatItem {
  ChatMessage({
    Key? key,
    required this.text,
    required String author,
    required Timestamp timestamp,
    required String id,
  }) : super(
            key: key,
            author: author,
            timestamp: timestamp,
            id: id,
            type: 'text');

  final String text;

  @override
  Widget buildItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Text(text),
    );
  }

  @override
  String getContentText() {
    return text;
  }

  static Map<String, dynamic> makeNewMessageJson(
      {required String author,
      required String text,
      required Timestamp timestamp,
      required String type}) {
    return {
      "author": author,
      "message": text,
      "timestamp": timestamp,
      "type": type,
    };
  }
}

class ChatLoading extends ChatItem {
  ChatLoading(
      {Key? key,
      required String author,
      required Timestamp timestamp,
      required String id,
      required String type})
      : super(
            key: key, author: author, timestamp: timestamp, id: id, type: type);

  @override
  Widget buildItem() {
    return const Text(
      "Loading...",
      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
    );
  }

  @override
  String getContentText() {
    return "Loading...";
  }
}

class ChatImage extends ChatItem {
  ChatImage(
      {Key? key,
      required String author,
      required Timestamp timestamp,
      required String id,
      required this.imageName,
      required this.imgData})
      : super(
            key: key,
            author: author,
            timestamp: timestamp,
            id: id,
            type: 'image');

  final String imageName;
  final String path = 'images/';
  final Uint8List imgData;

  @override
  Widget buildItem() {
    return Padding(
        padding: const EdgeInsets.all(10.0), child: Image.memory(imgData));
  }

  @override
  String getContentText() {
    return "Image: $imageName";
  }

  static Map<String, dynamic> makeNewImageJson(
      {required String author,
      required String filename,
      required Timestamp timestamp,
      required String type}) {
    return {
      "author": author,
      "timestamp": timestamp,
      "filename": filename,
      "type": type,
    };
  }
}
