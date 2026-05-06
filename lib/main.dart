import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

/// App entry point.
///
/// Initialisation order (PRD §7 — offline-first):
///   1. Hive — must be fully ready (initFlutter + box open) before runApp,
///      so [AppointmentController.build] can do synchronous box reads.
///   2. ProviderScope — wraps the widget tree; providers are lazy by default
///      so [AppointmentController] initialises on first watch.
///   3. MaterialApp — theme + router only; no logic here.
///
/// TODO (Milestone 5): Add Firebase.initializeApp() here (after Hive) once
///   google-services.json / GoogleService-Info.plist are configured.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Hive initialisation ────────────────────────────────────────────────
  //
  // We use a JSON-map approach (no generated TypeAdapters) which means:
  //   • No build_runner required.
  //   • Appointments are stored as Map<String, dynamic> via AppointmentMapper.
  //   • ServiceType is stored as an ID string; looked up from ServiceCatalog.
  //
  // The box MUST be opened here (not inside a provider) so that all
  // synchronous box reads in AppointmentController.build() succeed.
  await Hive.initFlutter();

  // Appointments — primary offline store (PRD §7).
  // Box<dynamic> is intentional: we cast map fields in AppointmentMapper.
  await Hive.openBox<dynamic>(AppConstants.hiveBoxAppointments);

  // Service types — reserved for future per-clinic configuration override.
  // Currently unused; ServiceCatalog provides the static list.
  await Hive.openBox<dynamic>(AppConstants.hiveBoxServiceTypes);

  // TODO (Milestone 5): Register Hive TypeAdapters if migrating from JSON-map
  //   to generated adapters for performance gains on large datasets.
  //   Example:
  //     Hive.registerAdapter(AppointmentHiveAdapter());

  // TODO (Milestone 5): Firebase.initializeApp() goes here:
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );

  runApp(
    // ── 2. Riverpod root ────────────────────────────────────────────────────
    // ProviderScope is the root; all providers are accessible below this.
    const ProviderScope(
      child: AppointQApp(),
    ),
  );
}

/// Root application widget.
///
/// Thin layer — only theme + router.
/// All business logic lives in providers and screens.
class AppointQApp extends StatelessWidget {
  const AppointQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── Theme ───────────────────────────────────────────────────────────
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // ── Navigation ──────────────────────────────────────────────────────
      initialRoute: AppConstants.routeHome,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
