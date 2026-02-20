import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  User? get currentUser => _auth.currentUser;

  Future<bool> userProfileExists() async {
    try {
      if (currentUser == null) {
        debugPrint("userProfileExists: No current user");
        return false;
      }
      
      debugPrint("userProfileExists: Checking for profile of user ${currentUser!.uid}");
      
      final docSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      final exists = docSnapshot.exists;
      debugPrint("userProfileExists: Profile exists: $exists");
      
      return exists;
    } catch (e) {
      debugPrint('Error checking if user profile exists: $e');
      return false;
    }
  }

  Future<UserProfile?> getUserProfile() async {
    try {
      if (currentUser == null) return null;
      
      final docSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
          
      if (!docSnapshot.exists) return null;
      
      final data = docSnapshot.data();
      if (data == null) return null;
      
      return UserProfile.fromMap(data);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> createUserProfile(UserProfile profile) async {
    try {
      if (currentUser == null) return false;
      
      // Create a profile map and manually set the timestamps
      final now = DateTime.now();
      final profileMap = profile.toMap();
      profileMap['user_id'] = currentUser!.uid;
      profileMap['email'] = currentUser!.email;
      profileMap['created_at'] = FieldValue.serverTimestamp();
      profileMap['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .set(profileMap);
          
      return true;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      if (currentUser == null) return false;
      
      // Create a profile map and manually set the timestamp
      final profileMap = profile.toMap();
      profileMap['user_id'] = currentUser!.uid;
      profileMap['updated_at'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(profileMap);
          
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      if (currentUser == null) return null;
      
      final fileName = '${currentUser!.uid}_${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child('profile_images/$fileName');
      
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  Future<String?> uploadChatImage(File imageFile) async {
    try {
      if (currentUser == null) return null;
      
      final fileName = 'chat_${currentUser!.uid}_${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child('chat_images/$fileName');
      
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading chat image: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
} 