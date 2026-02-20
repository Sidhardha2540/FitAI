import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart';
import '../../providers/workout_provider.dart';
import '../../models/workout_plan.dart';
import '../../widgets/workout_details_card.dart';
import 'workout_setup_screen.dart';

class CalendarWorkoutScreen extends StatefulWidget {
  const CalendarWorkoutScreen({super.key});

  @override
  State<CalendarWorkoutScreen> createState() => _CalendarWorkoutScreenState();
}

class _CalendarWorkoutScreenState extends State<CalendarWorkoutScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  // CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Calendar'),
        backgroundColor: colorScheme.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Calendar View',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Calendar functionality will be available soon',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Workouts'),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder methods for when table_calendar is added
  /*
  Widget _buildCalendar() {
    return TableCalendar<DailyWorkout>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      selectedDayPredicate: (day) {
        return isSameDay(_selectedDay, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(
          color: colorScheme.primary.withOpacity(0.7),
        ),
        holidayTextStyle: TextStyle(
          color: colorScheme.primary.withOpacity(0.7),
        ),
      ),
    );
  }
  */

  Widget _buildSelectedDayWorkout() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<WorkoutProvider>(
      builder: (context, workoutProvider, child) {
        if (workoutProvider.currentWorkoutPlan == null) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No workout plan available',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Find workout for selected day
        final weekday = _selectedDay.weekday;
        DailyWorkout? workout;
        
        try {
          workout = workoutProvider.currentWorkoutPlan!.workouts.firstWhere(
            (w) => w.day == weekday,
          );
        } catch (e) {
          workout = null;
        }

        if (workout == null) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.hotel,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rest Day',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDay),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        workout.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d').format(_selectedDay),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${workout.exercises.length} exercises • ${workout.duration}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 