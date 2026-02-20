import 'package:cloud_firestore/cloud_firestore.dart';

// Health data types enum
enum HealthDataType {
  steps,
  distance,
  calories,
  heartRate,
  weight,
  height,
  bodyFat,
  sleep,
  workout,
  activeEnergyBurned,
  basalEnergyBurned,
  bloodPressure,
  bloodOxygen,
  restingHeartRate,
}

// Health data point model
class HealthDataPoint {
  final String id;
  final String userId;
  final HealthDataType type;
  final double value;
  final String unit;
  final DateTime dateTime;
  final DateTime? endDateTime; // For duration-based data like sleep
  final Map<String, dynamic>? metadata;
  final String source; // 'apple_health', 'google_fit', 'manual', etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthDataPoint({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.dateTime,
    this.endDateTime,
    this.metadata,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthDataPoint.fromMap(Map<String, dynamic> map) {
    return HealthDataPoint(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: HealthDataType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => HealthDataType.steps,
      ),
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      dateTime: map['dateTime'] is Timestamp
          ? (map['dateTime'] as Timestamp).toDate()
          : DateTime.parse(map['dateTime'].toString()),
      endDateTime: map['endDateTime'] != null
          ? (map['endDateTime'] is Timestamp
              ? (map['endDateTime'] as Timestamp).toDate()
              : DateTime.parse(map['endDateTime'].toString()))
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      source: map['source'] ?? 'unknown',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'].toString()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'value': value,
      'unit': unit,
      'dateTime': Timestamp.fromDate(dateTime),
      'endDateTime': endDateTime != null ? Timestamp.fromDate(endDateTime!) : null,
      'metadata': metadata,
      'source': source,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  HealthDataPoint copyWith({
    String? id,
    String? userId,
    HealthDataType? type,
    double? value,
    String? unit,
    DateTime? dateTime,
    DateTime? endDateTime,
    Map<String, dynamic>? metadata,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthDataPoint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      dateTime: dateTime ?? this.dateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      metadata: metadata ?? this.metadata,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Daily health summary model
class DailyHealthSummary {
  final String id;
  final String userId;
  final DateTime date;
  final int steps;
  final double distance; // in km
  final double caloriesBurned;
  final double? averageHeartRate;
  final double? restingHeartRate;
  final double? sleepHours;
  final int? workoutMinutes;
  final double? weight; // in kg
  final int moveMinutes; // Active minutes from Health Connect
  final int heartPoints; // Intensity points from Health Connect
  final double hydration; // Water intake in ml
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;
  final double? bloodOxygen; // SpO2 percentage
  final Map<String, dynamic>? additionalMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyHealthSummary({
    required this.id,
    required this.userId,
    required this.date,
    required this.steps,
    required this.distance,
    required this.caloriesBurned,
    this.averageHeartRate,
    this.restingHeartRate,
    this.sleepHours,
    this.workoutMinutes,
    this.weight,
    this.moveMinutes = 0,
    this.heartPoints = 0,
    this.hydration = 0.0,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.bloodOxygen,
    this.additionalMetrics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyHealthSummary.fromMap(Map<String, dynamic> map) {
    return DailyHealthSummary(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.parse(map['date'].toString()),
      steps: map['steps']?.toInt() ?? 0,
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      averageHeartRate: (map['averageHeartRate'] as num?)?.toDouble(),
      restingHeartRate: (map['restingHeartRate'] as num?)?.toDouble(),
      sleepHours: (map['sleepHours'] as num?)?.toDouble(),
      workoutMinutes: map['workoutMinutes']?.toInt(),
      weight: (map['weight'] as num?)?.toDouble(),
      moveMinutes: map['moveMinutes']?.toInt() ?? 0,
      heartPoints: map['heartPoints']?.toInt() ?? 0,
      hydration: (map['hydration'] as num?)?.toDouble() ?? 0.0,
      bloodPressureSystolic: (map['bloodPressureSystolic'] as num?)?.toDouble(),
      bloodPressureDiastolic: (map['bloodPressureDiastolic'] as num?)?.toDouble(),
      bloodOxygen: (map['bloodOxygen'] as num?)?.toDouble(),
      additionalMetrics: map['additionalMetrics'] as Map<String, dynamic>?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'].toString()),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'steps': steps,
      'distance': distance,
      'caloriesBurned': caloriesBurned,
      'averageHeartRate': averageHeartRate,
      'restingHeartRate': restingHeartRate,
      'sleepHours': sleepHours,
      'workoutMinutes': workoutMinutes,
      'weight': weight,
      'moveMinutes': moveMinutes,
      'heartPoints': heartPoints,
      'hydration': hydration,
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'bloodOxygen': bloodOxygen,
      'additionalMetrics': additionalMetrics,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// Health sync status model
class HealthSyncStatus {
  final String userId;
  final DateTime? lastSyncTime;
  final Map<HealthDataType, DateTime> lastSyncByType;
  final bool isEnabled;
  final List<HealthDataType> enabledTypes;
  final String? errorMessage;
  final DateTime updatedAt;

  HealthSyncStatus({
    required this.userId,
    this.lastSyncTime,
    required this.lastSyncByType,
    required this.isEnabled,
    required this.enabledTypes,
    this.errorMessage,
    required this.updatedAt,
  });

  factory HealthSyncStatus.fromMap(Map<String, dynamic> map) {
    final lastSyncByTypeMap = map['lastSyncByType'] as Map<String, dynamic>? ?? {};
    final lastSyncByType = <HealthDataType, DateTime>{};
    
    for (final entry in lastSyncByTypeMap.entries) {
      try {
        final type = HealthDataType.values.firstWhere(
          (e) => e.toString() == entry.key,
        );
        final dateTime = entry.value is Timestamp
            ? (entry.value as Timestamp).toDate()
            : DateTime.parse(entry.value.toString());
        lastSyncByType[type] = dateTime;
      } catch (e) {
        // Skip invalid entries
      }
    }

    final enabledTypesStrings = (map['enabledTypes'] as List<dynamic>?)?.cast<String>() ?? [];
    final enabledTypes = enabledTypesStrings
        .map((typeString) {
          try {
            return HealthDataType.values.firstWhere(
              (e) => e.toString() == typeString,
            );
          } catch (e) {
            return null;
          }
        })
        .where((type) => type != null)
        .cast<HealthDataType>()
        .toList();

    return HealthSyncStatus(
      userId: map['userId'] ?? '',
      lastSyncTime: map['lastSyncTime'] != null
          ? (map['lastSyncTime'] is Timestamp
              ? (map['lastSyncTime'] as Timestamp).toDate()
              : DateTime.parse(map['lastSyncTime'].toString()))
          : null,
      lastSyncByType: lastSyncByType,
      isEnabled: map['isEnabled'] ?? false,
      enabledTypes: enabledTypes,
      errorMessage: map['errorMessage'],
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    final lastSyncByTypeMap = <String, dynamic>{};
    for (final entry in lastSyncByType.entries) {
      lastSyncByTypeMap[entry.key.toString()] = Timestamp.fromDate(entry.value);
    }

    return {
      'userId': userId,
      'lastSyncTime': lastSyncTime != null ? Timestamp.fromDate(lastSyncTime!) : null,
      'lastSyncByType': lastSyncByTypeMap,
      'isEnabled': isEnabled,
      'enabledTypes': enabledTypes.map((type) => type.toString()).toList(),
      'errorMessage': errorMessage,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
} 