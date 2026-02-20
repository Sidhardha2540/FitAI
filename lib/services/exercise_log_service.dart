import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise_log.dart';
import '../models/workout_plan.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ExerciseLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  
  // Collection names
  static const String _exerciseLogsCollection = 'exerciseLogs';
  
  // Singleton pattern
  static final ExerciseLogService _instance = ExerciseLogService._internal();
  factory ExerciseLogService() => _instance;
  ExerciseLogService._internal();

  // Generate unique exercise ID based on exercise name
  String generateExerciseId(String exerciseName) {
    return exerciseName.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  // Get or create today's exercise log for a specific exercise
  Future<ExerciseLogEntry?> getTodaysExerciseLog(String exerciseId, String exerciseName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Get all logs for this user and filter locally
      final querySnapshot = await _firestore
          .collection(_exerciseLogsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      // Find today's log for this exercise
      final todaysLogs = querySnapshot.docs
          .map((doc) => ExerciseLogEntry.fromMap({...doc.data(), 'id': doc.id}))
          .where((log) => 
              log.exerciseId == exerciseId && 
              log.date.isAfter(startOfDay) && 
              log.date.isBefore(endOfDay))
          .toList();

      if (todaysLogs.isNotEmpty) {
        // Return the existing log for today
        return todaysLogs.first;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting today\'s exercise log: $e');
      return null;
    }
  }

  // Log a single exercise with sets (updated to prevent multiple records per day)
  Future<String?> logExercise({
    required Exercise exercise,
    required List<SetData> completedSets,
    required DateTime date,
    String? workoutPlanId,
    String? workoutType,
    String? notes,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('Cannot log exercise: No authenticated user');
        return null;
      }

      // Only allow logging for today
      final today = DateTime.now();
      final logDate = DateTime(date.year, date.month, date.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      
      if (!logDate.isAtSameMomentAs(todayDate)) {
        debugPrint('Exercise logging is only allowed for today');
        return null;
      }

      final exerciseId = generateExerciseId(exercise.name);
      
      // Check if there's already a log for today
      final existingLog = await getTodaysExerciseLog(exerciseId, exercise.name);
      
      // Calculate personal record for this session
      PersonalRecord? sessionRecord;
      if (completedSets.where((set) => set.isCompleted).isNotEmpty) {
        final completedSetsList = completedSets.where((set) => set.isCompleted).toList();
        
        final maxWeight = completedSetsList
            .where((set) => set.weight != null)
            .map((set) => set.weight!)
            .fold<double>(0, (max, weight) => weight > max ? weight : max);
            
        final maxReps = completedSetsList
            .map((set) => int.tryParse(set.reps) ?? 0)
            .fold<int>(0, (max, reps) => reps > max ? reps : max);
            
        final totalVolume = completedSetsList
            .where((set) => set.weight != null)
            .map((set) => (set.weight ?? 0) * (int.tryParse(set.reps) ?? 0))
            .fold<double>(0, (sum, volume) => sum + volume);

        if (maxWeight > 0 || maxReps > 0 || totalVolume > 0) {
          sessionRecord = PersonalRecord(
            maxWeight: maxWeight > 0 ? maxWeight : null,
            maxReps: maxReps > 0 ? maxReps : null,
            maxVolume: totalVolume > 0 ? totalVolume : null,
            achievedAt: date,
          );
        }
      }

      if (existingLog != null) {
        // Update existing log
        final updatedLog = ExerciseLogEntry(
          id: existingLog.id,
          userId: userId,
          exerciseId: exerciseId,
          exerciseName: exercise.name,
          date: existingLog.date, // Keep original date
          sets: completedSets,
          workoutPlanId: workoutPlanId ?? existingLog.workoutPlanId,
          workoutType: workoutType ?? existingLog.workoutType,
          notes: notes ?? existingLog.notes,
          personalRecord: sessionRecord ?? existingLog.personalRecord,
          createdAt: existingLog.createdAt,
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(_exerciseLogsCollection)
            .doc(existingLog.id!)
            .update(updatedLog.toMap());

        debugPrint('Exercise log updated: ${exercise.name}');
        
        // Update user exercise history
        await _updateUserExerciseHistory(updatedLog);
        
        return existingLog.id;
      } else {
        // Create new log
        final logId = _uuid.v4();
        
        final exerciseLog = ExerciseLogEntry(
          id: logId,
          userId: userId,
          exerciseId: exerciseId,
          exerciseName: exercise.name,
          date: date,
          sets: completedSets,
          workoutPlanId: workoutPlanId,
          workoutType: workoutType,
          notes: notes,
          personalRecord: sessionRecord,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(_exerciseLogsCollection)
            .doc(logId)
            .set(exerciseLog.toMap());

        debugPrint('Exercise logged successfully: ${exercise.name}');
        
        // Update user exercise history
        await _updateUserExerciseHistory(exerciseLog);
        
        return logId;
      }
    } catch (e) {
      debugPrint('Error logging exercise: $e');
      return null;
    }
  }

  // Get exercise logs for a specific date (simplified to avoid index requirements)
  Future<List<ExerciseLogEntry>> getExerciseLogsForDate(DateTime date) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Simple query with just userId - no composite index needed
      final querySnapshot = await _firestore
          .collection(_exerciseLogsCollection)
          .where('userId', isEqualTo: userId)
          .limit(100) // Get more results and filter locally
          .get();

      // Filter by date locally to avoid index requirements
      final logs = querySnapshot.docs
          .map((doc) => ExerciseLogEntry.fromMap({...doc.data(), 'id': doc.id}))
          .where((log) => log.date.isAfter(startOfDay) && log.date.isBefore(endOfDay))
          .toList();

      // Sort by date locally
      logs.sort((a, b) => a.date.compareTo(b.date));
      
      return logs;
    } catch (e) {
      debugPrint('Error getting exercise logs for date: $e');
      return [];
    }
  }

  // Get recent exercise logs without complex queries
  Future<List<ExerciseLogEntry>> getRecentExerciseLogs({int limit = 10}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // Simple query with just userId - no complex indexes needed
      final querySnapshot = await _firestore
          .collection('exerciseLogs')
          .where('userId', isEqualTo: user.uid)
          .limit(limit)
          .get();

      final logs = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ExerciseLogEntry.fromMap(data);
      }).toList();

      // Sort by date locally
      logs.sort((a, b) => b.date.compareTo(a.date));
      
      return logs;
    } catch (e) {
      debugPrint('Error getting recent exercise logs: $e');
      return [];
    }
  }

  // Get exercise history (completely simplified - no indexes needed)
  Future<List<ExerciseLogEntry>> getExerciseHistory(String exerciseId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      print('Getting exercise history for exerciseId: $exerciseId, userId: $userId');

      // Simple query with ONLY userId - absolutely no indexes needed
      final querySnapshot = await _firestore
          .collection(_exerciseLogsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      print('Found ${querySnapshot.docs.length} total exercise logs');

      // Filter by exerciseId locally and sort by date
      final logs = querySnapshot.docs
          .map((doc) => ExerciseLogEntry.fromMap({...doc.data(), 'id': doc.id}))
          .where((log) => log.exerciseId == exerciseId)
          .toList();

      // Sort by date locally (newest first)
      logs.sort((a, b) => b.date.compareTo(a.date));

      print('Filtered to ${logs.length} logs for exercise: $exerciseId');

      return logs;
    } catch (e) {
      print('Error getting exercise history: $e');
      return [];
    }
  }

  // Get personal record for an exercise (simplified to avoid index requirements)
  Future<PersonalRecord?> getPersonalRecord(String exerciseId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      // Simple query with just userId - no composite index needed
      final querySnapshot = await _firestore
          .collection(_exerciseLogsCollection)
          .where('userId', isEqualTo: userId)
          .limit(100) // Get more results and filter locally
          .get();

      PersonalRecord? overallRecord;
      double maxWeight = 0;
      int maxReps = 0;
      double maxVolume = 0;
      DateTime? latestDate;

      // Filter by exerciseId and process locally
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['exerciseId'] != exerciseId) continue; // Filter locally
        
        final log = ExerciseLogEntry.fromMap({...data, 'id': doc.id});
        
        if (log.personalRecord != null) {
          final record = log.personalRecord!;
          bool isNewRecord = false;
          
          if (record.maxWeight != null && record.maxWeight! > maxWeight) {
            maxWeight = record.maxWeight!;
            isNewRecord = true;
          }
          
          if (record.maxReps != null && record.maxReps! > maxReps) {
            maxReps = record.maxReps!;
            isNewRecord = true;
          }
          
          if (record.maxVolume != null && record.maxVolume! > maxVolume) {
            maxVolume = record.maxVolume!;
            isNewRecord = true;
          }
          
          if (isNewRecord && (latestDate == null || record.achievedAt.isAfter(latestDate))) {
            latestDate = record.achievedAt;
          }
        }
      }

      if (maxWeight > 0 || maxReps > 0 || maxVolume > 0) {
        return PersonalRecord(
          maxWeight: maxWeight > 0 ? maxWeight : null,
          maxReps: maxReps > 0 ? maxReps : null,
          maxVolume: maxVolume > 0 ? maxVolume : null,
          achievedAt: latestDate ?? DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error getting personal record: $e');
      return null;
    }
  }

  // Update an existing exercise log
  Future<bool> updateExerciseLog(ExerciseLogEntry updatedLog) async {
    try {
      if (updatedLog.id == null) return false;

      final updatedData = updatedLog.toMap();
      updatedData['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection(_exerciseLogsCollection)
          .doc(updatedLog.id)
          .update(updatedData);

      // Update user exercise history
      await _updateUserExerciseHistory(updatedLog);

      return true;
    } catch (e) {
      debugPrint('Error updating exercise log: $e');
      return false;
    }
  }

  // Delete an exercise log
  Future<bool> deleteExerciseLog(String logId) async {
    try {
      await _firestore
          .collection(_exerciseLogsCollection)
          .doc(logId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting exercise log: $e');
      return false;
    }
  }

  // Private method to update user exercise history
  Future<void> _updateUserExerciseHistory(ExerciseLogEntry log) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // This will be implemented in UserExerciseHistoryService
      // For now, just log that we should update history
      debugPrint('Should update exercise history for ${log.exerciseName}');
    } catch (e) {
      debugPrint('Error updating user exercise history: $e');
    }
  }

  // Get exercise logs in date range (simplified to avoid index requirements)
  Future<List<ExerciseLogEntry>> getExerciseLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Simple query with just userId - no composite index needed
      final querySnapshot = await _firestore
          .collection(_exerciseLogsCollection)
          .where('userId', isEqualTo: userId)
          .limit(200) // Get more results and filter locally
          .get();

      // Filter by date range locally to avoid index requirements
      final logs = querySnapshot.docs
          .map((doc) => ExerciseLogEntry.fromMap({...doc.data(), 'id': doc.id}))
          .where((log) => 
              log.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
              log.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      // Sort by date locally
      logs.sort((a, b) => b.date.compareTo(a.date));
      
      return logs;
    } catch (e) {
      debugPrint('Error getting exercise logs by date range: $e');
      return [];
    }
  }
} 