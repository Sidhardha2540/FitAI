import 'package:flutter/material.dart';

/// A loading indicator that follows Material Design 3 guidelines.
/// 
/// This can be used as either a circular or linear progress indicator 
/// based on the type parameter.
class M3LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool isLinear;
  final double? value; // For determinate progress
  
  /// Creates a loading indicator following Material Design 3 guidelines.
  /// 
  /// [message] - Optional message to display below the indicator
  /// [isLinear] - Whether to use a linear (true) or circular (false) indicator
  /// [value] - Value between 0.0 and 1.0 for determinate progress; null for indeterminate
  const M3LoadingIndicator({
    super.key,
    this.message,
    this.isLinear = false,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLinear)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
              child: LinearProgressIndicator(
                value: value,
                minHeight: 4.0, // M3 spec for linear indicators
                backgroundColor: colorScheme.surfaceVariant,
                color: colorScheme.primary,
              ),
            )
          else
            CircularProgressIndicator(
              value: value,
              strokeWidth: 4.0, // M3 spec for circular indicators
              backgroundColor: colorScheme.surfaceVariant,
              color: colorScheme.primary,
            ),
          
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  /// Creates a circular indeterminate loading indicator.
  const factory M3LoadingIndicator.circular({String? message}) = _CircularLoadingIndicator;
  
  /// Creates a linear indeterminate loading indicator.
  const factory M3LoadingIndicator.linear({String? message}) = _LinearLoadingIndicator;
  
  /// Creates a determinate circular progress indicator.
  const factory M3LoadingIndicator.circularDeterminate({
    required double value, 
    String? message,
  }) = _CircularDeterminateLoadingIndicator;
  
  /// Creates a determinate linear progress indicator.
  const factory M3LoadingIndicator.linearDeterminate({
    required double value,
    String? message,
  }) = _LinearDeterminateLoadingIndicator;
}

/// Implementation of circular indeterminate loading indicator
class _CircularLoadingIndicator extends M3LoadingIndicator {
  const _CircularLoadingIndicator({String? message}) : super(
    message: message,
    isLinear: false,
  );
}

/// Implementation of linear indeterminate loading indicator
class _LinearLoadingIndicator extends M3LoadingIndicator {
  const _LinearLoadingIndicator({String? message}) : super(
    message: message,
    isLinear: true,
  );
}

/// Implementation of circular determinate loading indicator
class _CircularDeterminateLoadingIndicator extends M3LoadingIndicator {
  const _CircularDeterminateLoadingIndicator({
    required double value,
    String? message,
  }) : super(
    message: message,
    isLinear: false,
    value: value,
  );
}

/// Implementation of linear determinate loading indicator
class _LinearDeterminateLoadingIndicator extends M3LoadingIndicator {
  const _LinearDeterminateLoadingIndicator({
    required double value,
    String? message,
  }) : super(
    message: message,
    isLinear: true,
    value: value,
  );
} 