import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Reusable SetData class (keep existing)
class SetData {
  final int setNumber;
  String reps;
  double? weight;
  bool isCompleted;
  DateTime? completedAt;

  SetData({
    required this.setNumber,
    required this.reps,
    this.weight,
    this.isCompleted = false,
    this.completedAt,
  });

  factory SetData.fromMap(Map<String, dynamic> map) {
    return SetData(
      setNumber: map['setNumber'] is int ? map['setNumber'] : 
                (int.tryParse(map['setNumber'].toString()) ?? 0),
      reps: map['reps']?.toString() ?? '',
      weight: map['weight'] is num ? (map['weight'] as num).toDouble() : 
              (map['weight'] != null ? double.tryParse(map['weight'].toString()) : null),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
        ? (map['completedAt'] is Timestamp 
          ? (map['completedAt'] as Timestamp).toDate() 
          : DateTime.parse(map['completedAt'].toString()))
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
    };
  }
}

// New persistent exercise log model
class ExerciseLogEntry {
  final String? id;
  final String userId;
  final String exerciseId; // Unique identifier for exercise type
  final String exerciseName;
  final DateTime date;
  final List<SetData> sets;
  final String? workoutPlanId;
  final String? workoutType;
  final String? notes;
  final PersonalRecord? personalRecord;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExerciseLogEntry({
    this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.date,
    required this.sets,
    this.workoutPlanId,
    this.workoutType,
    this.notes,
    this.personalRecord,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExerciseLogEntry.fromMap(Map<String, dynamic> map) {
    try {
      final rawSets = map['sets'] as List<dynamic>? ?? [];
      List<SetData> sets = [];
      
      for (var setData in rawSets) {
        if (setData is Map<String, dynamic>) {
          sets.add(SetData.fromMap(setData));
        }
      }

      return ExerciseLogEntry(
        id: map['id'],
        userId: map['userId'] ?? '',
        exerciseId: map['exerciseId'] ?? '',
        exerciseName: map['exerciseName'] ?? 'Unknown Exercise',
        date: map['date'] is Timestamp 
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date'].toString()),
        sets: sets,
        workoutPlanId: map['workoutPlanId'],
        workoutType: map['workoutType'],
        notes: map['notes'],
        personalRecord: map['personalRecord'] != null 
          ? PersonalRecord.fromMap(map['personalRecord'])
          : null,
        createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'].toString()),
        updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'].toString()),
      );
    } catch (e) {
      debugPrint('Error parsing ExerciseLogEntry: $e');
      return ExerciseLogEntry(
        userId: '',
        exerciseId: '',
        exerciseName: 'Error Exercise',
        date: DateTime.now(),
        sets: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'date': Timestamp.fromDate(date),
      'sets': sets.map((set) => set.toMap()).toList(),
      'workoutPlanId': workoutPlanId,
      'workoutType': workoutType,
      'notes': notes,
      'personalRecord': personalRecord?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// Personal record tracking
class PersonalRecord {
  final double? maxWeight;
  final int? maxReps;
  final double? maxVolume; // total weight × reps
  final DateTime achievedAt;

  PersonalRecord({
    this.maxWeight,
    this.maxReps,
    this.maxVolume,
    required this.achievedAt,
  });

  factory PersonalRecord.fromMap(Map<String, dynamic> map) {
    return PersonalRecord(
      maxWeight: map['maxWeight']?.toDouble(),
      maxReps: map['maxReps']?.toInt(),
      maxVolume: map['maxVolume']?.toDouble(),
      achievedAt: map['achievedAt'] is Timestamp 
        ? (map['achievedAt'] as Timestamp).toDate()
        : DateTime.parse(map['achievedAt'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxWeight': maxWeight,
      'maxReps': maxReps,
      'maxVolume': maxVolume,
      'achievedAt': Timestamp.fromDate(achievedAt),
    };
  }
} 