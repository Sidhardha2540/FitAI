import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:jeeva_fit_ai/models/user_profile.dart';
import 'package:jeeva_fit_ai/providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _workoutMinutesController = TextEditingController();
  final _sleepHoursController = TextEditingController();
  final _favoritesFoodsController = TextEditingController();
  final _avoidedFoodsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _fitnessConcernsController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _specificTargetsController = TextEditingController();
  final _motivationController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedActivityLevel;
  String? _selectedFitnessLevel;
  String? _selectedFitnessGoal;
  String? _selectedWorkoutDays;
  String? _selectedEatingHabits;
  String? _selectedStressLevel;
  String? _selectedIndoorOutdoor;
  String? _selectedEquipmentAccess;
  List<String> _selectedDietaryRestrictions = [];
  List<String> _selectedWorkoutPreferences = [];
  List<String> _selectedMedicalConditions = [];
  bool _aiSuggestionsEnabled = true;
  
  bool _isLoading = false;
  bool _isNewUser = false;
  
  // Options for various dropdowns
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _activityLevelOptions = ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active', 'Extremely Active'];
  final List<String> _fitnessLevelOptions = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _fitnessGoalOptions = ['Lose Weight', 'Build Muscle', 'Improve Endurance', 'Increase Flexibility', 'Maintain Fitness'];
  final List<String> _workoutDaysOptions = ['1-2', '3-4', '5-6', 'Every day'];
  final List<String> _eatingHabitsOptions = ['Regular meals', 'Intermittent fasting', 'Small frequent meals', 'Irregular eating pattern'];
  final List<String> _stressLevelOptions = ['Low', 'Moderate', 'High', 'Very High'];
  final List<String> _indoorOutdoorOptions = ['Indoor', 'Outdoor', 'Both'];
  final List<String> _equipmentAccessOptions = ['None', 'Basic home equipment', 'Full gym access'];
  final List<String> _dietaryRestrictionOptions = [
    'Vegetarian', 'Vegan', 'Gluten-free', 'Dairy-free', 'Nut allergies', 
    'Pescatarian', 'Keto', 'Paleo', 'Low carb', 'Low fat', 'Halal', 'Kosher'
  ];
  final List<String> _workoutPreferenceOptions = [
    'Cardio', 'Strength training', 'Yoga', 'Pilates', 'HIIT', 
    'Running', 'Swimming', 'Cycling', 'Team sports', 'Dance', 'Martial arts'
  ];
  final List<String> _medicalConditionOptions = [
    'Asthma', 'Diabetes', 'Hypertension', 'Heart conditions', 'Joint issues',
    'Back pain', 'Arthritis', 'Pregnancy', 'Osteoporosis', 'None'
  ];

  // Helper to find matching option regardless of case sensitivity
  String? _findMatchingOption(String? value, List<String> options) {
    if (value == null) return null;
    
    // First try exact match
    if (options.contains(value)) {
      return value;
    }
    
    // Try case-insensitive match
    final lowercaseValue = value.toLowerCase();
    for (final option in options) {
      if (option.toLowerCase() == lowercaseValue) {
        return option;
      }
    }
    
    return null; // No match found
  }

  // Helper method to get the appropriate image asset based on gender
  String _getProfileImageAsset(String? gender) {
    if (gender?.toLowerCase() == 'female') {
      return 'assets/images/women.png';
    } else {
      return 'assets/images/man.png';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _workoutMinutesController.dispose();
    _sleepHoursController.dispose();
    _favoritesFoodsController.dispose();
    _avoidedFoodsController.dispose();
    _medicationsController.dispose();
    _fitnessConcernsController.dispose();
    _additionalNotesController.dispose();
    _specificTargetsController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userProfile = userProvider.userProfile;
    
    _isNewUser = userProfile == null;
    
    if (userProfile != null) {
      setState(() {
        _fullNameController.text = userProfile.fullName ?? '';
        _ageController.text = userProfile.age ?? '';
        _heightController.text = userProfile.heightCm ?? '';
        _weightController.text = userProfile.weightKg ?? '';
        _workoutMinutesController.text = userProfile.workoutMinutesPerSession ?? '';
        _sleepHoursController.text = userProfile.sleepHours ?? '';
        _favoritesFoodsController.text = userProfile.favoriteFoods ?? '';
        _avoidedFoodsController.text = userProfile.avoidedFoods ?? '';
        _medicationsController.text = userProfile.medications ?? '';
        _fitnessConcernsController.text = userProfile.fitnessConcerns ?? '';
        _additionalNotesController.text = userProfile.additionalNotes ?? '';
        _specificTargetsController.text = userProfile.specificTargets ?? '';
        _motivationController.text = userProfile.motivation ?? '';
        
        _selectedGender = _findMatchingOption(userProfile.gender, _genderOptions);
        _selectedActivityLevel = _findMatchingOption(userProfile.dailyActivityLevel, _activityLevelOptions);
        _selectedFitnessLevel = _findMatchingOption(userProfile.fitnessLevel, _fitnessLevelOptions);
        _selectedFitnessGoal = _findMatchingOption(userProfile.primaryFitnessGoal, _fitnessGoalOptions);
        _selectedWorkoutDays = _findMatchingOption(userProfile.workoutDaysPerWeek, _workoutDaysOptions);
        _selectedEatingHabits = _findMatchingOption(userProfile.eatingHabits, _eatingHabitsOptions);
        _selectedStressLevel = _findMatchingOption(userProfile.stressLevel, _stressLevelOptions);
        _selectedIndoorOutdoor = _findMatchingOption(userProfile.indoorOutdoorPreference, _indoorOutdoorOptions);
        _selectedEquipmentAccess = _findMatchingOption(userProfile.equipmentAccess, _equipmentAccessOptions);
        
        _selectedDietaryRestrictions = userProfile.dietaryRestrictions ?? [];
        _selectedWorkoutPreferences = userProfile.workoutPreferences ?? [];
        _selectedMedicalConditions = userProfile.medicalConditions ?? [];
        _aiSuggestionsEnabled = userProfile.aiSuggestionsEnabled ?? true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        final updatedProfile = UserProfile(
          fullName: _fullNameController.text.trim(),
          age: _ageController.text.trim(),
          gender: _selectedGender,
          heightCm: _heightController.text.trim(),
          weightKg: _weightController.text.trim(),
          workoutMinutesPerSession: _workoutMinutesController.text.trim(),
          sleepHours: _sleepHoursController.text.trim(),
          favoriteFoods: _favoritesFoodsController.text.trim(),
          avoidedFoods: _avoidedFoodsController.text.trim(),
          medications: _medicationsController.text.trim(),
          fitnessConcerns: _fitnessConcernsController.text.trim(),
          additionalNotes: _additionalNotesController.text.trim(),
          specificTargets: _specificTargetsController.text.trim(),
          motivation: _motivationController.text.trim(),
          
          dailyActivityLevel: _selectedActivityLevel,
          fitnessLevel: _selectedFitnessLevel,
          primaryFitnessGoal: _selectedFitnessGoal,
          workoutDaysPerWeek: _selectedWorkoutDays,
          eatingHabits: _selectedEatingHabits,
          stressLevel: _selectedStressLevel,
          indoorOutdoorPreference: _selectedIndoorOutdoor,
          equipmentAccess: _selectedEquipmentAccess,
          
          dietaryRestrictions: _selectedDietaryRestrictions.isNotEmpty ? _selectedDietaryRestrictions : null,
          workoutPreferences: _selectedWorkoutPreferences.isNotEmpty ? _selectedWorkoutPreferences : null,
          medicalConditions: _selectedMedicalConditions.isNotEmpty ? _selectedMedicalConditions : null,
          aiSuggestionsEnabled: _aiSuggestionsEnabled,
          
          email: userProvider.userProfile?.email,
          userId: userProvider.userProfile?.userId,
          id: userProvider.userProfile?.id,
          createdAt: userProvider.userProfile?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          progressPhotoUrl: userProvider.userProfile?.progressPhotoUrl,
        );
        
        if (_isNewUser) {
          await userProvider.createUserProfile(updatedProfile);
        } else {
          await userProvider.updateUserProfile(updatedProfile);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isNewUser ? 'Profile created successfully!' : 'Profile updated successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = userProvider.userProfile;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(_isNewUser ? 'Create Profile' : 'Edit Profile'),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: _saveProfile,
                icon: const Icon(Icons.check),
                tooltip: 'Save',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Form(
              key: _formKey,
              child: DefaultTabController(
                length: 5,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Basic Info'),
                        Tab(text: 'Fitness'),
                        Tab(text: 'Workout'),
                        Tab(text: 'Nutrition'),
                        Tab(text: 'Health'),
                      ],
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurfaceVariant,
                      indicatorColor: colorScheme.primary,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Basic Info Tab
                          _buildBasicInfoTab(colorScheme, textTheme, isDarkMode),
                          
                          // Fitness Tab
                          _buildFitnessTab(colorScheme, textTheme, isDarkMode),
                          
                          // Workout Tab
                          _buildWorkoutTab(colorScheme, textTheme, isDarkMode),
                          
                          // Nutrition Tab
                          _buildNutritionTab(colorScheme, textTheme, isDarkMode),
                          
                          // Health Tab
                          _buildHealthTab(colorScheme, textTheme, isDarkMode),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isLoading 
          ? null 
          : Container(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _saveProfile,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(_isNewUser ? 'Create Profile' : 'Save Changes'),
              ),
            ),
    );
  }
  
  Widget _buildBasicInfoTab(ColorScheme colorScheme, TextTheme textTheme, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo
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
            child: Center(
              child: Column(
                children: [
                  Hero(
                    tag: 'profile_image',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        image: _selectedGender != null
                            ? DecorationImage(
                                image: AssetImage(_getProfileImageAsset(_selectedGender)),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _selectedGender == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: colorScheme.onPrimaryContainer,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Profile Photo',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Based on gender selection',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Personal Information
          Text(
            'Personal Information',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Full Name
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Age
          _buildTextField(
            controller: _ageController,
            label: 'Age',
            prefixIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your age';
              }
              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                return 'Please enter a valid age';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Gender
          _buildDropdown(
            value: _selectedGender,
            label: 'Gender',
            items: _genderOptions,
            prefixIcon: Icons.people_outlined,
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Height
          _buildTextField(
            controller: _heightController,
            label: 'Height (cm)',
            prefixIcon: Icons.height_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your height';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Please enter a valid height';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Weight
          _buildTextField(
            controller: _weightController,
            label: 'Weight (kg)',
            prefixIcon: Icons.monitor_weight_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your weight';
              }
              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                return 'Please enter a valid weight';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildFitnessTab(ColorScheme colorScheme, TextTheme textTheme, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fitness Profile',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Activity Level
          _buildDropdown(
            value: _selectedActivityLevel,
            label: 'Daily Activity Level',
            items: _activityLevelOptions,
            prefixIcon: Icons.directions_walk_outlined,
            onChanged: (value) {
              setState(() {
                _selectedActivityLevel = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Fitness Level
          _buildDropdown(
            value: _selectedFitnessLevel,
            label: 'Fitness Level',
            items: _fitnessLevelOptions,
            prefixIcon: Icons.fitness_center_outlined,
            onChanged: (value) {
              setState(() {
                _selectedFitnessLevel = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Fitness Goal
          _buildDropdown(
            value: _selectedFitnessGoal,
            label: 'Primary Fitness Goal',
            items: _fitnessGoalOptions,
            prefixIcon: Icons.flag_outlined,
            onChanged: (value) {
              setState(() {
                _selectedFitnessGoal = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Specific Targets
          _buildTextField(
            controller: _specificTargetsController,
            label: 'Specific Targets (e.g., abs, arms)',
            prefixIcon: Icons.adjust_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          
          // Motivation
          _buildTextField(
            controller: _motivationController,
            label: 'What motivates you?',
            prefixIcon: Icons.emoji_emotions_outlined,
            maxLines: 3,
            helperText: 'What inspired you to start your fitness journey?',
          ),
          const SizedBox(height: 20),
          
          // Sleep Hours
          _buildTextField(
            controller: _sleepHoursController,
            label: 'Average Sleep Hours',
            prefixIcon: Icons.bedtime_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          
          // Stress Level
          _buildDropdown(
            value: _selectedStressLevel,
            label: 'Stress Level',
            items: _stressLevelOptions,
            prefixIcon: Icons.psychology_outlined,
            onChanged: (value) {
              setState(() {
                _selectedStressLevel = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // AI Suggestions Switch
          SwitchListTile(
            title: Text(
              'Enable AI Fitness Suggestions',
              style: textTheme.titleMedium,
            ),
            subtitle: Text(
              'Allow the app to suggest personalized workouts',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: _aiSuggestionsEnabled,
            onChanged: (value) {
              setState(() {
                _aiSuggestionsEnabled = value;
              });
            },
            activeColor: colorScheme.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutTab(ColorScheme colorScheme, TextTheme textTheme, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Preferences',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Workout Days Per Week
          _buildDropdown(
            value: _selectedWorkoutDays,
            label: 'Workout Days Per Week',
            items: _workoutDaysOptions,
            prefixIcon: Icons.event_available_outlined,
            onChanged: (value) {
              setState(() {
                _selectedWorkoutDays = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Workout Minutes Per Session
          _buildTextField(
            controller: _workoutMinutesController,
            label: 'Minutes Per Workout Session',
            prefixIcon: Icons.timer_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Indoor/Outdoor Preference
          _buildDropdown(
            value: _selectedIndoorOutdoor,
            label: 'Indoor/Outdoor Preference',
            items: _indoorOutdoorOptions,
            prefixIcon: Icons.location_on_outlined,
            onChanged: (value) {
              setState(() {
                _selectedIndoorOutdoor = value;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Equipment Access
          _buildDropdown(
            value: _selectedEquipmentAccess,
            label: 'Equipment Access',
            items: _equipmentAccessOptions,
            prefixIcon: Icons.sports_gymnastics_outlined,
            onChanged: (value) {
              setState(() {
                _selectedEquipmentAccess = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          // Workout Preferences (Multi-Select)
          Text(
            'Preferred Workouts',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _workoutPreferenceOptions.map((option) {
              final isSelected = _selectedWorkoutPreferences.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedWorkoutPreferences.add(option);
                    } else {
                      _selectedWorkoutPreferences.remove(option);
                    }
                  });
                },
                backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildNutritionTab(ColorScheme colorScheme, TextTheme textTheme, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Information',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Eating Habits
          _buildDropdown(
            value: _selectedEatingHabits,
            label: 'Eating Habits',
            items: _eatingHabitsOptions,
            prefixIcon: Icons.restaurant_outlined,
            onChanged: (value) {
              setState(() {
                _selectedEatingHabits = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          // Dietary Restrictions (Multi-Select)
          Text(
            'Dietary Restrictions',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dietaryRestrictionOptions.map((option) {
              final isSelected = _selectedDietaryRestrictions.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDietaryRestrictions.add(option);
                    } else {
                      _selectedDietaryRestrictions.remove(option);
                    }
                  });
                },
                backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          
          // Favorite Foods
          _buildTextField(
            controller: _favoritesFoodsController,
            label: 'Favorite Foods',
            prefixIcon: Icons.thumb_up_outlined,
            maxLines: 2,
            helperText: 'List some of your favorite foods',
          ),
          const SizedBox(height: 20),
          
          // Avoided Foods
          _buildTextField(
            controller: _avoidedFoodsController,
            label: 'Foods You Avoid',
            prefixIcon: Icons.thumb_down_outlined,
            maxLines: 2,
            helperText: 'List foods you prefer to avoid',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildHealthTab(ColorScheme colorScheme, TextTheme textTheme, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Information',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Medical Conditions (Multi-Select)
          Text(
            'Medical Conditions',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _medicalConditionOptions.map((option) {
              final isSelected = _selectedMedicalConditions.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedMedicalConditions.add(option);
                    } else {
                      _selectedMedicalConditions.remove(option);
                    }
                  });
                },
                backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          
          // Medications
          _buildTextField(
            controller: _medicationsController,
            label: 'Current Medications',
            prefixIcon: Icons.medication_outlined,
            maxLines: 2,
            helperText: 'List any medications that might affect your workouts',
          ),
          const SizedBox(height: 20),
          
          // Fitness Concerns
          _buildTextField(
            controller: _fitnessConcernsController,
            label: 'Fitness Concerns',
            prefixIcon: Icons.warning_amber_outlined,
            maxLines: 3,
            helperText: 'Any injuries or concerns we should know about?',
          ),
          const SizedBox(height: 32),
          
          // Additional Notes
          _buildTextField(
            controller: _additionalNotesController,
            label: 'Additional Notes',
            prefixIcon: Icons.note_outlined,
            maxLines: 4,
            helperText: 'Any other information you want to share',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? helperText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        prefixIconColor: colorScheme.primary,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        helperText: helperText,
        filled: true,
        fillColor: isDarkMode 
          ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
          : colorScheme.surfaceContainerHighest.withOpacity(0.1),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
  
  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required IconData prefixIcon,
    required Function(String?) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        prefixIconColor: colorScheme.primary,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: isDarkMode 
          ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
          : colorScheme.surfaceContainerHighest.withOpacity(0.1),
      ),
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
    );
  }
} 