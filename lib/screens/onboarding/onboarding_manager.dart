import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jeeva_fit_ai/models/user_profile.dart';
import 'package:jeeva_fit_ai/providers/user_provider.dart';
import 'package:jeeva_fit_ai/screens/onboarding/welcome_screen.dart';
import 'package:jeeva_fit_ai/screens/onboarding/personal_info_screen.dart';
import 'package:jeeva_fit_ai/screens/onboarding/fitness_goals_screen.dart';
import 'package:jeeva_fit_ai/screens/onboarding/workout_preferences_screen.dart';
import 'package:jeeva_fit_ai/screens/onboarding/nutrition_health_screen.dart';
import 'package:jeeva_fit_ai/screens/onboarding/summary_screen.dart';
import 'package:jeeva_fit_ai/widgets/onboarding_widgets.dart';
import 'package:jeeva_fit_ai/screens/home/home_screen.dart';

class OnboardingManager extends StatefulWidget {
  const OnboardingManager({super.key});

  @override
  State<OnboardingManager> createState() => _OnboardingManagerState();
}

class _OnboardingManagerState extends State<OnboardingManager> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final int _totalPages = 6;
  
  // User profile data
  UserProfile _userProfile = UserProfile();
  
  // Page indicators
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveUserProfile() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // First check if there's a profile image to upload
      String? photoUrl;
      if (userProvider.profileImage != null) {
        // Upload the image first
        photoUrl = await userProvider.uploadProfileImage();
        
        photoUrl ??= '👤 default_avatar';
      } else {
        // No image selected, use placeholder
        photoUrl = '👤 default_avatar';
      }
      
      // Create user profile
      final completeProfile = _userProfile.copyWith(
        progressPhotoUrl: photoUrl,
      );
      
      // Save to database
      final success = await userProvider.createUserProfile(completeProfile);
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        // Navigate to home screen
        if (mounted) {
          // Navigate to the main app screen after successful profile creation
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to save profile. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveUserProfile();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateProfile(UserProfile updatedProfile) {
    setState(() {
      _userProfile = updatedProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingProgress(
              currentStep: _currentPage + 1,
              totalSteps: _totalPages,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  const WelcomeScreen(),
                  PersonalInfoScreen(
                    userProfile: _userProfile,
                    onProfileUpdated: _updateProfile,
                  ),
                  FitnessGoalsScreen(
                    userProfile: _userProfile,
                    onProfileUpdated: _updateProfile,
                  ),
                  WorkoutPreferencesScreen(
                    userProfile: _userProfile,
                    onProfileUpdated: _updateProfile,
                  ),
                  NutritionHealthScreen(
                    userProfile: _userProfile,
                    onProfileUpdated: _updateProfile,
                  ),
                  SummaryScreen(
                    userProfile: _userProfile,
                    isSubmitting: _isLoading,
                    onSubmit: _saveUserProfile,
                  ),
                ],
              ),
            ),
            OnboardingActionButtons(
              onNext: _nextPage,
              onBack: _previousPage,
              isLastStep: _currentPage == _totalPages - 1,
              isFirstStep: _currentPage == 0,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
} 