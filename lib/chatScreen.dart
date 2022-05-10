import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key, required this.channel, required this.name})
      : super(key: key);
  final String channel;
  final String name;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  List<ChatItem> _messages = [];

  void _sendMessage(String msg) {
    FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channel)
        .collection('messages')
        .add(ChatMessage.makeNewMessageJson(
            text: msg,
            author: widget.name,
            timestamp: Timestamp.now(),
            type: 'text'));
    _controller.clear();
  }

  void _sendImage(FilePickerResult result) async {
    File file = File(result.files.single.path!);
    String filename = Uuid().v4();
    final storageRef = FirebaseStorage.instance.ref();
    final imgRef = storageRef.child("images/$filename");
    try {
      String imgExt =
          file.path.substring(file.path.lastIndexOf('.') + 1, file.path.length);
      await imgRef.putFile(
          file, SettableMetadata(contentType: 'image/$imgExt'));
      print("File Uploaded");
      FirebaseFirestore.instance
          .collection('channels')
          .doc(widget.channel)
          .collection('messages')
          .add(ChatImage.makeNewImageJson(
              author: widget.name,
              filename: filename,
              timestamp: Timestamp.now(),
              type: 'image'));
    } on FirebaseException catch (e) {
      print(e);
    }
  }

  void _messageLongPress(BuildContext context, int i) {
    showMenu(
        context: context,
        position: const RelativeRect.fromLTRB(0, 0, 100, 100),
        items: [
          PopupMenuItem(
            child: const Text("Copy"),
            onTap: () => Clipboard.setData(
                ClipboardData(text: _messages[i].getContentText())),
          ),
          PopupMenuItem(
            child: const Text("Delete"),
            onTap: () => _deleteMessage(_messages[i]),
          ),
        ]);
  }

  Future<void> _deleteMessage(ChatItem item) async {
    if (item.type == 'image') {
      await FirebaseStorage.instance
          .ref()
          .child('images/' + (item as ChatImage).imageName)
          .delete();
    }
    FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channel)
        .collection('messages')
        .doc(item.id)
        .delete();
  }

  Widget _buildListItem(BuildContext context, int i) {
    var _tapDownPos;
    return GestureDetector(
        onTapDown: (details) => _tapDownPos = details.globalPosition,
        onLongPress: () => _messageLongPress(context, i),
        child: _messages[i]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.channel)),
      body: Center(
        child: Column(children: [
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('channels')
                  .doc(widget.channel)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                } else {
                  _messages = [];
                  return ListView.builder(
                    reverse: true,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = snapshot.data!.docs[index];
                      if (document['type'] == 'text') {
                        _messages.add(ChatMessage(
                            id: document.id,
                            text: document['message'],
                            author: document['author'],
                            timestamp: document['timestamp']));
                        return _buildListItem(context, index);
                      } else if (document['type'] == 'image') {
                        _messages.add(ChatMessage(
                            id: document.id,
                            text: 'Loading...',
                            author: document['author'],
                            timestamp: document['timestamp']));
                        int ind = _messages.length - 1;
                        return FutureBuilder<Uint8List?>(
                            future: FirebaseStorage.instance
                                .ref()
                                .child('images/' + document['filename'])
                                .getData(),
                            builder: ((context, snapshot) {
                              if (snapshot.hasData) {
                                _messages[ind] = ChatImage(
                                    author: document['author'],
                                    timestamp: document['timestamp'],
                                    id: document.id,
                                    imageName: document['filename'],
                                    imgData: snapshot.data!);
                                return _buildListItem(context, index);
                              }
                              return _buildListItem(context, index);
                            }));
                      } else {
                        _messages.add(ChatMessage(
                            text: "Error Loading Message",
                            author: "System",
                            timestamp: Timestamp.now(),
                            id: "-1"));
                        return _buildListItem(context, index);
                      }
                    },
                    //itemCount: _messages.length,
                    itemCount: snapshot.data!.docs.length,
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your Message',
              ),
              controller: _controller,
              onSubmitted: _sendMessage,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png'],
                );

                if (result != null) {
                  _sendImage(result);
                } else {
                  // User canceled the picker
                }
              },
              icon: const Icon(Icons.file_open),
              label: const Text("Select File"),
            ),
          )
        ]),
      ),
    );
  }
}

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
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).primaryColorDark),
            borderRadius: BorderRadius.circular(10.0),
            color: Theme.of(context).primaryColorLight),
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(child: Text(author[0])),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(author,
                          style: Theme.of(context).textTheme.headline6),
                      _getTimestampText()
                    ],
                  ),
                  buildItem(),
                ],
              ),
            ),
          ],
        ),
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
    return Text(text);
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
