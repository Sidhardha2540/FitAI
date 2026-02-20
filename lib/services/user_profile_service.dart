import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  factory UserProfileService() {
    return _instance;
  }

  UserProfileService._internal();

  // Check if user profile exists
  Future<bool> userProfileExists() async {
    try {
      return await _firebaseService.userProfileExists();
    } catch (e) {
      debugPrint('Error checking if user profile exists: $e');
      return false;
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      return await _firebaseService.getUserProfile();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Create user profile
  Future<bool> createUserProfile(UserProfile profile) async {
    try {
      return await _firebaseService.createUserProfile(profile);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      return await _firebaseService.updateUserProfile(profile);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      return await _firebaseService.uploadProfileImage(imageFile);
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Get current user profile from Firestore
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
} 