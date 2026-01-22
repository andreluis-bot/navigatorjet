import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';

/// Splash Screen - Initial loading screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Initialize app and navigate to map
  Future<void> _initialize() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Navigate to map screen
    context.go('/map');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Icon(
              Icons.sailing,
              size: 120,
              color: AppConfig.success,
            ),
            const SizedBox(height: 24),
            
            // App name
            const Text(
              'NavigatorJet',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppConfig.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Tagline
            Text(
              'Navegue Seguro. Navegue Sempre.',
              style: TextStyle(
                fontSize: 16,
                color: AppConfig.textPrimary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConfig.success),
            ),
          ],
        ),
      ),
    );
  }
}