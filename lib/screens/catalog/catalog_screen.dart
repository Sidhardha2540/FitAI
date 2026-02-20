import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jeeva_fit_ai/providers/user_provider.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Text(
                'Discover',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find your perfect workout plan',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search workouts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Categories section
              Text(
                'Categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Category chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip(context, 'All', true),
                    _buildCategoryChip(context, 'Strength', false),
                    _buildCategoryChip(context, 'Cardio', false),
                    _buildCategoryChip(context, 'Flexibility', false),
                    _buildCategoryChip(context, 'Recovery', false),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Workout grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                  children: [
                    _buildWorkoutCard(
                      context,
                      'Strength',
                      'Full Body',
                      Icons.fitness_center,
                      '25 min',
                      'Beginner',
                    ),
                    _buildWorkoutCard(
                      context,
                      'Cardio',
                      'HIIT Training',
                      Icons.bolt,
                      '30 min',
                      'Intermediate',
                    ),
                    _buildWorkoutCard(
                      context,
                      'Flexibility',
                      'Morning Yoga',
                      Icons.self_improvement,
                      '20 min',
                      'All levels',
                    ),
                    _buildWorkoutCard(
                      context,
                      'Recovery',
                      'Stretching',
                      Icons.accessibility_new,
                      '15 min',
                      'Beginner',
                    ),
                    _buildWorkoutCard(
                      context,
                      'Strength',
                      'Upper Body',
                      Icons.fitness_center,
                      '30 min',
                      'Intermediate',
                    ),
                    _buildWorkoutCard(
                      context,
                      'Cardio',
                      'Running Plan',
                      Icons.directions_run,
                      '45 min',
                      'Advanced',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryChip(BuildContext context, String label, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? colorScheme.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        onSelected: (bool value) {
          // Handle category selection
        },
      ),
    );
  }
  
  Widget _buildWorkoutCard(
    BuildContext context,
    String category,
    String title,
    IconData icon,
    String duration,
    String level,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout image/icon
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
          ),
          
          // Workout details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        level,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 