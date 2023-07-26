import 'dart:math';

import 'package:flutter/material.dart';

class GameOne extends StatefulWidget {
 final String gameRoomId;
  GameOne({required this.gameRoomId});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game One'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Player One Score: $player1Score'),
            ElevatedButton(
              onPressed: () {
                _playGame(1);
              },
              child: Text('Spieler 1'),
            ),
            Text(
              'Player 1 Card Value: ${player1Card.isNotEmpty ? player1Card : '---'}',
              style: TextStyle(fontSize: 20),
            ),
            Text('Player Two Score: $player2Score'),
            ElevatedButton(
              onPressed: () {
                _playGame(2);
              },
              child: Text('Spieler 2'),
            ),
            Text(
              'Player 2 Card Value: ${player2Card.isNotEmpty ? player2Card : '---'}',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
