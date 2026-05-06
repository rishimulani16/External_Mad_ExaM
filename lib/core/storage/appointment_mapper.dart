/// Bidirectional JSON mapper: [Appointment] ↔ [Map].
///
/// Why JSON-map instead of a generated HiveTypeAdapter?
///   - Zero `build_runner` dependency.
///   - `ServiceType` is a nested value type looked up from [ServiceCatalog]
///     by ID, so there is nothing complex to serialise.
///   - Trivially portable to Firestore/REST (same map shape).
///
/// Field contract (stored map keys must not be renamed without a migration):
///   id, userName, serviceTypeId, dateTime, queuePosition,
///   status, createdAt, estimatedWaitMinutes, isSynced
library;

import '../domain/appointment.dart';
import '../domain/service_type.dart';

abstract final class AppointmentMapper {
  // ─────────────────────────────────────────────────────────────────────────
  // Appointment → Map
  // ─────────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> toMap(Appointment a) => {
        'id': a.id,
        'userName': a.userName,
        // Store only the ID — look up the full ServiceType on read.
        'serviceTypeId': a.serviceType.id,
        // ISO-8601 strings are human-readable and timezone-safe.
        'dateTime': a.dateTime.toIso8601String(),
        'queuePosition': a.queuePosition,
        // Use enum .name so stored strings match Dart enum identifiers.
        'status': a.status.name,
        'createdAt': a.createdAt.toIso8601String(),
        'estimatedWaitMinutes': a.estimatedWaitMinutes,
        // ── Sync flag ──────────────────────────────────────────────────────
        // false  = local change not yet pushed to Firestore.
        // true   = confirmed persisted on the backend.
        // TODO (Milestone 5): SyncManager sets this to true after a
        //         successful Firestore write-ack.
        'isSynced': a.isSynced,
      };

  // ─────────────────────────────────────────────────────────────────────────
  // Map → Appointment
  // ─────────────────────────────────────────────────────────────────────────

  /// [map] may be a `Map<String, dynamic>` from our own code, or a
  /// `Map<dynamic, dynamic>` as Hive returns it — we cast each field
  /// individually for safety.
  static Appointment fromMap(Map<dynamic, dynamic> map) {
    // ServiceType is a value object looked up by ID from the static catalog.
    final serviceType =
        ServiceCatalog.findById(map['serviceTypeId'] as String) ??
            ServiceCatalog.generalConsultation; // safe fallback

    // Status enum: decode from stored name string.
    final statusName = map['status'] as String;
    final status = AppointmentStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => AppointmentStatus.scheduled, // safe fallback
    );

    return Appointment(
      id: map['id'] as String,
      userName: map['userName'] as String,
      serviceType: serviceType,
      dateTime: DateTime.parse(map['dateTime'] as String),
      queuePosition: (map['queuePosition'] as num).toInt(),
      status: status,
      createdAt: DateTime.parse(map['createdAt'] as String),
      estimatedWaitMinutes: (map['estimatedWaitMinutes'] as num).toInt(),
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }
}
