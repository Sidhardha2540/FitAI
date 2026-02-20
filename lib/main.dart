import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/nutrition_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/workout/workout_setup_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/chat/ai_chat_screen.dart';
import 'services/data_migration_service.dart';
import 'services/fitai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Firebase initialized successfully');
  
  // Check authentication state
  final user = FirebaseAuth.instance.currentUser;
  debugPrint('Current authentication state: ${user != null ? 'User is logged in (${user.uid})' : 'No user logged in'}');
  
  // Initialize FitAI service early
  debugPrint('Initializing FitAI service...');
  final fitaiService = FitAIService();
  String? userId = user?.uid ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
  debugPrint('Using user ID for FitAI service: $userId');
  await fitaiService.initialize(userId: userId);
  debugPrint('FitAI service initialized successfully');
  
  // Run data migrations if a user is logged in
  if (user != null) {
    debugPrint('Running data migrations for user: ${user.uid}');
    final migrationService = DataMigrationService();
    await migrationService.migrateWorkoutPlans();
    debugPrint('Data migrations completed');
  }
  
  debugPrint('Starting application with route providers...');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
  debugPrint('Application started successfully');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'MyFitAI',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(nextScreen: const AuthPage()),
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/workout/setup': (context) => const WorkoutSetupScreen(),
        '/chat': (context) => const AIChatScreen(),
      },
    );
  }
  
  ThemeData _buildLightTheme() {
    // Vibrant light theme based on Material 3 expressive design
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        // Primary colors - vibrant blue similar to dark theme
        primary: const Color(0xFF006F8A),       // Deeper vibrant blue
        onPrimary: Colors.white,                // White text on primary
        primaryContainer: const Color(0xFFB6EEFF), // Light blue container background
        onPrimaryContainer: const Color(0xFF001F28), // Dark text on container
        
        // Secondary colors - cool cyan
        secondary: const Color(0xFF0288D1),     // Stronger blue
        onSecondary: Colors.white,              // White text on secondary
        secondaryContainer: const Color(0xFFCBE6FF), // Light container background
        onSecondaryContainer: const Color(0xFF001D36), // Dark text on container
        
        // Tertiary colors - purple accents
        tertiary: const Color(0xFF6750A4),      // Purple accent
        onTertiary: Colors.white,               // White text on tertiary
        tertiaryContainer: const Color(0xFFE9DDFF), // Light purple container
        onTertiaryContainer: const Color(0xFF22005D), // Dark text on tertiary container
        
        // Error colors
        error: const Color(0xFFBA1A1A),         // Error red
        onError: Colors.white,                  // White text on error
        errorContainer: const Color(0xFFFFDAD6), // Light error container
        onErrorContainer: const Color(0xFF410002), // Dark text on error container
        
        // Background and surface
        background: const Color(0xFFF5F5F7),    // Light background
        onBackground: const Color(0xFF1A1C1E),  // Dark text on background
        surface: const Color(0xFFF5F5F7),       // Surface same as background
        onSurface: const Color(0xFF1A1C1E),     // Dark text on surface
        
        // Surface containers with varying elevations
        surfaceContainerLowest: const Color(0xFFFBFBFC),
        surfaceContainerLow: const Color(0xFFF5F5F7),
        surfaceContainer: const Color(0xFFF0F0F2),
        surfaceContainerHigh: const Color(0xFFEAEAEC),
        surfaceContainerHighest: const Color(0xFFE4E4E6),
        
        // Variant surfaces
        surfaceVariant: const Color(0xFFE0E2EC),  // Light surface variant
        onSurfaceVariant: const Color(0xFF43474E), // Dark text on surface variant
        
        // Outline
        outline: const Color(0xFF73777F),         // Medium contrast outline
        outlineVariant: const Color(0xFFC3C7CF),  // Low contrast outline
        
        // Other contrasts
        inverseSurface: const Color(0xFF2F3033),  // Dark inverse surface
        onInverseSurface: const Color(0xFFF1F0F4), // Light text on inverse surface
        inversePrimary: const Color(0xFF8ECEFF),  // Light inverse primary
        
        // Shadow and scrim
        shadow: const Color(0xFF000000),          // Shadow color
        scrim: const Color(0xFF000000),           // Scrim color
        
        // Surface tint
        surfaceTint: Colors.transparent,          // No tint
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12, color: Color(0xFF202124)),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.16, color: Color(0xFF202124)),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.22, color: Color(0xFF202124)),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.25, color: Color(0xFF202124)),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.29, color: Color(0xFF202124)),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.33, color: Color(0xFF202124)),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.27, color: Color(0xFF202124)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, height: 1.5, color: Color(0xFF202124)),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43, color: Color(0xFF202124)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.43, color: Color(0xFF202124)),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.33, color: Color(0xFF202124)),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.45, color: Color(0xFF5F6368)),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.5, color: Color(0xFF202124)),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43, color: Color(0xFF202124)),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33, color: Color(0xFF5F6368)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: const Color(0xFF006F8A), // Match primary
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(color: const Color(0xFF006F8A), width: 1), // Match primary
          animationDuration: const Duration(milliseconds: 200),
          foregroundColor: const Color(0xFF006F8A), // Match primary
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          animationDuration: const Duration(milliseconds: 200),
          foregroundColor: const Color(0xFF006F8A), // Match primary
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF202124),
        toolbarHeight: 64,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF006F8A)); // Match primary
          }
          return const TextStyle(fontSize: 12, color: Color(0xFF77786A));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 24, color: Color(0xFF006F8A)); // Match primary
          }
          return const IconThemeData(size: 24, color: Color(0xFF77786A));
        }),
        height: 80,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFDADCE0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF81C784), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1), // Match error
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: const Color(0xFF81C784).withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE0E0E0)),
        secondaryLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF81C784)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
        alignment: Alignment.center,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        space: 24,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minLeadingWidth: 24,
        minVerticalPadding: 12,
        iconColor: Color(0xFF81C784),
        textColor: Color(0xFFE0E0E0),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF81C784),
        thumbColor: const Color(0xFF81C784),
        inactiveTrackColor: const Color(0xFF404040),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentTextStyle: const TextStyle(fontSize: 14),
        elevation: 3,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF81C784);
          }
          return const Color(0xFFBDBDBD);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF81C784).withOpacity(0.3);
          }
          return const Color(0xFF424242);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF81C784);
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFF1B1B1B)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF81C784);
          }
          return const Color(0xFFBDBDBD);
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF81C784).withOpacity(0.15);
            }
            return const Color(0xFF2C2C2C);
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF81C784);
            }
            return const Color(0xFFBDBDBD);
          }),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  ThemeData _buildDarkTheme() {
    // Modern dark theme with subtle colors for better UX and widget distinction
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        // Primary colors - much more subtle green
        primary: const Color(0xFF81C784),       // Subtle green, not too bright
        onPrimary: const Color(0xFF1B1B1B),     // Dark text on primary
        primaryContainer: const Color(0xFF2E7D32), // Medium green container
        onPrimaryContainer: const Color(0xFFC8E6C9), // Very light green text on container
        
        // Secondary colors - subtle blue-green
        secondary: const Color(0xFF4DB6AC),     // Subtle teal
        onSecondary: const Color(0xFF1B1B1B),   // Dark text on secondary
        secondaryContainer: const Color(0xFF00695C), // Medium teal container
        onSecondaryContainer: const Color(0xFFB2DFDB), // Light teal text on container
        
        // Tertiary colors - very subtle purple accents
        tertiary: const Color(0xFFBA68C8),      // Subtle purple accent
        onTertiary: const Color(0xFF1B1B1B),    // Dark text on tertiary
        tertiaryContainer: const Color(0xFF7B1FA2), // Medium purple container
        onTertiaryContainer: const Color(0xFFE1BEE7), // Light purple text on container
        
        // Error colors - subtle red
        error: const Color(0xFFE57373),         // Subtle red for errors
        onError: const Color(0xFF1B1B1B),       // Dark text on error
        errorContainer: const Color(0xFFD32F2F), // Medium red container
        onErrorContainer: const Color(0xFFFFCDD2), // Light text on error container
        
        // Background and surface - subtle dark
        background: const Color(0xFF0F0F0F),    // Very dark but not pure black
        onBackground: const Color(0xFFE8E8E8),  // Light gray text on background
        surface: const Color(0xFF1A1A1A),       // Dark surface with some warmth
        onSurface: const Color(0xFFE8E8E8),     // Light gray text on surface
        
        // Surface containers with subtle variations for better distinction
        surfaceContainerLowest: const Color(0xFF141414),
        surfaceContainerLow: const Color(0xFF1F1F1F),
        surfaceContainer: const Color(0xFF242424),
        surfaceContainerHigh: const Color(0xFF2A2A2A),
        surfaceContainerHighest: const Color(0xFF303030),
        
        // Variant surfaces - more distinct from primary surfaces
        surfaceVariant: const Color(0xFF2C2C2C),  // Distinct medium surface
        onSurfaceVariant: const Color(0xFFBDBDBD), // Medium gray text
        
        // Outline - more subtle
        outline: const Color(0xFF424242),         // Subtle outline
        outlineVariant: const Color(0xFF2C2C2C),  // Very subtle outline
        
        // Other contrasts
        inverseSurface: const Color(0xFFE8E8E8),  // Light inverse surface
        onInverseSurface: const Color(0xFF1A1A1A), // Dark text on inverse surface
        inversePrimary: const Color(0xFF81C784),  // Balanced inverse primary
        
        // Shadow and scrim
        shadow: const Color(0xFF000000),          // Shadow color
        scrim: const Color(0xFF000000),           // Scrim color
        
        // Surface tint - almost invisible
        surfaceTint: Colors.transparent,          // No tint for better distinction
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, height: 1.12, color: Color(0xFFE0E0E0)),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.16, color: Color(0xFFE0E0E0)),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, height: 1.22, color: Color(0xFFE0E0E0)),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.25, color: Color(0xFFF5F5F5)),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.29, color: Color(0xFFF5F5F5)),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.33, color: Color(0xFFF5F5F5)),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 0, height: 1.27, color: Color(0xFFF5F5F5)),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15, height: 1.5, color: Color(0xFFE0E0E0)),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.43, color: Color(0xFFE0E0E0)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, height: 1.43, color: Color(0xFF81C784)),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, height: 1.33, color: Color(0xFF81C784)),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, height: 1.45, color: Color(0xFFB0B0B0)),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.5, color: Color(0xFFE0E0E0)),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.43, color: Color(0xFFE0E0E0)),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, height: 1.33, color: Color(0xFFB0B0B0)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: const Color(0xFF81C784).withOpacity(0.2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: const Color(0xFF81C784),
          foregroundColor: const Color(0xFF1B1B1B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          backgroundColor: const Color(0xFF81C784),
          foregroundColor: const Color(0xFF1B1B1B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 2,
          shadowColor: const Color(0xFF81C784).withOpacity(0.2),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          side: const BorderSide(color: Color(0xFF81C784), width: 1.5),
          foregroundColor: const Color(0xFF81C784),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          animationDuration: const Duration(milliseconds: 200),
          foregroundColor: const Color(0xFF81C784),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Color(0xFF0F0F0F),
        foregroundColor: Color(0xFFE8E8E8),
        toolbarHeight: 64,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF81C784),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFF81C784).withOpacity(0.15),
        backgroundColor: const Color(0xFF1A1A1A),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF81C784));
          }
          return const TextStyle(fontSize: 12, color: Color(0xFFBDBDBD));
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 24, color: Color(0xFF81C784));
          }
          return const IconThemeData(size: 24, color: Color(0xFFBDBDBD));
        }),
        height: 80,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
        hintStyle: const TextStyle(color: Color(0xFF808080)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: const Color(0xFF81C784).withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFE0E0E0)),
        secondaryLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF81C784)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 8,
        alignment: Alignment.center,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        space: 24,
        thickness: 1,
        color: Color(0xFF404040),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minLeadingWidth: 24,
        minVerticalPadding: 12,
        iconColor: Color(0xFF81C784),
        textColor: Color(0xFFE0E0E0),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF81C784),
        thumbColor: const Color(0xFF81C784),
        inactiveTrackColor: const Color(0xFF404040),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2A2A2A),
        contentTextStyle: const TextStyle(fontSize: 14, color: Color(0xFFE0E0E0)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF81C784);
          }
          return const Color(0xFFBDBDBD);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF81C784).withOpacity(0.3);
          }
          return const Color(0xFF424242);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF81C784);
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFF1B1B1B)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF81C784);
          }
          return const Color(0xFFBDBDBD);
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF81C784).withOpacity(0.15);
            }
            return const Color(0xFF2C2C2C);
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF81C784);
            }
            return const Color(0xFFBDBDBD);
          }),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;
  bool _isPasswordVisible = false;
  
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      UserCredential userCredential; // To hold the result
      if (_isLogin) {
        // Sign in existing user
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Create new user
        userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      
      if (mounted && userCredential.user != null) {
        // Initialize UserProvider before navigating
        await Provider.of<UserProvider>(context, listen: false).initialize();
        // Navigate to home page on success
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _error = 'No user found with this email.';
            break;
          case 'wrong-password':
            _error = 'Wrong password provided.';
            break;
          case 'email-already-in-use':
            _error = 'Email is already in use.';
            break;
          case 'weak-password':
            _error = 'The password is too weak.';
            break;
          case 'invalid-email':
            _error = 'Invalid email address.';
            break;
          default:
            _error = 'Authentication failed: ${e.message}';
        }
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Initialize Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Ensure previous session is signed out to always show account picker
      await googleSignIn.signOut();
      
      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // If no user was selected (sign-in canceled), return
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Get auth details from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with Google credential
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential); // To hold the result
      
      // Navigate to home page on success
      if (mounted && userCredential.user != null) {
        // Initialize UserProvider before navigating
        await Provider.of<UserProvider>(context, listen: false).initialize();
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _error = 'Google sign-in failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? colorScheme.surface : colorScheme.primaryContainer,
              isDarkMode ? colorScheme.surface : Colors.white,
            ],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Animate(
                    effects: const [
                      SlideEffect(
                        begin: Offset(0, -0.1),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeOutQuad,
                      ),
                      FadeEffect(
                        begin: 0.0,
                        end: 1.0,
                        duration: Duration(milliseconds: 600),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.png', 
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Powered by Gemini',
                            style: TextStyle(
                              color: isDarkMode ? colorScheme.onSurfaceVariant : const Color(0xFF5F6368),
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Animate(
                    effects: const [
                      SlideEffect(
                        begin: Offset(0, 0.1),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeOutQuad,
                      ),
                      FadeEffect(
                        delay: Duration(milliseconds: 200),
                        begin: 0.0,
                        end: 1.0,
                        duration: Duration(milliseconds: 600),
                      ),
                    ],
                    child: Text(
                      'Your Personal Fitness Assistant',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Animate(
                    effects: const [
                      SlideEffect(
                        begin: Offset(0, 0.2),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeOutQuad,
                      ),
                      FadeEffect(
                        delay: Duration(milliseconds: 300),
                        begin: 0.0,
                        end: 1.0,
                        duration: Duration(milliseconds: 800),
                      ),
                    ],
                    child: Card(
                      elevation: 0,
                      shadowColor: Colors.black.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isLogin ? 'Sign In' : 'Create Account',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'example@email.com',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode 
                                    ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                                    : colorScheme.surfaceContainerHighest.withOpacity(0.1),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: _isLogin ? '********' : 'At least 6 characters',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode 
                                    ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                                    : colorScheme.surfaceContainerHighest.withOpacity(0.1),
                                ),
                                obscureText: !_isPasswordVisible,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (!_isLogin && value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 40),
                              if (_isLoading)
                                Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  )
                                )
                              else
                                FilledButton(
                                  onPressed: _submitForm,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    minimumSize: const Size(double.infinity, 56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    _isLogin ? 'Sign In' : 'Sign Up',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLogin ? 'Don\'t have an account?' : 'Already have an account?',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLogin = !_isLogin;
                                        _error = null;
                                      });
                                    },
                                    child: Text(
                                      _isLogin ? 'Sign Up' : 'Sign In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: colorScheme.outlineVariant,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'OR',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: colorScheme.outlineVariant,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  side: BorderSide(
                                    color: colorScheme.outline,
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: Image.asset(
                                  'assets/images/google_logo.png',
                                  height: 24,
                                  width: 24,
                                ),
                                label: Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Animate(
                      effects: const [
                        SlideEffect(
                          begin: Offset(0, 0.5),
                          end: Offset.zero,
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                        ),
                        FadeEffect(
                          begin: 0.0,
                          end: 1.0,
                          duration: Duration(milliseconds: 500),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Card(
                          color: colorScheme.errorContainer,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
