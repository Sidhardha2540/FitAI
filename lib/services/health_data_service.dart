import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health/health.dart' as health;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health_data.dart' as models;

class HealthDataService {
  static final HealthDataService _instance = HealthDataService._internal();
  factory HealthDataService() => _instance;
  HealthDataService._internal();

  final health.Health _health = health.Health();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;
  bool _hasPermissions = false;

  // Comprehensive list of all available health data types
  static const List<health.HealthDataType> _allDataTypes = [
    // Activity & Movement
    health.HealthDataType.STEPS,
    health.HealthDataType.DISTANCE_WALKING_RUNNING,
    health.HealthDataType.DISTANCE_CYCLING,
    health.HealthDataType.DISTANCE_SWIMMING,
    health.HealthDataType.ACTIVE_ENERGY_BURNED,
    health.HealthDataType.BASAL_ENERGY_BURNED,
    health.HealthDataType.TOTAL_CALORIES_BURNED,
    health.HealthDataType.WORKOUT,
    health.HealthDataType.EXERCISE_TIME,
    health.HealthDataType.FLIGHTS_CLIMBED,
    
    // Heart & Cardiovascular
    health.HealthDataType.HEART_RATE,
    health.HealthDataType.RESTING_HEART_RATE,
    health.HealthDataType.WALKING_HEART_RATE,
    health.HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    health.HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    health.HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    health.HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    health.HealthDataType.BLOOD_GLUCOSE,
    health.HealthDataType.BLOOD_OXYGEN,
    health.HealthDataType.ELECTROCARDIOGRAM,
    health.HealthDataType.HIGH_HEART_RATE_EVENT,
    health.HealthDataType.LOW_HEART_RATE_EVENT,
    health.HealthDataType.IRREGULAR_HEART_RATE_EVENT,
    health.HealthDataType.ATRIAL_FIBRILLATION_BURDEN,
    
    // Body Measurements
    health.HealthDataType.WEIGHT,
    health.HealthDataType.HEIGHT,
    health.HealthDataType.BODY_FAT_PERCENTAGE,
    health.HealthDataType.LEAN_BODY_MASS,
    health.HealthDataType.BODY_MASS_INDEX,
    health.HealthDataType.BODY_TEMPERATURE,
    health.HealthDataType.BODY_WATER_MASS,
    health.HealthDataType.WAIST_CIRCUMFERENCE,
    health.HealthDataType.PERIPHERAL_PERFUSION_INDEX,
    
    // Sleep & Recovery
    health.HealthDataType.SLEEP_ASLEEP,
    health.HealthDataType.SLEEP_AWAKE,
    health.HealthDataType.SLEEP_AWAKE_IN_BED,
    health.HealthDataType.SLEEP_DEEP,
    health.HealthDataType.SLEEP_IN_BED,
    health.HealthDataType.SLEEP_LIGHT,
    health.HealthDataType.SLEEP_OUT_OF_BED,
    health.HealthDataType.SLEEP_REM,
    health.HealthDataType.SLEEP_SESSION,
    health.HealthDataType.SLEEP_UNKNOWN,
    health.HealthDataType.RESPIRATORY_RATE,
    
    // Nutrition & Hydration
    health.HealthDataType.NUTRITION,
    health.HealthDataType.WATER,
    
    // Women's Health
    health.HealthDataType.MENSTRUATION_FLOW,
    
    // Additional Metrics
    health.HealthDataType.MINDFULNESS,
    health.HealthDataType.UV_INDEX,
    health.HealthDataType.ELECTRODERMAL_ACTIVITY,
    health.HealthDataType.INSULIN_DELIVERY,
    health.HealthDataType.AUDIOGRAM,
    
    // Environmental (Apple Watch Ultra)
    health.HealthDataType.WATER_TEMPERATURE,
    health.HealthDataType.UNDERWATER_DEPTH,
    
    // Headache tracking
    health.HealthDataType.HEADACHE_NOT_PRESENT,
    health.HealthDataType.HEADACHE_MILD,
    health.HealthDataType.HEADACHE_MODERATE,
    health.HealthDataType.HEADACHE_SEVERE,
    health.HealthDataType.HEADACHE_UNSPECIFIED,
  ];

  // Essential data types for basic health tracking
  static const List<health.HealthDataType> _essentialDataTypes = [
    health.HealthDataType.STEPS,
    health.HealthDataType.DISTANCE_WALKING_RUNNING,
    health.HealthDataType.ACTIVE_ENERGY_BURNED,
    health.HealthDataType.TOTAL_CALORIES_BURNED,
    health.HealthDataType.HEART_RATE,
    health.HealthDataType.RESTING_HEART_RATE,
    health.HealthDataType.WEIGHT,
    health.HealthDataType.HEIGHT,
    health.HealthDataType.BODY_FAT_PERCENTAGE,
    health.HealthDataType.SLEEP_SESSION,
    health.HealthDataType.SLEEP_ASLEEP,
    health.HealthDataType.SLEEP_DEEP,
    health.HealthDataType.SLEEP_LIGHT,
    health.HealthDataType.SLEEP_REM,
    health.HealthDataType.WATER,
    health.HealthDataType.WORKOUT,
    health.HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    health.HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    health.HealthDataType.BLOOD_OXYGEN,
    health.HealthDataType.RESPIRATORY_RATE,
    health.HealthDataType.NUTRITION,
  ];

  /// Initialize Health Connect and configure permissions
  Future<bool> initializeHealthData() async {
    try {
      debugPrint('Initializing Health Connect...');
      
      // Configure the Health plugin
      await _health.configure();
      
      // Check if Health Connect is available
      final isAvailable = await _health.hasPermissions(_essentialDataTypes) != null;
      if (!isAvailable) {
        debugPrint('Health Connect is not available on this device');
        return false;
      }

      // Request activity recognition permission first (required for steps)
      if (Platform.isAndroid) {
        final activityPermission = await Permission.activityRecognition.request();
        final locationPermission = await Permission.location.request();
        debugPrint('Activity recognition permission: $activityPermission');
        debugPrint('Location permission: $locationPermission');
      }

      // Request health data permissions
      final permissions = _essentialDataTypes.map((type) => health.HealthDataAccess.READ_WRITE).toList();
      final hasPermissions = await _health.hasPermissions(_essentialDataTypes, permissions: permissions);
      
      if (hasPermissions != true) {
        debugPrint('Requesting health data permissions...');
        final granted = await _health.requestAuthorization(_essentialDataTypes, permissions: permissions);
        _hasPermissions = granted;
        debugPrint('Health permissions granted: $granted');
      } else {
        _hasPermissions = true;
        debugPrint('Health permissions already granted');
      }

      _isInitialized = true;
      debugPrint('Health Connect initialization complete');
      return _hasPermissions;
    } catch (e) {
      debugPrint('Error initializing Health Connect: $e');
      return false;
    }
  }

  /// Check if health data is available on this device
  Future<bool> isHealthDataAvailable() async {
    try {
      // Test by trying to get permissions
      final hasPermissions = await _health.hasPermissions([health.HealthDataType.STEPS]);
      return hasPermissions != null;
    } catch (e) {
      debugPrint('Error checking health data availability: $e');
      return false;
    }
  }

  /// Get daily health summary with simplified processing
  Future<models.DailyHealthSummary?> getDailyHealthSummary(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      // Get basic health data
      final stepsData = await _health.getHealthDataFromTypes(
        types: [health.HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: endOfDay,
      );
      
      int steps = 0;
      if (stepsData.isNotEmpty) {
        steps = stepsData.fold<int>(0, (sum, point) {
          if (point.value is health.NumericHealthValue) {
            return sum + (point.value as health.NumericHealthValue).numericValue.toInt();
          }
          return sum;
        });
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final summary = models.DailyHealthSummary(
        id: '${userId}_${date.toIso8601String().split('T')[0]}',
        userId: userId,
        date: date,
        steps: steps,
        distance: 0.0,
        caloriesBurned: 0.0,
        averageHeartRate: null,
        restingHeartRate: null,
        sleepHours: null,
        workoutMinutes: null,
        weight: null,
        moveMinutes: 0,
        heartPoints: 0,
        hydration: 0.0,
        bloodPressureSystolic: null,
        bloodPressureDiastolic: null,
        bloodOxygen: null,
        additionalMetrics: {
          'dataTypes': ['STEPS'],
          'totalDataPoints': stepsData.length,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _saveDailyHealthSummary(summary);
      
      debugPrint('Generated basic daily health summary');
      return summary;
    } catch (e) {
      debugPrint('Error generating daily health summary: $e');
      return null;
    }
  }

  /// Get weekly health summaries
  Future<List<models.DailyHealthSummary>> getWeeklyHealthSummaries(DateTime startDate) async {
    final summaries = <models.DailyHealthSummary>[];
    
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final summary = await getDailyHealthSummary(date);
      if (summary != null) {
        summaries.add(summary);
      }
    }
    
    return summaries;
  }

  /// Get comprehensive health data for a specific date range
  Future<List<health.HealthDataPoint>> getHealthData({
    required health.HealthDataType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      await initializeHealthData();
    }

    try {
      final data = await _health.getHealthDataFromTypes(
        types: [type],
        startTime: startDate,
        endTime: endDate,
      );
      
      debugPrint('Retrieved ${data.length} data points for ${type.name}');
      return data;
    } catch (e) {
      debugPrint('Error getting health data for ${type.name}: $e');
      return [];
    }
  }

  /// Get total steps in a time interval
  Future<int?> getTotalStepsInInterval(DateTime startTime, DateTime endTime) async {
    try {
      return await _health.getTotalStepsInInterval(startTime, endTime);
    } catch (e) {
      debugPrint('Error getting total steps: $e');
      return null;
    }
  }

  /// Save daily health summary to Firestore
  Future<void> _saveDailyHealthSummary(models.DailyHealthSummary summary) async {
    try {
      await _firestore
          .collection('users')
          .doc(summary.userId)
          .collection('dailyHealthSummaries')
          .doc(summary.id)
          .set(summary.toMap());
    } catch (e) {
      debugPrint('Error saving daily health summary: $e');
    }
  }
} 