import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jeeva_fit_ai/providers/user_provider.dart';
import 'package:jeeva_fit_ai/providers/workout_provider.dart';
import 'package:jeeva_fit_ai/screens/profile/edit_profile_screen.dart';
import 'package:jeeva_fit_ai/widgets/theme_mode_toggle.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Helper method to get the appropriate image asset based on gender
  String _getProfileImageAsset(String? gender) {
    if (gender?.toLowerCase() == 'female') {
      return 'assets/images/women.png';
    } else {
      return 'assets/images/man.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProfile = userProvider.userProfile;
    
    // Initialize the workout provider when viewing profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      workoutProvider.initialize(force: true);
    });
    
    if (userProvider.isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }
    
    if (userProfile == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Animate(
                effects: const [
                  FadeEffect(duration: Duration(milliseconds: 600)),
                  SlideEffect(
                    begin: Offset(0, 30),
                    end: Offset.zero,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOutQuint,
                  ),
                ],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_circle_outlined,
                        size: 100,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'No Profile Found',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Create a profile to track your fitness journey',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Profile'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(240, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile header
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
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Center(
                                child: Hero(
                                  tag: 'profile_image',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.shadow.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: colorScheme.primaryContainer,
                                      backgroundImage: AssetImage(_getProfileImageAsset(userProfile.gender)),
                                    ),
                                  ),
                                ),
                              ),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: colorScheme.primary,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: colorScheme.onPrimary,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            userProfile.fullName ?? 'User',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userProfile.email ?? '',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats section
                Animate(
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 100)),
                    SlideEffect(
                      begin: Offset(0, 30),
                      end: Offset.zero,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOutQuint,
                      delay: Duration(milliseconds: 100),
                    ),
                  ],
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Stats',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                Icons.calendar_today_outlined,
                                userProfile.age ?? "N/A",
                                'Age',
                                colorScheme.primaryContainer,
                                colorScheme.primary,
                              ),
                              _buildStatItem(
                                context,
                                Icons.monitor_weight_outlined,
                                '${userProfile.weightKg ?? "N/A"} kg',
                                'Weight',
                                colorScheme.secondaryContainer,
                                colorScheme.secondary,
                              ),
                              _buildStatItem(
                                context,
                                Icons.height_outlined,
                                '${userProfile.heightCm ?? "N/A"} cm',
                                'Height',
                                colorScheme.tertiaryContainer,
                                colorScheme.tertiary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Personal Information
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
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Personal Information',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoListTile(
                            context,
                            'Gender',
                            userProfile.gender ?? 'Not specified',
                            Icons.people_outline,
                          ),
                          const Divider(height: 24),
                          _buildInfoListTile(
                            context,
                            'BMI',
                            _calculateBMI(userProfile.heightCm, userProfile.weightKg),
                            Icons.monitor_weight_outlined,
                          ),
                          if (userProfile.dailyActivityLevel != null) ...[
                            const Divider(height: 24),
                            _buildInfoListTile(
                              context,
                              'Activity Level',
                              userProfile.dailyActivityLevel!,
                              Icons.directions_walk,
                            ),
                          ],
                          if (userProfile.sleepHours != null) ...[
                            const Divider(height: 24),
                            _buildInfoListTile(
                              context,
                              'Sleep Hours',
                              '${userProfile.sleepHours} hours',
                              Icons.bedtime_outlined,
                            ),
                          ],
                          if (userProfile.stressLevel != null) ...[
                            const Divider(height: 24),
                            _buildInfoListTile(
                              context,
                              'Stress Level',
                              userProfile.stressLevel!,
                              Icons.psychology_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Fitness Information
                Animate(
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 300)),
                    SlideEffect(
                      begin: Offset(0, 30),
                      end: Offset.zero,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOutQuint,
                      delay: Duration(milliseconds: 300),
                    ),
                  ],
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fitness Information',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoListTile(
                            context,
                            'Fitness Level',
                            userProfile.fitnessLevel ?? 'Not specified',
                            Icons.fitness_center_outlined,
                          ),
                          const Divider(height: 24),
                          _buildInfoListTile(
                            context,
                            'Fitness Goal',
                            userProfile.primaryFitnessGoal ?? 'Not specified',
                            Icons.flag_outlined,
                          ),
                          const Divider(height: 24),
                          _buildInfoListTile(
                            context,
                            'Weekly Sessions',
                            userProfile.workoutDaysPerWeek ?? userProfile.weeklyExerciseDays ?? 'Not specified',
                            Icons.event_available_outlined,
                          ),
                          if (userProfile.workoutMinutesPerSession != null) ...[
                            const Divider(height: 24),
                            _buildInfoListTile(
                              context,
                              'Workout Duration',
                              '${userProfile.workoutMinutesPerSession} minutes',
                              Icons.timer_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Workout Preferences
                if (userProfile.workoutPreferences?.isNotEmpty == true ||
                    userProfile.indoorOutdoorPreference != null ||
                    userProfile.equipmentAccess != null) ...[
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
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Workout Preferences',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (userProfile.workoutPreferences?.isNotEmpty == true) ...[
                              _buildInfoItem(
                                'Favorite Workouts',
                                Text(
                                  userProfile.workoutPreferences!.join(', '),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Icons.fitness_center_outlined,
                                colorScheme,
                              ),
                              const Divider(height: 24),
                            ],
                            if (userProfile.indoorOutdoorPreference != null) ...[
                              _buildInfoListTile(
                                context,
                                'Location Preference',
                                userProfile.indoorOutdoorPreference!,
                                Icons.location_on_outlined,
                              ),
                              const Divider(height: 24),
                            ],
                            if (userProfile.equipmentAccess != null) ...[
                              _buildInfoListTile(
                                context,
                                'Equipment Access',
                                userProfile.equipmentAccess!,
                                Icons.sports_gymnastics_outlined,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Dietary Information
                if (userProfile.dietaryRestrictions?.isNotEmpty == true || 
                    userProfile.eatingHabits != null || 
                    userProfile.favoriteFoods != null || 
                    userProfile.avoidedFoods != null) ...[
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 500)),
                      SlideEffect(
                        begin: Offset(0, 30),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeOutQuint,
                        delay: Duration(milliseconds: 500),
                      ),
                    ],
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dietary Information',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (userProfile.dietaryRestrictions?.isNotEmpty == true) ...[
                              _buildInfoItem(
                                'Dietary Restrictions',
                                Text(
                                  userProfile.dietaryRestrictions!.join(', '),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Icons.no_food_outlined,
                                colorScheme,
                              ),
                              const Divider(height: 24),
                            ],
                            if (userProfile.eatingHabits != null) ...[
                              _buildInfoListTile(
                                context,
                                'Eating Habits',
                                userProfile.eatingHabits!,
                                Icons.restaurant_outlined,
                              ),
                              const Divider(height: 24),
                            ],
                            if (userProfile.favoriteFoods != null) ...[
                              _buildInfoItem(
                                'Favorite Foods',
                                Text(
                                  userProfile.favoriteFoods!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Icons.thumb_up_outlined,
                                colorScheme,
                              ),
                              const Divider(height: 24),
                            ],
                            if (userProfile.avoidedFoods != null) ...[
                              _buildInfoItem(
                                'Foods to Avoid',
                                Text(
                                  userProfile.avoidedFoods!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Icons.thumb_down_outlined,
                                colorScheme,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Medical Information
                if (userProfile.medicalConditions?.isNotEmpty == true || 
                    userProfile.medications != null || 
                    userProfile.fitnessConcerns != null) ...[
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 600)),
                      SlideEffect(
                        begin: Offset(0, 30),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeOutQuint,
                        delay: Duration(milliseconds: 600),
                      ),
                    ],
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Medical Information',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (userProfile.medicalConditions?.isNotEmpty == true) ...[
                              _buildInfoItem(
                                'Medical Conditions',
                                Text(
                                  userProfile.medicalConditions!.join(', '),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Icons.medical_information_outlined,
                                colorScheme,
                              ),
                              const Divider(height: 24),
                            ],
                            if (userProfile.medications != null) ...[
                              _buildInfoItem(
                                'Medications',
                                Text(
                                  userProfile.medications!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Icons.medication_outlined,
                                colorScheme,
                              ),
                              const Divider(height: 24),
                            ],
                            if (userProfile.fitnessConcerns != null) ...[
                              _buildInfoItem(
                                'Fitness Concerns',
                                Text(
                                  userProfile.fitnessConcerns!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                Icons.warning_amber_outlined,
                                colorScheme,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Additional Notes
                if (userProfile.additionalNotes != null) ...[
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 700)),
                      SlideEffect(
                        begin: Offset(0, 30),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeOutQuint,
                        delay: Duration(milliseconds: 700),
                      ),
                    ],
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Additional Notes',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EditProfileScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                userProfile.additionalNotes!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Edit Full Profile button
                Animate(
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 800)),
                    SlideEffect(
                      begin: Offset(0, 30),
                      end: Offset.zero,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOutQuint,
                      delay: Duration(milliseconds: 800),
                    ),
                  ],
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Full Profile'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                
                // Add padding at the bottom for spacing
                const SizedBox(height: 24),
                
                // Theme mode toggle
                Animate(
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 800)),
                    SlideEffect(
                      begin: Offset(0, 30),
                      end: Offset.zero,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOutQuint,
                      delay: Duration(milliseconds: 800),
                    ),
                  ],
                  child: const ThemeModeToggle(),
                ),
                
                const SizedBox(height: 32),
                
                // Sign out button
                Animate(
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 900)),
                    SlideEffect(
                      begin: Offset(0, 30),
                      end: Offset.zero,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOutQuint,
                      delay: Duration(milliseconds: 900),
                    ),
                  ],
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Sign Out'),
                            ),
                          ],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      );
                      
                      if (confirmed == true && context.mounted) {
                        await userProvider.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/auth');
                        }
                      }
                    },
                    icon: Icon(Icons.logout, color: colorScheme.error),
                    label: Text('Sign Out', style: TextStyle(color: colorScheme.error)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: BorderSide(color: colorScheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                
                // Add a section for workout plan management
                const SizedBox(height: 24),
                
                // Workout Plan Management
                Animate(
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 600), delay: Duration(milliseconds: 500)),
                    SlideEffect(
                      begin: Offset(0, 30),
                      end: Offset.zero,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOutQuint,
                      delay: Duration(milliseconds: 500),
                    ),
                  ],
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workout Plan Management',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Create or update your personalized workout plan',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: Consumer<WorkoutProvider>(
                              builder: (context, workoutProvider, _) {
                                final hasWorkoutPlan = workoutProvider.currentWorkoutPlan != null;
                                return FilledButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/workout/setup');
                                  },
                                  icon: const Icon(Icons.fitness_center),
                                  label: Text(hasWorkoutPlan ? 'Update Workout Plan' : 'Create Workout Plan'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color backgroundColor,
    Color iconColor,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
  
  Widget _buildInfoListTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
  
  String _calculateBMI(String? height, String? weight) {
    if (height == null || weight == null) {
      return 'N/A';
    }
    
    try {
      final heightM = double.parse(height) / 100;
      final weightKg = double.parse(weight);
      
      if (heightM <= 0) return 'N/A';
      
      final bmi = weightKg / (heightM * heightM);
      return bmi.toStringAsFixed(1);
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildInfoItem(
    String label,
    Widget child,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }
} 