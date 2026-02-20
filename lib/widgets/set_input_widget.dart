import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise_log.dart';

class SetInputWidget extends StatefulWidget {
  final SetData setData;
  final VoidCallback? onChanged;
  final bool showPrevious;
  final SetData? previousSet;

  const SetInputWidget({
    super.key,
    required this.setData,
    this.onChanged,
    this.showPrevious = false,
    this.previousSet,
  });

  @override
  State<SetInputWidget> createState() => _SetInputWidgetState();
}

class _SetInputWidgetState extends State<SetInputWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: widget.setData.reps);
    _weightController = TextEditingController(
      text: widget.setData.weight?.toString() ?? '',
    );
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: widget.setData.isCompleted
              ? colorScheme.primaryContainer.withOpacity(0.3)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.setData.isCompleted
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.3),
            width: widget.setData.isCompleted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Set number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.setData.isCompleted
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.setData.setNumber.toString(),
                  style: textTheme.labelMedium?.copyWith(
                    color: widget.setData.isCompleted
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Previous performance indicator
            if (widget.showPrevious && widget.previousSet != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last:',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${widget.previousSet!.weight?.toStringAsFixed(1) ?? "-"} kg × ${widget.previousSet!.reps}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
            
            // Reps input
            Expanded(
              child: _buildInput(
                controller: _repsController,
                label: 'Reps',
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  widget.setData.reps = value;
                  widget.onChanged?.call();
                },
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Weight input
            Expanded(
              child: _buildInput(
                controller: _weightController,
                label: 'Weight (kg)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                onChanged: (value) {
                  widget.setData.weight = value.isEmpty ? null : double.tryParse(value);
                  widget.onChanged?.call();
                },
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Completion checkbox
            GestureDetector(
              onTap: () {
                setState(() {
                  widget.setData.isCompleted = !widget.setData.isCompleted;
                  if (widget.setData.isCompleted) {
                    widget.setData.completedAt = DateTime.now();
                    _animationController.forward().then((_) {
                      _animationController.reverse();
                    });
                    HapticFeedback.lightImpact();
                  }
                });
                widget.onChanged?.call();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.setData.isCompleted
                      ? colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: widget.setData.isCompleted
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.setData.isCompleted
                    ? Icon(
                        Icons.check,
                        color: colorScheme.onPrimary,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required ValueChanged<String> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
            isDense: true,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
} 