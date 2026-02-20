import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isLast;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('h:mm a');
    
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 8.0,
        top: 8.0,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar for non-user messages
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Icon(
                Icons.fitness_center,
                size: 16,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Images if any
                if (message.imageUrls != null && message.imageUrls!.isNotEmpty) ...[
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      maxHeight: 200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: message.imageUrls!.length > 1 ? 2 : 1,
                          childAspectRatio: 1,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: message.imageUrls!.length > 4 
                            ? 4 
                            : message.imageUrls!.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                message.imageUrls![index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: colorScheme.surfaceVariant,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                },
                              ),
                              if (index == 3 && message.imageUrls!.length > 4)
                                Container(
                                  color: Colors.black54,
                                  child: Center(
                                    child: Text(
                                      '+${message.imageUrls!.length - 4}',
                                      style: textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isLoading 
                        ? colorScheme.surfaceVariant
                        : isUser
                            ? colorScheme.primary
                            : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: isUser
                          ? const Radius.circular(24)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(24),
                    ),
                    boxShadow: [
                      if (!message.isLoading)
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.05),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: message.isLoading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: colorScheme.primary,
                              size: 30,
                            ),
                          ),
                        )
                      : Text(
                          message.text,
                          style: textTheme.bodyLarge?.copyWith(
                            color: isUser
                                ? colorScheme.onPrimary
                                : colorScheme.onSecondaryContainer,
                          ),
                        ),
                ),
                
                // Timestamp
                if (!message.isLoading) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(message.timestamp),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // User avatar
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.tertiary,
              child: Icon(
                Icons.person,
                size: 16,
                color: colorScheme.onTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 