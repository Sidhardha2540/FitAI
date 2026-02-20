import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String? id;
  final String? userId;
  final String? email;
  final String? fullName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? age;
  final String? gender;
  final String? heightCm;
  final String? weightKg;
  final String? fitnessLevel;
  final String? weeklyExerciseDays;
  final String? previousProgramExperience;
  final String? primaryFitnessGoal;
  final String? specificTargets;
  final String? motivation;
  final List<String>? workoutPreferences;
  final String? indoorOutdoorPreference;
  final String? workoutDaysPerWeek;
  final String? workoutMinutesPerSession;
  final String? equipmentAccess;
  final List<String>? dietaryRestrictions;
  final String? eatingHabits;
  final String? favoriteFoods;
  final String? avoidedFoods;
  final List<String>? medicalConditions;
  final String? medications;
  final String? fitnessConcerns;
  final String? dailyActivityLevel;
  final String? sleepHours;
  final String? stressLevel;
  final String? progressPhotoUrl;
  final bool? aiSuggestionsEnabled;
  final String? additionalNotes;

  UserProfile({
    this.id,
    this.userId,
    this.email,
    this.fullName,
    this.createdAt,
    this.updatedAt,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.fitnessLevel,
    this.weeklyExerciseDays,
    this.previousProgramExperience,
    this.primaryFitnessGoal,
    this.specificTargets,
    this.motivation,
    this.workoutPreferences,
    this.indoorOutdoorPreference,
    this.workoutDaysPerWeek,
    this.workoutMinutesPerSession,
    this.equipmentAccess,
    this.dietaryRestrictions,
    this.eatingHabits,
    this.favoriteFoods,
    this.avoidedFoods,
    this.medicalConditions,
    this.medications,
    this.fitnessConcerns,
    this.dailyActivityLevel,
    this.sleepHours,
    this.stressLevel,
    this.progressPhotoUrl,
    this.aiSuggestionsEnabled,
    this.additionalNotes,
  });

  UserProfile copyWith({
    String? id,
    String? userId,
    String? email,
    String? fullName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? age,
    String? gender,
    String? heightCm,
    String? weightKg,
    String? fitnessLevel,
    String? weeklyExerciseDays,
    String? previousProgramExperience,
    String? primaryFitnessGoal,
    String? specificTargets,
    String? motivation,
    List<String>? workoutPreferences,
    String? indoorOutdoorPreference,
    String? workoutDaysPerWeek,
    String? workoutMinutesPerSession,
    String? equipmentAccess,
    List<String>? dietaryRestrictions,
    String? eatingHabits,
    String? favoriteFoods,
    String? avoidedFoods,
    List<String>? medicalConditions,
    String? medications,
    String? fitnessConcerns,
    String? dailyActivityLevel,
    String? sleepHours,
    String? stressLevel,
    String? progressPhotoUrl,
    bool? aiSuggestionsEnabled,
    String? additionalNotes,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      weeklyExerciseDays: weeklyExerciseDays ?? this.weeklyExerciseDays,
      previousProgramExperience: previousProgramExperience ?? this.previousProgramExperience,
      primaryFitnessGoal: primaryFitnessGoal ?? this.primaryFitnessGoal,
      specificTargets: specificTargets ?? this.specificTargets,
      motivation: motivation ?? this.motivation,
      workoutPreferences: workoutPreferences ?? this.workoutPreferences,
      indoorOutdoorPreference: indoorOutdoorPreference ?? this.indoorOutdoorPreference,
      workoutDaysPerWeek: workoutDaysPerWeek ?? this.workoutDaysPerWeek,
      workoutMinutesPerSession: workoutMinutesPerSession ?? this.workoutMinutesPerSession,
      equipmentAccess: equipmentAccess ?? this.equipmentAccess,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      eatingHabits: eatingHabits ?? this.eatingHabits,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      avoidedFoods: avoidedFoods ?? this.avoidedFoods,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      medications: medications ?? this.medications,
      fitnessConcerns: fitnessConcerns ?? this.fitnessConcerns,
      dailyActivityLevel: dailyActivityLevel ?? this.dailyActivityLevel,
      sleepHours: sleepHours ?? this.sleepHours,
      stressLevel: stressLevel ?? this.stressLevel,
      progressPhotoUrl: progressPhotoUrl ?? this.progressPhotoUrl,
      aiSuggestionsEnabled: aiSuggestionsEnabled ?? this.aiSuggestionsEnabled,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'fitness_level': fitnessLevel,
      'weekly_exercise_days': weeklyExerciseDays,
      'previous_program_experience': previousProgramExperience,
      'primary_fitness_goal': primaryFitnessGoal,
      'specific_targets': specificTargets,
      'motivation': motivation,
      'workout_preferences': workoutPreferences,
      'indoor_outdoor_preference': indoorOutdoorPreference,
      'workout_days_per_week': workoutDaysPerWeek,
      'workout_minutes_per_session': workoutMinutesPerSession,
      'equipment_access': equipmentAccess,
      'dietary_restrictions': dietaryRestrictions,
      'eating_habits': eatingHabits,
      'favorite_foods': favoriteFoods,
      'avoided_foods': avoidedFoods,
      'medical_conditions': medicalConditions,
      'medications': medications,
      'fitness_concerns': fitnessConcerns,
      'daily_activity_level': dailyActivityLevel,
      'sleep_hours': sleepHours,
      'stress_level': stressLevel,
      'progress_photo_url': progressPhotoUrl,
      'ai_suggestions_enabled': aiSuggestionsEnabled,
      'additional_notes': additionalNotes,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    try {
      return UserProfile(
        id: map['id'],
        userId: map['user_id'],
        email: map['email'],
        fullName: map['full_name'],
        createdAt: map['created_at'] != null ? 
          (map['created_at'] is Timestamp ? 
            (map['created_at'] as Timestamp).toDate() : 
            DateTime.parse(map['created_at'].toString())) : null,
        updatedAt: map['updated_at'] != null ? 
          (map['updated_at'] is Timestamp ? 
            (map['updated_at'] as Timestamp).toDate() : 
            DateTime.parse(map['updated_at'].toString())) : null,
        age: map['age'],
        gender: map['gender'],
        heightCm: map['height_cm'],
        weightKg: map['weight_kg'],
        fitnessLevel: map['fitness_level'],
        weeklyExerciseDays: map['weekly_exercise_days'],
        previousProgramExperience: map['previous_program_experience'],
        primaryFitnessGoal: map['primary_fitness_goal'],
        specificTargets: map['specific_targets'],
        motivation: map['motivation'],
        workoutPreferences: _handleListData(map['workout_preferences']),
        indoorOutdoorPreference: map['indoor_outdoor_preference'],
        workoutDaysPerWeek: map['workout_days_per_week'],
        workoutMinutesPerSession: map['workout_minutes_per_session'],
        equipmentAccess: map['equipment_access'],
        dietaryRestrictions: _handleListData(map['dietary_restrictions']),
        eatingHabits: map['eating_habits'],
        favoriteFoods: map['favorite_foods'],
        avoidedFoods: map['avoided_foods'],
        medicalConditions: _handleListData(map['medical_conditions']),
        medications: map['medications'],
        fitnessConcerns: map['fitness_concerns'],
        dailyActivityLevel: map['daily_activity_level'],
        sleepHours: map['sleep_hours'],
        stressLevel: map['stress_level'],
        progressPhotoUrl: map['progress_photo_url'],
        aiSuggestionsEnabled: map['ai_suggestions_enabled'],
        additionalNotes: map['additional_notes'],
      );
    } catch (e) {
      debugPrint('Error creating UserProfile from map: $e');
      return UserProfile(); // Return an empty profile instead of null
    }
  }

  // Helper method to safely handle list data
  static List<String> _handleListData(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    return [];
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));

  @override
  String toString() {
    return 'UserProfile(id: $id, userId: $userId, email: $email, fullName: $fullName, age: $age, gender: $gender)';
  }
} 