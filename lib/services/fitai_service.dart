import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class FitAIService {
  // Google ADK Agent configuration
  final String baseUrl;
  String userId;
  final String appName = 'fitai_adk';
  
  // Session management
  String? _sessionId;
  final uuid = Uuid();
  
  // Singleton pattern
  static final FitAIService _instance = FitAIService._internal();
  factory FitAIService() => _instance;
  
  FitAIService._internal()
      : baseUrl = 'https://fitai-agent-service-821526360592.us-central1.run.app',
        userId = 'default_user';
  
  // Initialize with user ID
  Future<void> initialize({String? userId}) async {
    if (userId != null) {
      this.userId = userId;
    }
    
    // Load or create session
    await _loadSessionFromStorage();
    
    // Always create a new session during initialization
    // to ensure we have a valid session
    _sessionId = uuid.v4();
    await createSession(_sessionId!);
    debugPrint('Initialized with new session ID: $_sessionId');
  }
  
  // Create a session for the user
  Future<bool> createSession(String sessionId) async {
    try {
      // Ensure userId is properly formatted and not empty
      final String sanitizedUserId = userId.isNotEmpty ? userId : 'anonymous_user';
      
      final endpoint = '$baseUrl/apps/$appName/users/$sanitizedUserId/sessions/$sessionId';
      debugPrint('Creating FitAI session: $sessionId');
      debugPrint('Using user ID: $sanitizedUserId');
      debugPrint('Request URL: $endpoint');
      
      final requestBody = {'state': {}};
      debugPrint('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      final success = response.statusCode == 200 || response.statusCode == 201;
      
      if (success) {
        _sessionId = sessionId;
        await _saveSessionToStorage();
        debugPrint('Created new FitAI session: $_sessionId');
      } else {
        debugPrint('Failed to create FitAI session: ${response.statusCode}, ${response.body}');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error creating FitAI session: $e');
      return false;
    }
  }
  
  // Send a message to the agent using the ADK format
  Future<ChatMessage> sendMessage(String text) async {
    if (_sessionId == null) {
      _sessionId = uuid.v4();
      await createSession(_sessionId!);
    }
    
    try {
      final endpoint = '$baseUrl/run';
      debugPrint('Sending message to FitAI service: "$text"');
      debugPrint('Request URL: $endpoint');
      
      // Ensure userId is properly formatted and not empty
      final String sanitizedUserId = userId.isNotEmpty ? userId : 'anonymous_user';
      debugPrint('Using sanitized user ID: $sanitizedUserId');
      
      // Include user ID explicitly in the message text to ensure it gets picked up
      final String messageWithUserContext = 
          text + (text.contains("user_id") ? "" : "\n\nUser ID reference: $sanitizedUserId");
      
      final requestBody = {
        'app_name': appName,
        'user_id': sanitizedUserId,
        'session_id': _sessionId,
        'new_message': {
          'role': 'user',
          'parts': [{'text': messageWithUserContext}]
        },
        'streaming': false
      };
      
      debugPrint('Request body: ${jsonEncode(requestBody)}');
      
      var response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      // If session not found, create a new one and retry
      if (response.statusCode == 404 && response.body.contains('Session not found')) {
        debugPrint('Session not found, creating a new session...');
        _sessionId = uuid.v4();
        final success = await createSession(_sessionId!);
        
        if (success) {
          // Update the session ID in the request body
          requestBody['session_id'] = _sessionId;
          
          // Retry the request
          debugPrint('Retrying with new session ID: $_sessionId');
          response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          );
          
          debugPrint('Retry response status code: ${response.statusCode}');
          debugPrint('Retry response body: ${response.body}');
        } else {
          throw Exception('Failed to create a new session');
        }
      }
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          String responseText = 'No response received';
          
          debugPrint('Parsed response data structure: $data');
          
          if (data is List && data.isNotEmpty) {
            // Process ADK response array
            for (var item in data) {
              if (item is Map && 
                  item.containsKey('content') && 
                  item['content'] is Map &&
                  item['content'].containsKey('parts')) {
                
                final parts = item['content']['parts'] as List;
                for (var part in parts) {
                  if (part is Map && part.containsKey('text')) {
                    // Found a text response
                    responseText = part['text'];
                    debugPrint('Found text response: $responseText');
                    break; // Use the first text response
                  }
                }
                
                // If we found a response, break the loop
                if (responseText != 'No response received') {
                  break;
                }
              }
            }
          }
          
          return ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: responseText,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
        } catch (parseError) {
          debugPrint('Error parsing response: $parseError');
          return ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'Error parsing AI response: $parseError',
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
        }
      } else {
        final errorMessage = 'Failed to get response: ${response.statusCode}, ${response.body}';
        debugPrint(errorMessage);
        
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Sorry, I encountered an error (Status ${response.statusCode}). Please try again later.',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Error communicating with agent: $e');
      
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Network error. Please check your connection and try again.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
    }
  }
  
  // Stream messages (for real-time responses)
  Stream<String> streamMessage(String text) async* {
    if (_sessionId == null) {
      _sessionId = uuid.v4();
      await createSession(_sessionId!);
    }
    
    try {
      final endpoint = '$baseUrl/run_sse';
      debugPrint('Streaming message to FitAI service: "$text"');
      debugPrint('Stream request URL: $endpoint');
      
      // Ensure userId is properly formatted and not empty
      final String sanitizedUserId = userId.isNotEmpty ? userId : 'anonymous_user';
      debugPrint('Using sanitized user ID for streaming: $sanitizedUserId');
      
      // Include user ID explicitly in the message text to ensure it gets picked up
      final String messageWithUserContext = 
          text + (text.contains("user_id") ? "" : "\n\nUser ID reference: $sanitizedUserId");
      
      final requestBody = {
        'app_name': appName,
        'user_id': sanitizedUserId,
        'session_id': _sessionId,
        'new_message': {
          'role': 'user',
          'parts': [{'text': messageWithUserContext}]
        },
        'streaming': true
      };
      
      debugPrint('Stream request body: ${jsonEncode(requestBody)}');
      
      // First check if session exists by making a normal request
      var checkResponse = await http.post(
        Uri.parse('$baseUrl/run'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'app_name': appName,
          'user_id': sanitizedUserId,
          'session_id': _sessionId,
          'new_message': {'role': 'user', 'parts': [{'text': 'Check session'}]},
          'streaming': false
        }),
      );
      
      // If session not found, create a new one
      if (checkResponse.statusCode == 404 && checkResponse.body.contains('Session not found')) {
        debugPrint('Streaming session not found, creating a new session...');
        _sessionId = uuid.v4();
        final success = await createSession(_sessionId!);
        
        if (success) {
          // Update the session ID in the request body
          requestBody['session_id'] = _sessionId;
          debugPrint('Updated stream request with new session ID: $_sessionId');
        } else {
          throw Exception('Failed to create a new session for streaming');
        }
      }
      
      final request = http.Request(
        'POST',
        Uri.parse(endpoint),
      );
      
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(requestBody);
      
      final response = await http.Client().send(request);
      debugPrint('Stream response status: ${response.statusCode}');
      
      final stream = response.stream.transform(utf8.decoder);
      
      await for (var data in stream) {
        debugPrint('Received stream data: $data');
        
        // SSE format: data starts with "data: " and each message is separated by two newlines
        final lines = data.split('\n\n');
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6); // Remove "data: " prefix
            try {
              final parsedData = jsonDecode(jsonStr);
              if (parsedData is Map && 
                  parsedData.containsKey('content') && 
                  parsedData['content'] is Map &&
                  parsedData['content'].containsKey('parts')) {
                
                final parts = parsedData['content']['parts'] as List;
                for (var part in parts) {
                  if (part is Map && part.containsKey('text')) {
                    yield part['text'];
                  }
                }
              }
            } catch (e) {
              // Skip invalid JSON
              debugPrint('Error parsing SSE data: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error streaming from agent: $e');
      yield 'Error streaming response: $e';
    }
  }
  
  // Get conversation history (not directly supported by ADK, would need backend support)
  Future<List<ChatMessage>> getConversationHistory() async {
    return [
      ChatMessage(
        id: '1',
        text: 'Hello! I\'m your FitAI coach. How can I help you today?',
        sender: MessageSender.ai,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      ),
    ];
  }
  
  // Save session ID to persistent storage
  Future<void> _saveSessionToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_sessionId != null) {
        await prefs.setString('fitai_session_id', _sessionId!);
        await prefs.setString('fitai_user_id', userId);
        debugPrint('Saved FitAI session to storage: $_sessionId');
      }
    } catch (e) {
      debugPrint('Error saving session to storage: $e');
    }
  }
  
  // Load session ID from persistent storage
  Future<void> _loadSessionFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('fitai_session_id');
      if (_sessionId != null) {
        debugPrint('Loaded FitAI session from storage: $_sessionId');
      } else {
        debugPrint('No existing FitAI session found in storage');
      }
    } catch (e) {
      debugPrint('Error loading session from storage: $e');
    }
  }
  
  // Clear the current session
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fitai_session_id');
      
      // Create a new session
      _sessionId = uuid.v4();
      final success = await createSession(_sessionId!);
      
      if (success) {
        debugPrint('Cleared and created new FitAI session: $_sessionId');
      } else {
        debugPrint('Failed to create new session after clearing');
      }
    } catch (e) {
      debugPrint('Error clearing FitAI session: $e');
    }
  }
} 