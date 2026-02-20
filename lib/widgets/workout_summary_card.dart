import 'package:flutter/material.dart';
import '../models/workout_session.dart';
import '../models/exercise_log.dart';

class WorkoutSummaryCard extends StatelessWidget {
  final WorkoutSession session;
  final List<ExerciseLogEntry> exerciseLogs;
  final VoidCallback? onViewDetails;

  const WorkoutSummaryCard({
    super.key,
    required this.session,
    required this.exerciseLogs,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final completedExercises = exerciseLogs.where(
      (log) => log.sets.any((set) => set.isCompleted),
    ).length;
    
    final totalVolume = exerciseLogs.fold<double>(
      0,
      (sum, log) => sum + log.sets
          .where((set) => set.isCompleted)
          .fold<double>(
            0,
            (setSum, set) => setSum + ((set.weight ?? 0) * (int.tryParse(set.reps) ?? 0)),
          ),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(session.completionStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(session.completionStatus),
                      color: _getStatusColor(session.completionStatus),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.workoutName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(session.date),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.workoutType,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: exerciseLogs.isEmpty ? 0 : completedExercises / exerciseLogs.length,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(session.completionStatus),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completedExercises/${exerciseLogs.length}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    context,
                    'Duration',
                    session.totalDuration != null
                        ? _formatDuration(session.totalDuration!)
                        : '-',
                    Icons.timer,
                  ),
                  _buildStat(
                    context,
                    'Volume',
                    '${totalVolume.toStringAsFixed(0)}kg',
                    Icons.fitness_center,
                  ),
                  _buildStat(
                    context,
                    'Calories',
                    session.caloriesBurned?.toString() ?? '-',
                    Icons.local_fire_department,
                  ),
                ],
              ),
              
              // Personal records indicator
              if (exerciseLogs.any((log) => log.personalRecord != null)) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Personal Records Set!',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(WorkoutCompletionStatus status) {
    switch (status) {
      case WorkoutCompletionStatus.completed:
        return Colors.green;
      case WorkoutCompletionStatus.inProgress:
        return Colors.orange;
      case WorkoutCompletionStatus.skipped:
        return Colors.red;
      case WorkoutCompletionStatus.notStarted:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(WorkoutCompletionStatus status) {
    switch (status) {
      case WorkoutCompletionStatus.completed:
        return Icons.check_circle;
      case WorkoutCompletionStatus.inProgress:
        return Icons.play_circle;
      case WorkoutCompletionStatus.skipped:
        return Icons.skip_next;
      case WorkoutCompletionStatus.notStarted:
        return Icons.radio_button_unchecked;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${difference} days ago';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
} 