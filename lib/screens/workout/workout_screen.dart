import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/workout_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/workout_plan.dart';
import '../../models/exercise_log.dart';
import '../../services/exercise_log_service.dart';
import 'workout_details_screen.dart';
import 'workout_logs_screen.dart';
import 'exercise_logs_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  late DateTime _currentWeekStart;
  
  // Exercise logs state
  final ExerciseLogService _exerciseLogService = ExerciseLogService();
  List<ExerciseLogEntry> _todaysExerciseLogs = [];
  bool _isLoadingExerciseLogs = false;
  
  @override
  void initState() {
    super.initState();
    // Set the date range to cover last 7 days to next 7 days
    final now = DateTime.now();
    _currentWeekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    
    // Initialize tab controller for 15 days (7 past + today + 7 future)
    _tabController = TabController(length: 15, vsync: this);
    
    // Set the initial tab to today (index 7)
    _tabController.index = 7;
    
    // Initialize the workout provider and load existing workout plan
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('======= WORKOUT SCREEN INITIALIZATION =======');
      
      try {
        final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
        
        // Force reinitialize to make sure we load the latest data from Firestore
        debugPrint('Initializing workout provider...');
        await workoutProvider.initialize(force: true);
        
        if (workoutProvider.error != null) {
          debugPrint('Error loading workout plan: ${workoutProvider.error}');
          _showErrorSnackBar(context, 'Error loading workout plan: ${workoutProvider.error}');
        } else {
          debugPrint('Workout plan initialization complete');
          debugPrint('Workout plan loaded: ${workoutProvider.currentWorkoutPlan != null}');
          
          if (workoutProvider.currentWorkoutPlan != null) {
            final plan = workoutProvider.currentWorkoutPlan!;
            debugPrint('Plan ID: ${plan.id}');
            debugPrint('Workouts count: ${plan.workouts.length}');
            if (plan.workouts.isNotEmpty) {
              final firstWorkout = plan.workouts.first;
              debugPrint('First workout: ${firstWorkout.name} (${firstWorkout.type})');
            }
          }
        }
      } catch (e) {
        debugPrint('Exception during workout screen initialization: $e');
        _showErrorSnackBar(context, 'Error loading workout data. Please try again.');
      }
      
      await _loadTodaysExerciseLogs();
      
      debugPrint('======= WORKOUT SCREEN INITIALIZATION COMPLETE =======');
    });
  }
  
  Future<void> _loadTodaysExerciseLogs() async {
    setState(() {
      _isLoadingExerciseLogs = true;
    });
    
    try {
      final today = DateTime.now();
      final exerciseLogs = await _exerciseLogService.getExerciseLogsForDate(today);
      
      setState(() {
        _todaysExerciseLogs = exerciseLogs;
        _isLoadingExerciseLogs = false;
      });
    } catch (e) {
      debugPrint('Error loading today\'s exercise logs: $e');
      setState(() {
        _isLoadingExerciseLogs = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh exercise logs when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodaysExerciseLogs();
    });
  }

  // Navigate to workout setup screen to create a new workout plan
  void _navigateToWorkoutSetup() {
    Navigator.pushNamed(context, '/workout/setup');
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Weekly Workout Plan',
          style: textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExerciseLogsScreen()),
            ),
            tooltip: 'View exercise logs',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading 
              ? null 
              : () => _navigateToWorkoutSetup(),
            tooltip: 'Create new workout plan',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: List.generate(15, (index) {
              final date = _currentWeekStart.add(Duration(days: index));
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final dayName = DateFormat('EEE').format(date); // Mon, Tue, Wed, etc.
              final dayNumber = DateFormat('d').format(date); // 1, 2, etc.
              
              return Tab(
                height: 60,
                child: Container(
                  width: 45, // Smaller fixed width to avoid overflow
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: isToday ? BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ) : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color: isToday ? colorScheme.onPrimaryContainer : null,
                          fontWeight: isToday ? FontWeight.bold : null,
                          fontSize: 11, // Smaller text to fit better
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Smaller gap
                      Text(
                        dayNumber,
                        style: TextStyle(
                          color: isToday ? colorScheme.onPrimaryContainer : null,
                          fontSize: 13, // Slightly smaller
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          if (workoutProvider.isLoading || _isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isLoading 
                      ? 'Creating your workout plan...' 
                      : 'Loading your workout plan...',
                    style: textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }
          
          if (workoutProvider.currentWorkoutPlan == null || workoutProvider.currentWorkoutPlan!.workouts.isEmpty) {
            return _buildNoWorkoutPlanView(context);
          }
          
          // Display workout plan with tabs
          return TabBarView(
            controller: _tabController,
            children: List.generate(15, (index) {
              final date = _currentWeekStart.add(Duration(days: index));
              return _buildDailyWorkoutView(context, date, workoutProvider);
            }),
          );
        },
      ),
      floatingActionButton: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, child) {
          if (workoutProvider.currentWorkoutPlan == null && !_isLoading && !workoutProvider.isLoading) {
            return FloatingActionButton.extended(
              onPressed: _navigateToWorkoutSetup,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Create Plan'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNoWorkoutPlanView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Animate(
        effects: const [
          FadeEffect(duration: Duration(milliseconds: 600)),
          SlideEffect(
            begin: Offset(0, 30),
            end: Offset.zero,
            duration: Duration(milliseconds: 800),
          ),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No workout plan found',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Create a workout plan to get started with your fitness journey',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _navigateToWorkoutSetup,
              icon: const Icon(Icons.add),
              label: const Text('Create Workout Plan'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailyWorkoutView(BuildContext context, DateTime date, WorkoutProvider workoutProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Get workout for the selected date by matching weekday
    final int weekday = date.weekday; // 1 = Monday, 7 = Sunday
    
    // Find workout by weekday
    DailyWorkout? workout;
    try {
      workout = workoutProvider.currentWorkoutPlan!.workouts.firstWhere(
        (w) => w.day == weekday,
      );
    } catch (e) {
      // No workout found for this day
      workout = null;
    }
    
    if (workout == null) {
      // No workout for this day
      return Center(
        child: Animate(
          effects: const [
            FadeEffect(duration: Duration(milliseconds: 400)),
          ],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hotel,
                size: 56,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Rest Day',
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No workout scheduled for ${DateFormat('EEEE').format(date)}',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => _navigateToWorkoutSetup(),
                child: const Text('Update Schedule'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Return workout view for this day
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Animate(
        effects: const [
          FadeEffect(duration: Duration(milliseconds: 400)),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
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
                        Icon(
                          _getWorkoutTypeIcon(workout.type),
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          workout.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(workout.type),
                          backgroundColor: colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Workout details row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWorkoutInfoItem(
                          context,
                          Icons.timer_outlined,
                          workout.duration,
                          'Duration',
                        ),
                        _buildWorkoutInfoItem(
                          context,
                          Icons.whatshot_outlined,
                          workout.intensity,
                          'Intensity',
                        ),
                        _buildWorkoutInfoItem(
                          context,
                          Icons.home_outlined,
                          workout.indoorOutdoor,
                          'Location',
                        ),
                      ],
                    ),
                    
                    // If there are notes, show them
                    if (workout.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              workout.notes,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutDetailsScreen(
                            workout: workout!,
                            workoutDate: date,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Full Workout'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Equipment needed
            if (workout.equipmentNeeded.isNotEmpty) ...[
              Text(
                'Equipment Needed',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: workout.equipmentNeeded.map((equipment) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              equipment,
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Exercise list preview
            if (workout.exercises.isNotEmpty) ...[
              Text(
                'Exercises (${workout.exercises.length})',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...workout.exercises.take(3).map((exercise) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    title: Text(exercise.name),
                    subtitle: Text('${exercise.sets} sets × ${exercise.reps} reps'),
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.fitness_center,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
              
              if (workout.exercises.length > 3) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailsScreen(
                          workout: workout!,
                          workoutDate: date,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.list),
                    label: Text('View all ${workout.exercises.length} exercises'),
                  ),
                ),
              ],
            ],
            
            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailsScreen(
                          workout: workout!,
                          workoutDate: date,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailsScreen(
                          workout: workout!,
                          workoutDate: date,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Workout'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            // Today's Exercise Logs Section (only show for today)
            if (DateUtils.isSameDay(date, DateTime.now())) ...[
              const SizedBox(height: 32),
              _buildTodaysExerciseLogsSection(context),
            ],
            
            // Bottom padding to prevent navbar from blocking content
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutInfoItem(BuildContext context, IconData icon, String text, String label) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
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

  Widget _buildTodaysExerciseLogsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    if (_isLoadingExerciseLogs) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Exercise Logs',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    if (_todaysExerciseLogs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Exercise Logs',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No exercises logged today',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start your workout to begin logging',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    // Calculate overall progress
    int totalSets = 0;
    int completedSets = 0;
    
    for (final log in _todaysExerciseLogs) {
      totalSets += log.sets.length;
      completedSets += log.sets.where((set) => set.isCompleted).length;
    }
    
    final completionPercentage = totalSets > 0 ? (completedSets / totalSets * 100).round() : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Exercise Logs',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (totalSets > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completionPercentage%',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                if (totalSets > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$completedSets/$totalSets sets',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completedSets / totalSets,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Exercise list
                ..._todaysExerciseLogs.take(3).map((log) {
                  final exerciseCompletedSets = log.sets.where((set) => set.isCompleted).length;
                  final exerciseTotalSets = log.sets.length;
                  final isCompleted = exerciseCompletedSets == exerciseTotalSets;
                  
                  // Get the latest completed set with weight
                  final latestWeightedSet = log.sets
                      .where((set) => set.isCompleted && set.weight != null && set.weight! > 0)
                      .lastOrNull;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isCompleted ? Colors.green : colorScheme.onSurfaceVariant,
                          size: 20,
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
                                  color: isCompleted ? Colors.green : null,
                                ),
                              ),
                              if (latestWeightedSet != null)
                                Text(
                                  'Latest: ${latestWeightedSet.weight} kg × ${latestWeightedSet.reps} reps',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCompleted 
                              ? Colors.green.withOpacity(0.1)
                              : colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$exerciseCompletedSets/$exerciseTotalSets',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.green : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                if (_todaysExerciseLogs.length > 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${_todaysExerciseLogs.length - 3} more exercises',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExerciseLogsScreen()),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View All Exercise Logs'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 