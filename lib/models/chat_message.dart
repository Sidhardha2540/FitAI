import 'package:flutter/material.dart';

enum MessageSender {
  user,
  ai
}

class ChatMessage {
  final String id;
  final String text;
  final List<String>? imageUrls;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.text,
    this.imageUrls,
    required this.sender,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromUser({
    required String id,
    required String text,
    List<String>? imageUrls,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      imageUrls: imageUrls,
      sender: MessageSender.user,
    );
  }

  factory ChatMessage.fromAI({
    required String id,
    required String text,
    List<String>? imageUrls,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      imageUrls: imageUrls,
      sender: MessageSender.ai,
    );
  }
  
  factory ChatMessage.loading({required String id}) {
    return ChatMessage(
      id: id,
      text: '',
      sender: MessageSender.ai,
      isLoading: true,
    );
  }
  
  ChatMessage copyWith({
    String? id,
    String? text,
    List<String>? imageUrls,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      imageUrls: imageUrls ?? this.imageUrls,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
} 