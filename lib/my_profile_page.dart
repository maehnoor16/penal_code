import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'login_page.dart';
import 'legal_guidance_page.dart';
import 'update_information_page.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<MyProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore
  User? _user;
  String? _username;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  Future<void> _getUser() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        // Fetch additional user data from Firestore
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await _firestore.collection('users').where('email', isEqualTo: user.email).get();

        if (querySnapshot.docs.isNotEmpty) {
          // Assuming there's only one document for the user
          DocumentSnapshot<Map<String, dynamic>> snapshot = querySnapshot.docs.first;

          setState(() {
            _user = user;
            _username = snapshot['username'];
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: Text(
          'Profile Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _user != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: NetworkImage(_user!.photoURL ?? ''),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${_username ?? _user!.email ?? 'User'}!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to update information page
                User? currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UpdateInformationPage(user: currentUser),
                    ),
                  );
                } else {
                  // Handle the case when the user is not logged in
                  print('User not logged in');
                }
              },
              child: Text('Update Information'),
              style: ElevatedButton.styleFrom(
                primary: Colors.white,
                onPrimary: Colors.brown,
                side: BorderSide(color: Colors.brown),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LegalGuidancePage()),
                );
                // Implement your own navigation logic
              },
              child: Text('Legal Advice'),
              style: ElevatedButton.styleFrom(
                primary: Colors.white,
                onPrimary: Colors.brown,
                side: BorderSide(color: Colors.brown),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Implement your own navigation logic for study material
              },
              child: Text('Study Material'),
              style: ElevatedButton.styleFrom(
                primary: Colors.white,
                onPrimary: Colors.brown,
                side: BorderSide(color: Colors.brown),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginPage()),
                );
              },
              child: Text('Signout', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                primary: Colors.brown,
                onPrimary: Colors.white,
              ),
            ),
          ],
        ),
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: MyProfilePage(),
    theme: ThemeData(
      primaryColor: Colors.brown,
      hintColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
    ),
  ));
}
