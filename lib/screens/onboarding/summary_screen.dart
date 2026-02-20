import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jeeva_fit_ai/models/user_profile.dart';

class SummaryScreen extends StatelessWidget {
  final UserProfile userProfile;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const SummaryScreen({
    super.key,
    required this.userProfile,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Profile Summary',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Review your information before submission',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 32),

          // Profile image and name section
          Center(
            child: Column(
              children: [
                if (userProfile.progressPhotoUrl != null)
                  userProfile.progressPhotoUrl!.startsWith('http') 
                    ? CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(userProfile.progressPhotoUrl!),
                      )
                    : userProfile.progressPhotoUrl!.contains('default_avatar')
                      ? CircleAvatar(
                          radius: 60,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: colorScheme.primary,
                          ),
                        )
                      : CircleAvatar(
                          radius: 60,
                          backgroundImage: FileImage(File(userProfile.progressPhotoUrl!)),
                        )
                else
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: colorScheme.primary,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  userProfile.fullName ?? 'Your Name',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Personal Info Section
          _buildSection(
            context,
            'Personal Information',
            [
              _buildInfoRow('Age', userProfile.age ?? 'Not specified'),
              _buildInfoRow('Gender', userProfile.gender ?? 'Not specified'),
              _buildInfoRow(
                'Height',
                userProfile.heightCm != null 
                    ? '${userProfile.heightCm} cm' 
                    : 'Not specified'
              ),
              _buildInfoRow(
                'Weight',
                userProfile.weightKg != null 
                    ? '${userProfile.weightKg} kg' 
                    : 'Not specified'
              ),
            ],
          ),

          // Fitness Goals Section
          _buildSection(
            context,
            'Fitness Goals',
            [
              _buildInfoRow('Fitness Level', userProfile.fitnessLevel ?? 'Not specified'),
              _buildInfoRow('Primary Goal', userProfile.primaryFitnessGoal ?? 'Not specified'),
              _buildInfoRow('Specific Targets', userProfile.specificTargets ?? 'Not specified'),
              _buildInfoRow('Workout Days', userProfile.workoutDaysPerWeek ?? 'Not specified'),
              _buildInfoRow('Previous Experience', userProfile.previousProgramExperience ?? 'Not specified'),
            ],
          ),

          // Workout Preferences Section
          _buildSection(
            context,
            'Workout Preferences',
            [
              _buildInfoRow('Environment', userProfile.indoorOutdoorPreference ?? 'Not specified'),
              _buildInfoRow('Equipment Access', userProfile.equipmentAccess ?? 'Not specified'),
              _buildInfoRow(
                'Workout Duration',
                userProfile.workoutMinutesPerSession != null 
                    ? '${userProfile.workoutMinutesPerSession} minutes' 
                    : 'Not specified'
              ),
              _buildInfoRow(
                'Workout Types',
                userProfile.workoutPreferences != null && userProfile.workoutPreferences!.isNotEmpty
                    ? userProfile.workoutPreferences!.join(', ')
                    : 'Not specified'
              ),
            ],
          ),

          // Nutrition & Health Section
          _buildSection(
            context,
            'Nutrition & Health',
            [
              _buildInfoRow(
                'Dietary Restrictions', 
                userProfile.dietaryRestrictions != null && userProfile.dietaryRestrictions!.isNotEmpty 
                    ? userProfile.dietaryRestrictions!.join(', ') 
                    : 'None'
              ),
              _buildInfoRow('Daily Activity', userProfile.dailyActivityLevel ?? 'Not specified'),
              _buildInfoRow('Sleep Hours', userProfile.sleepHours ?? 'Not specified'),
              _buildInfoRow('Stress Level', userProfile.stressLevel ?? 'Not specified'),
              _buildInfoRow('Eating Habits', userProfile.eatingHabits ?? 'Not specified'),
              _buildInfoRow('Favorite Foods', userProfile.favoriteFoods ?? 'Not specified'),
              _buildInfoRow('Avoided Foods', userProfile.avoidedFoods ?? 'Not specified'),
              _buildInfoRow('Health Concerns', userProfile.fitnessConcerns ?? 'None'),
              _buildInfoRow(
                'Medical Conditions',
                userProfile.medicalConditions != null && userProfile.medicalConditions!.isNotEmpty
                    ? userProfile.medicalConditions!.join(', ')
                    : 'None'
              ),
              _buildInfoRow('Medications', userProfile.medications ?? 'None'),
            ],
          ),

          // AI Personalization
          _buildSection(
            context,
            'AI Personalization',
            [
              _buildInfoRow(
                'AI Suggestions',
                userProfile.aiSuggestionsEnabled == true ? 'Enabled' : 'Disabled'
              ),
              _buildInfoRow('Additional Notes', userProfile.additionalNotes ?? 'None'),
            ],
          ),

          const SizedBox(height: 40),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: isSubmitting 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Creating Profile...'),
                      ],
                    )
                  : const Text('Complete Profile'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const Divider(),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 