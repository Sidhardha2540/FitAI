import 'package:flutter/material.dart';
import 'package:jeeva_fit_ai/constants/app_constants.dart';
import 'package:jeeva_fit_ai/models/user_profile.dart';
import 'package:jeeva_fit_ai/widgets/onboarding_widgets.dart';

class FitnessGoalsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;

  const FitnessGoalsScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<FitnessGoalsScreen> createState() => _FitnessGoalsScreenState();
}

class _FitnessGoalsScreenState extends State<FitnessGoalsScreen> {
  String? _fitnessLevel;
  String? _primaryGoal;
  late final TextEditingController _specificTargetsController;
  late final TextEditingController _motivationController;
  late final TextEditingController _weeklyExerciseDaysController;
  bool _hasPreviousExperience = false;

  @override
  void initState() {
    super.initState();
    _fitnessLevel = widget.userProfile.fitnessLevel;
    _primaryGoal = widget.userProfile.primaryFitnessGoal;
    _specificTargetsController = TextEditingController(text: widget.userProfile.specificTargets);
    _motivationController = TextEditingController(text: widget.userProfile.motivation);
    _weeklyExerciseDaysController = TextEditingController(text: widget.userProfile.weeklyExerciseDays);
    _hasPreviousExperience = widget.userProfile.previousProgramExperience == 'true';
  }

  @override
  void dispose() {
    _specificTargetsController.dispose();
    _motivationController.dispose();
    _weeklyExerciseDaysController.dispose();
    super.dispose();
  }

  void _saveData() {
    final updatedProfile = widget.userProfile.copyWith(
      fitnessLevel: _fitnessLevel,
      primaryFitnessGoal: _primaryGoal,
      specificTargets: _specificTargetsController.text,
      motivation: _motivationController.text,
      weeklyExerciseDays: _weeklyExerciseDaysController.text,
      previousProgramExperience: _hasPreviousExperience.toString(),
    );
    widget.onProfileUpdated(updatedProfile);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Your Fitness Goals',
            subtitle: 'Help us understand what you want to achieve',
          ),
          
          // Fitness level
          Text(
            'Current Fitness Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Column(
            children: AppConstants.fitnessLevels.map((level) {
              final isSelected = _fitnessLevel == level;
              final index = AppConstants.fitnessLevels.indexOf(level);
              
              String subtitle;
              IconData icon;
              
              switch (index) {
                case 0: // Beginner
                  subtitle = 'New to fitness or returning after a long break';
                  icon = Icons.emoji_people;
                  break;
                case 1: // Intermediate
                  subtitle = 'Consistent with workouts for a few months';
                  icon = Icons.directions_run;
                  break;
                case 2: // Advanced
                  subtitle = 'Experienced with regular challenging workouts';
                  icon = Icons.fitness_center;
                  break;
                case 3: // Elite
                  subtitle = 'Highly trained with years of dedicated experience';
                  icon = Icons.emoji_events;
                  break;
                default:
                  subtitle = '';
                  icon = Icons.person;
              }
              
              return OptionCard(
                title: level,
                subtitle: subtitle,
                icon: icon,
                isSelected: isSelected,
                animationIndex: index,
                onTap: () {
                  setState(() {
                    _fitnessLevel = level;
                  });
                  _saveData();
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Primary fitness goal
          Text(
            'Primary Fitness Goal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Column(
            children: AppConstants.primaryFitnessGoals.map((goal) {
              final isSelected = _primaryGoal == goal;
              final index = AppConstants.primaryFitnessGoals.indexOf(goal);
              
              IconData icon;
              
              switch (index) {
                case 0: // Weight loss
                  icon = Icons.trending_down;
                  break;
                case 1: // Muscle gain
                  icon = Icons.fitness_center;
                  break;
                case 2: // General fitness
                  icon = Icons.favorite;
                  break;
                case 3: // Strength building
                  icon = Icons.bolt;
                  break;
                case 4: // Endurance training
                  icon = Icons.timelapse;
                  break;
                case 5: // Flexibility & mobility
                  icon = Icons.accessibility_new;
                  break;
                default:
                  icon = Icons.fitness_center;
              }
              
              return OptionCard(
                title: goal,
                icon: icon,
                isSelected: isSelected,
                animationIndex: index + 5,
                onTap: () {
                  setState(() {
                    _primaryGoal = goal;
                  });
                  _saveData();
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Specific targets
          LabeledTextField(
            label: 'Specific Targets',
            hint: 'Describe your specific fitness targets',
            helperText: 'For example: "I want to lose 10kg" or "I want to run a 5k"',
            controller: _specificTargetsController,
            maxLines: 3,
            minLines: 2,
            animationIndex: 12,
            keyboardType: TextInputType.multiline,
            onChanged: (_) => _saveData(),
          ),
          
          // Motivation
          LabeledTextField(
            label: 'Your Motivation',
            hint: 'What drives you to achieve your fitness goals?',
            controller: _motivationController,
            maxLines: 3,
            minLines: 2,
            animationIndex: 13,
            keyboardType: TextInputType.multiline,
            onChanged: (_) => _saveData(),
          ),
          
          // Weekly exercise days
          LabeledTextField(
            label: 'Weekly Exercise Days',
            hint: 'How many days per week can you commit to exercise?',
            controller: _weeklyExerciseDaysController,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.calendar_today,
            animationIndex: 14,
            onChanged: (_) => _saveData(),
          ),
          
          // Previous experience
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text(
              'Previous Program Experience',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: const Text('Have you followed a fitness program before?'),
            value: _hasPreviousExperience,
            onChanged: (value) {
              setState(() {
                _hasPreviousExperience = value;
              });
              _saveData();
            },
            secondary: Icon(
              _hasPreviousExperience ? Icons.check_circle : Icons.cancel,
              color: _hasPreviousExperience ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
} 