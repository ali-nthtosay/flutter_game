import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chat_bubble.dart';
import 'game_page/game_one.dart';

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

void _showDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Matchmaking'),
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

              // Check if a game room already exists for both users
              String gameRoomId =
                  '${_firebaseAuth.currentUser!.uid}_${widget.receiverUserID}';
              DocumentSnapshot gameRoomSnapshot =
                  await FirebaseFirestore.instance
                      .collection('game_rooms')
                      .doc(gameRoomId)
                      .get();

              if (!gameRoomSnapshot.exists) {
                // Create a new game room with both users' IDs
                await FirebaseFirestore.instance
                    .collection('game_rooms')
                    .doc(gameRoomId)
                    .set({
                  'player1Uid': _firebaseAuth.currentUser!.uid,
                  'player2Uid': widget.receiverUserID,
                });
              }

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
///

class GameOne extends StatefulWidget {
  final Map<String, dynamic> userMap;
  final String gameRoomId;

  GameOne({required this.gameRoomId, required this.userMap});

  @override
  State<GameOne> createState() => _GameOneState();
}

class _GameOneState extends State<GameOne> {
  List<int> cards = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
  // player 1
  int player1Score = 0;
  String player1Card = '';
  bool player1Clicked = false;
  // player 2
  int player2Score = 0;
  String player2Card = '';
  bool player2Clicked = false;

  void _playGame(int playerNumber) async {
    setState(() {
      if (playerNumber == 1) {
        player1Card = cards[Random().nextInt(cards.length)].toString();
        player1Clicked = true;
      } else {
        player2Card = cards[Random().nextInt(cards.length)].toString();
        player2Clicked = true;
      }

      if (player1Clicked && player2Clicked) {
        // Show player cards for 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            if (player1Card.compareTo(player2Card) > 0) {
              player1Score++;
              print('player1card: $player1Card and player2card: $player2Card');
            } else if (player1Card.compareTo(player2Card) < 0) {
              player2Score++;
              print('player1card: $player1Card and player2card: $player2Card');
            }

            player1Card = '';
            player1Clicked = false;
            player2Card = '';
            player2Clicked = false;

            if (player1Score == 3 || player2Score == 3) {
              _showGameResult();
            }
          });
        });
      }
    });
  }

  void _showGameResult() {
    String winner;
    if (player1Score == player2Score) {
      winner = 'It\'s a tie!';
    } else {
      winner =
          player1Score > player2Score ? 'Player 1 wins!' : 'Player 2 wins!';
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text(winner),
          actions: [
            TextButton(
              child: Text('Play Again'),
              onPressed: () {
                setState(() {
                  player1Score = 0;
                  player2Score = 0;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
////////////////////////////////////////////////game design//
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Game ${widget.userMap['player1Email']} VS ${widget.userMap['player2Email']}'),
    ),
    backgroundColor: Colors.grey[200],
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCard(
            title: 'Player 1 Email:',
            content: '${widget.userMap['player1Email'] ?? '---'}',
          ),
          SizedBox(height: 20),
          _buildCard(
            title: 'Player One Score:',
            content: '$player1Score',
            buttonText: 'Play',
            onPressed: () => _playGame(1),
          ),
          SizedBox(height: 20),
          _buildCard(
            title: 'Player 1 Card Value:',
            content: '${player1Card.isNotEmpty ? player1Card : '---'}',
          ),
          SizedBox(height: 20),
          _buildCard(
            title: 'Player 2 Card Value:',
            content: '${player2Card.isNotEmpty ? player2Card : '---'}',
          ),
          SizedBox(height: 20),
          _buildCard(
            title: 'Player Two Score:',
            content: '$player2Score',
            buttonText: 'Play',
            onPressed: () => _playGame(2),
            buttonColor: Colors.green,
          ),
          SizedBox(height: 20),
          _buildCard(
            title: 'Player 2 Email:',
            content: '${widget.userMap['player2Email'] ?? '---'}',
          ),
        ],
      ),
    ),
  );
}

Widget _buildCard({
  required String title,
  required String content,
  String? buttonText,
  VoidCallback? onPressed,
  Color buttonColor = Colors.blue,
}) {
  return Card(
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20.0),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18),
          ),
          Text(
            content,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (buttonText != null)
            ElevatedButton(
              onPressed: onPressed,
              child: Text(buttonText),
              style: ElevatedButton.styleFrom(primary: buttonColor),
            ),
        ],
      ),
    ),
  );
}


}
