import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_game_card_with_flutter/game_page/game_one.dart';

import 'chat_bubble.dart';

class ChapPage extends StatefulWidget {
  final String receiverUserEmail;
  final String receiverUserID;
  const ChapPage({
    Key? key,
    required this.receiverUserEmail,
    required this.receiverUserID,
  }) : super(key: key);

  @override
  State<ChapPage> createState() => _ChapPageState();
}

class _ChapPageState extends State<ChapPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _dialog = true;

  void sendMessage() async {
    // only send message if there is sth to send
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.receiverUserID,
        _messageController.text,
      );
      // clear the text controller after sending the message
      _messageController.clear();
    }
  }

void _showDialog() async {
  // Check if a game room already exists for both users
  String gameRoomId =
      '${_firebaseAuth.currentUser!.uid}_${widget.receiverUserID}';
  DocumentSnapshot gameRoomSnapshot = await FirebaseFirestore.instance
      .collection('game_rooms')
      .doc(gameRoomId)
      .get();
  String gameRoomIdReverse =
      '${widget.receiverUserID}_${_firebaseAuth.currentUser!.uid}';
  DocumentSnapshot gameRoomReverseSnapshot =
      await FirebaseFirestore.instance
          .collection('game_rooms')
          .doc(gameRoomIdReverse)
          .get();

  if (gameRoomSnapshot.exists || gameRoomReverseSnapshot.exists) {
    // If the game room exists, navigate to GameOne page directly
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => GameOne(
        gameRoomId: gameRoomId,
        userMap: {
          'player1Uid': _firebaseAuth.currentUser!.uid,
          'player1Email': _firebaseAuth.currentUser!.email,
          'player2Uid': widget.receiverUserID,
          'player2Email': widget.receiverUserEmail,
        },
      ),
    ));
  } else {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Matchmaking'),
          content: Text('Möchtest du mit dem Spiel anfangen'),
          actions: [
            TextButton(
              onPressed: () async {
                // Code to handle button press in the dialog
                // Update the "in-game status" in Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_firebaseAuth.currentUser!.uid)
                    .update({"in-game": true});

                // Create a new game room with both users' IDs
                await FirebaseFirestore.instance
                    .collection('game_rooms')
                    .doc(gameRoomId)
                    .set({
                  'player1Uid': _firebaseAuth.currentUser!.uid,
                  'player2Uid': widget.receiverUserID,
                });

                // Create extra collections for players' cards and scores
                await FirebaseFirestore.instance
                    .collection('game_rooms')
                    .doc(gameRoomId)
                    .collection('players')
                    .doc(_firebaseAuth.currentUser!.uid)
                    .set({
                  'score': 0,
                  'card': '',
                });

                await FirebaseFirestore.instance
                    .collection('game_rooms')
                    .doc(gameRoomId)
                    .collection('players')
                    .doc(widget.receiverUserID)
                    .set({
                  'score': 0,
                  'card': '',
                });

                // Navigate to GameOne page and pass the userMap
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => GameOne(
                    gameRoomId: gameRoomId,
                    userMap: {
                      'player1Uid': _firebaseAuth.currentUser!.uid,
                      'player1Email': _firebaseAuth.currentUser!.email,
                      'player2Uid': widget.receiverUserID,
                      'player2Email': widget.receiverUserEmail,
                    },
                  ),
                ));
              },
              child: Text('OK'),
            ),
            TextButton(
              onPressed: () {
                // Code to handle button press in the dialog
                Navigator.of(context).pop();
              },
              child: Text('Nein'),
            ),
          ],
        );
      },
    );
  }
}








  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverUserEmail)),
      body: Column(
        children: [
          //messages
          Expanded(child: _buildMessageList()),
          //user input
          _buildMessageInput(),
          _dialogButton()
        ],
      ),
    );
  }

  // build message list
  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(
        widget.receiverUserID,
        _firebaseAuth.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Loading ...');
        }
        return ListView(
          children: snapshot.data!.docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  // build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    // align the messages to the right if the sender is the current user
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
            ChatBubble(message: data['message']),
          ],
        ),
      ),
    );
  }

  // build message input
  Widget _buildMessageInput() {
    return Container(
      margin: EdgeInsets.all(8.0),
      child: Row(
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
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
          ),
        ],
      ),
    );
  }

  Widget _dialogButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          _showDialog();
        },
        child: Text('match making'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          primary: Colors.blue, // Button color
          onPrimary: Colors.white, // Text color
        ),
      ),
    );
  }
}

///chat_service //////////////////////////////////////////////
class ChatService extends ChangeNotifier {
  // get instance of auth and firestore
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  // send message
  Future<void> sendMessage(String receiverId, String message) async {
    // get current user info
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email.toString();
    final Timestamp timestamp = Timestamp.now();
    // create a new message
    Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: message,
        timestamp: timestamp);
    // construct chat room id from current user id and receiverId (sorted to ensure uniqueness)

    List<String> ids = [currentUserId, receiverId];
    ids.sort(); // sort the ids (this ensures the chatroomid is always the same for any pair)
    String chatRoomId = ids.join("_");

    // add new message to the database
    await _fireStore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // get messages
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    // construct chat room id from the user ids
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");
    return _fireStore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}

/// Add the Message class if you don't have it already.
class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
/////////////
///Game Page /////////////////////////////////////////////////////////////////////////////////
//////////////////
