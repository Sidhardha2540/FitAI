import 'package:flutter/material.dart';
import '../models/workout_plan.dart';

class WorkoutDetailsCard extends StatelessWidget {
  final Exercise exercise;
  final Function(bool)? onCompleted;

  const WorkoutDetailsCard({
    super.key,
    required this.exercise,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCompleted != null)
                  Checkbox(
                    value: exercise.completed,
                    onChanged: (value) {
                      if (value != null) {
                        onCompleted!(value);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  context,
                  '${exercise.sets} sets',
                  Icons.repeat,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  context,
                  '${exercise.reps} reps',
                  Icons.fitness_center,
                ),
                if (exercise.weight != null && exercise.weight! > 0) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    '${exercise.weight} kg',
                    Icons.monitor_weight_outlined,
                  ),
                ],
              ],
            ),
            if (exercise.instructions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Instructions:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.instructions,
                style: textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 