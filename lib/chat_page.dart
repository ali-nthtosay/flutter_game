import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_game_card_with_flutter/chat/chat_service.dart';
import 'package:flutter_game_card_with_flutter/chat_bubble.dart';

class ChapPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;
  const ChapPage(
      {super.key,
      required this.receiverUserEmail,
      required this.receiverUserID});

  @override
  State<ChapPage> createState() => _ChapPageState();
}

class _ChapPageState extends State<ChapPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  void sendMessage() async {
    // only send message if there is sth to send
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.receiverUserID, _messageController.text);
      // clear the text controller after sending the message
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverUserEmail)),
      body: Column(children: [
        //messages
        Expanded(child: _buildMessageList()),
        //user input
        _buildMessageInput(),
      ]),
    );
  }

  // build message list
  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
        stream: _chatService.getMessages(
            widget.receiverUserID, _firebaseAuth.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text('loading ..');
          }
          return ListView(
            children: snapshot.data!.docs
                .map((document) => _buildMessageItem(document))
                .toList(),
          );
        });
  }

  //build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    // align the messages to the right if the send is the current user
    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    return Container(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
            crossAxisAlignment:
                (data['senderId'] == _firebaseAuth.currentUser!.uid)
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
            mainAxisAlignment:
                (data['senderId'] == _firebaseAuth.currentUser!.uid)
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            children: [
              Text(data['senderEmail']),
              SizedBox(
                height: 5,
              ),
              ChatBubble(message: data['message'])
            ]),
      ),
    );
  }

  // build message input
  Widget _buildMessageInput() {
    return Row(
  children: [
    Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: _messageController,
          obscureText: false,
          decoration: InputDecoration(
            hintText: 'Type your message here',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(color: Colors.blue),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
          style: TextStyle(fontSize: 16.0),
          maxLines: null,
          keyboardType: TextInputType.multiline,
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        onPressed: sendMessage,
        icon: Icon(Icons.send),
        color: Colors.blue,
        iconSize: 30.0,
      ),
    )
  ],
)
;
  }
}
