import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  File? _profileImage;

  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get profileImage => _profileImage;
  bool get hasProfile => _userProfile != null;

  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // First check if profile exists
      final exists = await _firebaseService.userProfileExists();
      print("Profile exists: $exists");
      
      if (exists) {
        // Only load if it exists
        final profile = await _firebaseService.getUserProfile();
        _userProfile = profile;
      } else {
        // Make sure to set the profile to null if it doesn't exist
        _userProfile = null;
      }
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize: $e');
      _userProfile = null;
    }
  }

  // Load user profile from database
  Future<void> loadUserProfile() async {
    _setLoading(true);
    try {
      final profile = await _firebaseService.getUserProfile();
      _userProfile = profile;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load profile: $e');
    }
  }

  // Create user profile
  Future<bool> createUserProfile(UserProfile profile) async {
    _setLoading(true);
    try {
      final success = await _firebaseService.createUserProfile(profile);
      if (success) {
        _userProfile = profile;
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Failed to create profile: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserProfile profile) async {
    _setLoading(true);
    try {
      final success = await _firebaseService.updateUserProfile(profile);
      if (success) {
        _userProfile = profile;
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    }
  }

  // Set profile image
  void setProfileImage(File? image) {
    _profileImage = image;
    notifyListeners();
  }

  // Upload profile image
  Future<String?> uploadProfileImage() async {
    if (_profileImage == null) return null;
    
    _setLoading(true);
    try {
      final imageUrl = await _firebaseService.uploadProfileImage(_profileImage!);
      _setLoading(false);
      return imageUrl;
    } catch (e) {
      _setError('Failed to upload image: $e');
      return null;
    }
  }

  // Check if user profile exists
  Future<bool> checkProfileExists() async {
    return await _firebaseService.userProfileExists();
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _firebaseService.signOut();
      _userProfile = null;
      _profileImage = null;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to sign out: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 