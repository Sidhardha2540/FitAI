import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/chat_message.dart';

class AgentService {
  // Google Cloud Vertex AI Agent Engine configuration
  static const String _location = 'us-central1';
  static const String _projectId = '821526360592';
  static const String _resourceId = '2659876957264543744';
  static const String _baseUrl = 'https://us-central1-aiplatform.googleapis.com/v1/projects/821526360592/locations/us-central1/reasoningEngines/2659876957264543744';
  
  // Session management
  String? _sessionId;
  String? _userId;
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  bool _isAuthenticated = false;
  
  // Test mode flag to reduce API calls during testing
  bool _testMode = false; // Set to false to use real API calls
  
  // OAuth token management
  String? _accessToken;
  DateTime? _tokenExpiry;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/cloud-platform',
    ],
  );
  
  // Singleton pattern
  static final AgentService _instance = AgentService._internal();
  factory AgentService() => _instance;
  AgentService._internal();
  
  // Authentication state stream
  Stream<bool> get authStateChanges => _authStateController.stream;
  bool get isAuthenticated => _isAuthenticated;
  
  // Initialize the service with minimal API calls
  Future<void> initialize({String? userId}) async {
    _userId = userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    if (_testMode) {
      // Skip most API calls in test mode
      _sessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
      _isAuthenticated = true;
      _authStateController.add(true);
      debugPrint('TESTMODE: Initialized with minimal API calls. Using test session: $_sessionId');
      return;
    }
    
    try {
      // Get token first (one API call)
      await _refreshGoogleAuthToken();
      
      // Load session from storage (no API call)
      await _loadSessionFromStorage();
      
      // If no session, create one (one API call)
      if (_sessionId == null) {
        await _createNewSession();
      }
      
      _isAuthenticated = true;
      _authStateController.add(true);
    } catch (e) {
      debugPrint('Error initializing agent service: $e');
      _isAuthenticated = false;
      _authStateController.add(false);
      
      // Fallback to a local session ID
      _sessionId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      await _saveSessionToStorage();
      _isAuthenticated = true;
      _authStateController.add(true);
    }
  }
  
  // Get Google Cloud OAuth authentication token
  Future<String?> _getAuthToken() async {
    if (_testMode) {
      return 'test_token';
    }
    
    try {
      // Check if the token is expired or not available
      if (_accessToken == null || _tokenExpiry == null || DateTime.now().isAfter(_tokenExpiry!)) {
        await _refreshGoogleAuthToken();
      }
      
      return _accessToken;
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }
  
  // Refresh Google OAuth token
  Future<void> _refreshGoogleAuthToken() async {
    if (_testMode) {
      _accessToken = 'test_token';
      _tokenExpiry = DateTime.now().add(Duration(hours: 1));
      debugPrint('TESTMODE: Skipped token refresh');
      return;
    }
    
    try {
      // Check if user is already signed in
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      
      // If not signed in, trigger sign in flow
      if (account == null) {
        account = await _googleSignIn.signIn();
      }
      
      if (account != null) {
        // Get authentication
        final authentication = await account.authentication;
        _accessToken = authentication.accessToken;
        
        // Set expiry to a conservative value (tokens typically last 1 hour)
        _tokenExpiry = DateTime.now().add(Duration(minutes: 50));
        
        debugPrint('Google OAuth token refreshed');
      } else {
        throw Exception('Failed to sign in with Google');
      }
    } catch (e) {
      debugPrint('Error refreshing Google auth token: $e');
      throw e;
    }
  }
  
  // Get authentication headers for requests
  Future<Map<String, String>> _getHeaders() async {
    // Standard headers for API requests
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final token = await _getAuthToken();
    
    // Add auth token if available
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Get API endpoint URL for a specific method
  String _getApiUrl(String method) {
    return '$_baseUrl:$method';
  }
  
  // Send a message to the agent
  Future<ChatMessage> sendMessage(String text) async {
    if (_sessionId == null) {
      await _createNewSession();
    }
    
    // Return mock response in test mode
    if (_testMode) {
      await Future.delayed(Duration(milliseconds: 300)); // Simulate network delay
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: "This is a test response to save API calls. Your message was: \"$text\"",
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
    }
    
    try {
      final headers = await _getHeaders();
      final Uri uri = Uri.parse(_getApiUrl('query'));
      
      // Exactly matching the format in the documentation
      final Map<String, dynamic> requestBody = {
        'class_method': 'query',
        'input': {
          'user_id': _userId,
          'session_id': _sessionId,
          'message': text
        }
      };
      
      debugPrint('Sending request to: $uri');
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Extract the agent's response
        final String responseText = responseData['result'] ?? 'No response from agent';
        
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: responseText,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        );
      } else {
        final errorMessage = 'Failed to get response from agent: ${response.statusCode}, ${response.body}';
        debugPrint(errorMessage);
        
        // No retries in this minimal implementation
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error communicating with agent: $e');
      
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'I encountered an error communicating with the AI service. Please try again later.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
    }
  }
  
  // Get conversation history (minimal implementation)
  Future<List<ChatMessage>> getConversationHistory() async {
    if (_testMode) {
      // Return mock conversation history
      return [
        ChatMessage(
          id: '1',
          text: 'Hello! How can I help with your fitness goals today?',
          sender: MessageSender.ai,
          timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        ),
      ];
    }
    
    if (_sessionId == null) {
      await _createNewSession();
      return [];
    }
    
    try {
      final headers = await _getHeaders();
      final Uri uri = Uri.parse(_getApiUrl('query'));
      
      // Format exactly matching documentation
      final Map<String, dynamic> requestBody = {
        'class_method': 'get_messages',
        'input': {
          'user_id': _userId,
          'session_id': _sessionId
        }
      };
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        
        // Convert the response data to ChatMessage objects
        return responseData.map((message) {
          final bool isUser = message['role'] == 'user';
          return ChatMessage(
            id: message['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            text: message['content'] ?? '',
            sender: isUser ? MessageSender.user : MessageSender.ai,
            timestamp: message['timestamp'] != null 
                ? DateTime.parse(message['timestamp'])
                : DateTime.now(),
          );
        }).toList();
      } else {
        debugPrint('Failed to get conversation history: ${response.statusCode}, ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error retrieving conversation history: $e');
      return [];
    }
  }
  
  // Create a new session with the agent (simplified)
  Future<void> _createNewSession() async {
    if (_testMode) {
      _sessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
      await _saveSessionToStorage();
      debugPrint('TESTMODE: Created test session: $_sessionId');
      return;
    }
    
    try {
      final headers = await _getHeaders();
      final Uri uri = Uri.parse(_getApiUrl('query'));
      
      // Format exactly matching documentation
      final Map<String, dynamic> requestBody = {
        'class_method': 'create_session',
        'input': {
          'user_id': _userId
        }
      };
      
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Extract session ID from response
        _sessionId = responseData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Save session to persistent storage
        await _saveSessionToStorage();
        
        debugPrint('Created new session: $_sessionId');
      } else {
        // If session creation fails, generate a fallback session ID
        _sessionId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
        await _saveSessionToStorage();
        
        debugPrint('Failed to create session with status ${response.statusCode}, using fallback: $_sessionId');
      }
    } catch (e) {
      // If there's an error, use a fallback session ID
      _sessionId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      await _saveSessionToStorage();
      
      debugPrint('Error creating session: $e, using fallback: $_sessionId');
    }
  }
  
  // Save session ID to persistent storage
  Future<void> _saveSessionToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_sessionId != null) {
        await prefs.setString('agent_session_id', _sessionId!);
        await prefs.setString('agent_user_id', _userId!);
      }
    } catch (e) {
      debugPrint('Error saving session to storage: $e');
    }
  }
  
  // Load session ID from persistent storage
  Future<void> _loadSessionFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('agent_session_id');
      
      // If we have a saved user ID, use it; otherwise, keep the one provided during initialization
      final savedUserId = prefs.getString('agent_user_id');
      if (savedUserId != null) {
        _userId = savedUserId;
      }
    } catch (e) {
      debugPrint('Error loading session from storage: $e');
    }
  }
  
  // Clear the current session
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('agent_session_id');
      _sessionId = null;
      
      if (_testMode) {
        _sessionId = 'test_session_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('TESTMODE: Created new test session: $_sessionId');
      } else {
        // Create a new session immediately
        await _createNewSession();
      }
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }
  
  // Delete a session
  Future<void> logout() async {
    if (_testMode) {
      _sessionId = null;
      _isAuthenticated = false;
      _authStateController.add(false);
      debugPrint('TESTMODE: Logged out');
      return;
    }
    
    if (_sessionId != null) {
      try {
        final headers = await _getHeaders();
        final Uri uri = Uri.parse(_getApiUrl('query'));
        
        // Format exactly matching documentation
        final Map<String, dynamic> requestBody = {
          'class_method': 'delete_session',
          'input': {
            'user_id': _userId,
            'session_id': _sessionId
          }
        };
        
        await http.post(
          uri,
          headers: headers,
          body: jsonEncode(requestBody),
        );
      } catch (e) {
        debugPrint('Error logging out: $e');
      }
    }
    
    _sessionId = null;
    await _saveSessionToStorage();
    
    // Sign out from Google
    try {
      await _googleSignIn.signOut();
      _accessToken = null;
      _tokenExpiry = null;
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
    
    _isAuthenticated = false;
    _authStateController.add(false);
  }
  
  // Clean up resources
  void dispose() {
    _authStateController.close();
  }
} 