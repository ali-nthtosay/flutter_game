import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Authservice extends ChangeNotifier {
  // instance of auth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // instance of  firestore
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
// sing user in
  Future<UserCredential> singInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      //after creating user , create document for the user
      _fireStore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'status': 'unAvailable',
        'searching-gaming': false,
        'in-game': false
      });

      //add a new document for the user in users collection if it does not already exists
      _fireStore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'status': 'unAvailable',
        'searching-gaming': false,
        'in-game': false
      }, SetOptions(merge: true));
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle sign-in errors
      throw Exception(e.code);
      print('Error: $e');
    }
  }

  // Sign Up
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, password) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      //after creating user , create document for the user
      _fireStore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'status': 'unAvailable',
        'searching-gaming': false,
        'in-game': false
      });
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //sing out
  Future<void> signOut() async {
    return await FirebaseAuth.instance.signOut();
  }
}
