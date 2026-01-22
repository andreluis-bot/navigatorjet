import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'data/models/route.dart' as app_models;
import 'data/models/waypoint.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Hive.initFlutter();
  
  // CORREÇÃO: Usando o alias app_models para Route e RoutePoint
  Hive.registerAdapter(app_models.RouteAdapter());
  // Se RoutePoint está dentro de route.dart, ele precisa do prefixo
  Hive.registerAdapter(app_models.RoutePointAdapter());
  Hive.registerAdapter(app_models.RouteDirectionAdapter());
  Hive.registerAdapter(WaypointAdapter());

  await Hive.openBox<app_models.Route>('routes');
  await Hive.openBox<Waypoint>('waypoints');
  await Hive.openBox('settings');

  WakelockPlus.enable();

  runApp(
    const ProviderScope(
      child: NavigatorJetApp(),
    ),
  );
}

class NavigatorJetApp extends ConsumerWidget {
  const NavigatorJetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'NavigatorJet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConfig.success,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppConfig.background,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppConfig.textPrimary),
          bodyMedium: TextStyle(color: AppConfig.textPrimary),
        ),
      ),
      routerConfig: router,
    );
  }
}