import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  
  const SplashScreen({
    super.key,
    required this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _startFadeOut = false;
  bool _showRipple = false;
  bool _showSecondRipple = false;
  bool _showThirdRipple = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _setupAnimationSequence();
  }

  void _setupAnimationSequence() {
    // Step 1: Wait a bit to show the logo
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showRipple = true;
        });
      }
    });
    
    // Step 2: Show second ripple with slight delay
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _showSecondRipple = true;
        });
      }
    });
    
    // Step 3: Show third ripple for multi-layered effect
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showThirdRipple = true;
        });
      }
    });
    
    // Step 4: Start fade out animation after ripples
    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _startFadeOut = true;
        });
      }
    });
    
    // Step 5: Navigate to the next screen
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
        ? colorScheme.surface 
        : colorScheme.primaryContainer.withOpacity(0.1),
      body: Stack(
        children: [
          // Background color animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 2500),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: _showRipple ? 1.2 : 0.1,
                colors: [
                  isDarkMode 
                    ? colorScheme.primaryContainer.withOpacity(0.3) 
                    : colorScheme.primaryContainer.withOpacity(0.6),
                  isDarkMode 
                    ? colorScheme.surface 
                    : Colors.white.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Logo with animations
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Animate(
                  effects: [
                    ScaleEffect(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.0, 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutExpo,
                    ),
                    FadeEffect(
                      begin: 0.0,
                      end: 1.0,
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                    ),
                    if (_startFadeOut)
                      FadeEffect(
                        delay: const Duration(milliseconds: 300),
                        begin: 1.0,
                        end: 0.0,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeIn,
                      ),
                  ],
                  child: Image.asset(
                    'assets/images/logo.png', 
                    height: screenSize.width * 0.5,
                    width: screenSize.width * 0.5,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Animate(
                  effects: [
                    FadeEffect(
                      delay: const Duration(milliseconds: 400),
                      begin: 0.0,
                      end: 1.0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                    ),
                    if (_startFadeOut)
                      FadeEffect(
                        delay: const Duration(milliseconds: 200),
                        begin: 1.0,
                        end: 0.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeIn,
                      ),
                  ],
                  child: Text(
                    'Powered by Gemini',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // First Ripple effect (largest)
          if (_showRipple)
            Positioned.fill(
              child: Center(
                child: Animate(
                  effects: [
                    ScaleEffect(
                      begin: const Offset(0.1, 0.1),
                      end: const Offset(15.0, 15.0),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeOut,
                    ),
                    FadeEffect(
                      begin: 0.9,
                      end: 0.0,
                      duration: const Duration(milliseconds: 1800),
                      curve: Curves.easeOut,
                    ),
                  ],
                  child: Container(
                    width: math.max(screenSize.width, screenSize.height) * 0.15,
                    height: math.max(screenSize.width, screenSize.height) * 0.15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.8),
                          colorScheme.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
          // Second Ripple effect (medium)
          if (_showSecondRipple)
            Positioned.fill(
              child: Center(
                child: Animate(
                  effects: [
                    ScaleEffect(
                      begin: const Offset(0.1, 0.1),
                      end: const Offset(12.0, 12.0),
                      duration: const Duration(milliseconds: 1800),
                      curve: Curves.easeOut,
                    ),
                    FadeEffect(
                      begin: 0.85,
                      end: 0.0,
                      duration: const Duration(milliseconds: 1600),
                      curve: Curves.easeOut,
                    ),
                  ],
                  child: Container(
                    width: math.max(screenSize.width, screenSize.height) * 0.12,
                    height: math.max(screenSize.width, screenSize.height) * 0.12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.7),
                          colorScheme.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
          // Third Ripple effect (smallest but fastest)
          if (_showThirdRipple)
            Positioned.fill(
              child: Center(
                child: Animate(
                  effects: [
                    ScaleEffect(
                      begin: const Offset(0.05, 0.05),
                      end: const Offset(8.0, 8.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOut,
                    ),
                    FadeEffect(
                      begin: 0.95,
                      end: 0.0,
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.easeOut,
                    ),
                  ],
                  child: Container(
                    width: math.max(screenSize.width, screenSize.height) * 0.1,
                    height: math.max(screenSize.width, screenSize.height) * 0.1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 