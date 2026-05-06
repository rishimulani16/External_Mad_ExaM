import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

/// App entry point.
///
/// Initialisation order (PRD §7 — offline-first):
///   1. Hive (local storage) — must be ready before any reads/writes.
///   2. ProviderScope — wraps the whole tree for Riverpod.
///   3. MaterialApp — uses AppTheme and AppRouter; no routing logic here.
///
/// Firebase initialisation will be inserted here in Milestone 4 when the
/// google-services.json file is configured.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 1. Hive initialisation ---
  await Hive.initFlutter();
  // TypeAdapters for Appointment and ServiceType will be registered here
  // in Milestone 3 once the models are code-generated via build_runner.
  await Hive.openBox<dynamic>(AppConstants.hiveBoxAppointments);
  await Hive.openBox<dynamic>(AppConstants.hiveBoxServiceTypes);

  // --- 2. (Optional) Firebase initialisation — uncomment in Milestone 4 ---
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(
    // --- 3. Riverpod root ---
    const ProviderScope(
      child: AppointQApp(),
    ),
  );
}

/// Root application widget.
/// Thin layer: only theme + router. All logic lives in providers and screens.
class AppointQApp extends StatelessWidget {
  const AppointQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // --- Theme ---
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // --- Navigation ---
      initialRoute: AppConstants.routeHome,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
