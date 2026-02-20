import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class WorkoutPlan {
  final String? id;
  final DateTime weekStartDate;
  final List<DailyWorkout> workouts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? preferredTime;
  final String? specialConsiderations;
  final int? totalWeeklyCalories;
  final List<int>? workoutDays;

  WorkoutPlan({
    this.id,
    required this.weekStartDate,
    required this.workouts,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.preferredTime,
    this.specialConsiderations,
    this.totalWeeklyCalories,
    this.workoutDays,
  });

  factory WorkoutPlan.fromMap(Map<String, dynamic> map) {
    try {
      debugPrint('Parsing WorkoutPlan from map with keys: ${map.keys.toList()}');
      final List<DailyWorkout> workouts = [];
      
      // Multiple approaches to find the workouts data
      // 1. Try workoutPlan field (most common in our app)
      if (map['workoutPlan'] != null) {
        debugPrint('workoutPlan field found with type: ${map['workoutPlan'].runtimeType}');
        if (map['workoutPlan'] is List) {
          final workoutList = map['workoutPlan'] as List;
          debugPrint('workoutPlan contains ${workoutList.length} items');
          
          for (var workout in workoutList) {
            if (workout is Map<String, dynamic>) {
              try {
                final dailyWorkout = DailyWorkout.fromMap(workout);
                workouts.add(dailyWorkout);
              } catch (e) {
                debugPrint('Error parsing individual workout: $e');
                debugPrint('Problematic workout data: $workout');
              }
            } else {
              debugPrint('Skipping invalid workout format: $workout (type: ${workout.runtimeType})');
            }
          }
        } else {
          debugPrint('Invalid workoutPlan format, not a list: ${map['workoutPlan']} (type: ${map['workoutPlan'].runtimeType})');
        }
      } 
      // 2. Try direct workouts field 
      else if (map['workouts'] != null && map['workouts'] is List) {
        debugPrint('workouts field found with ${(map['workouts'] as List).length} items');
        final workoutList = map['workouts'] as List;
        
        for (var workout in workoutList) {
          if (workout is Map<String, dynamic>) {
            try {
              final dailyWorkout = DailyWorkout.fromMap(workout);
              workouts.add(dailyWorkout);
            } catch (e) {
              debugPrint('Error parsing individual workout from workouts field: $e');
            }
          }
        }
      }
      // 3. Check for direct root-level workout objects (day 0, 1, 2, etc)
      else {
        debugPrint('Looking for direct root-level workout data');
        // Check if root contains workout data directly
        bool foundWorkoutData = false;
        
        for (int i = 0; i <= 6; i++) {  // 0-6 for days of week array-style
          if (map[i.toString()] is Map<String, dynamic>) {
            try {
              workouts.add(DailyWorkout.fromMap(
                {...map[i.toString()], 'day': i + 1}
              ));
              foundWorkoutData = true;
            } catch (e) {
              debugPrint('Error parsing direct workout at index $i: $e');
            }
          }
        }
        
        // Try day names if numeric indexes didn't work
        if (!foundWorkoutData) {
          final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
          for (int i = 0; i < dayNames.length; i++) {
            if (map[dayNames[i]] is Map<String, dynamic>) {
              try {
                workouts.add(DailyWorkout.fromMap(
                  {...map[dayNames[i]], 'day': i + 1, 'dayName': dayNames[i].capitalize()}
                ));
                foundWorkoutData = true;
              } catch (e) {
                debugPrint('Error parsing workout for ${dayNames[i]}: $e');
              }
            }
          }
        }
        
        if (!foundWorkoutData) {
          debugPrint('WARNING: Could not find workout data in any expected format');
        }
      }
      
      // Parse workout days array if available
      List<int>? workoutDays;
      if (map['workoutDays'] != null && map['workoutDays'] is List) {
        workoutDays = (map['workoutDays'] as List)
            .where((item) => item != null)
            .map<int>((item) => item is int ? item : int.tryParse(item.toString()) ?? 0)
            .where((day) => day > 0 && day <= 7)
            .toList();
      }
      
      // For weekStartDate, we don't actually use this for workout display
      // But parse it anyway for completeness - with a very lenient approach
      DateTime weekStartDate = DateTime.now();
      try {
        if (map['weekStartDate'] != null) {
          // Just use any valid date format, but don't worry if it fails
          try {
            weekStartDate = DateTime.parse(map['weekStartDate'].toString());
          } catch (_) {
            // If parsing fails, just use current date - it's not critical
            weekStartDate = DateTime.now();
          }
        }
      } catch (_) {
        // Silently use current date as fallback
        weekStartDate = DateTime.now();
      }
      
      // Simple parsing for timestamps
      DateTime createdAt = DateTime.now();
      DateTime updatedAt = DateTime.now();
      try {
        if (map['createdAt'] != null) {
          createdAt = DateTime.parse(map['createdAt'].toString());
        }
        if (map['updatedAt'] != null) {
          updatedAt = DateTime.parse(map['updatedAt'].toString());
        }
      } catch (_) {
        // Use current timestamp if parsing fails - not critical
      }
      
      // If no workouts were parsed, this is a problem
      if (workouts.isEmpty) {
        debugPrint('WARNING: No valid workouts parsed from data. This may indicate missing workout data.');
      } else {
        debugPrint('Successfully parsed ${workouts.length} workouts');
        // Debug print to check all the days in the workout plan
        final days = workouts.map((w) => w.day).toList()..sort();
        debugPrint('Workout days: $days');
      }
      
      final parsedPlan = WorkoutPlan(
        id: map['id']?.toString(),
        weekStartDate: weekStartDate, // Not critical for functionality
        workouts: workouts,           // This is what matters most
        createdAt: createdAt,
        updatedAt: updatedAt,
        userId: map['userId']?.toString() ?? '',
        preferredTime: map['preferredTime']?.toString(),
        specialConsiderations: map['specialConsiderations']?.toString(),
        totalWeeklyCalories: map['totalWeeklyCalories'] is int ? 
            map['totalWeeklyCalories'] : 
            (map['totalWeeklyCalories'] != null ? int.tryParse(map['totalWeeklyCalories'].toString()) : null),
        workoutDays: workoutDays,
      );
      
      debugPrint('Successfully created WorkoutPlan with ID: ${parsedPlan.id}');
      
      return parsedPlan;
    } catch (e) {
      debugPrint('Error parsing WorkoutPlan: $e');
      debugPrint('Problematic map: $map');
      // Return a default plan in case of error
      return WorkoutPlan(
        weekStartDate: DateTime.now(),
        workouts: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: '',
      );
    }
  }

  Map<String, dynamic> toMap() {
    final workoutsList = workouts.map((w) => w.toMap()).toList();
    
    final map = {
      'id': id,
      'weekStartDate': weekStartDate.toIso8601String(),
      'workoutPlan': workoutsList,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
    };
    
    // Add optional fields if they exist
    if (preferredTime != null) map['preferredTime'] = preferredTime!;
    if (specialConsiderations != null) map['specialConsiderations'] = specialConsiderations!;
    if (totalWeeklyCalories != null) map['totalWeeklyCalories'] = totalWeeklyCalories!;
    if (workoutDays != null) map['workoutDays'] = workoutDays!;
    
    return map;
  }

  // Get today's workout
  DailyWorkout? getTodaysWorkout() {
    final today = DateTime.now();
    final todayDateStr = DateFormat('yyyy-MM-dd').format(today);
    
    try {
      // First try to match by date string
      try {
        return workouts.firstWhere((workout) => 
          workout.date != null && DateFormat('yyyy-MM-dd').format(workout.date!) == todayDateStr);
      } catch (_) {
        // If that fails, match by day of week
        return workouts.firstWhere((workout) => workout.day == today.weekday);
      }
    } catch (e) {
      // If workout for today not found, return null
      return null;
    }
  }
}

class DailyWorkout {
  final int day;
  final String dayName;
  final DateTime? date;
  final String name;
  final String type;
  final String indoorOutdoor;
  final String duration;
  final List<String> equipmentNeeded;
  final List<Exercise> exercises;
  final String warmup;
  final String cooldown;
  final String notes;
  final String intensity;
  final String? preferredTime;
  final int? caloriesBurned;

  DailyWorkout({
    required this.day,
    required this.dayName,
    this.date,
    required this.name,
    required this.type,
    required this.indoorOutdoor,
    required this.duration,
    required this.equipmentNeeded,
    required this.exercises,
    required this.warmup,
    required this.cooldown,
    required this.notes,
    this.intensity = 'medium',
    this.preferredTime,
    this.caloriesBurned,
  });

  factory DailyWorkout.fromMap(Map<String, dynamic> map) {
    try {
      final List<Exercise> exercises = [];
      
      if (map['exercises'] != null && map['exercises'] is List) {
        for (var exercise in map['exercises']) {
          if (exercise is Map<String, dynamic>) {
            try {
              exercises.add(Exercise.fromMap(exercise));
            } catch (e) {
              debugPrint('Error parsing exercise: $e');
            }
          }
        }
      }
      
      // Parse equipment needed - handle both String and List
      List<String> equipment = [];
      if (map['equipmentNeeded'] is List) {
        equipment = List<String>.from((map['equipmentNeeded'] as List).map((e) => e.toString()));
      } else if (map['equipmentNeeded'] is String) {
        equipment = map['equipmentNeeded'].toString().split(',').map((e) => e.trim()).toList();
      }
      
      // Get day number
      int day = 0;
      if (map['day'] != null) {
        day = map['day'] is int ? map['day'] : int.tryParse(map['day'].toString()) ?? 0;
      }
      
      // Get or derive dayName
      String dayName = '';
      if (map['dayName'] != null) {
        dayName = map['dayName'].toString();
      } else {
        // Map day number to day name if dayName not provided
        final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        if (day >= 1 && day <= 7) {
          dayName = dayNames[day - 1];
        } else {
          dayName = 'Unknown';
        }
      }
      
      // Parse date if available
      DateTime? date;
      if (map['date'] != null) {
        try {
          date = DateTime.parse(map['date'].toString());
        } catch (e) {
          debugPrint('Error parsing date: $e');
        }
      }
      
      // Parse calories burned
      int? caloriesBurned;
      if (map['caloriesBurned'] != null) {
        if (map['caloriesBurned'] is int) {
          caloriesBurned = map['caloriesBurned'];
        } else {
          caloriesBurned = int.tryParse(map['caloriesBurned'].toString());
        }
      }
      
      return DailyWorkout(
        day: day,
        dayName: dayName,
        date: date,
        name: map['name']?.toString() ?? 'Workout',
        type: map['type']?.toString() ?? 'Not specified',
        indoorOutdoor: map['indoorOutdoor']?.toString() ?? 'Not specified',
        duration: map['duration']?.toString() ?? 'Not specified',
        equipmentNeeded: equipment,
        exercises: exercises,
        warmup: map['warmup']?.toString() ?? 'Standard warmup',
        cooldown: map['cooldown']?.toString() ?? 'Standard cooldown',
        notes: map['notes']?.toString() ?? '',
        intensity: map['intensity']?.toString() ?? 'medium',
        preferredTime: map['preferredTime']?.toString(),
        caloriesBurned: caloriesBurned,
      );
    } catch (e) {
      debugPrint('Error parsing DailyWorkout: $e');
      debugPrint('Problematic map: $map');
      // Return a default workout in case of error
      return DailyWorkout(
        day: 0,
        dayName: 'Unknown',
        name: 'Error Workout',
        type: 'Not specified',
        indoorOutdoor: 'Not specified',
        duration: 'Not specified',
        equipmentNeeded: [],
        exercises: [],
        warmup: 'Standard warmup',
        cooldown: 'Standard cooldown',
        notes: 'Error occurred while parsing this workout',
        intensity: 'medium',
      );
    }
  }

  Map<String, dynamic> toMap() {
    final map = {
      'day': day,
      'dayName': dayName,
      'name': name,
      'type': type,
      'indoorOutdoor': indoorOutdoor,
      'duration': duration,
      'equipmentNeeded': equipmentNeeded,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'warmup': warmup,
      'cooldown': cooldown,
      'notes': notes,
      'intensity': intensity,
    };
    
    // Add optional fields if available
    if (date != null) map['date'] = date!.toIso8601String();
    if (preferredTime != null) map['preferredTime'] = preferredTime!;
    if (caloriesBurned != null) map['caloriesBurned'] = caloriesBurned!;
    
    return map;
  }
}

class Exercise {
  final String name;
  final int sets;
  final dynamic reps; // Changed to dynamic to handle both integers and strings like "to failure"
  final int restBetweenSets;
  final String instructions;
  final List<String> targetMuscleGroups;
  double? weight; // Weight in kg or lbs
  bool completed = false; // Track completion status
  final String? modifications; // Added modifications field
  final int? caloriesPerSet; // Added calories per set field

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restBetweenSets,
    required this.instructions,
    required this.targetMuscleGroups,
    this.weight,
    this.completed = false,
    this.modifications,
    this.caloriesPerSet,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    try {
      // Parse target muscle groups - handle both String and List
      List<String> muscleGroups = [];
      if (map['targetMuscleGroups'] is List) {
        muscleGroups = List<String>.from((map['targetMuscleGroups'] as List).map((e) => e.toString()));
      } else if (map['targetMuscleGroups'] is String) {
        muscleGroups = map['targetMuscleGroups'].toString().split(',').map((e) => e.trim()).toList();
      }
      
      // Handle reps that could be a string like "to failure" or a number
      dynamic reps = map['reps'];
      if (reps is String && int.tryParse(reps) != null) {
        reps = int.parse(reps);
      } else if (reps == null) {
        reps = 10; // Default value
      }
      
      // Handle rest between sets that could be a string like "30 seconds" or a number
      int restBetweenSets = 30; // Default value
      if (map['restBetweenSets'] != null) {
        var restValue = map['restBetweenSets'];
        if (restValue is int) {
          restBetweenSets = restValue;
        } else if (restValue is String) {
          // Try to extract a number from the string (e.g., "30 seconds" -> 30)
          var numericPart = RegExp(r'(\d+)').firstMatch(restValue)?.group(1);
          if (numericPart != null) {
            restBetweenSets = int.tryParse(numericPart) ?? 30;
          } else if (restValue.toLowerCase() == 'n/a' || 
                    restValue.toLowerCase() == 'none' || 
                    restValue.isEmpty) {
            restBetweenSets = 0; // No rest between sets
          }
        }
      }
      
      // Parse sets with better error handling
      int sets = 3; // Default value
      if (map['sets'] != null) {
        var setsValue = map['sets'];
        if (setsValue is int) {
          sets = setsValue;
        } else if (setsValue is String) {
          sets = int.tryParse(setsValue) ?? 3;
        }
      }
      
      // Parse calories per set
      int? caloriesPerSet;
      if (map['caloriesPerSet'] != null) {
        caloriesPerSet = map['caloriesPerSet'] is int ? 
            map['caloriesPerSet'] : 
            int.tryParse(map['caloriesPerSet'].toString());
      }
      
      debugPrint('Parsed exercise ${map['name']}: Sets=$sets, Reps=$reps, Rest=$restBetweenSets');
      
      return Exercise(
        name: map['name']?.toString() ?? 'Exercise',
        sets: sets,
        reps: reps,
        restBetweenSets: restBetweenSets,
        instructions: map['instructions']?.toString() ?? '',
        targetMuscleGroups: muscleGroups,
        weight: map['weight'] != null ? (map['weight'] is num ? (map['weight'] as num).toDouble() : double.tryParse(map['weight'].toString())) : null,
        completed: map['completed'] as bool? ?? false,
        modifications: map['modifications']?.toString(),
        caloriesPerSet: caloriesPerSet,
      );
    } catch (e) {
      debugPrint('Error parsing Exercise: $e');
      debugPrint('Problematic exercise map: $map');
      // Return a default exercise in case of error
      return Exercise(
        name: map['name']?.toString() ?? 'Error Exercise',
        sets: 3,
        reps: 10,
        restBetweenSets: 30,
        instructions: 'Error parsing this exercise',
        targetMuscleGroups: [],
        weight: null,
        completed: false,
      );
    }
  }

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'sets': sets,
      'reps': reps,
      'restBetweenSets': restBetweenSets,
      'instructions': instructions,
      'targetMuscleGroups': targetMuscleGroups,
      'weight': weight,
      'completed': completed,
    };
    
    // Add optional fields if available
    if (modifications != null) map['modifications'] = modifications!;
    if (caloriesPerSet != null) map['caloriesPerSet'] = caloriesPerSet!;
    
    return map;
  }

  Exercise copyWith({
    String? name,
    int? sets,
    dynamic reps,
    int? restBetweenSets,
    String? instructions,
    List<String>? targetMuscleGroups,
    double? weight,
    bool? completed,
    String? modifications,
    int? caloriesPerSet,
  }) {
    return Exercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restBetweenSets: restBetweenSets ?? this.restBetweenSets,
      instructions: instructions ?? this.instructions,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      weight: weight ?? this.weight,
      completed: completed ?? this.completed,
      modifications: modifications ?? this.modifications,
      caloriesPerSet: caloriesPerSet ?? this.caloriesPerSet,
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
} 