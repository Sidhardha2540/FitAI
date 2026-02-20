import 'package:flutter/material.dart';
import '../screens/chat/ai_chat_screen.dart';

class FloatingChatButton extends StatelessWidget {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  
  const FloatingChatButton({
    super.key, 
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AIChatFullScreen(),
              ),
            );
          },
          customBorder: const CircleBorder(),
          child: Ink(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.smart_toy_outlined,
                color: colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 