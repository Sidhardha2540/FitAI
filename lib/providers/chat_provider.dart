import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../services/firebase_service.dart';
import '../services/fitai_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FitAIService _fitaiService = FitAIService();
  final Uuid _uuid = const Uuid();
  
  List<ChatMessage> _messages = [
    // Default welcome message to avoid empty state
    ChatMessage.fromAI(
      id: 'welcome',
      text: "Hi there! I'm your FitAI coach. How can I help with your fitness goals today?",
    ),
  ];
  bool _isLoading = false;
  bool _isInitialized = false;
  List<File> _selectedImages = [];
  
  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  List<File> get selectedImages => _selectedImages;
  
  // Initialize chat - modified to use post-frame callback
  void initializeAsync(BuildContext context) {
    // Initialize later to avoid setState during build
    if (_isInitialized) return;
    
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }
  
  // Private initialization method
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get current user ID for the agent from Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid ?? 'anonymous_user';
      
      // Initialize the agent service
      await _fitaiService.initialize(userId: userId);
      
      // Try to load conversation history - add a delay to prevent rapid API calls
      await Future.delayed(Duration(milliseconds: 300));
      final history = await _fitaiService.getConversationHistory();
      
      // If we have history, use it; otherwise, keep welcome message
      if (history.isNotEmpty) {
        _messages = history;
      }
      
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Send a message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty && _selectedImages.isEmpty) return;
    
    final userMessageId = _uuid.v4();
    final aiResponseId = _uuid.v4();
    
    // Add user message immediately
    final userMessage = ChatMessage.fromUser(
      id: userMessageId,
      text: text,
      // We'll update this with URLs after upload
      imageUrls: _selectedImages.isNotEmpty ? [] : null,
    );
    
    _messages.add(userMessage);
    notifyListeners();
    
    // Add loading indicator for AI response
    _messages.add(ChatMessage.loading(id: aiResponseId));
    notifyListeners();
    
    try {
      List<String>? uploadedImageUrls;
      
      // Handle image uploads if any
      if (_selectedImages.isNotEmpty) {
        uploadedImageUrls = [];
        
        for (final image in _selectedImages) {
          final url = await _firebaseService.uploadChatImage(image);
          if (url != null) {
            uploadedImageUrls.add(url);
          }
        }
        
        // Update the user message with image URLs
        final updatedUserMessage = userMessage.copyWith(imageUrls: uploadedImageUrls);
        final userIndex = _messages.indexWhere((msg) => msg.id == userMessageId);
        if (userIndex != -1) {
          _messages[userIndex] = updatedUserMessage;
          notifyListeners();
        }
        
        // Note: Currently the ADK API doesn't support image input directly
        // For future: We could add image URLs to the message or implement multimodal capabilities
      }
      
      // Add a small delay to prevent hitting rate limits
      await Future.delayed(Duration(milliseconds: 300));
      
      // Call the FitAI service
      final agentResponse = await _fitaiService.sendMessage(text);
      
      // Replace the loading message with the actual response
      final aiIndex = _messages.indexWhere((msg) => msg.id == aiResponseId);
      if (aiIndex != -1) {
        _messages[aiIndex] = ChatMessage.fromAI(
          id: aiResponseId,
          text: agentResponse.text,
        );
        notifyListeners();
      }
      
      // Clear selected images after sending
      _selectedImages = [];
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      // Replace loading message with error
      final aiIndex = _messages.indexWhere((msg) => msg.id == aiResponseId);
      if (aiIndex != -1) {
        _messages[aiIndex] = ChatMessage.fromAI(
          id: aiResponseId,
          text: "Sorry, I encountered an error communicating with the AI service. Please try again.",
        );
        notifyListeners();
      }
    }
  }
  
  // Add images to be sent
  void addImage(File image) {
    _selectedImages.add(image);
    notifyListeners();
  }
  
  // Remove image from selected images
  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }
  
  // Clear all selected images
  void clearImages() {
    _selectedImages = [];
    notifyListeners();
  }
  
  // Clear all messages
  void clearChat() {
    _messages = [
      ChatMessage.fromAI(
        id: _uuid.v4(),
        text: "Hi there! I'm your FitAI coach. How can I help with your fitness goals today?",
      ),
    ];
    // Reset the agent session to start a new conversation
    _fitaiService.clearSession();
    notifyListeners();
  }
} 