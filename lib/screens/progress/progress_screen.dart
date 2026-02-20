import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../services/exercise_log_service.dart';
import '../../models/exercise_log.dart';
import '../workout/exercise_logs_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final ExerciseLogService _logService = ExerciseLogService();
  bool _isLoading = true;
  List<ExerciseLogEntry> _recentLogs = [];
  Map<String, int> _exerciseCount = {};
  int _totalSessions = 0;
  int _totalSets = 0;
  int _completedSets = 0;
  double _totalVolume = 0;
  int _totalDays = 0;
  
  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }
  
  Future<void> _loadExerciseData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get logs from the past three months
      final now = DateTime.now();
      final lastThreeMonths = DateTime(now.year, now.month - 3, now.day);
      
      final logs = await _logService.getExerciseLogsByDateRange(
        startDate: lastThreeMonths,
        endDate: now,
      );
      
      // Process logs to get statistics
      _recentLogs = logs.take(10).toList();
      
      // Calculate statistics
      _exerciseCount = {};
      _totalSessions = logs.length;
      _totalSets = 0;
      _completedSets = 0;
      _totalVolume = 0;
      
      // Track unique days with workouts
      final uniqueDays = <String>{};
      
      for (final log in logs) {
        // Count exercise types
        final exerciseName = log.exerciseName;
        _exerciseCount[exerciseName] = (_exerciseCount[exerciseName] ?? 0) + 1;
        
        // Count sets and volume
        _totalSets += log.sets.length;
        _completedSets += log.sets.where((set) => set.isCompleted).length;
        
        // Calculate volume (weight × reps for completed sets)
        for (final set in log.sets.where((set) => set.isCompleted)) {
          if (set.weight != null && set.weight! > 0) {
            final reps = int.tryParse(set.reps) ?? 0;
            _totalVolume += set.weight! * reps;
          }
        }
        
        // Track unique days
        final dateStr = DateFormat('yyyy-MM-dd').format(log.date);
        uniqueDays.add(dateStr);
      }
      
      _totalDays = uniqueDays.length;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading exercise data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoading
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
                    'Loading your progress...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Text(
                    'Your Progress',
                    style: textTheme.titleLarge,
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadExerciseData,
                      tooltip: 'Refresh data',
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        // Summary Stats
            Animate(
              effects: const [
                FadeEffect(duration: Duration(milliseconds: 600)),
                SlideEffect(
                  begin: Offset(0, 30),
                  end: Offset.zero,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeOutQuint,
                ),
              ],
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                                        'Last 3 Months',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                              builder: (context) => const ExerciseLogsScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'View All Logs',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                                      Expanded(
                                        child: _buildStatCard(
                            context,
                                          'Exercise Sessions',
                                          _totalSessions.toString(),
                                          Icons.fitness_center,
                                          colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                            context,
                                          'Active Days',
                                          _totalDays.toString(),
                                          Icons.calendar_today,
                                          colorScheme.secondary,
                                        ),
                          ),
                        ],
                      ),
                                  const SizedBox(height: 12),
                              Row(
                                children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          context,
                                          'Sets Completed',
                                          '$_completedSets/$_totalSets',
                                          Icons.check_circle,
                                          colorScheme.tertiary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                    context,
                                          'Total Volume',
                                          '${_totalVolume.toInt()}kg',
                                          Icons.trending_up,
                                          Colors.orange,
                                        ),
                                  ),
                                ],
                              ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
                        // Exercise Breakdown
                        if (_exerciseCount.isNotEmpty) ...[
            Animate(
              effects: const [
                              FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 200)),
                SlideEffect(
                  begin: Offset(0, 30),
                  end: Offset.zero,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeOutQuint,
                                delay: Duration(milliseconds: 200),
                ),
              ],
                            child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                padding: const EdgeInsets.all(20),
                                      child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                      'Exercise Breakdown',
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                    ..._exerciseCount.entries.take(5).map((entry) {
                                      final percentage = (_exerciseCount[entry.key]! / _totalSessions * 100).round();
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    entry.key,
                                                    style: textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                          Text(
                                                  '${entry.value} sessions',
                                                  style: textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                                ),
                                              ],
                                          ),
                                            const SizedBox(height: 4),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: entry.value / _totalSessions,
                                                backgroundColor: colorScheme.surfaceVariant,
                                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                                                minHeight: 6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Recent Activity
                        if (_recentLogs.isNotEmpty) ...[
                          Animate(
                            effects: const [
                              FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 400)),
                              SlideEffect(
                                begin: Offset(0, 30),
                                end: Offset.zero,
                                duration: Duration(milliseconds: 500),
                                curve: Curves.easeOutQuint,
                                delay: Duration(milliseconds: 400),
                              ),
                            ],
                                      child: Card(
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Recent Activity',
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const ExerciseLogsScreen(),
                                              ),
                                            );
                                          },
                                          child: const Text('View All'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ..._recentLogs.take(5).map((log) {
                                      final completedSets = log.sets.where((set) => set.isCompleted).length;
                                      final totalSets = log.sets.length;
                                      final formattedDate = DateFormat('MMM d, yyyy').format(log.date);
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                          child: Row(
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
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                    log.exerciseName,
                                                    style: textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                    '$formattedDate • $completedSets/$totalSets sets',
                                                    style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                                                ],
                                              ),
                                            ),
                                            if (log.personalRecord != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.amber),
                                                          ),
                                                child: Text(
                                                  'PR',
                                                            style: textTheme.bodySmall?.copyWith(
                                                    color: Colors.amber[700],
                                                    fontWeight: FontWeight.bold,
                                                    ),
                                                ),
                                              ),
                                            ],
                                      ),
                                    );
                                  }).toList(),
                ],
              ),
            ),
                            ),
                ),
              ],
            
            const SizedBox(height: 100), // Increased bottom padding to prevent navbar from blocking content
          ],
                ),
        ),
      ),
              ],
            ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, 
    String title, 
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
          children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
            Expanded(
                child: Text(
                    title,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            ),
          ],
      ),
    );
  }
} 