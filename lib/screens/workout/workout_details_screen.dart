import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/workout_plan.dart';
import '../../models/exercise_log.dart';
import '../../models/workout_session.dart';
import '../../services/exercise_log_service.dart';
import '../../services/workout_session_service.dart';
import '../../services/user_exercise_history_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final DailyWorkout workout;
  final DateTime? workoutDate; // Add optional workout date

  const WorkoutDetailsScreen({
    super.key,
    required this.workout,
    this.workoutDate, // Optional parameter for workout date
  });

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  final Map<String, List<SetData>> _exerciseSets = {};
  final ExerciseLogService _exerciseLogService = ExerciseLogService();
  final WorkoutSessionService _sessionService = WorkoutSessionService();
  final UserExerciseHistoryService _historyService = UserExerciseHistoryService();
  
  bool _isLoading = false;
  String? _error;
  WorkoutSession? _currentSession;
  final Map<String, List<ExerciseLogEntry>> _exerciseHistories = {};

  // Check if this workout is for today
  bool get _isWorkoutForToday {
    if (widget.workoutDate == null) return true; // Default to true if no date specified
    final today = DateTime.now();
    final workoutDate = widget.workoutDate!;
    return DateUtils.isSameDay(today, workoutDate);
  }

  @override
  void initState() {
    super.initState();
    _initializeExerciseSets();
    _loadTodaysSession();
    _loadExerciseHistories();
  }

  void _initializeExerciseSets() {
    // Initialize sets for each exercise
    for (final exercise in widget.workout.exercises) {
      final exerciseId = _exerciseLogService.generateExerciseId(exercise.name);
      final sets = <SetData>[];
      
      for (int i = 0; i < exercise.sets; i++) {
        sets.add(SetData(
          setNumber: i + 1,
          reps: exercise.reps.toString(),
          weight: exercise.weight,
          isCompleted: false,
        ));
      }
      
      _exerciseSets[exerciseId] = sets;
    }
  }

  Future<void> _loadTodaysSession() async {
    try {
      // Simplified approach - don't load complex session data that requires indexes
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading today\'s session: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExerciseHistories() async {
    try {
      print('=== LOADING EXERCISE HISTORIES (SIMPLE VERSION) ===');
      
      // Use the existing service but get all logs and group them by exercise name  
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('No authenticated user found');
        return;
      }

      // Get all recent exercise logs and group by exercise name
      final allLogs = await _exerciseLogService.getRecentExerciseLogs(limit: 100);
      print('Found ${allLogs.length} total exercise logs');

      // Group logs by exercise name
      final Map<String, List<ExerciseLogEntry>> logsByExerciseName = {};
      
      for (final logEntry in allLogs) {
        final exerciseName = logEntry.exerciseName;
        if (!logsByExerciseName.containsKey(exerciseName)) {
          logsByExerciseName[exerciseName] = [];
        }
        logsByExerciseName[exerciseName]!.add(logEntry);
        print('Added log for exercise: $exerciseName');
      }

      // Sort each exercise's logs by date (newest first)
      logsByExerciseName.forEach((exerciseName, logs) {
        logs.sort((a, b) => b.date.compareTo(a.date));
        print('Exercise "$exerciseName" has ${logs.length} logs');
      });

      // Update the exercise histories using exercise names directly
      if (mounted) {
        setState(() {
          _exerciseHistories.clear();
          for (final exercise in widget.workout.exercises) {
            final logs = logsByExerciseName[exercise.name] ?? [];
            _exerciseHistories[exercise.name] = logs; // Use exercise name as key
            print('Set history for "${exercise.name}": ${logs.length} entries');
          }
        });
      }
      
      print('=== EXERCISE HISTORIES LOADED SUCCESSFULLY ===');
      print('Total histories loaded: ${_exerciseHistories.length}');
      
    } catch (e) {
      print('Error loading exercise histories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.workout.name,
          style: textTheme.titleLarge,
        ),
        actions: [
          if (_currentSession != null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => _showWorkoutHistory(context),
              tooltip: 'View workout history',
            ),
          ],
      ),
      body: _isLoading
        ? Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [
                LoadingAnimationWidget.fourRotatingDots(
                            color: colorScheme.primary,
                  size: 50,
                          ),
                const SizedBox(height: 16),
                          Text(
                  'Loading workout details...',
                              style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout info card
                _buildWorkoutInfoCard(context),
              const SizedBox(height: 24),
              
                // Current session status
                if (_currentSession != null) ...[
                  _buildSessionStatusCard(context),
                  const SizedBox(height: 24),
                ],
                
                // Exercises section
                Text(
                  'Exercises',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.workout.exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = widget.workout.exercises[index];
                    return _buildExerciseCard(context, exercise, index);
                  },
                ),
                
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => _startOrCompleteWorkout(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: Icon(_currentSession?.completionStatus == WorkoutCompletionStatus.completed
            ? Icons.update
            : (_currentSession != null ? Icons.check_circle : Icons.play_arrow)),
        label: Text(_currentSession?.completionStatus == WorkoutCompletionStatus.completed
            ? 'Update'
            : (_currentSession != null ? 'Complete Workout' : 'Start Workout')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildWorkoutInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
                  elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                            children: [
                              Icon(
                  _getWorkoutTypeIcon(widget.workout.type),
                                color: colorScheme.primary,
                              ),
                const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                    widget.workout.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(widget.workout.type),
                  backgroundColor: colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(context, Icons.timer, widget.workout.duration, 'Duration'),
                _buildInfoItem(context, Icons.fitness_center, 
                    '${widget.workout.exercises.length}', 'Exercises'),
                _buildInfoItem(context, Icons.whatshot, widget.workout.intensity, 'Intensity'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStatusCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _currentSession!.completionStatus == WorkoutCompletionStatus.completed
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _currentSession!.completionStatus == WorkoutCompletionStatus.completed
                    ? Icons.check_circle
                    : Icons.fitness_center,
                color: _currentSession!.completionStatus == WorkoutCompletionStatus.completed
                    ? colorScheme.primary
                    : colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                _currentSession!.completionStatus == WorkoutCompletionStatus.completed
                    ? 'Workout Completed'
                    : 'Workout In Progress',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
              ),
              const SizedBox(height: 8),
          Text(
            _currentSession!.completionStatus == WorkoutCompletionStatus.completed
                ? 'Great job! Your workout has been logged.'
                : 'Continue logging your exercises below.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final exerciseId = _exerciseLogService.generateExerciseId(exercise.name);
    final sets = _exerciseSets[exerciseId] ?? [];
    final history = _exerciseHistories[exercise.name] ?? [];

    // Debug logging
    print('=== BUILDING EXERCISE CARD ===');
    print('Exercise: ${exercise.name}');
    print('Exercise ID: $exerciseId');
    print('History entries: ${history.length}');
    if (history.isNotEmpty) {
      print('Last performance would be: ${_getLastPerformance(history)}');
    }
    print('================================');

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
            // Exercise header
                          Row(
                            children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                                child: Text(
                    '${index + 1}',
                    style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                const SizedBox(width: 12),
                              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                                  exercise.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                      ),
                      Text(
                        '${exercise.sets} sets × ${exercise.reps} reps',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                ),
                if (history.isNotEmpty)
                  Chip(
                    label: Text('Last: ${_getLastPerformance(history)}'),
                    backgroundColor: colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontSize: 12,
                    ),
                              ),
                            ],
                          ),
                          
                            const SizedBox(height: 16),
            
            // Exercise instructions
                          if (exercise.instructions.isNotEmpty) ...[
                            Text(
                              'Instructions',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise.instructions,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
                            const SizedBox(height: 16),
            ],

            // Sets tracking
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                            Text(
                      'Sets',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                      '${sets.where((s) => s.isCompleted).length}/${sets.length} completed',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                            ),
                    ),
                        ],
              ),
              
                // Show restriction message if not today's workout
                if (!_isWorkoutForToday) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Exercise logging is only available for today\'s workout',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                  ),
                ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: sets.isEmpty ? 0 : sets.where((s) => s.isCompleted).length / sets.length,
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    minHeight: 8,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Individual sets
                ...sets.asMap().entries.map((entry) {
                  final setIndex = entry.key;
                  final setData = entry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Set number
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: setData.isCompleted 
                                ? colorScheme.primary 
                                : colorScheme.outline.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                    child: Text(
                              '${setIndex + 1}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: setData.isCompleted 
                                    ? colorScheme.onPrimary 
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),
                        
                        const SizedBox(width: 12),
              
                        // Reps input
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: setData.reps,
                            enabled: _isWorkoutForToday, // Disable if not today
                            decoration: InputDecoration(
                              labelText: 'Reps',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _isWorkoutForToday ? (value) {
                              setData.reps = value;
                            } : null,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Weight input
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: setData.weight?.toString() ?? '',
                            enabled: _isWorkoutForToday, // Disable if not today
                            decoration: InputDecoration(
                              labelText: 'Weight (kg)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _isWorkoutForToday ? (value) {
                              setData.weight = double.tryParse(value);
                            } : null,
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Complete button
                        IconButton(
                          onPressed: _isWorkoutForToday ? () => _toggleSetCompletion(exerciseId, setIndex) : null,
                          icon: Icon(
                            setData.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: _isWorkoutForToday 
                                ? (setData.isCompleted ? colorScheme.primary : colorScheme.outline)
                                : colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getBestWeight(List<ExerciseLogEntry> history) {
    if (history.isEmpty) return '0';
    
    double maxWeight = 0;
    for (final entry in history) {
      for (final set in entry.sets) {
        if (set.weight != null && set.weight! > maxWeight) {
          maxWeight = set.weight!;
        }
      }
    }
    return maxWeight.toStringAsFixed(1);
  }

  String _getLastPerformance(List<ExerciseLogEntry> history) {
    if (history.isEmpty) return 'N/A';
    
    final entry = history.first; // Most recent entry
    final completedSets = entry.sets.where((set) => set.isCompleted).toList();
    
    if (completedSets.isNotEmpty) {
      final lastSet = completedSets.last;
      if (lastSet.weight != null && lastSet.weight! > 0) {
        return '${lastSet.weight}kg × ${lastSet.reps}';
      } else {
        return '${lastSet.reps} reps';
      }
    }
    
    return 'N/A';
  }

  void _toggleSetCompletion(String exerciseId, int setIndex) async {
    // Only allow toggling for today's workout
    if (!_isWorkoutForToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Exercise logging is only available for today\'s workout'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      final sets = _exerciseSets[exerciseId];
      if (sets != null && setIndex < sets.length) {
        final setData = sets[setIndex];
        setData.isCompleted = !setData.isCompleted;
        if (setData.isCompleted) {
          setData.completedAt = DateTime.now();
          // Haptic feedback for completion
          HapticFeedback.lightImpact();
        } else {
          setData.completedAt = null;
        }
      }
    });

    // Auto-save exercise logs when sets are completed
    await _autoSaveExerciseLogs(exerciseId);
  }

  // Auto-save exercise logs when sets are updated
  Future<void> _autoSaveExerciseLogs(String exerciseId) async {
    // Only auto-save for today's workout
    if (!_isWorkoutForToday) {
      return;
    }

    try {
      // Find the exercise
      final exercise = widget.workout.exercises.firstWhere(
        (ex) => _exerciseLogService.generateExerciseId(ex.name) == exerciseId,
        orElse: () => throw Exception('Exercise not found'),
      );
      
      final sets = _exerciseSets[exerciseId] ?? [];
      final completedSets = sets.where((set) => set.isCompleted).toList();
      
      // Only save if there are completed sets
      if (completedSets.isNotEmpty) {
        final logId = await _exerciseLogService.logExercise(
          exercise: exercise,
          completedSets: sets, // Save all sets, not just completed ones
          date: DateTime.now(),
          workoutType: widget.workout.type,
          notes: 'Auto-saved during workout',
        );
        
        if (logId != null) {
          debugPrint('Exercise log auto-saved: ${exercise.name}');
          
          // Refresh exercise history to show updated data
          await _refreshExerciseHistory(exerciseId);
          
          // Show a subtle confirmation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${exercise.name} progress saved'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error auto-saving exercise log: $e');
    }
  }

  // Refresh exercise history for a specific exercise
  Future<void> _refreshExerciseHistory(String exerciseId) async {
    try {
      // Find the exercise name from the exerciseId
      final exercise = widget.workout.exercises.firstWhere(
        (ex) => _exerciseLogService.generateExerciseId(ex.name) == exerciseId,
        orElse: () => throw Exception('Exercise not found'),
    );
      
      // Use the existing service to get exercise history
      final logs = await _exerciseLogService.getExerciseHistory(exerciseId);
      
      if (mounted) {
        setState(() {
          _exerciseHistories[exercise.name] = logs; // Use exercise name as key
        });
        print('Refreshed history for "${exercise.name}": ${logs.length} entries');
      }
    } catch (e) {
      debugPrint('Error refreshing exercise history: $e');
    }
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: 18),
            const SizedBox(width: 4),
        Text(
              value,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Future<void> _startOrCompleteWorkout(BuildContext context) async {
    if (_currentSession == null) {
      // Start new workout session
      await _startWorkoutSession();
    } else if (_currentSession!.completionStatus != WorkoutCompletionStatus.completed) {
      // Complete current session
      await _completeWorkoutSession();
    } else {
      // Update completed session
      await _updateWorkoutSession();
    }
  }

  Future<void> _startWorkoutSession() async {
    setState(() => _isLoading = true);

    try {
      final sessionId = await _sessionService.createWorkoutSession(
        workout: widget.workout,
        date: DateTime.now(),
        workoutPlanId: widget.workout.name, // You can pass actual plan ID here
      );

      if (sessionId != null) {
        await _loadTodaysSession();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout session started!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting workout: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeWorkoutSession() async {
    setState(() => _isLoading = true);

    try {
      // Log all exercises
      final exerciseLogIds = <String>[];
      
      for (final exercise in widget.workout.exercises) {
        final exerciseId = _exerciseLogService.generateExerciseId(exercise.name);
        final sets = _exerciseSets[exerciseId] ?? [];
        
        if (sets.any((set) => set.isCompleted)) {
          final logId = await _exerciseLogService.logExercise(
            exercise: exercise,
            completedSets: sets,
            date: DateTime.now(),
            workoutPlanId: _currentSession!.workoutPlanId,
            workoutType: widget.workout.type,
          );
          
          if (logId != null) {
            exerciseLogIds.add(logId);
            await _sessionService.addExerciseToSession(
              sessionId: _currentSession!.id!,
              exerciseLogId: logId,
            );
          }
        }
      }

      // Complete the session
      await _sessionService.completeWorkoutSession(
        sessionId: _currentSession!.id!,
        caloriesBurned: widget.workout.caloriesBurned,
      );

      await _loadTodaysSession();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout completed! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing workout: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateWorkoutSession() async {
    // Implementation for updating an already completed session
    await _completeWorkoutSession();
  }

  void _showWorkoutHistory(BuildContext context) {
    // Implementation for showing workout history
  }
  
  IconData _getWorkoutTypeIcon(String type) {
    final lowercaseType = type.toLowerCase();
    if (lowercaseType.contains('strength')) return Icons.fitness_center;
    if (lowercaseType.contains('cardio')) return Icons.directions_run;
    if (lowercaseType.contains('rest')) return Icons.hotel;
    if (lowercaseType.contains('yoga')) return Icons.self_improvement;
    if (lowercaseType.contains('hiit')) return Icons.flash_on;
    return Icons.sports_gymnastics;
  }
} 