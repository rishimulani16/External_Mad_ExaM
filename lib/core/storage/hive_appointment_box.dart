/// HiveAppointmentBox — thin synchronous wrapper around the Hive [Box].
///
/// Design decisions:
///   • Uses [Appointment.id] as the Hive key → O(1) point reads and writes.
///   • All operations are synchronous because the box is opened in [main]
///     before [runApp], so no async gap can occur.
///   • Exposes only the operations [AppointmentController] needs — no raw
///     Hive primitives leak into business logic.
///
/// Depends on [AppointmentMapper] for serialisation; nothing else.
library;

import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../domain/appointment.dart';
import 'appointment_mapper.dart';

abstract final class HiveAppointmentBox {
  // ── Box accessor ───────────────────────────────────────────────────────────

  /// Returns the already-opened box.
  /// Throws a [HiveError] if the box was never opened (should never happen
  /// because [main] always calls `Hive.openBox` before [runApp]).
  static Box<dynamic> get _box =>
      Hive.box<dynamic>(AppConstants.hiveBoxAppointments);

  // ─────────────────────────────────────────────────────────────────────────
  // Read operations
  // ─────────────────────────────────────────────────────────────────────────

  /// Loads all persisted appointments from Hive on startup.
  ///
  /// Returns an empty list if the box is empty (fresh install or cleared).
  /// Corrupted individual entries are silently skipped and logged to stderr.
  static List<Appointment> loadAll() {
    final results = <Appointment>[];
    for (final raw in _box.values) {
      try {
        results.add(AppointmentMapper.fromMap(raw as Map<dynamic, dynamic>));
      } catch (e) {
        // Ignore corrupted records — do not crash the app on startup.
        // TODO (Milestone 5): Report to crash-analytics (e.g. Firebase Crashlytics).
        // ignore: avoid_print
        print('[HiveAppointmentBox] Skipping corrupted record: $e');
      }
    }
    // Sort by createdAt so the loaded list is deterministically ordered.
    results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return results;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Write operations (delta — not full flush)
  // ─────────────────────────────────────────────────────────────────────────

  /// Persists (insert or update) a single [Appointment].
  ///
  /// Called after every state mutation in [AppointmentController].
  /// Using `put(id, map)` gives O(1) writes instead of a full list flush.
  static void save(Appointment appointment) {
    _box.put(appointment.id, AppointmentMapper.toMap(appointment));
  }

  /// Persists multiple appointments in one batch.
  ///
  /// Called after [advanceQueue] and [_recomputeQueuePositions] where
  /// several records change queuePosition / estimatedWaitMinutes at once.
  static void saveMany(List<Appointment> appointments) {
    final entries = {
      for (final a in appointments) a.id: AppointmentMapper.toMap(a),
    };
    _box.putAll(entries); // single write transaction
  }

  /// Removes a single appointment by [id].
  ///
  /// Not used in the current flow (we keep cancelled appointments for audit),
  /// but provided for completeness and test teardown.
  static void delete(String id) => _box.delete(id);

  /// Clears the entire box.
  ///
  /// ⚠️  Destructive — only call during testing / factory reset.
  static void clearAll() => _box.clear();

  // ─────────────────────────────────────────────────────────────────────────
  // Query helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true if the box contains at least one record.
  static bool get hasData => _box.isNotEmpty;

  /// Number of records currently stored.
  static int get count => _box.length;
}
