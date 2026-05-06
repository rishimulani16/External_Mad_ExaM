/// App-wide constants — no business logic, no widgets.
/// Add route names, Hive box keys, and configuration defaults here.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // Named Routes (must match keys in AppRouter)
  // ---------------------------------------------------------------------------
  static const String routeHome = '/';
  static const String routeBooking = '/booking';
  static const String routeQueue = '/queue';
  static const String routeAdminDashboard = '/admin/dashboard';
  static const String routeAdminQueueControl = '/admin/queue-control';
  static const String routeSearch = '/search';

  // ---------------------------------------------------------------------------
  // Hive Box Names  (PRD §7 — local storage keys)
  // ---------------------------------------------------------------------------
  static const String hiveBoxAppointments = 'appointments';
  static const String hiveBoxServiceTypes = 'service_types';

  // ---------------------------------------------------------------------------
  // Queue / Slot Defaults
  // ---------------------------------------------------------------------------
  static const int defaultMaxCapacityPerSlot = 5;   // PRD §6.1
  static const int defaultSlotDurationMinutes = 30;  // PRD §5.2

  // ---------------------------------------------------------------------------
  // App Metadata
  // ---------------------------------------------------------------------------
  static const String appName = 'AppointQ';
  static const String appVersion = '1.0.0';
}
