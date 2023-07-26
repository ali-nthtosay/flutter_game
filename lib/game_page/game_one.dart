
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Fetch players' scores and cards from Firestore
    _fetchPlayersData();
  }

  void _fetchPlayersData() async {
    try {
      DocumentSnapshot player1Snapshot = await _firestore
          .collection('game_rooms')
          .doc(widget.gameRoomId)
          .collection('players')
          .doc(widget.userMap['player1Uid'])
          .get();

      DocumentSnapshot player2Snapshot = await _firestore
          .collection('game_rooms')
          .doc(widget.gameRoomId)
          .collection('players')
          .doc(widget.userMap['player2Uid'])
          .get();

      setState(() {
        player1Score = player1Snapshot.get('score');
        player1Card = player1Snapshot.get('card');
        player2Score = player2Snapshot.get('score');
        player2Card = player2Snapshot.get('card');
      });
    } catch (e) {
      print('Error fetching players data: $e');
    }
  }

  void _playGame(int playerNumber) async {
    // Check if it's the current user's turn to play
    String currentPlayerUid = (playerNumber == 1)
        ? widget.userMap['player1Uid']
        : widget.userMap['player2Uid'];

    String currentUserUid = _firebaseAuth.currentUser!.uid;

    if (currentPlayerUid == currentUserUid) {
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

      // Update player's data in Firestore
      _updatePlayersData();
    }
  }

  void _updatePlayersData() async {
    try {
      // Player 1 data
      Map<String, dynamic> player1Data = {
        'uid': widget.userMap['player1Uid'],
        'email': widget.userMap['player1Email'],
        'score': player1Score,
        'card': player1Card,
      };
      await _firestore
          .collection('game_rooms')
          .doc(widget.gameRoomId)
          .collection('players')
          .doc(widget.userMap['player1Uid'])
          .set(player1Data);

      // Player 2 data
      Map<String, dynamic> player2Data = {
        'uid': widget.userMap['player2Uid'],
        'email': widget.userMap['player2Email'],
        'score': player2Score,
        'card': player2Card,
      };
      await _firestore
          .collection('game_rooms')
          .doc(widget.gameRoomId)
          .collection('players')
          .doc(widget.userMap['player2Uid'])
          .set(player2Data);
    } catch (e) {
      print('Error updating players data: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Game ${widget.userMap['player1Email']} VS ${widget.userMap['player2Email']}',
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Player 1 Section
            _buildPlayerSection(
              playerEmail: widget.userMap['player1Email'],
              playerScore: player1Score,
              playerCard: player1Card,
              onPressed: () => _playGame(1),
            ),
            SizedBox(height: 20),
            // Player 2 Section
            _buildPlayerSection(
              playerEmail: widget.userMap['player2Email'],
              playerScore: player2Score,
              playerCard: player2Card,
              onPressed: () => _playGame(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSection({
    required String playerEmail,
    required int playerScore,
    required String playerCard,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Text(
          'Player Email: $playerEmail',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 20),
        Text(
          'Player Score: $playerScore',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: onPressed,
          child: Text('Play'),
          style: ElevatedButton.styleFrom(primary: Colors.blue),
        ),
        SizedBox(height: 20),
        Text(
          'Player Card Value: ${playerCard.isNotEmpty ? playerCard : '---'}',
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
