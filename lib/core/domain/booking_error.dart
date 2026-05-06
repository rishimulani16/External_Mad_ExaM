/// Custom error types returned / thrown by AppointmentController.
///
/// Using a sealed class keeps error handling exhaustive (switch without
/// a default branch) and keeps business-rule descriptions out of the UI.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Sealed error hierarchy
// ─────────────────────────────────────────────────────────────────────────────

/// Base type for all booking / queue errors.
sealed class BookingError {
  const BookingError();

  /// Short user-facing message.
  String get message;
}

/// The exact (userName × serviceType × dateTime) combination already exists.
final class DuplicateBookingError extends BookingError {
  const DuplicateBookingError({required this.existingId});

  final String existingId;

  @override
  String get message =>
      'You already have an appointment (ID: APT-${existingId.substring(0, 8).toUpperCase()}) '
      'for the same service at the same time.';
}

/// The 30-minute window has reached its maximum capacity for the service type.
final class SlotFullError extends BookingError {
  const SlotFullError({
    required this.maxCapacity,
    required this.serviceTypeName,
  });

  final int maxCapacity;
  final String serviceTypeName;

  @override
  String get message =>
      'The selected slot is fully booked for "$serviceTypeName" '
      '(max $maxCapacity bookings per slot). Please choose a different time.';
}

/// The chosen date/time is in the past (PRD §Validation).
final class PastDateTimeError extends BookingError {
  const PastDateTimeError();

  @override
  String get message => 'Appointments cannot be booked for a past date or time.';
}

/// Attempted to act on an appointment that does not exist.
final class AppointmentNotFoundError extends BookingError {
  const AppointmentNotFoundError({required this.id});

  final String id;

  @override
  String get message => 'Appointment APT-${id.substring(0, 8).toUpperCase()} was not found.';
}

/// Queue is empty — nothing to advance.
final class EmptyQueueError extends BookingError {
  const EmptyQueueError();

  @override
  String get message => 'There are no pending appointments to advance.';
}
