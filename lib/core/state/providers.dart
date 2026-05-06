/// All Riverpod providers for the appointment + queue feature.
///
/// Import this file wherever you need to read appointment data.
/// Never construct AppointmentController manually — always read via providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/appointment.dart';
import '../domain/service_type.dart';
import 'appointment_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core: appointmentListProvider
// ─────────────────────────────────────────────────────────────────────────────

/// The single source of truth for all appointments.
///
/// Backed by [AppointmentController]; all mutation methods live there.
final appointmentListProvider =
    NotifierProvider<AppointmentController, List<Appointment>>(
  AppointmentController.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Derived: queueProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Today's pending queue sorted by queuePosition, then createdAt.
///
/// Includes only [scheduled] and [inProgress] appointments for today.
/// Recomputes automatically whenever [appointmentListProvider] changes.
final queueProvider = Provider<List<Appointment>>((ref) {
  final all = ref.watch(appointmentListProvider);
  final today = DateTime.now();

  bool sameDay(DateTime a) =>
      a.year == today.year && a.month == today.month && a.day == today.day;

  return all
      .where((a) =>
          sameDay(a.dateTime) &&
          (a.status == AppointmentStatus.scheduled ||
              a.status == AppointmentStatus.inProgress))
      .toList()
    ..sort((a, b) => a.queuePosition != b.queuePosition
        ? a.queuePosition.compareTo(b.queuePosition)
        : a.createdAt.compareTo(b.createdAt));
});

// ─────────────────────────────────────────────────────────────────────────────
// Derived: currentServingProvider
// ─────────────────────────────────────────────────────────────────────────────

/// The appointment currently being served (status == [inProgress]).
///
/// Returns null when the queue is empty or between patients.
final currentServingProvider = Provider<Appointment?>((ref) {
  final queue = ref.watch(queueProvider);
  try {
    return queue.firstWhere((a) => a.status == AppointmentStatus.inProgress);
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Derived: scheduledQueueProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Only the [scheduled] entries from today's queue (pending, not yet serving).
final scheduledQueueProvider = Provider<List<Appointment>>((ref) {
  return ref
      .watch(queueProvider)
      .where((a) => a.status == AppointmentStatus.scheduled)
      .toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Derived: queuePositionProvider (family — per user)
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the live queue position for a specific appointment id.
///
/// Example:
///   final pos = ref.watch(queuePositionProvider('apt-id-here'));
final queuePositionProvider =
    Provider.family<int?, String>((ref, appointmentId) {
  final queue = ref.watch(scheduledQueueProvider);
  try {
    return queue.firstWhere((a) => a.id == appointmentId).queuePosition;
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Derived: estimatedWaitProvider (family — per appointment id)
// ─────────────────────────────────────────────────────────────────────────────

/// Estimated wait in minutes for a specific appointment.
final estimatedWaitProvider =
    Provider.family<int, String>((ref, appointmentId) {
  final all = ref.watch(appointmentListProvider);
  try {
    return all.firstWhere((a) => a.id == appointmentId).estimatedWaitMinutes;
  } catch (_) {
    return 0;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Static: serviceTypeListProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable list of available service types for Booking dropdowns.
final serviceTypeListProvider = Provider<List<ServiceType>>(
  (_) => ServiceCatalog.all,
);
