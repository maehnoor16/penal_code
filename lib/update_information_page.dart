import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;



class UpdateInformationPage extends StatefulWidget {
  final User user;
  final Function()? onProfileUpdated; // Callback to notify profile update

  const UpdateInformationPage({Key? key, required this.user, this.onProfileUpdated})
      : super(key: key);

  @override
  _UpdateInformationPageState createState() => _UpdateInformationPageState();
}

class _UpdateInformationPageState extends State<UpdateInformationPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _dobController = TextEditingController();
  File? _pickedImage;
  User? _user;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.user.displayName ?? '';
    _emailController.text = widget.user.email ?? '';
    _getUser(); // Fetch the additional user data including username and image URL
  }

  Future<void> _updateProfile() async {
    try {
      // Check if the username field is not empty before updating
      if (_usernameController.text.isNotEmpty) {
        await widget.user.updateDisplayName(_usernameController.text);
      }

      // Check if the email field is not empty before updating
      if (_emailController.text.isNotEmpty) {
        await widget.user.updateEmail(_emailController.text);
      }

      // Check if the password field is not empty before updating
      if (_passwordController.text.isNotEmpty) {
        await widget.user.updatePassword(_passwordController.text);
      }

      // Update the profile image if a new image is picked
      if (_pickedImage != null) {
        await _uploadImageToFirebase(); // Upload image to Firebase Storage
        widget.onProfileUpdated?.call();
      }

      // Update user data in Firestore
      await _updateUserDataInFirestore();

      // Reload the user to get the updated information
      await widget.user.reload();
      User? updatedUser = widget.user;
      if (updatedUser != null) {
        setState(() {
          // Update the UI with the new user information
          _usernameController.text = updatedUser.displayName ?? '';
          _emailController.text = updatedUser.email ?? '';
        });
      }

      // Show a success message or navigate to another screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
        ),
      );
    } catch (e) {
      print("Error updating profile: $e");
      // Handle the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile. Please try again.'),
        ),
      );
    }
  }

  Future<void> _uploadImageToFirebase() async {
    try {
      String userEmail = widget.user.email ?? '';
      String fileName = 'profile_images/$userEmail.jpg';

      // Upload image to Firebase Storage
      UploadTask uploadTask =
      FirebaseStorage.instance.ref().child(fileName).putFile(_pickedImage!);

      TaskSnapshot taskSnapshot = await uploadTask;

      // Get the uploaded image URL
      String imageUrl = await taskSnapshot.ref.getDownloadURL();
      setState(() {
        _imageUrl = imageUrl;
      });
    } catch (e) {
      print("Error uploading image to Firebase: $e");
    }
  }



  Future<void> _updateUserDataInFirestore() async {
    try {
      // Update user data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        if (_usernameController.text.isNotEmpty) 'username': _usernameController.text,
        if (_emailController.text.isNotEmpty) 'email': _emailController.text,
        if (_dobController.text.isNotEmpty) 'dob': _dobController.text,
        if (_imageUrl != null) 'photoURL': _imageUrl, // Store image URL in Firestore
        // Add other fields as needed
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating user data in Firestore: $e");
    }
  }

  Future<void> _getUser() async {
    try {
      User? user = widget.user; // Use the passed user

      if (user != null) {
        // Fetch additional user data from Firestore
        DocumentSnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        setState(() {
          _user = user;
          _usernameController.text = snapshot['username'] ?? '';
          _imageUrl = snapshot['photoURL']; // Get the stored image URL
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _pickedImage = File(pickedImage.path);
        });
      }
    } catch (e) {
      print("Error picking profile picture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _pickedImage != null
                    ? FileImage(_pickedImage!)
                    : (_imageUrl != null
                    ? NetworkImage(_imageUrl!)
                    : AssetImage('assets/logo.png') as ImageProvider),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Update Information for ${_usernameController.text.isNotEmpty ? _usernameController.text : _user?.displayName ?? 'User'}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password (optional)'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              controller: _dobController,
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );

                if (selectedDate != null) {
                  setState(() {
                    _dobController.text = selectedDate.toLocal().toString().split(' ')[0];
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Date of Birth',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
