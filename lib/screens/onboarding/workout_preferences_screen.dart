import 'package:flutter/material.dart';
import 'package:jeeva_fit_ai/constants/app_constants.dart';
import 'package:jeeva_fit_ai/models/user_profile.dart';
import 'package:jeeva_fit_ai/widgets/onboarding_widgets.dart';

class WorkoutPreferencesScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;

  const WorkoutPreferencesScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<WorkoutPreferencesScreen> createState() => _WorkoutPreferencesScreenState();
}

class _WorkoutPreferencesScreenState extends State<WorkoutPreferencesScreen> {
  String? _indoorOutdoorPreference;
  String? _equipmentAccess;
  late final TextEditingController _workoutDaysController;
  late final TextEditingController _workoutMinutesController;
  late final TextEditingController _additionalNotesController;

  // Workout preferences
  final List<String> _workoutPreferences = [];

  @override
  void initState() {
    super.initState();
    _indoorOutdoorPreference = widget.userProfile.indoorOutdoorPreference;
    _equipmentAccess = widget.userProfile.equipmentAccess;
    _workoutDaysController = TextEditingController(text: widget.userProfile.workoutDaysPerWeek);
    _workoutMinutesController = TextEditingController(text: widget.userProfile.workoutMinutesPerSession);
    _additionalNotesController = TextEditingController(text: widget.userProfile.additionalNotes);
    
    if (widget.userProfile.workoutPreferences != null) {
      _workoutPreferences.addAll(widget.userProfile.workoutPreferences!);
    }
  }

  @override
  void dispose() {
    _workoutDaysController.dispose();
    _workoutMinutesController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  void _saveData() {
    final updatedProfile = widget.userProfile.copyWith(
      indoorOutdoorPreference: _indoorOutdoorPreference,
      equipmentAccess: _equipmentAccess,
      workoutDaysPerWeek: _workoutDaysController.text,
      workoutMinutesPerSession: _workoutMinutesController.text,
      workoutPreferences: _workoutPreferences,
      additionalNotes: _additionalNotesController.text,
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
            title: 'Workout Preferences',
            subtitle: 'Tell us how you prefer to exercise',
          ),
          
          // Indoor/Outdoor preference
          Text(
            'Workout Environment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Column(
            children: AppConstants.indoorOutdoorOptions.map((option) {
              final isSelected = _indoorOutdoorPreference == option;
              final index = AppConstants.indoorOutdoorOptions.indexOf(option);
              
              IconData icon;
              String subtitle;
              
              switch (index) {
                case 0: // Indoor
                  icon = Icons.home;
                  subtitle = 'Gym or home workouts';
                  break;
                case 1: // Outdoor
                  icon = Icons.landscape;
                  subtitle = 'Parks, trails, or outdoor areas';
                  break;
                case 2: // Both
                  icon = Icons.compare_arrows;
                  subtitle = 'Mix of indoor and outdoor activities';
                  break;
                default:
                  icon = Icons.fitness_center;
                  subtitle = '';
              }
              
              return OptionCard(
                title: option,
                subtitle: subtitle,
                icon: icon,
                isSelected: isSelected,
                animationIndex: index,
                onTap: () {
                  setState(() {
                    _indoorOutdoorPreference = option;
                  });
                  _saveData();
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Equipment access
          Text(
            'Equipment Access',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Column(
            children: AppConstants.equipmentOptions.map((option) {
              final isSelected = _equipmentAccess == option;
              final index = AppConstants.equipmentOptions.indexOf(option);
              
              IconData icon;
              
              switch (index) {
                case 0: // None
                  icon = Icons.not_interested;
                  break;
                case 1: // Minimal
                  icon = Icons.fitness_center;
                  break;
                case 2: // Home gym
                  icon = Icons.home_work;
                  break;
                case 3: // Full gym
                  icon = Icons.fitness_center;
                  break;
                default:
                  icon = Icons.fitness_center;
              }
              
              return OptionCard(
                title: option,
                icon: icon,
                isSelected: isSelected,
                animationIndex: index + 4,
                onTap: () {
                  setState(() {
                    _equipmentAccess = option;
                  });
                  _saveData();
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 32),
          
          // Workout days and duration
          Row(
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Days Per Week',
                  hint: '3-5',
                  controller: _workoutDaysController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.calendar_today,
                  animationIndex: 9,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    
                    final days = int.tryParse(value);
                    if (days == null || days < 1 || days > 7) {
                      return 'Enter 1-7';
                    }
                    
                    return null;
                  },
                  onChanged: (_) => _saveData(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LabeledTextField(
                  label: 'Minutes Per Session',
                  hint: '30-120',
                  controller: _workoutMinutesController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.timelapse,
                  animationIndex: 10,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    }
                    
                    final minutes = int.tryParse(value);
                    if (minutes == null || minutes < 10 || minutes > 240) {
                      return 'Enter 10-240';
                    }
                    
                    return null;
                  },
                  onChanged: (_) => _saveData(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Additional notes
          LabeledTextField(
            label: 'Additional Workout Notes',
            hint: 'Any specific preferences or constraints?',
            helperText: 'For example: "I prefer morning workouts" or "I have limited time on weekends"',
            controller: _additionalNotesController,
            maxLines: 3,
            minLines: 2,
            animationIndex: 11,
            keyboardType: TextInputType.text,
            onChanged: (_) => _saveData(),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
} 