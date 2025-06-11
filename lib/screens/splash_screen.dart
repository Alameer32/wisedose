// ignore_for_file: avoid_print, unreachable_switch_default

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisedose/services/auth_service.dart';
import 'package:wisedose/utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    
    // Fallback timer to prevent getting stuck on splash screen
    Future.delayed(const Duration(seconds: 5), () {
      if (!_hasNavigated && mounted) {
        print("Fallback navigation triggered");
        _navigateToLogin();
      }
    });
  }

  Future<void> _checkAuthState() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Wait a moment for Firebase to initialize
      await Future.delayed(const Duration(seconds: 2));
      
      if (authService.currentUser != null) {
        print("User is logged in, checking role...");
        
        // Ensure user data is loaded
        if (authService.userModel == null) {
          await Future.delayed(const Duration(seconds: 1));
        }
        
        if (!mounted) return;
        
        // Navigate based on user role
        if (authService.userModel != null) {
          print("Navigating based on role: ${authService.userModel!.role}");
          _navigateBasedOnRole(authService.userModel!.role);
        } else {
          print("User model is null, navigating to login");
          _navigateToLogin();
        }
      } else {
        print("No user logged in, navigating to login");
        _navigateToLogin();
      }
    } catch (e) {
      print("Error in splash screen: $e");
      if (mounted && !_hasNavigated) {
        _navigateToLogin();
      }
    }
  }

  void _navigateBasedOnRole(UserRole role) {
    if (_hasNavigated) return;
    
    setState(() {
      _hasNavigated = true;
    });
    
    switch (role) {
      case UserRole.patient:
        Navigator.of(context).pushReplacementNamed('/patient');
        break;
      case UserRole.pharmacist:
        Navigator.of(context).pushReplacementNamed('/pharmacist');
        break;
      case UserRole.admin:
        Navigator.of(context).pushReplacementNamed('/admin');
        break;
      default:
        Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _navigateToLogin() {
    if (_hasNavigated) return;
    
    setState(() {
      _hasNavigated = true;
    });
    
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/wisedose_logo.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.medication_rounded,
                      size: 80,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // App name
            const Text(
              'WiseDose',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // Tagline
            Text(
              'Smart Medication Management',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
