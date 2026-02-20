import 'package:flutter/foundation.dart';
import 'exercise_log.dart'; // Import SetData and ExerciseLogEntry from exercise_log.dart

class WorkoutLog {
  final String? id;
  final String userId;
  final String workoutName;
  final String workoutType;
  final String dayName;
  final int day;
  final String duration;
  final String completedDate;
  final DateTime timestamp;
  final List<ExerciseLog> exercises;
  final String? notes;
  final int? caloriesBurned;

  WorkoutLog({
    this.id,
    required this.userId,
    required this.workoutName,
    required this.workoutType,
    required this.dayName,
    required this.day,
    required this.duration,
    required this.completedDate,
    required this.timestamp,
    required this.exercises,
    this.notes,
    this.caloriesBurned,
  });

  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    try {
      final rawExercises = map['exercises'] as List<dynamic>? ?? [];
      final List<ExerciseLog> exercises = [];
      
      for (var exerciseData in rawExercises) {
        if (exerciseData is Map<String, dynamic>) {
          // Check if this exercise has detailed set information
          if (exerciseData['sets_detail'] != null && exerciseData['sets_detail'] is List) {
            exercises.add(ExerciseLog.fromMap(exerciseData));
          } else {
            // Convert old format to new format with sets
            final name = exerciseData['name'] ?? 'Unknown Exercise';
            final sets = exerciseData['sets'] is int ? exerciseData['sets'] : 
                         int.tryParse(exerciseData['sets'].toString()) ?? 0;
            final reps = exerciseData['reps'] ?? '';
            
            // Create a default set of SetData based on the sets and reps info
            List<SetData> defaultSets = [];
            for (int i = 0; i < sets; i++) {
              defaultSets.add(SetData(
                setNumber: i + 1,
                reps: reps is int ? reps.toString() : reps.toString(),
                weight: null,
                isCompleted: false,
              ));
            }
            
            exercises.add(ExerciseLog(
              name: name,
              setCount: sets,
              defaultReps: reps is int ? reps.toString() : reps.toString(),
              instructions: exerciseData['instructions'] ?? '',
              caloriesPerSet: exerciseData['caloriesPerSet'],
              sets: defaultSets,
            ));
          }
        }
      }

      DateTime timestamp;
      if (map['timestamp'] is DateTime) {
        timestamp = map['timestamp'];
      } else if (map['timestamp'] != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
          (map['timestamp'].seconds * 1000) + (map['timestamp'].nanoseconds ~/ 1000000),
        );
      } else {
        timestamp = DateTime.now();
      }

      return WorkoutLog(
        id: map['id'],
        userId: map['userId'] ?? '',
        workoutName: map['workoutName'] ?? 'Unknown Workout',
        workoutType: map['workoutType'] ?? '',
        dayName: map['dayName'] ?? '',
        day: map['day'] is int ? map['day'] : (int.tryParse(map['day'].toString()) ?? 0),
        duration: map['duration'] ?? '',
        completedDate: map['completedDate'] ?? '',
        timestamp: timestamp,
        exercises: exercises,
        notes: map['notes'],
        caloriesBurned: map['caloriesBurned'] is int ? map['caloriesBurned'] : 
                        (int.tryParse(map['caloriesBurned'].toString()) ?? null),
      );
    } catch (e) {
      debugPrint('Error parsing WorkoutLog: $e');
      return WorkoutLog(
        userId: '',
        workoutName: 'Error Workout',
        workoutType: '',
        dayName: '',
        day: 0,
        duration: '',
        completedDate: '',
        timestamp: DateTime.now(),
        exercises: [],
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'workoutName': workoutName,
      'workoutType': workoutType,
      'dayName': dayName,
      'day': day,
      'duration': duration,
      'completedDate': completedDate,
      'timestamp': timestamp,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      if (notes != null) 'notes': notes,
      if (caloriesBurned != null) 'caloriesBurned': caloriesBurned,
    };
  }
}

class ExerciseLog {
  final String name;
  final int setCount;
  final String defaultReps;
  final String instructions;
  final int? caloriesPerSet;
  final List<SetData> sets;

  ExerciseLog({
    required this.name,
    required this.setCount,
    required this.defaultReps,
    this.instructions = '',
    this.caloriesPerSet,
    required this.sets,
  });

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    try {
      final rawSets = map['sets_detail'] as List<dynamic>? ?? [];
      List<SetData> sets = [];
      
      for (var setData in rawSets) {
        if (setData is Map<String, dynamic>) {
          sets.add(SetData.fromMap(setData));
        }
      }
      
      // If no sets were found, create default ones
      if (sets.isEmpty) {
        final setCount = map['sets'] is int ? map['sets'] : 
                        (int.tryParse(map['sets'].toString()) ?? 0);
        final defaultReps = map['reps']?.toString() ?? '';
        
        for (int i = 0; i < setCount; i++) {
          sets.add(SetData(
            setNumber: i + 1,
            reps: defaultReps,
            weight: null,
            isCompleted: false,
          ));
        }
      }

      return ExerciseLog(
        name: map['name'] ?? 'Unknown Exercise',
        setCount: map['sets'] is int ? map['sets'] : 
                 (int.tryParse(map['sets'].toString()) ?? sets.length),
        defaultReps: map['reps']?.toString() ?? '',
        instructions: map['instructions'] ?? '',
        caloriesPerSet: map['caloriesPerSet'] is int ? map['caloriesPerSet'] : 
                        (int.tryParse(map['caloriesPerSet'].toString()) ?? null),
        sets: sets,
      );
    } catch (e) {
      debugPrint('Error parsing ExerciseLog: $e');
      return ExerciseLog(
        name: 'Error Exercise',
        setCount: 0,
        defaultReps: '',
        sets: [],
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': setCount,
      'reps': defaultReps,
      'instructions': instructions,
      if (caloriesPerSet != null) 'caloriesPerSet': caloriesPerSet,
      'sets_detail': sets.map((set) => set.toMap()).toList(),
    };
  }
} 