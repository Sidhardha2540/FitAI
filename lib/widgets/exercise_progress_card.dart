import 'package:flutter/material.dart';
import '../models/user_exercise_history.dart';
import 'package:fl_chart/fl_chart.dart';

class ExerciseProgressCard extends StatelessWidget {
  final UserExerciseHistory history;
  final VoidCallback? onTap;

  const ExerciseProgressCard({
    super.key,
    required this.history,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with exercise name and trend
              Row(
                children: [
                  Expanded(
                    child: Text(
                      history.exerciseName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildTrendIndicator(context),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Progress metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    context,
                    'Sessions',
                    history.totalSessions.toString(),
                    Icons.fitness_center,
                  ),
                  _buildMetric(
                    context,
                    'Avg Weight',
                    '${history.averageWeight.toStringAsFixed(1)}kg',
                    Icons.line_weight,
                  ),
                  if (history.allTimeRecord?.maxWeight != null)
                    _buildMetric(
                      context,
                      'PR',
                      '${history.allTimeRecord!.maxWeight!.toStringAsFixed(1)}kg',
                      Icons.star,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Mini progress chart
              if (history.recentPerformance.length >= 2)
                SizedBox(
                  height: 60,
                  child: _buildMiniChart(context),
                ),
              
              const SizedBox(height: 8),
              
              // Last performed
              if (history.lastPerformed != null)
                Text(
                  'Last performed: ${_formatDate(history.lastPerformed!)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    IconData icon;
    Color color;
    
    switch (history.progressTrend) {
      case ProgressTrend.improving:
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case ProgressTrend.declining:
        icon = Icons.trending_down;
        color = Colors.red;
        break;
      case ProgressTrend.stable:
        icon = Icons.trending_flat;
        color = colorScheme.onSurfaceVariant;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            history.progressTrend.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon) {
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

  Widget _buildMiniChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final spots = history.recentPerformance
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              entry.value.totalVolume,
            ))
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${(difference / 7).floor()} weeks ago';
  }
} 