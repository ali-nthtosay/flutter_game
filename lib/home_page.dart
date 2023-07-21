import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_game_card_with_flutter/auth/auth_service.dart';
import 'package:flutter_game_card_with_flutter/chat_page.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // instance of auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  // changing status
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
  }

  void setStatus(String status) async {
    await _fireStore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({"status": status});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      //online
      setStatus("Online");
    } else {
      //offline
      setStatus("Offline");
    }
  }

  //sing user out
  void signOut() {
    // get auth service
    final authService = Provider.of<Authservice>(context, listen: false);
    authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [IconButton(onPressed: signOut, icon: Icon(Icons.logout))],
      ),
      body: _buildUserList(),
    );
  }

  // build a list of users except for the current logged in user
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('error');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('..loading');
          }
          return ListView(
            children: snapshot.data!.docs
                .map((doc) => _buildUserListItem(doc))
                .toList(),
          );
        });
  }

  //build individual user list items
  Widget _buildUserListItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
    // display all users except current
    if (_auth.currentUser!.email != data['email']) {
      return Padding(
        padding: EdgeInsets.symmetric(
            vertical: 8.0), // Set the desired vertical margin between users
        child: Container(
          color: data['status'] == 'Online' ? Colors.green : Colors.black12, // Set the background color for each user here
          child: InkWell(
            onTap: () {
              // pass the clicked user's uid to the chat page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChapPage(
                    receiverUserEmail: data['email'],
                    receiverUserID: data['uid'],
                  ),
                ),
              );
            },
            child: ListTile(
              title: Text(
                data['email'],
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Status: ${data['status']}',
                style: TextStyle(
                  fontSize: 14.0,
                  color:data['status'] == 'Online' ? Colors.black : Colors.green,
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              trailing: Icon(Icons.chat, color: Colors.blue),
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
