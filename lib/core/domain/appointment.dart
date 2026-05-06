/// Enriched Appointment domain model — Milestone 3.
///
/// Replaces the plain-UI model in common/models/.
/// Hive TypeAdapter annotations will be added in Milestone 4
/// once the backend layer is integrated.
library;

import 'package:flutter/foundation.dart';
import 'service_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppointmentStatus enum  (PRD §5 — Appointment Status)
// ─────────────────────────────────────────────────────────────────────────────
enum AppointmentStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get displayName => switch (this) {
        AppointmentStatus.scheduled => 'Scheduled',
        AppointmentStatus.inProgress => 'In Progress',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.cancelled => 'Cancelled',
      };

  bool get isActive =>
      this == AppointmentStatus.scheduled ||
      this == AppointmentStatus.inProgress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Appointment model  (PRD §5.1)
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable domain model.  All mutations produce a new instance via [copyWith].
@immutable
class Appointment {
  const Appointment({
    required this.id,
    required this.userName,
    required this.serviceType,
    required this.dateTime,
    required this.queuePosition,
    required this.status,
    required this.createdAt,
    required this.estimatedWaitMinutes,
    this.isSynced = false,
  });

  final String id;
  final String userName;
  final ServiceType serviceType;

  /// Exact date + time of the booked slot (replaces separate date + timeSlot).
  final DateTime dateTime;

  /// 1-based position in today's queue; 0 means not in queue.
  final int queuePosition;

  final AppointmentStatus status;
  final DateTime createdAt;
  final int estimatedWaitMinutes;

  /// False until the record is persisted to Firestore / REST (PRD §7).
  final bool isSynced;

  // ── Derived properties ────────────────────────────────────────────────────

  /// Human-readable ID shown in the UI (PRD §5.1).
  String get displayId => 'APT-${id.substring(0, 8).toUpperCase()}';

  /// Formatted time slot label, e.g. "10:00 AM – 10:30 AM".
  String get timeSlotLabel {
    final h = dateTime.hour;
    final m = dateTime.minute.toString().padLeft(2, '0');
    final endDt = dateTime.add(Duration(minutes: serviceType.avgDurationMinutes));
    final eh = endDt.hour;
    final em = endDt.minute.toString().padLeft(2, '0');
    String fmt(int hour, String min) {
      final period = hour < 12 ? 'AM' : 'PM';
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$h12:$min $period';
    }
    return '${fmt(h, m)} – ${fmt(eh, em)}';
  }

  // ── copyWith ──────────────────────────────────────────────────────────────
  Appointment copyWith({
    String? userName,
    ServiceType? serviceType,
    DateTime? dateTime,
    int? queuePosition,
    AppointmentStatus? status,
    int? estimatedWaitMinutes,
    bool? isSynced,
  }) {
    return Appointment(
      id: id,
      userName: userName ?? this.userName,
      serviceType: serviceType ?? this.serviceType,
      dateTime: dateTime ?? this.dateTime,
      queuePosition: queuePosition ?? this.queuePosition,
      status: status ?? this.status,
      createdAt: createdAt,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Appointment && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Appointment($displayId, $userName, ${status.displayName})';
}
