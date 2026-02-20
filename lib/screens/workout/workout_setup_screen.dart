import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';

class WorkoutSetupScreen extends StatefulWidget {
  const WorkoutSetupScreen({super.key});

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  final List<String> _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  String _preferredTime = '';
  bool _isCreating = false;

  final List<String> _timeOptions = [
    'Early Morning (5-7 AM)',
    'Morning (7-10 AM)',
    'Mid-day (10 AM-2 PM)',
    'Afternoon (2-5 PM)',
    'Evening (5-8 PM)',
    'Night (8-11 PM)',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Your Workout'),
      ),
      body: _isCreating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Creating your workout plan...',
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Which days would you like to work out?',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the days that work best for your schedule.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: List.generate(7, (index) {
                          return CheckboxListTile(
                            title: Text(_dayNames[index]),
                            value: _selectedDays[index],
                            onChanged: (value) {
                              setState(() {
                                _selectedDays[index] = value ?? false;
                              });
                            },
                            activeColor: colorScheme.primary,
                            checkColor: colorScheme.onPrimary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            controlAffinity: ListTileControlAffinity.leading,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'What time of day do you prefer to work out?',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps us schedule your workout for the right time of day.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: _timeOptions.map((time) {
                          return RadioListTile<String>(
                            title: Text(time),
                            value: time,
                            groupValue: _preferredTime,
                            onChanged: (value) {
                              setState(() {
                                _preferredTime = value ?? '';
                              });
                            },
                            activeColor: colorScheme.primary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _getSelectedDaysCount() < 1
                          ? null
                          : () => _createWorkoutPlan(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Create Workout Plan',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  int _getSelectedDaysCount() {
    return _selectedDays.where((selected) => selected).length;
  }

  List<int> _getSelectedDayIndices() {
    final indices = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        // Add 1 to make it 1-based (1=Monday, 7=Sunday)
        indices.add(i + 1);
      }
    }
    return indices;
  }

  Future<void> _createWorkoutPlan(BuildContext context) async {
    if (_getSelectedDaysCount() < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one workout day'),
        ),
      );
      return;
    }

    if (_preferredTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preferred workout time'),
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      
      if (userProvider.userProfile != null) {
        final selectedDays = _getSelectedDayIndices();
        
        // Create a basic workout plan structure
        final now = DateTime.now();
        final workoutPlan = {
          'weekStartDate': now.toIso8601String(),
          'workoutPlan': _createBasicWorkoutPlan(selectedDays, _preferredTime),
        };
        
        await workoutProvider.createWorkoutPlan(workoutPlan);
        
        if (workoutProvider.error != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(workoutProvider.error!),
              ),
            );
          }
        }
        
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User profile not available. Please complete your profile first.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create workout plan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
  
  // Create a basic workout plan with rest days and workout days
  List<Map<String, dynamic>> _createBasicWorkoutPlan(List<int> workoutDays, String preferredTime) {
    final List<Map<String, dynamic>> workoutPlan = [];
    
    for (int day = 1; day <= 7; day++) {
      final String dayName = _dayNames[day - 1];
      
      if (workoutDays.contains(day)) {
        // This is a workout day
        workoutPlan.add({
          'day': day,
          'dayName': dayName,
          'date': _getDateForDay(day).toIso8601String(),
          'name': 'Workout Day',
          'type': day % 2 == 0 ? 'Cardio' : 'Strength',
          'indoorOutdoor': 'Indoor',
          'duration': '45 mins',
          'preferredTime': preferredTime,
          'equipmentNeeded': ['Dumbbells', 'Mat'],
          'exercises': [
            {
              'name': 'Warm-up',
              'sets': 1,
              'reps': 1,
              'restBetweenSets': '0 seconds',
              'instructions': 'Light cardio to warm up',
              'targetMuscleGroups': ['Full Body']
            },
            {
              'name': 'Exercise 1',
              'sets': 3,
              'reps': 10,
              'restBetweenSets': '60 seconds',
              'instructions': 'Focus on form',
              'targetMuscleGroups': ['Core']
            },
            {
              'name': 'Exercise 2',
              'sets': 3,
              'reps': 12,
              'restBetweenSets': '60 seconds',
              'instructions': 'Maintain proper posture',
              'targetMuscleGroups': ['Legs']
            },
          ],
          'warmup': '5 minute cardio',
          'cooldown': '5 minute stretching',
          'notes': 'Remember to stay hydrated',
          'intensity': 'medium',
        });
      } else {
        // This is a rest day
        workoutPlan.add({
          'day': day,
          'dayName': dayName,
          'date': _getDateForDay(day).toIso8601String(),
          'name': 'Rest Day',
          'type': 'Rest',
          'indoorOutdoor': 'N/A',
          'duration': '0 mins',
          'equipmentNeeded': [],
          'exercises': [],
          'warmup': '',
          'cooldown': '',
          'notes': 'Take it easy today and focus on recovery',
          'intensity': 'low',
        });
      }
    }
    
    return workoutPlan;
  }
  
  // Helper to get date for a specific day of the week
  DateTime _getDateForDay(int day) {
    final now = DateTime.now();
    final currentDay = now.weekday;
    final difference = day - currentDay;
    return now.add(Duration(days: difference));
  }
} 