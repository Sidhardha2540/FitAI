import 'package:flutter/material.dart';
import 'package:jeeva_fit_ai/constants/app_constants.dart';
import 'package:jeeva_fit_ai/models/user_profile.dart';
import 'package:jeeva_fit_ai/widgets/onboarding_widgets.dart';

class NutritionHealthScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;

  const NutritionHealthScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<NutritionHealthScreen> createState() => _NutritionHealthScreenState();
}

class _NutritionHealthScreenState extends State<NutritionHealthScreen> {
  // Diet information
  late final TextEditingController _eatingHabitsController;
  late final TextEditingController _favoriteFoodsController;
  late final TextEditingController _avoidedFoodsController;
  
  // Health information
  late final TextEditingController _medicationsController;
  late final TextEditingController _fitnessConcernsController;
  String? _dailyActivityLevel;
  String? _sleepHours;
  String? _stressLevel;
  
  // Lists
  final List<String> _dietaryRestrictions = [];
  final List<String> _medicalConditions = [];
  
  // AI suggestions option
  bool _aiSuggestionsEnabled = true;

  @override
  void initState() {
    super.initState();
    _eatingHabitsController = TextEditingController(text: widget.userProfile.eatingHabits);
    _favoriteFoodsController = TextEditingController(text: widget.userProfile.favoriteFoods);
    _avoidedFoodsController = TextEditingController(text: widget.userProfile.avoidedFoods);
    _medicationsController = TextEditingController(text: widget.userProfile.medications);
    _fitnessConcernsController = TextEditingController(text: widget.userProfile.fitnessConcerns);
    
    _dailyActivityLevel = widget.userProfile.dailyActivityLevel;
    _sleepHours = widget.userProfile.sleepHours;
    _stressLevel = widget.userProfile.stressLevel;
    
    if (widget.userProfile.dietaryRestrictions != null) {
      _dietaryRestrictions.addAll(widget.userProfile.dietaryRestrictions!);
    }
    
    if (widget.userProfile.medicalConditions != null) {
      _medicalConditions.addAll(widget.userProfile.medicalConditions!);
    }
    
    _aiSuggestionsEnabled = widget.userProfile.aiSuggestionsEnabled ?? true;
  }

  @override
  void dispose() {
    _eatingHabitsController.dispose();
    _favoriteFoodsController.dispose();
    _avoidedFoodsController.dispose();
    _medicationsController.dispose();
    _fitnessConcernsController.dispose();
    super.dispose();
  }

  void _saveData() {
    final updatedProfile = widget.userProfile.copyWith(
      eatingHabits: _eatingHabitsController.text,
      favoriteFoods: _favoriteFoodsController.text,
      avoidedFoods: _avoidedFoodsController.text,
      medications: _medicationsController.text,
      fitnessConcerns: _fitnessConcernsController.text,
      dailyActivityLevel: _dailyActivityLevel,
      sleepHours: _sleepHours,
      stressLevel: _stressLevel,
      dietaryRestrictions: _dietaryRestrictions,
      medicalConditions: _medicalConditions,
      aiSuggestionsEnabled: _aiSuggestionsEnabled,
    );
    widget.onProfileUpdated(updatedProfile);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Nutrition & Health',
            subtitle: 'Tell us about your eating habits and health considerations',
          ),
          
          // Dietary restrictions
          SelectionChipGroup(
            title: 'Dietary Restrictions',
            options: AppConstants.dietaryRestrictionOptions,
            selectedOptions: _dietaryRestrictions,
            onSelectionChanged: (selectedOptions) {
              setState(() {
                _dietaryRestrictions.clear();
                _dietaryRestrictions.addAll(selectedOptions);
              });
              _saveData();
            },
            animationIndex: 1,
          ),
          
          const SizedBox(height: 24),
          
          // Eating habits
          LabeledTextField(
            label: 'Eating Habits',
            hint: 'Describe your typical meal pattern',
            helperText: 'For example: "I eat 3 meals a day with 2 snacks" or "I practice intermittent fasting"',
            controller: _eatingHabitsController,
            maxLines: 2,
            animationIndex: 2,
            onChanged: (_) => _saveData(),
          ),
          
          // Favorite foods & avoided foods
          Row(
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Favorite Foods',
                  hint: 'List foods you enjoy',
                  controller: _favoriteFoodsController,
                  maxLines: 2,
                  animationIndex: 3,
                  onChanged: (_) => _saveData(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: LabeledTextField(
                  label: 'Avoided Foods',
                  hint: 'List foods you avoid',
                  controller: _avoidedFoodsController,
                  maxLines: 2,
                  animationIndex: 4,
                  onChanged: (_) => _saveData(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Daily activity level
          Text(
            'Daily Activity Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Column(
            children: AppConstants.activityLevelOptions.map((level) {
              final isSelected = _dailyActivityLevel == level;
              final index = AppConstants.activityLevelOptions.indexOf(level);
              
              IconData icon;
              String subtitle;
              
              switch (index) {
                case 0: // Sedentary
                  icon = Icons.weekend;
                  subtitle = 'Little to no regular physical activity';
                  break;
                case 1: // Lightly active
                  icon = Icons.directions_walk;
                  subtitle = 'Light exercise 1-3 days per week';
                  break;
                case 2: // Moderate
                  icon = Icons.directions_run;
                  subtitle = 'Moderate exercise 3-5 days per week';
                  break;
                case 3: // Very active
                  icon = Icons.directions_bike;
                  subtitle = 'Hard exercise 6-7 days per week';
                  break;
                case 4: // Extremely active
                  icon = Icons.sports;
                  subtitle = 'Very hard exercise & physical job';
                  break;
                default:
                  icon = Icons.directions_walk;
                  subtitle = '';
              }
              
              return OptionCard(
                title: level,
                subtitle: subtitle,
                icon: icon,
                isSelected: isSelected,
                animationIndex: index + 5,
                onTap: () {
                  setState(() {
                    _dailyActivityLevel = level;
                  });
                  _saveData();
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Sleep hours
          Text(
            'Average Sleep Hours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['5', '6', '7', '8', '9', '10'].map((hours) {
              final isSelected = _sleepHours == hours;
              return ChoiceChip(
                label: Text(hours),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _sleepHours = hours;
                    });
                    _saveData();
                  }
                },
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Stress level
          Text(
            'Stress Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: AppConstants.stressLevelOptions.map((level) {
              final isSelected = _stressLevel == level;
              final index = AppConstants.stressLevelOptions.indexOf(level);
              
              IconData icon;
              Color color;
              
              switch (index) {
                case 0: // Low
                  icon = Icons.sentiment_satisfied;
                  color = Colors.green;
                  break;
                case 1: // Medium
                  icon = Icons.sentiment_neutral;
                  color = Colors.amber;
                  break;
                case 2: // High
                  icon = Icons.sentiment_dissatisfied;
                  color = Colors.red;
                  break;
                default:
                  icon = Icons.sentiment_neutral;
                  color = Colors.grey;
              }
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _stressLevel = level;
                  });
                  _saveData();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isSelected 
                            ? color 
                            : colorScheme.surfaceContainerHighest,
                        child: Icon(
                          icon, 
                          color: isSelected 
                              ? Colors.white 
                              : color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        level,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? color : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Medical concerns
          LabeledTextField(
            label: 'Fitness Concerns or Limitations',
            hint: 'Any injuries, conditions, or limitations we should know about?',
            controller: _fitnessConcernsController,
            maxLines: 3,
            animationIndex: 10,
            onChanged: (_) => _saveData(),
          ),
          
          // Medications
          LabeledTextField(
            label: 'Medications (Optional)',
            hint: 'Any medications that might affect your workouts?',
            controller: _medicationsController,
            maxLines: 2,
            animationIndex: 11,
            onChanged: (_) => _saveData(),
          ),
          
          // AI suggestions
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text(
              'AI Personalized Suggestions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: const Text('Allow AI to use your data for personalized workout and nutrition recommendations'),
            value: _aiSuggestionsEnabled,
            onChanged: (value) {
              setState(() {
                _aiSuggestionsEnabled = value;
              });
              _saveData();
            },
            secondary: Icon(
              _aiSuggestionsEnabled ? Icons.smart_toy : Icons.smart_toy_outlined,
              color: _aiSuggestionsEnabled ? colorScheme.primary : Colors.grey,
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
} 