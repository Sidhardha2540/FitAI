import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/nutrition_plan.dart';

class NutritionProvider extends ChangeNotifier {
  // Use a constant for collection name to ensure consistency
  static const String _nutritionPlansCollection = 'nutrition_plans';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  
  NutritionPlan? _currentNutritionPlan;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  NutritionPlan? get currentNutritionPlan => _currentNutritionPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Initialize the provider - should be called on app startup
  Future<void> initialize({bool force = false}) async {
    if (_auth.currentUser == null) return;
    
    if (_currentNutritionPlan == null || force) {
      debugPrint('==== INITIALIZING NUTRITION PROVIDER ====');
      debugPrint('Force initialize: $force');
      await loadCurrentNutritionPlan();
    }
  }
  
  // Load the current nutrition plan from Firestore
  Future<void> loadCurrentNutritionPlan() async {
    if (_auth.currentUser == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final userId = _auth.currentUser!.uid;
      debugPrint('====== LOADING NUTRITION PLAN ======');
      debugPrint('User ID: $userId');
      debugPrint('Collection: $_nutritionPlansCollection');
      
      // First attempt: Try to load a document with ID matching user ID (preferred approach)
      try {
        final docSnapshot = await _firestore
            .collection(_nutritionPlansCollection)
            .doc(userId)
            .get();
            
        if (docSnapshot.exists) {
          debugPrint('Found nutrition plan document with ID matching user ID: $userId');
          final data = docSnapshot.data() ?? {};
          
          try {
            _currentNutritionPlan = NutritionPlan.fromMap({
              ...data,
              'id': docSnapshot.id,
              'userId': userId, // Ensure userId is included
            });
            
            debugPrint('Successfully parsed NutritionPlan from document with ID=$userId');
            debugPrint('Plan has ${_currentNutritionPlan?.dailyNutrition.length ?? 0} daily nutrition entries');
            _isLoading = false;
            notifyListeners();
            return;
          } catch (e) {
            debugPrint('Error parsing nutrition plan from document with ID=$userId: $e');
            // Continue to try other methods
          }
        }
      } catch (e) {
        debugPrint('Error retrieving document with ID=$userId: $e');
      }
      
      // Second attempt: Query all nutrition plans for this user
      debugPrint('Querying for all nutrition plans for user: $userId');
      
      final querySnapshot = await _firestore
          .collection(_nutritionPlansCollection)
          .where('userId', isEqualTo: userId)
          .get();
          
      debugPrint('Total documents in $_nutritionPlansCollection collection: ${querySnapshot.docs.length}');
      
      if (querySnapshot.docs.isNotEmpty) {
        debugPrint('Found ${querySnapshot.docs.length} documents belonging to current user');
        
        // Use the most recent one if there are multiple
        final doc = querySnapshot.docs.first;
        debugPrint('Document ID: ${doc.id}');
        
        try {
          final data = doc.data();
          
          // Make sure we have the key fields
          if (data.containsKey('dailyNutrition')) {
            debugPrint('Document contains dailyNutrition field');
          }
          
          _currentNutritionPlan = NutritionPlan.fromMap({
            ...data,
            'id': doc.id,
            'userId': userId, // Ensure userId is included
          });
          
          debugPrint('Successfully parsed NutritionPlan with ${_currentNutritionPlan?.dailyNutrition.length ?? 0} daily nutrition entries');
        } catch (e) {
          debugPrint('Error parsing nutrition plan: $e');
          _error = 'Failed to parse nutrition plan: $e';
          _currentNutritionPlan = null;
        }
      } else {
        debugPrint('No nutrition plans found for user $userId');
        _currentNutritionPlan = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading nutrition plan: $e');
      _error = 'Failed to load nutrition plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
    
    debugPrint('====== NUTRITION PLAN LOADING COMPLETED ======');
  }

  // Create a new nutrition plan
  Future<void> createNutritionPlan(Map<String, dynamic> nutritionData) async {
    if (_auth.currentUser == null) {
      _error = 'You must be logged in to create a nutrition plan';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _auth.currentUser!.uid;
      debugPrint('Creating new nutrition plan for user: $userId');
      
      // Use the user ID as the document ID for easier direct access
      final nutritionPlanId = userId;
      
      // Add additional metadata and make sure userId is included
      final nutritionPlanData = {
        ...nutritionData,
        'userId': userId,
        'id': nutritionPlanId,
      };
      
      // Save to Firestore
      await _firestore
          .collection(_nutritionPlansCollection)
          .doc(nutritionPlanId)
          .set(nutritionPlanData);
      
      debugPrint('Nutrition plan saved successfully with ID: $nutritionPlanId');
      
      // Update local state
      try {
        _currentNutritionPlan = NutritionPlan.fromMap(nutritionPlanData);
        debugPrint('Local state updated with new nutrition plan');
      } catch (e) {
        debugPrint('Error parsing nutrition plan: $e');
        throw Exception('Error parsing nutrition plan: $e');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating nutrition plan: $e');
      _error = 'An error occurred while creating your nutrition plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing nutrition plan
  Future<void> updateNutritionPlan(String planId, Map<String, dynamic> updatedData) async {
    if (_auth.currentUser == null) {
      _error = 'You must be logged in to update a nutrition plan';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _auth.currentUser!.uid;
      debugPrint('Updating nutrition plan $planId for user: $userId');
      
      // Update in Firestore
      await _firestore
          .collection(_nutritionPlansCollection)
          .doc(planId)
          .update(updatedData);
      
      debugPrint('Nutrition plan updated successfully');
      
      // Reload the current plan to reflect changes
      await loadCurrentNutritionPlan();
    } catch (e) {
      debugPrint('Error updating nutrition plan: $e');
      _error = 'An error occurred while updating your nutrition plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a nutrition plan
  Future<void> deleteNutritionPlan(String planId) async {
    if (_auth.currentUser == null) {
      _error = 'You must be logged in to delete a nutrition plan';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Deleting nutrition plan with ID: $planId');
      
      await _firestore
          .collection(_nutritionPlansCollection)
          .doc(planId)
          .delete();
      
      debugPrint('Nutrition plan deleted successfully');
      
      // If we deleted the current plan, clear it from state
      if (_currentNutritionPlan?.id == planId) {
        _currentNutritionPlan = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting nutrition plan: $e');
      _error = 'An error occurred while deleting your nutrition plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear current plan
  void clearCurrentPlan() {
    _currentNutritionPlan = null;
    notifyListeners();
  }

  // Get nutrition for the specified day (1-7 for Monday-Sunday)
  DailyNutrition? getNutritionForDay(int day) {
    if (_currentNutritionPlan == null) return null;
    return _currentNutritionPlan!.getNutritionForDay(day);
  }
  
  // Get today's nutrition
  DailyNutrition? getTodaysNutrition() {
    if (_currentNutritionPlan == null) return null;
    return _currentNutritionPlan!.getTodaysNutrition();
  }
  
  // Get a list of all meals for the given day
  List<Meal> getMealsForDay(int day) {
    final dailyNutrition = getNutritionForDay(day);
    if (dailyNutrition == null) return [];
    return dailyNutrition.meals;
  }
  
  // Get total calorie requirements
  Map<String, dynamic>? getTotalDailyCalories() {
    return _currentNutritionPlan?.totalDailyCalories;
  }
  
  // Get user's dietary restrictions
  String? getDietaryRestrictions() {
    return _currentNutritionPlan?.dietaryRestrictions;
  }
  
  // Get allergies
  List<String> getAllergies() {
    return _currentNutritionPlan?.allergies ?? [];
  }
} 