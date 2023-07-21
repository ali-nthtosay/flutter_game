import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_game_card_with_flutter/auth/auth_page.dart';
import 'package:flutter_game_card_with_flutter/auth/register_page.dart';

import '../home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user is logged in
          if (snapshot.hasData) {
            return  HomePage();
          } else {
            return AuthPage();
          }
        },
      ),
    );
  }
}
