import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeModeToggle extends StatelessWidget {
  final bool compact;
  
  const ThemeModeToggle({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: compact 
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (!compact) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Theme',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
            // Animated toggle
            GestureDetector(
              onTap: () => themeProvider.toggleTheme(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: compact ? 56 : 64,
                height: compact ? 28 : 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  color: isDark 
                      ? const Color(0xFF555C7A) 
                      : const Color(0xFFD0EDFD),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: isDark ? (compact ? 28 : 32) : 0,
                      right: isDark ? 0 : (compact ? 28 : 32),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: compact ? 28 : 32,
                        height: compact ? 28 : 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark 
                              ? const Color(0xFF8ECEFF) 
                              : const Color(0xFFFFDE7A),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isDark ? Icons.nightlight_round : Icons.wb_sunny,
                            size: compact ? 16 : 18,
                            color: isDark 
                                ? const Color(0xFF1A1C1E) 
                                : const Color(0xFFF57C00),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 