import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_message_bubble.dart';
import '../../widgets/chat_input_field.dart';
import '../../models/chat_message.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late ChatProvider _chatProvider;
  
  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _chatProvider.initializeAsync(context);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }
  
  void _handleSendMessage(String text) {
    _chatProvider.sendMessage(text);
    _scrollToBottom();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Icon(
                Icons.fitness_center,
                size: 14,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Fitness Coach',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              // Show confirmation dialog before clearing chat
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat'),
                  content: const Text('Are you sure you want to clear this conversation?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        _chatProvider.clearChat();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.messages;
                
                if (messages.isEmpty) {
                  return Center(
                    child: Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 600)),
                        SlideEffect(
                          begin: Offset(0, 30),
                          end: Offset.zero,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeOutQuint,
                        ),
                      ],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_outlined,
                            size: 64,
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with your AI Fitness Coach',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Show scrollable list of messages
                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    // After building a new message, scroll to bottom
                    if (index == messages.length - 1) {
                      _scrollToBottom();
                    }
                    
                    return Animate(
                      effects: [
                        FadeEffect(
                          duration: const Duration(milliseconds: 300),
                          delay: Duration(milliseconds: index * 50),
                        ),
                        SlideEffect(
                          begin: const Offset(0, 20),
                          end: Offset.zero,
                          duration: const Duration(milliseconds: 300),
                          delay: Duration(milliseconds: index * 50),
                          curve: Curves.easeOutQuint,
                        ),
                      ],
                      child: ChatMessageBubble(
                        message: message,
                        isLast: index == messages.length - 1,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Input field
          ChatInputField(
            onSendMessage: _handleSendMessage,
          ),
        ],
      ),
    );
  }
}

// Full screen version for the floating chat button that comes from Hero animation
class AIChatFullScreen extends StatefulWidget {
  const AIChatFullScreen({super.key});

  @override
  State<AIChatFullScreen> createState() => _AIChatFullScreenState();
}

class _AIChatFullScreenState extends State<AIChatFullScreen> {
  final ScrollController _scrollController = ScrollController();
  late ChatProvider _chatProvider;
  
  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _chatProvider.initializeAsync(context);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }
  
  void _handleSendMessage(String text) {
    _chatProvider.sendMessage(text);
    _scrollToBottom();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Hero(
      tag: 'chat_fab',
      child: Material(
        color: colorScheme.primary,
        child: Scaffold(
          backgroundColor: colorScheme.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary,
                  child: Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Fitness Coach',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: colorScheme.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: colorScheme.shadow.withOpacity(0.1),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: () {
                  // Show confirmation dialog before clearing chat
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Chat'),
                      content: const Text('Are you sure you want to clear this conversation?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            _chatProvider.clearChat();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Clear chat',
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final messages = chatProvider.messages;
                    
                    if (messages.isEmpty) {
                      return Center(
                        child: Animate(
                          effects: const [
                            FadeEffect(duration: Duration(milliseconds: 600)),
                            SlideEffect(
                              begin: Offset(0, 30),
                              end: Offset.zero,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeOutQuint,
                            ),
                          ],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_outlined,
                                size: 64,
                                color: colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a conversation with your AI Fitness Coach',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // Show scrollable list of messages
                    return ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        // After building a new message, scroll to bottom
                        if (index == messages.length - 1) {
                          _scrollToBottom();
                        }
                        
                        return Animate(
                          effects: [
                            FadeEffect(
                              duration: const Duration(milliseconds: 300),
                              delay: Duration(milliseconds: index * 50),
                            ),
                            SlideEffect(
                              begin: const Offset(0, 20),
                              end: Offset.zero,
                              duration: const Duration(milliseconds: 300),
                              delay: Duration(milliseconds: index * 50),
                              curve: Curves.easeOutQuint,
                            ),
                          ],
                          child: ChatMessageBubble(
                            message: message,
                            isLast: index == messages.length - 1,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Input field
              ChatInputField(
                onSendMessage: _handleSendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 