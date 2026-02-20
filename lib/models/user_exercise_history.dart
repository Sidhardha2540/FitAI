import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_log.dart';

class UserExerciseHistory {
  final String exerciseId;
  final String exerciseName;
  final PersonalRecord? allTimeRecord;
  final List<ExercisePerformanceSummary> recentPerformance;
  final ProgressTrend progressTrend;
  final DateTime? lastPerformed;
  final int totalSessions;
  final double averageWeight;
  final double averageReps;

  UserExerciseHistory({
    required this.exerciseId,
    required this.exerciseName,
    this.allTimeRecord,
    required this.recentPerformance,
    this.progressTrend = ProgressTrend.stable,
    this.lastPerformed,
    this.totalSessions = 0,
    this.averageWeight = 0.0,
    this.averageReps = 0.0,
  });

  factory UserExerciseHistory.fromMap(Map<String, dynamic> map) {
    final recentPerformanceList = map['recentPerformance'] as List<dynamic>? ?? [];
    List<ExercisePerformanceSummary> recentPerformance = [];
    
    for (var performance in recentPerformanceList) {
      if (performance is Map<String, dynamic>) {
        recentPerformance.add(ExercisePerformanceSummary.fromMap(performance));
      }
    }

    return UserExerciseHistory(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? 'Unknown Exercise',
      allTimeRecord: map['allTimeRecord'] != null 
        ? PersonalRecord.fromMap(map['allTimeRecord'])
        : null,
      recentPerformance: recentPerformance,
      progressTrend: ProgressTrend.fromString(map['progressTrend'] ?? 'stable'),
      lastPerformed: map['lastPerformed'] is Timestamp 
        ? (map['lastPerformed'] as Timestamp).toDate()
        : (map['lastPerformed'] != null 
          ? DateTime.parse(map['lastPerformed'].toString())
          : null),
      totalSessions: map['totalSessions']?.toInt() ?? 0,
      averageWeight: map['averageWeight']?.toDouble() ?? 0.0,
      averageReps: map['averageReps']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'allTimeRecord': allTimeRecord?.toMap(),
      'recentPerformance': recentPerformance.map((p) => p.toMap()).toList(),
      'progressTrend': progressTrend.toString(),
      'lastPerformed': lastPerformed != null 
        ? Timestamp.fromDate(lastPerformed!)
        : null,
      'totalSessions': totalSessions,
      'averageWeight': averageWeight,
      'averageReps': averageReps,
    };
  }
}

class ExercisePerformanceSummary {
  final DateTime date;
  final double? maxWeight;
  final int totalSets;
  final int completedSets;
  final double totalVolume;

  ExercisePerformanceSummary({
    required this.date,
    this.maxWeight,
    required this.totalSets,
    required this.completedSets,
    required this.totalVolume,
  });

  factory ExercisePerformanceSummary.fromMap(Map<String, dynamic> map) {
    return ExercisePerformanceSummary(
      date: map['date'] is Timestamp 
        ? (map['date'] as Timestamp).toDate()
        : DateTime.parse(map['date'].toString()),
      maxWeight: map['maxWeight']?.toDouble(),
      totalSets: map['totalSets']?.toInt() ?? 0,
      completedSets: map['completedSets']?.toInt() ?? 0,
      totalVolume: map['totalVolume']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'maxWeight': maxWeight,
      'totalSets': totalSets,
      'completedSets': completedSets,
      'totalVolume': totalVolume,
    };
  }
}

enum ProgressTrend {
  improving,
  stable,
  declining;

  static ProgressTrend fromString(String value) {
    switch (value) {
      case 'improving': return ProgressTrend.improving;
      case 'stable': return ProgressTrend.stable;
      case 'declining': return ProgressTrend.declining;
      default: return ProgressTrend.stable;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ProgressTrend.improving: return 'improving';
      case ProgressTrend.stable: return 'stable';
      case ProgressTrend.declining: return 'declining';
    }
  }
} 