import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_exercise_history.dart';
import '../models/exercise_log.dart';

class UserExerciseHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection names
  static const String _userExerciseHistoryCollection = 'userExerciseHistory';
  
  // Singleton pattern
  static final UserExerciseHistoryService _instance = UserExerciseHistoryService._internal();
  factory UserExerciseHistoryService() => _instance;
  UserExerciseHistoryService._internal();

  // Update exercise history after logging an exercise
  Future<void> updateExerciseHistory(ExerciseLogEntry exerciseLog) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get existing history or create new
      final historyRef = _firestore
          .collection(_userExerciseHistoryCollection)
          .doc(userId)
          .collection('exercises')
          .doc(exerciseLog.exerciseId);

      final historyDoc = await historyRef.get();
      UserExerciseHistory history;

      if (historyDoc.exists) {
        history = UserExerciseHistory.fromMap(historyDoc.data()!);
      } else {
        history = UserExerciseHistory(
          exerciseId: exerciseLog.exerciseId,
          exerciseName: exerciseLog.exerciseName,
          recentPerformance: [],
        );
      }

      // Calculate performance summary for this session
      final completedSets = exerciseLog.sets.where((set) => set.isCompleted).toList();
      if (completedSets.isNotEmpty) {
        final maxWeight = completedSets
            .where((set) => set.weight != null)
            .map((set) => set.weight!)
            .fold<double>(0, (max, weight) => weight > max ? weight : max);

        final totalVolume = completedSets
            .where((set) => set.weight != null)
            .map((set) => (set.weight ?? 0) * (int.tryParse(set.reps) ?? 0))
            .fold<double>(0, (sum, volume) => sum + volume);

        final performance = ExercisePerformanceSummary(
          date: exerciseLog.date,
          maxWeight: maxWeight > 0 ? maxWeight : null,
          totalSets: exerciseLog.sets.length,
          completedSets: completedSets.length,
          totalVolume: totalVolume,
        );

        // Add to recent performance (keep last 10)
        final updatedRecentPerformance = [performance, ...history.recentPerformance];
        if (updatedRecentPerformance.length > 10) {
          updatedRecentPerformance.removeRange(10, updatedRecentPerformance.length);
        }

        // Check for new personal records
        PersonalRecord? newAllTimeRecord = history.allTimeRecord;
        if (exerciseLog.personalRecord != null) {
          final sessionRecord = exerciseLog.personalRecord!;
          
          if (newAllTimeRecord == null) {
            newAllTimeRecord = sessionRecord;
          } else {
            // Update if new records achieved
            final updatedRecord = PersonalRecord(
              maxWeight: (sessionRecord.maxWeight != null && 
                         (newAllTimeRecord.maxWeight == null || 
                          sessionRecord.maxWeight! > newAllTimeRecord.maxWeight!))
                  ? sessionRecord.maxWeight
                  : newAllTimeRecord.maxWeight,
              maxReps: (sessionRecord.maxReps != null && 
                       (newAllTimeRecord.maxReps == null || 
                        sessionRecord.maxReps! > newAllTimeRecord.maxReps!))
                  ? sessionRecord.maxReps
                  : newAllTimeRecord.maxReps,
              maxVolume: (sessionRecord.maxVolume != null && 
                         (newAllTimeRecord.maxVolume == null || 
                          sessionRecord.maxVolume! > newAllTimeRecord.maxVolume!))
                  ? sessionRecord.maxVolume
                  : newAllTimeRecord.maxVolume,
              achievedAt: sessionRecord.achievedAt,
            );
            newAllTimeRecord = updatedRecord;
          }
        }

        // Calculate progress trend
        final progressTrend = _calculateProgressTrend(updatedRecentPerformance);

        // Calculate averages
        final totalSessions = history.totalSessions + 1;
        final allWeights = updatedRecentPerformance
            .where((p) => p.maxWeight != null)
            .map((p) => p.maxWeight!)
            .toList();
        final averageWeight = allWeights.isNotEmpty 
            ? allWeights.reduce((a, b) => a + b) / allWeights.length
            : 0.0;

        final allVolumes = updatedRecentPerformance.map((p) => p.totalVolume).toList();
        final averageVolume = allVolumes.isNotEmpty 
            ? allVolumes.reduce((a, b) => a + b) / allVolumes.length
            : 0.0;

        // Create updated history
        final updatedHistory = UserExerciseHistory(
          exerciseId: history.exerciseId,
          exerciseName: history.exerciseName,
          allTimeRecord: newAllTimeRecord,
          recentPerformance: updatedRecentPerformance,
          progressTrend: progressTrend,
          lastPerformed: exerciseLog.date,
          totalSessions: totalSessions,
          averageWeight: averageWeight,
          averageReps: averageVolume / (averageWeight > 0 ? averageWeight : 1),
        );

        // Save to Firestore
        await historyRef.set(updatedHistory.toMap());
        
        debugPrint('Updated exercise history for ${exerciseLog.exerciseName}');
      }
    } catch (e) {
      debugPrint('Error updating exercise history: $e');
    }
  }

  // Get exercise history for a specific exercise
  Future<UserExerciseHistory?> getExerciseHistory(String exerciseId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection(_userExerciseHistoryCollection)
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .get();

      if (!doc.exists) return null;

      return UserExerciseHistory.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting exercise history: $e');
      return null;
    }
  }

  // Get all exercise histories for user (simplified - no indexes needed)
  Future<List<UserExerciseHistory>> getAllExerciseHistories() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Simple query without orderBy to avoid index requirements
      final querySnapshot = await _firestore
          .collection(_userExerciseHistoryCollection)
          .doc(userId)
          .collection('exercises')
          .get();

      final histories = querySnapshot.docs
          .map((doc) => UserExerciseHistory.fromMap(doc.data()))
          .toList();

      // Sort by lastPerformed locally (most recent first)
      histories.sort((a, b) {
        if (a.lastPerformed == null && b.lastPerformed == null) return 0;
        if (a.lastPerformed == null) return 1;
        if (b.lastPerformed == null) return -1;
        return b.lastPerformed!.compareTo(a.lastPerformed!);
      });

      return histories;
    } catch (e) {
      debugPrint('Error getting all exercise histories: $e');
      return [];
    }
  }

  // Get exercises with improving trend (simplified - no indexes needed)
  Future<List<UserExerciseHistory>> getImprovingExercises() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Simple query without complex indexes
      final querySnapshot = await _firestore
          .collection(_userExerciseHistoryCollection)
          .doc(userId)
          .collection('exercises')
          .get();

      // Filter locally for improving trend
      final improvingExercises = querySnapshot.docs
          .map((doc) => UserExerciseHistory.fromMap(doc.data()))
          .where((history) => history.progressTrend == ProgressTrend.improving)
          .toList();

      // Sort by lastPerformed locally (most recent first)
      improvingExercises.sort((a, b) {
        if (a.lastPerformed == null && b.lastPerformed == null) return 0;
        if (a.lastPerformed == null) return 1;
        if (b.lastPerformed == null) return -1;
        return b.lastPerformed!.compareTo(a.lastPerformed!);
      });

      return improvingExercises;
    } catch (e) {
      debugPrint('Error getting improving exercises: $e');
      return [];
    }
  }

  // Get recent personal records
  Future<List<UserExerciseHistory>> getRecentPersonalRecords({int days = 30}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      final querySnapshot = await _firestore
          .collection(_userExerciseHistoryCollection)
          .doc(userId)
          .collection('exercises')
          .get();

      final recentRecords = <UserExerciseHistory>[];
      
      for (var doc in querySnapshot.docs) {
        final history = UserExerciseHistory.fromMap(doc.data());
        if (history.allTimeRecord != null && 
            history.allTimeRecord!.achievedAt.isAfter(cutoffDate)) {
          recentRecords.add(history);
        }
      }

      // Sort by record date (most recent first)
      recentRecords.sort((a, b) => 
          b.allTimeRecord!.achievedAt.compareTo(a.allTimeRecord!.achievedAt));

      return recentRecords;
    } catch (e) {
      debugPrint('Error getting recent personal records: $e');
      return [];
    }
  }

  // Private method to calculate progress trend
  ProgressTrend _calculateProgressTrend(List<ExercisePerformanceSummary> recentPerformance) {
    if (recentPerformance.length < 3) return ProgressTrend.stable;

    // Take last 3 sessions and compare with previous 3
    final recent = recentPerformance.take(3).toList();
    final previous = recentPerformance.skip(3).take(3).toList();

    if (previous.isEmpty) return ProgressTrend.stable;

    // Compare average volumes
    final recentAvgVolume = recent
        .map((p) => p.totalVolume)
        .reduce((a, b) => a + b) / recent.length;
    
    final previousAvgVolume = previous
        .map((p) => p.totalVolume)
        .reduce((a, b) => a + b) / previous.length;

    const significantChange = 0.05; // 5% change threshold
    
    if (recentAvgVolume > previousAvgVolume * (1 + significantChange)) {
      return ProgressTrend.improving;
    } else if (recentAvgVolume < previousAvgVolume * (1 - significantChange)) {
      return ProgressTrend.declining;
    }
    
    return ProgressTrend.stable;
  }

  // Delete exercise history
  Future<bool> deleteExerciseHistory(String exerciseId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection(_userExerciseHistoryCollection)
          .doc(userId)
          .collection('exercises')
          .doc(exerciseId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting exercise history: $e');
      return false;
    }
  }
} 