import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../services/workout_log_service.dart';
import '../../models/workout_log.dart';

class WorkoutLogsScreen extends StatefulWidget {
  const WorkoutLogsScreen({super.key});

  @override
  State<WorkoutLogsScreen> createState() => _WorkoutLogsScreenState();
}

class _WorkoutLogsScreenState extends State<WorkoutLogsScreen> {
  final WorkoutLogService _logService = WorkoutLogService();
  List<WorkoutLog> _logs = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadWorkoutLogs();
  }
  
  Future<void> _loadWorkoutLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final logs = await _logService.getWorkoutLogs();
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteLog(String logId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this workout log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _logService.deleteWorkoutLog(logId);
      
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadWorkoutLogs(); // Reload logs
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete log'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
          'Workout Logs',
          style: textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWorkoutLogs,
            tooltip: 'Refresh logs',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        strokeWidth: 2.5,
        onRefresh: _loadWorkoutLogs,
        child: _isLoading 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: colorScheme.primary,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading workout logs...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading workout logs',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _loadWorkoutLogs,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            : _logs.isEmpty
              ? Center(
                  child: Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 500)),
                      SlideEffect(
                        begin: Offset(0, 30),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeOutQuint,
                      ),
                    ],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          color: colorScheme.primary.withOpacity(0.5),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No workout logs yet',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete a workout and log it to see your history',
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    
                    // Parse date
                    DateTime? date;
                    try {
                      date = DateFormat('yyyy-MM-dd').parse(log.completedDate);
                    } catch (_) {}
                    
                    final formattedDate = date != null 
                        ? DateFormat('EEEE, MMMM d, yyyy').format(date)
                        : log.completedDate;
                    
                    return Animate(
                      effects: [
                        FadeEffect(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                        ),
                        SlideEffect(
                          begin: const Offset(0, 20),
                          end: Offset.zero,
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          curve: Curves.easeOutQuint,
                        ),
                      ],
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.workoutName,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${log.workoutType} • ${log.dayName}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: colorScheme.error,
                                    ),
                                    onPressed: () => _deleteLog(log.id ?? ''),
                                    tooltip: 'Delete log',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Completed: $formattedDate',
                                style: textTheme.bodyMedium,
                              ),
                              
                              Row(
                                children: [
                                  if (log.duration.isNotEmpty) ...[
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Duration: ${log.duration}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  if (log.caloriesBurned != null && log.caloriesBurned! > 0) ...[
                                    Icon(
                                      Icons.local_fire_department_outlined,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Calories burned: ${log.caloriesBurned}',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              
                              if (log.notes != null && log.notes!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Notes:',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  log.notes!,
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                              
                              if (log.exercises.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Exercises:',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...log.exercises.map<Widget>((exercise) {
                                  // Count completed sets
                                  final completedSets = exercise.sets.where((set) => set.isCompleted).length;
                                  final totalSets = exercise.sets.length;
                                  final isFullyCompleted = completedSets == totalSets && totalSets > 0;
                                  
                                  return ExpansionTile(
                                    title: Row(
                                      children: [
                                        Icon(
                                          isFullyCompleted 
                                            ? Icons.check_circle 
                                            : Icons.fitness_center,
                                          size: 18,
                                          color: isFullyCompleted 
                                            ? Colors.green 
                                            : colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            exercise.name,
                                            style: textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '$completedSets/$totalSets sets completed',
                                      style: textTheme.bodySmall,
                                    ),
                                    childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    children: exercise.sets.map((set) {
                                      // Skip empty sets that have no weight or reps
                                      if ((set.weight == null || set.weight == 0) && 
                                          (set.reps.isEmpty || set.reps == '0')) {
                                        return const SizedBox.shrink();
                                      }
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 30,
                                              child: Text(
                                                'Set ${set.setNumber}:',
                                                style: textTheme.bodySmall,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (set.reps.isNotEmpty) ...[
                                              Text(
                                                '${set.reps} reps',
                                                style: textTheme.bodyMedium,
                                              ),
                                            ],
                                            if (set.weight != null && set.weight! > 0) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '${set.weight} kg',
                                                style: textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                            const Spacer(),
                                            Icon(
                                              set.isCompleted 
                                                ? Icons.check_circle 
                                                : Icons.circle_outlined,
                                              size: 16,
                                              color: set.isCompleted 
                                                ? Colors.green 
                                                : colorScheme.onSurfaceVariant.withOpacity(0.5),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }).toList(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
} 