import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_plan.dart';
import '../models/user_profile.dart';

class WorkoutProvider extends ChangeNotifier {
  // Use a constant for collection name to ensure consistency
  static const String _workoutPlansCollection = 'workoutPlans';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  
  WorkoutPlan? _currentWorkoutPlan;
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  bool _initialized = false;
  
  // Getters
  WorkoutPlan? get currentWorkoutPlan => _currentWorkoutPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  
  // Get today's workout for easy access
  DailyWorkout? get todaysWorkout => getWorkoutForDate(DateTime.now());
  
  // Get all workouts for the current week
  List<DailyWorkout> get weeklyWorkouts => _currentWorkoutPlan?.workouts ?? [];
  
  // Get selected workout days as List<int> (1 = Monday, 7 = Sunday)
  List<int> get selectedWorkoutDays {
    final days = <int>[];
    if (_currentWorkoutPlan != null) {
      for (final workout in _currentWorkoutPlan!.workouts) {
        if (workout.type.toLowerCase() != 'rest') {
          days.add(workout.day);
        }
      }
    }
    return days;
  }
  
  // Set selected date for calendar view
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  // Initialize the provider - should be called on app startup
  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) {
      debugPrint('WorkoutProvider already initialized, skipping initialization');
      return;
    }
    
    debugPrint('==== INITIALIZING WORKOUT PROVIDER ====');
    debugPrint('Force initialize: $force');
    
    if (_auth.currentUser == null) {
      debugPrint('No authenticated user found. Skipping workout plan loading.');
      return;
    }
    
    final userId = _auth.currentUser!.uid;
    debugPrint('Authenticated user found. User ID: $userId');
    debugPrint('Loading current workout plan from database...');
    
    try {
      await loadCurrentWorkoutPlan();
      
      if (_currentWorkoutPlan != null) {
        debugPrint('Successfully loaded workout plan with ID: ${_currentWorkoutPlan!.id}');
        debugPrint('Plan contains ${_currentWorkoutPlan!.workouts.length} workouts');
        debugPrint('First workout: ${_currentWorkoutPlan!.workouts.isNotEmpty ? _currentWorkoutPlan!.workouts.first.name : "None"}');
      } else {
        debugPrint('No workout plan found in database for user: $userId');
      }
    } catch (e) {
      debugPrint('Error during workout provider initialization: $e');
    }
    
    _initialized = true;
    debugPrint('==== WORKOUT PROVIDER INITIALIZATION COMPLETE ====');
  }
  
  // Load the current workout plan from Firestore
  Future<void> loadCurrentWorkoutPlan() async {
    if (_auth.currentUser == null) {
      debugPrint('Cannot load workout plan: No authenticated user');
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final userId = _auth.currentUser!.uid;
      debugPrint('====== LOADING WORKOUT PLAN ======');
      debugPrint('User ID: $userId');
      debugPrint('Collection: $_workoutPlansCollection');
      
      // Debug query to check all documents in the collection
      try {
        final allDocs = await _firestore.collection(_workoutPlansCollection).get();
        debugPrint('Total documents in $_workoutPlansCollection collection: ${allDocs.docs.length}');
        
        if (allDocs.docs.isNotEmpty) {
          // Look for documents that match this user's ID to debug
          final userDocs = allDocs.docs.where((doc) => 
              doc.data()['userId'] == userId).toList();
          
          debugPrint('Found ${userDocs.length} documents belonging to current user');
          
          for (var doc in userDocs) {
            debugPrint('Document ID: ${doc.id}');
            debugPrint('Created At: ${doc.data()['createdAt']}');
          }
        }
      } catch (e) {
        debugPrint('Error checking collection: $e');
      }
      
      // First attempt: Try using document ID as user ID directly
      try {
        final docSnapshot = await _firestore
            .collection(_workoutPlansCollection)
            .doc(userId)
            .get();
        
        if (docSnapshot.exists) {
          debugPrint('Found workout plan document with ID matching user ID: $userId');
          final data = docSnapshot.data() ?? {};
          
          // Use this document if it has workout data
          if (_isValidWorkoutData(data)) {
            try {
              _currentWorkoutPlan = WorkoutPlan.fromMap({
                ...data,
                'id': docSnapshot.id,
              });
              
              debugPrint('Successfully parsed WorkoutPlan with ID=${docSnapshot.id}');
              _isLoading = false;
              notifyListeners();
              return;
            } catch (e) {
              debugPrint('Error parsing workout plan from document with ID=$userId: $e');
            }
          } else {
            debugPrint('Document exists but does not contain valid workout data. Trying alternative queries.');
          }
        } else {
          debugPrint('No document found with ID matching user ID: $userId. Trying alternative queries.');
        }
      } catch (e) {
        debugPrint('Error retrieving document with ID=$userId: $e');
      }
      
      // Second attempt: Query with where + orderBy approach (requires index)
      debugPrint('Trying query with where + orderBy...');
      try {
        final query = _firestore
            .collection(_workoutPlansCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(1);
        
        final snapshot = await query.get();
        
        debugPrint('Query complete. Found ${snapshot.docs.length} documents');
        
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data();
          final planId = doc.id;
          
          debugPrint('Found workout plan with ID: $planId');
          debugPrint('Plan Data Keys: ${data.keys.toList()}');
          
          // Check if data contains required fields
          if (_isValidWorkoutData(data)) {
            try {
              _currentWorkoutPlan = WorkoutPlan.fromMap({
                ...data,
                'id': planId,
              });
              
              if (_currentWorkoutPlan!.workouts.isEmpty) {
                debugPrint('WARNING: Parsed workout plan has no workouts. This might indicate a data issue.');
              } else {
                debugPrint('Successfully parsed WorkoutPlan with ${_currentWorkoutPlan!.workouts.length} workouts');
                debugPrint('First workout: ${_currentWorkoutPlan!.workouts.first.name}');
              }
            } catch (e) {
              debugPrint('Error parsing workout plan: $e');
              _error = 'Failed to parse workout plan: $e';
              _currentWorkoutPlan = null;
            }
          } else {
            debugPrint('Workout plan data does not contain required fields');
            _error = 'Workout plan data is missing required fields';
            _currentWorkoutPlan = null;
          }
        } else {
          debugPrint('No workout plan found for user $userId');
          _currentWorkoutPlan = null;
        }
      } catch (e) {
        final errorMsg = e.toString();
        
        // Check if this is a missing index error
        if (errorMsg.contains('FAILED_PRECONDITION') && errorMsg.contains('index')) {
          debugPrint('Missing Firestore index for compound query. Error: $errorMsg');
          _error = 'Firestore index required. Please check logs for details.';
          
          // Fallback to query without orderBy (no index needed)
          debugPrint('Using fallback query without orderBy...');
          final fallbackQuery = _firestore
              .collection(_workoutPlansCollection)
              .where('userId', isEqualTo: userId);
          
          final fallbackSnapshot = await fallbackQuery.get();
          
          if (fallbackSnapshot.docs.isNotEmpty) {
            // Just get the first one - not ideal but works as a fallback
            final doc = fallbackSnapshot.docs.first;
            final data = doc.data();
            final planId = doc.id;
            
            try {
              _currentWorkoutPlan = WorkoutPlan.fromMap({
                ...data,
                'id': planId,
              });
              debugPrint('Successfully loaded workout plan via fallback query');
            } catch (e) {
              debugPrint('Error parsing workout plan from fallback query: $e');
              _currentWorkoutPlan = null;
            }
          }
        } else {
          debugPrint('Error loading workout plan: $e');
          _error = 'Failed to load workout plan: ${e.toString()}';
          _currentWorkoutPlan = null;
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading workout plan: $e');
      _error = 'Failed to load workout plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Helper method to check if data is valid workout data
  bool _isValidWorkoutData(Map<String, dynamic> data) {
    // At minimum, we need the workoutPlan field to consider this valid
    if (!data.containsKey('workoutPlan')) {
      // Special case: check if the document has workouts field instead
      if (data.containsKey('workouts') && data['workouts'] is List) {
        debugPrint('Found "workouts" field instead of "workoutPlan" field - can adapt to this format');
        return true;
      }
      
      // Check if it contains individual day fields like monday, tuesday, etc.
      final dayFields = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      bool hasDayFields = dayFields.any((day) => data.containsKey(day));
      if (hasDayFields) {
        debugPrint('Found day-based workout structure - can adapt to this format');
        return true;
      }
      
      debugPrint('Document is missing workoutPlan field and alternative structures');
      return false;
    }
    
    // If workoutPlan exists but isn't a list, that's a problem
    if (data['workoutPlan'] is! List) {
      debugPrint('workoutPlan field exists but is not a List: ${data['workoutPlan'].runtimeType}');
      return false;
    }
    
    // If we reach here, the document appears to have valid workout data
    return true;
  }
  
  // Create a new workout plan directly (without AI generation)
  Future<void> createWorkoutPlan(Map<String, dynamic> workoutData) async {
    if (_auth.currentUser == null) {
      _error = 'You must be logged in to create a workout plan';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _auth.currentUser!.uid;
      debugPrint('Creating new workout plan for user: $userId');
      
      // Use user ID as document ID for direct access
      final planId = userId;
      
      // Add metadata
      final now = DateTime.now();
      final planData = {
        ...workoutData,
        'userId': userId,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'weekStartDate': workoutData['weekStartDate'] ?? now.toIso8601String(),
      };
      
      debugPrint('Saving workout plan to Firestore collection: $_workoutPlansCollection');
      
      // Save to Firestore
      await _firestore
          .collection(_workoutPlansCollection)
          .doc(planId)
          .set(planData);
      
      debugPrint('Workout plan saved successfully');
      
      // Update local state
      try {
        _currentWorkoutPlan = WorkoutPlan.fromMap({
          ...planData,
          'id': planId,
        });
        debugPrint('Local state updated with new workout plan');
      } catch (e) {
        debugPrint('Error parsing workout plan: $e');
        throw Exception('Error parsing workout plan: $e');
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating workout plan: $e');
      _error = 'An error occurred while creating your workout plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update an existing workout plan
  Future<void> updateWorkoutPlan(String planId, Map<String, dynamic> updatedData) async {
    if (_auth.currentUser == null) {
      _error = 'You must be logged in to update a workout plan';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Updating workout plan with ID: $planId');
      
      // Add updated timestamp
      final updateData = {
        ...updatedData,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Update in Firestore
      await _firestore
          .collection(_workoutPlansCollection)
          .doc(planId)
          .update(updateData);
      
      debugPrint('Workout plan updated successfully');
      
      // Reload the current plan to reflect changes
      await loadCurrentWorkoutPlan();
    } catch (e) {
      debugPrint('Error updating workout plan: $e');
      _error = 'An error occurred while updating your workout plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete a workout plan
  Future<void> deleteWorkoutPlan(String planId) async {
    if (_auth.currentUser == null) {
      _error = 'You must be logged in to delete a workout plan';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Deleting workout plan with ID: $planId');
      
      await _firestore
          .collection(_workoutPlansCollection)
          .doc(planId)
          .delete();
      
      debugPrint('Workout plan deleted successfully');
      
      // If we deleted the current plan, clear it from state
      if (_currentWorkoutPlan?.id == planId) {
        _currentWorkoutPlan = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting workout plan: $e');
      _error = 'An error occurred while deleting your workout plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get a specific workout by date
  DailyWorkout? getWorkoutForDate(DateTime date) {
    if (_currentWorkoutPlan == null || _currentWorkoutPlan!.workouts.isEmpty) return null;
    
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    
    try {
      return _currentWorkoutPlan!.workouts.firstWhere(
        (workout) => workout.day == weekday,
      );
    } catch (e) {
      // No workout found for this day
      return null;
    }
  }
  
  // Clear current workout plan
  void clearCurrentPlan() {
    _currentWorkoutPlan = null;
    notifyListeners();
  }
  
  // Reset provider error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 