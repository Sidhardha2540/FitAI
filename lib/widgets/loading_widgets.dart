import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool showMessage;
  
  const LoadingWidget({
    super.key,
    this.message,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.fitness_center,
              color: colorScheme.onPrimary,
              size: 40,
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).scale(
            duration: const Duration(milliseconds: 1000),
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.2, 1.2),
            curve: Curves.easeInOut,
          ).then().scale(
            duration: const Duration(milliseconds: 1000),
            begin: const Offset(1.2, 1.2),
            end: const Offset(0.8, 0.8),
            curve: Curves.easeInOut,
          ),
          
          if (showMessage) ...[
            const SizedBox(height: 24),
            Text(
              message ?? 'Loading...',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 300),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  
  const ErrorWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.error.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 40,
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
            ),
            
            const SizedBox(height: 24),
            
            // Error title
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
            ).slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 12),
            
            // Error message
            Text(
              message,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 400),
            ).slideY(begin: 0.3, end: 0),
            
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              
              // Retry button
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? 'Try Again'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 600),
              ).slideY(begin: 0.3, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionButtonText;
  
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: colorScheme.onSurfaceVariant,
                size: 50,
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
            ),
            
            const SizedBox(height: 32),
            
            // Empty state title
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
            ).slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 12),
            
            // Empty state message
            Text(
              message,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 400),
            ).slideY(begin: 0.3, end: 0),
            
            if (onAction != null) ...[
              const SizedBox(height: 32),
              
              // Action button
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionButtonText ?? 'Get Started'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 600),
              ).slideY(begin: 0.3, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}

class SuccessWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onContinue;
  final String? continueButtonText;
  
  const SuccessWidget({
    super.key,
    required this.title,
    required this.message,
    this.onContinue,
    this.continueButtonText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 40,
              ),
            ).animate().scale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
            ),
            
            const SizedBox(height: 24),
            
            // Success title
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
            ).slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 12),
            
            // Success message
            Text(
              message,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 400),
            ).slideY(begin: 0.3, end: 0),
            
            if (onContinue != null) ...[
              const SizedBox(height: 32),
              
              // Continue button
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward),
                label: Text(continueButtonText ?? 'Continue'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 600),
              ).slideY(begin: 0.3, end: 0),
            ],
          ],
        ),
      ),
    );
  }
} 