import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../services/exercise_log_service.dart';
import '../../models/exercise_log.dart';

class ExerciseLogsScreen extends StatefulWidget {
  const ExerciseLogsScreen({super.key});

  @override
  State<ExerciseLogsScreen> createState() => _ExerciseLogsScreenState();
}

class _ExerciseLogsScreenState extends State<ExerciseLogsScreen> {
  final ExerciseLogService _logService = ExerciseLogService();
  List<ExerciseLogEntry> _logs = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadExerciseLogs();
  }
  
  Future<void> _loadExerciseLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final logs = await _logService.getRecentExerciseLogs(limit: 50);
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
        content: const Text('Are you sure you want to delete this exercise log?'),
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
      
      final success = await _logService.deleteExerciseLog(logId);
      
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadExerciseLogs(); // Reload logs
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
          'Exercise Logs',
          style: textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExerciseLogs,
            tooltip: 'Refresh logs',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        strokeWidth: 2.5,
        onRefresh: _loadExerciseLogs,
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
                    'Loading exercise logs...',
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
                      'Error loading exercise logs',
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
                      onPressed: _loadExerciseLogs,
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
                          'No exercise logs yet',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start logging your exercises to see your progress',
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
                    
                    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(log.date);
                    final formattedTime = DateFormat('h:mm a').format(log.date);
                    
                    // Calculate completed sets
                    final completedSets = log.sets.where((set) => set.isCompleted).length;
                    final totalSets = log.sets.length;
                    
                    // Get max weight from completed sets
                    final maxWeight = log.sets
                        .where((set) => set.isCompleted && set.weight != null)
                        .map((set) => set.weight!)
                        .fold<double>(0, (max, weight) => weight > max ? weight : max);
                    
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
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.fitness_center,
                                      color: colorScheme.onPrimaryContainer,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log.exerciseName,
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$formattedDate at $formattedTime',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (log.id != null)
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: colorScheme.error,
                                      ),
                                      onPressed: () => _deleteLog(log.id!),
                                      tooltip: 'Delete log',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Progress summary
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$completedSets/$totalSets sets completed',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  if (maxWeight > 0) ...[
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.fitness_center_outlined,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Max: ${maxWeight}kg',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              
                              // Personal record badge
                              if (log.personalRecord != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.emoji_events,
                                        size: 16,
                                        color: Colors.amber[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Personal Record!',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.amber[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              // Sets details
                              if (log.sets.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Sets:',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: log.sets.map((set) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: set.isCompleted 
                                          ? colorScheme.secondaryContainer
                                          : colorScheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Set ${set.setNumber}: ',
                                            style: textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: set.isCompleted 
                                                ? colorScheme.onSecondaryContainer
                                                : colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          if (set.weight != null && set.weight! > 0)
                                            Text(
                                              '${set.weight}kg × ',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: set.isCompleted 
                                                  ? colorScheme.onSecondaryContainer
                                                  : colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          Text(
                                            '${set.reps} reps',
                                            style: textTheme.bodySmall?.copyWith(
                                              color: set.isCompleted 
                                                ? colorScheme.onSecondaryContainer
                                                : colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            set.isCompleted 
                                              ? Icons.check_circle 
                                              : Icons.circle_outlined,
                                            size: 14,
                                            color: set.isCompleted 
                                              ? Colors.green 
                                              : colorScheme.onSurfaceVariant.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                              
                              // Notes
                              if (log.notes != null && log.notes!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Notes:',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  log.notes!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
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