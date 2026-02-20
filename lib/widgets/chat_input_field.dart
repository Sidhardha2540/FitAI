import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  
  const ChatInputField({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (pickedFile != null && mounted) {
        Provider.of<ChatProvider>(context, listen: false)
            .addImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // Close the expanded menu after selecting
      if (_isExpanded) {
        _toggleExpanded();
      }
    }
  }
  
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty || Provider.of<ChatProvider>(context, listen: false).selectedImages.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatProvider = Provider.of<ChatProvider>(context);
    final selectedImages = chatProvider.selectedImages;
    
    return Column(
      children: [
        // Show selected images preview
        if (selectedImages.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          selectedImages[index],
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => chatProvider.removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: colorScheme.onError,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        // Input field and buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Add attachment button
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      onPressed: _toggleExpanded,
                      icon: const Icon(Icons.add, size: 24),
                      color: colorScheme.primary,
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
                      ),
                      tooltip: 'Add attachment',
                    ),
                  ),
                  
                  // Input field
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask your fitness coach...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  
                  // Voice input button
                  IconButton(
                    onPressed: () {
                      // Handle voice input (to be implemented)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Voice input coming soon!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.mic, size: 24),
                    color: colorScheme.secondary,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.secondaryContainer.withOpacity(0.3),
                    ),
                    tooltip: 'Voice input',
                  ),
                  
                  // Send or AI recommendation button
                  Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(left: 4, right: 8),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(
                        _controller.text.isEmpty 
                            ? Icons.graphic_eq 
                            : Icons.send_rounded,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      tooltip: _controller.text.isEmpty 
                          ? 'AI recommendation' 
                          : 'Send message',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Expandable attachment options
        SizeTransition(
          sizeFactor: _animation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.surface,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: colorScheme.tertiary,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: 'Gallery',
                    color: colorScheme.secondary,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  _buildAttachmentOption(
                    icon: Icons.delete,
                    label: 'Clear All',
                    color: colorScheme.error,
                    onTap: () => chatProvider.clearImages(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 