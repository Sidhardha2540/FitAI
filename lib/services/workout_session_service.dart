import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/workout_session.dart';
import '../models/workout_plan.dart';
import 'package:uuid/uuid.dart';

class WorkoutSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  
  // Collection names
  static const String _workoutSessionsCollection = 'workoutSessions';
  
  // Singleton pattern
  static final WorkoutSessionService _instance = WorkoutSessionService._internal();
  factory WorkoutSessionService() => _instance;
  WorkoutSessionService._internal();

  // Create a new workout session
  Future<String?> createWorkoutSession({
    required DailyWorkout workout,
    required DateTime date,
    String? workoutPlanId,
    String? notes,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('Cannot create workout session: No authenticated user');
        return null;
      }

      final sessionId = _uuid.v4();
      
      final session = WorkoutSession(
        id: sessionId,
        userId: userId,
        date: date,
        workoutPlanId: workoutPlanId,
        workoutName: workout.name,
        workoutType: workout.type,
        caloriesBurned: workout.caloriesBurned,
        exerciseLogIds: [], // Will be populated as exercises are logged
        notes: notes,
        completionStatus: WorkoutCompletionStatus.inProgress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_workoutSessionsCollection)
          .doc(sessionId)
          .set(session.toMap());

      debugPrint('Workout session created: ${workout.name}');
      return sessionId;
    } catch (e) {
      debugPrint('Error creating workout session: $e');
      return null;
    }
  }

  // Update workout session with exercise log reference
  Future<bool> addExerciseToSession({
    required String sessionId,
    required String exerciseLogId,
  }) async {
    try {
      await _firestore
          .collection(_workoutSessionsCollection)
          .doc(sessionId)
          .update({
        'exerciseLogIds': FieldValue.arrayUnion([exerciseLogId]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding exercise to session: $e');
      return false;
    }
  }

  // Complete a workout session
  Future<bool> completeWorkoutSession({
    required String sessionId,
    Duration? totalDuration,
    int? caloriesBurned,
    int? perceivedExertion,
    String? mood,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'completionStatus': WorkoutCompletionStatus.completed.toString(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (totalDuration != null) {
        updateData['totalDurationSeconds'] = totalDuration.inSeconds;
      }
      if (caloriesBurned != null) {
        updateData['caloriesBurned'] = caloriesBurned;
      }
      if (perceivedExertion != null) {
        updateData['perceivedExertion'] = perceivedExertion;
      }
      if (mood != null) {
        updateData['mood'] = mood;
      }
      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _firestore
          .collection(_workoutSessionsCollection)
          .doc(sessionId)
          .update(updateData);

      return true;
    } catch (e) {
      debugPrint('Error completing workout session: $e');
      return false;
    }
  }

  // Get today's workout session (simplified to avoid composite index)
  Future<WorkoutSession?> getTodaysWorkoutSession() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Simple query with just userId - no composite index needed
      final querySnapshot = await _firestore
          .collection(_workoutSessionsCollection)
          .where('userId', isEqualTo: userId)
          .limit(20) // Get recent sessions and filter locally
          .get();

      // Filter by date locally to avoid index requirements
      for (var doc in querySnapshot.docs) {
        final session = WorkoutSession.fromMap({...doc.data(), 'id': doc.id});
        if (session.date.isAfter(startOfDay) && session.date.isBefore(endOfDay)) {
          return session;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting today\'s workout session: $e');
      return null;
    }
  }

  // Get workout sessions in date range (simplified to avoid composite index)
  Future<List<WorkoutSession>> getWorkoutSessionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Simple query with just userId - no composite index needed
      final querySnapshot = await _firestore
          .collection(_workoutSessionsCollection)
          .where('userId', isEqualTo: userId)
          .limit(100) // Get more results and filter locally
          .get();

      // Filter by date range locally
      final sessions = querySnapshot.docs
          .map((doc) => WorkoutSession.fromMap({...doc.data(), 'id': doc.id}))
          .where((session) => 
              session.date.isAfter(startDate) && 
              session.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      // Sort by date locally
      sessions.sort((a, b) => b.date.compareTo(a.date));
      
      return sessions;
    } catch (e) {
      debugPrint('Error getting workout sessions by date range: $e');
      return [];
    }
  }

  // Get all workout sessions for user (simplified)
  Future<List<WorkoutSession>> getAllWorkoutSessions() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Simple query with just userId
      final querySnapshot = await _firestore
          .collection(_workoutSessionsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => WorkoutSession.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Sort by date locally
      sessions.sort((a, b) => b.date.compareTo(a.date));
      
      return sessions;
    } catch (e) {
      debugPrint('Error getting all workout sessions: $e');
      return [];
    }
  }

  // Delete workout session
  Future<bool> deleteWorkoutSession(String sessionId) async {
    try {
      await _firestore
          .collection(_workoutSessionsCollection)
          .doc(sessionId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting workout session: $e');
      return false;
    }
  }
} 