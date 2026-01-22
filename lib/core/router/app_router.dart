import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/navigation/presentation/screens/instrument_mode_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) => const MaterialPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        pageBuilder: (context, state) => const MaterialPage(
          child: MapScreen(),
        ),
      ),
      GoRoute(
        path: '/instruments',
        name: 'instruments',
        pageBuilder: (context, state) => const MaterialPage(
          child: InstrumentModeScreen(),
        ),
      ),
    ],
  );
});