import 'package:flutter/material.dart';
import 'dart:math' as math;

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Dark background like in the image
          borderRadius: BorderRadius.circular(36), // Fully rounded pill shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              index: 0,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.fitness_center_outlined,
              selectedIcon: Icons.fitness_center_rounded,
              label: 'Workouts',
              index: 1,
            ),
            // AI Chat button in the middle
            _buildAIChatButton(context),
            _buildNavItem(
              context: context,
              icon: Icons.trending_up_outlined,
              selectedIcon: Icons.trending_up_rounded,
              label: 'Progress',
              index: 2,
            ),
            _buildNavItem(
              context: context,
              icon: Icons.restaurant_menu_outlined,
              selectedIcon: Icons.restaurant_menu_rounded,
              label: 'Nutrition',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIChatButton(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (0.1 * (0.5 + 0.5 * math.sin(value * 6.28))), // Pulsing animation
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF81C784), // Subtle green to match new theme
                  Color(0xFF66BB6A), // Slightly darker subtle green
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF81C784).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/chat');
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated background circles
                      TweenAnimationBuilder<double>(
                        duration: const Duration(seconds: 3),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, animValue, child) {
                          return CustomPaint(
                            size: const Size(56, 56),
                            painter: _AIPulsePainter(animValue),
                          );
                        },
                      ),
                      // AI Icon with rotation animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(seconds: 4),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, rotationValue, child) {
                          return Transform.rotate(
                            angle: rotationValue * 2 * math.pi, // Full rotation
                            child: const Icon(
                              Icons.psychology_outlined,
                              color: Color(0xFF1A1A1A),
                              size: 28,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    
    return Expanded(
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(28),
            child: Container(
              height: 56, // Fixed height for consistent alignment
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon without glow effects
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      key: ValueKey(isSelected),
                      color: isSelected 
                          ? const Color(0xFF81C784) // Subtle green for selected
                          : Colors.white.withOpacity(0.7), // Light gray for unselected
                      size: 24,
                    ),
                  ),
                  
                  // Label without glow effects
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isSelected ? 16 : 12,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: 1.0, // Always show label
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected 
                              ? const Color(0xFF81C784) // Subtle green for selected
                              : Colors.white.withOpacity(0.7), // Light gray for unselected
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for AI button pulse animation
class _AIPulsePainter extends CustomPainter {
  final double animationValue;
  
  _AIPulsePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF81C784).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw pulsing circles
    for (int i = 0; i < 3; i++) {
      final radius = (10 + i * 8) * (1 + animationValue * 0.5);
      final opacity = (1 - animationValue) * (1 - i * 0.3);
      paint.color = const Color(0xFF81C784).withOpacity(opacity * 0.2);
      canvas.drawCircle(center, radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 