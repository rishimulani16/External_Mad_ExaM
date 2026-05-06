/// AppointmentController — Riverpod Notifier that owns the in-memory
/// appointment list and encapsulates all booking/queue business rules.
///
/// Milestone 3: purely in-memory (`List<Appointment>`).
/// Milestone 4: replace _state mutations with Hive writes + Firestore sync.
library;

import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/appointment.dart';
import '../domain/service_type.dart';
import '../domain/booking_error.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result type
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

/// Manages the canonical in-memory list of `Appointment`s.
///
/// Naming note: the class is intentionally called `AppointmentController` to
/// match the PRD, but it extends Riverpod's [Notifier] which is the modern
/// (v2) alternative to StateNotifier.
class AppointmentController extends Notifier<List<Appointment>> {
  // ── Initialise with seed data so screens show content immediately. ────────
  @override
  List<Appointment> build() => _seedData();

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Books a new appointment after running conflict checks (PRD §6.1).
  ///
  /// Returns [BookingSuccess<Appointment>] on success.
  /// Returns [BookingFailure] with a typed [BookingError] on conflict.
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

    final nextPosition =
        todayPending.isEmpty ? 1 : todayPending.map((a) => a.queuePosition).reduce(math.max) + 1;

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
      isSynced: false,
    );

    state = [...state, newAppointment];

    // TODO (Milestone 4): push to Hive + enqueue Firestore sync.
    return BookingSuccess(newAppointment);
  }

  /// Cancels an appointment by id.
  BookingResult<void> cancelAppointment(String id) {
    final idx = _indexOf(id);
    if (idx == -1) return BookingFailure(AppointmentNotFoundError(id: id));

    state = _replaceAt(idx, state[idx].copyWith(status: AppointmentStatus.cancelled));
    _recomputeQueuePositions();
    return const BookingSuccess(null);
  }

  /// Generic status update — admin use (mark completed, in-progress, etc.).
  BookingResult<void> updateStatus(String id, AppointmentStatus newStatus) {
    final idx = _indexOf(id);
    if (idx == -1) return BookingFailure(AppointmentNotFoundError(id: id));

    state = _replaceAt(idx, state[idx].copyWith(status: newStatus));
    return const BookingSuccess(null);
  }

  /// Marks the current [inProgress] appointment as [completed] and promotes
  /// the next [scheduled] appointment to [inProgress].
  ///
  /// Returns [EmptyQueueError] if the queue is already empty.
  BookingResult<void> advanceQueue() {
    final queue = _sortedPendingQueue();

    // Mark current in-progress as completed (if any)
    final inProgressIdx = state.indexWhere(
      (a) => a.status == AppointmentStatus.inProgress,
    );
    if (inProgressIdx != -1) {
      state = _replaceAt(
        inProgressIdx,
        state[inProgressIdx].copyWith(status: AppointmentStatus.completed),
      );
    }

    // Promote next scheduled → in-progress
    final nextScheduled = queue
        .where((a) => a.status == AppointmentStatus.scheduled)
        .firstOrNull;

    if (nextScheduled == null) return const BookingFailure(EmptyQueueError());

    final nextIdx = _indexOf(nextScheduled.id);
    state = _replaceAt(
      nextIdx,
      state[nextIdx].copyWith(status: AppointmentStatus.inProgress),
    );

    _recomputeQueuePositions();
    return const BookingSuccess(null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Two DateTimes are in the same 30-minute scheduling window.
  bool _sameSlot(DateTime a, DateTime b) {
    if (!_sameDay(a, b)) return false;
    // Normalise to the start of the 30-min window
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
  void _recomputeQueuePositions() {
    final today = DateTime.now();
    final pending = state
        .where((a) =>
            _sameDay(a.dateTime, today) &&
            a.status == AppointmentStatus.scheduled)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final copy = List<Appointment>.from(state);
    for (var i = 0; i < pending.length; i++) {
      final idx = copy.indexWhere((a) => a.id == pending[i].id);
      final wait = i * pending[i].serviceType.avgDurationMinutes;
      copy[idx] = copy[idx].copyWith(
        queuePosition: i + 1,
        estimatedWaitMinutes: wait,
      );
    }
    state = copy;
  }

  /// Crypto-free UUID-like ID sufficient for in-memory use.
  String _generateId() {
    final rng = math.Random();
    const chars = 'abcdef0123456789';
    String seg() => List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
    return '${seg()}-${seg()}-${seg()}-${seg()}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Seed data  (mirrors mock_data.dart; will be removed in Milestone 4)
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
        isSynced: true,
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
        isSynced: false,
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
