import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _sendMessage(String msg) {
    FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channel)
        .collection('messages')
        .add(ChatMessage(
          text: msg,
          author: widget.name,
          timestamp: Timestamp.now(),
        ).toMap());
    _controller.clear();
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return ChatMessage.fromSnapshot(
        text: document['message'],
        author: document['author'],
        timestamp: document['timestamp']);
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
                if (!snapshot.hasData) return const Text('Loading...');
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  reverse: true,
                  itemBuilder: (context, index) =>
                      _buildListItem(context, snapshot.data!.docs[index]),
                  itemCount: snapshot.data!.docs.length,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your Message',
              ),
              controller: _controller,
              onSubmitted: _sendMessage,
            ),
          ),
        ]),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({
    required this.text,
    required this.author,
    required this.timestamp,
    Key? key,
  }) : super(key: key);

  ChatMessage.fromSnapshot({
    required this.text,
    required this.author,
    required this.timestamp,
    Key? key,
  }) : super(key: key);

  final String text;
  final String author;
  final Timestamp timestamp;

  Map<String, dynamic> toMap() {
    return {
      "author": author,
      "message": text,
      "timestamp": timestamp,
    };
  }

  Widget _getTimestampText() {
    String txt = timestamp.toDate().hour.toString() +
        ':' +
        timestamp.toDate().minute.toString() +
        ':' +
        timestamp.toDate().second.toString();
    return Text(txt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    Text(author, style: Theme.of(context).textTheme.headline6),
                    _getTimestampText()
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
