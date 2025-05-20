import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:wisedose/firebase_options.dart';
import 'package:wisedose/services/auth_service.dart';
import 'package:wisedose/services/theme_service.dart';
import 'package:wisedose/services/notification_service.dart';
import 'package:wisedose/screens/splash_screen.dart';
import 'package:wisedose/screens/auth/login_screen.dart';
import 'package:wisedose/screens/auth/register_screen.dart';
import 'package:wisedose/screens/patient/patient_dashboard.dart';
import 'package:wisedose/screens/pharmacist/pharmacist_dashboard.dart';
import 'package:wisedose/screens/admin/admin_dashboard.dart';
import 'package:wisedose/screens/profile_screen.dart';
import 'package:wisedose/utils/app_theme.dart';


void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print("Initializing Firebase...");
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
    
    // Initialize notifications (placeholder)
    await NotificationService().initialize();
    
    // Uncomment the following lines to create test users
    // Only run this once, then comment it out again
    // final testUserCreator = TestUserCreator();
    // await testUserCreator.createTestUsers();
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          // Initialize AuthService after Firebase is ready
          ChangeNotifierProvider(create: (_) => AuthService()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print("Error during app initialization: $e");
    // Show error UI if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'WiseDose',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/patient': (context) => const PatientDashboard(),
            '/pharmacist': (context) => const PharmacistDashboard(),
            '/admin': (context) => const AdminDashboard(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}
