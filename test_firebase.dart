import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Test')),
        body: const FirebaseTestWidget(),
      ),
    );
  }
}

class FirebaseTestWidget extends StatefulWidget {
  const FirebaseTestWidget({super.key});

  @override
  State<FirebaseTestWidget> createState() => _FirebaseTestWidgetState();
}

class _FirebaseTestWidgetState extends State<FirebaseTestWidget> {
  String _status = 'Checking Firebase connectivity...';
  bool _isLoggedIn = false;
  String _userId = '';
  
  @override
  void initState() {
    super.initState();
    _checkFirebase();
  }
  
  Future<void> _checkFirebase() async {
    try {
      // Check Firebase connection
      _status = 'Checking Firebase connection...';
      setState(() {});

      await FirebaseFirestore.instance.collection('test').add({
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      _status = 'Firebase Firestore is connected! Test document created.';
      setState(() {});
      
      // Check for current user
      final user = FirebaseAuth.instance.currentUser;
      _isLoggedIn = user != null;
      _userId = user?.uid ?? 'Not logged in';
      setState(() {});
      
      if (_isLoggedIn) {
        // Check for user profile
        final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
          
        if (docSnapshot.exists) {
          _status = 'User profile exists in Firestore!';
        } else {
          _status = 'User is authenticated but no profile found in Firestore.';
        }
      }
      
      setState(() {});
    } catch (e) {
      _status = 'Error: $e';
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: $_status', 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text('Logged in: $_isLoggedIn'),
          Text('User ID: $_userId'),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _checkFirebase,
            child: const Text('Test Firebase Again'),
          ),
        ],
      ),
    );
  }
} 