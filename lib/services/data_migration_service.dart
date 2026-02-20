import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle migrating data between different Firestore collections
class DataMigrationService {
  static const String _oldWorkoutCollection = 'workout_Plans';
  static const String _newWorkoutCollection = 'workoutPlans';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Migrate workout plans from old collection to new collection
  Future<void> migrateWorkoutPlans() async {
    if (_auth.currentUser == null) return;
    
    try {
      debugPrint('Starting workout plans migration');
      
      // Get all workout plans from old collection for current user
      final oldPlansSnapshot = await _firestore
          .collection(_oldWorkoutCollection)
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .get();
      
      if (oldPlansSnapshot.docs.isEmpty) {
        debugPrint('No workout plans to migrate from $_oldWorkoutCollection');
        return;
      }
      
      debugPrint('Found ${oldPlansSnapshot.docs.length} plans to migrate');
      
      // For each old plan, copy to new collection if not exists
      for (final oldPlanDoc in oldPlansSnapshot.docs) {
        final oldPlanData = oldPlanDoc.data();
        final oldPlanId = oldPlanDoc.id;
        
        // Check if plan with same weekStartDate exists in new collection
        final weekStartDate = oldPlanData['weekStartDate'];
        if (weekStartDate == null) {
          debugPrint('Skipping migration for plan without weekStartDate: $oldPlanId');
          continue;
        }
        
        final existingPlanQuery = await _firestore
            .collection(_newWorkoutCollection)
            .where('userId', isEqualTo: _auth.currentUser!.uid)
            .where('weekStartDate', isEqualTo: weekStartDate)
            .limit(1)
            .get();
        
        // If plan doesn't exist in new collection, copy it
        if (existingPlanQuery.docs.isEmpty) {
          await _firestore
              .collection(_newWorkoutCollection)
              .doc(oldPlanId)
              .set(oldPlanData);
          
          debugPrint('Migrated workout plan with ID: $oldPlanId');
        } else {
          debugPrint('Plan already exists in new collection, skipping: $oldPlanId');
        }
      }
      
      debugPrint('Workout plans migration completed successfully');
    } catch (e) {
      debugPrint('Error during workout plans migration: $e');
      // Don't throw the error, just log it and continue
      // This allows the app to work even if migration fails
    }
  }
} 