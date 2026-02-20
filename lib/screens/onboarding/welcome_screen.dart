import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // App Logo/Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.fitness_center,
              size: 60,
              color: colorScheme.onPrimary,
            ),
          ).animate().scale(
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
          ),
          
          const SizedBox(height: 40),
          
          // Welcome Title
          Text(
            'Welcome to My Fit AI',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 200),
          ).slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            'Your AI-powered fitness companion that adapts to your lifestyle',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 400),
          ).slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 60),
          
          // Features List
          Expanded(
            child: Column(
              children: [
                _buildFeatureItem(
                  context,
                  icon: Icons.psychology,
                  title: 'AI Personal Trainer',
                  description: 'Get personalized workout plans and real-time coaching',
                  delay: 600,
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(
                  context,
                  icon: Icons.track_changes,
                  title: 'Smart Progress Tracking',
                  description: 'Monitor your fitness journey with detailed analytics',
                  delay: 800,
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(
                  context,
                  icon: Icons.restaurant_menu,
                  title: 'Nutrition Guidance',
                  description: 'Receive meal plans tailored to your fitness goals',
                  delay: 1000,
                ),
                const SizedBox(height: 24),
                _buildFeatureItem(
                  context,
                  icon: Icons.health_and_safety,
                  title: 'Health Integration',
                  description: 'Sync with Apple Health and Google Fit seamlessly',
                  delay: 1200,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Getting Started Message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Let\'s set up your profile to create the perfect fitness plan for you!',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 1400),
          ).slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int delay,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
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
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: delay),
    ).slideX(begin: -0.3, end: 0);
  }
} 