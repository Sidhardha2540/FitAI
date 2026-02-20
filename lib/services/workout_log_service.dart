import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_plan.dart';
import '../models/workout_log.dart';
import 'package:intl/intl.dart';

class WorkoutLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection name constant
  static const String _workoutLogsCollection = 'workoutLogs';
  
  // Singleton pattern
  static final WorkoutLogService _instance = WorkoutLogService._internal();
  factory WorkoutLogService() => _instance;
  WorkoutLogService._internal();
  
  // Log a completed workout
  Future<bool> logCompletedWorkout({
    required DailyWorkout workout,
    required DateTime completedDate,
    String? notes,
    Map<String, dynamic>? additionalData,
    List<ExerciseLog>? detailedExercises,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('Cannot log workout: No authenticated user');
        return false;
      }
      
      // Debug the workout object
      debugPrint('Logging workout: ${workout.name} - Type: ${workout.type}');
      debugPrint('Workout calories: ${workout.caloriesBurned}');
      
      // Format date as YYYY-MM-DD for consistent querying
      final dateString = DateFormat('yyyy-MM-dd').format(completedDate);
      
      // Get day name (e.g., Monday, Tuesday)
      final dayName = DateFormat('EEEE').format(completedDate);
      
      // Use only the workout's caloriesBurned without default values
      final int? caloriesBurned = workout.caloriesBurned;
      
      // Prepare the exercises data
      List<Map<String, dynamic>> exercisesData = [];
      
      // If detailed exercises with sets are provided, use them
      if (detailedExercises != null && detailedExercises.isNotEmpty) {
        exercisesData = detailedExercises.map((exercise) => exercise.toMap()).toList();
      } else {
        // Otherwise use the original exercise format
        exercisesData = workout.exercises.map((exercise) => {
          'name': exercise.name,
          'sets': exercise.sets,
          'reps': exercise.reps,
          'instructions': exercise.instructions,
          'caloriesPerSet': exercise.caloriesPerSet,
        }).toList();
      }
      
      // Create the log entry
      final logData = {
        'userId': userId,
        'workoutName': workout.name,
        'workoutType': workout.type,
        'dayName': dayName,
        'day': workout.day,
        'duration': workout.duration,
        'completedDate': dateString,
        'timestamp': FieldValue.serverTimestamp(),
        'exercises': exercisesData,
        'notes': notes,
      };
      
      // Only add caloriesBurned if it exists
      if (caloriesBurned != null) {
        logData['caloriesBurned'] = caloriesBurned;
      }
      
      // Log the data being stored
      debugPrint('Storing log with calories: ${logData['caloriesBurned']}');
      
      // Add any additional custom data
      if (additionalData != null) {
        logData.addAll(additionalData);
      }
      
      // Add the log to Firestore
      await _firestore
          .collection(_workoutLogsCollection)
          .add(logData);
      
      debugPrint('Workout logged successfully for $dayName ($dateString) with calories: $caloriesBurned');
      return true;
    } catch (e) {
      debugPrint('Error logging workout: $e');
      return false;
    }
  }
  
  // Get all workout logs for a user
  Future<List<WorkoutLog>> getWorkoutLogs() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('Cannot get workout logs: No authenticated user');
        return [];
      }
      
      // Simplified query that doesn't require a composite index
      final querySnapshot = await _firestore
          .collection(_workoutLogsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      // Parse and sort the results
      final List<WorkoutLog> logs = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        
        try {
          final workoutLog = WorkoutLog.fromMap(data);
          logs.add(workoutLog);
        } catch (e) {
          debugPrint('Error parsing workout log: $e');
        }
      }
      
      // Sort by timestamp (latest first)
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return logs;
    } catch (e) {
      debugPrint('Error getting workout logs: $e');
      return [];
    }
  }
  
  // Get today's workout log
  Future<WorkoutLog?> getTodaysWorkoutLog() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('Cannot get workout logs: No authenticated user');
        return null;
      }
      
      // Get today's date in YYYY-MM-DD format
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Query for today's workout
      final querySnapshot = await _firestore
          .collection(_workoutLogsCollection)
          .where('userId', isEqualTo: userId)
          .where('completedDate', isEqualTo: today)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final doc = querySnapshot.docs.first;
            final data = doc.data();
      data['id'] = doc.id;
      
      return WorkoutLog.fromMap(data);
    } catch (e) {
      debugPrint('Error getting today\'s workout log: $e');
      return null;
    }
  }
  
  // Get workout logs for a specific date range
  Future<List<WorkoutLog>> getWorkoutLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      // Simplified query without complex indexes
      final querySnapshot = await _firestore
          .collection(_workoutLogsCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      // Filter and sort locally to avoid index requirements
      final allLogs = querySnapshot.docs
          .map((doc) => WorkoutLog.fromMap({...doc.data(), 'id': doc.id}))
          .where((log) => log.completedDate.compareTo(startDateStr) >= 0 && 
                         log.completedDate.compareTo(endDateStr) <= 0)
          .toList();
      
      // Sort by completed date (latest first)
      allLogs.sort((a, b) => b.completedDate.compareTo(a.completedDate));

      return allLogs;
    } catch (e) {
      debugPrint('Error getting workout logs by date range: $e');
      return [];
    }
  }
  
  // Get recent workout logs without complex queries
  Future<List<WorkoutLog>> getRecentWorkoutLogs({int limit = 5}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // Simple query with just userId - no complex indexes needed
      final querySnapshot = await _firestore
          .collection(_workoutLogsCollection)
          .where('userId', isEqualTo: user.uid)
          .limit(limit * 2) // Get more and filter locally
          .get();

      final logs = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return WorkoutLog.fromMap(data);
      }).toList();

      // Sort by completed date locally
      logs.sort((a, b) => b.completedDate.compareTo(a.completedDate));
      
      return logs.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent workout logs: $e');
      return [];
    }
  }
  
  // Check if a workout was already logged for a specific date
  Future<bool> isWorkoutLoggedForDate(DateTime date) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return false;
      }
      
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      
      final querySnapshot = await _firestore
          .collection(_workoutLogsCollection)
          .where('userId', isEqualTo: userId)
          .where('completedDate', isEqualTo: dateString)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if workout logged: $e');
      return false;
    }
  }
  
  // Delete a workout log
  Future<bool> deleteWorkoutLog(String logId) async {
    try {
      await _firestore
          .collection(_workoutLogsCollection)
          .doc(logId)
          .delete();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting workout log: $e');
      return false;
    }
  }
  
  // Update a workout log
  Future<bool> updateWorkoutLog(WorkoutLog log) async {
    try {
      if (log.id == null) {
        debugPrint('Cannot update workout log: No ID provided');
        return false;
      }
      
      final Map<String, dynamic> logData = log.toMap();
      // Replace timestamp with server timestamp for updates
      logData['timestamp'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(_workoutLogsCollection)
          .doc(log.id)
          .update(logData);
      
      return true;
    } catch (e) {
      debugPrint('Error updating workout log: $e');
      return false;
    }
  }
} 