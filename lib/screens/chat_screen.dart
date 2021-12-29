import 'package:flutter/material.dart';
import 'package:flash_chat_app/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


final _fireStore = FirebaseFirestore.instance;
late User loggedUser;

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser(){
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedUser = user;
      }
    }
    catch(e){
        print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _fireStore.collection('messages').add({
                          'text': messageText,
                          'sender': loggedUser.email,
                          'date and time': DateTime.now().toString(),
                        },
                      );
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class MessagesStream extends StatelessWidget {
  const MessagesStream({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages').snapshots(),
      builder: (context, snapshot){
        List<MessageBubble> messageBubbles = [];
        if(snapshot.hasData) {
          final messages = snapshot.data!.docs;
          for (var message in messages) {
            final messageText = message['text'];
            final messageSender = message['sender'];
            final messageDateTime = message['date and time'];
            final messageBubble = MessageBubble(
                sender: messageSender,
                text: messageText,
                isMe: loggedUser.email == messageSender,
                dateTime: messageDateTime,
            );
            messageBubbles.add(messageBubble);
          }
          messageBubbles.sort((a,b) => (b.dateTime).compareTo(a.dateTime));
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}


class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final String dateTime;

  MessageBubble({required this.sender, required this.text, required this.isMe, required this.dateTime});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          Material(
            borderRadius: BorderRadius.only(
                topLeft: isMe ? Radius.circular(30.0) : Radius.circular(0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
                topRight: isMe ? Radius.circular(0) : Radius.circular(30.0)
            ),
            elevation: 5.0,
            color: isMe ? Colors.blueGrey : Colors.grey,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Container(
                child: IntrinsicWidth(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        DateFormat.Hm().format(DateTime.parse(dateTime)),
                        style: const TextStyle(
                          fontSize: 10.0,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]
      ),
    );
  }
}



// void getMessages() async {
//   final messages = await _fireStore.collection('messages').get();
//   for (var message in messages.docs){
//     print(message.data());
//   }
// }

// void messagesStream() async {
//   await for(var snapshot in _fireStore.collection('messages').snapshots()) {
//     for (var message in snapshot.docs){
//       print(message.data());
//     }
//   }
// }
