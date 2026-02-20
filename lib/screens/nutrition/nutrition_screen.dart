import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/nutrition_plan.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  late DateTime _currentWeekStart;
  
  @override
  void initState() {
    super.initState();
    // Set the date range to current week
    final now = DateTime.now();
    _currentWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    
    // Initialize tab controller for 7 days (Monday to Sunday)
    _tabController = TabController(length: 7, vsync: this);
    
    // Set the initial tab to today's weekday (1-7 for Monday-Sunday)
    _tabController.index = now.weekday - 1;
    
    // Initialize the nutrition provider and load existing nutrition plan
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('======= NUTRITION SCREEN INITIALIZATION =======');
      
      try {
        setState(() {
          _isLoading = true;
        });
        
        final nutritionProvider = Provider.of<NutritionProvider>(context, listen: false);
        
        // Force reinitialize to make sure we load the latest data
        debugPrint('Initializing nutrition provider...');
        await nutritionProvider.initialize(force: true);
        
        if (nutritionProvider.error != null) {
          debugPrint('Error loading nutrition plan: ${nutritionProvider.error}');
          _showErrorSnackBar(context, 'Error loading nutrition plan: ${nutritionProvider.error}');
        } else {
          debugPrint('Nutrition plan loaded: ${nutritionProvider.currentNutritionPlan != null}');
          
          if (nutritionProvider.currentNutritionPlan != null) {
            final plan = nutritionProvider.currentNutritionPlan!;
            debugPrint('Plan ID: ${plan.id}');
            debugPrint('Daily nutrition entries: ${plan.dailyNutrition.length}');
          }
        }
      } catch (e) {
        debugPrint('Exception during nutrition screen initialization: $e');
        _showErrorSnackBar(context, 'Error loading nutrition data. Please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
      
      debugPrint('======= NUTRITION SCREEN INITIALIZATION COMPLETE =======');
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Nutrition Plan',
          style: textTheme.titleLarge,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: List.generate(7, (index) {
              final date = _currentWeekStart.add(Duration(days: index));
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final dayName = DateFormat('EEE').format(date); // Mon, Tue, Wed, etc.
              final dayNumber = DateFormat('d').format(date); // 1, 2, etc.
              
              return Tab(
                height: 60,
                child: Container(
                  width: 45, // Smaller fixed width to avoid overflow
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: isToday ? BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ) : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          color: isToday ? colorScheme.onPrimaryContainer : null,
                          fontWeight: isToday ? FontWeight.bold : null,
                          fontSize: 11, // Smaller text to fit better
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // Smaller gap
                      Text(
                        dayNumber,
                        style: TextStyle(
                          color: isToday ? colorScheme.onPrimaryContainer : null,
                          fontSize: 13, // Slightly smaller
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, nutritionProvider, child) {
          if (nutritionProvider.isLoading || _isLoading) {
            return _buildLoadingView(context);
          }
          
          if (nutritionProvider.currentNutritionPlan == null) {
            return _buildNoNutritionPlanView(context);
          }
          
          // Display nutrition plan with tabs
          return TabBarView(
            controller: _tabController,
            children: List.generate(7, (index) {
              // weekday is 1-7 (Monday-Sunday)
              final day = index + 1;
              return _buildDailyNutritionView(context, day, nutritionProvider);
            }),
          );
        },
      ),
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your nutrition plan...',
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoNutritionPlanView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Animate(
        effects: const [
          FadeEffect(duration: Duration(milliseconds: 600)),
          SlideEffect(
            begin: Offset(0, 30),
            end: Offset.zero,
            duration: Duration(milliseconds: 800),
          ),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'No nutrition plan found',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Your nutrition plan hasn\'t been set up yet. Check back later when it\'s ready.',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailyNutritionView(BuildContext context, int day, NutritionProvider nutritionProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Get nutrition for selected day
    final dailyNutrition = nutritionProvider.getNutritionForDay(day);
    
    if (dailyNutrition == null) {
      return Center(
        child: Animate(
          effects: const [
            FadeEffect(duration: Duration(milliseconds: 400)),
          ],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.no_food,
                size: 56,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Nutrition Data',
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No nutrition data available for ${_getDayName(day)}',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Return nutrition view for this day
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Animate(
        effects: const [
          FadeEffect(duration: Duration(milliseconds: 400)),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily summary card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          dailyNutrition.workoutDay ? Icons.fitness_center : Icons.nights_stay,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dailyNutrition.dayName,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Chip(
                          label: Text(
                            dailyNutrition.workoutDay 
                                ? dailyNutrition.workoutType ?? 'Workout Day' 
                                : 'Rest Day'
                          ),
                          backgroundColor: dailyNutrition.workoutDay 
                              ? colorScheme.primaryContainer 
                              : colorScheme.surfaceVariant,
                          labelStyle: TextStyle(
                            color: dailyNutrition.workoutDay 
                                ? colorScheme.onPrimaryContainer 
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Calories and macro details row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutritionInfoItem(
                          context,
                          Icons.local_fire_department_outlined,
                          '${dailyNutrition.totalCalories}',
                          'Calories',
                        ),
                        _buildNutritionInfoItem(
                          context,
                          Icons.fitness_center_outlined,
                          dailyNutrition.workoutCaloriesBurned != null 
                              ? '${dailyNutrition.workoutCaloriesBurned}' 
                              : '0',
                          'Burned',
                        ),
                        _buildNutritionInfoItem(
                          context,
                          Icons.add_circle_outline,
                          '${dailyNutrition.calorieAdjustment}',
                          'Adjustment',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Macronutrients bar
                    Text(
                      'Macronutrients',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMacronutrientBar(context, dailyNutrition.macronutrients),
                    const SizedBox(height: 8),
                    
                    // Macronutrient details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroDetail(
                          context, 
                          'Carbs', 
                          '${dailyNutrition.macronutrients.carbohydrates.grams}g',
                          '${dailyNutrition.macronutrients.carbohydrates.percentage}%',
                          colorScheme.primary,
                        ),
                        _buildMacroDetail(
                          context, 
                          'Protein', 
                          '${dailyNutrition.macronutrients.protein.grams}g',
                          '${dailyNutrition.macronutrients.protein.percentage}%',
                          colorScheme.tertiary,
                        ),
                        _buildMacroDetail(
                          context, 
                          'Fats', 
                          '${dailyNutrition.macronutrients.fats.grams}g',
                          '${dailyNutrition.macronutrients.fats.percentage}%',
                          colorScheme.secondary,
                        ),
                      ],
                    ),
                    
                    // If there are special instructions, show them
                    if (dailyNutrition.specialInstructions != null && 
                        dailyNutrition.specialInstructions!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dailyNutrition.specialInstructions!,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Hydration section if available
            if (dailyNutrition.hydration != null) ...[
              Text(
                'Hydration',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dailyNutrition.hydration!.waterIntake,
                            style: textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (dailyNutrition.hydration!.electrolytesNeeded)
                            Chip(
                              label: const Text('Electrolytes'),
                              backgroundColor: colorScheme.tertiaryContainer,
                              labelStyle: TextStyle(
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                        ],
                      ),
                      if (dailyNutrition.hydration!.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          dailyNutrition.hydration!.notes,
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Meals section
            Text(
              'Meals (${dailyNutrition.meals.length})',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...dailyNutrition.meals.map((meal) => 
              _buildMealCard(context, meal),
            ).toList(),
            
            const SizedBox(height: 24),
            
            // Supplements section if available
            if (dailyNutrition.supplements != null && dailyNutrition.supplements!.isNotEmpty) ...[
              Text(
                'Supplements',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dailyNutrition.supplements!.map((supplement) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    supplement.name,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${supplement.dosage} - ${supplement.timing} (${supplement.purpose})',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 100), // Increased bottom padding to prevent navbar from blocking content
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, Meal meal) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Text(
          meal.name,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          meal.timing != null ? '${meal.timing} • ${meal.calories} kcal' : '${meal.calories} kcal',
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meal.notes != null && meal.notes!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.notes!,
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const Divider(),
          ],
          
          // Macro details for this meal
          if (meal.macros.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSimpleMacroDetail(context, 'Carbs', '${meal.macros['carbs'] ?? "--"}g'),
                _buildSimpleMacroDetail(context, 'Protein', '${meal.macros['protein'] ?? "--"}g'),
                _buildSimpleMacroDetail(context, 'Fats', '${meal.macros['fats'] ?? "--"}g'),
              ],
            ),
            const Divider(),
          ],
          
          // Foods in this meal
          const SizedBox(height: 8),
          Text(
            'Foods',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...meal.foods.map((food) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${food.calories}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (food.portion != null)
                          Text(
                            food.portion!,
                            style: textTheme.bodySmall,
                          ),
                        if (food.preparation != null)
                          Text(
                            food.preparation!,
                            style: textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildNutritionInfoItem(BuildContext context, IconData icon, String text, String label) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
  
  Widget _buildMacronutrientBar(BuildContext context, Macronutrients macros) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceVariant,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Carbs segment
          Flexible(
            flex: macros.carbohydrates.percentage,
            child: Container(
              color: colorScheme.primary,
            ),
          ),
          // Protein segment
          Flexible(
            flex: macros.protein.percentage,
            child: Container(
              color: colorScheme.tertiary,
            ),
          ),
          // Fats segment
          Flexible(
            flex: macros.fats.percentage,
            child: Container(
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroDetail(
    BuildContext context, 
    String label, 
    String value,
    String percentage,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          percentage,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildSimpleMacroDetail(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodySmall,
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown Day';
    }
  }
} 