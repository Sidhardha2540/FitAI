import 'package:flutter/foundation.dart';

class NutritionPlan {
  final String id;
  final String userId;
  final String? dietType;
  final String? dietaryRestrictions;
  final String? nutritionGoal;
  final double? proteinPerKg;
  final List<String> allergies; 
  final Map<String, dynamic>? totalDailyCalories;
  final List<DailyNutrition> dailyNutrition;

  NutritionPlan({
    required this.id,
    required this.userId,
    this.dietType,
    this.dietaryRestrictions,
    this.nutritionGoal,
    this.proteinPerKg,
    required this.allergies,
    this.totalDailyCalories,
    required this.dailyNutrition,
  });

  factory NutritionPlan.fromMap(Map<String, dynamic> map) {
    try {
      debugPrint('Parsing NutritionPlan from map with keys: ${map.keys.toList()}');
      
      // Parse allergies
      final List<String> allergiesList = [];
      if (map['allergies'] != null && map['allergies'] is List) {
        for (var allergy in map['allergies']) {
          if (allergy is String) {
            allergiesList.add(allergy);
          }
        }
      }
      
      // Parse daily nutrition
      final List<DailyNutrition> dailyNutritionList = [];
      if (map['dailyNutrition'] != null && map['dailyNutrition'] is List) {
        for (var dailyNutr in map['dailyNutrition']) {
          if (dailyNutr is Map<String, dynamic>) {
            try {
              dailyNutritionList.add(DailyNutrition.fromMap(dailyNutr));
            } catch (e) {
              debugPrint('Error parsing daily nutrition: $e');
            }
          }
        }
      }
      
      return NutritionPlan(
        id: map['id']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        dietType: map['dietType']?.toString(),
        dietaryRestrictions: map['dietaryRestrictions']?.toString(),
        nutritionGoal: map['nutritionGoal']?.toString(),
        proteinPerKg: map['proteinPerKg'] is num ? (map['proteinPerKg'] as num).toDouble() : null,
        allergies: allergiesList,
        totalDailyCalories: map['totalDailyCalories'] is Map ? Map<String, dynamic>.from(map['totalDailyCalories']) : null,
        dailyNutrition: dailyNutritionList,
      );
    } catch (e) {
      debugPrint('Error parsing NutritionPlan: $e');
      debugPrint('Problematic map: $map');
      // Return a default plan in case of error
      return NutritionPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        dietType: 'Unknown',
        dietaryRestrictions: 'None specified',
        nutritionGoal: 'Maintain',
        proteinPerKg: 1.6,
        allergies: [],
        totalDailyCalories: {
          "restDaysAvg": 2000,
          "workoutDaysAvg": 2350
        },
        dailyNutrition: [],
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'dietType': dietType,
      'dietaryRestrictions': dietaryRestrictions,
      'nutritionGoal': nutritionGoal, 
      'proteinPerKg': proteinPerKg,
      'allergies': allergies,
      'totalDailyCalories': totalDailyCalories,
      'dailyNutrition': dailyNutrition.map((dn) => dn.toMap()).toList(),
    };
  }
  
  // Get a specific day's nutrition
  DailyNutrition? getNutritionForDay(int day) {
    try {
      return dailyNutrition.firstWhere(
        (dn) => dn.day == day,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Get today's nutrition
  DailyNutrition? getTodaysNutrition() {
    final now = DateTime.now();
    final today = now.weekday; // weekday is 1-7 for Mon-Sun
    
    return getNutritionForDay(today);
  }
}

class DailyNutrition {
  final int day;
  final String dayName;
  final int calorieAdjustment;
  final bool workoutDay;
  final String? workoutType;
  final int totalCalories;
  final int? workoutCaloriesBurned;
  final Macronutrients macronutrients;
  final Hydration? hydration;
  final List<Meal> meals;
  final List<dynamic> micronutrients;
  final String? specialInstructions;
  final List<Supplement>? supplements;

  DailyNutrition({
    required this.day,
    required this.dayName,
    required this.calorieAdjustment,
    required this.workoutDay,
    this.workoutType,
    required this.totalCalories,
    this.workoutCaloriesBurned,
    required this.macronutrients,
    this.hydration,
    required this.meals,
    required this.micronutrients,
    this.specialInstructions,
    this.supplements,
  });

  factory DailyNutrition.fromMap(Map<String, dynamic> map) {
    try {
      // Parse meals
      final List<Meal> mealsList = [];
      if (map['meals'] != null && map['meals'] is List) {
        for (var meal in map['meals']) {
          if (meal is Map<String, dynamic>) {
            try {
              mealsList.add(Meal.fromMap(meal));
            } catch (e) {
              debugPrint('Error parsing meal: $e');
            }
          }
        }
      }
      
      // Parse supplements
      final List<Supplement> supplementsList = [];
      if (map['supplements'] != null && map['supplements'] is List) {
        for (var supp in map['supplements']) {
          if (supp is Map<String, dynamic>) {
            try {
              supplementsList.add(Supplement.fromMap(supp));
            } catch (e) {
              debugPrint('Error parsing supplement: $e');
            }
          }
        }
      }
      
      return DailyNutrition(
        day: map['day'] is int ? map['day'] : 1,
        dayName: map['dayName']?.toString() ?? 'Monday',
        calorieAdjustment: map['calorieAdjustment'] is int ? map['calorieAdjustment'] : 0,
        workoutDay: map['workoutDay'] is bool ? map['workoutDay'] : false,
        workoutType: map['workoutType']?.toString(),
        totalCalories: map['totalCalories'] is int ? map['totalCalories'] : 2000,
        workoutCaloriesBurned: map['workoutCaloriesBurned'] is int ? map['workoutCaloriesBurned'] : null,
        macronutrients: map['macronutrients'] is Map<String, dynamic> 
            ? Macronutrients.fromMap(map['macronutrients']) 
            : Macronutrients.defaultValues(),
        hydration: map['hydration'] is Map<String, dynamic> 
            ? Hydration.fromMap(map['hydration']) 
            : null,
        meals: mealsList,
        micronutrients: map['micronutrients'] is List ? List<dynamic>.from(map['micronutrients']) : [],
        specialInstructions: map['specialInstructions']?.toString(),
        supplements: supplementsList.isNotEmpty ? supplementsList : null,
      );
    } catch (e) {
      debugPrint('Error parsing DailyNutrition: $e');
      return DailyNutrition(
        day: 1,
        dayName: 'Error',
        calorieAdjustment: 0,
        workoutDay: false,
        totalCalories: 2000,
        macronutrients: Macronutrients.defaultValues(),
        meals: [],
        micronutrients: [],
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'dayName': dayName,
      'calorieAdjustment': calorieAdjustment,
      'workoutDay': workoutDay,
      'workoutType': workoutType,
      'totalCalories': totalCalories,
      'workoutCaloriesBurned': workoutCaloriesBurned,
      'macronutrients': macronutrients.toMap(),
      'hydration': hydration?.toMap(),
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'micronutrients': micronutrients,
      'specialInstructions': specialInstructions,
      'supplements': supplements?.map((supp) => supp.toMap()).toList(),
    };
  }
}

class Macronutrients {
  final MacronutrientDetails carbohydrates;
  final MacronutrientDetails fats;
  final MacronutrientDetails protein;

  Macronutrients({
    required this.carbohydrates,
    required this.fats,
    required this.protein,
  });

  factory Macronutrients.fromMap(Map<String, dynamic> map) {
    return Macronutrients(
      carbohydrates: map['carbohydrates'] is Map<String, dynamic> 
          ? MacronutrientDetails.fromMap(map['carbohydrates']) 
          : MacronutrientDetails.defaultValues('carbohydrates'),
      fats: map['fats'] is Map<String, dynamic> 
          ? MacronutrientDetails.fromMap(map['fats']) 
          : MacronutrientDetails.defaultValues('fats'),
      protein: map['protein'] is Map<String, dynamic> 
          ? MacronutrientDetails.fromMap(map['protein']) 
          : MacronutrientDetails.defaultValues('protein'),
    );
  }

  factory Macronutrients.defaultValues() {
    return Macronutrients(
      carbohydrates: MacronutrientDetails.defaultValues('carbohydrates'),
      fats: MacronutrientDetails.defaultValues('fats'),
      protein: MacronutrientDetails.defaultValues('protein'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carbohydrates': carbohydrates.toMap(),
      'fats': fats.toMap(),
      'protein': protein.toMap(),
    };
  }
}

class MacronutrientDetails {
  final int grams;
  final int percentage;
  final List<String> sources;

  MacronutrientDetails({
    required this.grams,
    required this.percentage,
    required this.sources,
  });

  factory MacronutrientDetails.fromMap(Map<String, dynamic> map) {
    final List<String> sourcesList = [];
    if (map['sources'] != null && map['sources'] is List) {
      for (var source in map['sources']) {
        if (source is String) {
          sourcesList.add(source);
        }
      }
    }

    return MacronutrientDetails(
      grams: map['grams'] is int ? map['grams'] : 0,
      percentage: map['percentage'] is int ? map['percentage'] : 0,
      sources: sourcesList,
    );
  }

  factory MacronutrientDetails.defaultValues(String type) {
    switch (type) {
      case 'carbohydrates':
        return MacronutrientDetails(
          grams: 200,
          percentage: 50,
          sources: ['Rice', 'Oats', 'Vegetables', 'Fruit'],
        );
      case 'fats':
        return MacronutrientDetails(
          grams: 65,
          percentage: 20,
          sources: ['Olive oil', 'Nuts', 'Avocado'],
        );
      case 'protein':
        return MacronutrientDetails(
          grams: 120,
          percentage: 30,
          sources: ['Chicken', 'Whey Protein', 'Eggs', 'Lentils'],
        );
      default:
        return MacronutrientDetails(
          grams: 0,
          percentage: 0,
          sources: [],
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'grams': grams,
      'percentage': percentage,
      'sources': sources,
    };
  }
}

class Hydration {
  final String waterIntake;
  final bool electrolytesNeeded;
  final String notes;

  Hydration({
    required this.waterIntake,
    required this.electrolytesNeeded,
    required this.notes,
  });

  factory Hydration.fromMap(Map<String, dynamic> map) {
    return Hydration(
      waterIntake: map['waterIntake']?.toString() ?? '3 liters',
      electrolytesNeeded: map['electrolytesNeeded'] is bool ? map['electrolytesNeeded'] : false,
      notes: map['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waterIntake': waterIntake,
      'electrolytesNeeded': electrolytesNeeded,
      'notes': notes,
    };
  }
}

class Meal {
  final String name;
  final String? timing;
  final String? notes;
  final int calories;
  final List<Food> foods;
  final Map<String, dynamic> macros;

  Meal({
    required this.name,
    this.timing,
    this.notes,
    required this.calories,
    required this.foods,
    required this.macros,
  });

  factory Meal.fromMap(Map<String, dynamic> map) {
    // Parse foods
    final List<Food> foodsList = [];
    if (map['foods'] != null && map['foods'] is List) {
      for (var food in map['foods']) {
        if (food is Map<String, dynamic>) {
          try {
            foodsList.add(Food.fromMap(food));
          } catch (e) {
            debugPrint('Error parsing food: $e');
          }
        }
      }
    }

    return Meal(
      name: map['name']?.toString() ?? 'Meal',
      timing: map['timing']?.toString(),
      notes: map['notes']?.toString(),
      calories: map['calories'] is int ? map['calories'] : 0,
      foods: foodsList,
      macros: map['macros'] is Map ? Map<String, dynamic>.from(map['macros']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'timing': timing,
      'notes': notes,
      'calories': calories,
      'foods': foods.map((food) => food.toMap()).toList(),
      'macros': macros,
    };
  }
}

class Food {
  final String name;
  final String? portion;
  final String? preparation;
  final int calories;
  final Map<String, dynamic> macros;

  Food({
    required this.name,
    this.portion,
    this.preparation,
    required this.calories,
    required this.macros,
  });

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      name: map['name']?.toString() ?? 'Food',
      portion: map['portion']?.toString(),
      preparation: map['preparation']?.toString(),
      calories: map['calories'] is int ? map['calories'] : 0,
      macros: map['macros'] is Map ? Map<String, dynamic>.from(map['macros']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'portion': portion,
      'preparation': preparation,
      'calories': calories,
      'macros': macros,
    };
  }
}

class Supplement {
  final String name;
  final String dosage;
  final String purpose;
  final String timing;

  Supplement({
    required this.name,
    required this.dosage,
    required this.purpose,
    required this.timing,
  });

  factory Supplement.fromMap(Map<String, dynamic> map) {
    return Supplement(
      name: map['name']?.toString() ?? 'Supplement',
      dosage: map['dosage']?.toString() ?? '',
      purpose: map['purpose']?.toString() ?? '',
      timing: map['timing']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'purpose': purpose,
      'timing': timing,
    };
  }
}

// Utility class to format macronutrient information
class MacronutrientInfo {
  static String formatMacroAmount(Map<String, dynamic> macro, String name) {
    final grams = macro['grams'];
    final percent = macro['percentOfCalories'];
    
    if (grams != null && percent != null) {
      return "$grams g ($percent% of calories)";
    } else if (grams != null) {
      return "$grams g";
    } else if (percent != null) {
      return "$percent% of calories";
    } else {
      return "Not specified";
    }
  }
  
  static String getMacroNote(Map<String, dynamic> macro) {
    return macro['note']?.toString() ?? '';
  }
}

// Utility class to format micronutrient information
class MicronutrientInfo {
  static String formatImportance(String importance) {
    switch (importance.toLowerCase()) {
      case 'high':
        return '⭐⭐⭐';
      case 'medium':
        return '⭐⭐';
      case 'low':
        return '⭐';
      default:
        return '';
    }
  }
} 