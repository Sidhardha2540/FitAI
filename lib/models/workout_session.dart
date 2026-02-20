import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutSession {
  final String? id;
  final String userId;
  final DateTime date;
  final String? workoutPlanId;
  final String workoutName;
  final String workoutType;
  final Duration? totalDuration;
  final int? caloriesBurned;
  final List<String> exerciseLogIds; // References to ExerciseLogEntry documents
  final String? notes;
  final WorkoutCompletionStatus completionStatus;
  final String? mood; // pre/post workout mood
  final int? perceivedExertion; // 1-10 scale
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutSession({
    this.id,
    required this.userId,
    required this.date,
    this.workoutPlanId,
    required this.workoutName,
    required this.workoutType,
    this.totalDuration,
    this.caloriesBurned,
    required this.exerciseLogIds,
    this.notes,
    this.completionStatus = WorkoutCompletionStatus.inProgress,
    this.mood,
    this.perceivedExertion,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    try {
      return WorkoutSession(
        id: map['id'],
        userId: map['userId'] ?? '',
        date: map['date'] is Timestamp 
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date'].toString()),
        workoutPlanId: map['workoutPlanId'],
        workoutName: map['workoutName'] ?? 'Unknown Workout',
        workoutType: map['workoutType'] ?? 'General',
        totalDuration: map['totalDurationSeconds'] != null 
          ? Duration(seconds: map['totalDurationSeconds'])
          : null,
        caloriesBurned: map['caloriesBurned']?.toInt(),
        exerciseLogIds: List<String>.from(map['exerciseLogIds'] ?? []),
        notes: map['notes'],
        completionStatus: WorkoutCompletionStatus.fromString(
          map['completionStatus'] ?? 'in_progress'
        ),
        mood: map['mood'],
        perceivedExertion: map['perceivedExertion']?.toInt(),
        createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'].toString()),
        updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'].toString()),
      );
    } catch (e) {
      debugPrint('Error parsing WorkoutSession: $e');
      return WorkoutSession(
        userId: '',
        date: DateTime.now(),
        workoutName: 'Error Workout',
        workoutType: 'General',
        exerciseLogIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'workoutPlanId': workoutPlanId,
      'workoutName': workoutName,
      'workoutType': workoutType,
      'totalDurationSeconds': totalDuration?.inSeconds,
      'caloriesBurned': caloriesBurned,
      'exerciseLogIds': exerciseLogIds,
      'notes': notes,
      'completionStatus': completionStatus.toString(),
      'mood': mood,
      'perceivedExertion': perceivedExertion,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

enum WorkoutCompletionStatus {
  notStarted,
  inProgress,
  completed,
  skipped;

  static WorkoutCompletionStatus fromString(String value) {
    switch (value) {
      case 'not_started': return WorkoutCompletionStatus.notStarted;
      case 'in_progress': return WorkoutCompletionStatus.inProgress;
      case 'completed': return WorkoutCompletionStatus.completed;
      case 'skipped': return WorkoutCompletionStatus.skipped;
      default: return WorkoutCompletionStatus.inProgress;
    }
  }

  @override
  String toString() {
    switch (this) {
      case WorkoutCompletionStatus.notStarted: return 'not_started';
      case WorkoutCompletionStatus.inProgress: return 'in_progress';
      case WorkoutCompletionStatus.completed: return 'completed';
      case WorkoutCompletionStatus.skipped: return 'skipped';
    }
  }
} 