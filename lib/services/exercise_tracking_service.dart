import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_plan.dart';

class ExerciseTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final ExerciseTrackingService _instance = ExerciseTrackingService._internal();
  factory ExerciseTrackingService() => _instance;
  ExerciseTrackingService._internal();

  // Save an updated exercise with weight and completion status
  Future<void> updateExercise({
    required String workoutPlanId,
    required String workoutDay,
    required int exerciseIndex,
    required Exercise updatedExercise,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get the current workout plan
      final docRef = _firestore.collection('users').doc(userId).collection('workoutPlans').doc(workoutPlanId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('Workout plan not found');
      }

      // Get the current data
      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Ensure the workout days exist
      if (!data.containsKey('workoutDays') || data['workoutDays'] is! Map) {
        throw Exception('Invalid workout plan structure');
      }

      // Get the workout days
      final workoutDays = Map<String, dynamic>.from(data['workoutDays']);
      
      // Ensure the requested workout day exists
      if (!workoutDays.containsKey(workoutDay)) {
        throw Exception('Workout day not found');
      }

      // Get the exercises for that day
      final workoutDayData = Map<String, dynamic>.from(workoutDays[workoutDay]);
      if (!workoutDayData.containsKey('exercises') || workoutDayData['exercises'] is! List) {
        throw Exception('No exercises found for this day');
      }

      final exercises = List<Map<String, dynamic>>.from(workoutDayData['exercises']);
      
      // Ensure the exercise index is valid
      if (exerciseIndex < 0 || exerciseIndex >= exercises.length) {
        throw Exception('Invalid exercise index');
      }

      // Update the exercise at the specified index
      exercises[exerciseIndex] = updatedExercise.toMap();
      
      // Update the workout days with the modified exercises
      workoutDayData['exercises'] = exercises;
      workoutDays[workoutDay] = workoutDayData;
      
      // Update the document
      await docRef.update({
        'workoutDays': workoutDays,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating exercise: $e');
      rethrow;
    }
  }

  // Update exercise completion status
  Future<void> toggleExerciseCompletion({
    required String workoutPlanId,
    required String workoutDay,
    required int exerciseIndex,
    required bool isCompleted,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final docRef = _firestore.collection('users').doc(userId).collection('workoutPlans').doc(workoutPlanId);
      
      // Use a transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        
        if (!docSnapshot.exists) {
          throw Exception('Workout plan not found');
        }

        final data = docSnapshot.data() as Map<String, dynamic>;
        final workoutDays = Map<String, dynamic>.from(data['workoutDays']);
        final workoutDayData = Map<String, dynamic>.from(workoutDays[workoutDay]);
        final exercises = List<Map<String, dynamic>>.from(workoutDayData['exercises']);

        if (exerciseIndex < 0 || exerciseIndex >= exercises.length) {
          throw Exception('Invalid exercise index');
        }

        // Update the completion status
        exercises[exerciseIndex]['completed'] = isCompleted;
        
        workoutDayData['exercises'] = exercises;
        workoutDays[workoutDay] = workoutDayData;
        
        transaction.update(docRef, {
          'workoutDays': workoutDays,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error toggling exercise completion: $e');
      rethrow;
    }
  }

  // Update exercise weight
  Future<void> updateExerciseWeight({
    required String workoutPlanId,
    required String workoutDay,
    required int exerciseIndex,
    required double weight,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final docRef = _firestore.collection('users').doc(userId).collection('workoutPlans').doc(workoutPlanId);
      
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        
        if (!docSnapshot.exists) {
          throw Exception('Workout plan not found');
        }

        final data = docSnapshot.data() as Map<String, dynamic>;
        final workoutDays = Map<String, dynamic>.from(data['workoutDays']);
        final workoutDayData = Map<String, dynamic>.from(workoutDays[workoutDay]);
        final exercises = List<Map<String, dynamic>>.from(workoutDayData['exercises']);

        if (exerciseIndex < 0 || exerciseIndex >= exercises.length) {
          throw Exception('Invalid exercise index');
        }

        // Update the weight
        exercises[exerciseIndex]['weight'] = weight;
        
        workoutDayData['exercises'] = exercises;
        workoutDays[workoutDay] = workoutDayData;
        
        transaction.update(docRef, {
          'workoutDays': workoutDays,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error updating exercise weight: $e');
      rethrow;
    }
  }
  
  // Track workout completion
  Future<void> markWorkoutDayCompleted({
    required String workoutPlanId,
    required String workoutDay,
    required bool isCompleted,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final docRef = _firestore.collection('users').doc(userId).collection('workoutPlans').doc(workoutPlanId);
      
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        
        if (!docSnapshot.exists) {
          throw Exception('Workout plan not found');
        }

        final data = docSnapshot.data() as Map<String, dynamic>;
        final workoutDays = Map<String, dynamic>.from(data['workoutDays']);
        final workoutDayData = Map<String, dynamic>.from(workoutDays[workoutDay]);
        
        // Add completion status to the workout day
        workoutDayData['completed'] = isCompleted;
        workoutDayData['completedAt'] = isCompleted ? FieldValue.serverTimestamp() : null;
        
        workoutDays[workoutDay] = workoutDayData;
        
        // Update the document
        transaction.update(docRef, {
          'workoutDays': workoutDays,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
      
      // Also update workout history for analytics
      if (isCompleted) {
        await _addWorkoutToHistory(workoutPlanId, workoutDay);
      }
    } catch (e) {
      print('Error marking workout day completion: $e');
      rethrow;
    }
  }
  
  // Add completed workout to history for analytics
  Future<void> _addWorkoutToHistory(String workoutPlanId, String workoutDay) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      // Get the workout data
      final docRef = _firestore.collection('users').doc(userId).collection('workoutPlans').doc(workoutPlanId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) return;
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      final workoutDays = Map<String, dynamic>.from(data['workoutDays']);
      final workoutDayData = Map<String, dynamic>.from(workoutDays[workoutDay]);
      
      // Create a workout history entry
      await _firestore.collection('users').doc(userId).collection('workoutHistory').add({
        'workoutPlanId': workoutPlanId,
        'workoutDay': workoutDay,
        'workoutName': workoutDayData['name'] ?? 'Unknown Workout',
        'workoutType': workoutDayData['type'] ?? 'Unknown Type',
        'exercises': workoutDayData['exercises'] ?? [],
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding workout to history: $e');
    }
  }
} 