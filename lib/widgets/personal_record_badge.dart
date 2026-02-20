import 'package:flutter/material.dart';

class PersonalRecordBadge extends StatefulWidget {
  final String title;
  final String value;
  final String? previousValue;
  final bool isNewRecord;
  final Color? color;

  const PersonalRecordBadge({
    super.key,
    required this.title,
    required this.value,
    this.previousValue,
    this.isNewRecord = false,
    this.color,
  });

  @override
  State<PersonalRecordBadge> createState() => _PersonalRecordBadgeState();
}

class _PersonalRecordBadgeState extends State<PersonalRecordBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    if (widget.isNewRecord) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: widget.isNewRecord
                      ? LinearGradient(
                          colors: [
                            Colors.amber.withOpacity(0.8),
                            Colors.orange.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.isNewRecord ? null : (widget.color ?? colorScheme.primaryContainer),
                  borderRadius: BorderRadius.circular(16),
                  border: widget.isNewRecord
                      ? Border.all(color: Colors.amber, width: 2)
                      : null,
                  boxShadow: widget.isNewRecord
                      ? [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isNewRecord) ...[
                      Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'NEW RECORD!',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      widget.title,
                      style: textTheme.bodyMedium?.copyWith(
                        color: widget.isNewRecord ? Colors.white : null,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.value,
                      style: textTheme.headlineSmall?.copyWith(
                        color: widget.isNewRecord ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.previousValue != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Previous: ${widget.previousValue}',
                        style: textTheme.bodySmall?.copyWith(
                          color: widget.isNewRecord 
                            ? Colors.white.withOpacity(0.8)
                            : colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} 