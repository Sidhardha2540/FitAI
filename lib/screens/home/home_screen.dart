import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:jeeva_fit_ai/providers/user_provider.dart';
import 'package:jeeva_fit_ai/providers/workout_provider.dart';
import 'package:jeeva_fit_ai/screens/onboarding/onboarding_manager.dart';
import 'package:jeeva_fit_ai/screens/profile/profile_screen.dart';
import 'package:jeeva_fit_ai/screens/progress/progress_screen.dart';
import 'package:jeeva_fit_ai/screens/workout/workout_details_screen.dart';
import 'package:jeeva_fit_ai/services/workout_log_service.dart';
import 'package:jeeva_fit_ai/widgets/bottom_nav_bar.dart';
import 'package:jeeva_fit_ai/screens/workout/workout_screen.dart';
import 'package:jeeva_fit_ai/screens/workout/exercise_logs_screen.dart';
import 'package:jeeva_fit_ai/screens/nutrition/nutrition_screen.dart';
import 'package:jeeva_fit_ai/screens/chat/ai_chat_screen.dart';
import 'package:jeeva_fit_ai/screens/health/health_dashboard_screen.dart';
import 'package:jeeva_fit_ai/models/workout_log.dart';
import 'package:jeeva_fit_ai/models/workout_plan.dart';
import 'package:jeeva_fit_ai/models/health_data.dart';
import 'package:jeeva_fit_ai/models/exercise_log.dart';
import 'package:jeeva_fit_ai/widgets/floating_chat_button.dart';
import 'package:jeeva_fit_ai/services/exercise_log_service.dart';
import 'package:jeeva_fit_ai/services/health_data_service.dart';
import 'package:jeeva_fit_ai/widgets/loading_widgets.dart';

// Forward declaration to avoid circular imports
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  
  @override
  State<AuthPage> createState() => throw UnimplementedError();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Random _random = Random();
  final List<String> _robotImages = [
    'assets/images/robo1.png',
    'assets/images/robo2.png',
    'assets/images/robo3.png',
  ];

  // Pages for the bottom navigation
  late List<Widget> _pages;
  bool _initialized = false;
  WorkoutLog? _todaysWorkoutLog;
  bool _isLoadingLog = false;

  // Service instances
  final WorkoutLogService _workoutLogService = WorkoutLogService();
  final HealthDataService _healthDataService = HealthDataService();
  final ExerciseLogService _exerciseLogService = ExerciseLogService();

  // Health data state
  DailyHealthSummary? _todaysHealthSummary;
  bool _isLoadingHealthData = false;
  
  // Today's exercise logs state
  List<ExerciseLogEntry> _todaysExerciseLogs = [];
  bool _isLoadingExerciseLogs = false;

  @override
  void initState() {
    super.initState();
    _checkForTodaysWorkoutLog();
    _loadTodaysHealthData();
    _loadTodaysExerciseLogs();
  }
  
  Future<void> _checkForTodaysWorkoutLog() async {
    setState(() {
      _isLoadingLog = true;
    });
    
    try {
      final workoutLogService = WorkoutLogService();
      final log = await workoutLogService.getTodaysWorkoutLog();
      
      setState(() {
        _todaysWorkoutLog = log;
        _isLoadingLog = false;
      });
    } catch (e) {
      debugPrint('Error loading today\'s workout log: $e');
      setState(() {
        _isLoadingLog = false;
      });
    }
  }
  
  Future<void> _loadTodaysHealthData() async {
    setState(() {
      _isLoadingHealthData = true;
    });
    
    try {
      final today = DateTime.now();
      
      // Load Health Connect data
      final healthSummary = await _healthDataService.getDailyHealthSummary(today);
      
      setState(() {
        _todaysHealthSummary = healthSummary;
        _isLoadingHealthData = false;
      });
    } catch (e) {
      debugPrint('Error loading health data: $e');
      setState(() {
        _isLoadingHealthData = false;
      });
    }
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
  
  // Refresh all today's data
  Future<void> _refreshTodaysData() async {
    await Future.wait([
      _checkForTodaysWorkoutLog(),
      _loadTodaysHealthData(),
      _loadTodaysExerciseLogs(),
    ]);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _pages = [
        _buildHomeContent(),  // Index 0: Home
        const WorkoutScreen(), // Index 1: Workouts
        const ProgressScreen(), // Index 2: Progress
        const NutritionScreen(), // Index 3: Nutrition
      ];
      _initialized = true;
    }
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  void _onBottomNavTap(int index) {
    // Since we removed profile from nav bar, we only handle 0-3
    setState(() {
      _currentIndex = index;
    });
  }

  String _getRandomRobotImage() {
    return _robotImages[_random.nextInt(_robotImages.length)];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  String _getMotivationalMessage() {
    final messages = [
      "Every workout brings you closer to your goals! 💪",
      "Your body can do it. It's your mind you need to convince! 🧠",
      "Progress, not perfection. Keep moving forward! 🚀",
      "The only bad workout is the one that didn't happen! ⭐",
      "Your future self will thank you for today's effort! 🌟",
      "Small steps daily lead to big changes yearly! 📈",
      "Believe in yourself and all that you are! ✨",
    ];
    return messages[_random.nextInt(messages.length)];
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProvider = Provider.of<UserProvider>(context);

    // Initialize user provider and check for profile
    // Use a one-time post-frame callback to avoid infinite rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Only run this check if we're not already loading
      if (!userProvider.isLoading && !userProvider.hasProfile) {
        await userProvider.initialize();
        
        // Check again after initialization
        if (context.mounted && !userProvider.hasProfile) {
          print("No profile found, navigating to onboarding");
          // If no profile exists, navigate to onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const OnboardingManager(),
            ),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Main content
          userProvider.isLoading 
        ? const LoadingWidget(
            message: 'Setting up your fitness journey...',
          )
        : _pages[_currentIndex],
            
          // Floating navigation bar
          AppBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTap,
          ),
        ],
      ),
    );
  }
  
  // Home tab content
  Widget _buildHomeContent() {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final workoutProvider = Provider.of<WorkoutProvider>(context);
        final todaysWorkout = workoutProvider.todaysWorkout;
        
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              toolbarHeight: 64,
              backgroundColor: colorScheme.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'MyFitAI',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.menu,
                    color: colorScheme.onSurface,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                        break;
                      case 'settings':
                        // TODO: Add settings screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings coming soon!')),
                        );
                        break;
                      case 'help':
                        // TODO: Add help screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Help coming soon!')),
                        );
                        break;
                      case 'logout':
                        _signOut(context);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          const Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          const Text('Settings'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'help',
                      child: Row(
                        children: [
                          Icon(Icons.help_outline, color: colorScheme.onSurface),
                          const SizedBox(width: 12),
                          const Text('Help & Support'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: colorScheme.error),
                          const SizedBox(width: 12),
                          Text(
                            'Sign Out',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting section
                    Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 600)),
                        SlideEffect(
                          begin: Offset(0, 30),
                          duration: Duration(milliseconds: 600),
                        ),
                      ],
                      child: Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          final profile = userProvider.userProfile;
                          final currentUser = FirebaseAuth.instance.currentUser;
                          
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primaryContainer.withOpacity(0.8),
                                  colorScheme.secondaryContainer.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Profile Avatar
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primary,
                                            colorScheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: profile?.progressPhotoUrl != null && 
                                             profile!.progressPhotoUrl!.startsWith('http')
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: Image.network(
                                              profile.progressPhotoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  color: colorScheme.onPrimary,
                                                  size: 30,
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            color: colorScheme.onPrimary,
                                            size: 30,
                                          ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getGreeting(),
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            profile?.fullName ?? currentUser?.displayName ?? 'Fitness Enthusiast',
                                            style: textTheme.headlineSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Notification/Streak indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            color: colorScheme.primary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '7', // TODO: Calculate actual streak
                                            style: textTheme.labelMedium?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Motivational message or quick stats
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.psychology,
                                        color: colorScheme.primary,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _getMotivationalMessage(),
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions Section
                    Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 600)),
                        SlideEffect(
                          begin: Offset(0, 30),
                          duration: Duration(milliseconds: 600),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  context,
                                  icon: Icons.psychology,
                                  title: 'AI Coach',
                                  subtitle: 'Get instant advice',
                                  color: colorScheme.primary,
                                  onTap: () => Navigator.pushNamed(context, '/chat'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionCard(
                                  context,
                                  icon: Icons.fitness_center,
                                  title: 'Start Workout',
                                  subtitle: 'Begin training',
                                  color: colorScheme.secondary,
                                  onTap: () => setState(() => _currentIndex = 1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  context,
                                  icon: Icons.restaurant_menu,
                                  title: 'Meal Plan',
                                  subtitle: 'Track nutrition',
                                  color: colorScheme.tertiary,
                                  onTap: () => setState(() => _currentIndex = 3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionCard(
                                  context,
                                  icon: Icons.trending_up,
                                  title: 'Progress',
                                  subtitle: 'View stats',
                                  color: colorScheme.outline,
                                  onTap: () => setState(() => _currentIndex = 2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Today's Workout Section - shows either workout log (if completed) or today's workout plan
                    if (_isLoadingLog) 
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: LoadingWidget(
                          message: 'Loading workout progress...',
                          showMessage: false,
                        ),
                      )
                    else if (_todaysWorkoutLog != null) 
                      _buildTodaysWorkoutLogCard(context, _todaysWorkoutLog!)
                    else if (todaysWorkout != null) 
                      _buildTodaysWorkoutCard(context, todaysWorkout),
                    
                    const SizedBox(height: 24),
                    
                    // Today's Exercise Logs Section - shows real-time exercise progress
                    if (_isLoadingExerciseLogs)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: LoadingWidget(
                          message: 'Loading today\'s exercises...',
                          showMessage: false,
                        ),
                      )
                    else if (_todaysExerciseLogs.isNotEmpty)
                      _buildTodaysExerciseLogsCard(context, _todaysExerciseLogs),
                    
                    const SizedBox(height: 24),
                    
                    // Health Summary Section
                    Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 600)),
                        SlideEffect(
                          begin: Offset(0, 30),
                          duration: Duration(milliseconds: 600),
                        ),
                      ],
                      child: _buildHealthSummarySection(context),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Activity Section
                    Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 600)),
                        SlideEffect(
                          begin: Offset(0, 30),
                          duration: Duration(milliseconds: 600),
                        ),
                      ],
                      child: _buildProgressSection(context),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // AI Recommendations Section
                    Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 600)),
                        SlideEffect(
                          begin: Offset(0, 30),
                          duration: Duration(milliseconds: 600),
                        ),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Recommendations',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: colorScheme.primary,
                                        child: Icon(
                                          Icons.psychology,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'AI Fitness Coach',
                                              style: textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Get personalized fitness advice, diet tips, and workout guidance',
                                              style: textTheme.bodyMedium?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const AIChatScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.chat_outlined),
                                      label: const Text('Chat Now'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Bottom padding to prevent navbar from blocking content
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Today's workout card
  Widget _buildTodaysWorkoutCard(BuildContext context, DailyWorkout workout) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Animate(
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
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getWorkoutTypeIcon(workout.type),
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY\'S WORKOUT',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workout.name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${workout.type} • ${workout.exercises.length} exercises • ${workout.duration}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Show the first 3 exercises as a preview
              if (workout.exercises.isNotEmpty) ...[
                ...workout.exercises.take(3).map((exercise) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${exercise.sets} × ${exercise.reps}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                if (workout.exercises.length > 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${workout.exercises.length - 3} more exercises',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WorkoutDetailsScreen(
                              workout: workout,
                              workoutDate: DateTime.now(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showLogWorkoutDialog(context, workout),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Log'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Today's workout log card - shows progress for today's workout
  Widget _buildTodaysWorkoutLogCard(BuildContext context, WorkoutLog workoutLog) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Count total sets and completed sets across all exercises
    int totalSets = 0;
    int completedSets = 0;
    
    for (final exercise in workoutLog.exercises) {
      totalSets += exercise.sets.length;
      completedSets += exercise.sets.where((set) => set.isCompleted).length;
    }
    
    // Calculate completion percentage
    final completionPercentage = totalSets > 0 ? (completedSets / totalSets * 100).round() : 0;
    
    return Animate(
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
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.done_all,
                      color: colorScheme.onSecondaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY\'S PROGRESS',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workoutLog.workoutName,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${workoutLog.workoutType} • ${workoutLog.exercises.length} exercises • ${workoutLog.duration}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completion',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$completionPercentage%',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: totalSets > 0 ? completedSets / totalSets : 0,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedSets of $totalSets sets completed',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Show exercises with their progress
              if (workoutLog.exercises.isNotEmpty) ...[
                Text(
                  'Exercise Progress',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...workoutLog.exercises.take(3).map((exercise) {
                  // Calculate progress for this exercise
                  final exerciseCompletedSets = exercise.sets.where((set) => set.isCompleted).length;
                  final exerciseTotalSets = exercise.sets.length;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '$exerciseCompletedSets/$exerciseTotalSets',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: exerciseCompletedSets == exerciseTotalSets 
                                  ? Colors.green 
                                  : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (exercise.sets.any((set) => set.weight != null && set.weight! > 0)) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Wrap(
                              spacing: 8,
                              children: exercise.sets
                                .where((set) => set.isCompleted && set.weight != null && set.weight! > 0)
                                .take(3)
                                .map((set) {
                                  return Chip(
                                    label: Text(
                                      '${set.weight} kg × ${set.reps}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                    backgroundColor: colorScheme.secondaryContainer,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                
                if (workoutLog.exercises.length > 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${workoutLog.exercises.length - 3} more exercises',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExerciseLogsScreen()),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View History'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // Try to find the workout in the workout provider
                        final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
                        final workout = workoutProvider.todaysWorkout;
                        
                        if (workout != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkoutDetailsScreen(
                                workout: workout,
                                workoutDate: DateTime.now(),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Update'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Method to show the log workout dialog
  void _showLogWorkoutDialog(BuildContext context, DailyWorkout workout) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final workoutLogService = WorkoutLogService();
    String? notes;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log Completed Workout',
          style: textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark this workout as complete:',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              workout.name,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Date: $formattedDate',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How did this workout feel?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                notes = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.secondary),
            ),
          ),
          FilledButton(
            onPressed: () async {
              // Close dialog first
              Navigator.of(context).pop();
              
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logging workout...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              // Log the workout
              final success = await workoutLogService.logCompletedWorkout(
                workout: workout,
                completedDate: now,
                notes: notes,
              );
              
              if (context.mounted) {
                if (success) {
                  // Refresh the workout log
                  _checkForTodaysWorkoutLog();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Workout logged successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to log workout. Please try again.'),
                      backgroundColor: colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            child: Text(
              'Log Workout',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
        ],
      ),
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

  // Placeholder screen for sections under development
  Widget _buildPlaceholderScreen(String title, String message) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<List<ExerciseLogEntry>>(
      future: ExerciseLogService().getRecentExerciseLogs(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final logs = snapshot.data!;
          
          // Group logs by date to show workout sessions
          final Map<String, List<ExerciseLogEntry>> logsByDate = {};
          for (final log in logs) {
            final dateStr = DateFormat('yyyy-MM-dd').format(log.date);
            if (!logsByDate.containsKey(dateStr)) {
              logsByDate[dateStr] = [];
            }
            logsByDate[dateStr]!.add(log);
          }
          
          final sessionDates = logsByDate.keys.take(3).toList();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ExerciseLogsScreen()),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sessionDates.length,
                  itemBuilder: (context, index) {
                    final dateStr = sessionDates[index];
                    final sessionLogs = logsByDate[dateStr]!;
                    final date = DateTime.parse(dateStr);
                    
                    // Calculate session stats
                    final totalSets = sessionLogs.fold<int>(0, (sum, log) => sum + log.sets.length);
                    final completedSets = sessionLogs.fold<int>(0, (sum, log) => 
                        sum + log.sets.where((set) => set.isCompleted).length);
                    
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 16),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Workout Session',
                                          style: textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          DateFormat('MMM d, yyyy').format(date),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.fitness_center_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${sessionLogs.length} exercises',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.check_circle_outlined,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$completedSets/$totalSets sets',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHealthSummarySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Summary',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HealthDashboardScreen()),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingHealthData)
          Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
            ),
          )
        else if (_todaysHealthSummary != null)
          _buildHealthSummaryCard(context)
        else
          _buildHealthConnectCard(context),
      ],
    );
  }

  Widget _buildHealthConnectCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
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
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.health_and_safety_outlined,
                    color: colorScheme.onSecondaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONNECT HEALTH DATA',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track Your Health Metrics',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Connect your Apple Health or Google Fit to automatically track steps, calories, heart rate, and more.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HealthDashboardScreen()),
                  );
                },
                icon: const Icon(Icons.link),
                label: const Text('Connect Health Data'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummaryCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final summary = _todaysHealthSummary!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Today\'s Health Summary',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.verified,
                  color: Colors.green,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    context,
                    'Steps',
                    '${summary.steps}',
                    Icons.directions_walk,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    context,
                    'Calories',
                    '${summary.caloriesBurned.toInt()}',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    context,
                    'Distance',
                    '${summary.distance.toStringAsFixed(1)} km',
                    Icons.straighten,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    context,
                    'Heart Rate',
                    summary.averageHeartRate != null 
                        ? '${summary.averageHeartRate!.toInt()} bpm'
                        : 'N/A',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
              ],
            ),
            if (summary.moveMinutes > 0 || summary.heartPoints > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (summary.moveMinutes > 0)
                    Expanded(
                      child: _buildHealthMetric(
                        context,
                        'Move Minutes',
                        '${summary.moveMinutes}',
                        Icons.timer,
                        colorScheme.primary,
                      ),
                    ),
                  if (summary.moveMinutes > 0 && summary.heartPoints > 0)
                    const SizedBox(width: 16),
                  if (summary.heartPoints > 0)
                    Expanded(
                      child: _buildHealthMetric(
                        context,
                        'Heart Points',
                        '${summary.heartPoints}',
                        Icons.favorite_border,
                        Colors.red,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthDashboardScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Health Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  foregroundColor: colorScheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildHealthMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
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
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Today's exercise logs card - shows real-time progress for individual exercises
  Widget _buildTodaysExerciseLogsCard(BuildContext context, List<ExerciseLogEntry> exerciseLogs) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Calculate overall progress
    int totalSets = 0;
    int completedSets = 0;
    
    for (final log in exerciseLogs) {
      totalSets += log.sets.length;
      completedSets += log.sets.where((set) => set.isCompleted).length;
    }
    
    final completionPercentage = totalSets > 0 ? (completedSets / totalSets * 100).round() : 0;
    
    return Animate(
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
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: colorScheme.onTertiaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY\'S EXERCISE LOGS',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live Workout Progress',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exerciseLogs.length} exercises logged • $completedSets/$totalSets sets',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Progress bar
              if (totalSets > 0) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Overall Progress',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$completionPercentage%',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: completedSets / totalSets,
                        backgroundColor: colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.tertiary),
                        minHeight: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Individual exercise progress
              Text(
                'Exercise Details',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ...exerciseLogs.take(4).map((log) {
                final exerciseCompletedSets = log.sets.where((set) => set.isCompleted).length;
                final exerciseTotalSets = log.sets.length;
                final isCompleted = exerciseCompletedSets == exerciseTotalSets;
                
                // Get the latest completed set with weight
                final latestWeightedSet = log.sets
                    .where((set) => set.isCompleted && set.weight != null && set.weight! > 0)
                    .lastOrNull;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCompleted 
                        ? colorScheme.tertiaryContainer.withOpacity(0.3)
                        : colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: isCompleted 
                        ? Border.all(color: colorScheme.tertiary.withOpacity(0.3))
                        : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 20,
                              color: isCompleted ? colorScheme.tertiary : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                log.exerciseName,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted ? colorScheme.tertiary : null,
                                ),
                              ),
                            ),
                            Text(
                              '$exerciseCompletedSets/$exerciseTotalSets',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: exerciseCompletedSets == exerciseTotalSets 
                                  ? Colors.green 
                                  : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        
                        if (latestWeightedSet != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(width: 32),
                              Icon(
                                Icons.fitness_center,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Latest: ${latestWeightedSet.weight} kg × ${latestWeightedSet.reps} reps',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Show completed sets as chips
                        if (log.sets.where((set) => set.isCompleted).isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: log.sets
                                .where((set) => set.isCompleted)
                                .take(6) // Show max 6 sets to avoid overflow
                                .map((set) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      set.weight != null && set.weight! > 0
                                        ? '${set.weight}kg × ${set.reps}'
                                        : '${set.reps} reps',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
              
              if (exerciseLogs.length > 4) ...[
                const SizedBox(height: 8),
                Text(
                  '+ ${exerciseLogs.length - 4} more exercises',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExerciseLogsScreen()),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('View All Logs'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 1; // Switch to Workouts tab
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Log Exercise'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.tertiary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 