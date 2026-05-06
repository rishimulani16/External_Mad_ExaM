/// AppointmentController — Riverpod Notifier that owns the in-memory
/// appointment list and encapsulates all booking/queue business rules.
///
/// Persistence layer (Milestone 3):
///   - [build] loads from Hive on startup; falls back to seed data on first run.
///   - Every mutation persists a delta (one or many records) to Hive via
///     [HiveAppointmentBox] before returning.
///   - `isSynced = false` is written on every local mutation, marking the
///     record as "needs push to Firestore".
///
/// TODO (Milestone 5): After each mutation, enqueue a background sync job
///   via SyncManager.push(appointment) which will set `isSynced = true`
///   on success and update the Hive record accordingly.
library;

import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/appointment.dart';
import '../domain/service_type.dart';
import '../domain/booking_error.dart';
import '../storage/hive_appointment_box.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result type  (same sealed class — no change)
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps either a success value or a typed [BookingError].
/// Avoids try/catch in the UI; instead: `switch (result) { ... }`.
sealed class BookingResult<T> {
  const BookingResult();
}

final class BookingSuccess<T> extends BookingResult<T> {
  const BookingSuccess(this.value);
  final T value;
}

final class BookingFailure<T> extends BookingResult<T> {
  const BookingFailure(this.error);
  final BookingError error;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppointmentController
// ─────────────────────────────────────────────────────────────────────────────

class AppointmentController extends Notifier<List<Appointment>> {
  // ─────────────────────────────────────────────────────────────────────────
  // Startup: load from Hive, seed on first run
  // ─────────────────────────────────────────────────────────────────────────

  @override
  List<Appointment> build() {
    // ── Load persisted data ─────────────────────────────────────────────────
    // HiveAppointmentBox.loadAll() is synchronous because the box was opened
    // in main() before runApp().  No async gap → no loading state needed.
    if (HiveAppointmentBox.hasData) {
      return HiveAppointmentBox.loadAll();
    }

    // ── First-run seed ──────────────────────────────────────────────────────
    // On a fresh install the box is empty.  Persist the seed data immediately
    // so subsequent launches read from Hive instead of re-seeding.
    final seed = _seedData();
    HiveAppointmentBox.saveMany(seed);
    return seed;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Books a new appointment after running conflict checks (PRD §6.1).
  ///
  /// On success: persists to Hive with `isSynced = false`.
  /// On conflict: returns a typed [BookingFailure] — nothing is persisted.
  BookingResult<Appointment> bookAppointment({
    required String userName,
    required ServiceType serviceType,
    required DateTime dateTime,
  }) {
    // ── Validation: no past date/time (PRD §Validation) ───────────────────
    if (dateTime.isBefore(DateTime.now())) {
      return const BookingFailure(PastDateTimeError());
    }

    // ── Conflict: exact duplicate (same user + service + slot) ────────────
    final duplicate = state.where((a) {
      return a.userName.toLowerCase() == userName.toLowerCase() &&
          a.serviceType.id == serviceType.id &&
          _sameSlot(a.dateTime, dateTime) &&
          a.status != AppointmentStatus.cancelled;
    }).firstOrNull;

    if (duplicate != null) {
      return BookingFailure(DuplicateBookingError(existingId: duplicate.id));
    }

    // ── Conflict: slot capacity exceeded (PRD §6.1) ───────────────────────
    final slotCount = state.where((a) {
      return a.serviceType.id == serviceType.id &&
          _sameSlot(a.dateTime, dateTime) &&
          a.status != AppointmentStatus.cancelled;
    }).length;

    if (slotCount >= serviceType.maxCapacityPerSlot) {
      return BookingFailure(
        SlotFullError(
          maxCapacity: serviceType.maxCapacityPerSlot,
          serviceTypeName: serviceType.name,
        ),
      );
    }

    // ── Assign queue position: max existing + 1 for today ─────────────────
    final todayPending = state.where((a) =>
        _sameDay(a.dateTime, dateTime) &&
        a.status == AppointmentStatus.scheduled);

    final nextPosition = todayPending.isEmpty
        ? 1
        : todayPending.map((a) => a.queuePosition).reduce(math.max) + 1;

    // ── Calculate estimated wait (PRD §6.2) ───────────────────────────────
    final ahead = nextPosition - 1;
    final estimatedWait = ahead * serviceType.avgDurationMinutes;

    final newAppointment = Appointment(
      id: _generateId(),
      userName: userName.trim(),
      serviceType: serviceType,
      dateTime: dateTime,
      queuePosition: nextPosition,
      status: AppointmentStatus.scheduled,
      createdAt: DateTime.now(),
      estimatedWaitMinutes: estimatedWait,
      // isSynced = false: local-only until SyncManager pushes to Firestore.
      // TODO (Milestone 5): SyncManager.enqueue(newAppointment) here.
      isSynced: false,
    );

    // ── Update in-memory state ────────────────────────────────────────────
    state = [...state, newAppointment];

    // ── Persist delta to Hive ─────────────────────────────────────────────
    HiveAppointmentBox.save(newAppointment);

    return BookingSuccess(newAppointment);
  }

  /// Cancels an appointment by id.
  ///
  /// Sets `isSynced = false` to mark the cancellation as a pending
  /// remote update.
  /// TODO (Milestone 5): SyncManager.enqueue(cancelled) after state change.
  BookingResult<void> cancelAppointment(String id) {
    final idx = _indexOf(id);
    if (idx == -1) return BookingFailure(AppointmentNotFoundError(id: id));

    final cancelled = state[idx].copyWith(
      status: AppointmentStatus.cancelled,
      isSynced: false, // local change — not yet pushed to Firestore
    );

    state = _replaceAt(idx, cancelled);

    // Persist the cancelled record before renumbering (order matters for
    // crash-recovery: we want the cancel stored even if renumber fails).
    HiveAppointmentBox.save(cancelled);

    // Renumber remaining queue and persist the batch.
    _recomputeQueuePositions();

    return const BookingSuccess(null);
  }

  /// Generic status update — admin use (mark completed, in-progress, etc.).
  ///
  /// Sets `isSynced = false` on every local status change.
  /// TODO (Milestone 5): SyncManager.enqueue(updated) after state change.
  BookingResult<void> updateStatus(String id, AppointmentStatus newStatus) {
    final idx = _indexOf(id);
    if (idx == -1) return BookingFailure(AppointmentNotFoundError(id: id));

    final updated = state[idx].copyWith(
      status: newStatus,
      isSynced: false, // local change — not yet confirmed on Firestore
    );

    state = _replaceAt(idx, updated);

    // ── Persist delta to Hive ─────────────────────────────────────────────
    HiveAppointmentBox.save(updated);

    return const BookingSuccess(null);
  }

  /// Marks the current [inProgress] appointment as [completed] and promotes
  /// the next [scheduled] appointment to [inProgress].
  ///
  /// Sets `isSynced = false` on every changed record.
  /// TODO (Milestone 5): SyncManager.enqueueMany([completed, promoted]).
  BookingResult<void> advanceQueue() {
    final queue = _sortedPendingQueue();

    // Track which appointments were mutated so we can batch-persist them.
    final changed = <Appointment>[];

    // ── Mark current in-progress as completed ─────────────────────────────
    final inProgressIdx =
        state.indexWhere((a) => a.status == AppointmentStatus.inProgress);

    if (inProgressIdx != -1) {
      final completed = state[inProgressIdx].copyWith(
        status: AppointmentStatus.completed,
        isSynced: false, // local change — not yet pushed to Firestore
      );
      state = _replaceAt(inProgressIdx, completed);
      changed.add(completed);
    }

    // ── Promote next scheduled → inProgress ───────────────────────────────
    final nextScheduled =
        queue.where((a) => a.status == AppointmentStatus.scheduled).firstOrNull;

    if (nextScheduled == null) {
      // Persist the completion before returning empty-queue error.
      if (changed.isNotEmpty) HiveAppointmentBox.saveMany(changed);
      return const BookingFailure(EmptyQueueError());
    }

    final nextIdx = _indexOf(nextScheduled.id);
    final promoted = state[nextIdx].copyWith(
      status: AppointmentStatus.inProgress,
      isSynced: false, // local change — not yet pushed to Firestore
    );
    state = _replaceAt(nextIdx, promoted);
    changed.add(promoted);

    // ── Persist completed + promoted before renumber ───────────────────────
    HiveAppointmentBox.saveMany(changed);

    // Renumber and persist remaining scheduled appointments.
    _recomputeQueuePositions();

    return const BookingSuccess(null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Two DateTimes are in the same 30-minute scheduling window.
  bool _sameSlot(DateTime a, DateTime b) {
    if (!_sameDay(a, b)) return false;
    final slotA = a.hour * 2 + (a.minute >= 30 ? 1 : 0);
    final slotB = b.hour * 2 + (b.minute >= 30 ? 1 : 0);
    return slotA == slotB;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _indexOf(String id) => state.indexWhere((a) => a.id == id);

  List<Appointment> _replaceAt(int idx, Appointment updated) {
    final copy = List<Appointment>.from(state);
    copy[idx] = updated;
    return copy;
  }

  /// Returns today's pending queue sorted by queuePosition then createdAt.
  List<Appointment> _sortedPendingQueue() {
    final today = DateTime.now();
    return state
        .where((a) =>
            _sameDay(a.dateTime, today) &&
            (a.status == AppointmentStatus.scheduled ||
                a.status == AppointmentStatus.inProgress))
        .toList()
      ..sort((a, b) => a.queuePosition != b.queuePosition
          ? a.queuePosition.compareTo(b.queuePosition)
          : a.createdAt.compareTo(b.createdAt));
  }

  /// After a cancel/advance, renumber queue positions so they stay contiguous.
  ///
  /// Persists all renumbered appointments in a single [HiveAppointmentBox.saveMany]
  /// call to minimise write transactions.
  void _recomputeQueuePositions() {
    final today = DateTime.now();
    final pending = state
        .where((a) =>
            _sameDay(a.dateTime, today) &&
            a.status == AppointmentStatus.scheduled)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final copy = List<Appointment>.from(state);
    final renumbered = <Appointment>[];

    for (var i = 0; i < pending.length; i++) {
      final idx = copy.indexWhere((a) => a.id == pending[i].id);
      final wait = i * pending[i].serviceType.avgDurationMinutes;
      final updated = copy[idx].copyWith(
        queuePosition: i + 1,
        estimatedWaitMinutes: wait,
        // Renumbering is a local bookkeeping change — mark unsynced.
        // TODO (Milestone 5): Batch these with the parent operation's sync job.
        isSynced: false,
      );
      copy[idx] = updated;
      renumbered.add(updated);
    }

    state = copy;

    // ── Batch persist all renumbered records in one Hive transaction ───────
    if (renumbered.isNotEmpty) {
      HiveAppointmentBox.saveMany(renumbered);
    }
  }

  /// Crypto-free UUID-like ID sufficient for offline-first use.
  /// Will be replaced by a Firestore document ID in Milestone 5.
  String _generateId() {
    final rng = math.Random();
    const chars = 'abcdef0123456789';
    String seg() =>
        List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
    return '${seg()}-${seg()}-${seg()}-${seg()}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Seed data  (first-run only — persisted to Hive immediately in build())
  // ─────────────────────────────────────────────────────────────────────────

  static List<Appointment> _seedData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      Appointment(
        id: 'a1b2c3d4e5f67890abcdef12',
        userName: 'Rishi Mulani',
        serviceType: ServiceCatalog.generalConsultation,
        dateTime: today.add(const Duration(hours: 10)),
        queuePosition: 1,
        status: AppointmentStatus.inProgress,
        createdAt: now.subtract(const Duration(hours: 2)),
        estimatedWaitMinutes: 0,
        isSynced: true, // seed data counts as "synced" (canonical source)
      ),
      Appointment(
        id: 'b2c3d4e5f6a78901bcdef123',
        userName: 'Priya Sharma',
        serviceType: ServiceCatalog.labTest,
        dateTime: today.add(const Duration(hours: 10, minutes: 30)),
        queuePosition: 2,
        status: AppointmentStatus.scheduled,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        estimatedWaitMinutes: 15,
        isSynced: true,
      ),
      Appointment(
        id: 'c3d4e5f6a7b89012cdef1234',
        userName: 'Arjun Patel',
        serviceType: ServiceCatalog.followUpVisit,
        dateTime: today.add(const Duration(hours: 11)),
        queuePosition: 3,
        status: AppointmentStatus.scheduled,
        createdAt: now.subtract(const Duration(hours: 1)),
        estimatedWaitMinutes: 30,
        isSynced: false, // simulates an offline-created appointment
      ),
      Appointment(
        id: 'd4e5f6a7b8c90123def12345',
        userName: 'Sneha Joshi',
        serviceType: ServiceCatalog.vaccination,
        dateTime: today.add(const Duration(hours: 11, minutes: 30)),
        queuePosition: 4,
        status: AppointmentStatus.scheduled,
        createdAt: now.subtract(const Duration(minutes: 50)),
        estimatedWaitMinutes: 45,
        isSynced: true,
      ),
      Appointment(
        id: 'e5f6a7b8c9d01234ef123456',
        userName: 'Rahul Desai',
        serviceType: ServiceCatalog.dentalCheckup,
        dateTime: today.subtract(const Duration(days: 1, hours: -9)),
        queuePosition: 0,
        status: AppointmentStatus.completed,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        estimatedWaitMinutes: 0,
        isSynced: true,
      ),
      Appointment(
        id: 'f6a7b8c9d0e12345f1234567',
        userName: 'Kavya Nair',
        serviceType: ServiceCatalog.generalConsultation,
        dateTime: today.subtract(const Duration(days: 1, hours: -10)),
        queuePosition: 0,
        status: AppointmentStatus.cancelled,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        estimatedWaitMinutes: 0,
        isSynced: true,
      ),
    ];
  }
}
