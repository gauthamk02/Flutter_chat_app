import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'chat_items.dart';

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

  void _messageLongPress(BuildContext context, Offset _tapDownPosition, int i) {
    final RenderBox overlay =
        Overlay.of(context)!.context.findRenderObject() as RenderBox;

    showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          _tapDownPosition.dx,
          _tapDownPosition.dy,
          overlay.size.width - _tapDownPosition.dx,
          overlay.size.height - _tapDownPosition.dy,
        ),
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
    late Offset _tapDownPos;
    return GestureDetector(
        onTapDown: (details) => _tapDownPos = details.globalPosition,
        onLongPress: () => _messageLongPress(context, _tapDownPos, i),
        child: _messages[i]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.channel)),
      body: Center(
        child: Container(
          color: Color.fromARGB(255, 230, 243, 110),
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
                          _messages.add(ChatLoading(
                              id: document.id,
                              author: document['author'],
                              type: 'text',
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
              padding:
                  const EdgeInsets.symmetric(vertical: 0.0, horizontal: 3.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png'],
                  );

                  if (result != null) {
                    _sendImage(result);
                  } else {
                    // User canceled the picker
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text("Image"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0)),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                  labelText: 'Message',
                  hintText: 'Enter the Message',
                  hintStyle: TextStyle(color: Colors.black),
                  labelStyle: TextStyle(color: Colors.black),
                ),
                controller: _controller,
                onSubmitted: _sendMessage,
              ),
            )
          ]),
        ),
      ),
    );
  }
}
